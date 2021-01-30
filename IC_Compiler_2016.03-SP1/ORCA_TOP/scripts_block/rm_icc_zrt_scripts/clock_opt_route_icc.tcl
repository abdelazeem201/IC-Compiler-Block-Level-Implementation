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
  set SEV(src) clock_opt_psyn_icc 
  set SEV(dst) clock_opt_route_icc 
set SEV(script_file) [info script] 

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl 

sproc_script_start 

  source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
    set ICC_CLOCK_OPT_PSYN_CEL $SEV(src)
    set ICC_CLOCK_OPT_ROUTE_CEL $SEV(dst)

#############################################
## clock_opt_route_icc: CLock Tree routing ##
#############################################

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_CLOCK_OPT_ROUTE_CEL}"
  copy_mw_cel -from $ICC_CLOCK_OPT_PSYN_CEL -to $ICC_CLOCK_OPT_ROUTE_CEL 
open_mw_cel $ICC_CLOCK_OPT_ROUTE_CEL ;




## Optimization Common Session Options - set in all sessions
source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl



## Source CTS Options 
source -echo common_cts_settings_icc.tcl

## Source Post CTS Options
source -echo common_post_cts_timing_settings.tcl

## Source Route Options
source common_route_si_settings_zrt_icc.tcl
## Turning off SI for clock routing
set_si_options -delta_delay false -min_delta_delay false -route_xtalk_prevention false


  if {$ICC_MCMM_CLOCK_OPT_ROUTE_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_CLOCK_OPT_ROUTE_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }


  if {[file exists [which $CUSTOM_SECONDARY_POWER_ROUTE_SCRIPT]]} {
        echo "RM-Info: Sourcing [which $CUSTOM_SECONDARY_POWER_ROUTE_SCRIPT]"
        source -echo $CUSTOM_SECONDARY_POWER_ROUTE_SCRIPT
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {[file exists [which $CUSTOM_CLOCK_OPT_ROUTE_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CLOCK_OPT_ROUTE_PRE_SCRIPT]"
source $CUSTOM_CLOCK_OPT_ROUTE_PRE_SCRIPT
}

##################################
#       CLOCK ROUTING            #
##################################
# set_delay_calculation_options -routed_clock arnoldi
route_zrt_group -all_clock_nets -reuse_existing_global_route true

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

## For additional psynopt after clock nets are routed, try the following :
#extract_rc -force
#update_timing
#set_attribute [get_cells -of [get_flat_pins [all_fanout -flat -from [get_attribute [get_clocks *] sources]] -filter pin_on_clock_network==true]] is_fixed true
#set psynopt_cmd "psynopt -area_recovery"
#if {$POWER_OPTIMIZATION} {lappend psynopt_cmd -power}
#echo $psynopt_cmd
#eval $psynopt_cmd  

if {[file exists [which $CUSTOM_CLOCK_OPT_ROUTE_PRE_CTO_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CLOCK_OPT_ROUTE_PRE_CTO_SCRIPT]"
source $CUSTOM_CLOCK_OPT_ROUTE_PRE_CTO_SCRIPT
}

if {$ICC_POST_CLOCK_ROUTE_CTO} {
   optimize_clock_tree -routed_clock_stage detail
}

if {$ICC_CTS_SHIELD_RULE_NAME != ""} {
## Generate clock shielding wires
#  Note: if routing resource is a concern, consider to run these at chip_finish_icc step instead
create_zrt_shield
set_route_zrt_common_options -reshield_modified_nets reshield
set_extraction_options -virtual_shield_extraction false
}
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }


if {[file exists [which $CUSTOM_CLOCK_OPT_ROUTE_POST_CTO_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_CLOCK_OPT_ROUTE_POST_CTO_SCRIPT]"
source $CUSTOM_CLOCK_OPT_ROUTE_POST_CTO_SCRIPT
}


  redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/${ICC_CLOCK_OPT_ROUTE_CEL}.mv {check_mv_design -verbose}
########################################
#           CONNECT P/G                #
########################################
## Connect Power & Ground for non-MV and MV-mode

 if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
   source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
 } else {
    if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
    redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/clock_opt_route.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

save_mw_cel -as $ICC_CLOCK_OPT_ROUTE_CEL 


if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.max.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.min.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}

if {$ICC_REPORTING_EFFORT == "MED" } {
 redirect -tee -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.qor {report_qor}
 redirect -tee -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.qor -append {report_qor -summary}
 redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.con {report_constraints}
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -clock_tree -name $ICC_CLOCK_OPT_ROUTE_CEL
 redirect -file $REPORTS_DIR_CLOCK_OPT_ROUTE/$ICC_CLOCK_OPT_ROUTE_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}



# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

