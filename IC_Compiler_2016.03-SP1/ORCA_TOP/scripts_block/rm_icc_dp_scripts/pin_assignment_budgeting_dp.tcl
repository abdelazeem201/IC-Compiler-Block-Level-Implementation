##################################################################################################
# ICC Hierarchical RM								 	 	 
# pin_assignment_budgeting_dp: Pin Assignment, Optimization, and Timing Budgetting
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

set SEV(src) routeability_on_plangroups_dp
set SEV(dst) pin_assignment_budgeting_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL $SEV(src) 
set ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL $SEV(dst) 
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
copy_mw_cel -from $ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL -to $ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL
open_mw_cel $ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL
link

source common_placement_settings_icc.tcl
source common_optimization_settings_icc.tcl


#########################################################################################
## Pin Assignment									#
#########################################################################################

if {$ICC_DP_ALLOW_FEEDTHROUGH} {
  set_fp_pin_constraints -allow_feedthroughs on -keep_buses_together on
} else {
  set_fp_pin_constraints -keep_buses_together on
}
## If -allow_feedthroughs on is enabled :
#  - You can use the -feedthrough_map_file option to specify a feedthrough map input file
#  - You can use report_fp_feedthroughs command to report feedthroughs


report_fp_pin_constraints

set_route_zrt_common_options -plan_group_aware all_routing
## For large designs, you can try top level routing only by:
#  set_route_zrt_common_options -plan_group_aware top_level_routing_only
route_zrt_global -exploration true

place_fp_pins -use_existing_routing [get_plan_groups *]
save_mw_cel -as ${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_place_fp_pins

check_fp_pin_assignment -pin_spacing -pin_preroute_spacing -shorts -missing [get_plan_groups *] > ${REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING}/${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_check_pin_assignment.rpt
check_fp_pin_alignment > ${REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING}/${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_check_pin_alignment.rpt

# To view feedthrough nets, use the following command from GUI : 
# File/Task/Design Planning/Pin Assignment/Pin and Feedthrough Analysis

#########################################################################################
## Optimization										#
#########################################################################################
## For large designs, you can try using trace mode by using the following command:
#	set_fp_trace_mode

set compile_instance_name_prefix dp_ipo
optimize_fp_timing 
# Here're some options to consider:
#       -fix_design_rule (fix max tran violations)
#       -effort effort (medium and high)
#       -report_qor (report QoR of optimization)

## If you turn on trace mode before optimize_fp_timing, please use the following command to turn it off:
#	end_fp_trace_mode

save_mw_cel -as ${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_ipo
redirect -file ${REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING}/${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_ipo.rpt {report_timing -nosplit -cap -tran -input -net -delay max -attribute -physical}
create_qor_snapshot -name ${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_ipo

#########################################################################################
## Timing Budgeting									#
#########################################################################################
check_fp_timing_environment -unbudgetable_pins -unconstrained_pins > $REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING/${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_check_timing_env.rpt

## If clock tree is fully synthesized on the design, set the following to let timing budgeting recognize the clock tree:
#	set synthesized_clocks TRUE
#	set_propagated_clock [get_clocks *]

allocate_fp_budgets -file_format_spec "$BUDGETING_SDC_OUTPUT_DIR/m.sdc"
# use ./sdc/m.sdc to write budgets to "sdc" dir in files named based on cell master
# use ./sdc/i.sdc to write budgets to "sdc" dir in files named based on instance name
# We're using cell master style through out the RM

check_fp_budget_result -block $ICC_DP_PLAN_GROUPS -file_name ${REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING}/${ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL}_budget_result.rpt

# remove_propagated_clock -all

########################################
#           CONNECT P/G                #
########################################
## Connect Power & Ground for non-MV and MV-mode

if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
  source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
} else {
  if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
  redirect -file $REPORTS_DIR_DP_PIN_ASSIGNMENT_BUDGETING/$ICC_DP_PIN_ASSIGNMENT_BUDGETING_CEL.mv {check_mv_design -verbose}
}
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }


# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

save_mw_cel
close_mw_lib
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

