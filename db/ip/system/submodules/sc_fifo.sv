//
//
//
module sc_fifo #(parameter DW = 32, DEPTH=8) (
  input logic clk_i,
  input logic rstn_i,
  input logic wr_i,
  input logic rd_i,
  input logic clr_i,
  input logic [DW-1:0] data_i,
  output logic [DW-1:0] data_o,
  output logic [$clog2(DEPTH):0] usedw_o,
  output logic full_o,
  output logic empty_o 
  //
  //
);
  
  localparam PTR_WIDTH = $clog2(DEPTH);
  logic [PTR_WIDTH:0] w_ptr, r_ptr; // additional bit to detect full/empty condition
  logic [DW-1:0] fifo[DEPTH];
  logic wrap_around;
  
	// 
  // To write data to FIFO
  always@(posedge clk_i) begin
    if(!rstn_i | clr_i) begin
		w_ptr <= '0;
    end
	else if(wr_i & !full_o) begin
		fifo[w_ptr[PTR_WIDTH-1:0]] <= data_i;
		w_ptr <= w_ptr + 1'd1;
	end
  end
  
 // To read data from FIFO
 //
  always@(posedge clk_i) begin
    if(!rstn_i | clr_i)begin
		r_ptr <= '0;
		data_o <= '0;
    end
	else if(rd_i & !empty_o) begin
		data_o <= fifo[r_ptr[PTR_WIDTH-1:0]];
		r_ptr <= r_ptr + 1'd1;
    end
  end
  //
  //
  //
  assign wrap_around = w_ptr[PTR_WIDTH] ^ r_ptr[PTR_WIDTH];
  // To check MSB of write and read pointers are different
  
  //Full condition
  assign full_o = wrap_around & (w_ptr[PTR_WIDTH-1:0] == r_ptr[PTR_WIDTH-1:0]);
  assign empty_o = (w_ptr == r_ptr);
  assign usedw_o = (w_ptr - r_ptr);
  //
endmodule