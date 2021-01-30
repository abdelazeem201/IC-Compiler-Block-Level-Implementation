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

set SEV(src) route_opt_icc
set SEV(dst) chip_finish_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_ROUTE_OPT_CEL $SEV(src) 
set ICC_CHIP_FINISH_CEL $SEV(dst) 

###################################################
## chip_finish_icc: Several chipfinishing steps  ##
###################################################

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_CHIP_FINISH_CEL}"
copy_mw_cel -from $ICC_ROUTE_OPT_CEL -to $ICC_CHIP_FINISH_CEL
open_mw_cel $ICC_CHIP_FINISH_CEL


source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl



########################################
#    LOAD THE ROUTE AND SI SETTINGS    #
########################################

source -echo common_route_si_settings_zrt_icc.tcl


##Turn of soft spacing for timing optimization during chip finishing
set_route_zrt_detail_options -eco_route_use_soft_spacing_for_timing_optimization false



#############################
## COMPLETE POWER CONNECTIONS
#############################

 check_mv_design -verbose
  if {$ICC_MCMM_CHIP_FINISH_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_CHIP_FINISH_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }


  if {$ICC_REDUCE_CRITICAL_AREA} {

    ########################################
    #      CRITICAL AREA REDUCTION          #
    ########################################
  
    ## Timing driven wire spreading for shorts and widening for opens
    ## It is recommended to define a slack threshold to avoid that nets with too small slack are touched
    ## the unit of $TIMING_PRESERVE_SLACK_SETUP and $TIMING_PRESERVE_SLACK_HOLD is the library unit, so make sure that you provide the correct
    ## values in case your library has ps as unit. Default are 0.1 and 0, i.e. 0.1ns and 0ns, respectively.
    spread_zrt_wires -timing_preserve_setup_slack_threshold $TIMING_PRESERVE_SLACK_SETUP -timing_preserve_hold_slack_threshold $TIMING_PRESERVE_SLACK_HOLD
    widen_zrt_wires -timing_preserve_setup_slack_threshold $TIMING_PRESERVE_SLACK_SETUP -timing_preserve_hold_slack_threshold $TIMING_PRESERVE_SLACK_HOLD

    if { [check_error -verbose] != 0} { 
      echo "RM-Error, flagging ..." 
    }
  }
if {$ICC_FIX_ANTENNA } {

  ########################################
  #        ANTENNA DIODE FIXING          #
  ########################################
  
  if { $ICC_USE_DIODES && [file exists [which $ANTENNA_RULES_FILE]] && $ICC_ROUTING_DIODES != ""} {
       set_route_zrt_detail_options -antenna true -diode_libcell_names $ICC_ROUTING_DIODES -insert_diodes_during_routing true
       route_zrt_detail -incremental true 
   }

}
  
  ########################################
  #          AUTO SHIELDING              #
  ########################################
## Generate shielding wires for clocks (if not done in clock_opt_route_icc step) or selected signal nets
#  create_zrt_shield
#  set_route_zrt_common_options -reshield_modified_nets reshield
#  set_extraction_options -virtual_shield_extraction false
  

if {$ADD_FILLER_CELL } {

  ########################################
  #          STD CELL FILLERS            #
  ########################################
  
##Filler Cells
   if {[file exists [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]]} {
     echo "RM-Info: Sourcing [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]"
     source -echo $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT
   }


if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

}
  

if {[file exists [which $CUSTOM_CHIP_FINISH_POST_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CHIP_FINISH_POST_SCRIPT]"
source $CUSTOM_CHIP_FINISH_POST_SCRIPT
}

if {$ICC_FIX_ANTENNA || $ICC_REDUCE_CRITICAL_AREA || $ADD_FILLER_CELL } {

  ########################################
  #   TIO setup for route_opt command
  ########################################
  if {$ICC_IMPLEMENTATION_PHASE == "top"} {
  source -echo common_route_opt_tio_settings_icc.tcl
  }

  ########################################
  #     INCREMENTAL TIMING OPTO          #
  ########################################
  route_opt -incremental -size_only

  if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
}
if {$ICC_DBL_VIA } {

  ## Optionally, if DV is really a key issue, we recommend to run a 3rd time
  ## but with timing preserve on, so that any critical paths are not touched by this step.
  ########################################
  #           REDUNDANT VIA              #
  ########################################
  
  if {$ICC_DBL_VIA_FLOW_EFFORT == "HIGH"} {
   insert_zrt_redundant_vias -effort medium \
                             -timing_preserve_setup_slack_threshold $TIMING_PRESERVE_SLACK_SETUP \
                             -timing_preserve_hold_slack_threshold $TIMING_PRESERVE_SLACK_HOLD

   if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
  }



}


if {$ADD_FILLER_CELL } {

  ########################################
  #          STD CELL FILLERS            #
  ########################################
  
##Filler Cells
    if {[file exists [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]]} {
        echo "RM-Info: Sourcing [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]"
        source -echo $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT
    }


if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

}
  
  
    ## in case new nets are created that go from one VA to another, level shifters need to be inserted on these nets
    # insert_level_shifters -all_clock_nets -verbose
if {$ICC_FIX_SIGNAL_EM} {
## Signal EM
#  All details of the ICC Signal EM flow can be found here :
#  https://solvnet.synopsys.com/retrieve/023849.html
#
#  Loading EM constraint is required for EM analysis and fixing. 
#  It can be in TLUPlus, plib, ALF, or ITF format.
#     ex, set_mw_technology_file -plib plib_file_name.plib $MW_DESIGN_LIBRARY  
#     ex, set_mw_technology_file -alf alf_file_name $MW_DESIGN_LIBRARY 
#  Loading and setting switching activity steps are optional.
#     ex, read_saif -input your_switching.saif
#     ex, set_switching_activity -toggle_rate <positive number> -static_probability <0to1> [get_nets -hier *]
#  To fix signal EM, please uncomment the following commands (after route_opt is completed)
#     fix_signal_em
}

########################################
#           CONNECT P/G                #
########################################
## Connect Power & Ground for non-MV and MV-mode

 if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
   source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
 } else {
    if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
    redirect -file $REPORTS_DIR_CHIP_FINISH/chip_finish.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
##Final Route clean-up - if needed:
##Once we hit minor cleanup, best to turn off ZRoute timing options
##This avoids extraction/timing hits
set_route_zrt_global_options -timing_driven false -crosstalk_driven false
set_route_zrt_track_options -timing_driven false -crosstalk_driven false
set_route_zrt_detail_options -timing_driven false

route_zrt_eco               ;#catch any opens and try to re-route them, recheck DRC

save_mw_cel -as $ICC_CHIP_FINISH_CEL

  redirect -file $REPORTS_DIR_CHIP_FINISH/${ICC_CHIP_FINISH_CEL}.mv {check_mv_design -verbose}
  save_upf $RESULTS_DIR/${ICC_CHIP_FINISH_CEL}.upf  
if {$ICC_REPORTING_EFFORT == "MED" } {
  redirect -tee -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.qor {report_qor}
  redirect -tee -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.qor -append {report_qor -summary}
  redirect -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.con {report_constraints}
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.max.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.min.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}
#    verify_zrt_route -antenna true 
#    verify_zrt_route -antenna false 
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -tee -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.sum {report_design_physical -all -verbose}
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -clock_tree -name $ICC_CHIP_FINISH_CEL
 redirect -file $REPORTS_DIR_CHIP_FINISH/$ICC_CHIP_FINISH_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}


# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

