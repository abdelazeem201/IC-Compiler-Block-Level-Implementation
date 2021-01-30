puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################
## Optimization Common Session Options - set in all sessions

## To display verbose messages during DRC fixing, setup fixing, hold fixing, multiple-port-net fixing and tie-off optimization
#  in preroute stage, set the following before place_opt :
# 	Off (default)        : set_app_var preroute_opt_verbose 0  
# 	General      	     : set_app_var preroute_opt_verbose 1  
# 	DRC                  : set_app_var preroute_opt_verbose 2 
# 	Hold                 : set_app_var preroute_opt_verbose 4  
# 	General + DRC + hold : set_app_var preroute_opt_verbose 7
# 	Tie-off              : set_app_var preroute_opt_verbose 8  
# 	Multiple port nets   : set_app_var preroute_opt_verbose 16 
#	Setup                : set_app_var preroute_opt_verbose 32
#
# The messages can also be saved to the file propt_verbose.log for the setup and DRC messages only. 
#       Setup & DRC          : set_app_var preroute_opt_verbose 162 ;# 128 + 32 + 2

## In H-2013.03, default settings for set_delay_calculation_options are 
#  -preroute elmore -routed_clock arnoldi -postroute arnoldi

# Default setting for preroute delay calculation is Elmore.
# To use AWE delay calculation set the ICC_PREROUTE_AWE_EFFORT variable to HIGH|MEDIUM|LOW
switch $ICC_PREROUTE_AWE_EFFORT {
  HIGH { set_delay_calculation_options -preroute awe -awe_effort high }
  MEDIUM { set_delay_calculation_options -preroute awe -awe_effort medium }
  LOW { set_delay_calculation_options -preroute awe -awe_effort low }
  default { set_delay_calculation_options -preroute elmore }
}

# Default setting for postroute delay calculation is Arnoldi medium effort
# To change the effort level set the ICC_ARNOLDI_EFFORT variable to HIGH|HYBRID|MEDIUM|LOW
switch $ICC_ARNOLDI_EFFORT {
  HIGH { set_delay_calculation_options -postroute arnoldi -arnoldi_effort high}
  HYBRID { set_delay_calculation_options -postroute arnoldi -arnoldi_effort hybrid}
  MEDIUM { set_delay_calculation_options -postroute arnoldi -arnoldi_effort medium}
  LOW { set_delay_calculation_options -postroute arnoldi -arnoldi_effort low}
  default { set_delay_calculation_options -postroute arnoldi -arnoldi_effort medium}
}

## To save the library cell derate settings to the design, uncomment the following variable setting
#  set_app_var timing_save_library_derate true

## General Optimization
set_host_options -max_cores $ICC_NUM_CORES
set_app_var timing_enable_multiple_clocks_per_reg true 
set_fix_multiple_port_nets -all -buffer_constants  
if {$ICC_TIE_CELL_FLOW} {
  set_auto_disable_drc_nets -constant false
} else {
  set_auto_disable_drc_nets -constant true
} 
## Evaluate whether you library and design requires timing_use_enhanced_capacitance_modeling or not. Also only needed for OCV
#	set_app_var timing_use_enhanced_capacitance_modeling true 
#       PT default - libraries with capacitance ranges (also see Solvnet 021686)

## Set dont use cells
#  Examples, big drivers (EM issues), very weak drivers, delay cells, clock cells
if {[file exists [which $ICC_IN_DONT_USE_FILE]] } { 
  source -echo  $ICC_IN_DONT_USE_FILE 
} 

## Fix hard macro locations
if {[all_macro_cells] != "" } { 
  set_attribute [all_macro_cells] is_fixed true 
}

## Set the buffering strategy for optimization
#  IC Compiler default is -effort none (the command is not enabled)
#  If the command is used without -effort option, then -effort medium is used.
#  Use the command with -effort high typically results in better reduction in buffer/inverter counts.
#  The command only works with preroute optimization, place_opt and clock_opt.

# 	set_buffer_opt_strategy -effort high


   if {$ICC_MAX_AREA != ""} {
     set_max_area $ICC_MAX_AREA
   }

## Set Area Critical Range
#  Typical value: 10 percent of critical clock period
if {$AREA_CRITICAL_RANGE_PRE_CTS != ""} {set_app_var physopt_area_critical_range $AREA_CRITICAL_RANGE_PRE_CTS} 

## Set Power Critical Range
#  Typical value: 9 percent of critical clock period
if {$POWER_CRITICAL_RANGE_PRE_CTS != ""} {set_app_var physopt_power_critical_range $POWER_CRITICAL_RANGE_PRE_CTS} 

## Script for customized set_multi_vth_constraints constraints. Effective only when $POWER_OPTIMIZATION is set to TRUE.
#  Specify to make leakage power optimization focused on lvt cell reduction. Refer to rm_icc_scripts/multi_vth_constraint.example as an example.
if {[file exists [which $ICC_CUSTOM_MULTI_VTH_CONSTRAINT_SCRIPT]] } { 
        source -echo  $ICC_CUSTOM_MULTI_VTH_CONSTRAINT_SCRIPT 
}

## In I-2013.12 ICC there is a new cell attribute "optimization_stage" that indicates
# at what stage of optimization a cell was inserted. This allows for better tracking   
# and investigation of a design after optimization. The stage can be queried with
# "get_attribute cellName optimization_stage" or with a command to report a summary
# of tracked cells:
#
# e.g.
#	report_optimization_created_cells 
#	get_cells -hierarchical -filter "optimization_stage == hfs"
#	get_flat_cells -filter "optimization_stage == setup"
#
# These are the following stages that can be found on cells after optimization:
#
#   setup               cell created at setup optimization stage
#   drc                 cell created at DRC fixing stage
#   hold                cell created at hold optimization stage
#   hfs                 cell created at HFS fixing stage
#   tie_optimization    cell created at tie-optimization stage 
#   port_fixing         cell created at multi-port-net fixing or port isolation stage
#
# This feature works with the following optimization commands:
#
# place_opt, psynopt, clock_opt, route_opt, focal_opt, preroute_focal_opt,
# place_opt_feasibility, clock_opt_feasibility

## End of Common Optimization Session Options

puts "RM-Info: Completed script [info script]\n"
