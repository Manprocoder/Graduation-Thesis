package func; 
//********************************************
//--file: function.sv
//--des: 
//********************************************
//************************************
//(1) --- select bd to do XOR
function logic [63:0] chosen_bd;
    input logic  [03:0]   size_i;  //ad_size or text_size
    input logic           last_block_i;
    input logic           last_flag_i;
    input logic  [03:0]   last_vld_byte_i;
    input logic  [63:0]   data_i;

    begin
        if(|size_i) begin //ad_size is not multiple of 8, or 8-bytes input(ascon_128a)
            if(last_flag_i) begin //ascon_128a
                if(last_vld_byte_i == 4'hf) begin
                    chosen_bd = {32'h80000000, 32'd0};
                end
                else chosen_bd = 64'd0;
                //-----handle ascon_128a done-----//
            end
            //else begin 
            else if(last_block_i) begin
               chosen_bd = last_bd(size_i, last_vld_byte_i, data_i); 
            end
            else begin
                chosen_bd = data_i;
            end
        end
        //ideal
        // ad_size(bytes) is a multiple of 8
        else begin
            chosen_bd = data_i; 
        end
    end
endfunction

//****************************************
//last_bd
function logic [63:0] last_bd;
    input logic [3:0] size_i;
    input logic [3:0] vld_byte_i;
    input logic [63:0] data_i;
    begin
        if(|size_i) begin  //| [3:0]
            if(vld_byte_i == 4'hf) begin //only two cases: 4 bytes or 8 bytes
                if(size_i[3]) begin
                    last_bd = data_i;
                end
                else begin
                    last_bd = {data_i[63:32], 32'h80000000};
                end
            end
            else begin  //others case, call pad function
                if(size_i[2]) begin
                    last_bd = {data_i[63:32], pad(data_i[31:0], vld_byte_i)};
                end
                else begin
                    last_bd = {pad(data_i[63:32], vld_byte_i), 32'd0};
                end
            end
        end //if |size_i[2:0]
        else begin
            last_bd = data_i;
        end
    end
endfunction
//****************************************
//pad
function logic [31:0] pad;
    input logic [31:0]  bd_i;
    input logic [3:0]   bd_valid_byte_i;
    //
    begin
        case(bd_valid_byte_i)
            4'h8: pad = {bd_i[31:24], 24'h800000};
            4'hC: pad = {bd_i[31:16], 16'h8000};
            4'hE: pad = {bd_i[31:08], 08'h80};
            default: pad = bd_i; 
        endcase
    end
    //
endfunction
//****************************************
//word cnt
function logic [6:0] len_in_words;
    input [6:0] size_in_byte;
    //
    begin
        len_in_words = (size_in_byte % 3'd4 == 0) ? (size_in_byte / 3'd4) : (size_in_byte / 3'd4 + 1'd1);
    end
endfunction

//****************************************
//word cnt
function logic [6:0] block_cnt;
    input [6:0] size_in_byte;
    //
    begin
        block_cnt = (size_in_byte % 4'd8 == 0) ? (size_in_byte / 4'd8) : (size_in_byte / 4'd8 + 1'd1);
    end
endfunction
endpackage: func