//
//
//
module control_register_file(
    //
    //
    input logic          iClk,
    input logic          iRstn,
    //
    //MASTER READ SIGNALS
	//
    input logic          iDataValid_Master_Read,
    input logic [31:0]   iReadData_Master_Read,
    //
    input logic [07:0]   ckn_cnt_i,
    input logic          get_dma_cfg_i,
	input logic 		 get_ckn_ad_i,
    input logic          wr_info_req_i,
    //
    //
    output logic 		 wr_info_avail_o,
    output logic [4:0]   mode_d_h_o,
    output logic [7:0]   ascon_din_words_o,
    output logic [07:0]  ckn_ad_words_o,
    output logic [09:0]  wr_info_o,  // dec_flag, hash_flag, ckn_ad_len
    output logic [31:0]  out_gap_o,
    output logic [31:0]  d_addr_o,
    output logic [31:0]  length_o,  //frame nums
    output logic [07:0]  ad_words_o,
    output logic [07:0]  text_words_o,
    output logic [03:0]  ad_vld_byte_o,
    output logic [03:0]  text_vld_byte_o //
    //
    //

);
	 //
	 import dma_cfg::*;
    //
    //internal signals
    //
    logic [31:0] cfg_data_reg;
    logic [31:0] out_gap_reg;
    logic [31:0] d_addr_reg;
    logic [31:0] length_reg;
    //
    logic ascon_cfg_vld, dma_cfg_vld;
    logic wr_len_control;
    //
    //
    logic [7:0] ckn_ad_words_reg;
    logic [3:0] last_ad_vld_byte, last_text_vld_byte;
	//fifo signals
    logic wr_info_fifo_wr, wr_info_fifo_rd;
	logic wr_info_fifo_empty;
    logic [9:0] wr_info_fifo_i, wr_info_fifo_o;
    //
    //output assignment
    //
	assign wr_info_avail_o = ~wr_info_fifo_empty;
    assign ascon_din_words_o = cfg_data_reg[31:24];
    assign ad_words_o = cfg_data_reg[23:16];
    assign text_words_o = cfg_data_reg[15:8];
    assign mode_d_h_o = cfg_data_reg[4:0];
    assign ckn_ad_words_o = ckn_ad_words_reg;
    assign out_gap_o = out_gap_reg;
    assign length_o = length_reg;
    assign d_addr_o = d_addr_reg;
    assign ad_vld_byte_o = last_ad_vld_byte;
    assign text_vld_byte_o = last_text_vld_byte;
    //
    //control signals to get data
    //
    assign dma_cfg_vld = iDataValid_Master_Read & get_dma_cfg_i;
    assign ascon_cfg_vld = iDataValid_Master_Read & (ckn_cnt_i == 8'd0) & get_ckn_ad_i;
    //
    //regs
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) begin
            d_addr_reg <= 32'd0;
            out_gap_reg <= 32'd0;
            length_reg <= 32'd0;
        end
        else if(dma_cfg_vld) begin
            case(ckn_cnt_i)
                8'd0: d_addr_reg <= iReadData_Master_Read;
                8'd1: out_gap_reg <= iReadData_Master_Read;
                8'd2: length_reg <= iReadData_Master_Read;
            endcase
        end
    end
//:%s/\[11:5\]/[15:8]/g
///
//
 always_ff@(posedge iClk, negedge iRstn) begin
	  if(~iRstn) begin
			cfg_data_reg <= 32'd0;
			ckn_ad_words_reg <= 8'd0;
	  end
	  else if(ascon_cfg_vld) begin
			cfg_data_reg[31:24] <= iReadData_Master_Read[31:24]; //ascon_din words
			cfg_data_reg[23:16] <= word_cnt(iReadData_Master_Read[23:16]); // ad words
			cfg_data_reg[15:08] <= word_cnt(iReadData_Master_Read[15:8]); //text words
			cfg_data_reg[07:00] <= iReadData_Master_Read[7:0];
			//
			
			if(iReadData_Master_Read[1]) begin
				  ckn_ad_words_reg <= (iReadData_Master_Read[31:24] - word_cnt(iReadData_Master_Read[15:8]) - 3'd4);
				  //subtract TEXT and TAG
				  //
			 end
			 //enc
			 else begin
				  ckn_ad_words_reg <= iReadData_Master_Read[31:24] - word_cnt(iReadData_Master_Read[15:8]);
				  //subtract TEXT
			 end
			
			//
	  end
 end
    //
    //vld bytes
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) begin
            last_ad_vld_byte <= 4'd0;
        end
        else if(ascon_cfg_vld) begin
            case(iReadData_Master_Read[17:16]) 
                2'b00: last_ad_vld_byte <= 4'hF;
                2'b01: last_ad_vld_byte <= 4'h8;
                2'b10: last_ad_vld_byte <= 4'hC;
                2'b11: last_ad_vld_byte <= 4'hE;
            endcase
        end
    end
    //
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) last_text_vld_byte <= 4'd0;
        else if(ascon_cfg_vld) begin
            case(iReadData_Master_Read[9:8]) 
                2'b00: last_text_vld_byte <= 4'hF;
                2'b01: last_text_vld_byte <= 4'h8;
                2'b10: last_text_vld_byte <= 4'hC;
                2'b11: last_text_vld_byte <= 4'hE;
            endcase
        end
    end
    //**********************************************************************
    //--------------------------GENERATE WR INFO---------------------
    //**********************************************************************
    //
    
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) wr_len_control <= 1'b0;
        else if(ascon_cfg_vld) begin
            wr_len_control <= 1'b1;
        end
        else begin
            wr_len_control <= 1'b0;
        end
    end
    //
    //signals assignment
    //
    assign wr_info_fifo_wr = wr_len_control;
    assign wr_info_fifo_i = {cfg_data_reg[1:0], ckn_ad_words_reg}; 
    assign wr_info_fifo_rd = wr_info_req_i;
    assign wr_info_o = wr_info_fifo_o;
    //
	wr_info_fifo wr_info_fifo(
	.aclr(1'b0),
	.clock(iClk),
	.data(wr_info_fifo_i),
	.rdreq(wr_info_fifo_rd),
	.wrreq(wr_info_fifo_wr),
	.empty(wr_info_fifo_empty),
	.full(),
	.q(wr_info_fifo_o)
	//
	);
    //
	//
    //
endmodule

