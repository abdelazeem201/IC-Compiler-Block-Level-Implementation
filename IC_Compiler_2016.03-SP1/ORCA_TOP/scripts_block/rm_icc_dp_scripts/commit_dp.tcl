##########################################################################################
# ICC Hierarchical RM								 	 
# commit_dp: Commit, Check Pin Assignment, and Split Libraries			 	 
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

set SEV(src) pin_assignment_budgeting_dp
set SEV(dst) commit_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL $SEV(src) 
set ICC_DP_COMMIT_CEL $SEV(dst) 
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
copy_mw_cel -from $ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL -to $ICC_DP_COMMIT_CEL
open_mw_cel $ICC_DP_COMMIT_CEL
link

source common_placement_settings_icc.tcl


#########################################################################################
## Commit Plangroups									#
#########################################################################################
## Write out floorplan with plan groups
write_floorplan -create_terminal -placement {io hard_macro} -row -track ${RESULTS_DIR}/fullchip_plangroup.tcl
write_def -version 5.6 -rows -macro -pins -blockages -verbose -output ${RESULTS_DIR}/fullchip.def
report_voltage_area -all > ${REPORTS_DIR_DP_COMMIT}/fullchip.icc_dp.voltage_area.rpt

commit_fp_plan_groups -push_down_power_and_ground_straps
save_mw_cel -hierarchy

if {$DFT && $ICC_DP_DFT_FLOW} {
  redirect -file $REPORTS_DIR_DP_COMMIT/${ICC_DP_COMMIT_CEL}_check_scan_chain.rpt {check_scan_chain}
  #redirect -file $REPORTS_DIR_DP_COMMIT/${ICC_DP_COMMIT_CEL}_report_scan_chain.rpt {report_scan_chain}
}

#########################################################################################
## Check Pin Assignment Quality								#
#########################################################################################
## The following commands have been performed after place_fp_pins in pin_assignment_budgeting_dp.tcl. 
#  If needed, uncomment them to check the SM pins.
#  check_fp_pin_assignment -pin_spacing -pin_preroute_spacing -shorts -missing > ${REPORTS_DIR_DP_COMMIT}/${ICC_DP_COMMIT_CEL}_check_pin_assignment.rpt
#  check_fp_pin_alignment > ${REPORTS_DIR_DP_COMMIT}/${ICC_DP_COMMIT_CEL}_check_pin_alignment.rpt

# use the following to view feedthough nets:
# File/Task/Design Planning/Pin Assignment/Feedthrough Analysis 

#########################################################################################
## Split Libraries									#
#########################################################################################
close_mw_lib
split_mw_lib -from $MW_DESIGN_LIBRARY $ICC_DP_COMMIT_CEL

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

