## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_generate_flow_docs.tcl#46 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains procedures used to automatically generate flow documentation.
## -----------------------------------------------------------------------------

proc rtm_generate_flow_docs { args } {

  global SEV env

  set options(-block) ""
  set options(-dir) ""
  set options(-force) 0
  set options(-debug) 0
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
  ## Create the documentation directory.
  ## -------------------------------------

  if { [file exists $options(-dir)] } {
    if { $options(-force) } {
      file delete -force $options(-dir)
    } else {
      puts "Error: The specified directory already exists."
      puts "       Specify a different directory or use the '-force' option."
      return
    }
  }

  ## -------------------------------------
  ## Set some DOC() variables.
  ## -------------------------------------

  set DOC(dir)     $options(-dir)
  set DOC(block)   $options(-block)
  set DOC(techlib) [current_techlib]
  set DOC(rpt)     $DOC(dir)/rpt.txt

  set DOC(color,top_flow)    #00ff00
  set DOC(color,tool_task)   #9775dc
  set DOC(color,gen_task)    #ffff24
  set DOC(color,branch_task) #ff1f1f
  set DOC(color,join_task)   #ff0fff
  set DOC(color,mux_task)    #21d321
  set DOC(color,flow_inst)   #ffa90c
  set DOC(color,black)       #000000
  set DOC(color,white)       #ffffff
  set DOC(color,gray)        #c0c0c0
  set DOC(color,red)         #ff0000
  set DOC(color,yellow)      #ffff00
  set DOC(color,blue)        #00b0ff
  set DOC(color,link)        #000000

  ## -------------------------------------
  ## Populate scripts
  ## -------------------------------------

  current_block $DOC(block)

  file mkdir $DOC(dir)
  file mkdir $DOC(dir)/images
  file mkdir $DOC(dir)/html

  puts "Info: Copying global scripts"

  set dir_src $SEV(workarea_dir)/scripts_global
  set dir_dst $DOC(dir)
  set cmd "cp -RL $dir_src $dir_dst"
  eval exec $cmd
  catch { exec find $DOC(dir)/scripts_global -type f } results
  foreach file $results {
    file rename -force $file $file.txt
  }

  puts "Info: Copying block scripts"

  if { $LYNX(lcrm_mode) } {
    set dir_src $SEV(workarea_dir)/$DOC(block)/scripts_block
    set dir_dst $DOC(dir)/$DOC(block)
  } else {
    set dir_src $SEV(workarea_dir)/blocks/$DOC(techlib)/$DOC(block)/scripts_block
    set dir_dst $DOC(dir)/blocks/$DOC(techlib)/$DOC(block)
  }
  if { [file exists $dir_src] } {
    file mkdir $dir_dst
    set cmd "cp -RL $dir_src $dir_dst"
    eval exec $cmd
    catch { exec find $dir_dst -type f } results
    foreach file $results {
      file rename -force $file $file.txt
    }
  }

  ## -------------------------------------
  ## Set remaining DOC() variables.
  ## -------------------------------------

  ## Generate DOC(flows) while creating image files

  puts "Info: Generating flow images"

  set top_flow_file [get_topflow_file]

  set flow_item_list [list]
  foreach { flow_name flow_file } [get_flows] {
    puts -nonewline "."
    flush stdout
    set flow_image images/$flow_name.png
    set image_file $DOC(dir)/images/$flow_name.png

    ## generate_flow_diagram -file_name $flow_file -output_file $image_file
    set id [fe_flow_open -filename $flow_file]
    fe_flow_image -id $id -filename $image_file
    fe_flow_close -id $id

    set flow_item [list $flow_name $flow_file $flow_image]
    lappend flow_item_list $flow_item
  }
  puts ""

  set flow_item_list [lsort -ascii -increasing -index 0 $flow_item_list]

  set DOC(flows) [list]
  foreach flow_item $flow_item_list {
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]
    set tmp_item [list $flow_name $flow_file $flow_image]
    if { $flow_file == $top_flow_file } {
      lappend DOC(flows) $tmp_item
    }
  }
  foreach flow_item $flow_item_list {
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]
    set tmp_item [list $flow_name $flow_file $flow_image]
    if { $flow_file != $top_flow_file } {
      lappend DOC(flows) $tmp_item
    }
  }

  ## Generate DOC(flow_objs,$flow_name)

  puts "Info: Gathering task information"

  foreach flow_item $DOC(flows) {
    puts -nonewline "."
    flush stdout

    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]

    set id [fe_flow_open -filename $flow_file]

    set flow_name   [fe_flow_name -id $id]
    set DOC(obj_info,$flow_name) [list]

    set flow_obj_list [fe_task_list -id $id]

    foreach obj_name $flow_obj_list {
      set obj_type [fe_task_type -id $id -task $obj_name]
      if { [lsearch { tool_task gen_task branch_task join_task flow_inst mux_task } $obj_type] == -1 } {
        continue
      }
      if { $obj_type == "flow_inst" } {
        unset -nocomplain TMP
        array set TMP [fe_task_get -id $id -task $obj_name]
        set obj_item [list $TMP(flow) $obj_type]
      } else {
        set obj_item [list $obj_name $obj_type]
      }
      lappend DOC(obj_info,$flow_name) $obj_item
    }

    fe_flow_close -id $id

    set DOC(obj_info,$flow_name) [lsort -ascii -increasing -index 0 $DOC(obj_info,$flow_name)]
  }
  puts ""

  if { $options(-debug) } {
    puts "Info: DOC(flows) :"
    foreach flow_item $DOC(flows) {
      set flow_name  [lindex $flow_item 0]
      set flow_file  [lindex $flow_item 1]
      set flow_image [lindex $flow_item 2]
      puts "Info:   $flow_name $flow_file $flow_image"
    }
    foreach flow_item $DOC(flows) {
      set flow_name  [lindex $flow_item 0]
      set flow_file  [lindex $flow_item 1]
      set flow_image [lindex $flow_item 2]
      puts "Info: DOC(obj_info,$flow_name) :"
      foreach obj_item $DOC(obj_info,$flow_name) {
        set obj_name [lindex $obj_item 0]
        set obj_type [lindex $obj_item 1]
        puts "Info:   $obj_name $obj_type"
      }
    }
    puts "Info: Exiting early in debug mode."

    ## EXAMPLE:BEGIN
    ##
    ## set flow_file /global/lynx_dev/users/styson/rtm_dev/scripts_global/flows/syn.xml
    ## set obj_name select_results
    ## set id [fe_flow_open -filename $flow_file]
    ##
    ## unset -nocomplain TASK_ATTR_FINAL
    ## unset -nocomplain TASK_ATTR_OVERRIDE
    ## unset -nocomplain TASK_ATTR_FLOWXML
    ## unset -nocomplain SCRIPT_ATTR
    ##
    ## array set TASK_ATTR_FINAL    [fe_task_get -id $id -task $obj_name -data_source final]
    ## array set TASK_ATTR_OVERRIDE [fe_task_get -id $id -task $obj_name -data_source file_override]
    ## array set TASK_ATTR_FLOWXML  [fe_task_get -id $id -task $obj_name -data_source file_xml]
    ##
    ## fe_flow_close -id $id
    ##
    ## parray TASK_ATTR_FINAL
    ##
    ## EXAMPLE:END

    return
  }

  puts "Info: Generating overview"
  _rtm_generate_flow_docs_overview $DOC(dir)/index.html [array get DOC]

  puts "Info: Generating flow and task summaries"
  foreach flow_item $DOC(flows) {
    puts -nonewline "."
    flush stdout
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]
    _rtm_generate_flow_docs_flow_summary $DOC(dir)/html/$flow_name.html [array get DOC] $flow_name
    foreach obj_item $DOC(obj_info,$flow_name) {
      set obj_name [lindex $obj_item 0]
      set obj_type [lindex $obj_item 1]
      if { [lsearch { tool_task gen_task branch_task mux_task } $obj_type] == -1 } {
        continue
      }
      _rtm_generate_flow_docs_obj_summary $DOC(dir)/html/$flow_name@$obj_name.html [array get DOC] $flow_name $obj_name $obj_type
    }
  }
  puts ""
  puts "Done!"
  puts ""
}

define_proc_attributes rtm_generate_flow_docs \
  -info "This command is used to generate HTML flow documentation." \
  -define_args {
  {-block "Specifies the block to be documented." AString string required}
  {-dir "Specifies the documentation directory to create." AString string required}
  {-force "Forces deletion of existing documentation directory." "" boolean optional}
  {-debug "For debugging documentation functions." "" boolean optional}
}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_overview:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_overview { output_file doc_array } {

  global SEV env

  array set DOC $doc_array

  ## -------------------------------------
  ## Detect LCRM mode
  ## -------------------------------------

  if { [info exists env(LYNX_LCRM_MODE)] } {
    set LYNX(lcrm_mode) 1
  } else {
    set LYNX(lcrm_mode) 0
  }

  ## -------------------------------------
  ## Create html
  ## -------------------------------------

  ## -------------------------------------
  ## Open file
  ## -------------------------------------

  set fid(html) [open $output_file w]

  puts $fid(html) "<!DOCTYPE html>"
  puts $fid(html) "<html>"
  puts $fid(html) "<body link=\"$DOC(color,link)\">"
  puts $fid(html) "<head>"
  puts $fid(html) "<title>Flow Overview: $DOC(block)</title>"
  puts $fid(html) "</head>"
  puts $fid(html) "<body>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"container\">"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"header\" style=\"color:$DOC(color,white);background-color:$DOC(color,black);margin-bottom:50px;\">"
  puts $fid(html) "  <h1>Flow Overview: $DOC(block)</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"t1\" style=\"float:left\" >"
  puts $fid(html) ""

  ## -------------------------------------
  ## Table for flows
  ## -------------------------------------

  puts $fid(html) "<table border=\"1\">"
  puts $fid(html) "<tr>"
  puts $fid(html) "<th colspan=\"3\" bgcolor=$DOC(color,gray)>Available Flows</th>"
  puts $fid(html) "</tr>"
  puts $fid(html) "<tr>"
  puts $fid(html) "<th bgcolor=$DOC(color,gray)>Name</th>"
  puts $fid(html) "<th bgcolor=$DOC(color,gray)>Summary</th>"
  puts $fid(html) "<th bgcolor=$DOC(color,gray)>Diagram</th>"
  puts $fid(html) "</tr>"

  set top_flow_flag 1
  foreach flow_item $DOC(flows) {
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]

    if { $top_flow_flag } {
      set color $DOC(color,top_flow)
    } else {
      set color $DOC(color,white)
    }
    puts $fid(html) "<tr>"
    puts $fid(html) "<td bgcolor=$color>$flow_name</td>"
    puts $fid(html) "<td bgcolor=$color><a href=\"html/$flow_name.html\">View Summary</a></td>"
    puts $fid(html) "<td bgcolor=$color><a href=\"$flow_image\">View Diagram</a></td>"
    puts $fid(html) "</tr>"
    set top_flow_flag 0

    set flow_file_short $flow_file
    set flow_file_short [regsub $SEV(bscript_dir) $flow_file_short "\$SEV(bscript_dir)"]
    set flow_file_short [regsub $SEV(tscript_dir) $flow_file_short "\$SEV(tscript_dir)"]
    set flow_file_short [regsub $SEV(gscript_dir) $flow_file_short "\$SEV(gscript_dir)"]
  }
  puts $fid(html) "</table>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Table for important files
  ## -------------------------------------

  puts $fid(html) "<div id=\"t2\" style=\"float:left;margin-left:50px\" >"
  puts $fid(html) ""

  if { $LYNX(lcrm_mode) } {
    set important_files [glob \
      scripts_global/conf/system.tcl \
      scripts_global/conf/global_error_checks.xml \
      $DOC(block)/scripts_block/lcrm_setup/lcrm_setup.tcl \
      $DOC(block)/scripts_block/rm_setup/*_setup.tcl \
      ]
  } else {
    set important_files [list \
      scripts_global/conf/system.tcl \
      scripts_global/conf/system_setup.tcl \
      scripts_global/conf/global_error_checks.xml \
      blocks/$DOC(techlib)/$DOC(block)/scripts_block/conf/block.tcl \
      blocks/$DOC(techlib)/$DOC(block)/scripts_block/conf/block_setup.tcl \
      ]
  }

  puts $fid(html) "<table border=\"1\">"
  puts $fid(html) "<tr>"
  puts $fid(html) "<th bgcolor=$DOC(color,gray)>Important Files</th>"
  puts $fid(html) "</tr>"

  foreach file $important_files {
    puts $fid(html) "<tr><td bgcolor=$DOC(color,white)><a href=\"$file.txt\">[file tail $file]</a></td></tr>"
  }
  puts $fid(html) "</table>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Table for cross-reference files
  ## -------------------------------------

  if { !$LYNX(lcrm_mode) } {

    puts $fid(html) "<div id=\"t3\" style=\"float:left;margin-left:50px\" >"
    puts $fid(html) ""

    puts $fid(html) "<table border=\"1\">"
    puts $fid(html) "<tr>"
    puts $fid(html) "<th bgcolor=$DOC(color,gray)>Cross-References</th>"
    puts $fid(html) "</tr>"

    puts $fid(html) "<tr><td bgcolor=$DOC(color,white)><a href=\"proc_xref.html\">Procedures</a></td></tr>"
    puts $fid(html) "<tr><td bgcolor=$DOC(color,white)><a href=\"svar_xref.html\">SVAR Variables</a></td></tr>"

    puts $fid(html) "</table>"
    puts $fid(html) ""

    puts $fid(html) "</div>"
    puts $fid(html) ""

    _rtm_generate_flow_docs_proc_xref $DOC(dir)/proc_xref.html [array get DOC]
    _rtm_generate_flow_docs_svar_xref $DOC(dir)/svar_xref.html [array get DOC]

  }

  ## -------------------------------------

  puts $fid(html) "<div id=\"spacer\" style=\"clear:both;\">"
  puts $fid(html) "  <h1>&nbsp</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"footer\" style=\"color:$DOC(color,white);background-color:$DOC(color,black);clear:both;\">"
  puts $fid(html) "  <h1>End Overview</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Close file
  ## -------------------------------------

  puts $fid(html) "</body>"
  puts $fid(html) "</html>"
  close $fid(html)

}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_flow_summary:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_flow_summary { output_file doc_array flow_name_arg } {

  global SEV

  array set DOC $doc_array

  ## -------------------------------------
  ## Select the specific flow_item
  ## -------------------------------------

  foreach flow_item $DOC(flows) {
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]
    if { $flow_name == $flow_name_arg } {
      break
    }
  }

  ## -------------------------------------
  ## Create html
  ## -------------------------------------

  ## -------------------------------------
  ## Open file
  ## -------------------------------------

  set fid(html) [open $output_file w]

  puts $fid(html) "<!DOCTYPE html>"
  puts $fid(html) "<html>"
  puts $fid(html) "<body link=\"$DOC(color,link)\">"
  puts $fid(html) "<head>"
  puts $fid(html) "<title>Flow Summary: $flow_name</title>"
  puts $fid(html) "</head>"
  puts $fid(html) "<body>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"container\">"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,flow_inst);margin-bottom:20px;\">"
  puts $fid(html) "  <h1>Flow Summary: $flow_name</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "<table border=\"0\">"
  puts $fid(html) "<tr>"
  puts $fid(html) ""

  puts $fid(html) "<td>"
  puts $fid(html) "  <table border=\"1\">"
  puts $fid(html) "  <caption>Objects Within Flow</caption>"
  puts $fid(html) "  <tr>"
  puts $fid(html) "  <th bgcolor=$DOC(color,gray)>Name</th>"
  puts $fid(html) "  <th bgcolor=$DOC(color,gray)>Type</th>"
  puts $fid(html) "  <th bgcolor=$DOC(color,gray)>Info</th>"
  puts $fid(html) "  </tr>"

  foreach obj_item $DOC(obj_info,$flow_name) {
    set obj_name [lindex $obj_item 0]
    set obj_type [lindex $obj_item 1]
    switch $obj_type {
      tool_task   { set color $DOC(color,$obj_type) }
      gen_task    { set color $DOC(color,$obj_type) }
      branch_task { set color $DOC(color,$obj_type) }
      join_task   { set color $DOC(color,$obj_type) }
      mux_task    { set color $DOC(color,$obj_type) }
      flow_inst   { set color $DOC(color,$obj_type) }
      default     { set color $DOC(color,white) }
    }
    puts $fid(html) "  <tr>"
    puts $fid(html) "  <td bgcolor=$DOC(color,white)>$obj_name</td>"
    puts $fid(html) "  <td bgcolor=$color>$obj_type</td>"
    switch $obj_type {
      tool_task -
      gen_task -
      branch_task -
      mux_task {
        puts $fid(html) "  <td bgcolor=$DOC(color,white)><a href=\"../html/$flow_name@$obj_name.html\">Task Info</a></td>"
      }
      join_task {
        puts $fid(html) "  <td bgcolor=$DOC(color,white)>NA</td>"
      }
      flow_inst {
        puts $fid(html) "  <td bgcolor=$DOC(color,white)><a href=\"../html/$obj_name.html\">Flow Summary</a></td>"
      }
    }
    puts $fid(html) "  </tr>"

  }
  puts $fid(html) "  </table>"
  puts $fid(html) "</td>"
  puts $fid(html) ""

  puts $fid(html) "<td>"
  puts $fid(html) "  &nbsp;&nbsp;&nbsp;&nbsp;"
  puts $fid(html) "</td>"
  puts $fid(html) ""

  puts $fid(html) "<td>"
  puts $fid(html) "  <a href=\"../$flow_image\">"
  puts $fid(html) "    <img src=\"../$flow_image\" style=\"border:5px solid black\" width=\"500px\"></img>"
  puts $fid(html) "  </a>"
  puts $fid(html) "</td>"
  puts $fid(html) ""

  puts $fid(html) "</tr>"
  puts $fid(html) "</table>"
  puts $fid(html) ""

  puts $fid(html) "<br>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,flow_inst);clear:both;text-align:center;\">"
  puts $fid(html) "  <a href=\"../index.html\">(Back to Flow Overview)</a>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Close file
  ## -------------------------------------

  puts $fid(html) "</body>"
  puts $fid(html) "</html>"
  close $fid(html)

}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_attr_level:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_attr_level { target doc_array TASK_ATTR_FINAL TASK_ATTR_OVERRIDE TASK_ATTR_FLOWXML } {

  array set DOC      $doc_array
  array set FINAL    $TASK_ATTR_FINAL
  array set OVERRIDE $TASK_ATTR_OVERRIDE
  array set FLOWXML  $TASK_ATTR_FLOWXML

  set return_source default
  set return_value  ""

  foreach name [array names FINAL] {
    if { $name == $target } {
      set return_value $FINAL($name)
      if { [info exists FLOWXML($name)] } {
        if { ($target == "tool") || ($target == "script_file") || ($target == "ports") } {
          ## Dont treat these specifications in the XML as non-default
        } else {
          set return_source flowxml
        }
      }
      if { [info exists OVERRIDE($name)] } {
        set return_source override
      }
      break
    }
  }

  if { ($target == "tool") && ($return_value == "") } {
    ## There is a bug in the fe_task_get command.
    ## No array entry for "tool" is being provided for gen_task or branch_task objects.
    ## This workaround assigns a value for "tool" if none is found.
    set return_value tcl
  }

  switch $return_source {
    default  { set return_bgcolor $DOC(color,white) }
    flowxml  { set return_bgcolor $DOC(color,yellow) }
    override { set return_bgcolor $DOC(color,blue) }
  }

  set return_item [list $return_bgcolor $return_value]
  return $return_item
}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_tev_level:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_tev_level { target doc_array SCRIPT_ATTR TASK_ATTR_FINAL TASK_ATTR_OVERRIDE TASK_ATTR_FLOWXML } {

  array set DOC      $doc_array
  array set SCRIPT   $SCRIPT_ATTR
  array set FINAL    $TASK_ATTR_FINAL
  array set OVERRIDE $TASK_ATTR_OVERRIDE
  array set FLOWXML  $TASK_ATTR_FLOWXML

  array set array_script $SCRIPT(script_variable_value)
  array set array_final  $FINAL(variables)
  if { [info exists OVERRIDE(variables)] } {
    array set array_override $OVERRIDE(variables)
  } else {
    array set array_override "foo foo"
  }
  if { [info exists FLOWXML(variables)] } {
    array set array_flowxml $FLOWXML(variables)
  } else {
    array set array_flowxml "foo foo"
  }

  set return_source default
  set return_value  ""
  set return_is_aux 0

  foreach name [array names array_final] {
    if { $name == $target } {
      set return_value $array_final($name)
      if { [info exists array_flowxml($name)] } {
        set return_source flowxml
      }
      if { [info exists array_override($name)] } {
        set return_source override
      }
      if { ![info exists array_script($name)] } {
        set return_is_aux 1
      }
      break
    }
  }

  switch $return_source {
    default  { set return_bgcolor $DOC(color,white) }
    flowxml  { set return_bgcolor $DOC(color,yellow) }
    override { set return_bgcolor $DOC(color,blue) }
  }

  set return_item [list $return_bgcolor $return_value $return_is_aux]
  return $return_item
}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_obj_summary:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_obj_summary { output_file doc_array flow_name_arg obj_name_arg obj_type_arg } {

  global SEV env

  array set DOC $doc_array

  ## -------------------------------------
  ## Detect LCRM mode
  ## -------------------------------------

  if { [info exists env(LYNX_LCRM_MODE)] } {
    set LYNX(lcrm_mode) 1
  } else {
    set LYNX(lcrm_mode) 0
  }

  ## -------------------------------------
  ## Select the specific flow_item
  ## -------------------------------------

  foreach flow_item $DOC(flows) {
    set flow_name  [lindex $flow_item 0]
    set flow_file  [lindex $flow_item 1]
    set flow_image [lindex $flow_item 2]
    if { $flow_name == $flow_name_arg } {
      break
    }
  }

  set obj_name $obj_name_arg

  ## -------------------------------------
  ## Create html
  ## -------------------------------------

  ## -------------------------------------
  ## Open file
  ## -------------------------------------

  set fid(html) [open $output_file w]

  puts $fid(html) "<!DOCTYPE html>"
  puts $fid(html) "<html>"
  puts $fid(html) "<body link=\"$DOC(color,link)\">"
  puts $fid(html) "<head>"
  puts $fid(html) "<title>Task Info: $flow_name:$obj_name</title>"
  puts $fid(html) "</head>"
  puts $fid(html) "<body>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"container\">"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,$obj_type_arg);margin-bottom:20px;\">"
  puts $fid(html) "  <h1>Task Info: $flow_name:$obj_name</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  set id [fe_flow_open -filename $flow_file]

  unset -nocomplain TASK_ATTR_FINAL
  unset -nocomplain TASK_ATTR_OVERRIDE
  unset -nocomplain TASK_ATTR_FLOWXML
  unset -nocomplain SCRIPT_ATTR

  array set TASK_ATTR_FINAL    [fe_task_get -id $id -task $obj_name -data_source final]
  array set TASK_ATTR_OVERRIDE [fe_task_get -id $id -task $obj_name -data_source file_override]
  array set TASK_ATTR_FLOWXML  [fe_task_get -id $id -task $obj_name -data_source file_xml]

  set real_file $TASK_ATTR_FINAL(script_file)
  set real_file [regsub -all {\\\$SEV\(} $real_file {$SEV(}]
  eval "set real_file $real_file"

  if { [file exists $real_file] } {
    array set SCRIPT_ATTR        [fe_script_get -id $id -task $obj_name]
    set flag_script_exists 1
  } else {
    set SCRIPT_ATTR(script_variable_info) "foo foo"
    set SCRIPT_ATTR(script_variable_value) "foo foo"
    set flag_script_exists 0
  }

  fe_flow_close -id $id

  ## -------------------------------------

  puts $fid(html) "<table border=\"1\">"

  puts $fid(html) "<tr>"
  puts $fid(html) "<th align=\"left\" colspan=\"3\" bgcolor=$DOC(color,black)><font color=\"$DOC(color,white)\">Highlighting Legend</font></th>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td align=\"left\" colspan=\"2\" bgcolor=$DOC(color,gray)>Text</td>"
  puts $fid(html) "<td align=\"left\" colspan=\"1\" bgcolor=$DOC(color,gray)>Meaning</td>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td align=\"left\" colspan=\"2\" bgcolor=$DOC(color,white)>Default Value</td>"
  puts $fid(html) "<td align=\"left\" colspan=\"1\" bgcolor=$DOC(color,white)>Black Text, White Background</td>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td align=\"left\" colspan=\"2\" bgcolor=$DOC(color,white)>Non-default value specified by flow XML file</td>"
  puts $fid(html) "<td align=\"left\" colspan=\"1\" bgcolor=$DOC(color,yellow)>Black Text, Yellow Background</td>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td align=\"left\" colspan=\"2\" bgcolor=$DOC(color,white)>Non-default value specified by task override</td>"
  puts $fid(html) "<td align=\"left\" colspan=\"1\" bgcolor=$DOC(color,blue)>Black Text, Blue Background</td>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td align=\"left\" colspan=\"2\" bgcolor=$DOC(color,white)>Aux TEV</td>"
  puts $fid(html) "<td align=\"left\" colspan=\"1\" bgcolor=$DOC(color,white)><i>Italic Text, Background Coloring White/Yellow/Blue</i></td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  puts $fid(html) "<tr>"
  puts $fid(html) "<th align=\"left\" colspan=\"3\" bgcolor=$DOC(color,black)><font color=\"$DOC(color,white)\">Task Details</font></th>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Task Attribute</th>"
  puts $fid(html) "<th align=\"left\" colspan=\"2\" bgcolor=$DOC(color,gray)>Value</th>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  set return_item [_rtm_generate_flow_docs_attr_level tool          [array get DOC] [array get TASK_ATTR_FINAL] [array get TASK_ATTR_OVERRIDE] [array get TASK_ATTR_FLOWXML]]
  set tool_bgcolor  [lindex $return_item 0]
  set tool_name     [lindex $return_item 1]

  ## Default
  set tool_version_for_display [rtm_tool_query -cmd get_version_val -tool $tool_name]
  set tool_bgcolor_for_display $DOC(color,white)

  ## Check to see if set in flowxml
  if { [info exists TASK_ATTR_FLOWXML(tool_versions)] } {
    foreach { tn tv } $TASK_ATTR_FLOWXML(tool_versions) {
      if { $tn == $tool_name } {
        set tool_version_for_display $tv
        set tool_bgcolor_for_display $DOC(color,yellow)
      }
    }
  }

  ## Check to see if set in override
  if { [info exists TASK_ATTR_OVERRIDE(tool_versions)] } {
    foreach { tn tv } $TASK_ATTR_OVERRIDE(tool_versions) {
      if { $tn == $tool_name } {
        set tool_version_for_display $tv
        set tool_bgcolor_for_display $DOC(color,blue)
      }
    }
  }

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>Tool</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$tool_bgcolor>$tool_name</td>"
  puts $fid(html) "</tr>"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>Tool Version</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$tool_bgcolor_for_display>$tool_version_for_display</td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>Step</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$DOC(color,white)>$TASK_ATTR_FINAL(step)</td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>SRC</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$DOC(color,white)>$TASK_ATTR_FINAL(src)</td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>DST</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$DOC(color,white)>$TASK_ATTR_FINAL(dst)</td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  set return_item [_rtm_generate_flow_docs_attr_level script_file [array get DOC] [array get TASK_ATTR_FINAL] [array get TASK_ATTR_OVERRIDE] [array get TASK_ATTR_FLOWXML]]
  set return_bgcolor [lindex $return_item 0]
  set return_value   [lindex $return_item 1]

  set file_xxx     [regsub -all {\\\$SEV\(} $return_value {$XXX(}]
  set file_display [regsub -all {\\\$SEV\(} $return_value {$SEV(}]
  set XXX(gscript_dir) scripts_global
  set XXX(tscript_dir) scripts_global/$DOC(techlib)
  if { $LYNX(lcrm_mode) } {
    set XXX(bscript_dir) $DOC(block)/scripts_block
  } else {
    set XXX(bscript_dir) blocks/$DOC(techlib)/$DOC(block)/scripts_block
  }
  eval "set file_real $file_xxx"

  puts $fid(html) "<tr>"
  puts $fid(html) "<td bgcolor=$DOC(color,white)>Script</td>"
  puts $fid(html) "<td colspan=\"2\" bgcolor=$return_bgcolor>"

  if { $flag_script_exists } {
    puts $fid(html) "<a href=\"../$file_real.txt\">"
    puts $fid(html) "<font color=\"$DOC(color,link)\">"
    puts $fid(html) "$file_display"
    puts $fid(html) "</font>"
    puts $fid(html) "</a>"
  } else {
    puts $fid(html) "<font color=\"$DOC(color,red)\">$file_display (file not found)"
    puts $fid(html) "</font>"
  }

  puts $fid(html) "</td>"
  puts $fid(html) "</tr>"

  ## -------------------------------------

  if { $obj_type_arg == "mux_task" } {

    set return_item [_rtm_generate_flow_docs_attr_level ports [array get DOC] [array get TASK_ATTR_FINAL] [array get TASK_ATTR_OVERRIDE] [array get TASK_ATTR_FLOWXML]]
    set return_bgcolor [lindex $return_item 0]
    set return_value   [lindex $return_item 1]

    puts $fid(html) "<tr>"
    puts $fid(html) "<td bgcolor=$DOC(color,white)>MUX Port Enables</td>"
    puts $fid(html) "<td colspan=\"2\" bgcolor=$return_bgcolor>$return_value</td>"
    puts $fid(html) "</tr>"

  }

  ## -------------------------------------

  if { [info exists SCRIPT_ATTR(script_description)] } {
    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" colspan=\"3\" bgcolor=$DOC(color,gray)>Script Description</th>"
    puts $fid(html) "</tr>"
    puts $fid(html) "<tr>"
    puts $fid(html) "<td colspan=\"3\" bgcolor=$DOC(color,white)>$SCRIPT_ATTR(script_description)</td>"
    puts $fid(html) "</tr>"
  }

  ## -------------------------------------

  if { [info exists TASK_ATTR_FINAL(variables)] } {

    puts $fid(html) "<tr>"
    puts $fid(html) "<th bgcolor=$DOC(color,gray)>TEV Variable</th>"
    puts $fid(html) "<th bgcolor=$DOC(color,gray)>Value</th>"
    puts $fid(html) "<th bgcolor=$DOC(color,gray)>Info</th>"
    puts $fid(html) "</tr>"

    foreach { name val } $TASK_ATTR_FINAL(variables) {

      set var_description ""
      foreach { name2 description } $SCRIPT_ATTR(script_variable_info) {
        if { $name == $name2 } {
          set var_description $description
          break
        }
      }

      set return_item [_rtm_generate_flow_docs_tev_level $name [array get DOC] [array get SCRIPT_ATTR] [array get TASK_ATTR_FINAL] [array get TASK_ATTR_OVERRIDE] [array get TASK_ATTR_FLOWXML]]
      set return_bgcolor [lindex $return_item 0]
      set return_value   [lindex $return_item 1]
      set return_is_aux  [lindex $return_item 2]

      puts $fid(html) "<tr>"
      puts $fid(html) "<td bgcolor=$DOC(color,white)>$name</td>"
      if { $return_is_aux } {
        puts $fid(html) "<td bgcolor=$return_bgcolor><i>$return_value</i></td>"
      } else {
        puts $fid(html) "<td bgcolor=$return_bgcolor>$return_value</td>"
      }
      puts $fid(html) "<td bgcolor=$DOC(color,white)>$var_description</td>"
      puts $fid(html) "</tr>"
    }

  }

  ## -------------------------------------

  puts $fid(html) "</table>"
  puts $fid(html) ""

  puts $fid(html) "<br>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,$obj_type_arg);clear:both;text-align:center;\">"
  puts $fid(html) "  <a href=\"../html/$flow_name.html\">(Back to Flow Summary)</a>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Close file
  ## -------------------------------------

  puts $fid(html) "</body>"
  puts $fid(html) "</html>"
  close $fid(html)

}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_proc_xref:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_proc_xref { output_file doc_array } {

  global SEV proc_info proc_args

  array set DOC $doc_array

  ## -------------------------------------
  ## -------------------------------------
  ## Generate cross reference information
  ## -------------------------------------
  ## -------------------------------------

  set file_list ""
  set file_list [concat $file_list [glob $DOC(dir)/scripts_global/*/*.tcl.txt]]
  set file_list [concat $file_list [glob $DOC(dir)/blocks/$DOC(techlib)/*/scripts_block/*/*.tcl.txt]]

  ## -------------------------------------
  ## Get list of all procedures
  ## -------------------------------------

  puts "Info: Finding all procedures"

  foreach file $file_list {
    set fid(tmp) [open $file r]
    set string_file [read $fid(tmp)]
    close $fid(tmp)
    set lines [split $string_file \n]

    foreach line $lines {
      if { [regexp {^\s*proc\s+(sproc_\w+)\s+\{} $line matchVar proc_name] } {
        set proc_declarations($proc_name) $file
      }
    }
    set file_lines($file) $lines
  }

  ## -------------------------------------
  ## Get list of files that reference procedures
  ## -------------------------------------

  puts "Info: Finding all procedure references"

  foreach file [array names file_lines] {
    puts -nonewline "."
    flush stdout
    foreach proc_name [array names proc_declarations] {
      if { [regexp $proc_name $file_lines($file)] } {
        lappend proc_files($proc_name) $file
      }
    }
  }
  puts ""

  foreach proc_name [array names proc_files] {
    set proc_files($proc_name) [lsort -unique $proc_files($proc_name)]
  }

  ## -------------------------------------
  ## Get procedure information from declarations
  ## -------------------------------------

  set file_list [list]
  foreach proc_name [array names proc_declarations] {
    lappend file_list $proc_declarations($proc_name)
  }
  set file_list [lsort -unique $file_list]

  foreach file $file_list {
    set fid(tmp) [open [lindex $file 0] r]
    set string_file [read $fid(tmp)]
    close $fid(tmp)
    set lines [split $string_file \n]

    set in_proc 0
    foreach line $lines {
      if { $in_proc } {
        if { [regexp {^\s*$} $line] } {
          set in_proc 0
        } else {
          set proc_body($proc_name) "$proc_body($proc_name) $line"
        }
      }
      if { [regexp {^define_proc_attributes\s+(\w+)} $line match proc_name] } {
        set proc_names($proc_name) 1
        set proc_body($proc_name) ""
        set proc_body($proc_name) "$proc_body($proc_name) $line"
        set in_proc 1
      }
    }
  }

  proc get_proc_attributes { args } {
    global proc_info proc_args
    set proc_name [lindex $args 0]
    for { set i 1 } { $i < [llength $args] } { incr i } {
      set arg [lindex $args $i]
      switch -- $arg {
        -info {
          incr i
          set info [lindex $args $i]
          set proc_info($proc_name) $info
        }
        -define_args {
          incr i
          set define_args [lindex $args $i]
          set proc_args($proc_name) $define_args
        }
        default {
        }
      }
    }
  }

  ## -------------------------------------
  ## Convert the parsed define_proc_attributes statements to a procedure call & execute it.
  ## The procedure is defined just above. The procedure creates the global variables:
  ##   proc_info
  ##   proc_args
  ## -------------------------------------

  puts "Info: Processing define_proc_attributes statements"
  foreach proc_name [array names proc_names] {
    puts -nonewline "."
    flush stdout
    set proc_body($proc_name) [regsub {define_proc_attributes} $proc_body($proc_name) {get_proc_attributes}]
    set proc_body($proc_name) [regsub -all {\\} $proc_body($proc_name) {}]
    eval $proc_body($proc_name)
  }
  puts ""

  ## -------------------------------------
  ## -------------------------------------
  ## Open file (main table)
  ## -------------------------------------
  ## -------------------------------------

  set fid(html) [open $output_file w]

  puts $fid(html) "<!DOCTYPE html>"
  puts $fid(html) "<html>"
  puts $fid(html) "<body link=\"$DOC(color,link)\">"
  puts $fid(html) "<head>"
  puts $fid(html) "<title>Procedure Cross-Reference</title>"
  puts $fid(html) "</head>"
  puts $fid(html) "<body>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"container\">"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,gray);margin-bottom:20px;\">"
  puts $fid(html) "  <h1>Procedure Cross-Reference</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "<a href=\"index.html\">(Back to Flow Overview)</a>"

  puts $fid(html) "<table width=\"90%\" border=\"1\">"
  puts $fid(html) "<tr>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Procedure</th>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Where Defined</th>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Details</th>"
  puts $fid(html) "</tr>"

  foreach proc_name [lsort [array names proc_files]] {
    puts $fid(html) "<tr>"
    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)>$proc_name</td>"
    set file_to_display $proc_declarations($proc_name)
    set file_to_display [file rootname $file_to_display]
    set file_to_display [regsub $DOC(dir)/ $file_to_display {}]
    set file_to_ref $proc_declarations($proc_name)
    set file_to_ref [regsub $DOC(dir)/ $file_to_ref {}]
    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"$file_to_ref\">$file_to_display</a></td>"
    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"html/proc_details.${proc_name}.html\">(Details)</a></td>"
    puts $fid(html) "</tr>"
  }
  puts $fid(html) "</table>"

  puts $fid(html) "<br>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,gray);clear:both;text-align:center;\">"
  puts $fid(html) "  <a href=\"index.html\">(Back to Flow Overview)</a>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Close file (main table)
  ## -------------------------------------

  puts $fid(html) "</body>"
  puts $fid(html) "</html>"
  close $fid(html)

  ## -------------------------------------
  ## -------------------------------------
  ## Create proc_details files
  ## -------------------------------------
  ## -------------------------------------

  foreach proc_name [lsort [array names proc_files]] {

    set fid(html) [open $DOC(dir)/html/proc_details.${proc_name}.html w]

    puts $fid(html) "<!DOCTYPE html>"
    puts $fid(html) "<html>"
    puts $fid(html) "<body link=\"$DOC(color,link)\">"
    puts $fid(html) "<head>"
    puts $fid(html) "<title>Procedure Details for $proc_name</title>"
    puts $fid(html) "</head>"
    puts $fid(html) "<body>"
    puts $fid(html) ""

    ## -------------------------------------

    puts $fid(html) "<div id=\"container\">"
    puts $fid(html) ""

    puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,gray);margin-bottom:20px;\">"
    puts $fid(html) "  <h1>Procedure Details for $proc_name</h1>"
    puts $fid(html) "</div>"
    puts $fid(html) ""

    puts $fid(html) "<a href=\"../proc_xref.html\">(Back to Procedure Cross Reference)</a>"

    ## -------------------------------------

    puts $fid(html) "<table width=\"90%\" border=\"1\">"

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Description</th>"
    puts $fid(html) "</tr>"
    if { [info exists proc_info($proc_name)] } {
      set info $proc_info($proc_name)
    } else {
      set info "No description available"
    }
    puts $fid(html) "<tr>"
    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)>$info</td>"
    puts $fid(html) "</tr>"

    ## -------------------------------------

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Arguments</th>"
    puts $fid(html) "</tr>"

    set define_args { {None-Defined "None-Defined" AString string required} }
    if { [info exists proc_args($proc_name)] } {
      if { [llength $proc_args($proc_name)] > 0 } {
        set define_args $proc_args($proc_name)
      }
    }
    foreach define_arg $define_args {
      set arg_name [lindex $define_arg 0]
      set arg_help [lindex $define_arg 1]
      puts $fid(html) "<tr>"
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><b>$arg_name</b>: $arg_help</td>"
      puts $fid(html) "</tr>"
    }

    ## -------------------------------------

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Files containing $proc_name</th>"
    puts $fid(html) "</tr>"

    foreach file $proc_files($proc_name) {
      set file_to_display $file
      set file_to_display [file rootname $file_to_display]
      set file_to_display [regsub $DOC(dir)/ $file_to_display {}]
      set file_to_ref $file
      set file_to_ref [regsub $DOC(dir)/ $file_to_ref {}]
      puts $fid(html) "<tr>"
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"../$file_to_ref\">$file_to_display</a></td>"
      puts $fid(html) "</tr>"
    }

    puts $fid(html) "</table>"

    puts $fid(html) "<br>"
    puts $fid(html) ""

    puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,gray);clear:both;text-align:center;\">"
    puts $fid(html) "  <a href=\"../proc_xref.html\">(Back to Procedure Cross Reference)</a>"
    puts $fid(html) "</div>"
    puts $fid(html) ""

    puts $fid(html) "</div>"
    puts $fid(html) ""

    ## -------------------------------------
    ## Close file (main table)
    ## -------------------------------------

    puts $fid(html) "</body>"
    puts $fid(html) "</html>"
    close $fid(html)

  }

}

## -----------------------------------------------------------------------------
## _rtm_generate_flow_docs_svar_xref:
## -----------------------------------------------------------------------------

proc _rtm_generate_flow_docs_svar_xref { output_file doc_array } {

  global SEV

  array set DOC $doc_array

  ## -------------------------------------
  ## -------------------------------------
  ## Generate cross reference information
  ## -------------------------------------
  ## -------------------------------------

  set file_list ""
  set file_list [concat $file_list [glob $DOC(dir)/scripts_global/$DOC(techlib)/common.tcl.txt]]
  set file_list [concat $file_list [glob $DOC(dir)/blocks/$DOC(techlib)/$DOC(block)/scripts_block/conf/block.tcl.txt]]

  ## -------------------------------------
  ## Get list of all SVARs
  ## -------------------------------------

  puts "Info: Finding all SVAR variables"

  catch { var_names -name SVAR(*) } svar_list
  set svar_name_list [list]
  foreach svar $svar_list {
    regexp {\(([\w\,\.]+)\)} $svar match svar_name
    lappend svar_name_list $svar_name
  }
  set svar_name_list [lsort $svar_name_list]

  ## -------------------------------------
  ## Get list of files that reference SVARs
  ## -------------------------------------

  set file_list ""
  set file_list [concat $file_list [glob $DOC(dir)/scripts_global/*/*.tcl.txt]]
  set file_list [concat $file_list [glob $DOC(dir)/blocks/$DOC(techlib)/*/scripts_block/*/*.tcl.txt]]

  foreach file $file_list {
    set fid(tmp) [open $file r]
    set string_file [read $fid(tmp)]
    close $fid(tmp)
    set lines [split $string_file \n]
    set file_lines($file) $lines
  }

  ## -------------------------------------
  ## Find all SVAR variable references
  ## -------------------------------------

  puts "Info: Finding all SVAR variable references"

  foreach file [array names file_lines] {
    puts -nonewline "."
    flush stdout
    foreach svar_name $svar_name_list {
      set pattern $svar_name
      set pattern [regsub {\(} $pattern {\\\\(}]
      set pattern [regsub {\)} $pattern {\\\\)}]
      if { [regexp $pattern $file_lines($file)] } {
        lappend svar_files($svar_name) $file
      }
    }
  }
  puts ""

  foreach svar_name $svar_name_list {
    set svar_files($svar_name) [lsort -unique $svar_files($svar_name)]
  }

  ## -------------------------------------
  ## -------------------------------------
  ## Open file (main table)
  ## -------------------------------------
  ## -------------------------------------

  set fid(html) [open $output_file w]

  puts $fid(html) "<!DOCTYPE html>"
  puts $fid(html) "<html>"
  puts $fid(html) "<body link=\"$DOC(color,link)\">"
  puts $fid(html) "<head>"
  puts $fid(html) "<title>SVAR Variable Cross-Reference</title>"
  puts $fid(html) "</head>"
  puts $fid(html) "<body>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"container\">"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,gray);margin-bottom:20px;\">"
  puts $fid(html) "  <h1>SVAR Variable Cross-Reference</h1>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "<a href=\"index.html\">(Back to Flow Overview)</a>"

  puts $fid(html) "<table width=\"90%\" border=\"1\">"
  puts $fid(html) "<tr>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>SVAR Variable</th>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Where Defined</th>"
  puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Details</th>"
  puts $fid(html) "</tr>"

  foreach svar_name $svar_name_list {
    puts $fid(html) "<tr>"

    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)>SVAR($svar_name)</td>"

    catch { var_exists                    -name SVAR($svar_name) } flag_common
    catch { var_exists -block $DOC(block) -name SVAR($svar_name) } flag_block
    if { $flag_block } {
      set file_to_display block.tcl
      set file_to_ref blocks/$DOC(techlib)/$DOC(block)/scripts_block/conf/block.tcl.txt
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"$file_to_ref\">$file_to_display</a></td>"
    } elseif { $flag_common }  {
      set file_to_display common.tcl
      set file_to_ref scripts_global/$DOC(techlib)/common.tcl.txt
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"$file_to_ref\">$file_to_display</a></td>"
    } else {
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)>Unknown</a></td>"
    }

    puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"html/svar_details.${svar_name}.html\">(Details)</a></td>"

    puts $fid(html) "</tr>"
  }
  puts $fid(html) "</table>"

  puts $fid(html) "<br>"
  puts $fid(html) ""

  puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,gray);clear:both;text-align:center;\">"
  puts $fid(html) "  <a href=\"index.html\">(Back to Flow Overview)</a>"
  puts $fid(html) "</div>"
  puts $fid(html) ""

  puts $fid(html) "</div>"
  puts $fid(html) ""

  ## -------------------------------------
  ## Close file (main table)
  ## -------------------------------------

  puts $fid(html) "</body>"
  puts $fid(html) "</html>"
  close $fid(html)

  ## -------------------------------------
  ## -------------------------------------
  ## Create svar_details files
  ## -------------------------------------
  ## -------------------------------------

  foreach svar_name $svar_name_list {

    set fid(html) [open $DOC(dir)/html/svar_details.${svar_name}.html w]

    puts $fid(html) "<!DOCTYPE html>"
    puts $fid(html) "<html>"
    puts $fid(html) "<body link=\"$DOC(color,link)\">"
    puts $fid(html) "<head>"
    puts $fid(html) "<title>SVAR Details for SVAR($svar_name)</title>"
    puts $fid(html) "</head>"
    puts $fid(html) "<body>"
    puts $fid(html) ""

    ## -------------------------------------

    puts $fid(html) "<div id=\"container\">"
    puts $fid(html) ""

    puts $fid(html) "<div id=\"header\" style=\"background-color:$DOC(color,gray);margin-bottom:20px;\">"
    puts $fid(html) "  <h1>SVAR Details for SVAR($svar_name)</h1>"
    puts $fid(html) "</div>"
    puts $fid(html) ""

    puts $fid(html) "<a href=\"../svar_xref.html\">(Back to Procedure Cross Reference)</a>"

    ## -------------------------------------

    puts $fid(html) "<table width=\"90%\" border=\"1\">"

    ## -------------------------------------

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Description</th>"
    puts $fid(html) "</tr>"

    catch { var_info -name SVAR($svar_name) } info

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,white)>$info</th>"
    puts $fid(html) "</tr>"

    if {0} {

      ## -------------------------------------

      puts $fid(html) "<tr>"
      puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Value from common.tcl</th>"
      puts $fid(html) "</tr>"

      puts $fid(html) "<tr>"
      puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,white)>blah</th>"
      puts $fid(html) "</tr>"

      ## -------------------------------------

      puts $fid(html) "<tr>"
      puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Value from block.tcl</th>"
      puts $fid(html) "</tr>"

      puts $fid(html) "<tr>"
      puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,white)>blah</th>"
      puts $fid(html) "</tr>"

    }

    ## -------------------------------------

    puts $fid(html) "<tr>"
    puts $fid(html) "<th align=\"left\" bgcolor=$DOC(color,gray)>Files containing SVAR($svar_name)</th>"
    puts $fid(html) "</tr>"

    foreach file $svar_files($svar_name) {
      set file_to_display $file
      set file_to_display [file rootname $file_to_display]
      set file_to_display [regsub $DOC(dir)/ $file_to_display {}]
      set file_to_ref $file
      set file_to_ref [regsub $DOC(dir)/ $file_to_ref {}]
      set file_to_ref ../$file_to_ref
      puts $fid(html) "<tr>"
      puts $fid(html) "<td align=\"left\" bgcolor=$DOC(color,white)><a href=\"$file_to_ref\">$file_to_display</a></td>"
      puts $fid(html) "</tr>"
    }

    puts $fid(html) "</table>"

    puts $fid(html) "<br>"
    puts $fid(html) ""

    puts $fid(html) "<div id=\"footer\" style=\"background-color:$DOC(color,gray);clear:both;text-align:center;\">"
    puts $fid(html) "  <a href=\"../svar_xref.html\">(Back to SVAR Cross Reference)</a>"
    puts $fid(html) "</div>"
    puts $fid(html) ""

    puts $fid(html) "</div>"
    puts $fid(html) ""

    ## -------------------------------------
    ## Close file (main table)
    ## -------------------------------------

    puts $fid(html) "</body>"
    puts $fid(html) "</html>"
    close $fid(html)

  }

}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
