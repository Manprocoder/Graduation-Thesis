
//**************************************************************
//-----------------DECRYPTION AND HASH----------------------
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
    //1ST INPUT, ASCON_128, 3 bytes AD, 3 bytes TEXT
    expected_text.push_back(32'haabbcc00);
    //2ND INPUT, ASCON_128A, 18 bytes AD, 50 bytes TEXT
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'hAABB0011);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h55555555);
    expected_text.push_back(32'h33333333);
    expected_text.push_back(32'h22220000);
    //3RD INPUT, ASCON_XOF, 64 bytes AD, 64 bytes OUTPUT
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
    //
    //4TH INPUT, ASCON_80PQ, 7 bytes AD, 7 bytes TEXT
    expected_text.push_back(32'hDDDDEEEE);
    expected_text.push_back(32'h4FCF8100);
    //5TH INPUT, ASCON_128, 0 bytes AD, 64 bytes TEXT
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'hAABBDDCC);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'hAABBDDCC);
    //6TH INPUT, ASCON_HASH, 5 bytes AD, 32 bytes OUTPUT
    expected_text.push_back(32'h11d30c75);
    expected_text.push_back(32'hde217f56);
    expected_text.push_back(32'hbe51a58e);
    expected_text.push_back(32'h2cbf60f1);
    expected_text.push_back(32'h19376fbc);
    expected_text.push_back(32'ha38be581);
    expected_text.push_back(32'hcfd0058d);
    expected_text.push_back(32'h98084e02);
    //7TH INPUT, ASCON_PQ, 16 bytes AD, 4 bytes TEXT
    expected_text.push_back(32'h4FCF81AB);
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
    //9TH INPUT, ASCON_80PQ, 26 bytes AD, 38 bytes TEXT
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'hAABBDDCC);
    expected_text.push_back(32'hB65763D3);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC9780);
    expected_text.push_back(32'h4FCF816F);
    expected_text.push_back(32'hA38824BB);
    expected_text.push_back(32'h6AAC0000);
    //10TH INPUT, ASCON_128a, 0 bytes AD, 10 bytes TEXT
    expected_text.push_back(32'h1111AAAA);
    expected_text.push_back(32'hBBBBCCCC);
    expected_text.push_back(32'h23450000);
    //
    //
end