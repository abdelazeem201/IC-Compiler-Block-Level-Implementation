## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/demo/demo_mux.tcl#21 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * Default selection task script to compare one metric across one or more tasks.
## * The result of the comparison is to link the task with the largest or smallest
## * metric value to the destination directory of the selection task.
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

## NAME: TEV(metric)
## TYPE: string
## INFO:
## * Specify a single metric to compare across sources
set TEV(metric) ""

## NAME: TEV(best_metric)
## TYPE: oos
## OOS_LIST: SMALLEST LARGEST
## INFO:
## * Specify which metric is best - largest or smallest, if metrics are the same
## * value then the first one will be used
set TEV(best_metric) "SMALLEST"

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
## Make sure there is a value for TEV(metric)
## -----------------------------------------------------------------------------

set error 0
set value ""

## Check required TEV options
if {$TEV(metric) == "" } {
  sproc_msg -error "No Value specified for TEV(metric)"
  incr error
}

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

## list of "src value number" for each enabled port
set port_info_list ""

if {$error ==0 } {

  if { $TEV(src_override) == "" } {

    set number_of_active_edges 0

    foreach item $SEV(parent_info) {
      set port_number [lindex $item 0]
      set port_enable [lindex $item 1]
      set port_src    [lindex $item 2]
      set port_task   [lindex $item 3]
      sproc_msg -info "port_number: $port_number"
      sproc_msg -info "  enable: $port_enable"
      sproc_msg -info "  src   : $port_src"
      sproc_msg -info "  task  : $port_task"
      if { $port_enable && ($port_src != "") } {
        incr number_of_active_edges
        set port_value [sproc_get_metric_value -source $port_src -task $port_task -metric $TEV(metric)]
        lappend port_info_list "$port_src $port_value $port_number"
      }
    }

    if {$TEV(best_metric) == "SMALLEST" } {
      set port_info_list [lsort -real -index 1 $port_info_list]
    } else {
      set port_info_list [lsort -decreasing -real -index 1 $port_info_list]
    }

    set active_port_src   [lindex [lindex $port_info_list 0] 0]
    set active_port_value [lindex [lindex $port_info_list 0] 1]

    sproc_msg -info "Selected source is $active_port_src with $TEV(best_metric) $TEV(metric) = $active_port_value"
    sproc_msg -info "METRIC | STRING INFO.SELECT_OPTIONS | $TEV(metric): $port_info_list"
    sproc_msg -info "METRIC | STRING INFO.SELECT_RESULT  | $active_port_src $active_port_value"

  } else {

    set number_of_active_edges 1
    set active_port_src $TEV(src_override)

    sproc_msg -warning "Overriding default source selection"
    sproc_msg -warning "TEV(src_override) set to: '$TEV(src_override)'"

  }

  switch $number_of_active_edges {
    0 {
      sproc_msg -error "No valid source directories available"
    }

    default {

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
  }
}

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
