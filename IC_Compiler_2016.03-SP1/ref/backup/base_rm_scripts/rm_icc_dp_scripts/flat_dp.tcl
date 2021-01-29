##########################################################################################
## ICC Design Planning RM
## flat_dp: Virtual Flat Placement, PNS, PNA, IPO, Proto Route, and Explore Runs
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

#################################################################################
# Lynx Compatible Setup : Overview
#
# This LCRM script contains support for running standalone or within the Lynx
# Design System without change. Note that Lynx is not required to run standalone.
#
# Features available when running within Lynx Design System include:
#
# * Graphical flow configuration and execution monitoring
# * Tool setup and version management
# * Job distribution handling
# * Visual execution status and error checking
# * Design and System metric capture for analysis in Lynx Manager Cockpit
#################################################################################

#################################################################################
# Lynx Compatible Setup : Task Environment Variables (TEV)
#
# Task Environment Variables allow configuration of this tool script.
# The Lynx Design System will automatically recognize the TEV definitions
# in this script and make them visible for configuration in the Lynx Design
# System graphical user interface.
#################################################################################

## NAME: TEV(num_cores)
## TYPE: integer
## INFO:
## * Specifies the number of cores to be used for multicore optimization.
## * Use a value of 1 to indicate single-core optimization (default).
set TEV(num_cores) 1

#################################################################################
# Lynx Compatible Setup : Script Initialization
#
# This section is used to initialize the scripts for use with the Lynx Design
# System.  Users should not make modifications to this section.
#################################################################################

set SEV(src) init_design_icc
set SEV(dst) flat_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_FLOORPLAN_CEL $SEV(src) 
source proc_explore.tcl
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
copy_mw_cel -from $ICC_FLOORPLAN_CEL -to flat_dp
open_mw_cel flat_dp
link

source common_placement_settings_icc.tcl
source common_optimization_settings_icc.tcl

## (Optional) Set ideal network on nets with fanout larger than the specified threshold  
if {$ICC_DP_SET_HFNS_AS_IDEAL_THRESHOLD != ""} {
	set hf_nets [all_high_fanout -nets -threshold $ICC_DP_SET_HFNS_AS_IDEAL_THRESHOLD]
	if { $hf_nets != "" } {
		redirect /dev/null {set_load 0 -subtract_pin_load $hf_nets}
		redirect /dev/null {set_ideal_network -no_propagate $hf_nets}
	}
}

## (Optional) Set ideal network on mixed clock/signal paths with high fanout; this will be removed in clock_opt_psyn_icc.tcl
if {$ICC_DP_SET_MIXED_AS_IDEAL} {set_ideal_network [all_fanout -flat -clock_tree]}

## Additional reporting before the major steps
if {$ICC_DP_VERBOSE_REPORTING} {
	check_design -summary > ${REPORTS_DIR_DP}/flat_dp.check_design.rpt
	report_net_fanout -nosplit -threshold 50 > ${REPORTS_DIR_DP}/flat_dp.high_fanout.rpt
}

########################################################################################
## Set Placement Constraints
########################################################################################

## You can control if you want to unfix macros before placement:
#	set ICC_DP_FIX_MACRO_LIST ""		: unfix all macros; 
#						  it performs "set_attribute [all_macro_cells] is_fixed false" 
#	set ICC_DP_FIX_MACRO_LIST skip		: skip unfix of macros; retain existing fix status; 
#					          it change macro fix status
#	set ICC_DP_FIX_MACRO_LIST {a list}	: fix specified macros and unfix the others; useful if you want to preserve certain macros locations
#						  it sets the is_fixed attribute false and then sets it true on specified macros
if {[all_macro_cells] != ""} {

	if {$ICC_DP_FIX_MACRO_LIST eq ""} {
	        set_attribute [all_macro_cells] is_fixed false
	} elseif {$ICC_DP_FIX_MACRO_LIST eq "skip"} {
	        echo "Setting is_fixed false for macros is skipped"
	} else {
	        set_attribute  [all_macro_cells] is_fixed false
	        set_attribute $ICC_DP_FIX_MACRO_LIST is_fixed true
	}

}


## You can customize padding and location preference by loading a file
## Below are examples for the kind of commands to put in the file using set_keepout_margin and set_fp_macro_array
#       set_keepout_margin -type soft -all_macros -outer {10 10 10 10}
#       set_fp_macro_array -name array1 -align_edge t -elements {macro_1 macro_2 macro_3}
if {[file exists [which $CUSTOM_ICC_DP_PLACE_CONSTRAINT_SCRIPT]]} {
        source $CUSTOM_ICC_DP_PLACE_CONSTRAINT_SCRIPT}


## You can customize power network synthesis constraints by loading a file
## Below are examples for the kind of commands to put in the file using set_fp_rail_constraints
#       set_fp_rail_constraints -set_global -keep_ring_outside_core -no_routing_over_hard_macros
if {[file exists [which $CUSTOM_ICC_DP_PNS_CONSTRAINT_SCRIPT]]} {
	source $CUSTOM_ICC_DP_PNS_CONSTRAINT_SCRIPT}


######################################################################################################################
## Flat Design Planning Flow : Virtual Flat Placement, Power Network Synthesis/Analysis, In Place Optimization, and Global Route 
######################################################################################################################

## There are two ways (or modes) that you can perform flat design planning flow depending on your needs.
## Explore mode : It automates multiple runs of virtual flat placement each with different combinations of placement parameters and options.
##		  It also performs global route, IPO, and PNS/PNA for full flow feasibility analysis
## Baseline mode : It performs one run of virtual flat placement + global route + PNS/PNA + IPO in plain script for flat design planning flow.
##	 	   It can serve as your reference and template for interactive flat design planning runs.
## Both modes are based on the same underlying flow steps.

if {$ICC_DP_EXPLORE_MODE} {

	if !{[info exists env(DISPLAY)]} {
		echo "RM-Info: DISPLAY is not set. GUI snapshot will be skipped."
	}

	## // Explore mode // 
	## macro_placement_exploration_dp.tcl : It contains all the runs to be performed. You can customize this file based on your needs. See the file for more details. 
	## gen_explore_table : It runs a Perl script to parse the outputs and generate an HTML table: ./${DESIGN_NAME}_explore.html
	save_mw_cel -as saved_cel_before_explore_mode -overwrite
	close_mw_cel
	source macro_placement_exploration_dp.tcl
	sh ../../scripts_block/rm_icc_dp_scripts/gen_explore_table ${REPORTS_DIR_DP} ${DESIGN_NAME}_explore.html 
 
} else {

	## // Baseline mode //
	## baseline.tcl : Plain script without automation which can be used as a template or starting point
	source baseline.tcl

}


##################################################################################################################################################
## If you use explore mode,
## how to use the results and proceed with ICC-RM?
##################################################################################################################################################
##
## After the explore mode is completed, please review results in the HTML table - ${DESIGN_NAME}_explore.html, and 
## choose one result to proceed with ICC-RM.
## You can do so by either of the following two approachs depending on your preference:
##
## 1.Use the saved CEL from the run you choose as the starting point for ICC-RM
##   -> Please specify the varible ICC_FLOORPLAN_CEL in icc_setup.tcl with this CEL name.
##    * This CEL will contain fixed macro placement or In Place Optimization or Power Network Synthesis changes depeding on what option you choose during the run.
##    * ICC_FLOORPLAN_CEL is the variable which you specify as the starting CEL for ICC-RM.
##
## 2.Use the written-out floorplan and route files from the run you choose and load them onto the original CEL
##   -> Open CEL saved_cel_before_explore_mode, load the written-out floorplan and route files. 
##   -> save the CEL as a differnt name, such as, flat_dp, and specify ICC_FLOORPLAN_CEL with this CEL name. Then ICC-RM will start with this CEL.
##    * This approach ensures no netlist change but only macro placement and PG routes from the explore mode.   
##    * saved_cel_before_explore_mode is the CEL saved before the explore mode starts which is your clean starting point.
##    * the written-out floorplan file is in $RESULTS_DIR which you can load by using the following command : 
##		read_floorplan $RESULTS_DIR/run0_default_dump.floorplan  
##    * the written-out route file is in $RESULTS_DIR which you can load by using the following command :
##		read_floorplan $RESULTS_DIR/run0_default_dump.route 

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop
