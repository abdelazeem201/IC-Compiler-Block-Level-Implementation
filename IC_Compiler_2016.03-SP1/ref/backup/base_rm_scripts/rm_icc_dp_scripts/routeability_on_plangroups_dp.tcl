##################################################################################################
# ICC Hierarchical RM								 	 	 
# routeability_on_plangroups_dp: PNS/PNA, IPO, and PGAR					 	 
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
set SEV(src) create_plangroups_dp 
set SEV(dst) routeability_on_plangroups_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_DP_CREATE_PLANGROUPS_CEL $SEV(src) 
set ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL $SEV(dst) 
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
copy_mw_cel -from $ICC_DP_CREATE_PLANGROUPS_CEL -to $ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL 
open_mw_cel $ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL
link

source common_placement_settings_icc.tcl


## You can customize power network synthesis constraints by loading a file
## Below are examples for the kind of commands to put in the file using set_fp_rail_constraints
#       set_fp_rail_constraints -set_global -keep_ring_outside_core -no_routing_over_hard_macros
if {[file exists [which $CUSTOM_ICC_DP_PNS_CONSTRAINT_SCRIPT]]} {
	source $CUSTOM_ICC_DP_PNS_CONSTRAINT_SCRIPT}

##############################################################################################################################
## Template Based Power Network Synthesis (T-PNS)
##############################################################################################################################
## For template based power network synthesis, you need to provide a customized script to include set_power_ring_strategy, 
#  set_power_plan_strategy, and compile_power_plan commands to synthesize ring and mesh.
#  Refer to SolvNet #034446 for application note with complete details

#  Please specify a customized script through $CUSTOM_ICC_DP_PNS_SCRIPT 
if {[file exists [which $CUSTOM_ICC_DP_PNS_SCRIPT]]} {
	source $CUSTOM_ICC_DP_PNS_SCRIPT
}

## Here are some examples for your reference :
#  <tpns_example.tcl> : an example of a customized script that makes use of the template examples mentioned below.
#  <ring_example.tpl> : an example of a template file for the ring strategies used by tpns_example.tcl 
#  <mesh_example.tpl> : an example of a template file for the mesh strategies used by tpns_example.tcl
#
#  Note :
#  - you can write out default templates from the tool instead of creating new ones yourself by doing the following :
#    compile_power_plan -ring -write_default_template ring_example.tpl and compile_power_plan -write_default_template mesh_example.tpl
#  - for advanced examples with parameters, refer to rm_icc_dp_scripts/tpns.example
#
#  <tpns_example.tcl> ------------------------------------------------------------------------------------------------------------------
#  	/specify strategy for rings/
#  	set_power_ring_strategy r1 -nets {VDD VSS} -core -template ring_example.tpl:non_uniform_top
#  	set_power_ring_strategy r2 -nets {VDDS VSS} -voltage_area VA0 -template ring_example.tpl:non_uniform_block
#  	compile_power_plan -ring 
#  	
#  	/specify strategy for top mesh and VA0 voltage area/
#  	set_power_plan_strategy s1 -core -nets {VDD VSS} -template mesh_example.tpl:top -extension {{stop: outermost_ring}}
#  	set_power_plan_strategy s2 -voltage_areas VA0 -nets {VDDS VDD} -template mesh_example.tpl:block -extension {{stop: innermost_ring}}
#  	compile_power_plan
#
#  <ring_example.tpl> ------------------------------------------------------------------------------------------------------------------
#  	/A side is an edge in the ring contour. A side is numbered from the lowest leftmost edge starting with "1" and 
#  	 increased in the clockwise direction.
#  	 Horizontal represents all horizontal sides and vertical represents all vertical sides/ 
#
#	template : non_uniform_top {
#	  side : horizontal {
#	        layer: M7
#	        width : 4
#	        spacing: minimum
#	        offset : 
#	  }
#	  side : vertical {
#	        layer: M6
#	        width : 4
#	        spacing: minimum
#	        offset : 
#	  }
#	  side : "1 3" {
#	        layer: M6
#	        width : 5
#	        spacing: minimum
#	        offset : 
#	  }     
#	}
#	template : non_uniform_block {
#	  side : horizontal {
#	        layer: M7
#	        width : 3
#	        spacing: minimum
#	        offset : 
#	  }
#	  side : vertical {
#	        layer: M6
#	        width : 3
#	        spacing: minimum
#	        offset : 
#	  }
#	  side : "1 3" {
#	        layer: M6
#	        width : 3
#	        spacing: minimum
#	        offset : 
#	  }     
#	}
#
#  <mesh_example.tpl> ------------------------------------------------------------------------------------------------------------------
#	template : top {
#	  layer : M7 {
#	        direction : horizontal
#	        width : 5
#	        spacing : minimum
#	        number : 
#	        pitch : 20 
#	        offset :
#	        trim_strap : true
#	  }
#	  layer : M8 {
#	        direction : vertical
#	        width : 5
#	        spacing : minimum
#	        number : 7
#	        pitch : 20
#	        offset :
#	        trim_strap : true
#	  }
#	}
#	
#	template : block {
#	  layer : M5 {
#	        direction : horizontal
#	        width : 2.5
#	        spacing : minimum
#	        number : 
#	        pitch : 15
#	        offset :
#	        trim_strap : true
#	  }
#	  layer : M6 {
#	        direction : vertical
#	        width : 2.5
#	        spacing : minimum
#	        number : 9
#	        pitch : 15
#	        offset :
#	        trim_strap : true
#	  }
#	}

## Use the following command to check the integrity of the power network
#  check_fp_rail

##############################################################################################################################
## Power Network Analysis (PNA)
##############################################################################################################################
## Optionally, use this command to set the wire extraction options for PNA. 
if {$PNA_EXTRACTION_TEMPERATURE != "" || $PNA_EXTRACTION_CORNER != ""} {
	set set_fp_rail_extraction_options_cmd "set_fp_rail_extraction_options"
	if {$PNA_EXTRACTION_TEMPERATURE != ""} {
		lappend set_fp_rail_extraction_options_cmd -operating_temperature $PNA_EXTRACTION_TEMPERATURE
	}
	if {$PNA_EXTRACTION_CORNER != ""} {
		lappend set_fp_rail_extraction_options_cmd -parasitic_corner $PNA_EXTRACTION_CORNER
	}
	eval $set_fp_rail_extraction_options_cmd
}

## To run it on block level with existing PG pins, you can use following option
#	-use_pins_as_pads
## To run it on a block without existing PG pins, you can use following commands before analyze_fp_rail
#       create_fp_virtual_pad -load_file pna_output/strap_end.VDD.vpad (VDD is your power net name)
#       create_fp_virtual_pad -load_file pna_output/strap_end.VSS.vpad (VSS is your ground net name
##   then add the following option to analyze_fp_rail
#       -use_pins_as_pads
## To run it on top level with existing power pads, you can use one of the following options
#       -pad_masters $PNS_PAD_MASTERS                   (specify pad cell masters) or
#       -read_pad_master_file $PNS_PAD_MASTER_FILE      (specify a file with pad cell masters) or
#       -read_pad_instance_file $PNS_PAD_INSTANCE_FILE  (specify a file with pad cell instances)
## To run it on top level without existing power pads, you cna use following commands before analyze_fp_rail
#       create_fp_virtual_pad -load_file pna_output/strap_end.VDD.vpad (VDD is your power net name)
#       create_fp_virtual_pad -load_file pna_output/strap_end.VSS.vpad (VSS is your ground net name
## To simulate standard cell rail during PNA, you can use the following option
#       -create_virtual_rails $PNS_VIRTUAL_RAIL_LAYER
## To use more accurate power consumption of each instance calculated in ICC, you can use the following option
#	-analyze_power
## Note: For multivoltage designs, you will have to perform analyze_fp_rail multiple times for each power/ground net set
##       Below is just an example. 
if {[file exists [which $CUSTOM_ICC_DP_PNA_SCRIPT]]} {
	source $CUSTOM_ICC_DP_PNA_SCRIPT
} else {
	analyze_fp_rail -power_budget $PNS_POWER_BUDGET -voltage_supply $PNS_VOLTAGE_SUPPLY -output_directory $PNS_OUTPUT_DIR -nets $PNS_POWER_NETS
}

#########################################################################################
## Check Placement QoR									#
#########################################################################################
mark_clock_tree -clock_net
if {$ICC_DP_ALLOW_FEEDTHROUGH} {
  set_fp_pin_constraints -allow_feedthroughs on -keep_buses_together on
} else {
  set_fp_pin_constraints -keep_buses_together on
}

set_host_options -max_cores $ICC_NUM_CORES
## For large designs, you can try top level routing only by:
#  set_route_zrt_common_options -plan_group_aware top_level_routing_only
set_route_zrt_common_options -plan_group_aware all_routing
route_zrt_global -exploration true -congestion_map_only true
save_mw_cel -as ${ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL}_groute_after_pna

extract_rc
create_qor_snapshot -name ${ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL}_groute_after_pna




#########################################################################################
## Optimization										#
#########################################################################################
source common_optimization_settings_icc.tcl
set compile_instance_name_prefix dp_ipo_hfs

if {[all_macro_cells] != "" } {
  set_attribute [all_macro_cells] is_fixed true
}

optimize_fp_timing -hfs_only 

save_mw_cel -as ${ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL}_ipo_hfs
create_qor_snapshot -name ${ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL}_ipo_hfs
redirect -file ${REPORTS_DIR_DP_ROUTEABILITY_ON_PLANGROUPS}/${ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL}_ipo_hfs.rpt {report_timing -nosplit -cap -tran -input -net -delay max -attribute -physical}

########################################
#           CONNECT P/G                #
########################################
## Connect Power & Ground for non-MV and MV-mode

 if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
   source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
 } else {
    derive_pg_connection
    if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
    redirect -file $REPORTS_DIR_DP_ROUTEABILITY_ON_PLANGROUPS/$ICC_DP_ROUTEABILITY_ON_PLANGROUPS_CEL.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {[file exists [which $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT]]} {
	source $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT
}


# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

save_mw_cel
close_mw_lib
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

