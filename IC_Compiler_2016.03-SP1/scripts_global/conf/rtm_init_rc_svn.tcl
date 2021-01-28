## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_init_rc_svn.tcl#44 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file is sourced by the RTM on startup and contains the following:
## * - Procedures used by the RTM.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## rtm_rc_method
## -----------------------------------------------------------------------------

proc rtm_rc_method {} {

  global env SEV SVAR TEV

  set rc_method $SEV(rc_method)

  if { ![info exists ::env(SVNROOT)] } {
    return -code error "rtm_rc_method: SVN selected, but SVNROOT not set."
  }
  if { [catch {exec svn list $::env(SVNROOT) >&/dev/null}] } {
    return -code error "rtm_rc_method: SVN selected, but SVNROOT directory does not exist."
  }

  return $rc_method
}

define_proc_attributes rtm_rc_method \
  -info "Customizable procedure for defining RC method and peforming basic RC checks." \
  -hidden \
  -define_args {
}

## -----------------------------------------------------------------------------
## rtm_rc_file:
## -----------------------------------------------------------------------------

proc rtm_rc_file { args } {

  global env SEV SVAR TEV

  set options(-file) ""
  set options(-op)   ""

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Define the RC system being used and perform some basic checks.
  ## -------------------------------------

  if { [ catch { rtm_rc_method } rc_method ] } {
    return -code error $rc_method
  }

  ## -------------------------------------
  ## Make sure the file exists.
  ## -------------------------------------

  if { ![file exists $options(-file)] || ![file isfile $options(-file)] } {
    return -code error "rtm_rc_file: File does not exist: $options(-file)"
  } else {
    ## Resolve symbolic links

    set fail_status [catch { file link $options(-file) }]
    if { $fail_status } {
      set real_file [file normalize $options(-file)]
    } else {
      set real_file [file link $options(-file)]
    }

  }

  if { $options(-op) == "co" } {

    ## -------------------------------------
    ## File "check out"
    ## -------------------------------------

    puts stderr "rtm_rc_file: Checking out file '$real_file'"

    set make_writable 0
    catch {exec svn status -u $real_file } status
    if { $status != "" } {
      if {[regexp ".+$real_file" $status m]} {
        set status [lindex $m 0]
      } else {
        set status ""
      }
    }
    switch $status {
      "M" {
        return -code error "rtm_rc_file: File is locally modified, so no checkout performed. You must resolve the changes first."
      }
      "*" {
        puts stderr "rtm_rc_file: File is not up to date, so updating file."
        if { [catch { exec svn update $real_file } out] } {
          return -code error "rtm_rc_file: $out"
        }
        set make_writeable 1
      }
      "" {
        puts stderr "rtm_rc_file: File is up to date, so no action required."
        set make_writeable 1
      }
      default {
        return -code error "rtm_rc_file: File status is '$status', so no action possible."
      }
    }
    if { $make_writeable } {
      puts stderr "rtm_rc_file: Adding write permissions."
      if { [catch { exec chmod +w $real_file } out] } {
        return -code error "rtm_rc_file: $out"
      }
    }

  } else {

    ## -------------------------------------
    ## File "check in"
    ## -------------------------------------

    ## This function not used.

  }

  return
}

define_proc_attributes rtm_rc_file \
  -info "Customizable procedure for file revision control." \
  -hidden \
  -define_args {
  {-file "File name" AString string required}
  {-op   "File operation to perform." AnOos one_of_string
  {optional value_help {values { ci co }}}}
}

## -----------------------------------------------------------------------------
## rtm_rc_files_status:
## -----------------------------------------------------------------------------

proc rtm_rc_files_status { args } {

  global env SEV SVAR TEV

  set options(-rtm_gui) 0

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Define the RC system being used and perform some basic checks.
  ## -------------------------------------

  if { [ catch { rtm_rc_method } rc_method ] } {
    return -code error $rc_method
  }

  ## -------------------------------------
  ## Determine the list of files to check.
  ##
  ## If invoked from the RTM GUI, check scripts_global and
  ## every block's scripts_block.
  ##
  ## If invoked from a script, check scripts_global and
  ## only the current block's scripts_block.
  ## -------------------------------------

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$SEV(techlib_name)
  }

  if { $options(-rtm_gui) } {
    set rc_report_file ./.rc_report_file
    set block_dir_list [glob -nocomplain -types d $block_root/*]
  } else {
    set rc_report_file [file rootname [file normalize $SEV(log_file)]].rc_report_file
    set block_dir_list [glob -nocomplain -types d $block_root/$SEV(block_name)]
  }
  set files [list]
  set files [concat $files [exec find $SEV(workarea_dir)/scripts_global -type f]]
  foreach block_dir $block_dir_list {
    if { [file tail $block_dir] == ".svn" } {
      continue
    } else {
      set files [concat $files [exec find $block_dir/scripts_block -type f]]
    }
  }

  ## -------------------------------------
  ## Generate the RC status report.
  ## -------------------------------------

  set fid [open $rc_report_file w]

  set file_changes 0
  foreach file $files {
    if { [regexp {/\.svn/} $file] } {
      ## This is a SVN repository file, so skip it.
      continue
    }
    catch { exec svn status -u $file } status
    if { $status != "" } {
      if {[regexp ".+$file" $status m]} {
        set status [lindex $m 0]
      } else {
        set status ""
      }
    }
    switch $status {
      "?" {
        puts $fid "SNPS_WARNING: Not under revision control: $file"
      }
      "" {
        ## puts $fid "SNPS_INFO: Up to date: $file"
      }
      "M" {
        incr file_changes
        puts $fid "SNPS_WARNING: Locally modified: $file"
      }
      "*" {
        incr file_changes
        puts $fid "SNPS_ERROR: Out of date: $file"
      }
      default {
        puts $fid "SNPS_WARNING: Unknown status '$status': $file"
      }
    }
  }
  if { !$file_changes } {
    puts $fid "SNPS_INFO: All files up to date."
  }

  close $fid

  ## -------------------------------------
  ## If invoked from the RTM GUI, display the report.
  ## If invoked from a script, echo the report contents to the log file.
  ## -------------------------------------

  if { $options(-rtm_gui) } {
    set window_name "RC Status ([file tail $SEV(workarea_dir)])"
    set cmd "xterm -T \"$window_name\" -e $SEV(exec_cmd) -c \"more $rc_report_file; read\""
    catch { eval exec $cmd } out
  } else {
    set fid [open $rc_report_file r]
    set rc_report_file_text [read $fid]
    close $fid
    puts $rc_report_file_text
  }

  cd $savepwd
}

define_proc_attributes rtm_rc_files_status \
  -info "Customizable procedure to present revision control system status." \
  -hidden \
  -define_args {
  {-rtm_gui "Indicates that procedure is being invoked from the RTM GUI." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_rc_files_checkin:
## -----------------------------------------------------------------------------

proc rtm_rc_files_checkin {} {

  global env SEV SVAR TEV

  ## -------------------------------------
  ## Define the RC system being used and perform some basic checks.
  ## -------------------------------------

  if { [ catch { rtm_rc_method } rc_method ] } {
    return -code error $rc_method
  }

  ## -------------------------------------
  ## SVN requires that the current working directory be a checked-out directory,
  ## or we have to supply the name of the directory to check-in.
  ## Since the cwd is not a checked-out directory, we do a commit
  ## on each of the top-level directories for blocks/ and scripts_global/.
  ## Note that svn commit on a directory that has no changes has no effect. (i.e is OK)
  ## -------------------------------------

  set savepwd [pwd]
  cd $SEV(workarea_dir)
  if { [info exists env(LYNX_LCRM_MODE)] } {
    set block_root ./
  } else {
    set block_root ./blocks/$SEV(techlib_name)
  }

  set block_dir_list [glob -nocomplain -types d $block_root/*]

  set files ./scripts_global

  foreach block_dir $block_dir_list {
    if { [file tail $block_dir] == ".svn" } {
      continue
    } else {
      set files [concat $files $block_dir/scripts_block]
    }
  }

  ## -------------------------------------
  ## Checkin each directory
  ## -------------------------------------

  foreach file $files {
    if { [regexp {/\.svn/} $file] } {
      ## This is a SVN repository file, so skip it.
      continue
    }
    puts "svn commit $file"
    set window_name "RC CheckIn ([file tail $SEV(workarea_dir)])"
    set cmd "xterm -T \"$window_name\" -e $SEV(exec_cmd) -c \"svn commit $file\""
    catch { eval exec $cmd } out
  }

  cd $savepwd
}

define_proc_attributes rtm_rc_files_checkin \
  -info "Customizable procedure for checking in all open files in revision control system." \
  -hidden \
  -define_args {
}

## -----------------------------------------------------------------------------
## rtm_rc_files_update:
## -----------------------------------------------------------------------------

proc rtm_rc_files_update {} {

  global env SEV SVAR TEV

  set savepwd [pwd]
  cd $SEV(workarea_dir)

  ## -------------------------------------
  ## Define the RC system being used and perform some basic checks.
  ## -------------------------------------

  if { [ catch { rtm_rc_method } rc_method ] } {
    return -code error $rc_method
  }

  ## -------------------------------------
  ## Present dialog for user.
  ## Do this for each directory in workarea than contains a ".svn" file.
  ## -------------------------------------

  set svn_files [glob -nocomplain */.svn]
  set svn_dirs ""
  foreach file $svn_files {
    set svn_dirs "$svn_dirs [file dirname $file]"
  }

  set window_name "RC Update ([file tail $SEV(workarea_dir)])"
  if {$svn_dirs != "" } {
    set xterm_cmd "svn update $svn_dirs"
  } else {
    set xterm_cmd "echo \"No files in workarea are under SVN control\""
  }
  set cmd "xterm -T \"$window_name\" -e $SEV(exec_cmd) -c \"$xterm_cmd ; read\""

  catch { eval exec $cmd } out

  cd $savepwd
}

define_proc_attributes rtm_rc_files_update \
  -info "Customizable procedure for updating files from revision control system." \
  -hidden \
  -define_args {
}

## -----------------------------------------------------------------------------
## rtm_rc_files_checkin_dir
## -----------------------------------------------------------------------------

proc rtm_rc_files_checkin_dir { args } {

  global env SEV SVAR TEV

  set savepwd [pwd]
  cd $SEV(workarea_dir)

  set options(-dir) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Define the RC system being used and perform some basic checks.
  ## -------------------------------------

  if { [ catch { rtm_rc_method } rc_method ] } {
    return -code error $rc_method
  }

  ## -------------------------------------
  ## Do the work.
  ## -------------------------------------

  cd $SEV(workarea_dir)
  set options(-dir) [regsub "$SEV(workarea_dir)/" $options(-dir) {}]

  if { ![file isdirectory $options(-dir)] } {
    return -code error "rtm_rc_files_checkin_dir: Directory does not exist."
  }

  set blockname [file tail $options(-dir) ]
  puts stderr "rtm_rc_files_checkin_dir: Importing files from $options(-dir)"

  set cmd "svn_setup.tcl $options(-dir)"
  puts $cmd
  catch { eval exec $cmd } out
  puts stderr $out

  puts stderr "rtm_rc_files_checkin_dir: Performing delete and SVN checkout for block $blockname"
  file delete -force $options(-dir)

  ## Change to block directory and make a checkout of the new block
  cd  blocks/$SEV(techlib_name)
  set cmd "svn -q co $env(SVNROOT)/blocks/$SEV(techlib_name)/$blockname"
  puts $cmd
  catch { eval exec $cmd } out
  puts stderr $out

  cd $savepwd
}

define_proc_attributes rtm_rc_files_checkin_dir \
  -info "Customizable procedure for checking a directory of files into a revision control system." \
  -hidden \
  -define_args {
  {-dir "The directory specification." AString string required}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
