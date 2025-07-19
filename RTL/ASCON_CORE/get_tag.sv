//
//
//
module get_tag(
    input logic clk_i,
    input logic rst_n_i,
    //interface inputs
    //
    input logic         bd_valid_i,
    input logic [2:0]   bd_type_i,
    input logic         bd_ready_i,
    input logic [31:0]  bd_i,
    //internal inputs
    input logic         pass_data_i,
    //internal outputs
    //
    output logic [127:0]  run_tag_o //

);

    //import
    import ascon_cfg::*;
	//internals
    logic get_tag_do;
    //
    logic [127:0] new_tag_reg, run_tag_reg;
    //
    //fifo signals
    //
	assign get_tag_do = bd_valid_i & bd_ready_i & (bd_type_i == D_TAG);
    //
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
            new_tag_reg <= 128'd0;
			run_tag_reg <= 128'd0;
        end
        else if(pass_data_i) begin
			new_tag_reg <= 128'd0;
			run_tag_reg <= new_tag_reg;
		  end
        else begin
            if(get_tag_do) begin
                new_tag_reg <= {new_tag_reg[95:0], bd_i};
            end
        end
    end
    //output assignment*/
    assign run_tag_o = run_tag_reg;

    /*always@(posedge clk_i) begin
		//
		if(pass_data_i) begin
			$display("*********(GET_TAG)***********");
			//$display("new_tag = %h", new_tag_reg);
			//$display("run_tag = %h", run_tag_reg);
		end

	end*/

endmodule