## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/demo/demo_script.tcl#109 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script is used when running the RTM in demo mode.
## *
## * The RTM demo mode is enabled by setting the shell variable named
## * LYNX_DEMO before starting the RTM. The value of LYNX_DEMO does not matter.
## *
## * During demo mode, run_flow behavior is adjusted as follows:
## * - The gen_tasks will run as normal.
## * - The branch_tasks will run as normal.
## * - For all other tasks:
## *   - This script is used instead of the normal script.
## *   - Tasks not using the tool named 'tcl' will be converted to 'tcl_job'.
## *     Tasks using the tool named 'tcl' will continue using 'tcl'.
## -----------------------------------------------------------------------------

source ../../scripts_global/conf/procs.tcl
sproc_source -file ../../scripts_global/conf/system.tcl
sproc_source -file $env(LYNX_VARFILE_SEV)
sproc_source -file ../../scripts_global/conf/system_setup.tcl
sproc_source -file $SEV(tscript_dir)/common.tcl
sproc_source -file $SEV(bscript_dir)/conf/block.tcl

## NAME: TEV(skip)
## TYPE: boolean
## INFO:
## * Set to 1 to skip this task.
set TEV(skip) "0"

## NAME: TEV(string)
## TYPE: string
## INFO:
## * Test variable.
set TEV(string) "misc_text_1"

sproc_source -file $env(LYNX_VARFILE_TEV)
sproc_source -file $SEV(bscript_dir)/conf/block_setup.tcl
sproc_script_start

## -----------------------------------------------------------------------------
## End of script header
## -----------------------------------------------------------------------------

## SECTION_START: initial

## SECTION_STOP: initial

## SECTION_START: task_delay

## -----------------------------------------------------------------------------
## This section is used to specify a runtime for the script.
## -----------------------------------------------------------------------------

set wait_always               [expr  5 * 1000]
set wait_extra_early_complete [expr  5 * 1000]

## -----------------------------------------------------------------------------
## This section is used to generate errors and perform early-completion
## based on step and task names. You can mock up demos in this manner.
## -----------------------------------------------------------------------------

after $wait_always

## SECTION_STOP: task_delay

## SECTION_START: task_activity

set generate_error 0

## To generate a FATAL, add this line: exit
## To generate a ERROR, add this line: set generate_error 1

switch -glob $SEV(step) {
  10_syn* {
    switch -glob $SEV(task) {
      dc_elaborate_baseline {
        set generate_error 1
      }
      default {
      }
    }
  }
  20_dp* -
  30_pnr* -
  40_finish* {
    switch -glob $SEV(task) {
      icc_* {
        sproc_early_complete
        after $wait_extra_early_complete
      }
      default {
      }
    }
  }
  default {
    sproc_msg -info "Unrecognized value for SEV(step) : $SEV(step)"
  }
}

if { $generate_error } {
  sproc_msg -error "User generated error"
}

## -----------------------------------------------------------------------------
## When run in LYNX_DEMO mode,
## these variables need to be set:
## -----------------------------------------------------------------------------

set TEV(num_child_jobs) 1

## -----------------------------------------------------------------------------
## When run in LYNX_DEMO mode,
## these messages satisfy the must_have checks for flow tasks:
## -----------------------------------------------------------------------------

## SECTION_STOP: task_activity

## SECTION_START: messages

puts "Total Floating Nets are 0"
puts "Total SHORT Nets are 0"
puts "Total OPEN Nets are 0"
puts "Translation completed."
puts "Verification SUCCEEDED"
puts "SNPS_PASS"

## SECTION_STOP: messages

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
