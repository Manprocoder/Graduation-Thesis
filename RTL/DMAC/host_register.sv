//
//
//
module host_register(
    //
	//	Global signals
	input	logic					iClk,
	input	logic					iRstn,
	//	Configuration
	input	logic					iChipSelect_Control,
	input	logic					iWrite_Control,
	input	logic					iRead_Control,
	input	logic		[1:0]		iAddress_Control,
	input	logic		[31:0]		iData_Control,
	output	logic		[31:0]		oData_Control,
    //
    //status signals
    //
    input logic         done_trigger_i,
    input logic [15:0]  tag_fail_nums_i,
    input logic [31:0]  end_addr_write_i,
    //
    output logic        sub_clk_o,
    output logic        sub_rstn_o,
    output logic        start_o,
    output logic        start_trigger_o,
    output logic [31:0] s_addr_o   //
    //
);
    //
    //internal signals
    //
    logic dma_done;
    logic start;
    logic [31:0] s_addr_reg;
    logic [31:0] status;
    logic [31:0] control;
    //
    //handle main regs
    //
    assign start_o = start;
    assign s_addr_o = s_addr_reg;
    assign status = {tag_fail_nums_i, 14'd0, start, dma_done};
    //**************************************************************
    //-------------------INTERFACE OUTPUT--------------------------
    //**************************************************************
    //
    always_ff@(posedge iClk or negedge iRstn) begin
        if (~iRstn) begin
            s_addr_reg <= 32'd0;
            control <= 32'd0;
        end else if(iChipSelect_Control & iWrite_Control) begin 
            case(iAddress_Control)
                2'd0:	s_addr_reg	<= 	iData_Control;
                2'd1:	control     <= 	iData_Control;
            endcase
        end else begin
            s_addr_reg <= s_addr_reg;
            control <= control;
        end	
    end
    //read status
always_ff@(posedge iClk or negedge iRstn) begin
	if (~iRstn)
		oData_Control <= 32'd0;
	else if(iChipSelect_Control & iRead_Control)
		case(iAddress_Control)
			2'd2: oData_Control <= status;
            2'd3: oData_Control <= end_addr_write_i;
		endcase
	else 
		oData_Control <= oData_Control;
end
    //start
always_ff @(posedge iClk, negedge iRstn) begin
	if (~iRstn)
		start <= 1'b0;
	else if (iChipSelect_Control & iWrite_Control & (iAddress_Control == 2'd1)) 
		start <= iData_Control[0];
	else if (done_trigger_i)
		start <= 1'b0;
	else 
		start <= start;
end
    //dma done
    always_ff@(posedge iClk, negedge iRstn) begin: DMA_DONE_SIGNAL
        if(~iRstn) dma_done <= 1'b0;
        else if(done_trigger_i) dma_done <= 1'b1;
        else if(start_trigger_o) dma_done <= 1'b0;
    end
//********************************************************************
//--------------------CLK DIVIDER AND START SIGNAL-------------------
//********************************************************************
//
clk_divider clk_divider(
    .sys_clk_i(iClk),
    .sys_rstn_i(iRstn),
    //
    .clk_o(sub_clk_o),
    .rstn_o(sub_rstn_o)
);
//
RiSiEdgeDetector RSEdgeDetector_start(
    .clk_i(iClk),
    .rstn_i(iRstn),
    .sign_i(start),
    .red_o(start_trigger_o)//
);
//
//
endmodule


