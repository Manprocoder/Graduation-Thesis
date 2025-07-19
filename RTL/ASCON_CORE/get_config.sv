//
//
//
module get_config
(
    input logic clk_i,
    input logic rst_n_i,
    //interface inputs
    //
    input logic         bd_valid_i,
    input logic [2:0]   bd_type_i,
    input logic [31:0]  bd_i,
	//
    //internal inputs
    //
	input logic 		eoi_i,
	input logic 		ready_i,
	input logic 		almost_done_i,
	input logic 		idle_state_i,
	//
    //internal outputs
    //
    output logic        pass_data_o,
    output logic [2:0]  run_mode_o,
    output logic        hash_flag_o,
    output logic        dec_flag_o,
    output logic [6:0]  ad_size_o,
	output logic [6:0]	ad_blocks_o,
	output logic [6:0]  text_bytes_o,
	output logic [6:0]	text_words_o,
	output logic [6:0]	hash_blocks_o,
	//
    //interface outputs
    //
    output logic        bdi_ready_o  
	//
	//
);
	//import
    import ascon_cfg::*;
	import func::*;
    //***********************************************
    //-----------INTERNAL SIGNALS------------------
    //***********************************************
	logic get_cfg_do;
    logic [31:0] new_cfg_reg, run_cfg_reg; 
	
	logic [6:0] ad_size_reg;
	logic [6:0] ad_blocks_reg;
	logic [6:0] text_bytes_reg, text_words_reg;
	logic [6:0] hash_blocks_reg;
	logic pass_data;
	logic pass_cfg, cfg_avail;
	logic start;
	logic pause;
    //do controls
	assign get_cfg_do = bd_valid_i & bdi_ready_o & (bd_type_i == D_CFG);
	//
	//start detect
	assign start = eoi_i & ready_i;
	//
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) pass_data <= 1'b0;
		else if(start) pass_data <= 1'b1;
		else pass_data <= 1'b0;
	end
	//
	//bdi_ready_o
	//
	assign pause = eoi_i & ~ready_i;
	//
	always_ff @(posedge clk_i or negedge rst_n_i) begin
        if(~rst_n_i) bdi_ready_o   <= 1'b0;
		  else if(pause) bdi_ready_o <= 1'b0;
		  else bdi_ready_o <= 1'b1;
    end
	//
	//get config
	//mode, ad_size, output_size, dec, hash
	//
	//(1)__get
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) cfg_avail <= 1'b0;
		else if(pass_cfg) cfg_avail <= 1'b0;
		else if(get_cfg_do) cfg_avail <= 1'b1;
	end
	//
	assign pass_cfg = cfg_avail & (idle_state_i | almost_done_i);

	//*****************************************************************
	//--------------------------GET INPUT----------------------------
	//*****************************************************************
	//(1)___get new config
	always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
            new_cfg_reg <= '0;
        end
        else if(get_cfg_do) begin
			new_cfg_reg <= bd_i;
        end
    end
	//(2)__pass config
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) run_cfg_reg <= '0;
		else if(pass_cfg) begin
			run_cfg_reg <= new_cfg_reg;
		end
	end
	
	 //(2_b)--AD_size
	 always_ff@(posedge clk_i, negedge rst_n_i) begin
	    if(~rst_n_i) begin
			ad_size_reg <= '0;
			ad_blocks_reg <= '0;
		end
		else if(pass_data) begin
			ad_size_reg <= run_cfg_reg[22:16];
			ad_blocks_reg <= block_cnt(run_cfg_reg[22:16]);
		end
	 end
	//(2_c)--TEXT or HASH size
	 always_ff@(posedge clk_i, negedge rst_n_i) begin
	    if(~rst_n_i) begin
			text_bytes_reg  <= '0;
			text_words_reg  <= '0;
			hash_blocks_reg <= '0;
		end
		else if(pass_data) begin
			text_bytes_reg <= run_cfg_reg[14:8];
			text_words_reg <= len_in_words(run_cfg_reg[14:8]);
			hash_blocks_reg <= block_cnt(run_cfg_reg[14:8]);
			
			//translate bytes into words (gen output)
			//
		end
	 end
    //
    //output assignment
	//
    assign pass_data_o           = pass_data;
	assign hash_flag_o	 		 = run_cfg_reg[0];
	assign dec_flag_o    		 = run_cfg_reg[1];
    assign run_mode_o    		 = run_cfg_reg[4:2];
	assign ad_size_o   	 	 	 = ad_size_reg;
	assign ad_blocks_o			 = ad_blocks_reg;
	assign text_bytes_o 	 	 = text_bytes_reg;
	assign text_words_o 	 	 = text_words_reg;
	assign hash_blocks_o	 	 = hash_blocks_reg;
	//
	//

endmodule