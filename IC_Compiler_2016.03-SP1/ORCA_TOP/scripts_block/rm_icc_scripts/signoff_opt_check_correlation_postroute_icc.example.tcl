puts "RM-Info: Running script [info script]\n"

# Note:
# If variables are not set to their recommended settings for best signoff correlation check_signoff_correlation and check_primetime_icc_consistency_settings commands will report them as Errors.
# In this script the Primetime values will be assumed for IC Compiler and applied for report_qor and report_timing
# The reason why they are not turned on in ICC RM by default is they are not necessarily to be applied and may depend on specific needs.
# For further information of these variables, please refer to SolvNet #021231 "IC Compiler Correlation Checklist Trilogy"

if {$PT_DIR == ""} {
  set PT_DIR [file dirname [sh which pt_shell]]
}
if {$STARRC_DIR == ""} {
  set STARRC_DIR [file dirname [sh which StarXtract]]
}
if {![file exists [which $PT_DIR/pt_shell]] || ![file exists [which $STARRC_DIR/StarXtract]]} {
  echo "RM-Info : $PT_DIR/pt_shell or $STARRC_DIR/StarXtract does not exist. check_signoff_correlation is skipped."

} else {

  set_primetime_options  -exec_dir $PT_DIR

  set_starrcxt_options  -exec_dir $STARRC_DIR \
     -map_file        $STARRC_MAP_FILE

## Check Primetime settings versus IC Compiler for correlation
# If IC Compiler variables differ from Primetime then change them to match 
  redirect -var cpc {check_primetime_icc_consistency_settings}
  puts "$cpc"

foreach var [lsearch -all [split $cpc ] (CORR-803)] {
  set variable_name  "[lindex [split $cpc] [expr $var - 20]]"
  regsub -all "\"" $variable_name "" variable_name
  set ICC_value "[lindex [split $cpc] [expr $var - 6]]"
  regsub -all ";|\"" $ICC_value "" ICC_value
  set PT_value "[lindex [split $cpc] [expr $var - 1]]"
  regsub -all "\"|\\.$" $PT_value "" PT_value
  if {![regexp "set_operating_condition" $variable_name]} {
    puts "Changing variable $variable_name from $ICC_value to $PT_value"
    set_app_var $variable_name $PT_value
  }
}

## Check StarRC settings versus ICC for correlation
check_signoff_correlation -star_only
}

extract_rc
update_timing

## Report QoR and Timing
redirect -file $REPORTS_DIR/postroute_timing_correlation_check.qor.rpt {report_qor}
redirect -file $REPORTS_DIR/postroute_timing_correlation_check.timing.rpt {report_timing -scenarios [all_scenarios]}

puts "RM-Info: Completed script [info script]\n"
