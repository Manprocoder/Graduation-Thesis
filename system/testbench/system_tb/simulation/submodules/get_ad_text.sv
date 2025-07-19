//
//
//
module get_ad_text
	import ascon_cfg::*;
(
    input logic clk_i,
    input logic rst_n_i,
    //interface inputs
    //
    input logic         bd_valid_i,
	input logic 		bd_last_i,
    input logic         bd_ready_i, //bd_ready_o
    input logic [2:0]   bd_type_i,
    input logic [3:0]   bd_vld_byte_i,
	input logic [31:0]  bd_i,
	//
    //internal inputs
    //
	input logic [6:0]	ad_blocks_i,
	input logic [6:0] 	text_blocks_i,
	input logic 		ad_data_req_i,
	input logic 		text_data_req_i,
	//input logic 		ad_stage_done_i,
	input logic 		sqz_hash_done_i,
	input logic 		init_domain_i,
	input logic 		sep_domain_i,
	input logic 		abs_ad_state_i,
	input logic 		abs_text_state_i,
	//
    //internal output
    //
    output logic [68:0] run_ad_o,
    output logic [72:0] run_text_o 
	//
	//
);

	//************************************************************************
	//-------------------------buffer signals--------------------------------
	//*************************************************************************
	//(1)____
	//(1.1)
	logic ad_fifo_wr, ad_fifo_rd, ad_fifo_empty;
	logic ad_fifo_full;
	logic text_fifo_wr, text_fifo_rd, text_fifo_empty;
	logic text_fifo_full;
	logic [68:0] ad_fifo_data_i; //{bd_last, vld_byte, bd}
	logic [72:0] text_fifo_data_i; //{bd_last, lsb_vld_byte, msb_da, lsb_data}
	/*--------------------------------
	(2)___AD, TEXT inputs
	--------------------------------*/
	logic [1:0] word_cnt;
	logic [3:0] tmp_vld_byte_reg;
	logic [31:0] tmp_data_reg;
	logic complete;
	logic valid_data;
	//************************************************************************
	//-------------------------INTERNAL ASSIGNMENT---------------------------
	//*************************************************************************
	
    //
    assign valid_data = bd_valid_i & bd_ready_i & ((bd_type_i == D_AD) | (bd_type_i == D_TEXT));
	assign complete = valid_data & (((word_cnt == 0) & bd_last_i) | (word_cnt == 1));
	//
	//word counter
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) word_cnt <= '0;
		else if(complete) word_cnt <= '0;
		else if(valid_data & ~bd_last_i) word_cnt <= word_cnt + 1'd1;
	end

	//(4)tmp data
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) begin
			tmp_data_reg <= 32'd0;
			tmp_vld_byte_reg <= 4'd0;
		end
		else if(valid_data) begin
			tmp_data_reg <= bd_i;
			tmp_vld_byte_reg <= bd_vld_byte_i;
		end
		
	end
	/*-------------------------------------------------------------
	----------------------------HANDLE AD-----------------------------
	--------------------------------------------------------------*/
	logic ad_done_status;
	logic ad_enable;
	logic ad_rd_done;
	logic ad_stage_done;
	logic [6:0] ad_block_cnt;
	//
	//AD counter
	//
	assign ad_stage_done = sep_domain_i | sqz_hash_done_i;
	assign ad_rd_done = (ad_block_cnt == ad_blocks_i) & abs_ad_state_i; //abs_ad state
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) ad_block_cnt <= '0;
		else if(ad_rd_done) ad_block_cnt <= '0;
		else if(ad_fifo_rd) ad_block_cnt <= ad_block_cnt + 1'd1;
	end
	//
	//pause fifo reading process
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) ad_done_status <= 1'b0;
		else if(ad_rd_done) ad_done_status <= 1'b1;
		else if(ad_stage_done) begin
			ad_done_status <= 1'b0;
		end
	end
	//
	//WRITE AD
	//
	assign ad_fifo_wr = complete & (bd_type_i == D_AD) & ~ad_fifo_full;
	assign ad_fifo_data_i = (word_cnt == 0) ? {bd_last_i, bd_vld_byte_i, bd_i, 32'd0} 
			: {bd_last_i, bd_vld_byte_i, tmp_data_reg, bd_i};
	//
	//READ AD
	//
	assign ad_enable = ~(ad_rd_done | ad_done_status);
	assign ad_fifo_rd = ad_data_req_i & ad_enable & ~ad_fifo_empty;
	/*-------------------------------------------------------------
	-------------------------HANDLE TEXT--------------------------
	--------------------------------------------------------------*/
	logic text_enable;
	logic text_done_status;
	logic text_rd_done;
	logic [6:0] text_block_cnt;
	//
	//TEXT counter
	//
	assign text_rd_done = (text_block_cnt == text_blocks_i) & abs_text_state_i;  //abs_text state
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) text_block_cnt <= '0;
		else if(text_rd_done) text_block_cnt <= '0;
		else if(text_fifo_rd) text_block_cnt <= text_block_cnt + 1'd1;
	end
	//pause fifo reading process
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) text_done_status <= 1'b0;
		else if(text_rd_done) text_done_status <= 1'b1;
		else if(init_domain_i) begin //init domain
			text_done_status <= 1'b0;
		end
	end
	//
	//WRITE TEXT
	//
	assign text_fifo_wr = complete & (bd_type_i == D_TEXT) & ~text_fifo_full;
	assign text_fifo_data_i = (word_cnt == 0) ? {bd_last_i, 4'h0, bd_vld_byte_i, bd_i, 32'd0} 
			  : {bd_last_i, tmp_vld_byte_reg, bd_vld_byte_i, tmp_data_reg, bd_i};
	//READ
	assign text_enable = ~(text_rd_done | text_done_status);
	assign text_fifo_rd = text_data_req_i & text_enable & ~text_fifo_empty;
	//
	//(0)
	//
	sc_fifo #(69, 32) ad_fifo(
		.clk_i(clk_i),
		.rstn_i(rst_n_i),
		.wr_i(ad_fifo_wr),
		.rd_i(ad_fifo_rd),
		.clr_i(1'b0),
		.data_i(ad_fifo_data_i), //69 bits (bd_last, lsb_vld_byte, msb_data, lsb_data)
		.data_o(run_ad_o),
		.usedw_o(),
		.full_o(ad_fifo_full),
		.empty_o(ad_fifo_empty) //
	);

	//
	//(1)
	//
	sc_fifo #(73, 32) text_fifo(
		.clk_i(clk_i),
		.rstn_i(rst_n_i),
		.wr_i(text_fifo_wr),
		.rd_i(text_fifo_rd),
		.clr_i(1'b0),
		.data_i(text_fifo_data_i), //
		.data_o(run_text_o),
		.usedw_o(),
		.full_o(text_fifo_full),
		.empty_o(text_fifo_empty) //
	);

/*RiSiEdgeDetector red_abs_ad(
    .clk_i(clk_i),
    .rstn_i(rst_n_i),
    .sign_i(abs_ad),
    .red_o(abs_ad_trigger)  //
);

RiSiEdgeDetector red_abs_text(
    .clk_i(clk_i),
    .rstn_i(rst_n_i),
    .sign_i(abs_text),
    .red_o(abs_text_trigger)  
	//
);*/
	//
	//
endmodule