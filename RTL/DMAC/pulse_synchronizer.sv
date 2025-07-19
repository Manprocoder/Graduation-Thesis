//
//synchronize 100MHz -> 50 MHz
//
module pulse_synchronizer(
    input logic src_clk_i,
    input logic src_rstn_i,
    input logic des_clk_i,
    input logic des_rstn_i,
    input logic d_in,
    //
    output logic synch_o
    //
);
    //
    logic q0, q1, q2, q3;
    logic mux_op;
    //
    assign mux_op = d_in ? ~q0 : q0; 
    //
    //detect d_in
    always_ff@(posedge src_clk_i, negedge src_rstn_i) begin
        if(~src_rstn_i) q0 <= 1'b0;
        else q0 <= mux_op;
    end
    //
    //2-FF synchronizer
    //
    always_ff@(posedge des_clk_i, negedge des_rstn_i) begin
        if(~des_rstn_i) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
            q3 <= 1'b0;
        end
        else begin
            q1 <= q0;
            q2 <= q1;
            q3 <= q2;
        end
    end
    //
    assign synch_o = q3 ^ q2;
    //
endmodule