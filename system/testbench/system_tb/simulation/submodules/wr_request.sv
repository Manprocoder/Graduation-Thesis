//
//
//
module wr_request(
    //
    //
    input logic          iClk,
    input logic          iRstn,
    //
    //MASTER WRITE 
    //
	output	logic		[31:0]		oAddress_Master_Write,
	output	logic		[31:0]		oData_Master_Write,
	output	logic					oWrite_Master_Write,
	input	logic					iWait_Master_Write, 
    //
    //internal inputs
    //
    input logic           wr_trigger_i,  //from store ckn_ad sub_module
	input logic 	      wr_info_avail_i,
    input logic [09:0]    wr_info_i,  //dec flag, hash flag, ckn_ad words
    input logic [31:0]    out_gap_i,
    input logic [31:0]    d_addr_i,
    input logic [31:0]    length_i,
    input logic [32:0]    ckn_data_i,
    input logic [32:0]    text_data_i,
    input logic [32:0]    tag_data_i,
    input logic           ckn_ad_avail_i,
    input logic           text_avail_i,
    input logic           tag_avail_i,
    input logic           res_avail_i,
    input logic           res_req_data_i,  //1: ascon done, 0: tag fail
    //
    //internal outputs
    //
    output logic [15:0]   tag_fail_nums_o,
    output logic [31:0]   end_addr_write_o,
    output logic          wr_info_req_o,
    output logic          ckn_ad_fetch_o,
    output logic          res_req_fetch_o,
    output logic          text_fetch_o,
    output logic          tag_fetch_o,
    output logic          done_trigger_o
    //
    //
);

    //
    //fsm wr
    //
    typedef enum logic [3:0] {W_IDLE, CKN_AD_FIFO_RD, W_INFO_FIFO_RD, RES_REQ_FIFO_RD, RES_ARBITER, TEXT_FIFO_RD, TAG_FIFO_RD, W_REQ, W_INCR} wr_state;
    wr_state wr_cs, wr_ns;
	//
    //internal regs
	//--counter
    logic [31:0] wreq_cnt;
	//--write addr
    logic [31:0] aead_waddr;
    logic [31:0] hash_code_waddr;
    //
    //variables
    //
    logic hash_code_rdy;
    logic hash_mode;
    logic dec_mode;
    logic dec_hash_mode;
	logic mst_wr_done;
    logic w_frame_done;
    //
    //fsm output
    //
	logic first_write;
    logic wr_addr_fetch;
    logic addr_for_hash;
    logic wr_addr_incr;
    logic wr_addr_subtract;
    logic tag_fail;
    logic dec_error;
    logic latch_end_addr_write;
    //
    //data control
    //
    //(1)__common
    logic write_transfer_done;
    
    //(2)__ckn
    logic ckn_transfer_done;
    logic ckn_data_trigger, write_ckn_data, write_ckn_done;
    //(3)__result
    logic text_data_trigger, write_text_data, write_text_done;
    //(4)
    logic tag_data_trigger, write_tag_data, write_tag_done;
    //********************************************************************
    //----------------------------OUTPUT BLOCK--------------------------
    //********************************************************************
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) tag_fail_nums_o <= 16'd0;
        else if(first_write) tag_fail_nums_o <= 16'd0;
        else if(tag_fail) begin
				tag_fail_nums_o <= tag_fail_nums_o + 1'd1;
		  end
		  //
    end
    //end addr write
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) end_addr_write_o <= 32'd0;
        else if(latch_end_addr_write) begin
            end_addr_write_o <= aead_waddr;
        end
    end
    //********************************************************************
    //-------------------HANDLE WRITE ADDRESS FOR HASH-----------------
    //********************************************************************
    assign dec_mode = wr_info_i[9];
	assign hash_mode = wr_info_i[8];
    
    //
    //hash code addr reg
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) hash_code_waddr <= 32'd0;
        else if(wr_addr_fetch) begin
            hash_code_waddr <= d_addr_i + out_gap_i;
        end
        else if(addr_for_hash) begin
            hash_code_waddr <= hash_code_waddr + 3'd4;
        end
    end

    //********************************************************************
    //-------------------HANDLE WRITE ADDRESS FOR AEAD-----------------
    //********************************************************************
    //aead addr reg
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) aead_waddr <= 32'd0;
        else if(wr_addr_fetch) aead_waddr <= d_addr_i;
        else if(wr_addr_subtract) begin
            aead_waddr <= aead_waddr - 4 * (wr_info_i[7:0] + 1'd1);
            //overwrite previous ckn_ad
        end
        else if(wr_addr_incr) begin
            aead_waddr <= aead_waddr + 3'd4;
        end
    end
    //********************************************************************
    //-----------------------HANDLE WRITE DATA TYPE---------------------
    //********************************************************************
	//
	assign ckn_transfer_done = write_transfer_done & write_ckn_data;
    assign write_ckn_done = ckn_data_i[32] & ckn_transfer_done;
    //
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) write_ckn_data <= 1'b0;
        else if(write_ckn_done) write_ckn_data <= 1'b0;
        else if(ckn_data_trigger) write_ckn_data <= 1'b1;
    end
    //(2) TEXT
    
	assign write_text_done = text_data_i[32] & write_transfer_done & write_text_data;
    //
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) write_text_data <= 1'b0;
        else if(write_text_done) write_text_data <= 1'b0;
        else if(text_data_trigger) write_text_data <= 1'b1;
    end
    //(3) TAG
   
    assign write_tag_done = tag_data_i[32] & write_transfer_done & write_tag_data;
    //
	
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) write_tag_data <= 1'b0;
        else if(write_tag_done) write_tag_data <= 1'b0;
        else if(tag_data_trigger) write_tag_data <= 1'b1;
    end
    //
    //state reg
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) wr_cs <= W_IDLE;
        else wr_cs <= wr_ns;
    end
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) dec_error <= 1'b0;
        else if(tag_fail) dec_error <= 1'b1;
        else dec_error <= 1'b0;
    end
    //done signal
    assign hash_code_rdy = write_text_data & hash_mode;
    assign dec_hash_mode = dec_mode | hash_mode;
    assign w_frame_done = (write_text_done & dec_hash_mode) | write_tag_done | dec_error;
    assign mst_wr_done = (wreq_cnt == (length_i - 1'd1)) & w_frame_done;
    //
    always_comb begin
        wr_ns = wr_cs;
        oWrite_Master_Write = 1'b0;
        oAddress_Master_Write = 32'd0;
        oData_Master_Write = 32'd0;
        //addr
        first_write = 1'b0;
        wr_addr_fetch = 1'b0;
        //ckn_ad
        ckn_data_trigger = 1'b0;
        ckn_ad_fetch_o = 1'b0;
        //text, tag, hash
        wr_info_req_o = 1'b0; 
        res_req_fetch_o = 1'b0;
        text_data_trigger = 1'b0;
        tag_fail = 1'b0;
        wr_addr_subtract = 1'b0;
        text_fetch_o = 1'b0;
        tag_fetch_o = 1'b0;
        //
        wr_addr_incr = 1'b0;
        addr_for_hash = 1'b0;
        //
        write_transfer_done = 1'b0;
        tag_data_trigger = 1'b0;
        //
        done_trigger_o = 1'b0;
        latch_end_addr_write = 1'b0;
        //
        //
        case(wr_cs)
            W_IDLE: begin
                if(wr_trigger_i) begin
                    wr_ns = CKN_AD_FIFO_RD;
                    first_write = 1'b1;
                    wr_addr_fetch = 1'b1;
                    ckn_data_trigger = 1'b1;
                end
                else begin
                    wr_ns = W_IDLE;
                    first_write = 1'b0;
                    wr_addr_fetch = 1'b0;
                    ckn_data_trigger = 1'b0;
                end
            end
            CKN_AD_FIFO_RD: begin
                //
                if(ckn_ad_avail_i) begin
					ckn_ad_fetch_o = 1'b1;
                    wr_ns = W_REQ; 
                    
                end
                else begin
					ckn_ad_fetch_o = 1'b0;
                    wr_ns = CKN_AD_FIFO_RD;
                    
                end
                //
            end
            W_INFO_FIFO_RD: begin
                if(wr_info_avail_i) begin
                    wr_info_req_o = 1'b1;
                    wr_ns = RES_REQ_FIFO_RD;
                   // 
                end
                else begin
				    wr_info_req_o = 1'b0;
                    wr_ns = W_INFO_FIFO_RD;
                    //
                end
            end
            RES_REQ_FIFO_RD: begin
                //
                /*if(res_req_vld_i) begin //finish read req
                    if(res_req_data_i) begin
                        wr_ns = TEXT_FIFO_RD;
                        text_data_trigger = 1'b1;
                        tag_fail = 1'b0;
                    end
                    else begin //tag fail
                        //
                        wr_ns = W_INCR;
                        tag_fail = 1'b1;
                        wr_addr_subtract = 1'b1;
                    // 
                    end
                end*/
               // else begin //sending read request
                    
                    //
                    if(res_avail_i) begin
                        res_req_fetch_o = 1'b1;
                        wr_ns = RES_ARBITER;
                    end
                    else begin
                        res_req_fetch_o = 1'b0;
                        wr_ns = RES_REQ_FIFO_RD;
                    end
						  //
                    //
                //end
            end
            RES_ARBITER: begin
                if(res_req_data_i) begin
                    wr_ns = TEXT_FIFO_RD;
                    text_data_trigger = 1'b1;
                    tag_fail = 1'b0;
                end
                else begin //tag fail
                    //
                    wr_ns = W_INCR;
                    tag_fail = 1'b1;
                    wr_addr_subtract = 1'b1;
                // 
                end
            end
            TEXT_FIFO_RD: begin
                if(text_avail_i) begin
                    text_fetch_o = 1'b1;
                    wr_ns = W_REQ;
                    
                end
                else begin
                    text_fetch_o = 1'b0;
                    wr_ns = TEXT_FIFO_RD;
                    
                end
            end
            TAG_FIFO_RD: begin
                if(tag_avail_i) begin
                    tag_fetch_o = 1'b1;
                    wr_ns = W_REQ;
                    
                end
                else begin
                    tag_fetch_o = 1'b0;
                    wr_ns = TAG_FIFO_RD;
                   // 
                end
            end
            W_REQ: begin
                //
                oWrite_Master_Write = 1'b1;
                oAddress_Master_Write = hash_code_rdy ? hash_code_waddr : aead_waddr;
                //
                if(write_ckn_data) oData_Master_Write = ckn_data_i[31:0];
                else if(write_text_data) oData_Master_Write = text_data_i[31:0];
                else oData_Master_Write = tag_data_i[31:0];
                //
                if(iWait_Master_Write) begin
                    wr_ns = W_REQ;
                end
                else begin
                    wr_ns = W_INCR;
                end
                //
            end
            W_INCR: begin
                write_transfer_done = 1'b1;
                //
                if(mst_wr_done) begin
                    wr_ns = W_IDLE;
                    done_trigger_o = 1'b1;
                    latch_end_addr_write = 1'b1;
                end
                else if(dec_error) begin
                    wr_ns = CKN_AD_FIFO_RD;
                    ckn_data_trigger = 1'b1;
                end
                else begin
                    if(write_ckn_data) begin
                        if(write_ckn_done) begin
                            wr_ns = W_INFO_FIFO_RD;
                        end
                        else begin
                            wr_ns = CKN_AD_FIFO_RD;
                        end
                        //
                        wr_addr_incr = 1'b1;
                        //
                    end
                    else begin
                        if(write_text_data) begin
                            if(write_text_done) begin
                                //
                                //
                                if(dec_mode | hash_mode) begin
                                    wr_ns = CKN_AD_FIFO_RD;
                                    ckn_data_trigger = 1'b1;
                                    tag_data_trigger = 1'b0;
                                end
                                else begin
                                    wr_ns = TAG_FIFO_RD;
                                    ckn_data_trigger = 1'b0;
                                    tag_data_trigger = 1'b1;
                                end
                                //
                                    if(hash_mode) begin
                                        addr_for_hash = 1'b1;
                                        wr_addr_incr = 1'b0;
                                    end
                                    else begin
                                        addr_for_hash = 1'b0;
                                        wr_addr_incr = 1'b1;
                                    end
                                    //
                                //
                            end //end of if(write_text_done)
                            else begin
										  
                                wr_ns = TEXT_FIFO_RD;
                                //
                                if(hash_mode) begin
                                    addr_for_hash = 1'b1;
                                end
                                else begin
                                    wr_addr_incr = 1'b1;
                                end
                            end
                        end //end of if(write_text_data)
                        else begin
                            if(write_tag_done) begin
                                wr_ns = CKN_AD_FIFO_RD;
                                ckn_data_trigger = 1'b1;
                            end
                            else begin
                                wr_ns = TAG_FIFO_RD;
                                ckn_data_trigger = 1'b0;
                            end
                            //
                            wr_addr_incr = 1'b1;
                            //
                        end
                    end
                end
            end
            default: begin
                wr_ns = wr_cs;
                oWrite_Master_Write = 1'b0;
                oAddress_Master_Write = 32'd0;
                oData_Master_Write = 32'd0;
                //addr
                first_write = 1'b0;
                wr_addr_fetch = 1'b0;
                //ckn_ad
                ckn_data_trigger = 1'b0;
                ckn_ad_fetch_o = 1'b0;
                //text, tag, hash
                wr_info_req_o = 1'b0; 
                res_req_fetch_o = 1'b0;
                text_data_trigger = 1'b0;
                tag_fail = 1'b0;
                wr_addr_subtract = 1'b0;
                text_fetch_o = 1'b0;
                tag_fetch_o = 1'b0;
                //
                wr_addr_incr = 1'b0;
                addr_for_hash = 1'b0;
                //
                write_transfer_done = 1'b0;
                tag_data_trigger = 1'b0;
                //
                done_trigger_o = 1'b0;
                latch_end_addr_write = 1'b0;
                //
            end
            //
            //
        endcase
    end
    //
    //internal counter
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) wreq_cnt <= 32'd0;
        else if(done_trigger_o) begin
            wreq_cnt <= 32'd0;
        end
        else if(w_frame_done) begin
            wreq_cnt <= wreq_cnt + 1'd1;
        end
    end
    //
    //
endmodule