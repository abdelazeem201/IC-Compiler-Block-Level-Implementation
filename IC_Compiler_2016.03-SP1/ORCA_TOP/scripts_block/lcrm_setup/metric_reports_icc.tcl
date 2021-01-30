##########################################################################################
# Lynx Compatible Reference Methodology (LCRM) Setup File
# Script: metric_reports_icc.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

## DESCRIPTION:
## * This script provides reports which are parsed to create design metrics
## -----------------------------------------------------------------------------

redirect -file $SEV(rpt_dir)/icc.report_units {
  report_units
}

redirect -file $SEV(rpt_dir)/icc.report_qor {
  report_qor
  report_qor -summary
}

redirect -file $SEV(rpt_dir)/icc.report_threshold_voltage_group {
  report_threshold_voltage_group
}

redirect -file $SEV(rpt_dir)/icc.report_power {
  if { [llength [all_active_scenarios]] > 0 } {
    report_power -scenario [all_active_scenarios]
  } else {
    report_power -nosplit
  }
}

redirect -file $SEV(rpt_dir)/icc.report_design_physical {
  report_design_physical -all -verbose
}

redirect $SEV(rpt_dir)/icc.cts.report_clock_timing {
  foreach scenario [all_active_scenarios] {
    current_scenario $scenario
    report_clock_timing -nosplit -type summary 
  }
}

set my_all_active_scenarios [all_active_scenarios]
if { [regexp {clock_opt_} $SEV(script_file) ] && [llength $my_all_active_scenarios] > 0} {
  redirect $SEV(rpt_dir)/icc.cts.report_clock_tree {
    report_clock_tree -settings -nosplit -scenario $my_all_active_scenarios
    report_clock_tree -exceptions -nosplit -scenario $my_all_active_scenarios
    report_clock_tree -nosplit -scenario $my_all_active_scenarios
    report_clock_tree -summary -nosplit -scenario $my_all_active_scenarios
  }
}

## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------

