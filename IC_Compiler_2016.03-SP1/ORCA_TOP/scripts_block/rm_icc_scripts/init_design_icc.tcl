##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################
##########################################################################################
## init_design_icc.tcl : initial scripts that reads the design, applies constraints and
##                       generates a zero interconnect timing report
##########################################################################################

##################################################################################################################
#  Note for a flow with physical guidance:
#  Please do not add commands that will modify netlist or floorplan in this script.
#  You must use a floorplan from Design Compiler, for example, through a DEF file or a floorplan file. 
#  $ICC_FLOORPLAN_INPUT == "CREATE" is not supported and has been omitted. 
##################################################################################################################

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

set SEV(src) init_design_icc
set SEV(dst) init_design_icc

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_FLOORPLAN_CEL $SEV(dst) 

########################################################################################
# Design Creation 
########################################################################################

if { $ICC_INIT_DESIGN_INPUT == "MW" } {

########################################################################################
# MW CEL as the format between DCT and ICC
########################################################################################

  if {$ICC_IMPLEMENTATION_PHASE == "default"} {

    ## If $MW_DESIGN_LIBRARY already exists and $COPY_FROM_MW_DESIGN_LIBRARY is specified ...
    if {[file exists $MW_DESIGN_LIBRARY]} {
      if {[file exists $COPY_FROM_MW_DESIGN_LIBRARY]} {
        file delete -force $MW_DESIGN_LIBRARY
        file copy -force $COPY_FROM_MW_DESIGN_LIBRARY $MW_DESIGN_LIBRARY
      } elseif {$COPY_FROM_MW_DESIGN_LIBRARY != "" && ![file exists $COPY_FROM_MW_DESIGN_LIBRARY]} {
        echo "RM-Error: $COPY_FROM_MW_DESIGN_LIBRARY is specified but doesn't exist. Skip copying. Use existing $MW_DESIGN_LIBRARY"
      }

    ## If $MW_DESIGN_LIBRARY does NOT exist and $COPY_FROM_MW_DESIGN_LIBRARY is specified ...
    } else {
      if {[file exists $COPY_FROM_MW_DESIGN_LIBRARY]} {
        file copy -force $COPY_FROM_MW_DESIGN_LIBRARY $MW_DESIGN_LIBRARY
      } elseif {$COPY_FROM_MW_DESIGN_LIBRARY != "" && ![file exists $COPY_FROM_MW_DESIGN_LIBRARY]} {
        echo "RM-Error: $COPY_FROM_MW_DESIGN_LIBRARY is specified but doesn't exist. Skip copying."
	echo "RM-Error: $MW_DESIGN_LIBRARY doesn't exist. Please provide a valid $MW_DESIGN_LIBRARY. Exiting ..."
  	# Lynx Compatible procedure which performs final metric processing and exits
  	sproc_script_stop -exit
      } else {
        echo "RM-Error: $MW_DESIGN_LIBRARY doesn't exist. Please provide a valid $MW_DESIGN_LIBRARY. Exiting ..." 
  	# Lynx Compatible procedure which performs final metric processing and exits
  	sproc_script_stop -exit
      }
    }

  }

 open_mw_cel $ICC_INPUT_CEL -library $MW_DESIGN_LIBRARY 

 if {$ICC_IMPLEMENTATION_PHASE == "top" && $ICC_BLOCK_ABSTRACTIONS_LIST != ""} {
   set_top_implementation_options -block_references $ICC_BLOCK_ABSTRACTIONS_LIST
   save_mw_cel  
 }

} else {

## The Milkyway libraries by default supports user defined and routing layers on layers 1-187 in 
# the tech file. The library can support from 1-4000 in the tech file if the extended layer mode
# is activated. The extended layer mode is permanent and cannot be reverted back to the 255 
# layer mode once activated. To check if the library is in the extended layer mode query for the
# "is_extended_layer_mode" attribute on the Milkyway library.
#
# get_attribute [current_mw_lib] is_extended_layer_mode
#
# The reference libraries should also be created in the extended layer mode to be consistent with
# the design library. For more information on the extended layer mode in schema 8.1 please refer
# to the Milkyway module of Solvnet article #1823238

    if {$MW_EXTENDED_LAYER_MODE} {
      extend_mw_layers
  }

  if { ![file exists [which $MW_DESIGN_LIBRARY/lib]] } {
     if { [file exists $MW_REFERENCE_CONTROL_FILE]} {
       create_mw_lib \
            -tech $TECH_FILE \
            -bus_naming_style {[%d]} \
            -reference_control_file $MW_REFERENCE_CONTROL_FILE \
            $MW_DESIGN_LIBRARY 
     } else {
       create_mw_lib \
            -tech $TECH_FILE \
            -bus_naming_style {[%d]} \
            -mw_reference_library $MW_REFERENCE_LIB_DIRS \
            $MW_DESIGN_LIBRARY 
     }
  }

}



if {$ICC_INIT_DESIGN_INPUT == "DDC" } {

########################################################################################
# DDC as the format between DCT and ICC
########################################################################################

  open_mw_lib $MW_DESIGN_LIBRARY
  suppress_message "UID-3"      ;# avoid local link library messages
  if {$ICC_IMPLEMENTATION_PHASE == "top" && $ICC_BLOCK_ABSTRACTIONS_LIST != ""} {
    set_top_implementation_options -block_references $ICC_BLOCK_ABSTRACTIONS_LIST
  }
  import_designs $ICC_IN_DDC_FILE -format ddc -top $DESIGN_NAME -cel $DESIGN_NAME
  unsuppress_message "UID-3" 

}


if {$ICC_INIT_DESIGN_INPUT == "VERILOG" } {

########################################################################################
# Ascii as the format between DCT and ICC
########################################################################################

 open_mw_lib $MW_DESIGN_LIBRARY


 ## add -dirty_netlist in case there are mismatches between the VERILOG netlist and the FRAM view of the cells
 read_verilog -top $DESIGN_NAME $ICC_IN_VERILOG_NETLIST_FILE

 uniquify_fp_mw_cel 
 current_design $DESIGN_NAME 


}

if {$ICC_INIT_DESIGN_INPUT == "VERILOG" } {
    if {[file exists [which $ICC_IN_UPF_FILE]]} {
      load_upf $ICC_IN_UPF_FILE
    }
    if {[file exists [which $ICC_IN_RESOLVE_SUPPLY_SET_UPF_FILE]]} {
      load_upf $ICC_IN_RESOLVE_SUPPLY_SET_UPF_FILE
    }
}
if { [check_error -verbose] != 0} { echo "RM-Error, flagging ..." }

if {$DFT} {

  ## Read Scan Chain Information from DEF for hierarchical flow : DFT-aware hierarchical design planning
  if {$ICC_DP_DFT_FLOW && $ICC_IMPLEMENTATION_PHASE == "default"} {
    set DFT_SCAN_DEF_FILE $ICC_IN_FULL_CHIP_SCANDEF_FILE
    set DFT_REPORT_PREFIX full_chip

  ## Read Scan Chain Information from DEF for flat 
  } elseif {!$ICC_DP_DFT_FLOW && $ICC_IMPLEMENTATION_PHASE == "default"} {
    set DFT_SCAN_DEF_FILE $ICC_IN_SCAN_DEF_FILE
    set DFT_REPORT_PREFIX scan_chain_pre_reordering

  ## Read Scan Chain Information from DEF for hierarchical flow : block level implementation
  } elseif {$ICC_IMPLEMENTATION_PHASE != "default"} {
    set DFT_SCAN_DEF_FILE $ICC_IN_SCAN_DEF_FILE
    set DFT_REPORT_PREFIX scan_chain_pre_reordering
  }    

  if {[info exists DFT_SCAN_DEF_FILE]} {
    if {[file exists [which $DFT_SCAN_DEF_FILE]]} {
      if {[get_scan_chain] != 0} {
        remove_scan_def
      }
      read_def $DFT_SCAN_DEF_FILE
    } elseif {$DFT_SCAN_DEF_FILE != ""} {
      echo "RM-Error: SCANDEF file $DFT_SCAN_DEF_FILE is specified but not found. Please investigate it"	
    }
  unset DFT_SCAN_DEF_FILE
  }

  if {[get_scan_chain] != 0} {
    redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.$DFT_REPORT_PREFIX.check_scan_chain.rpt {check_scan_chain}
    redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.$DFT_REPORT_PREFIX.report_scan_chain.rpt {report_scan_chain}
  }

}

  echo "RM-Info : starting the MCMM flow"
  if {$ICC_IMPLEMENTATION_PHASE == "default"} {
	remove_sdc
	remove_scenario -all
        ## If there are "create_voltage_area" commands in the input SDC, pls remove them before SDC is read.
        #  Otherwise, the message "Error: Core Area not defined" will appear.
        #  The "create_voltage_area" commands are to be provided through the $CUSTOM_CREATE_VA_SCRIPT variable.    

	echo "RM-Info: Sourcing [which $ICC_MCMM_SCENARIOS_FILE]"
	source -echo $ICC_MCMM_SCENARIOS_FILE
  }

   if {$ICC_CTS_INTERCLOCK_BALANCING && [file exists [which $ICC_CTS_INTERCLOCK_BALANCING_OPTIONS_FILE]]} {
     set cur_scenario [current_scenario]
     set cur_active_scenarios [all_active_scenarios]
     #making the CTS scenario also active as it needs to become the current scenario prior to ICDB setup
     set_active_scenarios -all
     foreach scenario [get_scenarios -cts_mode true] {
     current_scenario $scenario
     echo "RM-Info: Sourcing [which $ICC_CTS_INTERCLOCK_BALANCING_OPTIONS_FILE]"
     source -echo $ICC_CTS_INTERCLOCK_BALANCING_OPTIONS_FILE
     }
     set_active_scenarios $cur_active_scenarios
     current_scenario $cur_scenario
   }

  if {$ICC_INIT_DESIGN_INPUT == "VERILOG" } {
   set cur_scenario [current_scenario]
   foreach scenario [all_active_scenarios] {
     current_scenario $scenario 
     set ports_clock_root {} 
     foreach_in_collection a_clock [get_clocks -quiet] { 
       set src_ports [filter_collection [get_attribute $a_clock sources] @object_class==port] 
       set ports_clock_root  [add_to_collection $ports_clock_root $src_ports] 
     }
  
     group_path -name REGOUT -to [all_outputs]
     group_path -name REGIN -from [remove_from_collection [all_inputs] $ports_clock_root]
     #group_path -name REG2REG -from [all_clocks] -to [all_clocks]
     group_path -name REG2REG -from [all_registers] -to [all_registers]
     group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_outputs]
   };
   current_scenario $cur_scenario
  }

   set cur_scenario [current_scenario]
   foreach scenario [all_active_scenarios] {
     current_scenario $scenario 
     remove_propagated_clock -all
   };
   current_scenario $cur_scenario

 ## For MCMM designs, timing derate values are applied in rm_icc_scripts/mcmm.scenarios.example

## The set_critical_range command sets the value of critical_range attribute.
## It specifies absolute values and uses timing units, such as ns and is used in both WNS and TNS 
## optimization.
## If user does not use the set_critical_range command to set the critical_range attribute to a specified 
## value, the default value will be 0. This is the same for place_opt, clock_opt, and route_opt.
## However, in this case, ICC will dynamically derive internal value for the critical_range attribute. 
## This automatic critical range setting starts from 50% of a path group's WNS value at different stages of 
## TNS optimization.
   if {$ICC_CRITICAL_RANGE != "" || $ICC_MAX_TRANSITION != "" || $ICC_MAX_FANOUT != ""} {
     set cur_scenario [current_scenario]
     set cur_active_scenarios [all_active_scenarios]
     foreach scenario [all_active_scenarios] { 
        current_scenario $scenario 
        if {$ICC_CRITICAL_RANGE != ""} {set_critical_range $ICC_CRITICAL_RANGE [current_design]}
        if {$ICC_MAX_TRANSITION != ""} {set_max_transition $ICC_MAX_TRANSITION [current_design]}
        if {$ICC_MAX_FANOUT     != ""} {set_max_fanout     $ICC_MAX_FANOUT     [current_design]}
     }
     current_scenario $cur_scenario
   }

   ## set_clock_gating_check
   #  Note on using set_clock_gating_check for different clock gating styles:
   #  1.If your design has discrete clock gates but does not have any clock gating checks defined on them,
   #    you should uncomment the following commands or 
   #    customize them with non-zero values and set them on either the design level or on the instances preferably.
   #  2.If your design has ICG cells only,
   #    you do not need to uncomment the following commands as the tool will honor library defined checks.
   #
   #  set cur_scenario [current_scenario]
   #  set cur_active_scenarios [all_active_scenarios]
   #  foreach scenario [all_active_scenarios] {
   #     current_scenario $scenario
   #     set_clock_gating_check -setup 0 [current_design]
   #     set_clock_gating_check -hold 0 [current_design]
   #  }
   #  current_scenario $cur_scenario

  echo "RM-Info: MCMM tlu_plus settings are set during scenario definition"

   if {$ICC_CTS_UPDATE_LATENCY} {
   set cur_scenario [current_scenario]
   set cur_active_scenarios [all_active_scenarios]
   foreach scenario [all_active_scenarios] {
     if {[file exists [which $ICC_CTS_LATENCY_OPTIONS_FILE.$scenario]]} {
       current_scenario $scenario
       echo "RM-Info: Sourcing [which ICC_CTS_LATENCY_OPTIONS_FILE.$scenario]"
       source -echo $ICC_CTS_LATENCY_OPTIONS_FILE.$scenario
     }
   };
   current_scenario $cur_scenario
   }

derive_pg_connection -create_net 

#############################################################################################################################
# Floorplan Creation: DEF OR FLOORPLAN FILE OR PIN/PAD PHYSICAL CONSTRAINT FILE + create_floorplan
#############################################################################################################################
## Below steps apply if floorplan input is not a DEF file
##Connect P/G, to create Power and Ground Ports for Non-MV designs 
##Assuming P/G Ports are included in DEF file, need PG ports created for non-DEF flows 
if {$ICC_FLOORPLAN_INPUT != "DEF" } {
      ## If you have additional scripts to create pads, for example, create_cell, load it here       
      #       source $YOUR_SCRIPT 

      ## Connect PG first before loading floorplan file or create_floorplan
        if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
        source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
        } else {
	derive_pg_connection -verbose 
        }
}

if {[file exists [which $CUSTOM_INIT_DESIGN_PRE_SCRIPT]]} {
echo "RM-Info: Sourcing [which $CUSTOM_INIT_DESIGN_PRE_SCRIPT]"
source $CUSTOM_INIT_DESIGN_PRE_SCRIPT
}

## You can have DEF, floorplan file, or pin pad physical constraint file as floorplan input
if {$ICC_FLOORPLAN_INPUT == "DEF" && [file exists [which $ICC_IN_DEF_FILE]]} {
    if {[file exists [which $ICC_IN_PHYSICAL_ONLY_CELLS_CREATION_FILE]]} {source $ICC_IN_PHYSICAL_ONLY_CELLS_CREATION_FILE}
    if {[file exists [which $ICC_IN_PHYSICAL_ONLY_CELLS_CONNECTION_FILE]]} {source $ICC_IN_PHYSICAL_ONLY_CELLS_CONNECTION_FILE}

    ## Need mapping if there are multiple sites in DEF and they do not match the MW tile names. 
    #  Examples: 
    #  	set_app_var mw_site_name_mapping {{CORE unit}} OR   
    #  	set_app_var mw_site_name_mapping {{CORE unit} {CORE012 unit012} {CORE015 unit015}}
    #  In the example, CORE is the DEF site name and unit is the MW tile name.
    #  This helps fix PSYN-267 issues: XXX has no associated site row defined in the floorplan.

    read_def -verbose -no_incremental $ICC_IN_DEF_FILE

    if {[file exists [which $ICC_IN_SPG_DEF_FILE]]} {
      set_app_var spg_enable_ascii_flow true
      read_def -verbose $ICC_IN_SPG_DEF_FILE
    } 

    if {[check_error -verbose] != 0} {echo "RM-Error, flagging ..." }
} 

if {$ICC_FLOORPLAN_INPUT == "FP_FILE" } {
  if { [file exists [which $ICC_IN_PHYSICAL_ONLY_CELLS_CREATION_FILE]]} {source $ICC_IN_PHYSICAL_ONLY_CELLS_CREATION_FILE}
  if { [file exists [which $ICC_IN_PHYSICAL_ONLY_CELLS_CONNECTION_FILE]]} {source $ICC_IN_PHYSICAL_ONLY_CELLS_CONNECTION_FILE}

  if { [file exists [which $ICC_IN_FLOORPLAN_FILE]]} {
	read_floorplan $ICC_IN_FLOORPLAN_FILE
  }
}


if {$ICC_FLOORPLAN_INPUT == "USER_FILE"} {
   if {[file exists [which $ICC_IN_FLOORPLAN_USER_FILE]]} { source $ICC_IN_FLOORPLAN_USER_FILE}
} 

if {$ICC_FLOORPLAN_INPUT == "SKIP"} {
}

## If you want to add additional floorplan details such as macro location, corner cells, io filler cells, or pad rings,
## you can add them here :
if {[file exists [which $ICC_PHYSICAL_CONSTRAINTS_FILE]] } {
  source $ICC_PHYSICAL_CONSTRAINTS_FILE
}

## Also support for Well proximity effect (WPE) end cap cells 
if {$ICC_H_CAP_CEL != "" } {
  if {$ICC_V_CAP_CEL == ""} {
    add_end_cap -respect_blockage -lib_cell $ICC_H_CAP_CEL
  } else {
    add_end_cap -respect_blockage -lib_cell $ICC_H_CAP_CEL -vertical_cells $ICC_V_CAP_CEL -fill_corner
  }
}


source -echo common_optimization_settings_icc.tcl
source -echo common_placement_settings_icc.tcl


  report_power_domain
  # report_voltage_area -all
  ########################################################################################
  # MV mode : Creating the physical MV objects
  ########################################################################################

  if {$ICC_IMPLEMENTATION_PHASE == "default"} {
    if {[file exists [which $CUSTOM_CREATE_VA_SCRIPT]]} {
    echo "RM-Info: Sourcing [which $CUSTOM_CREATE_VA_SCRIPT]"
    source -echo $CUSTOM_CREATE_VA_SCRIPT
  
    } elseif { !$ICC_DP_AUTO_CREATE_VA} {
  
    ## Create VA with user specified locations; you'll need to provide exact coordinates
    if {$PD1 != "" } {create_voltage_area  -coordinate $VA1_COORDINATES -guard_band_x 1 -guard_band_y 1 -power_domain $PD1}
    if {$PD2 != "" } {create_voltage_area  -coordinate $VA2_COORDINATES -guard_band_x 1 -guard_band_y 1 -power_domain $PD2}
    if {$PD3 != "" } {create_voltage_area  -coordinate $VA3_COORDINATES -guard_band_x 1 -guard_band_y 1 -power_domain $PD3}
    if {$PD4 != "" } {create_voltage_area  -coordinate $VA4_COORDINATES -guard_band_x 1 -guard_band_y 1 -power_domain $PD4}
  	
    } else {
  
    ## Create VA by tool automatically; you can provide desired utilization in the scripts below
    ## Location and shape of VA will be decided by the tool; you'll still need to make necessary adjustments  
    source -echo create_va_dp.tcl
   }
  }
  report_voltage_area -all

if {$ICC_UPF_PM_CELL_EXISTING} {
  associate_mv_cells

  ## Please examine the report after associate_mv_cells is done
  #  - if UPF is incomplete, you need to manually edit the UPF file,
  #    and if UPF file is not available, you need to write out UPF file first
  #  - if power management cells are missing or not yet implemented,
  #    please run the following:
  if {$ICC_UPF_PM_CELL_INSERTION} {
    insert_mv_cells
  }
} else {
  if {$ICC_UPF_PM_CELL_INSERTION} {
    insert_mv_cells
  }
}  

 if {$ICC_AO_STRATEGY_SINGLE_POWER_POWER_DOMAIN_LIST != ""} {
 	## Specify power domains for single_power always on strategy.
 	#  Default in IC Compiler is duel_power for all power domains.
	set_always_on_strategy -object_list $ICC_AO_STRATEGY_SINGLE_POWER_POWER_DOMAIN_LIST -cell_type "single_power"
 }

        ## Script to create bound for single power always on cells
        #    ex, create_bounds -name AO_WELL -coordinate {10 10 20 20} -exclusive
        #  Note that boundary of bound should be within existing voltage area
        if {[file exists [which $CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT]]} {
	       echo "RM-Info: Sourcing [which $CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT]"
               source $CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT
        }

 	## Script to associate power guide with bounds created by $CUSTOM_AO_STRATEGY_SINGLE_POWER_CREATE_BOUND_SCRIPT
 	#    ex, set_power_guide -name AO_WELL
 	if {[file exists [which $CUSTOM_AO_STRATEGY_SINGLE_POWER_SET_POWER_GUIDE_SCRIPT]]} {
	       echo "RM-Info: Sourcing [which $CUSTOM_AO_STRATEGY_SINGLE_POWER_SET_POWER_GUIDE_SCRIPT]"
 	       source $CUSTOM_AO_STRATEGY_SINGLE_POWER_SET_POWER_GUIDE_SCRIPT
 	}

#############################################
## MTCMOS CELL INSTANTIATION + CONNECTION  ##
#############################################
  if {$ICC_IMPLEMENTATION_PHASE == "default"} {
    if { [file exists [which $CUSTOM_POWER_SWITCH_SCRIPT]] } {
      echo "RM-Info: Sourcing [which $CUSTOM_POWER_SWITCH_SCRIPT]"
      source -echo $CUSTOM_POWER_SWITCH_SCRIPT
    }
  }

########################################
#           CONNECT P/G                #
########################################

## Connect Power & Ground for non-MV and MV-mode


 if {[file exists [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]]} {
   echo "RM-Info: Sourcing [which $CUSTOM_CONNECT_PG_NETS_SCRIPT]"
   source -echo $CUSTOM_CONNECT_PG_NETS_SCRIPT
 }
 derive_pg_connection -verbose
 if {!$ICC_TIE_CELL_FLOW} {derive_pg_connection -verbose -tie}

 redirect -file $REPORTS_DIR_INIT_DESIGN/init_design.mv {check_mv_design -verbose}
 redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.ao_nets.rpt {get_always_on_logic -nets}
 redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.ao_cells.rpt  {get_always_on_logic -cells}
 redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.ao_all.rpt  {get_always_on_logic}
 redirect -file $REPORTS_DIR_INIT_DESIGN/$DESIGN_NAME.ao_all_boundary.rpt  {get_always_on_logic -boundary}
 save_upf $RESULTS_DIR/$ICC_FLOORPLAN_CEL.upf



save_mw_cel -as $ICC_FLOORPLAN_CEL

########################################################################################
# Saving the cell + snapshot creation
########################################################################################
if {$ICC_REPORTING_EFFORT != "OFF" } {
 create_qor_snapshot -name $ICC_FLOORPLAN_CEL
 redirect -file $REPORTS_DIR_INIT_DESIGN/$ICC_FLOORPLAN_CEL.qor_snapshot.rpt {report_qor_snapshot -no_display}
}



# Lynx compatible procedure which produces design metrics based on reports
sproc_generate_metrics


if {$ICC_REPORTING_EFFORT != "OFF" } {
########################################################################################
# Additional reporting: zero interconnect timing report and design summaries 
########################################################################################
redirect -tee -file $REPORTS_DIR_INIT_DESIGN/$ICC_FLOORPLAN_CEL.sum {report_design_physical -all -verbose}

set_zero_interconnect_delay_mode true
redirect -tee -file $REPORTS_DIR_INIT_DESIGN/$ICC_FLOORPLAN_CEL.zic.qor {report_qor}
set_zero_interconnect_delay_mode false
if {$ICC_SANITY_CHECK} {
  check_physical_design -stage pre_place_opt -no_display -output $REPORTS_DIR_INIT_DESIGN/check_physical_design.pre_place_opt
}

########################################################################################
# Checks : Library + technology checks
########################################################################################
set_check_library_options -all
redirect -file $REPORTS_DIR_INIT_DESIGN/check_library.sum {check_library}
}

# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

