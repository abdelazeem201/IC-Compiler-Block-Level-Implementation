##########################################################################################
# CES IC Compiler 1 Workshop
# Copyright (C) 2007-2012 Synopsys, Inc. All rights reserved.
##########################################################################################

set TEV(num_cores) 1

set SEV(src) route_opt_icc
set SEV(dst) post_route_opt_icc

set SEV(script_file) [info script]
source ../../scripts_block/lcrm_setup/lcrm_setup.tcl

sproc_script_start
source -echo ../../scripts_block/rm_setup/icc_setup.tcl 

set ICC_LOAD_CEL $SEV(src)


open_mw_lib $MW_DESIGN_LIBRARY
open_mw_cel $ICC_LOAD_CEL

