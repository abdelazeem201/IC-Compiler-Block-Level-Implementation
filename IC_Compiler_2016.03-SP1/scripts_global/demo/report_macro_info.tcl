#! /usr/bin/env tclsh
## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/demo/report_macro_info.tcl#35 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * Report hierarchy according to SVAR content.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Parse arguments
## -----------------------------------------------------------------------------

set argvar(techlib) ""
set argvar(block) ""

set error 0

for { set i 0 } { $i < [llength $argv] } { incr i } {
  set arg [lindex $argv $i]
  switch -- $arg {
    -techlib {
      incr i
      set argvar(techlib) [lindex $argv $i]
    }
    -block {
      incr i
      set argvar(block) [lindex $argv $i]
    }
    default {
      puts "Error: Unrecognized option: $arg"
      set error 1
    }
  }
}

if { $argvar(techlib) == "" } {
  puts "Error: You must specify an argument for -techlib"
  set error 1
}
if { $argvar(block) == "" } {
  puts "Error: You must specify an argument for -block"
  set error 1
}
if { ![file exists blocks]         || ![file isdirectory blocks] || \
    ![file exists scripts_global] || ![file isdirectory scripts_global] \
  } {
  puts "Error: You must run this script from the top of a workarea directory."
  set error 1
}

if { $error } {
  puts ""
  puts "Options are:"
  puts " -techlib <techlib> (Selects the techlib for reporting)"
  puts " -block <block>     (Selects the block for reporting)"
  puts ""
  exit
}

## -----------------------------------------------------------------------------
## Create variable reference
## -----------------------------------------------------------------------------

set SEV(techlib_dir)  NULL
set SEV(techlib_name) $argvar(techlib)
set SEV(gscript_dir)  scripts_global
set SEV(tscript_dir)  scripts_global/$argvar(techlib)
set SEV(bscript_dir)  blocks/$argvar(techlib)/$argvar(block)/scripts_block
set SEV(block_dir)    blocks/$argvar(techlib)/$argvar(block)
set SEV(block)        $argvar(block)

## -----------------------------------------------------------------------------
## For support of N-level hierarchical designs, we must consider the value of
## SVAR(hier,macro_info) for both the top-level design and also for the macro designs.
## These two procedures help make the code more manageable.
## -----------------------------------------------------------------------------

proc sproc_get_macro_info_get_svar_from_block { block } {
  global SEV
  source $SEV(tscript_dir)/common.tcl
  source $SEV(block_dir)/../$block/scripts_block/conf/block.tcl

  ## This unpacking and repacking ensures that macro_info_list is of a consistent format.
  set macro_info_list [list]
  foreach macro_info $SVAR(hier,macro_info) {
    set type            [lindex $macro_info 0]
    set design          [lindex $macro_info 1]
    set inst            [lindex $macro_info 2]
    set model_info_list [lindex $macro_info 3]
    set macro_info_new [list $type $design $inst $model_info_list]
    lappend macro_info_list $macro_info_new
  }

  return $macro_info_list
}

proc sproc_get_macro_info_resolve_macro_info_list { block inst_prefix depth ref_svar_blocks_queried } {

  ## -------------------------------------
  ## Keep track of all blocks that are queried.
  ## -------------------------------------

  upvar 1 $ref_svar_blocks_queried svar_blocks_queried
  if { [lsearch $svar_blocks_queried $block] == -1 } {
    lappend svar_blocks_queried $block
  }

  ## -------------------------------------
  ## Update instance names from SVAR(hier,macro_info) to reflect hierarchy.
  ## -------------------------------------

  set top_design_macro_info_list [list]
  set tmp_top_design_macro_info_list [sproc_get_macro_info_get_svar_from_block $block]
  foreach macro_info $tmp_top_design_macro_info_list {
    set type            [lindex $macro_info 0]
    set design          [lindex $macro_info 1]
    set inst            [lindex $macro_info 2]
    set model_info_list [lindex $macro_info 3]
    if { $inst_prefix == "" } {
      set inst_new $inst
    } else {
      set inst_new $inst_prefix/$inst
    }
    set macro_info_new [list $type $design $inst_new $model_info_list]
    lappend top_design_macro_info_list $macro_info_new
  }

  ## -------------------------------------
  ## Recursively process the designs that were specified in SVAR(hier,macro_info).
  ## -------------------------------------

  foreach macro_info $top_design_macro_info_list {
    set type            [lindex $macro_info 0]
    set design          [lindex $macro_info 1]
    set inst            [lindex $macro_info 2]
    set model_info_list [lindex $macro_info 3]

    set spaces [string repeat " " [expr $depth * 2]]
    puts "$spaces$design ($inst)"

    set sub_design_macro_info_list [sproc_get_macro_info_resolve_macro_info_list $design $inst [expr $depth + 1] svar_blocks_queried]

    foreach sub_design_macro_info $sub_design_macro_info_list {
      lappend top_design_macro_info_list $sub_design_macro_info
    }
  }

  return $top_design_macro_info_list
}

## -----------------------------------------------------------------------------
## Visit all block.tcl files and report design hierarchy information.
## -----------------------------------------------------------------------------

set svar_blocks_queried [list]

puts "## -------------------------------------"
puts "## Design Hierarchy: design (instance)"
puts "## -------------------------------------"
puts "$argvar(block)"

## -----------------------------------------------------------------------------
## Determine value from recursive examination of SVAR(hier,macro_info)
## -----------------------------------------------------------------------------

set macro_info_list [sproc_get_macro_info_resolve_macro_info_list $argvar(block) "" 1 svar_blocks_queried]

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
