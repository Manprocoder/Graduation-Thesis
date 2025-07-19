//
//
//
import ascon_cfg::*;
//
`include "falling_edge_detect.sv"
`include "tasks.sv"
module tb;
    //
    //*********************************************
    //-------------PARAMETER----------------
    //*********************************************
    parameter ROUNDS_PER_CYCLE0 = 3;
    parameter ROUNDS_PER_CYCLE1 = 2;
    
    //*********************************************
    //-------------SIMULATION TIME----------------
    //*********************************************
    int     CYCLE = 2000;

    //**********************************************
    //-------------------TB SIGNALS-----------------
    //**********************************************
    //(1)--variables
    text_data HASH_tb = 0, MESS_tb = 0;
    text_data TEXT_tb = 0;
    logic prev_done_o_tb = 0, finish_tb, match_tb = 0;
    int fd_o = 0; //multi_mode_result.txt___path: ./OUTPUT/multi_mode_result.txt
    int fd_comp_o = 0; //comp.txt___  path: ./OUTPUT/comp.txt
    logic [127:0] TAG_tb = 0;
    logic [031:0] valid_data = 0, expected_data = 0;
    //(2)--tb_fsm
    typedef enum logic [0:0] {
        IDLE_TB = 0,
        RUN_TB  = 1
    } state_tb;
    state_tb cs_tb, ns_tb;
    //
    //write results into output file
    //
    //signals to handle HASH mode
    //----------START
    logic [31:0] mes_data_queue [$];
    logic [ 3:0] vld_byte_queue[$];
    logic [ 6:0] mes_size_queue[$];
    logic [ 6:0] used_mes_size_tb = 0;
    logic       mes_size_queue_empty;
    logic       message_in_vld;
    logic prev_bd_last_i_tb, bd_last_falling_edge;
    logic collect_message_in = 0;
    //-----------DONE-----------
    logic pop_mes_size;
    //variables to manage process of writing output to txt file
    logic write_file_start = 0;
    logic write_file_start_falling_edge, prev_write_file_start;
    logic [31:0] counter_tb;
    //convenient to follow in waveforms
    data_type type_i_tb, type_o_tb;
    mode_type mode_i_tb = IDLE_MODE;
    mode_type wf_mode_i_tb = IDLE_MODE;
    //convenient to view in comp.txt file
    logic valid_rising_edge; //rising edge of bd_valid_o_tb
    logic dec_i_tb;
    logic hash_i_tb;
    //************************************
    //(3)--DUT
    logic           clk_i_tb;
    logic           rstn_i_tb;
    logic           key_valid_i_tb;
    logic           key_last_i_tb;
    logic [31:0]    key_i_tb;
    logic           key_ready_o_tb;
    logic           bd_valid_i_tb;
    logic [31:0]    bd_i_tb;
    logic [2:0]     bd_type_i_tb;
    logic           bd_last_i_tb;
    logic [3:0]     bd_valid_byte_i_tb;
    logic           eoi_i_tb;
    logic           bdi_ready_o_tb;
    logic [31:0]    bd_o_tb;
    logic [2:0]     bd_type_o_tb;
    logic           bd_last_o_tb;
    logic           bd_valid_o_tb;
    logic [3:0]     bd_valid_byte_o_tb;
    logic           auth_valid_o_tb;
    logic           tag_match_o_tb;
    logic           ready_o_tb;
    logic           done_o_tb;

    //*******************************************************
    //---------------------TEST_CASE-----------------------
    //*******************************************************
    //`include "./ENC_HASH_CASE/mul_mode.sv";
    //`include "./DEC_HASH_CASE/mul_mode.sv";
    `include "./MULTI_MODE/mul_mode.sv";
    //******************************************************
    //OUTPUT FILE
    //******************************************************
    string            OUT_FILE0 = "./OUTPUT/multi_mode_result.txt";
    string            COMP_FILE = "./OUTPUT/comp.txt";
    //******************************************************
    //-----------EXPECTED VALUES FROM SOFTWARE------------
    //******************************************************
    //`include "enc_hash_model.sv"
    //`include "dec_hash_model.sv"
    `include "multi_mode_model.sv"

    //***********************************************************
    //--------------ASSIGNMENT TASK&TB--------------------------
    //***********************************************************
    assign clk_i_task         = clk_i_tb;
    assign key_ready_o_task   = key_ready_o_tb;
    assign ready_o_task       = ready_o_tb;
    assign bdi_ready_o_task    = bdi_ready_o_tb;
    //
    assign key_last_i_tb      = key_last_i_task;
    assign key_valid_i_tb     = key_valid_i_task;
    assign key_i_tb           = key_i_task;
    assign bd_valid_i_tb      = bd_valid_i_task;
    assign bd_valid_byte_i_tb = bd_valid_byte_i_task;
    assign bd_i_tb            = bd_i_task;
    assign bd_type_i_tb       = bd_type_i_task;
    assign bd_last_i_tb       = bd_last_i_task;
    assign eoi_i_tb           = eoi_i_task;
    //*********************************************************
    //-----------Facilitate waveform watching
    //********************************************************
    assign type_i_tb = data_type'(bd_type_i_tb);
    assign type_o_tb = data_type'(bd_type_o_tb);
    //****************************************************
    //****************************************************
    //---------------------INSTANCE--------------------
    //****************************************************

ascon_core #(ROUNDS_PER_CYCLE0, ROUNDS_PER_CYCLE1) dut_top
(
    //global signals
    .clk_i(clk_i_tb),
    .rst_n_i(rstn_i_tb),
    //key
    .key_valid_i(key_valid_i_tb), 
    .key_last_i(key_last_i_tb),
    .key_i(key_i_tb),
    .key_ready_o(key_ready_o_tb),
    //
    .bd_valid_i(bd_valid_i_tb),
    .bd_i(bd_i_tb),
    //in case of config data
    //{reserved(8 bits), ad_size[23:16], output_size[15:8], mode[4:2], dec, hash}
    //
    .bd_type_i(bd_type_i_tb),
    .bd_last_i(bd_last_i_tb),
    .bd_vld_byte_i(bd_valid_byte_i_tb),
	.eoi_i(eoi_i_tb),
    .bdo_ready_i(1'b1),
    //
    .bdi_ready_o(bdi_ready_o_tb),
    .bd_o(bd_o_tb),
    .bd_type_o(bd_type_o_tb),
    .bd_last_o(bd_last_o_tb),
    .bd_valid_o(bd_valid_o_tb),
    .bd_vld_byte_o(bd_valid_byte_o_tb),
    //
    //authentication signal
    .auth_valid_o(auth_valid_o_tb),
    .tag_match_o(tag_match_o_tb),
    //
	.ready_o(ready_o_tb),
    .done_o(done_o_tb) //
);

    //***********************************************************************************
    //-------------------------------------RUN----------------------------------------
    //***********************************************************************************
    always @(posedge clk_i_tb) begin
      if(bd_valid_o_tb) begin
        if(valid_rising_edge) begin  //print this line into file only eac rising edge of bd_valid_o_tb
            fd_comp_o = $fopen(COMP_FILE, "a");
            print_mode(cmp_mode_tb, fd_comp_o);
            $fdisplay(fd_comp_o, "*****************************ATTEMPT %0d*******************************", (counter_tb+1));
            $fclose(fd_comp_o);
        end
        //check bd_o type
        assert (bd_type_o_tb inside {D_TEXT, D_TAG, D_HASH})
        else $fatal("invalid bd_type_o_tb value at %t", $time);
      //
      
        if (bd_type_o_tb == D_TEXT) begin
            //
            //open output file____extract valid data______make comparison
                //(1)______open file
                fd_comp_o = $fopen(COMP_FILE, "a");
                expected_data = expected_text.pop_front();
                for (int i = 0; i < 4; i++) begin
                    valid_data[i*8 +: 8] = bd_valid_byte_o_tb[i] ? bd_o_tb[i*8 +: 8] : 8'b0;
                end
                //(2)_____make a comparison
                if(valid_data == expected_data) begin
                    $fdisplay(fd_comp_o, "At %0t(ns) MATCHES-----IP_TEXT = %h vs Expected_TEXT = %h", $time, valid_data, expected_data);
                end
                else begin

                    $fdisplay(fd_comp_o, "At %0t(ns) UNMATCHES----IP_TEXT = %h vs Expected_TEXT = %h", $time, valid_data, expected_data);
                end

                TEXT_tb.text <= {TEXT_tb.text[SIZE-33:0], bd_o_tb};
                TEXT_tb.byteenable <= {TEXT_tb.byteenable[SIZE/8-5:0], bd_valid_byte_o_tb};
            $fclose(fd_comp_o);
      end //end of D_TEXT
      if (bd_type_o_tb == D_TAG) begin

           fd_comp_o = $fopen(COMP_FILE, "a");

            expected_data = expected_tag.pop_front();
           if(bd_o_tb == expected_data) begin
                $fdisplay(fd_comp_o, "At %0t(ns) MATCHES------IP_TAG = %h vs Expected_TAG = %h", $time, bd_o_tb, expected_data);
            end
            else begin

                $fdisplay(fd_comp_o, "At %0t(ns) UNMATCHES------IP_TAG = %h vs Expected_TAG = %h", $time, bd_o_tb, expected_data);
            end

          //$display("t => %h", bd_o_tb);
          TAG_tb <= {TAG_tb[95:0], bd_o_tb};
          $fclose(fd_comp_o);
      end
      if (bd_type_o_tb == D_HASH) begin 
        //$display("h => %h", bd_o_tb);
            //open output file________extract data and make comparison
            //(1)____open file
            fd_comp_o = $fopen(COMP_FILE, "a");
            //(2)___extract data
            for (int i = 0; i < 4; i++) begin
                valid_data[i*8 +: 8] = bd_valid_byte_o_tb[i] ? bd_o_tb[i*8 +: 8] : 8'b0;
            end
            expected_data = expected_text.pop_front();

            //(3)____make comparison
            if(valid_data == expected_data) begin
                $fdisplay(fd_comp_o, "At %0t(ns) MATCHES------IP_HASH = %h vs Expected_HASH = %h", $time, valid_data, expected_data);
            end
            else begin

                $fdisplay(fd_comp_o, "At %0t(ns) UNMATCHES------IP_HASH = %h vs Expected_HASH = %h", $time, valid_data, expected_data);
            end

          $fclose(fd_comp_o);
            HASH_tb.text <= {HASH_tb.text[SIZE-33:0], bd_o_tb};
            HASH_tb.byteenable <= {HASH_tb.byteenable[SIZE/8-5:0], bd_valid_byte_o_tb};
      end
      
    end
  end
    //*******************************************************************
    //--------------STORE MESS in case of HASH MODE-------------------
    //********************************************************************
    //(1)--write queue enable 
    assign message_in_vld = bd_valid_i_tb & bdi_ready_o_tb & (bd_type_i_tb == D_AD) & collect_message_in;
    //(2)--bd_last falling edge detect
    //
    falling_edge_detect fed_bd_last_i_tb(
        .clk_i(clk_i_tb),
        .rstn_i(rstn_i_tb),
        .sign_i(bd_last_i_tb),
        .fed_o(bd_last_falling_edge)  //
    );
    //(3)--write file start falling edge detect
    //
    falling_edge_detect fed_write_file_start(
        .clk_i(clk_i_tb),
        .rstn_i(rstn_i_tb),
        .sign_i(write_file_start),
        .fed_o(write_file_start_falling_edge)  //
    );
    //(4)---FSM
    //
    always_comb begin
        case(cs_tb)
            IDLE_TB: ns_tb = (bd_last_falling_edge) ? RUN_TB : IDLE_TB;
            RUN_TB: ns_tb = (done_o_tb & ~eoi_i_tb) ? IDLE_TB : RUN_TB;
        endcase
    end

    always@(posedge clk_i_tb, negedge rstn_i_tb) begin
        if(~rstn_i_tb) cs_tb <= IDLE_TB;
        else cs_tb <= ns_tb;
    end

    //(5)---write valid mes into queue
    //
    always@(posedge clk_i_tb) begin
        if(message_in_vld) begin
            mes_data_queue.push_back(bd_i_tb);
            vld_byte_queue.push_back(bd_valid_byte_i_tb);
        end
    end
    //
    logic push_mes_size_to_queue;
    assign push_mes_size_to_queue = bd_valid_i_tb & (bd_type_i_tb == D_CFG) & bd_i_tb[0];
    always@(posedge clk_i_tb) begin
        if(push_mes_size_to_queue) begin
            mes_size_queue.push_back(bd_i_tb[22:16]);
        end
    end
    //
    assign pop_mes_size = ((cs_tb == IDLE_TB) & bd_last_falling_edge) | ((cs_tb == RUN_TB) & write_file_start_falling_edge);
    assign mes_size_queue_empty = (mes_size_queue.size() == 0);
    always@(posedge clk_i_tb) begin
        if((!mes_size_queue_empty) && pop_mes_size) begin
            used_mes_size_tb <= mes_size_queue.pop_front();
        end
    end
    //(6)--pop data from queue and put them into struct
    //
    logic pop_mes_data;
    assign pop_mes_data = (!(mes_data_queue.size() == 0)) & (used_mes_size_tb > 0);
    //
    always@(posedge clk_i_tb) begin
        if(pop_mes_data) begin
            MESS_tb.text <= {MESS_tb.text[SIZE-33:0], mes_data_queue.pop_front()};
            MESS_tb.byteenable <= {MESS_tb.byteenable[SIZE/8-5:0], vld_byte_queue.pop_front()};
            used_mes_size_tb <= (used_mes_size_tb >= 3'd4) ? (used_mes_size_tb - 3'd4) : 7'd0;
            //read 4 bytes per time
            //
        end
    end

    //************************************************************************************
    //---------------------------- HANDLING HASH MODE DONE ----------------------------
    //************************************************************************************

    //************************************************************************************
    //------------------- Print simulation results of ASCON----------------------------
    //************************************************************************************
    //easier to follow in comp.txt file
RiSiEdgeDetector red_bd_valid_o_tb(
    .clk_i(clk_i_tb),
    .rstn_i(rstn_i_tb),
    .sign_i(bd_valid_o_tb),
    .red_o(valid_rising_edge)  //
);
    //*************************************************
    //----------------handle mode---------------------
    //*************************************************
    //(1)__get new mode
    logic dec_flag[$]; // dec, hash
    logic hash_flag[$];
    mode_type mode_queue [$];
    mode_type cmp_mode_queue [$];
    always @(posedge clk_i_tb) begin
        if(bd_valid_i_tb & (bd_type_i_tb == D_CFG) & bdi_ready_o_tb) begin
            dec_flag.push_back(bd_i_tb[1]);
            hash_flag.push_back(bd_i_tb[0]);
            collect_message_in <= bd_i_tb[0];
            mode_queue.push_back(mode_type'(bd_i_tb[4:2]));
            cmp_mode_queue.push_back(mode_type'(bd_i_tb[4:2]));
            mode_i_tb <= mode_type'(bd_i_tb[4:2]);  //only serve waveform
        end
    end
    //
    //(2)__get mode from queue to print SIM RESULT into file
    //
    always @(posedge clk_i_tb, negedge rstn_i_tb) begin : pass_mode_tb
        if(~rstn_i_tb) begin
            dec_i_tb <= 1'b0;
            hash_i_tb <= 1'b0;
        end
        else if(done_o_tb) begin
            wf_mode_i_tb <= mode_queue.pop_front();
            dec_i_tb <= dec_flag.pop_front();
            hash_i_tb <= hash_flag.pop_front();
        end
    end
    //(3)__handle mode for COMP.TXT file
    mode_type cmp_mode_tb;
    //(3.1) valid signal
    logic valid_mode;
    always @(posedge clk_i_tb) begin
        if(bd_valid_i_tb & (bd_type_i_tb == D_CFG)) begin
            valid_mode <= 1'b1;
        end
        else valid_mode <= 1'b0;
    end
    //(3.2) get mode to print into comp.txt file
    logic first_get, rest_get;
    assign first_get = (cs_tb == IDLE_TB) & valid_mode;
    assign rest_get  = ~first_get & finish_tb;
    always @(posedge clk_i_tb) begin
        if(first_get | rest_get) cmp_mode_tb <= cmp_mode_queue.pop_front();
    end
    //
    //STORE VERIFY TAG RESULT
    always @(posedge auth_valid_o_tb) begin
        match_tb <= tag_match_o_tb;
    end
    //
    always @(posedge clk_i_tb) begin
        prev_done_o_tb <= done_o_tb;
    end
    //
    //PRINT ALL SIM RESULTS into FILE
    //
    assign finish_tb = (prev_done_o_tb & ~done_o_tb);
  //
  always @(posedge finish_tb) begin
        
        $display("*************************************************");
        $display("****************ATTEMPT %0d DONE!!!***************", (counter_tb + 1));
        $display("*************************************************");
        //
        //
        begin
            //--------------------------------------------
            //----------print to output file-------------
            //--------------------------------------------
            write_file_start = 1;
                fd_o = $fopen(OUT_FILE0, "a");
                print_mode(wf_mode_i_tb, fd_o);
                $fdisplay(fd_o, "******************************ATTEMPT %0d*****************************", (counter_tb + 1));
                if(hash_i_tb) begin
                    $fwrite(fd_o, "MESSAGE: ");
                    $fdisplay(fd_o, "");
                    print_data(MESS_tb, fd_o);
                    $fwrite(fd_o, "HASH_CODE: ");
                    $fdisplay(fd_o, "");
                    print_data(HASH_tb, fd_o);
                end
                else begin
                    if(~dec_i_tb) begin
                        $fwrite(fd_o, "CIPHERTEXT: ");
                        $fdisplay(fd_o, "");
                        print_data(TEXT_tb, fd_o); //
                        $fdisplay(fd_o, "TAG: %h_%h", TAG_tb[127:64], TAG_tb[63:00]);
                        $fdisplay(fd_o, "");
                    end
                    else begin
                        $fdisplay(fd_o, "v => %h____%0s", match_tb, match_tb ? "TAG_MATCHES" : "TAG_UNMATCHES");
                        $fwrite(fd_o, "PLAINTEXT: ");
                        $fdisplay(fd_o, "");
                        print_data(TEXT_tb, fd_o);
                    end
                end
            //********************MUL MODE DONE*****************************//
            $fclose(fd_o);
        end
        //join
        #20;
        begin
            TEXT_tb <= '0;
            TAG_tb  <= '0;
            HASH_tb <= '0;
            MESS_tb <= '0;
        end
        #20;
        write_file_start = 0;
  end
    //****************************************
    //--------counter to track---------------
    always@(posedge clk_i_tb) begin
        if(~rstn_i_tb) counter_tb <= '0;
        else if(done_o_tb & ~eoi_i_tb) begin
            #20;
            counter_tb <= '0;
        end
        else if(finish_tb) begin
            counter_tb <= counter_tb + 1'd1;
        end
    end
    initial begin
        clk_i_tb = 0;
        forever #10 clk_i_tb = ~clk_i_tb;
    end

    initial begin
        rstn_i_tb = 1'b0;
        #40;
        rstn_i_tb = 1'b1;
        #(10*CYCLE);
        $finish;
    end

endmodule 