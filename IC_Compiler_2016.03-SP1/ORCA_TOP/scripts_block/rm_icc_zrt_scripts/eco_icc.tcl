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
set SEV(dst) eco_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_ECO_STARTING_CEL $SEV(src) 
set ICC_ECO_CEL $SEV(dst) 

#######################################
#            ECO Script
#######################################

##Open Design
open_mw_lib $MW_DESIGN_LIBRARY

redirect /dev/null "remove_mw_cel -version_kept 0 $ICC_ECO_CEL"
copy_mw_cel -from $ICC_ECO_STARTING_CEL -to $ICC_ECO_CEL
open_mw_cel $ICC_ECO_CEL

source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl
source -echo common_post_cts_timing_settings.tcl
source -echo common_route_si_settings_zrt_icc.tcl

#######################################
# Unconstrained ECO Flow
#######################################
if {$ICC_ECO_FLOW == "UNCONSTRAINED"} {

  echo "RM-Info: starting the UNCONSTRAINED ECO flow, executing the ECO steps"
  
  if {[file exists [which $ICC_ECO_FILE]]} {

    ## Read ECO file
    if {$ICC_ECO_FLOW_TYPE == "verilog"} {
      ## For functional ECO :
      eco_netlist -compare_pg -by_verilog_file $ICC_ECO_FILE
    }

    if {$ICC_ECO_FLOW_TYPE == "pt_drc_setup_fixing_tcl" || $ICC_ECO_FLOW_TYPE == "pt_hold_fixing_tcl" || $ICC_ECO_FLOW_TYPE == "pt_minimum_physical_impact"} {
      ## For DRC/Setup fixing ECO, hold fixing ECO, or Minimum Physical Impact ECO :
      #  ECO file is typically from PT generated change file by fix_eco_drc, fix_eco_leakage, OR fix_eco_timing -setup/-hold commands
      eco_netlist -by_tcl_file $ICC_ECO_FILE
    }

    ########################################
    #           CONNECT P/G                #
    ########################################
    ## Connect Power & Ground for non-MV and MV-mode
    if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
      source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
    } else {
      if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
      redirect -file $REPORTS_DIR_ECO/eco.mv {check_mv_design -verbose}
    }
    if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

    ## Place ECO cells
    if {$ICC_ECO_FLOW_TYPE == "pt_drc_setup_fixing_tcl"} {
      ## For DRC/Setup fixing ECO :
      #  ECO file is typically from PT generated change file by fix_eco_drc OR fix_eco_timing -setup commands
      set drcbuffer [get_cells -hier -filter "eco_change_status==insert_buffer"]
      place_eco_cells -cells $drcbuffer -no_legalize
    }

    set place_eco_cells_cmd "place_eco_cells -eco_changed_cells"

    if {$ICC_ECO_FLOW_TYPE != "verilog"} {lappend place_eco_cells_cmd -legalize_only}
    if {$ADD_FILLER_CELL} {lappend place_eco_cells_cmd -remove_filler_references "$FILLER_CELL_METAL $FILLER_CELL"}
    if {$ICC_ECO_FLOW_TYPE == "pt_minimum_physical_impact"} {lappend place_eco_cells_cmd -displacement_threshold 10}

    echo $place_eco_cells_cmd
    eval $place_eco_cells_cmd

    if {$ICC_ECO_FLOW_TYPE == "pt_minimum_physical_impact"} {
      ## ICC-PT Minimum Physical Impact Flow 
      # Legalize rejected cells by moving non-ECO cells
      legalize_placement -incremental
      set_attribute $epl_legalizer_rejected_cells eco_change_status eco_legalized
    }

  ## Insert fillers
    if {[file exists [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]]} {
	echo "RM-Info: Sourcing [which $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT]"
        source -echo $ICC_CUSTOM_MV_FILLER_CELL_INSERTION_SCRIPT
    }

    ## ECO route    
    #  Please refer to SolvNet #029833 for more information
    set_route_zrt_global_options -timing_driven false -crosstalk_driven false
    set_route_zrt_track_options -timing_driven false -crosstalk_driven false
    set_route_zrt_detail_options -timing_driven false
    # set_route_zrt_common_options -reshield_modified_nets reshield
    route_zrt_eco -reroute modified_nets_first_then_others

    if {$ICC_ECO_METAL_FILL_MODE == "early_stage"} {

      ## DRC based metal fill removal
      if {$ADD_METAL_FILL == "ICV" } {
        set_extraction_options -real_metalfill_extraction FLOATING
      
        if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
        save_mw_cel -as ${ICC_ECO_CEL}_metal_fill

        if {[file exists [which $SIGNOFF_FILL_RUNSET]] } {
          set_physical_signoff_options -exec_cmd icv -fill_runset $SIGNOFF_FILL_RUNSET
        }
      
        if {$SIGNOFF_MAPFILE != ""} {set_physical_signoff_options -mapfile $SIGNOFF_MAPFILE}

        report_physical_signoff_options  

        signoff_metal_fill -remove_overlap_by_rules min_spacing
      }

    } elseif {$ICC_ECO_METAL_FILL_MODE == "signoff_stage"} {

      ## Purge metal fill
      if {$ADD_METAL_FILL == "ICV" } {
        set_extraction_options -real_metalfill_extraction FLOATING
      
        if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
        save_mw_cel -as ${ICC_ECO_CEL}_metal_fill

        if {[file exists [which $SIGNOFF_FILL_RUNSET]] } {
          set_physical_signoff_options -exec_cmd icv -fill_runset $SIGNOFF_FILL_RUNSET
        }
      
        if {$SIGNOFF_MAPFILE != ""} {set_physical_signoff_options -mapfile $SIGNOFF_MAPFILE}

        report_physical_signoff_options  

        signoff_metal_fill -purge
    }

      ## Auto DRC Repair (ADR)
      #  When routing DRC is within a reasonable range, you can perform ADR to resolve remaining DRC
      #  Please refer to SolvNet #031882 for more information and how to generate config file for signoff_autofix_drc command

      #  signoff_drc -user_defined_options {-holding_cell} -run_dir {./signoff_drc_run} -ignore_child_cell_errors -read_cel_view 
      #  signoff_autofix_drc -incremental_level high -config_file $config_file -init_drc_error_db signoff_drc_run 
      #  save_mw_cel 
      #  signoff_drc -user_defined_options {-holding_cell} -run_dir {./signoff_drc_run_after} -ignore_child_cell_errors -read_cel_view

      ## Insert metal fill
      if {$ADD_METAL_FILL == "ICV" } {
        signoff_metal_fill 
      
        set_extraction_options -real_metalfill_extraction FLOATING
      
        if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }
      }

    }

  } else {
    echo "RM-Error : ECO can't be performed as $ICC_ECO_FILE is not found ..."
  }
}

#######################################
# Freeze Silicon ECO Flow
#######################################
if {$ICC_ECO_FLOW == "FREEZE_SILICON"} {
  
  echo "RM-Info: starting the Freeze Silicon ECO flow, executing the ECO steps"
  
  if {[file exists [which $ICC_ECO_FILE]]} {

    eco_netlist -compare_pg -freeze_silicon -by_verilog_file $ICC_ECO_FILE

  ########################################
  #           CONNECT P/G                #
  ########################################
  ## Connect Power & Ground for non-MV and MV-mode
   if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
     source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
   } else {
      if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}
      redirect -file $REPORTS_DIR_ECO/route.mv {check_mv_design -verbose}
   }
  if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

    place_freeze_silicon

    set_route_zrt_global_options -timing_driven false -crosstalk_driven false
    set_route_zrt_track_options -timing_driven false -crosstalk_driven false
    set_route_zrt_detail_options -timing_driven false
    route_zrt_eco

  } else {
    echo "RM-Error : ECO can't be performed as $ICC_ECO_FILE is not found ..."
  }
}

## Automatic Incremental ECO flow
# If you set the ICC_ECO_SIGNOFF_DRC_MODE variable to AUTO_ECO it will enable the automatic incremental ECO flow for using signoff_drc. This will enable signoff_drc to look at the previous cell that had signoff_drc called on the whole design and do a comparison with the current design that has had ECO performed. Since signoff_drc will identify what areas had ECO changes the checking will only happen in those areas. This should improve runtime since checking does not need to be performed on the whole chip again.
# This feature requires that the signoff_drc -auto_eco command is run on the most recently checked design and the current design. By default it will check for another design of the same name as the current one but using -pre_mw_eco_cel you can point to another design if it was saved to a different name. For multiple iterations of ECO please point the -pre_mw_eco_cel option to the design name of the previous iteration's ECO changes. 

if {$ICC_ECO_SIGNOFF_DRC_MODE == "AUTO_ECO"} {
   if {[file exists [which $SIGNOFF_DRC_RUNSET]] } {

    set_physical_signoff_options -exec_cmd icv -drc_runset $SIGNOFF_DRC_RUNSET

    if {$SIGNOFF_MAPFILE != ""} {
      set_physical_signoff_options -mapfile [which $SIGNOFF_MAPFILE]
    }
  
    report_physical_signoff_options
    signoff_drc -auto_eco -pre_eco_mw_cel $ICC_ECO_STARTING_CEL
  }
}

save_mw_cel -as $ICC_ECO_CEL

if {$ICC_REPORTING_EFFORT != "OFF" } {
     if {[llength [get_scenarios -active true -setup true]]} {
     redirect -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.clock_timing {report_clock_timing -nosplit -type skew -scenarios [get_scenarios -active true -setup true]} ;# local skew report
     redirect -tee -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.max.clock_tree {report_clock_tree -nosplit -summary -scenarios [get_scenarios -active true -setup true]}     ;# global skew report
     }
     if {[llength [get_scenarios -active true -hold true]]} {
     redirect -tee -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.min.clock_tree {report_clock_tree -nosplit -operating_condition min -summary -scenarios [get_scenarios -active true -hold true]}     ;# min global skew report
     }
}
if {$ICC_REPORTING_EFFORT == "MED" } {
 redirect -tee -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.qor {report_qor}
 redirect -tee -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.qor -append {report_qor -summary}
 redirect -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.con {report_constraints}
}
if {$ICC_REPORTING_EFFORT != "OFF" } {
 redirect -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.max.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay max} 
 redirect -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.min.tim {report_timing -nosplit -scenario [all_active_scenarios] -capacitance -transition_time -input_pins -nets -delay min} 
}


if {$ICC_REPORTING_EFFORT != "OFF" } {
  create_qor_snapshot -clock_tree -name $ICC_ECO_CEL
  redirect -file $REPORTS_DIR_ECO/$ICC_ECO_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}




# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

