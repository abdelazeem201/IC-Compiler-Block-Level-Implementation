puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

  set_app_var tio_allow_mim_optimization $ICC_TIO_OPTIMIZE_MIM_BLOCK_INTERFACE
  set_app_var tio_write_eco_changes $ICC_TIO_WRITE_ECO_FILE
  set_app_var tio_preserve_routes_for_block true
  # set_app_var tio_eco_output_directory TIO_eco_changes

  set set_top_implementation_options_cmd " \
  set_top_implementation_options \
  -block_references [list $ICC_TIO_BLOCK_LIST] \
  -optimize_block_interface $ICC_TIO_OPTIMIZE_BLOCK_INTERFACE \
  "
  ## You can also add the -size_only_mode option to specify size_only settings

  ## Enable -optimize_shared_logic if -optimize_block_interface is also enabled
  if {$ICC_TIO_OPTIMIZE_BLOCK_INTERFACE && $ICC_TIO_OPTIMIZE_SHARED_LOGIC} {
    lappend set_top_implementation_options_cmd -optimize_shared_logic $ICC_TIO_OPTIMIZE_SHARED_LOGIC
  }

  ## If a block update setup script exists pass it to -block_update_setup_script option
  if {[file exists [which $ICC_TIO_BLOCK_UPDATE_SETUP_SCRIPT]]} {
    if {!$upf_create_implicit_supply_sets} {
	## You have explicitly set upf_create_implicit_supply_sets at the top level to false
        ## If you have not explicitly set this in your block update setup script then please add this Tcl command 
	##	set_app_var upf_create_implicit_supply_sets false     

	lappend set_top_implementation_options_cmd -block_update_setup_script [which $ICC_TIO_BLOCK_UPDATE_SETUP_SCRIPT]
    } else {
        lappend set_top_implementation_options_cmd -block_update_setup_script [which $ICC_TIO_BLOCK_UPDATE_SETUP_SCRIPT]
    }
  } else {
   if {!$upf_create_implicit_supply_sets} {
	## If you have set upf_create_implicit_supply_sets false at the top level then this will also need to be applied for the block abstractions
	## We will create a file with a single tcl command to set the variable false and pass it to the -block_update_setup_script option for set_top_implementation_options
	set fid_w [open icc_tio_block_update_setup_script.tcl w]
	puts $fid_w "set_app_var upf_create_implicit_supply_sets false"  
	close $fid_w
	lappend set_top_implementation_options_cmd -block_update_setup_script [which icc_tio_block_update_setup_script.tcl]
   }
  }

  ## Enable -host_options  
  set ICC_TIO_HOST_OPTION_NOT_SPECIFIED_PROPERLY FALSE
  if {($ICC_TIO_HOST_OPTION == "lsf" || $ICC_TIO_HOST_OPTION == "grd") && $ICC_TIO_HOST_OPTION_SUBMIT_OPTIONS != ""} {
    set_host_options -name my_tio_host_options -pool $ICC_TIO_HOST_OPTION -submit_options $ICC_TIO_HOST_OPTION_SUBMIT_OPTIONS
  } elseif {$ICC_TIO_HOST_OPTION == "samehost"} {
    set_host_options -name my_tio_host_options [sh hostname]
  } elseif {$ICC_TIO_HOST_OPTION == "list_of_hosts"} {
    set_host_options -name my_tio_host_options $ICC_TIO_HOST_OPTION_HOSTS_LIST
  } else {
    set ICC_TIO_HOST_OPTION_NOT_SPECIFIED_PROPERLY TRUE
  }

  if {!$ICC_TIO_HOST_OPTION_NOT_SPECIFIED_PROPERLY} { 
    lappend set_top_implementation_options_cmd -host_options my_tio_host_options
  }

  puts $set_top_implementation_options_cmd

  if {$ICC_TIO_OPTIMIZE_BLOCK_INTERFACE && $ICC_TIO_BLOCK_LIST != ""} {

    if {!$ICC_TIO_HOST_OPTION_NOT_SPECIFIED_PROPERLY} {
      eval $set_top_implementation_options_cmd
      report_top_implementation_options
      if {$ICC_SANITY_CHECK} {
        check_interface_optimization_setup
      }
    } else {
      echo "RM-Error : \$ICC_TIO_OPTIMIZE_BLOCK_INTERFACE is set to true and \$ICC_TIO_BLOCK_LIST is not empty but \$ICC_TIO_HOST_OPTION is not specified properly. Please specify a valid \$ICC_TIO_HOST_OPTION value (and \$ICC_TIO_HOST_OPTION_SUBMIT_OPTIONS or \$ICC_TIO_HOST_OPTION_HOSTS_LIST), otherwise route_opt will not execute. set_top_implementation_options is not executed and interface optimization is skipped."
    }          

  } else {

    eval $set_top_implementation_options_cmd
    report_top_implementation_options
    if {$ICC_SANITY_CHECK} {
      check_interface_optimization_setup
    }

  }

  unset ICC_TIO_HOST_OPTION_NOT_SPECIFIED_PROPERLY

puts "RM-Info: Completed script [info script]\n"
