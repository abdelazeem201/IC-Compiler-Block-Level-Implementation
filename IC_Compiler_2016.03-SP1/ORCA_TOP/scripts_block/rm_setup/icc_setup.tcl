puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables for IC Compiler Reference Methodology, IC Compiler Design Planning Reference 
# Methodology, and IC Compiler Hierarchical Reference Methodology 
# Script: icc_setup.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

# Sourcing the common variables
source -echo ../../scripts_block/rm_setup/common_setup.tcl 

###############################
## Flow Variables
###############################
set ICC_INIT_DESIGN_INPUT         "DDC"         ;# VERILOG|DDC|MW; specify the type of starting point;
					       ;# if "VERILOG" is specified, you should also specify a valid $ICC_IN_VERILOG_NETLIST_FILE
					       ;# if "DDC" is specified, you should also specify a valid $ICC_IN_DDC_FILE 
					       ;# if "MW" is specified, you should also specify a valid $ICC_INPUT_CEL
					       ;# If MW is specified, script will copy Milkyway design library from rm_dc/work/dc to rm_icc/work 
set POWER_OPTIMIZATION            TRUE         ;# TRUE|FALSE; set TRUE to enable power optimization (-power option) for the core commands such as place_opt, clock_opt, 
				               ;# route_opt, and focal_opt. If $ICC_CUSTOM_MULTI_VTH_CONSTRAINT_SCRIPT below is also specified, 
					       ;# leakage power optimization is focused on lvt cell reduction; otherwise focused on leakage power reduction.
					       ;# for MCMM, set set_scenario_options -leakage true to enable leakage power optimization on scenarios;
					       ;# see rm_icc_scripts/mcmm.scenarios.example for more details.
set ICC_PLACE_LOW_POWER_PLACEMENT FALSE	       ;# TRUE|FALSE; set TRUE to enable low power placement for place_opt; requires $POWER_OPTIMIZATION to be TRUE to be effective.

					       ;# for MCMM, this feature requires you to set set_scenario_options -dynamic true;
					       ;# see rm_icc_scripts/mcmm.scenarios.example for more details.
set ICC_CUSTOM_MULTI_VTH_CONSTRAINT_SCRIPT ""  ;# script for customized set_multi_vth_constraints constraints. effective only when $POWER_OPTIMIZATION is set to TRUE;
					       ;# specify to make leakage power optimization focused on lvt cell reduction; 
					       ;# refer to rm_icc_scripts/multi_vth_constraint.example as an example.	   
set DFT                           TRUE	       ;# TRUE|FALSE; set TRUE to enable scan reordering flow and add -optimize_dft option to place_opt and clock_opt commands;
					       ;# if set TRUE, you should also provide a valid $ICC_IN_SCAN_DEF_FILE
set ICC_TIE_CELL_FLOW             TRUE        ;# TRUE|FALSE, set TRUE if you want TIE-CELLS to be used during optimizations instead of TIE-nets
set ICC_DBL_VIA                   TRUE         ;# TRUE|FALSE; set TRUE to enable redundant via insertion; more options in "Chipfinishing and Metal Fill Variables" section
set ICC_FIX_ANTENNA               TRUE        ;# TRUE|FALSE: set TRUE to enable antenna fixing; more options in "Chipfinishing Variables" section
set ADD_FILLER_CELL               TRUE        ;# TRUE|FALSE; set TRUE to enable std cells filler insertion; more options in "Chipfinishing Variables" section
set ICC_CREATE_MODEL              FALSE        ;# TRUE|FALSE; set TRUE to create block abstraction and FRAM view (at block level)
set ICC_REDUCE_CRITICAL_AREA      TRUE         ;# TRUE|FALSE; set TRUE to enable detail route wire spreading
set ADD_METAL_FILL                "ICV"        
					       ;# Note : It is recommended to use ICV with signoff_metal_fill command for technology nodes 45nm and below
                                               
                                               ;# ICV : signoff_metal_fill using IC Validator
set ICC_REPORTING_EFFORT          "MED"        ;# OFF|LOW|MED; if set to OFF, no reporting is done; if set to LOW, report_qor/report_constraints/report_power are skipped,
					       ;# additionally, report_timing is skipped in clock_opt_cts
set ICC_SANITY_CHECK              FALSE        ;# TRUE|FALSE, set TRUE to perform check_physical_design
set ICC_ENABLE_CHECKPOINT	  FALSE	       ;# TRUE|FALSE, set TRUE to perform checkpoint strategy for optimization commands 
					       ;# ensure there is enough disk space before enabling this feature. refer to the set_checkpoint_strategy man page for details.

###############################
## General Variables
###############################
set ICC_INPUT_CEL                 "${DESIGN_NAME}_DCT" ;# starting CEL for flow with a Milkyway CEL input which can be the final CEL from Design Compiler Topographical 
set PNET_METAL_LIST               "M2"           	;# List of metals in the design to be used for (partial) pnet options
set PNET_METAL_LIST_COMPLETE	  ""	       	;# List of metals in the design to be used for (complete) pnet options
set ICC_IN_DONT_USE_FILE          "$LIBRARY_DONT_USE_FILE" ;# script with library modifications for dont_use; default to $LIBRARY_DONT_USE_FILE in common_setup.tcl 
set ICC_FIX_HOLD_PREFER_CELLS     ""           	;# Syntax: library/cell_name - Example: slow/DLY1X1 slow/DLY1X4
set ICC_MAX_AREA                  ""           	;# max_area value used during area optimization
set MW_EXTENDED_LAYER_MODE        FALSE         ;# FALSE|TRUE: Default FALSE creates a Milkyway design library with the default layer mode that supports user defined and routing layers on layers 1-187 in the technology file. Setting this to TRUE will create a library in the extended layer mode that supports from layers 1-4000 in the technology file. 
set AREA_CRITICAL_RANGE_PRE_CTS   ""           	;# area critical range use during area optimization during place_opt
set AREA_CRITICAL_RANGE_POST_CTS  ""           	;# area critical range use during area optimization during post-CTS optimization 
set AREA_CRITICAL_RANGE_POST_RT   ""           	;# area critical range use during area optimization during route_opt
set POWER_CRITICAL_RANGE_PRE_CTS  ""           	;# power critical range use during area optimization during place_opt
set POWER_CRITICAL_RANGE_POST_CTS ""           	;# power critical range use during area optimization during post-CTS optimization 
set POWER_CRITICAL_RANGE_POST_RT  ""           	;# power critical range use during area optimization during route_opt
set ICC_NUM_CPUS                  1            	;# number of cpus for distributed processing
					       	;# specify a number greater than 1 to enable it for classic router based route_opt and insert_redundant_via commands
set ICC_NUM_CORES                 4            	;# number of cores on the local host for multicore support; 4 cores are recommended for IC Validator based signoff_metal_fill and
						;# signoff_drc commands
if {[info exists TEV(num_cores)] && [info exists env(LYNX_RTM_PRESENT)]} {
set ICC_NUM_CORES                 $TEV(num_cores)  ;# TEV(num_cores) must be used to control the number of cores when running in Lynx;
                                                   ;# Only configure TEV(num_cores) using the Lynx RTM or by editing at the top of the LCRM script
}
set PLACE_OPT_EFFORT 		  "medium"      ;# low|medium|high; choose effort level for place_opt command
set PLACE_OPT_TRADEOFF_TIMING_FOR_POWER_AREA FALSE ;# TRUE|FALSE; set TRUE to enable timing, power and area tradeoff optimization for place_opt command.
						   ;# It only works for medium effort place_opt with -power option
set ROUTE_OPT_EFFORT 		  "medium"      ;# low|medium|high; choose effort level for route_opt command
set PLACE_OPT_CONGESTION_DRIVEN	  TRUE          ;# TRUE|FALSE; set TRUE to enable congestion removal during place_opt command (place_opt_icc step) and 
						;# clock_opt -only_psyn command (clock_opt_psyn_icc step) 

set PLACE_OPT_LAYER_OPTIMIZATION	"TRUE" ;# TRUE|FALSE: Set to TRUE by default to control whether layer optimization is performed during place_opt by set_place_opt_strategy -layer_optimization 

set PLACE_OPT_LAYER_OPTIMIZATION_EFFORT	"MEDIUM" ;# medium|high: Set to medium by default. Controls the layer optimization effort during place_opt

set PLACE_OPT_CONSIDER_ROUTING		"FALSE" ;# FALSE|TRUE: Default FALSE. Controls whether track RC based optimization is performed during place_opt
						;# The RC models are generated from the current scenario so set the most critical scenario as the current scenario before running place_opt
set ICC_TOTAL_POWER_STRATEGY_EFFORT	none	;# none|medium|high; set to medium or high to improve total power (leakage + dynamic)
						;# A realistic SAIF will be needed to get accurate power savings
                                                ;# For MCMM design an active scenario with dynamic_power, leakage_power, and setup enabled is necessary for total power optimization
						;# Applies to place_opt -power, psynopt -power, and psynopt -only_power

set ICC_HIGH_RESISTANCE_OPTIMIZATION	"FALSE" ;# FALSE|TRUE: Default FALSE. Setting to TRUE will enable the high resistance optimization for route_opt and focal_opt. This feature may see increased effect on 20nm and below designs. 

set ICC_TNS_EFFORT_PREROUTE		"MEDIUM" ;# MEDIUM|HIGH: Default MEDIUM. Controls the effort of preroute optimization to explore TNS improvements. When set to HIGH preroute optimzation will spend longer looking for TNS improvements. Affects place_opt, clock_opt -only_psyn, psynopt, and preroute_focal_opt.

set ICC_TNS_EFFORT_POSTROUTE		"MEDIUM" ;# MEDIUM|HIGH: Default MEDIUM. Controls the effort of postroute optimization to explore TNS improvements. When set to HIGH postroute optimzation will spend longer looking for TNS improvements. Affects route_opt and focal_opt.

set PLACE_OPT_PREROUTE_FOCALOPT_LAYER_OPTIMIZATION FALSE 
						;# TRUE|FALSE; set TRUE to perform layer optimization (preroute_focal_opt -layer_optimization) 
						;# on existing buffer trees after place_opt command (place_opt_icc step)
set CLOCK_OPT_PSYN_PREROUTE_FOCALOPT_LAYER_OPTIMIZATION FALSE 
						;# TRUE|FALSE; set TRUE to perform layer optimization (preroute_focal_opt -layer_optimization) 
						;# on existing buffer trees after clock_opt -only_psyn command (clock_opt_psyn_icc step)
set CLOCK_OPT_PSYN_PREROUTE_FOCALOPT_AUTO_NDR FALSE
						;# TRUE|FALSE; set TRUE will perform optimization with automatic routing rules (preroute_focal_opt -auto_routing_rule) 
						;# on existing buffer trees after clock_opt -only_psyn command (clock_opt_psyn_icc step)
set ICC_CREATE_GR_PNG             FALSE  	;# TRUE|FALSE; set TRUE to create a global route congestion map snapshot in PNG format at the end of route_icc step
set ICC_WRITE_FULL_CHIP_VERILOG   FALSE		;# TRUE|FALSE; set TRUE for write_verilog in outputs_icc.tcl to write out module definitions for soft macros 

if {![info exists MW_POWER_NET]} {
set MW_POWER_NET 		  "VDD"
}
if {![info exists MW_POWER_PORT]} {
set MW_POWER_PORT                 "VDD"
}
if {![info exists MW_GROUND_NET]} {
set MW_GROUND_NET                 "VSS"
}
if {![info exists MW_GROUND_PORT]} { 
set MW_GROUND_PORT                "VSS"
}

set ICC_FLOORPLAN_CEL            ""	     		     

############################################################
## Customized Constraint Script for Core Commands (Optional)
############################################################ 
set CUSTOM_INIT_DESIGN_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced before the read_def command;
						;# review init_design_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_PLACE_OPT_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right before the place_opt core command;
						;# review place_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_PLACE_OPT_POST_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right after the place_opt core command;
						;# review place_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
  set CUSTOM_CLOCK_OPT_CTS_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right before the clock_opt -only_cts core command;
						;# review clock_opt_cts_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
  set CUSTOM_CLOCK_OPT_CTS_POST_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right after the clock_opt -only_cts core command;
						;# review clock_opt_cts_icc script for exact location where this is sourced to avoid overlap with existing constraints
  set CUSTOM_CLOCK_OPT_PSYN_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right before the clock_opt -only_psyn core command;
						;# review clock_opt_psyn_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
  set CUSTOM_CLOCK_OPT_PSYN_POST_SCRIPT ""	;# An optional Tcl file; if specified, will be sourced right after the clock_opt -only_psyn core command;
						;# review clock_opt_psyn_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_CLOCK_OPT_ROUTE_PRE_SCRIPT ""	;# An optional Tcl file; if specified, will be sourced before the route_group -all_clock_nets command;
						;# review clock_opt_route_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_CLOCK_OPT_ROUTE_PRE_CTO_SCRIPT ""	;# An optional Tcl file; if specified, will be sourced before the optimize_clock_tree command;
						;# review clock_opt_route_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_CLOCK_OPT_ROUTE_POST_CTO_SCRIPT ""	;# An optional Tcl file; if specified, will be sourced after the optimize_clock_tree command;
						;# review clock_opt_route_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_ROUTE_PRE_SCRIPT ""			;# An optional Tcl file; if specified, will be sourced before the route_opt -initial_route_only command;
						;# review route_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_ROUTE_POST_SCRIPT ""			;# An optional Tcl file; if specified, will be sourced after the route_opt -initial_route_only command;
						;# review route_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_ROUTE_OPT_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right before the route_opt core command;
						;# review route_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_ROUTE_OPT_POST_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced right after the route_opt core command;
						;# review route_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_FOCAL_OPT_PRE_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced before the focal_opt core commands;
						;# review focal_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_FOCAL_OPT_POST_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced after the focal_opt core commands;
						;# review focal_opt_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints
set CUSTOM_CHIP_FINISH_POST_SCRIPT ""		;# An optional Tcl file; if specified, will be sourced before the route_opt -inc -size_only command;
						;# review chip_finish_icc.tcl script for exact location where this is sourced to avoid overlap with existing constraints

###############################
## Floorplan Input Variables          		    
###############################
set ICC_FLOORPLAN_INPUT           	"DEF"   ;# DEF | FP_FILE | CREATE | USER_FILE | SKIP; "DEF" reads $ICC_IN_DEF_FILE; "FP_FILE" reads ICC_IN_FLOORPLAN_FILE;
						;# "CREATE" uses create_floorplan command; "USER_FILE" sources $ICC_IN_FLOORPLAN_USER_FILE; 
						;# "SKIP" skips floorplanning section
set ICC_IN_DEF_FILE		  	"ORCA_TOP.def"	;# Complete floorplan file in DEF format
set ICC_IN_SPG_DEF_FILE		        ""	;# Standard cell placement in DEF format from DC for Physical Guidance flow.
						;# The default naming convention for this file from DC-RM is ${DESIGN_NAME}.mapped.std_cell.def
set ICC_IN_FLOORPLAN_FILE	  	""	;# Complete floorplan file generated by write_floorplan 
set ICC_IN_FLOORPLAN_USER_FILE	  	""	;# Complete floorplan file generated by user; This file will simply be sourced.
set ICC_IN_PIN_PAD_PHYSICAL_CONSTRAINTS_FILE ""	;# I/O constraint file generated by write_pin_pad_physical_constraints which contains pin or pad information
						;# applied prior to create_floorplan command   
set ICC_IN_PHYSICAL_ONLY_CELLS_CREATION_FILE "" ;# a file to include physical-only cell creation commands to be sourced
                                                ;# e.g. create_cell {vdd1left vdd1right vdd1top vdd1bottom} pvdi
set ICC_IN_PHYSICAL_ONLY_CELLS_CONNECTION_FILE "" ;# a file to include physical-only cell connection commands to be sourced
                                                  ;# e.g. derive_pg_connection -power_net $MW_POWER_NET -power_pin $MW_POWER_PORT -ground_net $MW_GROUND_NET -ground_pin $MW_GROUND_PORT -cells {vdd1left vdd1right vdd1top vdd1bottom}

set ICC_PHYSICAL_CONSTRAINTS_FILE 	""	;# script to add incremental floorplan constraints which will be sourced after read_def, read_floorplan, or floorplan creation
set CUSTOM_CONNECT_PG_NETS_SCRIPT 	""      ;# script for customized derive_pg_connection commands which replaces the default derive_pg_connection commands in the scripts   

###############################
## Timing Variables
###############################
set ICC_APPLY_RM_DERATING               FALSE 	;# TRUE|FALSE; when set to FALSE, the derating is assumed to be set in the SDC
set ICC_LATE_DERATING_FACTOR	        1.01 	;# Late derating factor, used for both data and clock 
set ICC_EARLY_DERATING_FACTOR	        0.99 	;# Early derating factor, used for both data and clock 

set ICC_APPLY_RM_UNCERTAINTY_PRECTS     FALSE	;# TRUE|FALSE; when set to TRUE, user uncertainty will be replaced by $ICC_UNCERTAINTY_PRECTS
set ICC_APPLY_RM_UNCERTAINTY_POSTCTS    FALSE	;# TRUE|FALSE; when set to TRUE, user uncertainty will be replaced by $ICC_UNCERTAINTY_POSTCTS
set ICC_UNCERTAINTY_PRECTS_FILE         ""   	;# Pre-cts uncertainty file used during place_opt
set ICC_UNCERTAINTY_POSTCTS_FILE        ""   	;# Post-cts uncertainty file used during post-CTS optimization and route_opt
set ICC_MAX_TRANSITION                  ""   	;# max_transition value set on the design
set ICC_CRITICAL_RANGE                  ""   	;# critical_range set on the design; default = 50% of each clock period
set ICC_MAX_FANOUT                      ""   	;# max_fanout value set on the design
set ICC_ARNOLDI_EFFORT			"MEDIUM"	;# HIGH|HYBRID|MEDIUM|LOW  Default is MEDIUM which runs a combination of Arnoldi and Elmore for postroute delay calculation. 
							;# When set to HIGH, it will enable full Arnoldi postroute delay calculation. 
							;# When set to HYBRID, it will enable a combination of AWE and Arnoldi postroute delay calculation for faster runtime with comparable accuracy to full Arnoldi.
							;# When set to LOW, postroute delay calculation will only use AWE.
set ICC_PREROUTE_AWE_EFFORT		"NONE"	;# HIGH|MEDIUM|LOW|NONE By default preroute delay calculation uses Elmore. Setting this variable to HIGH, MEDIUM, or LOW will enable AWE for preroute delay calculation at different effort levels.

set ICC_IN_AOCV_TABLE_FILE		""	;# A file containing advanced on-chip variation (OCV) derate factor tables written out by PrimeTime's write_binary_aocvm command 
						;# If specified, it will be read right before clock_opt -only_psyn command at clock_opt_psyn_icc step and AOCV analysis will be enabled
						;# In the Concurrent Clock and Data flow it will be read before any clock_opt command is called at the clock_opt_ccd step

set ICC_AOCV_SCENARIO_MAPPING           ""      ;# A list of scenarios and the AOCV table file for each specified scenario. e.g "{scenario_1 aocv_file_1} {scenario_2 aocv_file_2} ..."
                                                ;# If specifying scenario specific AOCV data, uncomment the timing_library_derate_is_scenario_specific application variable at the end of this script. 
                                                ;# If design level or hierarchical cell level AOCV data is to be applied, put this AOCV file as the final file to be read in. 
                                                ;# e.g. "{scenario_1 aocv_file_1} {scenario_2 aocv_file_} ... {scenario_n design_aocv_file}"

###############################
## Multivoltage Variables                       
###############################
set ICC_IN_RESOLVE_SUPPLY_SET_UPF_FILE  ""      ;# For UPF flow with VERILOG inputs, provide a secondary UPF file to resolve supply sets after reading in the UPF file.
set CUSTOM_CREATE_VA_SCRIPT             "ORCA_TOP.VA.tcl"     	;# For voltage area creation, provide a customized Tcl script. If not provided, you can use the $ICC_DP_AUTO_CREATE_VA
						;# feature which automatically creates voltage area through rm_icc_dp_scripts/create_va_dp.tcl. Otherwise, voltage area
						;# can be created by create_voltage_area commands in the init_design_icc.tcl. 
set ICC_DP_AUTO_CREATE_VA               FALSE  	;# TRUE|FALSE; set TRUE to automatically create voltage area based on user specified utilization in 
						;# rm_icc_dp_scripts/create_va_dp.tcl. 
set CUSTOM_POWER_SWITCH_SCRIPT          ""     	;# A Tcl script to define commands for headers_footers and sleep pin connection
set CUSTOM_SECONDARY_POWER_ROUTE_SCRIPT ""     	;# A Tcl script to define the pre_route_standard_cells command for always-on/retention register cells 
set RR_CELLS                            ""     	;# Specify naming pattern for retention register library cells. Matched cells are set as don't toutch cells and fixed; 
						;# For example, specify "RSD" if each retention register contains RSD in its library cell name
set ICC_UPF_PM_CELL_EXISTING		FALSE	;# TRUE|FALSE; set TRUE to run associate_mv_cells command if design contains pre-existing power management cells.
set ICC_UPF_PM_CELL_INSERTION		FALSE	;# TRUE|FALSE; set TRUE to run insert_mv_cells command.
set ICC_AO_STRATEGY_SINGLE_POWER_POWER_DOMAIN_LIST ""		;# A list of power domains for a single power always-on strategy.
set CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT ""	;# A Tcl script to create bound for single power always-on cells
set CUSTOM_AO_STRATEGY_SINGLE_POWER_SET_POWER_GUIDE_SCRIPT ""	;# A Tcl script that associates power guides with bounds created by $CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT

#################################################
## Multicorner-Multimode (MCMM) Input Variables                             
#################################################
set ICC_MCMM_SCENARIOS_FILE             "mcmm.scenarios.tcl"     	;# A file containing scenario definitions - examples in rm_icc_scripts/mcmm.scenarios.example
set ICC_MCMM_PLACE_OPT_SCENARIOS        ""     	;# list of scenarios to be made active during place_opt; optional; by default all scenarios will be made active
set ICC_MCMM_CLOCK_OPT_PSYN_SCENARIOS   ""     	;# list of scenarios to be made active during post-CTS optimization (pre-route); optional; by default all scenarios will be made active
set ICC_MCMM_CLOCK_OPT_ROUTE_SCENARIOS  ""     	;# list of scenarios to be made active during clock routing; optional; by default all scenarios will be made active
set ICC_MCMM_ROUTE_SCENARIOS            ""     	;# list of scenarios to be made active during signal routing; optional; by default all scenarios will be made active
set ICC_MCMM_ROUTE_OPT_SCENARIOS        ""     	;# list of scenarios to be made active during route_opt; optional; by default all scenarios will be made active
set ICC_MCMM_CHIP_FINISH_SCENARIOS      ""     	;# list of scenarios to be made active during route_opt post chipfinish; optional; by default all scenarios will be made active
set ICC_MCMM_METAL_FILL_SCENARIOS       ""     	;# list of scenarios to be made active during metal filling; optional; by default all scenarios will be made active
set ICC_MCMM_FOCAL_OPT_SCENARIOS       ""     	;# list of scenarios to be made active during focal_opt; optional; by default all scenarios will be made active


#######################################
## Clock Tree Synthesis (CTS) Variables
#######################################
set ICC_CTS_RULE_NAME		"iccrm_clock_double_spacing" ;# specify the name of a clock nondefault routing rule that you have defined (for ex, in common_cts_settings_icc.tcl); 
						;# it will be associated with set_clock_tree_options -routing_rule  
						;# If ICC_CTS_RULE_NAME is set to iccrm_clock_double_spacing, double spacings will be applied to all layers
set ICC_CTS_LAYER_LIST		""		;# clock tree layers, usually M3 and above; e.g. set ICC_CTS_LAYER_LIST "M3 M4 M5"
set ICC_CTS_REF_LIST		""		;# cells for CTS; a space-deliminated list: cell1 cell2 
set ICC_CTS_REF_DEL_INS_ONLY	""		;# cells for CTS delay insertion; a space-deliminated list: cell1 cell2
set ICC_CTS_REF_SIZING_ONLY	""		;# cells for CTS sizing only; a space-deliminated list: cell1 cell2 
set ICC_CTS_SHIELD_RULE_NAME	""		;# specify clock shielding rule name; requires $ICC_CTS_SHIELD_SPACINGS, $ICC_CTS_SHIELD_WIDTHS to be also specified    
set ICC_CTS_SHIELD_SPACINGS	""		;# specify clock shielding spacing associated with shielding rule; a list of layer name and spacing pairs
set ICC_CTS_SHIELD_WIDTHS	""		;# specify clock shielding width associated with shielding rule: a list of layer name and width pair
set ICC_CTS_SHIELD_CLK_NAMES	""		;# optionally specify a subset of clock names to apply the clock shielding rule: $ICC_CTS_SHIELD_RULE_NAME;
						;# if not specified, $ICC_CTS_SHIELD_RULE_NAME will be applied to all clock nets 

set ICC_CTS_INTERCLOCK_BALANCING	FALSE	;# TRUE|FALSE; set TRUE to enable -inter_clock_balance for "clock_opt -only_cts" at clock_opt_cts_icc task;
						;# specify $ICC_CTS_INTERCLOCK_BALANCING_OPTIONS_FILE to set the options  
set ICC_CTS_INTERCLOCK_BALANCING_OPTIONS_FILE	"" ;# an optional file which contains set_inter_clock_delay_options commands
set ICC_CTS_UPDATE_LATENCY	FALSE		;# set TRUE to perform clock latency update post CTS
set ICC_CTS_LATENCY_OPTIONS_FILE	""	;# an optional file which specifies the latency adjustment options

set ICC_CTS_SELF_GATING		FALSE		;# TRUE|FALSE; set TRUE to insert XOR self-gating logic during clock tree synthesis before clock tree construction
						;# An optional gate-level SAIF file ($ICC_IN_SAIF_FILE) is recommended in order to provide clock activity information
set ICC_IN_SAIF_FILE            "$DESIGN_NAME.saif" ;# An optional gate-level SAIF file for self-gating ($ICC_CTS_SELF_GATING)
set ICC_SAIF_INSTANCE_NAME      $DESIGN_NAME	;# the instance in the SAIF file containing switching activity

set ICC_POST_CLOCK_ROUTE_CTO	FALSE  	       	;# set TRUE if to perform post route clock tree optimization after clock routing at clock_opt_route_icc step

#########################################
## Routing and Chipfinishing Variables
#########################################
## end cap cells 
set ICC_H_CAP_CEL                  ""           ;# defines the horizontal CAP CELL library cell 
set ICC_V_CAP_CEL                  ""           ;# defines the vertical CAP CELL library cell (for the Well Proximity Effect)

## redundant via insertion (ICC_DBL_VIA) options
set ICC_DBL_VIA_FLOW_EFFORT      LOW            ;# LOW|MED|HIGH  - MED enables concurrent soft-rule redundant via insertion
                                                ;# HIGH runs another redundant via, timing driven, after chipfinishing
set ICC_CUSTOM_DBL_VIA_DEFINE_SCRIPT ""         ;# script to define the redundant via definitions
set ICC_DBL_VIA_DURING_INITIAL_ROUTING TRUE	;# TRUE|FALSE - TRUE enables automatic redundant via insertion after detail route change of "route_opt -initial"
						;# FALSE runs insert_zrt_redundant_vias after "route_opt -initial"

## antenna fixing (ICC_FIX_ANTENNA) options
set ANTENNA_RULES_FILE           ""             ;# defines the antenna rules
set ICC_USE_DIODES               FALSE          ;# TRUE|FALSE; control variable to allow diodes to be inserted both by the 
                                                ;# insert_port_protection_diodes command as well as the router
set ICC_ROUTING_DIODES           ""             ;# space separated list of diode names
set ICC_PORT_PROTECTION_DIODE    ""             ;# diode name for insert_port_protection_diodes
						;# Format = library_name/diode_name
set ICC_PORT_PROTECTION_DIODE_EXCLUDE_PORTS ""  ;# a list of ports to be excluded by insert_port_protection_diodes

## filler cell insertion (ADD_FILLER_CELL) options
set ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT "" 
						;# script for customized filler cell insertion commands for MV designs
						;# use insert_mv_filler_cells.tcl as a template
set FILLER_CELL_METAL            ""             ;# space separated list of filler cells with metals
set FILLER_CELL                  ""             ;# space separated list of filler cells 

## signal em
set ICC_FIX_SIGNAL_EM		 FALSE		;# TRUE|FALSE; set TRUE to enable signal em fixing; please uncomment the section and follow instruction in chip_finish_icc.tcl 
set ICC_TLUPLUS_SIGNAL_EM_FILE	""		;# The TLU+ file with the advanced signal EM constraints in it to be read by read_signal_em_constraints. This may be the same as the standard TLU+ files. 
set ICC_ITF_SIGNAL_EM_FILE      ""    ;# The ITF file with the advanced signal EM constraints to be read by the read_signal_em_constraints -itf_em command in chip_finish_icc.tcl
			
###############################
## Emulation TLUplus Files
###############################
## Note : emulated metal fill may not correlate well with real metal fill, especially for advanced technology nodes.
#  Use it for reference only.
set TLUPLUS_MAX_EMULATION_FILE         ""  	;#  Max TLUplus file
set TLUPLUS_MIN_EMULATION_FILE         ""  	;#  Min TLUplus file

###############################
## check_signoff_correlation  Variables
###############################
set PT_DIR ""                          		;# path to PrimeTime bin directory
set PT_SDC_FILE ""                     		;# optional file in case PrimeTime has a different SDC that what is available in the IC Compiler database
set STARRC_DIR ""                      		;# path to StarRC bin directory
set STARRC_MAX_NXTGRD ""               		;# MAX NXTGRD file
set STARRC_MIN_NXTGRD ""               		;# MIN NXTGRD file
set STARRC_MAP_FILE "$MAP_FILE"        		;# NXTGRD mapping file, defaults to TLUPlus mapping file, but could be different

set ICC_SIGNOFF_OPT_CHECK_CORRELATION_POSTROUTE_SCRIPT "" ;# a file to be sourced to run at check_signoff_correlation end of route_opt_icc step; 
							  ;# example - rm_icc_scripts/signoff_opt_check_correlation_postroute_icc.example.tcl

#######################################
## Metal fill and Signoff DRC Variables
#######################################
## For IC Validator metal Fill - ensure environment variable PRIMEYIELD_HOME_DIR is set and that IC Validator is included in the same path where the IC Compiler shell is executed from
## For IC Validator DRC - ensure environment variable ICV_HOME_DIR is set and that IC Validator is included in the same path where the IC Compiler shell is executed from

set SIGNOFF_FILL_RUNSET ""             		;# IC Validator runset for signoff_metal_fill command
set SIGNOFF_DRC_RUNSET  ""             		;# IC Validator runset for signoff_drc command
set SIGNOFF_MAPFILE     ""             		;# IC Validator mapping file for signoff_metal_fill and signoff_drc commands
set ICC_ECO_SIGNOFF_DRC_MODE	"NONE"		;# NONE|AUTO_ECO determines whether signoff_drc will run in the Auto ECO flow mode. 

## Options for signoff_metal_fill command using ICV engine in metal_fill_icc.tcl
set SIGNOFF_METAL_FILL_TIMING_DRIVEN FALSE  	;# TRUE|FALSE : set this to TRUE to enable timing driven for IC Validator metal fill 	
set TIMING_PRESERVE_SLACK_SETUP	"0.1"  		;# float : setup slack threshold for timing driven ICV metal fill; default 0.1
						;# also used by wire_spreading/widening in chip_finishi_icc.tcl
set TIMING_PRESERVE_SLACK_HOLD "0"     		;# float : hold slack threshold for wire_spreading/widening in chip_finishi_icc.tcl; default 0
## Options for insert_metal_fill command using ICC engine in metal_fill_icc.tcl
set ICC_METAL_FILL_SPACE           2            ;# space amount used during the IC Compiler insert_metal_fill command
set ICC_METAL_FILL_TIMING_DRIVEN  TRUE          ;# enables timing driven metal fill for the IC Compiler insert_metal_fill command

###############################
## focal_opt Variables
###############################
set ICC_FOCAL_OPT_HOLD_VIOLS     "all"          ;# filename|all - blank to skip; filename to fix violations from a file; specify "all" to fix all hold violations
set ICC_FOCAL_OPT_SETUP_VIOLS    ""          	  ;# filename|all - blank to skip; filename to fix violations from a file; specify "all" to fix all setup violations
set ICC_FOCAL_OPT_DRC_NET_VIOLS  "all"          ;# filename|all - blank to skip; filename to fix violations from a file; specify "all" to fix all DRC net violations
set ICC_FOCAL_OPT_DRC_PIN_VIOLS  ""             ;# filename|all - blank to skip; filename to fix violations from a file; specify "all" to fix all DRC pin violations
set ICC_FOCAL_OPT_XTALK_VIOLS    ""             ;# filename - blank to skip; filename to fix crosstalk violations from a file

###############################
## ECO Flow Variables
###############################
set ICC_ECO_FLOW		"NONE" 	;# NONE|UNCONSTRAINED|FREEZE_SILICON
                                        ;# UNCONSTRAINED : NO spare cell insertion ; cells can be added (pre tapeout)
                                        ;# FREEZE_SILICON : spare cell insertion/freeze silicon ECO
set ICC_SPARE_CELL_FILE         ""     	;# Tcl script to insert the spare cells, e.g. :
                                       	;# insert_spare_cells -lib_cell {INV8 DFF1} -cell_name spares -num_instances 300
set ICC_ECO_FILE                ""     	;# a verilog netlist or Tcl file containing ECO changes - specify the file name and type of file using ICC_ECO_FLOW_TYPE
set ICC_ECO_FLOW_TYPE		"verilog" ;# verilog | pt_drc_setup_fixing_tcl | pt_hold_fixing_tcl | pt_minimum_physical_impact - specify type of ECO file for UNCONSTRAINED ICC_ECO_FLOW;
					  ;# depending on the value specified, the commands used to read ECO file and place ECO cells vary;
					  ;# specify verilog if you provide a functional eco file for ICC_ECO_FILE;
					  ;# specify pt_drc_setup_fixing_tcl if you provide a change file generated by the PrimeTime fix_eco_drc or fix_eco_timing -setup commands;
					  ;# specify pt_hold_fixing_tcl if you provide a change file generated by the PrimeTime fix_eco_timing -hold command
					  ;# specify pt_minimum_physical_impact if you provide a change file generated by the PrimeTime fix_eco_timing  or fix_eco_leakage command 
set ICC_ECO_METAL_FILL_MODE	"early_stage" ;# early_stage | signoff_stage; only ICV is supported;
					      ;# specify early stage to use ICV DRC based metal fill trimming (faster);
					      ;# specify signoff_stage to perform complete ICV metal fill purge, ADR and metal fill insertion  


########################################################################################################################
############                        IC COMPILER DESIGN PLANNING SPECIFIC                         #######################   
############(variables for IC Compiler Design Planning and IC Compiler Hierarchical Reference Methodologies)  ##########
########################################################################################################################

########################################################################################################################
## Common variables (applied to both IC Compiler Design Planning and IC Compiler Hierarchical Reference Methodologies )
########################################################################################################################

set ICC_DP_VERBOSE_REPORTING		FALSE		;# TRUE|FALSE; generate additional reports before placement
set ICC_DP_SET_HFNS_AS_IDEAL_THRESHOLD	""		;# integer; specify a threshold to set nets with fanout larger than it as ideal nets
set ICC_DP_SET_MIXED_AS_IDEAL		TRUE		;# TRUE|FALSE; set mixed clock/signal paths as ideal nets

set ICC_DP_FIX_MACRO_LIST		""		;# ""|skip|"a_list_of_macros"; unfix all macros OR skip fix OR fix specified macros before placement
set CUSTOM_ICC_DP_PLACE_CONSTRAINT_SCRIPT ""            ;# Put your set_keepout_margin and fp_set_macro_placement_constraint in this file 
set CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT ""		;# File to perform customized preroute_standard_cell commands

## PNS and PNA control variables
set CUSTOM_ICC_DP_PNS_CONSTRAINT_SCRIPT ""              ;# File to add PNS constraints which is loaded before running PNS
set PNS_POWER_NETS         		"${MW_POWER_NET} ${MW_GROUND_NET}" ;# Target nets for PNS; syntax is "your_power_net your_ground_net" 
set PNS_POWER_BUDGET       		1000          	;# Unit in milliWatts; default is 1000
set PNS_VOLTAGE_SUPPLY     		1.5           	;# Unit in Volts; default is 1.5
set PNS_VIRTUAL_RAIL_LAYER 		""              ;# Specify the metal layer you want to use as virtual rail
set PNS_OUTPUT_DIR         		"./pna_output"  ;# Output directory for PNS and PNA output files
set PNA_EXTRACTION_TEMPERATURE		""		;# Float; set the wire extraction temperature for PNA. Optional.
set PNA_EXTRACTION_CORNER		""		;# min|max; set the parasitic corner for RC extraction for PNA. Optional.

###############################################################
## IC Compiler Hierarchical Reference Methodology Variables
###############################################################

set ICC_DP_PLAN_GROUPS		"$HIERARCHICAL_CELLS"	;# full module names from which plan groups will be created
                                                        ;#   space deliminated list: "top/A top/B top/C"
							;# default to $HIERARCHICAL_CELLS from common_setup.tcl if using Design Compiler Topographical
set ICC_DP_PLANGROUP_FILE               ""              ;# floorplan file containing plan group creation and location which should be the output of write_floorplan

set ICC_DP_ALLOW_FEEDTHROUGH	        FALSE		;# TRUE|FALSE; allow feedthrough creation during pin assignment 

set CUSTOM_ICC_DP_PNS_SCRIPT 		""              ;# customized PNS script; replacing PNS section in scripts; for template based PNS, this is required
set CUSTOM_ICC_DP_PNA_SCRIPT 		""              ;# customized PNA script; replacing PNA section in scripts

## DFT-aware hierarchical design planning variables 
set ICC_DP_DFT_FLOW			FALSE		;# TRUE|FALSE; enable DFT-aware hierarchical design planning flow; requires ICC_IN_FULL_CHIP_SCANDEF_FILE
set ICC_IN_FULL_CHIP_SCANDEF_FILE "$DESIGN_NAME.mapped.expanded.scandef"		
							;# full-chip SCANDEF file for DFT-aware hierarchical design planning flow (see $ICC_DP_DFT_FLOW)
							;# used only in hierarchical design planning phase; not used or needed for block level implementations and top level assembly 



set BUDGETING_SDC_OUTPUT_DIR            "./sdc"         ;# budgeting SDC output directory; default is "./sdc"


## TIO and block abstraction variables
set ICC_BLOCK_ABSTRACTIONS_LIST		""		;# a list of all the block abstractions used in the design;
							;# if left empty, the list will be auto set to include all soft macros in the design if you are following HRM step-by-step 

set ICC_TIO_BLOCK_LIST			$ICC_BLOCK_ABSTRACTIONS_LIST
							;# a list of names of block abstractions that are to be optimized by transparent interface optimization (TIO) at route_opt_icc;
							;# you can change it to a subset of block abstractions before route_opt_icc starts  

set ICC_TIO_OPTIMIZE_BLOCK_INTERFACE    TRUE            ;# TRUE|FALSE; set TRUE for TIO to optimize interface logic
set ICC_TIO_OPTIMIZE_MIM_BLOCK_INTERFACE FALSE          ;# TRUE|FALSE; set TRUE for TIO to optimize inside MIM blocks; set true only when you are opening MIM blocks for TIO
set ICC_TIO_OPTIMIZE_SHARED_LOGIC       FALSE           ;# TRUE|FALSE; set TRUE for TIO to optimize shared logic; requires $ICC_TIO_OPTIMIZE_BLOCK_INTERFACE to be also enabled
set ICC_TIO_BLOCK_UPDATE_SETUP_SCRIPT	""		;# Script for block abstraction setup, useful for variable settings during block update. To be used during set_top_implementation_options -block_update_setup_script ICC_TIO_BLOCK_UPDATE_SETUP_SCRIPT.  The file name should not include relative paths

set ICC_TIO_HOST_OPTION 		""		;# lsf|grd|samehost|list_of_hosts; this controls the set_host_options value for TIO
       							;# if either lsf or grd is specified, you must also specify $ICC_TIO_HOST_OPTION_SUBMIT_OPTIONS 
       							;# if list_of_hosts is specified, you must also specify $ICC_TIO_HOST_OPTION_HOSTS_LIST
							;# Please note that if $ICC_TIO_OPTIMIZE_BLOCK_INTERFACE is set to TRUE and $ICC_TIO_BLOCK_LIST is not empty,
							;# which are both default for HRM, you should also specify a valid value for $ICC_TIO_HOST_OPTION
 			
set ICC_TIO_HOST_OPTION_SUBMIT_OPTIONS {}		;# controls the value of -submit_option option for set_host_options for TIO 
							;# If $ICC_TIO_HOST_OPTION is set to lsf, 
							;# then lsf specific submit options should be specified and vice versa, for example, 
							;# {-q bnormal -R "rusage\[mem=12000\]\cputype==emt64 cpuspeed==EMT3000 qsc==e"}

set ICC_TIO_HOST_OPTION_HOSTS_LIST	""              ;# a list of hosts on which to perform automatic block update during TIO


set ICC_TIO_WRITE_ECO_FILE              FALSE		;# TRUE|FALSE; set TRUE for TIO to write out an ECO file to TIO_eco_changes directory

set ICC_IMPLEMENTATION_PHASE		default         ;# default|block|top; set it to block or top to disable tasks such as Milkyway design library creation,
							;# importing of black boxes, scenario creation, voltage area creation, and power switch creation, etc 
							;# in init_design_icc.tcl which should have been completed during design planning phase and should be skipped during 
							;# block and top level implementation phases; also set it to top to enable TIO at route_opt_icc task;
							;# if you are following IC Compiler Hierarchical RM step-by-step, please do not change this;
							;# it will be automatically set to block or top for block or top level designs, respectively
  
set MW_SOFT_MACRO_LIBS                  ""       	;# a list containing paths to all block libraries; they will be added as reference libraries of the top level library
							;# if you are following IC Compiler Hierarchical RM step-by-step, please do not change this;
							;# it will be automatically set to include all block libraries in the design for top level implementation

###############################################################################
## IC Compiler Design Planning Reference Methodology (Flat) Variables
###############################################################################

## explore mode: flow control variables
set ICC_DP_EXPLORE_MODE			TRUE		;# TRUE|FALSE; turn on exploration mode
set ICC_DP_EXPLORE_STYLE		default		;# valid options are: default | placement_only | no_pns_pna | no_ipo
							;# default: place -> PNS/PNA -> in-place optimization -> final groute, snapshot, QoR, timing, and outputs 
							;# placement_only: skips pns/pna and in-place optimization from default | no_pns_pna: skips pna/pns from default 
                                                        ;# | no_ipo: skips in-place optimization from default 
set ICC_DP_EXPLORE_SAVE_CEL_EACH_STEP 	FALSE		;# TRUE|FALSE; save 3 additional CEL after placement, in-place optimization, and PNS in explore mode (requires more disk space)
set ICC_DP_EXPLORE_REPORTING_EACH_STEP	FALSE		;# TRUE|FALSE; generate QoR snapshot and timing report after each step (longer run time)
set ICC_DP_EXPLORE_USE_GLOBAL_ROUTE 	FALSE		
set ICC_DP_EXPLORE_SAVE_CEL_AFTER_GROUTE TRUE		;# TRUE|FALSE; save 2 additional CEL after global route: one after placement and one at the end
set ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT	""		;# string; script to be loaded to create customized PG straps after placement in explore mode; 
							;# valid only if ICC_DP_EXPLORE_STYLE is placement_only or no_pns_pna

## explore mode: additional PNS control variables
set PNS_TARGET_VOLTAGE_DROP     	250	        ;# Unit in milliVolts. Tool default is 10% of PNS_POWER_BUDGET
set PNS_BLOCK_MODE         		FALSE           ;# TRUE|FALSE; specify if the design is block or top level; It turns on correspondant options in PNS and PNA
set PNS_PAD_MASTERS        		""		;# Only for top level design with power pads. Specify cell masters for power pads, e.g. "pv0i.FRAM pv0a.FRAM"
set PNS_PAD_INSTANCE_FILE  		""              ;# Only for top level design with power pads. Specify the file with a list of power pad instances
set PNS_PAD_MASTER_FILE    		""		;# Only for top level design with power pads. Specify the file with a list of power pad masters
## Please provide only one of PNS_PAD_MASTERS, OR PNS_PAD_INSTANCE_FILE, OR PNS_PAD_MASTER_FILE 

#####################################################################################################################################
## NO NEED TO CHANGE THE FOLLOWING IF Design Compiler Reference Metholodgy IS USED PRIOR TO IC Compiler Reference Methodology
#####################################################################################################################################
set ICC_IN_VERILOG_NETLIST_FILE "$DESIGN_NAME.mapped.v" ;#1 to n verilog input files, spaced by blanks
set ICC_IN_SDC_FILE             "$DESIGN_NAME.mapped.sdc"
set ICC_IN_DDC_FILE             "$DESIGN_NAME.ddc"
set ICC_IN_UPF_FILE             "$DESIGN_NAME.mapped.upf"
set ICC_IN_SCAN_DEF_FILE        "" 			;# default from Design Compiler Reference Metholodgy is $DESIGN_NAME.mapped.scandef

###################################################################################################################
if {$upf_create_implicit_supply_sets} {
  # Starting G-2012.06 release, the variable upf_create_implicit_supply_sets enables creation of supply set handles
  # while creating power domains. Default is true.
  # The if clause is added to ensure it's changed only once per session. Refer to man page for details.
  # To change the value to false, please uncomment the following line :

  set_app_var upf_create_implicit_supply_sets false
}
###################################################################################################################

if {[info exists SEV(rpt_dir)]} {
  set REPORTS_DIR $SEV(rpt_dir)				;# Directory to write reports.
} else {
  set REPORTS_DIR "../rpts/null"			;# Directory to write reports.
}
if {[info exists SEV(dst_dir)]} {
  set RESULTS_DIR $SEV(dst_dir)				;# Directory to write output data files
} else {
  set RESULTS_DIR "../work/null"			;# Directory to write output data files
}
set SOURCE_DIR $RESULTS_DIR				;# Source directory for analysis tasks such as FM and MVRC

set MW_DESIGN_LIBRARY           "../work/${DESIGN_NAME}_LIB"    ;# milkyway design library
set COPY_FROM_MW_DESIGN_LIBRARY "../../rm_dc/work/dc/${DESIGN_NAME}_LIB" ;# specify a milkyway design library if you want reference methodology to copy it as MW_DESIGN_LIBRARY
							                 ;# only applies if ICC_INIT_DESIGN_INPUT is set to Milkyway

set REPORTS_DIR_INIT_DESIGN                     $REPORTS_DIR
set REPORTS_DIR_PLACE_OPT                       $REPORTS_DIR
set REPORTS_DIR_CLOCK_OPT_CTS                   $REPORTS_DIR
set REPORTS_DIR_CLOCK_OPT_PSYN                  $REPORTS_DIR
set REPORTS_DIR_CLOCK_OPT_ROUTE                 $REPORTS_DIR
set REPORTS_DIR_ROUTE                           $REPORTS_DIR
set REPORTS_DIR_ROUTE_OPT                       $REPORTS_DIR
set REPORTS_DIR_CHIP_FINISH                     $REPORTS_DIR
set REPORTS_DIR_ECO                        	$REPORTS_DIR
set REPORTS_DIR_FOCAL_OPT                       $REPORTS_DIR
set REPORTS_DIR_SIGNOFF_OPT                     $REPORTS_DIR
set REPORTS_DIR_METAL_FILL                      $REPORTS_DIR
set REPORTS_DIR_DP            			$REPORTS_DIR
set REPORTS_DIR_DP_CREATE_PLANGROUPS		$REPORTS_DIR
set REPORTS_DIR_DP_ROUTEABILITY_ON_PLANGROUPS   $REPORTS_DIR
set REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING     $REPORTS_DIR
set REPORTS_DIR_DP_COMMIT                       $REPORTS_DIR
set REPORTS_DIR_DP_PREPARE_BLOCK                $REPORTS_DIR
set REPORTS_DIR_FORMALITY			$REPORTS_DIR

if { ! [file exists $REPORTS_DIR_INIT_DESIGN] } { file mkdir $REPORTS_DIR_INIT_DESIGN }
if { ! [file exists $REPORTS_DIR_PLACE_OPT] } { file mkdir $REPORTS_DIR_PLACE_OPT }
if { ! [file exists $REPORTS_DIR_CLOCK_OPT_CTS] } { file mkdir $REPORTS_DIR_CLOCK_OPT_CTS }
if { ! [file exists $REPORTS_DIR_CLOCK_OPT_PSYN] } { file mkdir $REPORTS_DIR_CLOCK_OPT_PSYN }
if { ! [file exists $REPORTS_DIR_CLOCK_OPT_ROUTE] } { file mkdir $REPORTS_DIR_CLOCK_OPT_ROUTE }
if { ! [file exists $REPORTS_DIR_ROUTE] } { file mkdir $REPORTS_DIR_ROUTE }
if { ! [file exists $REPORTS_DIR_ROUTE_OPT] } { file mkdir $REPORTS_DIR_ROUTE_OPT }
if { ! [file exists $REPORTS_DIR_CHIP_FINISH] } { file mkdir $REPORTS_DIR_CHIP_FINISH }
if { ! [file exists $REPORTS_DIR_ECO] } { file mkdir $REPORTS_DIR_ECO }
if { ! [file exists $REPORTS_DIR_FOCAL_OPT] } { file mkdir $REPORTS_DIR_FOCAL_OPT }
if { ! [file exists $REPORTS_DIR_SIGNOFF_OPT] } { file mkdir $REPORTS_DIR_SIGNOFF_OPT }
if { ! [file exists $REPORTS_DIR_METAL_FILL] } { file mkdir $REPORTS_DIR_METAL_FILL }
if { ! [file exists $REPORTS_DIR_DP] } { file mkdir $REPORTS_DIR_DP }
if { ! [file exists $REPORTS_DIR_DP_CREATE_PLANGROUPS] } { file mkdir $REPORTS_DIR_DP_CREATE_PLANGROUPS }
if { ! [file exists $REPORTS_DIR_DP_ROUTEABILITY_ON_PLANGROUPS] } { file mkdir $REPORTS_DIR_DP_ROUTEABILITY_ON_PLANGROUPS }
if { ! [file exists $REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING] } { file mkdir $REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING }
if { ! [file exists $REPORTS_DIR_DP_COMMIT] } { file mkdir $REPORTS_DIR_DP_COMMIT }
if { ! [file exists $REPORTS_DIR_DP_PREPARE_BLOCK] } { file mkdir $REPORTS_DIR_DP_PREPARE_BLOCK }
if { ! [file exists $REPORTS_DIR_FORMALITY] } { file mkdir $REPORTS_DIR_FORMALITY }


## Logical libraries
  set_app_var search_path	". ../../scripts_block/rm_icc_scripts ../../scripts_block/rm_icc_zrt_scripts ../../scripts_block/rm_icc_dp_scripts ../../rm_dc/work/dc $ADDITIONAL_SEARCH_PATH $search_path" 
if {$synopsys_program_name != "mvrc" || $synopsys_program_name != "vsi" || $synopsys_program_name != "vcst"} {
  set_app_var target_library	"$TARGET_LIBRARY_FILES"
  set_app_var link_library	"* $TARGET_LIBRARY_FILES $ADDITIONAL_LINK_LIB_FILES"
} else {
  set_app_var link_library	"$TARGET_LIBRARY_FILES $ADDITIONAL_LINK_LIB_FILES"
}

if { ! [file exists $RESULTS_DIR] } {
  file mkdir $RESULTS_DIR
}
if { ! [file exists $REPORTS_DIR] } {
  file mkdir $REPORTS_DIR
}

if {$synopsys_program_name == "icc_shell"} {

## Min/Max library relationships
#  For "set_operating_conditions -analysis_type on_chip_variation", it is not recommended if only -max is specified.
#  (such as in rm_icc_scripts/mcmm.scenarios.example) 
#  Only use it if both -max and -min of set_operating_conditions are specified and point to two different libraries
#  and are characterized to model OCV effects of the same corner.
if {$MIN_LIBRARY_FILES != "" } {
  foreach {max_library min_library} $MIN_LIBRARY_FILES {
    set_min_library $max_library -min_version $min_library
  }
}

## Reference libraries
if { ![file exists [which $MW_REFERENCE_CONTROL_FILE]]} {
 if {[file exists $MW_DESIGN_LIBRARY/lib]} {
   set_mw_lib_reference $MW_DESIGN_LIBRARY -mw_reference_library "$MW_REFERENCE_LIB_DIRS $MW_SOFT_MACRO_LIBS"
 }
}

## PD4 is not always used
if {![info exists PD4]} {set PD4 ""}

## Avoiding too many messages
set_message_info -id PSYN-040 -limit 10 ;# Dont_touch for fixed cells
set_message_info -id PSYN-087 -limit 10 ;# Port inherits its location from pad pin
set_message_info -id LINT-8   -limit 10 ;# input port is unloaded

set_message_info -id PWR-536  -limit 5  ;# The library cell ... is not characterized for internal power.
set_message_info -id UID-401  -limit 5  ;# Design rule attributes from the driving cell will be set on the port.
suppress_message PWR-824                ;# The default value of the -leakage_power and -dynamic_power options of the set_scenario_options command changed from true to false in the F-2011.09 release.

set_app_var check_error_list "$check_error_list LINK-5 PSYN-375"

}


if {$synopsys_program_name == "fm_shell"} {
set_app_var sh_new_variable_message false
} 


## Uncomment this variable if you wish for specified library cell derates set 
# with the set_timing_derate command or AOCV data for library cells to be saved
# in the Milkyway database.
# When true, this variable will enable any derates specified on library cells to
# be saved to the Milkyway database:
#
# set_app_var timing_save_library_derate true


## Uncomment this variable to make set_timing_derate and read_aocvm only applied
# to the current scenario for settings related to library cell objects :
#  set_app_var timing_library_derate_is_scenario_specific true

#################################################################################


source ${WORKSHOP_REF_PATH}/tools/procs.tcl

puts "RM-Info: Completed script [info script]\n"
