//
//
//
module ascon_top3 #(
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
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], reserved(3 bits), mode[4:2], dec, hash}
    //
	input logic 	    bdo_ready_i,
	 //
    output logic        key_ready_o,
    output logic        bdi_ready_o,
    output logic        bd_last_o,
    output logic        bd_valid_o,
    output logic [ 2:0] bd_type_o,
    output logic [ 3:0] bd_vld_byte_o,
    output logic [31:0] bd_o,
    //authentication signal
    output logic        auth_valid_o,
    output logic        tag_match_o,
    //
	 output logic 	      ready_o,
    output logic        done_o 
	 //
	 //
);
//
//INTERNALS
//
//DUT0_IN SIGNALS
logic bdi_vld0, key_vld0, key_rdy0;
logic bd_rdy0;
logic rdy0;
logic auth_vld0, tag_match0, done0;
logic bdo_vld0;
logic bdo_last0;
logic [2:0] bdo_type0;
logic [3:0] bdo_vld_byte0;
logic [31:0] bdo0;
logic dut0_fifo_rd, dut0_fifo_wr;
logic empty0, full0;
logic [42:0] dut0_fifo_i, dut0_fifo_o;
logic start0;
logic wait_dut0_trigger;
logic enable0;
logic dut0_ctrl;

//DUT1_IN SIGNALS
logic bdi_vld1, key_vld1, key_rdy1;
logic bd_rdy1;
logic rdy1;
logic auth_vld1, tag_match1, done1;
logic bdo_vld1;
logic bdo_last1;
logic [2:0] bdo_type1;
logic [3:0] bdo_vld_byte1;
logic [31:0] bdo1;
logic dut1_fifo_rd, dut1_fifo_wr;
logic empty1, full1;
logic [42:0] dut1_fifo_i, dut1_fifo_o;
logic start1;
logic wait_dut1_trigger;
logic enable1;
logic dut1_ctrl;
//DUT2_IN SIGNALS
logic bdi_vld2, bd_rdy2;
logic key_vld2, key_rdy2;
logic rdy2;
logic auth_vld2, tag_match2, done2;
logic bdo_vld2;
logic bdo_last2;
logic [2:0] bdo_type2;
logic [3:0] bdo_vld_byte2;
logic [31:0] bdo2;
logic dut2_fifo_rd, dut2_fifo_wr;
logic empty2, full2;
logic [42:0] dut2_fifo_i, dut2_fifo_o;
logic start2;
logic wait_dut2_trigger;
logic enable2;
logic dut2_ctrl;
//COMMON SIGNALS
logic eoi_rs_edge;
logic trigger_cnt;
logic [1:0] out_cnt; //control dut fifo output
//***************************************************************
//-----------------------------IN STAGE-----------------------------
//***************************************************************
//(1)
typedef enum logic [1:0] {DUT0_IN, DUT1_IN, DUT2_IN} in_state;
in_state in_cs, in_ns;
//
always_ff @(posedge clk_i or negedge rst_n_i) begin
    if(~rst_n_i) in_cs <= DUT0_IN;
    else in_cs <= in_ns;
end
//
always_comb begin
    in_ns = in_cs;
	key_ready_o = 1'b0;
	bdi_ready_o = 1'b0;
    bdi_vld0 = 1'b0;
    bdi_vld1 = 1'b0;
    bdi_vld2 = 1'b0;
    key_vld0 = 1'b0;
    key_vld1 = 1'b0;
    key_vld2 = 1'b0;
    start0 = 1'b0;
    start1 = 1'b0;
    start2 = 1'b0;
    wait_dut0_trigger = 1'b0;
    wait_dut1_trigger = 1'b0;
    wait_dut2_trigger = 1'b0;
    //
    case (in_cs)
        DUT0_IN: begin
			key_ready_o = key_rdy0;
			bdi_ready_o = bd_rdy0;
            bdi_vld0 = bd_valid_i;
            key_vld0 = key_valid_i;
            start0 = eoi_rs_edge;
            //
            if(eoi_rs_edge) begin
                //
                if(~rdy0) wait_dut0_trigger = 1'b1;
                else wait_dut0_trigger = 1'b0;
                //
                in_ns = DUT1_IN;
               //
            end
            else in_ns = DUT0_IN;
        end
        DUT1_IN: begin
			key_ready_o = key_rdy1;
			bdi_ready_o = bd_rdy1;
            bdi_vld1 = bd_valid_i;
            key_vld1 = key_valid_i;
            start1 = eoi_rs_edge;
            //
            if(eoi_rs_edge) begin
                //
                if(~rdy1) wait_dut1_trigger = 1'b1;
                else wait_dut1_trigger = 1'b0;
                //
                in_ns = DUT2_IN;
                //
            end
            else in_ns = DUT1_IN;
            //
        end
        DUT2_IN: begin
			key_ready_o = key_rdy2;
			bdi_ready_o = bd_rdy2;
            bdi_vld2 = bd_valid_i;
            key_vld2 = key_valid_i;
            start2 = eoi_rs_edge;
            //
            if(eoi_rs_edge) begin
                //
                if(~rdy2) wait_dut2_trigger = 1'b1;
                else wait_dut2_trigger = 1'b0;
                //
                in_ns = DUT0_IN;
                //
            end
            else in_ns = DUT2_IN;
            //
        end
        default: begin
            in_ns = in_cs;
            key_ready_o = 1'b0;
            bdi_ready_o = 1'b0;
            bdi_vld0 = 1'b0;
            bdi_vld1 = 1'b0;
            bdi_vld2 = 1'b0;
            key_vld0 = 1'b0;
            key_vld1 = 1'b0;
            key_vld2 = 1'b0;
            start0 = 1'b0;
            start1 = 1'b0;
            start2 = 1'b0;
            wait_dut0_trigger = 1'b0;
            wait_dut1_trigger = 1'b0;
            wait_dut2_trigger = 1'b0;
            //
        end
        //
        //
    endcase
end
//*****************************************************************************
//--------------------------------DUT CONTROL------------------------------
//*****************************************************************************
//
//dut0
//details: [0]: high if dut0 is busy and need dut1's assistance, and vice versa
//[1]: data in fifo is available
//
always_ff@(posedge clk_i, negedge rst_n_i) begin
    if(~rst_n_i) dut0_ctrl <= 1'b0;
    else if(wait_dut0_trigger) begin
        dut0_ctrl <= 1'b1;
    end
    else if(dut0_ctrl & rdy0) begin
        dut0_ctrl <= 1'b0;
    end
end
//
assign enable0 = start0 | dut0_ctrl;
//
//dut1
//
always_ff@(posedge clk_i, negedge rst_n_i) begin
    if(~rst_n_i) dut1_ctrl <= 1'b0;
    else if(wait_dut1_trigger) begin
        dut1_ctrl <= 1'b1;
    end
    else if(dut1_ctrl & rdy1) begin
        dut1_ctrl <= 1'b0;
    end
end
//
assign enable1 = start1 | dut1_ctrl;
//
//dut2
//
always_ff@(posedge clk_i, negedge rst_n_i) begin
    if(~rst_n_i) dut2_ctrl <= 1'b0;
    else if(wait_dut2_trigger) begin
        dut2_ctrl <= 1'b1;
    end
    else if(dut2_ctrl & rdy2) begin
        dut2_ctrl <= 1'b0;
    end
end
//
assign enable2 = start2 | dut2_ctrl;
//
//****************************************************************
//------------------------OUT STATE----------------------------
//****************************************************************
typedef enum logic [1:0] {FIFO_RD, DUT0_OUT, DUT1_OUT, DUT2_OUT} out_state;
out_state out_cs, out_ns;
//
assign ready_o = rdy0 | rdy1 | rdy2;
//state reg
always_ff@(posedge clk_i, negedge rst_n_i) begin
    if(~rst_n_i) out_cs <= FIFO_RD;
    else out_cs <= out_ns;
end

//
//counter to track dut turn
//
always_ff@(posedge clk_i, negedge rst_n_i) begin
    if(~rst_n_i) out_cnt <= 2'd0;
    else if(out_cnt == 2 & trigger_cnt) begin
        out_cnt <= 2'd0;
    end
    else if(trigger_cnt) begin
        out_cnt <= out_cnt + 1'd1;
    end
end
//
//
always_comb begin
    dut0_fifo_rd = 1'b0;
    dut1_fifo_rd = 1'b0;
    dut2_fifo_rd = 1'b0;
	bd_valid_o = 1'b0;
    bd_last_o = 1'b0;
	bd_type_o = 3'd0;
	bd_vld_byte_o = 4'h0;
	bd_o = 32'd0;
	done_o = 1'b0;
	tag_match_o = 1'b0;
	auth_valid_o = 1'b0;
	trigger_cnt = 1'b0;
    //
    //
    case(out_cs)
        FIFO_RD: begin
				//
				//access fifo
				//
                if(out_cnt == 0) begin
                    if(~empty0) begin
                        dut0_fifo_rd = 1'b1;
                        out_ns = DUT0_OUT;
                    end
                    else begin
                        dut0_fifo_rd = 1'b0;
                        out_ns = FIFO_RD;
                    end
                end
				else if(out_cnt == 1) begin
                        if(~empty1) begin
                            dut1_fifo_rd = 1'b1;
                            out_ns = DUT1_OUT;
                        end
                        else begin
                            dut1_fifo_rd = 1'b0;
                            out_ns = FIFO_RD;
                        end
                    end
                else if(out_cnt == 2) begin
                    if(~empty2) begin
                        dut2_fifo_rd = 1'b1;
                        out_ns = DUT2_OUT;
                    end
                    else begin
                        dut2_fifo_rd = 1'b0;
                        out_ns = FIFO_RD;
                    end
                end
                else begin
                    dut0_fifo_rd = 1'b0;
                    dut1_fifo_rd = 1'b0;
                    dut2_fifo_rd = 1'b0;
                    out_ns = FIFO_RD;
                    //
				end
                //
				//
        end
        DUT0_OUT: begin
            bd_valid_o = ~dut0_fifo_o[42];// & bd_vld_reg;
            bd_last_o = dut0_fifo_o[39];
            bd_type_o = dut0_fifo_o[38:36];
            bd_vld_byte_o = dut0_fifo_o[35:32];
            bd_o = dut0_fifo_o[31:0];
            //change state
            if(bdo_ready_i) begin
                out_ns = FIFO_RD; 
                //
                if(dut0_fifo_o[40]) begin
                    done_o = 1'b1;
                    trigger_cnt = 1'b1;
                end
                else if(dut0_fifo_o[42]) begin
                    auth_valid_o = 1'b1;
                    //
                    if(dut0_fifo_o[41]) begin
                        tag_match_o = 1'b1;
                        trigger_cnt = 1'b0;
                    end
                    else begin
                        tag_match_o = 1'b0;
                        trigger_cnt = 1'b1;
                    end
                    //
                end
                else begin
                    done_o = 1'b0;
                    auth_valid_o = 1'b0;
                    tag_match_o = 1'b0;
                    trigger_cnt = 1'b0;
                end
                //
                //
            end
            else out_ns = DUT0_OUT;
            //
        end
            //
        DUT1_OUT: begin
            bd_valid_o = ~dut1_fifo_o[42];
            bd_last_o = dut1_fifo_o[39];
            bd_type_o = dut1_fifo_o[38:36];
            bd_vld_byte_o = dut1_fifo_o[35:32];
            bd_o = dut1_fifo_o[31:0];
            //change state
            if(bdo_ready_i) begin
                out_ns = FIFO_RD; 
                //
                if(dut1_fifo_o[40]) begin
                    done_o = 1'b1;
                    trigger_cnt = 1'b1;
                end
                else if(dut1_fifo_o[42]) begin
                    auth_valid_o = 1'b1;
                    //
                    if(dut1_fifo_o[41]) begin
                        tag_match_o = 1'b1;
                        trigger_cnt = 1'b0;
                    end
                    else begin
                        tag_match_o = 1'b0;
                        trigger_cnt = 1'b1;
                    end
                    //
                end
                else begin
                    done_o = 1'b0;
                    auth_valid_o = 1'b0;
                    tag_match_o = 1'b0;
                    trigger_cnt = 1'b0;
                end
                //
                //
            end
            else out_ns = DUT1_OUT;
               
            //
        end
        DUT2_OUT: begin
            bd_valid_o = ~dut2_fifo_o[42];
            bd_last_o = dut2_fifo_o[39];
            bd_type_o = dut2_fifo_o[38:36];
            bd_vld_byte_o = dut2_fifo_o[35:32];
            bd_o = dut2_fifo_o[31:0];
            //
            //change state
            //
            if(bdo_ready_i) begin
                out_ns = FIFO_RD; 
                //
                if(dut2_fifo_o[40]) begin
                    done_o = 1'b1;
                    trigger_cnt = 1'b1;
                end
                else if(dut2_fifo_o[42]) begin
                    auth_valid_o = 1'b1;
                    //
                    if(dut2_fifo_o[41]) begin
                        tag_match_o = 1'b1;
                        trigger_cnt = 1'b0;
                    end
                    else begin
                        tag_match_o = 1'b0;
                        trigger_cnt = 1'b1;
                    end
                    //
                end
                else begin
                    done_o = 1'b0;
                    auth_valid_o = 1'b0;
                    tag_match_o = 1'b0;
                    trigger_cnt = 1'b0;
                end
                //
                //
            end
            else out_ns = DUT2_OUT;
            //
        end
        //
        //
    endcase
end


//************************************************************************
//------------------TWO INSTANCES TO SERVE HIGH SPEED--------------------
//************************************************************************
ascon_core #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) dut_0(
    //global signals
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    //key
    .key_valid_i(key_vld0), 
    .key_last_i(key_last_i),
    .key_i(key_i),
    //
    //
    .bd_valid_i(bdi_vld0),
    .bd_last_i(bd_last_i),
    .bd_type_i(bd_type_i),
    .bd_vld_byte_i(bd_vld_byte_i),
	.eoi_i(enable0),
    .bd_i(bd_i),
    .bdo_ready_i(~full0),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], reserved(3 bits), mode[4:2], dec, hash}
    //
    .key_ready_o(key_rdy0),
    .bdi_ready_o(bd_rdy0),
    .bd_valid_o(bdo_vld0),
    .bd_last_o(bdo_last0),
    .bd_type_o(bdo_type0),
    .bd_vld_byte_o(bdo_vld_byte0),
    .bd_o(bdo0),
    //
    //authentication signal
    //
    .auth_valid_o(auth_vld0),
    .tag_match_o(tag_match0),
    //
	.ready_o(rdy0),
    .done_o(done0) //
);
//
//
ascon_core #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) dut_1(
    //global signals
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    //key
    .key_valid_i(key_vld1), 
    .key_last_i(key_last_i),
    .key_i(key_i),
    //
    //
    .bd_valid_i(bdi_vld1),
    .bd_last_i(bd_last_i),
    .bd_type_i(bd_type_i),
    .bd_vld_byte_i(bd_vld_byte_i),
	.eoi_i(enable1),
    .bd_i(bd_i),
    .bdo_ready_i(~full1),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], reserved(3 bits), mode[4:2], dec, hash}
    //
    .key_ready_o(key_rdy1),
    .bdi_ready_o(bd_rdy1),
    .bd_valid_o(bdo_vld1),
    .bd_last_o(bdo_last1),
    .bd_type_o(bdo_type1),
    .bd_vld_byte_o(bdo_vld_byte1),
    .bd_o(bdo1),
    //
    //authentication signal
    //
    .auth_valid_o(auth_vld1),
    .tag_match_o(tag_match1),
    //
	.ready_o(rdy1),
    .done_o(done1) //
);
//
ascon_core #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) dut_2(
    //global signals
    .clk_i(clk_i),
    .rst_n_i(rst_n_i),
    //key
    .key_valid_i(key_vld2), 
    .key_last_i(key_last_i),
    .key_i(key_i),
    //
    //
    .bd_valid_i(bdi_vld2),
    .bd_last_i(bd_last_i),
    .bd_type_i(bd_type_i),
    .bd_vld_byte_i(bd_vld_byte_i),
	.eoi_i(enable2),
    .bd_i(bd_i),
    .bdo_ready_i(~full2),
    //
    //in case of config data
    //bd_i = {reserved (8 bits), ad_size[23:16], output_size[15:8], reserved(3 bits), mode[4:2], dec, hash}
    //
    .key_ready_o(key_rdy2),
    .bdi_ready_o(bd_rdy2),
    .bd_valid_o(bdo_vld2),
    .bd_last_o(bdo_last2),
    .bd_type_o(bdo_type2),
    .bd_vld_byte_o(bdo_vld_byte2),
    .bd_o(bdo2),
    //
    //authentication signal
    //
    .auth_valid_o(auth_vld2),
    .tag_match_o(tag_match2),
    //
	.ready_o(rdy2),
    .done_o(done2) 
    //
);
//
assign dut0_fifo_wr = bdo_vld0 | auth_vld0;
assign dut0_fifo_i = {auth_vld0, tag_match0, done0, bdo_last0, bdo_type0, bdo_vld_byte0, bdo0};
//
//
instance_fifo dut0_fifo(
	.aclr(1'b0),
	.clock(clk_i),
	.data(dut0_fifo_i),
	.rdreq(dut0_fifo_rd),
	.wrreq(dut0_fifo_wr),
	.empty(empty0),
	.full(full0),
	.q(dut0_fifo_o)
	//
	);
//
//
//
assign dut1_fifo_wr = bdo_vld1 | auth_vld1;
assign dut1_fifo_i = {auth_vld1, tag_match1, done1, bdo_last1, bdo_type1, bdo_vld_byte1, bdo1};
//
//
instance_fifo dut1_fifo(
	.aclr(1'b0),
	.clock(clk_i),
	.data(dut1_fifo_i),
	.rdreq(dut1_fifo_rd),
	.wrreq(dut1_fifo_wr),
	.empty(empty1),
	.full(full1),
	.q(dut1_fifo_o)
	//
	);
//
assign dut2_fifo_wr = bdo_vld2 | auth_vld2;
assign dut2_fifo_i = {auth_vld2, tag_match2, done2, bdo_last2, bdo_type2, bdo_vld_byte2, bdo2};
//
//
instance_fifo dut2_fifo(
	.aclr(1'b0),
	.clock(clk_i),
	.data(dut2_fifo_i),
	.rdreq(dut2_fifo_rd),
	.wrreq(dut2_fifo_wr),
	.empty(empty2),
	.full(full2),
	.q(dut2_fifo_o)
	//
	);
//
//
//***************************************************************
//
//***************************************************************
RiSiEdgeDetector red_eoi_i(
    .clk_i(clk_i),
    .rstn_i(rst_n_i),
    .sign_i(eoi_i),
    .red_o(eoi_rs_edge)  //
);
//
//
endmodule