###################################################################################################
# ICC Design Planning RM
# proc_explore.tcl: performs exploration run with virtual flat placement, PNS/PNA, IPO, and proto route
#                   the procedure "dp_explore" is used by rm_icc_dp_scripts/macro_placement_exploration_dp.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
###################################################################################################

# =============================================================================================
# Variables that usually may not need to be changed during exploration
# You can change the setting here and will affect all explore runs
# =============================================================================================
set vfp_num_cores $ICC_NUM_CORES
set vfp_legalize 1

# =============================================================================================
# 		Procedure
# =============================================================================================
# This procedure is to have all arguments 
# Usage is like the following:
# dp_explore run0 default off low  on  off off off 512 low off "" "" automatic 10 low 1 1 1 off on high
proc dp_explore {run_num objective vfp_macros_on_edge vfp_auto_grouping vfp_hierarchy_gravity vfp_congestion_driven vfp_timing_driven vfp_set_ideal_network vfp_max_fanout vfp_effort vfp_incremental vfp_plan_groups vfp_voltage_areas vfp_macro_orientation vfp_sliver_size vfp_congestion_effort vfp_io_net_weight vfp_plangroup_net_weight vfp_spread_spare_cells vfp_legalizer_effort ipo_ahfs ipo_ahfs_remove_effort ipo_effort ipo_fix_drc ipo_area_recovery} {

       ##Declare all global variables as "global" to the explore procedure
        set vars__proc_explore [uplevel 1 info globals]
        foreach v__proc_explore $vars__proc_explore {
           if {$v__proc_explore != "args" && ![info exists $v__proc_explore]} {
              global $v__proc_explore
              #echo "RM-debug: global $v__proc_explore"
           }
        }



##############################################################
##	Virtual Flat Placement (create_fp_placement)
##############################################################
	echo ""
	echo "================================================================="
	echo "              Now starting $run_num $objective"
	echo "================================================================="

	echo ""	
	echo "------------------- Running Virtual Flat Placement --------------------"

	redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {copy_mw_cel -from saved_cel_before_explore_mode -to ${run_num}_${objective}}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {open_mw_cel ${run_num}_${objective}}

	set_host_options -max_cores $vfp_num_cores

	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -macro_orientation		$vfp_macro_orientation}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -auto_grouping 			$vfp_auto_grouping}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -macros_on_edge 		$vfp_macros_on_edge}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -sliver_size			$vfp_sliver_size}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -congestion_effort 		$vfp_congestion_effort}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -IO_net_weight	 		$vfp_io_net_weight}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -plan_group_interface_net_weight $vfp_plangroup_net_weight}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -legalizer_effort		$vfp_legalizer_effort}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {set_fp_placement_strategy -spread_spare_cells		$vfp_spread_spare_cells}

	if { $vfp_set_ideal_network eq "on" } {
	    set hf_nets [all_high_fanout -nets -threshold $vfp_max_fanout]
	    if { $hf_nets != "" } {
		redirect /dev/null {set_load 0 -subtract_pin_load $hf_nets}
	    	redirect /dev/null {set_ideal_network -no_propagate $hf_nets}
	    }
	}

	set create_fp_placement_cmd "create_fp_placement -effort $vfp_effort"

	if { $vfp_hierarchy_gravity eq "off" } {
	    lappend create_fp_placement_cmd -no_hierarchy_gravity
	}
	if { $vfp_legalize eq "off" } {
	    lappend create_fp_placement_cmd -no_legalize
	}
	if { $vfp_congestion_driven eq "on" } {
	    lappend create_fp_placement_cmd -congestion_driven
	}
	if { $vfp_timing_driven eq "on" } {
	    lappend create_fp_placement_cmd -timing_driven
	}
	if { $vfp_incremental eq "plan_groups" } {
	    lappend create_fp_placement_cmd -incremental $vfp_incremental -plan_groups $vfp_plan_groups
	} elseif { $vfp_incremental eq "voltage_areas" } {
	    lappend create_fp_placement_cmd -incremental $vfp_incremental -voltage_areas $vfp_voltage_areas
	}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {eval $create_fp_placement_cmd}
	echo "create_fp_placement is done. Log file: ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log"
	if {$ICC_DP_EXPLORE_SAVE_CEL_EACH_STEP} {redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_place.log {save_mw_cel -as ${run_num}_${objective}_place}}

if { $ICC_DP_EXPLORE_STYLE ne "placement_only" } {

	echo ""

	if {$ICC_DP_EXPLORE_USE_GLOBAL_ROUTE} {
	    echo "------------------- Running Zroute --------------------"
	    set_host_options -max_cores $ICC_NUM_CORES
	    route_zrt_global -exploration false > ${REPORTS_DIR_DP}/${run_num}_${objective}_groute_after_place.log 
	    echo "route_zrt_global is done. Log file: ${REPORTS_DIR_DP}/${run_num}_${objective}_groute_after_place.log"
	} else {
	    echo "------------------- Running Zroute with -exploration --------------------"
	    set_host_options -max_cores $ICC_NUM_CORES
	    route_zrt_global -exploration true > ${REPORTS_DIR_DP}/${run_num}_${objective}_groute_after_place.log 
	    echo "route_zrt_global -exploration true is done. Log file: ${REPORTS_DIR_DP}/${run_num}_${objective}_groute_after_place.log"
	}

	if {$ICC_DP_EXPLORE_SAVE_CEL_AFTER_GROUTE} {save_mw_cel -as ${run_num}_${objective}_groute_after_place >> ${REPORTS_DIR_DP}/${run_num}_${objective}_groute_after_place.log}

	#if {$ICC_DP_EXPLORE_REPORTING_EACH_STEP} {
	#	    remove_route_by_type -signal_detail_route -clock_tie_off -pg_tie_off
	#	    extract_rc
	#	    create_qor_snapshot -name flat_dp_place
	#}

}

	if {[all_macro_cells] != ""} {
		set_attribute [all_macro_cells] is_fixed true 
	}

if { $ICC_DP_EXPLORE_STYLE eq "placement_only" || $ICC_DP_EXPLORE_STYLE eq "no_pns_pna" } {

        if {$ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT != ""} { 
          if {[file exists [which $ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT]]} { 
            source $ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT 
          } else { 
            echo "RM-Error: ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT specified as 
\"$ICC_DP_EXPLORE_CUSTOM_PG_SCRIPT\", cannot be found" 
          } 
        }

}

##############################################################
##	PNS/PNA (synthesize_fp_rail/analyze_fp_rail)
##############################################################
if { $ICC_DP_EXPLORE_STYLE eq "default" || $ICC_DP_EXPLORE_STYLE eq "no_ipo" } {

	echo ""	
	echo "------------------- Running Power Network Synthesis --------------------"
	set synthesize_fp_rail_cmd "synthesize_fp_rail -power_budget $PNS_POWER_BUDGET -voltage_supply $PNS_VOLTAGE_SUPPLY -output_directory $PNS_OUTPUT_DIR -nets \{$PNS_POWER_NETS\} -synthesize_power_plan"

	if { $PNS_TARGET_VOLTAGE_DROP eq "lowest" } { 
		lappend synthesize_fp_rail_cmd -lowest_voltage_drop
	} elseif { $PNS_TARGET_VOLTAGE_DROP ne "" } { 
		lappend synthesize_fp_rail_cmd -target_voltage_drop $PNS_TARGET_VOLTAGE_DROP
	}

	if { $PNS_VIRTUAL_RAIL_LAYER ne "" } { lappend synthesize_fp_rail_cmd -create_virtual_rails $PNS_VIRTUAL_RAIL_LAYER }


	if { $PNS_BLOCK_MODE } {

	    	lappend synthesize_fp_rail_cmd -use_strap_ends_as_pads 
		# can't use -use_pins_as_pads because tool can't determin if PG pins exist

	} else {

		if { $PNS_PAD_MASTERS ne "" } {
	    	lappend synthesize_fp_rail_cmd -pad_masters $PNS_PAD_MASTERS
		} elseif {[file exists [which $PNS_PAD_MASTER_FILE]]} {
		lappend synthesize_fp_rail_cmd -read_pad_master_file $PNS_PAD_MASTER_FILE
		} elseif {[file exists [which $PNS_PAD_INSTANCE_FILE]]} {
		lappend synthesize_fp_rail_cmd -read_pad_instance_file $PNS_PAD_INSTANCE_FILE
		} else {lappend synthesize_fp_rail_cmd -synthesize_power_pad}		

	}
	redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_pns.log {eval $synthesize_fp_rail_cmd}
	redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_pns.log {commit_fp_rail}
	echo "synthesize_fp_rail is done. Log file: $REPORTS_DIR_DP/${run_num}_${objective}_pns.log"
	if {$ICC_DP_EXPLORE_SAVE_CEL_EACH_STEP} {redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_pns.log {save_mw_cel -as ${run_num}_${objective}_pns}}

	
	set analyze_fp_rail_cmd "analyze_fp_rail -power_budget $PNS_POWER_BUDGET -voltage_supply $PNS_VOLTAGE_SUPPLY -output_directory $PNS_OUTPUT_DIR -nets \{$PNS_POWER_NETS\}"

	if { $PNS_VIRTUAL_RAIL_LAYER ne "" } { lappend analyze_fp_rail_cmd -create_virtual_rails $PNS_VIRTUAL_RAIL_LAYER }

	if { $PNS_BLOCK_MODE } {

		# Assuming we use -use_pins_as_pads in PNS
	    	create_fp_virtual_pad -load_file ${PNS_OUTPUT_DIR}/strap_end.${MW_POWER_NET}.vpad
	    	create_fp_virtual_pad -load_file ${PNS_OUTPUT_DIR}/strap_end.${MW_GROUND_NET}.vpad
	    	lappend analyze_fp_rail_cmd -use_pins_as_pads

	} else {

		if { $PNS_PAD_MASTERS ne "" } {
	    	lappend analyze_fp_rail_cmd -pad_masters $PNS_PAD_MASTERS
		} elseif {[file exists [which $PNS_PAD_MASTER_FILE]]} {
		lappend analyze_fp_rail_cmd -read_pad_master_file $PNS_PAD_MASTER_FILE
		} elseif {[file exists [which $PNS_PAD_INSTANCE_FILE]]} {
		lappend analyze_fp_rail_cmd -read_pad_instance_file $PNS_PAD_INSTANCE_FILE
		} else {
	    		create_fp_virtual_pad -load_file ${PNS_OUTPUT_DIR}/strap_end.${MW_POWER_NET}.vpad
	   		create_fp_virtual_pad -load_file ${PNS_OUTPUT_DIR}/strap_end.${MW_GROUND_NET}.vpad}		

	}

	redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_pna.log {eval $analyze_fp_rail_cmd}
	echo "analyze_fp_rail is done. Log file: $REPORTS_DIR_DP/${run_num}_${objective}_pna.log"

}


#############################################
##	IPO (optimize_fp_timing)
#############################################
if { $ICC_DP_EXPLORE_STYLE eq "default" || $ICC_DP_EXPLORE_STYLE eq "no_pns_pna" } {

	echo ""
	echo "------------------- Running Optimization --------------------"
        #source common_optimization_settings_icc.tcl > $REPORTS_DIR_DP/${run_num}_${objective}_ipo.log

	if {$ICC_DP_EXPLORE_REPORTING_EACH_STEP} {
		extract_rc
		redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_optimize_fp_timing_before.rpt {report_timing -nosplit -cap -tran -input -net -delay max}
	}


	set compile_instance_name_prefix dp_ipo
	if { $ipo_ahfs eq "on" } {
	    set_ahfs_options -remove_effort $ipo_ahfs_remove_effort
	    set_ahfs_options -hf_threshold $vfp_max_fanout
	}

	set optimize_fp_timing_cmd "optimize_fp_timing -effort $ipo_effort"

	if { $ipo_fix_drc eq "on" } {
	    lappend optimize_fp_timing_cmd -fix_design_rule
	}
	if { $ipo_area_recovery eq "on" } {
	    lappend optimize_fp_timing_cmd -area_recovery
	}

	redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_ipo.log {eval $optimize_fp_timing_cmd}
	echo "optimize_fp_timing is done. Log file: $REPORTS_DIR_DP/${run_num}_${objective}_ipo.log"

	if {[file exists [which $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT]]} {
	        source $CUSTOM_ICC_DP_PREROUTE_STD_CELL_SCRIPT
	}

	if {$ICC_DP_EXPLORE_SAVE_CEL_EACH_STEP} {redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_ipo.log {save_mw_cel -as ${run_num}_${objective}_optimizea}}

}


##############################################
###		Final Report
##############################################
	echo ""
	echo "------------------- Final Report --------------------"

	echo ""
	if {$ICC_DP_EXPLORE_USE_GLOBAL_ROUTE} {
	    echo "------------------- Running Zroute --------------------"
	    set_host_options -max_cores $ICC_NUM_CORES	    	            
	    redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_groute.log {route_zrt_global -exploration false} 
	    echo "route_zrt_global is done. Log file: ${REPORTS_DIR_DP}/${run_num}_${objective}_groute.log"
	} else {
	    echo "------------------- Running Zroute with -exploration --------------------"
	    set_host_options -max_cores $ICC_NUM_CORES	    	            
	    redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_groute.log {route_zrt_global -exploration true} 
	    echo "route_zrt_global -exploration true is done. Log file: ${REPORTS_DIR_DP}/${run_num}_${objective}_groute.log"
	}

	if { $ICC_DP_EXPLORE_SAVE_CEL_AFTER_GROUTE } {redirect -append ${REPORTS_DIR_DP}/${run_num}_${objective}_groute.log {save_mw_cel -as ${run_num}_${objective}_groute}}

	if {[info exists env(DISPLAY)]} {
	    source gui_save_snapshots.tcl
	} else {
		echo "RM-Info: DISPLAY is not set. GUI snapshot will be skipped."
	}

	remove_route_by_type -signal_detail_route -clock_tie_off -pg_tie_off
	extract_rc
	
	create_qor_snapshot -name ${run_num}_${objective}
	redirect -file ${REPORTS_DIR_DP}/${run_num}_${objective}_final.rpt {report_timing -nosplit -cap -tran -input -net -delay max}
	report_qor_snapshot -name ${run_num}_${objective}

        file copy -force snapshot/${run_num}_${objective}.ss.sum.full ${REPORTS_DIR_DP}/

#	if {[all_macro_cells] != ""} {
#		set_attribute [all_macro_cells] is_fixed false
#	}

	save_mw_cel -overwrite
	write_floorplan -create_terminal -create_bound -row -track -preroute -placement {io hard_macro soft_macro} ${RESULTS_DIR}/${run_num}_${objective}_dump.fp
	write_floorplan -preroute ${RESULTS_DIR}/${run_num}_${objective}_dump.route
	write_floorplan -all ${RESULTS_DIR}/${run_num}_${objective}_dump.complete_floorplan
	write_pin_pad_physical_constraints -cel [get_object_name  [current_mw_cel]] -constraint_type side_order \
	                     ${RESULTS_DIR}/${run_num}_${objective}_dump.tdf -io_only
	
	### Outputs for DCT ###
	write_def -version 5.7 -rows_tracks_gcells -macro -pins -blockages -specialnets -vias -regions_groups -verbose -output ${RESULTS_DIR}/${run_num}_${objective}_dump.DCT.def
	write_floorplan -create_terminal -create_bound -row -preroute -placement {io hard_macro soft_macro} ${RESULTS_DIR}/${run_num}_${objective}_dump.DCT.fp

	close_mw_cel ${run_num}_${objective}

}

#set enable_concise_qor_snapshot false
