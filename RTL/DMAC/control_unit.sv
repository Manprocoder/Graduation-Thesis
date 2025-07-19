//
//
//
module control_unit(
    input logic         iClk,
    input logic         iRstn,
    input logic         sub_clk_i,
    input logic         sub_rstn_i,
    //trigger
    //
    input logic         start_i,
    input logic         start_trigger_i,
    input logic  [31:0] s_addr_i,
    //
    //DMA MASTER READ signals
    //
	output	logic		[31:0]		oAddress_Master_Read,
	output	logic					oRead_Master_Read,
	input	logic					iDataValid_Master_Read,
	input	logic					iWait_Master_Read,
	input	logic		[31:0]		iReadData_Master_Read,
    //
    //DMA MASTER WRITE signals
    //

	output	logic		[31:0]		oAddress_Master_Write,
	output	logic		[31:0]		oData_Master_Write,
	output	logic					oWrite_Master_Write,
	input	logic					iWait_Master_Write, 
    //sub signals
    //
    //(1) dma to sub
    //
    output logic          sub_key_vld_o,
    output logic          sub_key_last_o,
    output logic [31:0]   sub_key_o,
    output logic          sub_bdi_vld_o,
    output logic          sub_bdi_last_o,
    output logic [2:0]    sub_bdi_type_o,
    output logic [3:0]    sub_bdi_vld_byte_o,
    output logic          sub_eoi_o,
    output logic [31:0]   sub_bdi_o,
    //
    //(2) sub to dma
    //
    input logic           sub_auth_vld_i,
    input logic           sub_tag_match_i,
    input logic           sub_bdo_vld_i,
    input logic           sub_bdo_last_i,
    input logic [2:0]     sub_bdo_type_i,
    input logic [3:0]     sub_bdo_vld_byte_i,
    input logic [31:0]    sub_bdo_i, //
    //
    input logic           sub_done_i,
    input logic           sub_rdy_i,
    input logic           sub_key_rdy_i,
    input logic           sub_bdi_rdy_i, //
	output logic 		  sub_bdo_rdy_o,
    //
    //status signals
    //
    output logic [15:0]   tag_fail_nums_o,
    output logic [31:0]   end_addr_write_o,
    output logic          done_trigger_o
    //
    //
);

    //
    //internals
    //
    logic [31:0] out_gap;
    logic [31:0] length;
    logic [31:0] d_addr;
    logic [32:0] ckn_data;
    logic [09:0] wr_info;
    logic wr_info_req;
    logic ckn_ad_fetch;
    logic ckn_ad_avail;
    logic mst_rd_done;
    logic out_of_capacity;
    logic wr_trigger;
    logic wr_info_avail;
    logic frame_done;
    //
    rd_request rd_req(
    .iClk(iClk),
    .iRstn(iRstn),
    //
    //internal inputs
    //
    .start_trigger_i(start_trigger_i),
    .out_of_capacity_i(out_of_capacity),
    .frame_done_i(frame_done),
    .s_addr_i(s_addr_i),
    .length_i(length),
    //
    //interface
    //
	.oAddress_Master_Read(oAddress_Master_Read),
	.oRead_Master_Read(oRead_Master_Read),
	.iWait_Master_Read(iWait_Master_Read),
    //
    //internal outputs
    //
    .mst_rd_done_o(mst_rd_done)
    //
    //
    );
    //
    //
    dynamic_config dyn_cfg(

    .iClk(iClk),
    .iRstn(iRstn),
    .sub_clk_i(sub_clk_i),
    .sub_rstn_i(sub_rstn_i),
    //
    //interface inputs
    //MASTER READ
	.iDataValid_Master_Read(iDataValid_Master_Read),
	.iReadData_Master_Read(iReadData_Master_Read),
    //
    //(2) ascon
    .sub_rdy_i(sub_rdy_i),
    .sub_key_rdy_i(sub_key_rdy_i),
    .sub_bdi_rdy_i(sub_bdi_rdy_i), //
    //
    //internal inputs
    //
	.start_trigger_i(start_trigger_i),
    .s_addr_i(s_addr_i),
    .mst_rd_done_i(mst_rd_done),
    .wr_info_req_i(wr_info_req),
    .ckn_ad_fetch_i(ckn_ad_fetch),
    //
    //internal outputs
    //
    .out_of_capacity_o(out_of_capacity),
    .frame_done_o(frame_done),
    .wr_trigger_o(wr_trigger),
	.wr_info_avail_o(wr_info_avail),
    .ckn_ad_avail_o(ckn_ad_avail),
    .wr_info_o(wr_info),
    .out_gap_o(out_gap),
    .length_o(length),
    .d_addr_o(d_addr),
    .ckn_data_o(ckn_data), //last flag, data
    //
    //interface outputs
    //(2) dma to sub
    //
    .sub_key_vld_o(sub_key_vld_o),
    .sub_key_last_o(sub_key_last_o),
    .sub_key_o(sub_key_o),
    .sub_bdi_vld_o(sub_bdi_vld_o),
    .sub_bdi_last_o(sub_bdi_last_o),
    .sub_bdi_type_o(sub_bdi_type_o),
    .sub_bdi_vld_byte_o(sub_bdi_vld_byte_o),
    .sub_eoi_o(sub_eoi_o),
    .sub_bdi_o(sub_bdi_o)
    );

    wr_handle wr_hdl(
    //
    .iClk(iClk),
    .iRstn(iRstn),
    .sub_clk_i(sub_clk_i),
    //
    //internal inputs
    //
    .start_i(start_i),
    //
    //DMA MASTER WRITE signals
    //
	.oAddress_Master_Write(oAddress_Master_Write),
	.oData_Master_Write(oData_Master_Write),
	.oWrite_Master_Write(oWrite_Master_Write),
	.iWait_Master_Write(iWait_Master_Write), 
    //  
    //(2) sub to dma
    //
    .sub_auth_vld_i(sub_auth_vld_i),
    .sub_tag_match_i(sub_tag_match_i),
    .sub_bdo_vld_i(sub_bdo_vld_i),
    .sub_bdo_last_i(sub_bdo_last_i),
    .sub_bdo_type_i(sub_bdo_type_i),
    .sub_bdo_vld_byte_i(sub_bdo_vld_byte_i),
    .sub_bdo_i(sub_bdo_i), 
    //
    .sub_eoi_i(sub_eoi_o),
    .sub_rdy_i(sub_rdy_i),
    .sub_done_i(sub_done_i),
	 .sub_bdo_rdy_o(sub_bdo_rdy_o),
    //
    //internal inputs
    //
    .wr_trigger_i(wr_trigger),
	.wr_info_avail_i(wr_info_avail),
    .ckn_ad_avail_i(ckn_ad_avail),
    .wr_info_i(wr_info),
    .out_gap_i(out_gap),
    .length_i(length),
    .d_addr_i(d_addr),
    .ckn_data_i(ckn_data), //last flag, data
    //internal outputs
    .wr_info_req_o(wr_info_req),
    .ckn_ad_fetch_o(ckn_ad_fetch),
    //
    //status signals
    //
    .tag_fail_nums_o(tag_fail_nums_o),
    .end_addr_write_o(end_addr_write_o),
    .done_trigger_o(done_trigger_o)
    //
    //
    );
    //
    //
endmodule