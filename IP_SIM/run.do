#---------------------------------------------
# Clean output files
#---------------------------------------------
set files {"./OUTPUT/multi_mode_result.txt" "./OUTPUT/comp.txt"}
foreach f $files {
    set fp [open $f w]
    close $fp
}

#---------------------------------------------
# Compile
#---------------------------------------------
vlog -work work\
../RTL/COMMON/config.sv \
../RTL/COMMON/RiSiEdgeDetector.sv \
../RTL/ASCON_CORE/function.sv \
../RTL/ASCON_CORE/ascon_core.sv \
../RTL/ASCON_CORE/sc_fifo.sv \
../RTL/ASCON_CORE/fsm_control.sv \
../RTL/ASCON_CORE/counter.sv \
../RTL/ASCON_CORE/update_state.sv \
../RTL/ASCON_CORE/compare.sv \
../RTL/ASCON_CORE/flag.sv \
../RTL/ASCON_CORE/permutation.sv \
../RTL/ASCON_CORE/get_data.sv \
../RTL/ASCON_CORE/get_config.sv \
../RTL/ASCON_CORE/get_key_nonce.sv \
../RTL/ASCON_CORE/get_ad_text.sv \
../RTL/ASCON_CORE/get_tag.sv \
../RTL/ASCON_CORE/handle_data.sv \
../RTL/ASCON_CORE/store_data.sv \
tb.sv \
-timescale 1ns/1ns \
-l vlog.log \
+cover
#---------------------------------------------
# Optimize design with vopt
#---------------------------------------------
vopt work.tb +acc=rn +cover -o tb_opt

#---------------------------------------------
# Run simulation
#---------------------------------------------
vsim -voptargs="+acc=rn" work.tb -do "
    do add_wave.do;
    run -all;
"
