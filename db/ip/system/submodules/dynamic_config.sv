//
//
//
module dynamic_config(
    input logic iClk,
    input logic iRstn,
    input logic sub_clk_i,
    input logic sub_rstn_i,
    //
    //interface inputs
    //
    input logic          iDataValid_Master_Read,
    input logic [31:0]   iReadData_Master_Read,
    //(2) ascon
    input logic          sub_rdy_i,
    input logic          sub_key_rdy_i,
    input logic          sub_bdi_rdy_i, 
    //
    //internal inputs
    //
    input logic          start_trigger_i,
    input logic  [31:0]  s_addr_i,
    input logic          mst_rd_done_i,
    input logic          wr_info_req_i,
    input logic          ckn_ad_fetch_i,
    //
    //internal outputs
    //
    output logic          out_of_capacity_o,
    output logic          frame_done_o,
    output logic          wr_trigger_o,
    output logic 		  wr_info_avail_o,
    output logic          ckn_ad_avail_o,
    output logic [09:0]   wr_info_o,
    output logic [31:0]   out_gap_o,
    output logic [31:0]   length_o,
    output logic [31:0]   d_addr_o,
    output logic [32:0]   ckn_data_o,
    //
    //interface outputs
    //dma to sub
    //
    output logic          sub_key_vld_o,
    output logic          sub_key_last_o,
    output logic [31:0]   sub_key_o,
    output logic          sub_bdi_vld_o,
    output logic          sub_bdi_last_o,
    output logic [02:0]   sub_bdi_type_o,
    output logic [03:0]   sub_bdi_vld_byte_o,
    output logic          sub_eoi_o,
    output logic [31:0]   sub_bdi_o
    //
    //
);

    //
    //internals
    //
    logic [07:0] ad_words, text_words;
    logic [3:0] ad_vld_byte, text_vld_byte;
    logic [7:0] ckn_cnt;
    logic [7:0] ckn_ad_words, ascon_din_words;
    logic [4:0] mode_d_h;
    logic get_dma_cfg;
	logic get_ckn_ad;
    logic fmt_data_trigger;
    //
    //get config data from MEM
    //
    control_register_file crf(
		//
        .iClk(iClk),
        .iRstn(iRstn),
        //
        .iDataValid_Master_Read(iDataValid_Master_Read),
        .iReadData_Master_Read(iReadData_Master_Read),
        //
        .ckn_cnt_i(ckn_cnt),
        .get_dma_cfg_i(get_dma_cfg),
		.get_ckn_ad_i(get_ckn_ad),
        .wr_info_req_i(wr_info_req_i),
        //
        //
		.wr_info_avail_o(wr_info_avail_o),
        .mode_d_h_o(mode_d_h),
        .ascon_din_words_o(ascon_din_words),
        .ckn_ad_words_o(ckn_ad_words),
        .wr_info_o(wr_info_o),
        .out_gap_o(out_gap_o),
        .length_o(length_o),
        .d_addr_o(d_addr_o),
        .ad_words_o(ad_words),
        .text_words_o(text_words),
        .ad_vld_byte_o(ad_vld_byte),
        .text_vld_byte_o(text_vld_byte) //
    //
    //
    );
    //

    //
    store_ckn_ad store_cknad(
        .iClk(iClk),
        .iRstn(iRstn),
    //
    //interface inputs
    //
        .iDataValid_Master_Read(iDataValid_Master_Read),
        .iReadData_Master_Read(iReadData_Master_Read),
    //
    //internal inputs
    //
        .store_ckn_start_i(start_trigger_i),
        .ckn_ad_fetch_i(ckn_ad_fetch_i),
        .frame_done_i(frame_done_o),
        .out_of_capacity_i(out_of_capacity_o),
        .mst_rd_done_i(mst_rd_done_i),
        .s_addr_i(s_addr_i),
        .f_hash_i(mode_d_h[0]),
        .ascon_din_words_i(ascon_din_words),
        .ckn_ad_words_i(ckn_ad_words),
    //
    //internal outputs
    //
        .wr_trigger_o(wr_trigger_o),
        .fmt_data_trigger_o(fmt_data_trigger),
        .ckn_ad_avail_o(ckn_ad_avail_o),
        .get_dma_cfg_o(get_dma_cfg),
		.get_ckn_ad_o(get_ckn_ad),
        .ckn_cnt_o(ckn_cnt),
        .ckn_data_o(ckn_data_o)

    //
    //
    );
    //  
    format_data fmt_data(
    //
    .iClk(iClk),
    .iRstn(iRstn),
    .sub_clk_i(sub_clk_i),
    .sub_rstn_i(sub_rstn_i),
    //
    //interface
    //
    .iDataValid_Master_Read(iDataValid_Master_Read),
    .iReadData_Master_Read(iReadData_Master_Read),
    //
    //(2)__ASCON 
    .sub_rdy_i(sub_rdy_i),
    .sub_key_rdy_i(sub_key_rdy_i),
    .sub_bdi_rdy_i(sub_bdi_rdy_i),
    //
    //internal inputs
    //
    .fmt_data_trigger_i(fmt_data_trigger),
    .f_mode_i(mode_d_h[4:2]),
    .f_hash_i(mode_d_h[0]),
    .f_dec_i(mode_d_h[1]),
    .ascon_din_words_i(ascon_din_words),
    .ad_words_i(ad_words),
    .text_words_i(text_words),
    .ad_vld_byte_i(ad_vld_byte),
    .text_vld_byte_i(text_vld_byte),
    .mst_rd_done_i(mst_rd_done_i),
    //
    //internal outputs
    //
    .out_of_capacity_o(out_of_capacity_o),
    .frame_done_o(frame_done_o),
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
    //
    //
    );
	 //
	 //
endmodule