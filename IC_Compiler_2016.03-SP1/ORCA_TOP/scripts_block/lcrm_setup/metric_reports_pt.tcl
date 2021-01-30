##########################################################################################
# Lynx Compatible Reference Methodology (LCRM) Setup File
# Script: metric_reports_pt.tcl
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2007-2015 Synopsys, Inc. All rights reserved.
##########################################################################################
## DESCRIPTION:
## * This script provides reports which are parsed to create design metrics
## -----------------------------------------------------------------------------


redirect $RPT(basename).report_units {
  report_units
}

redirect $RPT(basename).report_qor {
  sproc_pt_report_qor -scenario $TEV(scenario)
}

redirect $RPT(basename).report_constraint {
  echo "case_analysis_sequential_propagation = $case_analysis_sequential_propagation"
  report_constraint \
    -all_violators \
    -nosplit
}

if { $power_enable_analysis } {
    redirect $RPT(basename).report_power {
      report_power
    }
}

if { $TEV(vx_enable) } {

  redirect $RPT(basename).report_clock_timing.latency {
    report_clock_timing -type latency -nosplit -variation
  }
  redirect $RPT(basename).report_clock_timing.skew {
    report_clock_timing -type skew -nosplit -variation
  }

} else {

  redirect $RPT(basename).report_clock_timing.latency {
    report_clock_timing -type latency -nosplit
  }
  redirect $RPT(basename).report_clock_timing.skew {
    report_clock_timing -type skew -nosplit
  }

}


## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------

