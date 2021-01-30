##########################################################################################
# CES IC Compiler 1 Workshop
# Copyright (C) 2007-2012 Synopsys, Inc. All rights reserved.
##########################################################################################

set TEV(num_cores) 1
set SEV(script_file) [info script]
set SEV(src) route_opt_icc
set SEV(dst) dfm_icc

source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 

open_mw_lib $MW_DESIGN_LIBRARY
redirect /dev/null "remove_mw_cel -version_kept 0 $SEV(dst)"
copy_mw_cel -from $SEV(src) -to $SEV(dst)
open_mw_cel $SEV(dst)

link -f


## Optimization Common Session options - set in all sessions
source -echo common_optimization_settings_icc.tcl 
source -echo common_placement_settings_icc.tcl 
source -echo common_post_cts_timing_settings.tcl
source -echo common_route_si_settings_zrt_icc.tcl


