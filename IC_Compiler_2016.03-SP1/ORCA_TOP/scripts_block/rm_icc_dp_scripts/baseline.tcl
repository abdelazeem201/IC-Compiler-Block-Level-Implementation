puts "RM-Info: Running script [info script]\n"

#########################################################################################
# ICC Design Planning RM
# baseline.tcl: Virtual flat placement, PNS, PNA, IPO, and Proto Route
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
#########################################################################################

##############################################################################################################################
## Set placement strategies
##############################################################################################################################

## Set placement strategies to further fine tune the placer based on your design style. 
## To find all available strategies and current values, use:
#       report_fp_placement_strategy

## To place macros on edge of chip or plan group which is default is off:
#	set_fp_placement_strategy -macros_on_edge on

## To control channels among macros which std cell can not be placed which is default 0:
set_fp_placement_strategy -sliver_size 10

## For multi-voltage designs, the following controls whether the tool uses special, high quality isolation
#  cells and performs level shifter handling. Uncomment to use it.
#       set_fp_placement_strategy -honor_mv_cells on

##############################################################################################################################
## Create virtual flat placement
##############################################################################################################################

## create_fp_placement is default with -effort low
## Alternatively, you can break the placement into 3 steps and fine tune the results gradually :
# 	create_fp_placement -effort low -no_legalize
# 	1st placement is intended to give you a fast and default macro placement result which allows you to observe design characteristics.
#   	Then please check GUI for macro locations and connectivity.
#
#	legalize_fp_placement
#
#	create_fp_placement -effort high -incremental all
# 	2nd placement is intended to let you add appropriate options to improve results
#	 for ex,
#	-timing_driven
#	-congestion_driven
create_fp_placement


##############################################################################################################################
## Check routability & timing
##############################################################################################################################
route_zrt_global -exploration true 
save_mw_cel -as flat_dp_groute_after_place
remove_route_by_type -signal_detail_route -clock_tie_off -pg_tie_off

extract_rc -estimate
create_qor_snapshot -name flat_dp_place
report_qor_snapshot -name flat_dp_place > ${REPORTS_DIR_DP}/pre.qor


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
## Power Network Synthesis (PNA)
##############################################################################################################################
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
## To run it on top level without existing power pads, you can use following commands before analyze_fp_rail
#       create_fp_virtual_pad -load_file pna_output/strap_end.VDD.vpad (VDD is your power net name)
#       create_fp_virtual_pad -load_file pna_output/strap_end.VSS.vpad (VSS is your ground net name
## To simulate standard cell rail during PNA, you can use the following option
#       -create_virtual_rails $PNS_VIRTUAL_RAIL_LAYER
## To use more accurate power consumption of each instance calculated in ICC, you can use the following option
#	-analyze_power
## Note: For multivoltage designs, you will have to perform analyze_fp_rail multiple times for each power/ground net set
##       Below is just an example. 
analyze_fp_rail -power_budget $PNS_POWER_BUDGET -voltage_supply $PNS_VOLTAGE_SUPPLY -output_directory $PNS_OUTPUT_DIR -nets $PNS_POWER_NETS

source common_optimization_settings_icc.tcl
extract_rc -estimate
report_timing -nosplit -cap -tran -input -net -delay max > $REPORTS_DIR_DP/optimize_fp_timing_before.rpt

set compile_instance_name_prefix dp_ipo
optimize_fp_timing

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
    redirect -file ${REPORTS_DIR_DP}/flat_dp.mv {check_mv_design -verbose}
   }
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {[file exists [which $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT]]} {
        source $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT
}

route_zrt_global -exploration true 
save_mw_cel -as flat_dp_groute
remove_route_by_type -signal_detail_route -clock_tie_off -pg_tie_off

extract_rc -estimate
create_qor_snapshot -name flat_dp
report_qor_snapshot -name flat_dp > ${REPORTS_DIR_DP}/final.qor
report_timing -nosplit -cap -tran -input -net -delay max > ${REPORTS_DIR_DP}/final.rpt

if {[all_macro_cells] != "" } { 
  set_attribute [all_macro_cells] is_fixed true
}
save_mw_cel
write_floorplan -placement {io hard_macro soft_macro} ${RESULTS_DIR}/dump.floorplan
write_floorplan -preroute ${RESULTS_DIR}/dump.route
write_floorplan -all ${RESULTS_DIR}/dump.complete_floorplan
write_pin_pad_physical_constraints -cel [get_object_name  [current_mw_cel]] -io_only -constraint_type side_order ${RESULTS_DIR}/dump.tdf

### Outputs for DCT ###
write_def -version 5.7 -rows_tracks_gcells -macro -pins -blockages -specialnets -vias -regions_groups -verbose -output ${RESULTS_DIR}/dump.DCT.def
write_floorplan -create_terminal -create_bound -row -track -preroute -placement {io terminal hard_macro soft_macro} ${RESULTS_DIR}/dump.DCT.fp

# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics


close_mw_cel

puts "RM-Info: Completed script [info script]\n"
