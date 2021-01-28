## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_init.tcl#240 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file is sourced by the RTM on startup and contains the following:
## * - Procedures used by the RTM.
## *
## * Notes on additions to version 1.9 that required update to version 2:
## * - For rtm_init_js_*.tcl files, the interface to rtm_kill_cmd was updated
## *   This change allows for more efficient processing of task kill operations.
## *
## * Notes on additions to version 1.8 that required update to version 1.9:
## * - For the rtm_init.tcl file:
## *   - Added '-make_writeable' switch to rtm_restore procedure (for 2014.09-SP1)
## *   - Removed SunOS support (for 2014.09-SP1)
## *   - Added ENV variables for test support (for 2014.09-SP2; Synopsys internal usage only)
## * - For the rtm_init_tools.tcl file:
## *   - Several tool-specific changes to rtm_tool_query procedure (for 2014.09-SP1)
## *   - Added bit/gui support for pr_shell to rtm_shell_cmd procedure (for 2014.09-SP1)
## *   - Added ENV variables for test support (for 2014.09-SP2; Synopsys internal usage only)
## -----------------------------------------------------------------------------

set rtm_init_version 2

## -----------------------------------------------------------------------------
## Initialize command to use for external program execution.
## -----------------------------------------------------------------------------

if { [info exists synopsys_program_name] } {
  if { $synopsys_program_name == "rtm_shell" } {
    set ::gRtmShell_AllowSevModify 1
  }
}

if { [exec uname] == "SunOS" } {
  set SEV(exec_cmd) bash
} else {
  set SEV(exec_cmd) sh
}

if { [info exists env(LYNX_DEBUG_RTM_SEQ1_FAIL)] && ($env(LYNX_DEBUG_RTM_SEQ1_FAIL) == "1") } {
  set SEV(exec_cmd) __LYNX_DEBUG_RTM_SEQ1_FAIL__
}

if { [info exists synopsys_program_name] } {
  if { $synopsys_program_name == "rtm_shell" } {
    set ::gRtmShell_AllowSevModify 0
  }
}

## -----------------------------------------------------------------------------
## These procedures must be present and defined.
## -----------------------------------------------------------------------------

if { [info command parse_proc_arguments] != "parse_proc_arguments" } {

  proc parse_proc_arguments { required_switch args options_ref } {

    global define_proc_attributes_booleans
    global define_proc_attributes_args

    upvar $options_ref options

    set parent_level [expr [info level] - 1]
    set parent_name [lindex [info level $parent_level] 0]
    set parent_name [regsub {^::} $parent_name {}]

    if { $required_switch == "-args" } {
      for { set i 0 } { $i < [llength $args] } { incr i } {
        set arg [lindex $args $i]
        if { [lsearch $define_proc_attributes_args($parent_name) $arg] >= 0 } {
          ## This is a defined option
          if { [lsearch $define_proc_attributes_booleans($parent_name) $arg] >= 0 } {
            ## This is a boolean switch
            set options($arg) 1
          } else {
            ## This is not a boolean switch
            incr i
            set options($arg) [lindex $args $i]
          }
        } else {
          return -code error "Error: unknown option '$arg'"
        }
      }
    }
  }

}

if { [info command define_proc_attributes] != "define_proc_attributes" } {

  unset -nocomplain define_proc_attributes_booleans
  unset -nocomplain define_proc_attributes_args

  proc define_proc_attributes args {

    global define_proc_attributes_booleans
    global define_proc_attributes_args

    set proc_name ""
    set proc_args [list]

    for { set i 0 } { $i < [llength $args] } { incr i } {
      set arg [lindex $args $i]
      if { $i == 0 } {
        set proc_name $arg
        continue
      }
      switch -- $arg {
        -hidden {
          continue
        }
        -info {
          incr i
          continue
        }
        -define_args {
          incr i
          set proc_args [lindex $args $i]
        }
        default {
          puts stderr "Error: define_proc_attributes: Unrecognized argument: $arg"
        }
      }
    }

    if { $proc_name != "" } {
      set define_proc_attributes_booleans($proc_name) [list]
      set define_proc_attributes_args($proc_name) [list]
      foreach proc_arg $proc_args {
        set switch_name [lindex $proc_arg 0]
        set switch_type [lindex $proc_arg end-1]
        if { $switch_type == "boolean" } {
          lappend define_proc_attributes_booleans($proc_name) $switch_name
        }
        lappend define_proc_attributes_args($proc_name) $switch_name
      }
    } else {
      puts stderr "Error: define_proc_attributes: Procedure name not defined."
    }

  }

}

## -----------------------------------------------------------------------------
## Load procedures from external files.
## -----------------------------------------------------------------------------

if { [info exists LYNX(rtm_shell_init)] } {
  set LYNX(rtm_init_path) $LYNX(rtm_shell_gscript_dir)/conf
} else {
  set LYNX(rtm_init_path) $SEV(gscript_dir)/conf
}

set files [list \
  $LYNX(rtm_init_path)/rtm_init_rc_$SEV(rc_method).tcl \
  $LYNX(rtm_init_path)/rtm_init_tools.tcl \
  $LYNX(rtm_init_path)/rtm_init_js_$SEV(job_app).tcl \
  $LYNX(rtm_init_path)/rtm_generate_flow_docs.tcl \
  $LYNX(rtm_init_path)/rtm_report_flow.tcl \
  ]

foreach file $files {
  if { ![file exists $file] } {
    puts "Error: File $file not found."
  } else {
    source $file
  }
}

set file $LYNX(rtm_init_path)/wait_for_job_to_finish_$SEV(job_app).tcl
if { ![file exists $file] } {
  puts "Error: File $file not found."
}

## -----------------------------------------------------------------------------
## Load remaining procedures from this file.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## rtm_notify
## -----------------------------------------------------------------------------

proc rtm_notify { args } {

  global env SEV SVAR TEV

  set options(-notify_info)   ""
  set options(-notify_email)  ""
  set options(-notify_option) 0

  parse_proc_arguments -args $args options

  set message_send 0
  set message_text "Undefined message"

  ## -------------------------------------
  ## The argument to -notify_info is a list with three fields.
  ##
  ## Field #1 (type): Allowed values are:
  ## - run_task_completed_task (meaning that a task invoked via run_task finished)
  ## - run_flow_completed_task (meaning that a task invoked via run_flow finished)
  ## - run_flow_completed_flow (meaning that a flow finished)
  ##
  ## Field #2 (item):
  ## - If type is run_task_completed_task | run_flow_completed_task,
  ##   then item will be the absolute path to the task's log file.
  ## - If type is run_flow_completed_flow,
  ##   then item will be the name of the run_flow command's goal.
  ##
  ## Field #3 (status): Available flow status values are:
  ## - status_finished
  ## - status_finished_with_errors
  ## - status_failed
  ## - status_halted
  ## - status_nothing_to_to
  ##
  ## -------------------------------------

  set type   [lindex $options(-notify_info) 0]
  set item   [lindex $options(-notify_info) 1]
  set status [lindex $options(-notify_info) 2]

  switch $type {

    run_task_completed_task -
    run_flow_completed_task {

      set logfile $item

      if { $type == "run_task_completed_task" } {
        set command_used run_task
      } else {
        set command_used run_flow
      }

      switch $status {
        status_finished {
          set message_send 0
          set message_text "Task completed via $command_used. Passed. Log File = $logfile."
        }
        status_finished_with_errors {
          set message_send 0
          set message_text "Task completed via $command_used. Waived. Log File = $logfile."
        }
        status_failed {
          set message_send 1
          set message_text "Task completed via $command_used. Failed. Log File = $logfile."
        }
        status_halted {
          set message_send 0
          set message_text "Task completed via $command_used. Halted. Log File = $logfile."
        }
        status_nothing_to_to {
          set message_send 0
          set message_text "Task not executed via $command_used."
        }
        default {
        }
      }

    }

    run_flow_completed_flow {

      set goal $item

      switch $status {
        status_finished {
          set message_send 1
        }
        status_finished_with_errors {
          set message_send 1
        }
        status_failed {
          set message_send 1
        }
        status_halted {
        }
        status_nothing_to_to {
        }
        default {
        }
      }

      set message_text "Flow completed. Status = $status. Goal = $goal."

    }

  }

  ## -------------------------------------
  ## Send email notification.
  ## -------------------------------------

  if { $message_send } {
    puts stderr "Sending notification to: $options(-notify_email)"
    puts stderr "Notification message: $message_text"

    set fid [open .message_text w]
    puts $fid $message_text
    close $fid

    catch { exec mail $options(-notify_email) -s "Runtime Manager Notification" < .message_text }

    file delete .message_text
  }

}

define_proc_attributes rtm_notify \
  -info "Customizable procedure for providing flow execution notifications." \
  -hidden \
  -define_args {
  {-notify_info "Notification info per format described in procedure body." AString string optional}
  {-notify_email "Email address information." AString string required}
  {-notify_option "Notification options." AnInt int required}
}

## -----------------------------------------------------------------------------
## rtm_clean:
## -----------------------------------------------------------------------------

proc rtm_clean { args } {

  global env SEV SVAR TEV

  set options(-techlib)  [current_techlib]
  set options(-block)    [current_block]
  set options(-step)     ""
  set options(-dst)      ""
  set options(-type)     ""
  set options(-tmp_only) 0

  parse_proc_arguments -args $args options

  if { $options(-techlib) == "" } {
    return -code error "rtm_clean: The value for -techlib is not specified."
  }
  if { $options(-block) == "" } {
    return -code error "rtm_clean: The value for -block is not specified."
  }
  if { ($options(-step) == "") && ($options(-dst) != "") } {
    return -code error "rtm_clean: The -dst argument must be used along with the -step argument."
  }
  if { ($options(-dst) == "") && ($options(-type) != "") } {
    return -code error "rtm_clean: The -type argument must be used along with the -dst argument."
  }
  if { $options(-tmp_only) && ($options(-dst) != "") } {
    return -code error "rtm_clean: The -tmp_only argument can't be used with the -dst argument."
  }

  if { ($options(-step) == "") } {
    set scope block
  } else {
    if { ($options(-dst) == "") } {
      set scope step
    } else {
      set scope dst
    }
  }

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  switch $scope {

    dst {
      set base_dir $block_root/$options(-block)/$options(-step)
      if { $options(-type) == "" } {
        ## Delete all types of dst directory.
        set dirs [list \
          $base_dir/work/$options(-dst) \
          $base_dir/logs/$options(-dst) \
          $base_dir/rpts/$options(-dst) \
          ]
      } else {
        ## Delete only the specific type of dst directory.
        set dirs [list \
          $base_dir/$options(-type)/$options(-dst) \
          ]
      }
      foreach dir $dirs {
        file delete -force $dir
      }
    }

    step {
      set base_dir $block_root/$options(-block)/$options(-step)
      if { $options(-tmp_only) } {
        set dirs [list $base_dir/tmp ]
      } else {
        set dirs [list $base_dir/tmp $base_dir/work $base_dir/logs $base_dir/rpts ]
      }
      foreach dir $dirs {
        set files [glob -nocomplain $dir/*]
        foreach file $files {
          if { ([file tail $file] == "CVS" || [file tail $file] == ".svn") && [file isdirectory $file] } {
            ## This is a CVS/SVN directory, so leave it alone.
          } else {
            file delete -force $file
          }
        }
      }
    }

    block {
      set potential_step_dirs \
        [glob -nocomplain -type d $block_root/$options(-block)/*]
      set step_dirs [list]
      foreach dir $potential_step_dirs {
        if { [file isdirectory $dir/tmp]  && \
            [file isdirectory $dir/work] && \
            [file isdirectory $dir/logs] && \
            [file isdirectory $dir/rpts] \
          } {
          lappend step_dirs $dir
        }
      }
      foreach dir $step_dirs {
        if { $options(-tmp_only) } {
          set dirs [list $dir/tmp ]
        } else {
          set dirs [list $dir/tmp $dir/work $dir/logs $dir/rpts ]
        }
        foreach dir $dirs {
          set files [glob -nocomplain $dir/*]
          foreach file $files {
            if { ([file tail $file] == "CVS"|| [file tail $file] == ".svn") && [file isdirectory $file] } {
              puts "skipping $file"
              ## This is a CVS directory, so leave it alone.
            } else {
              file delete -force $file
            }
          }
        }
      }
    }

  }

  cd $savepwd
}

define_proc_attributes rtm_clean \
  -info "Customizable procedure for cleaning a step directory." \
  -hidden \
  -define_args {
  {-techlib "The techlib specification. The default is current_techlib." AString string optional}
  {-block "The block specification. The default is current_block." AString string optional}
  {-step "The step specification." AString string optional}
  {-tmp_only "Enables deletion of only the tmp directory for a step." "" boolean optional}
  {-dst "The dst specification." AString string optional}
  {-type "The type specification." AnOos one_of_string
  {optional value_help {values { work logs rpts }}}}
}

## -----------------------------------------------------------------------------
## rtm_new_techlib:
## -----------------------------------------------------------------------------

proc rtm_new_techlib { args } {

  global env SEV SVAR TEV

  set options(-new_techlib) ""
  set options(-old_techlib) ""
  set options(-ci)          0
  set options(-check_only)  0

  parse_proc_arguments -args $args options

  set new_techlib $SEV(workarea_dir)/scripts_global/$options(-new_techlib)

  set old_techlib $SEV(workarea_dir)/scripts_global/$options(-old_techlib)

  if { [file isdirectory $new_techlib] } {
    return -code error "rtm_new_techlib: The directory specified by -new_techlib exists."
  }
  if { ![file isdirectory $old_techlib] } {
    return -code error "rtm_new_techlib: The directory specified by -old_techlib does not exist."
  }

  if { $options(-check_only) } {
    return
  }

  ## Create the new techlib by copying the old techlib.
  ## Remove the CVS/.svn directories.

  file copy $old_techlib $new_techlib

  set files [exec find $new_techlib -type d -name CVS]
  foreach file $files {
    file delete -force $file
  }
  set files [exec find $new_techlib -type d -name .svn]
  foreach file $files {
    file delete -force $file
  }

  ## Conditionally check techlib into RC system.

  if { $options(-ci) } {

    ## -------------------------------------
    ## Define the RC system being used and perform some basic checks.
    ## -------------------------------------

    if { [ catch { rtm_rc_method } rc_method ] } {
      return -code error $rc_method
    }

    rtm_rc_files_checkin_dir -dir $SEV(workarea_dir)/scripts_global/$options(-new_techlib)

  }

  ## Create directory beneath blocks so that RTM will start correctly.

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-new_techlib)
  }
  file mkdir $block_root
  cd $savepwd

}

define_proc_attributes rtm_new_techlib \
  -info "Customizable procedure for creating a new techlib directory." \
  -hidden \
  -define_args {
  {-new_techlib "The name of the techlib being created." AString string required}
  {-old_techlib "The name of the techlib being used as a template." AString string required}
  {-ci             "Check new techlib into RC system once created." "" boolean optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_new_block:
## -----------------------------------------------------------------------------

proc rtm_new_block { args } {

  global env SEV SVAR TEV

  set options(-techlib)        [current_techlib]
  set options(-block)          ""
  set options(-existing_block) ""
  set options(-is_template)    0
  set options(-ci)             0
  set options(-check_only)     0

  parse_proc_arguments -args $args options

  if { [llength $options(-block)] != 1 } {
    return -code error "rtm_new_block: You must supply a value for -block."
  }
  if { [llength $options(-existing_block)] != 1 } {
    return -code error "rtm_new_block: You must supply a value for -existing_block."
  }

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  set block_new $block_root/$options(-block)

  if { $options(-is_template) } {
    set block_old $SEV(workarea_dir)/scripts_global/$options(-techlib)/templates/$options(-existing_block)
  } else {
    set block_old $block_root/$options(-existing_block)
  }

  if { [file exists $block_new] } {
    cd $savepwd
    return -code error "rtm_new_block: The block specified by -block exists."
  }
  if { ![file isdirectory $block_old] } {
    cd $savepwd
    return -code error "rtm_new_block: The block specified by -existing_block does not exist."
  }

  if { $options(-check_only) } {
    cd $savepwd
    return
  }

  ## Create the new block by copying scripts from the old block.
  ## Remove the CVS/.svn directories.

  file mkdir $block_new
  file copy $block_old/scripts_block $block_new
  set files [exec find $block_new -type d -name CVS]
  foreach file $files {
    file delete -force $file
  }
  set files [exec find $block_new -type d -name .svn]
  foreach file $files {
    file delete -force $file
  }

  ## Conditionally check block into RC system.

  if { $options(-ci) } {

    ## -------------------------------------
    ## Define the RC system being used and perform some basic checks.
    ## -------------------------------------

    if { [ catch { rtm_rc_method } rc_method ] } {
      cd $savepwd
      return -code error $rc_method
    }

    rtm_rc_files_checkin_dir -dir $block_root/$options(-block)

  }

  cd $savepwd
}

define_proc_attributes rtm_new_block \
  -info "Customizable procedure for creating a new block directory." \
  -hidden \
  -define_args {
  {-techlib        "The techlib specification. The default is current_techlib." AString string optional}
  {-block          "The name of the block to create." AString string required}
  {-existing_block "The name of an existing block." AString string required}
  {-is_template    "The existing block is a template." "" boolean optional}
  {-ci             "Check new block into RC system once created." "" boolean optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_export_flow:
## -----------------------------------------------------------------------------

proc rtm_export_flow { args } {

  global env SEV SVAR TEV

  set options(-techlib)       [current_techlib]
  set options(-preview_file)   ""
  set options(-export_format) inline
  set options(-export_dir)    ""
  set options(-export_data)   [list]
  set options(-check_only)    0

  parse_proc_arguments -args $args options

  if { ![file exists $options(-preview_file)] } {
    return -code error "rtm_export_flow: The file specified by -preview_file does not exist."
  }

  if { [regexp {^/} $options(-export_dir)] } {
    ## Path is absolute
    set export_dir $options(-export_dir)
  } else {
    ## Path is relative
    set export_dir $SEV(workarea_dir)/$options(-export_dir)
  }

  if { [file exists $export_dir] } {
    return -code error "rtm_export_flow: The directory specified by -export_dir already exists."
  }

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  foreach dir $options(-export_data) {
    set f [split $dir /]
    set block [lindex $f 0]
    set step  [lindex $f 1]
    set work  [lindex $f 2]
    set dst   [lindex $f 3]
    if { ([llength $f] != 4) || ($work != "work") } {
      cd $savepwd
      return -code error "rtm_export_flow: A directory specified by -export_data is not valid: $dir"
    }
    set from_dir $block_root/$dir
    if { ![file isdirectory $from_dir] } {
      cd $savepwd
      return -code error "rtm_export_flow: A directory specified by -export_data does not exist: $from_dir"
    }
  }

  if { $options(-check_only) } {
    cd $savepwd
    return
  }

  ## -------------------------------------
  ## Parse the preview_file
  ## -------------------------------------

  set i 0
  unset -nocomplain task_items

  set fid [open $options(-preview_file) r]

  while { [gets $fid line] >= 0 } {
    set cmd_file [lindex $line 0]
    set f [split $cmd_file /]
    set block [lindex $f 0]
    set step  [lindex $f 1]
    set dst   [lindex $f 3]
    set task  [file rootname [lindex $f 4]]
    set task_item "$block $step $dst $task $cmd_file"
    set task_items($i) $task_item
    incr i
  }
  close $fid
  set num_tasks $i

  ## -------------------------------------
  ## Create the export_dir
  ## -------------------------------------

  file mkdir $export_dir

  file copy $options(-preview_file) $export_dir/the_preview_file

  set block_names [list]

  for {set i 0} { $i < $num_tasks } { incr i } {
    set task_item $task_items($i)
    set block     [lindex $task_item 0]
    set step      [lindex $task_item 1]
    set dst       [lindex $task_item 2]
    set task      [lindex $task_item 3]
    set cmd_file  [lindex $task_item 4]
    if { [lsearch $block_names $block] == -1 } {
      lappend block_names $block
    }
  }

  foreach block_name $block_names {

    puts stderr "Information: rtm_export_flow: Exporting $block_name"

    ## -------------------------------------
    ## Create the exported block dir
    ## -------------------------------------

    file mkdir $export_dir/$block_name

    ## -------------------------------------
    ## Create the step dirs
    ## -------------------------------------

    set dirs [glob -types d -nocomplain $block_root/$block_name/*]

    foreach dir $dirs {
      if { [file isdirectory $dir/logs] && \
          [file isdirectory $dir/rpts] && \
          [file isdirectory $dir/work] && \
          [file isdirectory $dir/tmp] \
        } {
        set step [file tail $dir]
        file mkdir $export_dir/$block_name/$step/logs
        file mkdir $export_dir/$block_name/$step/rpts
        file mkdir $export_dir/$block_name/$step/work
        file mkdir $export_dir/$block_name/$step/tmp
      }
    }

    ## -------------------------------------
    ## Copy the script dirs
    ## -------------------------------------

    set cmd "cp -RL $block_root/$block_name/scripts_block $export_dir/$block_name"
    eval exec $cmd

    set cmd "cp -RL $block_root/$block_name/scripts_global $export_dir/$block_name"
    eval exec $cmd

    set scripts_export_dir $export_dir/$block_name/scripts_export
    file mkdir $scripts_export_dir

    for {set i 0} { $i < $num_tasks } { incr i } {
      set task_item $task_items($i)
      set block     [lindex $task_item 0]
      set step      [lindex $task_item 1]
      set dst       [lindex $task_item 2]
      set task      [lindex $task_item 3]
      set cmd_file  [lindex $task_item 4]

      if { $block == $block_name } {

        if { $options(-export_format) == "native" } {
          set suffix_list [list sev.varfile tev.varfile]
        } else {
          set suffix_list [list script]
        }

        foreach suffix $suffix_list {
          set file_org [file rootname $cmd_file].$suffix
          set file_org $block_root/$file_org

          set file_new [file rootname [file tail $cmd_file]].$suffix
          set file_new $scripts_export_dir/$step/$dst/$file_new

          file mkdir [file dirname $file_new]
          file copy $file_org $file_new
        }

      }
    }

  }

  ## -------------------------------------
  ## Populate the step dirs
  ## -------------------------------------

  foreach dir $options(-export_data) {
    set f [split $dir /]
    set block [lindex $f 0]
    set step  [lindex $f 1]
    set work  [lindex $f 2]
    set dst   [lindex $f 3]

    set from_dir $block_root/$dir
    set to_dir   $export_dir/$dir
    set cmd "cp -RL $from_dir $to_dir"
    eval exec $cmd
  }

  ## -------------------------------------
  ## Create the top level automation files.
  ## -------------------------------------

  unset -nocomplain auto_items

  for {set i 0} { $i < $num_tasks } { incr i } {
    set task_item $task_items($i)
    set block     [lindex $task_item 0]
    set step      [lindex $task_item 1]
    set dst       [lindex $task_item 2]
    set task      [lindex $task_item 3]
    set cmd_file  [lindex $task_item 4]

    ## -------------------------------------
    ## Determine command
    ## -------------------------------------

    set fid [open $block_root/$cmd_file r]
    set lines_no_split [read $fid]
    close $fid

    set lines [split $lines_no_split \n]
    set rtm_shell_args ""
    foreach line $lines {
      if { [regexp {^## rtm_shell_cmd (.*)$} $line match rtm_shell_args] } {
        break
      }
    }
    if { $rtm_shell_args == "" } {
      cd $savepwd
      return -code error "rtm_export_flow: Unable to determine rtm_shell_args for $cmd_file."
    }

    set log_file ../logs/$dst/$task.log
    set sev_file [file rootname [file tail $cmd_file]].sev.varfile
    set sev_file ../../scripts_export/$step/$dst/$sev_file
    set tev_file [file rootname [file tail $cmd_file]].tev.varfile
    set tev_file ../../scripts_export/$step/$dst/$tev_file

    if { $options(-export_format) == "native" } {
      set fid [open [file rootname $block_root/$cmd_file].sev.varfile r]
      set lines [read $fid]
      close $fid
      set lines [split $lines \n]
      foreach line $lines {
        regexp {set\s+SEV\(script_file\)\s+\"([\w\.\/]+)\"} $line match script_file
      }
    } else {
      set script_file [file rootname [file tail $cmd_file]].script
      set script_file ../../scripts_export/$step/$dst/$script_file
    }

    set cmd ""
    set cmd "$cmd set new_cmd \["
    set cmd "$cmd rtm_shell_cmd $rtm_shell_args"
    set cmd "$cmd -export_script $script_file"
    set cmd "$cmd -export_logfile $log_file"
    set cmd "$cmd \]"
    eval $cmd

    set cmd_lines [split $new_cmd \n]
    set new_cmd [lindex $cmd_lines 0]

    set auto_item "$block $step $dst $task $sev_file $tev_file $new_cmd"
    set auto_items($i) $auto_item
  }

  ## -------------------------------------
  ## Create the shell script
  ## -------------------------------------

  set fid [open $export_dir/flow.sh w]
  puts $fid "#! /bin/sh"
  puts $fid ""

  for {set i 0} { $i < $num_tasks } { incr i } {
    set auto_item $auto_items($i)
    set block    [lindex $auto_item 0]
    set step     [lindex $auto_item 1]
    set dst      [lindex $auto_item 2]
    set task     [lindex $auto_item 3]
    set sev_file [lindex $auto_item 4]
    set tev_file [lindex $auto_item 5]
    set new_cmd [lrange $auto_item 6 end]

    puts $fid "mkdir -p $block/$step/logs/$dst $block/$step/rpts/$dst $block/$step/work/$dst"
    puts $fid "cd $block/$step/tmp"
    if { $options(-export_format) == "native" } {
      puts $fid "export LYNX_VARFILE_SEV=$sev_file"
      puts $fid "export LYNX_VARFILE_TEV=$tev_file"
    }
    puts $fid "$new_cmd"
    puts $fid "cd ../../.."
    puts $fid ""
  }

  close $fid

  file attributes $export_dir/flow.sh -permissions ugo+x

  ## -------------------------------------
  ## Create the makefile
  ## -------------------------------------

  set fid [open $export_dir/flow.make w]

  for {set i 0} { $i < $num_tasks } { incr i } {
    set auto_item $auto_items($i)
    set block    [lindex $auto_item 0]
    set step     [lindex $auto_item 1]
    set dst      [lindex $auto_item 2]
    set task     [lindex $auto_item 3]
    set sev_file [lindex $auto_item 4]
    set tev_file [lindex $auto_item 5]
    set new_cmd [lrange $auto_item 6 end]

    set index [format {%03d} $i]
    if { $i > 0 } {
      set index2 [format {%03d} [expr $i-1]]
      puts $fid "task_$index: task_$index2"
    } else {
      puts $fid "task_$index:"
    }
    puts $fid "\tmkdir -p $block/$step/logs/$dst $block/$step/rpts/$dst $block/$step/work/$dst"
    if { $options(-export_format) == "native" } {
      puts $fid "\tcd $block/$step/tmp && export LYNX_VARFILE_SEV=$sev_file && export LYNX_VARFILE_TEV=$tev_file && $new_cmd"
    } else {
      puts $fid "\tcd $block/$step/tmp && $new_cmd"
    }
    puts $fid "\tdate > task_$index"
    puts $fid ""
  }

  puts $fid "all: task_$index"
  puts $fid ""

  close $fid

  ## -------------------------------------
  ## That's all folks!
  ## -------------------------------------

  puts stderr "Information: rtm_export_flow: Done!"

  cd $savepwd
}

define_proc_attributes rtm_export_flow \
  -info "Customizable procedure for exporting a flow." \
  -define_args {
  {-techlib        "The techlib specification. The default is current_techlib." AString string optional}
  {-preview_file   "The task file from a flow preview." AString string required}
  {-export_format  "Selects format for the exported flow." AnOos one_of_string
  {optional value_help {values { inline native }}}}
  {-export_dir     "Specifies the directory that will contain the exported flow. Relative paths are interpreted as relative to the workarea directory." AString string required}
  {-export_data    "Data directories to include in the exported flow." AList list optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_export_workarea:
## -----------------------------------------------------------------------------

proc rtm_export_workarea { args } {

  global env SEV SVAR TEV

  set options(-techlib)       [current_techlib]
  set options(-export_data)   [list]
  set options(-check_only)    0

  parse_proc_arguments -args $args options

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  foreach dir $options(-export_data) {
    set f [split $dir /]
    set block [lindex $f 0]
    set step  [lindex $f 1]
    set work  [lindex $f 2]
    set dst   [lindex $f 3]
    if { ([llength $f] != 4) || ($work != "work") } {
      cd $savepwd
      return -code error "rtm_export_workarea: A directory specified by -export_data is not valid: $dir"
    }
    set from_dir $block_root/$dir
    if { ![file isdirectory $from_dir] } {
      cd $savepwd
      return -code error "rtm_export_workarea: A directory specified by -export_data does not exist: $from_dir"
    }
  }

  if { $options(-check_only) } {
    cd $savepwd
    return
  }

  ## -------------------------------------
  ## Create the list of directories to tar.
  ## -------------------------------------

  set dir_list [list]

  set dir_list [concat $dir_list scripts_global]
  set dir_list [concat $dir_list [glob $block_root/*/scripts_block]]

  foreach dir $options(-export_data) {
    set f [split $dir /]
    set block [lindex $f 0]
    set step  [lindex $f 1]
    set work  [lindex $f 2]
    set dst   [lindex $f 3]

    set dir_list [concat $dir_list $block_root/$block/$step/work/$dst]
    set dir_list [concat $dir_list $block_root/$block/$step/logs/$dst]
    set dir_list [concat $dir_list $block_root/$block/$step/rpts/$dst]
  }

  ## -------------------------------------
  ## Perform the tar creation
  ## -------------------------------------

  set tar_file $SEV(workarea_dir)/workarea.tgz

  file delete -force $tar_file

  set cmd "gtar cvfzh $tar_file $dir_list"

  catch { exec $SEV(exec_cmd) -c "$cmd" }

  ## -------------------------------------
  ## That's all folks!
  ## -------------------------------------

  puts stderr "Information: rtm_export_workarea: Done!"

  cd $savepwd
}

define_proc_attributes rtm_export_workarea \
  -info "Customizable procedure for exporting a workarea." \
  -define_args {
  {-techlib        "The techlib specification. The default is current_techlib." AString string optional}
  {-export_data    "Data directories to include in the exported flow." AList list optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_release_restore_query:
## -----------------------------------------------------------------------------

proc rtm_release_restore_query { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-techlib)                ""
  set options(-block)                  ""
  set options(-info_block_list)        0
  set options(-info_release_list)      0
  set options(-info_block_release_dir) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Processing for options(-info_block_list)
  ## -------------------------------------

  if { $options(-info_block_list) } {
    set block_list [list]

    set block_dirs [glob -nocomplain -types { d } $SEV(release_dir)/$options(-techlib)/*]
    foreach block_dir $block_dirs {
      lappend block_list [file tail $block_dir]
    }

    return $block_list
  }

  ## -------------------------------------
  ## Processing for options(-info_release_list)
  ## -------------------------------------

  if { $options(-info_release_list) } {
    set release_list [list]

    set release_dirs [glob -nocomplain -types { d } $SEV(release_dir)/$options(-techlib)/$options(-block)/*]
    foreach release_dir $release_dirs {
      lappend release_list [file tail $release_dir]
    }

    return $release_list
  }

  ## -------------------------------------
  ## Return the directory name that will hold the releases for a block.
  ## -------------------------------------

  if { $options(-info_block_release_dir) } {
    set block_release_dir $SEV(release_dir)/$options(-techlib)/$options(-block)
    return $block_release_dir
  }

}

define_proc_attributes rtm_release_restore_query \
  -info "Procedure for returning information about the release." \
  -define_args {
  {-techlib                "Specifies the techlib of the block being released." AString string optional}
  {-block                  "Specifies the name of the block being released." AString string optional}
  {-info_block_list        "Returns list of available blocks only." "" boolean optional}
  {-info_release_list      "Returns list of releases names only." "" boolean optional}
  {-info_block_release_dir "Returns base dir name only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_release:
## -----------------------------------------------------------------------------

proc rtm_release { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-techlib)        ""
  set options(-block)          ""
  set options(-dirs)           [list]
  set options(-release_name)   ""
  set options(-force)          0
  set options(-check_only)     0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Check arguments.
  ## -------------------------------------

  if { $options(-techlib) == "" } {
    return -code error "rtm_release: Argument for -techlib not specified."
  }
  if { $options(-block) == "" } {
    return -code error "rtm_release: Argument for -block not specified."
  }
  if { $options(-dirs) == "" } {
    return -code error "rtm_release: Argument for -dirs not specified."
  }
  if { $options(-release_name) == "" } {
    return -code error "rtm_release: Argument for -release_name not specified."
  }

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  foreach item $options(-dirs) {
    set input_dir $block_root/$options(-block)/$item
    if { ![file isdirectory $input_dir] } {
      cd $savepwd
      return -code error "rtm_release: Directory does not exist: $input_dir"
    }
  }

  if { $options(-check_only) } {
    cd $savepwd
    return
  }

  ## -------------------------------------
  ## If the release dir exists and -force is used,
  ## then attempt to delete the release dir.
  ## If the release dir exists and -force is not used,
  ## then abort in order to prevent data corruption.
  ## -------------------------------------

  foreach item $options(-dirs) {

    set release_dir $SEV(release_dir)/$options(-techlib)/$options(-block)/$options(-release_name)/$item
    set input_dir $block_root/$options(-block)/$item

    if { [file exists $release_dir] } {
      if { $options(-force) == 1 } {
        if { [file exists $release_dir] } {
          set cmd "chmod -R +w $release_dir"
          eval exec $cmd
        }
        file delete -force $release_dir
        if { [file exists $release_dir] } {
          cd $savepwd
          return -code error "rtm_release: Unable to delete release directory: $release_dir"
        }
      } else {
        cd $savepwd
        return -code error "rtm_release: The release directory already exists: $release_dir"
      }
    }

    ## -------------------------------------
    ## First, copy data from $input_dir directory to $release_dir.
    ## Then chmod on release_dir.
    ## -------------------------------------

    file mkdir [file dirname $release_dir]

    set cmd "cp -RL $input_dir $release_dir"
    eval exec $cmd
    set cmd "chmod -R -w $release_dir"
    eval exec $cmd

  }

  ## -------------------------------------
  ## Create a small readme file to document the release.
  ## -------------------------------------

  set readme_file $SEV(release_dir)/$options(-techlib)/$options(-block)/$options(-release_name)/.readme
  set fid [open $readme_file w]
  puts $fid "Release create on [date] using data from:"
  foreach item $options(-dirs) {
    set input_dir [file normalize $block_root/$options(-block)/$item]
    puts $fid "  $input_dir"
  }
  close $fid

  cd $savepwd
}

define_proc_attributes rtm_release \
  -info "Procedure for releasing data from a step directory into a release directory." \
  -define_args {
  {-techlib        "Specifies the techlib of the block being released." AString string required}
  {-block          "Specifies the name of the block being released." AString string required}
  {-dirs           "Specifies the directories being released." AString string required}
  {-release_name   "Specifies the name used for the released data." AString string required}
  {-force          "Forces replacement of pre-existing released data" "" boolean optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_restore:
## -----------------------------------------------------------------------------

proc rtm_restore { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-techlib)        ""
  set options(-block)          ""
  set options(-dirs)           [list]
  set options(-release_name)   ""
  set options(-force)          0
  set options(-copy)           0
  set options(-check_only)     0
  set options(-restore_to)     ""
  set options(-make_writeable) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Check arguments.
  ## -------------------------------------

  if { $options(-techlib) == "" } {
    return -code error "rtm_restore: Argument for -techlib not specified."
  }
  if { $options(-block) == "" } {
    return -code error "rtm_restore: Argument for -block not specified."
  }
  if { $options(-dirs) == "" } {
    return -code error "rtm_restore: Argument for -dirs not specified."
  }
  if { $options(-release_name) == "" } {
    return -code error "rtm_restore: Argument for -release_name not specified."
  }

  set release_dir_block_name $options(-block)

  if { $options(-restore_to) == "" } {
    set workarea_block_name $options(-block)
  } else {
    set workarea_block_name $options(-restore_to)
  }

  foreach item $options(-dirs) {
    set release_dir $SEV(release_dir)/$options(-techlib)/$release_dir_block_name/$options(-release_name)/$item
    if { ![file isdirectory $release_dir] } {
      return -code error "rtm_restore: Directory does not exist: $release_dir"
    }
  }

  if { $options(-check_only) } {
    return
  }

  ## -------------------------------------
  ## Continue
  ## -------------------------------------

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$options(-techlib)
  }

  ## -------------------------------------
  ## If the output directory exists and -force is used,
  ## then attempt to delete the directory.
  ## If the output directory exists and -force is not used,
  ## then abort in order to prevent data corruption.
  ## -------------------------------------

  foreach item $options(-dirs) {

    set release_dir $SEV(release_dir)/$options(-techlib)/$release_dir_block_name/$options(-release_name)/$item
    set output_dir $block_root/$workarea_block_name/$item

    if { [file exists $output_dir] } {
      if { $options(-force) == 1 } {
        set cmd "chmod -R +w $output_dir"
        eval exec $cmd
        file delete -force $output_dir
        if { [file exists $output_dir] } {
          cd $savepwd
          return -code error "rtm_restore: Unable to delete output directory: $output_dir"
        }
      } else {
        cd $savepwd
        return -code error "rtm_restore: The output directory already exists: $output_dir"
      }
    }

    ## -------------------------------------
    ## Now, copy or link the $release_dir to the $output_dir
    ## -------------------------------------

    if { $options(-copy) } {
      file mkdir [file dirname $output_dir]
      file copy -force $release_dir $output_dir
      if { $options(-make_writeable) } {
        set cmd "chmod -R +w $output_dir"
        eval exec $cmd
      }
    } else {
      file mkdir [file dirname $output_dir]
      file link $output_dir $release_dir
    }

  }

  cd $savepwd
}

define_proc_attributes rtm_restore \
  -info "Procedure for restoring data from a release directory into a step directory." \
  -define_args {
  {-techlib        "Specifies the block's techlib." AString string required}
  {-block          "Specifies the block's name." AString string required}
  {-dirs           "Specifies the directories being restored." AString string required}
  {-release_name   "Specifies the release name." AString string required}
  {-force          "Forces deletion of pre-existing block data." "" boolean optional}
  {-copy           "Copies data instead of linking data." "" boolean optional}
  {-check_only     "Checks arguments only." "" boolean optional}
  {-restore_to     "Specifies the block directory name that will be created in the workarea." AString string optional}
  {-make_writeable "Makes the restored data writeable." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_copy:
## -----------------------------------------------------------------------------

proc rtm_copy { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-techlib)    ""
  set options(-block_src)  ""
  set options(-block_dst)  ""
  set options(-dirs)       [list]
  set options(-force)      0
  set options(-check_only) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Check arguments.
  ## -------------------------------------

  if { $options(-techlib) == "" } {
    return -code error "rtm_copy: Argument for -techlib not specified."
  }
  if { $options(-block_src) == "" } {
    return -code error "rtm_copy: Argument for -block_src not specified."
  }
  if { $options(-block_dst) == "" } {
    return -code error "rtm_copy: Argument for -block_dst not specified."
  }
  if { $options(-dirs) == "" } {
    return -code error "rtm_copy: Argument for -dirs not specified."
  }

  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root $SEV(workarea_dir)
  } else {
    set block_root $SEV(workarea_dir)/blocks/$options(-techlib)
  }

  foreach item $options(-dirs) {
    set src_dir $block_root/$options(-block_src)/$item
    if { ![file isdirectory $src_dir] } {
      return -code error "rtm_copy: Source directory does not exist: $src_dir"
    }
  }

  if { $options(-check_only) } {
    return
  }

  ## -------------------------------------
  ## Continue
  ## -------------------------------------

  ## -------------------------------------
  ## If the output directory exists and -force is used,
  ## then attempt to delete the directory.
  ## If the output directory exists and -force is not used,
  ## then abort in order to prevent data corruption.
  ## -------------------------------------

  foreach item $options(-dirs) {

    set src_dir $block_root/$options(-block_src)/$item
    set dst_dir $block_root/$options(-block_dst)/$item

    puts stderr "Copying $options(-block_src)/$item ..."

    if { [file exists $dst_dir] } {
      if { $options(-force) == 1 } {
        set cmd "chmod -R +w $dst_dir"
        eval exec $cmd
        file delete -force $dst_dir
        if { [file exists $dst_dir] } {
          return -code error "rtm_copy: Unable to delete destination directory: $dst_dir"
        }
      } else {
        return -code error "rtm_copy: The destination directory already exists: $dst_dir"
      }
    }

    ## -------------------------------------
    ## Now, copy the $src_dir to the $dst_dir
    ## -------------------------------------

    file mkdir [file dirname $dst_dir]

    ## file copy -force $src_dir $dst_dir
    set cmd "cp -RL $src_dir $dst_dir"
    eval exec $cmd

  }

  puts stderr "Copying Done!"

}

define_proc_attributes rtm_copy \
  -info "Procedure for restoring data from a release directory into a step directory." \
  -define_args {
  {-techlib        "Specifies the block's techlib." AString string required}
  {-block_src      "Specifies the source block's name." AString string required}
  {-block_dst      "Specifies the destination block's name." AString string required}
  {-dirs           "Specifies the directories being copied." AString string required}
  {-force          "Forces deletion of pre-existing destination block data." "" boolean optional}
  {-check_only     "Checks arguments only." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_view_graph:
## -----------------------------------------------------------------------------

proc rtm_view_graph { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-id) ""
  set options(-obj) ""

  parse_proc_arguments -args $args options

  ## -------------------------------------

  set dot [current_block].dot
  set gif [current_block].gif

  create_dot_file -id $options(-id) -obj $options(-obj) -dot_file $dot

  set cmd "dot -Tgif -o$gif $dot"
  catch { eval exec $cmd }

  set cmd "eog $gif &"
  catch { eval exec $cmd }

}

define_proc_attributes rtm_view_graph \
  -info "Procedure for generating a dot graph." \
  -define_args {
  {-id "Specifies flow session for dot generation." AString string required}
  {-obj "Specifies flow object for dot generation." AString string required}
}

## -----------------------------------------------------------------------------
## rtm_logs_to_metrics:
## -----------------------------------------------------------------------------

proc rtm_logs_to_metrics { args } {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-logs) ""
  set options(-tags) ""
  set options(-metrics_enable_transfer) 0
  set options(-metrics_enable_forward) 0

  parse_proc_arguments -args $args options

  if { ($options(-metrics_enable_transfer) != 0) && ($options(-metrics_enable_transfer) != 1) && ($options(-metrics_enable_transfer) != 2) } {
    puts stderr "Error: The argument for -metrics_enable_transfer must be: 0 | 1 | 2"
    return
  }

  ## -------------------------------------
  ## Print info about tags.
  ## -------------------------------------

  set num_items [llength $options(-tags)]

  set all_valid 1

  if { $num_items > 0 } {

    if { [expr $num_items % 2] != 0 } {

      puts stderr "Error: The argument for -tags must be a list with an even number of elements."
      set all_valid 0

    } else {

      foreach { tag value } $options(-tags) {
        set valid 1
        if { ![regexp {^tag_(\d\d)$} $tag match index_char] } {
          set valid 0
        } else {
          if { [expr $index_char] > 30 } {
            set valid 0
          }
        }
        if { !$valid } {
          puts stderr "Error: Tag '$tag' has an invalid format."
          set all_valid 0
        }
      }

    }

    if { $all_valid } {
      puts stderr "Info: Tag updates are successfully specified as follows:"
      foreach { tag value } $options(-tags) {
        puts stderr "Info:   tag($tag), value($value)"
      }
    } else {
      puts stderr "Error: Tag updates were not successfully specified."
      puts stderr "  The argument for -tags must be a list of name/value pairs."
      puts stderr "  The tag names must be of this format: 'tag_NN', where NN is 01-30."
      puts stderr "  For example: -tags { tag_01 tag_value_wo_spaces tag_02 \"tag value w spaces\" }"
      return
    }

  } else {

    puts stderr "Info: Tag updates are not specified"

  }

  ## -------------------------------------
  ## Print info about log files.
  ## -------------------------------------

  set log_files [glob -nocomplain $options(-logs)]
  puts stderr "Info: List of log files to process:"
  foreach log_file $log_files {
    puts stderr "Info:   $log_file"
  }

  ## -------------------------------------
  ## Process the log files.
  ## -------------------------------------

  if { $options(-metrics_enable_transfer) != 0 } {

    set count_total 0
    set count_pass  0
    set count_fail  0

    set dir $SEV(workarea_dir)/.rtm_logs_to_metrics
    file delete -force $dir

    foreach log_file $log_files {

      incr count_total

      file mkdir $dir/$count_total
      set tmp_file $dir/$count_total/[file tail $log_file]

      set fid [open $log_file r]
      set string_file [read $fid]
      set lines [split $string_file \n]
      close $fid

      set fid [open $tmp_file w]
      foreach line $lines {
        puts $fid $line
      }
      foreach { tag value } $options(-tags) {
        set tag [string toupper $tag]
        puts $fid "SNPS_INFO : METRIC | TAG SYS.$tag | $value"
      }
      puts $fid "SNPS_INFO : METRIC | BOOLEAN INFO.METRICS_ENABLE_FORWARD | $options(-metrics_enable_forward)"
      close $fid

      set result [log_file_error_checker \
        -use_global_error_checks 0 \
        -metrics_enable_transfer $options(-metrics_enable_transfer) \
        -metrics_flag_errors 1 \
        -log_filename $tmp_file]

      if { $result == "Failed" } {
        puts stderr "  Info  : Not OK $log_file ($count_total)"
        incr count_fail
      } else {
        puts stderr "  Info  : OK     $log_file ($count_total)"
        incr count_pass
      }

    }

    puts stderr "Info: Log files total      : $count_total"
    puts stderr "Info: Log files w/o errors : $count_pass"
    puts stderr "Info: Log files w/  errors : $count_fail"
    puts stderr "Info: See this directory for detailed results: '$dir'"

  } else {

    puts stderr "Info: Use the -metrics_enable_transfer argument to enable actual processing."

  }

}

define_proc_attributes rtm_logs_to_metrics \
  -info "Procedure for processing log files for purposes of metric submission." \
  -define_args {
  {-logs "Specifies the log files relative to SEV(workarea_dir) using glob-style notation." AString string required}
  {-tags "Specifies a list of tag/value pairs that will overwrite those in the log files." AString string optional}
  {-metrics_enable_transfer "0 (only list log files); 1 (send SYS metrics from log files); 2 (send all metrics from log files)" "" int optional}
  {-metrics_enable_forward "0 (metrics are not forwarded); 1 (metrics are forwarded if forwarding enabled for project in the MC)" "" int optional}
}

## -----------------------------------------------------------------------------
## This section is for user-defined function buttons in the EM
## -----------------------------------------------------------------------------

if {0} {

  array set rtm_user_function_0_info { name "Show rtm_job_cmd file" icon "scripts_global/demo/sample_icon.png" }

  proc rtm_user_function_0 { args } {

    global env SEV SVAR TEV

    set options(-log_file) ""
    set options(-viewer) ""
    set options(-editor) ""
    parse_proc_arguments -args $args options

    set log_file_absolute [file normalize $options(-log_file)]

    set name(all)     [split $log_file_absolute /]
    set name(log)     [lindex $name(all) end-0]
    set name(dst)     [lindex $name(all) end-1]
    set name(step)    [lindex $name(all) end-3]
    set name(block)   [lindex $name(all) end-4]
    set name(techlib) [lindex $name(all) end-5]
    set name(work)    [lindex $name(all) end-7]
    set name(task)    [file rootname $name(log)]

    ## Example code
    set file_part_org [file tail $log_file_absolute]
    set dir_part_org  [file dirname $log_file_absolute]
    set file_part_new [file rootname $file_part_org].rtm_job_cmd
    set target_file $dir_part_org/$file_part_new

    set cmd "$options(-editor) $target_file &"
    catch { eval exec $cmd } out
  }

  define_proc_attributes rtm_user_function_0 \
    -info "Customizable procedure for defining how the RTM runs tools." \
    -define_args {
    {-log_file "Absolute path to Log file"  AString string required}
    {-viewer   "RTM view preference"        AString string optional}
    {-editor   "RTM editor preference"      AString string optional}
  }

}

## -----------------------------------------------------------------------------
## rtm_send_snapshot:
## -----------------------------------------------------------------------------

proc rtm_send_snapshot { args } {

  global env SEV SVAR TEV

  set options(-block) ""
  set options(-path)  ""
  set options(-force) 0
  parse_proc_arguments -args $args options

  puts stderr ""
  puts stderr "Warning: You are running a default version of the rtm_send_snapshot procedure."
  puts stderr "         Please review the procedure and make alterations per your specific needs."
  puts stderr ""

  ## -------------------------------------
  ## Check for valid -block argument
  ## -------------------------------------

  set block_names [get_blocks *]
  if { [lsearch $block_names $options(-block)] == -1 } {
    puts stderr "Error: Invalid value specified for -block argument."
    puts stderr "       Valid values: [join $block_names " | "]"
    return
  }

  ## -------------------------------------
  ## Develop path name within the snapshot directory
  ## -------------------------------------

  if { $options(-path) != "" } {
    set snapshot_path $options(-path)
  } else {
    set date [clock format [clock seconds] -format "%Y_%m_%d"]
    set snapshot_path $options(-block)/$date
  }

  ## -------------------------------------
  ## Do the work
  ## -------------------------------------

  set src_dir $SEV(workarea_dir)/blocks/[current_techlib]/$options(-block)
  set dst_dir $SEV(snapshot_dir)/$snapshot_path

  puts stderr "Info: Block Dir    : $src_dir"
  puts stderr "Info: Snapshot Dir : $dst_dir"

  if { [file exists $dst_dir/dont_delete] } {
    puts stderr "Info: Directory marked as 'dont_delete'."
    puts stderr "Info: You must remove this file: $dst_dir/dont_delete"
    return
  }

  if { [file exists $dst_dir] } {
    if { $options(-force) } {
      file delete -force $dst_dir
    } else {
      puts stderr "Info: The snapshot directory exists. Use -force to overwrite directory."
      return
    }
  }

  if { [file exists $dst_dir] } {
    puts stderr "Error: Unable to remove directory: $dst_dir"
    return
  }

  file mkdir $dst_dir

  ## Specify the list of files to copy
  set src_file_list ""
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/.*.qor]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_qor]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_units]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_power]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_congestion]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_threshold_voltage_group]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_design_physical]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_clock_tree]"
  set src_file_list "$src_file_list [glob -nocomplain $src_dir/*/rpts/*/*.report_user_units]"

  ## Copy the files
  set file_count 0
  foreach src_file $src_file_list {
    set block_file [regsub $src_dir/ $src_file {}]
    set dst_file $dst_dir/$block_file
    file mkdir [file dirname $dst_file]
    set cmd "cp -p $src_file $dst_file"
    catch { eval exec $cmd }
    incr file_count
  }

  puts stderr "Info: A total of $file_count files were copied to the snapshot directory."

}

define_proc_attributes rtm_send_snapshot \
  -info "Copies a snapshot of block data into the snapshot directory." \
  -define_args {
  {-block   "Block name" AString string required}
  {-path    "Path name" AString string optional}
  {-force   "Force overwrite" "" boolean optional}
}

## -----------------------------------------------------------------------------
## This file can be used to override any previous procedure.
## -----------------------------------------------------------------------------

set file $LYNX(rtm_init_path)/rtm_init_override.tcl
if { [file exists $file] } {
  source $file
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
