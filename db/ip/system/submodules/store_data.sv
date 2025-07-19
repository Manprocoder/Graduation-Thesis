//
//
`timescale 1ps/1ps
//
module store_data(
	//
    //global signals
    //
    input logic clk_i,
    input logic rst_n_i,
	//
    //internal inputs
    //
	//control signals
	input logic 		 latch_fifo_wused_i,
	input logic 		 hash_code_vld_i,
	input logic 		 aead_data_vld_i,
    input logic          sqz_hash_done_i,
    input logic          last_message_block_i,
	input logic 		 latch_text_type_i,
	input logic 		 fifo_read_i,
	input logic 		 tag_fail_i,
	//data
	input logic [1:0]	 abs_cnt_i,
    input logic [63:0]   state_i,
    input logic [63:0]   xor_result_i,
	input logic [07:0]   text_vld_byte_i,
    input logic [2:0]    run_mode_i,
	input logic [1:0]	 last_hash_block_size_i,
	input logic [6:0]	 text_words_i,

    //
	output logic 		 rd_done_o,
	output logic		 fifo_avail_o,
    output logic [38:0]  fifo_data_o

);

    //import
    import ascon_cfg::*;
    //(1)--FIFO
	logic fifo_empty;
	logic fifo_clr;
	logic fifo_wr, fifo_rd, fifo_full;
	logic [4:0] fifo_usedw;
	logic [38:0] fifo_data_i;
	logic [127:0] data_shift_reg;
	logic [15:0] vld_byte_shift_reg;
	logic [3:0] last_hash_vld_byte;
	logic [7:0] used_byte_enable;
	logic [7:0] hash_byte_enable;
	logic [2:0] type_reg;
	logic [6:0] text_words_cnt;
	logic [1:0] wr_cnt;	
	logic wr_done;
	logic wr_start;
	logic end_of_text;
	//************************************************************
	//---------------------internal output-------------------
	//************************************************************
	assign fifo_avail_o = ~fifo_empty;
	//************************************************************
	//---------------------internal assignment-------------------
	//************************************************************
	assign end_of_text = fifo_wr & (text_words_cnt == 1);
	//
	//vld bytes for hash
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) begin
			last_hash_vld_byte <= 4'h0;
		end
		else if(end_of_text) begin
			last_hash_vld_byte <= 4'h0;
		end
		else if(last_message_block_i) begin
			case(last_hash_block_size_i[1:0])
				2'b00: last_hash_vld_byte <= 4'hf;
				2'b01: last_hash_vld_byte <= 4'h8;
				2'b10: last_hash_vld_byte <= 4'hC;
				2'b11: last_hash_vld_byte <= 4'hE;
			endcase
		end
	end
	//type reg
	//
	always_ff@(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) type_reg <= D_NULL;
		else if(end_of_text) begin
			type_reg <= D_NULL;
		end
		else if(last_message_block_i) begin
			type_reg <= D_HASH;
		end
		else if(latch_text_type_i) begin
			type_reg <= D_TEXT;
		end
	end
	//
	//vld bytes
	//[71:64]
	assign used_byte_enable = (text_vld_byte_i[7:4] == 4'hf) ? {text_vld_byte_i[3:0], text_vld_byte_i[7:4]} : text_vld_byte_i;
	assign hash_byte_enable = sqz_hash_done_i ? {last_hash_vld_byte, 4'hf} : 8'hff;

	//***********************************************************************************
    //-----------------------------STORE AND LOAD PT/CT/HASH----------------------------
    //***********************************************************************************
	//A: WRITE
	//--temporarily put valid output into data shift reg, then push them into fifo
	//(1) put selected valid data into tmp reg (data_shift_reg)
	//
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) begin
			data_shift_reg <= '0;
			vld_byte_shift_reg <= '0;
		end
		else if(hash_code_vld_i) begin
			//
			data_shift_reg <= {data_shift_reg[127:64], state_i[31:0], state_i[63:32]};
			vld_byte_shift_reg <= {vld_byte_shift_reg[15:8], hash_byte_enable};
			//
			//
		end
		else if(aead_data_vld_i) begin
			case(abs_cnt_i)
				0: begin
					data_shift_reg <= {data_shift_reg[127:64], xor_result_i[31:0], xor_result_i[63:32]};
					vld_byte_shift_reg <= {vld_byte_shift_reg[15:8], used_byte_enable};
				end
				1: begin
					data_shift_reg <= {32'd0, xor_result_i[31:0], xor_result_i[63:32], data_shift_reg[63:32]};
					vld_byte_shift_reg <= {4'd0, used_byte_enable, vld_byte_shift_reg[7:4]};
				end
			endcase
		end
		else if(fifo_wr) begin
			data_shift_reg <= {32'd0, data_shift_reg[127:32]};
			vld_byte_shift_reg <= {4'd0, vld_byte_shift_reg[15:4]};
		end
	end
	//(2) write start enable
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) wr_start <= 1'b0;
		else if(wr_done) wr_start <= 1'b0;
		else if(hash_code_vld_i | aead_data_vld_i) begin
			wr_start <= 1'b1;
		end
	end
	//
	//(3)--counter to track maximum write times after finishing calculation of one block
	//
	assign wr_done = (wr_cnt == ((run_mode_i == ASCON_128A) ? 2'd3 : 2'd1));
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) wr_cnt <= 2'd0;
		else if(wr_done) wr_cnt <= 2'd0;
		else if(wr_start) wr_cnt <= wr_cnt + 1'd1;
	end	
	//
	//(4) manage valid write times IN TOTAL (AEAD or HASH)
	//
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) text_words_cnt <= '0;
		else if(latch_fifo_wused_i) begin
			text_words_cnt <= text_words_i;
		end
		else if(fifo_wr) begin
			text_words_cnt <= text_words_cnt - 1'd1;
		end
	end
	//********************************************************
	//B: READ
	//
	assign rd_done_o = (fifo_usedw == 1) & fifo_read_i;
	//
	//fifo signals
	//
	assign fifo_wr = wr_start & (text_words_cnt > 0) & ~fifo_full;
	assign fifo_rd = fifo_read_i;
	assign fifo_clr = tag_fail_i;
	assign fifo_data_i = {type_reg, vld_byte_shift_reg[3:0], data_shift_reg[31:0]};

//(1)
	sc_fifo #(39, 16) result_fifo(
		.clk_i(clk_i),
		.rstn_i(rst_n_i),
		.wr_i(fifo_wr),
		.rd_i(fifo_rd),
		.clr_i(fifo_clr),
		.data_i(fifo_data_i),
		//
		.data_o(fifo_data_o),
		.usedw_o(fifo_usedw),
		.full_o(fifo_full), 
		.empty_o(fifo_empty)  //
	);
//
//debug
//
	always@(posedge clk_i) begin
		if(fifo_rd) begin
			#20;
			$display("BDO_TYPE => %s", (fifo_data_o[38:36] == D_HASH) ? D_HASH : D_TEXT );
			$display("VLD_BYTES => %h", fifo_data_o[35:32]);
			$display("DATA_O = %h", fifo_data_o[31:0]);
			$display("-----------------*****************--------------");
		end
	end

endmodule