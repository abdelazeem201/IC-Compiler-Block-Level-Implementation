## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_init_tools.tcl#122 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * This file is sourced by the RTM on startup and contains the following:
## * - Procedures used by the RTM.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## rtm_tool_query:
## -----------------------------------------------------------------------------

proc rtm_tool_query { args } {

  global env SEV SVAR TEV

  set options(-cmd) ""
  set options(-tool) ""

  parse_proc_arguments -args $args options

  ## This list of items is used to store information for use by this procedure.
  ## Each item is composed of these fields:
  ##   "tool ver_var xml_support view_support"
  ## The meanings of the fields are as follows:
  ##   tool:           The name of the tool.
  ##   ver_var:        The SEV variable used for the tool's version.
  ##   xml_support:    If tool is allowed in XML specification, set to 1.
  ##   view_support:   If tool allowed for view operations, set to 1.
  ##                   If view_support is turned on make sure a matching
  ##                   <view_task> also exist in the view.xml file.

  if { [info exists env(LYNX_LCRM_MODE)] } {

    set item_list [list \
      { tcl            ver_tcl        1 1 } \
      { tcl_job        ver_tcl        1 1 } \
      { icc            ver_icc        1 1 } \
      { dc             ver_dc         1 1 } \
      { dct            ver_dc         1 1 } \
      { de             ver_dc         1 1 } \
      { lc             ver_dc         1 0 } \
      { pt             ver_pt         1 1 } \
      { pt_dmsa        ver_pt         1 1 } \
      { gca            ver_pt         1 1 } \
      { nanotime       ver_nanotime   1 0 } \
      { tx             ver_tx         1 1 } \
      { fm             ver_fm         1 1 } \
      { mw             ver_mw         1 0 } \
      { pr             ver_pr         1 0 } \
      { vcs            ver_vcs        0 0 } \
      { builder        ver_integrator 1 0 } \
      { integrator     ver_integrator 1 0 } \
      { leda           ver_leda       1 0 } \
      { mvrc           ver_mvtools    0 0 } \
      { mvrc_shell     ver_mvtools    1 0 } \
      { mvgui          ver_mvtools    0 0 } \
      { mvcmp          ver_mvtools    0 0 } \
      { mvcmp_vhdlan   ver_mvtools    0 0 } \
      { mvdbgen        ver_mvtools    0 0 } \
      { mvphydbgen     ver_mvtools    0 0 } \
      { mvtools        ver_mvtools    0 0 } \
      { vc_static      ver_vcst       1 1 } \
      { verdi          ver_verdi      0 0 } \
      { hercules       ver_hercules   0 0 } \
      { nettran_h      ver_hercules   0 0 } \
      { icv            ver_icv        0 0 } \
      { nettran_i      ver_icv        0 0 } \
      { star           ver_star       0 0 } \
      { hspice         ver_hspice     0 0 } \
      { icwb           ver_icwb       0 0 } \
      { cdesigner      ver_cdesigner  1 0 } \
      { nanosim        ver_nanosim    0 0 } \
      { pylcc          ver_pylcc      0 0 } \
      { icc2lm         ver_icc2       1 1 } \
      { icc2           ver_icc2       1 1 } \
      ]

  } else {

    set item_list [list \
      { tcl            ver_tcl        1 1 } \
      { tcl_job        ver_tcl        1 1 } \
      { icc            ver_icc        1 1 } \
      { dc             ver_dc         1 1 } \
      { dct            ver_dc         1 1 } \
      { de             ver_dc         1 1 } \
      { lc             ver_dc         1 0 } \
      { pt             ver_pt         1 1 } \
      { pt_dmsa        ver_pt         1 1 } \
      { gca            ver_pt         1 1 } \
      { nanotime       ver_nanotime   1 0 } \
      { tx             ver_tx         1 1 } \
      { fm             ver_fm         1 1 } \
      { mw             ver_mw         1 1 } \
      { pr             ver_pr         1 1 } \
      { vcs            ver_vcs        0 0 } \
      { builder        ver_integrator 1 0 } \
      { integrator     ver_integrator 1 0 } \
      { leda           ver_leda       1 1 } \
      { mvrc           ver_mvtools    0 0 } \
      { mvrc_shell     ver_mvtools    1 0 } \
      { mvgui          ver_mvtools    0 0 } \
      { mvcmp          ver_mvtools    0 0 } \
      { mvcmp_vhdlan   ver_mvtools    0 0 } \
      { mvdbgen        ver_mvtools    0 0 } \
      { mvphydbgen     ver_mvtools    0 0 } \
      { mvtools        ver_mvtools    0 0 } \
      { vc_static      ver_vcst       1 1 } \
      { verdi          ver_verdi      0 1 } \
      { hercules       ver_hercules   0 0 } \
      { nettran_h      ver_hercules   0 0 } \
      { icv            ver_icv        0 0 } \
      { nettran_i      ver_icv        0 0 } \
      { star           ver_star       0 0 } \
      { hspice         ver_hspice     0 0 } \
      { icwb           ver_icwb       0 1 } \
      { cdesigner      ver_cdesigner  1 1 } \
      { nanosim        ver_nanosim    0 0 } \
      { pylcc          ver_pylcc      0 0 } \
      { icc2lm         ver_icc2       1 1 } \
      { icc2           ver_icc2       1 1 } \
      ]

  }

  set valid_tool 0
  set list_all_tools    [list]
  set list_xml_tools    [list]
  set list_view_tools   [list]
  set list_version_vars       [list]
  foreach item $item_list {
    set tool           [lindex $item 0]
    set ver_var        [lindex $item 1]
    set xml_support    [lindex $item 2]
    set view_support   [lindex $item 3]
    if { $tool == $options(-tool) } {
      set valid_tool 1
    }
    if { [lsearch $list_all_tools $tool] == -1 } { lappend list_all_tools $tool }
    if { $xml_support }    { lappend list_xml_tools $tool }
    if { $view_support }   { lappend list_view_tools $tool }
    if { [lsearch $list_version_vars $ver_var] == -1 } { lappend list_version_vars $ver_var }
  }

  switch $options(-cmd) {
    is_all_tool -
    is_xml_tool -
    is_view_tool {
      if { $valid_tool } {
        return 1
      } else {
        return 0
      }
    }
    get_version_var -
    get_version_val {
      if { !$valid_tool } {
        return -code error "rtm_tool_query: The option '$options(-tool)' for -tool is not valid."
      }
    }
  }

  switch $options(-cmd) {
    get_version_var {
      set tmp_ver_var ""
      foreach item $item_list {
        set tool    [lindex $item 0]
        set ver_var [lindex $item 1]
        if { $tool == $options(-tool) } {
          set tmp_ver_var $ver_var
        }
      }
      if { [info exists SEV($tmp_ver_var)] } {
        return $tmp_ver_var
      } else {
        return -code error "rtm_tool_query: The variable 'SEV($tmp_ver_var)' is not defined."
      }
    }
    get_version_val {
      set tmp_ver_var ""
      foreach item $item_list {
        set tool    [lindex $item 0]
        set ver_var [lindex $item 1]
        if { $tool == $options(-tool) } {
          set tmp_ver_var $ver_var
        }
      }
      if { [info exists SEV($tmp_ver_var)] } {
        return $SEV($tmp_ver_var)
      } else {
        return -code error "rtm_tool_query: The variable 'SEV($tmp_ver_var)' is not defined."
      }
    }
    get_list_version_vars {
      return [lsort $list_version_vars]
    }
    get_list_all_tools {
      return [lsort $list_all_tools]
    }
    get_list_xml_tools {
      return [lsort $list_xml_tools]
    }
    get_list_view_tools {
      return [lsort $list_view_tools]
    }
    is_all_tool {
      if { [lsearch $list_all_tools $options(-tool)] != -1 } {
        return 1
      } else {
        return 0
      }
    }
    is_xml_tool {
      if { [lsearch $list_xml_tools $options(-tool)] != -1 } {
        return 1
      } else {
        return 0
      }
    }
    is_view_tool {
      if { [lsearch $list_view_tools $options(-tool)] != -1 } {
        return 1
      } else {
        return 0
      }
    }
  }

}

define_proc_attributes rtm_tool_query \
  -info "Customizable procedure for defining how the RTM runs tools." \
  -hidden \
  -define_args {
  {-cmd  "Allow options for this procedure"  AnOos one_of_string
  {required value_help {values { get_version_var get_version_val get_list_version_vars get_list_all_tools get_list_xml_tools get_list_view_tools is_all_tool is_xml_tool is_view_tool }}}}
  {-tool "Tool name"                         AString string optional}
}

## -----------------------------------------------------------------------------
## rtm_shell_cmd:
## -----------------------------------------------------------------------------

proc rtm_shell_cmd { args } {

  global env SEV SVAR TEV

  set options(-tool)           ""
  set options(-aux_tools)      ""
  set options(-bit)            64
  set options(-gui)            0
  set options(-interactive)    0
  set options(-rtm_check_only) 0
  set options(-export_script)  ""
  set options(-export_logfile) ""
  set options(-log_file)       ""
  set options(-disable_check)  0

  parse_proc_arguments -args $args options

  if { $options(-tool) == "" } {
    return -code error "rtm_shell_cmd: Argument for -tool not specified."
  }

  if { $options(-export_script) != "" } {
    set export_mode 1
  } else {
    set export_mode 0
  }

  if { $export_mode } {
    ## Build a command that runs the -export_script file.
    set wrapper $options(-export_script)
  } else {
    ## Build a command that runs the tool_wrapper.tcl file.
    set wrapper ../../scripts_global/conf/tool_wrapper.tcl
  }

  if { $options(-rtm_check_only) } {
    set options(-tool) tcl
  }

  ## -------------------------------------
  ## Call rtm_tool_cmd in order to resolve
  ## the correct values for SEV(cmd_*).
  ## -------------------------------------

  rtm_tool_cmd

  ## -------------------------------------
  ## Develop tool portion of command line
  ## -------------------------------------

  if { $export_mode } {
    set redirect_stdin "| tee $options(-export_logfile)"
  } else {
    if { $options(-interactive) } {
      set redirect_stdin ""
    } else {
      set redirect_stdin "< /dev/null"
    }
  }

  set primary_module ""
  set associated_modules "$SEV(ver_tcl)"

  switch $options(-tool) {

    tcl -
    tcl_job {
      if { $options(-interactive) } {
        set cmd "tcl_shell $wrapper $redirect_stdin"
      } else {
        set cmd "tclsh $wrapper $redirect_stdin"
      }
      set primary_module $SEV(ver_tcl)
    }

    icc {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }
      set cmd "icc_shell $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_icc)

      set associated_modules "$associated_modules $SEV(ver_pt)"
      set associated_modules "$associated_modules $SEV(ver_star)"
      set associated_modules "$associated_modules $SEV(ver_hercules)"
      set associated_modules "$associated_modules $SEV(ver_icv)"
      set associated_modules "$associated_modules $SEV(ver_hspice)"
      set associated_modules "$associated_modules $SEV(ver_nanosim)"
      set associated_modules "$associated_modules $SEV(ver_pr)"
      set associated_modules "$associated_modules $SEV(ver_pylcc)"
    }

    dc -
    dct {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }
      if { $options(-tool) == "dct" } {
        set extra "-topo"
      } else {
        set extra ""
      }

      set cmd "dc_shell $extra $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_dc)

      set associated_modules "$associated_modules $SEV(ver_icc)"
    }

    de {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }

      set extra ""

      set cmd "de_shell $extra $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_dc)

      set associated_modules "$associated_modules $SEV(ver_icc)"
    }

    lc {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }

      set cmd "lc_shell $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_dc)
    }

    pt -
    pt_dmsa {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-tool) == "pt_dmsa" } {
        set extra "-multi_scenario"
      } else {
        set extra ""
      }
      set cmd "pt_shell $extra $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_pt)
    }

    nanotime {
      set cmd "nt_shell -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_nanotime)
    }

    gca {
      if { $options(-gui) } {
        set gui ""
      } else {
        set gui "-no_gui"
      }
      set cmd "gca_shell $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_pt)
    }

    tx {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui "-shell"
      }
      if { $options(-bit) == "64" } {
        set bit "-64"
      } else {
        set bit ""
      }
      set cmd "tmax $bit $gui -nostartup -tcl $wrapper $redirect_stdin"

      set primary_module $SEV(ver_tx)
    }

    fm {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }
      set cmd "fm_shell $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_fm)

      set associated_modules "$associated_modules $SEV(ver_dc)"
    }

    mw {
      if { $options(-gui) } {
        set gui ""
      } else {
        set gui "-nullDisplay -nogui"
      }
      if { $options(-bit) == "64" } {
        set bit ""
      } else {
        set bit ""
      }
      set cmd "Milkyway -tcl $bit $gui -file $wrapper $redirect_stdin"

      set primary_module $SEV(ver_mw)
    }

    pr {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit "-32bit"
      }
      set cmd "pr_shell $bit $gui -file $wrapper $redirect_stdin"

      set primary_module $SEV(ver_pr)
    }

    integrator {
      set cmd "ish $wrapper $redirect_stdin"

      set primary_module $SEV(ver_integrator)
    }

    builder {
      set cmd "buildersh $wrapper $redirect_stdin"

      set primary_module $SEV(ver_integrator)
    }

    leda {
      if { $options(-gui) } {
        set cmd "leda -sverilog +gui +tcl_file $wrapper $redirect_stdin"
      } else {
        set cmd "leda -sverilog +tcl_shell +tcl_file $wrapper $redirect_stdin"
      }

      set primary_module $SEV(ver_leda)
    }

    mvrc_shell {
      if { $options(-bit) == "64" } {
        set bit "-full64"
      } else {
        set bit ""
      }
      ## File location varies between Lynx and LCRM scripts.
      if { [info exists env(LYNX_LCRM_MODE)] } {
        set archpro_ini ../../scripts_block/rm_setup/archpro.ini
      } else {
        set archpro_ini ../../scripts_block/formal/archpro.ini
      }
      if { $options(-gui) } {
        set cmd "ln -fs $archpro_ini . ; mvgui -mvrc $bit -f $wrapper $redirect_stdin"
      } else {
        set cmd "ln -fs $archpro_ini . ; mvrc $bit -f $wrapper $redirect_stdin"
      }

      set primary_module $SEV(ver_mvtools)
    }

    vc_static {
      if { $options(-bit) == "64" } {
        set bit "-mode64"
      } else {
        set bit ""
      }
      if { $options(-gui) } {
        set cmd "vc_static_shell -gui $bit -f $wrapper -session ../work/$SEV(dst)/vc_static_work $redirect_stdin"
      } else {
        set cmd "vc_static_shell -ui $bit -f $wrapper -session ../work/$SEV(dst)/vc_static_work $redirect_stdin"
      }

      set primary_module $SEV(ver_vcst)
    }

    cdesigner {
      set cmd "cdesigner -command \"source $wrapper\""
      set primary_module $SEV(ver_cdesigner)

      set associated_modules "$associated_modules $SEV(ver_icc)"
    }

    icc2lm  {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }
      set cmd "icc2_lm_shell $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_icc2)
    }

    icc2 {
      if { $options(-gui) } {
        set gui "-gui"
      } else {
        set gui ""
      }
      if { $options(-bit) == "64" } {
        set bit "-64bit"
      } else {
        set bit ""
      }
      set cmd "icc2_shell $bit $gui -f $wrapper $redirect_stdin"

      set primary_module $SEV(ver_icc2)
      set associated_modules $SEV(ver_icv)
    }

    hercules {
      set cmd "$SEV(cmd_hercules) ARGS"
      set primary_module $SEV(ver_hercules)
    }

    icv {
      set cmd "$SEV(cmd_icv) ARGS"
      set primary_module $SEV(ver_icv)
    }

    pylcc {
      set cmd "$SEV(cmd_pylcc) ARGS"
      set primary_module $SEV(ver_pylcc)
    }

    default {
      return -code error "rtm_shell_cmd: Argument for -tool not recognized: $options(-tool)"
    }

  }

  ## -------------------------------------
  ## Optional version control support
  ## -------------------------------------

  if { $SEV(ver_enable) } {

    ## -------------------------------------
    ## Set the module_init string
    ## -------------------------------------

    if { $options(-bit) == "64" } {
      set module_init "SNPS_BITMODE=64 && . $env(MODULESHOME)/init/sh"
    } else {
      set module_init "SNPS_BITMODE=32 && . $env(MODULESHOME)/init/sh"
    }

    ## -------------------------------------
    ## Develop "module load" string
    ## -------------------------------------

    set modules_prelim ""

    if { $primary_module == "" } {
      return -code error "rtm_shell_cmd: Tool version was not defined for tool: $options(-tool)"
    } else {
      set modules_prelim "$modules_prelim $primary_module"
    }
    set modules_prelim "$modules_prelim $associated_modules"

    set modules_aux ""
    foreach tool $options(-aux_tools) {
      set valid_tool [rtm_tool_query -cmd is_all_tool -tool $tool]
      if { $valid_tool } {
        set version_var [rtm_tool_query -cmd get_version_var -tool $tool]
        if { [info exists SEV($version_var)] } {
          set modules_aux "$modules_aux $SEV($version_var)"
        } else {
          return -code error "rtm_shell_cmd: Tool version was not defined for aux_tool: $tool"
        }
      } else {
        return -code error "rtm_shell_cmd: Invalid tool specification for aux_tool: $tool"
      }
    }
    set modules_prelim "$modules_prelim $modules_aux"

    set modules_final ""
    unset -nocomplain module_seen
    foreach module $modules_prelim {
      if { ![info exists module_seen($module)] } {
        set module_seen($module) 1
        set modules_final "$modules_final $module"
      }
    }

    set module_load "module load $modules_final"

    ## -------------------------------------
    ## Develop "module unload" string
    ## -------------------------------------

    set modules_unload_list ""

    foreach module $modules_final {
      set base ""
      set version ""
      if { [regexp {^([\w\.\-\/]+)/([\w\.\-]+)$} $module match base version] } {
        set modules_unload_list "$modules_unload_list $base"
      } else {
        return -code error "rtm_shell_cmd: Invalid module name format. Expected: 'name/version'. Received: '$module'"
      }
    }

    set module_unload "module unload $modules_unload_list"

    ## -------------------------------------
    ## Add module content to the command line
    ## -------------------------------------

    set cmd "$module_init && $module_unload && $module_load && $cmd"

  }

  ## -------------------------------------
  ## Add log file creation
  ## -------------------------------------

  if { $export_mode } {
    set cmd "$cmd"
  } else {
    if { $options(-interactive) || $options(-gui) } {
      set cmd "$cmd 2>&1 | tee $options(-log_file)"
    } else {
      set cmd "$cmd > $options(-log_file) 2>&1"
    }
  }

  ## -------------------------------------
  ## Add command to run the rtm_check application.
  ## -------------------------------------

  set file_part_org [file tail $options(-log_file)]
  set dir_part_org  [file dirname $options(-log_file)]

  set file_part_new .[file rootname $file_part_org].rtm_check.log
  set rtm_check_log $dir_part_org/$file_part_new

  set file_part_new .[file rootname $file_part_org].rtm_check.xml
  set rtm_check_xml $dir_part_org/$file_part_new

  if { [info exists env(LYNX_DEBUG_RTM_CHECKER_FAIL)] && ($env(LYNX_DEBUG_RTM_CHECKER_FAIL) == "1") } {
    set rtm_check_xml $rtm_check_xml.LYNX_DEBUG_RTM_CHECKER_FAIL
  }

  if { !$options(-disable_check) } {
    set cmd "$cmd\n\n$env(SYNOPSYS_RTM)/bin/rtm_check $rtm_check_xml > $rtm_check_log 2>&1"
  }

  ## -------------------------------------
  ## Return the final command
  ## -------------------------------------

  return "$cmd"

}

define_proc_attributes rtm_shell_cmd \
  -info "Customizable procedure for defining how the RTM runs tools." \
  -define_args {
  {-tool             "Tool name"                  AString string required}
  {-aux_tools        "Aux Tool names"             AString string optional}
  {-bit              "Selects BIT mode"           AnOos one_of_string
  {optional value_help {values { 32 64 }}}}
  {-gui              "Selects GUI mode"           AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
  {-interactive      "Selects interactive mode"   "" boolean optional}
  {-rtm_check_only   "Only run rtm_check."        "" boolean optional}
  {-export_script    "Exported script"            AString string optional}
  {-export_logfile   "Exported logfile"           AString string optional}
  {-log_file         "Absolute path to Log file"  AString string required}
  {-disable_check    "Disables call to rtm_check" AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
}

## -----------------------------------------------------------------------------
## rtm_tool_cmd:
## -----------------------------------------------------------------------------

proc rtm_tool_cmd { args } {

  global env SEV SVAR TEV

  set options(-show) 0

  parse_proc_arguments -args $args options

  set ::gRtmShell_AllowSevModify 1

  ## -------------------------------------
  ## Tools that have Tcl interfaces are invoked from the RTM, and
  ## the specifics of those invocations are defined via the rtm_shell_cmd procedure.
  ##
  ## Tools that don't have Tcl interfaces are invoked from Tcl scripts, and
  ## the specifics of those invocations are defined in those scripts.
  ##
  ## Some customers use wrappers to invoke tools.
  ## The SEV(cmd_*) variables are provided as a means to define the wrapper
  ## command in a single place, and avoid the need to update multiple scripts.
  ## -------------------------------------

  set SEV(cmd_vcs)            vcs

  set SEV(cmd_icwb)           icwbev
  set SEV(cmd_icv)            icv
  set SEV(cmd_nettran_i)      icv_nettran
  set SEV(cmd_hercules)       hercules
  set SEV(cmd_nettran_h)      nettran
  set SEV(cmd_pylcc)          runlcc

  set SEV(cmd_hspice)         hspice
  set SEV(cmd_nanosim)        nanosim

  set SEV(cmd_integrator)     integrator
  set SEV(cmd_integrator2ish) integrator2ish
  set SEV(cmd_builder)        builder
  set SEV(cmd_buildersh)      buildersh

  set SEV(cmd_mvrc)           mvrc
  set SEV(cmd_mvrc_shell)     mvrc
  set SEV(cmd_mvgui)          mvgui
  set SEV(cmd_mvcmp)          mvcmp
  set SEV(cmd_mvcmp_vhdlan)   mvcmp-vhdlan
  set SEV(cmd_mvdbgen)        mvdbgen
  set SEV(cmd_mvphydbgen)     mvphydbgen
  set SEV(cmd_vcst)           vc_static_shell

  set ::gRtmShell_AllowSevModify 0

  if { $options(-show) } {
    set max_length 0
    foreach name [lsort [array names SEV]] {
      if { [regexp {^cmd_} $name] } {
        set length [string length $name]
        if { $length > $max_length } {
          set max_length $length
        }
      }
    }
    foreach name [lsort [array names SEV]] {
      if { [regexp {^cmd_} $name] } {
        set length [string length $name]
        set count [expr $max_length - $length]
        puts stderr "Information: SEV($name)[string repeat { } $count] : $SEV($name)"
      }
    }
  }

}

define_proc_attributes rtm_tool_cmd \
  -info "Procedure for defining SEV(cmd_*) values." \
  -hidden \
  -define_args {
  {-show "Show the values assigned to all SEV(cmd_*) variables." "" boolean optional}
}

## -----------------------------------------------------------------------------
## rtm_host_query:
## -----------------------------------------------------------------------------

proc rtm_host_query { args } {

  global env SEV SVAR TEV

  set options(-cpu_cores) ""
  set options(-max_cpu_limit) ""
  set options(-min_mem_free) ""
  set options(-min_swap_free) ""
  set options(-pid_file) ""
  set options(-verbose) 0

  parse_proc_arguments -args $args options

  set options(-verbose) 1

  if { $options(-verbose) } {
    puts stderr "Info: rtm_host_query: Start of procedure"
  }

  ## -------------------------------------
  ## Definitions
  ## -------------------------------------

  set proc_stat    /proc/stat
  set proc_meminfo /proc/meminfo

  ## -------------------------------------
  ## Process history information
  ## -------------------------------------

  set lynx_pid [pid]

  set cmd "ps -p $lynx_pid -o ppid= -o cmd="
  if { [catch { exec $SEV(exec_cmd) -c "$cmd" } results] } {
    puts stderr "Error: rtm_host_query: ps command fail: $results"
    return HOST_BUSY
  }

  while { ![string match *rtmShell.exe* $results] } {
    set new_pid [lindex $results 0]
    set cmd "ps -p $new_pid -o ppid= -o cmd="
    if { [catch { exec $SEV(exec_cmd) -c "$cmd" } results] } {
      puts stderr "Error: rtm_host_query: ps command fail: $results"
      return HOST_BUSY
    }
  }
  set lynx_pid $new_pid

  set history_file "/tmp/lynx_local.$lynx_pid"

  set previously_requested(cpu_cores)     0
  set previously_requested(min_mem_free)  0
  set previously_requested(min_swap_free) 0
  set good_lines [list]

  if { [file exists $history_file] } {

    set fid [open $history_file r]
    set string_file [read $fid]
    close $fid
    set lines [split $string_file \n]

    foreach line $lines {

      ## Skip blank lines
      if { [regexp {^\s*$} $line] } {
        continue
      }

      ## Check to ensure line is in expected format
      if { [scan $line "%s %s %s %s" pid_file cpu_cores min_mem_free min_swap_free] != 4 } {
        puts stderr "Error: rtm_host_query: Invalid line in history file: $line"
        return HOST_BUSY
      }

      ## Make sure the process is still running
      if { ![file readable $pid_file] } {
        continue
      }

      set fid [open $pid_file r]
      set pid_line [gets $fid]
      close $fid
      if { [scan $pid_line "PID %s %s EOL" host pid] != 2 } {
        puts stderr "Error: rtm_host_query: Could not find PID in $pid_file"
        return HOST_BUSY
      }

      ## Make sure the pid is a child of lynx_pid
      set cmd "pstree -p $lynx_pid"
      catch { exec $SEV(exec_cmd) -c "$cmd" } results
      set pid_list [regexp -all -inline {\(\d+\)} $results]
      set pid_list [regexp -all -inline {\d+} $pid_list]
      set pid_list [lsort -unique -integer -decreasing $pid_list]

      if { [lsearch $pid_list $pid] >= 0 } {
        set previously_requested(cpu_cores)     [expr $previously_requested(cpu_cores)     + $cpu_cores]
        set previously_requested(min_mem_free)  [expr $previously_requested(min_mem_free)  + $min_mem_free]
        set previously_requested(min_swap_free) [expr $previously_requested(min_swap_free) + $min_swap_free]
        lappend good_lines $line
      }

    }

    if { $options(-verbose) } {
      puts "Info: rtm_host_query: Previously requested totals: $previously_requested(cpu_cores) $previously_requested(min_mem_free) $previously_requested(min_swap_free)"
    }

    ## Rewrite the history file with only the good lines
    set fid [open $history_file w]
    foreach line $good_lines {
      puts $fid $line
    }
    close $fid

  }

  ## -------------------------------------
  ## Get first CPU sample
  ## -------------------------------------

  set flag_ok 0

  set fid [open $proc_stat r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  set cpu_list [list]

  foreach line $lines {
    if { [regexp {(cpu\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)} $line match cpu user nice system idle] } {
      lappend cpu_list $cpu
      set cpu_one($cpu,user)   $user
      set cpu_one($cpu,nice)   $nice
      set cpu_one($cpu,system) $system
      set cpu_one($cpu,idle)   $idle
      set flag_ok 1
    }
  }

  if { !$flag_ok } {
    puts stderr "Error: rtm_host_query: Unable to parse /proc/stat"
    return ERROR_PROC_STAT
  }

  ## -------------------------------------
  ## Get second CPU sample
  ## -------------------------------------

  after 2000

  set flag_ok 0

  set fid [open $proc_stat r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  foreach line $lines {
    if { [regexp {(cpu\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)} $line match cpu user nice system idle] } {
      set cpu_two($cpu,user)   $user
      set cpu_two($cpu,nice)   $nice
      set cpu_two($cpu,system) $system
      set cpu_two($cpu,idle)   $idle
      set flag_ok 1
    }
  }

  if { !$flag_ok } {
    puts stderr "Error: rtm_host_query: Unable to parse /proc/stat"
    return ERROR_PROC_STAT
  }

  foreach cpu $cpu_list {

    set cpu_util($cpu) -1

    ## -------------------------------------
    ## Calculate the difference
    ## -------------------------------------

    set cpu_diff($cpu,user)   [expr $cpu_two($cpu,user)   - $cpu_one($cpu,user)]
    set cpu_diff($cpu,nice)   [expr $cpu_two($cpu,nice)   - $cpu_one($cpu,nice)]
    set cpu_diff($cpu,system) [expr $cpu_two($cpu,system) - $cpu_one($cpu,system)]
    set cpu_diff($cpu,idle)   [expr $cpu_two($cpu,idle)   - $cpu_one($cpu,idle)]

    ## -------------------------------------
    ## Calculate the load
    ## -------------------------------------

    set total_busy [expr 1.0 * ($cpu_diff($cpu,user) + $cpu_diff($cpu,nice) + $cpu_diff($cpu,system))]
    set total_all  [expr 1.0 * ($total_busy + $cpu_diff($cpu,idle))]
    set cpu_util($cpu) [format "%.2f" [expr 100.0 * $total_busy / $total_all]]

    if { $options(-verbose) } {
      puts stderr "Info: rtm_host_query: CPU load is [format "%6.2f" $cpu_util($cpu)]% ($cpu)"
    }

  }

  ## -------------------------------------
  ## Determine MEM usage
  ## -------------------------------------

  set flag_ok 0

  set mem_free_mb -1
  set swap_free_mb -1

  set fid [open $proc_meminfo r]
  set string_file [read $fid]
  close $fid
  set lines [split $string_file \n]

  foreach line $lines {
    if { [regexp {^MemFree:\s+(\d+)} $line match value] } {
      set value1 $value
      incr flag_ok
    }
    if { [regexp {^Buffers:\s+(\d+)} $line match value] } {
      set value2 $value
      incr flag_ok
    }
    if { [regexp {^Cached:\s+(\d+)} $line match value] } {
      set value3 $value
      incr flag_ok
    }
    if { [regexp {^SwapFree:\s+(\d+)} $line match value] } {
      set swap_free_mb [expr $value / pow(2,10)]
      incr flag_ok
    }
  }

  if { $flag_ok == 4 } {
    set mem_free_mb [expr ($value1 + $value2 + $value3) / pow(2,10)]
  } else {
    puts stderr "Error: rtm_host_query: Unable to parse /proc/meminfo"
    return ERROR_PROC_MEMINFO
  }

  ## -------------------------------------
  ## Apply metrics
  ## -------------------------------------

  set cpu_ok 0
  set mem_free_ok 0
  set swap_free_ok 0

  set idle_cpu_count 0
  foreach cpu $cpu_list {
    if { [regexp {cpu\d+} $cpu] } {
      if { ($cpu_util($cpu) != -1) && ($cpu_util($cpu) < $options(-max_cpu_limit)) } {
        set idle_cpu_count [expr $idle_cpu_count + 1]
      }
    }
  }
  set idle_cpu_count [expr $idle_cpu_count - $previously_requested(cpu_cores)]
  if { $idle_cpu_count >= $options(-cpu_cores) } {
    set cpu_ok 1
  }

  if { ($mem_free_mb != -1) && ($mem_free_mb > $options(-min_mem_free)) && ($mem_free_mb > $previously_requested(min_mem_free))} {
    set mem_free_ok 1
  }
  if { ($swap_free_mb != -1) && ($swap_free_mb > $options(-min_swap_free)) && ($swap_free_mb > $previously_requested(min_swap_free)) } {
    set swap_free_ok 1
  }

  if { $options(-verbose) } {
    puts "Info: rtm_host_query: Max Utilization per CPU  : $options(-max_cpu_limit)%"
    puts "Info: rtm_host_query: CPUs (Requested)         : $options(-cpu_cores)"
    puts "Info: rtm_host_query: CPUs (Allocated)         : $previously_requested(cpu_cores)"
    puts "Info: rtm_host_query: CPUs (Available)         : $idle_cpu_count"
    puts "Info: rtm_host_query: Free MEM MB (Requested)  : [format "%.2f" $options(-min_mem_free)]"
    puts "Info: rtm_host_query: Free MEM MB (Allocated)  : [format "%.2f" $previously_requested(min_mem_free)]"
    puts "Info: rtm_host_query: Free MEM MB (Current)    : [format "%.2f" $mem_free_mb]"
    puts "Info: rtm_host_query: Free SWAP MB (Requested) : [format "%.2f" $options(-min_swap_free)]"
    puts "Info: rtm_host_query: Free SWAP MB (Allocated) : [format "%.2f" $previously_requested(min_swap_free)]"
    puts "Info: rtm_host_query: Free SWAP MB (Current)   : [format "%.2f" $swap_free_mb]"
  }

  if { $cpu_ok && $mem_free_ok && $swap_free_ok } {
    if { $options(-verbose) } {
      puts stderr "Info: rtm_host_query: Local host usage IS allowed"
    }

    ## Write job information to history file
    set fid [open $history_file a]
    puts $fid "$options(-pid_file) $options(-cpu_cores) $options(-min_mem_free) $options(-min_swap_free)"
    close $fid

    return HOST_IDLE
  } else {
    if { $options(-verbose) } {
      puts stderr "Info: rtm_host_query: Local host usage IS NOT allowed"
    }
    return HOST_BUSY
  }

}

define_proc_attributes rtm_host_query \
  -info "Customizable procedure for determining host usage level." \
  -hidden \
  -define_args {
  {-cpu_cores      "Required number of CPUs"        AnInt int required}
  {-max_cpu_limit  "Max allowed CPU usage (%)"      AnInt int required}
  {-min_mem_free   "Min required free memory (MB)"  AnInt int required}
  {-min_swap_free  "Min required free swap (MB)"    AnInt int required}
  {-pid_file       "PID file"                       AString string required}
  {-verbose        "Enable verbose messages" "" boolean optional}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
