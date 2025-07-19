# ------------------------------------------------------------------------------
# Top Level Simulation Script to source msim_setup.tcl
# ------------------------------------------------------------------------------
set QSYS_SIMDIR obj/default/runtime/sim
source msim_setup.tcl
# Copy generated memory initialization hex and dat file(s) to current directory
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/hdl_sim/system_onchip_memory2_0.dat ./ 
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/hdl_sim/system_onchip_memory2_1.dat ./ 
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/hdl_sim/system_onchip_memory2_2.dat ./ 
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/system_onchip_memory2_0.hex ./ 
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/system_onchip_memory2_1.hex ./ 
file copy -force C:/ASCON_SYSTEM/software/ascon_system/mem_init/system_onchip_memory2_2.hex ./ 
