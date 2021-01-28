## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/procs_qor.tcl#72 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains report parsers for QoR Analysis.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## Master QoR Viewer Procedure
## -----------------------------------------------------------------------------

proc sproc_qv_gen_files { args } {

  sproc_pinfo -mode start

  global SEV SVAR synopsys_program_name

  ## -------------------------------------
  ## Useful truncations
  ## -------------------------------------

  set block $SEV(block_name)

  set rpt_root [file normalize $SEV(block_dir)/../$block/$SEV(step)/rpts/$SEV(dst)]

  set c_rpts [list]

  switch $synopsys_program_name {

    dc_shell {
      set c_rpts [glob -nocomplain -type f $rpt_root/dc.*]
    }
    icc_shell {
      set c_rpts [glob -nocomplain -type f $rpt_root/icc.*]
    }
    pt_shell {
      set c_rpts [glob -nocomplain -type f $rpt_root/pt_*]
    }
    icc2_shell {
      set c_rpts [glob -nocomplain -type f $rpt_root/icc2.*]
    }

  }

  foreach c_rpt $c_rpts {

    ## -------------------------------------
    ## Define required attributes
    ## -------------------------------------

    set attributes [list]
    lappend attributes [list STEP   $SEV(step)]
    lappend attributes [list TASK   $SEV(task)]
    lappend attributes [list DST    $SEV(dst)]
    lappend attributes [list DESIGN $SVAR(design_name)]
    if { [info exists SEV(flow_order)] } {
      lappend attributes [list FLOW_ORDER $SEV(flow_order)]
    } else {
      lappend attributes [list FLOW_ORDER -1]
    }

    ## -------------------------------------
    ## Set FILE attribute to a relative path
    ## -------------------------------------

    set rel_rpt $SEV(step)/rpts/$SEV(dst)/[file tail $c_rpt]

    ## -------------------------------------
    ## Match the report to the parser
    ## -------------------------------------

    switch -glob [file tail $c_rpt] {

      dc.report_qor -
      icc.report_qor -
      icc2.report_qor -
      pt.*.report_qor -
      pt_concat.report_qor {

        if { [regexp {.*/pt\.(\S+)\.report_qor} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        set o_file $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).qor.qor
        lappend attributes [list TYPE QOR]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_qor -file $c_rpt -output $o_file -attributes $attributes
      }

      dc.report_power -
      icc.report_power -
      icc2.report_power -
      pt.*.report_power -
      pt_concat.report_power {

        if { [regexp {.*/pt\.(\S+)\.report_power} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        set o_file $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).power.qor
        lappend attributes [list TYPE POWER]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_power -file $c_rpt -output $o_file -attributes $attributes -scenario $scenario
      }

      dc.report_timing -
      icc.report_timing.min -
      icc.report_timing.max -
      icc2.report_timing.min -
      icc2.report_timing.max -
      pt.*.report_timing.* -
      pt_concat.report_timing.* -
      *.max.tim -
      *.min.tim -
      *.mapped.timing.rpt {

        if { [regexp {.*/pt\.(\S+)\.report_timing\.m??} $c_rpt match value] } {
          set scenario $value
          if { $SEV(task) != "scenario.$scenario" } {
            continue
          }
        } else {
          set scenario ""
        }

        if { [string match */*.report_timing.min $c_rpt] || [string match */*.min.tim $c_rpt] } {
          set C_TYPE MIN
          set c_type min
        } else {
          set C_TYPE MAX
          set c_type max
        }

        set o_file $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).timing_${c_type}.qor
        lappend attributes [list TYPE TIMING_$C_TYPE]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_timing -file $c_rpt -output $o_file -attributes $attributes -scenario $scenario
      }

      dc.report_units -
      icc.report_units -
      icc2.report_user_units {

        set o_file $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).units.qor
        lappend attributes [list TYPE UNITS]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_units -file $c_rpt -output $o_file -attributes $attributes
      }

      icc.cts.report_clock_tree {
        set o_file_matrix $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).clock_tree_matrix-matrix.qor
        set o_file_table  $SEV(rpt_dir)/.$SEV(step).$SEV(task).$SEV(dst).clock_tree_summary-table.qor
        lappend attributes [list TYPE UD_MATRIX]
        lappend attributes [list FILE $rel_rpt]
        sproc_qv_report_clock_tree -file $c_rpt -matrix_output $o_file_matrix -table_output $o_file_table -attributes $attributes
      }

    }

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_gen_files \
  -info "Proc that generates QoR Viewer files." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_qv_report_qor:
## -----------------------------------------------------------------------------

proc sproc_qv_report_qor { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set qor [sproc_metric_parse_report_qor -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process timing entry
    ## -------------------------------------

    lappend output "\"timing\": \["

    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        lappend output "{"
          lappend output "\"Scenario\": \"$scenario_name\""
          lappend output "\"Timing Path Group\": \"$path_group_name\""
          lappend output "\"line\": \"$qor(path_group_data,$scenario_name,$path_group_name,line_number)\""
          lappend output "\"Levels of Logic\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,logic_levels)\""
          lappend output "\"Critical Path Length\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_length)\""
          lappend output "\"Critical Path Slack\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)\""
          lappend output "\"Critical Path Clk Period\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,path_period)\""
          lappend output "\"Total Negative Slack\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,tns)\""
          lappend output "\"No. of Violating Paths\": \"$qor(path_group_data,$scenario_name,$path_group_name,setup,nvp)\""
          lappend output "\"Worst Hold Violation\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)\""
          lappend output "\"Total Hold Violation\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,tns)\""
          lappend output "\"No. of Hold Violations\": \"$qor(path_group_data,$scenario_name,$path_group_name,hold,nvp)\""
        lappend output "}"
      }
    }
    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_qor \
  -info "Proc that parses report_qor reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_units:
## -----------------------------------------------------------------------------

proc sproc_qv_report_units { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set units [sproc_metric_parse_report_units -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process units
    ## -------------------------------------

    lappend output "\"Time_unit\": \"$units(text_time)\""
    lappend output "\"Capacitive_load_unit\": \"$units(text_capacitance)\""
    lappend output "\"Resistance_unit\": \"$units(text_resistance)\""
    lappend output "\"Voltage_unit\": \"$units(text_voltage)\""
    lappend output "\"Power_unit\": \"$units(text_power)\""
    lappend output "\"Current_unit\": \"$units(text_current)\""

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_units \
  -info "Proc that parses report_units reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_power:
## -----------------------------------------------------------------------------

proc sproc_qv_report_power { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set power [sproc_metric_parse_report_power -file $options(-file) -scenario $options(-scenario)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process power
    ## -------------------------------------

    lappend output "\"power\": \["

    foreach scenario_name $power(scenario_name_list) {
      lappend output "{"
        lappend output "\"Scenario\": \"$scenario_name\""
        lappend output "\"line\": \"$power($scenario_name,total_power,line_number)\""
        lappend output "\"total\": {"

          if { $power($scenario_name,internal_power) != "N/A" } {
            lappend output "\"Internal\": \"$power($scenario_name,internal_power)$power($scenario_name,internal_power_units)\""
          } else {
            lappend output "\"Internal\": \"\""
          }
          if { $power($scenario_name,switching_power) != "N/A" } {
            lappend output "\"Switching\": \"$power($scenario_name,switching_power)$power($scenario_name,switching_power_units)\""
          } else {
            lappend output "\"Switching\": \"\""
          }
          if { $power($scenario_name,leakage_power) != "N/A" } {
            lappend output "\"Leakage\": \"$power($scenario_name,leakage_power)$power($scenario_name,leakage_power_units)\""
          } else {
            lappend output "\"Leakage\": \"\""
          }
          if { $power($scenario_name,total_power) != "N/A" } {
            lappend output "\"Total\": \"$power($scenario_name,total_power)$power($scenario_name,total_power_units)\""
          } else {
            lappend output "\"Total\": \"\""
          }

        lappend output "}"
      lappend output "}"
    }

    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_power \
  -info "Proc that parses report_power reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
  {-scenario    "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_timing:
## -----------------------------------------------------------------------------

proc sproc_qv_report_timing { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-output) ""
  set options(-attributes) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set tim [sproc_metric_parse_report_timing -file $options(-file) -scenario $options(-scenario)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set output [list]
  lappend output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $options(-attributes) {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend output "\"$name\": \"$value\""
    }

    ## -------------------------------------
    ## Process timing
    ## -------------------------------------

    lappend output "\"timing\": \["

    foreach path_item $tim(path_items) {

      set scenario_name [lindex $path_item 0]
      set start_point   [lindex $path_item 1]
      set end_point     [lindex $path_item 2]
      set path_group    [lindex $path_item 3]
      set path_type     [lindex $path_item 4]
      set slack         [lindex $path_item 5]
      set line          [lindex $path_item 6]

      lappend output "{"
        lappend output "\"Scenario\": \"$scenario_name\""
        lappend output "\"Path Group\": \"$path_group\""
        lappend output "\"Path Type\": \"$path_type\""
        lappend output "\"Startpoint\": \"$start_point\""
        lappend output "\"Endpoint\": \"$end_point\""
        lappend output "\"Slack\": \"$slack\""
        lappend output "\"line\": \"$line\""
      lappend output "}"

    }

    lappend output "\]"

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

  lappend output "}"

  set output [sproc_qv_add_commas -lines $output]
  set output [join $output "\n"]

  set fid [open $options(-output) w]
  puts $fid $output
  close $fid

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_timing \
  -info "Proc that parses report_timing reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-output      "Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
  {-scenario    "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_qv_report_clock_tree
## -----------------------------------------------------------------------------

proc sproc_qv_report_clock_tree { args } {

  sproc_pinfo -mode start

  global env SEV SVAR

  set options(-file) ""
  set options(-matrix_output) ""
  set options(-table_output) ""
  set options(-attributes) ""
  parse_proc_arguments -args $args options

  if { ![file exists $options(-file)] } {
    sproc_msg -error "The argument for -file does not exist: '$options(-file)'"
    sproc_pinfo -mode stop
    return
  } else {
    array set cts [sproc_metric_parse_report_clock_tree -file $options(-file)]
  }

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set matrix_output [list]
  set table_output [list]
  lappend matrix_output "\{"
  lappend table_output "\{"

  ## -------------------------------------
  ## Process attributes
  ## -------------------------------------

  foreach attribute $options(-attributes) {
    set name  [lindex $attribute 0]
    set value [lindex $attribute 1]
    lappend matrix_output "\"$name\": \"$value\""
    if {$name == "TYPE"} {
      set value UD_TABLE
      lappend table_output "\"$name\": \"$value\""
    } else {
      lappend table_output "\"$name\": \"$value\""
    }
  }

  ## -------------------------------------
  ## Create CTS Matrix
  ## -------------------------------------

  lappend matrix_output "\"data\": \["
  lappend table_output "\"data\": \["
  set file [lindex [lindex $options(-attributes) end] end]

  foreach scenario_name $cts(scenario_name_list) {
    foreach clk_name $cts($scenario_name,clk_name_list) {
      lappend matrix_output "\{"
      lappend matrix_output "\"Scenario\": \"$scenario_name\""
      lappend matrix_output "\"Clock\": \"$clk_name\""
      foreach name $cts(name_list) {
        lappend matrix_output "\"$name\" \: \{"
        lappend matrix_output "\"value\" \: \"$cts($scenario_name,$clk_name,$name,value)\""
        lappend matrix_output "\"file\" \: \"$file\""
        lappend matrix_output "\"line\" \: \"$cts($scenario_name,$clk_name,$name,line_number)\""
        lappend matrix_output "\}"
      }
      lappend matrix_output "\}"
    }
  }
  lappend matrix_output "\]"

  ## Specification section

  lappend matrix_output "\"specification\" \: \{"
  lappend matrix_output "\"Rows\" \: \["
  lappend matrix_output "\"Clock\""
  lappend matrix_output "\]"
  lappend matrix_output "\"Columns\" \: \["
  lappend matrix_output "\"Scenario\""
  lappend matrix_output "\]"
  lappend matrix_output "\"Values\" \: \["
  lappend matrix_output "\"Max Global Skew\""
  lappend matrix_output "\"Longest path delay\""
  lappend matrix_output "\"Shortest path delay\""
  lappend matrix_output "\]"
  lappend matrix_output "\}"

  ## -------------------------------------
  ## Create CTS Table
  ## -------------------------------------

  foreach clk_name $cts(clk_name_list) {
    foreach scenario_name $cts(scenario_name_list) {
      if { [lsearch $cts($scenario_name,clk_name_list) $clk_name] >= 0 } {
        foreach name $cts(name_list) {
          lappend table_output "\{"
          lappend table_output "\"Clock\": \"${clk_name}\""
          lappend table_output "\"Scenario\": \"${scenario_name}\""
          lappend table_output "\"Metric\" \: \"$name\""
          lappend table_output "\"value\" \: \"$cts($scenario_name,$clk_name,$name,value)\""
          lappend table_output "\"line\" \: \"$cts($scenario_name,$clk_name,$name,line_number)\""
          lappend table_output "\"file\" \: \"$file\""
          lappend table_output "\}"
        }
      }

    }
  }
  lappend table_output "\]"

  ## Specification section

  lappend table_output "\"specification\" \: \{"

  lappend table_output "\"Rows\" \: \["
  lappend table_output "\"Clock\""
  lappend table_output "\"Scenario\""
  lappend table_output "\]"

  lappend table_output "\"Columns\" \: \["
  lappend table_output "\"Metric\""
  lappend table_output "\]"
  lappend table_output "\"Values\" \: \["
  lappend table_output "\"value\""
  lappend table_output "\]"
  lappend table_output "\"Properties\" \: \{"
  lappend table_output "\"model\" \: \{"
  lappend table_output "\"metric_on_columns\" \: true"
  lappend table_output "\"metric_index\" \: 0"
  lappend table_output "\}"
  lappend table_output "\}"
  lappend table_output "\}"

  ## -------------------------------------
  ## Complete output & create file
  ## -------------------------------------

  lappend matrix_output "\}"
  lappend table_output "\}"

  set matrix_output [sproc_qv_add_commas -lines $matrix_output]
  set matrix_output [join $matrix_output "\n"]

  set table_output [sproc_qv_add_commas -lines $table_output]
  set table_output [join $table_output "\n"]

  set fid [open $options(-matrix_output) w]
  puts $fid $matrix_output
  close $fid

  set fid2 [open $options(-table_output) w]
  puts $fid2 $table_output
  close $fid2

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_qv_report_clock_tree \
  -info "Proc that parses report_qor reports and returns metrics in JSON." \
  -define_args {
  {-file        "File name for the report." AString string required}
  {-matrix_output      "Output file." AString string required}
  {-table_output      "II type Output file." AString string required}
  {-attributes  "Attribute pairs to write to file" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_qv_add_commas:
## -----------------------------------------------------------------------------

proc sproc_qv_add_commas { args } {

  set options(-lines) ""
  parse_proc_arguments -args $args options

  set results [list]

  set index 0
  set index_max [llength $options(-lines)]

  while { $index < $index_max } {
    set this_line [lindex $options(-lines) $index]
    set next_line [lindex $options(-lines) [expr $index + 1]]
    if { [regexp {[\},\]]$} $this_line] && [regexp {[\[\{]$} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {\"$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {[0-9]$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    if { [regexp {(true|false)$} $this_line] && [regexp {^\"} $next_line] } {
      set this_line ${this_line},
    }
    lappend results $this_line
    incr index
  }

  return $results
}

define_proc_attributes sproc_qv_add_commas \
  -info "Proc that add commas for JSON output." \
  -define_args {
  {-lines       "The lines that need commas." AString string required}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
