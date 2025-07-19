//
//
//
module ascon_system(
	input CLOCK2_50,
	input [0:0] KEY
);
	system u_system(
		.clk_clk(CLOCK2_50),
		.reset_reset_n(KEY[0])
	);
endmodule