//
//
`timescale 1ps/1ps
//
module get_key_nonce(
    input logic clk_i,
    input logic rst_n_i,
    //interface inputs
    //
    input logic         key_valid_i,
    input logic         key_last_i,
    input logic [31:0]  key_i,
    //
    input logic         bd_valid_i,
    input logic [2:0]   bd_type_i,
    input logic         bd_ready_i,
    input logic [31:0]  bd_i,
    input logic         eoi_i,
    //internal inputs
    input logic         almost_done_i,
    input logic         ready_i,
    input logic         idle_state_i,
    //input logic    [3:0] cs_i,
    //
    //interface outputs
    //
    output logic        key_ready_o,
    //
    //internal outputs
    //
    output logic          run_key_vld_o,
    output logic [159:0]  run_key_o,
    output logic [127:0]  nonce_o //
);
    //import
    import ascon_cfg::*;
	//internals
    //(1) key
    logic get_key_do;
    logic get_key_done;
    logic pass_key;
    logic [159:0] new_key_reg, run_key_reg;
    logic [1:0] key_ctrl;
    logic key_avail;
    logic start;
    //(2) nonce
    logic get_nonce_do;
    logic [127:0] nonce_reg;
    //
    //signals assignment
    //
	assign get_key_do = key_valid_i & key_ready_o;
    assign get_key_done  = get_key_do & key_last_i;
	assign get_nonce_do = bd_valid_i & bd_ready_i & (bd_type_i == D_NONCE);
    assign start = eoi_i & ready_i;
    //
    //
	always_ff @(posedge clk_i or negedge rst_n_i) begin
		if(~rst_n_i) key_ready_o <= 1'b1; 
		else if(get_key_done) key_ready_o <= 1'b0;
		else if(start) key_ready_o <= 1'b1;
    end
	//key full
	always_ff @(posedge clk_i, negedge rst_n_i) begin
		if(~rst_n_i) key_ctrl <= 2'b00;
        else if(start) key_ctrl <= 2'b00;
        else if(pass_key) key_ctrl <= 2'b10;
		else if(get_key_done) begin
			key_ctrl <= {key_ctrl[1], 1'b1};
		end
	end
    //
    assign key_avail = key_ctrl[0];
	assign pass_key = key_avail & (idle_state_i | almost_done_i);
    //*******************************************************
    //(2)-------------------get key------------------------
    //*******************************************************
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
            new_key_reg <= '0;
			run_key_reg <= '0;
        end
        else if(pass_key) begin
			new_key_reg <= '0;
			run_key_reg <= new_key_reg;
		end
        else begin
            if(get_key_do) begin
                new_key_reg <= {new_key_reg[127:0], key_i};
            end
        end
    end
    //
    //
    always_ff@(posedge clk_i, negedge rst_n_i) begin
        if(~rst_n_i) begin
            nonce_reg <= '0;
        end
        else if(start) begin
			nonce_reg <= '0;
		end
        else begin
            if(get_nonce_do) begin
                nonce_reg <= {nonce_reg[95:0], bd_i};
            end
        end
    end

    //output assignment
    assign run_key_vld_o = key_ctrl[1];
    assign run_key_o = run_key_reg;
    assign nonce_o = nonce_reg;
    //
    //DEBUGGING
    always@(posedge clk_i) begin
        if(start) begin
			$display("*********(GET_NONCE)***********");
			$display("nonce_reg = %h", nonce_reg);
        end
    end

    //DEBUGGING
    //
    always@(posedge clk_i) begin
		if(pass_key) begin
			#20;
			$display("*********(GET_DATA)--KEY***********");
			$display("new_key_reg = %h", new_key_reg);
			$display("run_key_reg = %h", run_key_reg);
		end
    end

endmodule