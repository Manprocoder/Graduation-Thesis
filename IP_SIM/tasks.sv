//
//
//import cfg::*;
//parameter
parameter SIZE = 512;
//key
logic clk_i_task;
logic [31:0] key_i_task = 0;
logic key_valid_i_task = 0;
logic key_last_i_task = 0;
logic key_ready_o_task;

//other datas
logic [31:0] bd_i_task = 0;
logic [2:0] bd_type_i_task = 0;
logic [3:0] bd_valid_byte_i_task = 0;
logic bd_valid_i_task = 0;
logic bd_last_i_task = 0;
logic bdi_ready_o_task;
logic [5:0] size_i_task = 0;
logic [6:0] hash_size_i_task = 0;
logic eoi_i_task = 0;
logic ready_o_task;

//additionals
int j = 0, k = 0;
typedef struct packed {
    logic [SIZE-1:0] text;
    logic [SIZE/8-1:0] byteenable; //32 bytes
} text_data;
//(0)
task write_config;
    input logic [31:0] cfg_data;
    begin
        @(posedge clk_i_task)
        bd_i_task <= cfg_data;
        bd_valid_i_task <= 1'b1;
        bd_type_i_task <= D_CFG;
        @(posedge clk_i_task)
        bd_i_task <= 32'd0;
        bd_valid_i_task <= 1'b0;
        bd_type_i_task <= D_NULL;

    end
endtask
//(1)
task write_key;
    input [127:0] key1_data;
    input [159:0] key2_data;
    input [  0:0] mode_pq;
    begin
        k = (mode_pq) ? 4 : 3;
        for(int i = k; i >= 0; i--) begin
            @(posedge clk_i_task)
            key_i_task <= (mode_pq) ? key2_data[i*32 +: 32] : key1_data[i*32 +: 32];
            key_valid_i_task <= 1'b1;
            bd_valid_byte_i_task <= 4'hf;
            key_last_i_task <= (i == 0) ? 1'b1: 1'b0;
            wait(key_ready_o_task);
        end
        @(posedge clk_i_task)
        key_valid_i_task <= 1'b0;
        key_i_task <= 32'd0;
        key_last_i_task <= 1'b0;
    end
    k = 0;
endtask

//(2)
task write_nonce;
    input [127:0] nonce_data;
    begin
        for(int i = 3; i >= 0; i--) begin
            @(posedge clk_i_task)
            bd_i_task <= nonce_data[i*32 +: 32];
            bd_type_i_task <= D_NONCE;
            bd_valid_byte_i_task <= 4'hf;
            bd_last_i_task <= (i == 0) ? 1'b1: 1'b0;
            bd_valid_i_task <= 1'b1;
            wait(bdi_ready_o_task);
        end
        @(posedge clk_i_task)
        bd_i_task <= 32'd0;
        bd_type_i_task <= D_NULL;
        bd_valid_byte_i_task <= 4'h0;
        bd_valid_i_task <= 1'b0;
        bd_last_i_task <= 1'b0;
    end
endtask
//(3)
task write_tag;
    input [127:0] tag_data;
   // input         dec_i;
    begin
        for(int i = 3; i >= 0; i--) begin
            @(posedge clk_i_task)
            bd_i_task <= tag_data[i*32 +: 32];
            bd_type_i_task <= D_TAG;
            bd_valid_byte_i_task <= 4'hf;
            bd_last_i_task <= (i == 0) ? 1'b1: 1'b0;
            bd_valid_i_task <= 1'b1;
            wait(bdi_ready_o_task);
            //
            if(i==0) begin
                begin
                    @(posedge clk_i_task)
                    bd_i_task <= 32'd0;
                    bd_type_i_task <= D_NULL;
                    bd_valid_byte_i_task <= 4'h0;
                    bd_valid_i_task <= 1'b0;
                    bd_last_i_task <= 1'b0;
                    //
                    eoi_i_task <= 1'b1;
                    wait(ready_o_task);
                    @(posedge clk_i_task)
                    eoi_i_task <= 1'b0;
                end
            end
        end

    end
endtask
//*****************************************************
//-------------------------AD------------------------
//*****************************************************
task AD_write_data;
    input [063:0] data1_i;
    input [127:0] data2_i;
    input [255:0] data3_i;
    input [ 6:0] size_i; //(bytes)
    input [ 3:0] last_vld_byte_i;
    begin
        k = (size_i % 4 == 0) ? (size_i/4) : (size_i/4 + 1);
        for(int i = k-1; i >= 0; i--) begin
            @(posedge clk_i_task)
            if(size_i <= 4'd8) bd_i_task <= data1_i[i*32 +: 32];
            else if(size_i <= 5'd16) bd_i_task <= data2_i[i*32 +: 32];
            else bd_i_task <= data3_i[i*32+:32];
            //
            bd_valid_i_task <= 1'b1;
            bd_type_i_task <= D_AD;
            bd_last_i_task <= (i == 0) ? 1'b1 : 1'b0;
            bd_valid_byte_i_task <= (i == 0) ? last_vld_byte_i : 4'hf;
            wait(bdi_ready_o_task);
        end
        @(posedge clk_i_task)
        bd_i_task <= 32'd0;
        bd_valid_i_task <= 1'b0;
        bd_type_i_task <= D_NULL;
        bd_last_i_task <= 1'b0;
        bd_valid_byte_i_task <= 4'h0;
    end
    //k
    k=0;
endtask


//********************************************************
//----------------------TEXT---------------------------
//********************************************************
task TEXT_write_data;
    input [063:0] data1_i;
    input [127:0] data2_i;
    input [255:0] data3_i;
    input [511:0] data4_i;
    input [ 6:0] size_i;
    input [ 3:0] last_vld_byte_i;
    input        dec_i;
    begin
        k = (size_i % 4 == 0) ? (size_i/4) : (size_i/4 + 1);
        for(int i = k-1; i >= 0; i--) begin
            @(posedge clk_i_task)
            if(size_i <= 7'd8) bd_i_task <= data1_i[i*32 +: 32];
            else if(size_i <= 7'd16) bd_i_task <= data2_i[i*32 +: 32];
            else if(size_i <= 7'd32) bd_i_task <= data3_i[i*32 +: 32];
            else bd_i_task <= data4_i[i*32 +: 32];
            bd_valid_i_task <= 1'b1;
            bd_type_i_task <= D_TEXT;
            bd_last_i_task <= (i == 0) ? 1'b1 : 1'b0;
            bd_valid_byte_i_task <= (i == 0) ? last_vld_byte_i : 4'hf;
            wait(bdi_ready_o_task);
            if(i==0) begin
                @(posedge clk_i_task)
                bd_i_task <= 32'd0;
                bd_valid_i_task <= 1'b0;
                bd_type_i_task <= D_NULL;
                bd_last_i_task <= 1'b0;
                bd_valid_byte_i_task <= 4'h0;
                eoi_i_task <= 1'b0;
                //
                if(dec_i == 0) begin
                    eoi_i_task <= 1'b1;
                    wait(ready_o_task);
                    @(posedge clk_i_task)
                    eoi_i_task <= 1'b0;
                end
            end
            //
        end //for loop
        k = 0;
    end
endtask
//*******************************************************************
//-------------------------------HASH---------------------------
//*******************************************************************
task write_message;
    input [063:0] data1_i;
    input [127:0] data2_i;
    input [255:0] data3_i;
    input [511:0] data4_i;
    input [ 6:0] size_i;
    input [ 3:0] last_vld_byte_i;
    begin
        k = (size_i % 4 == 0) ? (size_i/4) : (size_i/4 + 1);
        for(int i = k-1; i >= 0; i--) begin
            @(posedge clk_i_task)

            if(size_i <= 7'd8) bd_i_task <= data1_i[i*32 +: 32];
            else if(size_i <= 7'd16) bd_i_task <= data2_i[i*32 +: 32];
            else if(size_i <= 7'd32) bd_i_task <= data3_i[i*32 +: 32];
            else bd_i_task <= data4_i[i*32 +: 32];
            //
            bd_valid_i_task <= 1'b1;
            bd_type_i_task <= D_AD;
            bd_last_i_task <= (i == 0) ? 1'b1 : 1'b0;
            bd_valid_byte_i_task <= (i == 0) ? last_vld_byte_i : 4'hf;
            wait(bdi_ready_o_task);
            if(i==0) begin
                @(posedge clk_i_task)
                bd_i_task <= 32'd0;
                bd_valid_i_task <= 1'b0;
                bd_type_i_task <= D_NULL;
                bd_last_i_task <= 1'b0;
                bd_valid_byte_i_task <= 4'h0;
                //
                eoi_i_task <= 1'b1;
                wait(ready_o_task);
                @(posedge clk_i_task)
                eoi_i_task <= 1'b0;
            end
        end //end of for loop
        
    end
    //k
    k=0;
endtask
//(4)
task print_data(text_data t, int file);
    begin
      if(file) begin //print to file
        for(int i = SIZE/8-1; i >= 0; i--) begin
          if(t.byteenable[i]) begin
            $fwrite(file, "%02x", t.text[8*i+:8]);
            j++;
            if((j % 8 == 0) & (t.byteenable[j+1])) $fdisplay(file, "");
          end
        end
        $fdisplay(file, "");
        $fdisplay(file, "[valid_byte = %0d bytes] -> 0x%0h", j, t.byteenable);
        j = 0;
      end
      else begin //print to console
        for(int i = SIZE/8-1; i >= 0; i--) begin
          if(t.byteenable[i]) begin
             $write("%02x", t.text[8*i+:8]);
            j++;
            if((j % 8 == 0) & (t.byteenable[j+1])) $display("");
          end
        end
        $display("");
        $display("[valid_byte = %0d bytes] -> 0%0h", j, t.byteenable);
        j = 0;  
      end
    end
endtask

//(5) print mode
task print_mode(mode_type mode_i, int file);
    begin 
        case(mode_i)
            ASCON_128: $fdisplay(file, "*****************************ASCON_128********************************");
            ASCON_128A: $fdisplay(file, "*****************************ASCON_128A*******************************");
            ASCON_80PQ: $fdisplay(file, "*****************************ASCON_80PQ*******************************");
            ASCON_HASH: $fdisplay(file, "*****************************ASCON_HASH*******************************");
            ASCON_XOF: $fdisplay(file, "******************************ASCON_XOF*******************************");
        endcase
    end
endtask

