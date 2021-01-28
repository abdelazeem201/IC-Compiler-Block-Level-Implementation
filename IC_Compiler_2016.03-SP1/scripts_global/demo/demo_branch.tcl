## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/demo/demo_branch.tcl#55 $
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

## NAME: TEV(decision_override)
## TYPE: oos
## OOS_LIST: 0 1 2 3 4
## INFO:
## * This variable can be used to override the flow's normal decision making logic.
## * Here are the selections:
## * 0 : Flow performs normal decision making logic. (default)
## * 1 : Take branch 1
## * 2 : Take branch 2
## * 3 : Take branch 3
## * 4 : Take branch 4
set TEV(decision_override) "1"

## NAME: TEV(misc_text_1)
## TYPE: string
## INFO:
## * Test variable.
set TEV(misc_text_1) "misc_text_1"

## NAME: TEV(misc_text_2)
## TYPE: string
## INFO:
## * Test variable.
set TEV(misc_text_2) "misc_text_2"

## NAME: TEV(misc_text_3)
## TYPE: string
## INFO:
## * Test variable.
set TEV(misc_text_3) "misc_text_3"

## NAME: TEV(misc_text_4)
## TYPE: string
## INFO:
## * Test variable.
set TEV(misc_text_4) "misc_text_4"

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
## Code for deciding about restore operations.
## -----------------------------------------------------------------------------

set decision 1

if { $TEV(decision_override) != 0 } {
  set decision $TEV(decision_override)
}

sproc_broadcast_decision -decision $decision

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
