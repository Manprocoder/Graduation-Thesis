//
//
`timescale 1ps/1ps
//
module update_state #(
parameter ROUNDS_PER_CYCLE0 = 3,  //
parameter ROUNDS_PER_CYCLE1 = 2  //
)
(
    input logic clk_i,
    input logic rst_n_i,
    //internal inputs
    input logic [2:0]      run_mode_i,
    input logic [7:0]      control_i,
		/*{eot_add_key, final_ct, abs_ad_do, abs_text_do, sep_domain, init_add_key, pdo, start};*///not used
    
    input logic [063:0]     new_state_i,
    input logic [127:0]     nonce_i,
    input logic [159:0]     key_reg_i,
    input logic [003:0]     round_cnt_i,
    //output
    output logic [319:0]    state_o //
);
    //
    //import parameter
    //
    import ascon_cfg::*;
    //internal regs
    logic [063:0]   xor_tmp, selected_tmp;
    logic [319:0]   pstate, ascon_a_pstate, other_pstate;
    logic [319:0]   state_reg;
	logic [159:0]   pq_add_key;
	logic [127:0]   rest_add_key;

    //****************************************************************
    //-----------------------INTERNAL ASSIGNMENT---------------------
	//****************************************************************
	//(2)-- add key
	assign xor_tmp = new_state_i ^ state_reg[319:256];  //get 32 MSB bits, padded_pt_i
	assign pq_add_key = state_reg[159:0] ^ key_reg_i;
	assign rest_add_key = state_reg[127:0] ^ key_reg_i[127:0];
	//(3)-- select
	assign selected_tmp = (control_i[6]) ? xor_tmp : new_state_i; //final_ct
    //(4)-- select pstate
    assign pstate = (run_mode_i == ASCON_128A) ? ascon_a_pstate : other_pstate;
    
	
    //*********************************************************
    //-----------------------Update State---------------------
	//*********************************************************
    always_ff @(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
			state_reg <= 320'h0;
		end
        else if(control_i[0]) begin  //start = eoi_i & ready_o
            case(run_mode_i)
                ASCON_128:  state_reg  <= {AS128_IV, key_reg_i[127:0], nonce_i};
                ASCON_128A: state_reg  <= {AS128A_IV, key_reg_i[127:0], nonce_i}; 
                ASCON_80PQ: state_reg  <= {AS80PQ_IV, key_reg_i, nonce_i}; 
                ASCON_HASH: state_reg  <= {H_IV, 256'h0}; 
                ASCON_XOF:  state_reg  <= {XOF_IV, 256'h0}; 
            endcase
        end
        else if(control_i[1]) begin  //pdo, control_i[1]
            state_reg <= pstate;
        end
        else if(control_i[2]) begin //init_add_key_do, [2]
            if(run_mode_i == ASCON_80PQ) state_reg <= {state_reg[319:160], pq_add_key};  //ascon_80PQ
            else state_reg <= {state_reg[319:128], rest_add_key};
        end
        else if(control_i[3]) state_reg[0] <= ~state_reg[0];  //XOR 1'b1[3]
        //
        else if(control_i[7]) begin  //eot_add_key
            //--------------------
            if(run_mode_i == ASCON_80PQ) begin
                state_reg[319:96] <= {selected_tmp, state_reg[255:96] ^ key_reg_i}; //ascon_80PQ
            end
            else if(run_mode_i == ASCON_128A) begin
                state_reg[319:64] <= {state_reg[255:192], selected_tmp, state_reg[191:64] ^ key_reg_i[127:0]}; //ascon_128a
            end
            else state_reg[319:128] <= {selected_tmp, state_reg[255:128] ^ key_reg_i[127:0]}; //ascon 128
        
        end
		  //
        else if(|control_i[5:4]) begin // ad_do, text_do
            if(run_mode_i == ASCON_128A) state_reg <= {state_reg[255:192], selected_tmp, state_reg[191:0]}; //ascon_128a
            else state_reg <= {selected_tmp, state_reg[255:0]};
        end
        else state_reg <= state_reg;
    end

    //instance
    //(1) serve other function
    permutation #(ROUNDS_PER_CYCLE0) p_others(
        .round_cnt_i(round_cnt_i),
        .x0_i(state_reg[319:256]),
        .x1_i(state_reg[255:192]),
        .x2_i(state_reg[191:128]),
        .x3_i(state_reg[127:064]),
        .x4_i(state_reg[063:0]),
        //
        .x0_o(other_pstate[319:256]),
        .x1_o(other_pstate[255:192]),
        .x2_o(other_pstate[191:128]),
        .x3_o(other_pstate[ 127:64]),
        .x4_o(other_pstate[   63:0])
    );

    //(1) serve Ascon_128A function
    permutation #(ROUNDS_PER_CYCLE1) p_ascon_a(
        .round_cnt_i(round_cnt_i),
        .x0_i(state_reg[319:256]),
        .x1_i(state_reg[255:192]),
        .x2_i(state_reg[191:128]),
        .x3_i(state_reg[127:064]),
        .x4_i(state_reg[063:0]),
        //
        .x0_o(ascon_a_pstate[319:256]),
        .x1_o(ascon_a_pstate[255:192]),
        .x2_o(ascon_a_pstate[191:128]),
        .x3_o(ascon_a_pstate[ 127:64]),
        .x4_o(ascon_a_pstate[   63:0])
    );
    //output assignment
    assign state_o = state_reg;
	 

    //****************************************
    //DEBUGGING
    //****************************************
    //(1) init permutation
    always @(posedge clk_i) begin

        if(control_i[0]) begin
            #20;
            $display("**************************************************");
            $display("------------------(Update State)------------------");
			case(run_mode_i)
				ASCON_128: $display("--------------MODE: %s--------------", ASCON_128);
				ASCON_128A: $display("--------------MODE: %s--------------", ASCON_128A);
				ASCON_80PQ: $display("--------------MODE: %s--------------", ASCON_80PQ);
				ASCON_HASH: $display("--------------MODE: %s--------------", ASCON_HASH);
				ASCON_XOF: $display("--------------MODE: %s--------------", ASCON_XOF);
			endcase
            $display("-------------NEW ASCON FUNCTION START-------------");
            $display("**************************************************");
            $display("state_reg[0] = %h", state_reg[319:256]);
            $display("state_reg[1] = %h", state_reg[255:192]);
            $display("state_reg[2] = %h", state_reg[191:128]);
            $display("state_reg[3] = %h", state_reg[127:064]);
            $display("state_reg[4] = %h", state_reg[063:000]);
            $display("---------------------*****************-------------------------");
        end

        if(control_i[1]) begin
            #20;
            $display("---------(Update State) %0d round of permutations finish-------", (run_mode_i == ASCON_128A) ? 2 : 3);
            $display("state_reg[0] = %h", state_reg[319:256]);
            $display("state_reg[1] = %h", state_reg[255:192]);
            $display("state_reg[2] = %h", state_reg[191:128]);
            $display("state_reg[3] = %h", state_reg[127:064]);
            $display("state_reg[4] = %h", state_reg[063:000]);
            $display("---------------------*****************-------------------------");
        end
        //init add key
        if(control_i[3]) begin //[2]
            #20;
            $display("---------(Update State)-AFTER INIT_ADD_KEY-------");
            $display("state_reg[0] = %h", state_reg[319:256]);
            $display("state_reg[1] = %h", state_reg[255:192]);
            $display("state_reg[2] = %h", state_reg[191:128]);
            $display("state_reg[3] = %h", state_reg[127:064]);
            $display("state_reg[4] = %h", state_reg[063:000]);
            $display("---------------------*****************-------------------------");
        end
        //
        if(control_i[6]) begin //[6]
            $display("---------(Update State) padding-----------");
            $display("new_state_i = %h", new_state_i);
            $display("state[319:256] = %h", state_reg[319:256]);
            $display("xor_result (state[319:256] ^ new_state_i) = %h", xor_tmp);
            $display("selected_temp = %h", selected_tmp);
            $display("--------------*************---------------");
        end

        if(control_i[7]) begin //[7]
            #20;
            $display("---------(Update State) BEFORE FINAL PERMUTATION__AFTER ADD KEY ---------");
            $display("state_reg[0] = %h", state_reg[319:256]);
            $display("state_reg[1] = %h", state_reg[255:192]);
            $display("state_reg[2] = %h", state_reg[191:128]);
            $display("state_reg[3] = %h", state_reg[127:064]);
            $display("state_reg[4] = %h", state_reg[063:000]);
            $display("---------------------*****************-------------------------");
        end
    end

endmodule
