//
//
//
module rstn_synchronizer(
    input logic clk_i,
    input logic en_i,
    output logic rstn_o
    //
);
    //reg
    logic [1:0] rstn_synch;
    //
    always_ff@(posedge clk_i or negedge en_i) begin
        if(~en_i) rstn_synch <= 2'b00;
        else rstn_synch <= {rstn_synch[0], 1'b1};
    end
    //
    assign rstn_o = rstn_synch[1];
    //
    //
endmodule