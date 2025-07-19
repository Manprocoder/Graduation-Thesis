onerror {resume}
quietly WaveActivateNextPane {} 0
#add wave -noupdate -divider -height 23 {ASCON_CORE_INTERFACE}
add wave -noupdate /tb/dut_top/clk_i
add wave -noupdate /tb/dut_top/rst_n_i
#add wave -noupdate /tb/mode_i_tb
add wave -noupdate -hex /tb/dut_top/key_i
add wave -noupdate /tb/dut_top/key_valid_i
#add wave -noupdate /tb/dut_top/key_last_i
add wave -noupdate /tb/dut_top/key_ready_o
add wave -noupdate -hex /tb/dut_top/bd_i
add wave -noupdate /tb/dut_top/bd_valid_i
add wave -noupdate /tb/dut_top/bdi_ready_o
#add wave -noupdate /tb/dut_top/bd_last_i
add wave -noupdate /tb/dut_top/bd_vld_byte_i
#add wave -noupdate /tb/type_i_tb
add wave -noupdate /tb/type_o_tb
add wave -noupdate -hex /tb/dut_top/bd_o
add wave -noupdate /tb/dut_top/bd_valid_o
add wave -noupdate -hex /tb/dut_top/bd_vld_byte_o
add wave -noupdate /tb/dut_top/eoi_i
add wave -noupdate /tb/dut_top/ready_o
add wave -noupdate /tb/dut_top/done_o
add wave -noupdate /tb/dut_top/tag_match_o
add wave -noupdate /tb/dut_top/auth_valid_o
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {TEST BENCH SIGNALS}
#add wave -noupdate -hex /tb/CT_tb.text
#add wave -noupdate -hex /tb/CT_tb.byteenable
#add wave -noupdate -hex /tb/TAG_tb
#add wave -noupdate -hex /tb/mes_enable
#add wave -noupdate -hex /tb/MESS_tb.text
#add wave -noupdate -hex /tb/MESS_tb.byteenable
#add wave -noupdate -hex /tb/HASH_tb.text
#add wave -noupdate -hex /tb/HASH_tb.byteenable
#add wave -noupdate -hex /tb/put_size_into_queue
#add wave -noupdate -hex /tb/empty_size_queue
#add wave -noupdate -unsigned /tb/mes_size_tb
#add wave -noupdate  /tb/get_size_enable
#add wave -noupdate  /tb/first_get
#add wave -noupdate  /tb/rest_get
#add wave -noupdate /tb/cmp_mode_tb
#add wave -noupdate  /tb/dec_i_tb
#add wave -noupdate  /tb/hash_i_tb
#add wave -noupdate  /tb/finish_tb
#add wave -noupdate  /tb/cs_tb
#add wave -noupdate  /tb/ns_tb
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {GET_CONFIG U0/C0/G0}
#add wave -noupdate /tb/dut_top/u0/c0/clk_i
#add wave -noupdate /tb/dut_top/u0/c0/g0/get_cfg_do
#add wave -noupdate /tb/dut_top/u0/c0/g0/pass_cfg
#add wave -noupdate /tb/dut_top/u0/c0/g0/mode_reg
#add wave -noupdate /tb/dut_top/u0/c0/g0/hash_reg
#add wave -noupdate /tb/dut_top/u0/c0/g0/dec_reg
#add wave -noupdate -unsigned /tb/dut_top/u0/c0/g0/text_words_o
#add wave -noupdate -unsigned /tb/dut_top/u0/c0/g0/ad_blocks_o
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {GET_KEY_NONCE U0/C0/G1}
#add wave -noupdate /tb/dut_top/u0/c0/g1/get_key_do
#add wave -noupdate -hex /tb/dut_top/u0/c0/g1/run_key_o
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {GET_AD_TEXT U0/C0/G2}
#add wave -noupdate /tb/dut_top/u0/c0/g2/clk_i
#add wave -noupdate /tb/dut_top/u0/c0/g2/ad_fifo_empty
#add wave -noupdate /tb/dut_top/u0/c0/g2/ad_fifo_rd
#add wave -noupdate -hex /tb/dut_top/u0/c0/g2/run_ad_o
#add wave -noupdate /tb/dut_top/u0/c0/g2/ad_rd_done
#add wave -noupdate -unsigned /tb/dut_top/u0/c0/g2/ad_block_cnt
#add wave -noupdate  /tb/dut_top/u0/c0/g2/text_fifo_rd
#add wave -noupdate  -hex /tb/dut_top/u0/c0/g2/run_text_o
#add wave -noupdate /tb/dut_top/u0/c0/g2/text_rd_done
#add wave -noupdate -unsigned /tb/dut_top/u0/c0/g2/word_cnt
#add wave -noupdate /tb/dut_top/u0/c0/g2/valid_data
#add wave -noupdate /tb/dut_top/u0/c0/g2/complete
#add wave -noupdate -hex /tb/dut_top/u0/c0/g2/tmp_vld_data_reg
#add wave -noupdate -hex /tb/dut_top/u0/c0/g2/tmp_vld_byte_reg
#add wave -noupdate -hex /tb/dut_top/u0/c0/g2/ad_fifo_data_i
#add wave -noupdate  /tb/dut_top/u0/c0/g2/ad_fifo_wr
#add wave -noupdate -hex /tb/dut_top/u0/c0/g2/text_fifo_data_i
#add wave -noupdate  /tb/dut_top/u0/c0/g2/text_fifo_wr
#add wave -noupdate -hex /tb/dut_top/u0/c0/new_key_reg
#add wave -noupdate -hex /tb/dut_top/u0/c0/run_key_reg
#add wave -noupdate -hex /tb/dut_top/u0/c0/nonce_reg
#------------------------------------------------------------------------#
#------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {GET_TAG U0/C0/G3}
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/tag_fifo_wr
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/tag_fifo_i
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/get_tag_done
#add wave -noupdate /tb/dut_top/u0/c0/g3/tag_ctrl
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/tag_fifo_rd
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/tag_fifo_o
#add wave -noupdate -hex /tb/dut_top/u0/c0/g3/run_tag_o
#------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {COUNTER U1}
#add wave -noupdate -unsigned /tb/dut_top/u1/abs_cnt_o
#add wave -noupdate -unsigned /tb/dut_top/u1/run_cnt_o
#add wave -noupdate  /tb/dut_top/u1/eom_active_i
#add wave -noupdate -unsigned /tb/dut_top/u1/rounds_a0
#add wave -noupdate -unsigned /tb/dut_top/u1/rounds_a1
#add wave -noupdate -unsigned /tb/dut_top/u1/rounds_b
#add wave -noupdate -unsigned /tb/dut_top/u1/abs_ad_done
#add wave -noupdate -unsigned /tb/dut_top/u1/abs_text_done
#add wave -noupdate -unsigned /tb/dut_top/u1/pdo_i
#add wave -noupdate -unsigned /tb/dut_top/u1/round_cnt_o
#-------------------------------------------------------------------------#
add wave -noupdate -divider -height 23 {HANLDE_DATA U0/C1}
#add wave -noupdate /tb/dut_top/u0/c1/clk_i
#add wave -noupdate -hex /tb/dut_top/u0/c1/xor_tag_reg
#add wave -noupdate -hex /tb/dut_top/u0/c1/full_key_i
add wave -noupdate /tb/dut_top/u0/c1/cs
add wave -noupdate /tb/dut_top/u0/c1/start
add wave -noupdate /tb/dut_top/u0/c1/run_mode_i
#add wave -noupdate /tb/dut_top/u0/c1/pdone_i
#add wave -noupdate /tb/dut_top/u0/c1/eot_add_key
#add wave -noupdate /tb/dut_top/u0/c1/final_ct
add wave -noupdate /tb/dut_top/u0/c1/hash_flag_i
add wave -noupdate /tb/dut_top/u0/c1/dec_flag_i
add wave -noupdate -unsigned /tb/dut_top/u0/c1/ad_size_i
add wave -noupdate -unsigned /tb/dut_top/u0/c1/text_bytes_i
#add wave -noupdate -hex /tb/dut_top/u0/c1/ad_data_i
#add wave -noupdate  /tb/dut_top/u0/c1/last_ad_flag
#add wave -noupdate  /tb/dut_top/u0/c1/ad_last
#add wave -noupdate  /tb/dut_top/u0/c1/invalid_flag
#add wave -noupdate  /tb/dut_top/u0/c1/text_last
#add wave -noupdate -hex /tb/dut_top/u0/c1/text_data_i
#add wave -noupdate -hex /tb/dut_top/u0/c1/state_i
#add wave -noupdate -hex /tb/dut_top/u0/c1/selected_bd
#add wave -noupdate -hex /tb/dut_top/u0/c1/xor_result
#add wave -noupdate -hex /tb/dut_top/u0/c1/new_state_o
#add wave -noupdate /tb/dut_top/u0/c1/almost_done_o
#add wave -noupdate -unsigned /tb/dut_top/u0/hash_blocks
#add wave -noupdate -unsigned /tb/dut_top/u0/text_words
#add wave -noupdate /tb/dut_top/u0/last_cc_i
#-------------------------------------------------------------------------#
add wave -noupdate -divider -height 23 -color blue {STORE_DATA}
#add wave -noupdate -unsigned /tb/dut_top/u0/c1/h0/text_words_cnt
#add wave -noupdate /tb/dut_top/u0/c1/h0/end_of_text
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {RESULT FIFO}
add wave -noupdate /tb/dut_top/u0/c1/h0/fifo_wr
add wave -noupdate /tb/dut_top/u0/c1/h0/fifo_rd
add wave -noupdate -hex /tb/dut_top/u0/c1/h0/fifo_data_i
add wave -noupdate -hex /tb/dut_top/u0/c1/h0/fifo_data_o
#add wave -noupdate -unsigned /tb/dut_top/u0/c1/h0/fifo_usedw
#add wave -noupdate /tb/dut_top/u0/c1/h0/fifo_empty
#add wave -noupdate /tb/dut_top/u0/c1/h0/rd_done_o
#-------------------------------------------------------------------------#
add wave -noupdate -divider -height 23 -color blue {FLAG U0/C1/H1}
add wave -noupdate /tb/dut_top/u0/c1/h1/last_ad_block_i
#add wave -noupdate /tb/dut_top/u0/c1/h1/last_ad_trigger
add wave -noupdate /tb/dut_top/u0/c1/h1/last_text_block_i
#add wave -noupdate /tb/dut_top/u0/c1/h1/last_text_trigger
add wave -noupdate /tb/dut_top/u0/c1/h1/invalid_flag_o
#-------------------------------------------------------------------------#
#add wave -noupdate -divider -height 20 {PERMUTATION OTHERS}
#add wave -noupdate /tb/dut_top/u3/clk_i
#add wave -noupdate -unsigned /tb/dut_top/u2/p_others/round_cnt_i
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x0_i
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x1_i
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x2_i
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x3_i
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x4_i
#
#add wave -r -hex /tb/dut_top/u2/p_others/x0
#add wave -r -hex /tb/dut_top/u2/p_others/x1
#add wave -r -hex /tb/dut_top/u2/p_others/x2
#add wave -r -hex /tb/dut_top/u2/p_others/x3
#add wave -r -hex /tb/dut_top/u2/p_others/x4
#add wave -r -hex /tb/dut_top/u2/p_others/c

#add wave -r -hex /tb/dut_top/u2/p_others/x0_update
#add wave -r -hex /tb/dut_top/u2/p_others/x1_update
#add wave -r -hex /tb/dut_top/u2/p_others/x2_update
#add wave -r -hex /tb/dut_top/u2/p_others/x3_update
#add wave -r -hex /tb/dut_top/u2/p_others/x4_update
#add wave -r -hex /tb/dut_top/u2/p_others/x0_aff1
#add wave -r -hex /tb/dut_top/u2/p_others/x1_aff1
#add wave -r -hex /tb/dut_top/u2/p_others/x2_aff1
#add wave -r -hex /tb/dut_top/u2/p_others/x3_aff1
#add wave -r -hex /tb/dut_top/u2/p_others/x4_aff1
#
#
#add wave -r -hex /tb/dut_top/u2/p_others/x0_map
#add wave -r -hex /tb/dut_top/u2/p_others/x1_map
#add wave -r -hex /tb/dut_top/u2/p_others/x2_map
#add wave -r -hex /tb/dut_top/u2/p_others/x3_map
#add wave -r -hex /tb/dut_top/u2/p_others/x4_map
#
#
#add wave -r -hex /tb/dut_top/u2/p_others/x0_aff2
#add wave -r -hex /tb/dut_top/u2/p_others/x1_aff2
#add wave -r -hex /tb/dut_top/u2/p_others/x2_aff2
#add wave -r -hex /tb/dut_top/u2/p_others/x3_aff2
#add wave -r -hex /tb/dut_top/u2/p_others/x4_aff2

#add wave -noupdate -hex /tb/dut_top/u2/p_others/x0_o
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x1_o
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x2_o
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x3_o
#add wave -noupdate -hex /tb/dut_top/u2/p_others/x4_o
#-------------------------------------------------------------#
#add wave -noupdate -divider -height 23 -color blue {COMPARE u3}
#add wave -noupdate /tb/dut_top/u3/match_reg
#add wave -noupdate -hex /tb/dut_top/u3/xor_tag_i
#add wave -noupdate -hex /tb/dut_top/u3/in_tag_i
#-------------------------------------------------------------#
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {925 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 145
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1050 ns}