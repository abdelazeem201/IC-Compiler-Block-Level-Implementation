## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/tool_wrapper.tcl#91 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script is only used when executing tasks via the rtm_shell.
## * The rtm_shell must set all SEV shell variables used by this script.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Provide information about the process ID
## -----------------------------------------------------------------------------

## -------------------------------------
## This is the old method
## -------------------------------------

puts "PID <[pid]>"

## -------------------------------------
## This is the new method
## -------------------------------------

source $env(LYNX_VARFILE_SEV)
set file_part_org [file tail $SEV(log_file)]
set dir_part_org  [file dirname $SEV(log_file)]
set file_part_new .[file rootname $file_part_org].pid
set pid_file $dir_part_org/$file_part_new

set fid [open $pid_file w]
puts $fid "PID [exec uname -n] [pid] EOL"
close $fid

## -----------------------------------------------------------------------------
## Define a needed command if not already available.
## -----------------------------------------------------------------------------

if { [info command date] != "date" } {
  proc date {} {
    return [clock format [clock seconds] -format {%a %b %e %H:%M:%S %Y}]
  }
}

## -----------------------------------------------------------------------------
## Create special strings.
## -----------------------------------------------------------------------------

catch { set snps_error [join {SNPS ERROR} _] }

## -----------------------------------------------------------------------------
## Print script entry message.
## -----------------------------------------------------------------------------

puts "SNPS_INFO   : SCRIPT_START : [file normalize ../../scripts_global/conf/tool_wrapper.tcl] : [date]"

## -----------------------------------------------------------------------------
## LYNX_RTM_CHECK_ONLY: If true, only the rtm_check is being run.
## -----------------------------------------------------------------------------

if { [info exists env(LYNX_RTM_CHECK_ONLY)] } {
  set rtm_check_only_flag 1
  set rtm_check_only_logfile $env(LYNX_RTM_CHECK_ONLY)
} else {
  set rtm_check_only_flag 0
}

## -----------------------------------------------------------------------------
## Send message to RTM to indicates that this task has started.
## -----------------------------------------------------------------------------

set ok 0

if { [info exists env(LYNX_SOCKET_HOST)] } {
  set socket_host $env(LYNX_SOCKET_HOST)
  incr ok
} else {
  puts "SNPS_ERROR : Environment variable not set: LYNX_SOCKET_HOST"
}

if { [info exists env(LYNX_SOCKET_PORT)] } {
  set socket_port $env(LYNX_SOCKET_PORT)
  incr ok
} else {
  puts "SNPS_ERROR : Environment variable not set: LYNX_SOCKET_PORT"
}

if { [info exists env(LYNX_SOCKET_RUNNING)] } {
  set socket_object $env(LYNX_SOCKET_RUNNING)
  incr ok
} else {
  puts "SNPS_ERROR : Environment variable not set: LYNX_SOCKET_RUNNING"
}

if { $ok == 3 } {

  if { [file exists $env(SYNOPSYS_RTM)/auxx/rtm/rtm_touch.tcl] } {

    if { [info exists env(LYNX_DEBUG_RTM_SEQ2_FAIL)] && ($env(LYNX_DEBUG_RTM_SEQ2_FAIL) == "1") } {
      set socket_object [regsub {\.touch1$} $socket_object {.touch2}]
    }

    exec $env(SYNOPSYS_RTM)/auxx/rtm/rtm_touch.tcl $socket_host $socket_port $socket_object

  } else {

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
      puts "SNPS_ERROR : Unable to create socket ($socket_host:$socket_port) from [info host] to RTM"
      puts "SNPS_ERROR : Socket returns $socket_channel"
    } else {

      fconfigure $socket_channel -blocking 1

      puts $socket_channel "$socket_object"

      flush $socket_channel
      close $socket_channel

    }

  }

}

## -----------------------------------------------------------------------------
## Define procedures needed for this file.
## -----------------------------------------------------------------------------

if { ![info exists synopsys_program_name] } {
  if { [info commands db::getAttr] == "::db::getAttr" } {
    set synopsys_program_name cdesigner
  } else {
    set synopsys_program_name tcl
  }
}

proc sproc_interactive_tcl {} {

  global snps_error

  ## If tcl_shell is being used, there is no need to run this procedure.
  if { [info exists ::Lynx:TclShell] } {
    return
  }

  while { 1 } {
    puts -nonewline "% "

    flush stdout

    ## Read the command from standard input

    set cmd [gets stdin]

    if { [eof stdin] } { return }

    ## -------------------------------------
    ## If the command is not a complete TCL script,
    ## (ie, balanced quotes, curly braces, square braces, etc)
    ## keep looping until it completes or we run out of input.
    ## -------------------------------------

    while { ![info complete $cmd] } {
      append cmd "\n"
      append cmd [gets stdin]

      if { [eof stdin] } { return }
    }

    ## -------------------------------------
    ## Good, we made it this far, so execute the command!
    ## Generate an error message if the command fails.
    ## -------------------------------------

    if { [catch { uplevel #0 $cmd } err] } {
      puts "$snps_error  : $err"
    }
  }

  return
}

## -----------------------------------------------------------------------------
## Take appropriate actions based on the variables
## $env(SEV_DONT_RUN) and $env(SEV_DONT_EXIT).
## -----------------------------------------------------------------------------

if { $rtm_check_only_flag } {

  ## rtm_check_only_logfile:
  ##   This is the default task log file created by the RTM
  ## rtm_check_only_logfile.rtm_check_only
  ##   This is the original task log file from a pre-existing task execution
  ##   that was renamed by the RTM prior to running a check-only task invocation.
  ##   This renaming was done to preserve the original log file contents.

  file delete -force $rtm_check_only_logfile
  file rename -force $rtm_check_only_logfile.rtm_check_only $rtm_check_only_logfile

} else {

  if { $env(SEV_DONT_RUN) == 0 } {

    set LYNX(script_file) $env(LYNX_SCRIPT_FILE)

    if { [file exists $LYNX(script_file)] } {

      puts "SNPS_INFO   : SCRIPT_START : [file normalize $LYNX(script_file)] : [date]"
      if { $synopsys_program_name == "tcl" } {
        source $LYNX(script_file)
      } elseif { $synopsys_program_name == "cdesigner" } {
        source $LYNX(script_file)
      } else {
        source -e -v $LYNX(script_file)
      }
      puts "SNPS_INFO   : SCRIPT_STOP  : [file normalize $LYNX(script_file)] : [date]"

    } else {

      puts "snps_error  : The file specified by LYNX_SCRIPT_FILE does not exist."
      puts "snps_error  : LYNX_SCRIPT_FILE = $LYNX(script_file)"

    }

    if { $env(SEV_DONT_EXIT) == 0 } {

      puts "SNPS_INFO   : SCRIPT_STOP : [file normalize ../../scripts_global/conf/tool_wrapper.tcl] : [date]"
      if { $synopsys_program_name == "cdesigner" } {
        sproc_cdesigner_cleanup
        exit -force 1
      } else {
        exit
      }

    } else {

      if { $synopsys_program_name == "tcl" } {
        sproc_interactive_tcl
      }

    }

  } else {

    if { $synopsys_program_name == "tcl" } {
      sproc_interactive_tcl
    }

  }

}

puts "SNPS_INFO   : SCRIPT_STOP  : [file normalize ../../scripts_global/conf/tool_wrapper.tcl] : [date]"

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
