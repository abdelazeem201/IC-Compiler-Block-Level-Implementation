## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_report_flow.tcl#26 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains procedures used to automatically generate flow documentation.
## -----------------------------------------------------------------------------

proc rtm_report_flow { args } {

  global stdout
  global SEV env

  set options(-block) ""
  set options(-obj) "*"
  set options(-over) 0
  set options(-sev) 0
  set options(-svar) 0
  set options(-flow) 0
  set options(-out) ""
  set options(-force) 0
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Detect LCRM mode
  ## -------------------------------------

  if { [info exists env(LYNX_LCRM_MODE)] } {
    set LYNX(lcrm_mode) 1
  } else {
    set LYNX(lcrm_mode) 0
  }

  ## -------------------------------------
  ## Validate the block to be documented.
  ## -------------------------------------

  set block_list [get_blocks *]
  if { [lsearch $block_list $options(-block)] == -1 } {
    puts "Error: Invalid block specified. The available blocks are:"
    foreach block $block_list {
      puts "         $block"
    }
    return
  }

  ## -------------------------------------
  ## Setup output
  ## -------------------------------------

  if { $options(-out) == "" } {
    ## Output to console
    set fout stdout
  } else {
    ## Output to file
    if { $options(-force) } {
      file delete -force $options(-out)
    }
    set fout [open $options(-out) w]
  }

  ## -------------------------------------
  ## Report: header
  ## -------------------------------------

  puts $fout "## [string repeat - 77]"
  puts $fout "## rtm_report_flow"
  puts $fout "##"
  puts $fout "## Date    : [clock format [clock seconds]]"

  set option_string "-block $options(-block) -obj $options(-obj)"
  if { $options(-over) } { set option_string "$option_string -over" }
  if { $options(-sev)  } { set option_string "$option_string -sev" }
  if { $options(-svar) } { set option_string "$option_string -svar" }
  if { $options(-flow) } { set option_string "$option_string -flow" }
  puts $fout "## Options : $option_string"
  puts $fout "## [string repeat - 77]"

  ## -------------------------------------
  ## Develop list of flows and tasks
  ## -------------------------------------

  current_block $options(-block)

  set flow_item_list [list]
  foreach { flow_name flow_file } [get_flows] {
    set flow_item [list $flow_name $flow_file]
    lappend flow_item_list $flow_item
  }
  set flow_item_list [lsort -ascii -increasing -index 0 $flow_item_list]

  set top_flow_file [get_topflow_file]

  set obj_item_list [list]
  unset -nocomplain obj_info_array

  foreach flow_item $flow_item_list {

    set flow_name [lindex $flow_item 0]
    set flow_file [lindex $flow_item 1]
    if { $top_flow_file == $flow_file } {
      set top_flow_name $flow_name
    }

    set id [fe_flow_open -filename $flow_file]

    set obj_list [fe_task_list -id $id]
    foreach obj_name $obj_list {
      set obj_type [fe_task_type -id $id -task $obj_name]
      if { [lsearch { tool_task gen_task branch_task join_task flow_inst mux_task } $obj_type] == -1 } {
        continue
      }

      switch $obj_type {
        flow_inst {
          unset -nocomplain TMP
          array set TMP [fe_task_get -id $id -task $obj_name]
          set full_obj_name $flow_name/$TMP(flow)
        }
        join_task -
        tool_task -
        gen_task -
        branch_task -
        mux_task {
          set full_obj_name $flow_name/$obj_name
          unset -nocomplain TASK_ATTR
          if { $options(-over) } {
            array set TASK_ATTR [fe_task_get -id $id -task $obj_name -data_source file_override]
          } else {
            array set TASK_ATTR [fe_task_get -id $id -task $obj_name -data_source final]
          }
          foreach index [array names TASK_ATTR] {
            set obj_info_array($full_obj_name,$index) $TASK_ATTR($index)
          }
        }
        default {
          puts "Error: Should not get here"
        }
      }

      set obj_item [list $full_obj_name $obj_type]
      lappend obj_item_list $obj_item
    }

    fe_flow_close -id $id
  }

  set tmp_found 0
  set tmp_obj_item_list [list]
  foreach obj_item $obj_item_list {
    set full_obj_name [lindex $obj_item 0]
    set obj_type      [lindex $obj_item 1]
    if { [string match $options(-obj) $full_obj_name] } {
      set tmp_found 1
      lappend tmp_obj_item_list $obj_item
    }
  }
  if { $tmp_found } {
    set obj_item_list [lsort -ascii -increasing -index 0 $tmp_obj_item_list]
  } else {
    puts "Error: Unable to find object matching pattern '$options(-obj)'."
    return
  }

  ## -------------------------------------
  ## Report: Flow XML
  ## -------------------------------------

  if { $options(-flow) } {

    puts $fout ""
    puts $fout "## [string repeat - 77]"
    puts $fout "## Top Flow (flow_name : flow_file):"
    puts $fout "## [string repeat - 77]"
    puts $fout ""
    puts $fout "  $top_flow_name:$top_flow_file"
    puts $fout ""
    puts $fout "## [string repeat - 77]"
    puts $fout "## Referenced Flows (flow_name:flow_file):"
    puts $fout "## [string repeat - 77]"
    puts $fout ""

    foreach flow_item $flow_item_list {
      set flow_name [lindex $flow_item 0]
      set flow_file [lindex $flow_item 1]
      puts $fout "  $flow_name : $flow_file"
    }

  }

  ## -------------------------------------
  ## Report: Task details
  ## -------------------------------------

  set special_attr_list [list \
    variables \
    ]

  ## At some point, we may want to add these to the special_attr_list.
  ## must_have_list \
  ## must_not_have_list \
  ## must_allow_list \

  puts $fout ""
  puts $fout "## [string repeat - 77]"
  puts $fout "## Flow Object Details (obj_name : obj_type):"
  puts $fout "## [string repeat - 77]"

  set obj_count 0

  foreach obj_item $obj_item_list {

    incr obj_count

    set full_obj_name [lindex $obj_item 0]
    set obj_type      [lindex $obj_item 1]

    set index_list [array names obj_info_array -glob $full_obj_name,*]
    set index_list [lsort -ascii -increasing $index_list]

    if { $options(-over) } {
      ## Only list object if there is information to report
      if { [llength $index_list] != 0 } {
        puts $fout ""
        puts $fout "  $full_obj_name : $obj_type"
      }
    } else {
      puts $fout ""
      puts $fout "  $full_obj_name : $obj_type"
    }

    foreach index $index_list {
      regexp {.*,(.*)} $index match attr
      if { [lsearch $special_attr_list $attr] != -1 } {
        ## Some attr require special processing
        continue
      }
      puts $fout "    $attr : $obj_info_array($full_obj_name,$attr)"
    }

    foreach attr $special_attr_list {

      if { $attr == "variables" } {
        if { ($obj_type == "flow_inst") || ($obj_type == "join_task") } {
          ## Nothing to report
        } else {
          if { [info exists obj_info_array($full_obj_name,$attr)] } {
            puts $fout "    $attr:"
            set item_list [list]
            foreach { name value } $obj_info_array($full_obj_name,$attr) {
              set item [list $name $value]
              lappend item_list $item
            }
            set item_list [lsort -ascii -increasing -index 0 $item_list]
            foreach item $item_list {
              set name  [lindex $item 0]
              set value [lindex $item 1]
              puts $fout "      $name : $value"
            }
          }
        }
      }

    }

  }

  puts $fout ""
  puts $fout "Total Object Count: $obj_count"

  ## -------------------------------------
  ## Report: SEV content
  ## -------------------------------------

  if { $options(-sev) } {

    puts $fout ""
    puts $fout "## [string repeat - 77]"
    puts $fout "## SEV Content (name : value):"
    puts $fout "## [string repeat - 77]"
    puts $fout ""

    set name_list [var_names -name SEV(*)]
    set name_list [lsort -ascii -increasing $name_list]
    foreach name $name_list {
      set value [var_get -name $name]
      puts $fout "  $name : $value"
    }

  }

  ## -------------------------------------
  ## Report: SVAR content
  ## -------------------------------------

  if { $options(-svar) } {

    puts $fout ""
    puts $fout "## [string repeat - 77]"
    puts $fout "## SVAR Content (name : value):"
    puts $fout "## [string repeat - 77]"
    puts $fout ""

    set name_list [var_names -name SVAR(*)]
    set name_list [lsort -ascii -increasing $name_list]
    foreach name $name_list {
      set value [var_get -block_name $options(-block) -name $name]
      puts $fout "  $name : $value"
    }

  }

  ## -------------------------------------
  ## Close report
  ## -------------------------------------

  puts $fout ""
  puts $fout "<end of report>"

  if { $fout != "stdout" } {
    close $fout
  }

  puts ""
  puts "Done!"

}

define_proc_attributes rtm_report_flow \
  -info "This command is used to generate an ASCII flow report." \
  -define_args {
  {-block "Specifies the block to be reported." AString string required}
  {-obj   "Pattern specifying the object(s) to be reported. (flow_name/task_name)" AString string optional}
  {-over  "Report override info only for specified object(s)." "" boolean optional}
  {-sev   "Reports on SEV variable content." "" boolean optional}
  {-svar  "Reports on SVAR variable content." "" boolean optional}
  {-flow  "Reports on flow file content." "" boolean optional}
  {-out   "Specifies the output file." AString string optional}
  {-force "Forces overwrite of output file." "" boolean optional}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
