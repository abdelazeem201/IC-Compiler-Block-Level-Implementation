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

set SEV(src) clock_opt_route_icc
set SEV(dst) route_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_CLOCK_OPT_ROUTE_CEL $SEV(src) 
set ICC_ROUTE_CEL $SEV(dst) 

########################
## route_icc: Routing ##
########################

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_ROUTE_CEL}"
copy_mw_cel -from $ICC_CLOCK_OPT_ROUTE_CEL -to $ICC_ROUTE_CEL
open_mw_cel $ICC_ROUTE_CEL


source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl


########################################
#    LOAD THE ROUTE AND SI SETTINGS    #
########################################

source -echo common_route_si_settings_zrt_icc.tcl


  ##########################
  ## FIX SPECIAL MV CELLS
  ##########################

  if {[all_level_shifters] != ""} {
    set LS_at_top_physical_hierarchy [filter_collection [all_level_shifters] "within_block_abstraction==false"]
    set_dont_touch $LS_at_top_physical_hierarchy
    set_attribute $LS_at_top_physical_hierarchy is_fixed true
  }

  if {[all_ao_cells] != ""} {
    set AO_at_top_physical_hierarchy [filter_collection [all_ao_cells] "within_block_abstraction==false"]
    set_dont_touch $AO_at_top_physical_hierarchy
    set_attribute $AO_at_top_physical_hierarchy is_fixed true
  }

  if {$RR_CELLS != ""} {
    set RR [get_cells -hier -f "ref_name =~ ${RR_CELLS}*"]
    set_dont_touch $RR
    set_attribute $RR is_fixed true
  }

  #############################
  ## COMPLETE POWER CONNECTIONS
  #############################
  
  check_mv_design -verbose
  
####Pre route_opt checks
##Check for Ideal Nets
set num_ideal [sizeof_collection [all_ideal_nets]]
if {$num_ideal >= 1} {echo "RM-Error: $num_ideal Nets are ideal prior to route_opt. Please investigate it."}

##Check for HFNs
set hfn_thres "41 101 501"
foreach thres $hfn_thres {
  set num_hfn [sizeof_collection [all_high_fanout -nets -threshold $thres]]
  echo "RM-Info: Number of nets with fanout > $thres = $num_hfn"
  if {$thres == 501 && $num_hfn >=1} {
    echo "RM-Error: $num_hfn Nets with fanout > 500 exist prior to route_opt - Please check if marked ideal - possibly add buffer tree"
  }
}
  if {$ICC_MCMM_ROUTE_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_ROUTE_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }


if {$ICC_DBL_VIA } {
  ########################################
  #        Rundant via insertion         #
  ########################################

  ## Redundant via definitions should be specified in common_route_si_settings_zrt_icc.tcl or by using the ICC_CUSTOM_DBL_VIA_DEFINE_SCRIPT variable 

  ## When running redundant via insertion in MCMM mode, be aware that it works only for the current_scenario - 
  #  You can use [get_dominant scenarios] command to get critical scenarios loaded :
  #  set_active_scenarios [get_dominant_scenarios]
  
  ## To enable automatic redundant via insertion after each detail route change without the need of the standalone 
  #  insert_zrt_redundant_vias command, set the following option, otherwise, run the standalone insert_zrt_redundant_via command after routing.
  #  For 20nm consideration, if routing DRC becomes higher priority than redundant via conversion rate, set ICC_DBL_VIA_DURING_INITIAL_ROUTING to FALSE.
  #  The standalone insert_zrt_redundant_via command will be enabled after routing.
  if {$ICC_DBL_VIA_DURING_INITIAL_ROUTING} {
  	set_route_zrt_common_options -post_detail_route_redundant_via_insertion medium
  }

  ## The following are additional features if ICC_DBL_VIA_FLOW_EFFORT is set to a value other than low (default is low) :
  #  To Optimize wire length and via counts : 
  if {$ICC_DBL_VIA_FLOW_EFFORT != "LOW"} {
    	set_route_zrt_detail_options -optimize_wire_via_effort_level high ;# default is low
  }
  #  To enable concurrent redundant via insertion :
  if {$ICC_DBL_VIA_FLOW_EFFORT == "HIGH"} {
    set_route_zrt_common_options -concurrent_redundant_via_mode reserve_space ;# default is off
    set_route_zrt_common_options -concurrent_redundant_via_effort_level medium  ;# default is low; only works if the above is not off
  }

}

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {[file exists [which $CUSTOM_ROUTE_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_ROUTE_PRE_SCRIPT]"
source $CUSTOM_ROUTE_PRE_SCRIPT
}

########################################
#       ROUTE_OPT CORE COMMAND         #
########################################

## some checks upfront 
#check_zrt_routability
report_preferred_routing_direction

## Route first the design 
  report_tlu_plus_files -scenario [all_scenarios]

  route_opt -initial_route_only 
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {$ICC_DBL_VIA && !$ICC_DBL_VIA_DURING_INITIAL_ROUTING} {
  	save_mw_cel -as route_opt_icc_pre_rv_insertion 
  	insert_zrt_redundant_vias 
  	set_route_zrt_common_options -post_detail_route_redundant_via_insertion medium
}

## For high effort ICC_DBL_VIA_FLOW_EFFORT, concurrent_redundant_via_mode is on before "route_opt -initial_route_only" and then turned off after routing
if {$ICC_DBL_VIA && $ICC_DBL_VIA_FLOW_EFFORT == "HIGH"} {
  set_route_zrt_common_options -concurrent_redundant_via_mode off
}

if {[file exists [which $CUSTOM_ROUTE_POST_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_ROUTE_POST_SCRIPT]"
source $CUSTOM_ROUTE_POST_SCRIPT
}

if {$ICC_CTS_UPDATE_LATENCY} {
   update_clock_latency
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
    redirect -file $REPORTS_DIR_ROUTE/route.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

save_mw_cel -as $ICC_ROUTE_CEL

if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT == "MED" } {
 redirect -tee -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.qor {report_qor}
 redirect -tee -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.qor -append {report_qor -summary}
 redirect -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.con {report_constraints}
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.max.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.min.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}

## Uncomment if you want detailed routing violation report with or without antenna info
# if {$ICC_FIX_ANTENNA} {
#    verify_zrt_route -antenna true ;
# } else {
#    verify_zrt_route -antenna false ;
#   }



if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -clock_tree -name $ICC_ROUTE_CEL
 redirect -file $REPORTS_DIR_ROUTE/$ICC_ROUTE_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}




if {$ICC_CREATE_GR_PNG} {
  if !{[info exists env(DISPLAY)]} {
  	echo "RM-Info: DISPLAY is not set. GUI snapshot will be skipped."
  } else {
  # start GUI
  gui_start
  
  # turn off DR
  gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting showRoute -value false
  gui_execute_events

  # show congestion overlay
  gui_set_setting -window [gui_get_current_window -types Layout -mru] -setting mmName -value AREAPARTITION 
  gui_zoom -window [gui_get_current_window -view] -full
  gui_execute_events
  
  # save snapshots
  gui_write_window_image -window [gui_get_current_window -view -mru] -file ${REPORTS_DIR_ROUTE}/${ICC_ROUTE_CEL}.GR.png
  
  # stop GUI
  gui_stop
  }
}

# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

