#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/wait_for_job_to_finish_lsf.tcl#48 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script must perform these functions:
## * - Parse job submission output and print the JOBID for use by the RTM.
## * - Wait until the originally submitted job completes.
## *   This is best accomplished by submitting a synchronization job
## *   that does not run&complete until the original job is finished.
## * - Perform an exit from this script, which returns control to the RTM
## *   and signals that all job processing is completed.
## * Note that many LSF and GRD installations are site-specific and
## * it may be neccessary to make adjustments to this code.
## -----------------------------------------------------------------------------

puts "Start of wait_for_job_to_finish_lsf.tcl execution."

set use_js_sync_function 0

## -----------------------------------------------------------------------------
## Initialize command to use for external program execution.
## -----------------------------------------------------------------------------

if { [info exists synopsys_program_name] } {
  if { $synopsys_program_name == "rtm_shell" } {
    set ::gRtmShell_AllowSevModify 1
  }
}

set SEV(exec_cmd) sh

if { [info exists synopsys_program_name] } {
  if { $synopsys_program_name == "rtm_shell" } {
    set ::gRtmShell_AllowSevModify 0
  }
}

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set option(log_file) ""
set option(jid_file) ""

for { set i 0 } { $i < [llength $argv] } { incr i } {
  set arg [lindex $argv $i]
  switch -- $arg {
    -log_file {
      incr i
      set option(log_file) [lindex $argv $i]
    }
    -jid_file {
      incr i
      set option(jid_file) [lindex $argv $i]
    }
    -job_name {
      incr i
      set option(job_name) [lindex $argv $i]
    }
    -project_name {
      incr i
      set option(project_name) [lindex $argv $i]
    }
    -queue_name {
      incr i
      set option(queue_name) [lindex $argv $i]
    }
    default {
      puts "Error: Unrecognized option: $arg"
      exit
    }
  }
}

## -----------------------------------------------------------------------------
## Global settings
## -----------------------------------------------------------------------------

set js_sync_tcl [file normalize [file dir $argv0]]/js_sync.tcl

set file_part_org [file tail $option(log_file)]
set dir_part_org  [file dirname $option(log_file)]
set file_part_new .[file rootname $file_part_org].js_sync.log
set js_sync_log $dir_part_org/$file_part_new

set file_part_new .[file rootname $file_part_org].js_sync.done
set js_sync_done $dir_part_org/$file_part_new

if { $option(jid_file) == "" } {
  set file_part_new .[file rootname $file_part_org].jid
  set jid_file $dir_part_org/$file_part_new
} else {
  set jid_file $option(jid_file)
}

set debug_mode 0

## -----------------------------------------------------------------------------
## LSF
## -----------------------------------------------------------------------------

set job_id ""

while { [gets stdin line] >= 0 } {
  if { $debug_mode } {
    puts "DEBUG: $line"
  }
  if { [regexp {^Job <(\d+)>} $line match job_id] } {
    break
  }
}

if { $job_id == "" } {

  puts "Error: Unable to identify JOBID from bsub results."

} else {

  ## -------------------------------------
  ## This is the old method
  ## -------------------------------------

  puts "LSF_JOBID $job_id"
  flush stdout

  ## -------------------------------------
  ## This is the new method
  ## -------------------------------------

  set fid [open $jid_file a]
  puts $fid "LSF_JOBID $job_id EOL"
  close $fid

  ## -------------------------------------
  ## Run a synchronization job that will wait until the original job is finished.
  ## -------------------------------------

  puts "Start of synchronization job."

  if { $use_js_sync_function } {

    set cmd "bsub -o /dev/null -P $option(project_name) -J $option(job_name).sync -q $option(queue_name) -R 'rusage\[mem=10\]' -K -w 'ended($job_id)'"
    set cmd "$cmd '$js_sync_tcl > $js_sync_log 2>&1'"

    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    puts "$results"

  } else {

    file delete -force $js_sync_done

    set cmd "bsub -o /dev/null -P $option(project_name) -J $option(job_name).sync -q $option(queue_name) -R 'rusage\[mem=10\]' -w 'ended($job_id)'"
    set cmd "$cmd '$js_sync_tcl $js_sync_done > $js_sync_log 2>&1'"

    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    puts "$results"

    set seconds 0
    set minutes 0
    puts "Waiting for file '$js_sync_done' ..."
    while { 1 } {
      after 1000
      incr seconds
      if { $seconds == 60 } {
        set seconds 0
        incr minutes
        puts "  Minutes: $minutes"
      }
      if { [file exists $js_sync_done] } {
        puts "  Found file '$js_sync_done'"
        break
      }
    }

  }

  puts "End of synchronization job."

}

## -----------------------------------------------------------------------------
## End
## -----------------------------------------------------------------------------

puts "End of wait_for_job_to_finish_lsf.tcl execution."

exit

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
