//
//
`timescale 1ps/1ps
//
module get_data
	import ascon_cfg::*;
(
	input logic clk_i,
	input logic rst_n_i,
	//interface input
	//
	input logic [31:0]  key_i,
	input logic 		key_valid_i,
	input logic 		key_last_i,
	input logic [31:0]  bd_i,
    //in case of config data
    //{reserved (8 bits), ad_size[23:26], output_size[15:8], mode[4:2], dec, hash}
	input logic 		bd_valid_i,
	input logic [ 2:0]  bd_type_i,
	input logic 		bd_last_i,
	input logic [ 3:0]  bd_vld_byte_i,
	input logic 		eoi_i,
	//
	//internal inputs
	//
	input logic 	  almost_done_i,
	input logic 	  sqz_hash_done_i,
	input logic 	  ready_i,
	input logic 	  ad_data_req_i,
	input logic 	  text_data_req_i,
	input logic 	  idle_state_i,
	input logic 	  init_domain_i,
	input logic 	  sep_domain_i,
	input logic 	  abs_ad_state_i,
	input logic 	  abs_text_state_i,
	//
	//internal outputs
	//
	output logic 						hash_flag_o,
	output logic 						dec_flag_o,
	output logic 						run_key_vld_o, //new key avail
	output logic [2:0]					run_mode_o,
	output logic [159:0] 				run_key_o,  //run_key_reg
	output logic [127:0]        		nonce_o,
	output logic [68:0] 				run_ad_o,
	output logic [72:0] 				run_text_o,
	output logic [127:0] 				run_tag_o,  //run_tag_reg
	output logic [6:0]					ad_size_o,
	output logic [6:0]					text_bytes_o,
	output logic [6:0]					text_words_o,
	output logic [6:0]					hash_blocks_o,
	//interface outputs
	output logic 						key_ready_o,
	output logic						bdi_ready_o 
	// 
	//
);

    //**********************************************************
	//---------------------INTERNAL SIGNALS-------------------
	//**********************************************************
	logic pass_data;
	logic [6:0] ad_blocks;

	//***********************************************************
	//-------------------------GET INPUT-----------------------
	//***********************************************************
		
	get_config g0(
    	.clk_i(clk_i),
    	.rst_n_i(rst_n_i),
    //interface inputs
    //
    	.bd_valid_i(bd_valid_i),
   		.bd_type_i(bd_type_i),
    	.bd_i(bd_i),
    //internal inputs
    //	
		.eoi_i(eoi_i),
		.ready_i(ready_i),
		.almost_done_i(almost_done_i),
		.idle_state_i(idle_state_i),
    //internal outputs
    //
    	.pass_data_o(pass_data),
    	.run_mode_o(run_mode_o),
    	.hash_flag_o(hash_flag_o),
    	.dec_flag_o(dec_flag_o),
    	.ad_size_o(ad_size_o),
		.ad_blocks_o(ad_blocks),
		.text_bytes_o(text_bytes_o),
		.text_words_o(text_words_o),
		.hash_blocks_o(hash_blocks_o),
    //interface outputs
    //
    	.bdi_ready_o(bdi_ready_o)  //

);
	//
	get_key_nonce g1(
     	.clk_i(clk_i),
    	.rst_n_i(rst_n_i),
    //interface inputs
    //
    	.key_valid_i(key_valid_i),
    	.key_last_i(key_last_i),
    	.key_i(key_i),
    	.bd_valid_i(bd_valid_i),
    	.bd_type_i(bd_type_i),
    	.bd_ready_i(bdi_ready_o),
   		.bd_i(bd_i),
    	.eoi_i(eoi_i),
    //internal inputs
	//
		.almost_done_i(almost_done_i),
    	.ready_i(ready_i),
		.idle_state_i(idle_state_i),
	//
    //interface outputs
    //
    	.key_ready_o(key_ready_o),
    //internal outputs
    //
		.run_key_vld_o(run_key_vld_o),
    	.run_key_o(run_key_o), //
    	.nonce_o(nonce_o) //
	);
	//
	//
	get_ad_text g2(
    	.clk_i(clk_i),
    	.rst_n_i(rst_n_i),
    //interface inputs
    //
    	.bd_valid_i(bd_valid_i),
		.bd_last_i(bd_last_i),
    	.bd_ready_i(bdi_ready_o), //bdi_ready_o
    	.bd_type_i(bd_type_i),
    	.bd_vld_byte_i(bd_vld_byte_i),
		.bd_i(bd_i),
    //internal inputs
    //
		.ad_blocks_i(ad_blocks),
		.text_blocks_i(hash_blocks_o),
		.ad_data_req_i(ad_data_req_i),
		.text_data_req_i(text_data_req_i),
		
		.sqz_hash_done_i(sqz_hash_done_i),
		.init_domain_i(init_domain_i),
		.sep_domain_i(sep_domain_i),
		.abs_ad_state_i(abs_ad_state_i),
		.abs_text_state_i(abs_text_state_i),
	//
    //internal output
    //
    	.run_ad_o(run_ad_o),
    	.run_text_o(run_text_o) //
);

	//
	get_tag g3(
    	.clk_i(clk_i),
    	.rst_n_i(rst_n_i),
    //interface inputs
    //
    	.bd_valid_i(bd_valid_i),
    	.bd_type_i(bd_type_i),
    	.bd_ready_i(bdi_ready_o),
		.bd_i(bd_i),
    //internal inputs
	//
    	.pass_data_i(pass_data),
    //internal outputs
    //
    	.run_tag_o(run_tag_o) //
	);

		
endmodule 