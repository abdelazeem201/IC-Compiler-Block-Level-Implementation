puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

##########################################################################################
## Place flip chip arrays
##########################################################################################
## Bump Ring1 and Ring2 
place_flip_chip_ring -physical_lib_cell $ICC_FLIP_CHIP_SIGNAL_BUMP_CELL -prefix "$ICC_FLIP_CHIP_SIGNAL_BUMP_PREFIX" -bump_spacing $ICC_FLIP_CHIP_BUMP_SPACING -ring_number $ICC_FLIP_CHIP_BUMP_RING_NUMBER  -ring_spacing $ICC_FLIP_CHIP_BUMP_RING_SPACING -number $ICC_FLIP_CHIP_SIGNAL_BUMP_NUMBER -boundary $ICC_FLIP_CHIP_BUMP_RING_BOUNDARY 

## Core VDD Array 
place_flip_chip_array -physical_lib_cell $ICC_FLIP_CHIP_VDD_BUMP_CELL -prefix "$ICC_FLIP_CHIP_VDD_BUMP_PREFIX" -start_point $ICC_FLIP_CHIP_VDD_ARRAY_START -number $ICC_FLIP_CHIP_VDD_BUMP_NUMBER -delta $ICC_FLIP_CHIP_VDD_ARRAY_DELTA -repeat $ICC_FLIP_CHIP_VDD_ARRAY_REPETITION 
change_selection [get_cells -all $ICC_FLIP_CHIP_VDD_BUMP_PREFIX*]
change_selection ""

## Core VSS Array
place_flip_chip_array -physical_lib_cell $ICC_FLIP_CHIP_VSS_BUMP_CELL -prefix "$ICC_FLIP_CHIP_VSS_BUMP_PREFIX" -start_point $ICC_FLIP_CHIP_VSS_ARRAY_START  -number $ICC_FLIP_CHIP_VSS_BUMP_NUMBER -delta $ICC_FLIP_CHIP_VSS_ARRAY_DELTA -repeat $ICC_FLIP_CHIP_VSS_ARRAY_REPETITION
change_selection [get_cells -all $ICC_FLIP_CHIP_VSS_BUMP_PREFIX*]
change_selection ""

save_mw_cel -as init_design_icc_place_flip_chip_array 

##########################################################################################
## Assign flip chip nets
##########################################################################################
set_flip_chip_grid -grid_origin $ICC_FLIP_CHIP_GRID_ORIGIN -x_step $ICC_FLIP_CHIP_GRID_X_STEP -y_step $ICC_FLIP_CHIP_GRID_Y_STEP 
create_fp_placement

## Set Fixed attribute
if {[all_macro_cells] != ""} {set_attribute [all_macro_cells] is_fixed true}

change_selection [get_cells -all $ICC_FLIP_CHIP_SIGNAL_BUMP_PREFIX*]
change_selection -add [get_cells -all $ICC_FLIP_CHIP_VDD_BUMP_PREFIX*]
change_selection -add [get_cells -all $ICC_FLIP_CHIP_VSS_BUMP_PREFIX*]
set_attribute [get_selection] is_fixed true

change_selection ""

## Automatic Net Assignment
#  Please use ICC GUI or tcl command to select a group of FC drivers and Bumps to set a personality type.
#  Below is an example by using the tcl commands.

## Select the P/G drivers based on the ref cell name
#  change_selection [get_cells -all -hierarchical -filter {ref_name=="PVSS2DGZ" || ref_name=="PVSS1DGZ" || ref_name=="PVDD2POC" || ref_name=="PVDD2DGZ" || ref_name=="PVDD1DGZ"}]

## Select a set of Bumps close to the P/G drivers ##########
#  win_select_objects -within { 137.000 1190.000 390.000 1730.000 } -slct_targets global -slct_targets_operation add 
#  win_select_objects -within { 1190.000 135.000 1740.000 390.000  } -slct_targets global -slct_targets_operation add
#  win_select_objects -within { 2830.000 880.000 3090.000 1145.000 } -slct_targets global -slct_targets_operation add

## Assign the personality type PG to the selected Drivers and Bumps
#  set_flip_chip_type -personality "PG" [get_selection]

## Select the Signal drivers based on the ref cell name 
#  change_selection [get_cells -all -hierarchical -filter {ref_name=="PDB04SDGZ"}]

## Select a set of Bumps close to the Signal drivers
#  win_select_objects -within { 137.000 430.000 390.000 1150.000 } -slct_targets global -slct_targets_operation add
#  win_select_objects -within { 440.000 135.000 1145.000 390.000 } -slct_targets global -slct_targets_operation add
#  win_select_objects -within { 1790.000 135.000 2790.000 390.000 } -slct_targets global -slct_targets_operation add
#  win_select_objects -within { 2830.000 430.000 3090.000 850.000 } -slct_targets global -slct_targets_operation add

## Assign the personality type signal to the selected Drivers and Bumps ####
#  set_flip_chip_type -personality "signal" [get_selection]

assign_flip_chip_nets
save_mw_cel -as init_design_icc_assign_flip_chip_nets

##########################################################################################
## Route flip chip
##########################################################################################
## Output all the flip chip nets to the specified file
if { $ICC_FLIP_CHIP_NET_FILE != "" } {
  write_flip_chip_nets -file_name $ICC_FLIP_CHIP_NET_FILE
}

## Route using the RDL flip chip router

## Define flip chip routing rules and options
define_routing_rule $ICC_FLIP_CHIP_RDL_ROUTING_RULE -widths $ICC_FLIP_CHIP_RDL_RULE_WIDTH -spacings $ICC_FLIP_CHIP_RDL_RULE_SPACING 

## Apply flip chip routing rule to RDL nets
set_net_routing_rule -rule $ICC_FLIP_CHIP_RDL_ROUTING_RULE $ICC_FLIP_CHIP_RDL_NETS

## Set RDL routing options
set_route_rdl_options -layer_bump_spacings $ICC_FLIP_CHIP_RDL_BUMP_SPACINGS -layer_routing_angles $ICC_FLIP_CHIP_RDL_LAYER_ROUTE_ANGLES

report_route_rdl_options

## RDL shield routing
# If shielding RDL nets apply these rules
if {$ICC_FLIP_CHIP_RDL_SHIELD_ROUTING_RULE != ""} {
  define_routing_rule $ICC_FLIP_CHIP_RDL_SHIELD_ROUTING_RULE -widths $ICC_FLIP_CHIP_SHIELD_RULE_WIDTH -spacings $ICC_FLIP_CHIP_SHIELD_RULE_SPACING -shield -shield_widths $ICC_FLIP_CHIP_SHIELD_WIDTH -shield_spacings $ICC_FLIP_CHIP_SHIELD_SPACINGS

  set_net_routing_rule -rule $ICC_FLIP_CHIP_RDL_SHIELD_ROUTING_RULE $ICC_FLIP_CHIP_SHIELD_NETS

  set_route_rdl_options -shielding_net $ICC_FLIP_CHIP_SHIELD_NETS -layer_tie_shield_widths $ICC_FLIP_CHIP_TIE_SHIELD_WIDTHS

  report_route_rdl_options
}

## RDL router
route_rdl_flip_chip -layers $ICC_FLIP_CHIP_RDL_LAYERS -nets $ICC_FLIP_CHIP_RDL_NETS

## Optimize RDL routing 
optimize_rdl_route -layer $ICC_FLIP_CHIP_RDL_LAYERS -nets $ICC_FLIP_CHIP_RDL_NETS

if {$ICC_FLIP_CHIP_RDL_SHIELD_ROUTING_RULE != ""} {
  create_rdl_shield -layers $ICC_FLIP_CHIP_SHIELD_LAYERS -shield_routing_tie true -shield_via_tie true -trim_floating false -nets $ICC_FLIP_CHIP_SHIELD_NETS
}

save_mw_cel -as init_design_icc_route_flip_chip

puts "RM-Info: Completed script [info script]\n"
