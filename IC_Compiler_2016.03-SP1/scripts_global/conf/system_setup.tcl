## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/system_setup.tcl#229 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file is used to provide basic services for the Lynx system.
## * Please see the comments contained within this file for more detailed information.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## env(LYNX_RTM_PRESENT):
##   This variable is set by the RTM.
##   If set, the RTM is being used.
##   If not set, the RTM is not being used.
##   This variable is resolved to LYNX(rtm_present).
## -----------------------------------------------------------------------------

if { [info exists env(LYNX_RTM_PRESENT)] } {
  set LYNX(rtm_present) 1
} else {
  set LYNX(rtm_present) 0
}

if { [info exists env(LYNX_LCRM_MODE)] } {
  set LYNX(lcrm_mode) 1
} else {
  set LYNX(lcrm_mode) 0
}

if { [info exists env(LYNX_REGRESSION_TESTING)] } {
  set LYNX(regression_testing) 1
} else {
  set LYNX(regression_testing) 0
}

if { [info exists env(LYNX_GALAXY_BETA)] } {
  set LYNX(galaxy_beta) 1
} else {
  set LYNX(galaxy_beta) 0
}

if { [info exists env(LYNX_DEMO)] } {
  set LYNX(demo) 1
} else {
  set LYNX(demo) 0
}

## -----------------------------------------------------------------------------
## Variable resolution
## -----------------------------------------------------------------------------

## -------------------------------------
## These variables:
## - Must be defined in system.tcl
## - Can be overridden in LYNX_VARFILE_SEV
## -------------------------------------

set varlist1 [list \
  project_dir \
  project_name \
  release_dir \
  techlib_dir \
  techlib_name \
  metrics_enable_generation \
  metrics_enable_transfer \
  metrics_server \
  metrics_port \
  ]

## -------------------------------------
## These variables:
## - Are only defined in LYNX_VARFILE_SEV
## - When RTM is used, this must be set in the env for the tool_wrapper:
##   - LYNX_SCRIPT_FILE
## -------------------------------------

set varlist2 [list \
  step \
  task \
  script_file \
  src \
  dst \
  log_file \
  ]

## -------------------------------------
## These variables:
## - Are assigned default values in this file.
## - Are overridden in LYNX_VARFILE_SEV if needed.
## - When RTM is used, these must also be set in the env for the tool_wrapper:
##   - SEV_DONT_RUN
##   - SEV_DONT_EXIT
## -------------------------------------

set varlist3 [list \
  gui \
  skip \
  bit \
  analysis_task \
  dont_run \
  dont_exit \
  trace \
  job_queue \
  ]

foreach var $varlist3 {
  if { ![info exists SEV($var)] } {
    switch $var {
      bit {
        set SEV($var) 64
      }
      job_queue {
        if { $SEV(dont_run) || $SEV(dont_exit) } {
          set SEV(job_queue) $SEV(job_queue_interactive)
        } else {
          set SEV(job_queue) $SEV(job_queue_batch)
        }
      }
      default {
        set SEV($var) 0
      }
    }
  }
}

## -------------------------------------
## These variables:
## - Are assigned default values in this file.
## -------------------------------------

set varlist4 [list \
  tmp_dir \
  workarea_dir \
  block_dir \
  block_name \
  step_dir \
  gscript_dir \
  tscript_dir \
  bscript_dir \
  work_dir \
  src_dir \
  dst_dir \
  log_dir \
  rpt_dir \
  ]

if { [info exists SEV(pt_dmsa_slave)] } {
  ## PT Slaves have SEVs already set
} else {
  ## Normal location.
  set SEV(tmp_dir) [pwd]

  set pwdlist [split $SEV(tmp_dir) /]

  if { $LYNX(rtm_present) } {
    if { $LYNX(lcrm_mode) } {
      set SEV(workarea_dir) [join [lrange $pwdlist 0 end-3] /]
    } else {
      set SEV(workarea_dir) [join [lrange $pwdlist 0 end-5] /]
    }
  } else {
    set SEV(workarea_dir) [join [lrange $pwdlist 0 end-3] /]
  }

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
  set SEV(log_file)       [file normalize $SEV(tmp_dir)/$SEV(log_file)]

}

## -------------------------------------
## Check to make sure the above variables are present.
## -------------------------------------

set varlist_all [concat $varlist1 $varlist2 $varlist3 $varlist4]

foreach var $varlist_all {
  if { ![info exists SEV($var)] } {
    sproc_msg -error "SEV variable undefined: SEV($var)"
  } else {
    ## The following line can be uncommented if additional log file content is desired.
    sproc_msg -info "SEV variable defined: SEV($var) : $SEV($var)"
  }
}

## -----------------------------------------------------------------------------
## Source the rtm_init.tcl file so those procedures are available to the flow.
## -----------------------------------------------------------------------------

source $SEV(gscript_dir)/conf/rtm_init.tcl

## -------------------------------------
## Resolve the SEV(cmd_*) variables,
## now that the procedure is available.
## -------------------------------------

rtm_tool_cmd

## -----------------------------------------------------------------------------
## Misc startup processing
## -----------------------------------------------------------------------------

## -------------------------------------
## Check for correct run directory.
## -------------------------------------

if { [info exists SEV(pt_dmsa_slave)] } {
  ## Skip this check.
} else {
  if { [file tail [pwd]] != "tmp" } {
    sproc_msg -error "You must run tools from the 'tmp' directory."
    sproc_script_stop -exit
  }
}

## -------------------------------------
## For standalone script operation,
## create directories for generated data.
## -------------------------------------

if { !$LYNX(rtm_present) } {

  set dir_list [list $SEV(dst_dir) $SEV(log_dir) $SEV(rpt_dir)]

  foreach dir $dir_list {
    if { [file exists $dir] && [file isdirectory $dir] } {
      sproc_msg -info "Directory does exist: $dir"
    } else {
      sproc_msg -info "Directory does not exist. Creating directory: $dir"
      file mkdir $dir
    }
  }

}

## -------------------------------------
## Check for .synopsys files.
## -------------------------------------

if { ![info exists env(HOME)] } {

  sproc_msg -error "The environment variable 'HOME' does not exist."
  sproc_msg -error "No way to determine home directories."

} else {

  set setup_files [glob -nocomplain "$env(HOME)/.synopsys_*.setup"]

  set generate_error 1
  if { [info exists env(SNPS_setup_file_error_message_disable)] } {
    if { $env(SNPS_setup_file_error_message_disable) == "1" } {
      set generate_error 0
    }
  }

  if { [llength $setup_files] > 0 } {
    if { $generate_error } {
      sproc_msg -error   "Detected .synopsys setup file(s) in home directory."
    } else {
      sproc_msg -warning "Detected .synopsys setup file(s) in home directory."
    }
    foreach setup_file $setup_files {
      sproc_msg -info "  $setup_file"
    }
  }

}

## -------------------------------------
## File system cache workaround.
## -------------------------------------

foreach dir [glob $SEV(work_dir)/*] {
  if { [file isdirectory $dir] } {
    sproc_refresh_file_system -dir $dir
  }
}

## -------------------------------------
## Command log setup
## -------------------------------------

if { ($synopsys_program_name == "dc_shell") || \
    ( $synopsys_program_name == "icc_shell" ) || \
    ( $synopsys_program_name == "pt_shell" ) || \
    ( $synopsys_program_name == "gca_shell" ) || \
    ( $synopsys_program_name == "fm_shell" ) \
  } {
  set command_log [file rootname $SEV(log_file)].cmd
  sproc_msg -info "Command log is: $command_log"
  if { [info exists env(SNPS_ENABLE_TESTCASE)] && ($synopsys_program_name == "dc_shell") } {
    sproc_msg -error "Environment variable SNPS_ENABLE_TESTCASE enabled. Log file is being managed by DC testcase packing utility."
  } else {
    set_app_var sh_command_log_file $command_log
  }
}

## -------------------------------------
## Trace log setup
## -------------------------------------

if { [string is integer $SEV(trace)] && ($SEV(trace) >= 0) && ($SEV(trace) <= 2) } {
  if { $SEV(trace) == 0 } {
    sproc_msg -info "Tracelog is not enabled"
  } else {
    set tracelog_supported 0
    if { $synopsys_program_name == "dc_shell" } { set tracelog_supported 1 }
    if { $synopsys_program_name == "icc_shell" } { set tracelog_supported 1 }
    if { $synopsys_program_name == "pt_shell"  } { set tracelog_supported 1 }
    if { $synopsys_program_name == "fm_shell"  } { set tracelog_supported 1 }
    if { $synopsys_program_name == "mvrc"      } { set tracelog_supported 1 }
    if { $tracelog_supported } {
      sproc_msg -info "Tracelog is enabled"
      sproc_source -file $SEV(gscript_dir)/conf/tracelog.tcl
      if { $SEV(trace) == 2 } {
        tracelog::set_options -echo_cmds_with_performance on
        tracelog::set_options -performance_echo_cpu_threshold 1
      }
      tracelog::start -file $SEV(log_file).trace
    } else {
      sproc_msg -warning "Tracelog is not supported for $synopsys_program_name"
    }
  }
} else {
  sproc_msg -error "SEV(trace) is set to $SEV(trace)"
  sproc_msg -error "Allowable values are 0, 1, and 2."
}

## -------------------------------------
## Shell control variables
## -------------------------------------

set sh_continue_on_error true

## -------------------------------------
## DC Cache Control
## -------------------------------------

if { $synopsys_program_name == "dc_shell" } {

  set libdir [file tail $SEV(techlib_dir)]

  set_app_var cache_read                 $SEV(project_dir)/cache/$libdir
  set_app_var cache_write                $SEV(project_dir)/cache/$libdir
  set_app_var alib_library_analysis_path $SEV(project_dir)/cache/$libdir

}

## -------------------------------------
## Netlisting/Naming variables
## -------------------------------------

if { ($synopsys_program_name == "dc_shell") || \
    ($synopsys_program_name == "icc_shell") \
  } {

  ## -------------------------------------
  ## Netlisting variables
  ## -------------------------------------

  set_app_var verilogout_no_tri true
  set_app_var verilogout_higher_designs_first true
  set_app_var verilogout_show_unconnected_pins true

  if { ($synopsys_program_name == "icc_shell") } {
    ## Setting for DC seems to cause effects on ddc (STAR TBD)
    set_app_var mv_output_enforce_simple_names true
  }

  ## minor beautification of upf written by DC
  set_app_var mv_output_upf_line_width 200
  set_app_var mv_output_upf_line_indent 4

  ## -------------------------------------
  ## Naming variables
  ## -------------------------------------

  set_app_var write_name_nets_same_as_ports true
  set_app_var bus_naming_style {%s[%d]}

}

## -------------------------------------
## Misc timing variables
## -------------------------------------

if { ($synopsys_program_name == "dc_shell") || \
    ($synopsys_program_name == "icc_shell") \
  } {

  ## alignment with PT defaults. Tool defaults changing in future release
  set_app_var timing_enable_multiple_clocks_per_reg true
  set_app_var timing_gclock_source_network_num_master_registers "10000000"
  set_app_var rc_driver_model_mode "advanced"
  set_app_var rc_receiver_model_mode "advanced"

}

## -------------------------------------
## To enable verbose messaging for monitoring and debug, uncomment the following line.
## -------------------------------------

if { $synopsys_program_name == "icc_shell" } {

  ## set_app_var monitor_cpu_memory true

}

## -----------------------------------------------------------------------------
## DEVELOPMENT VARIABLES
## These control workarounds typically enabled at various points in the flow.
## -----------------------------------------------------------------------------

## Hidden variable to enable new scandef hierarchical infrastructure for
## DC write_scan_def. Added during 2014.09-SP2 early builds for testing
##
##     0  revert to default tool behavior
##     1  enable new feature

set DEV(ascii_scandef_enable_expand) 1

## This controls what type of logic interace is configured when using
## block abstracts. This string is the argument on set_top_implementation
## -load_logic <ARG>. It has two valid settings:
##
##     full_interface    fanout paths to first register for each in/out port
##     compact_interface just best/worst paths for each in/out port

set DEV(abstract_style) full_interface

## This controls use of placement blockages in the SPG flow to represent
## MV HEADER cells. This can improve alignement with ICC and other accuracies
## when dealing with congested designs.
##
##     0    HEADER cells not accounted for in SPG DEF
##     1    HEADER cells represented as placement blockages in DEF

set DEV(dcg_header_blockage) 1

## -------------------------------------
## Working around STAR 9000837358.
## - Optimization prior to commit creates failing scan chain.
## -------------------------------------
##
##     0  default flow
##     1  enable scan def workaround flow

set DEV(scan_def_sm_workaround) 0

## New 2014.09 feature being tested. This allows saving top level only without
## the overhead of removing designs prior to save.
## 9/22/2014 - experiencing some syn_output differences that may be related. Turn off.
##
##     0  old remove design technique
##     1  new upf_block_partition

set DEV(201409_hier_upf_save) 1

## DC congestion reports were randomly creating extremely large report files
## and hanging. Disabling congestion reports by default until issue debugged.

set DEV(disable_dc_congestion_reports) 1

## Enables a check_scan_def in the dc_dft step. This can show false negatives.
##
##     0  no scan_def check performed
##     1  scan_def in dc_dft with errors flagged

set DEV(dft_scan_def_check) 0

## Filters UPF prime for hierarchical UPF as per STAR 90007999999
##
##     0  no change to upf written
##     1  remove certain upf constructs

set DEV(filter_hier_upf) 1

## This variable controls the filtering of set_attribute...lower_domain_boundary
## from the UPF' during the sproc_create_combined_upf proc. There are few
## tools that still use the combined UPF but some of those
## do not handle this attribute. It also must be set once at the top so
## filtering is also a way to limit the combined upf from doing otherwise.
## This should be turned off once tools support and once HiConn/LoConn
## hierarchical UPF methodologies are used.
##
##     0  leave attribute in UPF
##     1  remove the attribute

set DEV(remove_lower_domain_boundry_from_upf) 1

## Method of removing errant receiver supply constructs after ICC budgeting. STAR TBD
set DEV(upf_filter_workaround_receiver_supply) 1

## This variable controls the filtering of abstract model content
## that gets into the dop only upf. ICC STAR 9000818040
##
##     0  no workaround
##     1  filter UPF to remove these lines

set DEV(upf_filter_workaround_9000818040) 1

## This variable controls the filtering of the construct
## DERIVED_DIVERSE out of DP which has caused analysis tasks like
## formality and VC LP issues.
##
##     0  no workaround
##     1  filter UPF to remove these lines

set DEV(upf_filter_workaround_derived_diverse_clk) 1

## This variable enables close checking of the parasitics annotated in PT. If
## the number of unannotated nets exceeds the threshold, an error will be reported.
##
##   When set to 0, any missed annotations results in an error
##   When set to -1, no missed annotation will cause an error
set DEV(missing_parasitic_threshold) 100

## Switches the mode used in tools for handling UPF from "UPF Prime" to
## the emerging "Golden UPF" mode.
##
##     0  UPF Prime (traditional methodology)
##     1  Golden UPF flow (emerging)

set DEV(enable_golden_upf) 0

## This supports a beta capability for launching ICC2 design planning
## directly from DC. Unless the block is setup for ICC2, this enables
## an alternative method of setting up pointers to the ndm libraries.

set DEV(adhoc_dc_icc2_link_setup) 1

## Used with Golden UPF flow to force optional output of UPF prime
## for use with tools which do not fully support golden upf.
## Created to retrofit MVRC, VSI, VCS-NLP into golden upf flow
## until those tools support.
##
##     0  No additional UPF output
##     1  When in golden upf mode, the full UPF Prime is also created

set DEV(force_upf_prime) 0

## Enables a newer Formality power model for bottom up UPF verifications
##
##     0  no power models are created
##     1  power models are created and used

set DEV(formal_power_model) 1

## Provides control over how Verdi Signoff handles a number of initially non-default
## behaviors to better align with Galaxy. For instance, unconnected object checks
## and rail order/leakage checks.
##
##     0  current vsi defaults
##     1  recommended non-defaults to align with galaxy

set DEV(vcst_non_default_vars) 1

## Control how UPF for self scoped, soft macro flow is handled during SYN.
## This is focused on development of DP flows which may need split UPF
## during ODL operations.
##
##     0  single UPF file for hierarchy is saved
##     1  soft macro UPF is saved seperate from top

set DEV(syn_split_upf_outputs) 0

## Conditional to enable FM feature which will autocorrect lib supply items
## Conditional to enable FM feature which will autocorrect lib supply items
## that are identified for MV library cells.
##
##     0  FM will use default hdlin_library_auto_correct false and errors can result
##     1  FM will use hdlin_library_auto_correct true and ignore MV cell errors

switch $SEV(techlib_name) {
  default {
    set DEV(FM_LIB_AUTOCORRECT) 0
  }
}

## Conditional enablement of ICC 11.09 development code for the purpose
## of monitoring off litho grid shapes.
##
##     0  disabled
##     1  aggressively screen and monitor for off litho grid shapes
##        and generate SNPS_ERROR message indicating detection

set DEV(1109_monitor_off_litho_grid) 0

## Conditional enablement of ICC 13.12 development code

set DEV(1312_delete_gr_workaround) 1

## Output errors when generating SDF with WNS less than this value

set DEV(sdf_wns_threshold) 0.0

## Enable golden upf mode in tools

if { $DEV(enable_golden_upf) } {
  set enable_golden_upf true
  sproc_msg -setup "set enable_golden_upf $enable_golden_upf"
}

## For testing of QV features

set DEV(qv_physical) 1

if { ($synopsys_program_name == "dc_shell") } {
  set ascii_scandef_enable_expand true
  sproc_msg -setup "set ascii_scandef_enable_expand true"
  sproc_msg -issue "Is ascii_scandef_enable_expand behavior now default post 2014.09-SP2?"
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
