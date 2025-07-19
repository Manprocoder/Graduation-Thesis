//falling edge detect
//
module falling_edge_detect(
    input logic clk_i,
    input logic rstn_i,
    input logic sign_i,
    output logic fed_o  //
);

    //internal reg
    //
    logic prev_sign_i;
    //
    //output assignment
    assign fed_o = prev_sign_i & ~sign_i;
    //
    always_ff @(posedge clk_i, negedge rstn_i ) begin
        if(~rstn_i) prev_sign_i <= 1'b0;
        else prev_sign_i <= sign_i;
    end

endmodule