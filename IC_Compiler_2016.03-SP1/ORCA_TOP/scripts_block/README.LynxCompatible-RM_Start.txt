###################################################################################
# README for the Synopsys(R) Lynx-Compatible Reference Methodology 
# Version: J-2014.09-SP2 (January 12, 2015)
# Copyright (C) 2010-2015 Synopsys, Inc. All rights reserved.
###################################################################################

The Synopsys reference methodologies provide you with sets of product and release-
specific reference scripts that serve as a good starting point for running each 
tool. These scripts are not designed to run in their current form. You should use
them as a reference and adapt them for use in your design environment.

The Lynx-compatible reference methodology scripts are identical to the standard
reference methodology scripts except for changes in the structure and setup used 
for running the tools. The Lynx-compatible directory structure is more closely 
aligned with the directory structure used in the Lynx Design System, and the setup 
allows you to run the scripts with Lynx automation.

Throughout this document, the terms <PROD> and <prod> indicate the following 
uppercase and lowercase product identifiers:

*  The Synopsys Design Compiler(R) identifiers are DC and dc
*  The Synopsys IC Compiler(TM) identifiers are ICC and icc
*  The Synopsys PrimeTime(R) identifiers are PT and pt
*  The Synopsys StarRC(TM) identifiers are STARRC and starrc
*  The Synopsys TetraMAX(R) identifiers are TMAX and tmax

Before you begin using the Lynx-compatible reference methodology scripts, review 
the information in this README file to understand the scripts and the steps needed 
to get started.

Note: 
   This file explains how to set up and run the Lynx-compatible reference 
   methodology scripts. For instructions on how to set up and run the 
   standard reference methodology scripts, see the individual product README 
   files, README.<PROD>-RM.txt. 

For detailed information about the changes and enhancements made in each new 
release of the Lynx-compatible reference methodology scripts, see the file 
named Release_Notes.LynxCompatible-RM.txt.

For information about how to set up and run the Lynx-compatible reference
methodology scripts in the Lynx Design System, see Synopsys SolvNet(R) article
029774, "Using Lynx-Compatible Reference Methodology Scripts in Lynx."

Files Included for a Lynx-Compatible Reference Methodology Flow
===============================================================

------------------------------------------------------------------------------------
File                                Description
------------------------------------------------------------------------------------
./rm_setup/                         Directory containing the common and product-
                                    specific run scripts 

./rm_<prod>_scripts/                Directory containing the design and constraint 
                                    scripts used by the specified product 

./lcrm_setup/                       Directory containing the setup scripts used by
                                    the Lynx-compatible reference methodology flow 
                                    including procedure files and product-specific 
                                    XML files 
                              
./conf/                             Directory containing block-specific 
                                    configuration files used by the Lynx Design 
                                    System 

<prod>-RMsettings.txt               Reference methodology option settings that were 
                                    selected when the scripts were generated for 
                                    the specified product

README.<prod>-RM.txt                Information and instructions for setting up and 
                                    running the reference methodology scripts for 
                                    the specified product

Release_Notes.<prod>-RM.txt         Release notes listing the incremental changes 
                                    in each new version of the scripts for the  
                                    specified product

README.LynxCompatible-RM_Start.txt  Information for setting up and running the 
                                    reference methodology scripts within Lynx 
                                    
Release_Notes.LynxCompatible-RM.txt Release notes for all Lynx-compatible reference 
                                    methodology scripts listing the incremental 
                                    changes in each new version of the scripts 
------------------------------------------------------------------------------------


Example Script:
Using the Reference Methodology Scripts within Lynx 
===================================================

This section provides an example of a setup script for the Design Compiler 
Reference Methodology. You can edit the following lines and copy and paste
them into your shell to set up your Lynx-compatible reference methodology scripts. 
For more information about the setup steps, see the instructions in the next 
section.

---------------- EDIT ----- COPY ----- PASTE ----- from here ----------------------
# Specify the product and version variables:
# For PROD, use one of the following identifiers: 
# DC, ICC, PT, STARRC, or TMAX.
# For prod, use one of the following identifiers: 
# dc, icc, pt, starrc, or tmax.
set PROD=DC
set prod=dc
set RM_VERSION=G-2012.06-SP4
# Set the working directory:
# For example: /global/users/john/my_designs/blockA
set MY_BLOCK=/<path_to_working_dir>
# Extract the files from the archive:
# gunzip <PROD>-RM_<version>.tar.gz              # Use for packages in 
                                                   *.gz format 
tar -xvf ${PROD}-RM_${RM_VERSION}.tar
mkdir ${MY_BLOCK}/scripts_block
cp -r ./${PROD}-RM_${RM_VERSION}/* ${MY_BLOCK}/scripts_block
cd ${MY_BLOCK}
mkdir -p rm_${prod}/tmp               
mkdir -p rm_${prod}/logs/${prod}
cd rm_${prod}/tmp
---------------- EDIT ----- COPY ----- PASTE ------ to here -----------------------

 
Instructions:
Using the Reference Methodology Scripts Within Lynx 
===================================================

To set up your reference methodology scripts,

1. Copy the reference methodology tar file to a working directory. 

2. Extract the reference methodology files by using the gunzip command, 
   if necessary, and the tar command.

   % gunzip <PROD>-RM_<version>.tar.gz    ## <PROD> is DC, ICC, PT, STARRC, or TMAX 
   % tar -xvf <PROD>-RM_<version>.tar 

3. Create the ./scripts_block directory if it does not already exist.

   % mkdir ./scripts_block

4. Copy the contents of the tar file to the ./scripts_block directory. 

   % cp -r ./<prod>-RM_<version>/* ./scripts_block 

5. Create the runtime workspace and output directories at the same level as 
   the ./scripts_block directory, if they do not already exist. 
   
   % mkdir -p rm_<prod>/tmp               ## <prod> is dc, icc, pt, starrc, or tmax
   % mkdir -p rm_<prod>/logs/<prod>

6. Configure your reference methodology setup by editing the setup information in 
   the following files:
   
   o  ./scripts_block/rm_setup/common_setup.tcl   
   o  ./scripts_block/rm_setup/<prod>_setup.tcl  

   Note:
      This step does not apply to the StarRC Reference Methodology.

7. Customize the reference methodology flow by editing the script files in the
   ./scripts_block/rm_<prod>_scripts/ directory.

After you have set up the scripts, run the tool by entering the appropriate command 
for the tool and flow you are using. For the Lynx-compatible reference methodology 
flow, run the tool from the working directory ./rm_<prod>/tmp. Make sure that the 
working directory and the ./rm_dc/dc/logs directory exist before you run the tool.   
 
Before you run the reference methodology scripts, change into the working 
directory:

% cd rm_<prod>/tmp 

To run the Design Compiler Reference Methodology scripts, use one of the following 
commands:

*  To run the Design Compiler Reference Methodology in a top-down flow, enter

   % dc_shell -topo -f ../../scripts_block/rm_dc_scripts/dc.tcl \
        | tee ../logs/dc/dc.log

*  To run the Design Compiler Reference Methodology in a DC Explorer flow, enter

   % de_shell -f ../../scripts_block/rm_dc_scripts/dc.tcl \
        | tee ../logs/dc/de.log

   (Note that the LCRM changes the synopsys_program_name from de_shell to
    dc_shell using the de_rename_shell_name_to_dc_shell variable in
    lcrm_setup.tcl.)

*  To run Synopsys Formality(R) verification in the top-down flow, enter

   % fm_shell -f ../../scripts_block/rm_dc_scripts/fm.tcl | tee ../logs/dc/fm.log

*  To run the MVRC Static Verification Reference Methodology flow, enter

   % mvrc -f ../../scripts_block/rm_dc_scripts/mvrc.tcl | tee ../logs/dc/mvrc.log

*  To run the Synopsys Verification Compiler(TM) Low Power Static Signoff Reference 
   Methodology flow, enter

   % vc_static_shell -f ../../scripts_block/rm_dc_scripts/vc_lp.tcl \
        | tee ../logs/dc/vc_lp.log

To run the IC Compiler Reference Methodology scripts, use one of the following 
commands:

*  To run the IC Compiler Reference Methodology with Zroute, enter

   % make -f ../../scripts_block/rm_setup/Makefile_zrt ic

*  To run the IC Compiler Reference Methodology with the classic router, enter

   % make -f ../../scripts_block/rm_setup/Makefile ic

*  To run the engineering change order (ECO) flow with Zroute, enter

   % make -f ../../scripts_block/rm_setup/Makefile_zrt eco

*  To run the ECO flow with the classic router, enter

   % make -f ../../scripts_block/rm_setup/Makefile eco

*  To run the focal_opt flow with Zroute, enter

   % make -f ../../scripts_block/rm_setup/Makefile_zrt focal_opt

*  To run the focal_opt flow with the classic router, enter

   % make -f ../../scripts_block/rm_setup/Makefile focal_opt

*  To run the IC Compiler Design Planning Reference Methodology, enter

   % make -f ../../scripts_block/rm_setup/Makefile dp

*  To run the IC Compiler In-Design Rail Analysis Reference Methodology, enter

   % make -f ../../scripts_block/rm_setup/Makefile_ICC_rail in-design_rail_analysis

To run the PrimeTime Reference Methodology scripts, use one of the following 
commands:

*  To run the generic flow, enter

   % pt_shell -f ../../scripts_block/rm_pt_scripts/pt.tcl | tee ../logs/pt/pt.log

*  To run the distributed multi-scenario analysis (DMSA) flow, enter

   % pt_shell -multi \
        -f ../../scripts_block/rm_pt_scripts/dmsa.tcl | tee ../logs/pt/dmsa.log

To run the StarRC Reference Methodology script, enter the following command:
   
% ../../scripts_block/rm_setup/run_starrc.tcl 


To run the TetraMAX Reference Methodology script, enter the following command:
   
% tmax -shell ../../scripts_block/rm_tmax_scripts/tmax.tcl \
     | tee ../logs/tmax/tmax.log

For information about how to set up and run the Lynx-compatible reference 
methodology scripts in the Lynx Design System, see the instructions in the 
following documents:

*  SolvNet article 029774, "Using Lynx-Compatible Reference Methodology Scripts
   in Lynx"

   https://solvnet.synopsys.com/retrieve/029774.html

*  SolvNet article 033877, "Lynx-Compatible Reference Methodology Installation
   Utility"
 
   https://solvnet.synopsys.com/retrieve/033877.html




