//
//
//
package ascon_cfg;

    //******************************************
    //MODE
    //******************************************
    typedef enum logic [2:0]  { IDLE_MODE  = 3'd0,
                                ASCON_128  = 3'd1,
                                ASCON_128A = 3'd2,
                                ASCON_80PQ = 3'd3,
                                ASCON_HASH = 3'd4,
                                ASCON_XOF  = 3'd5
    } mode_type;
    //******************************************
    //DATA TYPE
    //******************************************
    typedef enum logic [2:0]  { D_NULL  = 3'h0,
                                D_CFG   = 3'h1,
                                D_NONCE = 3'h2, 
                                D_AD    = 3'h3, 
                                D_TEXT  = 3'h4, 
                                D_HASH  = 3'h5, 
                                D_TAG   = 3'h6 //
    } data_type;
    //******************************************
    //FSM
    //******************************************
    
	typedef enum logic [3:0] {  
                                IDLE        = 4'd0,  
								INIT_PER	= 4'd1,
                                INIT_DOM    = 4'd2,
                                ABS_AD      = 4'd3,        
                                SQZ_HASH    = 4'd4,
								SEP_DOM     = 4'd5,
                                ABS_TEXT    = 4'd6,
                                AD_PER      = 4'd7,
                                TEXT_PER    = 4'd8,
                                FINAL_PER   = 4'd9,
                                DO_TAG   	= 4'd10,
                                AUTH_TAG    = 4'd11,
                                GEN_TAG     = 4'd12,
                                GEN_TEXT    = 4'd13
    } state_fsm;
    

    //***************************************************                            
    //ROUNDS CONSTANT AND KEY WIDTH
    //***************************************************
    localparam logic [3:0] ROUNDS_A = 12;
    localparam logic [3:0] ROUNDS_B0 = 6;
    localparam logic [3:0] ROUNDS_B1 = 8;


    //****************************************************
    //--MODE CONSTANT
    //****************************************************
    localparam logic [63:0] AS128_IV   = 64'h80400c0600000000; //ASCON_128 AE_IV
    localparam logic [63:0] AS128A_IV  = 64'h80800c0800000000; //ASCON_128a
    localparam logic [31:0] AS80PQ_IV  = 32'ha0400c06;         //ASCON_80pq
    localparam logic [63:0] H_IV       = 64'h00400c0000000100; //ASCON_HASH IV
    localparam logic [63:0] XOF_IV     = 64'h00400c0000000000; //ASCON_XOF IV
    
endpackage: ascon_cfg


package dma_cfg;
	//
	typedef enum logic [2:0] {
			  FORMAT_IDLE = 3'd0,
			  FORMAT_CFG  = 3'd1,
			  FORMAT_K    = 3'd2,
			  FORMAT_N    = 3'd3,
			  FORMAT_AD   = 3'd4,
			  FORMAT_TEXT = 3'd5,
			  FORMAT_TAG  = 3'd6

	 } fmt_state;
    //
    //format function
    //
    function logic [40:0] f_data;
        input logic eoi_i;
        input logic bd_last_i;
        input logic [3:0] vld_bytes_i;
        input logic [2:0] bd_type_i;
        input logic [31:0] bd_i;
        //
        //
        begin
            if(bd_last_i) begin
                f_data = {eoi_i, 1'b1, vld_bytes_i, bd_type_i, bd_i};
            end
            else begin
                f_data = {1'b0, 1'b0, 4'hf, bd_type_i, bd_i};
            end
        end
    endfunction
    //
	 //calculate word count
	 //
	 function logic [7:0] word_cnt;
			input [7:0] size_in_byte;
			//
		  begin
				word_cnt = (size_in_byte % 3'd4 == 0) ? (size_in_byte / 3'd4) : (size_in_byte / 3'd4 + 1'd1);
		  end
	 endfunction
    //
endpackage: dma_cfg