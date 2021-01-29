##################################################################################################
# ICC Hierarchical RM								 	 	 
# create_plangroup_dp: Plangroup Creation/Import, Virtual Flat Placement, and Plan Group Shaping 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##################################################################################################

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
set SEV(dst) create_plangroups_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_FLOORPLAN_CEL $SEV(src) 
set ICC_DP_CREATE_PLANGROUPS_CEL $SEV(dst) 
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
copy_mw_cel -from $ICC_FLOORPLAN_CEL -to $ICC_DP_CREATE_PLANGROUPS_CEL 
open_mw_cel $ICC_DP_CREATE_PLANGROUPS_CEL
link

source common_placement_settings_icc.tcl


## (Optional) Set ideal network on nets with fanout larger than the specified threshold
if {$ICC_DP_SET_HFNS_AS_IDEAL_THRESHOLD != ""} {
        set hf_nets [all_high_fanout -nets -threshold $ICC_DP_SET_HFNS_AS_IDEAL_THRESHOLD]
        if { $hf_nets != "" } {
                redirect /dev/null {set_load 0 -subtract_pin_load $hf_nets}
                redirect /dev/null {set_ideal_network -no_propagate $hf_nets}
        }
}

## (Optional) Set ideal network on mixed clock/signal paths with high fanout; this will be removed in clock_opt_psyn_icc.tcl
#if {$ICC_DP_SET_MIXED_AS_IDEAL eq "true"} {set_ideal_network [all_fanout -flat -clock_tree]}

## Additional reporting before the major steps
if {$ICC_DP_VERBOSE_REPORTING} {
        check_design -summary > ${REPORTS_DIR_DP_CREATE_PLANGROUPS}/${ICC_DP_CREATE_PLANGROUPS_CEL}_pre.check_design.rpt
        report_net_fanout -nosplit -threshold 50 > ${REPORTS_DIR_DP_CREATE_PLANGROUPS}/${ICC_DP_CREATE_PLANGROUPS_CEL}_pre.high_fanout.rpt
}

#########################################################################################
# Create Plangroups									#
#########################################################################################
## 1.To decide which modules to create into plangroups:
## - A.Please use "hierarchy browser" or
## - B.you can run placement without legalization first and based on the result to make your decision:  
##	create_fp_placement -effort low -no_legalize
## 2.If you have decided, specify the list of modules in ICC_DP_PLAN_GROUPS (icc_setup.tcl)
## 3.If you already have a dumped floorplan file containing plangroups, specify it in ICC_DP_PLANGROUP_FILE (icc_setup.tcl) 
##   Note: A floorplan file including plangroups should be written out from the write_floorplan command.
##   Starting with C-2009.06 release, you need to set create_fp_plan_groups to TRUE before write_floorplan to write out plan group definitions.

if {[file exists [which $ICC_DP_PLANGROUP_FILE]]} {
        echo "RM-Info: Reading [which $ICC_DP_PLANGROUP_FILE]"
	read_floorplan $ICC_DP_PLANGROUP_FILE
} elseif {$ICC_DP_PLAN_GROUPS != ""} {
	create_plan_groups $ICC_DP_PLAN_GROUPS -cycle_color
} else {
	echo "RM-Error: Please create plan groups before you contunue with hierarchical flow"
}
create_fp_plan_group_padding -internal_widths {2 2 2 2} -external_widths {2 2 2 2} [get_plan_groups *]

#########################################################################################
# Set Placement Constraints								#
#########################################################################################
## You can control if you want to unfix macros before placement:
#       set ICC_DP_FIX_MACRO_LIST ""            : unfix all macros; performs "set_attribute [all_macro_cells] is_fixed false"
#       set ICC_DP_FIX_MACRO_LIST skip          : skip unfix of macros; retain existing fix status;
#       set ICC_DP_FIX_MACRO_LIST {a list}      : fix specified macros and unfix the others; useful if you want to preserve certain macros locations
#                                                 it sets the is_fixed attribute false and then sets it true on specified macros
if {[all_macro_cells] != ""} {
        if {$ICC_DP_FIX_MACRO_LIST eq ""} {
                set_attribute [all_macro_cells] is_fixed false
        } elseif {$ICC_DP_FIX_MACRO_LIST eq "skip"} {
                echo "Setting is_fixed false for macros is skipped"
        } else {
                set_attribute [all_macro_cells] is_fixed false
                set_attribute $ICC_DP_FIX_MACRO_LIST is_fixed true
	}
}

## You can customize padding and location preference by loading a file with set_keepout_margin and set_fp_macro_array, for example:
#       set_keepout_margin -type soft -all_macros -outer {10 10 10 10}
#       set_fp_macro_array -name array1 -align_edge t -elements {macro_1 macro_2 macro_3}
if {[file exists [which $CUSTOM_ICC_DP_PLACE_CONSTRAINT_SCRIPT]]} {
        source $CUSTOM_ICC_DP_PLACE_CONSTRAINT_SCRIPT}

set_host_options -max_cores $ICC_NUM_CORES


#########################################################################################
# Below steps are skipped if $ICC_DP_PLANGROUP_FILE is provided				#
#########################################################################################
if {$ICC_DP_PLAN_GROUPS != "" && $ICC_DP_PLANGROUP_FILE == ""} {

	#################################################################################
	# Shape Plangroups								#
	#################################################################################

	## Set placement strategies to further fine tune the placer based on your design style 
	## To find all available strategies and current values, use:
	#       report_fp_placement_strategy
	## To control net weight on plan group interface net:
	#	set_fp_placement_strategy -plan_group_interface_net_weight 2
	## To enable auto detection of logical hierarchies other than existing placegroups:
	#	set_fp_placement_strategy -force_auto_detect_hierarchy on
	## To control channels among macros which std cell can not be placed:
	set_fp_placement_strategy -sliver_size 10

	set_fp_placement_strategy -macros_on_edge off

	## If plangroups are already created and placed outside the core, create_fp_placement will use -exploration by default
        create_fp_placement

	shape_fp_blocks -channels 
        ## Even if -channels is speficied, tool may not create channels if tool determines that they are not needed 
	#  If you want to create channels with specific spacing btw plangroups, set the following command before shape_fp_blocks: 
        #  set_fp_shaping_strategy -min_channel_size value 

	save_mw_cel -as ${ICC_DP_CREATE_PLANGROUPS_CEL}_shape
}

#################################################################################
# Placement Based on Plangroups							#
#################################################################################

## To place macros on edge of chip or plan group which is default off. 
## Suggested to set it after plan groups are created:
	set_fp_placement_strategy -macros_on_edge auto
## For multi-voltage designs, the following controls whether the tool uses special, high quality isolation
#  cells and performs level shifter handling. Uncomment to use it.
#	set_fp_placement_strategy -honor_mv_cells on

	create_fp_placement -effort high 
	## Congestion aware shaping:
	#  If you see significant congestion after shape_fp_blocks, instead of using the above command,
	#  you can try the following combination of commands to reduce congestion:
	#  	set_fp_placement_strategy -congestion_effort low|medium|high (low is default;medium and high uses zroute)
	#	set_fp_placement_strategy -adjust_shapes on (incremental shaping)
	#	create_fp_placement -congestion_driven -effort high


if {$DFT && $ICC_DP_DFT_FLOW} {
	optimize_dft -plan_group
	redirect -file $REPORTS_DIR_DP_CREATE_PLANGROUPS/${ICC_DP_CREATE_PLANGROUPS_CEL}_check_scan_chain.rpt {check_scan_chain}
	#redirect -file $REPORTS_DIR_DP_CREATE_PLANGROUPS/${ICC_DP_CREATE_PLANGROUPS_CEL}_report_scan_chain.rpt {report_scan_chain}
}

report_fp_placement > ${REPORTS_DIR_DP_CREATE_PLANGROUPS}/${ICC_DP_CREATE_PLANGROUPS_CEL}_place.placement_rpt

#####################################################################################################
# REMINDER: After shaping is done, please examine plan group results and make necessary adjustments #
#####################################################################################################


# Lynx compatible procedure which produces design metrics based on reports
# sproc_generate_metrics

save_mw_cel
close_mw_lib
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

