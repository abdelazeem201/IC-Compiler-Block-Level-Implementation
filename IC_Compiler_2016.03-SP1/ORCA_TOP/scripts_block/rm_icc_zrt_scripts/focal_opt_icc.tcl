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

set SEV(src) chip_finish_icc
set SEV(dst) focal_opt_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_FOCAL_OPT_STARTING_CEL $SEV(src) 
set ICC_FOCAL_OPT_CEL $SEV(dst) 

###################################################
## focal_opt_icc: focal_opt
###################################################

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 ${ICC_FOCAL_OPT_CEL}"
copy_mw_cel -from $ICC_FOCAL_OPT_STARTING_CEL -to $ICC_FOCAL_OPT_CEL
open_mw_cel $ICC_FOCAL_OPT_CEL


source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl


########################################
#    LOAD THE ROUTE AND SI SETTINGS    #
########################################

source -echo common_route_si_settings_zrt_icc.tcl



#############################
## COMPLETE POWER CONNECTIONS
#############################

 check_mv_design -verbose
  if {$ICC_MCMM_FOCAL_OPT_SCENARIOS != ""} {
    set_active_scenarios $ICC_MCMM_FOCAL_OPT_SCENARIOS
  } else {
    set_active_scenarios [lminus [all_scenarios] [get_scenarios -setup false -hold false -cts_mode true]]
    ## Note: CTS only scenarios (get_scenarios -setup false -hold false -cts_mode true) are made inactive by RM during optimizations
  }

# Controls the effort level of TNS optimization
set_optimization_strategy -tns_effort $ICC_TNS_EFFORT_POSTROUTE

if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {[file exists [which $CUSTOM_FOCAL_OPT_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_FOCAL_OPT_PRE_SCRIPT]"
source $CUSTOM_FOCAL_OPT_PRE_SCRIPT
}

## focal_opt allows you to optimize a specific subset of post route violations for setup/hold/drc
## these violating endpoints can be provided via a simple ascii file, e.g. :
##          I_STACK_TOP/I3_STACK_MEM/Stack_Mem_reg_2__1_/D
## execute man focal_opt to find additional options

## Note :
#  For running route_opt and focal_opt with filler cells placed, the filler cells must be type std_filler.
#  This is done by marking the std filler cells with gdsStdFillerCell during library dataprep.
#  If you see the following message when filler cells are inserted prior to route_opt or focal_opt,
#  then that means they are not marked properly :
#     WARNING : cell <xxx> is not of std filler cell subtype

 if {$ICC_FOCAL_OPT_HOLD_VIOLS != ""} {
  if {[file exists [which $ICC_FOCAL_OPT_HOLD_VIOLS]]} {
    focal_opt -hold_endpoints $ICC_FOCAL_OPT_HOLD_VIOLS
  } elseif {$ICC_FOCAL_OPT_HOLD_VIOLS == "all"} {
    focal_opt -hold_endpoints all
    }
 }
 
 if {$ICC_FOCAL_OPT_SETUP_VIOLS != ""} {
  if {[file exists [which $ICC_FOCAL_OPT_SETUP_VIOLS]]} {
    focal_opt -setup_endpoints $ICC_FOCAL_OPT_SETUP_VIOLS
  } elseif {$ICC_FOCAL_OPT_SETUP_VIOLS == "all"} {
    focal_opt -setup_endpoints all
    }
 }
 
 if {$ICC_FOCAL_OPT_DRC_NET_VIOLS != ""} {
  if {[file exists [which $ICC_FOCAL_OPT_DRC_NET_VIOLS]]} {
    focal_opt -drc_nets $ICC_FOCAL_OPT_DRC_NET_VIOLS
  } elseif {$ICC_FOCAL_OPT_DRC_NET_VIOLS == "all"} {
    focal_opt -drc_nets all
    }
 }
 
 if {$ICC_FOCAL_OPT_DRC_PIN_VIOLS != ""} {
  if {[file exists [which $ICC_FOCAL_OPT_DRC_PIN_VIOLS]]} {
    focal_opt -drc_pins $ICC_FOCAL_OPT_DRC_PIN_VIOLS
  } elseif {$ICC_FOCAL_OPT_PIN_VIOLS == "all"} {
    focal_opt -drc_pins all
    }
 }
 
 if {$ICC_FOCAL_OPT_XTALK_VIOLS != ""} {
  if {[file exists [which $ICC_FOCAL_OPT_XTALK_VIOLS]]} {
    focal_opt -xtalk_reduction $ICC_FOCAL_OPT_XTALK_VIOLS
  }
 }


 ########################################
 #   TIO setup for route_opt command
 ########################################
 if {$ICC_IMPLEMENTATION_PHASE == "top"} {
 source -echo common_route_opt_tio_settings_icc.tcl
 }

 ## The following route_opt command performs final overall optimization with -size_only option which is used
 #  to avoid potential route and cell disturbances associated with buffer insertion. These refer to the 
 #  pre-H-2013.03 postroute design closure flow. Refer to SolvNet #034130 for details on this flow.
 #  Refer to SolvNet #038921 for more details about the post-H-2013.03 postroute design closure flow.
 route_opt -incremental -size_only

 if {$POWER_OPTIMIZATION} {
 if {[llength [get_scenarios -leakage true -active true]] == 1} {
   focal_opt -power
 } else {
   echo "RM-Error : Please specify one and only one scenario as leakage scenario for focal_opt -power."
 }
 }


if {[file exists [which $CUSTOM_FOCAL_OPT_POST_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_FOCAL_OPT_POST_SCRIPT]"
source $CUSTOM_FOCAL_OPT_POST_SCRIPT
}

save_mw_cel -as $ICC_FOCAL_OPT_CEL

if {$ICC_REPORTING_EFFORT == "MED" } {
  redirect -tee -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.qor {report_qor}
  redirect -tee -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.qor -append {report_qor -summary}
  redirect -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.con {report_constraints}
}

if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.max.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.min.tim {report_timing -nosplit -crosstalk_delta -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -tee -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.sum {report_design_physical -all -verbose}
}


## Create Snapshot and Save

if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -name $ICC_FOCAL_OPT_CEL
 redirect -file $REPORTS_DIR_FOCAL_OPT/$ICC_FOCAL_OPT_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}


# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

