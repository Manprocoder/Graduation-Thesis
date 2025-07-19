//
//
//
module sub_to_dma(
    //
    input logic           iClk,
    input logic           sub_clk_i,
    //
    //interface inputs
    //
    input logic           sub_done_i,
    input logic           sub_auth_vld_i,
    input logic           sub_tag_match_i,
    input logic           sub_bdo_vld_i,
    input logic           sub_bdo_last_i,
    input logic [2:0]     sub_bdo_type_i,
    input logic [3:0]     sub_bdo_vld_byte_i,
    input logic [31:0]    sub_bdo_i,
    //
    //internal inputs
    //
    input logic           res_req_fetch_i,
    input logic           text_fetch_i,
    input logic           tag_fetch_i,
	//
	output logic 		  sub_bdo_rdy_o,
    //
    //internal outputs
    //
    output logic          res_avail_o,
    output logic          tag_avail_o,
    output logic          text_avail_o,
    output logic          res_req_data_o,
    output logic [32:0]   text_data_o,
    output logic [32:0]   tag_data_o
    //
    //
);
    //
    //
    import dma_cfg::*;
    import ascon_cfg::*;
	//
    //tag fifo signals
    //
    logic tag_bdo_vld;
    logic tag_fifo_wr, tag_fifo_rd;
    logic tag_fifo_empty, tag_fifo_full;
    logic [32:0] tag_fifo_i;
    logic [32:0] tag_fifo_o;
    //
    //text fifo signals
    //
	 logic text_bdo_vld;
    logic text_fifo_wr, text_fifo_rd;
    logic text_fifo_empty, text_fifo_full;
    logic [32:0] text_fifo_i;
    logic [32:0] text_fifo_o;
    //
    //request fifo
    //
    logic res_req_fifo_wr, res_req_fifo_rd;
    logic res_req_fifo_i, res_req_fifo_o;
	logic res_req_fifo_empty;
    logic tag_fail;

    //********************************************************************
    //-----------------------------OUTPUTS------------------------------
    //********************************************************************
	 //(1) internals
	 //
    assign res_req_data_o = res_req_fifo_o;
    assign text_data_o = text_fifo_o;
    assign tag_data_o = tag_fifo_o;
    assign res_avail_o = ~res_req_fifo_empty;
    assign tag_avail_o  = ~tag_fifo_empty;
    assign text_avail_o = ~text_fifo_empty;
    //
    //block
	 //
    /*always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) res_req_vld_o <= 1'b0;
        else if(res_req_fifo_rd) begin
            res_req_vld_o <= 1'b1;
        end
        else res_req_vld_o <= 1'b0;
    end*/
	 //
	 //(2)
	 //interface

	assign sub_bdo_rdy_o = tag_bdo_vld ? ~tag_fifo_full : (text_bdo_vld ? ~text_fifo_full : 1'b1);
    /*---------------------------------------------------------------------
    -------------------------------FIFO HANDLING--------------------------
    ----------------------------------------------------------------------*/
    //(1) TAG
    //
    assign tag_bdo_vld = sub_bdo_vld_i & (sub_bdo_type_i == D_TAG);
    assign tag_fifo_wr = tag_bdo_vld & ~tag_fifo_full;
    assign tag_fifo_i =  {sub_bdo_last_i, sub_bdo_i};
    assign tag_fifo_rd = tag_fetch_i & ~tag_fifo_empty;
    //
    //(2) result req
    assign tag_fail = sub_auth_vld_i & ~sub_tag_match_i;
    //
    assign res_req_fifo_wr = sub_done_i | tag_fail;
    assign res_req_fifo_i = sub_done_i ? 1'b1 : 1'b0;
    assign res_req_fifo_rd = res_req_fetch_i;
    //
res_req_fifo res_req_fifo(
	.aclr(1'b0),
	.data(res_req_fifo_i),
	.rdclk(iClk),
	.rdreq(res_req_fifo_rd),
	.wrclk(sub_clk_i),
	.wrreq(res_req_fifo_wr),
	.q(res_req_fifo_o),
	.rdempty(res_req_fifo_empty),
	.wrfull());
    //
    //WIDTH, DEPTH
    //
tag_fifo tag_fifo(
	.aclr(1'b0),
	.data(tag_fifo_i),
	.rdclk(iClk),
	.rdreq(tag_fifo_rd),
	.wrclk(sub_clk_i),
	.wrreq(tag_fifo_wr),
	.q(tag_fifo_o),
	.rdempty(tag_fifo_empty),
	.wrfull(tag_fifo_full)
    //
    //
    );
    //
    //(2) TEXT, HASH
    //
    always_comb begin
        if(sub_bdo_vld_i & (sub_bdo_type_i != D_TAG)) begin
            //text_fifo_i
           if(sub_bdo_vld_byte_i == 4'hf) 
                text_fifo_i = {sub_bdo_last_i, sub_bdo_i};
           else if(sub_bdo_vld_byte_i == 4'hE)
                text_fifo_i = {sub_bdo_last_i, sub_bdo_i[31:08], 8'd0};
           else if(sub_bdo_vld_byte_i == 4'hC)
                text_fifo_i = {sub_bdo_last_i, sub_bdo_i[31:16], 16'd0};
           else if(sub_bdo_vld_byte_i == 4'h8)
                text_fifo_i = {sub_bdo_last_i, sub_bdo_i[31:24], 24'd0};
           else 
                text_fifo_i = 33'd0;
        end
        else begin
            text_fifo_i = 33'd0;
        end
    end
    //
    //
	assign text_bdo_vld = sub_bdo_vld_i & (sub_bdo_type_i != D_TAG);
    assign text_fifo_wr = text_bdo_vld & ~text_fifo_full;
    assign text_fifo_rd = text_fetch_i & ~text_fifo_empty;
    //
    //WIDTH, DEPTH
    //
text_fifo text_fifo(
	.aclr(1'b0),
	.data(text_fifo_i),
	.rdclk(iClk),
	.rdreq(text_fifo_rd),
	.wrclk(sub_clk_i),
	.wrreq(text_fifo_wr),
	.q(text_fifo_o),
	.rdempty(text_fifo_empty),
	.wrfull(text_fifo_full)
    //
    //
    );
    //
    //
endmodule