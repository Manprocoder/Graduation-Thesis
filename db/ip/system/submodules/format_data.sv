//
//
//
module format_data
//
import ascon_cfg::*;
(
    //
    input logic          iClk,
    input logic          iRstn,
    input logic          sub_clk_i,
    input logic          sub_rstn_i,
    //interface inputs
    //(1)__MASTER READ
    input logic          iDataValid_Master_Read,
    input logic   [31:0] iReadData_Master_Read, 
    //(2)__ASCON 

    input logic           sub_rdy_i,
    input logic           sub_key_rdy_i,
    input logic           sub_bdi_rdy_i, 
    //
    //internal inputs
    //
    input logic           fmt_data_trigger_i,
    input logic [02:0]    f_mode_i,
    input logic           f_hash_i,
    input logic           f_dec_i,
    
    input logic [07:0]    ascon_din_words_i,
    input logic [07:0]    ad_words_i,
    input logic [07:0]    text_words_i,
    input logic [03:0]    ad_vld_byte_i,
    input logic [03:0]    text_vld_byte_i,
    input logic           mst_rd_done_i,
    //
    //internal outputs
    //
    output logic          out_of_capacity_o,
    output logic          frame_done_o,
    //
    //interface outputs
    //
    output logic          sub_bdi_vld_o,
    output logic          sub_bdi_last_o,
    output logic [2:0]    sub_bdi_type_o,
    output logic [3:0]    sub_bdi_vld_byte_o,
    output logic [31:0]   sub_bdi_o,
    output logic          sub_key_vld_o,
    output logic          sub_key_last_o,
    output logic [31:0]   sub_key_o,
    output logic          sub_eoi_o
    //
    //
);
    //import 
    import dma_cfg::*;
    
    //
    //internal signals
    //
    logic [7:0] ad_limit_reg;
    logic [7:0] text_limit_reg;
    logic [7:0] fmt_cnt;
    logic fmt_cnt_incr;
    logic fmt_hash_flag;
    logic transfer_done;
    logic ad_done, empty_ad;
    logic text_done, text_eoi, text_last;
	logic key_last, key_done;
    logic nonce_done;
    logic tag_done;
    logic aead_start;
    logic hash_start;
    logic aead_start_synch, hash_start_synch;
    logic fifo_cfg_vld, frame_trigger, key_trigger;
    //
    //fsm receive
	// 
    fmt_state fmt_cs, fmt_ns;
    //
    //bdi fifo signals
    //
	 logic bdi_to_fifo;
    logic bdi_fifo_wr, bdi_fifo_rd;
    logic bdi_fifo_full, bdi_fifo_empty;
    logic [40:0] bdi_fifo_i, bdi_fifo_o;
    logic [6:0] bdi_rdusedw;
    //
    //key fifo signals
    //
	 logic key_to_fifo;
    logic key_fifo_wr, key_fifo_rd;
    logic key_fifo_empty, key_fifo_full;
    logic [32:0] key_fifo_i, key_fifo_o;
    //***********************************************************************
    //--------------------------------OUTPUTS--------------------------
    //***********************************************************************
    //1: assignment
    assign out_of_capacity_o = bdi_fifo_full | (key_fifo_full & (fmt_cs == FORMAT_K));
    assign frame_done_o = (fmt_cnt == ascon_din_words_i) & transfer_done & (fmt_cnt > 0);
    assign sub_bdi_type_o = bdi_fifo_o[34:32];
    assign sub_bdi_vld_byte_o = bdi_fifo_o[38:35];
    assign sub_bdi_o = bdi_fifo_o[31:0];
    assign sub_key_o  = key_fifo_o[31:0];
    //***********************************************************************
    //----------------------------INTERNAL BLOCKS---------------------------
    //***********************************************************************
    //
    //latch limit for AD and TEXT and TAG
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) begin
            ad_limit_reg <= '0;
            text_limit_reg <= '0;
        end
        else if(nonce_done) begin
            if(empty_ad) begin
                text_limit_reg <= fmt_cnt + text_words_i;
            end
            else begin
                ad_limit_reg <= fmt_cnt + ad_words_i;
                text_limit_reg <= fmt_cnt + ad_words_i + text_words_i;
            end
        end
    end
    //
    //fsm control signals
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) key_done <= 1'b0;
        else if(key_last) key_done <= 1'b1;
        else key_done <= 1'b0;
    end
    //
    //
    assign transfer_done = iDataValid_Master_Read & ~out_of_capacity_o;
    //
    assign key_last = ((f_mode_i == ASCON_80PQ) ? fmt_cnt == 8'd5 : fmt_cnt == 8'd4) & transfer_done & (fmt_cs == FORMAT_K);
    // 
    assign nonce_done = ((f_mode_i == ASCON_80PQ) ? fmt_cnt == 8'd9 : fmt_cnt == 8'd8) & transfer_done & (fmt_cs == FORMAT_N);
    //
    assign empty_ad = (ad_words_i == 8'd0) & ~f_hash_i;
    assign ad_done = (fmt_cnt == (f_hash_i ? ascon_din_words_i : ad_limit_reg)) & transfer_done & (fmt_cs == FORMAT_AD);
    //
    assign text_last = (fmt_cnt == text_limit_reg) & transfer_done & (fmt_cs == FORMAT_TEXT);
    assign text_eoi = ~f_dec_i & text_last;
    assign text_done = text_last | text_eoi; 
    //
    assign tag_done = (fmt_cnt == ascon_din_words_i) & transfer_done & (fmt_cs == FORMAT_TAG);
   
    //
    //state reg
    //
    always_ff @(posedge iClk, negedge iRstn) begin
        if(~iRstn) fmt_cs <= FORMAT_IDLE;
        else fmt_cs <= fmt_ns;
    end
    //
    //comb circuit
    
    assign fmt_hash_flag = transfer_done & iReadData_Master_Read[0] & (fmt_cs == FORMAT_CFG);
    //
    always_comb begin
        //
        fmt_ns = fmt_cs;
		  bdi_to_fifo = 1'b0;
        bdi_fifo_i = 41'd0;
		  key_to_fifo = 1'b0;
        key_fifo_i = 33'd0;
        hash_start = 1'b0;
        aead_start = 1'b0;
        //
        case(fmt_cs)
            FORMAT_IDLE: begin
                //
                //
                if(fmt_data_trigger_i) begin
                    fmt_ns = FORMAT_CFG;
                end
                else fmt_ns = FORMAT_IDLE;
            end
            FORMAT_CFG: begin
                //
					 bdi_to_fifo = 1'b1;
                bdi_fifo_i = f_data(1'b0, 1'b0, 4'h0, D_CFG, {8'd0, iReadData_Master_Read[23:0]});
                //change state
                if(transfer_done) begin
                    //
                    if(fmt_hash_flag) fmt_ns = FORMAT_AD;
                    else fmt_ns = FORMAT_K;
                    //
                end
                else fmt_ns = FORMAT_CFG;
            end
            FORMAT_K: begin
                if(key_done) begin
						  key_to_fifo = 1'b0;
                    fmt_ns = FORMAT_N;
						  //
                end
                else begin
						  //
						  key_to_fifo = 1'b1;
						  //
						  if(key_last) key_fifo_i = {1'b1, iReadData_Master_Read};
                    else key_fifo_i = {1'b0, iReadData_Master_Read};
						  //
                    fmt_ns = FORMAT_K;
						  //
                end
            end
            FORMAT_N: begin
					 bdi_to_fifo = 1'b1;
                bdi_fifo_i = f_data(1'b0, nonce_done, 4'hf, D_NONCE, iReadData_Master_Read);
                //
                //
                if(nonce_done) begin
                    //
                    //
                    if(~empty_ad) fmt_ns = FORMAT_AD;
                    else fmt_ns = FORMAT_TEXT;
                end
                else fmt_ns = FORMAT_N;
            end
            FORMAT_AD: begin
                //
					 bdi_to_fifo = 1'b1;
                //
                if(ad_done) begin
                    if(f_hash_i) begin
                        hash_start = 1'b1;
                        bdi_fifo_i = f_data(1'b1, 1'b1, ad_vld_byte_i, D_AD, iReadData_Master_Read);
                        //
                        //
                        if(mst_rd_done_i) fmt_ns = FORMAT_IDLE;
                        else begin
                            fmt_ns = FORMAT_CFG;
                        end
                    end
                    else begin
                        bdi_fifo_i = f_data(1'b0, 1'b1, ad_vld_byte_i, D_AD, iReadData_Master_Read);
                        fmt_ns = FORMAT_TEXT;
                    end
                end
                else begin
                    bdi_fifo_i = f_data(1'b0, 1'b0, ad_vld_byte_i, D_AD, iReadData_Master_Read);
                    fmt_ns = FORMAT_AD;
                end
            end
            FORMAT_TEXT: begin
                //
					 bdi_to_fifo = 1'b1;
					 //
                bdi_fifo_i = f_data(text_eoi, text_last, text_vld_byte_i, D_TEXT, iReadData_Master_Read);
                //
                if(text_done) begin
                    //
                    //
                    if(f_dec_i) fmt_ns = FORMAT_TAG;
                    else begin
                        aead_start = 1'b1;
                        //
                        if(mst_rd_done_i) fmt_ns = FORMAT_IDLE;
                        else begin
                            fmt_ns = FORMAT_CFG;
                        end
                    end
                    //
                end
                else begin
                    fmt_ns = FORMAT_TEXT;
                end
            end
            FORMAT_TAG: begin
					 //
					 bdi_to_fifo = 1'b1;
                //
                //
                if(tag_done) begin
                    //
                    bdi_fifo_i = f_data(1'b1, 1'b1, 4'hf, D_TAG, iReadData_Master_Read);
                    aead_start = 1'b1;
                    //
                    if(mst_rd_done_i) fmt_ns = FORMAT_IDLE;
                    else begin
                        fmt_ns = FORMAT_CFG;
                    end
                end
                else begin
                    bdi_fifo_i = f_data(1'b0, 1'b0, 4'hf, D_TAG, iReadData_Master_Read);
                    fmt_ns = FORMAT_TAG;
                end
            end
            default: begin
                fmt_ns = fmt_cs;
                bdi_to_fifo = 1'b0;
                bdi_fifo_i = 41'd0;
                key_to_fifo = 1'b0;
                key_fifo_i = 33'd0;
                hash_start = 1'b0;
                aead_start = 1'b0;
            end
        endcase
    end
    //
    //internal counter
    assign fmt_cnt_incr = transfer_done & (key_to_fifo | bdi_to_fifo);
    //
    always_ff @(posedge iClk, negedge iRstn) begin
        if(~iRstn) fmt_cnt <= 8'd0;
        else if(frame_done_o) begin
            fmt_cnt <= 8'd0;
        end
        else if(fmt_cnt_incr) begin
            fmt_cnt <= fmt_cnt + 1'd1;
        end
    end
    //
    //synchronize trigger signal
    //
pulse_synchronizer synchronizer_aead_start(
    .src_clk_i(iClk),
    .src_rstn_i(iRstn),
    .des_clk_i(sub_clk_i),
    .des_rstn_i(sub_rstn_i),
    .d_in(aead_start),
    //
    .synch_o(aead_start_synch)
    //
);

    //
pulse_synchronizer synchronizer_hash_start(
    .src_clk_i(iClk),
    .src_rstn_i(iRstn),
    .des_clk_i(sub_clk_i),
    .des_rstn_i(sub_rstn_i),
    .d_in(hash_start),
    //
    .synch_o(hash_start_synch)
    //
);
    //
    //(1)__Ascon fifo
    //{eoi, bd_last, vld_bytes, bd_type, bd}
    //
    assign bdi_fifo_wr = transfer_done & bdi_to_fifo;
    //
bdi_fifo bdi_fifo(
	.aclr(1'b0),
	.data(bdi_fifo_i),
	.rdclk(sub_clk_i),
	.rdreq(bdi_fifo_rd),
	.wrclk(iClk),
	.wrreq(bdi_fifo_wr),
	.q(bdi_fifo_o),
	.rdempty(bdi_fifo_empty),
    .rdusedw(bdi_rdusedw),
	.wrfull(bdi_fifo_full)
    );
    //
    //(2)__KEY fifo
    //
    assign key_fifo_wr = transfer_done & key_to_fifo;
    //

key_fifo key_fifo(
	.aclr(1'b0),
	.data(key_fifo_i),
	.rdclk(sub_clk_i),
	.rdreq(key_fifo_rd),
	.wrclk(iClk),
	.wrreq(key_fifo_wr),
	.q(key_fifo_o),
	.rdempty(key_fifo_empty),
	.wrfull(key_fifo_full)
	//
	//
    );
    //
    always_ff@(posedge sub_clk_i, negedge sub_rstn_i) begin
        if(~sub_rstn_i) fifo_cfg_vld <= 1'b0;
        else if(frame_trigger) fifo_cfg_vld <= 1'b1;
        else fifo_cfg_vld <= 1'b0;
    end
    //
    assign key_trigger = fifo_cfg_vld & ~bdi_fifo_o[0];
    //
dma_to_sub dma_to_sub(
    //
    .sub_clk_i(sub_clk_i),
    .sub_rstn_i(sub_rstn_i),
    //
    //ascon interface inputs
    //
    .sub_key_rdy_i(sub_key_rdy_i),
    .sub_bdi_rdy_i(sub_bdi_rdy_i),
    .sub_rdy_i(sub_rdy_i),
    //
    //internal inputs
    //
    .hash_start_i(hash_start_synch),
    .aead_start_i(aead_start_synch),
    .key_trigger_i(key_trigger),
    .key_fifo_empty_i(key_fifo_empty),
    .last_key_i(key_fifo_o[32]),
    .bdi_fifo_empty_i(bdi_fifo_empty),
    .bdi_rdusedw_i(bdi_rdusedw),
    .last_ascon_i(bdi_fifo_o[40:39]),
    //internal output
    .frame_trigger_o(frame_trigger),
    //
    //ascon interface outputs
    //
    .key_fifo_rd_o(key_fifo_rd),
    .bdi_fifo_rd_o(bdi_fifo_rd),
    .sub_key_vld_o(sub_key_vld_o),
    .sub_key_last_o(sub_key_last_o),
    .sub_bdi_vld_o(sub_bdi_vld_o), //
    .sub_bdi_last_o(sub_bdi_last_o),
    .sub_eoi_o(sub_eoi_o)  //
    //
    //
);
    //
    //
endmodule
