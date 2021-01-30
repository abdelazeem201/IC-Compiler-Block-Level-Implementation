remove_scenario -all

suppress_message UID-401

############################################################
create_scenario func_worst

read_sdc ORCA_TOP_func_worst.sdc
set_tlu_plus_files \
	-max_tluplus $TLUPLUS_MAX_FILE \
	-tech2itf_map $MAP_FILE

set_timing_derate -early 0.95

set_switching_activity -toggle_rate 0.07 [remove_from_collection [all_inputs] [get_ports *clk]]
set_app_var power_default_toggle_rate 0.005

set_scenario_options -setup true -hold false -leakage_power false -dynamic_power true

############################################################
create_scenario test_worst

read_sdc ORCA_TOP_test_worst.sdc
set_tlu_plus_files \
	-max_tluplus $TLUPLUS_MAX_FILE \
	-tech2itf_map $MAP_FILE

set_timing_derate -early 0.95

set_scenario_options -setup true -hold false -leakage_power false

############################################################
create_scenario func_best

read_sdc ORCA_TOP_func_best.sdc
set_tlu_plus_files \
	-max_tluplus $TLUPLUS_MIN_FILE \
	-tech2itf_map $MAP_FILE

set_timing_derate -late 1.05
set_scenario_options -setup false -hold true -leakage_power false

############################################################
create_scenario test_best

read_sdc ORCA_TOP_test_best.sdc
set_tlu_plus_files \
	-max_tluplus $TLUPLUS_MIN_FILE \
	-tech2itf_map $MAP_FILE

set_timing_derate -late 1.05
set_scenario_options -setup false -hold true -leakage_power false

############################################################
create_scenario leak
set_operating_conditions ff0p95v125c -analysis_type on_chip_variation
read_sdc ORCA_TOP_clocks_only.sdc
set_voltage 0    -object_list VSS
set_voltage 0.95 -object_list VDD
set_voltage 1.16 -object_list VDDH
set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE -tech2itf_map $MAP_FILE
set_scenario_options -setup false -hold false -leakage_power true

current_scenario func_worst
