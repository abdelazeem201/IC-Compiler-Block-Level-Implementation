#################################################################################
# Verification Compiler Low Power Static Signoff Script for
# IC Compiler Reference Methodology 
# Script: ##vc_lp.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2011-2015 Synopsys, Inc. All rights reserved.
#################################################################################


## Enable the default behavior of sh_continue_on_error to be same as DC
set_app_var sh_continue_on_error true
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
# Lynx Compatible Setup : Script Initialization
#
# This section is used to initialize the scripts for use with the Lynx Design
# System.  Users should not make modifications to this section.
#################################################################################

set SEV(src) outputs_icc
set SEV(dst) outputs_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start

source -echo -verbose ../../scripts_block/rm_setup/icc_setup.tcl

read_file -netlist -top $DESIGN_NAME $SOURCE_DIR/$DESIGN_NAME.output.pg.dc.v 

read_upf $SOURCE_DIR/$DESIGN_NAME.output.upf

check_upf
check_design
check_pg

report_lp -file ${REPORTS_DIR}/${DESIGN_NAME}.vclp_report_violations.PGNETLIST.rpt
report_lp -verbose -file ${REPORTS_DIR}/${DESIGN_NAME}.vclp_report_violations.PGNETLIST.verbose.rpt

puts "RM-Info: End script [info script]\n"
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop
