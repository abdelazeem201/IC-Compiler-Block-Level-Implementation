#################################################################################
# Formality Verification Script for
# IC Compiler Chip-Level Reference Methodology Script
# Script: fm.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
#################################################################################

set_app_var sh_allow_tcl_with_set_app_var_no_message_list [list target_library link_library]

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

set SEV(src) outputs_icc
set SEV(dst) outputs_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 

if {$ICC_INIT_DESIGN_INPUT == "MW"} {
	echo "RM-Error: The RM scripts are generated with UPF configuration but \$ICC_INIT_DESIGN_INPUT is set as MW."
	echo "	      Currently fm.tcl does not support UPF designs with MW input."
	echo "	      Exiting the program now..."
	exit
}

#################################################################################
# Sections of this script may be uncommented to perform various types of verifications.
#
# The default verification flow assumes the gate vs gate (G2G) verification 
# of the files going into IC Compiler and the resulting Verilog netlist from IC Compiler.
#
# This script may be manually modified to perform other types of verifications as needed.
# 
# This script will use variables set in the ICC-RM scripts icc_setup.tcl and common_setup.tcl
#
#################################################################################

#################################################################################
## Synopsys Auto Setup Mode
#################################################################################

## This mode applies to RTL vs gate verifications which are not the default for this script.
## 
## set_app_var synopsys_auto_setup true

## Note: The Synopsys Auto Setup mode is less conservative than the Formality default mode, 
## and is more likely to result in a successful verification out-of-the-box.
## 
## Using the Setting this variable will change the default values of the variables listed here below
## You may change any of these variables back to their default settings to be more conservative.
## Uncomment the appropriate lines below to revert back to their default settings:

	## set_app_var hdlin_ignore_parallel_case true
	## set_app_var hdlin_ignore_full_case true
	## set_app_var verification_verify_directly_undriven_output true
	## set_app_var hdlin_ignore_embedded_configuration false
	## set_app_var svf_ignore_unqualified_fsm_information true
	## set_app_var signature_analysis_allow_subset_match true

## Other variables with changed default values are described in the next few sections.

#################################################################################
## Setup for handling undriven signals in the design
#################################################################################

## The Synopsys Auto Setup mode sets undriven signals in the reference design to
## "0" or "BINARY" (as done by DC), and the undriven signals in the impl design are
## forced to "BINARY".  This is done with the following setting:
	## set_app_var verification_set_undriven_signals synthesis
## Uncomment the next line to revert back to the more conservative default setting:

	## set_app_var verification_set_undriven_signals BINARY:X


#################################################################################
## Setup for simulation/synthesis mismatch messaging
#################################################################################

## The Synopsys Auto Setup mode will produce warning messages, not error messages,
## when Formality encounters potential differences between simulation and synthesis.
## Uncomment the next line to revert back to the more conservative default setting:

	## set_app_var hdlin_error_on_mismatch_message true

#################################################################################
## Setup for Clock-gating
#################################################################################

## The Synopsys Auto Setup mode, along with the SVF file, will appropriately set the clock-gating variable.
## Otherwise, the user will need to notify Formality of clock-gating by uncommenting the next line:

	## set_app_var verification_clock_gate_hold_mode any

#################################################################################
## Setup for instantiated DesignWare or function-inferred DesignWare components
#################################################################################

## Set this variable ONLY if your design contains instantiated DW or function-inferred DW

	## set_app_var hdlin_dwroot "" ;# Enter the pathname to the top-level of the DC tree

#################################################################################
## Setup for handling missing design modules
#################################################################################

## If the design has missing blocks or missing components in both the reference and implementation designs,
## uncomment the following variable so that Formality can complete linking each design:

	## set_app_var hdlin_unresolved_modules black_box

#################################################################################
## Read in the SVF file(s)
#################################################################################

## Set this variable to point to individual SVF file(s) or to a directory containing SVF files.

## set_svf ${SOURCE_DIR}/${DESIGN_NAME}.mapped.svf

#################################################################################
# Read in the libraries
#################################################################################

foreach tech_lib "${TARGET_LIBRARY_FILES} ${ADDITIONAL_LINK_LIB_FILES}" {
  read_db -technology_library $tech_lib
}

#################################################################################
# Read in the Reference Design
#
# This sections uses ICC-RM variables to determine the type of reference design
#################################################################################

# For DDC
# read_ddc -r ${SOURCE_DIR}/${DESIGN_NAME}.mapped.ddc
if {$ICC_INIT_DESIGN_INPUT == "DDC" } {
	read_ddc -r $ICC_IN_DDC_FILE
}


# Or, for Verilog
# read_verilog -r ${SOURCE_DIR}/${DESIGN_NAME}.mapped.v
if {$ICC_INIT_DESIGN_INPUT == "VERILOG" } {
	read_verilog -r $ICC_IN_VERILOG_NETLIST_FILE
}

if { $ICC_INIT_DESIGN_INPUT == "DDC" || $ICC_INIT_DESIGN_INPUT == "VERILOG" } {
	# Setting the top of design for these input formats
	set_top r:/WORK/${DESIGN_NAME}

	#################################################################################
	# For a UPF MV flow, read in the UPF file for the Reference Design
	#################################################################################
	# load_upf -r ${SOURCE_DIR}/${DESIGN_NAME}.mapped.upf
	if { [file exists [which $ICC_IN_UPF_FILE]]} {
          load_upf -r $ICC_IN_UPF_FILE 
	} else {
	  echo "RM-Error: \$ICC_IN_UPF_FILE $ICC_IN_UPF_FILE is not found or not defined."
	  echo "	      For UPF designs, fm.tcl requires one single UPF file."
	  echo "	      Exiting the program now..."
	  exit
	}
}


#################################################################################
# Read in the Implementation Design from ICC-RM result
#
# Note: In ICC, When writing out a Verilog netlist for Formality use the following options:
# write_verilog -pg -no_physical_only_cells -supply_statement none 
#################################################################################

read_verilog -i $SOURCE_DIR/$DESIGN_NAME.output.pg.v 

set_top i:/WORK/${DESIGN_NAME}

#################################################################################
# Setup for scan re-ordering
#
# If IC Compiler has performed scan re-ordering, the user will need to manually
# set constants on the scan enable and test mode signals to disable scan path
# verification.
# 
# Example command format:
#
#   set_constant -type port r:/WORK/${DESIGN_NAME}/<port_name> <constant_value> 
#   set_constant -type port i:/WORK/${DESIGN_NAME}/<port_name> <constant_value> 
#
#
# Also, the user will need to manually perform set_dont_verify on dedicated scanout
# ports to avoid verification failures on those ports.
#
# Example command format:
#
#   set_dont_verify_point -type port r:/WORK/${DESIGN_NAME}/<port_name>
#   ...
#
#################################################################################

#################################################################################
# Note in using the UPF MV flow with Formality:
#
# By default Formality verifies low power designs with all UPF supplies 
# constrained to their ON state.  For the IC Compiler reference methodology flow,
# is it recommended to set this variable to false instead.
#
      set_app_var verification_force_upf_supplies_on false
#
#################################################################################

#################################################################################
# Match compare points and report unmatched points 
#################################################################################

match

report_unmatched_points > ${REPORTS_DIR_FORMALITY}/${DESIGN_NAME}.fmv_unmatched_points.rpt


#################################################################################
# Verify and Report
#
# If the verification is not successful, the session will be saved and reports
# will be generated to help debug the failed or inconclusive verification.
#################################################################################

if { ![verify] }  {  
  save_session -replace ${REPORTS_DIR_FORMALITY}/${DESIGN_NAME}
  report_failing_points > ${REPORTS_DIR_FORMALITY}/${DESIGN_NAME}.fmv_failing_points.rpt
  report_aborted > ${REPORTS_DIR_FORMALITY}/${DESIGN_NAME}.fmv_aborted_points.rpt
  # Use analyze_points to help determine the next step in resolving verification
  # issues. It runs heuristic analysis to determine if there are potential causes
  # other than logical differences for failing or hard verification points. 
  analyze_points -all > ${REPORTS_DIR_FORMALITY}/${DESIGN_NAME}.fmv_analyze_points.rpt
  set fm_passed FALSE
} else {
  set fm_passed TRUE
}

if {!$fm_passed} {
  # Output this message to be used as a Lynx metric indicating verification failed
  sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FORMAL | 0"
}  else {
  # Output this message to be used as a Lynx metric indicating verification passed
  sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FORMAL | 1"
}

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

