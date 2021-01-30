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

set SEV(src) metal_fill_icc
set SEV(dst) signoff_drc_icc 

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_METAL_FILL_CEL $SEV(src) 

open_mw_cel $ICC_METAL_FILL_CEL -lib $MW_DESIGN_LIBRARY

  ########################
  #     SIGNOFF DRC      #
  ########################

if {[file exists [which $SIGNOFF_DRC_RUNSET]] } {

  set_physical_signoff_options -exec_cmd icv -drc_runset $SIGNOFF_DRC_RUNSET

  if {$SIGNOFF_MAPFILE != ""} {
    set_physical_signoff_options -mapfile [which $SIGNOFF_MAPFILE]
  }
  
  report_physical_signoff_options
  signoff_drc

}
      ## Auto DRC Repair (ADR)
      #  When routing DRC is within a reasonable range, you can perform ADR to resolve remaining DRC
      #  Please refer to SolvNet #031882 for more information and how to generate config file for signoff_autofix_drc command

      #  signoff_drc -run_dir {./signoff_drc_run} -ignore_child_cell_errors -read_cel_view 
      #  signoff_autofix_drc -incremental_level high -config_file $config_file -init_drc_error_db signoff_drc_run 
      #  save_mw_cel 
      #  signoff_drc -run_dir {./signoff_drc_run_after} -ignore_child_cell_errors -read_cel_view

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

