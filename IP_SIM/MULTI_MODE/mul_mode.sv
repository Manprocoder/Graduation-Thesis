//**************************************************************
//--TEST CASE FOR 5 MODES (12 Test)
//AEAD: ASCON_128, 128a, PQ, 128a,(4 case)
//---(AD (bytes), TEXT(bytes)): (3, 3) (18, 34), (7, 7), (0, 64)
//HASH:XOF, HASH, XOF (3 case)
//(AD(bytes), HASH_CODE(bytes)): (64, 64); (5, 32); (18, 48) (512, 256, 384)
//AEAD: PQ, 128, 128A, 128A: (16, 4); (26, 38); (0, 10), (15, 15) 
//
//***************************************************************

initial begin
    wait(rstn_i_tb);
    #40;
    //
    //ASCON_128
    //FIRST INPUT: 7 bytes AD, 7 bytes TEXT
    //
            write_config(32'b00000000_00000111_00000111_00000100); 
            //ascon_128, 7 bytes AD, 7 bytes TEXT, dec = 0, hash = 0
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
    fork
            write_key(128'h22224444_1111AAAA_66223344_AABBEEFF, 160'h0, 0);
            //key1: 128, key2: 160, xof_mode
        begin
            write_nonce(128'h00000000_00000000_00000000_00000001);
        end
    join
    //write AD
    AD_write_data(64'h82828211_1AB3EEXX, 128'h0, 256'h0, 7, 4'hE);  //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'h44443333_AABBCCXX, 128'h0, 256'h0, 512'h0, 7, 4'hE, 0); //
    //
    //ASCON_HASH_________HASH256
    //2nd INPUT: 5 bytes message, 32 bytes output
    //
        //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
        write_config(32'b00000000_00000101_00100000_00010001); 
        //ascon_xof, 5 bytes AD, 32 bytes output, dec = 0, hash = 1
        write_message(64'h1AB3C589_E3000000, 128'h0, 256'h0, 512'h0, 5, 4'h8);
        //data1(max: 8bytes), data2(max:16 bytes), mes_size, last_mes_vld_byte
    //
    //ASCON_128__Decryption
    //3rd INPUT: 3 bytes AD, 3 bytes TEXT
    //
            write_config(32'b00000000_00000011_00000011_00000110); 
            //ascon_128, 3 bytes AD, 3 bytes TEXT, dec = 1, hash = 0
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
    fork
            write_key(128'h22224444_1111AAAA_66223344_AABBEEFF, 160'h0, 0);
            //key1: 128, key2: 160, xof_mode
        begin
            write_nonce(128'h00000000_00000000_00000000_00000001);
        end
    join
    //write AD
    AD_write_data(64'hXXXXXXXX_1AB3EEXX, 128'h0, 256'h0, 3, 4'hE);  //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'hXXXXXXXX_7E3E16XX, 128'h0, 256'h0, 512'h0, 3, 4'hE, 1); //
    //write TAG
    write_tag(128'hD682E22F_230FAEFF_AFD17CE8_AC8D77FA);
    //
    //ASCON_XOF
    //4th INPUT: 64 bytes MESSAGE, output: 64 bytes
    //
        write_config(32'b00000000_01000000_01000000_00010101); 
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
        //ascon_hash, 64 bytes AD, 64 bytes output dec = 0, hash = 1
        //
        #20;
        write_message(64'h0, 128'h0, 256'h0,
        512'h11110000_22220000_33330000_44440000_4FCF816F_B65763D3_A38824BB_6AAC9780_AABBDDCC_A38824BB_6AAC9780_4FCF816F_B65763D3_A38824BB_6AAC9780_AABBDDCC,
        64, 4'hf);
        //data1(max: 8bytes), data2(max:16 bytes), mes_size, hash_size, last_mes_vld_byte
        //
    //ASCON_128a
    //5TH INPUT: 18 bytes AD, 50 bytes TEXT
    //
           write_config(32'b00000000_00010010_00110010_00001000); 
            //ascon_128a, 18 bytes AD, 50 bytes TEXT, dec = 0, hash = 0
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
    fork
            write_key(128'h22224444_1111AAAA_44445555_AABBEEFF, 160'h0, 0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000002);
        end
    join
    //write AD
    AD_write_data(64'h0, 128'h0, 256'h00000000_00000000_00000000_1AB3C589_E3E64EC6_1AB3C589_E3E64EC6_1FCC0000, 18, 4'hC);  
    //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'h0, 128'h0, 256'h0,
    {96'h0, 416'h4FCF816F_B65763D3_A38824BB_6AAC9780_4FCF816F_B65763D3_A38824BB_6AAC9780_AABB0011_A38824BB_55555555_33333333_22220000},
    50, 4'hC, 0); //
    //
    //ASCON_80PQ
    //6TH INPUT: 7 bytes AD, 7 bytes TEXT
    //
            write_config(32'b00000000_00000111_00000111_00001100); 
            //ascon_80pq, 7 bytes AD, 7 bytes TEXT, dec = 0, hash = 0
    fork
            write_key(128'h0, 160'h1111AAAA_FAFB4444_22226789_66223344_AABBEEFF, 1'b1);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000003);
        end
    join
    //write AD
    AD_write_data(64'hAABBCCDD_123456XX, 128'h0, 256'h0, 7, 4'hE);  //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'hDDDDEEEE_4FCF8100, 128'h0, 256'h0, 512'h0, 7, 4'hE, 0); //
    // 
    //ASCON_128
    //7TH INPUT: 0bit AD, 64 bytes TEXT
    //
            write_config(32'b00000000_00000000_01000000_00000100); 
    fork
            write_key(128'h9D79B1A3_1111AAAA_66223344_AABBEEFF, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000004);
        end
    join
    //write PT
    TEXT_write_data(64'h0, 128'h0, 256'h0, 
    512'h4FCF816F_B65763D3_A38824BB_6AAC9780_4FCF816F_B65763D3_A38824BB_6AAC9780_AABBDDCC_B65763D3_A38824BB_6AAC9780_4FCF816F_B65763D3_A38824BB_AABBDDCC,
    64, 4'hF, 0);
    //ASCON_80PQ
    //8TH INPUT: 16 bytes AD, 4 bytes TEXT
    //
            write_config(32'b00000000_00010000_00000100_00001100); 
    fork
            write_key(128'h0, 160'hEEEE1111_9D79B1A3_1111AAAA_66223344_88882345, 1'b1);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000005);
        end
    join
    //write AD
    AD_write_data(64'h0, 128'h00AACCDD_12345678_87654321_AABBCCEE, 256'h0, 16, 4'hF);  //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'h00000000_4FCF81AB, 128'h0, 256'h0, 512'h0, 4, 4'hF, 0); //
    //
    //ASCON_XOF______HASH_384
    //9TH INPUT: 30 bytes MESSAGE, output: 48 bytes
    //
        write_config(32'b00000000_00011110_00110000_00010101); 
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
        //ASCON_XOF, 30 bytes AD, 48 bytes output dec = 0, hash = 1
        //
        #20;
        write_message(64'h0, 128'h0, 256'h11110000_22220000_33330000_44440000_4FCF0000_4FCF816F_B65763D3_A3880000, 512'h0, 30, 4'hC);

    //
    //ASCON_80PQ
    //10TH INPUT: 26 bytes AD, 38 bytes TEXT
    //
            write_config(32'b00000000_00011010_00100110_00001100); 
    fork
            write_key(128'h0, 160'hEEEE1111_9D79B1A3_66223344_88882345_12359876, 1'b1);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000006);
        end
    join
    //write AD
    AD_write_data(64'h0, 128'h0, 256'h00000000_11AACCDD_12345678_87654321_AABBCCEE_DDDD1111_2222AAAA_33440000, 26, 4'hC);  //data, size(bytes), last_vld_byte
    #20;
    //write PT
    TEXT_write_data(64'h0, 128'h0, 256'h0,
    512'h0000000_00000000_0000000_00000000_00000000_00000000_B65763D3_A38824BB_6AAC9780_AABBDDCC_B65763D3_A38824BB_6AAC9780_4FCF816F_A38824BB_6AAC0000,
    38, 4'hC, 0); //
    //
    //ASCON_128A
    //11TH INPUT: 0 bytes AD, 10 bytes TEXT
    //
            write_config(32'b00000000_00000000_00001010_00001000); 
    fork
            write_key(128'hEEEE1111_9D79B1A3_66223344_88882345, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000007);
        end
    join
    #20;
    //write PT
    TEXT_write_data(64'h0, 128'h00000000_1111AAAA_BBBBCCCC_23450000, 256'h0, 512'h0, 10, 4'hC, 0); //
    //
    //
    //ASCON_128A decryption
    //12TH INPUT: 15 bytes AD, 15 bytes TEXT
    //
            write_config(32'b00000000_00001111_00001111_00001010); 
    fork
            write_key(128'hEEEE1111_9D79B1A3_66223344_88882345, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_0000000C);
        end
    join
    #20;
    AD_write_data(64'h0, 128'h12345643_AAAACFCF_4A5A5AE1_62343300, 256'h0, 15, 4'hE);  
    //write PT
    TEXT_write_data(64'h0, 128'hda35f6df_f4db70da_bdd03d68_c6eb2300, 256'h0, 512'h0, 15, 4'hE, 1); //
    //write TAG
    write_tag(128'hcb94d323_cb084d23_fd8fb662_d02e0fb1);
    //
end