create_scenario func_best_hot

read_sdc ORCA_TOP_func_best.sdc
set_operating_conditions -analysis_type on_chip_variation ff0p95v125c
set_tlu_plus_files \
        -max_tluplus $TLUPLUS_MIN_FILE \
        -tech2itf_map $MAP_FILE

set_timing_derate -late 1.05
set_scenario_options -setup false -hold true -leakage_power false

############################################################
create_scenario test_best_hot

read_sdc ORCA_TOP_test_best.sdc
set_operating_conditions -analysis_type on_chip_variation ff0p95v125c
set_tlu_plus_files \
        -max_tluplus $TLUPLUS_MIN_FILE \
        -tech2itf_map $MAP_FILE

set_timing_derate -late 1.05
set_scenario_options -setup false -hold true -leakage_power false

foreach s {func_best_hot test_best_hot} {
	current_scenario $s
        set_clock_uncertainty -setup 0.05 [all_clocks]
        set_clock_uncertainty -hold 0.00 [all_clocks]
	set_fix_hold [all_clocks]
}

# The SDC files apply ideal networks to some clocks , which apply globally to all scenarios. 
# These ideal networks are normally removed after CTS , but since we are applying these 
# constraints after CTS, we need to explicitly remove the ideal networks: 
remove_ideal_network [all_fanout -flat -clock_tree]


propagate_all_clocks

current_scenario func_worst

