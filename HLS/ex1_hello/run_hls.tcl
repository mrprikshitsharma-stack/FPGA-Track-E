open_project ex1_hello_prj

set_top passthrough

add_files hello.cpp

open_solution sol1 -flow_target vivado

set_part xc7z100ffg900-2

create_clock -period 10 -name default

csynth_design
export_design -format ip_catalog
exit
