//
//
//
module dma_to_sub(
    input logic sub_clk_i,
    input logic sub_rstn_i,
    //
    //interface inputs
    //
    input logic         sub_key_rdy_i,
    input logic         sub_bdi_rdy_i,
    input logic         sub_rdy_i,
    //
    //internal inputs
    //
    input logic         hash_start_i,
    input logic         aead_start_i,
    input logic         key_trigger_i,
    input logic         key_fifo_empty_i,
    input logic         last_key_i,
    input logic         bdi_fifo_empty_i,
    input logic [6:0]   bdi_rdusedw_i,
    input logic [1:0]   last_ascon_i,
    //internal output
    output logic        frame_trigger_o,
    //
    //ascon interface outputs
    //
    output logic        key_fifo_rd_o,
    output logic        bdi_fifo_rd_o,
    output logic        sub_key_vld_o,
    output logic        sub_key_last_o,
    output logic        sub_bdi_vld_o, //
    output logic        sub_bdi_last_o, //
    output logic        sub_eoi_o //
    //
    //

);
    //
    //fsm
    //
    //1 key
    typedef enum logic[1:0] {KEY_IDLE, KEY_FIFO_RD, KEY_PASS} key_state;
    key_state k_cs, k_ns;
    //2 bdi
    typedef enum logic[1:0] {BDI_IDLE, BDI_FIFO_RD, BDI_PASS, BDI_EOI} bdi_state;
    bdi_state bdi_cs, bdi_ns;
    //internals
    logic cfg_trigger, frame_start;
    //*************************************************
    //--------------------handle key------------------
    //*************************************************
    
    //-------------------key fsm----------------------
    always_ff@(posedge sub_clk_i, negedge sub_rstn_i) begin
        if(~sub_rstn_i) k_cs <= KEY_IDLE;
        else k_cs <= k_ns;
    end
    //
    //
    always_comb begin
        k_ns = k_cs;
        key_fifo_rd_o = 1'b0;
        sub_key_vld_o = 1'b0;
        sub_key_last_o = 1'b0;
        //
        //
        case(k_cs)
            KEY_IDLE: begin
                if(key_trigger_i) begin
                    k_ns = KEY_FIFO_RD;
                end
                else begin
                    k_ns = KEY_IDLE;
                end
            end
            KEY_FIFO_RD: begin
                if(key_fifo_empty_i) begin
                    key_fifo_rd_o = 1'b0;
                    k_ns = KEY_FIFO_RD;
                end
                else begin
                    key_fifo_rd_o = 1'b1;
                    k_ns = KEY_PASS;
                end
            end
            KEY_PASS: begin
                //
                sub_key_vld_o = 1'b1;
                sub_key_last_o = last_key_i;
                //
                if(sub_key_rdy_i) begin
                    if(last_key_i) begin
                        k_ns = KEY_IDLE;
                        //
                    end
                    else begin
                        k_ns = KEY_FIFO_RD; 
                        //
                    end
                end
                else begin
                    k_ns = KEY_PASS;
                end
            end
            default: begin
                k_ns = k_cs;
                key_fifo_rd_o = 1'b0;
                sub_key_vld_o = 1'b0;
                sub_key_last_o = 1'b0;
            end
        endcase
    end
    //*********************************************************
    //------------------------HANDLE BDI----------------------
    //*********************************************************
    
    //
    always_ff@(posedge sub_clk_i, negedge sub_rstn_i) begin
        if(~sub_rstn_i) bdi_cs <= BDI_IDLE;
        else bdi_cs <= bdi_ns;
    end
    //
    always_ff@(posedge sub_clk_i, negedge sub_rstn_i) begin
        if(~sub_rstn_i) frame_start <= 1'b0;
        else if(cfg_trigger) frame_start <= 1'b1;
        else frame_start <= 1'b0;
    end
    //
    always_comb begin
        bdi_ns = bdi_cs;
        cfg_trigger = 1'b0;
        frame_trigger_o = 1'b0;
        bdi_fifo_rd_o = 1'b0;
        sub_bdi_vld_o = 1'b0;
        sub_bdi_last_o = 1'b0;
        sub_eoi_o = 1'b0;
        //
        //
        case(bdi_cs)
            BDI_IDLE: begin
                if(hash_start_i | aead_start_i) begin
                    bdi_ns = BDI_FIFO_RD;
                    cfg_trigger = 1'b1;
                    //
                end
                else begin
                    bdi_ns = BDI_IDLE;
                end
            end
            BDI_FIFO_RD: begin
                if(bdi_fifo_empty_i) begin
                    bdi_fifo_rd_o = 1'b0;
                    bdi_ns = BDI_FIFO_RD;
                end
                else begin
                    if(frame_start) frame_trigger_o = 1'b1;
                    else frame_trigger_o = 1'b0;
                    //
                    bdi_fifo_rd_o = 1'b1;
                    bdi_ns = BDI_PASS;
                end
                //
            end
            BDI_PASS: begin
                //
                sub_bdi_vld_o = 1'b1;
                sub_bdi_last_o = last_ascon_i[0];
                //
                if(sub_bdi_rdy_i) begin
                    if(last_ascon_i[1]) begin
                       bdi_ns = BDI_EOI;
                    end
                    else begin
                        bdi_ns = BDI_FIFO_RD;
                    end
                end
                else begin
                    bdi_ns = BDI_PASS;
                end
            end
            BDI_EOI: begin
                sub_eoi_o = 1'b1;
                //
                if(sub_rdy_i) begin
                    //
                    if(bdi_rdusedw_i < 2) begin //high probability of config bdi
                        bdi_ns = BDI_IDLE;
                    end
                    else begin
                        bdi_ns = BDI_FIFO_RD;
                        cfg_trigger = 1'b1;
                    end
                end
                else bdi_ns = BDI_EOI;
                //
            end
			//
        endcase
    end
    //
    //
endmodule