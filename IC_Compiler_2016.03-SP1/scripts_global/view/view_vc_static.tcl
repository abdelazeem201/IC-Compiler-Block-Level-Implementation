## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/view/view_vc_static.tcl#3 $
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

## NAME: TEV(session)
## TYPE: file
## INFO:
## * Use this to specify a session file name.
set TEV(session) ""


set SEV(script_file) [info script]

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start

source ../../scripts_block/rm_setup/common_setup.tcl

## -----------------------------------------------------------------------------
## Load the session.
## -----------------------------------------------------------------------------

if { $TEV(session) != "" } {
  set load_session $TEV(session)
  sproc_msg -info "Restoring override session specified via TEV(session)"
} else {
  set load_session $SEV(src_dir)/$SVAR(design_name).
}

puts ""
sproc_msg -info "Loading VC Static session data $load_session"
puts ""

set args "-restore -session $load_session"

set args "$args -full64"
if { $SEV(gui) } { set args "$args -gui" }

sproc_msg -info "NOTE: The VC Static UI does not currently allow interactive prompt"
sproc_msg -info "when running from within a shell. Use GUI mode to control your debug"
sproc_msg -info "session. You can type 'exit' and other commands in the command shell"
sproc_msg -info "window but you will not see the commands echoed"
puts ""
set cmd "$SEV(cmd_vcst) $args"
sproc_msg -setup "$cmd"
catch { exec $SEV(exec_cmd) -c "$cmd" }

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
