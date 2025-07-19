#---------------------------------------------
# Clean output files
#---------------------------------------------
set files {"./OUTPUT/multi_mode_result.txt" "./OUTPUT/comp.txt"}
foreach f $files {
    set fp [open $f w]
    close $fp
}