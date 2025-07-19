//
//
//
module counter #(
    parameter ROUNDS_PER_CYCLE0 = 3,  //
    parameter ROUNDS_PER_CYCLE1 = 2  //
)
(
    input logic 			clk_i,
    input logic 			rst_n_i,
    //
    //internal inputs
    //
    input logic 			start_i,
    input logic 			pdo_i,
    input logic [2:0]       run_mode_i,
    input logic             sqz_hash_do_i,
    input logic 			abs_ad_do_i,
    input logic 			abs_text_do_i,
    input logic 			eot_add_key_i,
    input logic 			hash_flag_i,
    //
    //internal outputs
    //
    output logic                       last_cc_o,
    output logic       	               pdone_o,
    output logic [1:0]                 abs_cnt_o,
    output logic [3:0] 	               round_cnt_o
    // number of rounds per cycle
    //
);
    //
	import ascon_cfg::*;

    //
    //internal signals
    //
    logic rounds_a0, rounds_a1, rounds_b;
    logic abs_ad_done, abs_text_done;

    //internal assignment
    assign rounds_a0 =  start_i | eot_add_key_i;
    assign rounds_a1 = (abs_ad_done & hash_flag_i) | sqz_hash_do_i;  
    assign rounds_b = abs_ad_done | abs_text_done;

    //abs counter
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) abs_cnt_o <= '0;
        else if(rounds_b) abs_cnt_o <= '0; 
        else if(abs_ad_do_i | abs_text_do_i) begin
            abs_cnt_o <= abs_cnt_o + 1'd1;
        end
        else abs_cnt_o <= abs_cnt_o;
    end
	
    //rounds counter
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) round_cnt_o <= 4'd0;
        else if(rounds_a0 | rounds_a1) round_cnt_o <= ROUNDS_A;
        else if(rounds_b) round_cnt_o <= (run_mode_i == ASCON_128A) ? ROUNDS_B1 : ROUNDS_B0;  //mode_flag_i == ASCON_128a, rounds_b
        else if(pdo_i) begin
            round_cnt_o <= round_cnt_o - ((run_mode_i == ASCON_128A) ? ROUNDS_PER_CYCLE1 : ROUNDS_PER_CYCLE0);
        end
        else round_cnt_o <= round_cnt_o;
    end

	 //output
    assign last_cc_o = (abs_cnt_o == ((run_mode_i == ASCON_128A) ? 1'd1 : 1'd0));
	assign abs_ad_done = last_cc_o & abs_ad_do_i; //& (cs_i == ABS_AD);
    assign abs_text_done = last_cc_o & abs_text_do_i; //(cs_i == ABS_TEXT);
	assign pdone_o = pdo_i & (round_cnt_o == ((run_mode_i == ASCON_128A) ? ROUNDS_PER_CYCLE1 : ROUNDS_PER_CYCLE0));

endmodule
