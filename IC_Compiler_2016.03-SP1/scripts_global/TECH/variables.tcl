## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/TSMC65LP.TSMC.A/variables.tcl#74 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * Procedures for variable support.
## -----------------------------------------------------------------------------

## -----------------------------------------------------------------------------
## This section is for procedures that provide variable values.
## -----------------------------------------------------------------------------

namespace eval Vars {

  proc var_post_update { self new_value old_value block } {

    if { $self == "SVAR(drc,ALL)" } {

      set new_enable [lindex $new_value 0]
      set old_enable [lindex $old_value 0]

      if { $new_enable != $old_enable } {

        set drc_list [var_get -name SVAR(setup,drc_list)]

        foreach drc $drc_list {

          if { $drc == "ALL" } { continue }

          if { $block == "@common" } {
            set tmp_val [var_get -name SVAR(drc,$drc)]
          } else {
            set tmp_val [var_get -name SVAR(drc,$drc) -block $block]
          }

          set tmp_val_0 [lindex $tmp_val 0]
          set tmp_val_1 [lindex $tmp_val 1]
          set tmp_val_2 [lindex $tmp_val 2]
          set tmp_val [list $new_enable $tmp_val_1 $tmp_val_2]

          if { $block == "@common" } {
            var_set -name SVAR(drc,$drc) -value $tmp_val -noundo
          } else {
            var_set -name SVAR(drc,$drc) -value $tmp_val -noundo -block $block
          }

        }

      }

    }

  }

  proc var_get_scenarios {} {
    global SEV
    source $SEV(tscript_dir)/common.tcl
    set scenario_list [list]
    foreach mm_type $SVAR(setup,mm_types_list) {
      foreach oc_type $SVAR(setup,oc_types_list) {
        foreach rc_type $SVAR(setup,rc_types_list) {
          set scenario $mm_type.$oc_type.$rc_type
          lappend scenario_list $scenario
        }
      }
    }
    return $scenario_list
  }

  proc var_get_rc_method {} {
    global SEV
    set files [glob $SEV(gscript_dir)/conf/rtm_init_rc_*.tcl]
    set rc_method_list [list]
    foreach file $files {
      regexp {rtm_init_rc_(\S+)\.tcl} $file match rc_method
      lappend rc_method_list $rc_method
    }
    return $rc_method_list
  }

  proc var_get_job_app {} {
    global SEV
    set files [glob $SEV(gscript_dir)/conf/rtm_init_js_*.tcl]
    set job_app_list [list]
    foreach file $files {
      regexp {rtm_init_js_(\S+)\.tcl} $file match job_app
      lappend job_app_list $job_app
    }
    return $job_app_list
  }

}

## -----------------------------------------------------------------------------
## This section is for procedures that implement the variable checking rules.
##
## Each procedure implementing a rule takes five parameters:
##   isList  - Specifies list vs scalar.
##   self    - The name of the SVAR variable.
##   value   - The value of the SVAR variable.
##   techlib - The name of the techlib associated with the SVAR.
##   block   - The name of the block associated with the SVAR.
##             If the block value is "@common", then the variable value comes from common.
##
## Each procedure implementing a rule must generate its own messages for display.
## All text output from a rule must be implemented via the rule_msg procedure.
## rule_msg [-warning|-error|-info|-debug] <message>
##   If the severity is not specified, -warning is the default.
##   All rule_msg calls are queued for display,
##   but will only be shown if the procedure's return value is 0. (see below)
##   The output of -debug is printed to the shell console.
##
## Each procedure implementing a rule must return either 0 or 1.
##   0 : Display the variable (and messages) in the report.
##       This is typically used for variables that are not OK.
##   1 : Don't display the variable (or messages) in the report.
##       Typically used for variables that are OK.
##
## -----------------------------------------------------------------------------

namespace eval Rules {

  ## -------------------------------------
  ## This procedure implements a rule that demonstrates
  ## the messaging options that are available.
  ## -------------------------------------

  proc isExample { isList self value techlib block } {
    set ok 0
    rule_msg -error   "This is error   #1 for the variable SVAR($self)"
    rule_msg -warning "This is warning #1 for the variable SVAR($self)"
    rule_msg -info    "This is info    #1 for the variable SVAR($self)"
    rule_msg -error   "This is error   #2 for the variable SVAR($self)"
    rule_msg -warning "This is warning #2 for the variable SVAR($self)"
    rule_msg -info    "This is info    #2 for the variable SVAR($self)"
    return $ok
  }

  ## -------------------------------------

  proc printValue { isList self value techlib block } {
    global SEV
    set ok 0
    rule_msg -info "The value of SEV($self) is $SEV($self)"
    return $ok
  }

  ## -------------------------------------

  proc isBoolean { isList self value techlib block } {
    return [_isBoolean 1 $isList $self $value $techlib $block]
  }

  proc _isBoolean { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      rule_msg -error "Variable is not set."
      return 0
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specified as a single boolean not a list - value is '$value'"
      set ok 0
    }
    foreach v $value {
      if { ![string is boolean -strict $v] } {
        rule_msg -error "Variable must be specified as a boolean - value is '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc isFloatRequired { isList self value techlib block } {
    return [_isFloat 1 $isList $self $value $techlib $block]
  }
  proc isFloatOptional { isList self value techlib block } {
    return [_isFloat 0 $isList $self $value $techlib $block]
  }

  proc _isFloat { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      if { $isRequired } {
        rule_msg -error "Variable is not set."
        return 0
      } else {
        rule_msg -warning "Variable is not set."
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specified as a single float not a list - value is '$value'"
      set ok 0
    }
    foreach v $value {
      if { ![string is double -strict $v] } {
        rule_msg -error "Variable must be specifed as a float - value is '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc isIntegerRequired { isList self value techlib block } {
    return [_isInteger 1 $isList $self $value $techlib $block]
  }
  proc isIntegerOptional { isList self value techlib block } {
    return [_isInteger 0 $isList $self $value $techlib $block]
  }

  proc _isInteger { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      if { $isRequired } {
        rule_msg -error "Variable is not set."
        return 0
      } else {
        rule_msg -warning "Variable is not set."
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specified as a single integer not a list."
      set ok 0
    }
    foreach v $value {
      if { ![string is integer -strict $v] } {
        rule_msg -error "Variable must be specified as an integer - value is '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc isSimpleStringRequired { isList self value techlib block } {
    return [_isSimpleString 1 $isList $self $value $techlib $block]
  }
  proc isSimpleStringOptional { isList self value techlib block } {
    return [_isSimpleString 0 $isList $self $value $techlib $block]
  }

  proc _isSimpleString { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      if { $isRequired } {
        rule_msg -error "Variable is not set."
        return 0
      } else {
        rule_msg -warning "Variable is not set."
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specfied as a single string not a list."
      set ok 0
    }
    foreach v $value {
      if { ![regexp {^[\w]+$} $v] } {
        rule_msg -error "Variable must be specified as a simpleString - value is '$v;"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc verifyTechlibName { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      rule_msg -error "Variable is not set."
      return 0
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specified as a string not a list - value is '$value'"
      set ok 0
    }
    foreach v $value {
      if { ![regexp {^[\w\.]+$} $v] } {
        rule_msg -error "Variable must be string of alphanumeric, underscore, and period characters - value is '$v'"
        set ok 0
      }
    }
    if { $ok } {
      rule_msg -info "The value for SEV($self) is $SEV($self)"
    }
    return $ok
  }

  ## -------------------------------------

  proc verifyDesignName { isList self value techlib block } {
    global SEV
    set value [subst $value]

    if { $block == "@common" } {
      set required 0
    } else {
      set required 1
    }

    set ok 1
    if { [llength $value] == 0 } {
      if { $required } {
        rule_msg -error "Variable is not set."
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must be specified as a single string - not a list."
      set ok 0
    }
    foreach v $value {
      if { ![regexp {^[\w]+$} $v] } {
        rule_msg -error "Variable must be a design name - value is '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc isFileRequired { isList self value techlib block } {
    return [_isFile 1 $isList $self $value $techlib $block]
  }
  proc isFileOptional { isList self value techlib block } {
    return [_isFile 0 $isList $self $value $techlib $block]
  }

  proc _isFile { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      if {$isList} {
        set msg "Variable is not set - it must be a list of files"
      } else {
        set msg "Variable is not set - it must be a single file"
      }
      if { $isRequired } {
        rule_msg -error $msg
        return 0
      } else {
        rule_msg -warning $msg
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must specify a single file, not a list - $value"
      set ok 0
    }
    foreach v $value {
      if { ($block == "@common") && [regexp $SEV(workarea_dir)/blocks/ $v] } {
        rule_msg -warning "This variable may reference the \$SEV(bscript_dir) variable,"
        rule_msg -warning "which is not defined when checking the common.tcl file."
        rule_msg -warning "The file existence check may not be valid."
        set ok 0
      }
      if { ![file exists $v] } {
        rule_msg -error "File does not exist: '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------
  proc verifyLibertyOptional { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    foreach v $value {
      if { ![file exists $v] } {
        rule_msg -error "A specified Liberty file does not exist: '$v'"
        set ok 0
      }
    }
  }

  proc verifyLiberty { isList self value techlib block } {
    global SEV
    set value [subst $value]

    ## -------------------------------------
    ## Determine if NLDM or CCS is selected.
    ## -------------------------------------

    set lib          [lindex [split $self ","] 1]
    set liberty_type [lindex [split $self ","] 2]
    if { $block == "@common" } {
      set use_ccs [var_get -name SVAR(lib,$lib,use_ccs)]
    } else {
      set use_ccs [var_get -name SVAR(lib,$lib,use_ccs) -block $block]
    }
    set required 0
    if { $use_ccs && ($liberty_type == "db_ccs_filelist") } {
      set required 1
    }
    if { !$use_ccs && ($liberty_type == "db_nldm_filelist") } {
      set required 1
    }

    ## -------------------------------------
    ## Check to make sure variable is defined.
    ## -------------------------------------

    set ok 1
    if { [llength $value] == 0 } {
      set ok 0
      if { $required } {
        rule_msg -error "Variable is not set."
        return 0
      } else {
        rule_msg -warning "Variable is not set."
        return 0
      }
    }

    ## -------------------------------------
    ## Check to make sure DB files exist.
    ## -------------------------------------

    foreach v $value {
      if { ![file exists $v] } {
        set ok 0
        if { $required } {
          rule_msg -error "File does not exist: '$v'"
        } else {
          rule_msg -warning "File does not exist: '$v'"
        }
      }
    }

    ## -------------------------------------
    ## Check to make sure that OC support is uniform.
    ## -------------------------------------

    set num_db_files_list [list]
    set oc_types_list [var_get -name SVAR(setup,oc_types_list)]
    foreach oc_type $oc_types_list {
      if { $block == "@common" } {
        set db_filelist [var_get -name SVAR(lib,$lib,$liberty_type,$oc_type)]
      } else {
        set db_filelist [var_get -name SVAR(lib,$lib,$liberty_type,$oc_type) -block $block]
      }
      lappend num_db_files_list [llength $db_filelist]
    }
    set num_db_files_list [lsort -unique $num_db_files_list]

    if { [llength $num_db_files_list] != 1 } {
      set ok 0
      rule_msg -error "The number of DB files is not consistent across all operating conditions. [llength $value] DB files specified"
    }

    return $ok
  }

  ## -------------------------------------

  proc verifyStarRC { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set rc_type [lindex [split $self ","] 2]
    if { $rc_type == "RC_VX" } {
      set required 0
    } else {
      set required 1
    }

    set ok 1
    if { [llength $value] == 0 } {
      set ok 0
      if { $required } {
        rule_msg -error "Variable is not set."
        return 0
      } else {
        rule_msg -warning "Variable is not set. Variation aware extraction not available."
        return 0
      }
    }

    foreach v $value {
      if { ![file exists $v] } {
        set ok 0
        if { $required } {
          rule_msg -error "File does not exist: '$v'"
        } else {
          rule_msg -warning "File does not exist: '$v'"
        }
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc isDirRequired { isList self value techlib block } {
    return [_isDir 1 $isList $self $value $techlib $block]
  }
  proc isDirOptional { isList self value techlib block } {
    return [_isDir 0 $isList $self $value $techlib $block]
  }

  proc _isDir { isRequired isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      if {$isList} {
        set msg "Variable is not set, it must be a list of directories"
      } else {
        set msg "Variable is not set, it must be a single directory"
      }
      if { $isRequired } {
        rule_msg -error $msg
        return 0
      } else {
        rule_msg -warning $msg
        return 0
      }
    }
    if { !$isList && ([llength $value] > 1) } {
      rule_msg -error "Variable must specify a single directory, not a list - value is '$value'"
      set ok 0
    }

    foreach v $value {
      if { ![file isdirectory $v] } {
        rule_msg -error "Directory does not exist: '$v'"
        set ok 0
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc stringIsLibCellPin { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { ![regexp {^[\w\.]+/[\w]+/[\w]+$} $value] } {
      rule_msg -error "Variable must be of format lib/cell/pin - value is '$value'"
      set ok 0
    }
    return $ok
  }

  ## -------------------------------------

  proc listIsDontUse { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    foreach v $value {
      if { ![regexp {^[\w\.\*]+/[\w\*]+$} $v] } {
        rule_msg -error "List entry must be of format lib/cell, with wildcards - value is '$v'"
        set ok 0
      }
    }
    return $ok
  }

  ## -------------------------------------

  proc listIsLibs { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set lib_list [subst [var_get -name SVAR(setup,lib_types_list) -block $block]]

    set ok 1
    if { [llength $value] == 0 } {
      rule_msg -error "Variable requires a list of one or more lib_types."
      set ok 0
    }
    foreach v $value {
      if { [lsearch $lib_list $v] == -1 } {
        rule_msg -error "Cannot find entry '$v' in SVAR(setup,lib_types_list)"
        set ok 0
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc verifyTieCell { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1

    set required [var_get -name SVAR(libsetup,tie_enable) -block $block]

    if { $required } {

      if { [llength $value] != 1 } {
        rule_msg -error "Variable requires a single value."
        set ok 0
      }
      if { ![regexp {^[\w]+/[\w]+/[\w]+$} $value] } {
        rule_msg -error "Variable must be of format lib/cell/pin - value is '$value'"
        set ok 0
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc verifyEndcapCellname { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1

    set required [var_get -name SVAR(libsetup,endcap_enable) -block $block]

    if { $required } {

      if { [llength $value] != 2 } {
        rule_msg -error "Variable requires a list of two values."
        set ok 0
      }
      foreach v $value {
        if { ![regexp {^\w+$} $v] } {
          rule_msg -error "List element must be a valid string - value is '$v'"
          set ok 0
        }
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc verifyContactOptList { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    foreach v $value {
      if { [llength $v] != 3 } {
        rule_msg -error "Each list must contain 3 elements - value is '$v'"
        set ok 0
      } else {
        set from_contact       [lindex $v 0]
        set to_contact         [lindex $v 1]
        set number_of_contacts [lindex $v 2]
        if { ![regexp {^[\w]+$} $from_contact] } {
          rule_msg -error "from_contact must be a valid string - value is $v"
          set ok 0
        }
        if { ![regexp {^[\w]+$} $to_contact] } {
          rule_msg -error "to_contact must be a valid string - value is $v"
          set ok 0
        }
        if { ![string is integer $number_of_contacts] } {
          rule_msg -error "number_of_contacts must be an integer - value is $v"
          set ok 0
        }
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc verifyMetalInfoList { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set ok 1
    if { [llength $value] == 0 } {
      rule_msg -error "Variable is not set."
      set ok 0
    }
    foreach v $value {
      if { [llength $v] != 2 } {
        rule_msg -error "All list elements must be a pair - value is '$v'"
        set ok 0
      } else {
        set layer_name [lindex $v 0]
        set layer_dir  [lindex $v 1]
        if { ![regexp {^[\w]+$} $layer_name] } {
          rule_msg -error "layer_name must be a simple string - value is '$layer_name'"
          set ok 0
        }
        if { ($layer_dir != "H") && ($layer_dir != "V") } {
          rule_msg -error "layer_dir must be 'H' or 'V' - value is '$layer_dir'"
          set ok 0
        }
      }
    }

    return $ok
  }

  ## -------------------------------------

  proc isScenario { isList self value techlib block } {
    global SEV
    set value [subst $value]

    set mm_types_list [subst [var_get -name SVAR(setup,mm_types_list) -block $block]]
    set oc_types_list [subst [var_get -name SVAR(setup,oc_types_list) -block $block]]
    set rc_types_list [subst [var_get -name SVAR(setup,rc_types_list) -block $block]]

    set ok 1
    foreach v $value {
      set parts [split $v .]
      set mm_type [lindex $parts 0]
      set oc_type [lindex $parts 1]
      set rc_type [lindex $parts 2]
      if { [lsearch $mm_types_list $mm_type] == -1 } {
        set ok 0
      }
      if { [lsearch $oc_types_list $oc_type] == -1 } {
        set ok 0
      }
      if { [lsearch $rc_types_list $rc_type] == -1 } {
        set ok 0
      }
    }
    if { !$ok } {
      rule_msg -error "Variable must contain valid scenarios - value is '$value'"
    }

    return $ok
  }

}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
