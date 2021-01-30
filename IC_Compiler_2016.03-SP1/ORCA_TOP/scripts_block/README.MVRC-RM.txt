####################################################################################
# Synopsys(R) MVRC Static Verification Reference Methodology
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2011-2015 Synopsys, Inc. All rights reserved.
####################################################################################

A reference methodology provides a set of reference scripts that serve as a good 
starting point for running a tool. These scripts are not designed to run in their 
current form. You should use them as a reference and adapt them for use in your 
design environment.

The MVRC Static Verification Reference Methodology includes options to run the
multivoltage rule checker tool, MVRC, in the netlist, RTL, and PG netlist design 
stages.

*  For the Synopsys Design Compiler(R) Reference Methodology, the MVRC Reference 
   Methodology scripts are configured to run on the netlist output by default. You
   can configure the scripts to run on RTL by setting the MVRC_RUN variable to RTL.

*  For the Synopsys IC Compiler(TM) Reference Methodology, the MVRC Reference 
   Methodology scripts always run on the PG netlist output.

The MVRC Static Verification Reference Methodology includes support for verification 
of output from the following flows:

*  The top-down synthesis flow, including multivoltage synthesis with 
   IEEE 1801, which is also known as Unified Power Format (UPF).

*  The hierarchical synthesis flow, including multivoltage synthesis with UPF.

*  The top-down place and route flow with UPF.

Note:
   Use version E-2011.03 or later of the MVRC tool with version F-2011.09 or 
   later of the MVRC Static Verification Reference Methodology scripts.


Files Included With the MVRC Static Verification Reference Methodology  
======================================================================

------------------------------------------------------------------------------------
File                            Description
------------------------------------------------------------------------------------
README.MVRC-RM.txt              Information and instructions for setting up and 
                                running the MVRC Static Verification Reference 
                                Methodology scripts. 

Release_Notes.MVRC-RM.txt       Release notes for the MVRC Static Verification 
                                Reference Methodology scripts listing the incremental 
                                changes in each new version of the scripts.

rm_dc_scripts/mvrc.tcl          MVRC Static Verification Reference Methodology 
                                script used to perform static verification of 
                                multivoltage designs for top-down synthesis or 
                                for block-level synthesis in a hierarchical flow.

rm_dc_scripts/mvrc_top.tcl      MVRC Static Verification Reference Methodology 
                                script used to perform static verification of
                                multivoltage designs at the full-chip level
                                in a hierarchical flow.

rm_icc_scripts/mvrc.tcl         MVRC Static Verification Reference Methodology 
                                script used to perform static verification of 
                                multivoltage designs for top-down place and route 
                                or for block-level place and route in a
                                hierarchical flow.
------------------------------------------------------------------------------------


Instructions:
Using the MVRC Static Verification Reference Methodology 
for a Top-Down Synthesis Flow
=============================

1.  Copy the reference methodology files to a new location.

2.  Customize the MVRC run.

    MVRC runs on the netlist version of the design by default. To run MVRC on the 
    RTL version of the design, change the MVRC_RUN variable to RTL in 
    rm_setup/dc_setup.tcl.

3.  Run your static low power verification by using the mvrc.tcl script.

    % mvrc -f rm_dc_scripts/mvrc.tcl | tee mvrc.log

4.  Verify the MVRC results by looking at your log file and studying the reports
    created in the ${REPORTS_DIR} directory.


Instructions:
Using the MVRC Static Verification Reference Methodology  
for a Full-Chip Design in a Bottom-Up Hierarchical Synthesis Flow
=================================================================

1.  Copy the reference methodology files to a new location.

2.  Customize the MVRC run.

    MVRC runs on the netlist version of the design by default. To run MVRC on the 
    RTL version of the design, change the MVRC_RUN variable to RTL in 
    rm_setup/dc_setup.tcl.

3.  Run your static low power verification by using the mvrc.tcl scripts.

    % mvrc -f rm_dc_scripts/mvrc_top.tcl | tee mvrc.log

4.  Verify the MVRC results by looking at your log file and studying the reports
    created in the ${REPORTS_DIR} directory.


Instructions:
Using the MVRC Static Verification Reference Methodology 
for a Top-Down or Block-Level Place and Route Flow
========================================================

1.  Copy the reference methodology files to a new location.

2.  Customize the MVRC run.

3.  Run your static low power verification by using the mvrc.tcl script.

    % mvrc -f rm_icc_scripts/mvrc.tcl | tee mvrc.log

4.  Verify the MVRC results by looking at your log file and studying the reports
    created in the ${REPORTS_DIR} directory.


Output Files from the MVRC Static Verification Reference Methodology
====================================================================

------------------------------------------------------------------------------------
File                                            Description
------------------------------------------------------------------------------------
{DESIGN_NAME}.mvrc_check_design.NETLIST.rpt     Reports for netlist verification runs

{DESIGN_NAME}.mvrc_check_design.RTL.rpt         Reports for RTL verification runs

{DESIGN_NAME}.mvrc_check_design.PGNETLIST.rpt   Reports for PG netlist verification 
                                                runs
------------------------------------------------------------------------------------


Using the MVRC Static Verification Reference Methodology 
in the Lynx-Compatible Reference Methodology Flow
========================================================

For the Lynx-compatible reference methodology flow, run the tool from the
working directory, rm_dc/tmp OR rm_icc/tmp. 

To run MVRC on the Design Compiler netlist or RTL, enter

   % cd rm_dc/tmp
   % mvrc -f ../../scripts_block/rm_dc_scripts/mvrc.tcl | tee ../logs/dc/mvrc.log

To run MVRC on the IC Compiler PG netlist, enter

   % cd rm_icc/tmp
   % mvrc -f ../../scripts_block/rm_icc_scripts/mvrc.tcl \
        | tee ../logs/outputs_icc/mvrc.log
