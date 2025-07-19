//
//
//
module clk_divider(
    input logic sys_clk_i,
    input logic sys_rstn_i,
    //
    output logic clk_o,
    output logic rstn_o
);
    //internals
    logic rst_tmp;
    logic locked;
    logic pll_clk_o;
    //internal assignment
    assign rst_tmp = ~sys_rstn_i;
    assign clk_o = pll_clk_o & locked;
    //
    //call brand IP
    //
    pll_clk pll_clk(
		.refclk(sys_clk_i),   //  refclk.clk
		.rst(rst_tmp),      //   reset.reset
		.outclk_0(pll_clk_o), // outclk0.clk
		.locked(locked)    //  locked.export
	);
    //
    rstn_synchronizer rstn_synchronizer(
        .clk_i(clk_o),
        .en_i(locked),
        .rstn_o(rstn_o)
    );
    //
endmodule