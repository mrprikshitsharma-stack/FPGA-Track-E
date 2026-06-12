# hls/ex3_passthrough/run_hls.tcl
open_project ex3_passthrough_prj
set_top passthrough_stream
add_files passthrough.cpp
add_files -tb tb_passthrough.cpp
open_solution sol1 -flow_target vivado
set_part xc7z100ffg900-2
create_clock -period 10 -name default
csim_design
csynth_design
exit
# Run: vitis_hls -f run_hls.tcl