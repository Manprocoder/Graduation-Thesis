
//**************************************************************
//--TEST CASE FOR 5 MODES (10 Test)
//AEAD: ASCON_128, 128a, PQ, 128a,(4 case)
//---(AD (bytes), TEXT(bytes)): (3, 3) (18, 34), (7, 7), (0, 64)
//HASH:XOF, HASH, XOF (3 case)
//(AD(bytes), HASH_CODE(bytes)): (64, 64); (5, 32); (18, 48) (512, 256, 384)
//AEAD: PQ, 128, 128A: (16, 4); (26, 38); (0, 10) 
//
//***************************************************************

initial begin
    wait(rstn_i_tb);
    #40;
    //ASCON_128
    //FIRST INPUT: 3 bytes AD, 3 bytes TEXT
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
    //ASCON_128a
    //SECOND INPUT: 18 bytes AD, 50 bytes TEXT
    //
           write_config(32'b00000000_00010010_00110010_00001010); 
            //ascon_128a, 18 bytes AD, 50 bytes TEXT, dec = 1, hash = 0
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
    {96'h0, 416'hb6320386_e90456c1_60ae4bc5_58df8cf4_2cce47ec_969387fa_ad26f537_e2de2e6f_d56ae251_7ccab096_902bd55b_8ffcf9dc_c3fd0000}, 50, 4'hC, 1);
    //write TAG
    write_tag(128'hca636b5a_3e8f66a6_2a73ab46_259fa2e5);
    //
    //ASCON_XOF
    //3RD INPUT: 64 bytes MESSAGE, output: 64 bytes
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
    //
    //ASCON_80PQ
    //4TH INPUT: 7 bytes AD, 7 bytes TEXT
    //
            write_config(32'b00000000_00000111_00000111_00001110); 
            //ascon_80pq, 7 bytes AD, 7 bytes TEXT, dec = 1, hash = 0
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
    TEXT_write_data(64'h593a507e_aed4fe00, 128'h0, 256'h0, 512'h0, 7, 4'hE, 1);
    //write TAG
    write_tag(128'h0db2bfe4_b71fc8a5_6709216b_82efc37e);
    // 
    //ASCON_128
    //5TH INPUT: 0bit AD, 64 bytes TEXT
    //
            write_config(32'b00000000_00000000_01000000_00000110); 
    fork
            write_key(128'h9D79B1A3_1111AAAA_66223344_AABBEEFF, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000004);
        end
    join
    //write CT
    TEXT_write_data(64'h0, 128'h0, 256'h0,
    512'h20339eff_1a012060_a4baf56a_31216e85_544d9132_d420c9cb_caf719dd_612fd925_ee0b7bf8_a33d5052_0ba1ae41_9e66e60f_c69a5a6c_70c479ae_3c4d42d0_36ce9510,
    64, 4'hF, 1);
    //write TAG
    write_tag(128'h3b1e60db_ffc3dda9_2179a2bb_951d3c4b);
    //************************************************************
    //------------------HASH FUNCTION------------------
    //**************************************************************
    //
    //ASCON_HASH
    //6TH INPUT: 5 bytes message, 32 bytes output
    //
        //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
        write_config(32'b00000000_00000101_00100000_00010001); 
        //ascon_xof, 5 bytes AD, 32 bytes output, dec = 0, hash = 1
        write_message(64'h1AB3C589_E3000000, 128'h0, 256'h0, 512'h0, 5, 4'h8);
        //data1(max: 8bytes), data2(max:16 bytes), mes_size, last_mes_vld_byte
    //
    //ASCON_80PQ
    //7TH INPUT: 16 bytes AD, 4 bytes TEXT
    //
            write_config(32'b00000000_00010000_00000100_00001110); 
    fork
            write_key(128'h0, 160'hEEEE1111_9D79B1A3_1111AAAA_66223344_88882345, 1'b1);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000005);
        end
    join
    //write AD
    AD_write_data(64'h0, 128'h00AACCDD_12345678_87654321_AABBCCEE, 256'h0, 16, 4'hF);  //data, size(bytes), last_vld_byte
    #20;
    //write CT
    TEXT_write_data(64'h00000000_0025caff, 128'h0, 256'h0, 512'h0, 4, 4'hF, 1);
    //write TAG
    write_tag(128'ha389972a_7b7e3bcb_a8b30e3c_b5832e66);
    //write_tag(128'hd20ede62_e736e0b6_bb949838_40d7ab99);
    //
    //ASCON_XOF
    //8TH INPUT: 30 bytes MESSAGE, output: 48 bytes
    //
        write_config(32'b00000000_00011110_00110000_00010101); 
            //{reserved (13 bits), ad_size[22:16], output_size[14:8], mode[4:2], dec, hash}
        //ascon_hash, 18 bytes AD, 48 bytes output dec = 0, hash = 1
        //
        #20;
        write_message(64'h0, 128'h0, 256'h11110000_22220000_33330000_44440000_4FCF0000_4FCF816F_B65763D3_A3880000, 512'h0, 30, 4'hC);
//*************************************************************************
//-----------------3 last ascon mode in 10 test case
//*************************************************************************
//
    //
    //ASCON_80PQ
    //9TH INPUT: 26 bytes AD, 38 bytes TEXT
    //
            write_config(32'b00000000_00011010_00100110_00001110); 
    fork
            write_key(128'h0, 160'hEEEE1111_9D79B1A3_66223344_88882345_12359876, 1'b1);
            //write_key(128'hEEEE1111_9D79B1A3_66223344_88882345, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000006);
        end
    join
    //write AD
    AD_write_data(64'h0, 128'h0, 256'h00000000_11AACCDD_12345678_87654321_AABBCCEE_DDDD1111_2222AAAA_33440000, 26, 4'hC);  //data, size(bytes), last_vld_byte
    #20;
    //write CT
    TEXT_write_data(64'h0, 128'h0, 256'h0,
    512'h0000000_00000000_00000000_00000000_00000000_00000000_4f29e7e6_4e5cc8cd_e8ec8e71_c2ed21a0_022302cd_dc050df4_3274e050_c9877e84_9f6cd642_19e20000,
    38, 4'hC, 1);
    //write TAG
    write_tag(128'hd58399ee_4965817f_0c3ab01d_d45c2f36);
    //
    //ASCON_128A
    //10TH INPUT: 0 bytes AD, 10 bytes TEXT
    //
            write_config(32'b00000000_00000000_00001010_00001010); 
    fork
            write_key(128'hEEEE1111_9D79B1A3_66223344_88882345, 160'h0, 1'b0);
        begin
            write_nonce(128'h00000000_00000000_00000000_00000007);
        end
    join
    #20;
    //write CT
    TEXT_write_data(64'h0, 128'h00000000_d03991aa_f67ae4ba_a65e0000, 256'h0, 512'h0, 10, 4'hC, 1);
    //write TAG
    write_tag(128'hcadfd009_2523adb0_c0d6b356_f78e333d);
    //
    //
end