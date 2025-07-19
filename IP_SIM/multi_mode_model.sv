

//**************************************************************
//-----------------ENC, DEC AND HASH----------------------
//--TEST CASE FOR 5 MODES (10 Test)
//AEAD: ASCON_128, 128a, PQ, 128a,(4 case)
//---(AD (bytes), TEXT(bytes)): (3, 3) (18, 34), (7, 7), (0, 64)
//HASH:XOF, HASH, XOF (3 case)
//(AD(bytes), HASH_CODE(bytes)): (64, 64); (5, 32); (18, 48) (512, 256, 384)
//AEAD: PQ, 128, 128A: (16, 4); (26, 38); (0, 10) 
//
//***************************************************************
int MUL_MODE = 1; //run multiple modes in single simulation
//
//

logic [31:0] expected_tag[$];
logic [31:0] expected_text[$];
//
//text queue
//
initial begin
    //1ST_a INPUT, ASCON_128, 7 bytes AD, 7 bytes TEXT, encryption
    expected_text.push_back(32'hb9da0fae);
    expected_text.push_back(32'h57dde800);
    //
    //6TH INPUT, ASCON_HASH, 5 bytes AD, 32 bytes OUTPUT
    expected_text.push_back(32'h11d30c75);
    expected_text.push_back(32'hde217f56);
    expected_text.push_back(32'hbe51a58e);
    expected_text.push_back(32'h2cbf60f1);
    expected_text.push_back(32'h19376fbc);
    expected_text.push_back(32'ha38be581);
    expected_text.push_back(32'hcfd0058d);
    expected_text.push_back(32'h98084e02);
    //1ST_b INPUT, ASCON_128, 3 bytes AD, 3 bytes TEXT, deccryption
    expected_text.push_back(32'haabbcc00);
    //3rd INPUT, ASCON_XOF, 64 bytes AD, 64 bytes OUTPUT
    expected_text.push_back(32'h145cee06);
    expected_text.push_back(32'hb7cf3c72);
    expected_text.push_back(32'h1c64d36c);
    expected_text.push_back(32'hca51f2bc);
    expected_text.push_back(32'h18cf7a1f);
    expected_text.push_back(32'h2d437cd5);
    expected_text.push_back(32'h40e90dc0);
    expected_text.push_back(32'h5359e494);
    expected_text.push_back(32'hb7413214);
    expected_text.push_back(32'hf272c779);
    expected_text.push_back(32'heead01ac);
    expected_text.push_back(32'hb4e84ec8);
    expected_text.push_back(32'h5845f5f0);
    expected_text.push_back(32'h2583068c);
    expected_text.push_back(32'hd06e825a);
    expected_text.push_back(32'h4f47e428);
    //4TH INPUT, ASCON_128A, 18 bytes AD, 50 bytes TEXT
    expected_text.push_back(32'hb6320386);
    expected_text.push_back(32'he90456c1);
    expected_text.push_back(32'h60ae4bc5);
    expected_text.push_back(32'h58df8cf4);
    expected_text.push_back(32'h2cce47ec);
    expected_text.push_back(32'h969387fa);
    expected_text.push_back(32'had26f537);
    expected_text.push_back(32'he2de2e6f);
    expected_text.push_back(32'hd56ae251);
    expected_text.push_back(32'h7ccab096);
    expected_text.push_back(32'h902bd55b);
    expected_text.push_back(32'h8ffcf9dc);
    expected_text.push_back(32'hc3fd0000);
    //4TH INPUT, ASCON_80PQ, 7 bytes AD, 7 bytes TEXT
    expected_text.push_back(32'h593a507e);
    expected_text.push_back(32'haed4fe00);
    //5TH INPUT, ASCON_128, 0 bytes AD, 64 bytes TEXT
    expected_text.push_back(32'h20339eff);
    expected_text.push_back(32'h1a012060);
    expected_text.push_back(32'ha4baf56a);
    expected_text.push_back(32'h31216e85);
    expected_text.push_back(32'h544d9132);
    expected_text.push_back(32'hd420c9cb);
    expected_text.push_back(32'hcaf719dd);
    expected_text.push_back(32'h612fd925);
    expected_text.push_back(32'hee0b7bf8);
    expected_text.push_back(32'ha33d5052);
    expected_text.push_back(32'h0ba1ae41);
    expected_text.push_back(32'h9e66e60f);
    expected_text.push_back(32'hc69a5a6c);
    expected_text.push_back(32'h70c479ae);
    expected_text.push_back(32'h3c4d42d0);
    expected_text.push_back(32'h36ce9510);
    //7TH INPUT, ASCON_PQ, 16 bytes AD, 4 bytes TEXT
    expected_text.push_back(32'h0025caff);
    //8TH INPUT, ASCON_XOF, 30 bytes AD, 48 bytes OUTPUT
    expected_text.push_back(32'hc050f7a6);
    expected_text.push_back(32'he6594411);
    expected_text.push_back(32'hd096a2fe);
    expected_text.push_back(32'h52b5a57a);
    expected_text.push_back(32'h38dd3e83);
    expected_text.push_back(32'hc47d1387);
    expected_text.push_back(32'hb726b7de);
    expected_text.push_back(32'h8391d8bd);
    expected_text.push_back(32'he41ded87);
    expected_text.push_back(32'hbebba3f4);
    expected_text.push_back(32'h1788a3f4);
    expected_text.push_back(32'hde3d8e8d);
    //9TH INPUT, ASCON_PQ, 26 bytes AD, 38 bytes TEXT
    expected_text.push_back(32'h4f29e7e6);
    expected_text.push_back(32'h4e5cc8cd);
    expected_text.push_back(32'he8ec8e71);
    expected_text.push_back(32'hc2ed21a0);
    expected_text.push_back(32'h022302cd);
    expected_text.push_back(32'hdc050df4);
    expected_text.push_back(32'h3274e050);
    expected_text.push_back(32'hc9877e84);
    expected_text.push_back(32'h9f6cd642);
    expected_text.push_back(32'h19e20000);

    //10TH INPUT, ASCON_128a, 0 bytes AD, 10 bytes TEXT
    //ciphertext
    expected_text.push_back(32'hd03991aa);
    expected_text.push_back(32'hf67ae4ba);
    expected_text.push_back(32'ha65e0000);
    //11TH INPUT, ASCON_128a, 15 bytes AD, 15 bytes TEXT
    //plaintext
    expected_text.push_back(32'h1111AAAA);
    expected_text.push_back(32'hBBBBCCCC);
    expected_text.push_back(32'h23450011);
    expected_text.push_back(32'h2267AE00);
    //
    //
end
//
//tag queue
//
initial begin

    //1ST INPUT, ASCON_128, 7 bytes AD, 7 bytes TEXT
    expected_tag.push_back(32'hedb5bce1);
    expected_tag.push_back(32'h19463a70);
    expected_tag.push_back(32'h6000184a);
    expected_tag.push_back(32'h3eef5115);
    //
    /*expected_tag.push_back(32'hd682e22f);
    expected_tag.push_back(32'h230faeff);
    expected_tag.push_back(32'hafd17ce8);
    expected_tag.push_back(32'hac8d77fa);*/
    //2ND INPUT, ASCON_128A, 18 bytes AD, 50 bytes TEXT
    expected_tag.push_back(32'hca636b5a);
    expected_tag.push_back(32'h3e8f66a6);
    expected_tag.push_back(32'h2a73ab46);
    expected_tag.push_back(32'h259fa2e5);
    //3RD INPUT, ASCON_80PQ, 7 bytes AD, 7 bytes TEXT
    expected_tag.push_back(32'h0db2bfe4);
    expected_tag.push_back(32'hb71fc8a5);
    expected_tag.push_back(32'h6709216b);
    expected_tag.push_back(32'h82efc37e);
    //4TH INPUT, ASCON_128, 0 bytes AD, 64 bytes TEXT
    expected_tag.push_back(32'h3b1e60db);
    expected_tag.push_back(32'hffc3dda9);
    expected_tag.push_back(32'h2179a2bb);
    expected_tag.push_back(32'h951d3c4b);
    //8TH INPUT, ASCON_PQ, 16 bytes AD, 4 bytes TEXT
    expected_tag.push_back(32'ha389972a);
    expected_tag.push_back(32'h7b7e3bcb);
    expected_tag.push_back(32'ha8b30e3c);
    expected_tag.push_back(32'hb5832e66);
    //9TH INPUT, ASCON_PQ, 26 bytes AD, 38 bytes TEXT
    expected_tag.push_back(32'hd58399ee);
    expected_tag.push_back(32'h4965817f);
    expected_tag.push_back(32'h0c3ab01d);
    expected_tag.push_back(32'hd45c2f36);
    //10TH INPUT, ASCON_128a, 0 bytes AD, 10 bytes TEXT
    expected_tag.push_back(32'hcadfd009);
    expected_tag.push_back(32'h2523adb0);
    expected_tag.push_back(32'hc0d6b356);
    expected_tag.push_back(32'hf78e333d);
    //
    //
    //
end


