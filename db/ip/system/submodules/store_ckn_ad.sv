//
//
//
module store_ckn_ad
(
    input logic iClk,
    input logic iRstn,
    //interface inputs
    //
    input logic iDataValid_Master_Read,
    input logic [31:0] iReadData_Master_Read,
    //
    //internal inputs
    //
    input logic store_ckn_start_i,
    input logic ckn_ad_fetch_i,
    input logic frame_done_i,
    input logic out_of_capacity_i,
    input logic mst_rd_done_i,
    input logic         f_hash_i,
    input logic [31:0]  s_addr_i,
    input logic [07:0]  ascon_din_words_i,
    input logic [07:0]  ckn_ad_words_i, 
    //
    //internal outputs
    //
    output logic wr_trigger_o,
    output logic fmt_data_trigger_o,
    output logic ckn_ad_avail_o,
    output logic get_dma_cfg_o,
	output logic get_ckn_ad_o,
    output logic [07:0] ckn_cnt_o,
    output logic [32:0] ckn_data_o
    //
    //
);
    //
    //receive fsm for dma write
    //
    typedef enum logic [1:0] {IN_IDLE, DMA_CFG, GET_CKN_AD, IN_PAUSE} ckn_state;
    ckn_state ckn_cs, ckn_ns;
    //
    //
    logic ckn_cnt_incr;
    logic transfer_done;
    logic end_of_ckn;
	 logic dma_cfg_vld;
    logic dma_cfg_done;
	 logic ascon_din_vld;
    
    //
    //fifo signals
    //
    logic [32:0] ckn_fifo_i;
    logic ckn_fifo_wr, ckn_fifo_rd;
    logic ckn_fifo_empty;
    //****************************************************************************************
    //----------------------------------INTERNAL OUTPUTS------------------------------------
    //****************************************************************************************
    //(1)
    assign ckn_ad_avail_o = ~ckn_fifo_empty;
    assign get_dma_cfg_o = (ckn_cs == DMA_CFG);
	assign get_ckn_ad_o = (ckn_cs == GET_CKN_AD) & ~out_of_capacity_i;
    //
    // state
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) ckn_cs <= IN_IDLE;
        else ckn_cs <= ckn_ns;
    end
    //
    //
    assign transfer_done = iDataValid_Master_Read;
	 assign dma_cfg_vld = transfer_done & (ckn_cs == DMA_CFG);
    assign dma_cfg_done = (ckn_cnt_o == 8'd2) & dma_cfg_vld;
    assign ascon_din_vld = transfer_done & get_ckn_ad_o;
    //
    //
    always_comb begin
        ckn_ns = ckn_cs;
        fmt_data_trigger_o = 1'b0;
        wr_trigger_o = 1'b0;
        ckn_fifo_i = 33'd0;
        //
        case(ckn_cs)
            IN_IDLE: begin
                if(store_ckn_start_i) begin
                    ckn_ns = DMA_CFG;
                end
                else ckn_ns = IN_IDLE;
            end
            DMA_CFG: begin
                //
                //
                if(ckn_cnt_o == 8'd0) begin
					ckn_fifo_i = {1'b0, s_addr_i}; //d_addr
                    //
                end
                else if(ckn_cnt_o == 8'd1) begin
                    ckn_fifo_i = {1'b0, iReadData_Master_Read}; //out_gap
                    
                end
                else if(ckn_cnt_o == 8'd2) begin
                    ckn_fifo_i = {1'b0, iReadData_Master_Read}; //length
                end
                else ckn_fifo_i = 33'd0;
                //
                //change state
                //
                if(dma_cfg_done) begin
                    ckn_ns = GET_CKN_AD;
                    fmt_data_trigger_o = 1'b1;
                    wr_trigger_o = 1'b1;
                end
                else ckn_ns = DMA_CFG;
            end
            GET_CKN_AD: begin
                //
                if(end_of_ckn) begin
                    ckn_fifo_i = {1'b1, iReadData_Master_Read};
                    //
                    //
                    if(frame_done_i) begin
                        if(mst_rd_done_i) ckn_ns = IN_IDLE;
                        else ckn_ns = GET_CKN_AD;
                    end
                    else ckn_ns = IN_PAUSE;
                end
                else begin
                    if(ckn_cnt_o == 8'd0) begin//ASCON CONFIG
                        //
                        if(iReadData_Master_Read[0]) begin  //hash mode
                            ckn_fifo_i = {1'b0, iReadData_Master_Read};
                        end
                        else begin
                            //
                            if(iReadData_Master_Read[1]) begin //dec mode
                                ckn_fifo_i = {1'b0, iReadData_Master_Read[31:24] - 3'd4, iReadData_Master_Read[23:2], ~iReadData_Master_Read[1], iReadData_Master_Read[0]};
                            end
                            else begin
                                ckn_fifo_i = {1'b0, iReadData_Master_Read[31:24] + 3'd4, iReadData_Master_Read[23:2], ~iReadData_Master_Read[1], iReadData_Master_Read[0]};
                            end
                        end
                    end
                    else begin
                        ckn_fifo_i = {1'b0, iReadData_Master_Read};
                    end
                    //
                    ckn_ns = GET_CKN_AD;
                end
            end
            IN_PAUSE: begin
                if(frame_done_i) begin
                    if(mst_rd_done_i) ckn_ns = IN_IDLE;
                    else ckn_ns = GET_CKN_AD;
                end
                else ckn_ns = IN_PAUSE;
            end
        endcase
    end
    //
    //internal counter
    //
    assign ckn_cnt_incr = dma_cfg_vld | ascon_din_vld;
    assign end_of_ckn = ascon_din_vld & (ckn_cnt_o == (f_hash_i ? ascon_din_words_i : ckn_ad_words_i)) & (ckn_cnt_o > 0);
    //(1) track data
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) ckn_cnt_o <= 8'd0;
        else if(end_of_ckn | dma_cfg_done)begin
            ckn_cnt_o <= 8'd0;
        end
        else if(ckn_cnt_incr) begin
            ckn_cnt_o <= ckn_cnt_o + 1'd1;
        end
    end
    //
    //cknad fifo
    //
    assign ckn_fifo_wr = dma_cfg_vld | ascon_din_vld;
    assign ckn_fifo_rd = ckn_ad_fetch_i;
    //
	//
    //
	ckn_ad_fifo ckn_fifo(
	.aclr(1'b0),
	.clock(iClk),
	.data(ckn_fifo_i),
	.rdreq(ckn_fifo_rd),
	.wrreq(ckn_fifo_wr),
	.empty(ckn_fifo_empty),
	.full(),
	.q(ckn_data_o)
	//
	);
    //
    //
endmodule
