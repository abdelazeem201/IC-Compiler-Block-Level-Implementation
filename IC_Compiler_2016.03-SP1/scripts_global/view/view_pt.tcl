## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/view/view_pt.tcl#4 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2013.12-SP1
## HEADER_MSG    Copyright (c) 2014 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2013.12-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively work in Primetime
## * This version is for use with Lynx-Compatible RM flow
## * The task is suitable for :
## *    1) GUI analysis and debug
## *    2) Command line analysis and debug
## *    3) Starting point for a custom script
## -----------------------------------------------------------------------------

## dont show all the variable creation messages at the end
suppress_message CMD-041

set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start

source ../../scripts_block/rm_setup/common_setup.tcl
source ../../scripts_block/rm_setup/pt_setup.tcl

sproc_msg -warning "PT shell setup. Designs can be opened manually from here."

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
