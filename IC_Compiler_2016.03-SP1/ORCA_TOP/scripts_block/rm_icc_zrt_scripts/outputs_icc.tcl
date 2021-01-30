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
set SEV(dst) outputs_icc 

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_METAL_FILL_CEL $SEV(src) 
set ICC_OUTPUTS_CEL $SEV(dst) 

#######################################
####Outputs Script
#######################################

##Open Design
open_mw_cel $ICC_METAL_FILL_CEL -lib $MW_DESIGN_LIBRARY


##Change Names
change_names -rules verilog -hierarchy
save_mw_cel -as $ICC_OUTPUTS_CEL 
close_mw_cel
open_mw_cel $ICC_OUTPUTS_CEL


##Verilog
if {$ICC_WRITE_FULL_CHIP_VERILOG} {
write_verilog -diode_ports -no_physical_only_cells -pg -supply_statement none $RESULTS_DIR/$DESIGN_NAME.output.pg.v -macro_definition

## For comparison with a Design Compiler netlist,the option -diode_ports is removed
write_verilog -no_physical_only_cells -pg -supply_statement none $RESULTS_DIR/$DESIGN_NAME.output.pg.dc.v -macro_definition

## For LVS use,the option -no_physical_only_cells is removed
write_verilog -diode_ports -pg $RESULTS_DIR/$DESIGN_NAME.output.pg.lvs.v -macro_definition

## For tools that require a non-PG netlist   
write_verilog -no_physical_only_cells $RESULTS_DIR/$DESIGN_NAME.output.v -macro_definition

} else {
write_verilog -diode_ports -no_physical_only_cells -pg -supply_statement none $RESULTS_DIR/$DESIGN_NAME.output.pg.v

## For comparison with a Design Compiler netlist,the option -diode_ports is removed
write_verilog -no_physical_only_cells -pg -supply_statement none $RESULTS_DIR/$DESIGN_NAME.output.pg.dc.v

## For tools that require a non-PG netlist   
write_verilog -no_physical_only_cells $RESULTS_DIR/$DESIGN_NAME.output.v
}

## For LVS use,the option -no_physical_only_cells is removed
write_verilog -diode_ports -pg $RESULTS_DIR/$DESIGN_NAME.output.pg.lvs.v

## Add -output_net_name_for_tie option to write_verilog command
#  if the verilog file is to be used by "eco_netlist -by_verilog_file" command in eco_icc task

## For Prime Time use,to include DCAP cells for leakage power analysis, add the option -force_output_references
#  if {$ICC_WRITE_FULL_CHIP_VERILOG} {
#  write_verilog -diode_ports -no_physical_only_cells -force_output_references [list of your DCAP cells] $RESULTS_DIR/$DESIGN_NAME.output.pt.v -macro_definition
#  } else {
#  write_verilog -diode_ports -no_physical_only_cells -force_output_references [list of your DCAP cells] $RESULTS_DIR/$DESIGN_NAME.output.pt.v
#  }

##SDC
set_app_var write_sdc_output_lumped_net_capacitance false
set_app_var write_sdc_output_net_resistance false

   set cur_scenario [current_scenario]
   foreach scenario [all_active_scenarios] {
     current_scenario $scenario
     write_sdc $RESULTS_DIR/$DESIGN_NAME.$scenario.output.sdc
   };
   current_scenario $cur_scenario
  save_upf $RESULTS_DIR/$DESIGN_NAME.output.upf 
  write_link_library -full_path_lib_names -output $RESULTS_DIR/write_link_library.tcl 

extract_rc -coupling_cap
#write_parasitics  -format SPEF -output $RESULTS_DIR/$DESIGN_NAME.output.spef
write_parasitics  -format SBPF -output $RESULTS_DIR/$DESIGN_NAME.output.sbpf

##DEF
write_def -output  $RESULTS_DIR/$DESIGN_NAME.output.def


###GDSII
##Set options - usually also include a mapping file (-map_layer)
##  set_write_stream_options \
#	-child_depth 99 \
#       -output_filling fill \
#       -output_outdated_fill \
#       -output_pin geometry \
#       -keep_data_type
#   write_stream -lib_name $MW_DESIGN_LIBRARY -format gds $RESULTS_DIR/$DESIGN_NAME.gds

if {$ICC_CREATE_MODEL } {
  save_mw_cel -as $DESIGN_NAME
  close_mw_cel
  open_mw_cel $DESIGN_NAME

  source -echo common_optimization_settings_icc.tcl
  source -echo common_placement_settings_icc.tcl
  source -echo common_post_cts_timing_settings.tcl
  source -echo common_route_si_settings_zrt_icc.tcl

  create_macro_fram 

  if {$ICC_FIX_ANTENNA} {
  ##create Antenna Info
    extract_zrt_hier_antenna_property -cell_name $DESIGN_NAME
  }

  create_block_abstraction
  save_mw_cel
  close_mw_cel 
}
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

