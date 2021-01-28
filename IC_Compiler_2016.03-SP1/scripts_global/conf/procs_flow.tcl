## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/procs_flow.tcl#251 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains Lynx procedure definitions.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## sproc_tool_environment_setup:
## -----------------------------------------------------------------------------

proc sproc_tool_environment_setup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV DEV
  global link_library
  global search_path
  global synopsys_program_name
  global synthetic_library
  global target_library
  global db_load_ccs_power_data
  global power_model_preference

  ## -------------------------------------
  ## Process args
  ## -------------------------------------

  set options(-debug) 0

  parse_proc_arguments -args $args options

  sproc_msg -info "synopsys_program_name = $synopsys_program_name"

  if { ( ( $synopsys_program_name == "icc2_shell" ) || ( $synopsys_program_name == "icc2_lm_shell" ) ) } {
    sproc_msg -warning "synopsys_program_name = $synopsys_program_name does not use sproc_tool_environment_setup.  Returning from the proc."
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Ensure that link_library always encompasses target_library
  ## -------------------------------------

  set SVAR(link_libs) [concat $SVAR(link_libs) $SVAR(target_libs)]
  set SVAR(link_libs) [sproc_uniquify_list -list $SVAR(link_libs)]

  ## -------------------------------------
  ## The variables SVAR(lib,$lib,db_filelist,$oc_type) are automatically derived variables.
  ## They are set to SVAR(lib,$lib,db_nldm_filelist,$oc_type) if SVAR(lib,$lib,use_ccs) is 0.
  ## They are set to SVAR(lib,$lib,db_ccs_filelist,$oc_type)  if SVAR(lib,$lib,use_ccs) is 1.
  ## -------------------------------------

  foreach lib $SVAR(setup,lib_types_list) {
    foreach oc_type $SVAR(setup,oc_types_list) {
      if { $SVAR(lib,$lib,use_ccs) } {
        set SVAR(lib,$lib,db_filelist,$oc_type) $SVAR(lib,$lib,db_ccs_filelist,$oc_type)
      } else {
        set SVAR(lib,$lib,db_filelist,$oc_type) $SVAR(lib,$lib,db_nldm_filelist,$oc_type)
      }
    }
  }

  sproc_check_library_setup -severity warning

  ## -------------------------------------
  ## MW reference list
  ## -------------------------------------

  if { (($synopsys_program_name == "dc_shell") && [shell_is_in_topographical_mode]) || \
      ($synopsys_program_name == "icc_shell") || \
      ($synopsys_program_name == "milkyway") \
    } {

    set SVAR(lib,mw_reflist) ""
    foreach lib $SVAR(link_libs) {
      foreach rlib $SVAR(lib,$lib,mw_reflist) {
        lappend SVAR(lib,mw_reflist) [file normalize $rlib]
      }
    }

  }

  if { [llength [sproc_get_macro_info -type [list hard soft logic] -info design]] > 0 } {
    set block_is_hierarchical 1
  } else {
    set block_is_hierarchical 0
  }

  if { $block_is_hierarchical } {
    switch -glob $SEV(step) {
      10_syn* {
        if { ($synopsys_program_name == "dc_shell") && [shell_is_in_topographical_mode] } {
          foreach element [sproc_get_macro_info -type [list hard] -info design_and_model -tool dc] {
            set design [lindex $element 0]
            set model  [lindex $element 1]
            if { $model == "icc_am" || $model == "etm" } {
              lappend SVAR(lib,mw_reflist) [file normalize $SEV(step_dir)/work/000_inputs/$design.mdb]
            }
          }
        }
      }
      25_dp* -
      20_dp* {
        if { ($synopsys_program_name == "dc_shell") || \
            ($synopsys_program_name == "icc_shell") || \
            ($synopsys_program_name == "milkyway") \
          } {
          set designs [sproc_get_macro_info -hier -type [list hard soft] -info design]
          foreach sm_design [sproc_get_macro_info -type [list soft] -info design] {
            set index [ lsearch $designs $sm_design ]
            set designs [lreplace $designs $index $index]
          }
          foreach design $designs {
            lappend SVAR(lib,mw_reflist) [file normalize $SEV(step_dir)/work/000_inputs/$design.mdb]
          }
        }
      }
      35_pnr* -
      30_pnr* -
      40_finish* {
        if { ($synopsys_program_name == "icc_shell") ||
          ($synopsys_program_name == "milkyway") \
          } {
          foreach design [sproc_get_macro_info -hier -type [list hard soft] -info design] {
            lappend SVAR(lib,mw_reflist) [file normalize $SEV(step_dir)/work/000_inputs/$design.mdb]
          }
        }
      }
      default {
        sproc_msg -error "Unrecognized value for SEV(step) : $SEV(step)"
      }
    }
  }

  ## -------------------------------------
  ## search path
  ## -------------------------------------

  if { ($synopsys_program_name == "dc_shell") || \
      ($synopsys_program_name == "icc_shell") || \
      ($synopsys_program_name == "pt_shell") || \
      ($synopsys_program_name == "gca_shell") || \
      ($synopsys_program_name == "fm_shell") || \
      ($synopsys_program_name == "mvrc") || \
      ($synopsys_program_name == "vcst") \
    } {

    set lynx_tmp(search_path) $search_path

    foreach lib $SVAR(link_libs) {
      foreach oc_type $SVAR(setup,oc_types_list) {
        foreach db_file $SVAR(lib,$lib,db_filelist,$oc_type) {
          lappend lynx_tmp(search_path) [file dirname [file normalize $db_file]]
        }
      }
    }

  }

  ## -------------------------------------
  ## link_library & target_library : dc_shell, icc_shell
  ## -------------------------------------

  if { ($synopsys_program_name == "dc_shell") || ($synopsys_program_name == "icc_shell") } {

    ## These variables are used to limit CCS memory usage.
    set db_load_ccs_power_data false
    set power_model_preference nlpm

    set lynx_tmp(link_library) "*"

    set oc_types [list]
    if { $synopsys_program_name == "dc_shell" } {
      foreach scenario $SVAR(mcmm,scenario_dc_all) {
        lappend oc_types [sproc_get_scenario_info -scenario $scenario -type oc_type]
      }
    } else {
      foreach scenario $SVAR(mcmm,scenario_icc_all) {
        lappend oc_types [sproc_get_scenario_info -scenario $scenario -type oc_type]
      }
    }
    set oc_types [ sproc_uniquify_list -list $oc_types ]

    foreach lib $SVAR(link_libs) {
      foreach oc_type $oc_types {
        foreach db_file $SVAR(lib,$lib,db_filelist,$oc_type) {
          lappend lynx_tmp(link_library) [ file tail $db_file ]
        }
      }
    }

    foreach lib $SVAR(target_libs) {
      foreach oc_type $oc_types {
        foreach db_file $SVAR(lib,$lib,db_filelist,$oc_type) {
          lappend lynx_tmp(target_library) [ file tail $db_file ]
        }
      }
    }

  }

  ## -------------------------------------
  ## link_library : fm_shell, mvrc
  ## -------------------------------------

  if { ($synopsys_program_name == "fm_shell") || ($synopsys_program_name == "mvrc") || ($synopsys_program_name == "vcst") } {

    set lynx_tmp(link_library) "*"

    set oc_types [list]
    set all_scenarios [concat $SVAR(mcmm,scenario_dc_all) $SVAR(mcmm,scenario_icc_all)]
    foreach scenario $all_scenarios {
      lappend oc_types [sproc_get_scenario_info -scenario $scenario -type oc_type]
    }
    set oc_type [lindex $oc_types 0]

    foreach lib $SVAR(link_libs) {
      foreach db_file $SVAR(lib,$lib,db_filelist,$oc_type) {
        lappend lynx_tmp(link_library) [ file tail $db_file ]
      }
    }

  }

  ## -------------------------------------
  ## Add DesignWare to the environment (e.g. link library, synthetic library)
  ## -------------------------------------

  if { $synopsys_program_name == "dc_shell" } {

    set sldb_files [list dw_foundation.sldb]

    foreach sldb_file $sldb_files {
      foreach path $lynx_tmp(search_path) {
        if { [file exists $path/$sldb_file] } {
          sproc_msg -info "Using DesignWare library $sldb_file"
          lappend lynx_tmp(link_library) $sldb_file
          lappend lynx_tmp(synthetic_library) $sldb_file
        }
      }
    }

  }

  ## -------------------------------------
  ## Add in QTM models for BBOX support.
  ## -------------------------------------

  if { [regexp {^20_dp} $SEV(step)] } {
    if { $synopsys_program_name == "icc_shell" } {
      set bbox_design_list [sproc_get_macro_info -type [list soft] -info bbox_design]
      foreach design $bbox_design_list {
        set qtm_models [glob $SEV(step_dir)/work/qtm_models/$design.*_lib.db]
        foreach qtm_model $qtm_models {
          lappend lynx_tmp(link_library) $qtm_model
        }
      }
    }
  }

  ## -------------------------------------
  ## Add in QTM models for generic BBOX instance support.
  ## -------------------------------------

  if { [llength $SVAR(hier,generic_bbox_designs)] > 0 } {
    if { $synopsys_program_name == "icc_shell" } {
      set bbox_design_list $SVAR(hier,generic_bbox_designs)
      foreach design $bbox_design_list {
        ## set qtm_models [glob $SEV(step_dir)/work/qtm_models/$design.*_lib.db]
        set qtm_models [glob $SEV(step_dir)/../20_dp/work/qtm_models/$design.*_lib.db]
        foreach qtm_model $qtm_models {
          lappend lynx_tmp(link_library) $qtm_model
        }
      }
    }
  }

  ## -------------------------------------
  ## Add ETM models
  ## -------------------------------------

  if { $synopsys_program_name == "dc_shell" } {
    set all_blocks_dm [sproc_get_macro_info -type [list hard soft] -info design_and_model -tool dc ]
    set etm_blocks_list [list]
    foreach dm $all_blocks_dm {
      set design [lindex $dm 0]
      set model [lindex $dm 1]
      if { $model == "etm" } {
        lappend etm_blocks_list $design
      }
    }
    foreach etm_block $etm_blocks_list {
      foreach scenario $SVAR(mcmm,scenario_dc_all) {
        set input_file $SEV(work_dir)/000_inputs/$etm_block.etm.$scenario.db
        if { [file exists $input_file] } {
          lappend lynx_tmp(link_library) [file tail $input_file]
          lappend lynx_tmp(search_path) [file dirname $input_file]
        } else {
          sproc_msg -error "$input_file does not exist"
        }
      }
    }
  } elseif { $synopsys_program_name == "icc_shell" } {
    set etm_blocks_list [list]
    if { $SEV(step) == "20_dp" && [string match {*baseline*} $SEV(task)] } {
      set all_blocks_dm [sproc_get_macro_info -type [list hard] -info design_and_model -tool icc ]
    } else {
      set all_blocks_dm [sproc_get_macro_info -type [list hard soft] -info design_and_model -tool icc ]
    }
    foreach dm $all_blocks_dm {
      set design [lindex $dm 0]
      set model [lindex $dm 1]
      if { $model == "etm" } {
        lappend etm_blocks_list $design
      }
    }
    foreach etm_block $etm_blocks_list {
      foreach scenario $SVAR(mcmm,scenario_icc_all) {
        set input_file $SEV(work_dir)/000_inputs/$etm_block.etm.$scenario.db
        if { [file exists $input_file] } {
          lappend lynx_tmp(link_library) [file tail $input_file]
          lappend lynx_tmp(search_path) [file dirname $input_file]
        } else {
          sproc_msg -error "$input_file does not exist"
        }
      }
    }
  } elseif { $synopsys_program_name == "pt_shell" } {
  }

  ## -------------------------------------
  ## Remove duplicate elements from the lists,
  ## and assign the final value.
  ## -------------------------------------

  if { [ info exists SVAR(lib,mw_reflist) ] } {
    set SVAR(lib,mw_reflist) [ sproc_uniquify_list -list $SVAR(lib,mw_reflist) ]
    sproc_msg -setup "set SVAR(lib,mw_reflist) \[list \\"
    foreach item $SVAR(lib,mw_reflist) { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }
  if { [ info exists lynx_tmp(link_library) ] } {
    set link_library [ sproc_uniquify_list -list $lynx_tmp(link_library) ]
    sproc_msg -setup "set link_library \[list \\"
    foreach item $link_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }
  if { [ info exists lynx_tmp(search_path) ] } {
    set search_path [ sproc_uniquify_list -list $lynx_tmp(search_path) ]
    sproc_msg -setup "set search_path \[list \\"
    foreach item $search_path { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }
  if { [ info exists lynx_tmp(synthetic_library) ] } {
    set synthetic_library [ sproc_uniquify_list -list $lynx_tmp(synthetic_library) ]
    sproc_msg -setup "set synthetic_library \[list \\"
    foreach item $synthetic_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }
  if { [ info exists lynx_tmp(target_library) ] } {
    set target_library [ sproc_uniquify_list -list $lynx_tmp(target_library) ]
    sproc_msg -setup "set target_library \[list \\"
    foreach item $target_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  ## -------------------------------------
  ## Look for potential DB file conflicts.
  ## -------------------------------------

  if { [ info exists search_path ] } {

    unset -nocomplain db_file_count
    foreach path $search_path {
      if { $path != "." } {
        set db_files [glob -nocomplain $path/*.db]
        foreach db_file $db_files {
          set index [file tail $db_file]
          if { ![info exists db_file_count($index)] } {
            set db_file_count($index) 1
          } else {
            incr db_file_count($index)
          }
        }
      }
    }
    foreach index [array names db_file_count] {
      set count $db_file_count($index)
      if { $count > 1 } {
        sproc_msg -error "The DB file '$index' is present $count times in the search_path."
      }
    }

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_tool_environment_setup \
  -info "Sets required library variables" \
  -define_args {
  {-debug       "Print debugging info" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_get_scenarios_for_task
## -----------------------------------------------------------------------------

proc sproc_get_scenarios_for_task { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-single) 0

  parse_proc_arguments -args $args options

  set return_value [list]

  foreach item $SVAR(mcmm,scenarios_for_analysis_task) {
    set pattern_flow   [lindex $item 0]
    set pattern_step   [lindex $item 1]
    set pattern_dst    [lindex $item 2]
    set pattern_task   [lindex $item 3]
    set scenarios      [lindex $item 4]

    if { [string match $pattern_flow   $SEV(flow_name)] && \
        [string match $pattern_step   $SEV(step)] && \
        [string match $pattern_dst    $SEV(dst)] && \
        [string match $pattern_task   $SEV(task)] \
      } {
      set return_value $scenarios
    }
  }

  if { [llength $return_value] == 0 } {
    sproc_msg -error "No matching entry found in SVAR(mcmm,scenarios_for_analysis_task)"
  } elseif { $options(-single) && ( [llength $return_value] > 1 ) } {
    sproc_msg -error "Multiple scenarios returned when only a single scenario was requested."
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_scenarios_for_task \
  -info "Returns scenarios to be used for the current task" \
  -define_args {
  {-single "Check to make sure a single scenario is returned" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_check_library_setup:
## -----------------------------------------------------------------------------

proc sproc_check_library_setup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-severity) warning

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Check for existence of DB files.
  ## -------------------------------------

  foreach lib $SVAR(setup,lib_types_list) {
    if { ![info exists SVAR(lib,$lib,use_ccs)] } {
      sproc_msg -error "The required variable SVAR(lib,$lib,use_ccs) is missing. Add for lib $lib."
      sproc_msg -error "Try using the variable checking features in the Runtime Manager."
    } else {

      foreach oc_type $SVAR(setup,oc_types_list) {
        if { $SVAR(lib,$lib,use_ccs) } {

          foreach db_file $SVAR(lib,$lib,db_ccs_filelist,$oc_type) {
            if { ![file exists $db_file] } {
              sproc_msg -warning "SVAR(lib,$lib,db_ccs_filelist,$oc_type) specifies a DB file that does not exist: $db_file"
              sproc_msg -warning "Try using the variable checking features in the Runtime Manager."
            }
          }

        } else {

          foreach db_file $SVAR(lib,$lib,db_nldm_filelist,$oc_type) {
            if { ![file exists $db_file] } {
              sproc_msg -warning "SVAR(lib,$lib,db_nldm_filelist,$oc_type) specifies a DB file that does not exist: $db_file"
              sproc_msg -warning "Try using the variable checking features in the Runtime Manager."
            }
          }

        }
      }
    }
  }

  ## -------------------------------------
  ## Check for mismatched lists of DB files.
  ## -------------------------------------

  foreach lib $SVAR(link_libs) {

    set mismatch 0

    set worst_oc [lindex $SVAR(setup,oc_types_list) 0]

    set db_file_count_for_worst_oc [llength $SVAR(lib,$lib,db_filelist,$worst_oc)]

    foreach oc_type $SVAR(setup,oc_types_list) {
      set db_file_count [llength $SVAR(lib,$lib,db_filelist,$oc_type)]
      if { $db_file_count != $db_file_count_for_worst_oc } {
        set mismatch 1
      }
    }

    if { $mismatch } {

      if { $options(-severity) == "error" } {

        sproc_msg -error "The number of DB files must be identical for all operating conditions:"
        foreach oc_type $SVAR(setup,oc_types_list) {
          set db_file_count [llength $SVAR(lib,$lib,db_filelist,$oc_type)]
          if { $SVAR(lib,$lib,use_ccs) } {
            sproc_msg -error "  SVAR(lib,$lib,db_ccs_filelist,$oc_type) has $db_file_count entries."
          } else {
            sproc_msg -error "  SVAR(lib,$lib,db_nldm_filelist,$oc_type) has $db_file_count entries."
          }
        }
        sproc_msg -error "Analysis tasks will require alignment across each operating condition."

      } else {

        sproc_msg -warning "The number of DB files must be identical for all operating conditions:"
        foreach oc_type $SVAR(setup,oc_types_list) {
          set db_file_count [llength $SVAR(lib,$lib,db_filelist,$oc_type)]
          if { $SVAR(lib,$lib,use_ccs) } {
            sproc_msg -warning "  SVAR(lib,$lib,db_ccs_filelist,$oc_type) has $db_file_count entries."
          } else {
            sproc_msg -warning "  SVAR(lib,$lib,db_nldm_filelist,$oc_type) has $db_file_count entries."
          }
        }
        sproc_msg -warning "Analysis tasks will require alignment across each operating condition."

      }

    }

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_check_library_setup \
  -info "Performs basic check on Liberty setup" \
  -define_args {
  {-severity "Severity of check" AnOos one_of_string
    {required value_help {values {warning error}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_update_target_and_link_libs:
## -----------------------------------------------------------------------------

proc sproc_update_target_and_link_libs { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name
  global SF

  if { ( ( $synopsys_program_name == "icc2_shell" ) || ( $synopsys_program_name == "icc2_lm_shell" ) ) } {
    sproc_msg -warning "synopsys_program_name = $synopsys_program_name does not use sproc_update_target_and_link_libs.  Returning from the proc."
    sproc_pinfo -mode stop
    return
  }

  set SVAR(lib,mw_reflist_update_required) 0

  ## -------------------------------------
  ## The side_file variables related to this procedure are:
  ## - SF(link_libs_adjusted), SF(target_libs_adjusted)
  ## - SF(link_libs_prev), SF(target_libs_prev)
  ##
  ## Check to see if the previous values for SVAR(link_libs)/SVAR(target_libs),
  ## which are represented by SF(link_libs_prev)/SF(target_libs_prev),
  ## match the common.tcl/block.tcl values for SVAR(link_libs)/SVAR(target_libs).
  ##
  ## If they do not match, this means the user has altered the common.tcl/block.tcl values.
  ##
  ## In this case:
  ## - Do not udpate the values for SVAR(link_libs)/SVAR(target_libs) based on the side file.
  ## - Instead, update the values for SVAR(link_libs)/SVAR(target_libs) based on:
  ##   - The normal common.tcl/block.tcl values for SVAR(link_libs)/SVAR(target_libs)
  ##   - The normal processing of SVAR(libsetup,target_and_link_lib_control)
  ## - Print a warning message indicating that the SVAR() have been altered.
  ## -------------------------------------

  set original_svar_values(link_libs)   $SVAR(link_libs)
  set original_svar_values(target_libs) $SVAR(target_libs)

  if { [info exists SF(link_libs_prev)] && [info exists SF(target_libs_prev)] &&
    [info exists SF(link_libs_adjusted)] && [info exists SF(target_libs_adjusted)] \
    } {

    set match 1

    if { [llength $SF(link_libs_prev)] != [llength $SVAR(link_libs)] } {
      set match 0
    } else {
      foreach lib $SF(link_libs_prev) {
        if { [lsearch $SVAR(link_libs) $lib] == -1 } {
          set match 0
        }
      }
    }

    if { [llength $SF(target_libs_prev)] != [llength $SVAR(target_libs)] } {
      set match 0
    } else {
      foreach lib $SF(target_libs_prev) {
        if { [lsearch $SVAR(target_libs) $lib] == -1 } {
          set match 0
        }
      }
    }

    if { $match } {
      set SVAR(link_libs)   $SF(link_libs_adjusted)
      set SVAR(target_libs) $SF(target_libs_adjusted)
    } else {
      set SVAR(lib,mw_reflist_update_required) 1
      sproc_msg -warning "It appears the values for SVAR(link_libs)/SVAR(target_libs) have been altered."
    }

  }

  ## -------------------------------------
  ## This code adds additional target and link libraries
  ## per the SVAR(libsetup,target_and_link_lib_control) variable.
  ## -------------------------------------

  foreach item $SVAR(libsetup,target_and_link_lib_control) {
    set step        [lindex $item 0]
    set task        [lindex $item 1]
    set target_libs [lindex $item 2]
    set link_libs   [lindex $item 3]

    if { [string match $step $SEV(step)] } {
      if { [string match $task $SEV(task)] } {
        set SVAR(target_libs) [concat $SVAR(target_libs) $target_libs]
        set SVAR(target_libs) [sproc_uniquify_list -list $SVAR(target_libs)]
        set SVAR(link_libs)   [concat $SVAR(link_libs) $link_libs]
        set SVAR(link_libs)   [concat $SVAR(link_libs) $SVAR(target_libs)]
        set SVAR(link_libs)   [sproc_uniquify_list -list $SVAR(link_libs)]
        set SVAR(lib,mw_reflist_update_required) 1
      }
    }
  }

  ## -------------------------------------
  ## If this is an optimization task, update the side file variables.
  ## -------------------------------------

  if { !$SEV(analysis_task) || ($SEV(analysis_task) && ($SEV(src_dir) != $SEV(dst_dir))) } {
    set SF(target_libs_adjusted)           $SVAR(target_libs)
    set SF(link_libs_adjusted)             $SVAR(link_libs)
    set SF(target_libs_prev) $original_svar_values(target_libs)
    set SF(link_libs_prev)   $original_svar_values(link_libs)
  }

  ## -------------------------------------
  ## Display the updated values.
  ## -------------------------------------

  sproc_msg -info "sproc_update_target_and_link_libs: SVAR(target_libs) : $SVAR(target_libs)"
  sproc_msg -info "sproc_update_target_and_link_libs: SVAR(link_libs) : $SVAR(link_libs)"
  sproc_msg -info "sproc_update_target_and_link_libs: SVAR(lib,mw_reflist_update_required) : $SVAR(lib,mw_reflist_update_required)"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_update_target_and_link_libs \
  -info "Updates target/link library variables by reading/writing target_and_link_libs.tcl file." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_set_operating_conditions:
## -----------------------------------------------------------------------------

proc sproc_set_operating_conditions { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global link_library
  global synopsys_program_name

  set options(-oc_mode) "ocv"
  set options(-oc_type) ""
  set options(-oc_type_min) ""
  set options(-oc_type_max) ""
  parse_proc_arguments -args $args options

  if { $options(-oc_mode) == "ocv" } {
    if { $options(-oc_type) == "" } {
      sproc_msg -error "You must specify -oc_type"
      sproc_script_stop -exit
    }
  } else {
    if { ($options(-oc_type_min) == "") || ($options(-oc_type_max) == "") } {
      sproc_msg -error "You must specify -oc_type_min and -oc_type_max"
      sproc_script_stop -exit
    }
  }

  ## -------------------------------------
  ## Reset the operating condition before it can be applied (in some tools)
  ## -------------------------------------

  set_operating_conditions
  sproc_msg -setup "set_operating_conditions"

  ## -------------------------------------
  ## Set the operating condition
  ## -------------------------------------

  switch $options(-oc_mode) {
    ocv {

      set libname [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type)) 0]
      set opcond  [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type)) 1]

      set_operating_conditions \
        -analysis_type on_chip_variation \
        -max_library $libname \
        -min_library $libname \
        -max $opcond \
        -min $opcond

      set set_operating_condition_cmd [list \
        set_operating_conditions \
        -analysis_type on_chip_variation \
        -max_library $libname \
        -min_library $libname \
        -max $opcond \
        -min $opcond \
        ]
    }

    bc_wc {

      set libname_wc [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type_max)) 0]
      set opcond_wc  [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type_max)) 1]
      set libname_bc [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type_min)) 0]
      set opcond_bc  [lindex $SVAR(libsetup,db_libname_opcond,$options(-oc_type_min)) 1]

      set_operating_conditions \
        -analysis_type bc_wc \
        -max_library $libname_wc \
        -min_library $libname_bc \
        -max $opcond_wc \
        -min $opcond_bc

      set set_operating_condition_cmd [list \
        set_operating_conditions \
        -analysis_type bc_wc \
        -max_library $libname_wc \
        -min_library $libname_bc \
        -max $opcond_wc \
        -min $opcond_bc \
        ]

      if { $synopsys_program_name == "pt_shell" } {
        sproc_msg -error "BC_WC configuration in PT is discouraged."
      }
    }
  }

  ## -------------------------------------
  ## Print some useful information
  ## -------------------------------------

  sproc_msg -setup "$set_operating_condition_cmd"

  sproc_pinfo -mode stop
  return $set_operating_condition_cmd
}

define_proc_attributes sproc_set_operating_conditions \
  -info "Pre-packaged operating conditions ." \
  -define_args {
  {-oc_mode "Operating Condition Mode" AnOos one_of_string
  {required value_help {values {ocv bc_wc}}}}
  {-oc_type "Operating Condition Type" AString string optional}
  {-oc_type_min "Min Operating Condition" AString string optional}
  {-oc_type_max "Max Operating Condition" AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_set_tlu_plus_files:
## -----------------------------------------------------------------------------

proc sproc_set_tlu_plus_files { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name

  set options(-rc_type) ""
  set options(-mf)      "emf_rmf"
  parse_proc_arguments -args $args options

  if { ($synopsys_program_name == "dc_shell") && ![shell_is_in_topographical_mode] } {
    sproc_msg -warning "Cannot execute set_tlu_plus_files in non-topo mode."
    sproc_pinfo -mode stop
    return
  }

  sproc_msg -info "Beginning sproc_set_tlu_plus_files:"
  sproc_msg -info "-rc_type = $options(-rc_type)"
  sproc_msg -info "-mf      = $options(-mf)"

  ## -------------------------------------
  ## set the TLU
  ## -------------------------------------

  set set_tlu_plus_files_cmd ""

  switch $options(-mf) {
    emf_rmf {
      set_tlu_plus_files \
        -max_emulation_tluplus  $SVAR(tech,tlup_emf_file,$options(-rc_type)) \
        -max_tluplus  $SVAR(tech,tlup_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf)

      set set_tlu_plus_files_cmd [list \
        set_tlu_plus_files \
        -max_emulation_tluplus  $SVAR(tech,tlup_emf_file,$options(-rc_type)) \
        -max_tluplus  $SVAR(tech,tlup_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf) \
        ]
    }
    emf {
      set_tlu_plus_files \
        -max_tluplus  $SVAR(tech,tlup_emf_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf)

      set set_tlu_plus_files_cmd [list \
        set_tlu_plus_files \
        -max_tluplus  $SVAR(tech,tlup_emf_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf) \
        ]
    }
    rmf {
      set_tlu_plus_files \
        -max_tluplus  $SVAR(tech,tlup_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf)

      set set_tlu_plus_files_cmd [list \
        set_tlu_plus_files \
        -max_tluplus  $SVAR(tech,tlup_file,$options(-rc_type)) \
        -tech2itf_map $SVAR(tech,map_file_mdb2itf) \
        ]
    }
  }

  ## -------------------------------------
  ## Print some useful information
  ## -------------------------------------

  sproc_msg -setup "$set_tlu_plus_files_cmd"

  sproc_pinfo -mode stop
  return $set_tlu_plus_files_cmd
}

define_proc_attributes sproc_set_tlu_plus_files \
  -info "Invoke TLU+ settings." \
  -define_args {
  {-rc_type "RC Corner" AString string optional}
  {-mf "Metal fill estimation mode" AnOos one_of_string
    {optional value_help {values {emf_rmf emf rmf}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_tool_environment_display:
## -----------------------------------------------------------------------------

proc sproc_tool_environment_display {} {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global link_library
  global link_path
  global search_path
  global synopsys_program_name
  global synthetic_library
  global target_library

  if { [info exists link_library] } {
    sproc_msg -setup "set link_library \[list \\"
    foreach item $link_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  if { [info exists link_path] } {
    sproc_msg -setup "set link_path \[list \\"
    foreach item $link_path { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  if { [info exists search_path] } {
    sproc_msg -setup "set search_path \[list \\"
    foreach item $search_path { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  if { [info exists synthetic_library] } {
    sproc_msg -setup "set synthetic_library \[list \\"
    foreach item $synthetic_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  if { [info exists target_library] } {
    sproc_msg -setup "set target_library \[list \\"
    foreach item $target_library { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  if { [info exists SVAR(lib,mw_reflist)] } {
    sproc_msg -setup "set SVAR(lib,mw_reflist) \[list \\"
    foreach item $SVAR(lib,mw_reflist) { sproc_msg -setup "  $item \\" }
    sproc_msg -setup "\]"
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_tool_environment_display \
  -info "Standard routine for displaying environmental tool startup." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_copyMDB:
## -----------------------------------------------------------------------------

proc sproc_copyMDB { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global RPT
  global synopsys_program_name
  global upf_create_implicit_supply_sets
  global link_allow_design_mismatch
  global DEV

  set options(-update_reflib) 0
  set options(-purge_unexpected_views) 1
  if { [llength $SVAR(hier,generic_bbox_designs)] > 0 } {
    set options(-purge_unexpected_views) 0
  }
  parse_proc_arguments -args $args options

  sproc_msg -info "Starting sproc_copyMDB : [date]"

  if {[info exists upf_create_implicit_supply_sets]} {
    if { $SVAR(pwr,implicit_supply_sets) } {
      if {!$upf_create_implicit_supply_sets} {
        set upf_create_implicit_supply_sets true
      }
      sproc_msg -setup "## UPF configured to use implicit supply sets"
    } else {
      if {$upf_create_implicit_supply_sets} {
        set upf_create_implicit_supply_sets false
      }
      sproc_msg -setup "## UPF configured to use explicit supply sets"
    }
  }

  if { ( $SVAR(hier,link_allow_design_mismatch_mode) == "2" ) } {
    set link_allow_design_mismatch true
    sproc_msg -info "link_allow_design_mismatch = $link_allow_design_mismatch to enable work with dirty data"
  }

  ## -------------------------------------
  ## Check for open library ..
  ## -------------------------------------

  switch $synopsys_program_name {
    "milkyway" -
    "icc_shell" {
      redirect /dev/null {catch {set tmp [current_mw_lib]}}
      if { $tmp != "" } {
        sproc_msg -warning "Milkyway library '[get_attribute [current_mw_lib] path]' is already open."
        sproc_pinfo -mode stop
        return
      }
    }
    default {
      sproc_msg -warning "Unable to verify if MW is open so assuming it is not."
    }
  }

  ## -------------------------------------
  ## Check for src library == dst library
  ## -------------------------------------

  if { $options(-src) == $options(-dst) } {
    sproc_msg -warning "Milkyway source '$options(-src)' equals destination '$options(-dst)', so not copying."
    sproc_pinfo -mode stop
    return
  }

  ## Check for existence of source library
  if { ![file exists $options(-src)] } {
    sproc_msg -error "Milkyway source library '$options(-src)' does not exist, so not copying."
    sproc_pinfo -mode stop
    return
  }

  ## Check for existence of destination library (& delete)
  if { [file exists $options(-dst)] } {
    if { $synopsys_program_name != "cdesigner" } {
      sproc_msg -warning "Milkyway '$options(-dst)' exists, so deleting prior to copy."
      file delete -force $options(-dst)
    }
  }

  ## -------------------------------------
  ## Copy the library
  ## -------------------------------------

  sproc_write_side_file

  sproc_msg -info "Copying Milkyway library '$options(-src)' to '$options(-dst)'"

  switch $synopsys_program_name {
    "milkyway" -
    "icc_shell" {

      set limit_try 3
      set count_try 0
      set try_flag 1

      while { $try_flag } {
        incr count_try

        sproc_refresh_file_system -dir $options(-src)
        file delete -force $options(-dst)
        redirect -variable foo {
          set copy_mw_lib_status [copy_mw_lib -from $options(-src) -to $options(-dst)]
        }

        if { $copy_mw_lib_status == 1 } {
          sproc_msg -info "The copy_mw_lib command was successful on attempt $count_try of $limit_try."
          set try_flag 0
        } else {
          if { $count_try < $limit_try } {
            sproc_msg -warning "FILE_SYSTEM_ISSUE: The copy_mw_lib command was not successful on attempt $count_try of $limit_try."
          } else {
            sproc_msg -error   "FILE_SYSTEM_ISSUE: The copy_mw_lib command was not successful on attempt $count_try of $limit_try."
            set try_flag 0
          }
        }

      }

      ## -------------------------------------
      ## Update reference libraries.
      ## Note: Generally we don't want to update reflibs without reason.
      ## Some possible reasons include:
      ## - New models, which Lynx updates automatically @ step boundaries.
      ## - Tool bugs.
      ## -------------------------------------

      if { [info exist SVAR(lib,mw_reflist_update_required)] == 0 } {
        set SVAR(lib,mw_reflist_update_required) 0
      }
      if { $options(-update_reflib) || $SVAR(lib,mw_reflist_update_required) } {
        sproc_msg -warning "Note with lynx/2012.06-SP2 the SVAR(lib,mw_relist) is applied to the design on an as needed basis.  This may be more frequent than in past releases."
        set_mw_lib_reference -mw_reference_library $SVAR(lib,mw_reflist) $options(-dst)
      }

      ## -------------------------------------
      ## the following is the latest approach for managing extra and unexpected views
      ## in a MW library and reflects that latest field feedback and desires.  in
      ## essence we've basically identified a list of expected or possible views,
      ## if another view exists we delete that view.  these is minimal overhead
      ## or other issues expected w/ this approach, but if they do occur please report
      ## for consideration.
      ## -------------------------------------

      if { $options(-purge_unexpected_views) } {

        sproc_msg -info "sproc_copyMDB -purge_unexpected_views = $options(-purge_unexpected_views) so attempting to manage extra MW views. Starting @ [date]"
        ## build a list of allowable views
        ##   CEL, FILL, FRAM, unitTile
        ##   some DP exceptions for SM views
        ##   some DP exceptions for ODL views
        set allowable_views ""
        lappend allowable_views "unitTile\.CEL"
        lappend allowable_views "$SVAR(design_name)\.CEL"
        ##       lappend allowable_views "$SVAR(design_name)\.FILL"
        lappend allowable_views "\.FILL"
        lappend allowable_views "$SVAR(design_name)\.FRAM"
        lappend allowable_views "$SVAR(design_name).*\.BLKG"
        lappend allowable_views "$SVAR(design_name)_sdrc\.err"
        if { [regexp {^20_dp} $SEV(step)] } {
          set soft_macro_design_list [sproc_get_macro_info -type [list soft] -info design]
          foreach design $soft_macro_design_list {
            lappend allowable_views "$design\.CEL"
            lappend allowable_views "$design\.FILL"
            lappend allowable_views "$design\.FRAM"
          }

          foreach design $soft_macro_design_list {
            lappend allowable_views "${design}\.ODL"
            lappend allowable_views "${design}_full\.ODL"
            lappend allowable_views "${design}_full_with_internal_SDC\.ODL"
          }
          lappend allowable_views "$SVAR(design_name)_odl\.CEL"
        }
        ## if { 1 } {
        ##   sproc_msg -issue "Due to ICV STAR(9000462629) related to failure to properly flatten FILL, extras views may exist in the MW database."
        ##   lappend allowable_views "\.FILL"
        ## }

        ## open the library and dump an initial report of the views
        open_mw_lib $options(-dst)
        redirect $RPT(basename).list_mw_cels.initial {
          list_mw_cels -all_views -all_versions -sort
        }

        if { 0 } {
          sproc_msg -issue "Implemented a workaround for ICC STARs (9000743151) & (9000794381)."
          set fname $RPT(basename).list_mw_cels.initial
          set view_list_minus_FILL [list ]
          set fid [open $fname "r"]
          while { [gets $fid line] >= 0 } {
            if { (![regexp {^.*\.FILL} $line]) && (![regexp {^1} $line]) && (![regexp {^.*\.BLKG} $line]) } {
              lappend view_list_minus_FILL $line
            }
          }
          close $fid
          ## remove redundant views (i.e. old versions) and dump an intermediate report of the views
          sproc_msg -warning "Redundant views being removed from the MW."
          remove_mw_cel -verbose -version_kept 1 $view_list_minus_FILL
        } else {
          ## remove redundant views (i.e. old versions) and dump an intermediate report of the views
          sproc_msg -warning "Redundant views being removed from the MW."
          remove_mw_cel -verbose -all_view -version_kept 1 $SVAR(design_name)
        }

        redirect $RPT(basename).list_mw_cels.intermediate {
          list_mw_cels -all_views -all_versions -sort
        }

        ## process the report and identify views as target deletion candidates,
        ## delete those views
        set views_to_delete ""
        set fid [open "$RPT(basename).list_mw_cels.intermediate" r]
        while { [gets $fid line] >= 0 } {

          if { ( $line == "1" ) || ( $line == "" ) } {
          } else {
            set hit 0
            foreach allowable_view $allowable_views {
              if { [regexp $allowable_view $line] } {
                set hit 1
              }
            }
            if { !$hit } {
              lappend views_to_delete "$line"
            }
          }
        }
        close $fid
        if { $views_to_delete != "" } {
          sproc_msg -warning "Views being removed from the MW = $views_to_delete"
          remove_mw_cel -verbose $views_to_delete
        }

        ## dump a final report of the views and close the MW
        redirect $RPT(basename).list_mw_cels.final {
          list_mw_cels -all_views -all_versions -sort
        }
        close_mw_lib

        ## it seems that w/ early complete feature can leave some undesireable nuggets in the MW.
        ## the following attempts to delete the left over nuggets.
        if { 1 } {
          set files [ glob -nocomplain $options(-dst)/CEL/$SVAR(design_name)*@* ]
          if { [ llength $files ] } {
            sproc_msg -info "[ llength $files ] items with \"@\" in their name identified for cleanup in sproc_copyMDB."
            foreach file $files {
              file delete -force $file
            }
          }
        }

      }

    }
    default {

      set limit_try 3
      set count_try 0
      set try_flag 1

      while { $try_flag } {
        incr count_try

        sproc_refresh_file_system -dir $options(-src)
        file delete -force $options(-dst)

        ## file copy -force $options(-src) $options(-dst)
        catch { exec cp -RL $options(-src) $options(-dst) } cp_status

        if { $cp_status == "" } {
          sproc_msg -info "The cp command was successful on attempt $count_try of $limit_try."
          set try_flag 0
        } else {
          sproc_msg -info "Development Debug >$cp_status<."
          if { $count_try < $limit_try } {
            sproc_msg -warning "FILE_SYSTEM_ISSUE: The cp command was not successful on attempt $count_try of $limit_try."
          } else {
            sproc_msg -error   "FILE_SYSTEM_ISSUE: The cp command was not successful on attempt $count_try of $limit_try."
            set try_flag 0
          }
        }

      }

    }
  }

  sproc_refresh_file_system -dir $options(-dst)

  ## -------------------------------------
  ## Check the reflibs and flag potential issues
  ## -------------------------------------

  if { ( $synopsys_program_name == "icc_shell" ) } {
    sproc_icc_check_mw_reflib \
      -src $options(-src) \
      -dst $options(-dst) \
      -fname $RPT(basename).sproc_icc_check_mw_reflib.rpt \
      -work_dir $SEV(dst_dir)/sproc_icc_check_mw_reflib
  }

  ## -------------------------------------

  sproc_msg -info "Finishing sproc_copyMDB : [date]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_copyMDB \
  -info "Milkyway library copy procedure." \
  -define_args {
  {-src "Source milkyway library"       AString string required}
  {-dst "Destination milkyway library"  AString string required}
  {-update_reflib  "Operation in continuous ref lib update mode." "" boolean optional}
  {-purge_unexpected_views  "Delete any unexpected to views to help manage disk space  (default:1)." "" int optional}
}

## -----------------------------------------------------------------------------
## sproc_icc_check_mw_reflib:
## -----------------------------------------------------------------------------

proc sproc_icc_check_mw_reflib { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-src) ""
  set options(-dst) ""
  set options(-fname) "./sproc_icc_check_mw_reflib.rpt"
  set options(-work_dir) "./sproc_icc_check_mw_reflib.work"
  parse_proc_arguments -args $args options

  ## -------------------------------------

  if { [file exists $options(-work_dir)] } {
    exec chmod -R 777 $options(-work_dir)
    file delete -force $options(-work_dir)
  }
  file mkdir $options(-work_dir)

  if { [file exists $options(-dst)] == 0 } {
    sproc_msg -error "  DST $options(-src) doesn't exist.  Terminal."
    sproc_pinfo -mode stop
    return
  }

  if { [file exists $options(-src)] == 0 } {
    set options(-src) $options(-dst)
    sproc_msg -warning "  SRC $options(-src) doesn't exist, remapping to $options(-dst)"
  }

  ## -------------------------------------

  set fname "$options(-work_dir)/write_mw_lib_files.src"
  if { [file exists  $options(-src)] } {
    write_mw_lib_files -reference_control_file -output $fname $options(-src)
  } else {
    sh touch $fname
  }
  set ds_src(num_libraries) 0
  set fid [open $fname "r"]
  while { [gets $fid line] >= 0 } {
    if { [regexp {^LIBRARY} $line] } {
      regexp {LIBRARY\s+(\S+)} $line {} library
      set ds_src($ds_src(num_libraries),library) $library
      set ds_src($ds_src(num_libraries),ref_lib) [list]
      incr ds_src(num_libraries)
    }
    if { [regexp {^\s*REFERENCE} $line] } {
      regexp {REFERENCE\s+(\S+)} $line {} reflib
      lappend ds_src([expr $ds_src(num_libraries) - 1],ref_lib) $reflib
    }
  }
  close $fid
  for {set i 0} {$i < $ds_src(num_libraries)} {incr i} {
    set ds_src($i,ref_lib) [lsort $ds_src($i,ref_lib)]
    set ds_src($i,num_ref_lib) [llength $ds_src($i,ref_lib)]
    set ds_src($i,unmatched_ref_lib) $ds_src($i,ref_lib)
    set ds_src($i,num_unmatched_ref_lib) [llength $ds_src($i,unmatched_ref_lib)]
  }

  set fname "$options(-work_dir)/write_mw_lib_files.dst"
  write_mw_lib_files -reference_control_file -output $fname $options(-dst)
  set ds_dst(num_libraries) 0
  set fid [open $fname "r"]
  while { [gets $fid line] >= 0 } {
    if { [regexp {^LIBRARY} $line] } {
      regexp {LIBRARY\s+(\S+)} $line {} library
      set ds_dst($ds_dst(num_libraries),library) $library
      set ds_dst($ds_dst(num_libraries),ref_lib) [list]
      incr ds_dst(num_libraries)
    }
    if { [regexp {^\s*REFERENCE} $line] } {
      regexp {REFERENCE\s+(\S+)} $line {} reflib
      lappend ds_dst([expr $ds_dst(num_libraries) - 1],ref_lib) $reflib
    }
  }
  close $fid
  for {set i 0} {$i < $ds_dst(num_libraries)} {incr i} {
    set ds_dst($i,ref_lib) [lsort $ds_dst($i,ref_lib)]
    set ds_dst($i,num_ref_lib) [llength $ds_dst($i,ref_lib)]
    set ds_dst($i,unmatched_ref_lib) $ds_dst($i,ref_lib)
    set ds_dst($i,num_unmatched_ref_lib) [llength $ds_dst($i,unmatched_ref_lib)]
  }

  ## -------------------------------------

  set fname $options(-fname)
  set fid [ open $fname "w" ]

  puts $fid "## "
  puts $fid "## Generated by sproc_icc_check_mw_reflib on [date]"
  puts $fid "## "
  puts $fid " "

  puts $fid "SRC : $options(-src)"
  for {set i 0} {$i < $ds_src(num_libraries)} {incr i} {
    puts $fid "  LIBRARY : $ds_src($i,library)"
    foreach ref_lib $ds_src($i,ref_lib) {
      puts $fid "    REFLIB : $ref_lib"
    }
  }
  puts $fid " "

  puts $fid "DST : $options(-dst)"
  for {set i 0} {$i < $ds_dst(num_libraries)} {incr i} {
    puts $fid "  LIBRARY : $ds_dst($i,library)"
    foreach ref_lib $ds_dst($i,ref_lib) {
      puts $fid "    REFLIB : $ref_lib"
    }
  }
  puts $fid " "

  set issues 0
  puts $fid "CHECKs for possible issues are below this point."
  puts $fid " "

  if { $ds_src(num_libraries) != $ds_dst(num_libraries) } {
    incr issues
    puts $fid "CHECK : number of libraries differ"
    puts $fid "  $ds_src(num_libraries) elements in $options(-src)"
    puts $fid "  $ds_dst(num_libraries) elements in $options(-dst)"
    puts $fid " "
  }

  for {set i 0} {$i < $ds_dst(num_libraries)} {incr i} {
    if { $i < $ds_src(num_libraries) } {
      if { $ds_src($i,num_ref_lib) != $ds_dst($i,num_ref_lib) } {
        incr issues
        puts $fid "CHECK : number of reflib elements differ"
        puts $fid "  $ds_src($i,num_ref_lib) elements in $ds_src($i,library)"
        puts $fid "  $ds_dst($i,num_ref_lib) elements in $ds_dst($i,library)"
      }
    }
  }

  ##
  ## note the number of libraries may not be equal so we need to take
  ## step to loop of the minimum of of libraries (ie.e. x1_num_libraries)
  ## and because the library indexs may not align we need to take steps
  ## to align them (i.e. x1_i)
  ##
  if { $ds_src(num_libraries) < $ds_dst(num_libraries) } {
    set x1_num_libraries $ds_src(num_libraries)
  } else {
    set x1_num_libraries $ds_dst(num_libraries)
  }
  for {set i 0} {$i < $x1_num_libraries} {incr i} {
    for {set j 0} {$j < $ds_src($i,num_ref_lib)} {incr j} {
      set x1_i -1;
      for {set k 0} {$k < $ds_dst(num_libraries)} {incr k} {
        if { [file tail $ds_src($i,library)] == [file tail $ds_dst($k,library)] } {
          set x1_i $k
          break;
        }
      }
      if { $x1_i >= 0 } {
        set k [lindex $ds_src($i,ref_lib) $j]
        set x_src [lsearch $ds_src($i,unmatched_ref_lib) $k]
        set x_dst [lsearch $ds_dst($x1_i,unmatched_ref_lib) $k]
        if { ( $x_src >= 0 ) && ( $x_dst >= 0 ) } {
          set ds_src($i,unmatched_ref_lib) [lreplace $ds_src($i,unmatched_ref_lib) $x_src $x_src]
          set ds_dst($i,unmatched_ref_lib) [lreplace $ds_dst($x1_i,unmatched_ref_lib) $x_dst $x_dst]
        }
      }
    }
    set ds_src($i,num_unmatched_ref_lib) [llength $ds_src($i,unmatched_ref_lib)]
    if { $x1_i >= 0 } {
      set ds_dst($x1_i,num_unmatched_ref_lib) [llength $ds_dst($x1_i,unmatched_ref_lib)]
    }
  }

  for {set i 0} {$i < $ds_src(num_libraries)} {incr i} {
    if { $ds_src($i,num_unmatched_ref_lib) > 0 } {
      incr issues
      puts $fid " "
      puts $fid "CHECK : unmatched content detected in $options(-src)"
      puts $fid "  $ds_src($i,num_unmatched_ref_lib) in $ds_src($i,library)"
      foreach ref_lib $ds_src($i,unmatched_ref_lib) {
        puts $fid "    $ref_lib"
      }
    }
  }

  for {set i 0} {$i < $ds_dst(num_libraries)} {incr i} {
    if { $ds_dst($i,num_unmatched_ref_lib) > 0 } {
      incr issues
      puts $fid " "
      puts $fid "CHECK : unmatched content detected in $options(-dst)"
      puts $fid "  $ds_dst($i,num_unmatched_ref_lib) element in $ds_dst($i,library)"
      foreach ref_lib $ds_dst($i,unmatched_ref_lib) {
        puts $fid "    $ref_lib"
      }
    }
  }

  puts $fid " "
  puts $fid "  $issues potential issues were detected."
  puts $fid " "
  close $fid

  if { $issues > 0 } {
    if { 1 } {
      sproc_msg -warning "$issues potential mismatches in MW relib content detected and should be reviewed and understood by the user."
      sproc_msg -warning "  See \"$fname\""
    } else {
      sproc_msg -error "$issues potential mismatches in MW relib content detected and should be reviewed and understood by the user."
      sproc_msg -error "  See \"$fname\""
    }
  } else {
    sproc_msg -info "  No potential mismatches in MW relib content detected."
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_icc_check_mw_reflib \
  -info "ICC procedure to analyze changes to the MW reflib." \
  -define_args {
  {-src "Source milkyway library"       AString string required}
  {-dst "Destination milkyway library"  AString string required}
  {-fname "Name of the output report"   AString string optional}
  {-work_dir "Name of the work directory for intermediate results"   AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_pt_sdc:
## -----------------------------------------------------------------------------

proc sproc_pt_sdc { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV SF

  ## -------------------------------------
  ## Get arguments
  ## -------------------------------------

  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Get individual components of requested scenario.
  ## -------------------------------------

  set MM_TYPE [sproc_get_scenario_info -scenario $options(-scenario) -type mm_type]
  set OC_TYPE [sproc_get_scenario_info -scenario $options(-scenario) -type oc_type]
  set RC_TYPE [sproc_get_scenario_info -scenario $options(-scenario) -type rc_type]

  ## -------------------------------------
  ## Find best-suited SDC file.
  ## -------------------------------------

  set use_mcmm_sdc 0

  if { [regexp {^10_syn} $SEV(step)] } {
    if { $SF(dc_use_mcmm) } {
      set use_mcmm_sdc 1
    }
  } else {
    set use_mcmm_sdc 1
  }

  if { $use_mcmm_sdc == 0 } {

    set scenario [lindex $SVAR(mcmm,scenario_dc_all) 0]
    set fname_src_sdc $SEV(src_dir)/$SVAR(design_name).$scenario.sdc

    sproc_msg -info "sproc_pt_sdc: Looking for non-MCMM SDC file."
    sproc_msg -info "sproc_pt_sdc:   $fname_src_sdc"

    if { [file exists $fname_src_sdc] } {
      sproc_msg -info  "sproc_pt_sdc: Non-MCMM SDC file was found."
    } else {
      sproc_msg -error "sproc_pt_sdc: Non-MCMM SDC file was not found."
      sproc_script_stop -exit
    }

  } else {

    set fname_src_sdc $SEV(src_dir)/$SVAR(design_name).$options(-scenario).sdc
    puts "DEBUG: - about to look for flawed file $fname_src_sdc"
    sproc_msg -info "sproc_pt_sdc: Looking for Exact MCMM SDC file for $options(-scenario)."
    sproc_msg -info "sproc_pt_sdc: check for $fname_src_sdc"

    if { [file exists $fname_src_sdc] } {

      sproc_msg -info  "sproc_pt_sdc: Exact MCMM SDC file was found."

    } else {

      sproc_msg -info  "sproc_pt_sdc: Exact MCMM SDC file was not found."

      set alt_sdc_files [list]
      sproc_msg -info  "sproc_pt_sdc: Globbing for $SEV(src_dir)/$SVAR(design_name).$MM_TYPE.$OC_TYPE.*.sdc"
      set alt_sdc_files [concat $alt_sdc_files [glob -nocomplain $SEV(src_dir)/$SVAR(design_name).$MM_TYPE.$OC_TYPE.*.sdc]]
      sproc_msg -info  "sproc_pt_sdc: Globbing for $SEV(src_dir)/$SVAR(design_name).$MM_TYPE.*.*.sdc"
      set alt_sdc_files [concat $alt_sdc_files [glob -nocomplain $SEV(src_dir)/$SVAR(design_name).$MM_TYPE.*.*.sdc]]

      if { [llength $alt_sdc_files] > 0 } {
        set fname_src_sdc [lindex $alt_sdc_files 0]
        sproc_msg -info  "sproc_pt_sdc: Non-exact MCMM SDC file was found."
        sproc_msg -info  "sproc_pt_sdc:   $fname_src_sdc"
      } else {
        sproc_msg -error "sproc_pt_sdc: Non-exact MCMM SDC file was not found."
        sproc_script_stop -exit
      }

    }

  }

  ## -------------------------------------
  ## Define file naming conventions
  ## -------------------------------------

  set fname_filtered_sdc "$SEV(dst_dir)/[file tail $fname_src_sdc].$options(-scenario)"
  set fname_bad_sdc      "$SEV(dst_dir)/[file tail $fname_src_sdc].$options(-scenario).bad"

  sproc_msg -info "sproc_pt_sdc: Using $fname_src_sdc as source SDC."
  sproc_msg -info "sproc_pt_sdc: Using $fname_filtered_sdc as filtered SDC."
  sproc_msg -info "sproc_pt_sdc: Using $fname_bad_sdc as bad SDC."

  ## Open files

  set fid_src_sdc      [open "$fname_src_sdc"  r]
  set fid_filtered_sdc [open "$fname_filtered_sdc" w]
  set fid_bad_sdc      [open "$fname_bad_sdc"      w]

  ## Keep track of generated clocks
  set gclk_list [list]

  set partial_line ""
  while { [gets $fid_src_sdc tmp_line] >= 0 } {

    ## -------------------------------------
    ## Handle lines ending with "\"
    ## -------------------------------------

    if { [regexp {\\$} $tmp_line] } {
      regsub {\\$} $tmp_line {} tmp_line
      append partial_line $tmp_line
      continue
    } else {
      append partial_line $tmp_line
      set line $partial_line
      set partial_line ""
    }

    ## -------------------------------------
    ## Perform filtering
    ## -------------------------------------

    switch -regexp $line {

      {set_ideal_network .*logic_[0-1]*} - 
      {group_path .*-name \*\*clock_gating_default\*\*} -
      {create_voltage_area} -
      {set_wire_load_mode} -
      {set_wire_load_model} -
      {set_operating_conditions} {
        ## create_voltage_area being removed per BSTAR 9000693379
        puts $fid_bad_sdc $line
      }

      {set_driving_cell} {
        puts $fid_bad_sdc $line
        regsub {\-library\s+\S+} $line {} line
        puts $fid_filtered_sdc $line
      }

      {create_generated_clock} {
        if { [regexp {create_generated_clock\s+\[get_pins\s+.*\-name\s+(\S+)\s} $line match_line match_field] } {
          set gclk $match_field
          lappend gclk_list $gclk
        }
        puts $fid_filtered_sdc $line
      }

      {set_clock_latency} {
        if { [regexp {\[get_clocks\s+(\S+)\]} $line match_line match_field] } {
          set gclk $match_field
          if { [lsearch $gclk_list $gclk] >= 0 } {
            ## Remove these constraints for generated clocks.
            puts $fid_bad_sdc $line
          } else {
            ## Allow these constraints for non-generated clocks.
            puts $fid_filtered_sdc $line
          }
        }
      }

      {set_voltage} {
        if { [regexp {sta_pnr_dmsa_lefdef} $SEV(task)] } {
          puts $fid_bad_sdc $line
        } else {
          puts $fid_filtered_sdc $line
        }
      }

      default {
        puts $fid_filtered_sdc $line
      }

    }
  }

  ## Close files
  close $fid_src_sdc
  close $fid_filtered_sdc
  close $fid_bad_sdc

  ## read the SDC
  read_sdc $fname_filtered_sdc
  sproc_msg -setup "read_sdc $fname_filtered_sdc"
  sproc_pinfo -mode stop
}

define_proc_attributes sproc_pt_sdc \
  -info "Procedure to filter SDC files for PT and then read them." \
  -define_args {
    {-scenario "The scenario to make sure all PT runs generate unique files " AString string required}
  }

## -----------------------------------------------------------------------------
## sproc_pt_adjust_virtual_clock_latency:
## -----------------------------------------------------------------------------

proc sproc_pt_adjust_virtual_clock_latency { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-max) 0
  set options(-min) 0
  parse_proc_arguments -args $args options

  if { $options(-max) & $options(-min) } {
    sproc_msg -error "sproc_pt_adjust_virtual_clock_latency: Cannot select both -max and -min"
    sproc_pinfo -mode stop
    return
  }

  foreach_in_collection clock [get_clocks -quiet] {
    set clock_name [get_object_name $clock]
    set clock_sources [get_attribute $clock sources]
    if { [sizeof_collection $clock_sources] == 0 } {

      set org_clock_latency_rise_max [get_attribute -quiet $clock clock_latency_rise_max]
      set org_clock_latency_fall_max [get_attribute -quiet $clock clock_latency_fall_max]
      set org_clock_latency_rise_min [get_attribute -quiet $clock clock_latency_rise_min]
      set org_clock_latency_fall_min [get_attribute -quiet $clock clock_latency_fall_min]

      set adj_clock_latency_rise_max $org_clock_latency_rise_max
      set adj_clock_latency_fall_max $org_clock_latency_fall_max
      set adj_clock_latency_rise_min $org_clock_latency_rise_min
      set adj_clock_latency_fall_min $org_clock_latency_fall_min

      if { $options(-max) } {
        set adj_clock_latency_rise_min $org_clock_latency_rise_max
        set adj_clock_latency_fall_min $org_clock_latency_fall_max
      }
      if { $options(-min) } {
        set adj_clock_latency_rise_max $org_clock_latency_rise_min
        set adj_clock_latency_fall_max $org_clock_latency_fall_min
      }

      sproc_msg -info "Virtual Clock : $clock_name"
      sproc_msg -info "Original latency info:"
      sproc_msg -info "  clock_latency_rise_max: $org_clock_latency_rise_max"
      sproc_msg -info "  clock_latency_fall_max: $org_clock_latency_fall_max"
      sproc_msg -info "  clock_latency_rise_min: $org_clock_latency_rise_min"
      sproc_msg -info "  clock_latency_fall_min: $org_clock_latency_fall_min"
      sproc_msg -info "Adjusted latency info:"
      sproc_msg -info "  clock_latency_rise_max: $adj_clock_latency_rise_max"
      sproc_msg -info "  clock_latency_fall_max: $adj_clock_latency_fall_max"
      sproc_msg -info "  clock_latency_rise_min: $adj_clock_latency_rise_min"
      sproc_msg -info "  clock_latency_fall_min: $adj_clock_latency_fall_min"

      set_clock_latency -rise -max $adj_clock_latency_rise_max $clock
      set_clock_latency -fall -max $adj_clock_latency_fall_max $clock
      set_clock_latency -rise -min $adj_clock_latency_rise_min $clock
      set_clock_latency -fall -min $adj_clock_latency_fall_min $clock

    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_pt_adjust_virtual_clock_latency \
  -info "Procedure to filter SDC files for PT and then read them." \
  -define_args {
  {-max "Set all latencies for virtual clocks to max values." "" boolean optional}
  {-min "Set all latencies for virtual clocks to min values." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_icc_mcmm_scenario_list_not:
## -----------------------------------------------------------------------------

proc sproc_icc_mcmm_scenario_list_not { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-base_list)  ""
  set options(-removal_list)  ""
  parse_proc_arguments -args $args options

  set not_list [list]
  foreach scenario $options(-base_list) {
    if { [lsearch $options(-removal_list) $scenario] < 0 } {
      lappend not_list $scenario
    }
  }

  return $not_list

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_icc_mcmm_scenario_list_not \
  -info "Procedure to return the list of non intersecting elements." \
  -define_args {
  {-base_list  "The original list " AString string required}
  {-removal_list  "The removal list " AString string required}
}

## -----------------------------------------------------------------------------
## sproc_icc_mcmm_sdc:
## -----------------------------------------------------------------------------

proc sproc_icc_mcmm_sdc { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-src_sdc)  ""
  set options(-new_mode)  0
  parse_proc_arguments -args $args options

  ## Validate src_sdc exists ... if not look for cloning candidate
  set src_sdc $options(-src_sdc)
  if { ![file exists $src_sdc] } {
    sproc_msg -warning "sproc_icc_mcmm_sdc: Specified SDC file $src_sdc does not exist."

    sproc_msg -warning "sproc_icc_mcmm_sdc:   We are looking to clone from the same mode."
    set tmp [ file rootname [ file rootname [ file rootname $src_sdc ] ] ]
    set tmp [ glob -nocomplain $tmp*.sdc ]

    if { [llength $tmp] > 0 } {
      foreach t $tmp {
        sproc_msg -warning "sproc_icc_mcmm_sdc:     Note cloning candidates include $t"
      }
      set src_sdc [lindex $tmp 0]
    } else {
      sproc_msg -warning "sproc_icc_mcmm_sdc:   Unable to clone from the same mode."
      sproc_msg -warning "sproc_icc_mcmm_sdc:   We are now looking to clone from a non scenario based sdc."
      set tmp "[ file rootname [ file rootname [ file rootname [ file rootname $src_sdc ] ] ] ].sdc"
      if { [file exists $tmp] } {
        set src_sdc [lindex $tmp 0]
      } else {
        sproc_msg -error "sproc_icc_mcmm_sdc: Unable to resolve an SDC for $options(-src_sdc)"
        sproc_pinfo -mode stop
        return
      }
    }
    sproc_msg -warning "sproc_icc_mcmm_sdc:   Cloning from $src_sdc"
  }

  ## Define file naming conventions
  set fname_filtered_sdc "$SEV(dst_dir)/[file tail $options(-src_sdc)]"
  set fname_bad_sdc      "$SEV(dst_dir)/[file tail $options(-src_sdc)].bad"

  sproc_msg -info "sproc_icc_mcmm_sdc:   Using $src_sdc as source SDC."
  sproc_msg -info "sproc_icc_mcmm_sdc:   Using $fname_filtered_sdc as filtered SDC."
  sproc_msg -info "sproc_icc_mcmm_sdc:   Using $fname_bad_sdc as bad SDC."

  ## Open files
  set fid_src_sdc      [open "$src_sdc"  r]
  set fid_filtered_sdc [open "$fname_filtered_sdc" w]
  set fid_bad_sdc      [open "$fname_bad_sdc"      w]

  set partial_line ""
  while { [gets $fid_src_sdc tmp_line] >= 0 } {

    ## Handle lines ending with "\"
    if { [regexp {\\$} $tmp_line] } {
      regsub {\\$} $tmp_line {} tmp_line
      append partial_line $tmp_line
      continue
    } else {
      append partial_line $tmp_line
      set line $partial_line
      set partial_line ""
    }

    ## Perform filtering
    switch -regexp $line {
      {set_voltage} -
      {create_voltage_area} -
      {set_operating_conditions} {
        puts $fid_bad_sdc "$line"
      }
      default {
        puts $fid_filtered_sdc "$line"
      }
    }
  }

  ## Close files
  close $fid_src_sdc
  close $fid_filtered_sdc
  close $fid_bad_sdc

  ## read the SDC
  if { $options(-new_mode) } {
    sproc_msg -info "sproc_icc_mcmm_sdc:   identifed $fname_filtered_sdc as valid ICC MCMM SDC."
    sproc_pinfo -mode stop
    return $fname_filtered_sdc
  } else {
    sproc_msg -info "sproc_icc_mcmm_sdc:   reading $fname_filtered_sdc as valid ICC MCMM SDC."
    read_sdc $fname_filtered_sdc
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_icc_mcmm_sdc \
  -info "Procedure to filter SDC files for ICC MCMM and then read them." \
  -define_args {
  {-src_sdc  "The original SDC files to filter " AString string required}
  {-new_mode  "Operation in new developmental mode." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_filter_wfd :
## -----------------------------------------------------------------------------

proc sproc_filter_wfd  { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-src_wfd)  ""
  set options(-dst_wfd)  ""
  set options(-pg_ports) [get_ports -all -filter {@port_type =~ "*Ground*" || @port_type =~ "*Power*"}]
  parse_proc_arguments -args $args options

  set fin [open $options(-src_wfd) r]
  set fout [open $options(-dst_wfd) w]

  while {[gets $fin line] >= 0} {

    ## -------------------------------------
    ## Remove any pg terminals.
    ## -------------------------------------

    if {[regexp {^create_terminal} $line]} {
      while {[gets $fin term_line] >= 0} {

        ## Detect if port is pg.
        set detect_pg 0
        foreach_in_collection pg_port $options(-pg_ports) {
          set pg_port_name [get_object_name $pg_port]
          if {[regexp $pg_port_name $term_line]} {
            set detect_pg 1
            break
          }
        }

        if { $detect_pg } {
          ## Don't write out pg ports.
          while {[gets $fin term_line] >= 0} {
            if {[regexp {eeq_class} $term_line]} {
              break
            }
          }
        } else {
          ## Print out non-pg ports.
          puts $fout $line
          puts $fout $term_line
          break
        }
        break
      }

      ## -------------------------------------
      ## Remove the Track section if it exists.
      ## -------------------------------------
    } elseif {[regexp {^\#  Track} $line]} {
      while {[gets $fin term_line] >= 0} {
        if {[regexp {^\#\*\*} $term_line]} {
          while {[gets $fin term_line] >= 0} {
            if {[regexp {^\#\*\*} $term_line]} {
              break
            }
          }
          break
        }
      }

      ## -------------------------------------
      ## Remove the Pin Guide section if it exists.
      ## -------------------------------------
    } elseif {[regexp {^\#  Pin Guide} $line]} {
      while {[gets $fin term_line] >= 0} {
        if {[regexp {^\#\*\*} $term_line]} {
          while {[gets $fin term_line] >= 0} {
            if {[regexp {^\#\*\*} $term_line]} {
              break
            }
          }
          break
        }
      }

      ## -------------------------------------
      ## The no_pins option is not supported for blockages in DCT.
      ## See STAR (9000422025) for additional details.
      ## -------------------------------------
    } else {
      regsub -- {-no_pin} $line {} line

      puts $fout $line
    }
  }
  close $fin
  close $fout

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_filter_wfd  \
  -info "Procedure to filter a WFD file." \
  -define_args {
  {-src_wfd  "The original WFD." AString string required}
  {-dst_wfd  "The final WFD." AString string required}
  {-pg_ports  "Specify the collection of pg ports in the design." "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_filter_def :
## -----------------------------------------------------------------------------

proc sproc_filter_def  { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-src_def)  ""
  set options(-dst_def)  ""
  set options(-purge_SCANCHAINS)  0
  set options(-purge_SPECIALNETS)  0
  set options(-purge_NETS)  0
  set options(-purge_nonfixed_COMPONENTS)  0
  set options(-purge_switch_cells)  0
  set options(-purge_other_cells)  ""
  parse_proc_arguments -args $args options

  set debug 0

  set number_of_deleted_components 0

  ## -------------------------------------
  ##
  ## purge scan chains
  ##

  ## Open files
  set fid_src [open "$options(-src_def)" r]
  set fid_dst [open "$options(-dst_def).1" w]

  set mode "copy"
  while { [gets $fid_src line] >= 0 } {

    if { $mode == "copy" } {
      if { $options(-purge_SCANCHAINS) && [regexp {^SCANCHAINS\s+([\d]+)\s+;} $line] } {
        sproc_msg -info "Purging SCANCHAINS section."
        set mode "purge_SCANCHAINS"
      } else {
        puts $fid_dst $line
      }
    } elseif { $mode == "purge_SCANCHAINS" } {
      if { [regexp {^END\s+SCANCHAINS} $line] } {
        set mode "copy"
      }
    } else {
      puts $fid_dst $line
    }

  }

  ## Close files
  close $fid_src
  close $fid_dst

  ## -------------------------------------
  ##
  ## purge SPECIALNETS
  ##

  ## Open files
  set fid_src [open "$options(-dst_def).1" r]
  set fid_dst [open "$options(-dst_def).2" w]

  set mode "copy"
  while { [gets $fid_src line] >= 0 } {

    if { $mode == "copy" } {
      if { $options(-purge_SPECIALNETS) && [regexp {^SPECIALNETS\s+([\d]+)\s+;} $line] } {
        sproc_msg -info "Purging SPECIALNETS section."
        set mode "purge_SPECIALNETS"
      } else {
        puts $fid_dst $line
      }
    } elseif { $mode == "purge_SPECIALNETS" } {
      if { [regexp {^END\s+SPECIALNETS} $line] } {
        set mode "copy"
      }
    } else {
      puts $fid_dst $line
    }

  }

  ## Close files
  close $fid_src
  close $fid_dst
  if { ! $debug } { file delete -force "$options(-dst_def).1" }

  ## -------------------------------------
  ##
  ## purge NETS
  ##

  ## Open files
  set fid_src [open "$options(-dst_def).2" r]
  set fid_dst [open "$options(-dst_def).3" w]

  set mode "copy"
  while { [gets $fid_src line] >= 0 } {

    if { $mode == "copy" } {
      if { $options(-purge_NETS) && [regexp {^NETS\s+([\d]+)\s+;} $line] } {
        sproc_msg -info "Purging NETS section."
        set mode "purge_NETS"
      } else {
        puts $fid_dst $line
      }
    } elseif { $mode == "purge_NETS" } {
      if { [regexp {^END\s+NETS} $line] } {
        set mode "copy"
      }
    } else {
      puts $fid_dst $line
    }

  }

  ## Close files
  close $fid_src
  close $fid_dst
  if { ! $debug } { file delete -force "$options(-dst_def).2" }

  ## -------------------------------------
  ##
  ## purge non fixed components
  ##

  ## Open files
  set fid_src [open "$options(-dst_def).3" r]
  set fid_dst [open "$options(-dst_def).4" w]

  set mode "copy"
  while { [gets $fid_src line] >= 0 } {

    if { $mode == "copy" } {
      if { $options(-purge_nonfixed_COMPONENTS) && [regexp {^COMPONENTS\s+([\d]+)\s+;} $line] } {
        sproc_msg -info "Purging non fixed COMPONENTS items."
        set mode "purge_nonfixed_COMPONENTS"
      }
      puts $fid_dst $line
    } elseif { $mode == "purge_nonfixed_COMPONENTS" } {
      if { [regexp {^END\s+COMPONENTS} $line] } {
        set mode "copy"
        puts $fid_dst $line
      } elseif { [regexp {\s+FIXED\s+} $line] } {
        puts $fid_dst $line
      } else {
        incr number_of_deleted_components
      }
    } else {
      puts $fid_dst $line
    }

  }

  ## Close files
  close $fid_src
  close $fid_dst
  if { ! $debug } { file delete -force "$options(-dst_def).3" }

  ## -------------------------------------

  ##
  ## purge header cells from components
  ##
  ## determine the ref_names of switch cells to purge
  if { $options(-purge_switch_cells) } {
    set t1 [ sproc_get_switch_cells ]
    set t2 [ get_attribute $t1 ref_name -quiet ]
    set header_cell_ref_names [ sproc_uniquify_list -list $t2 ]
  }

  ## Open files
  set fid_src [open "$options(-dst_def).4" r]
  set fid_dst [open "$options(-dst_def).5" w]

  set mode "copy"
  while { [gets $fid_src line] >= 0 } {

    if { $mode == "copy" } {
      if { $options(-purge_switch_cells) && [regexp {^COMPONENTS\s+([\d]+)\s+;} $line] } {
        sproc_msg -info "Purging header cells COMPONENTS items."
        set mode "header_cells_COMPONENTS"
      }
      puts $fid_dst $line
    } elseif { $mode == "header_cells_COMPONENTS" } {
      if { [regexp {^END\s+COMPONENTS} $line] } {
        set mode "copy"
        puts $fid_dst $line
      } else {
        set delete_line 0
        foreach header_cell_ref_name $header_cell_ref_names {
          if { [regexp " $header_cell_ref_name " $line] } {
            set delete_line 1
          }
        }
        if { $delete_line == 0 } {
          puts $fid_dst $line
        } else {
          incr number_of_deleted_components
        }
      }
    } else {
      puts $fid_dst $line
    }

  }

  ## Close files
  close $fid_src
  close $fid_dst
  if { ! $debug } { file delete -force "$options(-dst_def).4" }

  ## -------------------------------------

  ##
  ## purge header cells from components
  ##

  ## determine the ref_names of switch cells to purge
  if { [ sizeof_collection $options(-purge_other_cells) ] > 0 } {

    sproc_msg -info "Purging other cells COMPONENTS items."

    ## Open files
    set fid_src [open "$options(-dst_def).5" r]
    set fid_dst [open "$options(-dst_def).6" w]

    set mode "copy"
    while { [gets $fid_src line] >= 0 } {

      if { $mode == "copy" } {
        if { [regexp {^COMPONENTS\s+([\d]+)\s+;} $line] } {
          set mode "other_cells_COMPONENTS"
        }
        puts $fid_dst $line
      } elseif { $mode == "other_cells_COMPONENTS" } {
        if { [regexp {^END\s+COMPONENTS} $line] } {
          set mode "copy"
          puts $fid_dst $line
        } else {
          set delete_line 0
          foreach_in_collection cell $options(-purge_other_cells) {
            set cell_full_name [get_attribute $cell full_name]
            if { [regexp " $cell_full_name " $line] } {
              set delete_line 1
              break
            }
          }
          if { $delete_line == 0 } {
            puts $fid_dst $line
          } else {
            incr number_of_deleted_components
          }
        }
      } else {
        puts $fid_dst $line
      }

    }

    ## Close files
    close $fid_src
    close $fid_dst

  } else {
    file copy $options(-dst_def).5 $options(-dst_def).6
  }
  if { ! $debug } { file delete -force "$options(-dst_def).5" }

  ## -------------------------------------

  ##
  ## adjust component # for the # of items deleted
  ##

  ## Open files
  set fid_src [open "$options(-dst_def).6" r]
  set fid_dst [open "$options(-dst_def)" w]

  while { [gets $fid_src line] >= 0 } {

    if { [regexp {^COMPONENTS\s+([\d]+)\s+;} $line] } {
      regsub {^COMPONENTS\s+} $line "" line
      regsub {\s+;} $line "" line
      set line [expr $line - $number_of_deleted_components]
      set line "COMPONENTS $line ;"
    }
    puts $fid_dst $line

  }

  ## Close files
  close $fid_src
  close $fid_dst
  if { ! $debug } { file delete -force "$options(-dst_def).6" }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_filter_def  \
  -info "Procedure to filter a DEF file." \
  -define_args {
  {-src_def  "The original DEF." AString string required}
  {-dst_def  "The final DEF." AString string required}
  {-purge_SCANCHAINS  "Remove the SCANCHAINS section from the DEF." "" boolean optional}
  {-purge_SPECIALNETS  "Remove the SPECIALNETS section from the DEF." "" boolean optional}
  {-purge_NETS  "Remove the NETS section from the DEF." "" boolean optional}
  {-purge_nonfixed_COMPONENTS  "Remove the non fixed items in the COMPONENTS section of the DEF." "" boolean optional}
  {-purge_switch_cells  "Remove header cells from the COMPONENTS section of the DEF." "" boolean optional}
  {-purge_other_cells  "Remove user supplied collection of cells from the DEF." "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_remove_ideal_nets:
## -----------------------------------------------------------------------------

proc sproc_remove_ideal_network { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-restore_clocks) 0
  parse_proc_arguments -args $args options

  ##
  ## as best practices
  ##  - remove all ideal networks (except on CTS) ... so that high fanout items
  ##    get bufferred visa AHFS during place_opt.
  ##  - re-appliction on CTS network is to deal with data/clock mixing & is
  ##    a work around that should go away someday
  ##
  if { [llength [all_scenarios]] == 0 } {
    remove_ideal_network -all
    if { $options(-restore_clocks) } {
      set clks [ all_fanout -flat -clock_tree ]
      if { [sizeof $clks] > 0 } { set_ideal_network $clks }
    }
  } else {

    set tmp_current_scenario [current_scenario]

    set need_to_activate 0
    if { [ llength [all_active_scenarios] ] < [ llength [all_scenarios] ] } {
      set need_to_activate 1
      set orig_active_scenarios [all_active_scenarios]
      set_active_scenarios -all
    }

    remove_ideal_network -all

    if { $options(-restore_clocks) } {
      foreach scenario [all_scenarios] {
        current_scenario $scenario
        set clks [ all_fanout -flat -clock_tree ]
        if { [sizeof $clks] > 0 } { set_ideal_network $clks }
      }
    }

    if { $need_to_activate } {
      set_active_scenarios $orig_active_scenarios
    }

    current_scenario $tmp_current_scenario
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_remove_ideal_network \
  -info "Utility removing ideal nets ." \
  -define_args {
  {-restore_clocks  "Restore ideal network status on clocks during place_opt" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_icc_port_layer_correctness:
## -----------------------------------------------------------------------------

proc sproc_screen_icc_port_layer_correctness { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-verbose) 0
  parse_proc_arguments -args $args options

  if { !$SVAR(is_chip) } {

    ##
    ## Robustness in the context of multi-layer pins and other situtations
    ## not perfectly understood.  If you encounter any problems simply
    ## terminated usage of this proc.  Also advise of the situation so we
    ## can improve it.  Thanks.
    ##

    ## grab max layer routing layer mode
    set max_layer_mode [ get_route_zrt_common_options -name net_max_layer_mode ]

    ## grab max layer routing layer
    redirect -variable report {  report_ignored_layers }
    set lines [split $report "\n"]
    set max_routing_layer "tbd"
    foreach line $lines {
      regexp {Max_routing_layer:\s+([\w\.]+)} $line matchVar max_routing_layer
    }
    set max_routing_layer_index [lsearch [sproc_convert_to_metal_layer_name] $max_routing_layer]

    ##
    ## grab ports, for each port validate port is on a layer between any min
    ## and may layer constraints, if not generate a message
    ##
    set errors 0
    foreach_in_collection port [ get_ports ] {
      set port_layer [get_attribute $port layer]
      set net [all_connected $port]

      set max_layer [get_attribute $net max_layer]
      if { $max_layer == "no_max_layer" } {
        set max_index $max_routing_layer_index
      } else {
        set max_index [lsearch [sproc_convert_to_metal_layer_name] $max_layer]
      }

      set min_layer [get_attribute $net min_layer]
      if { $min_layer == "no_min_layer" } {
        set min_index 0
      } else {
        set min_index [lsearch [sproc_convert_to_metal_layer_name] $min_layer]
      }

      ## construction list of allowable layers for port
      incr min_index
      incr max_index
      set allowable_layer_list [sproc_convert_to_metal_layer_name -from $min_index -to $max_index]

      ## validate port is witin allowable_layer_list
      if { [lsearch $allowable_layer_list $port_layer] < 0 } {
        set port_name [get_attribute $port full_name]
        sproc_msg -error "Port \"$port_name\" is on layer \"$port_layer\" but is restricted to layers \"$allowable_layer_list\"."
        incr errors
      } elseif { $options(-verbose) } {
        set port_name [get_attribute $port full_name]
        sproc_msg -info "Port \"$port_name\" is on layer \"$port_layer\" but is restricted to layers \"$allowable_layer_list\"."
      } else {
      }
    }

    if { ( $errors > 0 ) && ( $max_layer_mode == "hard" ) } {
      sproc_msg -error "$errors errors were identified by sproc_screen_icc_port_layer_correctness."
      sproc_msg -error "set_route_zrt_common_options -max_layer_mode = \"$max_layer_mode\", as such the router may"
      sproc_msg -error "encounter DRC closure issues depending on other factors."
    } elseif { ( $errors > 0 ) } {
      sproc_msg -error "$errors errors were identified by sproc_screen_icc_port_layer_correctness."
      sproc_msg -error "set_route_zrt_common_options -max_layer_mode = \"$max_layer_mode\", as such the router may"
      sproc_msg -error "tolerate this situation.  You should be sure this is by design and not by accident."
    } else {
      sproc_msg -info "$errors errors were identified by sproc_screen_icc_port_layer_correctness."
    }
  } else {
    sproc_msg -info "SVAR(is_chip) = $SVAR(is_chip) so screen skipped by sproc_screen_icc_port_layer_correctness."
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_screen_icc_port_layer_correctness \
  -info "Utility checking for port metal layers vs any min / max layer constraints." \
  -define_args {
  {-verbose "Used to enable verbose mode." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_icc_constraint_quality:
## -----------------------------------------------------------------------------

proc sproc_screen_icc_constraint_quality { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-verbose) 0
  set options(-current_scenario_only) 0
  parse_proc_arguments -args $args options

  set errors 0

  if { $options(-current_scenario_only) } {
    sproc_msg -warning "sproc_screen_icc_constraint_quality is being ran w/ \"-current_scenario_only\"."
    set scenarios [current_scenario]
  } else {
    ## validate number of active scenarios
    set n1 [ llength [all_active_scenarios] ]
    set n2 [ llength [all_scenarios] ]
    if { $n1 < $n2 } {
      sproc_msg -warning "Only $n1 out of $n2 scenarios are active for analysis by  sproc_screen_icc_constraint_quality."
    }
    set scenarios [all_active_scenarios]
  }

  ## loop over active scenarios
  foreach scenario $scenarios {
    current_scenario $scenario

    ## check for critical range
    set cr [ get_attribute [current_design] critical_range ]
    if { $cr == "" } {
      sproc_msg -warning "Lynx detected [current_scenario] lacks critical range constraint."
      sproc_msg -warning "Although not a requirement it is highly recommended."
      incr errors
    } else {
      sproc_msg -info "Lynx detected [current_scenario] critical range constraint : $cr"
    }

    ## check for max transition
    set mt [ get_attribute [current_design] max_transition ]
    if { $mt == "" } {
      sproc_msg -warning "Lynx detected [current_scenario] lacks max transition constraint."
      sproc_msg -warning "Although not a requirement it is highly recommended."
      incr errors
    } else {
      sproc_msg -info "Lynx detected [current_scenario] max transition constraint : $mt"
    }

  }

  sproc_msg -info "$errors types of possible issues were identified by sproc_screen_icc_constraint_quality."

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_screen_icc_constraint_quality \
  -info "Utility checking for a few items that if missed can materially impact flow performance." \
  -define_args {
  {-verbose "Used to enable verbose mode." "" boolean optional}
  {-current_scenario_only "Used to enable analysis of the current scenario only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_icc_scenario_setup:
## -----------------------------------------------------------------------------

proc sproc_screen_icc_scenario_setup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-verbose) 0
  parse_proc_arguments -args $args options

  set errors 0
  set warnings 0

  ## confirm there is atleast 1 scenario
  set scenarios [all_scenarios]
  set num_scenarios [ llength $scenarios ]
  if { $num_scenarios == 0 } {
    sproc_msg -error "$num_scenarios scenarios have been detected.  Atleast one scenario is required."
    incr errors
  }

  ## analyze leakage scenarios for possible issues
  set scenarios [get_scenarios -leakage_power true *]
  set num_scenarios [ llength $scenarios ]
  if { $num_scenarios == 0 } {
    sproc_msg -warning "$num_scenarios scenarios have been identified as \"set_scenario_options -leakage_power true\"."
    sproc_msg -warning "Typically one scenario is identified as true so review your setup and confirm your intent."
    incr warnings
  } elseif { $num_scenarios > 1 } {
    sproc_msg -error "$num_scenarios scenarios have been identified as \"set_scenario_options -leakage_power true\"."
    sproc_msg -error "To ensure compatibilty w/ Final Stage Leakage Recover (FSLR) 1 leakage scenarios is recommened."
    incr errors
  }

  ## analyze cts scenarios for possible issues
  set scenarios [get_scenarios -cts_mode true *]
  set num_scenarios [ llength $scenarios ]
  if { $num_scenarios == 0 } {
    sproc_msg -warning "$num_scenarios scenarios have been explicitly identified as \"set_scenario_options -cts_mode true\"."
    sproc_msg -warning "As such tool will simply use the current_scenario at the point of CTS.  Atleast 1 scenario is highly recommended."
    incr warnings
  }

  ## >
  ## > CTS only scenario restrictions lifted w/ icc/2011.09-SP4.  currently lack hard verification hence
  ## > keeping the code but commenting out.
  ## >
  ##
  ## set scenarios [get_scenarios -cts_mode true -setup false *]
  ## set num_scenarios [ llength $scenarios ]
  ## if { $num_scenarios > 0 } {
  ##   sproc_msg -error "$num_scenarios scenarios have been explicitly identified as \"set_scenario_options -cts_mode true -setup false\"."
  ##   sproc_msg -error "As the CTS engine currently requires the max side graph to be present this is not a robust configuration."
  ##   sproc_msg -error "Also look closely as the CTO for the scenario is likely implicitly = max."
  ##   incr errors
  ## }

  ## analyze scenarios for possible configuration issues
  set scenarios [get_scenarios -dynamic_power true -setup false *]
  set num_scenarios [ llength $scenarios ]
  if { $num_scenarios > 0 } {
    sproc_msg -error "$num_scenarios scenarios have been explicitly identified as \"set_scenario_options -dynamic_power true -setup false\"."
    sproc_msg -error "This is not a robust configuration as dynamic power is costed against the max side graph graph."
    incr errors
  }

  sproc_msg -info "$warnings types of possible issues were identified as Warnings by sproc_screen_icc_scenario_setup."
  sproc_msg -info "$errors types of possible issues were identified as Errors by sproc_screen_icc_scenario_setup."
  if { ( $warnings > 0 ) || ( $errors > 0 ) } {
    sproc_msg -info "Something in your scenario setup has been flagged for review and could cause complications"
    sproc_msg -info "later in the flow.  It is advised to familiarize yourself with the issue and proceed accordingly."
    sproc_msg -info "A touch pass can be performed on this task if you wish to disregard this information."
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_screen_icc_scenario_setup \
  -info "Utility checking for issues w/ scenario setup." \
  -define_args {
  {-verbose "Used to enable verbose mode." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_icc_for_ideal_nets:
## -----------------------------------------------------------------------------

proc sproc_screen_icc_for_ideal_nets { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  parse_proc_arguments -args $args options

  ##
  ## at a certain point in the flow ideal nets should no longer exists.  this
  ## utility can be use to check for any and generates an error if detected
  ## - filter out Tie High / Low nets which got introduced w/ 08.09
  ##
  sproc_msg -info "  Checking for ideal nets."
  ## set ideal_nets [ get_nets -hier -filter "ideal_net==true" -quiet ]
  set ideal_nets [ all_ideal_nets ]

  set abstract_ideal_nets [ add_to_collection "" "" ]
  foreach_in_collection net $ideal_nets {
    foreach_in_collection abstract [ get_cells -hier * -filter "is_block_abstraction==TRUE" -quiet ] {
      set inst_abstract [ get_attribute $abstract full_name ]
      if { [regexp "^$inst_abstract" [get_attribute $net full_name] ] } {
        set abstract_ideal_nets [ add_to_collection $abstract_ideal_nets $net ]
      }
    }
  }
  set ideal_nets [ remove_from_collection $ideal_nets $abstract_ideal_nets ]

  set count [ sizeof_collection $ideal_nets ]

  if { $count > 0 } {
    sproc_msg -error "There should be no ideal nets left in the design, but $count"
    sproc_msg -error "ideal nets were identified.  Please investigate."
    foreach_in_collection net $ideal_nets {
      sproc_msg -warning "  [get_attribute $net full_name] is an ideal net, please investigate."
    }
  } else {
    sproc_msg -issue "$count possible issues were identified by sproc_screen_icc_for_ideal_nets."
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_screen_icc_for_ideal_nets \
  -info "Utility checking for ideal nets ." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_screen_icc_utilization:
## -----------------------------------------------------------------------------

proc sproc_screen_icc_utilization { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global placer_max_cell_density_threshold

  parse_proc_arguments -args $args options

  ##
  ## Establish a low_utilization_threshold.  this is a pseudo arbitrary # for
  ## which we have choosen 0.65
  ##
  set low_utilization_threshold 0.65

  ## determine the actual utilization of the design
  redirect -variable report { report_design_physical -utilization }
  set lines [split $report "\n"]
  set actual_utilization -1
  foreach line $lines {
    ##
    ## the regexp was
    ##   [ regexp {Cell/Core Ratio\s+:\s+([\d\.]+)\%} $line matchVar actual_utilization ]
    ## prior to lynx/2012.06-SP2 at which time it was updated
    ##
    if { [ regexp {^Cell Utilization\(non-fixed \+ fixed\) = ([\d\.]+)%} $line matchVar actual_utilization ] } {
      set actual_utilization [expr $actual_utilization / 100.0]
    }
  }

  if { $actual_utilization < 0 } {
    sproc_msg -error "sproc_screen_icc_utilization: Unable to determine utilization of the design."
  } else {
    if { ( $actual_utilization < $low_utilization_threshold ) && ( $placer_max_cell_density_threshold < 0 ) } {
      sproc_msg -warning "sproc_screen_icc_utilization: The design appears to have a utilization = $actual_utilization.  It"
      sproc_msg -warning "sproc_screen_icc_utilization: also appears absent placer_max_cell_density_threshold which can assist"
      sproc_msg -warning "sproc_screen_icc_utilization: with creating some clumping for low utilized designs.  You may want to"
      sproc_msg -warning "sproc_screen_icc_utilization: consider enabling placer_max_cell_density_threshold by way of"
      sproc_msg -warning "sproc_screen_icc_utilization: SVAR(place,placer_max_cell_density_threshold) for future DC and ICC runs."
    } elseif { $actual_utilization > $placer_max_cell_density_threshold } {
      sproc_msg -warning "sproc_screen_icc_utilization: The design appears to have a utilization = $actual_utilization which"
      sproc_msg -warning "sproc_screen_icc_utilization: is greater than SVAR(place,placer_max_cell_density_threshold) = $placer_max_cell_density_threshold."
      sproc_msg -warning "sproc_screen_icc_utilization: If you wish for greater clumping of standard cells you may wish to consider reducing the value of"
      sproc_msg -warning "sproc_screen_icc_utilization: SVAR(place,placer_max_cell_density_threshold) for future DC and ICC runs."
    }
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_screen_icc_utilization \
  -info "Utility checking for appropriate placement configuration based on utilization." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_get_preferred_direction:
## -----------------------------------------------------------------------------

proc sproc_get_preferred_direction { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-layer_name) ""
  parse_proc_arguments -args $args options

  set return_value NO_DIRECTION_FOUND

  ## -------------------------------------
  ## Parse data from SVAR(tech,metal_layer_info_list), so that
  ## changes in variable format do not affect this procedure.
  ## -------------------------------------
  foreach item $SVAR(tech,metal_layer_info_list) {
    set name [lindex $item 0]
    set dir  [lindex $item 1]
    if { $name == $options(-layer_name) } {
      set return_value $dir
    }
  }

  if { $return_value == "NO_DIRECTION_FOUND" } {
    sproc_msg -error "Unable to identify direction for layer $options(-layer_name)"
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_preferred_direction \
  -info "Returns preferred metal layer direction." \
  -define_args {
  {-layer_name "Layer to query for preferred metal layer direction." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_convert_to_metal_layer_name:
## -----------------------------------------------------------------------------

proc sproc_convert_to_metal_layer_name { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-list) ""
  set options(-from) ""
  set options(-to) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Parse data from SVAR(tech,metal_layer_info_list), so that
  ## changes in variable format do not affect this procedure.
  ## -------------------------------------
  unset -nocomplain metal_layer_name_list
  unset -nocomplain metal_layer_dir_list
  foreach item $SVAR(tech,metal_layer_info_list) {
    set name [lindex $item 0]
    set dir  [lindex $item 1]
    lappend metal_layer_name_list $name
    lappend metal_layer_dir_list $dir
  }

  ## -------------------------------------
  ## Determine max number of metal layers
  ## -------------------------------------
  set max_layer_number [llength $metal_layer_name_list]

  ## Check for valid query range
  if { $options(-to) < $options(-from) } {
    set to_temp $options(-to)
    set options(-to) $options(-from)
    set options(-from) $to_temp
  }

  ## Set lower layer.
  if { $options(-from) != "" } {
    set lower_layer $options(-from)
  } else {
    set lower_layer 1
  }

  ## Set higher layer.
  if { $options(-to) != "" } {
    set higher_layer $options(-to)
  } else {
    set higher_layer  $max_layer_number
  }

  ## List option overrides to/from
  if { $options(-list) == "" } {
    for {set x $lower_layer} { $x <= $higher_layer } { incr x } {
      lappend options(-list) $x
    }
  }

  set layer_name_list [list]

  foreach layer_number $options(-list) {
    if { ($layer_number >= 1) && ( $layer_number <= $max_layer_number) } {
      lappend layer_name_list [lindex $metal_layer_name_list [expr $layer_number - 1]]
    } else {
      sproc_msg -error "Metal layer number out of range."
      sproc_msg -error "Metal layer number must be between 1 and $max_layer_number."
      sproc_msg -error "The metal layer number used was $layer_number"
      sproc_pinfo -mode stop
      return ""
    }
  }

  sproc_pinfo -mode stop
  return $layer_name_list
}

define_proc_attributes sproc_convert_to_metal_layer_name \
  -info "Maps a list of layers expressed as integers into a list of metal layer names." \
  -define_args {
  {-list "The list of metal layers in integer format." AString string optional}
  {-to   "Query to"                                    AnInt int optional}
  {-from "Query from"                                  AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_pkg_star:
## -----------------------------------------------------------------------------

proc sproc_pkg_star { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name
  global link_library
  global target_library
  global search_path

  ## -------------------------------------
  ## Ensure we are running the supported tool.
  ## -------------------------------------

  if { ($synopsys_program_name != "dc_shell") && ($synopsys_program_name != "icc_shell") } {
    sproc_msg -error "This procedure only supports DesignCompiler & ICCompiler."
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-design) ""
  set options(-database) ""
  set options(-star_name) "STAR.tbdNum"
  set options(-overwrite) 0

  parse_proc_arguments -args $args options

  if { ![file exists $options(-database)] } {
    sproc_msg -error "The database specified by -database does not exist."
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Define some usefull local variables
  ## -------------------------------------

  set dir(star)    $options(-star_name)
  set dir(inputs)  $options(-star_name)/inputs
  set dir(libs)    $options(-star_name)/libs
  set dir(logs)    $options(-star_name)/logs
  set dir(rpts)    $options(-star_name)/rpts
  set dir(scripts) $options(-star_name)/scripts
  set dir(work)    $options(-star_name)/work

  ## -------------------------------------
  ## Create the STAR directory
  ## -------------------------------------

  if { $options(-overwrite) && [ file exists $dir(star) ] } {
    sproc_msg -info "Removing existing STAR directory."
    exec chmod -R 777 $dir(star)
    file delete -force $dir(star)
  }

  if { [file exists $dir(star)] } {
    sproc_msg -error "STAR directory already exists, and -overwrite not specified."
    sproc_pinfo -mode stop
    return
  } else {
    sproc_msg -info "Creating STAR directory."
    foreach index [array names dir] {
      file mkdir $dir($index)
    }
  }

  ## -------------------------------------
  ## Ensure that this procedure is called with a valid design already loaded.
  ## -------------------------------------

  sproc_msg -info "Checking initial design status."

  switch $synopsys_program_name {
    dc_shell {
      if { [current_design] != {} } {
        remove_design -all
        read_ddc $options(-database)
        link
      } else {
        sproc_msg -error "This procedure must be invoked with a loaded design."
      }
    }
    icc_shell {
      if { [sizeof_collection [current_mw_lib]] == 1 } {
        close_mw_lib
      } else {
        sproc_msg -error "This procedure must be invoked with a loaded design."
        sproc_pinfo -mode stop
        return
      }
    }
  }

  ## -------------------------------------
  ## Copy the design into the STAR directory
  ## -------------------------------------

  sproc_msg -info "Copying design data to $dir(inputs)"

  file copy -force $options(-database) $dir(inputs)

  ## -------------------------------------
  ## Copy the libraries into the STAR directory (physical)
  ## -------------------------------------

  sproc_msg -info "Copying physical libs to $dir(libs)"

  switch $synopsys_program_name {

    icc_shell {

      ## -------------------------------------
      ## Find the design's references
      ## -------------------------------------

      set design_reflib_list [list]
      set design_reflib_list2 [list]

      file delete -force tmp_file
      write_mw_lib_files -reference_control_file -output tmp_file $options(-database)

      set fid [open "tmp_file" r]
      while { [gets $fid line] >= 0 } {
        if { [regexp {^\s*REFERENCE} $line] } {
          regexp {REFERENCE\s+(\S+)} $line {} reflib
          if { [lsearch $design_reflib_list2 [file tail $reflib]] < 0 } {
            set design_reflib_list "$design_reflib_list $reflib"
            set design_reflib_list2 "$design_reflib_list2 [file tail $reflib]"
          } else {
            sproc_msg -warning "Duplicate reflib found...NOT copying $reflib."
          }
        }
      }
      close $fid

      ## -------------------------------------
      ## Find the reference's references
      ## -------------------------------------

      set reference_reflib_list [list]

      foreach reflib $design_reflib_list {

        file delete -force tmp_file
        write_mw_lib_files -reference_control_file -output tmp_file $reflib

        if { ![file exists tmp_file] } {
          continue
        }
        set fid [open "tmp_file" r]
        while { [gets $fid line] >= 0 } {
          if { [regexp {REFERENCE} $line] } {
            set reflib [lindex $line 1]
            if { [lsearch $design_reflib_list2 [file tail $reflib]] < 0 } {
              set reference_reflib_list "$reference_reflib_list $reflib"
              set design_reflib_list2 "$design_reflib_list2 [file tail $reflib]"
            } else {
              sproc_msg -warning "Duplicate reflib found...NOT copying $reflib."
            }
          }
        }
        close $fid

      }

      set all_reflib_list [lsort -unique "$design_reflib_list $reference_reflib_list"]

      if { $all_reflib_list == "" } {
        sproc_msg -error "There appears to be a problem as all_reflib_list appears empty."
      }

      ## -------------------------------------
      ## Copy the reference libs
      ## -------------------------------------

      foreach reflib $all_reflib_list {
        sproc_msg -info "Copying $reflib"
        if { [info exists $dir(libs)/[file tail $reflib]] == 0 } {
          file copy -force $reflib $dir(libs)
        }  else {
          set suffix 0
          while { [info exists $dir(libs)/[file tail $reflib].suffix] } {
            incr suffix
          }
          sproc_msg -error "Found a duplicate reflib...renaming to $dir(libs)/[file tail $reflib].suffix."
          file copy -force $reflib $dir(libs)/[file tail $reflib].suffix
        }
      }

      ## -------------------------------------
      ## Update references for all libs
      ## -------------------------------------

      set reflib_cmd_list [list]

      set org_libs "$options(-database) $all_reflib_list"

      foreach org_lib $org_libs {

        if { [lsearch $org_libs $org_lib] == 0 } {
          ## The first entry is the design
          set new_lib "\[pwd\]/work/[file tail $org_lib]"
        } else {
          set new_lib "\[pwd\]/libs/[file tail $org_lib]"
        }

        sproc_msg -info "Updating references for $new_lib"

        set old_reflib_list [list]

        file delete -force tmp_file
        write_mw_lib_files -reference_control_file -output tmp_file $org_lib

        if { ![file exists tmp_file] } {
          continue
        }
        set fid [open "tmp_file" r]
        while { [gets $fid line] >= 0 } {
          if { [regexp {REFERENCE} $line] } {
            set reflib [lindex $line 1]
            set old_reflib_list "$old_reflib_list $reflib"
          }
        }
        close $fid

        if { [llength $old_reflib_list] > 0 } {

          if { $synopsys_program_name == "icc_shell" } {
            set new_reflib_list [list]
          } else {
            set reflib_cmd "remove_reference_library -from $new_lib -all"
            lappend reflib_cmd_list $reflib_cmd
          }

          foreach old_reflib $old_reflib_list {
            set new_reflib "\[pwd]\/libs/[file tail $old_reflib]"
            ## sproc_msg -info "   Old reference is : $old_reflib"
            ## sproc_msg -info "   New reference is : $new_reflib"

            if { $synopsys_program_name == "icc_shell" } {
              set new_reflib_list "$new_reflib_list $new_reflib \\\n"
            } else {
              set reflib_cmd "add_reference_library -to $new_lib $new_reflib"
              lappend reflib_cmd_list $reflib_cmd
            }
          }

          if { $synopsys_program_name == "icc_shell" } {
            set reflib_cmd "set ref_list \[list \\\n${new_reflib_list}\]"
            lappend reflib_cmd_list $reflib_cmd
            set reflib_cmd "set_mw_lib_reference -mw_reference_library \$ref_list $new_lib \n"
            lappend reflib_cmd_list $reflib_cmd
          }

        }
      }
    }

    dc_shell {
      if { [shell_is_in_topographical_mode] } {
        foreach reflib $SVAR(lib,mw_reflist) {
          file copy -force $reflib $dir(libs)
        }
      }
    }

  }

  ## -------------------------------------
  ## Copy the libraries into the STAR directory (logical)
  ## -------------------------------------

  sproc_msg -info "Copying logical libs to $dir(libs)"

  switch $synopsys_program_name {

    dc_shell -
    icc_shell {

      set library_file_list [list]

      if { $synopsys_program_name == "dc_shell" } {
        redirect -variable rpt {
          list_libs
        }
      } else {
        open_mw_cel -library $options(-database) $options(-design)
        current_design $options(-design)
        link -force
        redirect -variable rpt {
          list_libs
        }
        close_mw_lib
      }

      set lines [split $rpt "\n"]
      set dash_count 0
      foreach line $lines {
        if { [regexp {^----} $line] } {
          incr dash_count
          continue
        }
        if { $dash_count != 2 } {
          continue
        }
        regsub {^m } $line { } line
        regsub {^M } $line { } line
        if { [llength $line] == 3 } {
          set lib  [lindex $line 0]
          set file [lindex $line 1]
          set path [lindex $line 2]
          set library_file_list "$library_file_list $path/$file"
        }
      }

      if { [info exists all_reflib_list] == 0 } {
        set all_reflib_list [list]
      }
      set lm_search_path [list]
      set db_copied 0
      foreach file $library_file_list {
        if { ([file extension $file] == ".sldb") || ([file tail $file] == "gtech.db") } {
          ## Dont copy libs in tool release
        } else {

          ## if using db is in the MW/LM ... then use it, else copy it

          set lm_hit 0
          foreach reflib $all_reflib_list {
            if { [ regexp $reflib $file ] == 1 } {
              set lm_hit 1
              lappend lm_search_path "./libs/[file tail $reflib]/LM"
              sproc_msg -info "   Using a MW [file tail $reflib]/LM view of $file"
            }
          }

          if { $lm_hit == 0 } {
            sproc_msg -info "   Copying $file"
            if { [info exists $dir(libs)/[file tail $file]] == 0 } {
              file copy -force $file $dir(libs)
            } else {
              set suffix 0
              while { [info exists $dir(libs)/[file tail $file].suffix] } {
                incr suffix
              }
              sproc_msg -error "Duplicate library found...renaming to $dir(libs)/[file tail $file].suffix"
              file copy -force $reflib $dir(libs)/[file tail $file].suffix
            }
            incr db_copied
          }

        }
      }
      set lm_search_path [lsort -unique $lm_search_path]

      if { $db_copied == 0 } {
        sproc_msg -error "There appears to be a problem as no dbs copied."
      }

    }

  }

  ## -------------------------------------
  ## Process tlu_plus information
  ## -------------------------------------

  sproc_msg -info "Copying TLU+ data to $dir(libs)"

  if { ($synopsys_program_name == "icc_shell") || (($synopsys_program_name == "dc_shell") && [shell_is_in_topographical_mode]) } {

    set num_scenarios 0
    set scenario_names($num_scenarios)   undefined
    set tlup_lib_max($num_scenarios)     undefined
    set tlup_lib_min($num_scenarios)     undefined
    set tlup_lib_max_emf($num_scenarios) undefined
    set tlup_lib_min_emf($num_scenarios) undefined
    set tlup_lib_map($num_scenarios)     undefined

    if { $synopsys_program_name == "icc_shell" } {
      open_mw_lib $options(-database)
      open_mw_cel $options(-design)

      set_active_scenarios -all
      if { [ llength [all_scenarios] ] > 0 } {
        set scenarios_list [all_scenarios]
      } else {
        set scenarios_list "undefined"
      }

      foreach scenario $scenarios_list {
        if { [ llength [all_scenarios] ] > 0 } {
          current_scenario $scenario
        }
        set scenario_names($num_scenarios)   $scenario
        set tlup_lib_max($num_scenarios)     undefined
        set tlup_lib_min($num_scenarios)     undefined
        set tlup_lib_max_emf($num_scenarios) undefined
        set tlup_lib_min_emf($num_scenarios) undefined
        set tlup_lib_map($num_scenarios)     undefined

        redirect -variable rpt {
          report_tlu_plus_files
        }

        set lines [split $rpt "\n"]
        foreach line $lines {
          regexp {^\s*Max TLU\+ file: (\S+)} $line matchVar tlup_lib_max($num_scenarios)
          regexp {^\s*Min TLU\+ file: (\S+)} $line matchVar tlup_lib_min($num_scenarios)
          regexp {^\s*Max EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_max_emf($num_scenarios)
          regexp {^\s*Min EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_min_emf($num_scenarios)
          regexp {^\s*Tech2ITF mapping file: (\S+)} $line matchVar tlup_lib_map($num_scenarios)
        }

        incr num_scenarios
      }

      close_mw_lib
    } else {
      if { [ llength [all_scenarios] ] > 0 } {
        set scenarios_list [all_scenarios]
        set_active_scenarios -all
      } else {
        set scenarios_list "undefined"
      }
      foreach scenario $scenarios_list {
        if { [ llength [all_scenarios] ] > 0 } {
          current_scenario $scenario
        }
        set scenario_names($num_scenarios)   $scenario
        set tlup_lib_max($num_scenarios)     undefined
        set tlup_lib_min($num_scenarios)     undefined
        set tlup_lib_max_emf($num_scenarios) undefined
        set tlup_lib_min_emf($num_scenarios) undefined
        set tlup_lib_map($num_scenarios)     undefined

        redirect -variable rpt {
          report_tlu_plus_files
        }

        set lines [split $rpt "\n"]
        foreach line $lines {
          regexp {^\s*Max TLU\+ file: (\S+)} $line matchVar tlup_lib_max($num_scenarios)
          regexp {^\s*Min TLU\+ file: (\S+)} $line matchVar tlup_lib_min($num_scenarios)
          regexp {^\s*Max EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_max_emf($num_scenarios)
          regexp {^\s*Min EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_min_emf($num_scenarios)
          regexp {^\s*Tech2ITF mapping file: (\S+)} $line matchVar tlup_lib_map($num_scenarios)
        }

        incr num_scenarios
      }

    }
    for {set x 0} { $x < $num_scenarios } {incr x} {
      if { [file exists $tlup_lib_max($x)]     } { file copy -force $tlup_lib_max($x)     $dir(libs) }
      if { [file exists $tlup_lib_min($x)]     } { file copy -force $tlup_lib_min($x)     $dir(libs) }
      if { [file exists $tlup_lib_max_emf($x)] } { file copy -force $tlup_lib_max_emf($x) $dir(libs) }
      if { [file exists $tlup_lib_min_emf($x)] } { file copy -force $tlup_lib_min_emf($x) $dir(libs) }
      if { [file exists $tlup_lib_map($x)]     } { file copy -force $tlup_lib_map($x)     $dir(libs) }
    }

  }

  ## -------------------------------------
  ## Create the script file
  ## -------------------------------------

  sproc_msg -info "Creating the_script.tcl"

  set filename $dir(scripts)/the_script.tcl

  set fid [open $filename w]

  set database [file tail $options(-database)]
  puts $fid "file delete -force \[pwd\]/work/$database"

  if { $synopsys_program_name == "icc_shell" } {
    puts $fid "copy_mw_lib -from \[pwd\]/inputs/$database -to \[pwd\]/work/$database \n"
  } else {
    puts $fid "file copy -force \[pwd\]/inputs/$database \[pwd\]/work/$database \n"
  }

  switch $synopsys_program_name {

    dc_shell {

      puts $fid "lappend search_path ./libs/ $lm_search_path \n"

      puts $fid "set link_library \[list \\"
      puts $fid "  * \\"
      foreach file $library_file_list {
        puts $fid "  [file tail $file] \\"
      }
      puts $fid "\] \n"

      puts $fid "set target_library \[list \\"
      foreach file $target_library {
        puts $fid "  [file tail $file] \\"
      }
      puts $fid "\] \n"

      if { [shell_is_in_topographical_mode] } {

        ## Need to create MW
        file copy -force $SVAR(tech,mw_tech_file) $dir(libs)
        set new_tf ./libs/[file tail $SVAR(tech,mw_tech_file)]
        set new_reflibs ""
        foreach reflib $SVAR(lib,mw_reflist) {
          set new_reflib \$\{STAR_dir\}/libs/[file tail $reflib]
          lappend new_reflibs $new_reflib
        }

        puts $fid "set STAR_dir \[pwd\] \n"
        puts $fid "file delete -force ./work/mw_lib_name \n"
        puts $fid "create_mw_lib \\"
        puts $fid "  -technology $new_tf \\"
        puts $fid "  -mw_reference_library \[list \\"

        foreach new_rlib $new_reflibs {
          puts $fid "    $new_rlib \\"
        }

        puts $fid "  \] \\"
        puts $fid "  ./work/mw_lib_name \n"
        puts $fid "open_mw_lib ./work/mw_lib_name \n"

        puts $fid "read_ddc ./work/$database"
        puts $fid "current_design $options(-design)"
        puts $fid "link \n"

        ## Need to set TLU+
        for {set x 0} { $x < $num_scenarios } { incr x } {
          if { [ llength [all_scenarios] ] > 0 } {
            puts $fid "current_scenario $scenario_names($x)"
          }
          puts $fid "set_tlu_plus_files \\"
          if { $tlup_lib_max($x) != "undefined" } {
            puts $fid "  -max_tluplus ./libs/[file tail $tlup_lib_max($x)] \\"
          }
          if { $tlup_lib_min($x) != "undefined" } {
            puts $fid "  -min_tluplus ./libs/[file tail $tlup_lib_min($x)] \\"
          }
          if { $tlup_lib_max_emf($x) != "undefined" } {
            puts $fid "  -max_emulation_tluplus ./libs/[file tail $tlup_lib_max_emf($x)] \\"
          }
          if { $tlup_lib_min_emf($x) != "undefined" } {
            puts $fid "  -min_emulation_tluplus ./libs/[file tail $tlup_lib_min_emf($x)] \\"
          }
          if { $tlup_lib_map($x) != "undefined" } {
            puts $fid "  -tech2itf_map ./libs/[file tail $tlup_lib_map($x)] "
          }
          puts $fid "\n"
        }

        puts $fid "report_mw_lib -mw_reference_library ./work/$database"
        puts $fid "report_tlu_plus_files \n"
      }

      ## Need to perform layer setup.

      puts $fid "report_preferred_routing_direction \n"
      puts $fid "remove_ignored_layers -all"
      set min_routing_layer [sproc_convert_to_metal_layer_name -list 1]
      set max_routing_layer [sproc_convert_to_metal_layer_name -list $SVAR(route,layer_signal_max)]
      puts $fid "set_ignored_layers -min_routing_layer $min_routing_layer -max_routing_layer $max_routing_layer"
      puts $fid "report_ignored_layers \n"

    }

    icc_shell {

      puts $fid "lappend search_path \[pwd\]/libs/ $lm_search_path \n"

      puts $fid "set link_library \[list \\"
      puts $fid "  * \\"
      foreach file $library_file_list {
        puts $fid "  [file tail $file] \\"
      }
      puts $fid "\] \n"

      puts $fid "set target_library \[list \\"
      foreach file $target_library {
        puts $fid "  [file tail $file] \\"
      }
      puts $fid "\] \n"

      foreach reflib_cmd $reflib_cmd_list {
        puts $fid $reflib_cmd
      }
      puts $fid ""

      puts $fid "open_mw_cel -library \[pwd\]/work/$database $options(-design)"
      puts $fid "current_design $options(-design)"
      puts $fid " \n"
      if { $scenario_names(0) != "undefined" } {
        puts $fid "set_active_scenarios -all \n"
        puts $fid " \n"
      }

      ## Need to set TLU+
      for {set x 0} { $x < $num_scenarios } { incr x } {
        set scenario_names($num_scenarios)   $scenario
        if { $scenario_names(0) != "undefined" } {
          puts $fid "current_scenario $scenario_names($x)"
        }
        puts $fid "set_tlu_plus_files \\"
        if { $tlup_lib_max($x) != "undefined" } {
          puts $fid "  -max_tluplus \[pwd\]/libs/[file tail $tlup_lib_max($x)] \\"
        }
        if { $tlup_lib_min($x) != "undefined" } {
          puts $fid "  -min_tluplus \[pwd\]/libs/[file tail $tlup_lib_min($x)] \\"
        }
        if { $tlup_lib_max_emf($x) != "undefined" } {
          puts $fid "  -max_emulation_tluplus \[pwd\]/libs/[file tail $tlup_lib_max_emf($x)] \\"
        }
        if { $tlup_lib_min_emf($x) != "undefined" } {
          puts $fid "  -min_emulation_tluplus \[pwd\]/libs/[file tail $tlup_lib_min_emf($x)] \\"
        }
        if { $tlup_lib_map($x) != "undefined" } {
          puts $fid "  -tech2itf_map \[pwd\]/libs/[file tail $tlup_lib_map($x)] "
        }
        puts $fid "\n"
      }

      puts $fid "## report_mw_lib -mw_reference_library \[pwd\]/work/$database \n"
      puts $fid "## report_tlu_plus_files \n"

    }

  }

  puts $fid "## Insert code to demonstrate STAR here. \n"

  close $fid

  ## -------------------------------------
  ## Create the README file
  ## -------------------------------------

  set filename $dir(star)/README

  set fid [open $filename w]

  puts $fid "\n"
  puts $fid "Date     : STAR assembled on [date] \n"
  puts $fid "Location : STAR created in [pwd] \n"
  puts $fid "Source   : STAR created from $options(-database) \n"
  puts $fid "To reproduce the STAR, load the tool and then execute 'Run' at your shell. \n"
  puts $fid "Example tool versions loading:"
  puts $fid "  module load tool/version \n"
  puts $fid "Read CRM for more info.\n"

  close $fid

  ## -------------------------------------
  ## Create the Run file
  ## -------------------------------------

  set filename $dir(star)/Run

  set fid [open $filename w]

  puts $fid "\n"

  switch $synopsys_program_name {
    dc_shell {
      if { [shell_is_in_topographical_mode] } {
        set extra "-topo"
      } else {
        set extra ""
      }
      puts $fid "dc_shell $extra  -64bit -f ./scripts/the_script.tcl | \\"
      puts $fid "  tee ./logs/the_script.log"
    }
    icc_shell {
      puts $fid "icc_shell -64bit -f ./scripts/the_script.tcl | \\"
      puts $fid "  tee ./logs/the_script.log"
    }
  }

  puts $fid "\n"

  close $fid

  file attributes $filename -permissions ugo+x

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_pkg_star \
      -info "\
      Procedure that assists in packaging a STAR. \
      Supports MW format for icc_shell. \
      Supports DDC format for dc_shell. \
      Note that all logfiles from the flow contain
    useful techlib setup information prefixed \
      with the string SNPS_SETUP. \
  " \
  -define_args {
  {-design     "Design within database from which to create the STAR" AString string required}
  {-database   "Path and filename of database from which to create the STAR (DDC or MW)"   AString string required}
  {-star_name  "Directory in which to package the STAR (default is STAR.tbdNum)" AString string optional}
  {-overwrite  "Overwrite if the STAR directory already exists" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_pkg_misc_library_data:
## -----------------------------------------------------------------------------

proc sproc_pkg_misc_library_data { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name
  global link_library
  global target_library
  global search_path

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-dst) "misc_library_data"
  set options(-allow_overwrite) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Create the STAR directory
  ## -------------------------------------

  if { [file exists $options(-dst)] && ( $options(-allow_overwrite) == 0 ) } {
    sproc_msg -warning "$options(-dst) directory already exists, and -allow_overwrite not specified."
    sproc_pinfo -mode stop
    return
  } else {
    sproc_msg -info "Creating STAR directory."
    file mkdir $options(-dst)
  }

  ## -------------------------------------

  set src_files [list]
  lappend src_files $SVAR(tech,mw_tech_file)
  lappend src_files $SVAR(tech,signal_em_constraints_file)
  lappend src_files $SVAR(tech,map_file_gds_out)

  set scenarios [all_active_scenarios]
  if { [llength $scenarios] > 0 } {
    foreach scenario [all_active_scenarios] {
      current_scenario $scenario
      set tmp [ sproc_icc_map_tlup_to_nxtgrd ]
      if { [ llength $tmp ] == 1 } {
        lappend src_files [ lindex $tmp 0 ]
      } else {
        lappend src_files [ lindex $tmp 0 ]
        lappend src_files [ lindex $tmp 1 ]
      }
    }
  } else {
    set tmp [ sproc_icc_map_tlup_to_nxtgrd ]
    if { [ llength $tmp ] == 1 } {
      lappend src_files [ lindex $tmp 0 ]
    } else {
      lappend src_files [ lindex $tmp 0 ]
      lappend src_files [ lindex $tmp 1 ]
    }
  }

  ## -------------------------------------

  foreach src_file $src_files {

    set dst_file "$options(-dst)/[file tail $src_file]"

    sproc_msg -info " "
    sproc_msg -info "  copying >$src_file<"
    sproc_msg -info "       to >$dst_file<"
    file copy -force $src_file $dst_file

  }

  ## -------------------------------------

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_pkg_misc_library_data \
  -info "Procedure that assists in packaging library data for a STAR." \
  -define_args {
  {-dst  "Directory in which to package the data (default is misc_library_data)" AString string optional}
  {-allow_overwrite  "Allow overwrite if the dst directory or data already exists" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_get_spec_info:
## -----------------------------------------------------------------------------

proc sproc_get_spec_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  parse_proc_arguments -args $args options

  switch $options(-info) {
    lib {
      set return_value [file dirname [file dirname $options(-spec)]]
    }
    cell {
      set return_value [file tail [file dirname $options(-spec)]]
    }
    pin {
      set return_value [file tail $options(-spec)]
    }
    lib_cell {
      set return_value [file dirname $options(-spec)]
    }
    lib_cell_pin {
      set return_value $options(-spec)
    }
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_spec_info \
  -info "Returns info about cell spec" \
  -define_args {
  {-info "Info to return from cell spec" AnOos one_of_string
    {required value_help {values {lib cell pin lib_cell lib_cell_pin}}}
  }
  {-spec "The cell spec" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_get_scenario_info:
## -----------------------------------------------------------------------------

proc sproc_get_scenario_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  parse_proc_arguments -args $args options

  set error_flag 0

  ## Check that the scenario name is properly formatted

  if { ! [regexp {(\w+)\.(\w+)\.(\w+)} $options(-scenario) match mm_type oc_type rc_type] } {
    sproc_msg -error "The scenario name is not of the proper format."
    sproc_msg -error "  -scenario : $options(-scenario)"
    set error_flag 1
  }
  if { [lsearch $SVAR(setup,mm_types_list) $mm_type] == -1 } {
    sproc_msg -issue "There is no longer a strict requirement on modal naming."
    sproc_msg -warning "Invalid scenario name field: $mm_type"
    sproc_msg -warning "Valid values are: $SVAR(setup,mm_types_list)"
    ## set error_flag 1
  }
  if { [lsearch $SVAR(setup,oc_types_list) $oc_type] == -1 } {
    sproc_msg -error "Invalid scenario name field: $oc_type"
    sproc_msg -error "Valid values are: $SVAR(setup,oc_types_list)"
    set error_flag 1
  }
  if { [lsearch $SVAR(setup,rc_types_list) $rc_type] == -1 } {
    sproc_msg -error "Invalid scenario name field: $rc_type"
    sproc_msg -error "Valid values are: $SVAR(setup,rc_types_list)"
    set error_flag 1
  }

  if { $error_flag } {
    set return_value ERROR
  } else {
    switch $options(-type) {
      mm_type { set return_value $mm_type }
      oc_type { set return_value $oc_type }
      rc_type { set return_value $rc_type }
    }
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_scenario_info \
  -info "Returns information about a scenario" \
  -define_args {
  {-scenario "The scenario name" AString string required}
  {-type     "The portion of the scenario name to return" AnOos one_of_string
    {required value_help {values {mm_type oc_type rc_type}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_correlation_paths:
## -----------------------------------------------------------------------------

proc sproc_correlation_paths { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global LYNX

  set options(-max_paths) 100
  parse_proc_arguments -args $args options

  if { $LYNX(regression_testing) && ( $SEV(block_name) == "dhm" ) && ( $SEV(step) != "10_syn" ) } {
    sproc_msg -warning "Development specific modification to get_timing_paths."
    current_scenario mode_norm.OC_WC.RC_MAX_1
    set timing_paths [ \
      get_timing_paths \
      -delay_type max \
      -group clk \
      -max_paths $options(-max_paths) \
      ]
    ## -slack_lesser_than 0.0
  } else {
    set timing_paths [ \
      get_timing_paths \
      -delay_type max \
      -max_paths $options(-max_paths) \
      ]
  }

  set fid [open $options(-script) w]

  set path_count 1

  foreach_in_collection path $timing_paths {
    set startpoint         [get_attribute $path startpoint]
    set endpoint           [get_attribute $path endpoint]
    set startpoint_name    [get_attribute $startpoint full_name]
    set endpoint_name      [get_attribute $endpoint   full_name]

    set points [get_attribute $path points]
    foreach_in_collection point $points {
      set object [get_attribute $point object]
      set point_name [get_attribute $object full_name]
      set point_rise_fall [get_attribute $point rise_fall]
    }
    if { ($point_rise_fall != "rise") && ($point_rise_fall != "fall") } {
      sproc_msg -error "Rise/Fall for endpoint $endpoint_name is unknown. (rise_fall attribute)"
      set point_rise_fall unknown
    }
    if { $endpoint_name != $point_name } {
      sproc_msg -error "Rise/Fall for endpoint $endpoint_name is unknown. (endpoint not equal to last point)"
      set point_rise_fall unknown
    }

    set path_name [format "%08s" $path_count]

    puts $fid "redirect \$RPT_DIR/path.$path_name {"
      puts $fid "  report_timing \\"
      puts $fid "    -delay max \\"
      puts $fid "    -tran -cap -path full_clock -crosstalk_delta \\"
      puts $fid "    -input_pins -nets -crosstalk_delta -derate \\"
      puts $fid "    -significant_digits 4 -nosplit \\"
      puts $fid "    -from $startpoint_name \\"
      switch $point_rise_fall {
        rise {
          puts $fid "    -rise_to $endpoint_name "
        }
        fall {
          puts $fid "    -fall_to $endpoint_name "
        }
        unknown {
          puts $fid "    -to $endpoint_name "
        }
      }
    puts $fid "}\n"

    incr path_count
  }

  close $fid

  sproc_msg -info "[expr $path_count - 1] paths extracted for correlation."

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_correlation_paths \
  -info "Generate paths file for correlation purposes." \
  -define_args {
  {-script "The script to create." AString string required}
  {-max_paths "The number of paths to check." AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_run_atpg:
## -----------------------------------------------------------------------------

proc sproc_run_atpg { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global sh_product_version

  set options(-enable_distributed) 0
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## See if any faults remain to be processed.
  ## Execute the run_atpg command if faults are present.
  ## (If faults are not present, an error message is generated.)
  ## -------------------------------------

  set fault_count 0
  redirect -variable report {
    report_summaries faults
  }
  set lines [split $report "\n"]
  foreach line $lines {
    regexp {^\s*Not detected\s+ND\s+(\d+)} $line match fault_count
  }
  if { $fault_count == 0 } {
    sproc_msg -warning "No ND faults remain to be tested. Skipping the run_atpg command."
    sproc_pinfo -mode stop
    return
  } else {
    sproc_msg -info "The non-detected fault count is currently at $fault_count"
  }

  ## -------------------------------------
  ## Faults are present, so continue with processing.
  ## -------------------------------------

  ##
  ## An error occurs if the fault list is smaller than the number of distributed processors.
  ## Just to be safe, the arbitrary min fault count of 13 is used to disable distribution.
  ##
  if { $options(-enable_distributed) && ($fault_count < 13) } {
    sproc_msg -issue "Disabling distribution for this limited fault list of $fault_count"
    set options(-enable_distributed) 0
  }

  if { $options(-enable_distributed) && ($TEV(num_child_jobs) > 1) && $SEV(job_enable) } {

    switch $SEV(job_app) {
      lsf -
      grd {
        sproc_msg -info "Valid value for SEV(job_app)"
      }
      default {
        sproc_msg -error "Unrecognized value $SEV(job_app) for SEV(job_app)"
        sproc_script_stop -exit
      }
    }

    set atpg_dist_dir $SEV(tmp_dir)/dist_atpg
    file mkdir $atpg_dist_dir
    set_messages -log $atpg_dist_dir/atpg_job.log -replace
    sproc_msg -setup "set_messages -log $atpg_dist_dir/atpg_job.log -replace"
    set_distributed \
      -work_dir $atpg_dist_dir \
      -slave_setup_timeout 1000 \
      -verbose
    sproc_msg -setup "set_distributed \
      -work_dir $atpg_dist_dir \
      -slave_setup_timeout 1000 \
      -verbose"

    switch $SEV(job_app) {
      lsf {
        set app [sproc_which -app bsub]
      }
      grd {
        set app [sproc_which -app qsub]
      }
      default {
        sproc_msg -error "Unrecognized value $SEV(job_app) for SEV(job_app)"
      }
    }

    if { $TEV(distributed_job_args) == "" } {
      set fname [file rootname $SEV(log_file)].rtm_job_cmd
      set job_args [sproc_distributed_job_args -file $fname]
    } else {
      set job_args $TEV(distributed_job_args)
    }

    add_distributed_processors \
      -lsf $app \
      -options $job_args \
      -nslaves $TEV(num_child_jobs)
    sproc_msg -setup "add_distributed_processors \
      -lsf $app \
      -options $job_args \
      -nslaves $TEV(num_child_jobs)"

    report_distributed_processors
    sproc_msg -setup "report_distributed_processors"

    report_settings distributed
    sproc_msg -setup "report_settings distributed"

    run_atpg -auto -distributed
    sproc_msg -setup "run_atpg -auto -distributed"

  } else {

    run_atpg -auto
    sproc_msg -setup "run_atpg -auto"

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_run_atpg \
  -info "Controls TetraMax parallel job execution." \
  -define_args {
  {-enable_distributed "Enable distributed operation" ""  boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_bbox_to_poly:
## -----------------------------------------------------------------------------

proc sproc_bbox_to_poly { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-bbox) ""
  parse_proc_arguments -args $args options

  ## Remove all {} if included
  regsub -all {\{||\}} $options(-bbox) {} options(-bbox)

  if {[llength $options(-bbox)] != 4} {
    sproc_msg -error "Input must be a valid bbox with the four points: lx ly ux uy."
    sproc_pinfo -mode stop
    return
  }

  sproc_msg -info "The input bbox is: $options(-bbox)"
  scan $options(-bbox) "%f %f %f %f" lx ly ux uy
  set return_list "{$lx $ly} {$ux $ly} {$ux $uy} {$lx $uy} {$lx $ly}"
  sproc_msg -info "The output points are: $return_list"

  sproc_pinfo -mode stop
  return $return_list
}

define_proc_attributes sproc_bbox_to_poly \
  -info "Returns polygon points for the input bbox." \
  -define_args {
  {-bbox    "Bounding box coordinates." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_insert_halos:
## -----------------------------------------------------------------------------

proc sproc_insert_halos { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-points) ""
  set options(-outer) 0
  set options(-width) $SVAR(libsetup,site_height)
  set options(-placement) 0
  set options(-route) 0
  set options(-rg_type) "signal"
  set options(-all_layers) 0
  set options(-port_sizing) 0
  set options(-prefix) "HALO"

  parse_proc_arguments -args $args options

  set development_rg_mode 1

  ## -------------------------------------
  ## Perform error checking of inputs.
  ## -------------------------------------

  if { !$options(-placement) && !$options(-route) } {
    sproc_msg -error "Must specify the halo type (i.e. placement/route)."
    sproc_pinfo -mode stop
    return
  }
  if { $options(-width) <= 0 } {
    sproc_msg -error "Must specify a positive width value."
    sproc_pinfo -mode stop
    return
  }

  if { $options(-port_sizing) && $options(-outer) } {
    sproc_msg -error "Cannot specify both -port_sizing and -outer switches."
    sproc_pinfo -mode stop
    return
  }

  if { ($options(-rg_type) != "signal") && ($options(-rg_type) != "preroute") } {
    sproc_msg -error "Must specify either signal or preroute."
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Create rectangles for blockages.
  ## -------------------------------------
  if { $options(-outer) } {
    set halo_width $options(-width)
  } else {
    set halo_width -$options(-width)
  }

  if {[llength $options(-points)] < 5} {
    set points [sproc_bbox_to_poly -bbox $options(-points)]
  } else {
    set points $options(-points)
  }
  set poly $points
  set delta_poly [resize_polygon -size $halo_width $points]

  if { $halo_width >= 0 } {
    set ring [compute_polygons -boolean not $delta_poly $poly]
  } else {
    set ring [compute_polygons -boolean not $poly $delta_poly]
  }
  set rectangles [convert_from_polygon $ring]

  ## -------------------------------------
  ## Create placement blockages.
  ## -------------------------------------

  if { $options(-placement) } {
    set x 0
    foreach rect $rectangles {
      create_placement_blockage -name $options(-prefix)_pb_$x -bbox $rect
      incr x
    }
  }

  if { $development_rg_mode == 0 } {

    ## -------------------------------------
    ## Create route guides.
    ## -------------------------------------

    if { $options(-route) } {

      if { $options(-rg_type) == "signal" } {
        set rg_type "-zero_min_spacing -no_signal_layers"
        set all_layers [sproc_convert_to_metal_layer_name -to $SVAR(route,layer_signal_max)]
      } else {
        set rg_type "-no_preroute_layers"
        set all_layers [sproc_convert_to_metal_layer_name -to $SVAR(route,layer_block_max)]
      }

      set x 0
      if { $options(-all_layers) } {
        ## Create route guides that block all layers.
        foreach rect $rectangles {
          eval create_route_guide -name $options(-prefix)_rg_$x -coordinate {$rect} $rg_type {$all_layers}
          incr x
        }
      } else {
        ## Create route guides for layers on preferred directions only.
        set vertical_layers ""
        set horizontal_layers ""

        ## Determine which layers are horizontal/vertical.
        foreach layer $all_layers {
          if { [sproc_get_preferred_direction -layer_name $layer] == "V" } {
            lappend vertical_layers $layer
          } else {
            lappend horizontal_layers $layer
          }
        }

        foreach rect $rectangles {
          set llx [lindex [lindex $rect 0] 0]
          set lly [lindex [lindex $rect 0] 1]
          set urx [lindex [lindex $rect 1] 0]
          set ury [lindex [lindex $rect 1] 1]

          ## Determine direction of rectangle.  Assuming larger side is direction.
          if { [expr $ury - $lly] > [expr $urx - $llx] } {
            set rect_dir V
          } else {
            set rect_dir H
          }
          ## Create route guides for layers on preferred directions.
          if { $rect_dir == "V" } {
            eval create_route_guide -name $options(-prefix)_rg_$x -coordinate {$rect} ${rg_type} {$vertical_layers}
          } else {
            eval create_route_guide -name $options(-prefix)_rg_$x -coordinate {$rect} ${rg_type} {$horizontal_layers}
          }
          incr x
        }
      }

    }
  }

  ## -------------------------------------
  ## Resize port shapes.
  ## -------------------------------------

  if { $options(-port_sizing) && $options(-route) && !$options(-outer) } {
    foreach rect $rectangles {
      set llx [lindex [lindex $rect 0] 0]
      set lly [lindex [lindex $rect 0] 1]
      set urx [lindex [lindex $rect 1] 0]
      set ury [lindex [lindex $rect 1] 1]

      ## Determine direction of rectangle.  Assuming larger side is direction.
      if { [expr $ury - $lly] > [expr $urx - $llx] } {
        ## Verticle side
        foreach_in_collection port [get_ports] {
          set terminal [get_terminals -of_objects $port]
          scan [get_attribute $terminal bbox] "{%f %f} {%f %f}" terminal_llx terminal_lly terminal_urx terminal_ury
          set terminal_width [expr $terminal_ury - $terminal_lly]
          set terminal_length [expr $terminal_urx - $terminal_llx]
          ## Ports on right side.
          if { $terminal_urx == $urx } {
            set_attribute $terminal bbox_llx [expr $urx - ($options(-width) + $terminal_width)]
          }
          ## Ports on left side.
          if { $terminal_llx == $llx } {
            set_attribute $terminal bbox_urx [expr $llx + ($options(-width) + $terminal_width)]
          }
        }

      } else {
        ## Horizontal side
        foreach_in_collection port [get_ports] {
          set terminal [get_terminals -of_objects $port]
          scan [get_attribute $terminal bbox] "{%f %f} {%f %f}" terminal_llx terminal_lly terminal_urx terminal_ury
          set terminal_width [expr $terminal_urx - $terminal_llx]
          set terminal_length [expr $terminal_ury - $terminal_lly]
          ## Ports on top side.
          if { $terminal_ury == $ury } {
            set_attribute $terminal bbox_lly [expr $ury - ($options(-width) + $terminal_width)]
          }
          ## Ports on bottom side.
          if { $terminal_lly == $lly } {
            set_attribute $terminal bbox_ury [expr $lly + ($options(-width) + $terminal_width)]
          }
        }
      }

    }
  }

  if { $development_rg_mode == 1 } {

    ## -------------------------------------
    ## Create route guides.
    ## -------------------------------------

    if { $options(-route) } {

      if { $options(-rg_type) == "signal" } {
        set all_layers [sproc_convert_to_metal_layer_name -to $SVAR(route,layer_signal_max)]
        set rg_type "-no_signal_layers"
      } else {
        set rg_type "-no_preroute_layers"
        set all_layers [sproc_convert_to_metal_layer_name -to $SVAR(route,layer_block_max)]
      }

      set x 0
      ## Create route guides that block appropriate layers.
      foreach rect1 $rectangles {

        foreach layer $all_layers {

          ## compute scaler for resizing shapes (eg terminals).  the scaler is slightly
          ## greater than x2 minSpacing to account of minSpacing to the left and the right.
          set layer_scaler [expr 2.1 * [get_layer_attribute -layer $layer minSpacing] ]

          ## compute layer preferred_direction
          set layer_preferred_direction [get_layer_attribute -layer $layer preferred_direction]

          ## compute rect1 orientation
          set llx [lindex [lindex $rect1 0] 0]
          set lly [lindex [lindex $rect1 0] 1]
          set urx [lindex [lindex $rect1 1] 0]
          set ury [lindex [lindex $rect1 1] 1]
          if { [expr $ury - $lly] > [expr $urx - $llx] } {
            set rect_orientation vertical
          } else {
            set rect_orientation horizontal
          }

          ## convert rect1 of potential route_guide into a polygon
          set poly1 [sproc_bbox_to_poly -bbox $rect1]
          set poly1_save $poly1

          ## get shapes (eg routes, terminals) intersecting rect1 ... filter out power & ground ...
          set shapes_net_shapes [ get_net_shapes -intersect $rect1 -filter "layer==$layer" -quiet ]
          set shapes_terminals [ get_terminals -intersect $rect1 -filter "layer==$layer" -quiet ]
          set pg_ports [remove_from_collection [get_ports -all *] [get_ports]]
          foreach_in_collection pg_port $pg_ports {
            set pg_net [all_connected $pg_port]
            set pg_port_name [get_attribute $pg_port name]
            set shapes_terminals [ filter_collection $shapes_terminals "owner_port!=$pg_port_name" ]
            set pg_net_name [get_attribute $pg_net name]
            set shapes_net_shapes [ filter_collection $shapes_net_shapes "owner_net!=$pg_net_name" ]
          }
          set shapes_net_shapes [ filter_collection $shapes_net_shapes "net_type!=Power" ]
          set shapes_net_shapes [ filter_collection $shapes_net_shapes "net_type!=Ground" ]
          set shapes [ add_to_collection $shapes_net_shapes $shapes_terminals ]

          ## perform polygon computations ... effectively start w/ original rect1
          ## and "not out" each shape.  each shape is padded by x2 minSpacing prior
          ## to "not out"
          foreach_in_collection shape $shapes {
            set poly2 [ convert_to_polygon $shape ]
            set poly2 [ resize_polygon $poly2 -size $layer_scaler]
            set poly2 [ compute_polygons -boolean and $poly1_save $poly2 ]
            set poly2_not [ compute_polygons -boolean xor $poly1_save $poly2 ]
            set poly1 [ compute_polygons -boolean and $poly1 $poly2_not ]
          }

          ##
          ## occassionally this routine is used to create route_guides for preroutes.
          ## when this is done a lot of times pins aren't yet assigned and other anomolies.
          ## as such some of the computations below fail and we get no route_guides.
          ## the following should detect this situation and force suitable route_guides
          ## to be created.  this should be OK as these route_guides get deleted after
          ## power insertion.  is is thought that when the UI to this proc is cleaned
          ## up we can approach this more robustly.
          ##
          if { ( $options(-rg_type) == "preroute" ) && ( $options(-port_sizing) == 0 ) } {
            set poly1 $poly1_save
          }

          ## create route guides that are contoured around actual routes
          if { [ llength [ lindex $poly1 0 ] ] == 2 } {
            set poly1 "{ $poly1 }"
          }
          foreach tmp_poly1 $poly1 {
            set rect2 [convert_from_polygon $tmp_poly1]
            if { [llength $rect2] == 1 } {
              if { $options(-all_layers) || ( $layer_preferred_direction == $rect_orientation ) } {
                eval create_route_guide -name $options(-prefix)_rg_$x -coordinate $rect2 $rg_type {$layer}
                incr x
              }
            }
          }

        }

      }

    }

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_insert_halos \
  -info "Create a ring of halos around the provided polygon at -width in size" \
  -define_args {
  {-points    "List of point that define the polygon" AString string required}
  {-outer     "Set if you want an outer ring."  "" boolean optional}
  {-width     "Width of halos"  AString string optional}
  {-placement "Set if you want placement blockages created." "" boolean optional}
  {-route     "Set if you want route guides created." "" boolean optional}
  {-rg_type   "Type of route guide.  Valid values are signal/preroute." AString string optional}
  {-all_layers "Set if you want route guides to block all layers." "" boolean optional}
  {-port_sizing "Set if you want to resize ports." "" boolean optional}
  {-prefix    "Prefix for halos" AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_get_drivers:
## -----------------------------------------------------------------------------

proc sproc_get_drivers {args} {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  global synopsys_program_name

  set options(-object_spec) ""
  parse_proc_arguments -args $args options

  ## If it's not a collection, convert into one

  redirect /dev/null {set size [sizeof_collection $options(-object_spec)]}
  if {$size == ""} {
    set objects {}
    foreach name $options(-object_spec) {
      if {[set stuff [get_ports -quiet $name]] == ""} {
        if {[set stuff [get_cells -quiet $name]] == ""} {
          if {[set stuff [get_pins -quiet $name]] == ""} {
            if {[set stuff [get_nets -quiet $name]] == ""} {
              continue
            }
          }
        }
      }
      set objects [add_to_collection $objects $stuff]
    }
  } else {
    set objects $options(-object_spec)
  }

  if {$objects == ""} {
    sproc_msg -error "No objects given"
    sproc_pinfo -mode stop
    return [add_to_collection "" ""]
  }

  set driver_results {}

  ## Process all cells

  if {[set cells [get_cells -quiet $objects]] != ""} {
    ## Add driver pins of these cells
    set driver_results [add_to_collection -unique $driver_results \
      [get_pins -quiet -of $cells -filter "pin_direction == out || pin_direction == inout"]]
  }

  ## Get any nets
  set nets [get_nets -quiet $objects]

  ## Get any pin-connected nets
  if {[set pins [get_pins -quiet $objects]] != ""} {
    set nets [add_to_collection -unique $nets \
      [get_nets -quiet -of $pins]]
  }

  ## Get any port-connected nets
  if {[set ports [get_ports -quiet $objects]] != ""} {
    set nets [add_to_collection -unique $nets \
      [get_nets -quiet -of $ports]]
  }

  ## Process all nets
  if {$nets != ""} {
    ## Add driver pins of these nets
    set driver_results [add_to_collection -unique $driver_results \
      [get_pins -quiet -leaf -of $nets -filter "pin_direction == out || pin_direction == inout"]]
    set driver_results [add_to_collection -unique $driver_results \
      [get_ports -quiet -of $nets -filter "port_direction == in || port_direction == inout"]]
  }

  sproc_pinfo -mode stop
  return $driver_results
}

define_proc_attributes sproc_get_drivers \
  -info "Return driver ports/pins of object" \
  -define_args {
  {-object_spec "Object(s) to report" "object_spec" string required}
}

## -----------------------------------------------------------------------------
## sproc_get_correct_inst_name:
## -----------------------------------------------------------------------------

proc sproc_get_correct_inst_name { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  parse_proc_arguments -args $args options

  set inst_name $options(-inst)

  ## See if the instance name is an exact match.

  set cell [get_cells -quiet $inst_name]

  if { [sizeof_collection $cell] == 1 } {

    ## If so, just return the instance name as is.

    set return_value $inst_name

  } else {

    ## If not, search for a likely alternative.

    set alt_cells [get_cells -hier * -filter "mask_layout_type==macro"]

    regsub -all {/} $inst_name {_} inst_name_new

    set found_flag 0
    foreach_in_collection alt_cell $alt_cells {
      if { !$found_flag } {
        set alt_name [get_attribute $alt_cell full_name]
        regsub -all {/} $alt_name {_} alt_name_new
        if { $inst_name_new == $alt_name_new } {
          set found_flag 1
          set return_value $alt_name
        }
      }
    }

    if { !$found_flag } {
      sproc_msg -error "Unable to resolve instance name $inst_name"
      set return_value CELL_NOT_FOUND
    }

  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_correct_inst_name \
  -info "Used to resolve instance names that may have slightly changed due to hier processing." \
  -define_args {
  {-inst "Instance name" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_dump_shape_off_litho_grid:
## -----------------------------------------------------------------------------

proc sproc_dump_shape_off_litho_grid { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global DEV

  set options(-shapes) ""
  set options(-fname) "./shape_off_litho_grid.rpt"
  parse_proc_arguments -args $args options

  ##
  ## initialization
  ##
  if { $options(-shapes) == "" } {
    sproc_msg -warning "sproc_dump_shape_off_litho_grid: \"-shapes\" == \"\" so attempting to auto identify shapes."
    set nets [ get_nets -hier * ]
    set options(-shapes) [ get_net_shapes -of $nets ]
    set options(-shapes) [ add_to_collection $options(-shapes) [ get_vias -of $nets ] ]
  }
  set myerrors 0
  set mycnt 1
  set mytot [sizeof_collection $options(-shapes)]
  set shapes_off_litho_grid {}
  set mydesign [current_mw_cel]
  set mylib [current_mw_lib]

  if { $mytot == 0 } {
    sproc_msg -warning "sproc_dump_shape_off_litho_grid: There are no shapes to process so exiting."
    sproc_pinfo -mode stop
    return
  }

  ##
  ## figure out unit resolution
  ##
  redirect -var report {
    report_mw_lib -unit_range $mylib
  }

  set units 0
  set lines [split $report "\n"]
  foreach line $lines {
    regexp {^length\s+\S+\s+(\S+)} $line match units
  }
  if {$units == 0} {
    sproc_msg -error "sproc_dump_shape_off_litho_grid: Could not derive units from report_mw_lib output"
    sproc_pinfo -mode stop
    return
  }

  ##
  ## start creating the report
  ##
  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "
  puts $fid " "

  ##
  ## save off current user grid in case it is set to something other than default
  ## set the grid to the litho grid, query grid to get litho grid
  ##
  set old_user_grid [get_user_grid $mydesign]
  set_user_grid -reset $mydesign
  set user_grid [get_user_grid $mydesign]

  set litho_grid_x [lindex $user_grid 1 0]
  set litho_grid_y [lindex $user_grid 1 1]

  set litho_grid_units_x [expr int([expr $litho_grid_x * $units])]
  set litho_grid_units_y [expr int([expr $litho_grid_y * $units])]

  foreach_in_collection shape $options(-shapes) {
    set shape_bbox_llx [get_attribute $shape bbox_llx]
    set shape_bbox_lly [get_attribute $shape bbox_lly]
    set shape_bbox_urx [get_attribute $shape bbox_urx]
    set shape_bbox_ury [get_attribute $shape bbox_ury]

    set shape_bbox_llx_units [expr int([expr $shape_bbox_llx * $units])]
    set shape_bbox_lly_units [expr int([expr $shape_bbox_lly * $units])]
    set shape_bbox_urx_units [expr int([expr $shape_bbox_urx * $units])]
    set shape_bbox_ury_units [expr int([expr $shape_bbox_ury * $units])]

    if { [expr $shape_bbox_llx_units % $litho_grid_units_x] != 0 || \
        [expr $shape_bbox_lly_units % $litho_grid_units_y] != 0 || \
        [expr $shape_bbox_urx_units % $litho_grid_units_x] != 0 || \
        [expr $shape_bbox_ury_units % $litho_grid_units_y] != 0  \
      } {
      append_to_collection shapes_off_litho_grid $shape
      incr myerrors
      puts $fid "litho grid issue detected.  this is error $myerrors."
      puts $fid "   shape = [get_attribute $shape name]"
      puts $fid "   net = [get_attribute $shape owner_net]"
      puts $fid "   bbox = { { $shape_bbox_llx $shape_bbox_lly } { $shape_bbox_urx $shape_bbox_ury } }"
      puts $fid " "
    }
    if {[expr $mycnt % 1000] == 0} {
      sproc_msg -info "sproc_dump_shape_off_litho_grid:   processed $mycnt of $mytot shapes, [date]."
    }
    incr mycnt
  }
  incr mycnt -1
  sproc_msg -info "sproc_dump_shape_off_litho_grid:   processed $mycnt of $mytot shapes, [date]."

  set_user_grid -user_grid $old_user_grid $mydesign

  puts $fid " "
  puts $fid " Grid Information"
  puts $fid "   Original Grid : {$old_user_grid}"
  puts $fid "      Litho Grid : {$user_grid}"
  puts $fid " "

  puts $fid " "
  puts $fid "  Processed $mycnt of $mytot shapes."
  if { ( $myerrors > 0 ) } {
    puts $fid "    $myerrors errors were identified."
  } else {
    puts $fid "    No errors were identified."
  }
  puts $fid " "
  close $fid

  ##
  ## it can be useful (e.g. regression testing) to have a concise error
  ## message in the log file indicating a problem
  ##
  if { [info exists DEV(1109_monitor_off_litho_grid)] && ( $myerrors > 0 ) } {
    sproc_msg -error "$myerrors off litho grid errors detected."
  }

  sproc_pinfo -mode stop
  return $shapes_off_litho_grid

}

define_proc_attributes sproc_dump_shape_off_litho_grid \
  -info "Utility for identify net shapes off litho grid." \
  -define_args {
  {-fname        "File name for the report." AString string  optional}
  {-shapes "A user specified colletion of net shapes to process" "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_ff_info:
## -----------------------------------------------------------------------------

proc sproc_dump_ff_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-include_cts) 0
  set options(-fname) "./ff_status.rpt"
  parse_proc_arguments -args $args options

  sproc_msg -info "Report Generation for FF Info Beginning : [date]"

  ## open FID and create table header
  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "
  puts $fid " "
  puts $fid "                                   IS    CTS"
  puts $fid "     BBOX(LL)        ORIEN PLACED FIXED FIXED DONT_TOUCH REF_NAME              FULL_NAME"

  for {set i 0} {$i <= $options(-include_cts)} {incr i} {

    ## get cells of interest
    if { $i == 1 } {
      puts $fid "      ----------> cts elements from this line down <----------"
      set the_cells [ remove_from_collection [ get_cells -of [ all_fanout -clock_tree ] ] \
        [ all_registers ] ]
      set the_cells [ filter $the_cells "is_hierarchical==false" ]
    } else {
      set the_cells [ all_registers ]
    }
    set the_cells [sort_collection $the_cells full_name]

    ## dump table
    foreach_in_collection the_cell $the_cells {
      set str [ format " %-20s" [get_attribute -quiet $the_cell bbox_ll] ]
      set str [ format "%s %-2s" $str [get_attribute -quiet $the_cell orientation] ]
      set str [ format "%s    %-5s" $str [get_attribute -quiet $the_cell is_placed] ]
      set str [ format "%s %-5s" $str [get_attribute -quiet $the_cell is_fixed] ]
      set str [ format "%s %-5s" $str [get_attribute -quiet $the_cell cts_fixed] ]
      set str [ format "%s  %-5s" $str [get_attribute -quiet $the_cell dont_touch] ]
      set str [ format "%s     %-20s" $str [get_attribute -quiet $the_cell ref_name] ]
      set str [ format "%s %-s " $str [get_attribute -quiet $the_cell full_name] ]
      puts $fid $str
    }
  }
  puts $fid " "
  close $fid

  sproc_msg -info "Report Generation for FF Info Ending    : [date]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dump_ff_info \
  -info "Dump snapshot of misc information (e.g. location, orientation, ref_name, etc.) regarding status of FF." \
  -define_args {
  {-fname        "File name for the report." AString string  optional}
  {-include_cts  "Include CTS elements too " ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_net_pattern_info:
## -----------------------------------------------------------------------------

proc sproc_dump_net_pattern_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-list_nets_with_ids) 0
  set options(-list_nets_without_ids) 0
  set options(-fname) "./net_pattern_info.rpt"
  parse_proc_arguments -args $args options

  ##
  ##
  ##
  sproc_msg -info "Report Generation for Net Pattern Info Beginning : [date]"

  ##
  ## determine net pattern IDs and the # of patterns
  ##
  redirect -variable tmp { report_net_search_pattern -all }
  set lines [split $tmp \n]
  set pattern_ids [list]
  foreach line $lines {
    if { [ regexp {pattern id: } $line ] } {
      lappend pattern_ids [ regsub {pattern id: } $line {} ]
    }
  }

  ##
  ## determine data / information regarding net patterns
  ##
  set ds(total_number_nets_with_ids) 0
  foreach pattern_id $pattern_ids {
    set ds($pattern_id,id) $pattern_id
    set ds($pattern_id,num_nets) [ sizeof_collection [ get_matching_nets_for_pattern -pattern $pattern_id ]  ]
    set ds($pattern_id,the_nets) [ get_matching_nets_for_pattern -pattern $pattern_id ]
    set ds(total_number_nets_with_ids) [ expr $ds(total_number_nets_with_ids) + $ds($pattern_id,num_nets) ]
  }

  ##
  ## determine total # of nets, # nets w/ patterns, # nets wo/ patterns, etc.
  ##
  set ds(total_nets) [ get_nets -hier * ]
  set ds(total_number_nets) [ sizeof_collection $ds(total_nets) ]
  set ds(total_nets_without_ids) [copy_collection $ds(total_nets)]
  foreach pattern_id $pattern_ids {
    set ds(total_nets_without_ids) [ remove_from_collection $ds(total_nets_without_ids) $ds($pattern_id,the_nets) ]
  }
  set ds(total_nets_without_ids) [ sort_collection $ds(total_nets_without_ids) full_name ]
  set ds(total_number_nets_without_ids) [ sizeof_collection $ds(total_nets_without_ids) ]

  ## -------------------------------------
  ## attempting to assess why nets are wo/ patterns.
  ##   -> this logic may not be robust (e.g. as we can only code what we have testcase for)
  ##   -> we are working from a list provide from IG as to why nets may not have patterns.  (this could change)
  ##   -> not all checks are coded
  ##
  ##   type    IG LIST
  ##   ====    =======
  ##           a) Clock nets
  ##           b) Nets synthesized by clock tree synthesis
  ##           c) Nets with a user-defined has_cts_ba attribute
  ##           d) Power or ground nets
  ##     4     e) Constant nets
  ##           f) Logic constants (1’b0 or 1’b1)
  ##     2     g) Ideal nets
  ##     1     h) Dangling nets (no loads)
  ##           i) Nets driven by multiple devices
  ##           j) Tri-state nets
  ##           k) DRC-disabled nets
  ##     3     l) Nets with a dont_touch attribute
  ##
  ##    98     logical nets connected to another net w/ a pattern id
  ## -------------------------------------

  ## type #1 check ... dangling nets
  set ds(type99,the_nets) [ copy_collection $ds(total_nets_without_ids) ]
  set ds(type1,the_nets) [add_to_collection "" ""]
  foreach_in_collection the_net $ds(type99,the_nets) {
    if { [ sizeof_collection [ all_connected [ all_connected $the_net ] ] ] == 0 } {
      set ds(type1,the_nets) [add_to_collection $ds(type1,the_nets) $the_net]
      set ds(type99,the_nets) [remove_from_collection $ds(type99,the_nets) $the_net]
    }
  }
  set ds(type1,number_of_nets)  [sizeof_collection $ds(type1,the_nets)]
  set ds(type99,number_of_nets) [sizeof_collection $ds(type99,the_nets)]

  ## type #2 check ... ideal nets
  set ds(type2,the_nets) [add_to_collection "" ""]
  foreach_in_collection the_net $ds(type99,the_nets) {
    if { [ get_attribute $the_net ideal_net ] == "true" } {
      set ds(type2,the_nets) [add_to_collection $ds(type2,the_nets) $the_net]
      set ds(type99,the_nets) [remove_from_collection $ds(type99,the_nets) $the_net]
    }
  }
  set ds(type2,number_of_nets)  [sizeof_collection $ds(type2,the_nets)]

  ## type #3 check ... dont touch
  set ds(type3,the_nets) [add_to_collection "" ""]
  foreach_in_collection the_net $ds(type99,the_nets) {
    if { [ get_attribute $the_net dont_touch ] == "true" } {
      set ds(type3,the_nets) [add_to_collection $ds(type3,the_nets) $the_net]
      set ds(type99,the_nets) [remove_from_collection $ds(type99,the_nets) $the_net]
    }
  }
  set ds(type3,number_of_nets)  [sizeof_collection $ds(type3,the_nets)]

  ## type #4 check ... case value
  set ds(type4,the_nets) [add_to_collection "" ""]
  foreach_in_collection the_net $ds(type99,the_nets) {
    set the_driver [filter_collection [all_connectivity_fanin -to [get_nets $the_net ] -flat -levels 1] "direction==out"]
    if { ( [ get_attribute $the_driver case_value ] == "0" ) || ( [ get_attribute $the_driver case_value ] == "1" ) } {
      set ds(type4,the_nets) [add_to_collection $ds(type4,the_nets) $the_net]
      set ds(type99,the_nets) [remove_from_collection $ds(type99,the_nets) $the_net]
    }
  }
  set ds(type4,number_of_nets)  [sizeof_collection $ds(type4,the_nets)]

  ## type #98 check for logical hier nets aliased to another name
  set ds(type98,the_nets) [add_to_collection "" ""]
  foreach_in_collection the_net $ds(type99,the_nets) {
    foreach_in_collection the_pin [ all_connected $the_net ] {
      if { ( [ get_attribute $the_pin is_hierarchical ] == true ) } {
        set the_net2 [all_connected $the_pin]
        set the_net2_full_name [get_attribute $the_net2 full_name]
        foreach pattern_id $pattern_ids {
          set collection1 [filter_collection $ds($pattern_id,the_nets) "full_name==$the_net2_full_name"]
          if { [sizeof_collection $collection1] == 1 } {
            set ds(type98,the_nets) [add_to_collection $ds(type98,the_nets) $the_net]
            set ds(type99,the_nets) [remove_from_collection $ds(type99,the_nets) $the_net]
            break
          }
        }
      }
    }
  }
  set ds(type98,number_of_nets)  [sizeof_collection $ds(type98,the_nets)]

  set ds(type99,number_of_nets) [sizeof_collection $ds(type99,the_nets)]

  ##
  ## open FID and create table header
  ##
  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "
  puts $fid " "
  puts $fid [ format "   %6d nets are associated with pattern ids " $ds(total_number_nets_with_ids) ]
  puts $fid [ format "   %6d nets are not associated with pattern ids "  $ds(total_number_nets_without_ids) ]
  puts $fid [ format "       %6d type1  (e.g. unconnected nets) "  $ds(type1,number_of_nets) ]
  puts $fid [ format "       %6d type2  (e.g. ideal_net nets) "  $ds(type2,number_of_nets) ]
  puts $fid [ format "       %6d type3  (e.g. dont_touch nets) "  $ds(type3,number_of_nets) ]
  puts $fid [ format "       %6d type4  (e.g. case_value nets) "  $ds(type4,number_of_nets) ]
  puts $fid [ format "       %6d type98 (e.g. logical net connected to a another net w/ a pattern id) "  $ds(type98,number_of_nets) ]
  puts $fid [ format "       %6d type99 (e.g. unknown reason) "  $ds(type99,number_of_nets) ]
  puts $fid " "
  puts $fid " Pattern     #"
  puts $fid "   ID      Nets"
  puts $fid "  ----    ------"

  ## dump table
  foreach pattern_id $pattern_ids {
    set str [ format "  %3d" $ds($pattern_id,id) ]
    set str [ format "%s     %6d" $str $ds($pattern_id,num_nets) ]
    puts $fid $str
  }
  puts $fid " "

  if { $options(-list_nets_with_ids) } {

    ## nets w/ pattern ids
    foreach pattern_id $pattern_ids {
      puts $fid "  $ds($pattern_id,num_nets) nets with Pattern ID: $ds($pattern_id,id)"
      foreach the_net [get_attribute $ds($pattern_id,the_nets) full_name] {
        puts $fid "   $the_net"
      }
      puts $fid ""
    }

  }

  if { $options(-list_nets_without_ids) } {

    ## nets wo/ pattern ids of type1 (unloaded)
    puts $fid "  $ds(type1,number_of_nets) nets without Pattern ID of type1 (i.e. wo/ loads)"
    foreach the_net [get_attribute $ds(type1,the_nets) full_name] {
      puts $fid "   $the_net"
    }
    puts $fid ""

    ## nets wo/ pattern ids of type2 (ideal_net)
    puts $fid "  $ds(type2,number_of_nets) nets without Pattern ID of type2 (i.e. ideal_net)"
    foreach the_net [get_attribute $ds(type2,the_nets) full_name] {
      puts $fid "   $the_net"
    }
    puts $fid ""

    ## nets wo/ pattern ids of type3 (dont_touch)
    puts $fid "  $ds(type3,number_of_nets) nets without Pattern ID of type3 (i.e. dont_touch)"
    foreach the_net [get_attribute $ds(type3,the_nets) full_name] {
      puts $fid "   $the_net"
    }
    puts $fid ""

    ## nets wo/ pattern ids of type4 (case_value)
    puts $fid "  $ds(type4,number_of_nets) nets without Pattern ID of type4 (i.e. case_value)"
    foreach the_net [get_attribute $ds(type4,the_nets) full_name] {
      puts $fid "   $the_net"
    }
    puts $fid ""

    ## nets wo/ pattern ids and unknown type
    puts $fid "  $ds(type99,number_of_nets) nets without Pattern ID and of an unknown type99 (i.e. unknown reason)"
    foreach the_net [get_attribute $ds(type99,the_nets) full_name] {
      puts $fid "   $the_net"
    }
    puts $fid ""

  }
  close $fid

  sproc_msg -info "Report Generation for Net Pattern Info Ending    : [date]"

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_dump_net_pattern_info \
  -info "Dump misc information regarding net patterns." \
  -define_args {
  {-fname                 "File name for the report." AString string  optional}
  {-list_nets_with_ids    "List nets in each net pattern id" ""      boolean optional}
  {-list_nets_without_ids "List nets without net pattern id" ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_icg_info:
## -----------------------------------------------------------------------------

proc sproc_dump_icg_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-undefined) 0
  set options(-fname) "./icg_status.rpt"
  parse_proc_arguments -args $args options

  sproc_msg -warning "Note \"sproc_dump_icg_info\" is still development so robustness TBD."
  ##
  ## known issue for consideration
  ##   - how to deal w/ CT buffers on output of ICGs post CTS, if @ all
  ##

  sproc_msg -info "Report Generation for ICG Info Beginning : [date]"

  ## get cells of interest
  set the_icgs [ get_cells -hier * -filter "clock_gating_integrated_cell!=\"\"" ]
  set the_icgs [ filter_collection $the_icgs "within_block_abstraction!=true" ]
  set the_icgs [sort_collection $the_icgs full_name]

  set num_icgs 0
  foreach_in_collection the_icg $the_icgs {

    set ds($num_icgs,the_icg) $the_icg
    set ds($num_icgs,icg_name) [get_attribute -quiet $the_icg full_name]
    set ds($num_icgs,icg_en_pin) [ get_pins -of $the_icg -filter "clock_gate_enable_pin==true" ]
    set slacks [ get_attribute [ get_timing_path -through $ds($num_icgs,icg_en_pin) -scenarios [all_active_scenarios] ] slack ]
    set ds($num_icgs,icg_en_slack) [ lindex $slacks 0 ]
    for { set i 1 } { $i < [llength $slacks] } { incr i } {
      if { [ lindex $slacks $i ] < $ds($num_icgs,icg_en_slack) } {
        set ds($num_icgs,icg_en_slack) [ lindex $slacks $i ]
      }
    }
    set ds($num_icgs,icg_output_pins) [ get_pins -of $the_icg -filter "direction==out" ]
    set ds($num_icgs,icg_loads) [ sort_collection [ all_fanout -from $ds($num_icgs,icg_output_pins) -flat -levels 1 ] full_name ]
    set ds($num_icgs,icg_num_loads) [sizeof_collection $ds($num_icgs,icg_loads)]
    set ds($num_icgs,loads_bbox_llx) [get_attribute $the_icg bbox_llx]
    set ds($num_icgs,loads_bbox_lly) [get_attribute $the_icg bbox_lly]
    set ds($num_icgs,loads_bbox_urx) [get_attribute $the_icg bbox_urx]
    set ds($num_icgs,loads_bbox_ury) [get_attribute $the_icg bbox_ury]
    set ds($num_icgs,loads_bbox_ury) [get_attribute $the_icg bbox_ury]
    foreach_in_collection the_load $ds($num_icgs,icg_loads) {
      set the_load_llx [get_attribute $the_load bbox_llx]
      set the_load_lly [get_attribute $the_load bbox_lly]
      set the_load_urx [get_attribute $the_load bbox_urx]
      set the_load_ury [get_attribute $the_load bbox_ury]
      if { $the_load_llx < $ds($num_icgs,loads_bbox_llx) } {
        set ds($num_icgs,loads_bbox_llx) $the_load_llx
      }
      if { $the_load_lly < $ds($num_icgs,loads_bbox_lly) } {
        set ds($num_icgs,loads_bbox_lly) $the_load_lly
      }
      if { $the_load_urx > $ds($num_icgs,loads_bbox_urx) } {
        set ds($num_icgs,loads_bbox_urx) $the_load_urx
      }
      if { $the_load_ury > $ds($num_icgs,loads_bbox_ury) } {
        set ds($num_icgs,loads_bbox_ury) $the_load_ury
      }
    }
    set ds($num_icgs,loads_bbox_width)  [expr $ds($num_icgs,loads_bbox_urx) - $ds($num_icgs,loads_bbox_llx)]
    set ds($num_icgs,loads_bbox_height) [expr $ds($num_icgs,loads_bbox_ury) - $ds($num_icgs,loads_bbox_lly)]
    set ds($num_icgs,loads_bbox_area)   [expr $ds($num_icgs,loads_bbox_width) * $ds($num_icgs,loads_bbox_height)]

    incr num_icgs

  }

  ## compute some averages
  set ds(ave,icg_num_loads)     0
  set ds(ave,icg_en_slack)      0
  set ds(ave,loads_bbox_width)  0
  set ds(ave,loads_bbox_height) 0
  set ds(ave,loads_bbox_area)   0
  for {set i 0} {$i<$num_icgs} {incr i} {
    set ds(ave,icg_num_loads)     [expr $ds(ave,icg_num_loads)     + $ds($i,icg_num_loads)    ]
    if { $ds($i,icg_en_slack) == "" } {
    } else {
      set ds(ave,icg_en_slack)      [expr $ds(ave,icg_en_slack)      + $ds($i,icg_en_slack)    ]
    }
    set ds(ave,loads_bbox_width)  [expr $ds(ave,loads_bbox_width)  + $ds($i,loads_bbox_width) ]
    set ds(ave,loads_bbox_height) [expr $ds(ave,loads_bbox_height) + $ds($i,loads_bbox_height)]
    set ds(ave,loads_bbox_area)   [expr $ds(ave,loads_bbox_area)   + $ds($i,loads_bbox_area)]
  }
  set ds(ave,icg_num_loads)     [expr $ds(ave,icg_num_loads)     / double( $num_icgs )]
  set ds(ave,icg_en_slack)      [expr $ds(ave,icg_en_slack)      / $num_icgs]
  set ds(ave,loads_bbox_width)  [expr $ds(ave,loads_bbox_width)  / $num_icgs]
  set ds(ave,loads_bbox_height) [expr $ds(ave,loads_bbox_height) / $num_icgs]
  set ds(ave,loads_bbox_area)   [expr $ds(ave,loads_bbox_area)   / $num_icgs]

  ## compute some mins
  set delta 0.000000001
  set ds(min,icg_num_loads)     [expr $ds(ave,icg_num_loads)     + $delta]
  set ds(min,icg_en_slack)      [expr $ds(ave,icg_en_slack)      + $delta]
  set ds(min,loads_bbox_width)  [expr $ds(ave,loads_bbox_width)  + $delta]
  set ds(min,loads_bbox_height) [expr $ds(ave,loads_bbox_height) + $delta]
  set ds(min,loads_bbox_area)   [expr $ds(ave,loads_bbox_area)   + $delta]
  set ds(min,icg_en_slack_icg_name) ""
  set ds(max,icg_num_loads)     [expr $ds(ave,icg_num_loads)     - $delta]
  set ds(max,icg_en_slack)      [expr $ds(ave,icg_en_slack)      - $delta]
  set ds(max,loads_bbox_width)  [expr $ds(ave,loads_bbox_width)  - $delta]
  set ds(max,loads_bbox_height) [expr $ds(ave,loads_bbox_height) - $delta]
  set ds(max,loads_bbox_area)   [expr $ds(ave,loads_bbox_area)   - $delta]
  set ds(max,icg_en_slack_icg_name) ""
  for {set i 0} {$i<$num_icgs} {incr i} {
    if { $ds(min,icg_num_loads) > $ds($i,icg_num_loads) } {
      set ds(min,icg_num_loads) $ds($i,icg_num_loads)
      set ds(min,icg_num_loads_icg_name) $ds($i,icg_name)
    }
    if { $ds(max,icg_num_loads) < $ds($i,icg_num_loads) } {
      set ds(max,icg_num_loads) $ds($i,icg_num_loads)
      set ds(max,icg_num_loads_icg_name) $ds($i,icg_name)
    }

    if { $ds(min,icg_en_slack) > $ds($i,icg_en_slack) } {
      set ds(min,icg_en_slack) $ds($i,icg_en_slack)
      set ds(min,icg_en_slack_icg_name) $ds($i,icg_name)
    }
    if { $ds(max,icg_en_slack) < $ds($i,icg_en_slack) } {
      set ds(max,icg_en_slack) $ds($i,icg_en_slack)
      set ds(max,icg_en_slack_icg_name) $ds($i,icg_name)
    }

    if { $ds(min,loads_bbox_width) > $ds($i,loads_bbox_width) } {
      set ds(min,loads_bbox_width) $ds($i,loads_bbox_width)
      set ds(min,loads_bbox_width_icg_name) $ds($i,icg_name)
    }
    if { $ds(max,loads_bbox_width) < $ds($i,loads_bbox_width) } {
      set ds(max,loads_bbox_width) $ds($i,loads_bbox_width)
      set ds(max,loads_bbox_width_icg_name) $ds($i,icg_name)
    }

    if { $ds(min,loads_bbox_height) > $ds($i,loads_bbox_height) } {
      set ds(min,loads_bbox_height) $ds($i,loads_bbox_height)
      set ds(min,loads_bbox_height_icg_name) $ds($i,icg_name)
    }
    if { $ds(max,loads_bbox_height) < $ds($i,loads_bbox_height) } {
      set ds(max,loads_bbox_height) $ds($i,loads_bbox_height)
      set ds(max,loads_bbox_height_icg_name) $ds($i,icg_name)
    }

    if { $ds(min,loads_bbox_area) > $ds($i,loads_bbox_area) } {
      set ds(min,loads_bbox_area) $ds($i,loads_bbox_area)
      set ds(min,loads_bbox_area_icg_name) $ds($i,icg_name)
    }
    if { $ds(max,loads_bbox_area) < $ds($i,loads_bbox_area) } {
      set ds(max,loads_bbox_area) $ds($i,loads_bbox_area)
      set ds(max,loads_bbox_area_icg_name) $ds($i,icg_name)
    }
  }

  ## -------------------------------------

  ## open FID and create table header
  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "

  ## dump table of basic ICG info
  puts $fid " "
  puts $fid "                                   IS    CTS"
  puts $fid "     BBOX(LL)        ORIEN PLACED FIXED FIXED DONT_TOUCH  SLACK       REF_NAME             FULL_NAME (ICG)"
  for {set i 0} {$i<$num_icgs} {incr i} {
    set the_icg $ds($i,the_icg)
    set str [ format " %-20s" [get_attribute -quiet $the_icg bbox_ll] ]
    set str [ format "%s %-2s" $str [get_attribute -quiet $the_icg orientation] ]
    set str [ format "%s    %-5s" $str [get_attribute -quiet $the_icg is_placed] ]
    set str [ format "%s %-5s" $str [get_attribute -quiet $the_icg is_fixed] ]
    set str [ format "%s %-5s" $str [get_attribute -quiet $the_icg cts_fixed] ]
    set str [ format "%s  %-5s" $str [get_attribute -quiet $the_icg dont_touch] ]
    if { $ds($i,icg_en_slack) == "" } {
      set str [ format "%s            " $str ]
    } else {
      set str [ format "%s     %7.3f" $str $ds($i,icg_en_slack) ]
    }
    set str [ format "%s     %-20s" $str [get_attribute -quiet $the_icg ref_name] ]
    set str [ format "%s %-s " $str [get_attribute -quiet $the_icg full_name] ]
    puts $fid $str
  }

  ## dump table of advanced ICG info including loads

  puts $fid " "
  puts $fid "      ----------> dumping advanced ICG info from this line down <----------"
  puts $fid " "
  puts $fid " ICG> LOADS \[ BBOX_LOADS \] \[ BBOX_WIDTH BBOX_HEIGHT \] BBOX_AREA FULL_NAME(ICG)"
  puts $fid " "
  puts $fid "                                      IS    CTS"
  puts $fid "        BBOX(LL)        ORIEN PLACED FIXED FIXED DONT_TOUCH REF_NAME              FULL_NAME (Load)"
  puts $fid " "

  for {set i 0} {$i<$num_icgs} {incr i} {

    set str [ format " ICG>" ]
    set str [ format "%s %d " $str $ds($i,icg_num_loads) ]
    set str [ format "%s \[ %5.3f %5.3f %5.3f %5.3f \] " $str $ds($i,loads_bbox_llx) $ds($i,loads_bbox_lly) $ds($i,loads_bbox_urx) $ds($i,loads_bbox_ury) ]
    set str [ format "%s \[ %5.3f %5.3f \] " $str $ds($i,loads_bbox_width) $ds($i,loads_bbox_height) ]
    set str [ format "%s \[ %11.3f \] " $str $ds($i,loads_bbox_area) ]
    set str [ format "%s %-s " $str $ds($i,icg_name) ]
    puts $fid $str

    foreach_in_collection the_load $ds($i,icg_loads) {
      set the_cell [get_cell [get_attribute $the_load cell_name]]
      set str [ format "  " ]
      set str [ format "%s %-20s" $str [get_attribute -quiet $the_cell bbox_ll] ]
      set str [ format "%s %-2s" $str [get_attribute -quiet $the_cell orientation] ]
      set str [ format "%s    %-5s" $str [get_attribute -quiet $the_cell is_placed] ]
      set str [ format "%s %-5s" $str [get_attribute -quiet $the_cell is_fixed] ]
      set str [ format "%s %-5s" $str [get_attribute -quiet $the_cell cts_fixed] ]
      set str [ format "%s  %-5s" $str [get_attribute -quiet $the_cell dont_touch] ]
      set str [ format "%s     %-20s" $str [get_attribute -quiet $the_cell ref_name] ]
      set str [ format "%s %-s " $str [get_attribute -quiet $the_cell full_name] ]
      puts $fid $str
    }

    puts $fid " "

  }

  puts $fid "      ----------> dumping advanced ICG summary info from this line down <----------"
  puts $fid " "
  puts $fid "    # ICGs analyzed : $num_icgs "
  puts $fid " "
  puts $fid "        ICG EN Slack "
  if { ( $ds(ave,icg_en_slack) == 0 ) && ( ( $ds(min,icg_en_slack_icg_name) == "" ) || ( $ds(max,icg_en_slack_icg_name) == "" ) ) } {
    puts $fid "                Ave : "
    puts $fid "                Min : "
    puts $fid "                Max : "
  } else {
    puts $fid "                Ave : [ format "%7.3f " $ds(ave,icg_en_slack) ]"
    puts $fid "                Min : [ format "%7.3f %s " $ds(min,icg_en_slack) $ds(min,icg_en_slack_icg_name) ] "
    puts $fid "                Max : [ format "%7.3f %s " $ds(max,icg_en_slack) $ds(max,icg_en_slack_icg_name) ] "
  }
  puts $fid " "
  puts $fid "     Number of Loads "
  puts $fid "                Ave : [ format "%7.3f " $ds(ave,icg_num_loads) ]"
  puts $fid "                Min : [ format "%7.3f %s " $ds(min,icg_num_loads) $ds(min,icg_num_loads_icg_name) ] "
  puts $fid "                Max : [ format "%7.3f %s " $ds(max,icg_num_loads) $ds(max,icg_num_loads_icg_name) ] "
  puts $fid " "
  puts $fid "    Loads BBOX Width"
  puts $fid "                Ave : [ format "%7.3f " $ds(ave,loads_bbox_width) ]"
  puts $fid "                Min : [ format "%7.3f %s " $ds(min,loads_bbox_width)  $ds(min,loads_bbox_width_icg_name) ] "
  puts $fid "                Max : [ format "%7.3f %s " $ds(max,loads_bbox_width)  $ds(max,loads_bbox_width_icg_name) ] "
  puts $fid " "
  puts $fid "   Loads BBOX Height"
  puts $fid "                Ave : [ format "%7.3f " $ds(ave,loads_bbox_height) ]"
  puts $fid "                Min : [ format "%7.3f %s " $ds(min,loads_bbox_height)  $ds(min,loads_bbox_height_icg_name) ] "
  puts $fid "                Max : [ format "%7.3f %s " $ds(max,loads_bbox_height)  $ds(max,loads_bbox_height_icg_name) ] "
  puts $fid " "
  puts $fid "     Loads BBOX Area"
  puts $fid "                Ave : [ format "%11.3f " $ds(ave,loads_bbox_area) ]"
  puts $fid "                Min : [ format "%11.3f %s " $ds(min,loads_bbox_area)  $ds(min,loads_bbox_area_icg_name) ] "
  puts $fid "                Max : [ format "%11.3f %s " $ds(max,loads_bbox_area)  $ds(max,loads_bbox_area_icg_name) ] "
  puts $fid " "
  close $fid

  sproc_msg -info "Report Generation for ICG Info Ending    : [date]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dump_icg_info \
  -info "Dump snapshot of misc information (e.g. location, orientation, ref_name, etc.) regarding status of icg." \
  -define_args {
  {-fname        "File name for the report." AString string  optional}
  {-unused       "Currently Unused " ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_cts_route_info:
## -----------------------------------------------------------------------------

proc sproc_dump_cts_route_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-fname) "./cts_route_status.rpt"
  parse_proc_arguments -args $args options

  sproc_msg -info "Report Generation for CTS Route Info Beginning : [date]"

  ##
  ## Gather information and compute stats about netshapes
  ##
  ## Note some trickery w/r/t to getting valid CTS pins,
  ## as objects globbed @ a chip level can cause down
  ## stream failures ... hence restricting pin set to
  ## those items that appear to be std cells.
  ##

  set ct_pins [all_fanout -clock_tree]
  set ct_cells [get_cells -of $ct_pins]
  set ct_cells_std [filter $ct_cells "mask_layout_type==std"]
  set ct_cells_not_std [remove_from_collection $ct_cells $ct_cells_std]
  set ct_pins_valid [remove_from_collection $ct_pins [get_pins -of $ct_cells_not_std]]

  ## alpha numeric sort, make sure unique collection, and real
  set the_nets [ sort_collection [ get_nets -of $ct_pins_valid ] full_name ]
  set the_nets_names [ collection_to_list $the_nets -name_only -no_braces ]
  set the_nets_names [ sproc_uniquify_list -list $the_nets_names ]
  set the_nets [ get_nets $the_nets_names ]
  set the_nets [ filter_collection $the_nets "number_of_wires>0" ]

  set ds(ns) [ get_net_shapes -of $the_nets ]
  set ds(ns_number) [ sizeof_collection $ds(ns) ]
  set ds(via) [ get_vias -of [ get_nets -of $ct_pins_valid ] ]
  set ds(via_number) [ sizeof_collection $ds(via) ]

  if { ( $ds(via_number) != 0 ) && ( $ds(ns_number) == 0 ) } {

    sproc_msg -info "sproc_dump_cts_route_info: ICGR appears to be present, proceeding accordingly."
    sproc_msg -warning "Work in progress and hence no functionality"

    set dr 0
    set via 1

  } elseif { ( $ds(via_number) != 0 ) && ( $ds(ns_number) != 0 ) } {

    sproc_msg -warning "sproc_dump_cts_route_info: DR appears to be present, proceeding accordingly."

    set dr 1
    set via 1

  } else {

    sproc_msg -warning "sproc_dump_cts_route_info: no CTS route info identified, aborting."

    set dr 0
    set via 0

  }

  ##
  ## perform dr analysis
  ##
  if { $dr } {

    set ds(length) 0.0
    set layers [ sproc_convert_to_metal_layer_name ]
    foreach layer $layers {

      set ds($layer,ns) [ filter $ds(ns) "layer == $layer" ]
      set ds($layer,number) [ sizeof_collection $ds($layer,ns) ]

      ## gather information
      foreach orientation "HWIRE VWIRE" {
        set ds($layer,$orientation,ns) [ filter $ds($layer,ns) "object_type == $orientation" ]
        set ds($layer,$orientation,number) [ sizeof_collection $ds($layer,$orientation,ns) ]
        set ds($layer,$orientation,length) 0
        foreach_in_collection ns $ds($layer,$orientation,ns) {
          set ds($layer,$orientation,length) [expr $ds($layer,$orientation,length) + [get_attribute $ns length] ]
        }
      }

      set ds($layer,length) [expr $ds($layer,HWIRE,length) + $ds($layer,VWIRE,length) ]
      set ds(length) [expr $ds(length) + $ds($layer,length)]
      if { $ds($layer,length) > 0.0 } {
        set ds($layer,HWIRE,length,percent) [expr 100.0 * $ds($layer,HWIRE,length) / $ds($layer,length) ]
        set ds($layer,VWIRE,length,percent) [expr 100.0 * $ds($layer,VWIRE,length) / $ds($layer,length) ]
      } else {
        set ds($layer,HWIRE,length,percent) 0.0
        set ds($layer,VWIRE,length,percent) 0.0
      }
      if { $ds($layer,number) > 0 } {
        set ds($layer,HWIRE,number,percent) [expr 100.0 * $ds($layer,HWIRE,number) / $ds($layer,number) ]
        set ds($layer,VWIRE,number,percent) [expr 100.0 * $ds($layer,VWIRE,number) / $ds($layer,number) ]
      } else {
        set ds($layer,HWIRE,number,percent) 0.0
        set ds($layer,VWIRE,number,percent) 0.0
      }

    }

    ## compute composite statistics for layer
    foreach layer $layers {
      set ds($layer,length,percent) [expr 100.0 * $ds($layer,length) / $ds(length) ]
      set ds($layer,number,percent) [expr 100.0 * $ds($layer,number) / $ds(ns_number) ]
    }

  }

  ##
  ## perform via analysis
  ##
  if { $via } {
    ## technology via_layer info
    set via_layers [ get_layers * ]
    set via_layers [ filter $via_layers "is_routing_layer==true" ]
    set via_layers [ filter $via_layers "layer_type==via" ]

    ## statistics of via_layer of design
    foreach_in_collection via_layer $via_layers {
      set via_layer_name [get_attribute $via_layer full_name]
      set ds($via_layer_name,via) [filter_collection $ds(via) "via_layer==$via_layer_name"]
      set ds($via_layer_name,number) [sizeof_collection $ds($via_layer_name,via) ]
      set ds($via_layer_name,number,percent) [ expr 100.0 * $ds($via_layer_name,number) / $ds(via_number) ]
    }
  }

  ##
  ## report generation
  ##
  if { $via || $dr } {
    ## open FID and create table header
    set fid [open $options(-fname) w]
    puts $fid " "
    puts $fid " Report generated on [date] "
  }

  ##
  if { $dr } {
    puts $fid " "
    puts $fid "                   NETSHAPE LENGTH"
    puts $fid " LAYER      TOTAL (  %  ) /    HORIZ (  %  ) /    VERTI (  %  )  "
    foreach layer $layers {
      set str [ format "  %-4s" $layer ]
      set str [ format "%s %10.2f" $str $ds($layer,length) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,length,percent) ]
      set str [ format "%s %10.2f" $str $ds($layer,HWIRE,length) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,HWIRE,length,percent) ]
      set str [ format "%s %10.2f" $str $ds($layer,VWIRE,length) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,VWIRE,length,percent) ]
      puts $fid $str
    }
    set str [ format "       %10.2f " $ds(length) ]
    puts $fid $str

    puts $fid " "
    puts $fid "                    # NETSHAPES"
    puts $fid " LAYER      TOTAL (  %  ) /    HORIZ (  %  ) /    VERTI (  %  )  "
    foreach layer $layers {
      set str [ format "  %-4s" $layer ]
      set str [ format "%s %10.0f" $str $ds($layer,number) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,number,percent) ]
      set str [ format "%s %10.0f" $str $ds($layer,HWIRE,number) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,HWIRE,number,percent) ]
      set str [ format "%s %10.0f" $str $ds($layer,VWIRE,number) ]
      set str [ format "%s (%5.2f)" $str $ds($layer,VWIRE,number,percent) ]
      puts $fid $str
    }
    set str [ format "       %10.0f " $ds(ns_number) ]
    puts $fid $str
  }

  if { $via } {
    puts $fid " "
    puts $fid "    # VIA_LAYERS"
    puts $fid " LAYER      TOTAL (  %  ) "
    foreach_in_collection via_layer $via_layers {
      set via_layer_name [get_attribute $via_layer full_name]
      set ds($via_layer_name,number,percent)
      set str [ format "  %-4s" $via_layer_name ]
      set str [ format "%s %10.0f" $str $ds($via_layer_name,number) ]
      set str [ format "%s (%5.2f)" $str $ds($via_layer_name,number,percent) ]
      puts $fid $str
    }
    set str [ format "       %10.0f " $ds(via_number) ]
    puts $fid $str
    puts $fid " "
  }

  if { $via && !$dr } {
    puts $fid " "
    puts $fid "   GROUTE     X       Y       NUM     NUM "
    puts $fid "   LENGTH   LENGTH  LENGTH    PINS   WIRES    NAME "
    foreach_in_collection the_net $the_nets {
      set str [ format " %8.3f" [get_attribute -quiet $the_net groute_length] ]
      set x_length [get_attribute -quiet $the_net x_length]
      if { $x_length == "" } {
        set str [ format "%s        " $str ]
      } else {
        set str [ format "%s %7d" $str $x_length ]
      }
      set y_length [get_attribute -quiet $the_net y_length]
      if { $y_length == "" } {
        set str [ format "%s        " $str ]
      } else {
        set str [ format "%s %7d" $str $y_length ]
      }
      set str [ format "%s %7d" $str [get_attribute -quiet $the_net num_pins] ]
      set str [ format "%s %7d" $str [get_attribute -quiet $the_net number_of_wires] ]
      set str [ format "%s   %-s " $str [get_attribute -quiet $the_net full_name] ]
      puts $fid $str
    }
    puts $fid " "
  }

  if { $via || $dr } {
    close $fid
  }

  sproc_msg -info "Report Generation for CTS Route Info Ending    : [date]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dump_cts_route_info \
  -info "Dump snapshot of cts route information." \
  -define_args {
  {-fname        "File name for the report."                      AString string  optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_port_info:
## -----------------------------------------------------------------------------

proc sproc_dump_port_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-fname) "./port_status.rpt"
  set options(-max_metal_length) 50.0
  parse_proc_arguments -args $args options

  sproc_msg -info "Report Generation for Port Info Beginning : [date]"

  ##
  ## Compute and gather stats
  ##

  set ports [get_ports]
  set ports [remove_from_collection $ports [get_ports -quiet -filter "direction==inout"]]
  set ports [ sort_collection $ports {direction full_name} ]
  set num_ports 0

  foreach_in_collection port $ports {

    ## Info about port / net

    set ds($num_ports,name) [get_attribute $port name]
    set ds($num_ports,direction) [get_attribute $port direction]

    set net [get_net -of [get_port $port]]

    if { [sizeof_collection $net] == 0 } {

      ##
      ## Deal with exception case were the MW doesn't see a net on unconnected port.
      ##

      set ds($num_ports,num_loads) 0
      set ds($num_ports,num_ant_loads) 0
      set ds($num_ports,load_ref_name) ""
      ## set ds($num_ports,vias) ""
      set ds($num_ports,num_vias) 0
      ## set ds($num_ports,ns) ""
      set ds($num_ports,num_ns) 0
      set ds($num_ports,length_ns) 0
      set ds($num_ports,area_ns) 0

    } else {

      if { $ds($num_ports,direction) == "in" } {
        if  { [ sizeof_collection [all_connected $net] ] == 1 } {
          set loads [ add_to_collection "" "" ]
        } else {
          set loads [ all_fanout -from $net -flat -only_cells -levels 0 ]
        }
        set ds($num_ports,num_loads) [ sizeof_collection $loads ]
      } else {
        set net_src [ all_connected [ all_fanin -to $net -flat -levels 0 ] ]
        if { [ sizeof_collection $net_src ] == 0 } {
          set loads [ add_to_collection "" "" ]
        } else {
          set loads [ all_fanin -to $net_src -flat -levels 0 ]
        }
        set ds($num_ports,num_loads) [ sizeof_collection $loads ]
      }

      ## Attempt to determine if any of the loads are diodes

      set ds($num_ports,num_ant_loads) 0
      set ds($num_ports,load_ref_name) ""
      foreach_in_collection load $loads {
        set load_name [get_attribute $load full_name]
        set cell_name [file dirname $load_name]
        ##
        ## puts "load_name: $load_name"
        ## puts "cell_name: $cell_name"
        ##
        if { [ regexp ^LYNX_dp_ant_ $load_name ] } {
          incr ds($num_ports,num_ant_loads)
        }
        set ds($num_ports,load_ref_name) "$ds($num_ports,load_ref_name) [get_attribute -quiet $cell_name ref_name]"
      }

      ## Stats on net_shapes

      set ds($num_ports,vias) [get_vias -of $net]
      set ds($num_ports,num_vias) [sizeof_collection $ds($num_ports,vias)]
      set ds($num_ports,ns) [get_net_shapes -of $net]
      set ds($num_ports,num_ns) [sizeof_collection $ds($num_ports,ns)]
      set ds($num_ports,length_ns) 0
      set ds($num_ports,area_ns) 0
      foreach_in_collection ns $ds($num_ports,ns) {
        set ds($num_ports,length_ns) \
          [expr $ds($num_ports,length_ns) + [get_attribute $ns length]]
        set ds($num_ports,area_ns) \
          [expr $ds($num_ports,area_ns) + ( [get_attribute $ns length] * [get_attribute $ns width] ) ]
      }
    }

    incr num_ports

  }

  ##
  ## Screen if unrouted database & suppress no metal warnings
  ##

  set suppress_no_metal 0
  set num_no_metal_ports 0
  for {set i 0} {$i < $num_ports} {incr i} {
    if { $ds($i,length_ns) < 0.00001 } { incr num_no_metal_ports }
  }
  if { [ expr ( ( 1.0 * $num_no_metal_ports ) / $num_ports ) ] > 0.5 } {
    set suppress_no_metal 1
  }

  ##
  ## Analyze data for warnings
  ##

  for {set i 0} {$i < $num_ports} {incr i} {

    set ds($i,comment) ""
    if { [expr $ds($i,num_loads) - $ds($i,num_ant_loads) ] > 1 } {
      if { $ds($i,comment) == "" } {
        set ds($i,comment) "NON-SINGLE POINT CONNECTION"
      } else {
        set ds($i,comment) "$ds($i,comment), NON-SINGLE POINT CONNECTION"
      }
    }
    if { $ds($i,num_loads) < 1 } {
      if { $ds($i,comment) == "" } {
        set ds($i,comment) "UNCONNECTED PORT"
      } else {
        set ds($i,comment) "$ds($i,comment), UNCONNECTED PORT"
      }
    }
    if { $ds($i,length_ns) > $options(-max_metal_length) } {
      if { $ds($i,comment) == "" } {
        set ds($i,comment) "METAL LENGTH > $options(-max_metal_length)"
      } else {
        set ds($i,comment) "$ds($i,comment), METAL LENGTH > $options(-max_metal_length)"
      }
    }
    if { $ds($i,length_ns) < 0.00001 && ( $suppress_no_metal == 0 ) } {
      if { $ds($i,comment) == "" } {
        set ds($i,comment) "NO METAL"
      } else {
        set ds($i,comment) "$ds($i,comment), NO METAL"
      }
    }
  }

  ##
  ## Open FID and create table header & table
  ##

  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "
  if { $suppress_no_metal } {
    puts $fid " "
    puts $fid "   The design appears to not be routed yet so suppressing NO METAL warnings."
  }
  puts $fid " "
  puts $fid "               Est.    Net     Net"
  puts $fid " Check    #   Diode   Shape   Shape    #    #         Port                            Load"
  puts $fid " Flag   Loads Loads  Length    Area    NS  VIAS dir   Name                 Comment  Ref Name(s)"
  puts $fid " -----  ----- ----- -------- -------- ---- ---- --- -------------------- ---------- -----------"
  for {set i 0} {$i < $num_ports} {incr i} {
    if { $ds($i,comment) == "" } {
      set str "       "
    } else {
      set str " CHECK "
    }
    set str [ format "%s %5d" $str $ds($i,num_loads) ]
    set str [ format "%s %5d" $str $ds($i,num_ant_loads) ]
    set str [ format "%s %8.2f" $str $ds($i,length_ns) ]
    set str [ format "%s %8.2f" $str $ds($i,area_ns) ]
    set str [ format "%s %4d %4d" $str $ds($i,num_ns) $ds($i,num_vias)]
    set str [ format "%s %-3s" $str $ds($i,direction) ]
    set str [ format "%s %-20s " $str $ds($i,name) ]
    set str [ format "%s %-8s " $str $ds($i,comment) ]
    if { $ds($i,num_loads) > 4 } {
      set str [ format "%s %s " $str "[lrange $ds($i,load_ref_name) 0 3] ..." ]
    } else {
      set str [ format "%s %s " $str $ds($i,load_ref_name) ]
    }
    puts $fid "$str"
  }
  puts $fid " "
  close $fid

  sproc_msg -info "Report Generation for Port Info Ending    : [date]"
  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dump_port_info \
  -info "Dump snapshot of misc information (e.g. loads, net length, name, etc.) regarding ports of a design." \
  -define_args {
  {-fname    "File name for the report."                      AString string  optional}
  {-max_metal_length "Screen for total metal length > # (default=50.0)" "" float optional}
}

## -----------------------------------------------------------------------------
## sproc_dump_single_connection_to_pin_check
##  - the following routine can be used to analyze pins that have been accessed
##    by the router at more than one location
## -----------------------------------------------------------------------------

proc sproc_dump_single_connection_to_pin_check { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-fname) "./single_connection_to_pin_check.rpt"
  set options(-metal1) "M1"
  parse_proc_arguments -args $args options

  sproc_msg -info "Report Generation for Single Connection to Pin Check Beginning : [date]"

  ##
  ## misc initialization
  ##
  set total_problems 0
  set cells [get_cells -hier *]

  set fid [open $options(-fname) w]
  puts $fid " "
  puts $fid " Report generated on [date] "
  puts $fid " "
  puts $fid " # isolated    pin        pin w/"
  puts $fid " net shapes  direction   problem"
  puts $fid " ----------  ---------  ----------------------------------"

  ## loop over cells
  foreach_in_collection cell $cells {

    ## grab key info and loop over pins
    set cell_bbox [get_attribute $cell bbox]
    set pins [get_pins -quiet -of $cell]
    foreach_in_collection pin $pins {

      ## filter net & via shapes down to those overlapping cell on 'metal1'
      set net [ all_connected $pin ]

      set via_shapes [add_to_collection "" ""]
      set via_shapes [add_to_collection $via_shapes [get_vias -of $net -intersect $cell_bbox] ]
      set via_shapes [add_to_collection $via_shapes [get_vias -of $net -within $cell_bbox] ]
      set via_shapes [filter $via_shapes "lower_layer==$options(-metal1)" ]

      set net_shapes [add_to_collection "" ""]
      set net_shapes [add_to_collection $net_shapes [get_net_shapes -of $net -intersect $cell_bbox] ]
      set net_shapes [add_to_collection $net_shapes [get_net_shapes -of $net -within $cell_bbox] ]
      set net_shapes [filter $net_shapes "layer==$options(-metal1)" ]

      set the_shapes [add_to_collection $via_shapes $net_shapes]

      set num_shapes [sizeof $the_shapes]

      ## verify shapes overlapping
      if { $num_shapes > 1 } {
        for {set x 0} {$x<$num_shapes} {incr x} {
          set overlaps($x) 0
          set ob1 [index_collection $the_shapes $x]
          set ob1_llx [get_attribute $ob1 bbox_llx]
          set ob1_lly [get_attribute $ob1 bbox_lly]
          set ob1_urx [get_attribute $ob1 bbox_urx]
          set ob1_ury [get_attribute $ob1 bbox_ury]
          for {set y 0} {$y<$num_shapes} {incr y} {
            if { $x != $y } {
              set ob2 [index_collection $the_shapes $y]
              set ob2_llx [get_attribute $ob2 bbox_llx]
              set ob2_lly [get_attribute $ob2 bbox_lly]
              set ob2_urx [get_attribute $ob2 bbox_urx]
              set ob2_ury [get_attribute $ob2 bbox_ury]
              if { ( $ob1_llx <= $ob2_llx ) && ( $ob1_urx >= $ob2_llx ) && ( $ob1_lly <= $ob2_lly ) && ( $ob1_ury >= $ob2_lly ) ||
                ( $ob1_llx <= $ob2_urx ) && ( $ob1_urx >= $ob2_urx ) && ( $ob1_lly <= $ob2_lly ) && ( $ob1_ury >= $ob2_lly ) ||
                ( $ob1_llx <= $ob2_urx ) && ( $ob1_urx >= $ob2_urx ) && ( $ob1_lly <= $ob2_ury ) && ( $ob1_ury >= $ob2_ury ) ||
                ( $ob1_llx <= $ob2_llx ) && ( $ob1_urx >= $ob2_llx ) && ( $ob1_lly <= $ob2_ury ) && ( $ob1_ury >= $ob2_ury ) ||
                ( $ob2_llx <= $ob1_llx ) && ( $ob2_urx >= $ob1_llx ) && ( $ob2_lly <= $ob1_lly ) && ( $ob2_ury >= $ob1_lly ) ||
                ( $ob2_llx <= $ob1_urx ) && ( $ob2_urx >= $ob1_urx ) && ( $ob2_lly <= $ob1_lly ) && ( $ob2_ury >= $ob1_lly ) ||
                ( $ob2_llx <= $ob1_urx ) && ( $ob2_urx >= $ob1_urx ) && ( $ob2_lly <= $ob1_ury ) && ( $ob2_ury >= $ob1_ury ) ||
                ( $ob2_llx <= $ob1_llx ) && ( $ob2_urx >= $ob1_llx ) && ( $ob2_lly <= $ob1_ury ) && ( $ob2_ury >= $ob1_ury ) \
                } {
                set overlaps($x) [expr $overlaps($x) + 1]
              }
            }
          }
        }

        ## look if the are non overlapping shapes (ie isolated_shapes)
        set isolated_shapes 0
        for {set x 0} {$x<$num_shapes} {incr x} {
          if { $overlaps($x) == 0 } {
            incr isolated_shapes
          }
        }

        ## if isolated_shapes verify they aren't due to same net connecting to multiple pins
        if { $isolated_shapes > 0 } {
          set num_common_nets 0
          set net1_name [get_attribute $net name]
          set nets [all_connected $pins]
          foreach_in_collection net2 $nets {
            set net2_name [get_attribute $net2 name]
            if { $net1_name == $net2_name } {
              incr num_common_nets
            }
          }
          if { $isolated_shapes == $num_common_nets } {
            set isolated_shapes 0
          } else {
            set isolated_shapes [expr $isolated_shapes - $num_common_nets + 1]
          }
        }

      }

      if { $num_shapes > 1 && $isolated_shapes > 0 } {
        set str [ format "    %2d          %3s     %-s " $isolated_shapes [get_attribute $pin direction] [get_attribute $pin full_name] ]
        puts $fid $str
        incr total_problems
      }

    }

  }

  puts $fid " "
  puts $fid "  WARNING : $total_problems pins were identified as having been accessed in more than one location."
  puts $fid " "
  close $fid

  sproc_msg -info "Report Generation for Single Connection To Pin on Check Ending    : [date]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dump_single_connection_to_pin_check \
  -info "Dump pins with more than one route connection accessing it." \
  -define_args {
  {-fname    "File name for the report."   AString string optional}
  {-metal1   "Name of metal1 (default=M1)" AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_icc_map_tlup_to_nxtgrd:
## -----------------------------------------------------------------------------

proc sproc_icc_map_tlup_to_nxtgrd { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  parse_proc_arguments -args $args options

  sproc_msg -info "Executing sproc_icc_map_tlup_to_nxtgrd"

  ## determine TLU+ settings
  set tlup_lib_max "unset"
  set tlup_lib_min "unset"
  set tlup_lib_max_emf "unset"
  set tlup_lib_min_emf "unset"
  redirect -variable rpt {
    report_tlu_plus_files
  }

  set lines [split $rpt "\n"]
  foreach line $lines {
    regexp {^\s*Max TLU\+ file: (\S+)} $line matchVar tlup_lib_max
    regexp {^\s*Min TLU\+ file: (\S+)} $line matchVar tlup_lib_min
    regexp {^\s*Max EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_max_emf
    regexp {^\s*Min EMULATION TLU\+ file: (\S+)} $line matchVar tlup_lib_min_emf
  }

  if { [ sizeof_collection [ get_mw_cel -quiet $SVAR(design_name).FILL ] ] == 0 } {

    sproc_msg -info "  Using nxtgrd for emulated FILL."

    ## map max TLU+ -> NXTGRD
    set nxtgrd_max "unset"
    if { $tlup_lib_max_emf == "unset" } {
      foreach oc $SVAR(setup,rc_types_list) {
        if { $SVAR(tech,tlup_file,$oc) == $tlup_lib_max } {
          set nxtgrd_max $SVAR(tech,nxtgrd_file,$oc)
        }
      }
    } else {
      foreach oc $SVAR(setup,rc_types_list) {
        if { $SVAR(tech,tlup_emf_file,$oc) == $tlup_lib_max_emf } {
          set nxtgrd_max $SVAR(tech,nxtgrd_emf_file,$oc)
        }
      }
    }

    ## map min TLU+ -> NXTGRD
    set nxtgrd_min "unset"
    if { $tlup_lib_min_emf == "unset" } {
      foreach oc $SVAR(setup,rc_types_list) {
        if { $SVAR(tech,tlup_file,$oc) == $tlup_lib_min } {
          set nxtgrd_min $SVAR(tech,nxtgrd_file,$oc)
        }
      }
    } else {
      foreach oc $SVAR(setup,rc_types_list) {
        if { $SVAR(tech,tlup_emf_file,$oc) == $tlup_lib_min_emf } {
          set nxtgrd_min $SVAR(tech,nxtgrd_emf_file,$oc)
        }
      }
    }

  } else {

    sproc_msg -info "  Using nxtgrd for real FILL."

    ## map max TLU+ -> NXTGRD
    set nxtgrd_max "unset"
    foreach oc $SVAR(setup,rc_types_list) {
      if { $SVAR(tech,tlup_file,$oc) == $tlup_lib_max } {
        set nxtgrd_max $SVAR(tech,nxtgrd_file,$oc)
      }
    }

    ## map min TLU+ -> NXTGRD
    set nxtgrd_min "unset"
    foreach oc $SVAR(setup,rc_types_list) {
      if { $SVAR(tech,tlup_file,$oc) == $tlup_lib_min } {
        set nxtgrd_min $SVAR(tech,nxtgrd_file,$oc)
      }
    }

  }

  if { $nxtgrd_max == "unset" } {
    sproc_msg -error "Unable to perform and TLU+ -> NXTGRD mapping"
    sproc_msg -error "tluplus_lib_max"
    sproc_msg -error "tluplus_lib_min"
    sproc_msg -error "nxtgrd_max"
    sproc_msg -error "nxtgrd_min"
    report_tlu_plus_files
    set return_value ""
  } elseif { ( $nxtgrd_max != "unset" ) && ( $nxtgrd_min == "unset" ) } {
    set return_value $nxtgrd_max
  } elseif { ( $nxtgrd_max != "unset" ) && ( $nxtgrd_min != "unset" ) } {
    set return_value "$nxtgrd_max $nxtgrd_min"
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_icc_map_tlup_to_nxtgrd \
  -info "Procedure to map TLU+ to NXTGRD for signoff_opt ." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_macro_setup:
## -----------------------------------------------------------------------------

proc sproc_macro_setup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global compile_preserve_subdesign_interfaces upf_block_partition
  global DEV

  ##
  ## Get arguments
  ##

  set options(-load_only) 0
  set options(-force_full_model) 0
  parse_proc_arguments -args $args options

  if { !$options(-load_only) && $options(-force_full_model) } {
    sproc_msg -error "Forcing full model only allowed with -load_only option. Disabling"
    set options(-force_full_model) 0
  }

  ##
  ## Configure for correct macro loading.
  ##

  unset -nocomplain design_name_already_used
  set ddc_am_designs [list]

  set design_and_model_list [sproc_get_macro_info -type [list hard logic] -info design_and_model -tool dc -hier]
  if { ![regexp { full_model| ddc_am| icc_am} $design_and_model_list] } {
    ## abstracts and full models need recursive setup
    set design_and_model_list [sproc_get_macro_info -type [list hard logic] -info design_and_model -tool dc]
  }

  foreach design_and_model $design_and_model_list {

    set design [lindex $design_and_model 0]
    set model  [lindex $design_and_model 1]
    if { $options(-force_full_model) && $model!="full_model" } {
      sproc_msg -info "Forcing a full model"
      set model full_model
    }

    if { [info exists design_name_already_used($design)] } {
      sproc_msg -info "Design $design already modeled with type $model"
    } else {
      set design_name_already_used($design) 1
      if { $SVAR(pwr,upf_enable) } {
        ## Omit macro UPF from upf save
        if { $DEV(201409_hier_upf_save) } {
          lappend upf_block_partition $design
          sproc_msg -setup "lappend upf_block_partition $design"
        }
      }
      if { [shell_is_in_topographical_mode] } {
        switch $model {
          full_model {
            sproc_msg -info "Design $design modeled with type $model"
            read_ddc $SEV(step_dir)/work/000_inputs/$design.ddc
          }
          ddc_am {
            sproc_msg -info "Design $design modeled with type $model"
            eval set_top_implementation_options -block_reference [list $design] -load_logic $DEV(abstract_style)
            sproc_msg -setup "set_top_implementation_options -block_reference [list $design] -load_logic $DEV(abstract_style)"
            lappend ddc_am_designs  $SEV(step_dir)/work/000_inputs/$design.ddc
          }
          icc_am {
            sproc_msg -info "Design $design modeled with type $model"
            eval set_top_implementation_options -block_reference $design -load_logic $DEV(abstract_style)
            sproc_msg -setup "set_top_implementation_options -block_reference $design -load_logic $DEV(abstract_style)"
          }
          etm {
            sproc_msg -info "Design $design modeled with type $model"
          }
          default {
            sproc_msg -error "Incorrect model type for macro $design: $model"
          }
        }
      } else {
        switch $model {
          full_model {
            sproc_msg -info "Design $design modeled with type $model"
            read_ddc $SEV(step_dir)/work/000_inputs/$design.ddc
          }
          ddc_am {
            sproc_msg -info "Design $design modeled with type $model"
            eval set_top_implementation_options -block_reference $design -load_logic $DEV(abstract_style)
            sproc_msg -setup "set_top_implementation_options -block_reference $design -load_logic $DEV(abstract_style)"
            lappend ddc_am_designs  $SEV(step_dir)/work/000_inputs/$design.ddc
          }
          icc_am {
            sproc_msg -error "Incorrect model type for macro $design: $model"
            sproc_msg -error "The model type $model is not supported for non-topo."
          }
          etm {
            sproc_msg -info "Design $design modeled with type $model"
          }
          default {
            sproc_msg -error "Incorrect model type for macro $design: $model"
          }
        }
      }
    }
  }

  ## complete the setup of any abstract models
  if {[llength $ddc_am_designs] > 0} {
    read_ddc [list $ddc_am_designs]
    sproc_msg -setup "read_ddc [list $ddc_am_designs]"
  }

  ##
  ## If -load_only was specified, do not perform any other functions.
  ##

  if { $options(-load_only) } {
    sproc_msg -info "Skipping optimization controls for macros."
    sproc_pinfo -mode stop
    return
  }

  ##
  ## Set current_design back to the top level in preparation for rest of procedure.
  ##

  current_design $SVAR(design_name)

  ##
  ## Manage treatement of macros
  ##

  foreach inst_and_model [sproc_get_macro_info -type [list hard logic] -info inst_and_model -tool dc] {
    set inst  [lindex $inst_and_model 0]
    set model [lindex $inst_and_model 1]
    if { [shell_is_in_topographical_mode] } {
      if { $model == "full_model" } {
        if { [get_attribute [get_cells $inst] dct_hier_is_physical_block -quiet]!=true } {
          sproc_msg -info "sproc_macro_setup: Setting $inst as physical_hierarchy"
          set_physical_hierarchy $inst
        } else {
          sproc_msg -info "sproc_macro_setup: instance $inst reference already set as physical_hierarchy"
        }
      } else {
        sproc_msg -info "sproc_macro_setup: Model type $model for $inst needs no additional setup"
      }
    } else {
      sproc_msg -info "sproc_macro_setup: Setting $inst as dont_touch"
      set_dont_touch $inst
    }
  }

  set macros [sproc_get_macro_info -type [list hard logic] -info design]

  ## soft macro handling
  foreach inst  [sproc_get_macro_info -type [list soft] -info inst] {
    sproc_msg -info "sproc_macro_setup: Preventing ungrouping for soft macro $inst"
    set_ungroup $inst false
  }

  foreach macro [sproc_get_macro_info -type [list soft] -info design] {
    set covered_as_logic_mac 0
    foreach lmacro [sproc_get_macro_info -type [list logic] -info design] {
      if { $macro == $lmacro } {
        set covered_as_logic_mac 1
      }
    }
    if { !$covered_as_logic_mac } {
      sproc_msg -info "sproc_macro_setup: Preventing boundary optimization for soft macro $macro"
      set_boundary_optimization $macro false
      sproc_msg -info "sproc_macro_setup: Attributing macro $macro with its current name for restoring later"
      ## special attribute for restoring macro model name after uniquification
      set_attribute [get_designs $macro] orig_soft_macro_name -type string $macro
      set_app_var compile_preserve_subdesign_interfaces true
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_macro_setup \
  -info "Procedure to consistently configure macros for synthesis." \
  -define_args {
  {-load_only "Only load macros, do not set compilation attributes." "" boolean optional}
  {-force_full_model "Force the model type to be full_model. Only supported with -load_only" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_restore_soft_macro_names:
## -----------------------------------------------------------------------------

proc sproc_restore_soft_macro_names  { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## find designs (soft macros) which have attribute indicating original name and restore
  set renamed_sm  [get_object_name [get_designs -filter orig_soft_macro_name!=""]]
  set renamed_sm [lsort -uniq $renamed_sm]
  foreach des $renamed_sm {
    set des_name [get_attribute $des full_name]
    set original_name [get_attribute $des_name orig_soft_macro_name]
    if { $des_name != $original_name } {
      sproc_msg -info "Restore uniquified soft macro name $des_name back to orignal $original_name"
      rename_design $des $original_name
    } else {
      sproc_msg -info "No name change needed to restore soft macro name $des_name"
    }
  }
  sproc_pinfo -mode stop
}

define_proc_attributes sproc_restore_soft_macro_names \
  -info "Procedure to restore soft macro names after uniquification." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_dct_setup_mw:
## -----------------------------------------------------------------------------

proc sproc_dct_setup_mw {} {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global mw_reference_library
  global mw_design_library
  global ignore_tf_error

  set mw_reference_library $SVAR(lib,mw_reflist)
  set mw_design_library $SEV(dst_dir)/$SVAR(design_name).mdb

  if { [file exists $mw_design_library] } {
    file delete -force $mw_design_library
    sproc_msg -setup "## Removing existing $mw_design_library"
  }

  if { $SVAR(tech,extend_mw_layers) } {
    extend_mw_layers
  }

  create_mw_lib \
    -technology $SVAR(tech,mw_tech_file) \
    -mw_reference_library $SVAR(lib,mw_reflist) \
    $mw_design_library
  sproc_msg -setup "create_mw_lib -technology $SVAR(tech,mw_tech_file) \\"
  sproc_msg -setup "  -mw_reference_library  $SVAR(lib,mw_reflist) \\"
  sproc_msg -setup "  $mw_design_library"

  open_mw_lib $mw_design_library
  sproc_msg -setup "open_mw_lib $mw_design_library"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_dct_setup_mw \
  -info "Procedure to consistently create MW database for DCT usage." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_dct_setup_physical:
## -----------------------------------------------------------------------------

proc sproc_dct_setup_physical { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global PD
  global fuzzy_matching_enabled
  global LYNX

  set options(-physical_format) "SKIP"
  set options(-physical_file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Parse data from SVAR(tech,metal_layer_info_list), so that
  ## changes in variable format do not affect this procedure.
  ## -------------------------------------
  unset -nocomplain metal_layer_name_list
  unset -nocomplain metal_layer_dir_list
  foreach item $SVAR(tech,metal_layer_info_list) {
    set name [lindex $item 0]
    set dir  [lindex $item 1]
    lappend metal_layer_name_list $name
    lappend metal_layer_dir_list $dir
  }

  ## -------------------------------------
  ## Set preferred routing direction.
  ## -------------------------------------

  for { set i 0 } { $i < [llength $metal_layer_name_list] } { incr i } {
    set layer_name [lindex $metal_layer_name_list $i]
    set layer_dir  [lindex $metal_layer_dir_list $i]

    if { ($layer_dir == "H") || ($layer_dir == "V") } {
      sproc_msg -info "Direction for metal layer $layer_name is $layer_dir"
      set_preferred_routing_direction -layers $layer_name -direction $layer_dir
    } else {
      sproc_msg -error "Direction for metal layer $layer_name is $layer_dir"
    }
  }

  report_preferred_routing_direction

  ## -------------------------------------
  ## Set ignored layers.
  ## -------------------------------------

  sproc_set_ignored_layers -verbose

  ## -------------------------------------
  ## Custom set_delay_estimation_options
  ## -------------------------------------

  sproc_source -file $SVAR(tech,rc_multipliers_file)
  report_delay_estimation_options

  ## -------------------------------------
  ## Physical information
  ## -------------------------------------

  set fuzzy_matching_enabled true

  switch $options(-physical_format) {
    SKIP {
      sproc_msg -info "No physical constraints applied."
    }
    DEF {
      extract_physical_constraints $options(-physical_file) -allow_physical_cells
    }
    READ_FP {
      read_floorplan $options(-physical_file)
    }
    USER_FILE {
      sproc_source -file $options(-physical_file)
    }
    default {
      sproc_msg -error "Unrecognized value for options(-physical_format) : '$options(-physical_format)'"
    }
  }

  set fuzzy_matching_enabled false
  report_physical_constraints

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_dct_setup_physical \
  -info "Procedure to consistently configure layer information for DCT usage." \
  -define_args {
  {-physical_format "Specifies the physical format method." AnOos one_of_string
    {optional value_help {values {SKIP DEF READ_FP USER_FILE}}}
  }
  {-physical_file "Specifies the physical format file." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_create_combined_upf:
## -----------------------------------------------------------------------------

proc sproc_create_combined_upf {args} {

  sproc_pinfo -mode start

  global env SEV SVAR TEV DEV
  global temp_svar_design_name_override
  global synopsys_program_name

  set default_path_to_macros \$env(BLOCK_DIR)/$SEV(step)/work/000_inputs

  set options(-top_upf) NULL
  set options(-logic) 0
  set options(-soft_only) 0
  set options(-file) NULL
  set options(-suffix) .upf
  set options(-load_only) 0

  parse_proc_arguments -args $args options

  ## Create UPF file
  sproc_msg -info "Creating single UPF file $options(-file)"

  ## Copy top upf into consilidated file
  set wid [open $options(-file) w]

  ## Empty top design expected for characterize flow
  if {$options(-top_upf)==""} {
    puts $wid "## ---------------------------------------------------------------------"
    puts $wid "## INFO: Combined UPF file created by sproc_create_combined_upf"
    puts $wid "## called from $SEV(script_file)"
    puts $wid "## Top UPF was empty so creating an empty file"
    puts $wid "## ---------------------------------------------------------------------"
    close $wid
    sproc_pinfo -mode stop
    return
  }

  ## First comment line maintained since it reflects the original tool that produced the upf
  set top_upf $options(-top_upf)
  if { [file exists $top_upf] } {
    set rid [open $top_upf r]
    gets $rid line
    if {[regexp {^#.*} $line]} {
      puts $wid $line
    }
    close $rid
  } else {
    if { !$DEV(enable_golden_upf) && $options(-top_upf) == "NULL" } {
      sproc_msg -error "The -top_upf option is invalid. File does not exist: $top_upf"
      sproc_script_stop -exit
    }
  }

  puts $wid "## ---------------------------------------------------------------------"
  puts $wid "## INFO: Combined UPF file created by sproc_create_combined_upf"
  puts $wid "## called from $SEV(script_file)"
  puts $wid "## ---------------------------------------------------------------------"
  puts $wid ""

  ## determine which macro upf to combine depending on step and options
  if { $options(-logic) } {
    set macro_type_list [list logic hard]
  } else {
    if { $SEV(step)=="10_syn" } {
      set macro_type_list [list hard]
    } else {
      set macro_type_list [list hard soft]
    }
  }

  if { $options(-soft_only) } {
    set macro_type_list [list soft]
  }

  ## Corner case situations used during icc export of soft macros which should ignore macro_info
  if { [info exists temp_svar_design_name_override] && $temp_svar_design_name_override } {
    set macro_type_list [list]
  }

  foreach macro_type $macro_type_list {
    set design_and_inst_list [sproc_get_macro_info -type $macro_type -info design_and_inst -disable_instance_matching]
    foreach design_and_inst $design_and_inst_list  {
      set design [lindex $design_and_inst 0]
      set inst   [lindex $design_and_inst 1]
      set macro_upf_file $default_path_to_macros/$design$options(-suffix)

      ## soft macro upf is output for DP step where it is first exported
      if { $macro_type == "soft" && $SEV(step) == "20_dp" } {
        set macro_upf_file [regsub "000_inputs" $macro_upf_file "800_outputs"]
        sproc_msg -info "Adjusted path to soft macro to $macro_upf_file"
      }

      puts $wid "## -------------------------------------"
      puts $wid "## INFO: $macro_type macro $design UPF"
      puts $wid "## -------------------------------------"
      puts $wid "load_upf -scope $inst $macro_upf_file"
      puts $wid ""

    }

  }

  puts $wid "## ------------------------------------------------------------------------------"
  puts $wid "## INFO: Top level UPF added from $top_upf"
  puts $wid "## ------------------------------------------------------------------------------"
  puts $wid ""
  if {$options(-load_only)} {
    ## Load original top upf rather than copying and filtering its contents into the new file
    if { $top_upf != "NULL" } {
      set top_upf_reference [regsub -all "$SEV(block_dir)" [file normalize $top_upf] "\$env(BLOCK_DIR)"]
      puts $wid "load_upf $top_upf_reference"
    }
    puts $wid ""
    puts $wid "## Option choosen to load original UPF rather than copy and filter"
    close $wid
    sproc_pinfo -mode stop
    return
  }

  ## Copy top upf into consilidated file
  set rid [open $top_upf r]
  set filtering 0
  puts $wid "## -------------------------------------------------------------------------------------------"
  puts $wid "## NOTE: Filtering is enabled. UPF constructs considered redundant with macro upf are filtered"
  puts $wid "## -------------------------------------------------------------------------------------------"
  puts $wid ""

  while { [gets $rid line] >= 0 } {
    switch -glob $line {
      *set_design_attributes*lower_domain_boundary* {
        if { $DEV(remove_lower_domain_boundry_from_upf) } {
          set line "## FILTERED LINE - DEV(remove_lower_domain_boundry_from_upf) : $line"
        }
      }
      default {
        ## NOP
      }
    }
    puts $wid $line
  }

  close $rid
  close $wid

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_create_combined_upf \
  -info "Merge top UPF and macro UPF into a single UPF file. Used to support reintegration of hierarchical upf data" \
  -define_args {
  {-top_upf "Top level UPF file." AString string optional}
  {-logic "Include any logic macro upf in the combined (in addition to any hard macros)" "" boolean optional}
  {-load_only "Include the original top using a load_upf rather than copying and filtering upf" "" boolean optional}
  {-soft_only "Special case used in DP when top and soft need to be integrated" "" boolean optional}
  {-suffix "Allow control over the suffix style for the desired UPF (default is .upf). This is needed for golden upf control" AString string optional}
  {-file "Combined UPF output file name" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_filter_upf:
## -----------------------------------------------------------------------------

proc sproc_filter_upf {args} {

  sproc_pinfo -mode start

  global env SEV SVAR TEV DEV
  global synopsys_program_name

  set options(-file) NULL

  parse_proc_arguments -args $args options

  set upf_file $options(-file)

  file delete -force $upf_file.orig
  file copy $upf_file $upf_file.orig
  set rid [open $upf_file.orig r]
  set wid [open $upf_file w]

  set regexp_domain_inst "NULL"

  ## setup for upf_filter_workaround_9000818040 filtering
  if { $DEV(upf_filter_workaround_9000818040) } {
    sproc_msg -issue "Implementing DEV(upf_filter_workaround_9000818040)"
    set abstract_blocks [get_object_name [get_cell -quiet -hier -filter is_block_abstraction==true]]
    if { [llength $abstract_blocks] > 0 } {
      foreach blk $abstract_blocks {
        set regexp_domain_inst "$regexp_domain_inst\|domain $blk"
      }
    }
    sproc_msg -issue "Filtering on macro inst search $regexp_domain_inst"
  }
  if { $DEV(upf_filter_workaround_derived_diverse_clk) } {
    sproc_msg -issue "Implementing DEV(upf_filter_workaround_derived_diverse_clk)"
  }
  if { $DEV(upf_filter_workaround_receiver_supply) } {
    sproc_msg -issue "Implementing DEV(upf_filter_workaround_receiver_supply)"
  }

  ## Filtering performed here
  while { [gets $rid line] >= 0 } {
    switch -regexp $line {
      ^set_isolation.* -
      ^set_level_shift.* {
        ## remove erroneous references to abstract power domain content
        if { $DEV(upf_filter_workaround_9000818040) && $synopsys_program_name == "icc_shell" &&  [regexp $regexp_domain_inst $line] } {
          set line "## FILTERED LINE - DEV(upf_filter_workaround_9000818040) : $line"
        }
      }
      .*DERIVED_DIVERSE.* {
        if { $DEV(upf_filter_workaround_derived_diverse_clk) && ![regexp {^#} $line] } {
          set line "## FILTERED LINE - DEV(upf_filter_workaround_derived_diverse_upf) : $line"
        }
      }
      ^set_port_attributes.* {
        ## This one is tricky because it might span multiple lines. Looking for a port attribute with -receiver_supply
        if { $DEV(upf_filter_workaround_receiver_supply) } {
          set fline $line
          while { [regexp {\\$} $line] } {
            gets $rid line
            set fline $fline\n$line
          }
          if { [regexp receiver_supply $fline] } {
            set fstring "## FILTERED LINE - DEV(upf_filter_workaround_receiver_supply) : "
          } else {
            set fstring ""
          }
          foreach ln [split $fline \n] {
            puts $wid "$fstring$ln"
          }
          set line ""
        }
      }
    }
    puts $wid $line
  }
  close $rid
  close $wid

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_filter_upf \
  -info "Filter content in the UPF as part of possible workarounds. See DEV variables which allow control over the filtering." \
  -define_args {
  {-file "UPF file to filter. A *.orig version of the original is saved." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_place_macro:
## -----------------------------------------------------------------------------

proc sproc_place_macro { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-macro) {}
  set options(-snap) 0
  parse_proc_arguments -args $args options
  set macro $options(-macro)

  lappend macro_list $macro
  set inst_name   [lindex $macro 0]
  set orientation [lindex $macro 1]
  set xy          [lindex $macro 2]
  set inst_name [sproc_get_correct_inst_name -inst $inst_name]
  set x [lindex $xy 0]
  set y [lindex $xy 1]
  set xy "$x $y"

  sproc_msg -info "Macro : $inst_name oriented $orientation at $xy"

  set_object_fixed $inst_name false
  set cell [get_cells $inst_name]
  rotate_objects -to $orientation $cell
  if { $options(-snap) } {
    set_object_snap_type -enabled true
  } else {
    set_object_snap_type -enabled false
  }
  move_objects -to $xy $cell
  set_object_snap_type -enabled true
  set_object_fixed $inst_name true

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_place_macro \
  -info "This procedure is used by the flow development team for custom floorplanning." \
  -define_args {
  {-macro "Name of macro to be processed." "" string required}
  {-snap  "Snap to row site" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_set_ignored_layers:
## -----------------------------------------------------------------------------

proc sproc_set_ignored_layers { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## default "options" to info already in SVARs
  set options(-min_routing_layer) [sproc_convert_to_metal_layer_name -list $SVAR(route,layer_signal_min)]
  set options(-max_routing_layer) [sproc_convert_to_metal_layer_name -list $SVAR(route,layer_signal_max)]
  if { $SVAR(route,rc_congestion_ignored_layers) != "" } {
    set options(-rc_congestion_ignored_layers) [sproc_convert_to_metal_layer_name -list $SVAR(route,rc_congestion_ignored_layers)]
  } else {
    set options(-rc_congestion_ignored_layers) ""
  }
  set options(-verbose) 0
  parse_proc_arguments -args $args options

  ## reset prior settings as updates are cumulative
  ## note "-all" only wrt "-rc_congestion_ignored_layers"
  remove_ignored_layers -max_routing_layer
  remove_ignored_layers -min_routing_layer
  remove_ignored_layers -all

  ## update set_ignored_layers w/ new values
  set_ignored_layers -min_routing_layer $options(-min_routing_layer)
  set_ignored_layers -max_routing_layer $options(-max_routing_layer)
  if { $options(-rc_congestion_ignored_layers) != "" } {
    set_ignored_layers -rc_congestion_ignored_layers $options(-rc_congestion_ignored_layers)
  }

  ## if verbose mode generate report
  if { $options(-verbose) } {
    report_ignored_layers
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_set_ignored_layers \
  -info "Standard procedure for interfacing to set_ignored_layers." \
  -define_args {
  {-min_routing_layer "User supplied minimum routing layer, using SVAR by default"  AString string optional}
  {-max_routing_layer "User supplied maximum routing layer, using SVAR by default"  AString string optional}
  {-rc_congestion_ignored_layers "User supplied layer list, using SVAR by default"  AString string optional}
  {-verbose "Used to enable verbose mode." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_set_preferred_routing_direction:
## - first build a data structure of the tools view
## - then compare the data structure to the Lynx view
## - update any inconsistencies to the Lynx view
## -----------------------------------------------------------------------------

proc sproc_set_preferred_routing_direction { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  sproc_msg -info "Analyzing preferred routing direction through the first $SVAR(route,layer_signal_max) layers to ensure consistentcy between Lynx and the tool."

  ## build a data structure of the tools view of the preferred routing direction
  redirect -variable report {  report_preferred_routing_direction }
  set lines [split $report "\n"]
  set ds_num_layers 0
  set mode "searching"
  foreach line $lines {
    if { $mode == "searching" } {
      if { [ regexp {Tool understands} $line matchVar ] } {
        set mode "locked"
      }
    } elseif { $mode == "locked" } {
      if { [ regexp {^/s+} $line matchVar ] } {
        set mode "finished"
      } else {
        set ds($ds_num_layers,layer_name) [lindex $line 0]
        set ds($ds_num_layers,direction) [ string toupper [string index [lindex $line 3] 0] ]
        incr ds_num_layers
      }
    } elseif { $mode == "finished" } {
    }
  }

  ## compare the tools view of the preferred routing direction to the Lynx view, update if different
  for { set i 0 } { $i < $SVAR(route,layer_signal_max) } { incr i } {
    set layer_name $ds($i,layer_name)
    set layer_direction $ds($i,direction)
    if { [sproc_get_preferred_direction -layer_name $layer_name] == $layer_direction } {
      sproc_msg -info "Preferred routing direction of $layer_name is consistent between Lynx and the tool."
    } else {
      sproc_msg -warning "Preferred routing direction of $layer_name is inconsistent between Lynx and the tool."
      if { [sproc_get_preferred_direction -layer_name $layer_name] == "H" } {
        sproc_msg -info "Setting routing direction of $layer_name per Lynx specification to be horizontal."
        set_preferred_routing_direction -layers $layer_name -direction horizontal
      } else {
        sproc_msg -info "Setting routing direction of $layer_name per Lynx specification to be vertical."
        set_preferred_routing_direction -layers $layer_name -direction vertical
      }
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_set_preferred_routing_direction \
  -info "Standard procedure for adjusting preferred routing layer directions." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_screen_library_checks:
## -----------------------------------------------------------------------------

proc sproc_screen_library_checks { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-report_file) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-report_file)] } {
    sproc_msg -error "Could not find report file $options(-report_file)"
  }

  set no_problems 1

  set fid [open $options(-report_file) r]

  sproc_msg -info "Screening check status messages in $options(-report_file)"
  while { [gets $fid line] >= 0 } {
    if { [regexp {INCONSIST} $line match] } {
      sproc_msg -info "check_library status:  $line"
    }
    if { [regexp {PASS} $line match] } {
      sproc_msg -info "check_library status:  $line"
    }
    if { [regexp {FAIL} $line match] } {
      sproc_msg -info "check_library status:  $line"
    }
  }
  close $fid

  sproc_pinfo -mode stop
  return $no_problems
}

define_proc_attributes sproc_screen_library_checks \
  -info "Checks check_library outputs for various errors." \
  -define_args {
  {-report_file "check_library output reprt" "" string required}
}

## -----------------------------------------------------------------------------
## sproc_screen_dft_drc:
## -----------------------------------------------------------------------------

proc sproc_screen_file_errors { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set default_string Error:
  set options(-file) ""
  set options(-error_string) $default_string

  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "Could not find file $options(-file)"
  }

  set error_count 0

  set error_flag 0

  set fid [open $options(-file) r]

  while { [gets $fid line] >= 0 } {
    if { [ regexp $options(-error_string) $line mtch ] } {
      incr error_count
      if { ![string match $options(-error_string) $default_string] } {
        sproc_msg -error $line
      }
    }
  }

  if { $error_count > 0 } {
    sproc_msg -error "$error_count errors detected. Review $options(-file)"
    set error_flag 1
  }

  close $fid
  sproc_pinfo -mode stop
  return $error_flag

}

define_proc_attributes sproc_screen_file_errors \
  -info "Checks the supplied file for basic errors and creates one error message" \
  -define_args {
  {-file "file" "" string required}
  {-error_string "Alternate error string to match. Default is 'Error:'" "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_mv_checks:
## -----------------------------------------------------------------------------

proc sproc_screen_mv_checks { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-logfile) ""
  set options(-context) build
  parse_proc_arguments -args $args options

  if { ![file exists $options(-logfile)] } {
    sproc_msg -error "Could not find logfile $options(-logfile)"
  }

  set fail_flag 1

  set fid [open $options(-logfile) r]

  while { [gets $fid line] >= 0 } {
    switch $options(-context) {
      build {
        if { [regexp {MVCMP completed with .* 0 error} $line match] } {
          set fail_flag 0
        }
        if { [regexp {MVDBGEN completed with .* 0 error} $line match] } {
          set fail_flag 0
        }
        sproc_msg -info $line
      }
      rtl - netlist {
        ## this flag is only used for context build
        set fail_flag 0
        if { $options(-context)=="rtl" } {
          set critical_errors "X_PROPAGATION"
        } else {
          set critical_errors "X_PROPAGATION ISO_DEVICE_MISSING"
        }
        if { [ regexp {\|ERROR\s+\|(\S+)\s+\|.+\|(\d+)\s+\|} $line mtch err_type err_cnt ] } {
          if { $err_cnt > 0 && [regexp "$err_type" $critical_errors mtch] } {
            sproc_msg -error "MVTools report $err_cnt error(s) of type $err_type - Review reports contained in $options(-logfile)"
          }
        }
      }
      default {
        sproc_msg -error "Should have defaulted to 'build'"
      }
    }
  }

  close $fid

  if { $fail_flag } {
    sproc_msg -error "Failure during build. See $options(-logfile)"
    set return_value 1
  } else {
    set return_value 0
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_screen_mv_checks \
  -info "Checks intermediate logfiles for errors." \
  -define_args {
  {-logfile "logfile" "" string required}
  {-context {scan based on type builddefault)|rtl|netlist} "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_screen_mv_debugger:
## -----------------------------------------------------------------------------

proc sproc_screen_mv_debugger { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global product_version
  global LYNX
  global auto_insert_level_shifters_on_clocks
  global mv_insert_level_shifters_on_ideal_nets
  global mv_no_main_power_violations

  ## Get arguments
  set options(-report) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-report)] } {
    sproc_msg -error "Could not find logfile $options(-report)"
  }

  set fid [open $options(-report) r]

  set error_mv231_found 0
  set error_mv076_found 0
  file delete -force $options(-report).debug_level_shifters
  file delete -force $options(-report).debug_always_on
  while { [gets $fid line] >= 0 } {
    if { [regexp {MV-229} $line match ] } {
      sproc_msg -error $line
    }
    if { [regexp {MV-080} $line match ] } {
      sproc_msg -error $line
    }
    if { [regexp {Warning: Pin '(\S*)'\S* cannot drive '(\S*)'\S} $line match source_pin sink_pin] } {
      set error_mv231_found 1
      set cmd "analyze_mv_design -level_shifter -from_pin $source_pin -to_pin $sink_pin -verbose"
      sproc_msg -warning "$cmd"
      set tip_text "
      ## -------------------------------------
      LYNX_INFO:

      This file contains some info for debug of a MV-231 level shifter problem. Lynx auto detected the condition
      during check_mv_design and generated this report. It contains:

        Output from analyze_mv_design to show details useful for further debug of the missing LS
        Output from report_timing -through the pins as additional context of the LS

      Based on these reports, users may investigate design, UPF, or library aspects that can lead to the missing
      level shifts. Note that there are some variables that can also be used as part of the solution or workaround
      of missing level_shifters. Consider the settings of these variables to solve within the expectation of the
      front end and back end design teams:

        By default, level shifters are not inserted on clock nets. To change this behavior, use:

          set auto_insert_level_shifters_on_clocks \<clk1 clk2 ..\> \| \<all\>
            (current value is auto_insert_level_shifters_on_clocks=$auto_insert_level_shifters_on_clocks)

        By default, level shifters are not inserted on ideal nets. To change this behavior, use:

          set mv_insert_level_shifters_on_ideal_nets all
            (current value is mv_insert_level_shifters_on_ideal_nets=$mv_insert_level_shifters_on_ideal_nets)

        By default, level shifters are not inserted on dont_touch nets. To change this behavior, use:

          remove_attribute net_name dont_touch

        By default, level shifters will not insert if there is a main power mismatch. To change this behavior, use:

          set mv_no_main_power_violations false
            (current value is mv_no_main_power_violations=$mv_no_main_power_violations)

        Note: Allowing main rail violations for LS will defer the issues until layout. You will need to create 
        an exclusive movebound to place these level shifters in IC Compiler. Review this strategy with the back end team.
        Other options include keeping this variable true and adding an adjacent power domain with proper main rail to
        locate the level shifters (see dhm_upf example design).

      ## -------------------------------------

      "
      redirect -append $options(-report).debug_level_shifters {
        puts $tip_text
        eval $cmd
        report_timing -through $source_pin -through $sink_pin -att -net -in
      }
    }
    if { [regexp {Warning: Always on net '(\S*)'.*MV-076.*} $line match ao_net] } {
      set error_mv076_found 1
      set cmd "analyze_mv_design -always_on -verbose -net $ao_net"
      sproc_msg -warning "$cmd"
      redirect -append $options(-report).debug_always_on {
        eval $cmd
        report_timing -input -net -att -through $ao_net
      }
    }
  }

  close $fid
  if { $error_mv231_found } {
    sproc_msg -error "sproc_screen_mv_debugger detected MV-231 issues in $options(-report). See analyze_mv_design debug info in file $options(-report).debug_level_shifters"
  }
  if { $error_mv076_found } {
    sproc_msg -error "sproc_screen_mv_debugger detected MV-076 issues in $options(-report). See analyze_mv_design debug info in file $options(-report).debug_always_on"
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_screen_mv_debugger \
  -info "Routine to check report for issues and begin first order detail of cause" \
  -define_args {
  {-report "check_mv_design report" "" string required}
}

## -----------------------------------------------------------------------------
## sproc_get_retention_registers:
## -----------------------------------------------------------------------------

proc sproc_get_retention_registers { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  parse_proc_arguments -args $args options

  set retention_registers [ add_to_collection "" "" ]

  set power_domains [get_power_domains -hier *]
  redirect -variable report { report_retention_cell -domain $power_domains }
  set lines [split $report "\n"]
  set state "unlocked"
  foreach line $lines {
    if { ( $state == "unlocked" ) && [regexp {^\| Ret Cell Name} $line] } {
      set state "locking"
    } elseif { ( $state == "locking" ) && [regexp {^-------------------} $line] } {
      set state "locked"
    } elseif { ( $state == "locking" ) } {
      set state "unlocked"
    } elseif { ( $state == "locked" ) } {
      set inst_name ""
      regexp {(\s*)([\w\.\/]+)\s+} $line inst_name
      set retention_reg [get_cells -quiet $inst_name]
      if { [sizeof $retention_reg] == 1 } {
        set retention_registers [ add_to_collection $retention_registers $retention_reg ]
      } else {
        set state "unlocked"
      }
    }
  }

  sproc_pinfo -mode stop
  return $retention_registers

}

define_proc_attributes sproc_get_retention_registers \
  -info "Return a collection of retention registers." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_get_switch_cells :
## -----------------------------------------------------------------------------

proc sproc_get_switch_cells { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  parse_proc_arguments -args $args options

  ## build a list of ref_names for the header cells in the design
  set header_cell_ref_names ""
  redirect -variable report { report_power_switch [get_power_switches * -hierarchical] }
  set lines [split $report "\n"]
  foreach line $lines {
    if { [regexp {^Lib Cell Name} $line] } {
      set line [ regsub {^.*\/} $line "" ]
      set header_cell_ref_names "$header_cell_ref_names $line"
      echo "$line"
    }
  }
  set header_cell_ref_names [ sproc_uniquify_list -list $header_cell_ref_names ]

  ## now build a collection of header cells
  set all_cells [ get_cells -hier * -quiet]
  set header_cells [ add_to_collection "" "" ]
  foreach header_cell_ref_name $header_cell_ref_names {
    set header_cells [ append_to_collection $header_cells [ filter_collection $all_cells "ref_name==$header_cell_ref_name" ] ]
  }

  sproc_pinfo -mode stop
  return $header_cells

}

define_proc_attributes sproc_get_switch_cells \
  -info "Return a collection of header cells." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_get_ippd_diode:
## -----------------------------------------------------------------------------

proc sproc_get_ippd_diode { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  sproc_msg -info "sproc_get_ippd_diode : starting execution"

  ## Get arguments
  parse_proc_arguments -args $args options

  set scenarios [all_active_scenarios]

  if { ( [llength $scenarios] > 0 ) } {
    sproc_msg -info "sproc_get_ippd_diode : mcmm mode"

    set tmp [sproc_get_spec_info -info cell -spec $SVAR(libsetup,diode_cell)]
    set the_diode_cell [ get_lib_cells -scenario [current_scenario] */$tmp ]
    set the_diode_cell [ collection_to_list -name_only -no_braces [ index_collection $the_diode_cell 0 ] ]

  } else {
    sproc_msg -error "sproc_get_ippd_diode : non mcmm mode ... this shouldn't occur as the flow is fulltime MCMM."
  }

  if { [llength $the_diode_cell] == 1 } {
    sproc_msg -info "sproc_get_ippd_diode : $the_diode_cell identified for usage."
    set return_value $the_diode_cell
  } else {
    sproc_msg -error "sproc_get_ippd_diode : no diode identified for usage."
    set return_value ""
  }

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_get_ippd_diode \
  -info "Determine the diode to use for IPPD." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_screen_alib_issues:
## -----------------------------------------------------------------------------

proc sproc_screen_alib_issues { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-log_file) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-log_file)] } {
    sproc_msg -error "sproc_screen_alib_issues: Could not find DC log file $options(-log_file)"
  }

  set problems 0

  set fid [open $options(-log_file) r]

  sproc_msg -info "sproc_screen_alib_issues: Screening for evidence of lengthy alib analysis in log file $options(-log_file)"
  while { [gets $fid line] >= 0 } {
    if { [regexp {SYS.MACHINE\s+\|\s+(\w+)} $line match machine] } {
      sproc_msg -info "sproc_screen_alib_issues: running on host $machine"
    }
    if { [regexp {Analyzing:\s+(.+)} $line match lib] } {
      regsub {"} $lib {} clean_lib
      set lib [file tail $clean_lib]
      sproc_msg -info "sproc_screen_alib_issues: lengthy alib analysis occuring for $lib"
      incr problems
    } 
    if { [regexp {^Warning:.*OPT-1311} $line match] } {
      ## avoiding use of string in message to avoid error message loop
      sproc_msg -info "sproc_screen_alib_issues: OPT_1311 message seen"
      incr problems
    }
    if { [regexp {^Warning:.*OPT-1310} $line match] } {
      ## avoiding use of string in message to avoid error message loop
      sproc_msg -info "sproc_screen_alib_issues: OPT_1310 message seen"
      incr problems
    }
  }
  close $fid

  sproc_pinfo -mode stop
  return $problems
}

define_proc_attributes sproc_screen_alib_issues \
  -info "Checks DC log file for indication of unexpected alib issues which can increase runtime"  \
  -define_args {
  {-log_file "DC log file" "" string required}
}

## -----------------------------------------------------------------------------
## sproc_load_lppi:
## -----------------------------------------------------------------------------

proc sproc_load_lppi { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global search_path link_path_per_instance link_path
  global lut_wc_lib_to_other_lib

  set options(-file)    ""
  set options(-scope)   NULL
  set options(-oc_type) ""

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Make sure file exists
  ## -------------------------------------

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The link_path_per_instance file does not exist."
    sproc_msg -error "  $options(-file)"
    sproc_script_stop -exit
  }

  ## -------------------------------------
  ## Save the original link_path and link_path_per_instance value
  ## -------------------------------------

  set original_lppi $link_path_per_instance
  set original_link_path $link_path
  set link_path [list]

  ## -------------------------------------
  ## Load the new link_path_per_instance value
  ## -------------------------------------

  set link_path_per_instance {{NULL NULL}}

  sproc_msg -info "Loading link_path_per_instance file $options(-file)"
  sproc_source -file $options(-file)

  if { $link_path_per_instance == {NULL NULL} } {
    sproc_msg -error "Sourcing the file $options(-file) did not set the link_path_per_instance variable."
    sproc_script_stop -exit
  }

  ## -------------------------------------
  ## Update the scope for link_path_per_instance
  ## -------------------------------------
  if { $options(-scope) == "NULL" } {
    ## Handling of top level LPPI load
    set new_lppi $link_path_per_instance
    set new_path [list]
    if { $link_path != "" } {
      sproc_msg -info "Detected link_path entry in the top level link_path_per_instance file. Checking against existing link_path."
      if { $options(-oc_type) != "" } {
        ## link_path libraries must be first mapped to existing operation condition
        foreach p $link_path {
          if { $p == "*" } {
            set new_p "*"
          } else {
            if { [info exists lut_wc_lib_to_other_lib($options(-oc_type),$p)] } {
              set new_p $lut_wc_lib_to_other_lib($options(-oc_type),$p)
            } else {
              sproc_msg -error "A worst_case-to-$options(-oc_type) mapping does not exist for:"
              sproc_msg -error "  $p"
              sproc_pinfo -mode stop
              return
            }
          }
          set new_path [concat $new_path $new_p]
        } 
        set link_path $new_path
      }
    }
  } else {
    ## Handling of instance LPPI loading
    set new_lppi [list]
    if { $link_path != "" } {
      sproc_msg -info "Detected link_path entry in link_path_per_instance file. Adding as a link_path_per_instance element for $options(-scope)"
      lappend new_lppi [list $options(-scope) $link_path]
    }
    sproc_msg -info "Adding instance scope $options(-scope) to each link_path_per_instance element for $options(-file)"
    foreach original_item $link_path_per_instance {
      set new_inst_list ""
      set original_inst_list [lindex $original_item 0]
      set original_lib_list [lindex $original_item 1]
      foreach inst $original_inst_list {
        set new_inst_list [concat $new_inst_list $options(-scope)/$inst]
      }
      set new_item [list $new_inst_list $original_lib_list]

      lappend new_lppi $new_item
    }
  }

  ## -------------------------------------
  ## Accumulate link_path_per_instance across loads
  ## -------------------------------------

  set link_path_per_instance "$original_lppi $new_lppi"

  ## -------------------------------------
  ## Map link_path_per_instance to required oc_type
  ## -------------------------------------

  if { $options(-scope) == "NULL" && $options(-oc_type) != "" } {
    set new_lppi $link_path_per_instance
    foreach nm [array names lut_wc_lib_to_other_lib] {
      if {[regsub $options(-oc_type), $nm {} ref_lib]} {
        lappend libs_to_replace $ref_lib
      }
    }
    if {[llength $libs_to_replace] > 0} {
      foreach lb $libs_to_replace {
        set replacement_lib $lut_wc_lib_to_other_lib($options(-oc_type),$lb)
        if { [regsub -all $lb $new_lppi $replacement_lib new_lppi] } {
          sproc_msg -info "Replaced $lb with $replacement_lib"
        }
      }
      set link_path_per_instance $new_lppi
    } else {
      sproc_msg -error "Problem finding any reference libraries to map to request operating condition"
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_load_lppi \
  -info "Load rather that source link_path_per_instance with options to control how it is applied" \
  -define_args {
  {-file  "The link_path_per_instance file." AString string required}
  {-scope  "Alter the link_path_per_instance to apply to provided instance path" AString string optional}
  {-oc_type  "Maps any link_path content present in the lppi file from WC to specified OC_TYPE" AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_set_scenario_options_stack:
## -----------------------------------------------------------------------------

proc sproc_set_scenario_options_stack { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-debug) 1

  set options(-mode) "save"
  set options(-fname) "./report_scenario_options.rpt"

  parse_proc_arguments -args $args options

  sproc_msg -info "sproc_set_scenario_options_stack mode = '$options(-mode)' fname = '$options(-fname)'"

  if { $options(-mode) == "save" } {

    redirect $options(-fname) {
      report_scenario_options -scenarios [all_scenarios]
    }
    set_scenario_options -scenarios [all_scenarios] -reset_all true

  } elseif { $options(-mode) == "restore" } {

    if { $options(-debug) } {
      redirect $options(-fname).restore.pnt1 {
        report_scenario_options -scenarios [all_scenarios]
      }
    }

    set fid [open $options(-fname) r]
    set cntl 0
    while { [gets $fid line] >= 0 } {
      if { ( $cntl == 0 ) && [regexp "Scenario: " $line] } {
        set cntl 1
        regsub {^Scenario: } $line "" line
        regsub " .*$" $line "" line
        set new_line "set_scenario_options -scenarios $line"
      } elseif { ( $cntl == 1 ) && [regexp "^(\s)*$" $line] } {
        eval $new_line
        set cntl 0
      } elseif { $cntl == 1 } {
        regsub {^\s+} $line "-" line
        regsub {\s+:\s+} $line " " line
        set new_line "$new_line $line"
      }
    }
    close $fid

    if { $options(-debug) } {
      redirect $options(-fname).restore.pnt2 {
        report_scenario_options -scenarios [all_scenarios]
      }
    }

  } elseif { $options(-mode) == "report" } {
    redirect $options(-fname) {
      report_scenario_options -scenarios [all_scenarios]
    }

  } else {
    sproc_msg -error "sproc_set_scenario_options_stack -mode = $options(-mode) is illegal"
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_set_scenario_options_stack \
  -info "Utility to assist w/ saving and restoring set_scenario_options state used for some work arounds." \
  -define_args {
  {-fname    "File from which to save / restore set_scenario_options state." AString string  required}
  {-mode     "report / save / restore set_scerario_options state [report,save,restore]" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_distributed_job_args
## -----------------------------------------------------------------------------

proc sproc_distributed_job_args { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-file)  ""
  parse_proc_arguments -args $args options

  if { !$SEV(job_enable) } {
    sproc_msg -error "Job distribution is not enabled."
    return
  }

  sproc_msg -info "Examining file $options(-file)"

  set fid [open $options(-file) r]
  set lines [read $fid]
  close $fid
  set lines [split $lines \n]
  set original_job_command_line ""
  foreach line $lines {
    set app [file tail [lindex $line 0]]
    if { ($app == "bsub") || ($app == "aro_sub_lsf") || ($app == "qsub") || ($app == "aro_sub_grd") } {
      set original_job_command_line $line
    }
  }
  if { $original_job_command_line == "" } {
    sproc_msg -error "Unable to determine original_job_command_line"
  }

  set new_app_args ""

  switch $SEV(job_app) {

    lsf {

      ## -------------------------------------
      ## Keep these arguments:
      ## -------------------------------------

      if { [regexp {\-P\s+(\S+)} $original_job_command_line match project_name] } {
        set new_app_args "$new_app_args -P $project_name"
      }
      if { [regexp {\-J\s+(\S+)} $original_job_command_line match job_name] } {
        set new_app_args "$new_app_args -J $job_name.CHILD"
      }
      if { [regexp {\-q\s+(\S+)} $original_job_command_line match queue_name] } {
        if { $SEV(job_queue_child) != "" } {
          set queue_name $SEV(job_queue_child)
        }
        set new_app_args "$new_app_args -q $queue_name"
      }
      if { [regexp {\-o\s+(\S+)} $original_job_command_line match output_option] } {
        set new_app_args "$new_app_args -o $output_option"
      }
      if { [regexp {\-R\s+('[^']+')} $original_job_command_line match resource_option] } {
        set new_app_args "$new_app_args -R $resource_option"
      }

      ## -------------------------------------
      ## Discard this argument if present:
      ## -------------------------------------

      if { [regexp {span\[hosts=1\]} $new_app_args] } {
        sproc_msg -warning "Detected and suppressing 'span\[hosts=1\]' while developing bsub arguments."
        regsub {span\[hosts=1\]} $new_app_args {} new_app_args 
      }

    }

    grd {

      ## -------------------------------------
      ## Keep these arguments:
      ## -------------------------------------

      if { [regexp {\-P\s+(\S+)} $original_job_command_line match project_name] } {
        set new_app_args "$new_app_args -P $project_name"
      }
      if { [regexp {\-N\s+(\S+)} $original_job_command_line match job_name] } {
        set new_app_args "$new_app_args -N $job_name.CHILD"
      }

      if { [regexp {\-o\s+(\S+)} $original_job_command_line match value] } {
        set new_app_args "$new_app_args -o $value"
      }
      if { [regexp {\-e\s+(\S+)} $original_job_command_line match value] } {
        set new_app_args "$new_app_args -e $value"
      }

      if { [regexp {\-l\s+(\S+)} $original_job_command_line match resource_option] } {
        ## Make sure we have matching ' characters around the resource
        set resource_option [regsub -all {'} $resource_option ""]
        set resource_option "'$resource_option'"
        set new_app_args "$new_app_args -l $resource_option"
      }

      ## -------------------------------------
      ## Discard this argument if present:
      ## -------------------------------------

      if { [regexp {\-pe\s+\S+\s+\d+} $new_app_args] } {
        sproc_msg -warning "Detected and suppressing '-pe <pe_name> N' while developing qsub arguments."
      }

    }

    default {
      sproc_msg -error "Unrecognized value $SEV(job_app) for SEV(job_app)"
      return
    }

  }

  sproc_msg -info "New arguments for distributed processing: "
  sproc_msg -info "  '$new_app_args'"

  sproc_pinfo -mode stop

  return $new_app_args

}

define_proc_attributes sproc_distributed_job_args \
  -info "Procedure for computing arguments for distributed jobs." \
  -define_args {
  {-file "rtm_job_cmd file to build arguments from" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_pv_distributed_job_args
## -----------------------------------------------------------------------------

proc sproc_pv_distributed_job_args { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-in_design) 0
  set options(-pylcc) 0

  parse_proc_arguments -args $args options

  set total_number_cores [expr $TEV(num_child_hosts) * $TEV(num_child_cores_per_host)]

  if { $TEV(distributed_job_args) == "" } {
    set fname [file rootname $SEV(log_file)].rtm_job_cmd
    set job_args [sproc_distributed_job_args -file $fname]
  } else {
    set job_args $TEV(distributed_job_args)
  }

  switch $SEV(job_app) {
    lsf {
      ## Remove arguments that icvlsf does not accept.
      set job_args [regsub {\-P\s+\S+} $job_args {}]
      set job_args [regsub {\-J\s+\S+} $job_args {}]
      set job_args [regsub {\-o\s+\S+} $job_args {}]

      if { $options(-in_design) } {
        if { $options(-pylcc) } {
      set host_options_args " \
        -submit_command $SEV(gscript_dir)/finish/Herculeslsf \
        -submit_options {-dp$total_number_cores -cpu$TEV(num_child_cores_per_host)=$TEV(num_child_hosts) -wait $job_args} \
          "
        } else {
      set host_options_args " \
        -submit_command $SEV(gscript_dir)/finish/icvlsf \
        -submit_options {-dp$total_number_cores -cpu$TEV(num_child_cores_per_host)=$TEV(num_child_hosts) $job_args} \
          "
}
      }
    }
    grd {
      ## Remove arguments that icvgrid does not accept.
      set job_args [regsub {\-N\s+\S+} $job_args {}]

      ## Add job_dist setup file.
      set job_args "$job_args -conf $SEV(gscript_dir)/finish/icvgrid.sh"

      if { $options(-in_design) } {
        if { $options(-pylcc) } {
      set host_options_args " \
        -submit_command $SEV(gscript_dir)/finish/Herculesgrid \
        -submit_options {-dp$total_number_cores -cpu$TEV(num_child_cores_per_host)=$TEV(num_child_hosts) -wait $job_args} \
          "
        } else {
      set host_options_args " \
        -submit_command $SEV(gscript_dir)/finish/icvgrid \
        -submit_options {-dp$total_number_cores -cpu$TEV(num_child_cores_per_host)=$TEV(num_child_hosts) $job_args} \
          "
}
      }
    }
    default {
      sproc_msg -error "Unrecognized value $SEV(job_app) for SEV(job_app)"
      sproc_script_stop -exit
    }
  }

  set job_args "$job_args -dp$total_number_cores"
  set job_args "$job_args -cpu$TEV(num_child_cores_per_host)=$TEV(num_child_hosts)"
  set job_args "$job_args -wait"

  sproc_pinfo -mode stop

  if { $options(-in_design) } {
    return $host_options_args
  } else {
    return $job_args
  }

}

define_proc_attributes sproc_pv_distributed_job_args \
  -info "Procedure for computing arguments for PV distributed jobs." \
  -define_args {
  {-in_design "If set to 1, builds arguments for set_host_options." "" boolean optional}
  {-pylcc "Points to Hercules based job distribution utility for LCC runs." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_icc_create_qor_snapshot:
## -----------------------------------------------------------------------------

proc sproc_icc_create_qor_snapshot { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-name) "unnamed"
  set options(-flags) "-clock_tree -power"

  parse_proc_arguments -args $args options

  ##
  ## It doesn't make a lot of sense to generate qor snapshot in parallel
  ## reporting. It makes more sense to generate them during the mainline.
  ## hence some example logic to skip provide below but not used (ie
  ## commented out.  Possibly will revist in the future.
  ##
  set skip 0

  if { $skip } {
    sproc_msg -warning "sproc_icc_create_qor_snapshot has been configured to skip create_qor_snapshot."
  } else {
    set t1 [clock seconds]
    eval create_qor_snapshot -name $options(-name) $options(-flags)
    set t2 [clock seconds]
    set t3 [expr $t2 - $t1]
    sproc_msg -info "sproc_icc_create_qor_snapshot : elapsed time of create_qor_snaphot = $t3 seconds."
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_icc_create_qor_snapshot \
  -info "Utility to centalize create_qor_snapshot calls to assist with some stability work arounds." \
  -define_args {
  {-name    "The name of the snapshot to be created." AString string  required}
  {-flags   "Optional flags to pass to create qor snapshot." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_persistent_set_app_var:
## -----------------------------------------------------------------------------

proc sproc_persistent_set_app_var { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global SF

  ## -------------------------------------
  ## Case 1: sproc_persistent_set_app_var -name foo
  ##   Set variable 'foo' to value of side file variable 'SF(foo)' if the side file variable exists.
  ##
  ## Case 2: sproc_persistent_set_app_var -name foo -value bar
  ##   Set variable 'foo' to 'bar'.
  ##   Set variable 'SF(foo)' to 'bar'.
  ##
  ## For both of the above cases, the '-non_app_var' switch controls
  ## processing of 'foo' per app_var or non-app_var conventions.
  ## -------------------------------------

  set restore_command LYNX_RESTORE_VAR

  set options(-value) $restore_command
  set options(-non_app_var) 0
  parse_proc_arguments -args $args options

  eval upvar #0 $options(-name) $options(-name)

  if { $options(-value) == $restore_command } {

    ## Set variable specified by options(-name) to value of side file variable

    if { [info exists SF($options(-name))] } {
      if { $options(-non_app_var) } {
        set $options(-name) $SF($options(-name))
        sproc_msg -info "sproc_persistent_set_app_var : Executed 'set $options(-name) $SF($options(-name))'"
      } else {
        set_app_var $options(-name) $SF($options(-name))
        sproc_msg -info "sproc_persistent_set_app_var : Executed 'set_app_var $options(-name) $SF($options(-name))'"
      }
    } else {
      sproc_msg -warning "sproc_persistent_set_app_var : Attempted to set '$options(-name)' from persistent storage, but no value found."
    }

  } else {

    ## Set variable specified by options(-name) to value of options(-value)

    if { [info exists SF($options(-name))] } {
      sproc_msg -warning "sproc_persistent_set_app_var : Overwriting prior value of '$options(-name)' in persistent storage."
    } else {
      sproc_msg -warning "sproc_persistent_set_app_var : Creating value for '$options(-name)' in persistent storage."
    }

    set SF($options(-name)) $options(-value)
    if { $options(-non_app_var) } {
      set $options(-name) $options(-value)
      sproc_msg -info "sproc_persistent_set_app_var : Executed 'set $options(-name) $options(-value)'"
    } else {
      set_app_var $options(-name) $options(-value)
      sproc_msg -info "sproc_persistent_set_app_var : Executed 'set_app_var $options(-name) $options(-value)'"
    }

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_persistent_set_app_var \
  -info "Used to read and store user defined attributes onto a database." \
  -define_args {
  {-name    "The name of the variable." AString string required}
  {-value   "The value of the variable to be stored on the MW." AString string optional}
  {-non_app_var "If set to 1, the variable is treated as a non-app_var." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_clone_scenario_icc :
## -----------------------------------------------------------------------------

proc sproc_clone_scenario_icc { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-ref_scenario)  ""
  set options(-new_scenario)  ""
  set options(-user_sdc)  "undefined"
  set options(-user_saif)  "undefined"
  set options(-user_important)  "undefined"
  parse_proc_arguments -args $args options

  set fname "$SEV(dst_dir)/$SVAR(design_name).$options(-ref_scenario).write_script"

  ## generate most info from ref_scenario for future leverage
  if { [ get_scenarios -active true $options(-ref_scenario) ] == "" } {
    set_active_scenarios "[all_active_scenario] $options(-ref_scenario)"
  }
  current_scenario $options(-ref_scenario)
  write_script \
    -no_annotated_check -no_annotated_delay -no_cg \
    -nosplit -format dctcl -output $fname

  ## filter reference material into SDC, SAEF, important, etc.
  sproc_filter_write_script -infile $fname

  ## create new scenario and start to construct it, allow for user overrides
  sproc_msg -info " About to create scenario \"$options(-new_scenario)\" from"
  if { $options(-user_sdc) == "undefined" } {
    set options(-user_sdc) "$fname.flt.sdc"
    sproc_msg -info "   Machine SDC : \"$options(-user_sdc)\""
  } else {
    sproc_msg -info "   User SDC : \"$options(-user_sdc)\""
  }
  if { $options(-user_saif) == "undefined" } {
    set options(-user_saif) "$fname.flt.saif"
    sproc_msg -info "   Machine SAIF : \"$options(-user_saif)\""
  } else {
    sproc_msg -info "   User SAIF : \"$options(-user_saif)\""
  }
  if { $options(-user_important) == "undefined" } {
    set options(-user_important) "$fname.flt.important"
    sproc_msg -info "   Machine Important : \"$options(-user_important)\""
  } else {
    sproc_msg -info "   User Important : \"$options(-user_important)\""
  }
  create_scenario $options(-new_scenario)
  sproc_source -file $options(-user_sdc) -optional
  sproc_source -file $options(-user_saif) -optional
  sproc_source -file $options(-user_important) -optional

  ## apply new scenario OC and RC
  set OC_TYPE [sproc_get_scenario_info -scenario $options(-new_scenario) -type oc_type]
  set RC_TYPE [sproc_get_scenario_info -scenario $options(-new_scenario) -type rc_type]
  sproc_set_operating_conditions -oc_type $OC_TYPE -oc_mode ocv
  sproc_set_tlu_plus_files -rc_type $RC_TYPE

  ## recreate scenario options
  if { [get_scenarios -setup true $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -setup true
  } else {
    set_scenario_options -scenario $options(-new_scenario) -setup false
  }

  if { [get_scenarios -hold true $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -hold true
  } else {
    set_scenario_options -scenario $options(-new_scenario) -hold false
  }

  if { [get_scenarios -leakage_power true $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -leakage_power true
  } else {
    set_scenario_options -scenario $options(-new_scenario) -leakage_power false
  }

  if { [get_scenarios -dynamic_power true $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -dynamic_power true
  } else {
    set_scenario_options -scenario $options(-new_scenario) -dynamic_power false
  }

  if { [get_scenarios -cts_mode true $options(-ref_scenario)] == "" } {
    set_scenario_options -scenario $options(-new_scenario) -cts_mode false
  } else {
    set_scenario_options -scenario $options(-new_scenario) -cts_mode true
  }

  if { [get_scenarios -cts_corner max $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -cts_corner max
  } elseif { [get_scenarios -cts_corner min $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -cts_corner min
  } elseif { [get_scenarios -cts_corner min_max $options(-ref_scenario)] != "" } {
    set_scenario_options -scenario $options(-new_scenario) -cts_corner min_max
  } else {
    set_scenario_options -scenario $options(-new_scenario) -cts_corner none
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_clone_scenario_icc  \
  -info "Procedure used to clone (create) one scenario from a pre existing scenario." \
  -define_args {
  {-ref_scenario  "The reference scenario " AString string required}
  {-new_scenario  "The new scenario " AString string required}
  {-user_sdc  "User supplied SDC content from which to create the new scenario " AString string optional}
  {-user_saif  "User supplied SAIF content from which to create the new scenario " AString string optional}
  {-user_important  "User supplied important content from which to create the new scenario " AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_filter_write_script:
## -----------------------------------------------------------------------------

proc sproc_filter_write_script { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-infile)  ""
  set options(-outfile)  ""
  set options(-debug)  0
  parse_proc_arguments -args $args options

  if { $options(-outfile)  == "" } {
    set options(-outfile) "$options(-infile).flt"
  }

  set fid_r [open $options(-infile) r]

  set fid_w_sdc       [open $options(-outfile).sdc w]
  set fid_w_saif      [open $options(-outfile).saif w]
  set fid_w_important [open $options(-outfile).important w]

  if { $options(-debug) } {
    set fid_w_sdc_object      [open $options(-outfile).sdc.object w]
    set fid_w_sdc_basic       [open $options(-outfile).sdc.basic w]
    set fid_w_sdc_secondary   [open $options(-outfile).sdc.secondary w]
    set fid_w_sdc_environment [open $options(-outfile).sdc.environment w]
    set fid_w_sdc_ambiguous   [open $options(-outfile).sdc.ambiguous w]
    set fid_w_other           [open $options(-outfile).other w]
  }

  ##
  ## sort out the write_script content into
  ##   sdc  : minus set_operating_conditions
  ##   saif
  ##
  while { ( [gets $fid_r line] >= 0 ) } {
    switch -regexp $line {

      {^all_clocks} -
      {^all_inputs} -
      {^all_outputs} -
      {^all_registers} -
      {^current_design} -
      {^current_instance} -
      {^get_cells} -
      {^get_clocks} -
      {^get_libs} -
      {^get_lib_cells} -
      {^get_lib_pins} -
      {^get_nets} -
      {^get_pins} -
      {^get_ports} -
      {^set_hierarchy_separator} {
        ## slice out the SDC "object access functions" content

        ## note these are "object access" and would be used by other SDC commands and would
        ## be the operative command being executed.  as such we don't wish to capture lines
        ## that begin with this (eg current_design foo).  left here for debug only
        ## >> puts $fid_w_sdc $line

        if { $options(-debug) } {
          puts $fid_w_sdc_object $line
        }
      }

      {^create_clock} -
      {^create_generated_clock} -
      {^group_path} -
      {^set_clock_gating_check} -
      {^set_clock_groups} -
      {^set_clock_latency} -
      {^set_clock_sense} -
      {^set_clock_transition} -
      {^set_clock_uncertainty} -
      {^set_false_path} -
      {^set_ideal_latency} -
      {^set_ideal_transition} -
      {^set_input_delay} -
      {^set_max_delay} -
      {^set_min_delay} -
      {^set_multicycle_path} -
      {^set_output_delay} -
      {^set_propagated_clock} {
        ## slice out the SDC "basic timing assertions" content
        puts $fid_w_sdc $line
        if { $options(-debug) } {
          puts $fid_w_sdc_basic $line
        }
      }

      {^set_disable_timing} -
      {^set_max_time_borrow} {
        ## slice out the SDC "secondary timing assertions" content
        puts $fid_w_sdc $line
        if { $options(-debug) } {
          puts $fid_w_sdc_secondary $line
        }
      }

      {^create_voltage_area} -
      {^set_case_analysis} -
      {^set_driving} -
      {^set_driving_cell} -
      {^set_fanout_load} -
      {^set_input_transition} -
      {^set_ideal_network} -
      {^set_level_shifter_strategy} -
      {^set_level_shifter_threshold} -
      {^set_load\s+(?![\d])} -
      {^set_logic_dc} -
      {^set_logic_one} -
      {^set_logic_zero} -
      {^set_max_area} -
      {^set_max_capacitance} -
      {^set_max_dynamic_power} -
      {^set_max_fanout} -
      {^set_max_leakage_power} -
      {^set_max_transition} -
      {^set_min_capacitance} -
      {^set_min_fanout} -
      {^set_min_porosity} -
      {^set_operating_conditions} -
      {^set_port_fanout_number} -
      {^set_resistance\s+(?![\d])} -
      {^set_wire_load_min_block_size} -
      {^set_wire_load_mode} -
      {^set_wire_load_model} -
      {^set_wire_load_selection_group} {
        ## slice out the SDC "environment assertions" content
        puts $fid_w_sdc $line
        if { $options(-debug) } {
          puts $fid_w_sdc_environment $line
        }
      }

      {^set_timing_derate} -
      {^set_units} {
        ## slice out the SDC "ambiguous" content (ie in SDC file but not listed in man page)
        puts $fid_w_sdc $line
        if { $options(-debug) } {
          puts $fid_w_sdc_ambiguous $line
        }
      }

      {^set_switching_activity} {
        ## slice out the saif content
        puts $fid_w_saif $line
      }

      {^set_critical_range} -
      {^set_fix_hold} -
      {^set_latency_adjustment_options} -
      {^set_tlu_plus_files} {
        ## slice out the important layered content for scenario recreation
        puts $fid_w_important $line
      }

      default {
        ## information thought not to be important for scenario recreation
        if { $options(-debug) } {
          puts $fid_w_other $line
        }
      }
    }
  }
  close $fid_r
  close $fid_w_sdc
  close $fid_w_saif
  close $fid_w_important
  if { $options(-debug) } {
    close $fid_w_sdc_object      
    close $fid_w_sdc_basic       
    close $fid_w_sdc_secondary   
    close $fid_w_sdc_environment 
    close $fid_w_sdc_ambiguous 
    close $fid_w_other
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_filter_write_script \
  -info "Procedure to filter write script to assist w/ scenario recreation." \
  -define_args {
  {-infile  "The original write script " AString string required}
  {-outfile  "The original write script " AString string optional}
  {-debug  "Optional debug flag "     ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_retention_register_setup:
## -----------------------------------------------------------------------------

proc sproc_retention_register_setup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global hdlin_upf_library

  ## -------------------------------------
  ## Retention register support requires the usage of tech-specific models.
  ## The procedure sproc_retention_register_setup helps ensure consistency of setup.
  ## The SVAR(pwr,fm_retention_model_mode) directs the behavior of this setup. When
  ## configured as "libery_model", no changes are made during this procedure. When
  ## configured as "sim_model", the tech-specific simulation models are loaded and 
  ## liberty models of those cells are removed from the FM tech lib.
  ## -------------------------------------

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Parse the model file and determine the list of new models.
  ## -------------------------------------

  switch $SVAR(pwr,fm_retention_model_mode) {

    sim_model {
      set rreg_file $SEV(tscript_dir)/formality_models_for_retention_registers.v

      if { ![file exists $rreg_file] } {
        sproc_msg -error "Unable to find file '$rreg_file'."
        return
      }

      set retention_register_list [list]

      set fid [open $rreg_file r]
      while { [gets $fid line] >= 0 } {
        if { [regexp {^module\s+(\w+)\s+\(} $line match retention_register] } {
          lappend retention_register_list $retention_register
        }
      }
      close $fid

      ## -------------------------------------
      ## Remove the old models.
      ## -------------------------------------

      foreach retention_register $retention_register_list {
        set design_list [list]
        set design_list [concat $design_list [find_designs i:/*/$retention_register]]
        foreach design $design_list {
          remove_design -shared_lib $design
          sproc_msg -setup "remove_design -shared_lib $design"
        }
      }

      ## -------------------------------------
      ## Read the new models.
      ## -------------------------------------

      set hdlin_upf_library UPF_LIB
      sproc_msg -setup "set hdlin_upf_library UPF_LIB"

      set filelist "$SEV(tscript_dir)/GENUPFRR.v $rreg_file"

      if { $options(-container) == "r" } {
        read_verilog -r -libname UPF_LIB -technology_library $filelist
        sproc_msg -setup "read_verilog -r -libname UPF_LIB -technology_library \"$filelist\""
      } else {
        read_verilog -i -libname UPF_LIB -technology_library $filelist
        sproc_msg -setup "read_verilog -i -libname UPF_LIB -technology_library \"$filelist\""
      }
    }
    liberty_model {
      sproc_msg -setup "## FM will rely on liberty models for retention cells. See that report_libraries.defects is clean for these cells"
    }
    default {
      sproc_msg -error "Unknown SVAR(pwr,fm_retention_model_mode) setting of $SVAR(pwr,fm_retention_model_mode)"
    }
  }
  sproc_pinfo -mode stop

}

define_proc_attributes sproc_retention_register_setup \
  -info "Library-specific aid for setting up Formality to handle retention registers." \
  -define_args {
  {-container "Choose r or i" AnOos one_of_string
    {required value_help {values {r i}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_cdesigner_open:
## -----------------------------------------------------------------------------

proc sproc_cdesigner_open { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ##
  ## this procedure opens a database in custom designer
  ##

  set options(-library) ""
  set options(-design_name) ""
  parse_proc_arguments -args $args options

  ##
  ## so that we can robustly manage both the MW and the OA database
  ## we are going to require that the env variable
  ##    SYSNOPSYS_CUSTOM_LOCAL
  ## and
  ##    SEV(dst_dir) => options(-library) (minus the MW)
  ## are the same
  ##
  if { [info exists env(SYNOPSYS_CUSTOM_LOCAL)] == 0 } {
    sproc_msg -info "SYNOPSYS_CUSTOM_LOCAL = \"\""
  } else {
    sproc_msg -info "SYNOPSYS_CUSTOM_LOCAL = \"$env(SYNOPSYS_CUSTOM_LOCAL)\""
  }
  sproc_msg -info "         SEV(src_dir) = \"$SEV(src_dir)\""
  sproc_msg -info "         SEV(dst_dir) = \"$SEV(dst_dir)\""
  sproc_msg -info "           MW Library = \"$options(-library)\""

  set error 0
  if { [info exists env(SYNOPSYS_CUSTOM_LOCAL)] == 0 } {
    sproc_msg -error "The env variable SYNOPSYS_CUSTOM_LOCAL variable does not appear to exist."
    incr error
  } elseif { $env(SYNOPSYS_CUSTOM_LOCAL) != [file dirname $options(-library)] } {
    sproc_msg -error "The env SYNOPSYS_CUSTOM_LOCAL != SEV(dst_dir)"
    incr error
  } elseif { $SEV(src_dir) != $SEV(dst_dir) } {
    sproc_msg -error "SEV(src_dir) does not equal SEV(dst_dir)"
    incr error
  } 

  if { $error > 0 } {

    sproc_msg -error "There are a few rules so that we can robustly manage the MW and the OA database"
    sproc_msg -error "  a) SEV(src_dir) should equal SEV(dst_dir)"
    sproc_msg -error "  b) the env SYNOPSYS_CUSTOM_LOCAL should equal SEV(dst_dir)"

  } elseif { [file exist $env(SYNOPSYS_CUSTOM_LOCAL)/iccbridge] } {

    sproc_msg -warning "Re-using a pre-existing iccbridge found at \"$env(SYNOPSYS_CUSTOM_LOCAL)/iccbridge]\""

    dm::showLibraryManager

    gi::setCurrentIndex {libs} -index "$options(-design_name)" -in [gi::getWindows 1]
    gi::setItemSelection {libs} -index "$options(-design_name)" -in [gi::getWindows 1]

    gi::setCurrentIndex {cells} -index "$options(-design_name)" -in [gi::getWindows 1]
    gi::setItemSelection {cells} -index "$options(-design_name)" -in [gi::getWindows 1]

    gi::setCurrentIndex {views} -index {layout} -in [gi::getWindows 1]
    gi::setItemSelection {views} -index {layout} -in [gi::getWindows 1]
    gi::executeAction dmOpen -in [gi::getWindows 1]

  } else { 

    set SNPS_OA_translation_time1 [clock seconds]

    dm::showLibraryManager
    dm::showAddLibrary -parent 1

    gi::setField {libDir} -value "$options(-library)" -in [gi::getDialogs {dmAddLibrary} -parent [gi::getWindows 1]]
    gi::setField {libName} -value "$options(-design_name)" -in [gi::getDialogs {dmAddLibrary} -parent [gi::getWindows 1]]

    gi::pressButton {ok} -in [gi::getDialogs {dmAddLibrary} -parent [gi::getWindows 1]]

    gi::setItemSelection {libs} -index "$options(-design_name)" -in [gi::getWindows 1]
    gi::setItemSelection {cells} -index "$options(-design_name)" -in [gi::getWindows 1]
    gi::setItemSelection {views} -index {layout} -in [gi::getWindows 1]
    gi::executeAction dmOpen -in [gi::getWindows 1]

    set SNPS_OA_translation_time2 [clock seconds]
    set SNPS_OA_translation_time3 [ expr $SNPS_OA_translation_time2 - $SNPS_OA_translation_time1 ]
    sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.OA_TRANSLATION | $SNPS_OA_translation_time3"

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_cdesigner_open \
  -info "Procedure to open a database in custom designer." \
  -define_args {
  {-library "Source milkyway library" AString string required}
  {-design_name "Design to open"     AString string required}
}

## -----------------------------------------------------------------------------
## sproc_cdesigner_cleanup:
## -----------------------------------------------------------------------------

proc sproc_cdesigner_cleanup { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## -------------------------------------
  ## This procedure cleans up after a cdesigner task
  ## -------------------------------------

  global SEV SVAR hdlin_upf_library

  parse_proc_arguments -args $args options

  ## create a parsable log file
  set fname "$SEV(dst_dir)/cdesigner.log"
  sproc_msg -info "Creating a Lynx parseable log file from \"$fname\"."
  set fid_in [open $fname r]
  set fid_out [open $SEV(dst_dir)/cdesigner.log.clean w]
  while { [gets $fid_in line] >= 0 } {
    set line [string range $line 17 end]
    puts $fid_out $line
  }
  close $fid_in
  close $fid_out
  file copy -force $SEV(dst_dir)/cdesigner.log.clean $SEV(log_file) 

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_cdesigner_cleanup \
  -info "Library-specific aid for setting up Formality to handle cdesigner_cleanup registers." \
  -define_args { 
}

## -----------------------------------------------------------------------------
## sproc_cdesigner_cleanup:
## -----------------------------------------------------------------------------

proc sproc_get_test_modes { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global hdlin_upf_library

  parse_proc_arguments -args $args options

  set test_modes [list]
  redirect -var report { list_test_modes }
  set lines [split $report "\n"]
  foreach line $lines {
    if { [regexp {^.*Name: (.*)} $line match name] } {
      if { $name!="Mission_mode" } {
        lappend test_modes $name
      }
    } 
  }
  return $test_modes
  sproc_pinfo -mode stop
}

define_proc_attributes sproc_get_test_modes \
  -info "get a list of all the test_modes on the current database" \
  -define_args { 
}

## -----------------------------------------------------------------------------
## sproc_focal_opt_report_constraint_preprocessor :
## -----------------------------------------------------------------------------

proc sproc_focal_opt_report_constraint_preprocessor { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-fname_in) ""
  set options(-fname_out) ""
  set options(-violation_type) ""
  parse_proc_arguments -args $args options

  set fid_in [open $options(-fname_in) r]
  set fid_out [open $options(-fname_out) w]

  ##
  ## state
  ##  undefined : searching
  ##  max_delay : max_delay extraction and format conversion
  ##  min_delay :  min_delay extraction and format conversion
  ##  max_transition : max_transition extraction and format conversion
  ##
  set state undefined
  while { ( [gets $fid_in line] >= 0 ) } {
    switch $state {
      undefined { 
        if { ( $options(-violation_type) == "max_delay" ) && [regexp {^\s+max_delay} $line] } { 
          set state max_delay
          while { [regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line] == 0 } {
            gets $fid_in line
          }
        } elseif { ( $options(-violation_type) == "min_delay" ) && [regexp {^\s+min_delay} $line] } { 
          set state min_delay
          while { [regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line] == 0 } {
            gets $fid_in line
          }
        } elseif { ( $options(-violation_type) == "max_transition" ) && [regexp {^\s+max_transition} $line] } { 
          set state max_transition
          while { [regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line] == 0 } {
            gets $fid_in line
          }
        }
      }
      max_delay { 
        if { [regexp {^$} $line] } { 
          set state undefined
        } else {
          set line [ regsub -all {\s+} $line " " ]
          set line [ regsub {^\s+} $line "" ]
          set elements [ split $line ]
          set f3 [ regsub {:} [lindex $elements 3] ")" ]
          puts $fid_out "[lindex $elements 0] [lindex $elements 2] $f3 [lindex $elements 1] "
        }
      }
      min_delay { 
        if { [regexp {^$} $line] } { 
          set state undefined
        } else {
          set line [ regsub -all {\s+} $line " " ]
          set line [ regsub {^\s+} $line "" ]
          set elements [ split $line ]
          set f3 [ regsub {:} [lindex $elements 3] ")" ]
          puts $fid_out "[lindex $elements 0] [lindex $elements 2] $f3 [lindex $elements 1] "
        }
      }
      max_transition { 
        if { [regexp {^$} $line] } { 
          set state undefined
        } else {
          set line [ regsub -all {\s+} $line " " ]
          set line [ regsub {^\s+} $line "" ]
          set elements [ split $line ]
          set f5 [ regsub {:} [lindex $elements 5] ")" ]
          puts $fid_out "[lindex $elements 0] [lindex $elements 4] $f5 [lindex $elements 1] "
        }
      }
      default { 
        sproc_msg -error "sproc_focal_opt_report_constraint_preprocessor: The violation_type = $options(-violation_type) is not understood."
      }

    }

  }

  close $fid_in
  close $fid_out

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_focal_opt_report_constraint_preprocessor \
  -info "This procedure is convert report_constraint file from PT into a format consumable for focal_opt endpoint based optimization." \
  -define_args {
    {-fname_in "The name of the input file" AString string required}
    {-fname_out "The name of the output file" AString string required}
    {-violation_type "Specifies the type of violation to extract from the input file" AnOos one_of_string
      {required value_help {values {max_delay min_delay max_transition}}}
    }
  }

## -----------------------------------------------------------------------------
## sproc_get_macro_info:
## -----------------------------------------------------------------------------

proc sproc_get_macro_info { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global DEV
  global synopsys_program_name

  set options(-type) [list]
  set options(-tool) dc
  set options(-info) design
  set options(-hier) 0
  set options(-verbose) 0
  set options(-disable_instance_matching) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Define some useful reference information.
  ## -------------------------------------

  set return_list [list]
  set valid_macro_types_arg [list hard logic soft]
  set valid_macro_types_var [list hard logic soft logic_and_soft]
  set valid_model_combos [list \
    dc:full_model \
    dc:ddc_am \
    dc:icc_am \
    dc:etm \
    icc:icc_am \
    icc:icc_cam \
    icc:etm \
    pt:full_model \
    pt:pt_ilm \
    pt:etm \
  ]

  ## -------------------------------------
  ## Perform some error checking on arguments.
  ## -------------------------------------

  ## Remove any duplicate list elements.
  set options(-type) [lsort -unique $options(-type)]

  ## Check that each list element is valid.
  foreach type $options(-type) {
    if { [lsearch $valid_macro_types_arg $type] < 0 } {
      sproc_msg -error "Incorrect list element in -type argument: '$type'"
      sproc_msg -error "Expecting one of these: $valid_macro_types_arg"
      sproc_pinfo -mode stop
      return $return_list
    }
  }

  ## -------------------------------------
  ## For support of N-level hierarchical designs, we
  ## must consider the value of SVAR(hier,macro_info)
  ## for both the top-level design, and also
  ## for the macro-level designs.
  ## -------------------------------------

  proc sproc_get_macro_info_get_svar_from_block { block } {
    global env SEV
    source $SEV(tscript_dir)/common.tcl
    source $SEV(block_dir)/../$block/scripts_block/conf/block.tcl

    ## This unpacking and repacking ensures that macro_info_list is of a consistent format.
    set macro_info_list [list]
    foreach macro_info $SVAR(hier,macro_info) {
      set type            [lindex $macro_info 0]
      set design          [lindex $macro_info 1]
      set inst            [lindex $macro_info 2]
      set model_info_list [lindex $macro_info 3]
      set macro_info_new [list $type $design $inst $model_info_list]
      lappend macro_info_list $macro_info_new
    }

    return $macro_info_list
  }

  proc sproc_get_macro_info_resolve_macro_info_list { block inst_prefix depth ref_svar_blocks_queried verbose } {
    global env SEV

    ## -------------------------------------
    ## Keep track of all blocks that are queried.
    ## -------------------------------------

    upvar 1 $ref_svar_blocks_queried svar_blocks_queried
    if { [lsearch $svar_blocks_queried $block] == -1 } {
      lappend svar_blocks_queried $block
    }

    ## -------------------------------------
    ## Update instance names from SVAR(hier,macro_info) to reflect hierarchy.
    ## -------------------------------------

    set top_design_macro_info_list [list]
    set tmp_top_design_macro_info_list [sproc_get_macro_info_get_svar_from_block $block]
    foreach macro_info $tmp_top_design_macro_info_list {

      if { ( $depth == 0 ) || [regexp {^10_syn} $SEV(step)] } {
        set type            [lindex $macro_info 0]
      } else {
        set type hard
      }
      set design          [lindex $macro_info 1]
      set inst            [lindex $macro_info 2]
      set model_info_list [lindex $macro_info 3]
      if { $inst_prefix == "" } {
        set inst_new $inst
      } else {
        set inst_new $inst_prefix/$inst
      }
      set macro_info_new [list $type $design $inst_new $model_info_list]
      lappend top_design_macro_info_list $macro_info_new
    }

    ## -------------------------------------
    ## Recursively process the designs that were specified in SVAR(hier,macro_info).
    ## -------------------------------------

    foreach macro_info $top_design_macro_info_list {
      set type            [lindex $macro_info 0]
      set design          [lindex $macro_info 1]
      set inst            [lindex $macro_info 2]
      set model_info_list [lindex $macro_info 3]

      set spaces [string repeat " " [expr $depth * 2]]
      if { $verbose } {
        sproc_msg -info "  $spaces$design ($inst)"
      }

      set sub_design_macro_info_list [sproc_get_macro_info_resolve_macro_info_list $design $inst [expr $depth + 2] svar_blocks_queried $verbose]

      foreach sub_design_macro_info $sub_design_macro_info_list {
        lappend top_design_macro_info_list $sub_design_macro_info
      }
    }

    return $top_design_macro_info_list
  }

  set svar_blocks_queried [list]

  if { $options(-hier) } {

    if { $options(-verbose) } {
      sproc_msg -info "## -------------------------------------"
      sproc_msg -info "## Design Hierarchy: design (instance)"
      sproc_msg -info "## -------------------------------------"
      sproc_msg -info "$SEV(block_name)"
    }

    ## Determine value from recursive examinatin of SVAR(hier,macro_info)
    set macro_info_list [sproc_get_macro_info_resolve_macro_info_list $SEV(block_name) "" 0 svar_blocks_queried $options(-verbose)]

  } else {

    ## Determine value from direct examinatin of SVAR(hier,macro_info)
    set macro_info_list [sproc_get_macro_info_get_svar_from_block $SEV(block_name)]

  }

  if { $options(-verbose) } {
    if { $options(-hier) } {
      sproc_msg -info "## -------------------------------------"
      sproc_msg -info "## Per Block SVAR(hier,macro_info) values:"
      sproc_msg -info "## -------------------------------------"
      foreach block $svar_blocks_queried {
        set design_macro_info_list [sproc_get_macro_info_get_svar_from_block $block]
        sproc_msg -info "For $block:"
        if { [llength $design_macro_info_list] == 0 } {
          sproc_msg -info "   <empty>"
        } else {
          foreach macro_info $design_macro_info_list {
            sproc_msg -info "  $macro_info"
          }
        }
      }
      sproc_msg -info "## -------------------------------------"
      sproc_msg -info "## Derived value of SVAR(hier,macro_info):"
      sproc_msg -info "## -------------------------------------"
      foreach macro_info $macro_info_list {
        sproc_msg -info "  $macro_info"
      }
    } else {
      sproc_msg -info "## -------------------------------------"
      sproc_msg -info "## Actual value of SVAR(hier,macro_info):"
      sproc_msg -info "## -------------------------------------"
      foreach macro_info $macro_info_list {
        sproc_msg -info "  $macro_info"
      }
    }
  }

  ## -------------------------------------
  ## Perform some error checking and pre-processing on the macro_info_list variable.
  ##
  ## We need to determine the model type to return based on the current tool & step.
  ## The resolved_model_type variable will hold this information.
  ##
  ## We need to track the state of the assignment process,
  ## so we can detect conflicting model specifications.
  ## The resolved_model_state variable is used to track this state.
  ## The states for this variable are: unassigned, assigned_for_all, assigned_for_step
  ## -------------------------------------

  unset -nocomplain resolved_model_type
  unset -nocomplain resolved_model_state

  set error 0
  foreach macro_info $macro_info_list {

    if { [llength $macro_info] == 4 } {

      ## Grab each of the 4 primary list elements.

      set type            [lindex $macro_info 0]
      set design          [lindex $macro_info 1]
      set inst            [lindex $macro_info 2]
      set model_info_list [lindex $macro_info 3]

      set orig_inst($inst) $inst

      if { [lsearch $valid_macro_types_var $type] < 0 } {
        sproc_msg -error "Incorrect format for macro info: $macro_info"
        sproc_msg -error "Expecting one of these: $valid_macro_types_var"
        set error 1
      }

      ## Specify the default model type & default model state for each instance.

      set resolved_model_type($inst,dc)  ddc_am
      set resolved_model_type($inst,icc) icc_am
      set resolved_model_type($inst,pt)  full_model

      set resolved_model_state($inst,dc)  unassigned
      set resolved_model_state($inst,icc) unassigned
      set resolved_model_state($inst,pt)  unassigned

      foreach model_info $model_info_list {

        set model_info_fields [split $model_info ":"]

        if { ([llength $model_info_fields] == 2) || ([llength $model_info_fields] == 3) } {

          set model_tool [lindex $model_info_fields 0]
          set model_type [lindex $model_info_fields 1]
          set model_step [lindex $model_info_fields 2]

          if { [lsearch $valid_model_combos $model_tool:$model_type] < 0 } {
            sproc_msg -error "Incorrect value for model info: $model_info"
            sproc_msg -error "Expecting one of these: $valid_model_combos"
            set error 1
          }

          if { $model_step == "" } {
            switch $resolved_model_state($inst,$model_tool) {
              unassigned {
                set resolved_model_state($inst,$model_tool) assigned_for_all
                set resolved_model_type($inst,$model_tool) $model_type
              }
              assigned_for_all {
                sproc_msg -error "Conflicting model specifications: $model_info"
                set error 1
              }
              assigned_for_step {
                ## Ignore general assignment if already assigned for step.
              }
            }
          } elseif { [regexp $model_step $SEV(step)] } {
            switch $resolved_model_state($inst,$model_tool) {
              unassigned -
              assigned_for_all {
                set resolved_model_state($inst,$model_tool) assigned_for_step
                set resolved_model_type($inst,$model_tool) $model_type
              }
              assigned_for_step {
                sproc_msg -error "Conflicting model specifications: $model_info"
                set error 1
              }
            }
          }

        } else {
          sproc_msg -error "Incorrect format for model info: $model_info"
          set error 1
        }
      }
    } else {
      sproc_msg -error "Incorrect format for macro info: $macro_info"
      set error 1
    }

  }

  if { $error } {
    sproc_pinfo -mode stop
    return $return_list
  }

  ## -------------------------------------
  ## Perform some error checking in the event of MIM operations.
  ## -------------------------------------

  if { ($options(-info) == "mim_inst") || ($options(-info) == "mim_master_inst") } {

    set error 0

    if { [llength $SVAR(hier,mim_master_inst_list)] == 0 } {
      sproc_msg -warning "There are no MIM master instances defined by SVAR(hier,mim_master_inst_list)."
    }

    ## -------------------------------------
    ## Check that each MIM master is both a logic and soft macro. (ie, is type 'logic_and_soft')
    ## -------------------------------------

    foreach mim_master_inst $SVAR(hier,mim_master_inst_list) {
      set match 0
      foreach macro_info $macro_info_list {
        set type   [lindex $macro_info 0]
        set design [lindex $macro_info 1]
        set inst   [lindex $macro_info 2]
        if { $mim_master_inst == $inst } {
          set match 1
          if { $type != "logic_and_soft" } {
            sproc_msg -error "The MIM master instance '$mim_master_inst' must also be setup as a macro of type 'logic_and_soft'."
            set error 1
          }
        }
      }
      if { !$match } {
        sproc_msg -error "The MIM master instance '$mim_master_inst' must also be setup as a macro of type 'logic_and_soft'."
        set error 1
      }
    }

    ## -------------------------------------
    ## Check that needed commands are available.
    ## -------------------------------------

    set tmp [info commands get_cells]
    if { [llength $tmp] == 0 } {
      sproc_msg -error "Unable to perform MIM processing without the get_cells command."
      set error 1
    }
    set tmp [info commands get_attribute]
    if { [llength $tmp] == 0 } {
      sproc_msg -error "Unable to perform MIM processing without the get_attribute command."
      set error 1
    }

    if { $error } {
      sproc_pinfo -mode stop
      return $return_list
    }

  }

  ## -------------------------------------
  ## Determine the entries in macro_info_list that match the requested types.
  ## Place the relevant entries into the matched_macro_info variable.
  ## -------------------------------------

  set matched_macro_info [list]

  foreach macro_info $macro_info_list {
    set type [lindex $macro_info 0]
    set match 0
    switch $type {
      hard {
        if { [lsearch $options(-type) "hard"]  >= 0 } { set match 1 }
      }
      logic {
        if { [lsearch $options(-type) "logic"] >= 0 } { set match 1 }
      }
      soft {
        if { [lsearch $options(-type) "soft"]  >= 0 } { set match 1 }
      }
      logic_and_soft {
        if { [lsearch $options(-type) "logic"] >= 0 } { set match 1 }
        if { [lsearch $options(-type) "soft"]  >= 0 } { set match 1 }
      }
    }
    if { $match } {
      lappend matched_macro_info $macro_info
    }
  }

  ## -------------------------------------
  ## Optional instance name resolution.
  ## -------------------------------------

  set resolve_inst_names 1

  if { ![regexp {inst} $options(-info)] } {
    ## No instances are being requested. 
    set resolve_inst_names 0 
  }

  if { $options(-disable_instance_matching) } {
    ## Instance name resolution is being explicitly disabled.
    set resolve_inst_names 0
  }

  switch $synopsys_program_name {
    pt_shell -
    fm_shell -
    dc_shell -
    icc_shell {
      ## Instance name resolution is allowed for these tools.
    }
    default {
      set resolve_inst_names 0
    }
  }

  if { $resolve_inst_names } {

    if { $synopsys_program_name != "fm_shell" } {
      set hier_cells [get_cells -hier -filter "is_hierarchical==true" -quiet]
    }

    set final_macro_info [list]
    foreach macro_info $matched_macro_info {
      set type            [lindex $macro_info 0]
      set design          [lindex $macro_info 1]
      set inst            [lindex $macro_info 2]
      set model_info_list [lindex $macro_info 3]

      set inst_wild [regsub -all {/} $inst {?}]

      if { $synopsys_program_name == "fm_shell" } {
        set resolved_inst $inst_wild
      } else {
        if { [sizeof_collection [get_cells -quiet $inst]] == 1 } {
          ## The instance was found using the original name.
          set resolved_inst $inst
        } else {
          ## The instance was not found using the original name.
          set resolved_inst_from_hier_cells [get_attribute [filter_collection $hier_cells full_name=~$inst_wild] full_name]
          if { [llength $resolved_inst_from_hier_cells] == 1 } {
            ## The instance was found via a limited search.
            set resolved_inst $resolved_inst_from_hier_cells
          } else {
            ## The instance must be found via a more comprehensive search.
            set resolved_inst_from_all_cells [get_attribute [get_cells -hier -quiet -filter full_name=~$inst_wild] full_name]
            if { [llength $resolved_inst_from_all_cells] == 1 } {
              set resolved_inst $resolved_inst_from_all_cells
            } else {
              set resolved_inst ""
            }
          }
        }
      }
      if { $resolved_inst != "" } {
        set macro_info_new [list $type $design $resolved_inst $model_info_list]
        lappend final_macro_info $macro_info_new
        set orig_inst($resolved_inst) $inst
      } else {
        sproc_msg -error "Unable to locate instance '$inst' in the design."
      }
    }

    set final_mim_master_inst_list [list]
    foreach inst $SVAR(hier,mim_master_inst_list) {
      set inst_wild [regsub -all {/} $inst {?}]
      if { $synopsys_program_name == "fm_shell" } { 
        set inst $inst_wild
      } else {
        set inst [get_attribute [get_cells -hier -quiet -filter full_name=~$inst_wild] full_name]
      }

      lappend final_mim_master_inst_list $inst
    }

    set final_bbox_inst_list [list]
    foreach inst $SVAR(hier,bbox_inst_list) {
      set inst_wild [regsub -all {/} $inst {?}]
      if { $synopsys_program_name == "fm_shell" } {
        set inst $inst_wild
      } else {
        set inst [get_attribute [get_cells -hier -quiet -filter full_name=~$inst_wild] full_name]
      }

      lappend final_bbox_inst_list $inst
    }

  } else {

    set final_macro_info $matched_macro_info
    set final_mim_master_inst_list $SVAR(hier,mim_master_inst_list)
    set final_bbox_inst_list $SVAR(hier,bbox_inst_list)

  }

  ## -------------------------------------
  ## Develop the data to return.
  ## -------------------------------------

  switch $options(-info) {

    design {
      foreach macro_info $final_macro_info {
        set design [lindex $macro_info 1]
        lappend return_list $design
      }
    }

    inst {
      foreach macro_info $final_macro_info {
        set inst [lindex $macro_info 2]
        lappend return_list $inst
      }
    }

    design_and_inst {
      foreach macro_info $final_macro_info {
        set design [lindex $macro_info 1]
        set inst   [lindex $macro_info 2]
        set design_and_inst [list $design $inst]
        lappend return_list $design_and_inst
      }
    }

    design_and_model {
      foreach macro_info $final_macro_info {
        set design [lindex $macro_info 1]
        set inst   [lindex $macro_info 2]
        set model $resolved_model_type($orig_inst($inst),$options(-tool))
        set design_and_model [list $design $model]
        lappend return_list $design_and_model
      }
    }

    inst_and_model {
      foreach macro_info $final_macro_info {
        set design [lindex $macro_info 1]
        set inst   [lindex $macro_info 2]
        set model $resolved_model_type($orig_inst($inst),$options(-tool))
        set inst_and_model [list $inst $model]
        lappend return_list $inst_and_model
      }
    }

    mim_inst {
      foreach mim_master_inst $final_mim_master_inst_list {
        foreach macro_info $final_macro_info {
          if { $mim_master_inst == [lindex $macro_info 2] } {
            set mim_master_ref [lindex $macro_info 1]
          }
        }
        foreach macro_info $final_macro_info {
          set design [lindex $macro_info 1]
          set inst   [lindex $macro_info 2]
          if { $mim_master_ref == $design } {
            lappend return_list $inst
          }
        }
      }
    }

    mim_master_inst {
      foreach mim_master_inst $final_mim_master_inst_list {
        lappend return_list $mim_master_inst
      }
    }

    bbox_inst {
      foreach macro_info $final_macro_info {
        set inst [lindex $macro_info 2]
        if { [lsearch $final_bbox_inst_list $inst] >= 0 } {
          lappend return_list $inst
        }
      }
    }

    bbox_design {
      foreach macro_info $final_macro_info {
        set design [lindex $macro_info 1]
        set inst   [lindex $macro_info 2]
        if { [lsearch $final_bbox_inst_list $inst] >= 0 } {
          lappend return_list $design
        }
      }
    }

  }

  ## -------------------------------------
  ## Return the final value.
  ## -------------------------------------

  set return_list [lsort -unique $return_list]

  sproc_pinfo -mode stop
  return $return_list
}

define_proc_attributes sproc_get_macro_info \
  -info "This procedure is used to return info about subdesign macros." \
  -define_args {
  {-type "Specifies a list of macro types to query. Valid values in the list are: hard, logic, soft." AString string required}
  {-info "Specifies the type of information to return" AnOos one_of_string
    {required value_help {values {design inst design_and_inst design_and_model inst_and_model mim_inst mim_master_inst bbox_inst bbox_design}}}
  }
  {-tool "Specifies the tool when requesting modeling information." AnOos one_of_string
    {optional value_help {values {dc icc pt}}}
  }
  {-hier "Specifies that information is returned for the entire design hierarchy." "" boolean optional}
  {-verbose "Prints additional information during processing." "" boolean optional}
  {-disable_instance_matching "Disables instance name matching functionality." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_set_message_info_processing :
## -----------------------------------------------------------------------------

proc sproc_set_message_info_processing  { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name

  set options(-fname) ""
  set options(-limit_threshold_e) 0
  set options(-limit_threshold_i) 0
  set options(-limit_threshold_w) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------

  if { [file exists $options(-fname)] == 0 } {
    sproc_msg -error "sproc_set_message_info_processing : The file \"$options(-fname)\" doesn't exist."
  } else {
    sproc_msg -info "sproc_set_message_info_processing :  "
    sproc_msg -info "sproc_set_message_info_processing :   Processing \"$options(-fname)\""
    sproc_msg -info "sproc_set_message_info_processing :  "
    sproc_msg -info "sproc_set_message_info_processing :                   Threshold"
    sproc_msg -info "sproc_set_message_info_processing :                   ---------"
    sproc_msg -info "sproc_set_message_info_processing :           Error :    $options(-limit_threshold_e)"
    sproc_msg -info "sproc_set_message_info_processing :   Informational :    $options(-limit_threshold_i)"
    sproc_msg -info "sproc_set_message_info_processing :         Warning :    $options(-limit_threshold_w)"
    sproc_msg -info "sproc_set_message_info_processing :  "

    ## we are seeing some files w/ embedded control M.  the following is used to
    ## clean that up so that we can then process cleanly
    set tmp_fname "$SEV(tmp_dir)/[file tail $options(-fname)]_$SEV(task)_$SEV(dst)"
    set fid [open $options(-fname) r]
    set fid_new [open $tmp_fname w]
    while { ( [gets $fid line] >= 0 ) } {
      puts $fid_new "$line"
    }
    close $fid
    close $fid_new

    set continuation_line 0
    set fid [open $tmp_fname r]
    while { ( [gets $fid line] >= 0 ) } {
      if { $continuation_line } {
        ## skipping over continuation lines
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        } else {
          set continuation_line 0
        }
      } elseif { [regexp "^E " $line] } {
        ## Errors
        regsub {^E(\s+)} $line "" message_id
        regsub {(\s+).*} $message_id "" message_id
        if { $options(-limit_threshold_e) > 0 } {
          set_message_info -id $message_id -limit $options(-limit_threshold_e)
        }
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        }
      } elseif { [regexp "^F " $line] } {
        ## Fatal ... can't be suppressed
        regsub {^F(\s+)} $line "" message_id
        regsub {(\s+).*} $message_id "" message_id
        ## set_message_info -id $message_id -limit $options(-limit_threshold)
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        }
      } elseif { [regexp "^I " $line] } {
        ## Information
        regsub {^I(\s+)} $line "" message_id
        regsub {(\s+).*} $message_id "" message_id
        if { $options(-limit_threshold_i) > 0 } {
          set_message_info -id $message_id -limit $options(-limit_threshold_i)
        }
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        }
      } elseif { [regexp "^S " $line] } {
        ## Severe Error ... can't be suppressed
        regsub {^S(\s+)} $line "" message_id
        regsub {(\s+).*} $message_id "" message_id
        ## set_message_info -id $message_id -limit $options(-limit_threshold)
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        }
      } elseif { [regexp "^W " $line] } {
        ## Warnings
        regsub {^W(\s+)} $line "" message_id
        regsub {(\s+).*} $message_id "" message_id
        if { $options(-limit_threshold_w) > 0 } {
          set_message_info -id $message_id -limit $options(-limit_threshold_w)
        }
        if { [regexp {\\$} $line] } {
          set continuation_line 1
        }
      } elseif { [regexp {\\$} $line] } {
        ## Empty continuation line
        set continuation_line 1
      } elseif { [regexp "^#" $line] } {
        ## skipping over comments
      } elseif { [regexp {^$} $line] } {
        ## blank line
      } else {
        ## if a pattern that generates an error condition is encounterd either add appropriate 
        ## processing of change the "sproc_msg -error" to "sproc_msg -warning"
        sproc_msg -error "sproc_set_message_info_processing : The pattern \"$line\" is not understood."
      }
    }
    close $fid
    if { [file exists $tmp_fname] == 0 } {
      file delete $tmp_fname
    }
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_set_message_info_processing  \
  -info "This procedure applies set_message_info w/ a limit to a file of ids.  The file of ids comes from the tool distribution.  A limit of 0 means unsuppressed" \
  -define_args {
  {-fname "Specifies the file name from which to extract ids to pass to set_message_info." AString string required}
  {-limit_threshold_e "Maximum occurences before auto-suppression of error messages (default=0)" "0" int optional}
  {-limit_threshold_i "Maximum occurences before auto-suppression of informational messages (default=0)" "0" int optional}
  {-limit_threshold_w "Maximum occurences before auto-suppression of warning messages (default=0)" "0" int optional}
}

## -----------------------------------------------------------------------------
## sproc_ft_export:
## -----------------------------------------------------------------------------

proc sproc_ft_export { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global search_path link_library target_library

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-database_name) ""
  set options(-design_name) ""
  set options(-directory_name) "ft_export"
  set options(-overwrite) 0

  parse_proc_arguments -args $args options

  set ft_export_version "ft_export 0.1"

  ## -------------------------------------
  ## Check for open MW
  ## -------------------------------------
  redirect /dev/null {catch {set tmp [current_mw_lib]}}
  if { $tmp != "" } {
    sproc_msg -error "Milkyway library '[get_attribute [current_mw_lib] path]' is already open and must be closed before executing sproc_ft_export."
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Create the directory
  ## -------------------------------------

  if { [ file exists $options(-directory_name) ] } {
    sproc_msg -info "Directory exists : $options(-directory_name)"
    if { $options(-overwrite) } {
      sproc_msg -info "-overwrite specified, removing ..."
      exec chmod -R 777 $options(-directory_name)
      file delete -force $options(-directory_name)
    } else {
      sproc_msg -info "-overwrite not specified, exiting ..."
      sproc_pinfo -mode stop
      return
    }
  }

  sproc_msg -info "Creating directory : $options(-directory_name)"
  file mkdir $options(-directory_name)
  file mkdir $options(-directory_name)/inputs
  file mkdir $options(-directory_name)/logs
  file mkdir $options(-directory_name)/rpts
  file mkdir $options(-directory_name)/scripts
  file mkdir $options(-directory_name)/work

  ## -------------------------------------
  ## Copy MW and create a script that loads database
  ## -------------------------------------

  copy_mw_lib \
    -from [ file normalize $options(-database_name) ] \
    -to [ file normalize $options(-directory_name)/inputs/[ file tail $options(-database_name) ] ]

  ## -------------------------------------
  ## Create the README file
  ## -------------------------------------

  set filename $options(-directory_name)/README
  set fid [open $filename w]
  puts $fid ""
  puts $fid "Created by  : $ft_export_version"
  puts $fid "User        : [sh whoami]"
  puts $fid "Date        : [date]"
  puts $fid "Location    : [pwd]"
  puts $fid "Source MW   : [file normalize $options(-database_name)]"
  puts $fid ""
  close $fid

  ## -------------------------------------
  ## Create the Run file
  ## -------------------------------------

  set filename $options(-directory_name)/Run
  set fid [open $filename w]
  puts $fid ""
  puts $fid "## module load icc/2012.06-SP3"
  puts $fid "icc_shell -64bit -f ./scripts/the_script.tcl | tee ./logs/the_script.tcl"
  puts $fid ""
  close $fid

  ## -------------------------------------
  ## Create the the_script file
  ## -------------------------------------

  set fid [open "$options(-directory_name)/scripts/the_script.tcl" "w"]
  puts $fid ""

  ## search_path
  puts $fid "set search_path \[ list \\"
  foreach tmp $search_path {
    puts $fid "  $tmp \\"
  }
  puts $fid "\]\n"

  ## link_library
  puts $fid "set link_library \[ list \\"
  foreach tmp $link_library {
    puts $fid "  $tmp \\"
  }
  puts $fid "\]\n"

  ## target_library
  puts $fid "set target_library \[ list \\"
  foreach tmp $target_library {
    puts $fid "  $tmp \\"
  }
  puts $fid "\]\n"

  puts $fid ""
  puts $fid "if { \[ file exists \[pwd\]/work/[file tail $options(-database_name)] \] } {"
  puts $fid "  file delete -force \[pwd\]/work/[file tail $options(-database_name)]"
  puts $fid "}"
  puts $fid ""
  puts $fid "copy_mw_lib \\"
  puts $fid "  -from \[pwd\]/inputs/[file tail $options(-database_name)] \\"
  puts $fid "  -to \[pwd\]/work/[file tail $options(-database_name)] "
  puts $fid ""
  puts $fid "open_mw_cel \\"
  puts $fid "  -library \[pwd\]/work/[file tail $options(-database_name)] \\"
  puts $fid "  $options(-design_name)\n"

  puts $fid "## -------------------------------------"
  puts $fid "## code to aid in exporting data"
  puts $fid "##   - note this changes the state of the design"
  puts $fid "## -------------------------------------\n"

  puts $fid "if { 0 } {\n"

  puts $fid "  set data_dir ./work\n"

  puts $fid "  set_active_scenarios -all"
  puts $fid "  change_names -rules verilog -hierarchy"
  puts $fid "  set_scenario_options -scenarios \[all_scenarios\] -setup true -hold true\n"

  puts $fid "  write_verilog \$data_dir/$options(-design_name).v\n"

  puts $fid "  write_def -all_vias -output \$data_dir/$options(-design_name).def\n"
  puts $fid "  write_def -scanchain -output \$data_dir/$options(-design_name).scan.def\n"

  puts $fid "  save_upf \$data_dir/$options(-design_name).upf\n"

  puts $fid "  set_app_var write_sdc_output_lumped_net_capacitance false"
  puts $fid "  set_app_var write_sdc_output_net_resistance false"
  puts $fid "  foreach s1 \[all_active_scenarios\] {"
  puts $fid "    current_scenario \$s1"
  puts $fid "    write_sdc -nosplit \$data_dir/$options(-design_name).\$s1.sdc"
  puts $fid "    write_script -no_annotated_check -no_annotated_delay -no_cg \\"
  puts $fid "      -format dctcl -nosplit -output \$data_dir/$options(-design_name).\$s1.dctcl"
  puts $fid "  }\n"

  puts $fid "  set rpts_dir ./rpts\n"

  puts $fid "  foreach s1 \[all_active_scenarios\] {"
  puts $fid "    current_scenario \$s1"
  puts $fid "    redirect \${rpts_dir}/report_delay_estimation_options.\[current_scenario\] {"
  puts $fid "      report_delay_estimation_options"
  puts $fid "    }"
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_design_physical {"
  puts $fid "    report_design_physical -all -verbose "
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_extraction_options {"
  puts $fid "    report_extraction_options -scenarios \[all_active_scenarios\]"
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_ignored_layers {"
  puts $fid "    report_ignored_layers "
  puts $fid "  }\n"

  puts $fid "  foreach s1 \[all_active_scenarios\] {"
  puts $fid "    current_scenario \$s1"
  puts $fid "    redirect \${rpts_dir}/report_inter_clock_delay_options.\[current_scenario\] {"
  puts $fid "      report_inter_clock_delay_options"
  puts $fid "    }"
  puts $fid "  }\n"

  puts $fid "  foreach s1 \[all_active_scenarios\] {"
  puts $fid "    current_scenario \$s1"
  puts $fid "    redirect \${rpts_dir}/report_latency_adjustment_options.\[current_scenario\] {"
  puts $fid "      report_latency_adjustment_options"
  puts $fid "    }"
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_pnet_options {"
  puts $fid "    report_pnet_options "
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_preferred_routing_direction {"
  puts $fid "    report_preferred_routing_direction "
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_scenarios {"
  puts $fid "    report_scenarios "
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_scenario_options {"
  puts $fid "    report_scenario_options -scenarios \[all_active_scenarios\]"
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_timing_derate {"
  puts $fid "    report_timing_derate -scenarios \[all_active_scenarios\]"
  puts $fid "  }\n"

  puts $fid "  redirect \${rpts_dir}/report_tlu_plus_files {"
  puts $fid "    report_tlu_plus_files -scenarios \[all_active_scenarios\]"
  puts $fid "  }\n"

  puts $fid "}\n"

  close $fid

  ## -------------------------------------

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_ft_export \
        -info "\
        Procedure that assists in packaging for FT. \
  " \
  -define_args {
  {-database_name  "Design database" AString string required}
  {-design_name    "Design name" AString string required}
  {-directory_name "Directory in which to package" AString string optional}
  {-overwrite      "Overwrite if the directory already exists" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_ft_import:
## -----------------------------------------------------------------------------

proc sproc_ft_import { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-src_work) ""
  set options(-src_rpt) ""
  set options(-dst) "000_from_ft"
  set options(-overwrite) 1

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Close any open library
  ## -------------------------------------

  if { [llength [current_mw_lib]] > 0 } {
    close_mw_lib
  }

  ## -------------------------------------
  ## Setup and Create the directory
  ## -------------------------------------

  sproc_msg -info "Redefining SEV(dst_dir) and SEV(rpt_dir)"
  set SEV(dst_dir) "[ file dirname $SEV(dst_dir) ]/$options(-dst)"
  set SEV(rpt_dir) "[ file dirname $SEV(rpt_dir) ]/$options(-dst)"

  if { [ file exists $SEV(dst_dir) ] && ( $options(-overwrite) == 0 ) } {
    sproc_msg -error "Directory already exists and -overwrite not specified. $SEV(dst_dir)"
    sproc_pinfo -mode stop
    return
  } elseif { [ file exists $SEV(dst_dir) ] && ( $options(-overwrite) == 1 ) } {
    sproc_msg -info "Removing existing directory: $SEV(dst_dir)"
    exec chmod -R 777 $SEV(dst_dir)
    file delete -force $SEV(dst_dir)
  }

  if { [ file exists $SEV(rpt_dir) ] && ( $options(-overwrite) == 0 ) } {
    sproc_msg -error "Directory already exists and -overwrite not specified. $SEV(rpt_dir)"
    sproc_pinfo -mode stop
    return
  } elseif { [ file exists $SEV(rpt_dir) ] && ( $options(-overwrite) == 1 ) } {
    sproc_msg -info "Removing existing directory: $SEV(rpt_dir)"
    exec chmod -R 777 $SEV(rpt_dir)
    file delete -force $SEV(rpt_dir)
  }

  sproc_msg -info "Creating directories."
  file mkdir $SEV(dst_dir)
  file mkdir $SEV(rpt_dir)

  ## -------------------------------------
  ## Preparing to create the database
  ## -------------------------------------

  sproc_msg -info "Creating the database."
  create_mw_lib $SEV(dst_dir)/$SVAR(design_name).mdb -tech $SVAR(tech,mw_tech_file) -mw_reference_library $SVAR(lib,mw_reflist)
  open_mw_lib $SEV(dst_dir)/$SVAR(design_name).mdb

  read_verilog -allow_black_box -top $SVAR(design_name) $options(-src_work)/$SVAR(design_name).v
  read_def -no_incremental $options(-src_work)/$SVAR(design_name).def

  sproc_msg -info "Creating Scenarios."
  set sdcs [glob -nocomplain $options(-src_work)/*.sdc]
  foreach sdc $sdcs {
    set scenario_split [split [file tail $sdc] "."]
    set scenario "[lindex $scenario_split 1].[lindex $scenario_split 2].[lindex $scenario_split 3]"
    create_scenario $scenario
    read_sdc $sdc
  }

  save_mw_cel

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_ft_import \
        -info "\
        Procedure that assists in packaging for FT. \
  " \
  -define_args {
  {-src_work  "Source data from which to import" AString string optional}
  {-src_prt  "Source reports from which to import" AString string optional}
  {-dst  "Destination in which to create the imported data" AString string optional}
  {-overwrite  "Overwrite if the directory already exists" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_pt_report_qor
## -----------------------------------------------------------------------------

proc sproc_pt_report_qor { args } {

  global env SEV SVAR TEV
  global synopsys_program_name
  global sh_product_version
  global sh_dev_null
  global pt_shell_mode

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-scenario) [list]
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Basic error checking
  ## -------------------------------------

  if { $synopsys_program_name != "pt_shell" } {
    puts "Error: This script only functions properly in PrimeTime."
    return 0
  }

  switch $pt_shell_mode {
    primetime {
      if { [llength $options(-scenario)] != 1 } {
        puts "Error: A single scenario must be specified."
        return 0
      }
    }
    primetime_slave {
      if { [llength $options(-scenario)] != 1 } {
        puts "Error: A single scenario must be specified."
        return 0
      }
      if { $options(-scenario) != [current_scenario] } {
        puts "Error: Slave session does not match selected scenario."
        return 0
      }
    }
    primetime_master {
      puts "Error: This command not implemented for PT DMSA Masters."
      return 0
    }
  }

  catch { set design [current_design] } result
  if { $design == "" } {
    return 0
  }

  ## -------------------------------------
  ## Variables to configure this procedure.
  ## -------------------------------------

  set max_path_count 100000

  ## -------------------------------------
  ## Print banner
  ## -------------------------------------

  puts "## -------------------------------------"
  puts "## Report : Lynx Design System version of 'report_qor' for Primetime"
  puts "## Design : [get_object_name $design]"
  puts "## Scenario(s):"
  foreach scenario $options(-scenario) {
    puts "##   $scenario"
  }
  puts "## Version: $sh_product_version"
  puts "## Date   : [date]"
  puts "## -------------------------------------"
  puts ""

  ## -------------------------------------
  ## Gather data for report. (per path_group)
  ## -------------------------------------

  set path_group_name_list [list]

  foreach_in_collection path_group_obj [get_path_groups] {

    set path_group_name [get_object_name $path_group_obj]

    set timing_path_max_worst [get_timing_paths -group $path_group_obj -delay_type max]

    set num_of_paths [sizeof_collection $timing_path_max_worst]

    if { $num_of_paths == 0 } {

      continue

    } else {

      lappend path_group_name_list $path_group_name

      ## -------------------------------------
      ## Max info (per path_group)
      ## -------------------------------------

      set pg($path_group_name,max,levels) [sproc_pt_report_qor_count_levels $timing_path_max_worst]
      set pg($path_group_name,max,delay) [get_attribute $timing_path_max_worst arrival]
      set slack [get_attribute $timing_path_max_worst slack]
      if { $slack == "" } {
        set pg($path_group_name,max,wns) 99.99
      } else {
        set pg($path_group_name,max,wns) $slack
      }

      set endpoint_clock [get_attribute $timing_path_max_worst endpoint_clock]
      if { $endpoint_clock == "" } {
        set pg($path_group_name,max,period) 0.0
      } else {
        set period [get_attribute $endpoint_clock period]
        if { $period == "" } {
          set pg($path_group_name,max,period) 0.0
        } else {
          set pg($path_group_name,max,period) $period
        }
      }

      set tns 0.0
      set nvp 0
      if { $pg($path_group_name,max,wns) < 0.0 } {
        set timing_paths_max [get_timing_paths -group $path_group_obj -delay_type max -slack_lesser_than 0.0 -max_paths $max_path_count]
        set nvp [sizeof_collection $timing_paths_max]
        foreach_in_collection path $timing_paths_max {
          set slack [get_attribute $path slack]
          set tns [expr $tns + $slack]
        }
      }
      set pg($path_group_name,max,tns) $tns
      set pg($path_group_name,max,nvp) $nvp

      ## -------------------------------------
      ## Min info (per path_group)
      ## -------------------------------------

      set timing_path_min_worst [get_timing_paths -group $path_group_name -delay_type min]

      set slack [get_attribute $timing_path_min_worst slack]
      if { $slack == "" } {
        set pg($path_group_name,min,wns) 99.99
      } else {
        set pg($path_group_name,min,wns) $slack
      }

      set tns 0.0
      set nvp 0
      if { $pg($path_group_name,min,wns) < 0.0 } {
        set timing_paths_min [get_timing_paths -group $path_group_obj -delay_type min -slack_lesser_than 0.0 -max_paths $max_path_count]
        set nvp [sizeof_collection $timing_paths_min]
        foreach_in_collection path $timing_paths_min {
          set slack [get_attribute $path slack]
          set tns [expr $tns + $slack]
        }
      }
      set pg($path_group_name,min,tns) $tns
      set pg($path_group_name,min,nvp) $nvp

    }
  }

  ## -------------------------------------
  ## Gather data for report. (per scenario)
  ## -------------------------------------

  ## set timing_path_max_worst [get_timing_paths -delay_type max]
  set worst_slack ""
  foreach_in_collection path [get_timing_paths -delay_type max] {
    set slack [get_attribute $path slack]
    if { $slack != "" } {
      if { $worst_slack == "" } {
        set worst_slack $slack
        set timing_path_max_worst $path
      } else {
        if { $slack < $worst_slack } {
          set worst_slack $slack
          set timing_path_max_worst $path
        }
      }
    }
  }
  if { $worst_slack == "" } {
    set timing_path_max_worst $path
  }

  ## -------------------------------------
  ## Max info (per scenario)
  ## -------------------------------------

  set path_group_name ___DESIGN___

  set pg($path_group_name,max,levels) [sproc_pt_report_qor_count_levels $timing_path_max_worst]
  set pg($path_group_name,max,delay) [get_attribute $timing_path_max_worst arrival]
  set slack [get_attribute $timing_path_max_worst slack]

  if { $slack == "" } {
    set pg($path_group_name,max,wns) 0.0
  } else {
    if { $slack < 0.0 } {
      set pg($path_group_name,max,wns) [expr abs($slack)]
    } else {
      set pg($path_group_name,max,wns) 0.0
    }
  }

  set endpoint_clock [get_attribute $timing_path_max_worst endpoint_clock]
  if { $endpoint_clock == "" } {
    set pg($path_group_name,max,period) n/a
  } else {
    set period [get_attribute $endpoint_clock period]
    if { $period == "" } {
      set pg($path_group_name,max,period) n/a
    } else {
      set pg($path_group_name,max,period) $period
    }
  }

  set tns 0.0
  set nvp 0
  if { $pg($path_group_name,max,wns) > 0.0 } {
    set timing_paths_max [get_timing_paths -delay_type max -slack_lesser_than 0.0 -max_paths $max_path_count]
    set nvp [sizeof_collection $timing_paths_max]
    foreach_in_collection path $timing_paths_max {
      set slack [get_attribute $path slack]
      set tns [expr $tns + $slack]
    }
  }
  set pg($path_group_name,max,tns) [expr abs($tns)]
  set pg($path_group_name,max,nvp) $nvp

  ## -------------------------------------
  ## Min info (per scenario)
  ## -------------------------------------

  ## set timing_path_min_worst [get_timing_paths -delay_type min]
  set worst_slack ""
  foreach_in_collection path [get_timing_paths -delay_type min] {
    set slack [get_attribute $path slack]
    if { $slack != "" } {
      if { $worst_slack == "" } {
        set worst_slack $slack
        set timing_path_min_worst $path
      } else {
        if { $slack < $worst_slack } {
          set worst_slack $slack
          set timing_path_min_worst $path
        }
      }
    }
  }
  if { $worst_slack == "" } {
    set timing_path_min_worst $path
  }

  set slack [get_attribute $timing_path_min_worst slack]
  if { $slack == "" } {
    set pg($path_group_name,min,wns) 0.00
  } else {
    if { $slack < 0.0 } {
      set pg($path_group_name,min,wns) [expr abs($slack)]
    } else {
      set pg($path_group_name,min,wns) 0.0
    }
  }

  set tns 0.0
  set nvp 0
  if { $pg($path_group_name,min,wns) > 0.0 } {
    set timing_paths_min [get_timing_paths -delay_type min -slack_lesser_than 0.0 -max_paths $max_path_count]
    set nvp [sizeof_collection $timing_paths_min]
    foreach_in_collection path $timing_paths_min {
      set slack [get_attribute $path slack]
      set tns [expr $tns + $slack]
    }
  }
  set pg($path_group_name,min,tns) [expr abs($tns)]
  set pg($path_group_name,min,nvp) $nvp

  ## -------------------------------------
  ## Create body of report.
  ## -------------------------------------

  foreach scenario $options(-scenario) {
    foreach path_group_name $path_group_name_list {

      puts "  Scenario '$scenario'"
      puts "  Timing Path Group '$path_group_name'"
      puts "  -----------------------------------"
      puts "  Levels of Logic:             $pg($path_group_name,max,levels)"
      puts "  Critical Path Length:        $pg($path_group_name,max,delay)"
      puts "  Critical Path Slack:         $pg($path_group_name,max,wns)"
      puts "  Critical Path Clk Period:    $pg($path_group_name,max,period)"
      puts "  Total Negative Slack:        $pg($path_group_name,max,tns)"
      puts "  No. of Violating Paths:      $pg($path_group_name,max,nvp)"
      puts "  Worst Hold Violation:        $pg($path_group_name,min,wns)"
      puts "  Total Hold Violation:        $pg($path_group_name,min,tns)"
      puts "  No. of Hold Violations:      $pg($path_group_name,min,nvp)"
      puts "  -----------------------------------"
      puts ""
      if { $pg($path_group_name,max,nvp) >= $max_path_count } {
        puts "Warning: No. of Violating Paths exceeds $max_path_count"
        puts ""
      }
      if { $pg($path_group_name,min,nvp) >= $max_path_count } {
        puts "Warning: No. of Hold Violations exceeds $max_path_count"
        puts ""
      }
    }

    set path_group_name ___DESIGN___
    puts "  Scenario: $scenario        WNS: $pg($path_group_name,max,wns) TNS: $pg($path_group_name,max,tns) Number of Violating Paths: $pg($path_group_name,max,nvp)"
    puts "  Design                     WNS: $pg($path_group_name,max,wns) TNS: $pg($path_group_name,max,tns) Number of Violating Paths: $pg($path_group_name,max,nvp)"
    puts ""
    puts "  Scenario: $scenario (Hold) WNS: $pg($path_group_name,min,wns) TNS: $pg($path_group_name,min,tns) Number of Violating Paths: $pg($path_group_name,min,nvp)"
    puts "  Design              (Hold) WNS: $pg($path_group_name,min,wns) TNS: $pg($path_group_name,min,tns) Number of Violating Paths: $pg($path_group_name,min,nvp)"
    puts ""

  }

  puts "End of Report"

}

define_proc_attributes sproc_pt_report_qor \
  -info "Report QoR for Primetime" \
  -define_args {\
    {-scenario "The scenario to process." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_pt_report_qor_count_levels (proc used by pt_report_qor)
## -----------------------------------------------------------------------------

proc sproc_pt_report_qor_count_levels { path } {
  set levels 0
  set endpoint [get_object_name [get_attribute -quiet $path endpoint]]
  foreach_in_collection point [get_attribute -quiet $path points] {
    set object [get_attribute -quiet $point object]
    if {[get_attribute -quiet $object object_class] == "pin"} {
      if {[get_attribute -quiet $object pin_direction] == "in"} {
        if {[get_attribute -quiet $object is_port] == "false"} {
          if {[get_attribute -quiet $object full_name] != $endpoint} {
            incr levels
          }
        }
      }
    }
  }
  return $levels
}

## -----------------------------------------------------------------------------
## sproc_link_library_debugger:
## -----------------------------------------------------------------------------

proc sproc_link_library_debugger { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name

  ## Get arguments
  set options(-output) ""
  set options(-scenario) ""
  set options(-compare_file) ""
  set options(-compare_only) 0
  set options(-scaling_in_use) 0
  parse_proc_arguments -args $args options

  set cell_collection [sort_collection [get_cell -hier -filter is_hierarchical==false] full_name]

  if {!$options(-compare_only)} {
    ## Generate an explicit 'link_path_per_instance' style output with every cell/lib covered
    set fid [open $options(-output) w]
    puts "SNPS_INFO   : Reporting on [sizeof_collection $cell_collection] cells."
    puts $fid "## unofficial link_path_per_instance generated by debugger utility. Scaling in use set to $options(-scaling_in_use)"
    puts $fid "set link_path_per_instance  \[list \\"
    ## STAR on -scenario switch in get_lib_cells used below. Applying this approach for workaround
    if { $options(-scenario)!="" } {
      current_scenario $options(-scenario)
      if {[current_scenario]!=$options(-scenario)} {
        puts "Error: Unable to set current_scenario to $options(-scenario). Exiting utility"
        break
      }
    }
    foreach_in_collection cl $cell_collection {
      set cl_name [get_object_name $cl]
      set lib_name NULL
      array unset lib_names
      if { $options(-scaling_in_use) } {
        set drive_lib [lsort -unique [get_object_name [get_attribute [get_pins -quiet -of_object $cl] driver_model_scaling_libs_max -quiet]]]
        set receive_lib [lsort -unique [get_object_name [get_attribute [get_pins -quiet -of_object $cl] receiver_model_scaling_libs_max -quiet]]]
        if { ![string match $drive_lib $receive_lib] && $drive_lib!="" } {
          puts "INFO: Multiple libraries used for pins of cell $cl_name.  Drive pins use ($drive_lib) and input pins use ($receive_lib)"
          puts "INFO: Using drive lib $drive_lib for the debug output"
        }
        set lib_name $drive_lib
      } else {
        ## other tools have more direct linking that can be traced using get_lib_cells
        if { [get_lib_cells -of_object $cl -quiet]=={} } {
          puts "Skipping lib info for $cl_name"
          continue
        }
        ## STAR on -scenario switch in get_lib_cells. Skipping this approach for now.
        ## if { $options(-scenario)=="" } {
        ##   set lib_name [file dirname [get_object_name [get_lib_cells -of_object $cl]]]
        ## } else {
        ##   set lib_name [file dirname [get_object_name [get_lib_cells -of_object $cl -scenario $options(-scenario)]]]
        ## }
        set lib_name [file dirname [get_object_name [get_lib_cells -quiet -of_object $cl]]]
    }
      puts $fid "\[list $cl_name $lib_name\] \\"
    }
    puts $fid {]} 

    close $fid
  }

  if { $options(-compare_file)!="" } {
    if { [file exists $options(-compare_file)] } {
      puts "SNPS_INFO   : Start comparing cell-lib pairs from $options(-output) to $options(-compare_file)"
      set compare_errors 0
      set cid [open $options(-compare_file) r]
      set fid [open $options(-output) r]
      while { ( [gets $fid line] >= 0 ) } {
        gets $cid line_c
        if { ![string equal $line $line_c] } {
          puts "SNPS_ERROR  : cell-lib mismatch."
          puts "            :  \"$line\" from $options(-output) not matching"
          puts "            :  \"$line_c\" from $options(-compare_file)"
          incr compare_errors
        } else {
          ## puts "MATCH: $line   ==========  $line_c"
        }
      }
      if { $compare_errors > 0 } {
        puts "SNPS_ERROR  : Done comparing cell-lib pairs. $compare_errors mismatches"
      } else {
        puts "SNPS_INFO   : Done comparing cell-lib pairs. No mismatches"
      }
    } else {
      puts "SNPS_ISSUE  : No file $options(-compare_file) exists. No comparison done."
    }
  }
  sproc_pinfo -mode stop
}

define_proc_attributes sproc_link_library_debugger \
  -info "Outputs a complete list of cells and associated library in a link_path_per_instance format. Useful for comparing between DC/ICC/PT tools" \
  -define_args {
  {-output "output file" "" string required}
  {-scaling_in_use "determin linked lib using scaling attributes present after update timing." "" boolean optional}
  {-scenario "optional scenario to report, if more than one defined" "" string optional}
  {-compare_file "a prior output_file to compare, if provided" "" string optional}
  {-compare_only "only do the compare of output to compare_file" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_scaling_lib_group_utility:
## -----------------------------------------------------------------------------

proc sproc_scaling_lib_group_utility { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## Get arguments
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  if { $options(-scenario)!="" } {
    current_scenario $options(-scenario)
  }

  foreach_in_collection lib [get_libs] {
    set lib_db [file tail [get_attribute $lib source_file_name]]
    set lib_name [get_object_name $lib] 
    if [regexp {gtech|.sldb} $lib_name] {
      continue
    }
    set nom_volt [get_attribute $lib nom_voltage]
    set nom_temperature [get_attribute $lib nom_temperature]
    set nom_process [get_attribute $lib nom_process]
    set cc [sizeof_collection [get_lib_cell $lib_name/*]]
    set first_cell [file tail [lindex [get_object_name [get_lib_cell $lib_name/*]] 0]]
    lappend lib_group($cc,$first_cell,$nom_process,$nom_temperature) $lib_db
  }

  sproc_msg -info "Outputing string that could be used for setting up library scaling in Lynx"
  sproc_msg -info "NOTE: REVIEW and validate this suggested list"
  sproc_msg -info "      This current version only groups libs with identical cells. There are cases where cells are identical and operating"
  sproc_msg -info "      conditions are the same whic result in SLG-209 errors in PT define_scaling_lib_group. This type situation is difficult to"
  sproc_msg -info "      provide an automatic approach but the output here can be a useful start point."

  set worst_oc [lindex $SVAR(setup,oc_types_list) 0]

  puts "set scaling_lib_groups($worst_oc) \[list \\"
  foreach i [array names lib_group] {
    puts "  \{ $lib_group($i) \} \\"
  }
  puts "\]"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_scaling_lib_group_utility \
  -info "Generates a plausable list for use as a scaling_lib_group based on a currently linked design" \
  -define_args {
  {-scenario "optional scenario to report, if more than one defined" "" string optional}
}

## -----------------------------------------------------------------------------
## sproc_icc_task_combining:
## -----------------------------------------------------------------------------

proc sproc_icc_task_combining { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments
  ## -------------------------------------

  set options(-work_dir) "./work"
  set options(-overwrite) 0
  set options(-input_tasks) ""
  set options(-output_task) ""
  set options(-debug) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Create the directory
  ## -------------------------------------

  sproc_msg -info "Phase : Initialization "

  if { ( $options(-overwrite) == 0 ) && [file exists $options(-work_dir)] } {
    sproc_msg -error "  Directory \"$options(-work_dir)\" already exists and -overwrite not specified."
    sproc_pinfo -mode stop
    return
  }

  if { $options(-overwrite) && [ file exists $options(-work_dir) ] } {
    sproc_msg -info "  Removing existing directory \"$options(-work_dir)\" ..."
    exec chmod -R 777 $options(-work_dir)
    file delete -force $options(-work_dir)
  } 

  sproc_msg -info "  Creating directory \"$options(-work_dir)\" ..."
  file mkdir $options(-work_dir)

  ## -------------------------------------
  ## Phase 0 : copy the source files
  ## -------------------------------------

  set phase -1

  incr phase
  sproc_msg -info "Phase $phase : Copying input tasks to process ..."
  set src ""
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst
  set cnt 0
  foreach input_file_name $options(-input_tasks) {
    if { [file exists $input_file_name] } {
      sproc_msg -info "  $input_file_name"
      set tmp [format "%02d_%s" $cnt [ file tail $input_file_name ]]
      file copy $input_file_name $dst/$tmp
      incr cnt
    } else {
      sproc_msg -error "  $input_file_name does not exist"
    }
  }

  ## -------------------------------------
  ## Phase 1 : updates for all files 
  ##   - map from "TEV(" to "TEV(#_"
  ##   - pre "sproc_source -file $SEV(bscript_dir)/conf/block_setup.tcl" add SEV(script)
  ##   - post "sproc_script_start" add localized overrides 
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : Global Updates ..."
  set src "$options(-work_dir)/[expr $phase - 1]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst
  set cnt 0
  set file_names [ lsort -increasing [  glob $src/* ] ]
  foreach file_name $file_names {
    set fout_name "$dst/[file tail $file_name]"
    set fin [open $file_name "r"]
    set fout [open $fout_name "w"]
    set mode 0
    set remapping_lines [list]

    while { ( [gets $fin line] >= 0 ) } {

      if { ($mode == 0) && [regexp {TEV\(} $line] } {
        if { [regexp {^set } $line] } {
          regsub {^set\s+} $line "" tline
          regsub {\).*} $tline "\)" tline
          regsub -all {TEV\(} $tline [format "\$TEV(%d_" $cnt ] tline2
          set tline "set $tline $tline2"
          lappend remapping_lines $tline
        }
        regsub -all {TEV\(} $line [format "TEV(%d_" $cnt ] line
      } elseif { [regexp {sproc_source.*block_setup.tcl} $line] } {

          set mode 1
          set tmp_name [file tail $file_name]
          regsub {[\d]+_} $tmp_name "" tmp_name
          puts $fout "set SEV(script_file) $tmp_name"
          puts $fout "sproc_msg -info \"Manually setting SEV(script_file) = \$SEV(script_file)\""

      } elseif { [regexp {sproc_script_start} $line] } {
          puts $fout $line

          set tmp_name [file tail $file_name]
          regsub {[\d]+_} $tmp_name "" tmp_name
          puts $fout "sproc_msg -info \"Mapping from TEV(${cnt}_field) back to TEV(field).\""

          foreach tline $remapping_lines {
            puts $fout $tline
          }

          set line ""
      }
      puts $fout $line

    }

    close $fin
    close $fout

    incr cnt
  }

  ## -------------------------------------
  ## Phase 2 : for all but the first file
  ##   - suppress all commands upto the first TEV definition
  ##   - suppress "sproc_source -file $SEV(bscript_dir)/conf/block_setup.tcl"
  ##   - suppress "sproc_script_start"
  ##   - suppress "sproc_copyMDB"
  ##   - suppress "open_mw_cel"
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : Updates to all but the first ..."
  set src "$options(-work_dir)/[expr $phase - 1]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst
  set cnt 0
  set file_names [ lsort -increasing [  glob $src/* ] ]
  foreach file_name $file_names {

    set fout_name "$dst/[file tail $file_name]"

    if { [ lsearch [ lrange $file_names 1 end ] $file_name ] < 0 } {

      file copy $file_name $fout_name

    } else { 

      set fin [open $file_name "r"]
      set fout [open $fout_name "w"]

      set update_cnt 0
      set found_TEV 0

      while { ( [gets $fin line] >= 0 ) } {

        if { $found_TEV == 0 } {
          if { [regexp {^## NAME: TEV} $line] } {
            set found_TEV 1
          } elseif { [regexp {^##} $line] } {
          } elseif { [regexp {^$} $line] } {
          } else {
            set line "##> $line"
          }
        } elseif { [regexp {sproc_source.*block_setup.tcl} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {sproc_script_start} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {sproc_copyMDB} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {open_mw_cel} $line] } {
          set line "##> $line"
          incr update_cnt
        }
        puts $fout $line

      }

      close $fin
      close $fout

      set expected_cnt 0
      if { $update_cnt != $expected_cnt } {
        sproc_msg -info "  $update_cnt updates to $file_name"
      }

    }

    incr cnt
  }

  ## -------------------------------------
  ## Phase 3 : for all but the last files
  ##   - suppress "sproc_source -file $env(LYNX_VARFILE_TEV)"
  ##   - update "set RPT(basename) $SEV(rpt_dir)/icc"
  ##
  ##   - suppress "sproc_early_complete"
  ##   - suppress "sproc_metric"
  ##   - suppress "close_mw_lib"
  ##   - suppress "sproc_script_stop"
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : Updates to all but the last ..."
  set src "$options(-work_dir)/[expr $phase - 1]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst
  set cnt 0
  set file_names [ lsort -increasing [  glob $src/* ] ]
  foreach file_name $file_names {

    set fout_name "$dst/[file tail $file_name]"

    if { [ lsearch [ lrange $file_names 0 end-1 ] $file_name ] < 0 } {

      file copy $file_name $fout_name

    } else { 

      set fin [open $file_name "r"]
      set fout [open $fout_name "w"]

      set update_cnt 0

      while { ( [gets $fin line] >= 0 ) } {

        if { [regexp {LYNX_VARFILE_TEV} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {set\s+RPT\(basename\)\s+} $line] } {
          puts $fout "##> $line"
          set line "${line}_${cnt}"
          incr update_cnt
        } elseif { [regexp {sproc_early_complete} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {sproc_metric_} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {close_mw_lib} $line] } {
          set line "##> $line"
          incr update_cnt
        } elseif { [regexp {sproc_script_stop} $line] } {
          set line "##> $line"
          incr update_cnt
        }
        puts $fout $line

      }

      close $fin
      close $fout

      set expected_cnt 0
      if { $update_cnt != $expected_cnt } {
        sproc_msg -info "  $update_cnt updates to $file_name"
      }

    }

    incr cnt
  }

  ## -------------------------------------
  ## Phase 4 : split 
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : Splitting ..."
  set src "$options(-work_dir)/[expr $phase - 1]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst
  set file_names [ lsort -increasing [  glob $src/* ] ]
  foreach file_name $file_names {

    set fin [open $file_name "r"]
    set fout1 [open "$dst/[file tail $file_name].part1" "w"]
    set fout2 [open "$dst/[file tail $file_name].part2" "w"]

    set mode 0
    while { ( [gets $fin line] >= 0 ) } {
      if { $mode == 0 } {
        puts $fout1 $line
        if { [regexp {LYNX_VARFILE_TEV} $line] } {
          set mode 1
        }
      } else {
        puts $fout2 $line
      }
    }

    close $fin
    close $fout1
    close $fout2

  }

  ## -------------------------------------

  if { $options(-debug) } {

    sproc_msg -info "Phase $phase : Splitting ... (debug)"
    set src "$options(-work_dir)/0"
    set dst "$options(-work_dir)/${phase}.debug"
    file mkdir $dst
    set file_names [ lsort -increasing [  glob $src/* ] ]
    foreach file_name $file_names {

      set fin [open $file_name "r"]
      set fout1 [open "$dst/[file tail $file_name].part1" "w"]
      set fout2 [open "$dst/[file tail $file_name].part2" "w"]

      set mode 0
      while { ( [gets $fin line] >= 0 ) } {
        if { $mode == 0 } {
          puts $fout1 $line
          if { [regexp {LYNX_VARFILE_TEV} $line] } {
            set mode 1
          }
        } else {
          puts $fout2 $line
        }
      }

      close $fin
      close $fout1
      close $fout2

    }

  }

  ## -------------------------------------
  ## Phase 5 : combining
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : Combining ..."
  set src "$options(-work_dir)/[expr $phase - 1 ]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst

  set fout_name "$dst/[file tail $options(-output_task)]"
  set fout [open "$fout_name" "w"]

  set file_names [ lsort -increasing [  glob $src/*.part1 ] ]
  foreach file_name $file_names {
    set fin [open $file_name "r"]
    while { ( [gets $fin line] >= 0 ) } {
      puts $fout $line
    }
    close $fin
  }
  set file_names [ lsort -increasing [  glob $src/*.part2 ] ]
  foreach file_name $file_names {
    set fin [open $file_name "r"]
    while { ( [gets $fin line] >= 0 ) } {
      puts $fout $line
    }
    close $fin
  }

  close $fout

  ## -------------------------------------

  if { $options(-debug) } {

    sproc_msg -info "Phase $phase : Combining ... (debug)"
    set src "$options(-work_dir)/[expr $phase - 1 ].debug"
    set dst "$options(-work_dir)/$phase.debug"
    file mkdir $dst

    set fout_name "$dst/[file tail $options(-output_task)]"
    set fout [open "$fout_name" "w"]

    set file_names [ lsort -increasing [  glob $src/*.part1 ] ]
    foreach file_name $file_names {
      set fin [open $file_name "r"]
      while { ( [gets $fin line] >= 0 ) } {
        puts $fout $line
      }
      close $fin
    }
    set file_names [ lsort -increasing [  glob $src/*.part2 ] ]
    foreach file_name $file_names {
      set fin [open $file_name "r"]
      while { ( [gets $fin line] >= 0 ) } {
        puts $fout $line
      }
      close $fin
    }

    close $fout

    ## remember the name for use later
    set output_task_debug $fout_name

  }

  ## -------------------------------------
  ## Phase 6 : TEV(num_cores)
  ## -------------------------------------

  incr phase
  sproc_msg -info "Phase $phase : TEV(num_cores) ..."
  set src "$options(-work_dir)/[expr $phase - 1]"
  set dst "$options(-work_dir)/$phase"
  file mkdir $dst

  set fin_name "$src/[file tail $options(-output_task)]"
  set fout_name "$dst/[file tail $options(-output_task)]"
  set fin [open "$fin_name" "r"]
  set fout [open "$fout_name" "w"]

  set cntl 0

  while { ( [gets $fin line] >= 0 ) } {

    if { ( $cntl == 0 ) && [regexp {## NAME: TEV\([\d]+_num_cores\)} $line] } {
      regsub -all {TEV\([\d]+_num_cores\)} $line "TEV(num_cores)" line
    } elseif { ( $cntl == 0 ) && [regexp {set TEV\([\d]+_num_cores\)} $line] } {
      regsub -all {TEV\([\d]+_num_cores\)} $line "TEV(num_cores)" line
      set cntl 1
    } elseif { ( $cntl == 1 ) && [regexp {## NAME: TEV\([\d]+_num_cores\)} $line] } {
      set line "##> $line"
      set cntl 2
    } elseif { ( $cntl == 2 ) && [regexp {set TEV\([\d]+_num_cores\)} $line] } {
      set line "##> $line"
      set cntl 1
    } elseif { ( $cntl == 2 ) } {
      set line "##> $line"
    } elseif { ( $cntl == 1 ) && [regexp {TEV\([\d]+_num_cores\)} $line] } {
      regsub -all {TEV\([\d]+_num_cores\)} $line "TEV(num_cores)" line
    }
    puts $fout $line

  }

  close $fin
  close $fout

  ## -------------------------------------

  file copy "$dst/[file tail $options(-output_task)]" $options(-output_task)
  if { $options(-debug) } {
    file copy $output_task_debug $options(-output_task).debug
  }

  ## -------------------------------------
  ## clean-up
  ## -------------------------------------

  sproc_msg -info "Phase : Clean Up ..."
  if { $options(-debug) == 0 } {
    sproc_msg -info "  Deleting \"$options(-work_dir)\" ..."
    file delete -force $options(-work_dir)
  } else {
    sproc_msg -info "  Deleting \"$options(-work_dir)\" suppressed due to debug mode ..."
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_icc_task_combining \
        -info "\
        Procedure that assists in combining ICC tasks. \
  " \
  -define_args {
  {-work_dir  "Directory in which to work and perform intermediate processing" AString string optional}
  {-input_tasks  "Ordered list of tasks to combine" AString string optional}
  {-output_task  "Output task as a result of combining" AString string optional}
  {-overwrite  "Overwrite if the work_dir if it already exists" "" boolean optional}
  {-debug  "Run in debug mode" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_execute_vue_and_load_data:
## -----------------------------------------------------------------------------

proc sproc_execute_vue_and_load_data {} {
  sproc_pinfo -mode start
  global env SEV SVAR TEV

  set snps_icv_home [file normalize $env(ICV_HOME_DIR)]
  set snps_icv_home "${snps_icv_home}/bin/${env(SYNOPSYS_SYSTYPE)}"
  set vue_binary_path "${snps_icv_home}/icv_vue"
  if { [file exists $vue_binary_path] != 1 } {
      sproc_msg -error "VUE Binary doesn't exist!\n"
      return
  }
  if { [file executable $vue_binary_path] != 1 } {
      sproc_msg -error "VUE Binary isn't executable!\n"
      return
  }

  sproc_msg -info " VUE INFO: VuePortNumber = $::ICV::VuePortNumber\n"
  eval exec "$vue_binary_path -lay ICC -layArgs Port $::ICV::VuePortNumber -load $SEV(src_dir)/signoff_drc_run/$SVAR(design_name).vue &"
}

define_proc_attributes sproc_execute_vue_and_load_data \
  -info "Proc to activate ICC/ICV-VUE interface and load VUE data in interactive ICC tasks." \
  -define_args {
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
