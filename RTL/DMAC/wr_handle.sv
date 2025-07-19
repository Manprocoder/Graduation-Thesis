//
//
//
module wr_handle(
    //
    input logic         iClk,
    input logic         iRstn,
    input logic         sub_clk_i,
    //
    //internal inputs
    //
    input logic         start_i,
    //
    //MASTER WRITE signals
    //  
	output	logic		[31:0]		oAddress_Master_Write,
	output	logic		[31:0]		oData_Master_Write,
	output	logic					oWrite_Master_Write,
	input	logic					iWait_Master_Write, 
    //(2) sub to dma
    //
    input logic           sub_auth_vld_i,
    input logic           sub_tag_match_i,
    input logic           sub_bdo_vld_i,
    input logic           sub_bdo_last_i,
    input logic [02:0]    sub_bdo_type_i,
    input logic [03:0]    sub_bdo_vld_byte_i,
    input logic [31:0]    sub_bdo_i, 
    //
    input logic           sub_done_i,
    input logic           sub_rdy_i,
    input logic           sub_eoi_i,
	output logic 		  sub_bdo_rdy_o,
    //
    //internal inputs
    //
    input logic             wr_trigger_i,
	input logic 			wr_info_avail_i,
    input logic             ckn_ad_avail_i,
    input logic [09:0]      wr_info_i,
    input logic [31:0]      out_gap_i,
    input logic [31:0]      length_i,
    input logic [31:0]      d_addr_i,
    input logic [32:0]      ckn_data_i, 
    //internal outputs
    output logic            wr_info_req_o,
    output logic            ckn_ad_fetch_o,
    //
    //status signals
    //
    output logic [15:0]     tag_fail_nums_o,
    output logic [31:0]     end_addr_write_o,
    output logic            done_trigger_o
    //
    //
);
    //
    //internal signals
    //
    logic res_req_data;
    logic res_req_fetch;
    //logic res_req_vld;
    logic res_avail;
    logic [32:0] text_data, tag_data;
    logic text_fetch, tag_fetch;
    logic text_avail, tag_avail;
    //
    //(1)
    //
sub_to_dma sub_to_dma(
    .iClk(iClk),
    //.iRstn(iRstn),
    .sub_clk_i(sub_clk_i),
    //
    //interface inputs
    //sub to dma
    //
    .sub_done_i(sub_done_i),
    .sub_auth_vld_i(sub_auth_vld_i),
    .sub_tag_match_i(sub_tag_match_i),
    .sub_bdo_vld_i(sub_bdo_vld_i),
    .sub_bdo_last_i(sub_bdo_last_i),
    .sub_bdo_type_i(sub_bdo_type_i),
    .sub_bdo_vld_byte_i(sub_bdo_vld_byte_i),
    .sub_bdo_i(sub_bdo_i), 
    //
    //internal inputs
    //
    .res_req_fetch_i(res_req_fetch),
    .text_fetch_i(text_fetch),
    .tag_fetch_i(tag_fetch),
	 //
	 .sub_bdo_rdy_o(sub_bdo_rdy_o),
    //
    //internal outputs
    //
    .res_avail_o(res_avail),
    .tag_avail_o(tag_avail),
    .text_avail_o(text_avail),
    .res_req_data_o(res_req_data),
    .text_data_o(text_data),
    .tag_data_o(tag_data)
    //
    //
);
    //
    //(2)
    //
    wr_request wr_req(
        .iClk(iClk),
        .iRstn(iRstn),
    //MASTER WRITE SIGNALS
    .oAddress_Master_Write(oAddress_Master_Write),
    .oData_Master_Write(oData_Master_Write),
    .oWrite_Master_Write(oWrite_Master_Write),
    .iWait_Master_Write(iWait_Master_Write),
    //
    //internal inputs
    //
    .wr_trigger_i(wr_trigger_i),  //from rd_crf sub_module
	.wr_info_avail_i(wr_info_avail_i),
    .wr_info_i(wr_info_i),  //dec flag, hash flag, ckn_ad words, text_words
    .out_gap_i(out_gap_i),
    .d_addr_i(d_addr_i),
    .length_i(length_i),
    .ckn_data_i(ckn_data_i),
    .text_data_i(text_data),
    .tag_data_i(tag_data),
    .ckn_ad_avail_i(ckn_ad_avail_i),
    .text_avail_i(text_avail),
    .tag_avail_i(tag_avail),
    .res_avail_i(res_avail),
    //.res_req_vld_i(res_req_vld),
    .res_req_data_i(res_req_data),  //1: ascon done, 0: tag fail
    //
    //internal outputs
    //
    .tag_fail_nums_o(tag_fail_nums_o),
    .end_addr_write_o(end_addr_write_o),
    .wr_info_req_o(wr_info_req_o),
    .ckn_ad_fetch_o(ckn_ad_fetch_o),
    .res_req_fetch_o(res_req_fetch),
    .text_fetch_o(text_fetch),
    .tag_fetch_o(tag_fetch),
    .done_trigger_o(done_trigger_o)
    //
    //
    );
    //
    //
endmodule