//
//
//
module rd_request(
    input logic iClk,
    input logic iRstn,
    //
    //internal inputs
    //
    input logic         start_trigger_i,
    input logic         out_of_capacity_i,
    input logic         frame_done_i,
    input logic  [31:0] s_addr_i,
    input logic  [31:0] length_i,
    //
    //interface
    //
	output	logic		[31:0]		oAddress_Master_Read,
	output	logic					oRead_Master_Read,
	input	logic					iWait_Master_Read,
    //
    //internal outputs
    //
    output logic        mst_rd_done_o
    //
    //

);

    //fsm rd request
    //
    typedef enum logic [1:0] {R_IDLE, R_REQ, R_INCR} r_state;
    r_state rreq_cs, rreq_ns;
    //
    //internal signals
    //
    logic [31:0] rreq_cnt;
    logic [31:0] rd_addr_reg;
    logic rd_addr_fetch, rd_addr_incr;
    logic dma_rd_done;
    //********************************************************************
    //------------------------OUTPUT ASSIGNMENT--------------------------
    //********************************************************************
    //
    assign dma_rd_done = (rreq_cnt == (length_i - 1'd1)) & frame_done_i;
    //
    //rd address
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) rd_addr_reg <= 32'd0;
        else if(rd_addr_fetch) begin
            rd_addr_reg <= s_addr_i;
        end
        else if(rd_addr_incr) begin
            rd_addr_reg <= rd_addr_reg + 3'd4;
        end
    end
    //
    //rreq state reg
    //
    always_ff @(posedge iClk, negedge iRstn) begin
        if(~iRstn) rreq_cs <= R_IDLE;
        else rreq_cs <= rreq_ns;
    end
    //
    //
    //
    always_comb begin
        rreq_ns = rreq_cs;
        oAddress_Master_Read = 32'd0;
        oRead_Master_Read = 1'b0;
        rd_addr_fetch = 1'b0;
        rd_addr_incr  = 1'b0;
        mst_rd_done_o = 1'b0;
        //
        //
        case(rreq_cs)
            R_IDLE: begin
                //
                //change state
                //
                if(start_trigger_i) begin
                    rreq_ns = R_REQ;
                    rd_addr_fetch = 1'b1;
                end
                else rreq_ns = R_IDLE;
            end
            R_REQ: begin
                //
                oAddress_Master_Read = rd_addr_reg;
                oRead_Master_Read = 1'b1;
                //
                if(iWait_Master_Read | out_of_capacity_i) begin
                    rreq_ns = R_REQ;
                end 
                else begin
                    rreq_ns = R_INCR;
                    rd_addr_incr = 1'b1;
                end
            end
            R_INCR: begin
                if(dma_rd_done) begin
					mst_rd_done_o = 1'b1;
					rreq_ns = R_IDLE;
				end
                else begin
                    rreq_ns = R_REQ;
                    
                end
            end
            default: begin
                rreq_ns = rreq_cs;
                oAddress_Master_Read = 32'd0;
                oRead_Master_Read = 1'b0;
                rd_addr_fetch = 1'b0;
                rd_addr_incr  = 1'b0;
                mst_rd_done_o = 1'b0;
                
            end
        endcase
    end
    //
    //internal counter
    //
    always_ff@(posedge iClk, negedge iRstn) begin
        if(~iRstn) rreq_cnt <= 32'd0;
        else if(mst_rd_done_o) begin
            rreq_cnt <= 32'd0;
        end
        else if(frame_done_i) begin 
            rreq_cnt <= rreq_cnt + 1'd1;
        end
    end
    //
    //
endmodule