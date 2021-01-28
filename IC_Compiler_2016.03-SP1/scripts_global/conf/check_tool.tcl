## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/check_tool.tcl#77 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This script used to verify presence of tool versions for flow.
## -----------------------------------------------------------------------------

source ../../scripts_global/conf/procs.tcl
sproc_source -file ../../scripts_global/conf/system.tcl
sproc_source -file $env(LYNX_VARFILE_SEV)
sproc_source -file ../../scripts_global/conf/system_setup.tcl
sproc_source -file $SEV(tscript_dir)/common.tcl
sproc_source -file $SEV(bscript_dir)/conf/block.tcl

## NAME: TEV(tool)
## TYPE: string
## INFO:
## * Used to specify the tool being checked.
set TEV(tool) NULL

sproc_source -file $env(LYNX_VARFILE_TEV)
sproc_source -file $SEV(bscript_dir)/conf/block_setup.tcl
sproc_script_start

## -----------------------------------------------------------------------------
## End of script header
## -----------------------------------------------------------------------------

## SECTION_START: initial

## SECTION_STOP: initial

## SECTION_START: body

## -----------------------------------------------------------------------------
## Run code that attempts to verify that the specified tool is being run.
## -----------------------------------------------------------------------------

switch $TEV(tool) {

  tcl {
    set version_ok 0

    if { [info tclversion] >= 8.4  } {
      set version_ok 1
    } else {
      sproc_msg -error "patchlevel is $patchlevel; expected 8.4.13 or higher"
    }

    if { $version_ok } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  leda {
    if { $synopsys_program_name != "leda" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  dc {
    if { $synopsys_program_name != "dc_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  icc {
    if { $synopsys_program_name != "icc_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  pt {
    if { $synopsys_program_name != "pt_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  gca {
    if { $synopsys_program_name != "gca_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  tx {
    if { $synopsys_program_name != "tmax_tcl" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  fm {
    if { $synopsys_program_name != "fm_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  mw {
    if { $synopsys_program_name != "milkyway" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  pr {
    if { $synopsys_program_name != "pr_shell" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  vcs {
    set cmd "$SEV(cmd_vcs) -help"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {vcs script version} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  mvcmp {
    set cmd "$SEV(cmd_mvcmp) -version"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {ArchPro MVCMP} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  hercules {
    set cmd "$SEV(cmd_hercules) -V"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {Printing individual version numbers} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  nettran_h {
    set cmd "$SEV(cmd_nettran_h) -V"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {\s+nettran:} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  icv {
    set cmd "$SEV(cmd_icv) -Version"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {Printing individual version numbers} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  nettran_i {
    set cmd "$SEV(cmd_nettran_i) -V"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {\s+icv_nettran:} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  star {
    set cmd "StarXtract -v"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {ExecName.*Version:} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  hspice {
    set cmd "$SEV(cmd_hspice) -v"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {HSPICE Version} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  icwb {
    set cmd "$SEV(cmd_icwb) -version"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {PROD} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  nanosim {
    set cmd "$SEV(cmd_nanosim) --version"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {Version} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  pylcc {
    set cmd "$SEV(cmd_pylcc) -V"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    sproc_msg -info "CMD: $cmd"
    sproc_msg -info "RESULT: $results"
    if { [regexp {Proteus} $results] } {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  vc_static {
    if { $synopsys_program_name != "vcst" } {
      sproc_msg -error "synopsys_program_name is $synopsys_program_name"
    } else {
      sproc_msg -info "OKOK: $TEV(tool)"
    }
  }

  default {
    sproc_msg -error "The tool $TEV(tool) is not recognized."
  }

}

## SECTION_STOP: body

## SECTION_START: final

## SECTION_STOP: final

sproc_script_stop

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
