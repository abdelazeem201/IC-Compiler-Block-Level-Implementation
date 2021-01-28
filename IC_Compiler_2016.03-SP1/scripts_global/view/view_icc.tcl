## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/view/view_icc.tcl#4 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2013.12-SP1
## HEADER_MSG    Copyright (c) 2014 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2013.12-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively view a database with IC Compiler.
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

source -echo -verbose ../../scripts_block/rm_setup/icc_setup.tcl

## Cell in LCRM is named to reflect the task script
set cel_name [file tail $SEV(src_dir)]

if { [file exists $MW_DESIGN_LIBRARY] } {

  open_mw_cel -library $MW_DESIGN_LIBRARY $cel_name

  if { [current_design] != $DESIGN_NAME } {

    sproc_msg -warning "CEL $cel_name not found in $MW_DESIGN_LIBRARY"
    sproc_msg -warning "Exit tool or manually open CEL of interest"

  } else {

    sproc_msg -info "CEL $cel_name opened from $MW_DESIGN_LIBRARY"

  }

}  else {

  sproc_msg -warning "Milkyway library $MW_DESIGN_LIBRARY does not exist. Check your MW_DESIGN_LIBRARY setup."

}


sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
