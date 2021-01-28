#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/wait_for_job_to_finish.tcl#24 $
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

puts "Start of wait_for_job_to_finish.tcl execution."

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set option(log_file) ""

for { set i 0 } { $i < [llength $argv] } { incr i } {
  set arg [lindex $argv $i]
  switch -- $arg {
    -log_file {
      incr i
      set option(log_file) [lindex $argv $i]
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

set file_part_org [file tail $option(log_file)]
set dir_part_org  [file dirname $option(log_file)]
set file_part_new .[file rootname $file_part_org].job_done
set wait_file $dir_part_org/$file_part_new

set seconds 0
set minutes 0
puts "Waiting for file '$wait_file' ..."
while { 1 } {
  after 1000
  incr seconds
  if { $seconds == 60 } {
    set seconds 0
    incr minutes
    puts "  Minutes: $minutes"
  }
  if { [file exists $wait_file] } {
    puts "  Found file '$wait_file'"
    break
  }
}

puts "End of wait_for_job_to_finish.tcl execution."

exit

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
