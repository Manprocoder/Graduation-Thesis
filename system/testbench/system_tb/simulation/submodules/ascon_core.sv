

//************************************************************************************************
//file: ascon_core.sv
//top-module: ascon_core
//submodules: --fsm_control.sv, update_state.sv, compare.sv, counter.sv
//				  --padding function in handle_data.sv__fsm_control.sv
//description: ---This module is the top level module 
//             ---for the ascon v1.2 (AE & HASH) core
//             ---This supports 5 modes: ASCON_128, ASCON_128A, ASCON_80PQ, ASCON_HASH, ASCON_XOF
//             ---datapath: 64 bits
//	            				
//************************************************************************************************
module ascon_core #(
    parameter ROUNDS_PER_CYCLE0 = 3,
    parameter ROUNDS_PER_CYCLE1 = 2
)(
    //global signals
    input logic clk_i,
    input logic rst_n_i,
    //key
    input logic         key_valid_i, 
    input logic         key_last_i,
    input logic [31:0]  key_i,
    //
    //
    input logic         bd_valid_i,
    input logic         bd_last_i,
    input logic [ 2:0]  bd_type_i,
    input logic [ 3:0]  bd_vld_byte_i,
	input logic 		eoi_i,
    input logic [31:0]  bd_i,
    input logic         bdo_ready_i,
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], reserved(3 bits), mode[4:2], dec, hash}
    //
    output logic        key_ready_o,
    output logic        bdi_ready_o,
    output logic        bd_valid_o,
    output logic        bd_last_o,
    output logic [ 2:0] bd_type_o,
    output logic [ 3:0] bd_vld_byte_o,
    output logic [31:0] bd_o,
    //authentication signal
    output logic        auth_valid_o,
    output logic        tag_match_o,
    //
	output logic 	    ready_o,
    output logic        done_o 
    //
    //
);
    //import parameter
    import ascon_cfg::*;
    //control signals
    logic pdone;
    logic verify_tag;
    logic [10:0] control; 
    //control_o = {ascon_a, p_hash, sqz_hash_do, eot_add_key, final_ct, abs_text_do, abs_ad_do,
    //									dom_add_key, init_add_key, pdo, start};
    //counter
	logic [1:0]  abs_cnt;
    logic [3:0]  round_cnt;
    //mode signals
    logic [2:0] mode;
    //data 
    logic [159:0] key_data;
    logic [319:0] state_data;
    logic [063:0] new_state; //used for update state
	logic [127:0] nonce;
    logic [127:0] in_tag, xor_tag;
	 
    //**********************************************
    //------------------INSTANCES------------------
    //**********************************************
    //(0)
    fsm_control u0(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
		  //interface inputs
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
        .bdo_ready_i(bdo_ready_i),
        //internals inputs
        //counters module
        //
        .pdone_i(pdone),
        .abs_cnt_i(abs_cnt),
        //
        //states module
        //
        .state_i({state_data[319:256], state_data[127:0]}),  //update state reg, gen in_tag
        //
        //flag module
        .auth_valid_i(auth_valid_o),
        .tag_match_i(tag_match_o),
        //internal outputs
        //
        //to state
        //
        .run_mode_o(mode),
        .control_o(control),
	    .new_state_o(new_state),
	    .full_key_o(key_data),
	    .nonce_o(nonce),
        //
        //to flag
	    .in_tag_o(in_tag),
        .xor_tag_o(xor_tag),
        .verify_tag_o(verify_tag),
        //interface outputs
        //
        .key_ready_o(key_ready_o),
        .bdi_ready_o(bdi_ready_o),
        .bd_o(bd_o),
        .bd_valid_o(bd_valid_o),
        .bd_type_o(bd_type_o),
        .bd_last_o(bd_last_o),
        .bd_vld_byte_o(bd_vld_byte_o),
        .ready_o(ready_o), //
        .done_o(done_o) //
		  
    );

        //(1)
    counter #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) u1 (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        //
        //internal inputs
        //
        .start_i(control[0]),
        .pdo_i(control[1]),
        .ascon_a_i(control[10]),
        .sqz_hash_do_i(control[8]),
        .abs_ad_do_i(control[4]),
        .abs_text_do_i(control[5]),
        .eot_add_key_i(control[7]), //[7]
        .hash_flag_i(control[9]),
		  //
		  //internal outputs
		  //
        .pdone_o(pdone),
        .abs_cnt_o(abs_cnt),
        .round_cnt_o(round_cnt) // number of rounds per cycle
    );

    //(2)
    update_state #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) u2(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        //
        //internal inputs
        //
        .run_mode_i(mode),
        .control_i(control[7:0]),
        .new_state_i(new_state),
        .nonce_i(nonce),
        .key_reg_i(key_data),
        .round_cnt_i(round_cnt),
        .state_o(state_data) //
    );

    //(3)
    compare u3(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        //internal input
        //
	    .in_tag_i(in_tag),
        .xor_tag_i(xor_tag),
        .verify_tag_i(verify_tag),
        //
        //internal output
        //
        .auth_valid_o(auth_valid_o),
        .tag_match_o(tag_match_o) 
        //
        //
    );

endmodule
