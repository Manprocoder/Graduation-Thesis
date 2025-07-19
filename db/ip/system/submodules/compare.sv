
//
//
//
module compare(
    input logic 		    clk_i,
    input logic 			rst_n_i,
    //
    //internal input
    //
	input logic [127:0]     in_tag_i, 
    input logic [127:0]     xor_tag_i, 
    input logic             verify_tag_i,
	//
    //internal outputs
	//
    output logic        auth_valid_o, //
    output logic        tag_match_o //
);
    
    //internal regs
    logic match_reg, auth_valid_reg;
    //
    //
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) match_reg <= 1'b0;
        else if(match_reg) match_reg <= 1'b0; //aead_done_i
        else if(verify_tag_i) match_reg <= (xor_tag_i == in_tag_i);
    end

    //output 
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
            auth_valid_reg <= 1'b0;
        end
        else if(auth_valid_reg) begin
            auth_valid_reg <= 1'b0;
        end
        else if(verify_tag_i) begin
            auth_valid_reg <= 1'b1;
        end
    end
    
    //output assignment
    assign auth_valid_o = auth_valid_reg;
    assign tag_match_o = auth_valid_reg & match_reg;

endmodule