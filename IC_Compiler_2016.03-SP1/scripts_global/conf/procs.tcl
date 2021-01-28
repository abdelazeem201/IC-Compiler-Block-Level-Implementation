## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/procs.tcl#535 $
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
## Setting synopsys_program_name for de_shell to 'dc_shell'
## to increase compatibility with existing dc_shell scripts.
## -----------------------------------------------------------------------------

if { $synopsys_program_name == "de_shell" } {
  set_app_var de_rename_shell_name_to_dc_shell true
  set_app_var synopsys_program_name dc_shell
}

## -----------------------------------------------------------------------------
## These procedures/variables are not uniformly available
## for all tools used in the flow. This section of code creates
## the procedures/variables if they are not available.
## -----------------------------------------------------------------------------

if { [info command date] != "date" } {
  proc date {} {
    return [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
  }
}

## The following line relies on the presence of a 'date' command.
## This is why it is not the very first line in the file.
puts "SNPS_INFO   : SCRIPT_START : [file normalize ../../scripts_global/conf/procs.tcl] : [date]"

if { ![info exists synopsys_root] } {
  set synopsys_root "synopsys_root"
}

## This code is also present in the scripts_global/conf/tool_wrapper.tcl file.
## It is repeated here to support execution of exported flows, which do not
## make use of the scripts_global/conf/tool_wrapper.tcl file.

if { ![info exists synopsys_program_name] } {
  if { [info commands db::getAttr] == "::db::getAttr" } {
    set synopsys_program_name cdesigner
  } else {
    set synopsys_program_name tcl
  }
}

if { $synopsys_program_name == "tcl" } {
  set sh_product_version [info patchlevel]
}
if { $synopsys_program_name == "cdesigner" } {
  set sh_product_version [db::getAttr version -of [db::getProcessInfo]]
}

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
        -info {
          incr i
          continue
        }
        -hidden {
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
## sproc_use_lynx_dirs:
## -----------------------------------------------------------------------------

proc sproc_use_lynx_dirs { args } {

  global SEV

  set options(-value) ""
  parse_proc_arguments -args $args options

  set rdir_list [list \
    tmp_dir \
    dst_dir \
    src_dir \
    log_dir \
    rpt_dir \
    work_dir \
    step_dir \
    bscript_dir \
    block_dir \
    tscript_dir \
    gscript_dir\
    workarea_dir \
    release_dir \
    techlib_dir \
    project_dir \
    ]

  set value $options(-value)

  foreach rdir $rdir_list {
    set value [regsub -all "$SEV($rdir)" $value "\$SEV($rdir)"]
  }

  return $value

}

define_proc_attributes sproc_use_lynx_dirs \
  -info "Convert argument to use standard Lynx directory references." \
  -define_args {
  {-value "The string to convert" AString string required}
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
## sproc_xfer:
## -----------------------------------------------------------------------------

proc sproc_xfer { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Process arguments.
  ## -------------------------------------

  set options(-f)       ""
  set options(-d)       ""
  set options(-rename)  ""
  set options(-link)    1

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Check arguments.
  ## -------------------------------------

  set error 0

  if { ($options(-f) == "") && ($options(-d) == "") } {
    sproc_msg -error "sproc_xfer: either -f or -d required."
    incr error
  }
  if { ($options(-f) != "") && ($options(-d) != "") } {
    sproc_msg -error "sproc_xfer: -f and -d are mutually exclusive."
    incr error
  }
  if { [regexp {^\.} $options(-rename)] || [regexp {^\/} $options(-rename)] } {
    sproc_msg -error "sproc_xfer: -rename must be a simple relative filespec."
    incr error
  }

  if { $error > 0 } {
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Continue
  ## -------------------------------------

  ## -------------------------------------
  ## Make sure that specified filespec_src
  ## exists and is correct w/r/t being
  ## either a file or a directory.
  ## -------------------------------------

  if { $options(-f) != "" } {
    set filespec_src $options(-f)
    set is_file 1
  } else {
    set filespec_src $options(-d)
    set is_file 0
  }

  sproc_msg -info "sproc_xfer: filespec_src is $filespec_src"

  set error 0

  if { ![file exists $filespec_src] } {
    sproc_msg -error "sproc_xfer: source file $filespec_src does not exist as of [date]."
    incr error
  } else {
    if { $is_file && [file isdirectory $filespec_src] } {
      sproc_msg -error "sproc_xfer: source file $filespec_src is not a file."
      incr error
    }
    if { !$is_file && ![file isdirectory $filespec_src] } {
      sproc_msg -error "sproc_xfer: source file $filespec_src is not a directory."
      incr error
    }
  }

  if { $error > 0 } {
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Calculate filespec_dst
  ## -------------------------------------

  if { $options(-rename) == "" } {
    set filespec_dst $SEV(dst_dir)/[file tail $filespec_src]
  } else {
    set filespec_dst $SEV(dst_dir)/$options(-rename)
  }

  sproc_msg -info "sproc_xfer: filespec_dst is $filespec_dst"

  ## -------------------------------------
  ## Do the copy or link
  ## -------------------------------------

  set platform [exec uname]
  if { $platform == "SunOS" } {
    set cp_cmd "cp -R"
  } else {
    set cp_cmd "cp -RL"
  }

  file delete -force $filespec_dst
  if { [file exists $filespec_dst] } {
    sproc_msg -error "sproc_xfer: unable to delete destination file $filespec_dst prior to copy"
  } else {
    file mkdir [file dirname $filespec_dst]
    if { $options(-link) } {
      file link $filespec_dst [file normalize $filespec_src]
    } else {
      ## file copy -force $filespec_src $filespec_dst
      set cmd "$cp_cmd $filespec_src $filespec_dst"
      eval exec $cmd
      set cmd "chmod -R +w $filespec_dst"
      eval exec $cmd
    }
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_xfer \
  -info "Procedure for transferring data to and from work directories." \
  -define_args {
  {-f      "Specifies the name of the file to transfer." AString string optional}
  {-d      "Specifies the name of the dir to transfer." AString string optional}
  {-rename "Allows renaming of the file or dir being transferred." AString string optional}
  {-link   "If set to 1, the file (or directory) is linked, instead of copied." AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
}

## -----------------------------------------------------------------------------
## sproc_which:
## -----------------------------------------------------------------------------

proc sproc_which { args } {

  global env SEV SVAR TEV

  sproc_pinfo -mode start

  ## -------------------------------------
  ## The behavior of the 'which' command is not
  ## completely uniform across all platforms.
  ## This procedure provides a standard method that is used across the flow
  ## and can be easily modified if system specific alterations are required.
  ## -------------------------------------

  set options(-app) ""

  parse_proc_arguments -args $args options

  set cmd "which $options(-app)"
  catch { exec $SEV(exec_cmd) -c "$cmd" } results

  if { [regexp $options(-app) [lindex $results 0]] } {
    set return_value [lindex $results 0]
  } else {
    set return_value NULL
    sproc_msg -error "sproc_which: Unable to locate: $options(-app)"
  }

  sproc_msg -info "sproc_which: return value: $return_value"

  sproc_pinfo -mode stop
  return $return_value
}

define_proc_attributes sproc_which \
  -info "Returns the full path to the specified application." \
  -define_args {
  {-app "The application to locate." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_uniquify_list:
## -----------------------------------------------------------------------------

proc sproc_uniquify_list { args } {

  set options(-list) ""
  parse_proc_arguments -args $args options

  set output_list [list]

  foreach element $options(-list) {
    if { ![info exists list_of_found_elements($element)] } {
      set list_of_found_elements($element) 1
      lappend output_list $element
    }
  }

  return $output_list
}

define_proc_attributes sproc_uniquify_list \
  -info "Returns a list with no duplicate elements." \
  -define_args {
  {-list "Input list needing to be uniquified." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_cat_file:
## -----------------------------------------------------------------------------

proc sproc_cat_file { args } {

  sproc_pinfo -mode start

  set options(-file) ""
  parse_proc_arguments -args $args options

  set cnt 0
  set limit 100
  while { ![file exists $options(-file)] && ( $cnt < $limit ) } {
    incr cnt
    after 1000
    sproc_msg -warning "Waiting for file: $options(-file)"
    sproc_msg -warning "Loop interation $cnt of $limit at [date]"
  }

  if { [file exists $options(-file)] } {
    set fid [open $options(-file) r]
    while { [gets $fid line] >= 0 } {
      puts $line
    }
    close $fid
  } else {
    sproc_msg -error "File argument to sproc_cat_file '$options(-file)' does not exist."
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_cat_file \
  -info "Cats specified file to logfile." \
  -define_args {
  {-file  "The file to cat to logfile." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_printvars:
## -----------------------------------------------------------------------------

proc sproc_printvars { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global SNPS_tool
  global SNPS_vars_to_print

  set options(-filename) ""
  set options(-tool) 0
  set options(-env) 0
  set options(-SEV) 0
  set options(-SVAR) 0
  set options(-TEV) 0

  parse_proc_arguments -args $args options

  if { $options(-filename) != "" } {
    set fid [open $options(-filename) w]
  } else {
    set fid stdout
  }

  ## -------------------------------------
  ## Define tool variables to print
  ## -------------------------------------

  set SNPS_vars_to_print [list]
  lappend SNPS_vars_to_print search_path
  lappend SNPS_vars_to_print link_library
  lappend SNPS_vars_to_print target_library
  lappend SNPS_vars_to_print synthetic_library

  ## -------------------------------------
  ## Grab variables from the context from which this procedure was invoked.
  ## -------------------------------------

  array set tmp_env  [array get env]
  array set tmp_SEV  [array get SEV]
  array set tmp_SVAR [array get SVAR]
  array set tmp_TEV  [array get TEV]

  uplevel #0 {
    foreach var $SNPS_vars_to_print {
      if { [info exists $var] } {
        eval set SNPS_tool($var) \$$var
      }
    }
  }

  ## -------------------------------------
  ## Now print the variables that were just grabbed.
  ## -------------------------------------

  puts $fid "## [string repeat "-" 77]"
  puts $fid "## Start of variable printing."
  puts $fid "## [string repeat "-" 77]"

  if { $options(-tool) } {
    puts $fid "## [string repeat "-" 77]"
    puts $fid "## Tool variable settings"
    puts $fid "## [string repeat "-" 77]"
    set name_list [lsort [array names SNPS_tool]]
    foreach name $name_list {
      set length [llength $SNPS_tool($name)]
      if { $length == 0 } {
        puts $fid "set $name \"\""
      } elseif { $length == 1 } {
        puts $fid "set $name $SNPS_tool($name)"
      } else {
        puts -nonewline $fid "set $name \{ "
        foreach item $SNPS_tool($name) {
          if { [llength $item] > 1 } {
            puts -nonewline $fid "\{ $item \} "
          } else {
            puts -nonewline $fid "$item "
          }
        }
        puts $fid "\}"
      }
    }
  }

  if { $options(-SEV) } {
    puts $fid "## [string repeat "-" 77]"
    puts $fid "## SEV variable settings"
    puts $fid "## [string repeat "-" 77]"
    set name_list [lsort [array names tmp_SEV]]
    foreach name $name_list {
      set length [llength $tmp_SEV($name)]
      if { $length == 0 } {
        puts $fid "set SEV\($name\) \"\""
      } elseif { $length == 1 } {
        puts $fid "set SEV\($name\) $tmp_SEV($name)"
      } else {
        puts -nonewline $fid "set SEV\($name\) \{ "
        foreach item $tmp_SEV($name) {
          if { [llength $item] > 1 } {
            puts -nonewline $fid "\{ $item \} "
          } else {
            puts -nonewline $fid "$item "
          }
        }
        puts $fid "\}"
      }
    }
  }

  if { $options(-SVAR) } {
    puts $fid "## [string repeat "-" 77]"
    puts $fid "## SVAR variable settings"
    puts $fid "## [string repeat "-" 77]"
    set name_list [lsort [array names tmp_SVAR]]
    foreach name $name_list {

      set length [llength $tmp_SVAR($name)]
      if { $length == 0 } {
        puts $fid "set SVAR\($name\) \"\""
      } elseif { $length == 1 } {

        if { [regexp {\[} $tmp_SVAR($name)] } {
          puts $fid "set SVAR\($name\) \{$tmp_SVAR($name)\}"
        } else {
          puts $fid "set SVAR\($name\) $tmp_SVAR($name)"
        }

      } else {
        puts -nonewline $fid "set SVAR\($name\) \{ "
        foreach item $tmp_SVAR($name) {
          if { [llength $item] > 1 } {
            puts -nonewline $fid "\{ $item \} "
          } else {
            puts -nonewline $fid "$item "
          }
        }
        puts $fid "\}"
      }
    }
  }

  if { $options(-TEV) } {
    puts $fid "## [string repeat "-" 77]"
    puts $fid "## TEV variable settings"
    puts $fid "## [string repeat "-" 77]"
    set name_list [lsort [array names tmp_TEV]]
    foreach name $name_list {
      set length [llength $tmp_TEV($name)]
      if { $length == 0 } {
        puts $fid "set TEV\($name\) \"\""
      } elseif { $length == 1 } {
        puts $fid "set TEV\($name\) $tmp_TEV($name)"
      } else {
        puts -nonewline $fid "set TEV\($name\) \{ "
        foreach item $tmp_TEV($name) {
          if { [llength $item] > 1 } {
            puts -nonewline $fid "\{ $item \} "
          } else {
            puts -nonewline $fid "$item "
          }
        }
        puts $fid "\}"
      }
    }
  }

  if { $options(-env) } {
    puts $fid "## [string repeat "-" 77]"
    puts $fid "## Shell variable settings"
    puts $fid "## [string repeat "-" 77]"
    set name_list [lsort [array names tmp_env]]
    foreach name $name_list {
      puts $fid "setenv $name '$tmp_env($name)'"
    }
  }

  puts $fid "## [string repeat "-" 77]"
  puts $fid "## End of variable printing."
  puts $fid "## [string repeat "-" 77]"

  if { $options(-filename) != "" } {
    close $fid
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_printvars \
  -info "Procedure for printing variables." \
  -define_args {
  {-filename "Name of file for output information" AString string optional}
  {-tool  "Print tool variables" "" boolean optional}
  {-env   "Print Shell variables" "" boolean optional}
  {-SEV   "Print SEV variables" "" boolean optional}
  {-SVAR  "Print SVAR variables" "" boolean optional}
  {-TEV   "Print TEV variables" "" boolean optional}
}

## -----------------------------------------------------------------------------
## sproc_multiline_grep:
## -----------------------------------------------------------------------------

proc sproc_multiline_grep { args } {

  sproc_pinfo -mode start

  set options(-v) 0
  set options(-output) NULL
  set options(-add_error_msg) 0

  parse_proc_arguments -args $args options
  set file         $options(-file)
  set grep_string  $options(-grep_string)
  set inverse $options(-v)

  if { $options(-output) != "NULL" } {
    set standard_out 0
    file delete -force $options(-output)
    set wid [open $options(-output)   w]
  } else {
    set standard_out 1
  }

  set rid [open $file  r]

  set return_status 0
  set lcnt 0
  set match_found 0
  while { [gets $rid line] >= 0 } {
    incr lcnt
    set full_line($lcnt) $line
    if { [regexp "$grep_string" $line] } {
      set match_found 1
    }
    if { ![regexp {\\$} $line] } {
      if { ($match_found && !$inverse) || (!$match_found && $inverse) } {
        for {set i 1} {$i <= $lcnt } {incr i} {
          if { $standard_out } {
            if { $options(-add_error_msg) } {
              sproc_msg -error $full_line($i)
            } else {
              puts $full_line($i)
            }
          } else {
            puts $wid $full_line($i)
          }
        }
        set return_status 1
      }
      set lcnt 0
      set match_found 0
    }
  }

  close $rid
  if { !$standard_out } {
    close $wid
  }
  sproc_pinfo -mode stop
  return $return_status
}

define_proc_attributes sproc_multiline_grep \
  -info "grep lines containing a string even if the line spans multiple lines." \
  -define_args {
  {-file "input file" AString string required}
  {-output "output file" AString string optional}
  {-grep_string "string to match" AString string required}
  {-v "output lines that dont match only" "" boolean optional}
  {-add_error_msg "echo an error message on match" "" boolean optional}
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
## sproc_broadcast_decision:
## -----------------------------------------------------------------------------

proc sproc_broadcast_decision { args } {

  global env SEV SVAR TEV

  set options(-decision) ""
  parse_proc_arguments -args $args options

  ## Write decision to log file, as a metric.

  sproc_msg -info "METRIC | INTEGER INFO.DECISION | $options(-decision)"

  ## Write decision to dec file.

  set dec_file [file rootname $SEV(log_file)].dec
  set fid [open $dec_file w]
  puts $fid "SNPS_INFO: METRIC | INTEGER INFO.DECISION | $options(-decision)"
  close $fid

}

define_proc_attributes sproc_broadcast_decision \
  -info "Standard procedure for communicating decision information to the RTM." \
  -define_args {
  {-decision "Specifies the decision value to communicate to the RTM." AnInt int required}
}

## -----------------------------------------------------------------------------
## sproc_refresh_file_system:
## -----------------------------------------------------------------------------

proc sproc_refresh_file_system { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV

  set options(-dir) ""

  parse_proc_arguments -args $args options

  if { [file isdirectory $options(-dir)] } {
    ## sproc_msg -info "sproc_refresh_file_system: Refreshing directory: '$options(-dir)'"
    catch { exec ls -al $options(-dir) }
  } else {
    sproc_msg -error "sproc_refresh_file_system: The directory specified does not exist: '$options(-dir)'"
  }

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_refresh_file_system \
  -info "Provides a standard way to for an NFS file system refresh." \
  -define_args {
  {-dir "The directory to refresh." AString string required}
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
## sproc_script_stop:
## -----------------------------------------------------------------------------

proc sproc_script_stop { args } {

  global LYNX
  global env SEV SVAR TEV
  global sh_product_version
  global synopsys_program_name

  set options(-exit) 0
  set options(-mem_mb) -1
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Generate end-of-script metrics.
  ## -------------------------------------

  sproc_metric_time -stop
  sproc_metric_system -end_of_script -mem_mb $options(-mem_mb)

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
        } elseif { $synopsys_program_name == "vcst" } {
          ## avoid auto session saving
          exit -force
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
  {-exit   "Perform an exit." "" boolean optional}
  {-mem_mb "The amount of memory used by the task. (Integer number of MBs)" AnInt int optional}
}

## -----------------------------------------------------------------------------
## sproc_rpt_start:
## -----------------------------------------------------------------------------

proc sproc_rpt_start {} {
  global SNPS_rpt_time_start

  set SNPS_rpt_time_start [clock seconds]
}

define_proc_attributes sproc_rpt_start \
  -info "Called at start of report processing. Used for metrics generation." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_rpt_stop:
## -----------------------------------------------------------------------------

proc sproc_rpt_stop { args } {
  global SNPS_rpt_time_start SNPS_rpt_time_stop SNPS_rpt_time_elapsed

  parse_proc_arguments -args $args options

  set SNPS_rpt_time_stop [clock seconds]

  set SNPS_rpt_time_elapsed [expr $SNPS_rpt_time_stop - $SNPS_rpt_time_start]
  set dhms [sproc_metric_time_elapsed -start $SNPS_rpt_time_start -stop $SNPS_rpt_time_stop]
  sproc_msg -info "METRIC | TIME INFO.ELAPSED_TIME.REPORT | $SNPS_rpt_time_elapsed"
  sproc_msg -info "INFO.ELAPSED_TIME.REPORT | $dhms"
}

define_proc_attributes sproc_rpt_stop \
  -info "Called at stop of report processing. Used for metrics generation." \
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
    sproc_msg -info "METRIC | TAG SYS.TAG_20 | $SVAR(tag_20)"

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
      gca_shell {
        set mem_kb [mem]
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
        if { [regexp {^\s+} $line] } {
          set the_license [regsub -all {\s} $line {}]
          lappend license_list $the_license
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
        }
        if { [regexp {^\s+} $line] } {
          set the_license [regsub -all {\s} $line {}]
          lappend license_list $the_license
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
    ## Flow Summary - Generate the data
    ## -------------------------------------

    set lynx_resource_name_list [list]
    unset -nocomplain lynx_resource_value

    set name "Host"
    set value [exec uname -n]
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    set name "Tool"
    set value $synopsys_program_name
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    set name "Cores"
    set value $TEV(num_cores)
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    set wall_time [expr $SNPS_time_stop - $SNPS_time_start]
    set name "Wall Time"
    set value $wall_time
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

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
    set name "CPU Time"
    set value $cputime_s
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    set name "CPU Efficiency"
    set value $cputime_e
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    if { $memory_used == "NaM" } {
      set value_m NA
    } else {
      set value_m $memory_used
    }
    set name "Mem"
    set value $value_m
    lappend lynx_resource_name_list $name
    set lynx_resource_value($name) $value

    ## -------------------------------------
    ## Flow Summary - Create Resource Report
    ## -------------------------------------

    set file $SEV(rpt_dir)/.$SEV(task).lynx_task

    file delete -force $file

    set fid [open $file w]

    puts $fid "flow_order|$SEV(flow_order)"
    foreach lynx_resource_name $lynx_resource_name_list {
      puts $fid "$lynx_resource_name|$lynx_resource_value($lynx_resource_name)"
    }

    close $fid

    ## -------------------------------------
    ## Flow Summary - Create JSON output for QV
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

      set dv_output [list]

      foreach lynx_resource_name $lynx_resource_name_list {
        set fs_output [sproc_qv_flow_summary -o $fs_output -name $lynx_resource_name -value $lynx_resource_value($lynx_resource_name)]
        lappend dv_output [list $name $value]
      }

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

    set fid [open $SEV(rpt_dir)/$SEV(task).report_resource_summary w]
    puts $fid [sproc_report_info]
    foreach item $dv_output {
      set name  [lindex $item 0]
      set value [lindex $item 1]
      puts $fid "$name : $value"
    }
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
## sproc_get_metric_value:
## -----------------------------------------------------------------------------

## -------------------------------------
## Given a source directory, task, and metric name,
## return the value of the metric by extracting it from
## the .task.metrics.record file in the logs/source directory.
## -------------------------------------

proc sproc_get_metric_value { args } {

  sproc_pinfo -mode start

  set options(-source) ""
  set options(-task) ""
  set options(-metric) ""
  parse_proc_arguments -args $args options

  set value ""
  set error 0

  if {$options(-metric) == "" } {
    sproc_msg -error "sproc_get_metric_value: option -metric must be specified"
    incr error
  }

  if { $options(-source) == "" } {
    sproc_msg -error "sproc_get_metric_value: option -source must be specified"
    incr error
  } elseif { ![file isdir ../logs/$options(-source)] } {
    sproc_msg -error "sproc_get_metric_value: Specified source log directory ../logs/$options(-source) does not exist"
    incr error
  }

  if { $options(-task) == "" } {
    sproc_msg -error "sproc_get_metric_value: option -task must be specified"
    incr error
  } else {
    set metric_file ../logs/$options(-source)/.$options(-task).metrics.record
    if { ![file exists $metric_file] } {
      sproc_msg -error "sproc_get_metric_value: Metrics file ($metric_file) for source $options(-source) and task $options(-task) does not exist"
      incr error
    }
  }

  if {$error == 0 } {
    set fid [open $metric_file r]
    while { [gets $fid line] >= 0 } {
      set tmp [split $line "|"]
      if { [lindex $tmp 0] == $options(-metric) } {
        set value [lindex $tmp 2]
        continue
      }
    }
    close $fid
    if { $value == "" } {
      sproc_msg -error "Cannot find metric $options(-metric) for source $options(-source) and task $options(-task)"
    } else {
      sproc_msg -info "Found metric $options(-metric) with value $value for source $options(-source) and task $options(-task)"
    }
  }

  sproc_pinfo -mode stop

  return $value
}

define_proc_attributes sproc_get_metric_value \
  -info "Return the value of a metric for a specified source directory and task" \
  -define_args {
  {-source "The source directory from which to extract the metric." AString string required}
  {-task "The task script that generated the metric." AString string required}
  {-metric "The metric to extract" AString string required}
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
      ## set line {## HEADER $Id: //sps/lynx/ds_tmp/scripts_global/10_syn/dc_elaborate.tcl#4}
      ## -------------------------------------

      set re {^## HEADER \$Id: [\w\/\.]+#([\d]+)}

      if { [regexp $re $line match version] } {
        break
      }

      ## -------------------------------------
      ## CVS format example:
      ## set line {## HEADER $Id: tool_launch_part1.make,v 1.2 2010/04/02 21:34:44 gamble Exp}
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
## sproc_write_side_file
## -----------------------------------------------------------------------------

proc sproc_write_side_file { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global SF SF_INIT side_file_src

  set side_file $SEV(dst_dir)/$SVAR(design_name).side_file
  if { $SEV(src_dir) != $SEV(dst_dir) } {
    file delete -force $side_file
    if { $side_file_src!="" && [file exists $side_file_src] } {
      file copy $side_file_src $side_file
    }
  }

  set fid [open $side_file a]

  puts $fid "## $SEV(step)/$SEV(task) on [date]"
  foreach name [lsort [array names SF]] {
    ## only output new or different
    if { [info exists SF_INIT($name)] && $SF($name)!=$SF_INIT($name) || ![info exists SF_INIT($name)] } {
      puts $fid "set SF($name) \"$SF($name)\""
    }
  }

  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_write_side_file \
  -info "Called to write a side file of variables for tracking flow information." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_read_side_file
## -----------------------------------------------------------------------------

proc sproc_read_side_file { args } {

  sproc_pinfo -mode start

  global env SEV SVAR TEV
  global synopsys_program_name
  global SF SF_INIT side_file_src

  ## -------------------------------------
  ## Formal verification source comes from TEV(imp).
  ## This is an exception for normal processing.
  ## -------------------------------------

  if { ($synopsys_program_name == "fm_shell") && [info exists TEV(imp)] && $TEV(imp)!="" } {
    set side_file $SEV(block_dir)/$SEV(step)/work/$TEV(imp)/$SVAR(design_name).side_file
  } else {
    set side_file $SEV(block_dir)/$SEV(step)/work/$SEV(src)/$SVAR(design_name).side_file
  }

  sproc_msg -info "The side file is: '$side_file'"
  set side_file_src $side_file

  ## -------------------------------------
  ## Source the side_file.
  ## -------------------------------------

  if { [file exists $side_file] } {
    sproc_source -file $side_file
  } else {
    sproc_msg -warning "Unable to identify side file"
  }

  ## -------------------------------------
  ## Print the SF() variables.
  ## -------------------------------------

  foreach name [lsort [array names SF]] {
    sproc_msg -info "SF($name) : $SF($name)"
    ## remember initial SF vars
    set SF_INIT($name) $SF($name)
  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_read_side_file \
  -info "Called to read a side file of variables for tracking flow information." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_report_info
## -----------------------------------------------------------------------------

proc sproc_report_info { args } {
  global SEV

  set enabled 0

  if { $enabled } {

    set sev_name_list [list flow_order step dst task]
    set msg ""

    foreach sev_name $sev_name_list {
      if { $msg == "" } {
        set msg "SEV($sev_name) : $SEV($sev_name)"
      } else {
        set msg "$msg\nSEV($sev_name) : $SEV($sev_name)"
      }
    }

    puts $msg
    return $msg

  } else {

    return

  }
}

define_proc_attributes sproc_report_info \
  -info "Called to produce information for inclusion in report output." \
  -define_args {
}

## -----------------------------------------------------------------------------
## Source additional procedure definitions
## -----------------------------------------------------------------------------

if { [info exists SEV(pt_dmsa_slave)] } {
  ## pt slaves have the SEVs already set
  set scripts_global $SEV(gscript_dir)
} else {
  ## Normal location relative to tmp_dir
  set scripts_global [pwd]/../../scripts_global
}

sproc_source -file $scripts_global/conf/procs_metrics.tcl
sproc_source -file $scripts_global/conf/procs_flow.tcl
sproc_source -file $scripts_global/conf/procs_qor.tcl
sproc_source -file $scripts_global/conf/procs_lwrap.tcl
sproc_source -file $scripts_global/conf/procs_user.tcl

puts "SNPS_INFO   : SCRIPT_STOP  : [file normalize ../../scripts_global/conf/procs.tcl] : [date]"

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
