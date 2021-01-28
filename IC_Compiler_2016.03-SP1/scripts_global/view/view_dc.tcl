## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/view/view_dc.tcl#4 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2013.12-SP1
## HEADER_MSG    Copyright (c) 2014 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2013.12-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This task is used to interactively view a database with Design Compiler.
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

source -echo -verbose ../../scripts_block/rm_setup/dc_setup.tcl

set src_design $SEV(src_dir)/$DCRM_FINAL_DDC_OUTPUT_FILE

if { [file exists $src_design] } {

  read_ddc $src_design
  link

  if { [get_object_name [current_design]] != $DESIGN_NAME } {
    sproc_msg -warning "Design $DESIGN_NAME not found in $src_design"
    sproc_msg -warning "Exit tool or manually open design of interest"
  } else {
    sproc_msg -info "Design $DESIGN_NAME opened from $src_design"
  }

} else {

  sproc_msg -warning "Database $src_design not found"
  sproc_msg -warning "Exit tool or manually open design of interest"

}

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
