## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/mux_task.tcl#38 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script performs the default processing for mux_task objects.
## -----------------------------------------------------------------------------

source ../../scripts_global/conf/procs.tcl
sproc_source -file ../../scripts_global/conf/system.tcl
sproc_source -file $env(LYNX_VARFILE_SEV)
sproc_source -file ../../scripts_global/conf/system_setup.tcl
sproc_source -file $SEV(tscript_dir)/common.tcl
sproc_source -file $SEV(bscript_dir)/conf/block.tcl

## NAME: TEV(src_override)
## TYPE: string
## INFO:
## * Used to specify a source directory for linking, without regard to normal checks.
set TEV(src_override) ""

## NAME: TEV(allow_none_selected)
## TYPE: boolean
## INFO:
## * Used to allow a mux configured with no inputs selected. This will inhibit issuing
## * a SNPS_ERROR. This is generally useful for 1-bit muxes or muxes where no data is
## * copied forward.
set TEV(allow_none_selected) "0"

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
## If TEV(src_override) is not used:
##   Query information about edges.
##   Link the source data, as specified by the active edge, if there is exactly one active edge.
##   Otherwise, generate an error.
##
## If TEV(src_override) is used:
##   Link the source data, as specified by the TEV(src_override), if it exists.
##   Otherwise, generate an error.
## -----------------------------------------------------------------------------

if { $TEV(src_override) == "" } {

  set number_of_active_edges 0

  foreach item $SEV(parent_info) {
    set port_number [lindex $item 0]
    set port_enable [lindex $item 1]
    set port_src    [lindex $item 2]
    sproc_msg -info "port_number: $port_number"
    sproc_msg -info "  enable: $port_enable"
    sproc_msg -info "  source: $port_src"
    if { $port_enable && ($port_src != "") } {
      incr number_of_active_edges
      set active_port_number $port_number
      set active_port_src    $port_src
    }
  }

} else {

  set number_of_active_edges 1
  set active_port_src $TEV(src_override)

  sproc_msg -warning "Overriding default source selection"
  sproc_msg -warning "TEV(src_override) set to: '$TEV(src_override)'"

}

switch $number_of_active_edges {
  0 {
    if { $TEV(allow_none_selected) } {
      sproc_msg -info "No inputs selected."
    } else {
      sproc_msg -error "No valid source directories available"
    }
  }

  1 {

    set src_dir $SEV(block_dir)/$SEV(step)/work/$active_port_src

    if { ![file exists $src_dir] } {
      sproc_msg -error "The source directory does not exist: '$src_dir'"
    }

    if { $src_dir != $SEV(dst_dir) } {
      sproc_msg -info "Linking data:"
      sproc_msg -info "  From : $src_dir/"
      sproc_msg -info "  To   : $SEV(dst_dir)/"

      set i 0
      if { [file exists $SEV(dst_dir)] && ($i < 10) } {
        sproc_msg -warning "Deleting '$SEV(dst_dir)' since it already exists. Attempt $i"
        file delete -force $SEV(dst_dir)
        incr i
        exec sleep 1
      }

      set i 0
      while { [file exists $SEV(dst_dir)] && ($i < 100) } {
        puts "Waiting for NFS flush. Attempt $i"
        exec sleep 1
        incr i
      }

      file link $SEV(dst_dir) $src_dir
    }
  }

  default {
    sproc_msg -error "Multiple valid source directories available"
  }

}

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
