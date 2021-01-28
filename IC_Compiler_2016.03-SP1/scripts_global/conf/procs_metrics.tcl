## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/procs_metrics.tcl#124 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file contains Lynx procedure definitions.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_timing:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_timing { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(path_items) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  set line_number 0
  foreach line $lines {
    incr line_number

    regexp {^\s+Startpoint:\s+(\S+)} $line match start_point
    regexp {^\s+Endpoint:\s+(\S+)}   $line match end_point
    regexp {^\s+Scenario:\s+(\S+)}   $line match scenario_name
    regexp {^\s+Path Group:\s+(\S+)} $line match path_group
    regexp {^\s+Path Type:\s+(\S+)}  $line match path_type
    if { [regexp {^\s+slack\s+\(\S+\)\s+([\d\.\-]+)} $line match value] } {
      set slack $value
      set line $line_number
      set path_item "$scenario_name $start_point $end_point $path_group $path_type $slack $line"
      lappend rval(path_items) $path_item
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_timing \
  -info "Parses information for report_timing." \
  -define_args {\
    {-file     "The report_units file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_units:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_units { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag)       0
  set rval(time_unit)        "undefined"

  set rval(text_time)        "undefined"
  set rval(text_capacitance) "undefined"
  set rval(text_resistance)  "undefined"
  set rval(text_voltage)     "undefined"
  set rval(text_power)       "undefined"
  set rval(text_current)     "undefined"

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  if { $synopsys_program_name == "icc2_shell" } {

    foreach line $lines {
      regexp {^time\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_time)
      regexp {^resistance\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_capacitance)
      regexp {^capacitance\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_resistance)
      regexp {^voltage\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_voltage)
      regexp {^current\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_power)
      regexp {^power\s+:\s+[\d\.]*(.*)\s*$} $line match rval(text_current)
    }
    set rval(time_unit) $rval(text_time)

  } else {

    set time_unit undefined
    foreach line $lines {
      regexp {(e\-\S\S)\s+Second} $line match time_unit

      regexp {^Time_unit\s+:\s+(.*)\s*$} $line match rval(text_time)
      regexp {^Capacitive_load_unit\s+:\s+(.*)\s*$} $line match rval(text_capacitance)
      regexp {^Resistance_unit\s+:\s+(.*)\s*$} $line match rval(text_resistance)
      regexp {^Voltage_unit\s+:\s+(.*)\s*$} $line match rval(text_voltage)
      regexp {^Power_unit\s+:\s+(.*)\s*$} $line match rval(text_power)
      regexp {^Current_unit\s+:\s+(.*)\s*$} $line match rval(text_current)
    }

    switch $time_unit {
      e-00 {
        set rval(time_unit) s
      }
      e-03 {
        set rval(time_unit) ms
      }
      e-06 {
        set rval(time_unit) us
      }
      e-09 {
        set rval(time_unit) ns
      }
      e-12 {
        set rval(time_unit) ps
      }
      e-15 {
        set rval(time_unit) fs
      }
      default {
        sproc_msg -error "Unrecognized value for time units: $time_unit"
        set rval(error_flag) 1
      }
    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_units \
  -info "Parses information for report_units." \
  -define_args {\
    {-file "The report_units file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_clock_tree:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_clock_tree { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0
  set rval(scenario_name_list) [list]

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report (for Clock Tree Summary info)
  ## This information used for METRICS
  ## -------------------------------------

  set in_section 0

  set index 0
  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Clock Tree Summary =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {
      if { [regexp {Clock\s+Sinks\s+CTBuffers\s+ClkCells\s+Skew\s+LongestPath\s+TotalDRC\s+BufferArea} $line] } {
        ## This is header line
        continue
      } elseif { [regexp {^----} $line] } {
        ## This is seperator line
        continue
      } elseif { [scan $line {%s %s %s %s %s %s %s %s} clock_name sinks buffers cells skew path drc area] == 8 } {
        ## This is data line
        set rval($scenario_name,$clock_name,sinks) $sinks
        set rval($scenario_name,$clock_name,skew)  $skew
        set rval($scenario_name,$clock_name,path)  $path
        set rval($scenario_name,$clock_name,drc)   $drc
        set rval($scenario_name,$clock_name,sinks,line_number) $line_number
        set rval($scenario_name,$clock_name,skew,line_number)  $line_number
        set rval($scenario_name,$clock_name,path,line_number)  $line_number
        set rval($scenario_name,$clock_name,drc,line_number)   $line_number
        continue
      } else {
        ## No longer in summary
        set in_section 0
        continue
      }
    }

  }

  ## -------------------------------------
  ## Parse the report (for Global Skew Report info)
  ## This information used for QOR JSON files
  ## -------------------------------------

  set rval(name_list) [list \
    "Clock Period" \
    "Number of Levels" \
    "Number of Sinks" \
    "Number of CT Buffers" \
    "Number of CTS added gates" \
    "Number of Preexisting Gates" \
    "Number of Preexisting Buf/Inv" \
    "Total Number of Clock Cells" \
    "Total Area of CT Buffers" \
    "Total Area of CT cells" \
    "Max Global Skew" \
    "Number of MaxTran Violators" \
    "Number of MaxCap Violators" \
    "Number of MaxFanout Violators" \
    "Clock global Skew" \
    "Longest path delay" \
    "Shortest path delay" \
    ]

  set in_section 0

  set index 0
  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {\=\=Report for scenario \((\S+)\)\=\=} $line match value] } {
      set scenario_name $value
      lappend rval(scenario_name_list) $scenario_name
      continue
    }

    if { [regexp {\=\= Global Skew Report =\=} $line] } {
      set in_section 1
      continue
    }

    if { $in_section } {

      if { [regexp "^Clock Tree Name" $line] } {
        set clk_name [lindex [split [string trim $line]] end]
        set clk_name [regsub -all {\"} $clk_name {}]
        puts "$scenario_name : $clk_name"
        lappend rval(clk_name_list) $clk_name
        lappend rval($scenario_name,clk_name_list) $clk_name
        foreach name $rval(name_list) {
          set rval($scenario_name,$clk_name,$name,value) unknown
          set rval($scenario_name,$clk_name,$name,line_number) 0
        }
        continue
      }

      foreach name $rval(name_list) {
        if { [regexp "^$name\s*\:*\s*" $line] } {
          set value [lindex [split [string trim $line]] end]
          set rval($scenario_name,$clk_name,$name,value) $value
          set rval($scenario_name,$clk_name,$name,line_number) $line_number

          ## set value_line [list $value $line_number]
          ## lappend rval($clk_name,$name,value_line_list) $value_line

          continue
        }
      }

      if { [regexp {^Report} $line] } {
        set in_section 0
        continue
      }

    }

  }

  ## Clean up

  set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]
  set rval(clk_name_list)      [lsort -unique $rval(clk_name_list)]

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_clock_tree \
  -info "Parses information for report_clock_tree." \
  -define_args {\
    {-file "The report_clock_tree file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_qor:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_qor { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report for path group information.
  ## -------------------------------------

  set rval(path_group_data,scenario_name_list) [list]

  set scenario_name None/non-MCMM

  set line_number 0
  set path_group_name NO_PATH_GROUP
  foreach line $lines {
    incr line_number

    regexp {^\s*Scenario\s+\'(.*)\'} $line matchVar scenario_name

    if { [regexp {^\s*Timing Path Group\s+'(\S+)'} $line matchVar path_group_name] } {

      lappend rval(path_group_data,scenario_name_list) $scenario_name
      lappend rval(path_group_data,path_group_name_list,$scenario_name) $path_group_name

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack)   NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period)  NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp)          NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack)    NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns)           NA
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp)           NA

      set rval(path_group_data,$scenario_name,$path_group_name,line_number) $line_number

      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) 1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number)   1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number)  1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number)          1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number)    1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number)           1
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number)           1
    }

    if { [regexp {^\s*Levels of Logic:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,logic_levels,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Length:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_length,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Critical Path Clk Period:\s+(\S+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,path_period,line_number) $line_number
    }
    if { [regexp {^\s*Total Negative Slack:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Violating Paths:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,setup,nvp,line_number) $line_number
    }
    if { [regexp {^\s*Worst Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,path_slack,line_number) $line_number
    }
    if { [regexp {^\s*Total Hold Violation:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,tns,line_number) $line_number
    }
    if { [regexp {^\s*No. of Hold Violations:\s+([\-\d\.]+)} $line matchVar data] } {
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp) $data
      set rval(path_group_data,$scenario_name,$path_group_name,hold,nvp,line_number) $line_number
    }
  }

  set rval(path_group_data,scenario_name_list) [lsort -unique $rval(path_group_data,scenario_name_list)]
  foreach scenario_name $rval(path_group_data,scenario_name_list) {
    set rval(path_group_data,path_group_name_list,$scenario_name) [lsort -unique $rval(path_group_data,path_group_name_list,$scenario_name)]
  }

  ## -------------------------------------
  ## Parse the report for summary information.
  ## -------------------------------------

  set rval(summary_data,_ss,scenario_name_list) [list]
  ## rval(summary_data,_ss,$scenario_name,setup,path_slack)
  ## rval(summary_data,_ss,$scenario_name,setup,tns)
  ## rval(summary_data,_ss,$scenario_name,setup,nvp)
  ## rval(summary_data,_ss,$scenario_name,hold,path_slack)
  ## rval(summary_data,_ss,$scenario_name,hold,tns)
  ## rval(summary_data,_ss,$scenario_name,hold,nvp)

  ## rval(summary_data,_ms,setup,path_slack)
  ## rval(summary_data,_ms,setup,tns)
  ## rval(summary_data,_ms,setup,nvp)
  ## rval(summary_data,_ms,hold,path_slack)
  ## rval(summary_data,_ms,hold,tns)
  ## rval(summary_data,_ms,hold,nvp)

  set line_number 0
  foreach line $lines {
    incr line_number

    if { $synopsys_program_name == "icc2_shell" } {

      ## -------------------------------------
      ## Per-scenario setup
      ## -------------------------------------

      if { [scan $line { %s (Setup) %e %e %d } scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,setup,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,setup,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-scenario hold
      ## -------------------------------------

      if { [scan $line { %s (Hold) %e %e %d } scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        set rval(summary_data,_ss,$scenario_name,hold,path_slack)             $wns
        set rval(summary_data,_ss,$scenario_name,hold,tns)                    $tns
        set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design setup
      ## -------------------------------------

      if { [scan $line { Design (Setup) %e %e %d } wns tns nvp] == 3 } {
        set rval(summary_data,_ms,setup,path_slack)             $wns
        set rval(summary_data,_ms,setup,tns)                    $tns
        set rval(summary_data,_ms,setup,nvp)                    $nvp
        set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ms,setup,tns,line_number)        $line_number
        set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design hold
      ## -------------------------------------

      if { [scan $line { Design (Hold) %e %e %d } wns tns nvp] == 3 } {
        set rval(summary_data,_ms,hold,path_slack)             $wns
        set rval(summary_data,_ms,hold,tns)                    $tns
        set rval(summary_data,_ms,hold,nvp)                    $nvp
        set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ms,hold,tns,line_number)        $line_number
        set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
      }

    } else {

      ## -------------------------------------
      ## Per-scenario setup
      ## -------------------------------------

      if { [scan $line { Scenario: %s WNS: %e TNS: %e Number of Violating Paths: %d} scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ss,$scenario_name,setup,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ss,$scenario_name,setup,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ss,$scenario_name,setup,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,setup,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-scenario hold
      ## -------------------------------------

      if { [scan $line { Scenario: %s (Hold) WNS: %e TNS: %e Number of Violating Paths: %d} scenario_name wns tns nvp] == 4 } {
        lappend rval(summary_data,_ss,scenario_name_list) $scenario_name
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ss,$scenario_name,hold,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ss,$scenario_name,hold,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ss,$scenario_name,hold,nvp)                    $nvp
        set rval(summary_data,_ss,$scenario_name,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ss,$scenario_name,hold,tns,line_number)        $line_number
        set rval(summary_data,_ss,$scenario_name,hold,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design setup
      ## -------------------------------------

      if { [scan $line { Design WNS: %e TNS: %e Number of Violating Paths: %d} wns tns nvp] == 3 } {
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ms,setup,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ms,setup,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ms,setup,nvp)                    $nvp
        set rval(summary_data,_ms,setup,path_slack,line_number) $line_number
        set rval(summary_data,_ms,setup,tns,line_number)        $line_number
        set rval(summary_data,_ms,setup,nvp,line_number)        $line_number
      }

      ## -------------------------------------
      ## Per-design hold
      ## -------------------------------------

      if { [scan $line { Design (Hold) WNS: %e TNS: %e Number of Violating Paths: %d} wns tns nvp] == 3 } {
        ## Note that wns and tns numbers are negated to keep reporting consistent that negative is a violation
        set rval(summary_data,_ms,hold,path_slack)             [format %f [expr 0.0 - $wns]]
        set rval(summary_data,_ms,hold,tns)                    [format %f [expr 0.0 - $tns]]
        set rval(summary_data,_ms,hold,nvp)                    $nvp
        set rval(summary_data,_ms,hold,path_slack,line_number) $line_number
        set rval(summary_data,_ms,hold,tns,line_number)        $line_number
        set rval(summary_data,_ms,hold,nvp,line_number)        $line_number
      }

    }

  }

  set rval(summary_data,_ss,scenario_name_list) [lsort -unique $rval(summary_data,_ss,scenario_name_list)]

  ## -------------------------------------
  ## A "pt_concat.report_qor" file is generated after DMSA processing and is simply
  ## a concatenation of the "report_qor" files for each scenario (generated by the PT slaves),
  ## and the "pt_master.report_global_timing" file (generated by the PT master).
  ## The per-design metrics are extracted from the "pt_master.report_global_timing" content.
  ## -------------------------------------

  if { [file tail $options(-file)] == "pt_concat.report_qor" } {

    unset -nocomplain rval(summary_data,_ms,setup,path_slack)
    unset -nocomplain rval(summary_data,_ms,setup,tns)
    unset -nocomplain rval(summary_data,_ms,setup,nvp)
    unset -nocomplain rval(summary_data,_ms,setup,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,setup,nvp,line_number)

    unset -nocomplain rval(summary_data,_ms,hold,path_slack)
    unset -nocomplain rval(summary_data,_ms,hold,tns)
    unset -nocomplain rval(summary_data,_ms,hold,nvp)
    unset -nocomplain rval(summary_data,_ms,hold,path_slack,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,tns,line_number)
    unset -nocomplain rval(summary_data,_ms,hold,nvp,line_number)

    set line_number 0
    foreach line $lines {
      incr line_number

      if { [regexp {^Setup violations} $line] } {
        set type setup
      }
      if { [regexp {^Hold violations} $line] } {
        set type hold
      }

      if { [regexp {^WNS} $line] } {
        set rval(summary_data,_ms,$type,path_slack) [lindex $line 1]
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
      }
      if { [regexp {^TNS} $line] } {
        set rval(summary_data,_ms,$type,tns)        [lindex $line 1]
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
      }
      if { [regexp {^NUM} $line] } {
        set rval(summary_data,_ms,$type,nvp)        [lindex $line 1]
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

      if { [regexp {^No setup violations found} $line] } {
        set type setup
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }
      if { [regexp {^No hold violations found} $line] } {
        set type hold
        set rval(summary_data,_ms,$type,path_slack) 0.0
        set rval(summary_data,_ms,$type,tns)        0.0
        set rval(summary_data,_ms,$type,nvp)        0
        set rval(summary_data,_ms,$type,tns,line_number)        $line_number
        set rval(summary_data,_ms,$type,path_slack,line_number) $line_number
        set rval(summary_data,_ms,$type,nvp,line_number)        $line_number
      }

    }

  }

  ## -------------------------------------
  ## Parse the report for design information.
  ## -------------------------------------

  set rval(design_data,leaf_cell_count)     -1
  set rval(design_data,bufinv_cell_count)   -1
  set rval(design_data,ctbufinv_cell_count) -1

  set rval(design_data,comb_cell_count)     -1
  set rval(design_data,seq_cell_count)      -1
  set rval(design_data,macro_cell_count)    -1

  set rval(design_data,cell_area)           -1
  set rval(design_data,design_area)         -1
  set rval(design_data,net_length)          -1

  set rval(design_data,net_count)           -1
  set rval(design_data,ldrc_total)          -1
  set rval(design_data,ldrc_trans)          -1
  set rval(design_data,ldrc_cap)            -1

  ## -------------------------------------

  set rval(design_data,leaf_cell_count,line_number)     1
  set rval(design_data,bufinv_cell_count,line_number)   1
  set rval(design_data,ctbufinv_cell_count,line_number) 1

  set rval(design_data,comb_cell_count,line_number)     1
  set rval(design_data,seq_cell_count,line_number)      1
  set rval(design_data,macro_cell_count,line_number)    1

  set rval(design_data,cell_area,line_number)           1
  set rval(design_data,design_area,line_number)         1
  set rval(design_data,net_length,line_number)          1

  set rval(design_data,net_count,line_number)           1
  set rval(design_data,ldrc_total,line_number)          1
  set rval(design_data,ldrc_trans,line_number)          1
  set rval(design_data,ldrc_cap,line_number)            1

  ## -------------------------------------

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {Leaf Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,leaf_cell_count) $data
      set rval(design_data,leaf_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*Buf/Inv Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,bufinv_cell_count) $data
      set rval(design_data,bufinv_cell_count,line_number) $line_number
    }
    if { [regexp {^\s*CT Buf/Inv Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,ctbufinv_cell_count) $data
      set rval(design_data,ctbufinv_cell_count,line_number) $line_number
    }

    if { [regexp {Combinational Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,comb_cell_count) $data
      set rval(design_data,comb_cell_count,line_number) $line_number
    }
    if { [regexp {Sequential Cell Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,seq_cell_count) $data
      set rval(design_data,seq_cell_count,line_number) $line_number
    }
    if { [regexp {Macro Count:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,macro_cell_count) $data
      set rval(design_data,macro_cell_count,line_number) $line_number
    }

    if { [regexp {Cell Area:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,cell_area) $data
      set rval(design_data,cell_area,line_number) $line_number
    }
    if { [regexp {Design Area:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,design_area) $data
      set rval(design_data,design_area,line_number) $line_number
    }
    if { [regexp {Net Length\s+:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,net_length) $data
      set rval(design_data,net_length,line_number) $line_number
    }

    if { [regexp {Total Number of Nets:\s+([\d\.]+)} $line match data] } {
      set rval(design_data,net_count) $data
      set rval(design_data,net_count,line_number) $line_number
    }
    if { [regexp {Nets With Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_total) $data
      set rval(design_data,ldrc_total,line_number) $line_number
    }
    if { [regexp {Max Trans Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_trans) $data
      set rval(design_data,ldrc_trans,line_number) $line_number
    }
    if { [regexp {Max Cap Violations:\s+([\d]+)} $line match data] } {
      set rval(design_data,ldrc_cap) $data
      set rval(design_data,ldrc_cap,line_number) $line_number
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_qor \
  -info "Parses information for report_qor." \
  -define_args {\
    {-file "The report_qor file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_congestion:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_congestion { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(grc_overflow) undefined

  foreach line $lines {
    regexp {Both Dirs: Overflow.*\(([\d\.]+)%\)} $line match rval(grc_overflow)
  }

  if { $rval(grc_overflow) == "undefined" } {
    sproc_msg -error "Unable to parse value for 'Both Dirs: Overflow'"
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_congestion \
  -info "Parses information for report_congestion." \
  -define_args {\
    {-file "The report_congestion file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_threshold_voltage_group:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_threshold_voltage_group { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(vth,vth_names) [list]
  ## rval(cell_count,$vth_name)
  ## rval(cell_percentage,$vth_name)

  set flag_name 0
  set flag_astr 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Name} $line] } {
      incr flag_name
      continue
    }

    if { $flag_name == 1 } {
      if { [regexp {^[\*\-]} $line] } {
        incr flag_astr
        continue
      }
    }

    if { ($flag_name == 1) && ($flag_astr == 1) } {
      ## We are in the data section
      set parse 0

      if { [llength $line] == 1 } {
        set save_line $line
      }
      if { [llength $line] == 6 } {
        set line "$save_line $line"
        set parse 1
      }
      if { [llength $line] == 7 } {
        set parse 1
      }

      if { $synopsys_program_name == "icc2_shell" } {
        if { [llength $line] == 8 } {
          set parse 1
        }
      }

      if { $parse } {
        regexp {^(\S+)\s+([\d\.]+)\s+\(([\d\.]+)\%\)} $line match vth_name cell_count cell_percentage
        lappend rval(vth,vth_names) $vth_name
        set rval(cell_count,$vth_name)                  $cell_count
        set rval(cell_percentage,$vth_name)             $cell_percentage
        set rval(cell_count,$vth_name,line_number)      $line_number
        set rval(cell_percentage,$vth_name,line_number) $line_number
      }

    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_threshold_voltage_group \
  -info "Parses information for report_threshold_voltage_group." \
  -define_args {\
    {-file "The report_threshold_voltage_group file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_design_physical:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_design_physical { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(cell2core_ratio)                -1
  set rval(chip_width)                     -1
  set rval(chip_height)                    -1
  set rval(chip_area)                      -1
  set rval(num_drc_errors)                 -1
  set rval(num_drc_errors_types)           -1

  ## -------------------------------------

  set rval(cell2core_ratio,line_number)      1
  set rval(chip_width,line_number)           1
  set rval(chip_height,line_number)          1
  set rval(chip_area,line_number)            1
  set rval(num_drc_errors,line_number)       1
  set rval(num_drc_errors_types,line_number) 1

  ## -------------------------------------

  set num_drc_errors_types -1
  set capture_error_types 0

  set line_number 0
  foreach line $lines {
    incr line_number

    if { [regexp {^Cell/Core Ratio\s+:\s+([\d\.]+)\%} $line match value] } {
      set rval(cell2core_ratio)             $value
      set rval(cell2core_ratio,line_number) $line_number
    }

    if { [regexp {^Chip\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)} $line match value1 value2 value3] } {
      set rval(chip_width)              $value1
      set rval(chip_height)             $value2
      set rval(chip_area)               $value3
      set rval(chip_width,line_number)  $line_number
      set rval(chip_height,line_number) $line_number
      set rval(chip_area,line_number)   $line_number
    }

    if { [regexp {^DRC information:\s*$} $line] } {
      set num_drc_errors_types 0
      set capture_error_types 1
      continue
    }
    if { $capture_error_types } {
      if { [regexp {^\s+Total error number:\s+([\d\.]+)} $line match data] } {
        set rval(num_drc_errors)                   $data
        set rval(num_drc_errors_types)             $num_drc_errors_types
        set rval(num_drc_errors,line_number)       $line_number
        set rval(num_drc_errors_types,line_number) $line_number
        set capture_error_types 0
        continue
      } else {
        incr num_drc_errors_types
      }
    }
  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_design_physical \
  -info "Parses information for report_design_physical." \
  -define_args {\
    {-file "The report_design_physical file to parse." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_parse_report_power:
## -----------------------------------------------------------------------------

proc sproc_metric_parse_report_power { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  set options(-file) ""
  set options(-scenario) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Standard setup
  ## -------------------------------------

  set rval(error_flag) 0

  ## -------------------------------------
  ## Standard argument processing
  ## -------------------------------------

  if { [file exists $options(-file)] } {
    sproc_msg -info "The specified report file is: '$options(-file)'"
  } else {
    sproc_msg -error "The specified report file does not exist: '$options(-file)'"
    set rval(error_flag) 1
    sproc_pinfo -mode stop
    return [array get rval]
  }

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fid [open $options(-file) r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set rval(scenario_name_list) [list]

  if { $options(-scenario) == "" } {
    set scenario_name None/non-MCMM
  } else {
    set scenario_name $options(-scenario)
  }

  switch $synopsys_program_name {

    dc_shell -
    icc_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^Scenario\(s\):\s+(\S+)} $line match scenario_name

        if { [scan $line "Total %s %s %s %s %s %s %s %s" m1 m2 m3 m4 m5 m6 m7 m8] == 8 } {
          set rval($scenario_name,internal_power)        $m1
          set rval($scenario_name,internal_power_units)  $m2
          set rval($scenario_name,switching_power)       $m3
          set rval($scenario_name,switching_power_units) $m4
          set rval($scenario_name,leakage_power)         $m5
          set rval($scenario_name,leakage_power_units)   $m6
          set rval($scenario_name,total_power)           $m7
          set rval($scenario_name,total_power_units)     $m8

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  $line_number
          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) $line_number
          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   $line_number
          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     $line_number

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    icc2_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^Mode:\s+(\S+)} $line match mode_name
        regexp {^Corner:\s+(\S+)} $line match corner_name

        if { [scan $line "Total %s %s %s %s %s %s %s %s" m1 m2 m3 m4 m5 m6 m7 m8] == 8 } {
          set scenario_name "${mode_name}.${corner_name}"
          set rval($scenario_name,internal_power)        $m1
          set rval($scenario_name,internal_power_units)  $m2
          set rval($scenario_name,switching_power)       $m3
          set rval($scenario_name,switching_power_units) $m4
          set rval($scenario_name,leakage_power)         $m5
          set rval($scenario_name,leakage_power_units)   $m6
          set rval($scenario_name,total_power)           $m7
          set rval($scenario_name,total_power_units)     $m8

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  $line_number
          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) $line_number
          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   $line_number
          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     $line_number

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

    pt_shell {

      set line_number 0
      foreach line $lines {
        incr line_number

        regexp {^LYNX_SCENARIO:\s+(\S+)} $line match scenario_name

        if { [regexp {^\s*Net Switching Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,switching_power)                   $value
          set rval($scenario_name,switching_power_units)             W

          set rval($scenario_name,switching_power,line_number)       $line_number
          set rval($scenario_name,switching_power_units,line_number) 1
        }
        if { [regexp {^\s*Cell Internal Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,internal_power)                    $value
          set rval($scenario_name,internal_power_units)              W

          set rval($scenario_name,internal_power,line_number)        $line_number
          set rval($scenario_name,internal_power_units,line_number)  1
        }
        if { [regexp {^\s*Cell Leakage Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,leakage_power)                     $value
          set rval($scenario_name,leakage_power_units)               W

          set rval($scenario_name,leakage_power,line_number)         $line_number
          set rval($scenario_name,leakage_power_units,line_number)   1
        }
        if { [regexp {^\s*Total Power\s+=\s+(\S+)} $line match value] } {
          set rval($scenario_name,total_power)                       $value
          set rval($scenario_name,total_power_units)                 W

          set rval($scenario_name,total_power,line_number)           $line_number
          set rval($scenario_name,total_power_units,line_number)     1

          lappend rval(scenario_name_list) $scenario_name
        }
      }
      set rval(scenario_name_list) [lsort -unique $rval(scenario_name_list)]

    }

  }

  ## -------------------------------------
  ## Return the parsed information
  ## -------------------------------------

  sproc_pinfo -mode stop
  return [array get rval]
}

define_proc_attributes sproc_metric_parse_report_power \
  -info "Parses information for report_power." \
  -define_args {\
    {-file "The report_power file to parse." AString string required}
  {-scenario "The scenario name." AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_verify:
## -----------------------------------------------------------------------------

proc sproc_metric_verify { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  if { ( $SEV(metrics_enable_generation) == 0 ) } {
    sproc_msg -warning "Metrics are disabled per SEV(metrics_enable_generation)"
    sproc_pinfo -mode stop
    return
  }

  set options(-function) ""
  set options(-tool) ""
  set options(-pass) 0
  set options(-num_type) ""
  set options(-num_errors) ""
  parse_proc_arguments -args $args options

  switch $options(-function) {

    formal {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FORMAL | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FORMAL | 0"
      }
    }

    lvs_extract {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVS.PASS_EXTRACT | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVS.PASS_EXTRACT | 0"
      }

      if { $options(-num_type) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVS.NUM_TYPES | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVS.NUM_TYPES | $options(-num_type)"
      }

      if { $options(-num_errors) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVS.NUM_ERRORS | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVS.NUM_ERRORS | $options(-num_errors)"
      }

      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.LVS.TOOL | ICV"
      }
      if { $options(-tool) == "hercules" } {
        sproc_msg -info "METRIC | STRING VERIFY.LVS.TOOL | HERCULES"
      }
    }

    lvs_compare {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVS.PASS_COMPARE | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVS.PASS_COMPARE | 0"
      }
    }

    fill {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FILL | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.PASS_FILL | 0"
      }

      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.FILL.TOOL | ICV"
      }
      if { $options(-tool) == "hercules" } {
        sproc_msg -info "METRIC | STRING VERIFY.FILL.TOOL | HERCULES"
      }
    }

    drc {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.DRC.PASS | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.DRC.PASS | 0"
      }

      if { $options(-num_type) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_TYPES | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_TYPES | $options(-num_type)"
      }

      if { $options(-num_errors) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_ERRORS | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_ERRORS | $options(-num_errors)"
      }

      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.DRC.TOOL | ICV"
      }
      if { $options(-tool) == "hercules" } {
        sproc_msg -info "METRIC | STRING VERIFY.DRC.TOOL | HERCULES"
      }
    }

    lvl {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVL.PASS | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LVL.PASS | 0"
      }

      if { $options(-num_type) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVL.NUM_TYPES | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVL.NUM_TYPES | $options(-num_type)"
      }

      if { $options(-num_errors) == "" } {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVL.NUM_ERRORS | NaM"
      } else {
        sproc_msg -info "METRIC | INTEGER VERIFY.LVL.NUM_ERRORS | $options(-num_errors)"
      }

      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.LVL.TOOL | ICV"
      }
      if { $options(-tool) == "hercules" } {
        sproc_msg -info "METRIC | STRING VERIFY.LVL.TOOL | HERCULES"
      }
    }

    lcc {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LCC.PASS | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.LCC.PASS | 0"
      }

      if { $options(-tool) == "pylcc" } {
        sproc_msg -info "METRIC | STRING VERIFY.LCC.TOOL | PYLCC"
      }
      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.LCC.TOOL | ICV"
      }
    }

    cmp {
      if { $options(-pass) } {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.CMP.PASS | 1"
      } else {
        sproc_msg -info "METRIC | BOOLEAN VERIFY.CMP.PASS | 0"
      }

      if { $options(-tool) == "icv" } {
        sproc_msg -info "METRIC | STRING VERIFY.CMP.TOOL | ICV"
      }
    }

  }

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_verify \
  -info "Gathers verification information for metrics reporting." \
  -define_args {
  {-function "Type of function performed" AnOos one_of_string
    {required value_help {values {formal lvs_extract lvs_compare fill drc lvl lcc cmp}}}
  }
  {-tool "Tool used to perform the function." AString string optional}
  {-pass "Flag to indicate successful verification." "" boolean optional}
  {-num_type "Number of DRC error types." "" int optional}
  {-num_errors "Total number of DRC errors." "" int optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_atpg:
## -----------------------------------------------------------------------------

proc sproc_metric_atpg { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode

  if { ( $SEV(metrics_enable_generation) == 0 ) } {
    sproc_msg -warning "Metrics are disabled per SEV(metrics_enable_generation)"
    sproc_pinfo -mode stop
    return
  }

  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## Set default values
  ## -------------------------------------

  set total_faults NaM
  set test_coverage NaM
  set fault_coverage 0
  set atpg_effectiveness 0

  ## -------------------------------------
  ## Read the report
  ## -------------------------------------

  set fname $SEV(rpt_dir)/tmax_rm.report_summaries

  set fid [open $fname r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  ## -------------------------------------
  ## Parse the report
  ## -------------------------------------

  set fault_types "Iddq Transition Path_delay Bridging Dynamic_bridging Hold_time IDDQ_bridging"

  foreach fault_type $fault_types {
    set ${fault_type}_faults "NaM"
    set ${fault_type}_coverage "NaM"
  }

  foreach line $lines {
    foreach fault_type $fault_types {
      regexp "$fault_type\\s+\(\[\\.\\d\]+\)\\s+\(\[\\.\\d\]+\)\\%" $line matchVar ${fault_type}_faults ${fault_type}_coverage
      regexp {total faults\s+([\d]+)} $line matchVar total_faults
      regexp {test coverage\s+([\.\d]+)\%} $line matchVar fault_coverage
    }
  }

  ## -------------------------------------
  ## Generate metrics
  ## -------------------------------------

  sproc_msg -info "METRIC | INTEGER ATPG.TRANSITION.FAULTS         | $Transition_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.TRANSITION.COVERAGE       | $Transition_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.BRIDGING.FAULTS           | $Bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.BRIDGING.COVERAGE         | $Bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.HOLD_TIME.FAULTS          | $Hold_time_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.HOLD_TIME.COVERAGE        | $Hold_time_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.IDDQ_BRIDGING.FAULTS      | $IDDQ_bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.IDDQ_BRIDGING.COVERAGE    | $IDDQ_bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.IDDQ.FAULTS               | $Iddq_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.IDDQ.COVERAGE             | $Iddq_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.PATH_DELAY.FAULTS         | $Path_delay_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.PATH_DELAY.COVERAGE       | $Path_delay_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.DYNAMIC_BRIDGING.FAULTS   | $Dynamic_bridging_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.DYNAMIC_BRIDGING.COVERAGE | $Dynamic_bridging_coverage"
  sproc_msg -info "METRIC | INTEGER ATPG.STUCK_AT.FAULTS   | $total_faults"
  sproc_msg -info "METRIC | DOUBLE  ATPG.STUCK_AT.COVERAGE | $fault_coverage"

  sproc_pinfo -mode stop
}

define_proc_attributes sproc_metric_atpg \
  -info "Gathers ATPG information for metrics reporting." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_metric_normalize:
## -----------------------------------------------------------------------------

proc sproc_metric_normalize { args } {

  sproc_pinfo -mode start

  ## table contains the multiplier for converting from supplied unit to normalized default
  set default_power_unit mw
  set normalize_lut(w)    1e+3
  set normalize_lut(mw)   1e+0
  set normalize_lut(uw)   1e-3
  set normalize_lut(nw)   1e-6
  set normalize_lut(pw)   1e-9

  set default_time_unit ps
  set normalize_lut(s)    1e+12
  set normalize_lut(ns)   1e+3
  set normalize_lut(ps)   1e+0

  set default_area_unit um
  set normalize_lut(nm)   1e-3
  set normalize_lut(um)   1e+0
  set normalize_lut(m)    1e+6

  set options(-value) ""
  set options(-current_unit) ""

  parse_proc_arguments -args $args options

  set val $options(-value)

  if { $val=="NaM" } {
    sproc_msg -info "Passing through special case value $val"
    sproc_pinfo -mode stop
    return $val
  }

  if { ![scan $val "%f" match] } {
    sproc_msg -error "sproc_metric_normalize cannot process value $val"
    sproc_pinfo -mode stop
    return "NaM"
  }

  if { $options(-current_unit) != "" } {
    set cur_unit [string tolower $options(-current_unit)]
    if { [array names normalize_lut -exact $cur_unit] != "" } {
      set norm_scalar $normalize_lut($cur_unit)
    } else {
      sproc_msg -error "sproc_metric_normalize not configured to convert $cur_unit"
      sproc_pinfo -mode stop
      return "NaM"
    }
  }

  set val_out [expr $val * $norm_scalar]

  sproc_pinfo -mode stop

  return $val_out

}

define_proc_attributes sproc_metric_normalize \
  -info "Used to convert metric numbers from one unit standard to another." \
  -define_args {
  {-value "value to convert" decimal string required}
  {-current_unit "Units of current value" AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_clean_string:
## -----------------------------------------------------------------------------

proc sproc_metric_clean_string { args } {

  sproc_pinfo -mode start

  set options(-string) ""
  parse_proc_arguments -args $args options

  set string_before $options(-string)

  ## Only allow alphanumric and underscore characters
  set string_after [regsub -all { [^\w\.] } $string_before {_}]

  if {![string match $string_after $string_before]} {
    sproc_msg -warn "sproc_metric_clean_string: String <$string_before> changed to <$string_after>"
  }

  sproc_pinfo -mode stop

  return $string_after
}

define_proc_attributes sproc_metric_clean_string \
  -info "Removes characters not supported for metric strings." \
  -define_args {
  {-string  "The string that needs cleaning." AString string required}
}

## -----------------------------------------------------------------------------
## sproc_metric_main:
## -----------------------------------------------------------------------------

proc sproc_metric_main { args } {

  sproc_pinfo -mode start

  global env SEV SVAR synopsys_program_name pt_shell_mode
  global TEV SNPS_time_start

  set options(-scenario_name) ""
  set options(-metrics_sta) 0
  set options(-metrics_power) 0
  set options(-metrics_design) 0
  set options(-metrics_cts) 0
  set options(-report_qor) ""
  set options(-report_units) ""
  set options(-report_power) ""
  set options(-report_congestion) ""
  set options(-report_design_physical) ""
  set options(-report_threshold_voltage_group) ""
  set options(-report_clock_tree) ""
  parse_proc_arguments -args $args options

  ## -------------------------------------
  ## If reporting is turned off, then metrics are disabled as well.
  ## -------------------------------------

  if { [regexp -nocase {NONE} $TEV(report_level)] || ($SEV(metrics_enable_generation) == 0) } {
    sproc_msg -warning "Metrics are disabled per TEV(report_level) or SEV(metrics_enable_generation)"
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Determine the file names for reports
  ## -------------------------------------

  if { $synopsys_program_name == "pt_shell" } {
    if { ($pt_shell_mode == "primetime") && ($options(-scenario_name) == "") } {
      sproc_msg -error "You must specify a scenario name using the -scenario_name argument."
    }
    switch $pt_shell_mode {
      primetime {
        if { $options(-report_qor) == "" } {
          set options(-report_qor) $SEV(rpt_dir)/pt.$options(-scenario_name).report_qor
        }
        if { $options(-report_units) == "" } {
          set options(-report_units) $SEV(rpt_dir)/pt.$options(-scenario_name).report_units
        }
        if { $options(-report_power) == "" } {
          set options(-report_power) $SEV(rpt_dir)/pt.$options(-scenario_name).report_power
        }
      }
      primetime_master {
        if { $options(-report_qor) == "" } {
          set options(-report_qor) $SEV(rpt_dir)/pt_concat.report_qor
        }
        if { $options(-report_units) == "" } {
          set options(-report_units) $SEV(rpt_dir)/pt_concat.report_units
        }
        if { $options(-report_power) == "" } {
          set options(-report_power) $SEV(rpt_dir)/pt_concat.report_power
        }
      }
    }
  } elseif { $synopsys_program_name == "icc_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/icc.report_qor
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/icc.report_units
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/icc.report_power
    }
    if { $options(-report_congestion) == "" } {
      set options(-report_congestion) $SEV(rpt_dir)/icc.report_congestion
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/icc.report_threshold_voltage_group
    }
    if { $options(-report_design_physical) == "" } {
      set options(-report_design_physical) $SEV(rpt_dir)/icc.report_design_physical
    }
    if { $options(-report_clock_tree) == "" } {
      set options(-report_clock_tree) $SEV(rpt_dir)/icc.cts.report_clock_tree
    }
  } elseif { $synopsys_program_name == "dc_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/dc.report_qor
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/dc.report_units
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/dc.report_power
    }
    if { $options(-report_congestion) == "" } {
      if {![shell_is_in_exploration_mode]} {
        set options(-report_congestion) $SEV(rpt_dir)/dc.report_congestion
      }
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/dc.report_threshold_voltage_group
    }
  } elseif { $synopsys_program_name == "icc2_shell" } {
    if { $options(-report_qor) == "" } {
      set options(-report_qor) $SEV(rpt_dir)/icc2.report_qor
    }
    if { $options(-report_power) == "" } {
      set options(-report_power) $SEV(rpt_dir)/icc2.report_power
    }
    if { $options(-report_units) == "" } {
      set options(-report_units) $SEV(rpt_dir)/icc2.report_user_units
    }
    if { $options(-report_threshold_voltage_group) == "" } {
      set options(-report_threshold_voltage_group) $SEV(rpt_dir)/icc2.report_threshold_voltage_group
    }
  }

  ## -------------------------------------
  ## Determine the list of reports that are needed.
  ## -------------------------------------

  set report_type_list [list \
    -report_qor \
    -report_units \
    -report_power \
    -report_congestion \
    -report_design_physical \
    -report_threshold_voltage_group \
    -report_clock_tree \
    ]

  foreach report_type $report_type_list {
    set required($report_type) 0
  }

  if { $options(-metrics_sta) } {
    set required(-report_qor) 1
    set required(-report_units) 1
  }

  if { $options(-metrics_power) } {
    set required(-report_power) 1
  }

  if { $options(-metrics_design) } {
    set required(-report_qor) 1
    set required(-report_threshold_voltage_group) 1
    if { [file exists $options(-report_congestion)] } {
      set required(-report_congestion) 1
    }
    if { $synopsys_program_name == "icc_shell" } {
      set required(-report_design_physical) 1
    }
  }

  if { $options(-metrics_cts) } {
    set required(-report_clock_tree) 1
  }

  ## -------------------------------------
  ## Check that reports are available
  ## -------------------------------------

  set error 0
  foreach report_type $report_type_list {
    if { $required($report_type) } {
      if { ![file exists $options($report_type)] } {
        set error 1
        if { $SEV(metrics_flag_errors) } {
          sproc_msg -error   "The file specified by '$report_type' does not exist: '$options($report_type)'"
        } else {
          sproc_msg -warning "The file specified by '$report_type' does not exist: '$options($report_type)'"
        }
      }
    }
  }

  if { $error } {
    sproc_pinfo -mode stop
    return
  }

  ## -------------------------------------
  ## Parse the reports
  ## -------------------------------------

  foreach report_type $report_type_list {
    if { $required($report_type) } {
      switch -- $report_type {
        -report_qor                     { array set qor   [sproc_metric_parse_report_qor                     -file $options(-report_qor)] }
        -report_units                   { array set units [sproc_metric_parse_report_units                   -file $options(-report_units)] }
        -report_power                   { array set power [sproc_metric_parse_report_power                   -file $options(-report_power)] }
        -report_congestion              { array set cong  [sproc_metric_parse_report_congestion              -file $options(-report_congestion)] }
        -report_design_physical         { array set phy   [sproc_metric_parse_report_design_physical         -file $options(-report_design_physical)] }
        -report_threshold_voltage_group { array set vth   [sproc_metric_parse_report_threshold_voltage_group -file $options(-report_threshold_voltage_group)] }
        -report_clock_tree              { array set cts   [sproc_metric_parse_report_clock_tree              -file $options(-report_clock_tree)] }
      }
    }
  }

  ## -------------------------------------
  ## Generate outputs
  ## -------------------------------------

  if { $options(-metrics_sta) } {

    ## -------------------------------------
    ## This code is for generation of path group metrics (setup)
    ## -------------------------------------

    set ignore_list $SVAR(metrics,path_group_ignore_list_setup)

    set path_group_setup_item_list [list]

    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        set item [list \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack) \
          $path_group_name \
          $scenario_name \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_length) \
          $qor(path_group_data,$scenario_name,$path_group_name,setup,path_period) \
          ]
        set valid 1
        if { ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)] || \
            ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_length)] || \
            ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,setup,path_period)] \
          } {
          set valid 0
        }
        if { $valid } {
          lappend path_group_setup_item_list $item
        }
      }
    }

    set item_list [lsort -index 0 -increasing -real $path_group_setup_item_list]
    set item_list_length [llength $item_list]

    set index_count 0
    set metric_count 0

    while { $metric_count < $SVAR(metrics,max_path_group_count) } {

      if { $index_count < $item_list_length } {
        set item [lindex $item_list $index_count]
        set path_slack      [lindex $item 0]
        set path_group_name [lindex $item 1]
        set scenario_name   [lindex $item 2]
        set path_length     [lindex $item 3]
        set path_period     [lindex $item 4]

        set adj_path_slack [sproc_metric_normalize -value $path_slack -current_unit $units(time_unit)]

        if { [string is double -strict $path_length] && ($path_length != 0) } {
          set adj_path_length [sproc_metric_normalize -value $path_length -current_unit $units(time_unit)]
          set freq_actual [expr 1.0 / ( $adj_path_length / 1000000000000.0 )]
        } else {
          set freq_actual NaM
        }

        if { [string is double -strict $path_period] && ($path_period != 0) } {
          set adj_path_period [sproc_metric_normalize -value $path_period -current_unit $units(time_unit)]
          set freq_target [expr 1.0 / ( $adj_path_period / 1000000000000.0 )]
        } else {
          set freq_target NaM
        }

        set ignore_flag 0
        foreach pattern $ignore_list {
          if { [string match $pattern $path_group_name] } {
            set ignore_flag 1
          }
        }
        if { $ignore_flag } {
          incr index_count
          continue
        }
      } else {
        set path_slack      NaM
        set path_group_name NaM
        set scenario_name   NaM
        set freq_actual     NaM
        set freq_target     NaM
        set adj_path_slack  NaM
      }

      ## set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
      set path_group_name_displayed $path_group_name

      sproc_msg -info "METRIC | DOUBLE STA.SETUP_$metric_count.SLACK                  | $adj_path_slack"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.PATH_GROUP             | $path_group_name_displayed"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.SCENARIO               | $scenario_name"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.CALCULATED_FREQ_ACTUAL | $freq_actual"
      sproc_msg -info "METRIC | STRING STA.SETUP_$metric_count.CALCULATED_FREQ_TARGET | $freq_target"
      incr index_count
      incr metric_count

    }

    ## -------------------------------------
    ## This code is for generation of path group metrics (hold)
    ## -------------------------------------

    set ignore_list $SVAR(metrics,path_group_ignore_list_hold)

    set path_group_hold_item_list [list]
    foreach scenario_name $qor(path_group_data,scenario_name_list) {
      foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {
        set item [list \
          $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack) \
          $path_group_name \
          $scenario_name \
          ]
        set valid 1
        if { ![string is double -strict $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)] } {
          set valid 0
        }
        if { $valid } {
          lappend path_group_hold_item_list $item
        }
      }
    }

    set item_list [lsort -index 0 -increasing -real $path_group_hold_item_list]
    set item_list_length [llength $item_list]

    set index_count 0
    set metric_count 0

    while { $metric_count < $SVAR(metrics,max_path_group_count) } {

      if { $index_count < $item_list_length } {
        set item [lindex $item_list $index_count]
        set path_slack      [lindex $item 0]
        set path_group_name [lindex $item 1]
        set scenario_name   [lindex $item 2]

        set adj_path_slack [sproc_metric_normalize -value $path_slack -current_unit $units(time_unit)]

        set ignore_flag 0
        foreach pattern $ignore_list {
          if { [string match $pattern $path_group_name] } {
            set ignore_flag 1
          }
        }
        if { $ignore_flag } {
          incr index_count
          continue
        }
      } else {
        set path_slack      NaM
        set path_group_name NaM
        set scenario_name   NaM
        set adj_path_slack  NaM
      }

      ## set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
      set path_group_name_displayed $path_group_name

      sproc_msg -info "METRIC | DOUBLE STA.HOLD_$metric_count.SLACK                  | $adj_path_slack"
      sproc_msg -info "METRIC | STRING STA.HOLD_$metric_count.PATH_GROUP             | $path_group_name_displayed"
      sproc_msg -info "METRIC | STRING STA.HOLD_$metric_count.SCENARIO               | $scenario_name"
      incr index_count
      incr metric_count

    }

    ## -------------------------------------
    ## This code is for generation of summary metrics
    ## -------------------------------------

    foreach scenario_name $qor(summary_data,_ss,scenario_name_list) {
      set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
      if { [info exists qor(summary_data,_ss,$scenario_name,setup,path_slack)] } {
        if { $qor(summary_data,_ss,$scenario_name,setup,path_slack) != "" } {
          set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,setup,path_slack) -current_unit $units(time_unit)]
          set tns         [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,setup,tns) -current_unit $units(time_unit)]
          set nvp                                        $qor(summary_data,_ss,$scenario_name,setup,nvp)
          sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.SCENARIO.$scenario_name_displayed  | $path_slack"
          sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.SCENARIO.$scenario_name_displayed  | $tns"
          sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.SCENARIO.$scenario_name_displayed | $nvp"
        }
      }
      if { [info exists qor(summary_data,_ss,$scenario_name,hold,path_slack)] } {
        if { $qor(summary_data,_ss,$scenario_name,hold,path_slack) != "" } {
          set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,hold,path_slack) -current_unit $units(time_unit)]
          set tns         [sproc_metric_normalize -value $qor(summary_data,_ss,$scenario_name,hold,tns) -current_unit $units(time_unit)]
          set nvp                                        $qor(summary_data,_ss,$scenario_name,hold,nvp)
          sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.SCENARIO.$scenario_name_displayed  | $path_slack"
          sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.SCENARIO.$scenario_name_displayed  | $tns"
          sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.SCENARIO.$scenario_name_displayed | $nvp"
        }
      }
    }

    if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
      set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ms,setup,path_slack) -current_unit $units(time_unit)]
      set tns         [sproc_metric_normalize -value $qor(summary_data,_ms,setup,tns) -current_unit $units(time_unit)]
      set nvp                                        $qor(summary_data,_ms,setup,nvp)
      sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.COMPOSITE  | $path_slack"
      sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.COMPOSITE  | $tns"
      sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.COMPOSITE | $nvp"
    }
    if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
      set path_slack  [sproc_metric_normalize -value $qor(summary_data,_ms,hold,path_slack) -current_unit $units(time_unit)]
      set tns         [sproc_metric_normalize -value $qor(summary_data,_ms,hold,tns) -current_unit $units(time_unit)]
      set nvp                                        $qor(summary_data,_ms,hold,nvp)
      sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.COMPOSITE  | $path_slack"
      sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.COMPOSITE  | $tns"
      sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.COMPOSITE | $nvp"
    }

    ## -------------------------------------
    ## This code is for generation of all path group metrics
    ## By default this code is disabled to prevent generation
    ## of an extemely large number of metrics for some designs.
    ## -------------------------------------

    if {1} {
      foreach scenario_name $qor(path_group_data,scenario_name_list) {
        foreach path_group_name $qor(path_group_data,path_group_name_list,$scenario_name) {

          set path_group_name_displayed [sproc_metric_clean_string -string $path_group_name]
          set scenario_name_displayed   [sproc_metric_clean_string -string $scenario_name]
          set metric_name $path_group_name_displayed.$scenario_name_displayed

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,logic_levels)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.LOGIC_LEVELS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,path_slack)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.WNS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,path_slack)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.WNS_MIN.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,tns)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.TNS_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,tns)
          if { $data != "NA" } {
            set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
            sproc_msg -info "METRIC | DOUBLE STA.TNS_MIN.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,setup,nvp)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.NVP_MAX.$metric_name | $value"
          }

          set data $qor(path_group_data,$scenario_name,$path_group_name,hold,nvp)
          if { $data != "NA" } {
            set value [expr int($data)]
            sproc_msg -info "METRIC | INTEGER STA.NVP_MIN.$metric_name | $value"
          }
        }
      }
    }

  }

  if { $options(-metrics_power) } {

    foreach scenario_name $power(scenario_name_list) {

      if { [string is double -strict $power($scenario_name,total_power)] } {
        set total_power   [sproc_metric_normalize -value $power($scenario_name,total_power)   -current_unit $power($scenario_name,total_power_units)]
      } else {
        set total_power   NaM
      }
      if { [string is double -strict $power($scenario_name,leakage_power)] } {
        set leakage_power [sproc_metric_normalize -value $power($scenario_name,leakage_power) -current_unit $power($scenario_name,leakage_power_units)]
      } else {
        set leakage_power NaM
      }

      if { $scenario_name == "None/non-MCMM" } {
        if { $synopsys_program_name == "pt_shell" } {
          if { $pt_shell_mode == "primetime" } {
            set scenario_name $options(-scenario_name)
          }
        }
      }
      set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]

      sproc_msg -info "METRIC | DOUBLE PWR.TOTAL.$scenario_name_displayed   | $total_power"
      sproc_msg -info "METRIC | DOUBLE PWR.LEAKAGE.$scenario_name_displayed | $leakage_power"

    }

  }

  if { $options(-metrics_design) } {

    ## From report_threshold_voltage_group

    foreach vth_name $vth(vth,vth_names) {
      sproc_msg -info "METRIC | INTEGER PWR.VTH_NUM_CELLS.$vth_name     | $vth(cell_count,$vth_name)"
      sproc_msg -info "METRIC | PERCENT PWR.VTH_PERCENT_CELLS.$vth_name | $vth(cell_percentage,$vth_name)"
    }

    ## From report_congestion

    if { [info exists cong(error_flag)] } {
      sproc_msg -info "METRIC | PERCENT PHYSICAL.CONGESTION | $cong(grc_overflow)"
    }

    ## From report_qor

    sproc_msg -info "METRIC | DOUBLE  LOGICAL.CELL_AREA     | $qor(design_data,cell_area)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_INSTS     | $qor(design_data,leaf_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_MACROS    | $qor(design_data,macro_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_FLIPFLOPS | $qor(design_data,seq_cell_count)"
    sproc_msg -info "METRIC | INTEGER LOGICAL.NUM_NETS      | $qor(design_data,net_count)"

    sproc_msg -info "METRIC | DOUBLE  PHYSICAL.WLENGTH      | $qor(design_data,net_length)"

    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.TOTAL | $qor(design_data,ldrc_total)"
    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.TRANS | $qor(design_data,ldrc_trans)"
    sproc_msg -info "METRIC | INTEGER STA.LOGICAL_DRC.CAP   | $qor(design_data,ldrc_cap)"

    ## From report_design_physical

    if { $synopsys_program_name == "icc_shell" } {
      sproc_msg -info "METRIC | PERCENT PHYSICAL.UTIL         | $phy(cell2core_ratio)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.AREA         | $phy(chip_area)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.WIDTH        | $phy(chip_width)"
      sproc_msg -info "METRIC | DOUBLE  PHYSICAL.HEIGHT       | $phy(chip_height)"
      sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_ERRORS | $phy(num_drc_errors)"
      sproc_msg -info "METRIC | INTEGER VERIFY.DRC.NUM_TYPES  | $phy(num_drc_errors_types)"
      sproc_msg -info "METRIC | STRING  VERIFY.DRC.TOOL       | ICC"
    }

  }

  if { $options(-metrics_cts) } {
    if {1} {
      sproc_msg -warning "CTS metrics must be enabled via edit to procs_metrics.tcl file."
    } else {
      foreach name [array names cts *,skew] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set data $cts($name)
        set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
        sproc_msg -info "METRIC | DOUBLE CTS.SKEW.$metric_name | $value"
      }
      foreach name [array names cts *,path] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set data $cts($name)
        set value [sproc_metric_normalize -value $data -current_unit $units(time_unit)]
        sproc_msg -info "METRIC | DOUBLE CTS.PATH.$metric_name | $value"
      }
      foreach name [array names cts *,sinks] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set value $cts($name)
        sproc_msg -info "METRIC | INTEGER CTS.SINKS.$metric_name | $value"
      }
      foreach name [array names cts *,drc] {
        set scenario_name [lindex [split $name ,] 0]
        set clock_name    [lindex [split $name ,] 1]

        set clock_name_displayed    [sproc_metric_clean_string -string $clock_name]
        set scenario_name_displayed [sproc_metric_clean_string -string $scenario_name]
        set metric_name $clock_name_displayed.$scenario_name_displayed

        set value $cts($name)
        sproc_msg -info "METRIC | INTEGER CTS.DRC.$metric_name | $value"
      }
    }
  }

  ## -------------------------------------
  ## This code creates the file used to support the QoR summary report.
  ## -------------------------------------

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
  lappend attributes [list TYPE FLOW_SUMMARY]

  ## -------------------------------------
  ## Start output
  ## -------------------------------------

  set fs_output [list]
  lappend fs_output "{"

    ## -------------------------------------
    ## Process attributes
    ## -------------------------------------

    foreach attribute $attributes {
      set name  [lindex $attribute 0]
      set value [lindex $attribute 1]
      lappend fs_output "\"$name\": \"$value\""
    }
    lappend fs_output "\"flow_summary\": \["

    ## -------------------------------------
    ## All content below here is optional
    ## -------------------------------------

    ## -------------------------------------
    ## This code generates per-design summary information.
    ## -------------------------------------

    if { [info exists qor] } {
      set file $options(-report_qor)
      set file [join [lrange [split $file /] end-3 end] /]
    }

    if { [info exists qor(summary_data,_ms,setup,path_slack)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup WNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,setup,path_slack) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,path_slack,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup TNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,setup,tns) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,tns,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Setup Violations" \
        -value $qor(summary_data,_ms,setup,nvp) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,setup,nvp,line_number)]
    }
    if { [info exists qor(summary_data,_ms,hold,path_slack)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold WNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,hold,path_slack) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,path_slack,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold TNS ($units(time_unit))" \
        -value $qor(summary_data,_ms,hold,tns) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,tns,line_number)]
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Design Hold Violations" \
        -value $qor(summary_data,_ms,hold,nvp) \
        -section 1 \
        -file $file \
        -line $qor(summary_data,_ms,hold,nvp,line_number)]
    }

    if { [info exists qor(design_data,leaf_cell_count)] } {
      set value $qor(design_data,leaf_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Leaf Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,leaf_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,bufinv_cell_count)] } {
      set value $qor(design_data,bufinv_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Buf/Inv Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,bufinv_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,ctbufinv_cell_count)] } {
      set value $qor(design_data,ctbufinv_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "CT Buf/Inv Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,ctbufinv_cell_count,line_number)]
      }
    }

    if { [info exists qor(design_data,comb_cell_count)] } {
      set value $qor(design_data,comb_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Comb Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,comb_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,seq_cell_count)] } {
      set value $qor(design_data,seq_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Seq Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,seq_cell_count,line_number)]
      }
    }
    if { [info exists qor(design_data,macro_cell_count)] } {
      set value $qor(design_data,macro_cell_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Macro Cell Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,macro_cell_count,line_number)]
      }
    }

    if { [info exists qor(design_data,cell_area)] } {
      set value $qor(design_data,cell_area)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Cell Area" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,cell_area,line_number)]
      }
    }
    if { [info exists qor(design_data,design_area)] } {
      set value $qor(design_data,design_area)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Design Area" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,design_area,line_number)]
      }
    }
    if { [info exists qor(design_data,net_length)] } {
      set value $qor(design_data,net_length)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Length" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,net_length,line_number)]
      }
    }

    if { [info exists qor(design_data,net_count)] } {
      set value $qor(design_data,net_count)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Count" \
          -value $value \
          -section 4 \
          -file $file \
          -line $qor(design_data,net_count,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_total)] } {
      set value $qor(design_data,ldrc_total)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations Total" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_total,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_trans)] } {
      set value $qor(design_data,ldrc_trans)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations Trans" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_trans,line_number)]
      }
    }
    if { [info exists qor(design_data,ldrc_cap)] } {
      set value $qor(design_data,ldrc_cap)
      if { $value != -1 } {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Net Violations MaxCap" \
          -value $value \
          -section 5 \
          -file $file \
          -line $qor(design_data,ldrc_cap,line_number)]
      }
    }

    if { [info exists phy] } {
      set file $options(-report_design_physical)
      set file [join [lrange [split $file /] end-3 end] /]
    }

    if { [info exists phy(cell2core_ratio)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "Utilization" \
        -value $phy(cell2core_ratio) \
        -section 4 \
        -file $file \
        -line $phy(cell2core_ratio,line_number)]
    }
    if { [info exists phy(num_drc_errors)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "DRC Errors Total" \
        -value $phy(num_drc_errors) \
        -section 5 \
        -file $file \
        -line $phy(num_drc_errors,line_number)]
    }
    if { [info exists phy(num_drc_errors_types)] } {
      set fs_output [sproc_qv_flow_summary \
        -o $fs_output \
        -name "DRC Errors Types" \
        -value $phy(num_drc_errors_types) \
        -section 5 \
        -file $file \
        -line $phy(num_drc_errors_types,line_number)]
    }

    if { [info exists vth] } {
      set file $options(-report_threshold_voltage_group)
      set file [join [lrange [split $file /] end-3 end] /]
      foreach vth_name $vth(vth,vth_names) {
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Vth Percent ($vth_name)" \
          -value $vth(cell_percentage,$vth_name) \
          -section 3 \
          -file $file \
          -line $vth(cell_percentage,$vth_name,line_number)]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Vth Count   ($vth_name)" \
          -value $vth(cell_count,$vth_name) \
          -section 3 \
          -file $file \
          -line $vth(cell_count,$vth_name,line_number)]
      }
    }

    if { [info exists power] } {
      set file $options(-report_power)
      set file [join [lrange [split $file /] end-3 end] /]

      set total_power_max ""
      set total_power_units ""
      set total_power_line_number ""
      set leakage_power_max ""
      set leakage_power_units ""
      set leakage_power_line_number ""

      foreach scenario_name $power(scenario_name_list) {
        set total_power_units   $power($scenario_name,total_power_units)
        set leakage_power_units $power($scenario_name,leakage_power_units)

        if { [string is double -strict $power($scenario_name,total_power)] } {
          if { ($total_power_max == "") || ($power($scenario_name,total_power) > $total_power_max) } {
            set total_power_max         $power($scenario_name,total_power)
            set total_power_line_number $power($scenario_name,total_power,line_number)
          }
        }

        if { [string is double -strict $power($scenario_name,leakage_power)] } {
          if { ($leakage_power_max == "") || ($power($scenario_name,leakage_power) > $leakage_power_max) } {
            set leakage_power_max         $power($scenario_name,leakage_power)
            set leakage_power_line_number $power($scenario_name,leakage_power,line_number)
          }
        }
      }

      if { [string is double -strict $total_power_max] } {
        set total_power_max_adj [sproc_metric_normalize -value $total_power_max -current_unit $total_power_units]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Power Total (mW)" \
          -value $total_power_max_adj \
          -section 2 \
          -file $file \
          -line $total_power_line_number]
      }

      if { [string is double -strict $leakage_power_max] } {
        set leakage_power_max_adj [sproc_metric_normalize -value $leakage_power_max -current_unit $leakage_power_units]
        set fs_output [sproc_qv_flow_summary \
          -o $fs_output \
          -name "Power Leakage (mW)" \
          -value $leakage_power_max_adj \
          -section 2 \
          -file $file \
          -line $leakage_power_line_number]
      }

    }

    ## -------------------------------------
    ## Complete output & create file
    ## -------------------------------------

    lappend fs_output "\]"
  lappend fs_output "}"

  set fs_output [sproc_qv_add_commas -lines $fs_output]
  set fs_output [join $fs_output "\n"]

  set fid [open $SEV(rpt_dir)/.$SEV(block_name).$SEV(step).$SEV(task).$SEV(dst).design_summary-flow_summary.qor w]
  puts $fid $fs_output
  close $fid

  sproc_qv_gen_files

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_metric_main \
  -info "This is the main metrics procedure." \
  -define_args { \
    {-scenario_name                  "Specifies the scenario name"           AString string optional}
  {-metrics_sta                    "Generate 'sta' metrics"                "" boolean optional}
  {-metrics_power                  "Generate 'power' metrics"              "" boolean optional}
  {-metrics_design                 "Generate 'design' metrics"             "" boolean optional}
  {-metrics_cts                    "Generate 'cts' metrics"                "" boolean optional}
  {-report_qor                     "The file to parse."                    AString string optional}
  {-report_units                   "The file to parse."                    AString string optional}
  {-report_power                   "The file to parse."                    AString string optional}
  {-report_congestion              "The file to parse."                    AString string optional}
  {-report_design_physical         "The file to parse."                    AString string optional}
  {-report_threshold_voltage_group "The file to parse."                    AString string optional}
  {-report_clock_tree              "The file to parse."                    AString string optional}
}

## -----------------------------------------------------------------------------
## sproc_metric_tags:
## -----------------------------------------------------------------------------

proc sproc_metric_tags { args } {

  global env SEV SVAR TEV DEV

  sproc_pinfo -mode start

  ## -------------------------------------
  ## This section of code is for automatic generation of metrics.
  ## The metrics SYS.TAG_21 - SYS.TAG_30 are allocated for this purpose.
  ## -------------------------------------

  ## -------------------------------------
  ## SYS.TAG_21
  ##
  ## We are setting this metric to a value that always indicates the date of the next Sunday.
  ## This ensures data is tagged according to the week it is developed.
  ## (and the data is ready for reporting on Monday morning)
  ## -------------------------------------

  set seconds_per_day [expr 24 * 60 * 60]
  set today_in_seconds [clock seconds]
  set today_in_name [clock format $today_in_seconds -format "%A"]

  while { $today_in_name != "Sunday" } {
    set today_in_seconds [expr $today_in_seconds + $seconds_per_day]
    set today_in_name [clock format $today_in_seconds -format "%A"]
  }

  set metric_value [clock format $today_in_seconds -format "%Y_%m_%d"]
  sproc_msg -info "METRIC | TAG SYS.TAG_21 | $metric_value"

  ## -------------------------------------
  ## SYS.TAG_22
  ##
  ## We are setting this metric to indicate if the RTM is running the flow.
  ## -------------------------------------

  sproc_msg -info "METRIC | TAG SYS.TAG_22 | [info exists env(LYNX_RTM_PRESENT)]"

  ## -------------------------------------
  ## SYS.TAG_23 - SYS.TAG_30
  ##
  ## These are placeholders for more interesting content.
  ## -------------------------------------

  sproc_msg -info "METRIC | TAG SYS.TAG_23 | TagValue23"
  sproc_msg -info "METRIC | TAG SYS.TAG_24 | TagValue24"
  sproc_msg -info "METRIC | TAG SYS.TAG_25 | TagValue25"
  sproc_msg -info "METRIC | TAG SYS.TAG_26 | TagValue26"
  sproc_msg -info "METRIC | TAG SYS.TAG_27 | TagValue27"
  sproc_msg -info "METRIC | TAG SYS.TAG_28 | TagValue28"
  sproc_msg -info "METRIC | TAG SYS.TAG_29 | TagValue29"
  sproc_msg -info "METRIC | TAG SYS.TAG_30 | TagValue30"

  sproc_pinfo -mode stop

}

define_proc_attributes sproc_metric_tags \
  -info "Generates automatic tag metrics." \
  -define_args {
}

## -----------------------------------------------------------------------------
## sproc_qv_flow_summary:
## -----------------------------------------------------------------------------

proc sproc_qv_flow_summary { args } {

  set options(-o) ""
  set options(-name) ""
  set options(-value) ""
  set options(-file) ""
  set options(-line) ""
  set options(-section) ""
  parse_proc_arguments -args $args options

  set output $options(-o)

  lappend output "{"

    lappend output "\"name\": \"$options(-name)\""
    lappend output "\"value\": \"$options(-value)\""

    if { $options(-file) != "" } {
      lappend output "\"file\": \"$options(-file)\""
    }
    if { $options(-line) != "" } {
      lappend output "\"line\": \"$options(-line)\""
    }
    if { $options(-section) != "" } {
      lappend output "\"section\": \"$options(-section)\""
    }

  lappend output "}"

  return $output

}

define_proc_attributes sproc_qv_flow_summary \
  -info "Proc that creates flow summary entries in JSON." \
  -define_args { \
    {-o          "Output"        AString string required}
  {-name       "Item name"     AString string required}
  {-value      "Item value"    AString string required}
  {-file       "Item file"     AString string optional}
  {-line       "Item line"     AnInt int optional}
  {-section    "Item section"  AnInt int optional}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
