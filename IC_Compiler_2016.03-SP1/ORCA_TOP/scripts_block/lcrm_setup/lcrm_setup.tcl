#########################################################################################
# Lynx Compatible Reference Methodology (LCRM) Setup File
# Script: lcrm_setup.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
#########################################################################################
## DESCRIPTION:
## * This script provides LCRM scripts access to a subset of Lynx functions.
## * It manages variables and metric procedures used by the LCRM scripts when
## * running standalone or within the Lynx Design System.
## * 
## * Automation Variables:
## * The LCRM scripts utilize some variables for managing directory structures used
## * for log files, reports, and output data. These variables are hardcoded for correct
## * operation when running LCRM scripts standalone. When running the LCRM scripts within
## * the Lynx Design System, these variables are under control of the flow automation.
## * 
## * Metrics:
## * The lcrm_setup.tcl contains procedures to support extraction of metric information
## * about the design and system. These appear as METRIC strings in the log file. When
## * running within the Lynx Design System, these METRIC messages are extracted and 
## * transfered to a database server. The Lynx Manager Cockpit application can be used
## * to analyze and generate reports from the collected data.
## * 
## * Users of LCRM scripts need not modify any of the contents of this script or
## * related references contained in each task script. These Lynx Compatabile functions
## * work when in Lynx and when running standalone and do not add any appreciable runtime
## * overhead.
## -----------------------------------------------------------------------------


## -----------------------------------------------------------------------------
## Lynx System Variable. 
## When running in Lynx, these SEV* variables are configured in the GUI and saved
## in the system.tcl file. When running outside of Lynx, a number of SEV(*) variables 
## need to be set to values to avoid errors in some of the metric procedures.
## The environment variable LYNX_RTL_PRESENT is set automatically when Lynx is run and
## is used here to setup variables according to the runtime environment
## -----------------------------------------------------------------------------


## enable consistent script error handling across tools
set sh_continue_on_error true

## not all tool tcl shells handle the source options. StarRCXT is one example needing special handling
if {[info exists synopsys_program_name]} {
  if { $synopsys_program_name=="tcl" } {
    set source_options ""
  } else {
    set source_options "-e -v"
  }
} else {
  # tcl program does not support -e -v options
  set source_options ""
}

## Support of DC Explorer uses same program name as dc_shell. This is done in the LCRM
## to provide compatability with procedures in this file that only rely on dc_shell.
if { [info exists synopsys_program_name] && $synopsys_program_name == "de_shell" } {
  set_app_var de_rename_shell_name_to_dc_shell true
  set_app_var synopsys_program_name dc_shell
}

## -----------------------------------------------------------------------------
## SVARs needing to be initialized for proper metric function
## -----------------------------------------------------------------------------
set SVAR(metrics,path_group_ignore_list_setup) ""
set SVAR(metrics,path_group_ignore_list_hold) ""
set SVAR(metrics,max_path_group_count) 5

if { [info exists env(LYNX_RTM_PRESENT)] } {

  puts "RM-Info: Lynx is setting SEV variables."
  set LYNX(rtm_present) 1

  eval source $source_options ../../scripts_global/conf/system.tcl

  ## -----------------------------------------------------------------------------
  ## Allow Lynx to define and overide dynamic System Environment Variabls
  ## -----------------------------------------------------------------------------

  eval source $source_options $env(LYNX_VARFILE_SEV)

} else {

  set LYNX(rtm_present) 0
  puts "RM-Info: Setting default SEV variables for running outside of Lynx."
  set SEV(project_dir)    my_project_dir
  set SEV(project_name)   lcrm
  set SEV(release_dir)    my_release_dir
  set SEV(techlib_dir)    my_techlib_dir
  set SEV(metrics_enable_generation) 1
  set SEV(metrics_enable_transfer) 1
  set SEV(log_file)       my_log_file
  set SEV(ver_star)       NaM
  set SEV(task)           [file root [file tail $SEV(script_file)]]
  set SEV(aro_enable)     0

}


## Remaining SEVs are calculated the same whether running standalone or in Lynx

if { ![info exist SEV(dont_run)] }      { set SEV(dont_run) 0 }
if { ![info exist SEV(dont_exit)] }     { set SEV(dont_exit) 0 }
if { ![info exist SEV(analysis_task)] } { set SEV(analysis_task) 0 }

set SEV(tmp_dir) [pwd]

set SEV(workarea_dir)   [file dirname [file dirname [file dirname [file dirname [file dirname $SEV(tmp_dir)]]]]]
set SEV(techlib_name)   [file tail  [file dirname [file dirname [file dirname $SEV(tmp_dir)]]]]

set SEV(block_dir)      [file dirname [file dirname $SEV(tmp_dir)]]
set SEV(block_name)     [file tail $SEV(block_dir)]
set SEV(step_dir)       [file dirname $SEV(tmp_dir)]
set SEV(step)           [file tail $SEV(step_dir)]
set SEV(gscript_dir)    [file normalize $SEV(tmp_dir)/../../scripts_global]
set SEV(tscript_dir)    [file normalize $SEV(tmp_dir)/../../scripts_global/$SEV(techlib_name)]
set SEV(bscript_dir)    [file normalize $SEV(tmp_dir)/../../scripts_block]
set SEV(work_dir)       [file normalize $SEV(tmp_dir)/../work]
set SEV(src_dir)        [file normalize $SEV(tmp_dir)/../work/$SEV(src)]
set SEV(dst_dir)        [file normalize $SEV(tmp_dir)/../work/$SEV(dst)]
set SEV(log_dir)        [file normalize $SEV(tmp_dir)/../logs/$SEV(dst)]
set SEV(rpt_dir)        [file normalize $SEV(tmp_dir)/../rpts/$SEV(dst)]

## -----------------------------------------------------------------------------
## The SVAR(design_name) must be undefined at this point in the script
## -----------------------------------------------------------------------------

set SVAR(design_name)  undefined

## -----------------------------------------------------------------------------
## These SVAR(tag_##) variables are a mechanism for grouping metrics. They are
## not used by default but can be overridden in block.tcl as shown below
## -----------------------------------------------------------------------------

set SVAR(tag_01) [list value]
set SVAR(tag_02) [list value]
set SVAR(tag_03) [list value]
set SVAR(tag_04) [list value]
set SVAR(tag_05) [list value]
set SVAR(tag_06) [list value]
set SVAR(tag_07) [list value]
set SVAR(tag_08) [list value]
set SVAR(tag_09) [list value]
set SVAR(tag_10) [list value]
set SVAR(tag_11) [list value]
set SVAR(tag_12) [list value]
set SVAR(tag_13) [list value]
set SVAR(tag_14) [list value]
set SVAR(tag_15) [list value]
set SVAR(tag_16) [list value]
set SVAR(tag_17) [list value]
set SVAR(tag_18) [list value]
set SVAR(tag_19) [list value]
set SVAR(tag_20) [list value]

## -----------------------------------------------------------------------------
## The block.tcl file is normally empty but sourced here 
## The most common use would be for overriding metric tags SVAR(tag_##) listed above
## as a method of labeling groups of experiments for easier metric filtering.
## -----------------------------------------------------------------------------

if {[file exists ../../scripts_block/conf/block.tcl]} {
  puts "RM-Info: sourcing ../../scripts_block/conf/block.tcl"
  eval source $source_options ../../scripts_block/conf/block.tcl
}

if { [info exists env(LYNX_RTM_PRESENT)] } {

  if { ![info exists SVAR(misc,early_complete_enable)] } { set SVAR(misc,early_complete_enable) 0 }

  ## -----------------------------------------------------------------------------
  ## Allow Lynx to overide Task Environment Variabls
  ## -----------------------------------------------------------------------------

  puts "RM-Info: Lynx is setting any TEV overrides from the RTM environment"
  eval source $source_options $env(LYNX_VARFILE_TEV)

} else {
  ## disable early_complete feature for all standalone execution
  set SVAR(misc,early_complete_enable) 0
}

## -----------------------------------------------------------------------------
## These Task variables that need to be assigned for proper standalone behavior but
## that are controlled in the Lynx environment by the content of LYNX_VARFILE_TEV file
## sourced below
## -----------------------------------------------------------------------------

set TEV(vx_enable) 0
set TEV(scenario) DEFAULT_SCENARIO
set TEV(report_level) NORMAL

## -----------------------------------------------------------------------------
## These procedures/variables are not uniformly available
## for all tools used in the flow. This section of code creates
## the procedures/variables if they are not available.
## -----------------------------------------------------------------------------

if { ![info exists synopsys_root] } {
set synopsys_root "synopsys_root"
}

if { ![info exists synopsys_program_name] } {
set synopsys_program_name "tcl"
}

if { $synopsys_program_name == "tcl" } {
set sh_product_version [info patchlevel]
}

if { [info command parse_proc_arguments] != "parse_proc_arguments" } {
proc parse_proc_arguments { cmdSwitch procArgs optsRef } {
upvar $optsRef opts
if { $cmdSwitch == "-args" } {
foreach arg $procArgs {
if { [string index $arg 0] == "-" } {
  set curArg $arg
  set opts($curArg) 1
} else {
  if { [info exists curArg] } {
    set opts($curArg) $arg
    unset curArg
  } else {
    puts "SNPS_ERROR: Found invalid argument: '$arg', with no preceding switch."
    puts "SNPS_ERROR: Called from procedure: [lindex [info level -1] 0]"
  }
}
}
}
}
}

if { [info command define_proc_attributes] != "define_proc_attributes" } {
proc define_proc_attributes args {}
}

if { [info command date] != "date" } {
proc date {} {
return [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
}
}

## -----------------------------------------------------------------------------
## sproc_script_stop: LCRM customized version
## -----------------------------------------------------------------------------

proc sproc_script_stop { args } {

  global LYNX
  global env SEV SVAR TEV
  global sh_product_version
  global synopsys_program_name

  set options(-exit) 0
  parse_proc_arguments -args $args options

  if {[info exists ::DESIGN_NAME]} {
    ## LCRM generates the corrected SYS.BLOCK metric reflecting DESIGN_NAME
    sproc_msg -info "METRIC | STRING SYS.BLOCK          | $::DESIGN_NAME"
  }

  ## -------------------------------------
  ## Generate metrics for each of the TEV variables.
  ## -------------------------------------

  set generate_metrics_for_tev 0

  if { $generate_metrics_for_tev } {

    set name_list [lsort [array names TEV]]
    foreach name $name_list {
      set length [llength $TEV($name)]
      if { $length == 0 } {
        sproc_msg -info "METRIC | STRING TEV.$name | NULL_VALUE"
      } else {
        sproc_msg -info "METRIC | STRING TEV.$name | $TEV($name)"
      }
    }

  }

  ## -------------------------------------
  ## Generate end-of-script metrics.
  ## -------------------------------------

  sproc_metric_time -stop
  sproc_metric_system -end_of_script

  ## -------------------------------------
  ## Exit processing.
  ## -------------------------------------

  if { $LYNX(rtm_present) } {
    if { $SEV(dont_exit) } {
      ## User is requesting that no exit be performed.
    } else {
      ## Check to see if explicit exit is being requested.
      if { $options(-exit) } {
        if { $synopsys_program_name == "cdesigner" } {
          exit -force 1
        } else {
          exit
        }
      }
    }
  } else {
    if { $synopsys_program_name == "cdesigner" } {
      exit -force 1
    } else {
      exit
    }
  }

}

define_proc_attributes sproc_script_stop \
  -info "Standard procedure for ending a script." \
  -define_args {
  {-exit  "Perform an exit." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_generate_metrics:
## -----------------------------------------------------------------------------

proc sproc_generate_metrics {} {

sproc_pinfo -mode start

global env SEV SVAR TEV
  global synopsys_program_name
  global power_enable_analysis
  global case_analysis_sequential_propagation
  global DESIGN_NAME DCRM_MCMM_SCENARIOS_SETUP_FILE
  global REPORTS_DIR

  file mkdir $SEV(rpt_dir)

  switch $synopsys_program_name {
    dc_shell {
      source ../../scripts_block/lcrm_setup/metric_reports_dc.tcl
      sproc_metric_main -metrics_design -metrics_power -metrics_sta
    }
    icc_shell {
      set my_all_active_scenarios [all_active_scenarios]
      source ../../scripts_block/lcrm_setup/metric_reports_icc.tcl
      if { [regexp {clock_opt_} $SEV(script_file) ] && [llength $my_all_active_scenarios] > 0 } {
        sproc_metric_main -metrics_design -metrics_power -metrics_sta -metrics_cts
      } else {
        sproc_metric_main -metrics_design -metrics_power -metrics_sta
      }
    }
    pt_shell {
      set RPT(basename) $SEV(rpt_dir)/pt.$TEV(scenario)
      source ../../scripts_block/lcrm_setup/metric_reports_pt.tcl
      if { $power_enable_analysis } {
        sproc_metric_main -metrics_sta -scenario_name $TEV(scenario) -metrics_power
      } else {
        sproc_metric_main -metrics_sta -scenario_name $TEV(scenario)
      }
    }
    tmax_tcl {
      redirect ${REPORTS_DIR}/tmax_rm.report_summaries {
        report_summaries 
      }
      sproc_metric_atpg
    }
  }

  sproc_pinfo -mode stop

}

## -----------------------------------------------------------------------------
## sproc_script_start:
## -----------------------------------------------------------------------------

proc sproc_script_start {} {

  global LYNX
  global env SEV SVAR TEV
  global sh_product_version
  global synopsys_program_name

  sproc_metric_time -start
  sproc_metric_system -start_of_script

}

define_proc_attributes sproc_script_start \
  -info "Standard procedure for starting a script." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_script_start:
## -----------------------------------------------------------------------------

proc sproc_script_start {} {

  global LYNX
  global env SEV SVAR TEV
  global sh_product_version
  global synopsys_program_name

  sproc_metric_time -start
  sproc_metric_system -start_of_script

}

define_proc_attributes sproc_script_start \
  -info "Standard procedure for starting a script." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_msg:
## -----------------------------------------------------------------------------

proc sproc_msg { args } {

  ## Assigning default value of "bell" since that is never used.

  set options(-info)    "\b"
  set options(-warning) "\b"
  set options(-error)   "\b"
  set options(-setup)   "\b"
  set options(-issue)   "\b"
  set options(-note)    "\b"
  set options(-header)  0
  parse_proc_arguments -args $args options

  global _sproc_msg_count
  if { ![info exists _sproc_msg_count(warning)] } { set _sproc_msg_count(warning) 0 }
  if { ![info exists _sproc_msg_count(issue)]   } { set _sproc_msg_count(issue)   0 }
  if { ![info exists _sproc_msg_count(note)]    } { set _sproc_msg_count(note)    0 }

  if       { $options(-info)   != "\b" } {
    puts "SNPS_INFO   : $options(-info)"
  } elseif { $options(-warning) != "\b" } {
    puts "SNPS_WARNING: $options(-warning)"
    incr _sproc_msg_count(warning)
  } elseif { $options(-error)  != "\b" } {
    puts "SNPS_ERROR  : $options(-error)"
  } elseif { $options(-setup)  != "\b" } {
    puts "SNPS_SETUP  : $options(-setup)"
  } elseif { $options(-issue)  != "\b" } {
    puts "SNPS_ISSUE  : $options(-issue)"
    incr _sproc_msg_count(issue)
  } elseif { $options(-note)  != "\b" } {
    puts "SNPS_NOTE  : $options(-note)"
    incr _sproc_msg_count(note)
  } elseif { $options(-header) } {
    puts "SNPS_HEADER : ## ------------------------------------- "
  } else {
    puts "SNPS_ERROR  : Unrecognized arguments for sproc_msg : $args"
  }
}

define_proc_attributes sproc_msg \
  -info "Standard message printing procedure." \
  -define_args {
  {-info    "Info message"    AString string optional}
  {-warning "Warning message" AString string optional}
  {-error   "Error message"   AString string optional}
  {-setup   "Setup message"   AString string optional}
  {-issue   "Issue message"   AString string optional}
  {-note    "Note  message"   AString string optional}
  {-header  "Header flag"     ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_msg:
## -----------------------------------------------------------------------------

proc sproc_msg { args } {

  ## Assigning default value of "bell" since that is never used.

  set options(-info)    "\b"
  set options(-warning) "\b"
  set options(-error)   "\b"
  set options(-setup)   "\b"
  set options(-issue)   "\b"
  set options(-note)    "\b"
  set options(-header)  0
  parse_proc_arguments -args $args options

  global _sproc_msg_count
  if { ![info exists _sproc_msg_count(warning)] } { set _sproc_msg_count(warning) 0 }
  if { ![info exists _sproc_msg_count(issue)]   } { set _sproc_msg_count(issue)   0 }
  if { ![info exists _sproc_msg_count(note)]    } { set _sproc_msg_count(note)    0 }

  if       { $options(-info)   != "\b" } {
    puts "SNPS_INFO   : $options(-info)"
  } elseif { $options(-warning) != "\b" } {
    puts "SNPS_WARNING: $options(-warning)"
    incr _sproc_msg_count(warning)
  } elseif { $options(-error)  != "\b" } {
    puts "SNPS_ERROR  : $options(-error)"
  } elseif { $options(-setup)  != "\b" } {
    puts "SNPS_SETUP  : $options(-setup)"
  } elseif { $options(-issue)  != "\b" } {
    puts "SNPS_ISSUE  : $options(-issue)"
    incr _sproc_msg_count(issue)
  } elseif { $options(-note)  != "\b" } {
    puts "SNPS_NOTE  : $options(-note)"
    incr _sproc_msg_count(note)
  } elseif { $options(-header) } {
    puts "SNPS_HEADER : ## ------------------------------------- "
  } else {
    puts "SNPS_ERROR  : Unrecognized arguments for sproc_msg : $args"
  }
}

define_proc_attributes sproc_msg \
  -info "Standard message printing procedure." \
  -define_args {
  {-info    "Info message"    AString string optional}
  {-warning "Warning message" AString string optional}
  {-error   "Error message"   AString string optional}
  {-setup   "Setup message"   AString string optional}
  {-issue   "Issue message"   AString string optional}
  {-note    "Note  message"   AString string optional}
  {-header  "Header flag"     ""      boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_source:
## -----------------------------------------------------------------------------

proc sproc_source { args } {

  global synopsys_program_name SEV

  if { ![info exists SEV(log_level)] } {
    set SEV(log_level) 1
  }

  set options(-file) ""
  set options(-quiet) 0
  set options(-optional) 0
  parse_proc_arguments -args $args options

  if { [llength $options(-file)] > 0 } {
    ## The file specification is not empty.
    if { [file exists $options(-file)] } {
      sproc_msg -info "SCRIPT_START : [file normalize $options(-file)] : [date]"
      if { $synopsys_program_name == "tcl" } {
        uplevel 1 source $options(-file)
      } elseif { $synopsys_program_name == "cdesigner" } {
        uplevel 1 source $options(-file)
      } elseif { $synopsys_program_name == "mvrc" } {
        uplevel 1 source $options(-file)
      } else {

        ## -------------------------------------
        ## Determine the verbosity level.
        ## -------------------------------------

        set filename [file tail $options(-file)]

        switch -glob $filename {
          procs.tcl -
          procs_metrics.tcl -
          procs_flow.tcl -
          procs_user.tcl -
          procs_qor.tcl -
          system.tcl -
          *.sev.varfile -
          system_setup.tcl -
          common.tcl -
          block.tcl -
          *.tev.varfile -
          block_setup.tcl {
            set is_standard_file 1
          }
          default {
            set is_standard_file 0
          }
        }

        switch $SEV(log_level) {
          0 {
            ## Normal Mode
            set quite_mode $options(-quiet)
          }
          1 {
            ## Suppress-standard-files Mode
            if { $is_standard_file } {
              set quite_mode 1
            } else {
              set quite_mode $options(-quiet)
            }
          }
          2 {
            ## Suppress-all-files Mode
            set quite_mode 1
          }
          default {
            ## Default to Normal Mode if variable value is incorrect.
            set quite_mode $options(-quiet)
            sproc_msg -error "Value for SEV(log_level) not recognized."
          }
        }

        if { $quite_mode } {
          uplevel 1 source $options(-file)
        } else {
          uplevel 1 source -e -v $options(-file)
        }

      }

      sproc_msg -info "SCRIPT_STOP  : [file normalize $options(-file)] : [date]"

    } else {

      sproc_msg -error "sproc_source: The specified file does not exist; '$options(-file)'"

    }

  } else {

    ## The file specification is empty.
    if { $options(-optional) } {
      sproc_msg -warning "sproc_source: An empty file specification was provided; file is optional."
    } else {
      sproc_msg -error   "sproc_source: An empty file specification was provided; file is not optional."
    }

  }

}

define_proc_attributes sproc_source \
  -info "Provides a standard way to source files." \
  -define_args {
  {-file "This option is used to specify the file to source. An argument value of <non-empty-string> requires that the specified file exists. An argument value of <empty-string> will cause an error unless the -optional argument is also supplied." AString string required}
  {-optional "This option prevents an <empty-string> -file argument from causing an error." "" boolean optional}
  {-quiet "Echo minimal file content." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_source:
## -----------------------------------------------------------------------------

proc sproc_source { args } {

  global synopsys_program_name SEV

  if { ![info exists SEV(log_level)] } {
    set SEV(log_level) 1
  }

  set options(-file) ""
  set options(-quiet) 0
  set options(-optional) 0
  parse_proc_arguments -args $args options

  if { [llength $options(-file)] > 0 } {
    ## The file specification is not empty.
    if { [file exists $options(-file)] } {
      sproc_msg -info "SCRIPT_START : [file normalize $options(-file)] : [date]"
      if { $synopsys_program_name == "tcl" } {
        uplevel 1 source $options(-file)
      } elseif { $synopsys_program_name == "cdesigner" } {
        uplevel 1 source $options(-file)
      } elseif { $synopsys_program_name == "mvrc" } {
        uplevel 1 source $options(-file)
      } else {

        ## -------------------------------------
        ## Determine the verbosity level.
        ## -------------------------------------

        set filename [file tail $options(-file)]

        switch -glob $filename {
          procs.tcl -
          procs_metrics.tcl -
          procs_flow.tcl -
          procs_user.tcl -
          procs_qor.tcl -
          system.tcl -
          *.sev.varfile -
          system_setup.tcl -
          common.tcl -
          block.tcl -
          *.tev.varfile -
          block_setup.tcl {
            set is_standard_file 1
          }
          default {
            set is_standard_file 0
          }
        }

        switch $SEV(log_level) {
          0 {
            ## Normal Mode
            set quite_mode $options(-quiet)
          }
          1 {
            ## Suppress-standard-files Mode
            if { $is_standard_file } {
              set quite_mode 1
            } else {
              set quite_mode $options(-quiet)
            }
          }
          2 {
            ## Suppress-all-files Mode
            set quite_mode 1
          }
          default {
            ## Default to Normal Mode if variable value is incorrect.
            set quite_mode $options(-quiet)
            sproc_msg -error "Value for SEV(log_level) not recognized."
          }
        }

        if { $quite_mode } {
          uplevel 1 source $options(-file)
        } else {
          uplevel 1 source -e -v $options(-file)
        }

      }

      sproc_msg -info "SCRIPT_STOP  : [file normalize $options(-file)] : [date]"

    } else {

      sproc_msg -error "sproc_source: The specified file does not exist; '$options(-file)'"

    }

  } else {

    ## The file specification is empty.
    if { $options(-optional) } {
      sproc_msg -warning "sproc_source: An empty file specification was provided; file is optional."
    } else {
      sproc_msg -error   "sproc_source: An empty file specification was provided; file is not optional."
    }

  }

}

define_proc_attributes sproc_source \
  -info "Provides a standard way to source files." \
  -define_args {
  {-file "This option is used to specify the file to source. An argument value of <non-empty-string> requires that the specified file exists. An argument value of <empty-string> will cause an error unless the -optional argument is also supplied." AString string required}
  {-optional "This option prevents an <empty-string> -file argument from causing an error." "" boolean optional}
  {-quiet "Echo minimal file content." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_pinfo:
## -----------------------------------------------------------------------------

proc sproc_pinfo { args } {

  set options(-mode) ""
  parse_proc_arguments -args $args options

  set parent_level [expr [info level] - 1]
  set parent_name [lindex [info level $parent_level] 0]
  set parent_name [regsub {^::} $parent_name {}]

  set no_msg_list [list \
    sproc_refresh_file_system \
    sproc_metric_clean_string \
    sproc_metric_normalize \
    ]

  if { [lsearch $no_msg_list $parent_name] >= 0 } {
    ## Suppress messages for these procedures.
  } else {
    switch $options(-mode) {
      start   { sproc_msg -info "PROC_START : $parent_name" }
      stop    { sproc_msg -info "PROC_STOP  : $parent_name" }
      default { sproc_msg -error "Invalid argument to sproc_pinfo" }
    }
  }

}

define_proc_attributes sproc_pinfo \
  -info "Prints standard messages at procedure boundaries." \
  -define_args {
  {-mode "Specifies which message to print" AnOos one_of_string
    {required value_help {values {start stop}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_pinfo:
## -----------------------------------------------------------------------------

proc sproc_pinfo { args } {

  set options(-mode) ""
  parse_proc_arguments -args $args options

  set parent_level [expr [info level] - 1]
  set parent_name [lindex [info level $parent_level] 0]
  set parent_name [regsub {^::} $parent_name {}]

  set no_msg_list [list \
    sproc_refresh_file_system \
    sproc_metric_clean_string \
    sproc_metric_normalize \
    ]

  if { [lsearch $no_msg_list $parent_name] >= 0 } {
    ## Suppress messages for these procedures.
  } else {
    switch $options(-mode) {
      start   { sproc_msg -info "PROC_START : $parent_name" }
      stop    { sproc_msg -info "PROC_STOP  : $parent_name" }
      default { sproc_msg -error "Invalid argument to sproc_pinfo" }
    }
  }

}

define_proc_attributes sproc_pinfo \
  -info "Prints standard messages at procedure boundaries." \
  -define_args {
  {-mode "Specifies which message to print" AnOos one_of_string
    {required value_help {values {start stop}}}
  }
}

## -----------------------------------------------------------------------------
## sproc_script_version:
## -----------------------------------------------------------------------------

proc sproc_script_version {} {

  sproc_pinfo -mode start

  global LYNX
  global env SEV SVAR TEV

  ## Determine version of $SEV(script_file)

  set version "Nam"

  if { [file exists $SEV(script_file)] } {

    set fid [open $SEV(script_file) r]

    while { [gets $fid line] >= 0 } {

      ## -------------------------------------
      ## Perforce format example:
      ## -------------------------------------

      set re {^## HEADER \$Id: [\w\/\.]+#([\d]+)}

      if { [regexp $re $line match version] } {
        break
      }

      ## -------------------------------------
      ## CVS format example:
      ## -------------------------------------

      set re {^## HEADER \$Id: [\w\/\.\,]+\s+([\d\.]+)}

      if { [regexp $re $line match version] } {
        break
      }

    }

    close $fid
  }

  sproc_pinfo -mode stop
  return $version

}

define_proc_attributes sproc_script_version \
  -info "Used to determine the version of a script." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_script_version:
## -----------------------------------------------------------------------------

proc sproc_script_version {} {

  sproc_pinfo -mode start

  global LYNX
  global env SEV SVAR TEV

  ## Determine version of $SEV(script_file)

  set version "Nam"

  if { [file exists $SEV(script_file)] } {

    set fid [open $SEV(script_file) r]

    while { [gets $fid line] >= 0 } {

      ## -------------------------------------
      ## Perforce format example:
      ## -------------------------------------

      set re {^## HEADER \$Id: [\w\/\.]+#([\d]+)}

      if { [regexp $re $line match version] } {
        break
      }

      ## -------------------------------------
      ## CVS format example:
      ## -------------------------------------

      set re {^## HEADER \$Id: [\w\/\.\,]+\s+([\d\.]+)}

      if { [regexp $re $line match version] } {
        break
      }

    }

    close $fid
  }

  sproc_pinfo -mode stop
  return $version

}

define_proc_attributes sproc_script_version \
  -info "Used to determine the version of a script." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_metric_system:
## -----------------------------------------------------------------------------

proc sproc_metric_system { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV DEV
  global sh_product_version
  global synopsys_program_name
  global _sproc_msg_count
  global SNPS_time_start SNPS_time_stop

  set xxx1 [clock seconds]

  set options(-start_of_script) 0
  set options(-end_of_script) 0
  set options(-mem_mb) -1
  parse_proc_arguments -args $args options

  if { $options(-start_of_script) } {

    sproc_msg -info "METRIC | STRING SYS.TASK           | $SEV(task)"
    sproc_msg -info "METRIC | STRING SYS.PROJECT_NAME   | $SEV(project_name)"
    sproc_msg -info "METRIC | STRING SYS.PROJECT_DIR    | $SEV(project_dir)"
    sproc_msg -info "METRIC | STRING SYS.TECHLIB_NAME   | $SEV(techlib_name)"
    sproc_msg -info "METRIC | STRING SYS.TECHLIB_DIR    | $SEV(techlib_dir)"
    sproc_msg -info "METRIC | STRING SYS.WORKAREA_DIR   | $SEV(workarea_dir)"
    sproc_msg -info "METRIC | STRING SYS.BLOCK_DIR      | $SEV(block_dir)"
    sproc_msg -info "METRIC | STRING SYS.USER           | [exec whoami]"
    sproc_msg -info "METRIC | STRING SYS.BLOCK          | $SVAR(design_name)"
    sproc_msg -info "METRIC | STRING SYS.STEP           | $SEV(step)"
    sproc_msg -info "METRIC | STRING SYS.SRC            | $SEV(src)"
    sproc_msg -info "METRIC | STRING SYS.DST            | $SEV(dst)"
    sproc_msg -info "METRIC | STRING SYS.LOG            | [file normalize $SEV(log_file)]"
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_NAME    | [file normalize $SEV(script_file)]"
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_VERSION | [sproc_script_version]"

    set script_type unknown
    if { [regexp "/scripts_global/" $SEV(script_file)] } {
      set script_type global
    }
    if { [regexp "/scripts_global/$SEV(techlib_name)/" $SEV(script_file)] } {
      set script_type techlib
    }
    if { [regexp "/scripts_block/" $SEV(script_file)] } {
      set script_type block
    }
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_TYPE    | $script_type"

    sproc_msg -info "METRIC | STRING SYS.MACHINE        | [exec uname -n]"
    sproc_msg -info "METRIC | STRING SYS.TOOL_NAME      | $synopsys_program_name"

    if { ![info exists sh_product_version] || $sh_product_version == "" } {
      set sh_product_version NaM
    }
    sproc_msg -info "METRIC | STRING SYS.TOOL_VERSION   | $sh_product_version"

    if { $SEV(dont_run) || $SEV(dont_exit) } {
      if { $SEV(analysis_task) } {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | ANALYZE_INTERACTIVE"
      } else {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | OPTIMIZE_INTERACTIVE"
      }
    } else {
      if { $SEV(analysis_task) } {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | ANALYZE"
      } else {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | OPTIMIZE"
      }
    }

    sproc_msg -info "METRIC | TAG SYS.TAG_01 | $SVAR(tag_01)"
    sproc_msg -info "METRIC | TAG SYS.TAG_02 | $SVAR(tag_02)"
    sproc_msg -info "METRIC | TAG SYS.TAG_03 | $SVAR(tag_03)"
    sproc_msg -info "METRIC | TAG SYS.TAG_04 | $SVAR(tag_04)"
    sproc_msg -info "METRIC | TAG SYS.TAG_05 | $SVAR(tag_05)"
    sproc_msg -info "METRIC | TAG SYS.TAG_06 | $SVAR(tag_06)"
    sproc_msg -info "METRIC | TAG SYS.TAG_07 | $SVAR(tag_07)"
    sproc_msg -info "METRIC | TAG SYS.TAG_08 | $SVAR(tag_08)"
    sproc_msg -info "METRIC | TAG SYS.TAG_09 | $SVAR(tag_09)"
    sproc_msg -info "METRIC | TAG SYS.TAG_10 | $SVAR(tag_10)"
    sproc_msg -info "METRIC | TAG SYS.TAG_11 | $SVAR(tag_11)"
    sproc_msg -info "METRIC | TAG SYS.TAG_12 | $SVAR(tag_12)"
    sproc_msg -info "METRIC | TAG SYS.TAG_13 | $SVAR(tag_13)"
    sproc_msg -info "METRIC | TAG SYS.TAG_14 | $SVAR(tag_14)"
    sproc_msg -info "METRIC | TAG SYS.TAG_15 | $SVAR(tag_15)"
    sproc_msg -info "METRIC | TAG SYS.TAG_16 | $SVAR(tag_16)"
    sproc_msg -info "METRIC | TAG SYS.TAG_17 | $SVAR(tag_17)"
    sproc_msg -info "METRIC | TAG SYS.TAG_18 | $SVAR(tag_18)"
    sproc_msg -info "METRIC | TAG SYS.TAG_19 | $SVAR(tag_19)"
    sproc_msg -info "METRIC | TAG SYS.TAG_20 | RTM_PRESENT !! [info exists env(LYNX_RTM_PRESENT)]" 

    sproc_metric_tags

    if { [info exists SEV(flow_order)] } {
      sproc_msg -info "METRIC | INTEGER SYS.FLOW_ORDER | $SEV(flow_order)"
    }

  }

  if { $options(-end_of_script) } {

    if { ![info exists TEV(num_jobs)] }        { set TEV(num_jobs) 1 }
    if { ![info exists TEV(num_cores)] }       { set TEV(num_cores) 1 }
    if { ![info exists TEV(num_child_jobs)] }  { set TEV(num_child_jobs) 1 }
    if { ![info exists TEV(num_child_cores)] } { set TEV(num_child_cores) 1 }

    sproc_msg -info "METRIC | INTEGER INFO.NUM_JOBS        | $TEV(num_jobs)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CORES       | $TEV(num_cores)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CHILD_JOBS  | $TEV(num_child_jobs)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CHILD_CORES | $TEV(num_child_cores)"

    sproc_msg -info "METRIC | INTEGER INFO.WARNING | $_sproc_msg_count(warning)"
    sproc_msg -info "METRIC | INTEGER INFO.ISSUE   | $_sproc_msg_count(issue)"
    sproc_msg -info "METRIC | INTEGER INFO.NOTE    | $_sproc_msg_count(note)"

    ## -------------------------------------
    ## Provide metric for job id
    ## -------------------------------------

    set job_id NaM

    if { [info exists env(LYNX_JOB)] } {

      ## -------------------------------------
      ## If env(LYNX_JOB) exists (set in the rtm_job_cmd file),
      ## then the task being run is a distributed job.
      ## -------------------------------------

      if { $SEV(job_app) == "lsf" } {
        if { [info exists env(LSB_JOBID)] } {
          set job_id $env(LSB_JOBID)
        }
      }
      if { $SEV(job_app) == "grd" } {
        if { [info exists env(JOB_ID)] } {
          set job_id $env(JOB_ID)
        }
      }

      sproc_msg -info "METRIC | STRING INFO.JOB_ID | $job_id"

    }

    ## -------------------------------------
    ## Provide metric for memory usage
    ## -------------------------------------

    set memory_used NaM
    set cputime_s NaM

    switch $synopsys_program_name {
      pt_shell {
        if { [info exists SEV(pt_dmsa_slave)] } {
          ## -------------------------------------
          ## If running DMSA, report the max memory across the master and slaves.
          ## -------------------------------------
          remote_execute { set slave_mem_kb [mem] }
          get_distributed_variables { slave_mem_kb }
          set mem_kb_list [mem]
          foreach session [array names slave_mem_kb] {
            lappend mem_kb_list $slave_mem_kb($session)
          }
          set mem_kb [lindex [lsort -integer -decreasing $mem_kb_list] 0]
        } else {
          set mem_kb [mem]
        }
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      dc_shell -
      icc_shell {
        set mem_kb [mem -all]
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      icc2_shell -
      icc2_lm_shell -
      fm_shell {
        set mem_kb [mem]
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      vcst {
        set mem_mb [get_resource_cost -tcl -mem]
        set memory_used $mem_mb
        set cputime_s [get_resource_cost -tcl -cpu]
      }
    }

    if { $options(-mem_mb) >= 0 } {
      set memory_used $options(-mem_mb)
    }

    sproc_msg -info "METRIC | INTEGER INFO.MEMORY_USED | $memory_used"

    if { $SEV(aro_enable) && ($job_id != "NaM") && ($memory_used != "NaM") } {

      set log_file [file normalize $SEV(log_file)]
      set file_part_org [file tail $log_file]
      set dir_part_org  [file dirname $log_file]
      set file_part_new .[file rootname $file_part_org].metrics.aro_mem
      set aro_mem_file $dir_part_org/$file_part_new

      file delete -force $aro_mem_file
      set fid [open $aro_mem_file w]
      puts $fid "INFO.MEMORY_USED|INTEGER|$memory_used"
      close $fid

      sproc_send_aro_mem -job_id $job_id -memory_used $memory_used

    }

    ## -------------------------------------
    ## Provide metric for license usage
    ## -------------------------------------

    set license_list [list]

    if { [info command list_licenses] == "list_licenses" } {
      redirect -var report {
        list_licenses
      }
      set lines [split $report "\n"]
      foreach line $lines {
        if { [regexp {^\s*$} $line] } {
          continue
        }
        if { [regexp {^\s+[\w\-]+} $line] } {
          lappend license_list [lindex $line 0]
        }
      }
    } elseif { $synopsys_program_name == "tmax_tcl" } {
      redirect -var report {
        report_licenses
      }
      set lines [split $report "\n"]
      foreach line $lines {
        if { [regexp {^\s*$} $line] } {
          continue
        } else {
          lappend license_list [lindex $line 0]
        }
      }
    }

    if { [llength $license_list] == 0 } {
      set license_list [list LicenseDataUnavailable]
    }

    sproc_msg -info "METRIC | STRING INFO.LICENSES | $license_list"

    if { [info exists SEV(metrics_enable_forward)] } {
      sproc_msg -info "METRIC | BOOLEAN INFO.METRICS_ENABLE_FORWARD | $SEV(metrics_enable_forward)"
    } else {
      sproc_msg -info "METRIC | BOOLEAN INFO.METRICS_ENABLE_FORWARD | 0"
    }

    ## -------------------------------------
    ## Flow Summary - Resource
    ## -------------------------------------

    ## -------------------------------------
    ## Define required attributes
    ## -------------------------------------

    set attributes [list]
    lappend attributes [list STEP   $SEV(step)]
    lappend attributes [list TASK   $SEV(task)]
    lappend attributes [list DST    $SEV(dst)]
    lappend attributes [list DESIGN $SVAR(design_name)]
    if { [info exists SEV(flow_order)] } {
      lappend attributes [list FLOW_ORDER $SEV(flow_order)]
    } else {
      lappend attributes [list FLOW_ORDER -1]
    }
    lappend attributes [list TYPE FLOW_SUMMARY]

    ## -------------------------------------
    ## Start output
    ## -------------------------------------

    set fs_output [list]

    lappend fs_output "{"

      ## -------------------------------------
      ## Process attributes
      ## -------------------------------------

      foreach attribute $attributes {
        set name  [lindex $attribute 0]
        set value [lindex $attribute 1]
        lappend fs_output "\"$name\": \"$value\""
      }
      lappend fs_output "\"flow_summary\": \["

      ## -------------------------------------
      ## All content below here is optional
      ## -------------------------------------

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Host"  -value [exec uname -n]]

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Tool"  -value $synopsys_program_name]

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Cores" -value $TEV(num_cores)]

      set wall_time [expr $SNPS_time_stop - $SNPS_time_start]
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Wall Time"  -value $wall_time]

      if { $cputime_s == "NaM" } {
        set cputime_s NA
        set cputime_e NA
      } else {
        set cputime_s [expr int($cputime_s)]
        if { ($cputime_s >= 10) && ($wall_time >= 10) } {
          set total_wall_time [expr $TEV(num_cores) * $wall_time]
          set cputime_e [format "%.2f" [expr double($cputime_s) / double($total_wall_time) * 100.0]]
        } else {
          set cputime_e NA
        }
      }
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "CPU Time"       -value $cputime_s]
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "CPU Efficiency" -value $cputime_e]

      if { $memory_used == "NaM" } {
        set value NA
      } else {
        set value $memory_used
      }
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Mem"   -value $value]

      ## -------------------------------------
      ## Complete output & create file
      ## -------------------------------------

      lappend fs_output "\]"

    lappend fs_output "}"

    set fs_output [sproc_qv_add_commas -lines $fs_output]
    set fs_output [join $fs_output "\n"]

    set fid [open $SEV(rpt_dir)/.$SEV(block_name).$SEV(step).$SEV(task).$SEV(dst).resource_summary-flow_summary.qor w]
    puts $fid $fs_output
    close $fid

  }

  set xxx2 [clock seconds]
  set xxx [expr $xxx2 - $xxx1]
  sproc_msg -info "METRICS sproc_metric_system took $xxx seconds"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_system \
  -info "Used to generate metrics related to task execution." \
  -define_args {
  {-start_of_script "Indicates routine is being called at start of script execution." "" boolean optional}
  {-end_of_script "Indicates routine is being called at end of script execution." "" boolean optional}
  {-mem_mb "The amount of memory used by the task. (Integer number of MBs)" AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_system:
## -----------------------------------------------------------------------------

proc sproc_metric_system { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV DEV
  global sh_product_version
  global synopsys_program_name
  global _sproc_msg_count
  global SNPS_time_start SNPS_time_stop

  set xxx1 [clock seconds]

  set options(-start_of_script) 0
  set options(-end_of_script) 0
  set options(-mem_mb) -1
  parse_proc_arguments -args $args options

  if { $options(-start_of_script) } {

    sproc_msg -info "METRIC | STRING SYS.TASK           | $SEV(task)"
    sproc_msg -info "METRIC | STRING SYS.PROJECT_NAME   | $SEV(project_name)"
    sproc_msg -info "METRIC | STRING SYS.PROJECT_DIR    | $SEV(project_dir)"
    sproc_msg -info "METRIC | STRING SYS.TECHLIB_NAME   | $SEV(techlib_name)"
    sproc_msg -info "METRIC | STRING SYS.TECHLIB_DIR    | $SEV(techlib_dir)"
    sproc_msg -info "METRIC | STRING SYS.WORKAREA_DIR   | $SEV(workarea_dir)"
    sproc_msg -info "METRIC | STRING SYS.BLOCK_DIR      | $SEV(block_dir)"
    sproc_msg -info "METRIC | STRING SYS.USER           | [exec whoami]"
    sproc_msg -info "METRIC | STRING SYS.BLOCK          | $SVAR(design_name)"
    sproc_msg -info "METRIC | STRING SYS.STEP           | $SEV(step)"
    sproc_msg -info "METRIC | STRING SYS.SRC            | $SEV(src)"
    sproc_msg -info "METRIC | STRING SYS.DST            | $SEV(dst)"
    sproc_msg -info "METRIC | STRING SYS.LOG            | [file normalize $SEV(log_file)]"
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_NAME    | [file normalize $SEV(script_file)]"
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_VERSION | [sproc_script_version]"

    set script_type unknown
    if { [regexp "/scripts_global/" $SEV(script_file)] } {
      set script_type global
    }
    if { [regexp "/scripts_global/$SEV(techlib_name)/" $SEV(script_file)] } {
      set script_type techlib
    }
    if { [regexp "/scripts_block/" $SEV(script_file)] } {
      set script_type block
    }
    sproc_msg -info "METRIC | STRING SYS.SCRIPT_TYPE    | $script_type"

    sproc_msg -info "METRIC | STRING SYS.MACHINE        | [exec uname -n]"
    sproc_msg -info "METRIC | STRING SYS.TOOL_NAME      | $synopsys_program_name"

    if { ![info exists sh_product_version] || $sh_product_version == "" } {
      set sh_product_version NaM
    }
    sproc_msg -info "METRIC | STRING SYS.TOOL_VERSION   | $sh_product_version"

    if { $SEV(dont_run) || $SEV(dont_exit) } {
      if { $SEV(analysis_task) } {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | ANALYZE_INTERACTIVE"
      } else {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | OPTIMIZE_INTERACTIVE"
      }
    } else {
      if { $SEV(analysis_task) } {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | ANALYZE"
      } else {
        sproc_msg -info "METRIC | STRING SYS.TASK_TYPE      | OPTIMIZE"
      }
    }

    sproc_msg -info "METRIC | TAG SYS.TAG_01 | $SVAR(tag_01)"
    sproc_msg -info "METRIC | TAG SYS.TAG_02 | $SVAR(tag_02)"
    sproc_msg -info "METRIC | TAG SYS.TAG_03 | $SVAR(tag_03)"
    sproc_msg -info "METRIC | TAG SYS.TAG_04 | $SVAR(tag_04)"
    sproc_msg -info "METRIC | TAG SYS.TAG_05 | $SVAR(tag_05)"
    sproc_msg -info "METRIC | TAG SYS.TAG_06 | $SVAR(tag_06)"
    sproc_msg -info "METRIC | TAG SYS.TAG_07 | $SVAR(tag_07)"
    sproc_msg -info "METRIC | TAG SYS.TAG_08 | $SVAR(tag_08)"
    sproc_msg -info "METRIC | TAG SYS.TAG_09 | $SVAR(tag_09)"
    sproc_msg -info "METRIC | TAG SYS.TAG_10 | $SVAR(tag_10)"
    sproc_msg -info "METRIC | TAG SYS.TAG_11 | $SVAR(tag_11)"
    sproc_msg -info "METRIC | TAG SYS.TAG_12 | $SVAR(tag_12)"
    sproc_msg -info "METRIC | TAG SYS.TAG_13 | $SVAR(tag_13)"
    sproc_msg -info "METRIC | TAG SYS.TAG_14 | $SVAR(tag_14)"
    sproc_msg -info "METRIC | TAG SYS.TAG_15 | $SVAR(tag_15)"
    sproc_msg -info "METRIC | TAG SYS.TAG_16 | $SVAR(tag_16)"
    sproc_msg -info "METRIC | TAG SYS.TAG_17 | $SVAR(tag_17)"
    sproc_msg -info "METRIC | TAG SYS.TAG_18 | $SVAR(tag_18)"
    sproc_msg -info "METRIC | TAG SYS.TAG_19 | $SVAR(tag_19)"
    sproc_msg -info "METRIC | TAG SYS.TAG_20 | RTM_PRESENT !! [info exists env(LYNX_RTM_PRESENT)]" 

    sproc_metric_tags

    if { [info exists SEV(flow_order)] } {
      sproc_msg -info "METRIC | INTEGER SYS.FLOW_ORDER | $SEV(flow_order)"
    }

  }

  if { $options(-end_of_script) } {

    if { ![info exists TEV(num_jobs)] }        { set TEV(num_jobs) 1 }
    if { ![info exists TEV(num_cores)] }       { set TEV(num_cores) 1 }
    if { ![info exists TEV(num_child_jobs)] }  { set TEV(num_child_jobs) 1 }
    if { ![info exists TEV(num_child_cores)] } { set TEV(num_child_cores) 1 }

    sproc_msg -info "METRIC | INTEGER INFO.NUM_JOBS        | $TEV(num_jobs)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CORES       | $TEV(num_cores)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CHILD_JOBS  | $TEV(num_child_jobs)"
    sproc_msg -info "METRIC | INTEGER INFO.NUM_CHILD_CORES | $TEV(num_child_cores)"

    sproc_msg -info "METRIC | INTEGER INFO.WARNING | $_sproc_msg_count(warning)"
    sproc_msg -info "METRIC | INTEGER INFO.ISSUE   | $_sproc_msg_count(issue)"
    sproc_msg -info "METRIC | INTEGER INFO.NOTE    | $_sproc_msg_count(note)"

    ## -------------------------------------
    ## Provide metric for job id
    ## -------------------------------------

    set job_id NaM

    if { [info exists env(LYNX_JOB)] } {

      ## -------------------------------------
      ## If env(LYNX_JOB) exists (set in the rtm_job_cmd file),
      ## then the task being run is a distributed job.
      ## -------------------------------------

      if { $SEV(job_app) == "lsf" } {
        if { [info exists env(LSB_JOBID)] } {
          set job_id $env(LSB_JOBID)
        }
      }
      if { $SEV(job_app) == "grd" } {
        if { [info exists env(JOB_ID)] } {
          set job_id $env(JOB_ID)
        }
      }

      sproc_msg -info "METRIC | STRING INFO.JOB_ID | $job_id"

    }

    ## -------------------------------------
    ## Provide metric for memory usage
    ## -------------------------------------

    set memory_used NaM
    set cputime_s NaM

    switch $synopsys_program_name {
      pt_shell {
        if { [info exists SEV(pt_dmsa_slave)] } {
          ## -------------------------------------
          ## If running DMSA, report the max memory across the master and slaves.
          ## -------------------------------------
          remote_execute { set slave_mem_kb [mem] }
          get_distributed_variables { slave_mem_kb }
          set mem_kb_list [mem]
          foreach session [array names slave_mem_kb] {
            lappend mem_kb_list $slave_mem_kb($session)
          }
          set mem_kb [lindex [lsort -integer -decreasing $mem_kb_list] 0]
        } else {
          set mem_kb [mem]
        }
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      dc_shell -
      icc_shell {
        set mem_kb [mem -all]
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      icc2_shell -
      icc2_lm_shell -
      fm_shell {
        set mem_kb [mem]
        set mem_b [expr $mem_kb * pow(2,10)]
        set mem_mb [expr int($mem_b / pow(2,20)) + 1]
        set memory_used $mem_mb
        set cputime_s [cputime]
      }
      vcst {
        set mem_mb [get_resource_cost -tcl -mem]
        set memory_used $mem_mb
        set cputime_s [get_resource_cost -tcl -cpu]
      }
    }

    if { $options(-mem_mb) >= 0 } {
      set memory_used $options(-mem_mb)
    }

    sproc_msg -info "METRIC | INTEGER INFO.MEMORY_USED | $memory_used"

    if { $SEV(aro_enable) && ($job_id != "NaM") && ($memory_used != "NaM") } {

      set log_file [file normalize $SEV(log_file)]
      set file_part_org [file tail $log_file]
      set dir_part_org  [file dirname $log_file]
      set file_part_new .[file rootname $file_part_org].metrics.aro_mem
      set aro_mem_file $dir_part_org/$file_part_new

      file delete -force $aro_mem_file
      set fid [open $aro_mem_file w]
      puts $fid "INFO.MEMORY_USED|INTEGER|$memory_used"
      close $fid

      sproc_send_aro_mem -job_id $job_id -memory_used $memory_used

    }

    ## -------------------------------------
    ## Provide metric for license usage
    ## -------------------------------------

    set license_list [list]

    if { [info command list_licenses] == "list_licenses" } {
      redirect -var report {
        list_licenses
      }
      set lines [split $report "\n"]
      foreach line $lines {
        if { [regexp {^\s*$} $line] } {
          continue
        }
        if { [regexp {^\s+[\w\-]+} $line] } {
          lappend license_list [lindex $line 0]
        }
      }
    } elseif { $synopsys_program_name == "tmax_tcl" } {
      redirect -var report {
        report_licenses
      }
      set lines [split $report "\n"]
      foreach line $lines {
        if { [regexp {^\s*$} $line] } {
          continue
        } else {
          lappend license_list [lindex $line 0]
        }
      }
    }

    if { [llength $license_list] == 0 } {
      set license_list [list LicenseDataUnavailable]
    }

    sproc_msg -info "METRIC | STRING INFO.LICENSES | $license_list"

    if { [info exists SEV(metrics_enable_forward)] } {
      sproc_msg -info "METRIC | BOOLEAN INFO.METRICS_ENABLE_FORWARD | $SEV(metrics_enable_forward)"
    } else {
      sproc_msg -info "METRIC | BOOLEAN INFO.METRICS_ENABLE_FORWARD | 0"
    }

    ## -------------------------------------
    ## Flow Summary - Resource
    ## -------------------------------------

    ## -------------------------------------
    ## Define required attributes
    ## -------------------------------------

    set attributes [list]
    lappend attributes [list STEP   $SEV(step)]
    lappend attributes [list TASK   $SEV(task)]
    lappend attributes [list DST    $SEV(dst)]
    lappend attributes [list DESIGN $SVAR(design_name)]
    if { [info exists SEV(flow_order)] } {
      lappend attributes [list FLOW_ORDER $SEV(flow_order)]
    } else {
      lappend attributes [list FLOW_ORDER -1]
    }
    lappend attributes [list TYPE FLOW_SUMMARY]

    ## -------------------------------------
    ## Start output
    ## -------------------------------------

    set fs_output [list]

    lappend fs_output "{"

      ## -------------------------------------
      ## Process attributes
      ## -------------------------------------

      foreach attribute $attributes {
        set name  [lindex $attribute 0]
        set value [lindex $attribute 1]
        lappend fs_output "\"$name\": \"$value\""
      }
      lappend fs_output "\"flow_summary\": \["

      ## -------------------------------------
      ## All content below here is optional
      ## -------------------------------------

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Host"  -value [exec uname -n]]

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Tool"  -value $synopsys_program_name]

      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Cores" -value $TEV(num_cores)]

      set wall_time [expr $SNPS_time_stop - $SNPS_time_start]
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Wall Time"  -value $wall_time]

      if { $cputime_s == "NaM" } {
        set cputime_s NA
        set cputime_e NA
      } else {
        set cputime_s [expr int($cputime_s)]
        if { ($cputime_s >= 10) && ($wall_time >= 10) } {
          set total_wall_time [expr $TEV(num_cores) * $wall_time]
          set cputime_e [format "%.2f" [expr double($cputime_s) / double($total_wall_time) * 100.0]]
        } else {
          set cputime_e NA
        }
      }
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "CPU Time"       -value $cputime_s]
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "CPU Efficiency" -value $cputime_e]

      if { $memory_used == "NaM" } {
        set value NA
      } else {
        set value $memory_used
      }
      set fs_output [sproc_qv_flow_summary -o $fs_output -name "Mem"   -value $value]

      ## -------------------------------------
      ## Complete output & create file
      ## -------------------------------------

      lappend fs_output "\]"

    lappend fs_output "}"

    set fs_output [sproc_qv_add_commas -lines $fs_output]
    set fs_output [join $fs_output "\n"]

    set fid [open $SEV(rpt_dir)/.$SEV(block_name).$SEV(step).$SEV(task).$SEV(dst).resource_summary-flow_summary.qor w]
    puts $fid $fs_output
    close $fid

  }

  set xxx2 [clock seconds]
  set xxx [expr $xxx2 - $xxx1]
  sproc_msg -info "METRICS sproc_metric_system took $xxx seconds"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_system \
  -info "Used to generate metrics related to task execution." \
  -define_args {
  {-start_of_script "Indicates routine is being called at start of script execution." "" boolean optional}
  {-end_of_script "Indicates routine is being called at end of script execution." "" boolean optional}
  {-mem_mb "The amount of memory used by the task. (Integer number of MBs)" AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_time:
## -----------------------------------------------------------------------------

proc sproc_metric_time { args } {

  sproc_pinfo -mode start

  global SEV
  global SNPS_time_start SNPS_time_stop SNPS_rpt_time_elapsed

  set options(-start) 0
  set options(-stop) 0

  parse_proc_arguments -args $args options

  if { $options(-start) } {
    ## This code for GMT support is not for this release.
    ## set gmt_date [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y" -gmt 1]
    ## set gmt_seconds [clock scan $gmt_date -gmt 1]
    ## sproc_msg -info "METRIC | TIMESTAMP SYS.START_TIME  | $gmt_seconds"
    sproc_msg -info "METRIC | TIMESTAMP SYS.START_TIME  | [clock seconds]"

    sproc_msg -info "SYS.START_TIME | [date]"
    set SNPS_time_start [clock seconds]
  }

  if { $options(-stop) } {
    ## This code for GMT support is not for this release.
    ## set gmt_date [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y" -gmt 1]
    ## set gmt_seconds [clock scan $gmt_date -gmt 1]
    ## sproc_msg -info "METRIC | TIMESTAMP SYS.STOP_TIME   | $gmt_seconds"
    sproc_msg -info "METRIC | TIMESTAMP SYS.STOP_TIME   | [clock seconds]"

    sproc_msg -info "SYS.STOP_TIME | [date]"
    set SNPS_time_stop [clock seconds]
    set SNPS_time_total_seconds [expr $SNPS_time_stop - $SNPS_time_start]
    set dhms [sproc_metric_time_elapsed -start $SNPS_time_start -stop $SNPS_time_stop]
    sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.TOTAL | $SNPS_time_total_seconds"
    sproc_msg -info "INFO.ELAPSED_TIME.TOTAL | $dhms"

    if { [info exists SNPS_rpt_time_elapsed] } {
      set SNPS_time_stop_minus_reports [expr $SNPS_time_stop - $SNPS_rpt_time_elapsed]
      set SNPS_time_total_minus_reports_seconds [ expr $SNPS_time_stop_minus_reports - $SNPS_time_start]
      set dhms [sproc_metric_time_elapsed -start $SNPS_time_start -stop $SNPS_time_stop_minus_reports]
      sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.TOTAL_MINUS_REPORT | $SNPS_time_total_minus_reports_seconds"
      sproc_msg -info "INFO.ELAPSED_TIME.TOTAL_MINUS_REPORT | $dhms"
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_time \
  -info "Used to generate metrics related to duration of task execution." \
  -define_args {
  {-start "Indicates routine is being called to provide start time info.." "" boolean optional}
  {-stop "Indicates routine is being called to provide stop time info." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_time:
## -----------------------------------------------------------------------------

proc sproc_metric_time { args } {

  sproc_pinfo -mode start

  global SEV
  global SNPS_time_start SNPS_time_stop SNPS_rpt_time_elapsed

  set options(-start) 0
  set options(-stop) 0

  parse_proc_arguments -args $args options

  if { $options(-start) } {
    ## This code for GMT support is not for this release.
    ## set gmt_date [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y" -gmt 1]
    ## set gmt_seconds [clock scan $gmt_date -gmt 1]
    ## sproc_msg -info "METRIC | TIMESTAMP SYS.START_TIME  | $gmt_seconds"
    sproc_msg -info "METRIC | TIMESTAMP SYS.START_TIME  | [clock seconds]"

    sproc_msg -info "SYS.START_TIME | [date]"
    set SNPS_time_start [clock seconds]
  }

  if { $options(-stop) } {
    ## This code for GMT support is not for this release.
    ## set gmt_date [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y" -gmt 1]
    ## set gmt_seconds [clock scan $gmt_date -gmt 1]
    ## sproc_msg -info "METRIC | TIMESTAMP SYS.STOP_TIME   | $gmt_seconds"
    sproc_msg -info "METRIC | TIMESTAMP SYS.STOP_TIME   | [clock seconds]"

    sproc_msg -info "SYS.STOP_TIME | [date]"
    set SNPS_time_stop [clock seconds]
    set SNPS_time_total_seconds [expr $SNPS_time_stop - $SNPS_time_start]
    set dhms [sproc_metric_time_elapsed -start $SNPS_time_start -stop $SNPS_time_stop]
    sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.TOTAL | $SNPS_time_total_seconds"
    sproc_msg -info "INFO.ELAPSED_TIME.TOTAL | $dhms"

    if { [info exists SNPS_rpt_time_elapsed] } {
      set SNPS_time_stop_minus_reports [expr $SNPS_time_stop - $SNPS_rpt_time_elapsed]
      set SNPS_time_total_minus_reports_seconds [ expr $SNPS_time_stop_minus_reports - $SNPS_time_start]
      set dhms [sproc_metric_time_elapsed -start $SNPS_time_start -stop $SNPS_time_stop_minus_reports]
      sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.TOTAL_MINUS_REPORT | $SNPS_time_total_minus_reports_seconds"
      sproc_msg -info "INFO.ELAPSED_TIME.TOTAL_MINUS_REPORT | $dhms"
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_time \
  -info "Used to generate metrics related to duration of task execution." \
  -define_args {
  {-start "Indicates routine is being called to provide start time info.." "" boolean optional}
  {-stop "Indicates routine is being called to provide stop time info." "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_normalize:
## -----------------------------------------------------------------------------

proc sproc_metric_normalize { args } {

  sproc_pinfo -mode start

  ## table contains the multiplier for converting from supplied unit to normalized default
  set default_power_unit mw
  set normalize_lut(w)    1e+3
  set normalize_lut(mw)   1e+0
  set normalize_lut(uw)   1e-3
  set normalize_lut(nw)   1e-6
  set normalize_lut(pw)   1e-9

  set default_time_unit ps
  set normalize_lut(s)    1e+12
  set normalize_lut(ns)   1e+3
  set normalize_lut(ps)   1e+0

  set default_area_unit um
  set normalize_lut(nm)   1e-3
  set normalize_lut(um)   1e+0
  set normalize_lut(m)    1e+6

  set options(-value) ""
  set options(-current_unit) ""

  parse_proc_arguments -args $args options

  set val $options(-value)

  if { $val=="NaM" } {
    sproc_msg -info "Passing through special case value $val"
    sproc_pinfo -mode stop
    return $val
  }

  if { ![scan $val "%f" match] } {
    sproc_msg -error "sproc_metric_normalize cannot process value $val"
    sproc_pinfo -mode stop
    return "NaM"
  }

  if { $options(-current_unit) != "" } {
    set cur_unit [string tolower $options(-current_unit)]
    if { [array names normalize_lut -exact $cur_unit] != "" } {
      set norm_scalar $normalize_lut($cur_unit)
    } else {
      sproc_msg -error "sproc_metric_normalize not configured to convert $cur_unit"
      sproc_pinfo -mode stop
      return "NaM"
    }
  }

  set val_out [expr $val * $norm_scalar]

  sproc_pinfo -mode stop

  return $val_out

}

define_proc_attributes sproc_metric_normalize \
  -info "Used to convert metric numbers from one unit standard to another." \
  -define_args {
  {-value "value to convert" decimal string required}
  {-current_unit "Units of current value" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_clean_string:
## -----------------------------------------------------------------------------

proc sproc_metric_clean_string { args } {

  sproc_pinfo -mode start

  set options(-string) ""
  parse_proc_arguments -args $args options

  set string_before $options(-string)

  ## Only allow alphanumric and underscore characters
  set string_after [regsub -all { [^\w\.] } $string_before {_}]

  if {![string match $string_after $string_before]} {
    sproc_msg -warn "sproc_metric_clean_string: String <$string_before> changed to <$string_after>"
  }

  sproc_pinfo -mode stop

  return $string_after
}

define_proc_attributes sproc_metric_clean_string \
  -info "Removes characters not supported for metric strings." \
  -define_args {
  {-string  "The string that needs cleaning." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_time_elapsed:
## -----------------------------------------------------------------------------

proc sproc_metric_time_elapsed { args } {

  sproc_pinfo -mode start

  set options(-start) 0
  set options(-stop) 0
  parse_proc_arguments -args $args options

  set seconds_in_day [expr 24 * 3600.0]
  set total_seconds [expr $options(-stop) - $options(-start)]
  set num_days_f [expr floor($total_seconds / $seconds_in_day)]
  set partial_day_f [expr ($total_seconds / $seconds_in_day) - $num_days_f]
  set num_days [expr int($num_days_f)]
  set partial_day [expr int($partial_day_f * $seconds_in_day)]
  set hms [clock format $partial_day -format %T -gmt true]
  set dhms [format "%02d:%s" $num_days $hms]

  sproc_pinfo -mode stop
  return "$dhms"
}

define_proc_attributes sproc_metric_time_elapsed \
  -info "Used to generate metrics related to duration of task execution." \
  -define_args {
  {-start "Indicates start time in seconds." "" int required}
  {-stop  "Indicates stop time in seconds." "" int required}
}

## -----------------------------------------------------------------------------
## sproc_metric_time_elapsed:
## -----------------------------------------------------------------------------

proc sproc_metric_time_elapsed { args } {

  sproc_pinfo -mode start

  set options(-start) 0
  set options(-stop) 0
  parse_proc_arguments -args $args options

  set seconds_in_day [expr 24 * 3600.0]
  set total_seconds [expr $options(-stop) - $options(-start)]
  set num_days_f [expr floor($total_seconds / $seconds_in_day)]
  set partial_day_f [expr ($total_seconds / $seconds_in_day) - $num_days_f]
  set num_days [expr int($num_days_f)]
  set partial_day [expr int($partial_day_f * $seconds_in_day)]
  set hms [clock format $partial_day -format %T -gmt true]
  set dhms [format "%02d:%s" $num_days $hms]

  sproc_pinfo -mode stop
  return "$dhms"
}

define_proc_attributes sproc_metric_time_elapsed \
  -info "Used to generate metrics related to duration of task execution." \
  -define_args {
  {-start "Indicates start time in seconds." "" int required}
  {-stop  "Indicates stop time in seconds." "" int required}
}

## -----------------------------------------------------------------------------
## sproc_early_complete:
## -----------------------------------------------------------------------------

proc sproc_early_complete  { args } {

  sproc_pinfo -mode start

  global SEV SVAR
  global synopsys_program_name

  set options(-suppress) 0
  parse_proc_arguments -args $args options

  if { $SVAR(misc,early_complete_enable) && ( $options(-suppress) == 0 ) } {

    sproc_msg -warning "Early complete enabled."

    set fname [file rootname $SEV(log_file)].early
    set fid [open $fname w]
    puts $fid "Early complete at [date]"
    close $fid

  } else {

    sproc_msg -warning "Early complete disabled."

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_early_complete  \
  -info "Procedure to signal early completion of task to RTM." \
  -define_args {
  {-suppress      "Optionally disable early complete (0 enable, 1 disable)." AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_early_complete:
## -----------------------------------------------------------------------------

proc sproc_early_complete  { args } {

  sproc_pinfo -mode start

  global SEV SVAR
  global synopsys_program_name

  set options(-suppress) 0
  parse_proc_arguments -args $args options

  if { $SVAR(misc,early_complete_enable) && ( $options(-suppress) == 0 ) } {

    sproc_msg -warning "Early complete enabled."

    set fname [file rootname $SEV(log_file)].early
    set fid [open $fname w]
    puts $fid "Early complete at [date]"
    close $fid

  } else {

    sproc_msg -warning "Early complete disabled."

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_early_complete  \
  -info "Procedure to signal early completion of task to RTM." \
  -define_args {
  {-suppress      "Optionally disable early complete (0 enable, 1 disable)." AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_pt_report_qor:
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
## sproc_pt_report_qor:
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
## sproc_pt_report_qor_count_levels:
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
## sproc_pt_report_qor_count_levels:
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
## sproc_send_aro_mem:
## -----------------------------------------------------------------------------

proc sproc_send_aro_mem { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-job_id) ""
  set options(-memory_used) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Open a blocking-style socket
  ## -------------------------------------

  set socket_host $SEV(aro_server)
  set socket_port $SEV(aro_port)

  set socket_ok 0
  set max_socket_attempts 10
  for { set i 1 } { $i < [expr $max_socket_attempts + 1] } { incr i } {
    set socket_return [catch { socket $socket_host $socket_port } socket_channel]
    if { $socket_return } {
      puts "SNPS_INFO: Unable to establish socket channel on attempt $i"
      after 1000
    } else {
      set socket_ok 1
      break
    }
  }

  if { !$socket_ok } {
    puts "SNPS_ERROR : Unable to create socket ($socket_host:$socket_port) from [info host] to ARO Daemon"
    puts "SNPS_ERROR : Socket returns $socket_channel"
  } else {

    fconfigure $socket_channel -blocking 1

    ## -------------------------------------
    ## Send MEM command to ARO daemon
    ## -------------------------------------

    puts $socket_channel "ARO_MEM_START"
    puts $socket_channel "FILE|$options(-job_id).aro_mem"
    puts $socket_channel "INFO.MEMORY_USED|INTEGER|$options(-memory_used)"
    puts $socket_channel "ARO_MEM_STOP"

    flush $socket_channel

    ## -------------------------------------
    ## Read MEM response from ARO daemon
    ## -------------------------------------

    set lines [list]
    while {1} {
      set line [gets $socket_channel]
      if { [eof $socket_channel] } {
        close $socket_channel
        break
      } else {
        lappend lines $line
      }
    }

    set aro_reply_status [lindex [split [lindex $lines 0] "|"] 0]
    set aro_reply_msg    [lindex [split [lindex $lines 0] "|"] 1]

    if { $aro_reply_status == "1" } {
      sproc_msg -info "Successful send of ARO_MEM"
    } else {
      sproc_msg -error "Reply during ARO_MEM: $aro_reply_msg"
    }

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_send_aro_mem \
  -info "Used to determine the version of a script." \
  -define_args {
  {-job_id      "The job id for the task reporting memory usage." AnInt int required}
  {-memory_used "The amount of memory in MB."                     AnInt int required}
}

## -----------------------------------------------------------------------------
## sproc_send_aro_mem:
## -----------------------------------------------------------------------------

proc sproc_send_aro_mem { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-job_id) ""
  set options(-memory_used) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Open a blocking-style socket
  ## -------------------------------------

  set socket_host $SEV(aro_server)
  set socket_port $SEV(aro_port)

  set socket_ok 0
  set max_socket_attempts 10
  for { set i 1 } { $i < [expr $max_socket_attempts + 1] } { incr i } {
    set socket_return [catch { socket $socket_host $socket_port } socket_channel]
    if { $socket_return } {
      puts "SNPS_INFO: Unable to establish socket channel on attempt $i"
      after 1000
    } else {
      set socket_ok 1
      break
    }
  }

  if { !$socket_ok } {
    puts "SNPS_ERROR : Unable to create socket ($socket_host:$socket_port) from [info host] to ARO Daemon"
    puts "SNPS_ERROR : Socket returns $socket_channel"
  } else {

    fconfigure $socket_channel -blocking 1

    ## -------------------------------------
    ## Send MEM command to ARO daemon
    ## -------------------------------------

    puts $socket_channel "ARO_MEM_START"
    puts $socket_channel "FILE|$options(-job_id).aro_mem"
    puts $socket_channel "INFO.MEMORY_USED|INTEGER|$options(-memory_used)"
    puts $socket_channel "ARO_MEM_STOP"

    flush $socket_channel

    ## -------------------------------------
    ## Read MEM response from ARO daemon
    ## -------------------------------------

    set lines [list]
    while {1} {
      set line [gets $socket_channel]
      if { [eof $socket_channel] } {
        close $socket_channel
        break
      } else {
        lappend lines $line
      }
    }

    set aro_reply_status [lindex [split [lindex $lines 0] "|"] 0]
    set aro_reply_msg    [lindex [split [lindex $lines 0] "|"] 1]

    if { $aro_reply_status == "1" } {
      sproc_msg -info "Successful send of ARO_MEM"
    } else {
      sproc_msg -error "Reply during ARO_MEM: $aro_reply_msg"
    }

  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_send_aro_mem \
  -info "Used to determine the version of a script." \
  -define_args {
  {-job_id      "The job id for the task reporting memory usage." AnInt int required}
  {-memory_used "The amount of memory in MB."                     AnInt int required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_units:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_units { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag)       0
  set rval(time_unit)        "undefined"

  set rval(text_time)        "undefined"
  set rval(text_capacitance) "undefined"
  set rval(text_resistance)  "undefined"
  set rval(text_voltage)     "undefined"
  set rval(text_power)       "undefined"
  set rval(text_current)     "undefined"

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  if { $synopsys_program_name == "icc2_shell" } {

    foreach line $lines {
      regexp {^time\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_time)
      regexp {^resistance\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_capacitance)
      regexp {^capacitance\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_resistance)
      regexp {^voltage\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_voltage)
      regexp {^current\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_power)
      regexp {^power\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_current)
    }
    set rval(time_unit) $rval(text_time)

  } else {

    set time_unit undefined
    foreach line $lines {
      regexp {(e\-\S\S)\s+Second} $line match time_unit

      regexp {^Time_unit\s+:\s+(.*)\s*$} $line match rval(text_time)
      regexp {^Capacitive_load_unit\s+:\s+(.*)\s*$} $line match rval(text_capacitance)
      regexp {^Resistance_unit\s+:\s+(.*)\s*$} $line match rval(text_resistance)
      regexp {^Voltage_unit\s+:\s+(.*)\s*$} $line match rval(text_voltage)
      regexp {^Power_unit\s+:\s+(.*)\s*$} $line match rval(text_power)
      regexp {^Current_unit\s+:\s+(.*)\s*$} $line match rval(text_current)
    }

    switch $time_unit {
      e-00 {
        set rval(time_unit) s
      }
      e-03 {
        set rval(time_unit) ms
      }
      e-06 {
        set rval(time_unit) us
      }
      e-09 {
        set rval(time_unit) ns
      }
      e-12 {
        set rval(time_unit) ps
      }
      e-15 {
        set rval(time_unit) fs
      }
      default {
        sproc_msg -error "Unrecognized value for time units: $time_unit"
        set rval(error_flag) 1
      }
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_units \
  -info "Parses information for report_units." \
  -define_args {\
    {-file "The report_units file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_qor:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_qor { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report for path group information.
  ## -------------------------------------

  set rval(path_group_data,scenario_name_list) [list]

  set scenario_name None/non-MCMM

  set line_number 0
  set path_group_name NO_PATH_GROUP
  foreach line $lines {
    incr line_number

    regexp {^\s*Scenario\s+\'(.*)\'} $line matchVar scenario_name

    if { [regexp {^\s*Timing Path Group\s+'(\S+)'} $line matchVar path_group_name] } {

      lappend rval(path_group_data,scenario_name_list) $scenario_name
      lappend rval(path_group_data,path_group_name_list,$scenario_name) $path_group_name

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack)   NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack)    NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns)           NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp)           NA

      set rval(path_group_data,$scenario_name,$path_group_name,line_number) $line_number

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) 1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number)   1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number)    1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number)           1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number)           1
    }

    if { [regexp {^\s*Levels of Logic:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Length:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Clk Period:\s+(\S+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number) $line_number
    }
    if { [regexp {^\s*Total Negative Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Violating Paths:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number) $line_number
    }
    if { [regexp {^\s*Worst Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Total Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Hold Violations:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number) $line_number
    }
  }

  set rval(path_group_data,scenario_name_list) [lsort -unique $rval(path_group_data,scenario_name_list)]
  foreach scenario_name $rval(path_group_data,scenario_name_list) {
    set rval(path_group_data,path_group_name_list,$scenario_name) [lsort -unique $rval(path_group_data,path_group_name_list,$scenario_name)]
  }

  ## -------------------------------------
  ## Parse the report for summary information.
  ## -------------------------------------

  set rval(summary_data,_ss,scenario_name_list) [list]
  ## rval(summary_data,_ss,$scenario_name,setup,path_slack)
  ## rval(summary_data,_ss,$scenario_name,setup,tns)
  ## rval(summary_data,_ss,$scenario_name,setup,nvp)
  ## rval(summary_data,_ss,$scenario_name,hold,path_slack)
  ## rval(summary_data,_ss,$scenario_name,hold,tns)
  ## rval(summary_data,_ss,$scenario_name,hold,nvp)

  ## rval(summary_data,_ms,setup,path_slack)
  ## rval(summary_data,_ms,setup,tns)
  ## rval(summary_data,_ms,setup,nvp)
  ## rval(summary_data,_ms,hold,path_slack)
  ## rval(summary_data,_ms,hold,tns)
  ## rval(summary_data,_ms,hold,nvp)

  set line_number 0
  foreach line $lines {
    incr line_number

    if { $synopsys_program_name == "icc2_shell" } {

      ## -------------------------------------
      ## Per-scenario setup
      ## -------------------------------------

      if { [scan $line { %s (Setup) %e %e %d } scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,setup,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,setup,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-scenario hold
      ## -------------------------------------

      if { [scan $line { %s (Hold) %e %e %d } scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,hold,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,hold,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design setup
      ## -------------------------------------

      if { [scan $line { Design (Setup) %e %e %d } wns tns nvp] == 3 } {
        set rval(summary_data,_ms,setup,path_slack)             $wns
        set rval(summary_data,_ms,setup,tns)                    $tns
        set rval(summary_data,_ms,setup,nvp)                    $nvp
        set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ms,setup,tns,line_number)        $line_number
        set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design hold
      ## -------------------------------------

      if { [scan $line { Design (Hold) %e %e %d } wns tns nvp] == 3 } {
        set rval(summary_data,_ms,hold,path_slack)             $wns
        set rval(summary_data,_ms,hold,tns)                    $tns
        set rval(summary_data,_ms,hold,nvp)                    $nvp
        set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ms,hold,tns,line_number)        $line_number
        set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
      }

    } else {

      ## -------------------------------------
      ## Per-scenario setup
      ## -------------------------------------

      if { [scan $line { Scenario: %s WNS: %e TNS: %e Number of Violating Paths: %d} scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ss,$scenario_name,setup,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ss,$scenario_name,setup,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-scenario hold
      ## -------------------------------------

      if { [scan $line { Scenario: %s (Hold) WNS: %e TNS: %e Number of Violating Paths: %d} scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ss,$scenario_name,hold,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ss,$scenario_name,hold,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design setup
      ## -------------------------------------

      if { [scan $line { Design WNS: %e TNS: %e Number of Violating Paths: %d} wns tns nvp] == 3 } {
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ms,setup,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ms,setup,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ms,setup,nvp)                    $nvp
        set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ms,setup,tns,line_number)        $line_number
        set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design hold
      ## -------------------------------------

      if { [scan $line { Design (Hold) WNS: %e TNS: %e Number of Violating Paths: %d} wns tns nvp] == 3 } {
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ms,hold,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ms,hold,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ms,hold,nvp)                    $nvp
        set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ms,hold,tns,line_number)        $line_number
        set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
      }

    }

  }

  set rval(summary_data,_ss,scenario_name_list) [lsort -unique $rval(summary_data,_ss,scenario_name_list)]

  ## -------------------------------------
  ## A "pt_concat.report_qor" file is generated after DMSA processing and is simply
  ## a concatenation of the "report_qor" files for each scenario (generated by the PT slaves),
  ## and the "pt_master.report_global_timing" file (generated by the PT master).
  ## The per-design metrics are extracted from the "pt_master.report_global_timing" content.
  ## -------------------------------------

  if { [file tail $options(-file)] == "pt_concat.report_qor" } {

    unset -nocomplain rval(summary_data,_ms,setup,path_slack)
    unset -nocomplain rval(summary_data,_ms,setup,tns)
    unset -nocomplain rval(summary_data,_ms,setup,nvp)
    unset -nocomplain rval(summary_data,_ms,setup,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,nvp,line_number)

    unset -nocomplain rval(summary_data,_ms,hold,path_slack)
    unset -nocomplain rval(summary_data,_ms,hold,tns)
    unset -nocomplain rval(summary_data,_ms,hold,nvp)
    unset -nocomplain rval(summary_data,_ms,hold,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,nvp,line_number)

    set line_number 0
    foreach line $lines {
      incr line_number

      if { [regexp {^Setup violations} $line] } {
        set type setup
      }
      if { [regexp {^Hold violations} $line] } {
        set type hold
      }

      if { [regexp {^WNS} $line] } {
        set rval(summary_data,_ms,$type,path_slack) [lindex $line 1]
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
      }
      if { [regexp {^TNS} $line] } {
        set rval(summary_data,_ms,$type,tns)        [lindex $line 1]
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
      }
      if { [regexp {^NUM} $line] } {
        set rval(summary_data,_ms,$type,nvp)        [lindex $line 1]
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

      if { [regexp {^No setup violations found} $line] } {
        set type setup
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }
      if { [regexp {^No hold violations found} $line] } {
        set type hold
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

    }

  }

  ## -------------------------------------
  ## Parse the report for design information.
  ## -------------------------------------

  set rval(design_data,leaf_cell_count)     -1
  set rval(design_data,bufinv_cell_count)   -1
  set rval(design_data,ctbufinv_cell_count) -1

  set rval(design_data,comb_cell_count)     -1
  set rval(design_data,seq_cell_count)      -1
  set rval(design_data,macro_cell_count)    -1

  set rval(design_data,cell_area)           -1
  set rval(design_data,design_area)         -1
  set rval(design_data,net_length)          -1

  set rval(design_data,net_count)           -1
  set rval(design_data,ldrc_total)          -1
  set rval(design_data,ldrc_trans)          -1
  set rval(design_data,ldrc_cap)            -1

  ## -------------------------------------

  set rval(design_data,leaf_cell_count,line_number)     1
  set rval(design_data,bufinv_cell_count,line_number)   1
  set rval(design_data,ctbufinv_cell_count,line_number) 1

  set rval(design_data,comb_cell_count,line_number)     1
  set rval(design_data,seq_cell_count,line_number)      1
  set rval(design_data,macro_cell_count,line_number)    1

  set rval(design_data,cell_area,line_number)           1
  set rval(design_data,design_area,line_number)         1
  set rval(design_data,net_length,line_number)          1

  set rval(design_data,net_count,line_number)           1
  set rval(design_data,ldrc_total,line_number)          1
  set rval(design_data,ldrc_trans,line_number)          1
  set rval(design_data,ldrc_cap,line_number)            1

  ## -------------------------------------

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {Leaf Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,leaf_cell_count) $data
      set rval(design_data,leaf_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*Buf/Inv Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,bufinv_cell_count) $data
      set rval(design_data,bufinv_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*CT Buf/Inv Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,ctbufinv_cell_count) $data
      set rval(design_data,ctbufinv_cell_count,line_number) $line_number
    }

    if { [regexp {Combinational Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,comb_cell_count) $data
      set rval(design_data,comb_cell_count,line_number) $line_number
    }
    if { [regexp {Sequential Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,seq_cell_count) $data
      set rval(design_data,seq_cell_count,line_number) $line_number
    }
    if { [regexp {Macro Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,macro_cell_count) $data
      set rval(design_data,macro_cell_count,line_number) $line_number
    }

    if { [regexp {Cell Area:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,cell_area) $data
      set rval(design_data,cell_area,line_number) $line_number
    }
    if { [regexp {Design Area:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,design_area) $data
      set rval(design_data,design_area,line_number) $line_number
    }
    if { [regexp {Net Length\s+:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,net_length) $data
      set rval(design_data,net_length,line_number) $line_number
    }

    if { [regexp {Total Number of Nets:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,net_count) $data
      set rval(design_data,net_count,line_number) $line_number
    }
    if { [regexp {Nets With Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_total) $data
      set rval(design_data,ldrc_total,line_number) $line_number
    }
    if { [regexp {Max Trans Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_trans) $data
      set rval(design_data,ldrc_trans,line_number) $line_number
    }
    if { [regexp {Max Cap Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_cap) $data
      set rval(design_data,ldrc_cap,line_number) $line_number
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_qor \
  -info "Parses information for report_qor." \
  -define_args {\
    {-file "The report_qor file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_congestion:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_congestion { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(grc_overflow) undefined

  foreach line $lines {
    regexp {Both Dirs: Overflow.*\(([\d\.]+)%\)} $line match rval(grc_overflow)
  }

  if { $rval(grc_overflow) == "undefined" } {
    sproc_msg -error "Unable to parse value for 'Both Dirs: Overflow'"
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_congestion \
  -info "Parses information for report_congestion." \
  -define_args {\
    {-file "The report_congestion file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_threshold_voltage_group:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_threshold_voltage_group { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(vth,vth_names) [list]
  ## rval(cell_count,$vth_name)
  ## rval(cell_percentage,$vth_name)

  set flag_name 0
  set flag_astr 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Name} $line] } {
      incr flag_name
      continue
    }

    if { $flag_name == 1 } {
      if { [regexp {^[\*\-]} $line] } {
        incr flag_astr
        continue
      }
    }

    if { ($flag_name == 1) && ($flag_astr == 1) } {
      ## We are in the data section
      set parse 0

      if { [llength $line] == 1 } {
        set save_line $line
      }
      if { [llength $line] == 6 } {
        set line "$save_line $line"
        set parse 1
      }
      if { [llength $line] == 7 } {
        set parse 1
      }

      if { $parse } {
        regexp {^(\S+)\s+([\d\.]+)\s+\(([\d\.]+)\%\)} $line match vth_name cell_count cell_percentage
        lappend rval(vth,vth_names) $vth_name
        set rval(cell_count,$vth_name)                  $cell_count
        set rval(cell_percentage,$vth_name)             $cell_percentage
        set rval(cell_count,$vth_name,line_number)      $line_number
        set rval(cell_percentage,$vth_name,line_number) $line_number
      }

    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_threshold_voltage_group \
  -info "Parses information for report_threshold_voltage_group." \
  -define_args {\
    {-file "The report_threshold_voltage_group file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_design_physical:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_design_physical { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(cell2core_ratio)                -1
  set rval(chip_width)                     -1
  set rval(chip_height)                    -1
  set rval(chip_area)                      -1
  set rval(num_drc_errors)                 -1
  set rval(num_drc_errors_types)           -1

  ## -------------------------------------

  set rval(cell2core_ratio,line_number)      1
  set rval(chip_width,line_number)           1
  set rval(chip_height,line_number)          1
  set rval(chip_area,line_number)            1
  set rval(num_drc_errors,line_number)       1
  set rval(num_drc_errors_types,line_number) 1

  ## -------------------------------------

  set num_drc_errors_types -1
  set capture_error_types 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Cell/Core Ratio\s+:\s+([\d\.]+)\%} $line match value] } {
      set rval(cell2core_ratio)             $value
      set rval(cell2core_ratio,line_number) $line_number
    }

    if { [regexp {^Chip\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)} $line match value1 value2 value3] } {
      set rval(chip_width)              $value1
      set rval(chip_height)             $value2
      set rval(chip_area)               $value3
      set rval(chip_width,line_number)  $line_number
      set rval(chip_height,line_number) $line_number
      set rval(chip_area,line_number)   $line_number
    }

    if { [regexp {^DRC information:\s*$} $line] } {
      set num_drc_errors_types 0
      set capture_error_types 1
      continue
    }
    if { $capture_error_types } {
      if { [regexp {^\s+Total error number:\s+([\d\.]+)} $line match data] } {
        set rval(num_drc_errors)                   $data
        set rval(num_drc_errors_types)             $num_drc_errors_types
        set rval(num_drc_errors,line_number)       $line_number
        set rval(num_drc_errors_types,line_number) $line_number
        set capture_error_types 0
        continue
      } else {
        incr num_drc_errors_types
      }
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_design_physical \
  -info "Parses information for report_design_physical." \
  -define_args {\
    {-file "The report_design_physical file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_power:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_power { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(scenario_name_list) [list]

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  switch $synopsys_program_name {

    dc_shell -
    icc_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^Scenario\(s\):\s+(\S+)} $line match scenario_name

        if { [scan $line "Total %s %s %s %s %s %s %s %s" m1 m2 m3 m4 m5 m6 m7 m8] == 8 } {
          set rval($scenario_name,internal_power)        $m1
          set rval($scenario_name,internal_power_units)  $m2
          set rval($scenario_name,switching_power)       $m3
          set rval($scenario_name,switching_power_units) $m4
          set rval($scenario_name,leakage_power)         $m5
          set rval($scenario_name,leakage_power_units)   $m6
          set rval($scenario_name,total_power)           $m7
          set rval($scenario_name,total_power_units)     $m8

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  $line_number
          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) $line_number
          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   $line_number
          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     $line_number

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    icc2_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^Mode:\s+(\S+)} $line match mode_name
        regexp {^Corner:\s+(\S+)} $line match corner_name

        if { [scan $line "Total %s %s %s %s" m1 m2 m3 m4] == 4 } {
          set scenario_name "${mode_name}.${corner_name}"
          set rval($scenario_name,leakage_power)         $m1
          set rval($scenario_name,leakage_power_units)   $m2
          set rval($scenario_name,total_power)           $m3
          set rval($scenario_name,total_power_units)     $m4

          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   $line_number
          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     $line_number

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    pt_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^LYNX_SCENARIO:\s+(\S+)} $line match scenario_name

        if { [regexp {^\s*Net Switching Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,switching_power)                   $value
          set rval($scenario_name,switching_power_units)             W

          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) 1
        }
        if { [regexp {^\s*Cell Internal Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,internal_power)                    $value
          set rval($scenario_name,internal_power_units)              W

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  1
        }
        if { [regexp {^\s*Cell Leakage Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,leakage_power)                     $value
          set rval($scenario_name,leakage_power_units)               W

          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   1
        }
        if { [regexp {^\s*Total Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,total_power)                       $value
          set rval($scenario_name,total_power_units)                 W

          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     1

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_power \
  -info "Parses information for report_power." \
  -define_args {\
    {-file "The report_power file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_timing:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_timing { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(path_items) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  set line_number 0
  foreach line $lines {
    incr line_number

    regexp {^\s+Startpoint:\s+(\S+)} $line match start_point
    regexp {^\s+Endpoint:\s+(\S+)}   $line match end_point
    regexp {^\s+Scenario:\s+(\S+)}   $line match scenario_name
    regexp {^\s+Path Group:\s+(\S+)} $line match path_group
    regexp {^\s+Path Type:\s+(\S+)}  $line match path_type
    if { [regexp {^\s+slack\s+\(\S+\)\s+([\d\.\-]+)} $line match value] } {
      set slack $value
      set line $line_number
      set path_item "$scenario_name $start_point $end_point $path_group $path_type $slack $line"
      lappend rval(path_items) $path_item
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_timing \
  -info "Parses information for report_timing." \
  -define_args {\
    {-file     "The report_units file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_units:
## -----------------------------------------------------------------------------

proc sproc_qv_report_units { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set units [sproc_metric_parse_report_units -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process units
    ## -------------------------------------

    lappend output "\"Time_unit\": \"$units(text_time)\""
    lappend output "\"Capacitive_load_unit\": \"$units(text_capacitance)\""
    lappend output "\"Resistance_unit\": \"$units(text_resistance)\""
    lappend output "\"Voltage_unit\": \"$units(text_voltage)\""
    lappend output "\"Power_unit\": \"$units(text_power)\""
    lappend output "\"Current_unit\": \"$units(text_current)\""

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_units \
  -info "Proc that parses report_units reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_atpg:
## -----------------------------------------------------------------------------

proc sproc_metric_atpg { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  if { ( $SEV(metrics_enable_generation) == 0 ) } {
    sproc_msg -warning "Metrics are disabled per SEV(metrics_enable_generation)"
    sproc_pinfo -mode stop
    return
  }

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Set default values
  ## -------------------------------------

  set total_faults NaM
  set test_coverage NaM
  set fault_coverage 0
  set atpg_effectiveness 0

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fname $SEV(rpt_dir)/tmax_rm.report_summaries

  set fid [open $fname r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set fault_types "Iddq Transition Path_delay Bridging Dynamic_bridging Hold_time IDDQ_bridging"

  foreach fault_type $fault_types {
    set ${fault_type}_faults "NaM"
    set ${fault_type}_coverage "NaM"
  }

  foreach line $lines {
    foreach fault_type $fault_types {
      regexp "$fault_type\\s+\(\[\\.\\d\]+\)\\s+\(\[\\.\\d\]+\)\\%" $line matchVar ${fault_type}_faults ${fault_type}_coverage
      regexp {total faults\s+([\d]+)} $line matchVar total_faults
      regexp {test coverage\s+([\.\d]+)\%} $line matchVar fault_coverage
    }
  }

  ## -------------------------------------
  ## Generate metrics
  ## -------------------------------------

  sproc_msg -info "METRIC | INTEGER ATPG.TRANSITION.FAULTS         | $Transition_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.TRANSITION.COVERAGE       | $Transition_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.BRIDGING.FAULTS           | $Bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.BRIDGING.COVERAGE         | $Bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.HOLD_TIME.FAULTS          | $Hold_time_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.HOLD_TIME.COVERAGE        | $Hold_time_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.IDDQ_BRIDGING.FAULTS      | $IDDQ_bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.IDDQ_BRIDGING.COVERAGE    | $IDDQ_bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.IDDQ.FAULTS               | $Iddq_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.IDDQ.COVERAGE             | $Iddq_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.PATH_DELAY.FAULTS         | $Path_delay_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.PATH_DELAY.COVERAGE       | $Path_delay_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.DYNAMIC_BRIDGING.FAULTS   | $Dynamic_bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.DYNAMIC_BRIDGING.COVERAGE | $Dynamic_bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.STUCK_AT.FAULTS   | $total_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.STUCK_AT.COVERAGE | $fault_coverage"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_atpg \
  -info "Gathers ATPG information for metrics reporting." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_metric_main:
## -----------------------------------------------------------------------------

proc sproc_metric_main { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode
  global TEV SNPS_time_start

  set options(-scenario_name) ""
  set options(-metrics_sta) 0
  set options(-metrics_power) 0
  set options(-metrics_design) 0
  set options(-metrics_cts) 0
  set options(-report_qor) ""
  set options(-report_units) ""
  set options(-report_power) ""
  set options(-report_congestion) ""
  set options(-report_design_physical) ""
  set options(-report_threshold_voltage_group) ""
  set options(-report_clock_tree) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## If reporting is turned off, then metrics are disabled as well.
  ## -------------------------------------

  if { [regexp -nocase {NONE} $TEV(report_level)] || ($SEV(metrics_enable_generation) == 0) } {
    sproc_msg -warning "Metrics are disabled per TEV(report_level) or SEV(metrics_enable_generation)"
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Determine the file names for reports
  ## -------------------------------------

  if { $synopsys_program_name == "pt_shell" } {
    if { ($pt_shell_mode == "primetime") && ($options(-scenario_name) == "") } {
      sproc_msg -error "You must specify a scenario name using the -scenario_name argument."
    }
    switch $pt_shell_mode {
      primetime {
        if { $options(-report_qor) == "" } {
          set options(-report_qor) $SEV(rpt_dir)/pt.$options(-scenario_name).report_qor
        }
        if { $options(-report_units) == "" } {
          set options(-report_units) $SEV(rpt_dir)/pt.$options(-scenario_name).report_units
        }
        if { $options(-report_power) == "" } {
          set options(-report_power) $SEV(rpt_dir)/pt.$options(-scenario_name).report_power
        }
      }
      primetime_master {
        if { $options(-report_qor) == "" } {
          set options(-report_qor) $SEV(rpt_dir)/pt_concat.report_qor
        }
        if { $options(-report_units) == "" } {
          set options(-report_units) $SEV(rpt_dir)/pt_concat.report_units
        }
        if { $options(-report_power) == "" } {
          set options(-report_power) $SEV(rpt_dir)/pt_concat.report_power
        }
      }
    }
  } elseif { $synopsys_program_name == "icc_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/icc.report_qor
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/icc.report_units
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/icc.report_power
    }
    if { $options(-report_congestion) == "" } {
      set options(-report_congestion) $SEV(rpt_dir)/icc.report_congestion
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/icc.report_threshold_voltage_group
    }
    if { $options(-report_design_physical) == "" } {
      set options(-report_design_physical) $SEV(rpt_dir)/icc.report_design_physical
    }
    if { $options(-report_clock_tree) == "" } {
      set options(-report_clock_tree) $SEV(rpt_dir)/icc.cts.report_clock_tree
    }
  } elseif { $synopsys_program_name == "dc_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/dc.report_qor
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/dc.report_units
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/dc.report_power
    }
    if { $options(-report_congestion) == "" } {
      if {![shell_is_in_exploration_mode]} {
        set options(-report_congestion) $SEV(rpt_dir)/dc.report_congestion
      }
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/dc.report_threshold_voltage_group
    }
  } elseif { $synopsys_program_name == "icc2_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/icc2.report_qor
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/icc2.report_power
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/icc2.report_user_units
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/icc2.report_threshold_voltage_group
    }
  }

  ## -------------------------------------
  ## Determine the list of reports that are needed.
  ## -------------------------------------

  set report_type_list [list \
    -report_qor \
    -report_units \
    -report_power \
    -report_congestion \
    -report_design_physical \
    -report_threshold_voltage_group \
    -report_clock_tree \
    ]

  foreach report_type $report_type_list {
    set required($report_type) 0
  }

  if { $options(-metrics_sta) } {
    set required(-report_qor) 1
    set required(-report_units) 1
  }

  if { $options(-metrics_power) } {
    set required(-report_power) 1
  }

  if { $options(-metrics_design) } {
    set required(-report_qor) 1
    set required(-report_threshold_voltage_group) 1
    if { [file exists $options(-report_congestion)] } {
      set required(-report_congestion) 1
    }
    if { $synopsys_program_name == "icc_shell" } {
      set required(-report_design_physical) 1
    }
  }

  if { $options(-metrics_cts) } {
    set required(-report_clock_tree) 1
  }

  ## -------------------------------------
  ## Check that reports are available
  ## -------------------------------------

  set error 0
  foreach report_type $report_type_list {
    if { $required($report_type) } {
      if { ![file exists $options($report_type)] } {
        set error 1
        if { $SEV(metrics_flag_errors) } {
          sproc_msg -error   "The file specified by '$report_type' does not exist: '$options($report_type)'"
        } else {
          sproc_msg -warning "The file specified by '$report_type' does not exist: '$options($report_type)'"
        }
      }
    }
  }

  if { $error } {
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Parse the reports
  ## -------------------------------------

  foreach report_type $report_type_list {
    if { $required($report_type) } {
      switch -- $report_type {
        -report_qor                     { array set qor   [sproc_metric_parse_report_qor                     -file $options(-report_qor)] }
        -report_units                   { array set units [sproc_metric_parse_report_units                   -file $options(-report_units)] }
        -report_power                   { array set power [sproc_metric_parse_report_power                   -file $options(-report_power)] }
        -report_congestion              { array set cong  [sproc_metric_parse_report_congestion              -file $options(-report_congestion)] }
        -report_design_physical         { array set phy   [sproc_metric_parse_report_design_physical         -file $options(-report_design_physical)] }
        -report_threshold_voltage_group { array set vth   [sproc_metric_parse_report_threshold_voltage_group -file $options(-report_threshold_voltage_group)] }
        -report_clock_tree              { array set cts   [sproc_metric_parse_report_clock_tree              -file $options(-report_clock_tree)] }
      }
    }
  }

  ## -------------------------------------
  ## Generate outputs
  ## -------------------------------------

  if { $options(-metrics_sta) } {

    ## -------------------------------------
    ## This code is for generation of path group metrics (setup)
    ## -------------------------------------

    set ignore_list $SVAR(metrics,path_group_ignore_list_setup)

    set path_group_setup_item_list [list]

    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        set item [list \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack) \
          $path_group_name \
          $scenario_name \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_length) \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_period) \
          ]
        set valid 1
        if { ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)] || \
            ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_length)] || \
            ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_period)] \
          } {
          set valid 0
        }
        if { $valid } {
          lappend path_group_setup_item_list $item
        }
      }
    }

    set item_list [lsort -index 0 -increasing -real $path_group_setup_item_list]
    set item_list_length [llength $item_list]

    set index_count 0
    set metric_count 0

    while { $metric_count < $SVAR(metrics,max_path_group_count) } {

      if { $index_count < $item_list_length } {
        set item [lindex $item_list $index_count]
        set path_slack      [lindex $item 0]
        set path_group_name [lindex $item 1]
        set scenario_name   [lindex $item 2]
        set path_length     [lindex $item 3]
        set path_period     [lindex $item 4]

        set adj_path_slack [sproc_metric_normalize -value $path_slack -current_unit $units(time_unit)]

        if { [string is double -strict $path_length] && ($path_length != 0) } {
          set adj_path_length [sproc_metric_normalize -value $path_length -current_unit $units(time_unit)]
          set freq_actual [expr 1.0 / ( $adj_path_length / 1000000000000.0 )]
        } else {
          set freq_actual NaM
        }

        if { [string is double -strict $path_period] && ($path_period != 0) } {
          set adj_path_period [sproc_metric_normalize -value $path_period -current_unit $units(time_unit)]
          set freq_target [expr 1.0 / ( $adj_path_period / 1000000000000.0 )]
        } else {
          set freq_target NaM
        }

        set ignore_flag 0
        foreach pattern $ignore_list {
          if { [string match $pattern $path_group_name] } {
            set ignore_flag 1
          }
        }
        if { $ignore_flag } {
          incr index_count
          continue
        }
      } else {
        set path_slack      NaM
        set path_group_name NaM
        set scenario_name   NaM
        set freq_actual     NaM
        set freq_target     NaM
        set adj_path_slack  NaM
      }

      ## set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
      set path_group_name_displayed $path_group_name

      sproc_msg -info "METRIC | DOUBLE STA.SETUP_$metric_count.SLACK                  | $adj_path_slack"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.PATH_GROUP             | $path_group_name_displayed"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.SCENARIO               | $scenario_name"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.CALCULATED_FREQ_ACTUAL | $freq_actual"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.CALCULATED_FREQ_TARGET | $freq_target"
      incr index_count
      incr metric_count

    }

    ## -------------------------------------
    ## This code is for generation of path group metrics (hold)
    ## -------------------------------------

    set ignore_list $SVAR(metrics,path_group_ignore_list_hold)

    set path_group_hold_item_list [list]
    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        set item [list \
          $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack) \
          $path_group_name \
          $scenario_name \
          ]
        set valid 1
        if { ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)] } {
          set valid 0
        }
        if { $valid } {
          lappend path_group_hold_item_list $item
        }
      }
    }

    set item_list [lsort -index 0 -increasing -real $path_group_hold_item_list]
    set item_list_length [llength $item_list]

    set index_count 0
    set metric_count 0

    while { $metric_count < $SVAR(metrics,max_path_group_count) } {

      if { $index_count < $item_list_length } {
        set item [lindex $item_list $index_count]
        set path_slack      [lindex $item 0]
        set path_group_name [lindex $item 1]
        set scenario_name   [lindex $item 2]

        set adj_path_slack [sproc_metric_normalize -value $path_slack -current_unit $units(time_unit)]

        set ignore_flag 0
        foreach pattern $ignore_list {
          if { [string match $pattern $path_group_name] } {
            set ignore_flag 1
          }
        }
        if { $ignore_flag } {
          incr index_count
          continue
        }
      } else {
        set path_slack      NaM
        set path_group_name NaM
        set scenario_name   NaM
        set adj_path_slack  NaM
      }

      ## set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
      set path_group_name_displayed $path_group_name

      sproc_msg -info "METRIC | DOUBLE STA.HOLD_$metric_count.SLACK                  | $adj_path_slack"
      sproc_msg -info "METRIC | STRING STA.HOLD_$metric_count.PATH_GROUP             | $path_group_name_displayed"
      sproc_msg -info "METRIC | STRING STA.HOLD_$metric_count.SCENARIO               | $scenario_name"
      incr index_count
      incr metric_count

    }

    ## -------------------------------------
    ## This code is for generation of summary metrics
    ## -------------------------------------

    foreach scenario_name $qor(summary_data,_ss,scenario_name_list) {
      set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
      if { $qor(summary_data,_ss,$scenario_name,setup,path_slack) != "" } {
        set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,setup,path_slack) -current_unit $units(time_unit)]
        set tns         [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,setup,tns) -current_unit $units(time_unit)]
        set nvp                                        $qor(summary_data,_ss,$scenario_name,setup,nvp)
        sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.SCENARIO.$scenario_name_displayed  | $path_slack"
        sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.SCENARIO.$scenario_name_displayed  | $tns"
        sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.SCENARIO.$scenario_name_displayed | $nvp"
      }
      if { [info exists qor(summary_data,_ss,$scenario_name,hold,path_slack)] } {
        if { $qor(summary_data,_ss,$scenario_name,hold,path_slack) != "" } {
          set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,hold,path_slack) -current_unit $units(time_unit)]
          set tns         [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,hold,tns) -current_unit $units(time_unit)]
          set nvp                                        $qor(summary_data,_ss,$scenario_name,hold,nvp)
          sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.SCENARIO.$scenario_name_displayed  | $path_slack"
          sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.SCENARIO.$scenario_name_displayed  | $tns"
          sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.SCENARIO.$scenario_name_displayed | $nvp"
        }
      }
    }

    if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
      set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ms,setup,path_slack) -current_unit $units(time_unit)]
      set tns         [sproc_metric_normalize -value $qor(summary_data,_ms,setup,tns) -current_unit $units(time_unit)]
      set nvp                                        $qor(summary_data,_ms,setup,nvp)
      sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.COMPOSITE  | $path_slack"
      sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.COMPOSITE  | $tns"
      sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.COMPOSITE | $nvp"
    }
    if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
      set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ms,hold,path_slack) -current_unit $units(time_unit)]
      set tns         [sproc_metric_normalize -value $qor(summary_data,_ms,hold,tns) -current_unit $units(time_unit)]
      set nvp                                        $qor(summary_data,_ms,hold,nvp)
      sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.COMPOSITE  | $path_slack"
      sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.COMPOSITE  | $tns"
      sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.COMPOSITE | $nvp"
    }

    ## -------------------------------------
    ## This code is for generation of all path group metrics
    ## By default this code is disabled to prevent generation
    ## of an extemely large number of metrics for some designs.
    ## -------------------------------------

    if {1} {
      foreach scenario_name $qor(path_group_data,scenario_name_list) {
        foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {

          set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
          set scenario_name_displayed   [sproc_metric_clean_string -string $scenario_name]
          set metric_name $path_group_name_displayed.$scenario_name_displayed

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,logic_levels)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.LOGIC_LEVELS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,tns)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,tns)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,nvp)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,nvp)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.$metric_name | $value"
          }
        }
      }
    }

  }

  if { $options(-metrics_power) } {

    foreach scenario_name $power(scenario_name_list) {

      if { [string is double -strict $power($scenario_name,total_power)] } {
        set total_power   [sproc_metric_normalize -value $power($scenario_name,total_power)   -current_unit $power($scenario_name,total_power_units)]
      } else {
        set total_power   NaM
      }
      if { [string is double -strict $power($scenario_name,leakage_power)] } {
        set leakage_power [sproc_metric_normalize -value $power($scenario_name,leakage_power) -current_unit $power($scenario_name,leakage_power_units)]
      } else {
        set leakage_power NaM
      }

      if { $scenario_name == "None/non-MCMM" } {
        if { $synopsys_program_name == "pt_shell" } {
          if { $pt_shell_mode == "primetime" } {
            set scenario_name $options(-scenario_name)
          }
        }
      }
      set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]

      sproc_msg -info "METRIC | DOUBLE PWR.TOTAL.$scenario_name_displayed   | $total_power"
      sproc_msg -info "METRIC | DOUBLE PWR.LEAKAGE.$scenario_name_displayed | $leakage_power"

    }

  }

  if { $options(-metrics_design) } {

    ## From report_threshold_voltage_group

    foreach vth_name $vth(vth,vth_names) {
      sproc_msg -info "METRIC | INTEGER PWR.VTH_NUM_CELLS.$vth_name     | $vth(cell_count,$vth_name)"
      sproc_msg -info "METRIC | PERCENT PWR.VTH_PERCENT_CELLS.$vth_name | $vth(cell_percentage,$vth_name)"
    }

    ## From report_congestion

    if { [info exists cong(error_flag)] } {
      sproc_msg -info "METRIC | PERCENT PHYSICAL.CONGESTION | $cong(grc_overflow)"
    }

    ## From report_qor

    sproc_msg -info "METRIC | DOUBLE  LOGICAL.CELL_AREA     | $qor(design_data,cell_area)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_INSTS     | $qor(design_data,leaf_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_MACROS    | $qor(design_data,macro_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_FLIPFLOPS | $qor(design_data,seq_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_NETS      | $qor(design_data,net_count)"

    sproc_msg -info "METRIC | DOUBLE  PHYSICAL.WLENGTH      | $qor(design_data,net_length)"

    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.TOTAL | $qor(design_data,ldrc_total)"
    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.TRANS | $qor(design_data,ldrc_trans)"
    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.CAP   | $qor(design_data,ldrc_cap)"

    ## From report_design_physical

    if { $synopsys_program_name == "icc_shell" } {
      sproc_msg -info "METRIC | PERCENT PHYSICAL.UTIL         | $phy(cell2core_ratio)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.AREA         | $phy(chip_area)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.WIDTH        | $phy(chip_width)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.HEIGHT       | $phy(chip_height)"
      sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_ERRORS | $phy(num_drc_errors)"
      sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_TYPES  | $phy(num_drc_errors_types)"
      sproc_msg -info "METRIC | STRING  VERIFY.DRC.TOOL       | ICC"
    }

  }

  if { $options(-metrics_cts) } {
    if {1} {
      sproc_msg -warning "CTS metrics must be enabled via edit to procs_metrics.tcl file."
    } else {
      foreach name [array names cts *,skew] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set data $cts($name)
        set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
        sproc_msg -info "METRIC | DOUBLE CTS.SKEW.$metric_name | $value"
      }
      foreach name [array names cts *,path] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set data $cts($name)
        set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
        sproc_msg -info "METRIC | DOUBLE CTS.PATH.$metric_name | $value"
      }
      foreach name [array names cts *,sinks] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set value $cts($name)
        sproc_msg -info "METRIC | INTEGER CTS.SINKS.$metric_name | $value"
      }
      foreach name [array names cts *,drc] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set value $cts($name)
        sproc_msg -info "METRIC | INTEGER CTS.DRC.$metric_name | $value"
      }
    }
  }

  ## -------------------------------------
  ## This code creates the file used to support the QoR summary report.
  ## -------------------------------------

  ## -------------------------------------
  ## Define required attributes
  ## -------------------------------------

  set attributes [list]
  lappend attributes [list STEP   $SEV(step)]
  lappend attributes [list TASK   $SEV(task)]
  lappend attributes [list DST    $SEV(dst)]
  lappend attributes [list DESIGN $SVAR(design_name)]
  if { [info exists SEV(flow_order)] } {
    lappend attributes [list FLOW_ORDER $SEV(flow_order)]
  } else {
    lappend attributes [list FLOW_ORDER -1]
  }
  lappend attributes [list TYPE FLOW_SUMMARY]

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set fs_output [list]
  lappend fs_output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $attributes {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend fs_output "\"$name\": \"$value\""
    }
    lappend fs_output "\"flow_summary\": \["

    ## -------------------------------------
    ## All content below here is optional
    ## -------------------------------------

    ## -------------------------------------
    ## This code generates per-design summary information.
    ## -------------------------------------

    if { [info exists qor] } {
      set file $options(-report_qor)
      set file [join [lrange [split $file /] end-3 end] /]
    }

    if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup WNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,setup,path_slack) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,path_slack,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup TNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,setup,tns) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,tns,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup Violations" \
        -value $qor(summary_data,_ms,setup,nvp) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,nvp,line_number)]
    }
    if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold WNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,hold,path_slack) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,path_slack,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold TNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,hold,tns) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,tns,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold Violations" \
        -value $qor(summary_data,_ms,hold,nvp) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,nvp,line_number)]
    }

    if { [info exists qor(design_data,leaf_cell_count)] } {
      set value $qor(design_data,leaf_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Leaf Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,leaf_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,bufinv_cell_count)] } {
      set value $qor(design_data,bufinv_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Buf/Inv Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,bufinv_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,ctbufinv_cell_count)] } {
      set value $qor(design_data,ctbufinv_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "CT Buf/Inv Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,ctbufinv_cell_count,line_number)]
      }
    }

    if { [info exists qor(design_data,comb_cell_count)] } {
      set value $qor(design_data,comb_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Comb Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,comb_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,seq_cell_count)] } {
      set value $qor(design_data,seq_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Seq Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,seq_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,macro_cell_count)] } {
      set value $qor(design_data,macro_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Macro Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,macro_cell_count,line_number)]
      }
    }

    if { [info exists qor(design_data,cell_area)] } {
      set value $qor(design_data,cell_area)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Cell Area" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,cell_area,line_number)]
      }
    }
    if { [info exists qor(design_data,design_area)] } {
      set value $qor(design_data,design_area)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Design Area" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,design_area,line_number)]
      }
    }
    if { [info exists qor(design_data,net_length)] } {
      set value $qor(design_data,net_length)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Length" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,net_length,line_number)]
      }
    }

    if { [info exists qor(design_data,net_count)] } {
      set value $qor(design_data,net_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,net_count,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_total)] } {
      set value $qor(design_data,ldrc_total)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations Total" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_total,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_trans)] } {
      set value $qor(design_data,ldrc_trans)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations Trans" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_trans,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_cap)] } {
      set value $qor(design_data,ldrc_cap)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations MaxCap" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_cap,line_number)]
      }
    }

    if { [info exists phy] } {
      set file $options(-report_design_physical)
      set file [join [lrange [split $file /] end-3 end] /]
    }

    if { [info exists phy(cell2core_ratio)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Utilization" \
        -value $phy(cell2core_ratio) \
        -section 4 \
        -file $file \
        -line $phy(cell2core_ratio,line_number)]
    }
    if { [info exists phy(num_drc_errors)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "DRC Errors Total" \
        -value $phy(num_drc_errors) \
        -section 5 \
        -file $file \
        -line $phy(num_drc_errors,line_number)]
    }
    if { [info exists phy(num_drc_errors_types)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "DRC Errors Types" \
        -value $phy(num_drc_errors_types) \
        -section 5 \
        -file $file \
        -line $phy(num_drc_errors_types,line_number)]
    }

    if { [info exists vth] } {
      set file $options(-report_threshold_voltage_group)
      set file [join [lrange [split $file /] end-3 end] /]
      foreach vth_name $vth(vth,vth_names) {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Vth Percent ($vth_name)" \
          -value $vth(cell_percentage,$vth_name) \
          -section 3 \
          -file $file \
          -line $vth(cell_percentage,$vth_name,line_number)]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Vth Count   ($vth_name)" \
          -value $vth(cell_count,$vth_name) \
          -section 3 \
          -file $file \
          -line $vth(cell_count,$vth_name,line_number)]
      }
    }

    if { [info exists power] } {
      set file $options(-report_power)
      set file [join [lrange [split $file /] end-3 end] /]

      set total_power_max ""
      set total_power_units ""
      set total_power_line_number ""
      set leakage_power_max ""
      set leakage_power_units ""
      set leakage_power_line_number ""

      foreach scenario_name $power(scenario_name_list) {
        set total_power_units   $power($scenario_name,total_power_units)
        set leakage_power_units $power($scenario_name,leakage_power_units)

        if { [string is double -strict $power($scenario_name,total_power)] } {
          if { ($total_power_max == "") || ($power($scenario_name,total_power) > $total_power_max) } {
            set total_power_max         $power($scenario_name,total_power)
            set total_power_line_number $power($scenario_name,total_power,line_number)
          }
        }

        if { [string is double -strict $power($scenario_name,leakage_power)] } {
          if { ($leakage_power_max == "") || ($power($scenario_name,leakage_power) > $leakage_power_max) } {
            set leakage_power_max         $power($scenario_name,leakage_power)
            set leakage_power_line_number $power($scenario_name,leakage_power,line_number)
          }
        }
      }

      if { [string is double -strict $total_power_max] } {
        set total_power_max_adj [sproc_metric_normalize -value $total_power_max -current_unit $total_power_units]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Power Total (mW)" \
          -value $total_power_max_adj \
          -section 2 \
          -file $file \
          -line $total_power_line_number]
      }

      if { [string is double -strict $leakage_power_max] } {
        set leakage_power_max_adj [sproc_metric_normalize -value $leakage_power_max -current_unit $leakage_power_units]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Power Leakage (mW)" \
          -value $leakage_power_max_adj \
          -section 2 \
          -file $file \
          -line $leakage_power_line_number]
      }

    }

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

    lappend fs_output "\]"
  lappend fs_output "}"

  set fs_output [sproc_qv_add_commas -lines $fs_output]
  set fs_output [join $fs_output "\n"]

  set fid [open $SEV(rpt_dir)/.$SEV(block_name).$SEV(step).$SEV(task).$SEV(dst).design_summary-flow_summary.qor w]
  puts $fid $fs_output
  close $fid

  sproc_qv_gen_files

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_metric_main \
  -info "This is the main metrics procedure." \
  -define_args { \
    {-scenario_name                  "Specifies the scenario name"           AString string optional}
  {-metrics_sta                    "Generate 'sta' metrics"                "" boolean optional}
  {-metrics_power                  "Generate 'power' metrics"              "" boolean optional}
  {-metrics_design                 "Generate 'design' metrics"             "" boolean optional}
  {-metrics_cts                    "Generate 'cts' metrics"                "" boolean optional}
  {-report_qor                     "The file to parse."                    AString string optional}
  {-report_units                   "The file to parse."                    AString string optional}
  {-report_power                   "The file to parse."                    AString string optional}
  {-report_congestion              "The file to parse."                    AString string optional}
  {-report_design_physical         "The file to parse."                    AString string optional}
  {-report_threshold_voltage_group "The file to parse."                    AString string optional}
  {-report_clock_tree              "The file to parse."                    AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_tags:
## -----------------------------------------------------------------------------

proc sproc_metric_tags { args } {

  global env SEV SVAR TEV DEV

  sproc_pinfo -mode start

  ## -------------------------------------
  ## This section of code is for automatic generation of metrics.
  ## The metrics SYS.TAG_21 - SYS.TAG_30 are allocated for this purpose.
  ## -------------------------------------

  ## -------------------------------------
  ## SYS.TAG_21
  ##
  ## We are setting this metric to a value that always indicates the date of the next Sunday.
  ## This ensures data is tagged according to the week it is developed.
  ## (and the data is ready for reporting on Monday morning)
  ## -------------------------------------

  set seconds_per_day [expr 24 * 60 * 60]
  set today_in_seconds [clock seconds]
  set today_in_name [clock format $today_in_seconds -format "%A"]

  while { $today_in_name != "Sunday" } {
    set today_in_seconds [expr $today_in_seconds + $seconds_per_day]
    set today_in_name [clock format $today_in_seconds -format "%A"]
  }

  set metric_value [clock format $today_in_seconds -format "%Y_%m_%d"]
  sproc_msg -info "METRIC | TAG SYS.TAG_21 | $metric_value"

  ## -------------------------------------
  ## SYS.TAG_22
  ##
  ## We are setting this metric to indicate if the RTM is running the flow.
  ## -------------------------------------

  sproc_msg -info "METRIC | TAG SYS.TAG_22 | [info exists env(LYNX_RTM_PRESENT)]"

  ## -------------------------------------
  ## SYS.TAG_23 - SYS.TAG_30
  ##
  ## These are placeholders for more interesting content.
  ## -------------------------------------

  sproc_msg -info "METRIC | TAG SYS.TAG_23 | TagValue23"
  sproc_msg -info "METRIC | TAG SYS.TAG_24 | TagValue24"
  sproc_msg -info "METRIC | TAG SYS.TAG_25 | TagValue25"
  sproc_msg -info "METRIC | TAG SYS.TAG_26 | TagValue26"
  sproc_msg -info "METRIC | TAG SYS.TAG_27 | TagValue27"
  sproc_msg -info "METRIC | TAG SYS.TAG_28 | TagValue28"
  sproc_msg -info "METRIC | TAG SYS.TAG_29 | TagValue29"
  sproc_msg -info "METRIC | TAG SYS.TAG_30 | TagValue30"

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_metric_tags \
  -info "Generates automatic tag metrics." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_qv_flow_summary:
## -----------------------------------------------------------------------------

proc sproc_qv_flow_summary { args } {

  set options(-o) ""
  set options(-name) ""
  set options(-value) ""
  set options(-file) ""
  set options(-line) ""
  set options(-section) ""
  parse_proc_arguments -args $args options

  set output $options(-o)

  lappend output "{"

    lappend output "\"name\": \"$options(-name)\""
    lappend output "\"value\": \"$options(-value)\""

    if { $options(-file) != "" } {
      lappend output "\"file\": \"$options(-file)\""
    }
    if { $options(-line) != "" } {
      lappend output "\"line\": \"$options(-line)\""
    }
    if { $options(-section) != "" } {
      lappend output "\"section\": \"$options(-section)\""
    }

  lappend output "}"

  return $output

}

define_proc_attributes sproc_qv_flow_summary \
  -info "Proc that creates flow summary entries in JSON." \
  -define_args { \
    {-o          "Output"        AString string required}
  {-name       "Item name"     AString string required}
  {-value      "Item value"    AString string required}
  {-file       "Item file"     AString string optional}
  {-line       "Item line"     AnInt int optional}
  {-section    "Item section"  AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_add_commas:
## -----------------------------------------------------------------------------

proc sproc_qv_add_commas { args } {

  set options(-lines) ""
  parse_proc_arguments -args $args options

  set results [list]

  set index 0
  set index_max [llength $options(-lines)]

  while { $index < $index_max } {
    set this_line [lindex $options(-lines) $index]
    set next_line [lindex $options(-lines) [expr $index + 1]]
    if { [regexp {[\},\]]$} $this_line] && [regexp {[\[\{]$} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {\"$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {[0-9]$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {(true|false)$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    lappend results $this_line
    incr index
  }

  return $results
}

define_proc_attributes sproc_qv_add_commas \
  -info "Proc that add commas for JSON output." \
  -define_args {
  {-lines       "The lines that need commas." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_qv_gen_files:
## -----------------------------------------------------------------------------

proc sproc_qv_gen_files { args } {

  sproc_pinfo -mode start

  global SEV SVAR

  ## -------------------------------------
  ## Useful truncations
  ## -------------------------------------

  set block $SEV(block_name)

  set rpt_root [file normalize $SEV(block_dir)/../$block/$SEV(step)/rpts/$SEV(dst)]

  foreach c_rpt [glob -nocomplain -type f $rpt_root/*] {

    ## -------------------------------------
    ## Define required attributes
    ## -------------------------------------

    set attributes [list]
    lappend attributes [list STEP   $SEV(step)]
    lappend attributes [list TASK   $SEV(task)]
    lappend attributes [list DST    $SEV(dst)]
    lappend attributes [list DESIGN $SVAR(design_name)]
    if { [info exists SEV(flow_order)] } {
      lappend attributes [list FLOW_ORDER $SEV(flow_order)]
    } else {
      lappend attributes [list FLOW_ORDER -1]
    }

    ## -------------------------------------
    ## Set FILE attribute to a relative path
    ## -------------------------------------

    set rel_rpt $SEV(step)/rpts/$SEV(dst)/[file tail $c_rpt]

    ## -------------------------------------
    ## Match the report to the parser
    ## -------------------------------------

    switch -glob [file tail $c_rpt] {

      dc.report_qor -
      icc.report_qor -
      pt.*.report_qor -
      pt_concat.report_qor {

        if { [regexp {.*/pt\.(\S+)\.report_qor} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        set o_file $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).qor.qor
        lappend attributes [list TYPE QOR]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_qor -file $c_rpt -output $o_file -attributes $attributes
      }

      dc.report_power -
      icc.report_power -
      pt.*.report_power -
      pt_concat.report_power {

        if { [regexp {.*/pt\.(\S+)\.report_power} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        set o_file $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).power.qor
        lappend attributes [list TYPE POWER]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_power -file $c_rpt -output $o_file -attributes $attributes -scenario $scenario
      }

      dc.report_timing -
      icc.report_timing.min -
      icc.report_timing.max -
      pt.*.report_timing.* -
      pt_concat.report_timing.* -
      *.max.tim -
      *.min.tim -
      *.mapped.timing.rpt {

        if { [regexp {.*/pt\.(\S+)\.report_timing\.m??} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        if { [string match */*.report_timing.min $c_rpt] || [string match */*.min.tim $c_rpt] } {
          set C_TYPE MIN
          set c_type min
        } else {
          set C_TYPE MAX
          set c_type max
        }

        set o_file $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).timing_${c_type}.qor
        lappend attributes [list TYPE TIMING_$C_TYPE]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_timing -file $c_rpt -output $o_file -attributes $attributes -scenario $scenario
      }

      dc.report_units -
      icc.report_units {

        set o_file $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).units.qor
        lappend attributes [list TYPE UNITS]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_units -file $c_rpt -output $o_file -attributes $attributes
      }

      icc.cts.report_clock_tree {
        set o_file_matrix $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).clock_tree_matrix-matrix.qor
        set o_file_table $SEV(rpt_dir)/.${block}.$SEV(step).$SEV(task).$SEV(dst).clock_tree_summary-table.qor
        lappend attributes [list TYPE UD_MATRIX]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_clock_tree -file $c_rpt -matrix_output $o_file_matrix -table_output $o_file_table -attributes $attributes
      }

    }

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_gen_files \
  -info "Proc that generates QoR Viewer files." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_qv_report_timing:
## -----------------------------------------------------------------------------

proc sproc_qv_report_timing { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set tim [sproc_metric_parse_report_timing -file $options(-file) -scenario $options(-scenario)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process timing
    ## -------------------------------------

    lappend output "\"timing\": \["

    foreach path_item $tim(path_items) {

      set scenario_name [lindex $path_item 0]
      set start_point   [lindex $path_item 1]
      set end_point     [lindex $path_item 2]
      set path_group    [lindex $path_item 3]
      set path_type     [lindex $path_item 4]
      set slack         [lindex $path_item 5]
      set line          [lindex $path_item 6]

      lappend output "{"
        lappend output "\"Scenario\": \"$scenario_name\""
        lappend output "\"Path Group\": \"$path_group\""
        lappend output "\"Path Type\": \"$path_type\""
        lappend output "\"Startpoint\": \"$start_point\""
        lappend output "\"Endpoint\": \"$end_point\""
        lappend output "\"Slack\": \"$slack\""
        lappend output "\"line\": \"$line\""
      lappend output "}"

    }

    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_timing \
  -info "Proc that parses report_timing reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
  {-scenario    "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_qor:
## -----------------------------------------------------------------------------

proc sproc_qv_report_qor { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set qor [sproc_metric_parse_report_qor -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process timing entry
    ## -------------------------------------

    lappend output "\"timing\": \["

    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        lappend output "{"
          lappend output "\"Scenario\": \"$scenario_name\""
          lappend output "\"Timing Path Group\": \"$path_group_name\""
          lappend output "\"line\": \"$qor(path_group_data,$scenario_name,$path_group_name,line_number)\""
          lappend output "\"Levels of Logic\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,logic_levels)\""
          lappend output "\"Critical Path Length\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_length)\""
          lappend output "\"Critical Path Slack\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)\""
          lappend output "\"Critical Path Clk Period\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_period)\""
          lappend output "\"Total Negative Slack\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,tns)\""
          lappend output "\"No. of Violating Paths\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,nvp)\""
          lappend output "\"Worst Hold Violation\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)\""
          lappend output "\"Total Hold Violation\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,tns)\""
          lappend output "\"No. of Hold Violations\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,nvp)\""
        lappend output "}"
      }
    }
    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_qor \
  -info "Proc that parses report_qor reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_power:
## -----------------------------------------------------------------------------

proc sproc_qv_report_power { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set power [sproc_metric_parse_report_power -file $options(-file) -scenario $options(-scenario)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process power
    ## -------------------------------------

    lappend output "\"power\": \["

    foreach scenario_name $power(scenario_name_list) {
      lappend output "{"
        lappend output "\"Scenario\": \"$scenario_name\""
        lappend output "\"line\": \"$power($scenario_name,total_power,line_number)\""
        lappend output "\"total\": {"

          if { $power($scenario_name,internal_power) != "N/A" } {
            lappend output "\"Internal\": \"$power($scenario_name,internal_power)$power($scenario_name,internal_power_units)\""
          } else {
            lappend output "\"Internal\": \"\""
          }
          if { $power($scenario_name,switching_power) != "N/A" } {
            lappend output "\"Switching\": \"$power($scenario_name,switching_power)$power($scenario_name,switching_power_units)\""
          } else {
            lappend output "\"Switching\": \"\""
          }
          if { $power($scenario_name,leakage_power) != "N/A" } {
            lappend output "\"Leakage\": \"$power($scenario_name,leakage_power)$power($scenario_name,leakage_power_units)\""
          } else {
            lappend output "\"Leakage\": \"\""
          }
          if { $power($scenario_name,total_power) != "N/A" } {
            lappend output "\"Total\": \"$power($scenario_name,total_power)$power($scenario_name,total_power_units)\""
          } else {
            lappend output "\"Total\": \"\""
          }

        lappend output "}"
      lappend output "}"
    }

    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_power \
  -info "Proc that parses report_power reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
  {-scenario    "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_clock_tree:
## -----------------------------------------------------------------------------

proc sproc_qv_report_clock_tree { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-matrix_output) ""
  set options(-table_output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set cts [sproc_metric_parse_report_clock_tree -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set matrix_output [list]
  set table_output [list]
  lappend matrix_output "\{"
  lappend table_output "\{"

  ## -------------------------------------
  ## Process attributes
  ## -------------------------------------

  foreach attribute $options(-attributes) {
    set name  [lindex $attribute 0]
    set value [lindex $attribute 1]
    lappend matrix_output "\"$name\": \"$value\""
    if {$name == "TYPE"} {
      set value UD_TABLE
      lappend table_output "\"$name\": \"$value\""
    } else {
      lappend table_output "\"$name\": \"$value\""
    }
  }

  ## -------------------------------------
  ## Create CTS Matrix
  ## -------------------------------------

  lappend matrix_output "\"data\": \["
  lappend table_output "\"data\": \["
  set file [lindex [lindex $options(-attributes) end] end]

  foreach scenario_name $cts(scenario_name_list) {
    foreach clk_name $cts($scenario_name,clk_name_list) {
      lappend matrix_output "\{"
      lappend matrix_output "\"Scenario\": \"$scenario_name\""
      lappend matrix_output "\"Clock\": \"$clk_name\""
      foreach name $cts(name_list) {
        lappend matrix_output "\"$name\" \: \{"
        lappend matrix_output "\"value\" \: \"$cts($scenario_name,$clk_name,$name,value)\""
        lappend matrix_output "\"file\" \: \"$file\""
        lappend matrix_output "\"line\" \: \"$cts($scenario_name,$clk_name,$name,line_number)\""
        lappend matrix_output "\}"
      }
      lappend matrix_output "\}"
    }
  }
  lappend matrix_output "\]"

  ## Specification section

  lappend matrix_output "\"specification\" \: \{"
  lappend matrix_output "\"Rows\" \: \["
  lappend matrix_output "\"Clock\""
  lappend matrix_output "\]"
  lappend matrix_output "\"Columns\" \: \["
  lappend matrix_output "\"Scenario\""
  lappend matrix_output "\]"
  lappend matrix_output "\"Values\" \: \["
  lappend matrix_output "\"Max Global Skew\""
  lappend matrix_output "\"Longest path delay\""
  lappend matrix_output "\"Shortest path delay\""
  lappend matrix_output "\]"
  lappend matrix_output "\}"

  ## -------------------------------------
  ## Create CTS Table
  ## -------------------------------------

  foreach clk_name $cts(clk_name_list) {
    foreach scenario_name $cts(scenario_name_list) {
      if { [lsearch $cts($scenario_name,clk_name_list) $clk_name] >= 0 } {
        foreach name $cts(name_list) {
          lappend table_output "\{"
          lappend table_output "\"Clock\": \"${clk_name}\""
          lappend table_output "\"Scenario\": \"${scenario_name}\""
          lappend table_output "\"Metric\" \: \"$name\""
          lappend table_output "\"value\" \: \"$cts($scenario_name,$clk_name,$name,value)\""
          lappend table_output "\"line\" \: \"$cts($scenario_name,$clk_name,$name,line_number)\""
          lappend table_output "\"file\" \: \"$file\""
          lappend table_output "\}"
        }
      }

    }
  }
  lappend table_output "\]"

  ## Specification section

  lappend table_output "\"specification\" \: \{"

  lappend table_output "\"Rows\" \: \["
  lappend table_output "\"Clock\""
  lappend table_output "\"Scenario\""
  lappend table_output "\]"

  lappend table_output "\"Columns\" \: \["
  lappend table_output "\"Metric\""
  lappend table_output "\]"
  lappend table_output "\"Values\" \: \["
  lappend table_output "\"value\""
  lappend table_output "\]"
  lappend table_output "\"Properties\" \: \{"
  lappend table_output "\"model\" \: \{"
  lappend table_output "\"metric_on_columns\" \: true"
  lappend table_output "\"metric_index\" \: 0"
  lappend table_output "\}"
  lappend table_output "\}"
  lappend table_output "\}"

  ## -------------------------------------
  ## Complete output & create file
  ## -------------------------------------

  lappend matrix_output "\}"
  lappend table_output "\}"

  set matrix_output [sproc_qv_add_commas -lines $matrix_output]
  set matrix_output [join $matrix_output "\n"]

  set table_output [sproc_qv_add_commas -lines $table_output]
  set table_output [join $table_output "\n"]

  set fid [open $options(-matrix_output) w]
  puts $fid $matrix_output
  close $fid

  set fid2 [open $options(-table_output) w]
  puts $fid2 $table_output
  close $fid2

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_clock_tree \
  -info "Proc that parses report_qor reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-matrix_output      "Output file." AString string required}
  {-table_output      "II type Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_clock_tree:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_clock_tree { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(scenario_name_list) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report (for Clock Tree Summary info)
  ## This information used for METRICS
  ## -------------------------------------

  set in_section 0

  set index 0
  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Clock Tree Summary =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {
      if { [regexp {Clock\s+Sinks\s+CTBuffers\s+ClkCells\s+Skew\s+LongestPath\s+TotalDRC\s+BufferArea} $line] } {
        ## This is header line
        continue
      } elseif { [regexp {^----} $line] } {
        ## This is seperator line
        continue
      } elseif { [scan $line {%s %s %s %s %s %s %s %s} clock_name sinks buffers cells skew path drc area] == 8 } {
        ## This is data line
        set rval($scenario_name,$clock_name,sinks) $sinks
        set rval($scenario_name,$clock_name,skew)  $skew
        set rval($scenario_name,$clock_name,path)  $path
        set rval($scenario_name,$clock_name,drc)   $drc
        set rval($scenario_name,$clock_name,sinks,line_number) $line_number
        set rval($scenario_name,$clock_name,skew,line_number)  $line_number
        set rval($scenario_name,$clock_name,path,line_number)  $line_number
        set rval($scenario_name,$clock_name,drc,line_number)   $line_number
        continue
      } else {
        ## No longer in summary
        set in_section 0
        continue
      }
    }

  }

  ## -------------------------------------
  ## Parse the report (for Global Skew Report info)
  ## This information used for QOR JSON files
  ## -------------------------------------

  set rval(name_list) [list \
    "Clock Period" \
    "Number of Levels" \
    "Number of Sinks" \
    "Number of CT Buffers" \
    "Number of CTS added gates" \
    "Number of Preexisting Gates" \
    "Number of Preexisting Buf/Inv" \
    "Total Number of Clock Cells" \
    "Total Area of CT Buffers" \
    "Total Area of CT cells" \
    "Max Global Skew" \
    "Number of MaxTran Violators" \
    "Number of MaxCap Violators" \
    "Number of MaxFanout Violators" \
    "Clock global Skew" \
    "Longest path delay" \
    "Shortest path delay" \
    ]

  set in_section 0

  set index 0
  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Global Skew Report =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {

      if { [regexp "^Clock Tree Name" $line] } {
        set clk_name [lindex [split [string trim $line]] end]
        set clk_name [regsub -all {\"} $clk_name {}]
        puts "$scenario_name : $clk_name"
        lappend rval(clk_name_list) $clk_name
        lappend rval($scenario_name,clk_name_list) $clk_name
        foreach name $rval(name_list) {
          set rval($scenario_name,$clk_name,$name,value) unknown
          set rval($scenario_name,$clk_name,$name,line_number) 0
        }
        continue
      }

      foreach name $rval(name_list) {
        if { [regexp "^$name\s*\:*\s*" $line] } {
          set value [lindex [split [string trim $line]] end]
          set rval($scenario_name,$clk_name,$name,value) $value
          set rval($scenario_name,$clk_name,$name,line_number) $line_number

          ## set value_line [list $value $line_number]
          ## lappend rval($clk_name,$name,value_line_list) $value_line

          continue
        }
      }

      if { [regexp {^Report} $line] } {
        set in_section 0
        continue
      }

    }

  }

  ## Clean up

  set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]
  set rval(clk_name_list)      [lsort -unique $rval(clk_name_list)]

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_clock_tree \
  -info "Parses information for report_clock_tree." \
  -define_args {\
    {-file "The report_clock_tree file to parse." AString string required}
}


sproc_msg -info "METRIC | INTEGER INFO.LCRM_RTM_MODE          | $LYNX(rtm_present)"

## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------


