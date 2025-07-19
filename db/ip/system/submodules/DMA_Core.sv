//
//MULTI-FUNCTION DMAC
//
module DMA_Core (
	//	Global signals
	input	logic					iClk,
	input	logic					iRstn,
		
	//	Configuration
	input	logic					iChipSelect_Control,
	input	logic					iWrite_Control,
	input	logic					iRead_Control,
	input	logic		[01:0]		iAddress_Control,
	input	logic		[31:0]		iData_Control,
	output	logic		[31:0]		oData_Control,
	// Master Read
	output	logic		[31:0]		oAddress_Master_Read,
	output	logic					oRead_Master_Read,
	input	logic					iDataValid_Master_Read,
	input	logic					iWait_Master_Read,
	input	logic		[31:0]		iReadData_Master_Read,
	// Master write
	output	logic		[31:0]		oAddress_Master_Write,
	output	logic		[31:0]		oData_Master_Write,
	output	logic					oWrite_Master_Write,
	input	logic					iWait_Master_Write, 
	//
    //(1) dma to sub
    //
    output logic          sub_clk_o,
    output logic          sub_rstn_o,
    output logic          sub_key_vld_o,
    output logic          sub_key_last_o,
    output logic [31:0]   sub_key_o,
    output logic          sub_bdi_vld_o,
    output logic          sub_bdi_last_o,
    output logic [2:0]    sub_bdi_type_o,
    output logic [3:0]    sub_bdi_vld_byte_o,
    output logic [31:0]   sub_bdi_o,
    output logic          sub_eoi_o,
    //
    //(2) sub to dma
    //
	output logic 		  sub_bdo_rdy_o,
    input logic           sub_key_rdy_i,
    input logic           sub_bdi_rdy_i, //
    input logic           sub_bdo_vld_i,
    input logic           sub_bdo_last_i,
    input logic [2:0]     sub_bdo_type_i,
    input logic [3:0]     sub_bdo_vld_byte_i,
    input logic [31:0]    sub_bdo_i, //
    //
    input logic           sub_auth_vld_i,
    input logic           sub_tag_match_i,
    input logic           sub_done_i,
    input logic           sub_rdy_i
);

//
//internal
//
logic done_trigger, start, start_trigger;
logic [31:0] s_addr;
logic [31:0] end_addr_write;
logic [15:0] tag_fail_nums;
//
//
//
host_register u_host_reg(
    //
	//	Global signals
	.iClk(iClk),
	.iRstn(iRstn),
	//	Configuration
	.iChipSelect_Control(iChipSelect_Control),
	.iWrite_Control(iWrite_Control),
	.iRead_Control(iRead_Control),
	.iAddress_Control(iAddress_Control),
	.iData_Control(iData_Control),
	.oData_Control(oData_Control),
    //
    //status signals
    //
    .done_trigger_i(done_trigger),
    .tag_fail_nums_i(tag_fail_nums),
    .end_addr_write_i(end_addr_write),
    //
    .sub_clk_o(sub_clk_o),
    .sub_rstn_o(sub_rstn_o),
    .start_o(start),
    .start_trigger_o(start_trigger),
    .s_addr_o(s_addr)   
	//
    //
);
//
//
control_unit ctrl_unit(
    .iClk(iClk),
    .iRstn(iRstn),
    .sub_clk_i(sub_clk_o),
    .sub_rstn_i(sub_rstn_o),
	//
    //trigger
    //
    .start_i(start),
    .start_trigger_i(start_trigger),
    .s_addr_i(s_addr),
    //
    //DMA MASTER READ signals
    //
	.oAddress_Master_Read(oAddress_Master_Read),
	.oRead_Master_Read(oRead_Master_Read),
	.iDataValid_Master_Read(iDataValid_Master_Read),
	.iWait_Master_Read(iWait_Master_Read),
	.iReadData_Master_Read(iReadData_Master_Read),
    //
    //DMA MASTER WRITE signals
    //
	.oAddress_Master_Write(oAddress_Master_Write),
	.oData_Master_Write(oData_Master_Write),
	.oWrite_Master_Write(oWrite_Master_Write),
	.iWait_Master_Write(iWait_Master_Write), 
	//
    //sub signals
    //(1) dma to sub
    //
    .sub_key_vld_o(sub_key_vld_o),
    .sub_key_last_o(sub_key_last_o),
    .sub_key_o(sub_key_o),
    .sub_bdi_vld_o(sub_bdi_vld_o),
    .sub_bdi_last_o(sub_bdi_last_o),
    .sub_bdi_type_o(sub_bdi_type_o),
    .sub_bdi_vld_byte_o(sub_bdi_vld_byte_o),
    .sub_eoi_o(sub_eoi_o),
    .sub_bdi_o(sub_bdi_o),
    //
    //(2) sub to dma
    //
    .sub_auth_vld_i(sub_auth_vld_i),
    .sub_tag_match_i(sub_tag_match_i),
    .sub_bdo_vld_i(sub_bdo_vld_i),
    .sub_bdo_last_i(sub_bdo_last_i),
    .sub_bdo_type_i(sub_bdo_type_i),
    .sub_bdo_vld_byte_i(sub_bdo_vld_byte_i),
    .sub_bdo_i(sub_bdo_i), //
    //
    .sub_done_i(sub_done_i),
    .sub_rdy_i(sub_rdy_i),
    .sub_key_rdy_i(sub_key_rdy_i),
    .sub_bdi_rdy_i(sub_bdi_rdy_i),
	 .sub_bdo_rdy_o(sub_bdo_rdy_o),
    //
    //status signals
    //
    .tag_fail_nums_o(tag_fail_nums),
    .end_addr_write_o(end_addr_write),
    .done_trigger_o(done_trigger)
    //
    //
);
endmodule