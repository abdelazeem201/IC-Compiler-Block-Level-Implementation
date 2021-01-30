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

set SEV(src) clock_opt_cts_icc
set SEV(dst) clock_opt_psyn_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_CLOCK_OPT_CTS_CEL $SEV(src) 
set ICC_CLOCK_OPT_PSYN_CEL $SEV(dst) 
###############################################
## clock_opt_psyn_icc: Post CTS optimization ##
###############################################
 
open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_CLOCK_OPT_PSYN_CEL}" 
copy_mw_cel -from $ICC_CLOCK_OPT_CTS_CEL -to $ICC_CLOCK_OPT_PSYN_CEL
open_mw_cel $ICC_CLOCK_OPT_PSYN_CEL



## Optimization Common Session Options - set in all sessions
source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl



## Source CTS Options 
source -echo common_cts_settings_icc.tcl

## Source Post CTS Options
source -echo common_post_cts_timing_settings.tcl


set_app_var compile_instance_name_prefix icc_clock 

  if {$ICC_MCMM_CLOCK_OPT_PSYN_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_CLOCK_OPT_PSYN_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }

  ## If you add additional scenarios after clock_opt_cts_icc step, use the following command to propagate all clock sources for active scenarios :
  #	propagate_all_clocks
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {$ICC_AOCV_SCENARIO_MAPPING != "" || [file exists  [which $ICC_IN_AOCV_TABLE_FILE]]} {
  # Enable AOCV analysis
  set_app_var timing_aocvm_enable_analysis true
  set_app_var timing_aocvm_enable_distance_analysis true

  ## For when scenario specific AOCV data is to be applied
  if {$timing_library_derate_is_scenario_specific} {
    set cur_scenario [current_scenario]
    foreach pair $ICC_AOCV_SCENARIO_MAPPING {
      if {[file exists [which [lindex $pair 1] ] ]} {
        current_scenario [lindex $pair 0]
        read_aocvm [lindex $pair 1]
        # Report specified AOCV data and computed derates for the scenario
        redirect -append $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.aocvm.rpt {current_scenario; report_ocvm -type aocvm -nosplit}
      } else {
        echo "Error: Could not find the AOCV table file [lindex $pair 1] for the scenario [lindex $pair 0]"
      }
    }
    current_scenario $cur_scenario
  } else {
  ## If the AOCV data is not scenario specific 
    if {[file exists  [which $ICC_IN_AOCV_TABLE_FILE]]} {
      # Read AOCV tables for design, hierarchical cells or lib cells
      read_aocvm $ICC_IN_AOCV_TABLE_FILE
   
      # Report specified AOCV data and computed derates
      redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.aocvm.rpt {report_ocvm -type aocvm -nosplit}
    }
  }
}

# Controls the effort level of TNS optimization
set_optimization_strategy -tns_effort $ICC_TNS_EFFORT_PREROUTE

extract_rc
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {$ICC_ENABLE_CHECKPOINT} {
echo "RM-Info : Please ensure there's enough disk space before enabling the set_checkpoint_strategy feature."
set_checkpoint_strategy -enable -overwrite
# The -overwrite option is used by default. Remove it if needed.
}

if {[file exists [which $CUSTOM_CLOCK_OPT_PSYN_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CLOCK_OPT_PSYN_PRE_SCRIPT]"
source $CUSTOM_CLOCK_OPT_PSYN_PRE_SCRIPT
}
set clock_opt_psyn_cmd "clock_opt -no_clock_route -only_psyn -area_recovery" 
if {$PLACE_OPT_CONGESTION_DRIVEN} {lappend clock_opt_psyn_cmd -congestion}
if {!$DFT && [get_scan_chain] == 0} {lappend clock_opt_psyn_cmd -continue_on_missing_scandef}
if {$POWER_OPTIMIZATION} {lappend clock_opt_psyn_cmd -power}
echo $clock_opt_psyn_cmd
eval $clock_opt_psyn_cmd
## Use -optimize_dft if you have SCANDEF and there are scan nets with hold violations.
#  Note that scan wirelength can increase and may impact QoR.

if {[file exists [which $CUSTOM_CLOCK_OPT_PSYN_POST_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CLOCK_OPT_PSYN_POST_SCRIPT]"
source $CUSTOM_CLOCK_OPT_PSYN_POST_SCRIPT
}

if {$ICC_ENABLE_CHECKPOINT} {set_checkpoint_strategy -disable}

route_zrt_group -all_clock_nets -reuse_existing_global_route true -stop_after_global_route true
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
############################################################################################################
# ADDITIONAL FEATURES FOR THE POST CTS OPTIMIZATION
############################################################################################################

## When the design has congestion issues post CTS, use :
# refine_placement -congestion_effort medium

## Additional optimization can be done using the psynopt command
# psynopt -effort "medium|high"

if {$CLOCK_OPT_PSYN_PREROUTE_FOCALOPT_LAYER_OPTIMIZATION} {
## For advanced technologies, where upper metal layer resistance values are much smaller then lower layer ones,
#  you can perform layer optimization to improve existing buffer trees.
#  Use set_preroute_focal_opt_strategy to customize the settings.
report_preroute_focal_opt_strategy
preroute_focal_opt -layer_optimization
}

if {$CLOCK_OPT_PSYN_PREROUTE_FOCALOPT_AUTO_NDR} {
## This will assign 2x width spacing non-default rules to timing critical nets while taking congestion into
# consideration. The automatically generated non-default rule will be named "auto_ndr_rule" and can be
# reported by the report_net_routing_rule command. 
set_preroute_focal_opt_strategy -congestion_effort high
preroute_focal_opt -auto_routing_rule
}


########################################
#         ANTENNA PREVENTION           #
########################################


if {$ICC_USE_DIODES && $ICC_PORT_PROTECTION_DIODE != ""} {
 ## Optionally insert a diode before routing to avoid antenna's on the ports of the block
 remove_attribute $ICC_PORT_PROTECTION_DIODE dont_use
 set ports [remove_from_collection [get_ports * -filter "direction==in"] [get_ports $ICC_PORT_PROTECTION_DIODE_EXCLUDE_PORTS]]
 insert_port_protection_diodes -prefix port_protection_diode -diode_cell [get_lib_cells $ICC_PORT_PROTECTION_DIODE] -port $ports -ignore_dont_touch
 legalize_placement
 
}

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
    redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/clock_opt_psyn.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

save_mw_cel -as $ICC_CLOCK_OPT_PSYN_CEL 


if {$ICC_REPORTING_EFFORT == "MED" } {
 redirect -tee -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.qor {report_qor}
 redirect -tee -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.qor -append {report_qor -summary}
 # redirect -tee -file $REPORTS_DIR_PLACE_OPT/$ICC_CLOCK_OPT_PSYN_CEL.qor -append {report_timing_histogram -range_maximum 0 -scenario [all_active_scenarios]}
 # redirect -tee -file $REPORTS_DIR_PLACE_OPT/$ICC_CLOCK_OPT_PSYN_CEL.qor -append {report_timing_histogram -range_minimum 0 -scenario [all_active_scenarios]}
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.con {report_constraints}
}


if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.max.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.min.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}
if {$ICC_REPORTING_EFFORT == "MED" && $POWER_OPTIMIZATION } {
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.power {report_power -nosplit -scenario [all_active_scenarios]}
}

## Create Snapshot and Save
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.placement_utilization.rpt {report_placement_utilization -verbose}
 create_qor_snapshot -clock_tree -name $ICC_CLOCK_OPT_PSYN_CEL
 redirect -file $REPORTS_DIR_CLOCK_OPT_PSYN/$ICC_CLOCK_OPT_PSYN_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}
## Categorized Timing Report (CTR)
#  Use CTR in the interactive mode to view the results of create_qor_snapshot.
#  Recommended to be used with GUI opened.
#	query_qor_snapshot -display (or GUI: Timing -> Query QoR Snapshot)
#  query_qor_snapshot condenses the timing report into a cross-referencing table for quick analysis. 
#  It can be used to highlight violating paths and metric in the layout window and timing reports. 
#  CTR also provides special options to focus on top-level and hierarchical timing issues. 
#  When dealing with dirty designs, increasing the number violations per path to 20-30 when generating a snapshot can help 
#  find more issues after each run (create_qor_snapshot -max_paths 20). 

# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

