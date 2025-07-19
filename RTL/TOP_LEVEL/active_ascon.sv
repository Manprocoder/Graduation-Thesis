//**************************************************************************************
//file: active_ascon.sv
//module: active_ascon module
//sub module: DMAC module, ascon_top module (2 ascon_core instances)
//des: --- this module support 5 modes ASCON
//     --- DMA read data from mem, then format them before passing all down to ascon_top
//     --- DMA write output of ascon back to mem
//     --- this system uses AVALON protocol
//***************************************************************************************

module active_ascon #(
    parameter ROUNDS_PER_CYCLE0 = 3, //serve for the rest modes
    parameter ROUNDS_PER_CYCLE1 = 2  //ASCON_128A
)
(
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
	input	logic					iWait_Master_Write
    //
    //
);

    //
    //INTERNALS
    //
    logic ascon_key_vld, ascon_key_last;
    logic [31:0] ascon_key;
    logic ascon_bdi_vld, ascon_bdi_last;
    logic [2:0] ascon_bdi_type;
    logic [3:0] ascon_bdi_vld_byte;
    logic [31:0] ascon_bdi;
    //
    logic ascon_key_rdy, ascon_bdi_rdy;
    logic ascon_bdo_vld;
	logic ascon_bdo_last;
    logic [2:0] ascon_bdo_type;
    logic [3:0] ascon_bdo_vld_byte;
    logic [31:0] ascon_bdo;
    logic ascon_auth_vld;
    logic ascon_tag_match;
    logic ascon_rdy;
    logic ascon_done;
    logic sub_clk;
    logic sub_rstn;
    logic ascon_eoi;
	 logic ascon_bdo_rdy;
    //
    // DMAC CORE
    //

DMA_Core dmac_core(
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
	// Master Read
	.oAddress_Master_Read(oAddress_Master_Read),
	.oRead_Master_Read(oRead_Master_Read),
	.iDataValid_Master_Read(iDataValid_Master_Read),
	.iWait_Master_Read(iWait_Master_Read),
	.iReadData_Master_Read(iReadData_Master_Read),
	// Master write
	.oAddress_Master_Write(oAddress_Master_Write),
	.oData_Master_Write(oData_Master_Write),
	.oWrite_Master_Write(oWrite_Master_Write),
	.iWait_Master_Write(iWait_Master_Write), 
    //
    //(1) dma to sub
    //
    .sub_clk_o(sub_clk),
    .sub_rstn_o(sub_rstn),
    .sub_key_vld_o(ascon_key_vld),
    .sub_key_last_o(ascon_key_last),
    .sub_key_o(ascon_key),
    .sub_bdi_vld_o(ascon_bdi_vld),
    .sub_bdi_last_o(ascon_bdi_last),
    .sub_bdi_type_o(ascon_bdi_type),
    .sub_bdi_vld_byte_o(ascon_bdi_vld_byte),
    .sub_bdi_o(ascon_bdi), //39 bits
    .sub_eoi_o(ascon_eoi),
    //
    //(2) sub to dma
    //
    .sub_key_rdy_i(ascon_key_rdy),
    .sub_bdi_rdy_i(ascon_bdi_rdy), //
    .sub_bdo_vld_i(ascon_bdo_vld),
    .sub_bdo_last_i(ascon_bdo_last),
    .sub_bdo_type_i(ascon_bdo_type),
    .sub_bdo_vld_byte_i(ascon_bdo_vld_byte),
    .sub_bdo_i(ascon_bdo),
	.sub_bdo_rdy_o(ascon_bdo_rdy),
    //
    .sub_auth_vld_i(ascon_auth_vld),
    .sub_tag_match_i(ascon_tag_match),
    .sub_rdy_i(ascon_rdy),
    .sub_done_i(ascon_done)
    //
    //

);
//
// ASCON_TOP__2 instances
//

ascon_top #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) ascon_core(
    //global signals
    .clk_i(sub_clk),
    .rst_n_i(sub_rstn),
    //key
    .key_valid_i(ascon_key_vld), 
    .key_last_i(ascon_key_last),
    .key_i(ascon_key),
    //
    .bd_valid_i(ascon_bdi_vld),
    .bd_last_i(ascon_bdi_last),
    .bd_type_i(ascon_bdi_type),
    .bd_vld_byte_i(ascon_bdi_vld_byte),
	.eoi_i(ascon_eoi),
    .bd_i(ascon_bdi),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], mode[4:2], dec, hash}
    //
	.bdo_ready_i(ascon_bdo_rdy),
    .key_ready_o(ascon_key_rdy),
    .bdi_ready_o(ascon_bdi_rdy),
    .bd_valid_o(ascon_bdo_vld),
    .bd_last_o(ascon_bdo_last),
    .bd_type_o(ascon_bdo_type),
    .bd_vld_byte_o(ascon_bdo_vld_byte),
    .bd_o(ascon_bdo),
    //authentication signal
    .auth_valid_o(ascon_auth_vld),
    .tag_match_o(ascon_tag_match),
    //
	.ready_o(ascon_rdy),
    .done_o(ascon_done) 
    //
    //
);

//
//1 instance
//
/*
ascon_core #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) ascon_core(
    //global signals
    .clk_i(sub_clk),
    .rst_n_i(sub_rstn),
    //key
    .key_valid_i(ascon_key_vld), 
    .key_last_i(ascon_key_last),
    .key_i(ascon_key),
    //
    .bd_valid_i(ascon_bdi_vld),
    .bd_last_i(ascon_bdi_last),
    .bd_type_i(ascon_bdi_type),
    .bd_vld_byte_i(ascon_bdi_vld_byte),
	.eoi_i(ascon_eoi),
    .bd_i(ascon_bdi),
	 .bdo_ready_i(ascon_bdo_rdy),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], mode[4:2], dec, hash}
    //
    .key_ready_o(ascon_key_rdy),
    .bdi_ready_o(ascon_bdi_rdy),
    .bd_valid_o(ascon_bdo_vld),
    .bd_last_o(ascon_bdo_last),
    .bd_type_o(ascon_bdo_type),
    .bd_vld_byte_o(ascon_bdo_vld_byte),
    .bd_o(ascon_bdo),
    //authentication signal
    .auth_valid_o(ascon_auth_vld),
    .tag_match_o(ascon_tag_match),
    //
	.ready_o(ascon_rdy),
    .done_o(ascon_done) 
    //
    //
);
//
//3 instances
//
ascon_top3 #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) ascon_core(
    //global signals
    .clk_i(sub_clk),
    .rst_n_i(sub_rstn),
    //key
    .key_valid_i(ascon_key_vld), 
    .key_last_i(ascon_key_last),
    .key_i(ascon_key),
    //
    .bd_valid_i(ascon_bdi_vld),
    .bd_last_i(ascon_bdi_last),
    .bd_type_i(ascon_bdi_type),
    .bd_vld_byte_i(ascon_bdi_vld_byte),
	.eoi_i(ascon_eoi),
    .bd_i(ascon_bdi),
	 .bdo_ready_i(ascon_bdo_rdy),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], mode[4:2], dec, hash}
    //
    .key_ready_o(ascon_key_rdy),
    .bdi_ready_o(ascon_bdi_rdy),
    .bd_valid_o(ascon_bdo_vld),
    .bd_last_o(ascon_bdo_last),
    .bd_type_o(ascon_bdo_type),
    .bd_vld_byte_o(ascon_bdo_vld_byte),
    .bd_o(ascon_bdo),
    //authentication signal
    .auth_valid_o(ascon_auth_vld),
    .tag_match_o(ascon_tag_match),
    //
	 .ready_o(ascon_rdy),
    .done_o(ascon_done) 
    //
    //
);
*/

//
//4 instances
//
/*
ascon_top4 #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) ascon_core(
    //global signals
    .clk_i(sub_clk),
    .rst_n_i(sub_rstn),
    //key
    .key_valid_i(ascon_key_vld), 
    .key_last_i(ascon_key_last),
    .key_i(ascon_key),
    //
    .bd_valid_i(ascon_bdi_vld),
    .bd_last_i(ascon_bdi_last),
    .bd_type_i(ascon_bdi_type),
    .bd_vld_byte_i(ascon_bdi_vld_byte),
	.eoi_i(ascon_eoi),
    .bd_i(ascon_bdi),
	 .bdo_ready_i(ascon_bdo_rdy),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], mode[4:2], dec, hash}
    //
    .key_ready_o(ascon_key_rdy),
    .bdi_ready_o(ascon_bdi_rdy),
    .bd_valid_o(ascon_bdo_vld),
    .bd_last_o(ascon_bdo_last),
    .bd_type_o(ascon_bdo_type),
    .bd_vld_byte_o(ascon_bdo_vld_byte),
    .bd_o(ascon_bdo),
    //authentication signal
    .auth_valid_o(ascon_auth_vld),
    .tag_match_o(ascon_tag_match),
    //
	 .ready_o(ascon_rdy),
    .done_o(ascon_done) 
    //
    //
);
*/

//
endmodule