## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/scripts_dev/lcrm/rtm_auxx/scripts_global/TECH/common.tcl#10 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Copyright (c) 2010-2011 Synopsys
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This is common.tcl for TECH
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This variable defines the valid set of library names.
## These names, which are arbitrary strings, provide
## convenient handles for specifying libraries.
## These variables must use characters that are alpha/numeric/underscore only.
## Examples: stdcell_hvt, stdcell_lvt, ram, io, etc
## -----------------------------------------------------------------------------

set SVAR(setup,lib_types_list) [list \
  "your_lib_1" \
  "your_lib_2" \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This variable defines the valid set of operating condition names.
## These names, which are arbitrary strings, provide
## convenient handles for specifying operating conditions.
## These variables must use characters that are alpha/numeric/underscore only.
## Examples: OC_BC, OC_WC, OC_TYP, OC_LEAKAGE, etc.
## -----------------------------------------------------------------------------

set SVAR(setup,oc_types_list) [list \
  "your_oc_type_1" \
  "your_oc_type_2" \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This variable defines the valid set of parasitic condition names.
## These names, which are arbitrary strings, provide
## convenient handles for specifying parasitic conditions.
## These variables must use characters that are alpha/numeric/underscore only.
## Examples: RC_MIN_1, RC_MAX_1, RC_TYP, etc.
## -----------------------------------------------------------------------------

set SVAR(setup,rc_types_list) [list \
  "your_rc_type_1" \
  "your_rc_type_2" \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type CCS (.db format) (your_oc_type_1)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,db_ccs_filelist,your_oc_type_1) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type CCS (.db format) (your_oc_type_2)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,db_ccs_filelist,your_oc_type_2) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type NLDM (.db format) (your_oc_type_1)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,db_nldm_filelist,your_oc_type_1) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type NLDM (.db format) (your_oc_type_2)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,db_nldm_filelist,your_oc_type_2) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## GDS file library
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,gds_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## HSPICE files
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,hspice_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## LVS files
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,lvs_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Milkyway Reference Libraries
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,mw_reflist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Enable use of CCS format Liberty files.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,use_ccs) "0"

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Verilog files for library cells uses for gate-level simulation.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,vlog_sim_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Verilog files for library cells used for ATPG with TetraMAX.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_1,vlog_tmax_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type CCS (.db format) (your_oc_type_1)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,db_ccs_filelist,your_oc_type_1) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type CCS (.db format) (your_oc_type_2)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,db_ccs_filelist,your_oc_type_2) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type NLDM (.db format) (your_oc_type_1)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,db_nldm_filelist,your_oc_type_1) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Liberty files of type NLDM (.db format) (your_oc_type_2)
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,db_nldm_filelist,your_oc_type_2) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## GDS file library
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,gds_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## HSPICE files
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,hspice_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## LVS files
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,lvs_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Milkyway Reference Libraries
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,mw_reflist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Enable use of CCS format Liberty files.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,use_ccs) "0"

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Verilog files for library cells uses for gate-level simulation.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,vlog_sim_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## Verilog files for library cells used for ATPG with TetraMAX.
## -----------------------------------------------------------------------------

set SVAR(lib,your_lib_2,vlog_tmax_filelist) [list \
]

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This variable defines the valid set of operating mode names.
## These names, which are arbitrary strings, provide
## convenient handles for specifying operating modes.
## These variables must use characters that are alpha/numeric/underscore only.
## Examples: normal, lowpower, standby, test, etc.
## -----------------------------------------------------------------------------

set SVAR(setup,mm_types_list) [list \
  "your_mode_1" \
  "your_mode_2" \
]

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_01) "TagValue01"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_02) "TagValue02"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_03) "TagValue03"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_04) "TagValue04"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_05) "TagValue05"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_06) "TagValue06"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_07) "TagValue07"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_08) "TagValue08"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_09) "TagValue09"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_10) "TagValue10"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_11) "TagValue11"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_12) "TagValue12"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_13) "TagValue13"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_14) "TagValue14"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_15) "TagValue15"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_16) "TagValue16"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_17) "TagValue17"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_18) "TagValue18"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_19) "TagValue19"

## -----------------------------------------------------------------------------
## This is one of the 20 tag metrics which are useful for grouping metrics across the
## flow. Add strings that can then be used when filtering in Management Cockpit.
## 
## LCRM users can use TAGs but they must be set in the block variables to be
## honored, not the common.
## -----------------------------------------------------------------------------

set SVAR(tag_20) "TagValue20"

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the NXTGRD file for your_rc_type_1 conditions
## with metal fill estimation. If you do not
## have an NXTGRD file with metal fill estimation capability,
## simply use an NXTGRD file without metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,nxtgrd_emf_file,your_rc_type_1) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the NXTGRD file for your_rc_type_2 conditions
## with metal fill estimation. If you do not
## have an NXTGRD file with metal fill estimation capability,
## simply use an NXTGRD file without metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,nxtgrd_emf_file,your_rc_type_2) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the NXTGRD file for your_rc_type_1 conditions
## without metal fill estimation.
## This file should NOT perform metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,nxtgrd_file,your_rc_type_1) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the NXTGRD file for your_rc_type_2 conditions
## without metal fill estimation.
## This file should NOT perform metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,nxtgrd_file,your_rc_type_2) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the TLU+ file for your_rc_type_1 conditions
## with metal fill estimation. If you do not have a
## TLU+ file with metal fill estimation capability,
## simply use an TLU+ file without metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,tlup_emf_file,your_rc_type_1) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the TLU+ file for your_rc_type_2 conditions
## with metal fill estimation. If you do not have a
## TLU+ file with metal fill estimation capability,
## simply use an TLU+ file without metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,tlup_emf_file,your_rc_type_2) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the TLU+ file for your_rc_type_1 conditions
## without metal fill estimation.
## This file should NOT perform metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,tlup_file,your_rc_type_1) ""

## -----------------------------------------------------------------------------
## NOTE: Not used in LCRM. Provided here to illustrate Lynx Design System capabilities.
## 
## This is the TLU+ file for your_rc_type_2 conditions
## without metal fill estimation.
## This file should NOT perform metal fill estimation.
## -----------------------------------------------------------------------------

set SVAR(tech,tlup_file,your_rc_type_2) ""

## -----------------------------------------------------------------------------
## End of File
## -----------------------------------------------------------------------------
