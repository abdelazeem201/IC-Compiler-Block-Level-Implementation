#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/js_sync.tcl#50 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script is executed by the synchronization job.
## * Note that many LSF and GRD installations are site-specific and
## * it may be neccessary to make adjustments to this code.
## -----------------------------------------------------------------------------

puts "Start of js_sync.tcl execution."

after 1000

set file $argv
set fid [open $file w]
puts $fid "Sync Job Complete"
close $fid

puts "End of js_sync.tcl execution."

exit

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
