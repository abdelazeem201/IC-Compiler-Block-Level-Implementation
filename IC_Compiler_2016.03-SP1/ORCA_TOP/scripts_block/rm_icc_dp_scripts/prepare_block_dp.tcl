########################################################################################
# ICC Hierarchical RM
# prepare_block_dp: Prepare block and top sub directories
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
#########################################################################################

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

set SEV(src) commit_dp
set SEV(dst) prepare_block_dp

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 
set ICC_DP_COMMIT_CEL $SEV(src) 
gui_set_current_task -name {Design Planning}

open_mw_lib $MW_DESIGN_LIBRARY
open_mw_cel $ICC_DP_COMMIT_CEL -readonly


########################################################################################
## Get Block List
########################################################################################
set block_list {}
foreach softmacro ${ICC_DP_PLAN_GROUPS} {
	set block [get_attribute -class cell $softmacro ref_name]
	set block_list "$block_list $block"
	set unique_block_list [lsort -unique $block_list]
}

close_mw_cel
close_mw_lib

########################################################################################
## Check that block work areas have been installed and ready for DP data
########################################################################################
set error_count 0

foreach block [concat $unique_block_list $DESIGN_NAME] {
  if {![file exists ../../../$block/rm_icc/work]} {
     echo "RM-Error: Required block workarea ../../../$block/rm_icc/work does not exist."
     incr error_count
  }
}

if { $error_count > 0 } {
     echo "RM-Error: Exiting because of previous errors."
     sproc_script_stop -exit
}

########################################################################################
## Prepare block level run directory
########################################################################################
set current_working_dir [pwd] 
foreach block $unique_block_list {
	#file mkdir ../../../$block (considered existing)
	#file copy -force ../../scripts_block/rm_setup ../../scripts_block/rm_icc_scripts ../../scripts_block/rm_icc_zrt_scripts ../../scripts_block/rm_icc_dp_scripts ../../../$block/scripts_block/
	if {[file exists ../../../$block/rm_icc/work/lib_${block}]} {file delete -force ../../../$block/rm_icc/work/lib_${block}}
	if {![file exists ../../../$block/rm_icc/work]} {file mkdir ../../../$block/rm_icc/work}
	file rename ../work/lib_${block} ../../../$block/rm_icc/work
	file mkdir ../../../$block/rm_icc/work/DC

	if {[file exists ../../../$block/rm_icc/tmp/$BUDGETING_SDC_OUTPUT_DIR]} {file delete -force ../../../$block/rm_icc/tmp/$BUDGETING_SDC_OUTPUT_DIR} 
	file copy -force $BUDGETING_SDC_OUTPUT_DIR ../../../$block/rm_icc/tmp 

		if {[file exists fp_mcmm_scripts]} {file copy -force fp_mcmm_scripts ../../../$block/rm_icc/tmp/} 

	### Prepare Setup Files ###
	set fid_r [open ../../scripts_block/rm_setup/common_setup.tcl r] 
	set fid_w [open ../../../${block}/scripts_block/rm_setup/common_setup.tcl w] 
	while {[gets $fid_r line] >= 0} {
		if { [regexp "set DESIGN_NAME" $line]} {
			puts $fid_w "set DESIGN_NAME $block"
		} else {
			puts $fid_w $line
		}
	}
	close $fid_w
	close $fid_r
	set fid_r [open ../../scripts_block/rm_setup/icc_setup.tcl r] 
	set fid_w [open ../../../${block}/scripts_block/rm_setup/icc_setup.tcl w] 
	while {[gets $fid_r line] >= 0} {
		if { [regexp "set MW_DESIGN_LIBRARY" $line]} {
			puts $fid_w "set MW_DESIGN_LIBRARY ../work/lib_\$DESIGN_NAME" 
		} elseif { [regexp "set ICC_INIT_DESIGN_INPUT" $line]} {
			puts $fid_w "set ICC_INIT_DESIGN_INPUT MW"
		} elseif { [regexp "set ICC_INPUT_CEL" $line]} {
			puts $fid_w "set ICC_INPUT_CEL \$DESIGN_NAME"
		} elseif { [regexp "set ICC_FLOORPLAN_INPUT" $line]} {
			puts $fid_w "set ICC_FLOORPLAN_INPUT SKIP"
		} elseif { [regexp "set PNS_BLOCK_MODE" $line]} {
			puts $fid_w "set PNS_BLOCK_MODE TRUE"
		} elseif { [regexp "set ICC_IMPLEMENTATION_PHASE" $line]} {
			puts $fid_w "set ICC_IMPLEMENTATION_PHASE block"
		} elseif { [regexp "set ICC_CREATE_MODEL" $line]} {
			puts $fid_w "set ICC_CREATE_MODEL TRUE"
		} else {
			puts $fid_w $line
		}
	}
	close $fid_w
	close $fid_r

	### Open CEL ###
	cd ../../../$block/rm_icc/tmp/
	source ../../scripts_block/rm_setup/icc_setup.tcl
	open_mw_lib $MW_DESIGN_LIBRARY
	open_mw_cel $block

	## Outputs for DCT ###
	write_def -version 5.7 -rows_tracks_gcells -macro -pins -blockages -specialnets -vias -regions_groups -verbose -output ../work/DC/${block}.DCT.def
	write_floorplan -create_terminal -create_bound -row -track -preroute -placement {io terminal hard_macro soft_macro} ../work/DC/${block}.DCT.fp

	write_floorplan -no_bound -no_create_boundary -no_placement_blockage -no_plan_group -no_route_guide ../work/DC/${block}.create_voltage_area.tcl 

	### Create FRAM and block abstraction
	create_macro_fram 
	create_block_abstraction
	save_mw_cel

	close_mw_cel
	close_mw_lib
	cd $current_working_dir 
}


########################################################################################
## Prepare top level run directory
########################################################################################
	source ../../scripts_block/rm_setup/common_setup.tcl
	#file mkdir ../../../${DESIGN_NAME}
	if {![file exists ../../../top]} {
        sh ln -s ${DESIGN_NAME} top
	file rename top ../../../
	}
	#file copy -force ../../scripts_block/rm_setup ../../scripts_block/rm_icc_scripts ../../scripts_block/rm_icc_zrt_scripts ../../scripts_block/rm_icc_dp_scripts  ../../../top/scripts_block/
	if {[file exists ../../../${DESIGN_NAME}/rm_icc/work/lib_$ICC_DP_COMMIT_CEL]} {file delete -force ../../../${DESIGN_NAME}/rm_icc/work/lib_$ICC_DP_COMMIT_CEL} 
	if {![file exists ../../../${DESIGN_NAME}/rm_icc/work]} {file mkdir ../../../${DESIGN_NAME}/rm_icc/work}
	file rename ../work/lib_$ICC_DP_COMMIT_CEL ../../../${DESIGN_NAME}/rm_icc/work
	file mkdir ../../../${DESIGN_NAME}/rm_icc/work/DC

	if {[file exists ../../../${DESIGN_NAME}/rm_icc/tmp/${BUDGETING_SDC_OUTPUT_DIR}]} {file delete -force ../../../${DESIGN_NAME}/rm_icc/tmp/${BUDGETING_SDC_OUTPUT_DIR}} 
	file copy -force ${BUDGETING_SDC_OUTPUT_DIR} ../../../${DESIGN_NAME}/rm_icc/tmp 

	### Prepare Setup Files ###
	set fid_r [open ../../scripts_block/rm_setup/icc_setup.tcl r] 
	set fid_w [open ../../../${DESIGN_NAME}/scripts_block/rm_setup/icc_setup.tcl w] 
	while {[gets $fid_r line] >= 0} {
		if { [regexp "set MW_DESIGN_LIBRARY" $line]} {
			puts $fid_w "set MW_DESIGN_LIBRARY ../work/lib_$ICC_DP_COMMIT_CEL" 
		} elseif { [regexp "set ICC_INIT_DESIGN_INPUT" $line]} {
			puts $fid_w "set ICC_INIT_DESIGN_INPUT MW"
		} elseif { [regexp "set ICC_INPUT_CEL" $line]} {
			puts $fid_w "set ICC_INPUT_CEL $ICC_DP_COMMIT_CEL"
		} elseif { [regexp "set ICC_FLOORPLAN_INPUT" $line]} {
			puts $fid_w "set ICC_FLOORPLAN_INPUT SKIP"
		} elseif { [regexp "set ICC_IMPLEMENTATION_PHASE" $line]} {
			puts $fid_w "set ICC_IMPLEMENTATION_PHASE top"
		} elseif { [regexp "set ICC_CREATE_MODEL" $line]} {
			puts $fid_w "set ICC_CREATE_MODEL FALSE"
		} elseif { [regexp "set ICC_WRITE_FULL_CHIP_VERILOG" $line]} {
			puts $fid_w "set ICC_WRITE_FULL_CHIP_VERILOG TRUE"
		} elseif { [regexp "set ICC_BLOCK_ABSTRACTIONS_LIST" $line]} {
		        if {$ICC_BLOCK_ABSTRACTIONS_LIST == ""} {
			puts $fid_w "set ICC_BLOCK_ABSTRACTIONS_LIST \"$unique_block_list\""
		        } else {
			puts $fid_w $line		
			}
		} else {
			puts $fid_w $line
		}
	}
	close $fid_w
	close $fid_r
	set MW_SOFT_MACRO_LIBS {}
	foreach block $unique_block_list {
		set MW_SOFT_MACRO_LIBS "$MW_SOFT_MACRO_LIBS ../../../${block}/rm_icc/work/lib_${block}"
	}
	redirect -append ../../../${DESIGN_NAME}/scripts_block/rm_setup/icc_setup.tcl {echo set MW_SOFT_MACRO_LIBS {"} $MW_SOFT_MACRO_LIBS {"}} 
	redirect -append ../../../${DESIGN_NAME}/scripts_block/rm_setup/icc_setup.tcl {
		echo if "{" {$synopsys_program_name} == \"icc_shell\" "}" "{" set_mw_lib_reference {$MW_DESIGN_LIBRARY} -mw_reference_library {"$MW_REFERENCE_LIB_DIRS $MW_SOFT_MACRO_LIBS"} "}"
		#echo "set_mw_lib_reference" {$MW_DESIGN_LIBRARY} -mw_reference_library {"$MW_REFERENCE_LIB_DIRS $MW_SOFT_MACRO_LIBS"}
	}

	### Prepare Link, FRAM View and fix the blocks
	cd ../../../${DESIGN_NAME}/rm_icc/tmp
	source ../../scripts_block/rm_setup/icc_setup.tcl
	open_mw_lib $MW_DESIGN_LIBRARY
	open_mw_cel $ICC_DP_COMMIT_CEL

 	foreach block $unique_block_list {
 	        change_macro_view -reference $block -view FRAM
 	}
	foreach softmacro $ICC_DP_PLAN_GROUPS {
	set_attribute $softmacro is_fixed false
	}


          set_top_implementation_options -block_references "$unique_block_list" 

	save_mw_cel

	### Outputs for DCT ###
	write_def -version 5.7 -rows_tracks_gcells -macro -pins -blockages -specialnets -vias -regions_groups -verbose -output ../work/DC/top.DCT.def 
	write_floorplan -create_terminal -create_bound -row -track -preroute -placement {io terminal hard_macro soft_macro} ../work/DC/top.DCT.fp 

	write_floorplan -no_bound -no_create_boundary -no_placement_blockage -no_plan_group -no_route_guide ../work/DC/top.create_voltage_area.tcl 

	close_mw_cel
	close_mw_lib
	cd $current_working_dir 
# Lynx Compatible procedure which performs final metric processing and exits
sproc_script_stop

