//
//
//
module flag(
    input logic 		    clk_i,
    input logic 			rst_n_i,
    //interface inputs
    //internal input
    //
    input logic             last_ad_flag_clr_i,
    input logic 			last_cc_i,
    input logic             last_ad_block_i,
    input logic             last_text_block_i,
	//
    //internal outputs
	//
    output logic        last_ad_flag_o,
	output logic        invalid_flag_o    //
);
    //import parameter
    import ascon_cfg::*;
    //internal regs
    logic invalid_flag_reg, last_ad_reg;

	 // 
	 //output assignment
	 //
    assign invalid_flag_o = invalid_flag_reg;
    assign last_ad_flag_o = last_ad_reg;
    //AD last flag 
    //also used for HASH process
    always_ff @(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) last_ad_reg <= 1'b0;
        else if(last_ad_flag_clr_i) begin   //sep domain, gen_hash_trigger
			last_ad_reg <= 1'b0;
		end
        else if(last_ad_block_i) begin
            last_ad_reg <= 1'b1;
        end
    end
	 
	 //TEXT last flag 
    always_ff @(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) invalid_flag_reg <= 1'b0;
        else if(last_cc_i) begin 
            invalid_flag_reg <= 1'b0;
		end
        else if(last_text_block_i) invalid_flag_reg <= 1'b1;
    end
    

endmodule