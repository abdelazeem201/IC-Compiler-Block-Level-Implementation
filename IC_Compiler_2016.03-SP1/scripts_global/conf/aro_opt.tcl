#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/aro_opt.tcl#57 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script is used to perform ARO processing related to job submission.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## Define procedures
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## parse_args:
## -----------------------------------------------------------------------------

proc parse_args {} {

  global argv
  global argvar

  set argvar(function)   ""
  set argvar(js_type)    ""
  set argvar(file1)      ""
  set argvar(file2)      ""
  set argvar(file3)      ""
  set argvar(jname)      ""
  set argvar(queue)      ""
  set argvar(memory)     ""
  set argvar(aro_server) ""
  set argvar(aro_port)   ""
  set argvar(aro_no_opt) 0

  set error_flag 0

  for { set i 0 } { $i < [llength $argv] } { incr i } {
    set arg [lindex $argv $i]
    switch -- $arg {
      -function {
        incr i
        set argvar(function) [lindex $argv $i]
      }
      -js_type {
        incr i
        set argvar(js_type) [lindex $argv $i]
      }
      -file1 {
        incr i
        set argvar(file1) [lindex $argv $i]
      }
      -file2 {
        incr i
        set argvar(file2) [lindex $argv $i]
      }
      -file3 {
        incr i
        set argvar(file3) [lindex $argv $i]
      }
      -jname {
        incr i
        set argvar(jname) [lindex $argv $i]
      }
      -queue {
        incr i
        set argvar(queue) [lindex $argv $i]
      }
      -memory {
        incr i
        set argvar(memory) [lindex $argv $i]
      }
      -aro_server {
        incr i
        set argvar(aro_server) [lindex $argv $i]
      }
      -aro_port {
        incr i
        set argvar(aro_port) [lindex $argv $i]
      }
      -aro_no_opt {
        incr i
        set argvar(aro_no_opt) [lindex $argv $i]
      }
      default {
        puts "Error: Unrecognized option: $arg"
        set error_flag 1
      }
    }
  }

  return $error_flag

}

## -----------------------------------------------------------------------------
## do_optimize:
## -----------------------------------------------------------------------------

proc do_optimize {} {

  global argvar
  global gvar
  global aro_info

  ## -------------------------------------
  ## Define files
  ## -------------------------------------

  set file_aro_opt_optimize_results $argvar(file1)
  set file_aro_info_wo_jobid $argvar(file2)

  ## -------------------------------------
  ## Record the time stamp
  ## -------------------------------------

  set aro_info(JOB_TIMESTAMP) [clock seconds]

  ## -------------------------------------
  ## Record the values that were originally requested
  ## -------------------------------------

  set aro_info(MEM_EST_ORG)  $argvar(memory)
  set aro_info(TIME_EST_ORG) -1
  set aro_info(QUEUE_ORG)    $argvar(queue)

  ## -------------------------------------
  ## The optimization proc must set these variables:
  ## - aro_info(MEM_EST_OPT)
  ## - aro_info(TIME_EST_OPT)
  ## - aro_info(QUEUE_OPT)
  ## -------------------------------------

  if { $gvar(use_custom_opt) } {
    do_custom_opt
  } else {
    do_daemon_opt
  }

  ## -------------------------------------
  ## Record the values that will be used for estimation
  ## -------------------------------------

  if { $argvar(aro_no_opt) } {

    set aro_info(MEM_EST_ACT)  $aro_info(MEM_EST_ORG)
    set aro_info(TIME_EST_ACT) $aro_info(TIME_EST_ORG)
    set aro_info(QUEUE_ACT)    $aro_info(QUEUE_ORG)

  } else {

    if { $aro_info(MEM_EST_OPT) != "-1" } {
      set aro_info(MEM_EST_ACT) $aro_info(MEM_EST_OPT)
    } else {
      set aro_info(MEM_EST_ACT) $aro_info(MEM_EST_ORG)
    }

    if { $aro_info(TIME_EST_OPT) != "-1" } {
      set aro_info(TIME_EST_ACT) $aro_info(TIME_EST_OPT)
    } else {
      set aro_info(TIME_EST_ACT) $aro_info(TIME_EST_ORG)
    }

    if { $aro_info(QUEUE_OPT) != "-1" } {
      set aro_info(QUEUE_ACT) $aro_info(QUEUE_OPT)
    } else {
      set aro_info(QUEUE_ACT) $aro_info(QUEUE_ORG)
    }

  }

  ## -------------------------------------
  ## Now that we have the new values for queue and resource,
  ## write that information to a file the sh script can source.
  ## -------------------------------------

  set fid [open $file_aro_opt_optimize_results w]
  puts $fid "new_memory=$aro_info(MEM_EST_ACT)"
  puts $fid "new_time=$aro_info(TIME_EST_ACT)"
  puts $fid "new_queue=$aro_info(QUEUE_ACT)"
  if { $gvar(global_error_flag) || $gvar(force_debug) } {
    puts $fid "debug=1"
  }
  close $fid

  ## -------------------------------------
  ## Write the initial set of ARO information.
  ## -------------------------------------

  puts "## -------------------------------------"
  puts "## Final results for aro_info file"
  puts "## -------------------------------------"

  puts "JOB_NAME|$argvar(jname)"
  puts "JOB_ID|JOB_ID_PLACEHOLDER"
  puts "JOB_TIMESTAMP|$aro_info(JOB_TIMESTAMP)"
  puts "MEM_EST_ORG|$aro_info(MEM_EST_ORG)"
  puts "MEM_EST_OPT|$aro_info(MEM_EST_OPT)"
  puts "MEM_EST_ACT|$aro_info(MEM_EST_ACT)"
  puts "TIME_EST_ORG|$aro_info(TIME_EST_ORG)"
  puts "TIME_EST_OPT|$aro_info(TIME_EST_OPT)"
  puts "TIME_EST_ACT|$aro_info(TIME_EST_ACT)"
  puts "QUEUE_ORG|$aro_info(QUEUE_ORG)"
  puts "QUEUE_OPT|$aro_info(QUEUE_OPT)"
  puts "QUEUE_ACT|$aro_info(QUEUE_ACT)"
  puts ""

  set fid [open $file_aro_info_wo_jobid w]
  puts $fid "JOB_NAME|$argvar(jname)"
  puts $fid "JOB_ID|JOB_ID_PLACEHOLDER"
  puts $fid "JOB_TIMESTAMP|$aro_info(JOB_TIMESTAMP)"
  puts $fid "MEM_EST_ORG|$aro_info(MEM_EST_ORG)"
  puts $fid "MEM_EST_OPT|$aro_info(MEM_EST_OPT)"
  puts $fid "MEM_EST_ACT|$aro_info(MEM_EST_ACT)"
  puts $fid "TIME_EST_ORG|$aro_info(TIME_EST_ORG)"
  puts $fid "TIME_EST_OPT|$aro_info(TIME_EST_OPT)"
  puts $fid "TIME_EST_ACT|$aro_info(TIME_EST_ACT)"
  puts $fid "QUEUE_ORG|$aro_info(QUEUE_ORG)"
  puts $fid "QUEUE_OPT|$aro_info(QUEUE_OPT)"
  puts $fid "QUEUE_ACT|$aro_info(QUEUE_ACT)"
  close $fid

}

## -----------------------------------------------------------------------------
## do_custom_opt:
## -----------------------------------------------------------------------------

proc do_custom_opt {} {

  global gvar
  global argvar
  global aro_info

  puts "Using Custom Optimization"
  puts ""

  ## -------------------------------------
  ## ARO_HIST transaction
  ## -------------------------------------

  set tx_lines [list]
  lappend tx_lines "ARO_HIST_START"
  lappend tx_lines "JOB_NAME|$argvar(jname)"
  lappend tx_lines "RECORDS_MAXIMUM|5"
  lappend tx_lines "ARO_HIST_STOP"

  set error_flag [daemon_transaction ARO_HIST tx_lines rx_lines]

  if { $error_flag } {

    incr gvar(global_error_flag)

    set aro_info(MEM_EST_OPT) -1
    set aro_info(TIME_EST_OPT) -1

  } else {

    ## -------------------------------------
    ## Parse ARO_HIST response from ARO daemon
    ## -------------------------------------
    ## 1|Success
    ## JOB_HISTORY|N (where N = 1 to NMAX)
    ##   For each history entry:
    ##   JOB_STATUS|value
    ##   MEM_ACT_RES|value
    ##   MEM_ACT_SWAP|value
    ##   MEM_ACT_TOOL|value
    ##   TIME_ACT_EXEC|value
    ## -------------------------------------

    set line_index 0

    set line [lindex $rx_lines [incr line_index]]

    set parse_info(history_count) 0
    regexp {^JOB_HISTORY\|(\d+)} $line match parse_info(history_count)

    for { set hist_index 0 } { $hist_index < $parse_info(history_count) } { incr hist_index } {

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^JOB_STATUS\|([\d\-]+)} $line match value] } {
        set JOB_STATUS $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_RES\|([\d\-]+)} $line match value] } {
        set MEM_ACT_RES $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_SWAP\|([\d\-]+)} $line match value] } {
        set MEM_ACT_SWAP $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_TOOL\|([\d\-]+)} $line match value] } {
        set MEM_ACT_TOOL $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^TIME_ACT_EXEC\|([\d\-]+)} $line match value] } {
        set TIME_ACT_EXEC $value
      }

      set parse_hist($hist_index) [list $JOB_STATUS $MEM_ACT_RES $MEM_ACT_SWAP $MEM_ACT_TOOL $TIME_ACT_EXEC]
    }

    puts "## -------------------------------------"
    puts "## Parsed ARO_HIST Results"
    puts "## -------------------------------------"

    puts "parse_info(history_count) : $parse_info(history_count)"
    for { set hist_index 0 } { $hist_index < $parse_info(history_count) } { incr hist_index } {
      puts "parse_hist($hist_index) : $parse_hist($hist_index)"
    }
    puts "parse_hist fields : JOB_STATUS MEM_ACT_RES MEM_ACT_SWAP MEM_ACT_TOOL TIME_ACT_EXEC"
    puts ""

    ## -------------------------------------
    ## This is the input data available for
    ## implementing a custom solution:
    ##
    ## set aro_info(MEM_EST_ORG)   4000
    ## set aro_info(TIME_EST_ORG)  -1
    ## set aro_info(QUEUE_ORG)     normal
    ## set parse_info(history_count) 3
    ## set parse_hist(0) {    0          100         400          700          11         }
    ## set parse_hist(1) {    0          200         500          800          22         }
    ## set parse_hist(2) {    0          300         600          900          33         }
    ## -------------------------------------

    ## -------------------------------------
    ## For MEM estimates:
    ## - Use the previous job's actual measured value + 10%
    ## - Only consider previous jobs with a JOB_STATUS of 0
    ## - If there is no previous job available, use the original estimate
    ## - Use this precedence: MEM_ACT_TOOL, MEM_ACT_RES, MEM_ACT_SWAP
    ## - Estimate a minimum of gvar(min_custom_opt_mem_estimate)
    ## - Estimate a maximum of gvar(max_custom_opt_mem_estimate)
    ##
    ## For TIME estimates:
    ## - Use the previous job's actual measured value + 10%
    ## - Only consider previous jobs with a JOB_STATUS of 0
    ## - If there is no previous job available, use the original estimate
    ## -------------------------------------

    set new_mem_est $aro_info(MEM_EST_ORG)
    set history_index -1
    for { set i 0 } { $i < $parse_info(history_count) } { incr i } {
      set JOB_STATUS    [lindex $parse_hist($i) 0]
      set MEM_ACT_RES   [lindex $parse_hist($i) 1]
      set MEM_ACT_SWAP  [lindex $parse_hist($i) 2]
      set MEM_ACT_TOOL  [lindex $parse_hist($i) 3]
      set TIME_ACT_EXEC [lindex $parse_hist($i) 4]
      if { $JOB_STATUS == 0 } {
        if { $MEM_ACT_TOOL != -1 } {
          set new_mem_est $MEM_ACT_TOOL
          set history_index $i
          break
        }
        if { $MEM_ACT_RES != -1 } {
          set new_mem_est $MEM_ACT_RES
          set history_index $i
          break
        }
        if { $MEM_ACT_SWAP != -1 } {
          set new_mem_est $MEM_ACT_SWAP
          set history_index $i
          break
        }
      }
    }
    set new_mem_est [expr int($new_mem_est * 1.1)]

    if { $new_mem_est < $gvar(min_custom_opt_mem_estimate) } {
      set new_mem_est $gvar(min_custom_opt_mem_estimate)
    }
    if { $new_mem_est > $gvar(max_custom_opt_mem_estimate) } {
      set new_mem_est $gvar(max_custom_opt_mem_estimate)
    }

    if { $history_index == -1 } {
      set new_time_est -1
    } else {
      set new_time_est [lindex $parse_hist($history_index) 4]
    }
    set new_time_est [expr int($new_time_est * 1.1)]

    set aro_info(MEM_EST_OPT) $new_mem_est
    set aro_info(TIME_EST_OPT) $new_time_est

  }

  ## -------------------------------------
  ## Now perform QUEUE optimization using these updated variables:
  ##   aro_info(MEM_EST_OPT)
  ##   aro_info(TIME_EST_OPT)
  ## -------------------------------------

  ## -------------------------------------
  ## ARO_QUEUE transaction
  ## -------------------------------------

  set tx_lines [list]
  lappend tx_lines "ARO_QUEUE_START"
  lappend tx_lines "MEM_EST_OPT|$aro_info(MEM_EST_OPT)"
  lappend tx_lines "TIME_EST_OPT|$aro_info(TIME_EST_OPT)"
  lappend tx_lines "ARO_QUEUE_STOP"

  set error_flag [daemon_transaction ARO_QUEUE tx_lines rx_lines]

  if { $error_flag } {

    incr gvar(global_error_flag)

    set aro_info(QUEUE_OPT) -1

  } else {

    ## -------------------------------------
    ## Parse ARO_QUEUE response from ARO daemon
    ## -------------------------------------
    ## 1|Success
    ## QUEUE_OPT|value
    ## -------------------------------------

    set line_index 0

    set line [lindex $rx_lines [incr line_index]]
    if { [regexp {^QUEUE_OPT\|(\S+)} $line match value] } {
      set parse_info(QUEUE_OPT) $value
    }

    puts "## -------------------------------------"
    puts "## Parsed ARO_QUEUE Results"
    puts "## -------------------------------------"
    puts "parse_info(QUEUE_OPT)  : $parse_info(QUEUE_OPT)"
    puts ""

    set aro_info(QUEUE_OPT) $parse_info(QUEUE_OPT)

  }

  puts "Custom value for aro_info(MEM_EST_OPT)  : $aro_info(MEM_EST_OPT)"
  puts "Custom value for aro_info(TIME_EST_OPT) : $aro_info(TIME_EST_OPT)"
  puts "Custom value for aro_info(QUEUE_OPT)    : $aro_info(QUEUE_OPT)"
  puts ""

}

## -----------------------------------------------------------------------------
## do_daemon_opt:
## -----------------------------------------------------------------------------

proc do_daemon_opt {} {

  global gvar
  global argvar
  global aro_info

  puts "Using Daemon Optimization"
  puts ""

  ## -------------------------------------
  ## ARO_OPT transaction
  ## -------------------------------------

  set tx_lines [list]
  lappend tx_lines "ARO_OPT_START"
  lappend tx_lines "JOB_NAME|$argvar(jname)"
  lappend tx_lines "ARO_OPT_STOP"

  set error_flag [daemon_transaction ARO_OPT tx_lines rx_lines]

  if { $error_flag } {

    incr gvar(global_error_flag)

    set aro_info(MEM_EST_OPT)  -1
    set aro_info(TIME_EST_OPT) -1
    set aro_info(QUEUE_OPT)    -1

  } else {

    ## -------------------------------------
    ## Parse ARO_OPT response from ARO daemon
    ## -------------------------------------
    ## 1|Success
    ## MEM_EST_OPT|value
    ## TIME_EST_OPT|value
    ## QUEUE_OPT|value
    ## JOB_HISTORY|N (where N = 1 to NMAX)
    ##   For each history entry:
    ##   JOB_STATUS|value
    ##   MEM_ACT_RES|value
    ##   MEM_ACT_SWAP|value
    ##   MEM_ACT_TOOL|value
    ##   TIME_ACT_EXEC|value
    ## -------------------------------------

    set line_index 0

    set line [lindex $rx_lines [incr line_index]]
    if { [regexp {^MEM_EST_OPT\|([\d\-]+)} $line match value] } {
      set parse_info(MEM_EST_OPT) $value
    }

    set line [lindex $rx_lines [incr line_index]]
    if { [regexp {^TIME_EST_OPT\|([\d\-]+)} $line match value] } {
      set parse_info(TIME_EST_OPT) $value
    }

    set line [lindex $rx_lines [incr line_index]]
    if { [regexp {^QUEUE_OPT\|(\S+)} $line match value] } {
      set parse_info(QUEUE_OPT) $value
    }

    set line [lindex $rx_lines [incr line_index]]

    set parse_info(history_count) 0
    regexp {^JOB_HISTORY\|(\d+)} $line match parse_info(history_count)

    for { set hist_index 0 } { $hist_index < $parse_info(history_count) } { incr hist_index } {

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^JOB_STATUS\|([\d\-]+)} $line match value] } {
        set JOB_STATUS $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_RES\|([\d\-]+)} $line match value] } {
        set MEM_ACT_RES $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_SWAP\|([\d\-]+)} $line match value] } {
        set MEM_ACT_SWAP $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^MEM_ACT_TOOL\|([\d\-]+)} $line match value] } {
        set MEM_ACT_TOOL $value
      }

      set line [lindex $rx_lines [incr line_index]]
      if { [regexp {^TIME_ACT_EXEC\|([\d\-]+)} $line match value] } {
        set TIME_ACT_EXEC $value
      }

      set parse_hist($hist_index) [list $JOB_STATUS $MEM_ACT_RES $MEM_ACT_SWAP $MEM_ACT_TOOL $TIME_ACT_EXEC]
    }

    puts "## -------------------------------------"
    puts "## Parsed ARO_OPT Results"
    puts "## -------------------------------------"
    puts "parse_info(MEM_EST_OPT)   : $parse_info(MEM_EST_OPT)"
    puts "parse_info(TIME_EST_OPT)  : $parse_info(TIME_EST_OPT)"
    puts "parse_info(QUEUE_OPT)     : $parse_info(QUEUE_OPT)"

    puts "parse_info(history_count) : $parse_info(history_count)"
    for { set hist_index 0 } { $hist_index < $parse_info(history_count) } { incr hist_index } {
      puts "parse_hist($hist_index) : $parse_hist($hist_index)"
    }
    puts "parse_hist fields : JOB_STATUS MEM_ACT_RES MEM_ACT_SWAP MEM_ACT_TOOL TIME_ACT_EXEC"
    puts ""

    set aro_info(MEM_EST_OPT)  $parse_info(MEM_EST_OPT)
    set aro_info(TIME_EST_OPT) $parse_info(TIME_EST_OPT)
    set aro_info(QUEUE_OPT)    $parse_info(QUEUE_OPT)

  }

  puts "Daemon value for aro_info(MEM_EST_OPT)  : $aro_info(MEM_EST_OPT)"
  puts "Daemon value for aro_info(TIME_EST_OPT) : $aro_info(TIME_EST_OPT)"
  puts "Daemon value for aro_info(QUEUE_OPT)    : $aro_info(QUEUE_OPT)"
  puts ""

}

## -----------------------------------------------------------------------------
## do_finalize:
## -----------------------------------------------------------------------------

proc do_finalize {} {

  global argvar
  global gvar

  ## -------------------------------------
  ## Define files
  ## -------------------------------------

  set file_sub_stdout $argvar(file1)
  set file_aro_info_wo_jobid $argvar(file2)
  set file_aro_opt_finalize_results $argvar(file3)

  ## -------------------------------------
  ## Perform processing
  ## -------------------------------------

  set fid [open $file_sub_stdout r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  set job_id ""

  foreach line $lines {
    switch $argvar(js_type) {
      lsf {
        if { [regexp {^Job <(\d+)> is submitted to queue} $line match job_id] } {
          break
        }
      }
      grd {
        if { [regexp {^Your job (\d+) \(.*\) has been submitted} $line match job_id] } {
          break
        }
      }
    }
  }

  set lines_aro_info [list]

  if { $job_id != "" } {

    set fid [open $file_aro_info_wo_jobid r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]
    foreach line $lines {
      set line [regsub {JOB_ID_PLACEHOLDER} $line $job_id]
      if { [llength $line] > 0 } {
        lappend lines_aro_info $line
      }
    }

    ## -------------------------------------
    ## The lines in lines_aro_info need to be sent to the ARO deamon,
    ## to await processing by the accounting application, which does
    ## aro_info/aro_mem -> aro_metrics
    ## -------------------------------------

    ## -------------------------------------
    ## ARO_INFO transaction
    ## -------------------------------------

    set tx_lines [list]
    lappend tx_lines "ARO_INFO_START"
    lappend tx_lines "FILE|$job_id.aro_info"
    foreach line $lines_aro_info {
      lappend tx_lines $line
    }
    lappend tx_lines "ARO_INFO_STOP"

    set error_flag [daemon_transaction ARO_INFO tx_lines rx_lines]

    if { $error_flag } {

      incr gvar(global_error_flag)

      puts "Error: ARO info file not sent."
      puts ""

    } else {

      puts "ARO info file sent."
      puts ""

    }

  } else {

    puts "Error: Unable to determine the job ID from file $file_sub_stdout"
    set error_flag 1

  }

  ## -------------------------------------
  ## If there are any errors, set the debug variable.
  ## -------------------------------------

  set fid [open $file_aro_opt_finalize_results w]
  if { $gvar(global_error_flag) || $gvar(force_debug) } {
    puts $fid "debug=1"
  }
  close $fid

}

## -----------------------------------------------------------------------------
## daemon_transaction:
## -----------------------------------------------------------------------------

proc daemon_transaction { transaction tx_lines_name rx_lines_name } {

  global argvar

  upvar $tx_lines_name tx_lines
  upvar $rx_lines_name rx_lines

  set error_flag 0

  puts "## -------------------------------------"
  puts "## Transaction $transaction: Begin"
  puts "## -------------------------------------"
  puts ""

  ## -------------------------------------
  ## Open a blocking-style socket
  ## -------------------------------------

  set socket_host $argvar(aro_server)
  set socket_port $argvar(aro_port)

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

  if { $socket_ok } {

    fconfigure $socket_channel -blocking 1

    puts "## -------------------------------------"
    puts "## Transaction $transaction: Send"
    puts "## -------------------------------------"

    foreach line $tx_lines {
      puts "$line"
    }
    puts ""

    foreach line $tx_lines {
      puts $socket_channel $line
    }

    flush $socket_channel

    puts "## -------------------------------------"
    puts "## Transaction $transaction: Receive"
    puts "## -------------------------------------"

    set rx_lines [list]
    while {1} {
      set line [gets $socket_channel]
      if { [eof $socket_channel] } {
        close $socket_channel
        break
      } else {
        lappend rx_lines $line
      }
    }

    foreach line $rx_lines {
      puts "$line"
    }
    puts ""

    set reply_status [lindex [split [lindex $rx_lines 0] "|"] 0]
    set reply_msg    [lindex [split [lindex $rx_lines 0] "|"] 1]

    if { $reply_status != "1" } {

      puts "Error: Reply during $transaction: $reply_msg"
      set error_flag 1

    }

  } else {

    puts "Error : Unable to create socket ($socket_host:$socket_port) from [info host] to ARO Daemon"
    puts "Error : Socket returns $socket_channel"
    set error_flag 1

  }

  puts "## -------------------------------------"
  puts "## Transaction $transaction: End"
  puts "## -------------------------------------"
  puts ""

  return $error_flag

}

## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------
## Main
## -----------------------------------------------------------------------------
## -----------------------------------------------------------------------------

puts "Start aro_opt.tcl"
puts ""

## -------------------------------------
## Set some global variables
## -------------------------------------

set gvar(global_error_flag) 0
set gvar(force_debug)       0
set gvar(use_custom_opt)    1
set gvar(min_custom_opt_mem_estimate)   1000
set gvar(max_custom_opt_mem_estimate)  32000

## -------------------------------------
## Parse command line arguments
## -------------------------------------

if { [parse_args] } {
  incr gvar(global_error_flag)
}

## -------------------------------------
## Determine the function to perform and do it
## -------------------------------------

set function [lindex $argv 0]
if { $argvar(function) == "optimize" } {
  do_optimize
}
if { $argvar(function) == "finalize" } {
  do_finalize
}

puts "Stop aro_opt.tcl"
puts ""

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
