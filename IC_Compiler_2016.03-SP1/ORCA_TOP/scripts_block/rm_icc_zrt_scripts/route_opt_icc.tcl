##########################################################################################
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

set SEV(src) route_icc
set SEV(dst) route_opt_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_ROUTE_CEL $SEV(src) 
set ICC_ROUTE_OPT_CEL $SEV(dst) 

############################################
## route_opt_icc: Post Route optimization ##
############################################

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_ROUTE_OPT_CEL}"
copy_mw_cel -from $ICC_ROUTE_CEL -to $ICC_ROUTE_OPT_CEL

## TIO setup for route_opt command
if {$ICC_IMPLEMENTATION_PHASE == "top"} {
  ## Copy block CELs to current library for interface optimization, 
  #  if ICC_TIO_OPTIMIZE_BLOCK_INTERFACE is enabled, ICC_TIO_BLOCK_LIST not empty, and host options are specified 
  if {$ICC_TIO_OPTIMIZE_BLOCK_INTERFACE && $ICC_TIO_BLOCK_LIST != "" && $ICC_TIO_HOST_OPTION != ""} {
    foreach block $ICC_TIO_BLOCK_LIST {
    copy_mw_cel -from_lib ../../../${block}/rm_icc/work/lib_${block} -from $block 
    }
  }
}

open_mw_cel $ICC_ROUTE_OPT_CEL



source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl

## Load the route and si settings
source -echo common_route_si_settings_zrt_icc.tcl



  if {$ICC_MCMM_ROUTE_OPT_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_ROUTE_OPT_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }

  ## If you add additional scenarios after clock_opt_cts_icc step, use the following command to propagate all clock sources for active scenarios :
  #	propagate_all_clocks


##############################
## RP : Relative Placement  ##     
##############################
## Ensuring that the RP cells are not changed during route_opt
#set_rp_group_options [all_rp_groups] -route_opt_option fixed_placement
#set_rp_group_options [all_rp_groups] -route_opt_option "size_only"


if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
## start the post route optimization
set_app_var compile_instance_name_prefix icc_route_opt
if {$ICC_SANITY_CHECK} {
	check_physical_design -stage pre_route_opt -no_display -output check_physical_design.pre_route_opt
}

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {$ICC_ENABLE_CHECKPOINT} {
echo "RM-Info : Please ensure there's enough disk space before enabling the set_checkpoint_strategy feature."
set_checkpoint_strategy -enable -overwrite
# The -overwrite option is used by default. Remove it if needed.
}

# To enable cell pre-sizing as a first step in route_opt crosstalk reduction,
# set the following variable to TRUE (default is FALSE):
# set_app_var routeopt_xtalk_reduction_cell_sizing TRUE

# Controls the effort level of TNS optimization
set_optimization_strategy -tns_effort $ICC_TNS_EFFORT_POSTROUTE

if {[file exists [which $CUSTOM_ROUTE_OPT_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_ROUTE_OPT_PRE_SCRIPT]"
source $CUSTOM_ROUTE_OPT_PRE_SCRIPT
}

########################################
#   TIO setup for route_opt command
########################################
if {$ICC_IMPLEMENTATION_PHASE == "top"} {
source -echo common_route_opt_tio_settings_icc.tcl
}

########################################
#   route_opt core command
########################################
## For running route_opt with filler cells placed :
#  The filler cells must be of type std_filler.
#  This is done by marking the std filler cells with gdsStdFillerCell during library dataprep.
#  If you see the following message when filler cells are inserted prior to route_opt,
#  then that means they are not marked properly :
#     WARNING : cell <xxx> is not of std filler cell subtype

## To enable verbose output for information related to route_opt operations, set the following.
#  See man page for complete details. Here's an example :
#  	set_app_var routeopt_verbose 31

## To use the scenario compression feature, try the following :
#	open_mw_cel, etc 
#	compress_scenario
#	route_opt -skip_initial_route -effort $ROUTE_OPT_EFFORT -xtalk_reduction -power
#	route_opt -incremental ;# more run time benefit when multiple route_opt commands are used
#	uncompress_scenario
#	route_opt -incremental -size_only ;# to recover final QoR

set route_opt_cmd "route_opt -skip_initial_route -effort $ROUTE_OPT_EFFORT -xtalk_reduction" 

## route_opt -power performs both power aware optimization (PAO, for ex, replacing LVT with HVT cells), 
#  and power recovery (PR, for ex, at the end of route_opt, recovering power by sizing).
#  If only PAO is desired and not PR, please do the following:
#  1. set_route_opt_strategy -power_aware_optimization true
#  2. comment out the line below (-power is not needed)
if {$POWER_OPTIMIZATION} {lappend route_opt_cmd -power}

echo $route_opt_cmd
eval $route_opt_cmd

if {[file exists [which $CUSTOM_ROUTE_OPT_POST_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_ROUTE_OPT_POST_SCRIPT]"
source $CUSTOM_ROUTE_OPT_POST_SCRIPT
}

if {$ICC_ENABLE_CHECKPOINT} {set_checkpoint_strategy -disable}

########################################
#   Additional route_opt practices
########################################
## For more on the post-H-2013.03 recommended postroute design closure flow, 
#  refer to SolvNet #038921
# Using the following flow can help further improvme QoR in postroute. 
# These steps come after the initial "route_opt -skip_initial":
#	set_app_var routeopt_enable_aggressive_optimization true
#	route_opt -incremental
#	set_app_var routeopt_restrict_tns_to_size_only true
#	route_opt -incremental

## To limit route_opt to specific optimizations :
#	route_opt -incremental -only_xtalk_reduction : only xtalk reduction 
#	route_opt -incremental -only_hold_time : only hold fixing 
#	route_opt -incremental -(only_)wire_size : runs wire sizing which fixes timing by applying NDR's from define_routing_rule

## To prioritize max tran fixing :
#  By default, route_opt prioritizes max delay cost over max design rule costs (e.g. max tran). 
#  To set higher priority for DRC fixing, set the following variable.
#  Note that this variable only works with the -only_design_rule option.
#  set_app_var routeopt_drc_over_timing true
#  	route_opt -incremental -only_design_rule

## To run size only but still allowing buffers to be inserted for hold fixing :
#  set_app_var routeopt_allow_min_buffer_with_size_only true
########################################

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
    ## in case new nets are created that go from one VA to another, level shifters need to be inserted on these nets
    # insert_level_shifters -all_clock_nets -verbose
########################################
#           CONNECT P/G                #
########################################
## Connect Power & Ground for non-MV and MV-mode

 if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
   source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
 } else {
    if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
    redirect -file $REPORTS_DIR_ROUTE_OPT/route_opt.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

save_mw_cel -as $ICC_ROUTE_OPT_CEL

if {$ICC_REPORTING_EFFORT == "MED" } {
 redirect -tee -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.qor {report_qor}
 redirect -tee -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.qor -append {report_qor -summary}
 # redirect -tee -file $REPORTS_DIR_PLACE_OPT/$ICC_ROUTE_OPT_CEL.qor -append {report_timing_histogram -range_maximum 0 -scenario [all_active_scenarios]}
 # redirect -tee -file $REPORTS_DIR_PLACE_OPT/$ICC_ROUTE_OPT_CEL.qor -append {report_timing_histogram -range_minimum 0 -scenario [all_active_scenarios]}
 redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.con {report_constraints}
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
  redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.max.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max}
  redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.min.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min}
}
if {$ICC_REPORTING_EFFORT == "MED" && $POWER_OPTIMIZATION } {
  redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.power {report_power -nosplit -scenario [all_active_scenarios]}
}

## Uncomment if you want detailed routing violation report with or without antenna info
# if {$ICC_FIX_ANTENNA} {
#    verify_zrt_route -antenna true ;
# } else {
#    verify_zrt_route -antenna false ;
#   }



if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -clock_tree -name $ICC_ROUTE_OPT_CEL
 redirect -file $REPORTS_DIR_ROUTE_OPT/$ICC_ROUTE_OPT_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}
## This script will check correlation between Primetime and StarRC and write out a timing and QoR report 
# For Primetime, if the variable values in ICC differ they will be changed to the PT value
if {[file exists [which $ICC_SIGNOFF_OPT_CHECK_CORRELATION_POSTROUTE_SCRIPT]]} { 
  source $ICC_SIGNOFF_OPT_CHECK_CORRELATION_POSTROUTE_SCRIPT 
}

# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

