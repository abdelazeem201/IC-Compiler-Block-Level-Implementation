## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/view/view_fm.tcl#4 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2013.12-SP1
## HEADER_MSG    Copyright (c) 2014 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2013.12-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively view a saved Formality session
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

set session_name "NULL"

## This code handles location of session based on which product LCRM is in use

set src_reports ../rpts/$SEV(src)

if { $SEV(step)=="rm_dc" } {
  source -echo -verbose ../../scripts_block/rm_setup/dc_setup.tcl
  set session_name ${FMRM_FAILING_SESSION_NAME}
} 

if { $SEV(step)=="rm_icc" } {
  source -echo -verbose ../../scripts_block/rm_setup/icc_setup.tcl
  set session_name ${DESIGN_NAME}
} 

if { !([file extension $session_name] == "fss") } {
  set session_name $session_name.fss
}

set src_session $src_reports/$session_name

if { [file exists $src_session] } {

  restore_session  $src_session
  sproc_msg -info "Saved session $src_session is restored"

} else {

  sproc_msg -warning "Source design $src_session does not exist."

}

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
