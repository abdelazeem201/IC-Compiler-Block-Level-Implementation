## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/demo/demo_gen.tcl#57 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This is the standard decision script for data management.
## * The decision being made is promote vs restore.
## -----------------------------------------------------------------------------

source ../../scripts_global/conf/procs.tcl
sproc_source -file ../../scripts_global/conf/system.tcl
sproc_source -file $env(LYNX_VARFILE_SEV)
sproc_source -file ../../scripts_global/conf/system_setup.tcl
sproc_source -file $SEV(tscript_dir)/common.tcl
sproc_source -file $SEV(bscript_dir)/conf/block.tcl

## NAME: TEV(number_of_children)
## TYPE: integer
## INFO:
## * Controls the number of child tasks that are generated.
set TEV(number_of_children) "3"

## NAME: TEV(edge_mode)
## TYPE: oos
## OOS_LIST: SERIAL PARALLEL
## INFO:
## * Controls edges
set TEV(edge_mode) "PARALLEL"

sproc_source -file $env(LYNX_VARFILE_TEV)
sproc_source -file $SEV(bscript_dir)/conf/block_setup.tcl
sproc_script_start

## -----------------------------------------------------------------------------
## End of script header
## -----------------------------------------------------------------------------

## SECTION_START: initial

## SECTION_STOP: initial

## SECTION_START: body

## -----------------------------------------------------------------------------
## Code for creating some generated tasks.
## -----------------------------------------------------------------------------

set fid_subflow [open $SEV(gen_file) w]
puts $fid_subflow "<gen_group>"
puts $fid_subflow ""

for { set i 1 } { $i <= $TEV(number_of_children) } { incr i } {
  puts $fid_subflow "  <tool_task>"
  puts $fid_subflow "    <name>child_task_$i</name>"
  puts $fid_subflow "    <tool>tcl_job</tool>"
  puts $fid_subflow "    <script_file>\$SEV(gscript_dir)/demo/demo_script.tcl</script_file>"
  puts $fid_subflow "    <step>$SEV(step)</step>"
  puts $fid_subflow "    <src>$SEV(src)</src>"
  puts $fid_subflow "    <dst>$SEV(dst)</dst>"
  puts $fid_subflow "  </tool_task>"
  puts $fid_subflow ""
}

if { $TEV(edge_mode) == "SERIAL" } {
  puts $fid_subflow " <edges>"
  set a 0
  for { set b 2 } { $b <= $TEV(number_of_children) } { incr b } {
    puts $fid_subflow "    <edge from=\"child_task_[incr a]\" to=\"child_task_$b\"/>"
  }
  puts $fid_subflow " </edges>"
}

puts $fid_subflow "</gen_group>"
close $fid_subflow

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
