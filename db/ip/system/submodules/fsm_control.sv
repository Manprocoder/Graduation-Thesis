//
//
//
module fsm_control
(
    input logic clk_i,
    input logic rst_n_i,
	 //interface inputs
	 //
	input logic [31:0]	 key_i,
    input logic 		 key_valid_i,
	input logic 		 key_last_i,
	input logic [31:0]	 bd_i,
    //in case of config data
    //{reserved (8 bits), ad_size[23:26], output_size[15:8], mode[4:2], dec, hash}
	input logic 		 bd_valid_i,
	input logic [2:0]    bd_type_i,
	input logic 		 bd_last_i,
	input logic [3:0]	 bd_vld_byte_i,
	input logic 		 eoi_i,
	input logic 		 bdo_ready_i,
	//internal inputs
	//counters
	input logic 		 last_cc_i, 
	input logic 		 pdone_i,
	input logic [1:0]	 abs_cnt_i,
	//
	//state submodule
	input logic [191:0]  state_i,
	//
	//flag submodule
	input logic 		 auth_valid_i,
	input logic 		 tag_match_i,
	//internal outputs
	//
	//to counter
	//output logic 			hash_flag_o,
	//
	//to state
	output logic [002:0]	run_mode_o,
	output logic [009:0]    control_o,
	output logic [063:0]	new_state_o,
	output logic [159:0]	full_key_o,
	output logic [127:0]    nonce_o,
	//
	//to compare submodule
	output logic [127:0]	in_tag_o,
	output logic [127:0]	xor_tag_o,
	output logic 			verify_tag_o,
	 //interface outputs
	 //	
	output logic 			key_ready_o,
	output logic 			bdi_ready_o, //
	output logic [31:0]		bd_o,
	output logic 			bd_valid_o,
	output logic [2:0]		bd_type_o,
	output logic 			bd_last_o,
	output logic [3:0]		bd_vld_byte_o,
	output logic 			ready_o,//
	output logic 		 	done_o //
	//
	//	
);
	//
	import ascon_cfg::*;
	//******************************************************
	//------------------internal signals-------------------
	//******************************************************
	logic dec_flag;
	logic run_key_vld;
	logic almost_done;
	logic hash_flag;
	logic [6:0] hash_blocks;
	logic [6:0] ad_size;
	logic [6:0] text_bytes, text_words;
	logic [68:0] ad_data;
	logic [72:0] text_data;
	logic ad_data_req, text_data_req;
	logic idle_state;
	logic sqz_hash_done_trigger;
	//**************************************
	//submodules
	//(1) pipeline
	get_data c0(
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
		//interface input
		//
		.key_i(key_i),
		.key_valid_i(key_valid_i),
		.key_last_i(key_last_i),
		.bd_i(bd_i),
		.bd_valid_i(bd_valid_i),
		.bd_type_i(bd_type_i),
		.bd_last_i(bd_last_i),
		.bd_vld_byte_i(bd_vld_byte_i),
		.eoi_i(eoi_i),
		//internal inputs
		//
		.almost_done_i(almost_done),
		.sqz_hash_done_i(sqz_hash_done_trigger),
		.ready_i(ready_o),
		.ad_data_req_i(ad_data_req),
		.text_data_req_i(text_data_req),
		.idle_state_i(idle_state),
		//.ad_stage_done_i(ad_stage_done),
		.init_domain_i(control_o[2]),
		.sep_domain_i(control_o[3]),
		.abs_ad_state_i(control_o[4]),
		.abs_text_state_i(control_o[5]),
		//
		//internal outputs
		//
		.hash_flag_o(hash_flag),
		.dec_flag_o(dec_flag),
		.run_key_vld_o(run_key_vld),
		.run_mode_o(run_mode_o),
		.run_key_o(full_key_o),  //key_reg1
		.nonce_o(nonce_o),
		.run_ad_o(ad_data),
		.run_text_o(text_data),
		.run_tag_o(in_tag_o),  //xor_tag_o1
		.ad_size_o(ad_size),
		.text_bytes_o(text_bytes),
		.text_words_o(text_words),
		.hash_blocks_o(hash_blocks),
		//interface outputs
		.key_ready_o(key_ready_o),
		.bdi_ready_o(bdi_ready_o) //
	);

	//(1)
	handle_data c1(
		//global signals
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
		//interface inputs
		//
		.eoi_i(eoi_i),
		.bdo_ready_i(bdo_ready_i),
		//internal inputs
		//
		.abs_cnt_i(abs_cnt_i),
		.auth_valid_i(auth_valid_i),
		.tag_match_i(tag_match_i),
		.state_i(state_i),
		.pdone_i(pdone_i),
		.last_cc_i(last_cc_i),
		.hash_flag_i(hash_flag),
		.dec_flag_i(dec_flag),
		.run_key_vld_i(run_key_vld),
		.run_mode_i(run_mode_o),            
		.full_key_i(full_key_o[127:0]),
		.ad_data_i(ad_data),
		.text_data_i(text_data),
		.ad_size_i(ad_size),
		.text_bytes_i(text_bytes),
		.text_words_i(text_words),
		.hash_blocks_i(hash_blocks),
		//
		//internal outputs
		//
		//to get_data module
		.almost_done_o(almost_done),
		.sqz_hash_done_trigger_o(sqz_hash_done_trigger),
		.ad_data_req_o(ad_data_req),
		.text_data_req_o(text_data_req),
		.idle_state_o(idle_state),
		//.ad_stage_done_o(ad_stage_done),
		//
		//to state
		.control_o(control_o),
		.new_state_o(new_state_o),
		//to compare submodule
		.xor_tag_o(xor_tag_o),
		.verify_tag_o(verify_tag_o),
		//
		//interface outputs
		//
		//(1)_data
		.bd_valid_o(bd_valid_o),
		.bd_last_o(bd_last_o),
		.bd_type_o(bd_type_o),
		.bd_vld_byte_o(bd_vld_byte_o),
		.bd_o(bd_o),
		//(2) done
		//
		.done_o(done_o),
		.ready_o(ready_o) 
		//
		//
	);

	
endmodule