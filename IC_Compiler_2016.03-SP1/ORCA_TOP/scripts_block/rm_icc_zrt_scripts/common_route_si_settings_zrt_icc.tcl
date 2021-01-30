puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
##########################################################################################

#########################################
#       TIMING ANALYSIS OPTIONS         #
#########################################
## By default, Xtalk Delta Delay is enabled for all flows
set_si_options -delta_delay true  \
               -route_xtalk_prevention true \
               -route_xtalk_prevention_threshold 0.25 \
	       -analysis_effort medium

## By default, -route_xtalk_prevention true enables xtalk prevention for global route and track assignment,
#  to disable xtalk prevention for global route, uncomment the following command :
#  set_route_zrt_global_options -crosstalk_driven false

## For the QoR flow, we also enable min_delta_delay
set_si_options -min_delta_delay true 

#########################################
#    MAX_TRAN FIXING                    #
#########################################
## From 2006.06-SP4 onwards, route_opt will NOT fix nor report Delta Max 
## Tran violations.  Hence all max_tran violations exclude the portion 
## that is introduced by Xtalk.
## If you want to change this behavior, and fix max_transition violations 
## including these caused by Xtalk, please use the switch -max_transition_mode
## in set_si_options. Keep in mind that you can expect a runtime hit of up 
## to 2x in DRC fixing during route_opt.

# set_si_options -delta_delay true \
#                -route_xtalk_prevention true \
#                -route_xtalk_prevention_threshold 0.25 \
#		 -analysis_effort medium \
#                -max_transition_mode total_slew

#########################################
#      ADVANCED TIMING FEATURES         #
#########################################

## if using CCS noise model, uncomment the following:
# set_app_var rc_noise_model_mode advanced

## if static noise (aka glitches) needs to be reduced, please use the following with additional options :
# set_si_options -delta_delay true \
#                -route_xtalk_prevention true \
#                -route_xtalk_prevention_threshold 0.25 \
#		 -analysis_effort medium \
#                -static_noise true \
#                -static_noise_threshold_above_low 0.35 \
#                -static_noise_threshold_below_high 0.35

## if you want to enable Timing Windows during XDD calculation, please use :
#  set_si_options -timing_window true

########################################
#          ZROUTE OPTIONS              #
########################################
## Default search and repair loop setting for route_opt -initial_route is 10. 
#  Use 40 to improve DRC convergence for aggressive range rules which are more prevalent at newer technology nodes such as 28nm and below.
#  set_route_opt_strategy -search_repair_loop 40 

# For designs with process nodes 40nm and above, it is recommended to uncomment the line below
# to disable the check min area and length for cell pins feature (default is true):
# set_route_zrt_detail_options -check_pin_min_area_min_length false

## Zroute global route specific options can be set by the following command
#  set_route_zrt_global_options 

## Zroute track assign specific options can be set by the following command
#  set_route_zrt_track_options 

## Zroute detail route specific options can be set by the following command
#  set_route_zrt_detail_options

########################################
#   route_opt and focal_opt OPTIONS
########################################
## Set Area Critical Range
## Typical value: 3-4 percent of critical clock period
if {$AREA_CRITICAL_RANGE_POST_RT != ""} {set_app_var physopt_area_critical_range $AREA_CRITICAL_RANGE_POST_RT}

## Set Power Critical Range
## Typical value: 3-4 percent of critical clock period
if {$POWER_CRITICAL_RANGE_POST_RT != ""} {set_app_var physopt_power_critical_range $POWER_CRITICAL_RANGE_POST_RT}

set_app_var routeopt_skip_report_qor true  ;##default is false - set to skip second report_qor in route_opt

## To enable port punching mode for route_opt and focal_opt to open additional bufferable area in a net that is difficult
#  to fix with buffer insertion due to a consistency mismatch between the logical and physical hierarchy.
#  Currently it works only with multi-threading. 
#  	if {$ICC_NUM_CORES > 1} {set_route_opt_strategy -enable_port_punching TRUE}

## High resistance optimization can be enabled for designs during routing and postroute. 
set_optimization_strategy -high_resistance $ICC_HIGH_RESISTANCE_OPTIMIZATION


########################################
#       ROUTE_OPT CROSSTALK OPTIONS    #
########################################
## 2010.03 control for xtalk reduction - values shown are just examples and not recommendations 
#  set_route_opt_zrt_crosstalk_options -effort_level medium                                ;# low|medium|high - default low 
#  set_route_opt_zrt_crosstalk_options -setup true                                         ;# default true 
#  set_route_opt_zrt_crosstalk_options -hold true                                          ;# default false 
#  set_route_opt_zrt_crosstalk_options -transition true                                    ;# default false 
#             										   ;# needs:  set_si_options -max_transition_mode total_slew
#  set_route_opt_zrt_crosstalk_options -static_noise true                                  ;# default false 
#             										   ;# needs:  set_si_options -static_noise true 


########################################
#       REDUNDANT VIA INSERTION        #
########################################
if {$ICC_DBL_VIA } {
  ## Customize the following as needed - if nothing is provided, Zroute will select from those available
  #  define_zrt_redundant_vias \
        #-from_via "<from_via_list>" \
        #-to_via "<to_via_list>" \
        #-to_via_x_size "<list_of_via_x_sizes>" \
        #-to_via_y_size "<list_of_via_y_sizes>" \
        #-to_via_weights "<list_of_via_weights>"
        ##example: -from_via "VIA45 VIA45 VIA12A" -to_via "VIA45f VIA45 VIA12f" -to_via_x_size "1 1 1" -to_via_y_size "2 2 2" -to_via_weights "10 6 4"

  ## Speficy a customized file 
  if {[file exists [which $ICC_CUSTOM_DBL_VIA_DEFINE_SCRIPT]]} {
    source -echo $ICC_CUSTOM_DBL_VIA_DEFINE_SCRIPT
  }
 
  if {$ICC_DBL_VIA_FLOW_EFFORT == "HIGH"} {
    # set_route_zrt_common_options -eco_route_concurrent_redundant_via_mode reserve_space
    # set_route_zrt_common_options -eco_route_concurrent_redundant_via_effort_level low  ;# default is low
  }
}


######################################
#           ANTENNA FIXING           #
######################################
if {$ICC_FIX_ANTENNA } {
  
  if {[file exists [which $ANTENNA_RULES_FILE]]} {
       set_route_zrt_detail_options -antenna true
       source -echo $ANTENNA_RULES_FILE
   } else {
       echo "RM-Info : Antenna rules file does not exist"
       echo "RM-Info : Turning off antenna fixing"
       set_route_zrt_detail_options -antenna false
   }
} else {
       echo "RM-Info : Turning off antenna fixing"
       set_route_zrt_detail_options -antenna false
}
   

puts "RM-Info: Completed script [info script]\n"
