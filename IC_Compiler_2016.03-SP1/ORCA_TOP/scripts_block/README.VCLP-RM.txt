####################################################################################
# Synopsys(R) Verification Compiler(TM) Low Power Static Signoff Reference 
# Methodology 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2014-2015 Synopsys, Inc. All rights reserved.
####################################################################################

A reference methodology provides a set of reference scripts that serve as a good 
starting point for running a tool. These scripts are not designed to run in their 
current form. You should use them as a reference and adapt them for use in your 
design environment.

The Verification Compiler Low Power Static Signoff Reference Methodology includes 
options to run the multivoltage rule checker tool, Verification Compiler Low Power 
Static, in the netlist, RTL, and PG netlist design stages.

*  For the Synopsys Design Compiler(R) Reference Methodology, the Verification
   Compiler Low Power Static Signoff Reference Methodology scripts are configured 
   to run on the netlist output by default. You can configure the scripts to run on 
   the RTL by setting the VCLP_RUN variable to RTL.

*  For the Synopsys IC Compiler(TM) Reference Methodology, the Verification Compiler
   Low Power Static Signoff Reference Methodology scripts always run on the PG 
   netlist output.

The Verification Compiler Low Power Static Signoff Reference Methodology includes 
support for verification of output from the following flows:

*  The top-down synthesis flow, including multivoltage synthesis with 
   IEEE 1801, which is also known as Unified Power Format (UPF).

*  The hierarchical synthesis flow, including multivoltage synthesis with UPF.

*  The top-down place and route flow with UPF.


Files Included With the Verification Compiler
Low Power Static Signoff Reference Methodology  
==============================================

------------------------------------------------------------------------------------
File                        Description
------------------------------------------------------------------------------------
README.VCLP-RM.txt          Information and instructions for setting up and 
                            running the Verification Compiler Low Power Static 
                            Signoff Reference Methodology scripts. 

Release_Notes.VCLP-RM.txt   Release notes for the Verification Compiler Low Power 
                            Static Signoff Reference Methodology scripts listing 
                            the incremental changes in each new version of the 
                            scripts.

rm_dc_scripts/vc_lp.tcl     Verification Compiler Low Power Static Signoff Reference 
                            Methodology script used to perform static verification
                            of multivoltage designs for top-down synthesis or for 
                            block-level synthesis in a hierarchical flow.

rm_dc_scripts/vc_lp_top.tcl Verification Compiler Low Power Static Signoff Reference 
                            Methodology script used to perform static verification
                            of multivoltage designs at the full-chip level in a 
                            hierarchical flow.

rm_icc_scripts/vc_lp.tcl    Verification Compiler Low Power Static Signoff Reference 
                            Methodology script used to perform static verification 
                            of multivoltage designs for top-down place and route 
                            or for block-level place and route in a
                            hierarchical flow.
------------------------------------------------------------------------------------


Instructions:
Using the Verification Compiler Low Power Static Signoff
Reference Methodology for a Top-Down Synthesis Flow
===================================================

1. Copy the reference methodology files to a new location.

2. Customize the Verification Compiler Low Power Static run.

   The Verification Compiler Low Power Static tool runs on the netlist version of 
   the design by default. To run the tool on the RTL version of the design, change 
   the VCLP_RUN variable to RTL in rm_setup/dc_setup.tcl.

3. Run your static low power verification by using the vc_lp.tcl script.

   % vc_static_shell -f rm_dc_scripts/vc_lp.tcl | tee vc_lp.log

4. Verify the Verification Compiler Low Power Static results by looking at your log 
   file and studying the reports created in the ${REPORTS_DIR} directory.


Instructions:
Using the Verification Compiler Low Power Static Signoff Reference Methodology  
for a Full-Chip Design in a Bottom-Up Hierarchical Synthesis Flow
=================================================================

1. Copy the reference methodology files to a new location.

2. Customize the Verification Compiler Low Power Static run.

   The Verification Compiler Low Power Static tool runs on the netlist version of 
   the design by default. To run the tool on the RTL version of the design, change 
   the VCLP_RUN variable to RTL in rm_setup/dc_setup.tcl.

3. Run your static low power verification by using the vc_lp_top.tcl script.

   % vc_static_shell -f rm_dc_scripts/vc_lp_top.tcl | tee vc_lp_top.log

4. Verify the Verification Compiler Low Power Static results by looking at your log 
   file and studying the reports created in the ${REPORTS_DIR} directory.


Instructions:
Using the Verification Compiler Low Power Static Signoff Reference 
Methodology for a Top-Down or Block-Level Place and Route Flow
==============================================================

1. Copy the reference methodology files to a new location.

2. Customize the Verification Compiler Low Power Static run.

3. Run your static low power verification by using the vc_lp.tcl script.

   % vc_static_shell -f rm_icc_scripts/vc_lp.tcl | tee vc_lp.log

4. Verify the Verification Compiler Low Power Static results by looking at your log 
   file and studying the reports created in the ${REPORTS_DIR} directory.


Output Files from the Verification Compiler 
Low Power Static Signoff Reference Methodology
==============================================

------------------------------------------------------------------------------------
File                                                        Description
------------------------------------------------------------------------------------
{DESIGN_NAME}.vclp_report_violations.NETLIST.rpt            Reports for netlist 
                                                            verification runs

{DESIGN_NAME}.vclp_report_violations.NETLIST.verbose.rpt    Reports for netlist 
                                                            verification run details

{DESIGN_NAME}.vclp_report_violations.RTL.rpt                Reports for RTL 
                                                            verification runs

{DESIGN_NAME}.vclp_report_violations.RTL.verbose.rpt        Reports for RTL 
                                                            verification run details

{DESIGN_NAME}.vclp_report_violations.PGNETLIST.rpt          Reports for PG netlist 
                                                            verification runs

{DESIGN_NAME}.vclp_report_violations.PGNETLIST.verbose.rpt  Reports for PG netlist 
                                                            verification run details
------------------------------------------------------------------------------------


Using the Verification Compiler Low Power Static Signoff Reference 
Methodology in the Lynx-Compatible Reference Methodology Flow
=============================================================

For the Lynx-compatible reference methodology flow, run the tool from the
working directory (rm_dc/tmp or rm_icc/tmp). 

To run the Verification Compiler Low Power Static tool on the Design Compiler 
netlist or RTL, enter

   % cd rm_dc/tmp
   % vc_static_shell -f ../../scripts_block/rm_dc_scripts/vc_lp.tcl \
        | tee ../logs/dc/vc_lp.log

To run the Verification Compiler Low Power Static tool on the IC Compiler 
PG netlist, enter

   % cd rm_icc/tmp
   % vc_static_shell -f ../../scripts_block/rm_icc_scripts/vc_lp.tcl \
        | tee ../logs/outputs_icc/vc_lp.log
