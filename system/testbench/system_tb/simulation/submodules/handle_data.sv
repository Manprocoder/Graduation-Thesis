//
//
`timescale 1ps/1ps
//
module handle_data
(
    //global signals
    input logic clk_i,
    input logic rst_n_i,
    //interface inputs
    //
    input logic             eoi_i,
	input logic 			bdo_ready_i,
    //internal inputs
    //
	input logic [1:0]		abs_cnt_i,
	input logic 			auth_valid_i,
    input logic             tag_match_i,
    input logic [191:0]     state_i,
    input logic             pdone_i,
    input logic             hash_flag_i,
    input logic             dec_flag_i,
	input logic 			run_key_vld_i,
    input logic [2:0]       run_mode_i,            
    input logic [127:0]     full_key_i,
    input logic [68:0]      ad_data_i,  //{bd_last, vld_byte, bd_i}
    input logic [72:0]      text_data_i, //{bd_last, prev_vld_data, last_vld_byte, msb_data, lsb_data}
	input logic [6:0]       ad_size_i,
	input logic [6:0]       text_bytes_i,
	input logic [6:0]	    text_words_i,
	input logic [6:0]		hash_blocks_i,
    //internal outputs
    //
	//to get_data
	output logic 			almost_done_o,
	output logic 			sqz_hash_done_trigger_o,
	output logic 			ad_data_req_o,
	output logic 			text_data_req_o,
	output logic 			idle_state_o,
	//
	//
	//to state and counter
	output logic [10:0]     control_o,
	output logic [063:0]	new_state_o,
	//
	//to compare submodule
	output logic [127:0]	xor_tag_o,
	output logic 			verify_tag_o,
    //
    //interface outputs
    //
    //(1)_data
    output logic        bd_valid_o,
    output logic        bd_last_o,
    output logic [2:0]  bd_type_o,
    output logic [3:0]  bd_vld_byte_o,
    output logic [31:0] bd_o,

    //(2) done
    output logic        done_o,
    output logic        ready_o //
);
	//import essential functions
    import func::*;
	import ascon_cfg::*;
    //fsm 
    state_fsm cs, ns;
	//(1)--FIFO
	logic [38:0] fifo_data_o;
	logic result_fifo_read, tag_fail, fifo_avail;
	//result signals (HASH, TEXT)
	logic latch_fifo_wused;
	logic last_message_blk;
	logic latch_text_type;
	logic hash_code_vld, aead_data_vld;
    //(2)--XOR_DO, TAG 
    logic [63:0] selected_bd, xor_result;
	logic [127:0] xor_tag_reg;
	logic shift_left_tag_enable;
	//(3)--UPDATE STATE
	logic abs_ad_do, abs_text_do, init_add_key, sep_domain, final_ct, pdo;
	logic start, eot_add_key;
	//(5) internal counter
	logic [2:0] hash_tag_cnt; //squeeze hash and gen tag output
	logic hash_tag_cnt_incr;
	logic hash_tag_cnt_clr;
	//(6) internal status
	logic status;
	logic internal_rdy;
	logic sqz_hash_done, gen_tag_done;
	//(7)--ADDITIONALS
	logic ascon_a;
	logic last_cc; //"1": last cycle of XOR between r-bit State and r-bit data block (64-bit Datapath could lead to 2-cycles)
	logic empty_ad;
	logic last_ad_flag;
	logic invalid_flag; //[1]: result(xor_result) is invalid due to padding process, thus NOT pushing it into result fifo
	logic ad_last, text_last;
	logic sqz_hash_do;
	logic p_hash; //update permutation rounds for hash mode
	logic last_ad_flag_clr;
    //**********************************************************************
	//--------------------INTERNAL OUTPUT ASSIGNMENT-----------------------
	//**********************************************************************
	//(1)--control update state and manage counter 
	assign ascon_a = (run_mode_i == ASCON_128A);
    assign abs_ad_do = (cs == ABS_AD);
    assign abs_text_do = (cs == ABS_TEXT);
	assign init_add_key = (cs == INIT_DOM);
	assign sep_domain = (cs == SEP_DOM);
	assign sqz_hash_do = (cs == SQZ_HASH);
	assign final_ct = text_last & dec_flag_i;
	assign eot_add_key = text_last & last_cc;
	assign pdo = (cs == INIT_PER) | (cs == AD_PER) | (cs == TEXT_PER) | (cs == FINAL_PER);
	assign control_o = {ascon_a, p_hash, sqz_hash_do, eot_add_key, final_ct, abs_text_do, abs_ad_do, sep_domain, init_add_key, pdo, start};
	//(2)--TAG
	assign xor_tag_o = xor_tag_reg;
	//******************************************************************
	//---------------------------INTERFACE OUTPUT----------------------
	//******************************************************************
	//(1) done_o
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) done_o <= 1'b0;
		else if(almost_done_o) done_o <= 1'b1;
		else done_o <= 1'b0;
	end
	//(2) ready_o
	//2.1: prehandle
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) status <= 1'b0;
		else if(almost_done_o) status <= 1'b1;
		else if(internal_rdy) begin
			status <= 1'b0;
		end
	end
	//2.2: assignment
	assign internal_rdy = hash_flag_i ? status : (status & run_key_vld_i);
    assign ready_o = (cs == IDLE) ? 1'b1 : internal_rdy;
	//(3) data
	assign bd_type_o = (cs == GEN_TAG) ? D_TAG : fifo_data_o[38:36];
    assign bd_o = (cs == GEN_TAG) ? xor_tag_reg[127:96] : fifo_data_o[31:0];
	assign bd_vld_byte_o = (cs == IDLE) ? 4'h0 : fifo_data_o[35:32];
	

	//*******************************************************************
	//--------------------------INTERNALS ASSIGNMENT--------------------
	//*******************************************************************
	//start signal
	assign start = eoi_i & ready_o;
	assign empty_ad = (ad_size_i == '0) & ~hash_flag_i;
	//
	//hash_tag counter
	//
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) hash_tag_cnt <= '0;
        else if(hash_tag_cnt_clr) begin 
            hash_tag_cnt <= '0;
        end
        else if(hash_tag_cnt_incr) begin 
            hash_tag_cnt <= hash_tag_cnt + 1'd1;
        end
    end
	//other signals
	assign sqz_hash_done = (hash_tag_cnt == (hash_blocks_i - 1'd1)) & (cs == SQZ_HASH);
    assign gen_tag_done =  shift_left_tag_enable & (hash_tag_cnt == 3);
	//*******************************************************************************
	//--------------handle TAG to send outside or serve authentication--------------
	//*******************************************************************************
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) xor_tag_reg <= '0;
		else if(shift_left_tag_enable) begin
			xor_tag_reg <= {xor_tag_reg[95:0], 32'd0};
		end
		else if(cs == DO_TAG) begin
			xor_tag_reg <= state_i[127:0] ^ full_key_i[127:0];
		end
	end

	//*******************************************************************
	//-----------------------------DO XOR------------------------------
	assign xor_result = state_i[191:128] ^ selected_bd;

	//
    //state regs
	//
    always_ff @(posedge clk_i or negedge rst_n_i) begin
        if(~rst_n_i) cs <= IDLE;
        else cs <= ns;
    end
	//next state logic
    always_comb begin
		ns = cs;
		idle_state_o = 1'b0;
		ad_data_req_o = 1'b0;
		text_data_req_o = 1'b0;
		//
		last_cc = 1'b0;
		selected_bd = 64'd0;
		new_state_o = 64'd0;
		ad_last = 1'b0;
		p_hash = 1'b0;
		latch_fifo_wused = 1'b0;
		last_message_blk = 1'b0;
		latch_text_type = 1'b0;
		last_ad_flag_clr = 1'b0;
		hash_code_vld = 1'b0;
		//
		text_last = 1'b0;
		aead_data_vld = 1'b0;
		//
		sqz_hash_done_trigger_o = 1'b0;
		hash_tag_cnt_clr = 1'b0;
		hash_tag_cnt_incr = 1'b0;
		shift_left_tag_enable = 1'b0;
		verify_tag_o = 1'b0;
		result_fifo_read = 1'b0;
		tag_fail = 1'b0;
		//
		bd_valid_o = 1'b0;
		bd_last_o = 1'b0;
		//
		//
        case(cs)
            IDLE: begin
				idle_state_o = 1'b1;
				//
                if(start) ns = INIT_PER;   //as all of inputs are in successful pass
                else ns = IDLE;
            end
			INIT_PER: begin
				//
				//
				if(pdone_i) begin 
					//
					if(hash_flag_i) begin
						ad_data_req_o = 1'b1;
						ns = ABS_AD;
					end
					else begin
						ns = INIT_DOM;
					end
			    end
				else ns = INIT_PER;
			end
            INIT_DOM: begin
				//
				//
                if(empty_ad) ns = SEP_DOM;
                else begin
					ad_data_req_o = 1'b1;
					ns = ABS_AD;
				end
            end
            ABS_AD: begin 
				//data 
				last_cc = (abs_cnt_i == ((run_mode_i == ASCON_128A) ? 2'd1 : 2'd0));
				//
				selected_bd = chosen_bd(ad_size_i, ad_data_i[68], last_ad_flag, ad_data_i[67:64], ad_data_i[63:0]);
				new_state_o = xor_result;
				ad_last = ad_data_i[68];
				//
				if(hash_flag_i) begin
					p_hash = 1'b1;
					//
					if(ad_data_i[68]) begin
						latch_fifo_wused = 1'b1;
						last_message_blk = 1'b1;
					end
					else begin
						latch_fifo_wused = 1'b0;
						last_message_blk = 1'b0;
					end
				end
				else p_hash = 1'b0;
				//
				//change state
				//
				if(run_mode_i == ASCON_128A) begin
                	if(last_cc) ns = AD_PER; //abs_ad_done
					else begin
						ad_data_req_o = 1'b1;
						ns = ABS_AD;
					end
				end
                else ns = AD_PER;
				//
            end
			SQZ_HASH: begin //wr_hash
				hash_code_vld = 1'b1;
				//
				if(sqz_hash_done) begin
					result_fifo_read = 1'b1;
					ns = GEN_TEXT;
					sqz_hash_done_trigger_o = 1'b1;
					hash_tag_cnt_clr = 1'b1;
					last_ad_flag_clr = 1'b1;
				end
				else begin
					ns = AD_PER;
					hash_tag_cnt_incr = 1'b1;
				end
			end
            SEP_DOM: begin
				text_data_req_o = 1'b1;
                ns = ABS_TEXT;
				latch_fifo_wused = 1'b1;
				latch_text_type = 1'b1;
				last_ad_flag_clr = 1'b1;
            end
            ABS_TEXT: begin
				//datapath: 64 bits
				last_cc = (abs_cnt_i == ((run_mode_i == ASCON_128A) ? 2'd1 : 2'd0));
				text_last = text_data_i[72];
				//(1)----select selected_bd
				if(dec_flag_i) begin
					selected_bd = text_data_i[63:0];
				end
				else begin
					selected_bd = chosen_bd(text_bytes_i, text_data_i[72], invalid_flag, text_data_i[67:64], text_data_i[63:0]);
				end
				//
				//
				if(invalid_flag) aead_data_vld = 1'b0;
				else aead_data_vld = 1'b1; 

				//*************************************************
				//decryption
				//(2) determine new_state_o
				if(dec_flag_i) begin
					if(invalid_flag) begin
						//
						if(text_data_i[67:64] == 4'hf) begin
							new_state_o = {32'h80000000, 32'd0};
						end
						else new_state_o = 64'd0;
					end
					else if(text_data_i[72]) begin
						new_state_o = last_bd(text_bytes_i, text_data_i[67:64], xor_result);
					end
					else new_state_o = selected_bd;
				end//end of if(dec_flag_i_i)
				else new_state_o = xor_result;

				//change state
				//
				if(run_mode_i == ASCON_128A) begin
					if(last_cc) begin
						if(eot_add_key) ns = FINAL_PER;
						else ns = TEXT_PER;
					end
					else begin
						text_data_req_o = 1'b1;
						ns = ABS_TEXT;
					end
				end
                else begin
					if(text_last) ns = FINAL_PER;
					else ns = TEXT_PER;
				end
            end
            AD_PER: begin
				//
                if(pdone_i) begin
                    if(hash_flag_i) begin
                        if(last_ad_flag) ns = SQZ_HASH;
                        else begin
							ad_data_req_o = 1'b1;
							ns = ABS_AD;
						end
                    end 
                    else if (last_ad_flag) ns = SEP_DOM;
                    else begin
						ad_data_req_o = 1'b1;
						ns = ABS_AD;
					end
                end// end of pdone_i
                else ns = AD_PER;
            end
            TEXT_PER: begin
				//
                if(pdone_i) begin
					text_data_req_o = 1'b1;
					ns = ABS_TEXT;
				end
                else ns = TEXT_PER;
            end
            FINAL_PER: begin
				//
                if(pdone_i) ns = DO_TAG;
                else ns = FINAL_PER;
            end
            DO_TAG: begin  //add key 
                if(dec_flag_i) ns = AUTH_TAG;
                else ns = GEN_TAG;
            end
			AUTH_TAG: begin
				verify_tag_o = 1'b1;
				//
				if(auth_valid_i) begin
					if(tag_match_i) begin
						result_fifo_read = 1'b1;
						ns = GEN_TEXT;
					end
					else begin
						tag_fail = 1'b1;
						ns = IDLE;
					end
				end
				else ns = AUTH_TAG;
				//
			end	
            GEN_TAG: begin
				//
				bd_valid_o = 1'b1;
				bd_last_o = (hash_tag_cnt == 3);
				//
				//
				if(bdo_ready_i) begin
					shift_left_tag_enable = 1'b1;
					hash_tag_cnt_incr = 1'b1;
				end
				else begin
					shift_left_tag_enable = 1'b0;
					hash_tag_cnt_incr = 1'b0;
				end
				//change state
                if(gen_tag_done) begin
					result_fifo_read = 1'b1;
					ns = GEN_TEXT;
					hash_tag_cnt_clr = 1'b1;
				end
                else begin
					ns = GEN_TAG;
					//
				end
            end
			GEN_TEXT: begin
				bd_valid_o = 1'b1;
				bd_last_o = done_o;
				//
				if(bdo_ready_i & fifo_avail) begin
					result_fifo_read = 1'b1;
				end
				else result_fifo_read = 1'b0;
				//
				//change state
				//
                if(done_o) begin
					if(start) ns = INIT_PER;  //pipeline mechanism
					else ns = IDLE;
				end
                else ns = GEN_TEXT;
            end
            default: begin
                ns = cs;
				idle_state_o = 1'b0;
				ad_data_req_o = 1'b0;
				text_data_req_o = 1'b0;
				//
				last_cc = 1'b0;
				selected_bd = 64'd0;
				new_state_o = 64'd0;
				ad_last = 1'b0;
				//
				p_hash = 1'b0;
				latch_fifo_wused = 1'b0;
				last_message_blk = 1'b0;
				latch_text_type = 1'b0;
				last_ad_flag_clr = 1'b0;
				hash_code_vld = 1'b0;
				//
				text_last = 1'b0;
				//
				aead_data_vld = 1'b0;
				sqz_hash_done_trigger_o = 1'b0;
				hash_tag_cnt_clr = 1'b0;
				hash_tag_cnt_incr = 1'b0;
				shift_left_tag_enable = 1'b0;
				verify_tag_o = 1'b0;
				result_fifo_read = 1'b0;
				tag_fail = 1'b0;
				//
				bd_valid_o = 1'b0;
				bd_last_o = 1'b0;
				//
				//
            end
			//
			//
        endcase
    end//end of always_comb
	//
    //result
    //
	store_data h0(
		//global signals
		//
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
		//
		//
		//internal inputs
		//control signals
		.latch_fifo_wused_i(latch_fifo_wused),
		.hash_code_vld_i(hash_code_vld),
		.aead_data_vld_i(aead_data_vld),
		.sqz_hash_done_i(sqz_hash_done_trigger_o),
		.last_message_blk_i(last_message_blk),
		.latch_text_type_i(latch_text_type),
		.fifo_read_i(result_fifo_read),
		.tag_fail_i(tag_fail),
		//
		//data signals
		.abs_cnt_i(abs_cnt_i),
		.state_i(state_i[191:128]),
		.xor_result_i(xor_result),
		.text_vld_byte_i(text_data_i[71:64]),
		.run_mode_i(run_mode_i),
		.last_hash_block_size_i(text_bytes_i[1:0]),
		.text_words_i(text_words_i),
		//
		//
		.rd_done_o(almost_done_o),
		.fifo_avail_o(fifo_avail),
		.fifo_data_o(fifo_data_o) 
		//
	);

	//
	//
	flag h1(
		.clk_i(clk_i),
    	.rst_n_i(rst_n_i),
    //internal inputs
    //
		.last_ad_flag_clr_i(last_ad_flag_clr),
    	.last_cc_i(last_cc),
    	.last_ad_block_i(ad_last),
    	.last_text_block_i(text_last),
	//
    //internal outputs
	//
    	.last_ad_flag_o(last_ad_flag),
		.invalid_flag_o(invalid_flag)   //  
	);


    //*******************************************
    //---------------DEBUGGING-------------------
	//*******************************************
	//int error_file;
    always @(posedge clk_i) begin
        if(cs == ABS_AD) begin
            
            $display("----------COMPUTE__AD----------");
			$display("--------------%s---------------", hash_flag_i ? "HASH" : "AEAD");
			$display("msb_state => %h", state_i[191:128]);
            $display("selected_bd => %h", selected_bd);
            $display("new_state_o => %h", new_state_o);
            $display("----------**********-----------");
        end

        if(cs == ABS_TEXT) begin
            //$display("----------handle_data(TEXT)----------");
            $display("----------COMPUTE__TEXT----------");
			$display("msb_state => %h", state_i[191:128]);
            $display("selected_bd => %h", selected_bd); 
            $display("xor_result => %h", xor_result); 
            if(dec_flag_i) begin
                if(text_data_i[64]) begin
                    $display("(dec__last_block)new_state_o => %h", new_state_o);
				end
                else begin 
					//$display("");
                    $display("(dec)new_state_o => %h", selected_bd);
				end
            end
            else begin 
                $display("(enc)new_state_o => %h", new_state_o);
            end
            //---------------------------------------//
            $display("bd_o => %h", bd_o);
            $display("----------**********-----------");
        end
		//
		
		if((cs == DO_TAG & ~dec_flag_i) | (cs == GEN_TAG & ~gen_tag_done)) begin
			#20;
			$display("TAG => %h", bd_o);
			$display("-----------------*****************--------------");
		end
	

		/*if(invalid_flag & (run_mode_i == ASCON_128A)) begin
			
			error_file = $fopen("../SIM/ERROR/error.txt");
			if((text_data_i[67:64] ==4'hf) && (new_state_o != 64'h80000000_00000000)) begin
				$fdisplay(error_file, "--------------(64'h8___)FSM CONTROL ERROR!!!----------------");
				$fdisplay(error_file, "--------------FALSE VALUE OF NEW_STATE_0!!!-----------------");
				$fdisplay(error_file, "new_state_o = %0h", new_state_o);
			end
			//
			if((text_data_i[67:64] !=4'hf) && (new_state_o != 64'h00000000_00000000)) begin
				$fdisplay(error_file, "--------------(64'h0___)FSM CONTROL ERROR!!!----------------");
				$fdisplay(error_file, "--------------FALSE VALUE OF NEW_STATE_0!!!-----------------");
				$fdisplay(error_file, "new_state_o = %0h", new_state_o);
			end

		//--------------------CHECK SELECTED_BD AFTER PADDING-------------------------//
			if((text_data_i[67:64] ==4'hf) && (selected_bd != 64'h80000000_00000000)) begin
				$fdisplay(error_file, "--------------(64'h8__)FSM CONTROL ERROR!!!-----------------");
				$fdisplay(error_file, "--------------FALSE VALUE OF SELECTED_BD!!!-----------------");
				$fdisplay(error_file, "selected_bd = %0h", selected_bd);
			end

			//
			if((text_data_i[67:64] !=4'hf) && (selected_bd != 64'h00000000_00000000)) begin
				$fdisplay(error_file, "--------------(64'h0__)FSM CONTROL ERROR!!!-----------------");
				$fdisplay(error_file, "--------------FALSE VALUE OF SELECTED_BD!!!-----------------");
				$fdisplay(error_file, "selected_bd = %0h", selected_bd);
			end
			$fclose(error_file);
		end
		//-----------------------
		if(final_ct) begin
			#20
			if(~final_ct) begin
				error_file = $fopen("../SIM/ERROR/error.txt");
				$fdisplay(error_file, "logic level of FINAL_CT ERROR!!!!");
				$fdisplay(error_file, "FINAL_CT does not last 2 cycles since it actives");
				$fclose(error_file);
			end 
		end*/
    end

endmodule