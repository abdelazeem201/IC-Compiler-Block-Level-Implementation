## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/tracelog.tcl#40 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG 
## -----------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
# Package: tracelog
#
# Description:
#   This package provides a prototype implementation of an application command
#   trace log.  The goal of this project is to allow us to capure a log that
#   is equivalent to the application functions invoked, but doesn't contain any
#   customer-supplied script dependencies.  This can make it easier to debug
#   problems.
#
#   The package also provides options to echo the traced application commands
#   along with memory/cpu deltas to the output stream of the tool to help you
#   to associate the output with the commands that generate it, as well as to
#   help find inefficiencies in how the tool executes your scripts.
#
#  Disclaimer:
#   This script is not a Synopsys product, and is provided "as-is".  
#
#   The trace captured is not guaranteed to replay exactly the same as the
#   original sourced scripts.  The accuracy of the replay can be impacted by
#   applications that do not meet the assumptions for the operation of this 
#   script.  In many cases it has proven useful for such replay, but there
#   is no guarantee of suitability for any version of the tool or given set 
#   of scripts.
#
# Public Interface:
#   tracelog::start       -- start a tracelog to the specified file.
#   tracelog::stop        -- stop tracing and close the log file.
#   tracelog::set_options -- control options for tracing
#
#   Advanced Functions
#   tracelog::suspend  -- suspend tracing but keep the log active.
#   tracelog::resume   -- resume tracing after a suspend.
#   tracelog::print_trace str  -- print a specified string to the trace log file
#
# Usage:
#   Start the synopsys tool, load the tracelog.tcl package and set any options.
#   Often the application startup file is a good place to do this.
#
#   Then start the logging logging before loading any of the customer scripts.  
#   To start the trace log call tracelog::start and pass it the name of the 
#   file the trace log should be written to.
#
#   After the trace log is initialized, simply run the tool scripts as you 
#   would normally and exit the tool. You will not have a raw tracelog.  To be 
#   valid for replaying this log in the tool you need to post-process it with 
#   the tracelog-postprocess.pl tool.
#
#   There are a few options to control the behavior of the tracing and these 
#   can be set via tracelog::set_options.
#
# Configuration:
#   The tracelog::set_options command can be used to configure the behavior of
#   the tracing.  In addition to the facility to generate a trace log, the
#   facility can also annotate the output log for the tool with the commands as
#   well as performance/memory information to help in the debug-ability in the
#   tool log output.  These is controled via the -echo_cmds and
#   -echo_cmds_with_performance options.
#
# Determining what gets Traced:
#   The set of commands that is traced by default depends on the UI conventions for
#   Synopsys being followed by the application.  If the app follows those
#   conventions then the script will correctly and automatically trace those
#   commands.  There is no requirement that commands be manually registered for tracing, 
#   as long as the conventions are followed.  If the app has bugs and does not follow
#   the conventions then the script allows a work around via explicit configuration
#   using the tracelog::set_options command.
#
#   The expected UI conventions are:
#   For commands:
#   + All application commands that should be traced show up in the help for the
#     application.
#   + Tcl/CCI Builtins are in the Builtins command group and the application has not
#     modified this group.
#   + No application command should appear only in the in the Procedures command
#     group in the help.
#   + Application commands take their arguments by value and not by reference.
#   + Application commands don't provide control constructs that should be
#     omitted from the tracing.
#   + All application commands to be traced exist when this package is loaded.
#   + Application usage of enter/leave Tcl traces (e.g. trace add execution enter ...)
#     should not call any commands that are traced by tracelog.
#   For Variables
#   + All public variables for the application should be returned by 
#     printvar -application when this package is loaded.
#
#   Note that only 1-level of commands is traced, so if you add your own
#   procs to the list of commands to be traced, none of the application commands
#   called from within those procs will be traced.  Note that the procs must
#   exist when the tracing is started to have them be traced.
#
#   If there are commands or variables that are traced by default that you want
#   to omit from the tracing you can do that with the -dont_trace_commands and
#   the -dont_trace_variables options to the tracelog::set_options command.
#
# Example 1: A simple trace log
#   icc_sh> source tracelog.tcl
#   icc_sh> tracelog::start  -file ./trace_log_file_name.tcl
#   icc_sh> source complex_flow_scripts.tcl
#   icc_sh> exit
#
#   bash> tracelog-postprocess.pl -input  ./trace_log_file_name.tcl \
#                                 -output ./trace_replay_file.tcl
#
# Example 2: A trace log with no annotation of commands to the tool log
#   icc_sh> source tracelog.tcl
#   icc_sh> tracelog::set_options -echo_cmds off
#   icc_sh> tracelog::start  -file ./trace_log_file_name.tcl
#   icc_sh> source complex_flow_scripts.tcl
#   icc_sh> exit
#
#   bash> tracelog-postprocess.pl -input  ./trace_log_file_name.tcl \
#                                 -output ./trace_replay_file.tcl
#
# Example 3: A trace log on a batch script and then gui debugging after that
#   icc_sh> source tracelog.tcl
#   icc_sh> tracelog::start  -file ./trace_log_file_name.tcl
#   icc_sh> source complex_flow_scripts.tcl
#   icc_sh> tracelog::suspend
#      <gui interaction done here>
#   icc_sh> tracelog::resume
#   icc_sh> source next_complex_flow_script.tcl
#   icc_sh> exit
#
#   bash> tracelog-postprocess.pl -input  ./trace_log_file_name.tcl \
#                                 -output ./trace_replay_file.tcl
#
# Example 4: Advanced scenario with control over tracelog contents
#   icc_sh> source tracelog.tcl
#   icc_sh> tracelog::start  -file ./trace_log_file_name.tcl
#   icc_sh> source complex_flow_scripts.tcl
#   icc_sh> tracelog::suspend ;# no tracelog logging done -- instead user prints log content
#   icc_sh> tracelog::print_trace " custom app section"
#   icc_sh> tracelog::print_trace " instead of normal tracing print this to the log"
#   icc_sh> tracelog::resume ;# resume normal trace logging 
#   icc_sh> exit
#
#   bash> tracelog-postprocess.pl -input  ./trace_log_file_name.tcl \
#                                 -output ./trace_replay_file.tcl
#
# Example 5: adding tracing set up to my .synopsys_dc.setup file
#    In ~/.synopsys_dc.setup
#          source tracelog.tcl
#          # setup options for ignoring some of the gui commands
#          ::tracelog::set_options -dont_trace_commands "[info commands gui_*]"
#          ::tracelog::set_options -dont_trace_commands "[info commands get_object_snap_type]"
#          ::tracelog::set_options -dont_trace_commands "[info commands get_selection]"
#          # actually start the tracing
#          ::tracelog::start -file my.tcl
#
# Caveats:
#   + Collection garbage collection is bypassed in the replay log since we have
#     variables for the collections. Need to post-process the log and unset the
#     collection variable at the last time it is referenced in the log as a 
#     work-around for now. Use script tracelog-postprocess.pl for that task.
#   + You will get quite a lot of traced commands if you turn on the logging
#     while interacting with the gui.  This is because the gui executes those
#     commands on the fly to do updates on the screen. If you want to interactively
#     work with the tool after tracing a long script I suggest using the 
#     tracelog::suspend function to suspend the tracing, and then resume tracing
#     before you start a new script.
#   + When using tracelAllGlobals new global variable creation isn't logged
#     so this assumes that the  new variables don't have an impact.
#   + The wrappers have an impact on help.  cmd -help shows name of renamed actual 
#     command, while "help <cmd>" shows the help for the the proc and not the command
#     itself.
#
# ICC Specific Issues:
#   + ICC has a couple problems with its UI that break the assumptions of this
#     package and must be worked around.
#     + Not all variables that impact the application code are reported by 
#       printvar -application.  The work around would be to use the _moreVars
#       variable to add a list of additional variables to be traced by tracelog.
#       At this point I don't know which variables these are so they are not
#       listed. The work around is to enable _traceAllGlobalsVars which may pick
#       up any global vars defined when this package is defined and trace them.
#     + There are several application commands that are listed by the help in the
#       procedures group instead of one of the application built-in groups. The
#       work around is to use the _moreCmds variable to enable traceing of these
#       commands by tracelog.  I have hand-generated this list based on the current
#       2006.06 ICC code for now.
#     + read_sdc fatals if you run it when it is renamed and the read_sdc command is
#       a proc wrapper.  I worked around this with a custom wrapper for read_sdc for
#       now.
#     + run_signoff is removing commands and then using the unknown command handling
#       to forward them to the signoff tools.  This mechanism isn't supported by
#       tracelog so that type of command invocation will not be traced.
#     + cts_batch_mode registers enter/leave command traces that call public commands
#       but their behavior depends on hidden tcl variables.  Since enter/leave are outside
#       of the command invocation these are not nested commands and therefore are showing
#       up in the trace.  The creates an invalid trace, and today the only work around is
#       to not use cts_batch_mode with tracelog if you want to replay the log.
#
# Todo:
#   + Add a check for cmd -help and replace the __real stuff with the command name
#     so that the help doesn't have the wrapped command name shown.
#
#-------------------------------------------------------------------------------

package provide tracelog 1.0

#-------------------------------------------------------------------------------
# 
# namespace and variable definitions
#
namespace eval tracelog {

  # version number for this package
  set _version 1.0.46
  #   1.0.46 01/08/2015
  #       + Update tracelog-postprocess-beautify.pl to handle commands that take a collection as 
  #         an argument and return that same collection as their result, which can happen with 
  #         set_attribute in ICCII. Issue reported by Srinivas Tejomurtula 
  #   1.0.45 05/22/2014
  #      + fix script for cci change in QSC-J to the help command by setting the variable to use the
  #        old form of help for this script
  #   1.0.44 01/21/2013
  #      + fix proc ordering for check_app_commands when cmds are missing from Scott Tyson
  #   1.0.43 02/01/2011
  #      + Update variables for ICC from Bill
  #   1.0.42 09/22/2011
  #      + add support for -unique for append_to_collection wrapper
  #   1.0.41 09/15/2011
  #      + Minor update to is_collection test to minimize clct overhead when tracing is on
  #      + Add wrapper for append_to_collection to translate it into add_to_collection for 
  #        tracing.
  #   1.0.40 12/04/2011
  #      + Fix issue with quoting of lists of collections
  #   1.0.39 11/01/2010
  #      + Update cmds+vars for 2010.12 from Bill S.
  #   1.0.38 08/26/2010
  #      + Formality returns cputime in hundredths of a second and this caused a problem
  #        in the time formatting. Just round the formatted time to seconds to avoid the 
  #        error.
  #   1.0.37 04/16/2010
  #      + Added disclaimer on replayability to header comment in the generated trace 
  #      + Added disclaimer comment at the head of this script
  #   1.0.36 01/25/2010
  #      + option for -suppress_unknown_clct option to hide errors for collections used by
  #        gui internals
  #      + Additional ICC variables and commands from Bill
  #   1.0.35 07/02/2009
  #      + Bill's latest updates of ICC variables for 2009.06
  #   1.0.34 02/04/2009
  #      + Handle load_upf like we do read_sdc - fixes issue when logging is on with load_upf
  #   1.0.33 02/04/2009
  #      + Change expression for inserting $_sel references to only match in whole words
  #      + Fix for change from 1.0.30 that was clobbering the collection references in the
  #        original command string for cases of a collection args specified as [list [get_cells foo]] 
  #   1.0.32 01/30/2009
  #      + Fix typo in initialization of _preLogPosition which caused defined variable errors
  #   1.0.31 12/01/2008
  #      + Use sh_enable_stdout_redirect to force trace output to stdout and not allow it to redirect via the redirect command
  #   1.0.30 11/19/2008
  #      + Make sure that literals are quoted to guarantee the same execution in the trace to address a bug reported by Chris Smith.
  #   1.0.29 11/07/2008
  #      + Add Bill's 2008.09 command/variables update
  #      + Tweak to cpu reporting to make it easier to compare real time delta vs cputime delta
  #   1.0.28 05/23/2008
  #      + Reduce amount of performance trace output. Eliminate start line and Add option 
  #        -performance_echo_cpu_threshold to allow only printing end lines with cpu > the threshold
  #   1.0.27 04/21/2008 
  #      + remove experimental run_signoff wrapper and just use the normal tracing. Tracing of external commands invoked
  #        during signoff mode will not be in the trace log.
  #   1.0.26 04/04/2008 
  #      + don't log redirect used underneath another logged command - fixes Internal error messages for logged commands
  #        that use redirect
  #   1.0.25 03/31/2008 
  #      + Fix for redirect log - missing args
  #   1.0.24 03/25/2008 
  #      + Support putting the redirect command into the trace file along with the flattened commands
  #        that it invokes
  #   1.0.23 03/25/2008 
  #      + Add run_signoff custom wrapper that removes and reapplies the command wrappers so the 
  #        wrapping done by run_signoff is wrapped for tracing properly.
  #      + Ensure variable traces are setup before commands so that they don't end up triggering
  #        logging of their commands under the hood.
  #   1.0.22 03/19/2008 
  #      + Bugfix in command existance test for foreach_in_collection and read_sdc wrappers 
  #        which was preventing those commands from being properly handled.
  #   1.0.21 03/13/2008 
  #      + Add checks to fix tracelog with formality - (no read_sdc command). 
  #        Fix for reported elapsed time when a command runs longer than 24 hours.
  #   1.0.20 02/28/2008 
  #      + provide fallback for the cputime command to use the basic cputime command if -child -self are 
  #        not supported. Devin reported this as an issue with Primetime.
  #   1.0.19 02/25/2008 
  #      + add ICC variables from List list in ICC 2007.12 and 2007.12-SP1
  #   1.0.18 10/19/2007 
  #      + add ICC variables from Bill's List in ICC 2007.03-SP4, and 2007.12-Beta
  #      + automatically add tracing for variables in sh_allow_tcl_with_set_app_var_no_message_list
  #        as the variable is modified
  #   1.0.17 10/16/2007 
  #      + automatically add variables defined in sh_allow_tcl_with_set_app_var_no_message_list to be 
  #        traced so if set is used instead of set_app_var these will be traced too.
  #   1.0.16 10/15/2007 
  #      + trace set_app_var and get_app_var (new Synopsys Tcl commands for global variable interaction)
  #   1.0.15 10/08/2007 
  #      + include child process times in the cputime reported 
  #   1.0.14 09/06/2007 
  #      + add more cmds/variables for ICC from Bill
  #   1.0.13 08/20/2007 
  #      + bug fix ICC - procs cmd list was accidentally in the variables list
  #   1.0.12 08/08/2007 
  #      + Add icc specific proc exceptions for 2007.03-SP3 from Bill
  #   1.0.11 08/03/2007 
  #      + Fix problem where variables accessed via upvar with a different name
  #        would be traced with the alias instead of the actual global variable
  #        being updated
  #      + Added more ICC commands in procs group get_clocks.
  #   1.0.10 06/04/2007 
  #      + A number of ICC commands are now showing up as procs in 2007.03-SP2,
  #        add a work around for the tracing of them.
  #   1.0.9 05/23/2007 
  #      + Update list of ICC traced vars from Bill for 2007.03-SP1
  #   1.0.8 04/03/2007 
  #      + Update list of ICC traced vars from Bill.
  #   1.0.7 03/09/2007 
  #      + Don't force :: on moreVars for icc so that they will match with
  #        those from printvar.
  #   1.0.6 01/08/2007 
  #      + Add latest set of ICC-specific vars from Bill for SP4 and SP5.
  #   1.0.5 01/05/2007 
  #      + don't trace global vars that are arrays. Tcl traces are being invoked
  #        for the env array, when namespace eval :: is being invoked
  #        (incorrectly as far as I can tell).  Work around this by ensuring we
  #        do not trace any Tcl array variables for now.
  #      + add auto_restore_mw_cel_lib_setup as an ICC more variable
  #   1.0.4 12/20/2006 
  #      + ensure unset of variables is traced
  #   1.0.3 12/19/2006 
  #      + Add variables not registered for printvar into special section
  #        based on feedback on the set of variables needed from Bill S.
  #   1.0.2 12/06/2006 
  #      + Add tracing hidden commands if specified explicitly in
  #        more commands to work around problem where some cts commands were
  #        incorrectly hidden in ICC.
  #   1.0.1 11/07/2006 
  #      + Added version number tracking
  #      + Added catch for wrapper setting to fix issue with dc_shell-xg-t -top
  #        having errors during rename of some commands.
  #      + Added echoing of the tracelog version to the header in the trace file.

  #----------------------------------------------------------
  # configuation options
  #----------------------------------------------------------

  # list builtin commands that should be logged because they impact
  # the context in which the app commands run.
  # don't put control constructs in this list because it will cause double 
  # logging. 
  set _moreCmds {cd set_message_info suppress_message exec sh setenv
                 set_unix_variable exit quit}

  #
  # Tcl builtin vars that get manipulated under the hood for many commands
  # skip tracing of these when _traceAllGlobalVars is set to cut down on
  # noise
  set _skipVars(auto_noexec) 1
  set _skipVars(errorCode) 1
  set _skipVars(auto_oldpath) 1
  set _skipVars(errorInfo) 1
  set _skipVars(auto_path) 1

  # list of variables that don't show up in printvar -application but do have an impact
  # on the result of the executed script
  set _moreVars {}

  # app commands that shouldn't be logged
  # there are a few Tcl builtins that show up in the procedures that we 
  # should make sure don't gets traced.
  set _skipCmds(package) 1
  set _skipCmds(pkg_compareExtension) 1
  set _skipCmds(pkg_mkIndex) 1
  set _skipCmds(tclPkgSetup) 1
  set _skipCmds(tclPkgUnknown) 1
  set _skipCmds(pkg_mkIndex) 1
  set _skipCmds(source) 1

  # don't mark for logging commands that are in the help groups
  # specified.
  set _skipCmdsInHelpGroups(Procedures) 1
  set _skipCmdsInHelpGroups(Builtins) 1

  #----------------------------------------------------------
  # private variables
  #----------------------------------------------------------
  # This variable tells the tracelog to trace all global variables and not
  # just the ones returned by printvar -application.  It can be set as a 
  # work-around for generating a replay log if the application has variables
  # that are not reported via printvar -application.
  set _traceAllGlobalsVars 0
  # echo traced commands to the output log as well as doing
  # the tracelog
  set _echoCmds 1
  # echo the performance data as well as the command
  set _echoPerformance 0
  set _echoPerformanceStart 0
  set _echoPerformanceThreshold 0
  set _tracelogCmdGroup "Procedures"
  set _skipCmdsInHelpGroups($_tracelogCmdGroup) 1
  # suspend/resume control
  set _inSuspend 0
  # global variable to avoid nested tracing
  set _inTracedCmd 0
  set _preLogPosition -1
  # output file handle
  set _logFile ""
  # output file name
  set _logFileName ""
  # set lists of commands organized by command group
  # that will be processed when tracing is started
  # this is initialized when this package is loaded.
  array set _cmdsByGroup {}
  #
  # This is a list of the global variables that is setup
  # when the package is initialized and is used for the 
  # global variable-based tracing.
  set _globalVarsToTrace {}

  #
  # flag to control debug message printing for this package
  set _debug 0
  # variables for performance tracing
  set _startTime 0
  set _startCpu 0
  set _startMem 0

  # hash to track which collection handles have been traced
  set _suppressUntracedClct 1
  array set _tracedCollections {}
  set _numCmdSkippedForUntracedClct 0

  # messages types for print_message
  set _ERROR "Error"
  set _WARN  "Warning"
  set _INFO  "Information"
}

#-------------------------------------------------------------------------------
#
# prints debug messages for the tracelog package if tracelog::debug is true.
# the greater the number for the level the more detail the messages
#
proc tracelog::debug { level msg } {
  if { $::tracelog::_debug >= $level } {
    set save_inTraceCmd $::tracelog::_inTracedCmd
    set ::tracelog::_inTracedCmd 1

    set save $::sh_enable_stdout_redirect
    set ::sh_enable_stdout_redirect false

    puts stdout "tracelog debug $msg"

    set ::sh_enable_stdout_redirect $save

    set ::tracelog::_inTracedCmd $save_inTraceCmd 
  }
}

#-------------------------------------------------------------------------------
#
# write text to the trace log file
#
proc tracelog::print_trace { str } {
  debug 2 "trace entry $str"
  puts $tracelog::_logFile "$str"
  flush  $tracelog::_logFile
}

#-------------------------------------------------------------------------------
#
# write test to the trace log file
#
proc tracelog::print_to_console { str } {

  set save_inTraceCmd $::tracelog::_inTracedCmd
  set ::tracelog::_inTracedCmd 1

  set save $::sh_enable_stdout_redirect
  set ::sh_enable_stdout_redirect false

  puts stdout "$str"
  flush stdout

  set ::sh_enable_stdout_redirect $save

  set ::tracelog::_inTracedCmd $save_inTraceCmd 
}

#-------------------------------------------------------------------------------
#
# write a user message to the console
# use _ERROR, _WARN, or _INFO for sev
#
proc tracelog::print_message { sev str } {
  tracelog::print_to_console "TRACELOG-${sev} : $str"
}



#-------------------------------------------------------------------------------
#
# generate stub commands for cputime and mem if the app
# doesn't support them. This way we don't get errors
# when tracelog is run with them.
#
proc tracelog::check_app_cmds {} {
  foreach cmd {mem {cputime -self -child}} {
    redirect /dev/null {
      set caughtError [catch $cmd]
    }
    if { $caughtError } {
      set baseCmd [lindex $cmd 0]
      redirect /dev/null {
        set caughtError [catch $baseCmd]
      }
      if { $caughtError } {
        proc ::tracelog::$baseCmd { args } {
          return 0
        }
        tracelog::print_message  $::tracelog::_WARN "application does not support the $baseCmd command. cpu reporting in tracelog will not be supported. " 
      } else {
        proc ::tracelog::$baseCmd { args } " return \[::$baseCmd\] "
        debug 1 "Warning: application does not support the $cmd command."
        debug 1 "         but does support the $baseCmd command."
        debug 1 "         cpu reporting in tracelog will not include child process flags. " 
      }
    }
  }
  if { [catch {@@info commands info}] } {
    # a simple wrapper if @@ info isn't defined
    proc ::tracelog::@@info { args } {
      set args [linsert $args 0 info]
      return [uplevel $args]
    }
  }

  # since these commands are new -- wrap them in preference to using
  # the variable tracing if they are available
  foreach cmd {set_app_var get_app_var} {
    if { ![string equal [@@info command ::$cmd] ""] } {
      lappend ::tracelog::_moreCmds $cmd
    } 
  }

  # add special case for unregistered app vars to also be auto traced
  # hopefully people will use set_app_var but in case they don't we will
  # trace them anyway.
  if { ![string equal [info vars ::sh_allow_tcl_with_set_app_var_no_message_list] ""] } {
    foreach var $::sh_allow_tcl_with_set_app_var_no_message_list {
      lappend ::tracelog::_moreVars "${var}"
    }
    trace add variable ::sh_allow_tcl_with_set_app_var_no_message_list {write unset} "tracelog::trace_sh_allow_tcl_with_set_app_var_no_message_list"
  }

  if { ![info exists ::sh_enable_stdout_redirect] } {
    set ::sh_enable_stdout_redirect false
  }
}
tracelog::check_app_cmds

#-------------------------------------------------------------------------------
#
# This proc is used for a variable trace that tracks changes to 
# sh_allow_tcl_with_set_app_var_no_message_list and # ensures that all variables 
# listed are also in the _moreVars list so that tracelog traces them.
#
proc tracelog::trace_sh_allow_tcl_with_set_app_var_no_message_list { aliasedVarname subscript op } {
  debug 1 "tracing variable $op to trace_sh_allow_tcl_with_set_app_var_no_message_list"
  # prevent n**2 by using an array to make the search logn
  array set moreVarsArray {}
  foreach var $::tracelog::_moreVars {
    set moreVarsArray($var) 1
  } 
  # for all variables not already in the _moreVars list add them
  foreach var $::sh_allow_tcl_with_set_app_var_no_message_list {
    if { ![info exists moreVarsArray(${var})] } {
       lappend ::tracelog::_moreVars "${var}"
       set moreVarsArray($var) 1
       debug 1 "added variable $var to _moreVars"
       # if the trace is already active then also add traces
       if { !( [string equal $::tracelog::_logFile "" ] ||
                $::tracelog::_inSuspend ) } {
         tracelog::wrap_variable $var
         debug 1 "wrapped variable $var"
       }
    }
  }
  debug 1 "end tracing variable $op to trace_sh_allow_tcl_with_set_app_var_no_message_list"
}


#-------------------------------------------------------------------------------
# For ICC this contains the list of commands that are showing up in the procedures group
# but should really have been in one of the application groups.
# This is constantly changing -- so for now I just list the superset of commands 
# I have seen in various releases and prune out those that have gone away from
# the set added to _moreCmds
#
# This is a noop for applications other than icc
proc tracelog::icc_fix_conventions { } {
  if { ![string equal $::synopsys_program_name "icc_shell"] } {
    return 
  }

  # commands erroneously in Procedures command group or hidden
  foreach cmd { all_bounds_of_cell all_cells_in_bound all_clocks 
                 all_connected all_critical_cells all_critical_pins
                 all_designs all_dont_touch all_drc_violated_nets all_fanin
                 all_fanout all_fixed_placement all_high_fanout all_ideal_nets
                 all_inputs all_macro_cells all_objects_in_bounding_box all_outputs
                 all_physical_only_cells all_physical_only_nets
                 all_physical_only_ports all_registers all_size_only_cells
                 all_spare_cells all_threestate all_tieoff_cells
                 close_mw_cel close_mw_lib copy_design create_design create_mw_lib
                 get_clocks get_clock_tree_objects get_magnet_cells group 
                 read_db read_ddc
                 read_milkyway read_sdc read_pdef read_verilog rebuild_mw_lib
                 remove_ccl_attribute remove_ccl_str_in_pattern_list
                 remove_ignore_cell remove_user_attribute rename_design
                 report_mw_lib reset_design route rp_group_references
                 set_ignore_cell set_mw_lib_reference set_mw_technology_file
                 set_separate_process_options
                 set_user_attribute 
                 uniquify write_milkyway write_mw_lib_files check_physical_design 
                 set_active_scenarios all_active_scenarios set_cts_scenario get_cts_scenario
                 change_link  get_lib_cells set_dont_touch set_dont_touch_network
                 set_dont_use set_false_path set_ideal_net set_ideal_network   
                 set_load set_max_area set_max_capacitance 
                 set_max_delay set_max_fanout set_max_transition  
                 set_min_capacitance set_min_delay set_multicycle_path 
                 set_operating_conditions set_resistance 
                 add_to_rp_group 
                 all_scenarios 
                 change_selection_no_core 
                 change_selection_too_many_objects 
                 characterize 
                 create_clock 
                 create_generated_clock 
                 create_scenario 
                 drive_of 
                 get_buffers 
                 get_clusters 
                 get_designs 
                 get_generated_clocks 
                 get_lib_pins 
                 get_libs 
                 get_path_groups 
                 get_timing_paths 
                 group_path 
                 gui_get_setting 
                 gui_set_setting 
                 gui_show_man_page 
                 read_verilog_to_cel
                 remove_driving_cell 
                 remove_from_rp_group 
                 remove_rp_groups 
                 report_histogram
                 reset_path 
                 set_drive 
                 set_driving_cell 
                 set_size_only 
                 set_ungroup 
                 trace_scan_chain
                 optimize_pre_cts_power
                } {
    if { ![string equal [@@info command ::$cmd] ""] } {
      lappend ::tracelog::_moreCmds $cmd
    } else {
      tracelog::debug 1 "icc moreCmd $cmd not added because command was not found"
    }
  }

  # variables not showing up in printvar
  foreach var { 
          adaptive_leakage_opto
          adaptive_leakage_opto_high_effort
          auto_restore_mw_cel_lib_setup 
          bind_unused_hierarchical_pins
          case_analysis_large_cell_pin_cnt
          case_analysis_propagate_through_icg
          cetan
          cgpl_smooth_time_factor
          change_names_bit_blast_negative_index
          chipfinish_hard_keepout_only
          clk_dft_postprocess
          clock_cell_has_multiple_edge
          compare_rc_first_dominant_layer_percentage
          compare_rc_total_vs_wire
          compile_delete_unloaded_sequential_cells
          compile_enable_library_pruning
          compile_hold_reduce_cell_count
          compile_instance_name_prefix
          compile_log_format
          compile_new_scan_flow
          compile_no_new_cells_at_top_level
          compile_remove_unloaded_constant_cells
          complete_mixed_mode_extraction
          conan_enable_clock_opt_flow
          conan_enable_place_opt_flow
          cpd_skip_timing_check
          ctc_delay_target
          ctdn_match_lib_footprint
          ctdn_optimize_generated_clock
          ctdn_prune_small_drive
          ctdn_replace_cto
          cto_2007_12
          cto_2008_09_post_route
          cto_do_post_route_optimization
          cto_fix_load_cap_violation
          cto_fix_transition_violation
          cto_inter_clock_insertion_delay_offset
          cto_inter_clock_skew_offset
          cto_intra_clock_balance
          cto_remove_ilm_guide_buffer
          cto_report_start_paths
          cto_search_repair_loop
          cto_signal_routed
          cto_skew_improve
          cto_skip_clock_eco_route
          cto_use_virtual_route
          cts_add_arrival_time
          cts_allow_dont_touch_subtree_sizing
          cts_allow_ilm_guide_buffer_optimization
          cts_auto_split_debug_mode
          cts_ba_lowpower
          cts_blockage_map_new_grid
          cts_blockage_map_xgrids
          cts_blockage_map_ygrids
          cts_buffer_file_name
          cts_build_imbalanced_exception_tree
          cts_check_legality
          cts_clock_source_is_exclude_pin
          cts_clock_source_is_ignore_pin
          cts_disable_driver_aware
          cts_disable_scenario_switching
          cts_do_characterization
          cts_do_eco_placement
          cts_drc_check
          cts_drc_honor_dont_touch_subtree
          cts_dump_ignore_pins
          cts_enable_boundary_port_guide_buffer_insertion
          cts_enable_clock_at_hierarchical_pin
          cts_enable_clock_at_ilm_port
          cts_enable_drc_fixing_on_data
          cts_enable_multiple_pins_macro_guide_buffer_insertion
          cts_enable_option_loading
          cts_enable_pin_level_delay_balance
          cts_enable_slew_degradation
          cts_enh
          cts_fix_clock_tree
          cts_fix_clock_tree_sinks
          cts_fix_drc_beyond_exceptions
          cts_fix_drc_on_data
          cts_fix_rp_cells
          cts_flatten_formality_file_name
          cts_force_ilm_keep_full_clock_tree
          cts_force_user_constraints
          cts_go_through_ilm
          cts_high_effort_latency
          cts_honor_std_cell_spacing
          cts_icgr_hard_max_layer_constraint
          cts_icgr_hard_min_layer_constraint
          cts_input_transition_for_load_estimation
          cts_insert_guide_buffer
          cts_insert_high_fanout_tree
          cts_instance_name_prefix
          cts_integrated_global_router
          cts_integrated_router
          cts_level_shifter_threshold
          cts_low_power
          cts_low_power_relax_target_transition
          cts_max_net_length
          cts_max_net_length_margin
          cts_mcmm_user_scn_order
          cts_mcmm_user_scn_synthesis_order
          cts_move_clock_gate
          cts_net_file_name
          cts_net_name_prefix
          cts_new_clustering
          cts_new_clustering_debug
          cts_new_clustering_delay_tolerance
          cts_new_clustering_rc_limit
          cts_new_clustering_target_itran
          cts_new_clustering_target_otran
          cts_new_one_fanout_path
          cts_no_in_place_sizing_of_flops
          cts_only_presize_clock_gates
          cts_open_partial_blocked_grids
          cts_prects_upsize_gates
          cts_prelude_load_estimation
          cts_prerelocation_honor_dont_touch
          cts_print_jump_through_latch
          cts_push_down_buffer
          cts_rc_percent_for_float_pins
          cts_remove_buffers_inserted_by_fixing_drc
          cts_restore_ideal_network
          cts_router_update_internal_blockage_map
          cts_separate_data_pin
          cts_set_aon_onoff_net_dont_buffer
          cts_size_clock_gate
          cts_split_any_gate
          cts_split_intermediate_level_clock_gates
          cts_target_cap
          cts_target_fanout
          cts_target_transition
          cts_tight_drc
          cts_timing_file_name
          cts_top_level_ocv
          cts_trace_nonstop_gclk
          cts_traverse_dont_touch_subtrees
          cts_update_clock_attributes
          cts_upsize_for_drc_beyond_exception
          cts_use_awe
          cts_use_debug_mode
          cts_use_designtime_root_transition
          cts_use_lib_max_fanout
          cts_use_multi_input_buffer
          cts_use_old_port_cleanup
          cts_use_sdc_max_fanout
          dcpm_skip_checking_pg_driver
          def_enable_mw_shielding
          def_ignore_via_definitions
          def_non_default_width_wiring_to_net
          defout_max_route_elements_per_line
          def_pg_route_and_connection_to_spnet
          DEFWIRESONLYFORALL
          def_write_rotated_vias
          derive_default_routing_layer_direction
          dft_honor_dont_touch_nets
          disable_bump_cover_as_physical_only
          disable_delta_slew_for_tran_cstr
          do_eco_placement
          dont_bind_unused_input_pins_to_logic_constant
          DONT_CHECK_TERMS_ON_PADS
          dont_touch_cells_with_dont_touch_nets
          dont_touch_nets_with_size_only_cells
          dont_touch_power_domain_control_nets
          eco_keep_split_net_batch_tcl
          eco_netlist_preprocess_for_verilog
          eco_preserve_routes
          eco_record_cell_change
          enable_ao_synthesis
          enable_arnoldi_run_time_flow
          enable_clock_to_data_analysis
          enable_concise_qor_snapshot
          enable_detailed_xtalk_est_in_opt
          enable_hier_si
          enable_layer_blockage_detour
          enable_mcmm_qor_snapshot
          enable_mw_ilm_view_ui_support
          enable_mw_open_sync_bus_for_existing_ports
          enable_net_pattern_nondrule_assignment_after_hfs
          enable_net_pattern_rc_scaling
          enable_new_detour_check
          enable_sn_aware_ao_synthesis
          enable_spacing_weights_in_define_routing_rule
          enable_timing_directed_cluster_hfs
          enable_timing_directed_hfs
          enable_via_conversion
          extract_clock_nets_only
          extract_coupling_cap
          extract_dont_remove_ba
          extract_dr_metalfill_ratio_adjust
          extract_enable_cel_geoms
          extract_enable_interlayer_cc
          extract_enable_mwp2b_process
          extract_enable_new_r_tree
          extract_enable_pl_flow
          extract_enable_temperature_derating
          extract_enable_vr_layer_blockage
          extract_enable_vr_res_space_weighting
          extract_enable_vr_sparse_handle
          extract_enable_vr_track_spacing
          extract_enhanced_detour_around_pins
          extract_has_cts_ba_nets
          extract_ilm_use_fast_flow
          extract_max_num_of_threads
          feas_auto_clock_ideal_net
          feas_drc_only_tt_and_cap
          feas_ignore_scan
          feas_use_placer_max_cell_density
          fpopt_ctc_dpi_use_pq
          fpopt_env_feedthru_buf
          freeze_skew_in_clock_arnoldi
          galileo_signoff_verbose
          glo_more_opto
          gr_delay_calc_level_threshold
          gr_open_pins
          gui_online_browser
          hdl_dont_create_pg_terminal
          hdlin_enable_presto
          hdlin_enable_presto_for_vhdl
          hdlin_enable_vpp
          hdlout_internal_busses
          hfs_driver_aware_clustering
          hfs_insert_threshold
          hfs_max_net_length
          hfs_min_net_length
          hfs_remove_threshold
          hfs_strategy
          hfs_top_level_buffering
          hier_filler
          hold_fix_rebase_sdn_slack
          icc_congestion_for_initial_placement
          icc_enable_buffer_chain_mode
          icc_enable_dbl_inv_hold_fix
          icc_enable_high_effort_congestion
          icc_enable_incremental_hfs
          icc_enable_low_fanout_synthesis
          icc_enable_new_dtdp_res_model
          icc_enable_old_place_opt_high_effort_flow
          icc_enable_skip_clock_network
          icc_force_dont_use_dedicated_scanout
          icc_hold_fix_density_limit
          icc_hold_prioritize_max_trans
          icc_improved_buffering_on_long_net
          icc_LFS_blocked_bbox_area_ratio
          icc_LFS_show_low_fanout_blocked_nets
          icc_LFS_verbose
          icc_port_location_guided_buffering
          icc_preroute_power_1012
          icc_quick_effort_hold_fix
          icc_rbuf_cluster_honor_worst_tran
          icc_refine_multi_site_loc
          icc_save_bindings_to_database
          icc_short_summary_report
          icc_skip_buffering_on_pg_nets
          icc_spg_allow_unplaced_cells
          icc_tns_high_effort
          icc_tns_opto_use_fresh_borrow
          icc_transfer_binary_scandef
          icc_use_pin_location_for_mpn
          ignore_clock_input_delay_for_skew
          ilm_allow_all_rotations
          ilm_connect_auto_ignore_ports
          ilm_create_ilm_port_bound
          ilm_cut_nets_through_ilm_ports
          ilm_limited_tie_off
          ilm_on_demand_scenario_loading
          ilm_support_custom_blocks
          ilm_support_mixed_mode_rc
          ilm_use_ports_for_placement
          jtb_do_mim_budgeting
          legalize_allow_all_apl_messages
          legalize_auto_x_keepout_margin
          legalize_auto_y_keepout_margin
          legalize_disable_cts_em_spacing
          legalize_displace_print_count_limit
          legalizer_debug_plots
          legalizer_enable_2007_12_flow
          legalizer_enable_spacing_rules
          legalizer_enable_spacing_rules_on_fixed_phys_only_cells
          legalizer_enable_timeout
          legalizer_enhance_precision
          legalizer_skip_overcapacity_check
          legalizer_skip_preroute_merge
          legalizer_skip_via_pnet_extra_expansion
          legalize_support_phys_only_cell
          lib_cell_using_delay_from_ccs
          lib_load_timing_format
          lib_pin_using_cap_from_ccs
          lpl_density_aware
          lpl_width_aware_location_assignment
          lr_block_va_boundary
          lr_min_allowed_layer
          lr_route_leaf_nets_on_lower_layers
          magnet_placement_nworst
          mcmm_enable_high_capacity_flow
          mcmm_high_capacity_effort_level
          mv_allow_va_overutilization
          mv_continue_on_postlude_error
          mv_continue_on_prelude_error
          mv_cts_honor_no_new_cells_at_top_level
          mv_disable_lib_opcond_check
          mv_disable_voltage_area_aware_detour_routing
          mv_enable_macro_opcond_spreading
          mv_enable_mvbuf_costing
          mv_enable_pad_opcond_spreading
          mv_enable_power_domain_power_net_check
          mv_match_temperature
          mv_no_cells_at_default_va
          mw_cel_consistency_check
          mw_change_names_support_ILM_feedthrough
          mwdc_allow_higher_mem_usage
          mwdc_enable_cell_is_pad_from_design
          mwdc_restore_special_pg_connection
          mw_enable_cel_check
          mw_enable_check_unplace_status
          mw_enable_def_check_only
          mw_enable_escape_style_check
          mw_enable_name_check
          mw_enable_octagon_extension
          mw_enable_route_patch_paging
          mw_hdl_consolidated_verilog_reader
          mw_hdl_consolidated_verilog_writer
          mw_hier_pg_fix_mismatch
          mw_mwu_keep_on_flow
          MW_USE_VIA_ENHANCEMENT
          mw_verilog_eco_flow
          new_case_analysis_flow
          no_preparing_data_for_gui_query
          no_row_gap
          optimize_dft_chain_sort_prepartition
          optimize_dft_further_reorder
          optimize_dft_min_wirelength_flow
          optimize_dft_new_repartition
          optimize_dft_skip_partition
          output_clock_port_as_data
          pattern_center_in_region
          PDFT_101
          physopt_ahfs_check_max_cap_trans
          physopt_allow_dt_sizing
          physopt_auto_area_recovery
          physopt_auto_disable_mv_net_segment
          physopt_coarse_placer_process_name
          physopt_congestion_reduction_factor
          physopt_delete_unloaded_sequential_cells
          physopt_density_area_recovery
          physopt_density_area_recovery_limit
          physopt_drive_strength_mode_legalize
          physopt_enable_adjust_placement
          physopt_enable_astro_legality_checker
          physopt_enable_coarse_placer_process
          physopt_enable_placement_hfs
          physopt_enable_router_process
          physopt_enable_router_timer_process
          physopt_enable_tlu_plus_process
          physopt_enable_via_res_long_net_scaling
          physopt_enable_via_scaling
          physopt_fast_high_effort_area_recovery
          physopt_fix_cells_on_soft_keepouts
          physopt_fix_multiple_clean_inv
          physopt_fix_multiple_port_nets
          physopt_force_pccts_dont_touch_for_ilm
          physopt_hfs_driver_with_no_timing_arcs
          physopt_hfs_hf_new_port
          physopt_hfs_hf_new_port_map
          physopt_hfs_hf_threshold
          physopt_hfs_preprocess_ilms
          physopt_hfs_verbose
          physopt_high_effort_max_net_length_fix
          physopt_long_net_via_resistance_scale
          physopt_low_density_placement
          physopt_macro_cell_height_threshold
          physopt_margin_area_threshold
          physopt_max_displace_rows
          physopt_max_placement_density
          physopt_monitor_cpu_memory
          physopt_monitor_cpu_memory_level
          physopt_multiple_placement_area
          physopt_no_legalize
          physopt_onroute_size_all_in_place
          physopt_pccts_dont_touch_support
          physopt_pccts_verbose
          physopt_protect_margin
          physopt_reset_placement_hfs
          physopt_rp_enable_pin_visibility
          physopt_skip_auto_extraction
          physopt_soft_keepout_distance
          physopt_soft_keepout_exclude_registers
          physopt_tmp_dir
          physopt_vr_partial_track_rate
          place_mark_cell_soft_fixed
          placement_treat_soft_keepout
          place_opt_enable_experimental_cong_removal
          place_opt_enable_new_hfs
          place_opt_enable_top_level_solution
          place_opt_hfs_inverter
          place_opt_low_power_disable_cts
          place_opt_new_leakage_optimization
          placer_allow_buffers_and_inverters_over_soft_blockages
          placer_allow_combinational_cells_over_soft_blockages
          placer_allow_density_aware_shoving_in_cong_mode
          placer_allow_repeaters_over_soft_blockages
          placer_auto_bound_for_gated_clock_high_fanout_threshold
          placer_congestion_expansion_factors_bugfix
          placer_congestion_removal_weight
          placer_detect_detours
          placer_enable_advanced_resistance_model
          placer_enable_enhanced_soft_blockages
          placer_enable_high_effort_congestion
          placer_enable_two_pass_blockage_flow
          placer_fix_cells_on_soft_keepouts
          placer_hack_force_no_congestion_driven
          placer_max_allowed_timing_depth
          placer_region_placement_mode
          placer_routing_grid_size
          placer_run_in_separate_process
          placer_soft_blockages_for_non_buffers_only
          placer_soft_blockages_for_registers_only
          placer_support_many_cts_buffers
          placer_use_center_of_mass_seed_locations
          placer_use_density_aware_blockage_shoving
          placer_use_dynamic_keepouts
          placer_use_initial_values
          placer_use_max_density_for_keepout_planes
          placer_use_ndrs_in_cong_estimation
          placer_use_path_group_weights
          placer_use_rt_blockage_shoving
          placer_use_zroute
          placer_zroute_ignore_scan
          placer_zrt_deterministic_mode
          pna_pin_voltage_file
          power_cg_auto_identify
          power_disable_clock_gate_optimization
          power_do_not_size_icg_cells
          power_keep_tns
          power_multi_vt_dont_use_sequential_cell
          power_opt_power_critical_flow
          pre_cts_power_opt_enable_icg_removal
          preroute_1003
          preroute_focal_opt_rebuffer_verbose
          preserved_floating_nets
          project100
          project101
          project101_tns
          project101_tns_effort
          project86
          project99
          psyn_cache_timing_on_disk
          psyn_dont_cleanup_net_length
          psyn_enable_min_max_layer_optimization
          psyn_enable_new_inherit_pad_location
          psyn_enable_wide_wire_optimization
          psyn_lib_cell_class_opto_only
          psyn_onroute_disable_cap
          psyn_onroute_disable_cap_drc
          psyn_onroute_disable_fanout_drc
          psyn_onroute_disable_hold_fix
          psyn_onroute_disable_netlength_drc
          psyn_onroute_disable_trans
          psyn_onroute_disable_trans_drc
          psyn_onroute_enable_tran_buf
          psyn_onroute_size_seqcell
          psyn_onroute_size_seqcell_factor
          psynopt_adaptive_leakage_opto
          psynopt_adaptive_mcmm
          psynopt_density_limit
          psynopt_dpi_cden_threshold
          psynopt_dpi_num_rows
          psynopt_enable_cden_map
          psynopt_enable_high_fanout_legality
          psynopt_enable_post_ao_legalization_sizing
          psynopt_high_fanout_legality_limit
          psynopt_use_tsize
          rbuf_cluster_fake_cxcy
          rc_adjust_rd_when_less_than_rnet
          rc_degrade_min_slew_when_rd_less_than_rnet
          rc_filter_rd_less_than_rnet
          rc_pt_driver_model
          rc_rd_more_than_rnet_arnoldi_threshold
          relax_iso_output
          reopt_cstr_log_interval
          reopt_enable_auto_blockage_detection
          reopt_place_block_core_ratio
          report_congestion_skip_legality_check
          report_qor_show_hold_slack
          report_timing_use_accurate_delay_symbol
          restrict_fp_multi_height_orient
          ropt_1109
          ropt_fopt_endpoint_margin
          ropt_hold_1012
          routeopt_allow_min_buffer_with_size_only
          routeopt_density_limit
          route_opt_enable_blocked_region_buffer
          routeopt_enable_incremental_track_assign
          routeopt_hold_strategy
          route_opt_max_loops
          routeopt_mt_num
          routeopt_preserve_routes
          routeopt_trans_exp
          route_opt_xtalk_reduction_hold
          route_opt_xtalk_reduction_hold_threshold
          route_opt_xtalk_reduction_max_net_count
          route_opt_xtalk_reduction_min_net_count
          routeopt_xtalk_reduction_min_net_count
          route_opt_xtalk_reduction_setup_slack_threshold
          route_opt_xtalk_reduction_setup_threshold
          routeopt_xtalk_reduction_tns
          routeopt_xtalk_reduction_tns_delta_delay_threshold
          routeopt_xtalk_reduction_tns_effort_level medium
          routeopt_xtalk_reduction_tns_hold_delta_delay_threshold
          routeopt_xtalk_reduction_tns_hold_slack_threshold
          routeopt_xtalk_reduction_tns_max_hold_net_count
          routeopt_xtalk_reduction_tns_max_net_count
          routeopt_xtalk_reduction_tns_max_static_noise_net_count
          routeopt_xtalk_reduction_tns_max_tran_net_count
          routeopt_xtalk_reduction_tns_total_delta_delay_threshold
          routeopt_xtalk_reduction_tns_tran_delta_delay_threshold
          routeopt_xtalk_reduction_tns_tran_slack_threshold
          routeopt_xtalk_reduction_transition
          routeopt_xtalk_reduction_tran_threshold
          routeopt_zrt
          routeopt_zrt_preserve_routes
          rp_dont_ignore_std_fixed_cell
          rpt_local_skew_skip_icg
          save_mw_cel_lib_setup
          save_only_top_level_upf
          save_upf_resolve_type_parallel
          sdn_charz_min_only_fix
          sdn_connleg_new_refresh_mode
          sdn_honor_dtn_attr
          set_physopt_cpulimit_options
          show_whole_flow_in_analyze_displacement
          si_changed_min_computation
          si_changed_tran_computation
          si_enable_analysis
          si_enable_lev2_hier_calc
          signal_em_enable_real_geom
          signoff_path_based
          si_noise_use_ccsn_only
          si_signal_em_report_bbox
          skew_opt_adjustment_limit
          skew_opt_hold_margin
          skew_opt_improvement_threshold
          skew_opt_latches_are_fragile
          skew_opt_optimize_from_latches
          skew_opt_optimize_to_clock_gates
          skew_opt_optimize_to_latches
          skew_opt_setup_margin
          skew_opt_skip_clock_balancing
          skew_opt_skip_ideal_clocks
          skew_opt_skip_propagated_clocks
          snps_handle_physical_only
          sopt_correlation_report_dir
          sot_dont_buffer_for_hold_in_ipo
          sot_icc_improved_hold_fixing
          spg_ascii_flow
          synthesized_clocks
          tau_filter_in_fs
          test_sccomp_put_buffer
          timing_aocvm_analysis_mode
          timing_ccs_pin_based_cap_convert
          timing_clock_gating_propagate_enable
          timing_clock_tracing_through_ilm_interface_pin
          timing_crpr_filtering
          timing_cts_jump_all_related_clks
          timing_disable_clock_gating_check
          timing_disable_internal_inout_net_arcs
          timing_disable_recovery_removal_checks
          timing_early_launch_at_borrowing_latches
          timing_fast_incr_case_update
          timing_input_port_default_clock_choice
          timing_no_computation
          timing_path_intersect_fast
          timing_scgc_override_library_setup_hold
          timing_use_clock_specific_transition
          timing_use_driver_arc_transition_at_clock_source
          timing_use_propagated_master_clock_transition
          TRACEMODE_CLOCK_TECHNIQUE_ADVANCED
          tv_case_sequential_test_enable
          ui_ring_connection_support
          use_only_overlap_layer_for_PO_PB
          use_pt_fallback_for_correlation 
          vdd_type_diode_cell_name
          vss_type_diode_cell_name
          zbo_area_layered_record
                } {
    lappend ::tracelog::_moreVars "${var}"
  }
}  



#-------------------------------------------------------------------------------
#
# returns 1 if the string is a collection handle else returns 0
#
proc tracelog::is_collection { str } {
  if { [string is space $str] } {
    return 0
  }
  # just use pattern matching for now could be more exact
  set retval [string equal [regexp -inline {^_sel\d+$} $str] $str] 
  if { $retval } {
    as_collection $str; # Make a collection again, remove from cache since string ops trash the clct
  }
  return $retval
}

#-------------------------------------------------------------------------------
#
# take an elapsed time calculated from [clock seconds] and format it
# as a string with days hours minutes and seconds and return the string
proc tracelog::formatElapsedTime { elapsedTime } {
  set minutesPerDay 86400
  # work around for formality returning a resultion of hundredths of a sec
  # instead of seconds.  For now just round to the second.
  set elapsedTime [expr {int($elapsedTime)}] 
  set d [expr { ( ( $elapsedTime ) / $minutesPerDay ) }]
  set result ""
  if { $d > 0 } {
    if { $d > 1 } {
      set result "$d days "
    } else {
      set result "$d day "
    }
  }
  set elapsedTime [expr {$elapsedTime - ($d * $minutesPerDay)}]
  append result [clock format $elapsedTime -format %k:%M:%S -gmt 1]
  return $result
}

#-------------------------------------------------------------------------------
#
# write the text for the given command and its result to the log
#  
# We actually double log the command.  The first time we log it before we
# execute it.  This is just in case the command fatals, so that the command
# does show up in the log.  The second time is after the command completes.
#
# In this case we seek back to where we pre-logged the command and overwite
# it with the final logging that includes the result.  
#
proc tracelog::print_cmd_trace { cmd result {prelog 0} } {

  set untracedClct 0
  if { $::tracelog::_suppressUntracedClct } {
    foreach clct [regexp -all -inline {\m(_sel\d+)\M} $cmd] {
      if { ![info exists ::tracelog::_tracedCollections($clct)] } {
        set untracedClct 1
      }
    }
    if { $untracedClct } {
      incr ::tracelog::_numCmdSkippedForUntracedClct
      if { $::tracelog::_numCmdSkippedForUntracedClct == 1 } {
        tracelog::print_message  $::tracelog::_WARN {Found one or more instances of collections to trace that haven't been created.  
          Trace will omit those commands that use those collections. 
          If this causes problems you can disable the suppression by setting the option -suppress_unknown_clct off, but the trace may have errors during replay.}
      }
    }
  }

  set logFormat ";### %5s: MEM: %-10s %-14s; CPU: %-12s %-12s; TIME: %-25s %s"
  if { $prelog } {
    set ::tracelog::_preLogPosition [tell $::tracelog::_logFile]
    if { $::tracelog::_echoCmds } {
      if { ! $untracedClct } {
        print_to_console ";## $cmd"
      }
      if { $::tracelog::_echoPerformance } {
        set ::tracelog::_startTime [clock seconds]
        set ::tracelog::_startCpu  [cputime -self -child]
        set ::tracelog::_startMem  [mem]
        if { $::tracelog::_echoPerformanceStart } {
          set a [format $logFormat \
                 "start" \
                 $::tracelog::_startMem "" \
                 $::tracelog::_startCpu "" \
                 [date] ""]
          if { ! $untracedClct } {
            print_to_console $a
          }
        }
      }
    }
  } else {
    if { $::tracelog::_preLogPosition >= 0 } {
      seek $::tracelog::_logFile $::tracelog::_preLogPosition
      set ::tracelog::_preLogPosition -1
    }
    if { $::tracelog::_echoCmds && $::tracelog::_echoPerformance } {
      set endCpu [cputime -self -child]
      set endMem [mem]
      set endTime [clock seconds]
      set elapsedTime [expr {$endTime - $::tracelog::_startTime}]
      set elapsedCpu [expr {$endCpu - $::tracelog::_startCpu}]
      if { $elapsedCpu >= $::tracelog::_echoPerformanceThreshold } { 
        set a [format $logFormat \
                    "end" \
                    $endMem "(delta [expr {$endMem - $::tracelog::_startMem}])" \
                    $endCpu "(delta $elapsedCpu [formatElapsedTime $elapsedCpu])" \
                    [date]  "(delta $elapsedTime [formatElapsedTime $elapsedTime])"]
        if { ! $untracedClct } {
           print_to_console $a
        }
      }
    }
  }


  # make sure we only substitute word-delimited collection
  # references.
  # And make sure lists of collections are build with the list
  # command.  We can't use list commands here since it messes with
  # the quoting of the elements
  set newCmd ""
  foreach arg $cmd {
    if {[regsub -all {\m(_sel\d+)\M} $arg {$\1} arg]} {
      if {[llength $arg] > 1} {
        append newCmd { [list } $arg {]}
      } else {
        if { ![string equal $newCmd ""] } {
          append newCmd " " 
        } 
        append newCmd $arg
      }
    } else {
      if { ![string equal $newCmd ""] } {
        append newCmd " " 
      } 
      append newCmd [list $arg]
    }
  }
  debug 2 "trace subtituted command\n\t$cmd\n\t$newCmd\n"


  if { ! $untracedClct } {
    if { [is_collection $result] } {
      print_trace "set $result \[$newCmd\]"
      if { $::tracelog::_suppressUntracedClct } {
        set ::tracelog::_tracedCollections($result) 1
      }
    } else {
      print_trace "$newCmd"
    }
  }
}

#-------------------------------------------------------------------------------
#
# define a procedure that wraps a command that generates a
# log entry for the command when executing it.
#
proc tracelog::wrap_command {cmdName clear } {
  # this is the template for the proc that will
  # be generated
  set procTemplate {
    proc PROCNAME { args } {
      set cName CMDNAME
      set cNameProc __real4trace_${cName}
      set baseCmd BASECMDNAME

      tracelog::debug 2 "in wrapper for command $cName "

      set doTrace 0
      if { ! $::tracelog::_inTracedCmd } {
        set doTrace 1
      }
      set ::tracelog::_inTracedCmd 1

      set cmdName $baseCmd
      if { [string equal [@@info command ::${baseCmd}] ""] } {
        set cmdName $cNameProc
      }
      set logCmd $args
      set logCmd [linsert $logCmd 0 $baseCmd]
      set args [linsert $args 0 $cName]

      if { $doTrace } {
        ::tracelog::print_cmd_trace $logCmd "" 1
      }

      set result ""
      set rc [catch {set result [uplevel $args]} errMsg]
      set savedInfo $::errorInfo

      if { $doTrace } {
        ::tracelog::print_cmd_trace $logCmd $result 
        set ::tracelog::_inTracedCmd 0
      }

      switch -exact -- $rc {
        0 {
          # OK
        }
        1 {
          # Error - clean up the stack trace to skip this wrapper
          set thisCmdStack [lreplace [info level 0] 0 0 $cName]
          set errList [split $savedInfo \n]
          set errList [lrange $errList 0 [expr {[llength $errList] - [llength [split $thisCmdStack \n]] - 5}]]
          set newErrorInfo [join $errList \n]
          return -code error -errorinfo $newErrorInfo $errMsg
        }
        2 {
          # Return
          return -code return $errMsg
        }
        3 {
          # Break
        }
        4 {
          # Continue
        }
      }

      # todo add fixing of error_info stack to remove __real4trace_
      #      stuff.
      return $result
    }
  }

  if { $clear } {
    debug 3 "removing wrapper for command $cmdName"

    # undefine the wrapper proc and move the original back
    if { [string equal [@@info command ::__real4trace_${cmdName}] ""] } {
      tracelog::print_message $::tracelog::_ERROR "tracelog cannot find real command ::__real4trace_${cmdName} to remove wrapper"
    } else {
      uplevel #0 rename -force $cmdName {""}
      uplevel #0 rename -force  __real4trace_${cmdName} $cmdName
    }
  } else {

    debug 3 "defining wrapper for command $cmdName"
    # substitue the PROCNAME, CMDNAME, and BASECMDNAME into the template
    set cmd $procTemplate
    regsub -- {BASECMDNAME} $cmd $cmdName cmd
    regsub -- {CMDNAME} $cmd __real4trace_${cmdName} cmd
    regsub -- {PROCNAME} $cmd ${cmdName} cmd
    # rename the command to be __real4trace_<cmd>
    uplevel #0 rename -force $cmdName __real4trace_${cmdName}

    # now define the new proc with the original command name that 
    # calls that command as well as does the logging
    uplevel #0 $cmd
  }

}

#-------------------------------------------------------------------------------
#
# Return the commands returned by the help command into an array that is
# indexed by the command group they belong in.
#
proc tracelog::get_commands_by_group { cmdsByGroupArrayName } {
  upvar $cmdsByGroupArrayName cmdsByGroup
  set helpOutput ""
  if { [info exists ::sh_help_shows_group_overview] } {
    set saveShHelpShowsGroupOverview $::sh_help_shows_group_overview
    set ::sh_help_shows_group_overview false
  }
  redirect -variable helpOutput {help}
  if { [info exists saveShHelpsShowGroupOverview ] } {
    set ::sh_help_shows_group_overview $saveShHelpShowsGroupOverview
  }
  set group ""
  foreach line [split $helpOutput "\n"] {
    if { [string is space $line] } {
      set group ""
      continue
    }
    if { [string equal $group ""] } {
      set group [regsub {^(.*):.*$} $line {\1}]
      continue
    }
    if { ![info exists cmdsByGroup($group)] } {
      set cmdsByGroup($group) ""
    }
    set oneLineOfCmds [eval concat [split $line " ,"]]
    set cmdsByGroup($group) [concat $cmdsByGroup($group) $oneLineOfCmds]
  }
  return
}


#-------------------------------------------------------------------------------
#
# Setup command traces
#
# Determines which commands to trace by using help command output to find
# public application commands.  Procedures are only included if they have 
# help support for them. Tcl Builtins are not traced.
#
# The package variables _skipCmds and _moreCmds can be used to modify this
# default set of commands being traced.
#
proc tracelog::setup_command_traces { {clearTraces 0} } {
  variable _cmdsByGroup
  debug 1 "enter setup_command_traces clear = $clearTraces"

  if { ![array size _cmdsByGroup] } {
    get_commands_by_group _cmdsByGroup
  }

  array set wrappedCmds [array get ::tracelog::_skipCmds]

  # force the skipping of commands with custom wrappers since we 
  # manually wrap that at the end
  set customWrapperCmds {append_to_collection foreach_in_collection redirect read_sdc load_upf}
  set foundCustomWrapperCmds ""
  foreach cmd $customWrapperCmds {
    if { ![string equal [@@info command ::$cmd] ""] } {
      set wrappedCmds($cmd) 1
      lappend foundCustomWrapperCmds $cmd
    }
  }
  set customWrapperCmds $foundCustomWrapperCmds

  # wrap the commands skipping Procedures and Builtins
  foreach group [array names _cmdsByGroup] {
    if { ![info exists tracelog::_skipCmdsInHelpGroups($group)] } {
      foreach cmd $_cmdsByGroup($group) {
        if { [string equal [@@info command ::$cmd] ""] } {
          tracelog::print_message $::tracelog::_WARN "command $cmd does not exist - it will not be wrapped by tracelog"
        } else {
          if { ! [info exists wrappedCmds($cmd)] } {
            if { [catch {wrap_command $cmd $clearTraces} msg] } {
              if { ! $clearTraces } {
                set warn "could not wrap command $cmd because\n"
                append warn "         $msg\n"
                append warn "         The trace will not trace this command."
                tracelog::print_message  $::tracelog::_WARN $warn
              }
            } else {
              set wrappedCmds($cmd) $group 
            }
          }
        }
      }
    }
  }

  # a few of the builtins are important for replay
  # so manually specify them
  foreach cmd $::tracelog::_moreCmds {
    if { ![info exists wrappedCmds($cmd)] } {
      if { [string equal [@@info command ::${cmd}] ""] } {
        tracelog::print_message  $::tracelog::_WARN "Could not wrap command $cmd specified in ::tracelog::_moreCmds because it does not exist."
        # remove the command from the list so that it doesn't complain on stop
        set p [lsearch -exact $::tracelog::_moreCmds $cmd]
        set ::tracelog::_moreCmds [lreplace $::tracelog::_moreCmds $p $p]
      } else {
        wrap_command $cmd $clearTraces
        set wrappedCmds($cmd) $group 
      }
    }
  }

  #
  # Replace the implementation of collection routines that work on pass by
  # reference.
  #
  if { $clearTraces } {
    foreach cmd $customWrapperCmds {
      debug 3 "removing custom for command $cmd"
      uplevel #0 rename -force $cmd tracelog__${cmd}
      uplevel #0 rename -force __real4trace_${cmd} $cmd
    }
  } else {
    foreach cmd $customWrapperCmds {
      debug 3 "defining custom wrapper for command $cmd"
      uplevel #0 rename -force $cmd __real4trace_${cmd}
      uplevel #0 rename -force tracelog__${cmd} $cmd
    }
  }

  debug 1 "leave setup_command_traces clear = $clearTraces"
}

#-------------------------------------------------------------------------------
#
# load_upf seems sensitive to the wrappers for tracelog -- work around this by
# having a tracelog wrapper for load_upf which removes all of the wrappers before
# running load_upf and then runs it and then re-creates the wrappers.
#
proc tracelog__load_upf { args } {
  set args [linsert $args 0 load_upf]
  set args [linsert $args 0 "tracelog::eval_cmd_without_traces"]
  uplevel $args
}
define_proc_attributes tracelog__load_upf -hidden

#-------------------------------------------------------------------------------
#
# read_sdc seems sensitive to the wrappers for tracelog -- work around this by
# having a tracelog wrapper for read_sdc which removes all of the wrappers before
# running read_sdc and then runs it and then re-creates the wrappers.
#
proc tracelog__read_sdc { args } {
  set args [linsert $args 0 read_sdc]
  set args [linsert $args 0 "tracelog::eval_cmd_without_traces"]
  uplevel $args
}
define_proc_attributes tracelog__read_sdc -hidden

#-------------------------------------------------------------------------------
#
# run_signoff wraps a number of built-in commands, so we will re-wrap the commands
# after it runs to ensure we have the correct layer of commands wrapped
#
proc tracelog__run_signoff { args } {
  set args [linsert $args 0 run_signoff]
  set args [linsert $args 0 "tracelog::eval_cmd_without_traces"]
  uplevel $args
}
define_proc_attributes tracelog__run_signoff -hidden

#-------------------------------------------------------------------------------
#
# Evaluate the specified command after removing the traces and then re-starting 
# them when it completes. 
#
proc tracelog::eval_cmd_without_traces { args } {

  set doTrace 0
  if { ! $::tracelog::_inTracedCmd } {
    set doTrace 1
  }
  set ::tracelog::_inTracedCmd 1

  # we will re-execute the cmd after this wrapper has been removed
  set cmd [lindex $args 0]

  # remove all of the tracelog command traces
  ::tracelog::debug 1 "tracelog::eval_cmd_without_traces for $cmd removing command traces"
  ::tracelog::setup_command_traces 1

  if { $doTrace } {
    ::tracelog::print_cmd_trace $args "" 1
  }

  ::tracelog::debug 1 "tracelog::eval_cmd_without_traces invoking original $cmd command"
  set result ""

  set rc [catch {set result [uplevel $args]} errMsg]
  set savedInfo $::errorInfo

  if { $doTrace } {
    ::tracelog::print_cmd_trace $args $result 
    set ::tracelog::_inTracedCmd 0
  }

  # now put them back 
  ::tracelog::debug 1 "tracelog::eval_cmd_without_traces for $cmd restoring command traces"
  ::tracelog::setup_command_traces 

  switch -exact -- $rc {
    0 {
      # OK
    }
    1 {
      # Error
      set thisCmdStack [lreplace [info level 0] 0 0 $cmd]
      # Error - clean up the stack trace to skip this wrapper
      set errList [split $savedInfo \n]
      set errList [lrange $errList 0 [expr {[llength $errList] - [llength [split $thisCmdStack \n]] - 5}]]
      set newErrorInfo [join $errList \n]
      return -code error -errorinfo $newErrorInfo $errMsg
    }
    2 {
      # Return
      return -code return $errMsg
    }
    3 {
      # Break
      return 
    }
    4 {
      # Continue
    }
  }
  return $result
}

#-------------------------------------------------------------------------------
#
# A Tcl override of redirect so that we can properly trace the command
# but unlike other traces, also trace the commands called within the 
# redirect.
#
# Note that > redirect is not traced in this manner since
#
# We don't log most control constructs, but since this one impacts
# the execution behavior of the application commands we will log it.
#
proc tracelog__redirect { args } {

  # create the real redirect command
  # and the original application cmd being executed
  set cmd [linsert $args 0 __real4trace_redirect]
  set logcmd [linsert $args 0 redirect]


  # don't do nested tracing if a higher level command is already
  # traced and is calling redirect under the hood
  set doTrace 1
  if { $::tracelog::_inTracedCmd } {
    set doTrace 0
  }

  if { $doTrace } {
    # get the current position in the logfile since we are going to seek back here when the command
    # completes to get the proper log entry generated.
    set preLogPosition [tell $::tracelog::_logFile]

    # just to be sure - make sure that the seeking here isn't going to mess with the other logging
    if { $::tracelog::_preLogPosition > 0 } {
      tracelog::print_message $::tracelog::_ERROR "Internal Error: redirect called in the middle of a traced command execution at log position $::tracelog::_preLogPosition"
    }

    #echo "preLogPosition is $preLogPosition"

    # log the part of redirect without the code
    ::tracelog::print_trace $logcmd
    set nestedCmdsLogPosition [tell $::tracelog::_logFile]
    #echo "nestedCmdsLogPosition is $nestedCmdsLogPosition"
  }

  # note the current log file end -- everthing logged after this is inside the redirect
  # and will need to be part of the args when the final logging is done.

  # execute the command
  set result ""
  set rc [catch {set result [uplevel $cmd]} errMsg]
  set savedInfo $::errorInfo

  if { $doTrace } {
    set postCmdPos [tell $::tracelog::_logFile]
    #echo "position after cmd exec is $postCmdPos"

    # replace the redirect body with the commands that were logged when executing the body

    set logcmd "redirect"
    set pos 1
    foreach opt $args {
      switch -glob -- $opt {
        -*  {
          lappend logcmd $opt
        }
        default {
          if { $pos < 2 } {
            lappend logcmd $opt
            incr pos
          }
        }
      }
    }
    #echo "base redirect cmd is $logcmd"

    #echo "seek to $nestedCmdsLogPosition"
    seek $::tracelog::_logFile $nestedCmdsLogPosition
    set nestedCmds [read $::tracelog::_logFile]
    append logcmd " \{\n" $nestedCmds "\}"

    # relog the redirect with the properly expanded logged commands
    seek $::tracelog::_logFile $preLogPosition
    #echo "seek to $preLogPosition"
    if { [::tracelog::is_collection $result] } {
      ::tracelog::print_trace "set $result \[$logcmd\]"
      if { $::tracelog::_suppressUntracedClct } {
        set ::tracelog::_tracedCollections($result) 1
      }
    } else {
      ::tracelog::print_trace "$logcmd"
    }

    #echo "logging trace of $logcmd"

    set finalPos [tell $::tracelog::_logFile]
    #echo "position after final logging is $finalPos"

    while { $finalPos < $postCmdPos } {
      if { $finalPos+1 == $postCmdPos } {
        puts $::tracelog::_logFile ""
      }  else {
        puts -nonewline $::tracelog::_logFile " "
      }
      incr finalPos
    }
    #echo "position after cleanup is [tell $::tracelog::_logFile]"
  }

  # properly pass along the value
  switch -exact -- $rc {
    0 {
      # OK
    }
    1 {
      # Error
      set thisCmdStack [lreplace [info level 0] 0 0 "redirect"]
      # Error - clean up the stack trace to skip this wrapper
      set errList [split $savedInfo \n]
      set errList [lrange $errList 0 [expr {[llength $errList] - [llength [split $thisCmdStack \n]] - 5}]]
      set newErrorInfo [join $errList \n]
      return -code error -errorinfo $newErrorInfo $errMsg
    }
    2 {
      # Return
      return -code return $errMsg
    }
    3 {
      # Break
      return 
    }
    4 {
      # Continue
    }
  }
  return $result
}
define_proc_attributes tracelog__redirect -hidden

#-------------------------------------------------------------------------------
#
# A Tcl override of append_to_collection so that we can properly catch
# the updating of the collection variable.
#
# This proc converts the operation to use add_to_collection which can properly
# be traced by tracelog, so this proc itself isn't part of the trace.
#
proc tracelog__append_to_collection { args } {
  set options(-unique) 0 
  parse_proc_arguments -args $args options
  upvar $options(var_name) var
  set clct $options(object_spec)
  if { ![info exists var] } {
    if { $options(-unique) } {
      set var [add_to_collection -unique $clct ""]
    } else {
      set var $clct
    }
  } else {
    if { $options(-unique) } {
      set var [add_to_collection -unique $var $clct]
    } else {
      set var [add_to_collection $var $clct]
    }
  }
  return $var
}
define_proc_attributes tracelog__append_to_collection -hidden -define_args {
     {-unique "Remove duplicates from the result" "" boolean optional}
     {var_name "Variable holding the collection" "" string required}
     {object_spec "Object(s) to add" "" string required}
} 



#-------------------------------------------------------------------------------
#
# A Tcl override of foreach_in_collection so that we can properly catch
# the generation of the collection handles in the unrolled loop. The 
# default passes the loop variable by reference, which is a problem.
# This impl uses index_collection which is wrapped and can be logged.
#
# This is actually a control construct so it is intentionally not
# logging itself.  However, the index_collection calls for the
# unrolling of the loop will be logged.
#
proc tracelog__foreach_in_collection { iter_var collections body } {
  upvar $iter_var var
  set numClct [llength $collections]
  set clctListIdx 0
  set result ""
  while {$clctListIdx < $numClct} {
    set clct [lindex $collections $clctListIdx]
    set numItems [sizeof_collection $clct]
    set idx 0
    while { $idx < $numItems } {
      set result ""
      set var [index_collection $clct $idx]
      set rc [catch {set result [uplevel $body]} errMsg]
      set savedInfo $::errorInfo
      switch -exact -- $rc {
        0 {
          # OK
        }
        1 {
          # Error
          set thisCmdStack [lreplace [info level 0] 0 0 "foreach_in_collection"]
          # Error - clean up the stack trace to skip this wrapper
          set errList [split $savedInfo \n]
          set errList [lrange $errList 0 [expr {[llength $errList] - [llength [split $thisCmdStack \n]] - 5}]]
          set newErrorInfo [join $errList \n]
          return -code error -errorinfo $newErrorInfo $errMsg
        }
        2 {
          # Return
          return -code return $errMsg
        }
        3 {
          # Break
          return 
        }
        4 {
          # Continue
        }
      }
      incr idx
    }
    incr clctListIdx
  }
  return $result
}
define_proc_attributes tracelog__foreach_in_collection -hidden

#-------------------------------------------------------------------------------
#
# application variable trace callback
#
# Callback for a Tcl trace which writes changes to the application variables to
# the trace file.
#
proc tracelog::do_variable_trace { varname aliasedVarname subscript op  } {
  if { $::tracelog::_inTracedCmd } {
    # don't trace variables manipulated under the hood for application commands
    return
  }
  debug 1 "do_variable_trace $varname $subscript $op"

  # todo: need to add code to handle resolution for names which may have been aliased due
  #       to upvar
  if { [string equal $op "write"] } {
    upvar ::${varname} var
    if { [string equal $subscript ""] } {
      set cmd "set $varname [list $var]"
    } else { 
      set cmd "set $varname\($subscript\) [list $var($subscript)]"
    }
    print_trace $cmd
    if { $::tracelog::_echoCmds } {
      print_to_console ";## $cmd"
    }
  } elseif { [string equal $op "unset"] } {
    if { [string equal $subscript ""] } {
      set var "$varname"
    } else { 
      set var "$varname\($subscript\)"
    }
    set cmd "unset $var"
    print_trace $cmd
    if { $::tracelog::_echoCmds } {
      print_to_console ";## $cmd"
    }
    tracelog::wrap_variable $var
  }

  return
}


#-------------------------------------------------------------------------------
#
# trace a given global variable
#
proc tracelog::wrap_variable { varname {clearTraces 0} } {
  debug 3 "wrap_variable $varname clear = $clearTraces"

  if { [array exists ::$varname] } {
    debug 1 "wrap_variable ::$varname skipped because it is an array"
    return 
  }

  if { [info exists ::tracelog::_skipVars($varname)] } {
    debug 1 "wrap_variable $varname skipped because it is in _skipVars"
    return
  }

  set traceOp add
  if { $clearTraces } {
    set traceOp remove
  } 
  trace $traceOp variable ::${varname} {write unset} "tracelog::do_variable_trace ${varname}"
  debug 3 "wrap_variable trace $varname clear = $clearTraces done"
}

#-------------------------------------------------------------------------------
#
# Setup application variable traces
#
# Use printvar -application to get the list of application variables and then
# setup Tcl traces to allow us to track and log changes to their values.
#
proc tracelog::setup_variable_traces { {clearTraces 0} } {
  debug 1 "enter setup_variable_traces clear=$clearTraces"
  array set wrappedVars {}
  set appVarList {} 
  # there is a problem with printvar not working at other than 
  # global scope -- work around it
  debug 1 "      setup_variable_traces getting app vars"
  redirect -variable appVarList {namespace eval :: {printvar -application}}
  debug 1 "      setup_variable_traces got app vars"
  foreach varEntry [split $appVarList "\n"] {
    set varname [regsub {(\w+)\s*=.*} $varEntry {\1}]
    if { ![string equal $varname ""] } {
      wrap_variable $varname $clearTraces
      set wrappedVars($varname) 1
    }
  }

  # a few of the builtins are important for replay
  # so manually specify them
  foreach varname $::tracelog::_moreVars {
    if { ![info exists wrappedVars($varname)] } {
      wrap_variable $varname $clearTraces
      set wrappedVars($varname) 1
    }
  }

  # enable this work-around for allowing a replayable log
  if { $::tracelog::_traceAllGlobalsVars } {
    foreach varname $::tracelog::_globalVarsToTrace {
      if { ![info exists wrappedVars($varname)] } {
        wrap_variable $varname $clearTraces
        set wrappedVars($varname) 1
      }
    }
  }
  debug 1 "leave setup_variable_traces clear=$clearTraces"
}

#-------------------------------------------------------------------------------
#
# cache a list of all of the global variables in the _globalVarsToTrace 
# this is used to setup traces if _traceAllGlobalVars is enabled
#
proc tracelog::initialize_global_vars_to_trace {} {
  set tracelog::_globalVarsToTrace [uplevel #0 info vars]
}

#-------------------------------------------------------------------------------
#
# Initialization done at the time the package is loaded to build the list of
# commands and global vars that may be traced.
#
proc tracelog::initialze_commands_and_global_vars {} {
   get_commands_by_group ::tracelog::_cmdsByGroup
   initialize_global_vars_to_trace
   return ""
}

#-------------------------------------------------------------------------------
#
# Write a header into the trace log to check to ensure it isn't re-played without
# being run through the tracelog-postprocess.pl script.
#
proc tracelog::print_log_header {} {
  print_trace "#tracelog-filter-check-begin"
  print_trace {
    echo {Error: Before replaying this log it must be run through tracelog-postprocess.pl}
    exit
  }
  print_trace "#tracelog-filter-check-end"
  print_trace "#-------------------------------------------------------------------------------"
  print_trace "# Synopsys Application Trace Log for ${::synopsys_program_name} $::sh_product_version"
  print_trace "# Generated: [clock format [clock scan now] -format {%Y.%m.%d-%H:%M}]"
  print_trace "#            tracelog version $tracelog::_version"
  print_trace "#"
  print_trace "# Tracelog does not guarantee 100% replayability, and may not re-execute"
  print_trace "# exactly what was run originally in all situations."
  print_trace "#-------------------------------------------------------------------------------"
}

#-------------------------------------------------------------------------------
#
# suspend logging without closing the log file
#
proc tracelog::suspend { args } {
  parse_proc_arguments -args $args options
  if { [string equal $::tracelog::_logFile "" ] } {
    tracelog::print_message $::tracelog::_ERROR "Tracing not enabled."
    return
  }
  if { $::tracelog::_inSuspend } {
    tracelog::print_message $::tracelog::_ERROR "tracing already suspended"
    return
  }
  if { $::tracelog::_inTracedCmd } {
    tracelog::print_message $::tracelog::_ERROR "cannot suspend tracing while executing a traced command"
    return
  }
  setup_command_traces 1
  setup_variable_traces 1
  set ::tracelog::_inSuspend 1
}
define_proc_attributes ::tracelog::suspend -dont_abbrev -info "resume trace logging after suspending it." -define_args {
} -command_group $::tracelog::_tracelogCmdGroup 

#-------------------------------------------------------------------------------
#
# resume logging after it was suspended with tracelog::suspend
#
proc tracelog::resume { args } {
  parse_proc_arguments -args $args options
  if { [string equal $::tracelog::_logFile "" ] } {
    tracelog::print_message $::tracelog::_ERROR "Tracing not enabled."
    return
  }
  if { ! $::tracelog::_inSuspend } {
    tracelog::print_message $::tracelog::_ERROR "tracing not currently suspended"
    return
  }
  if { $::tracelog::_inTracedCmd } {
    tracelog::print_message $::tracelog::_ERROR "cannot resume tracing while executing a traced command"
    return
  }
  setup_variable_traces 
  setup_command_traces 
  set ::tracelog::_inSuspend 0
}
define_proc_attributes ::tracelog::resume -dont_abbrev -info "resume trace logging after suspending it." -define_args {
} -command_group $::tracelog::_tracelogCmdGroup 

#-------------------------------------------------------------------------------
#
# Enable Tracing of Application commands and variables
#
# This procedure does setup and 
#
proc tracelog::start { args } {
  array set options {}
  parse_proc_arguments -args $args options
  set filename $options(-file) 

  # don't allow mutliple starts
  if { ![string equal $::tracelog::_logFile "" ] } {
    tracelog::print_message $::tracelog::_ERROR "Tracing already enabled. Log file is $::tracelog::_logFileName"
    return
  }
  if { [string equal $filename ""] } {
    tracelog::print_message $::tracelog::_ERROR "must specify a file name for the trace log file"
    return
  }
  # open the log file
  if { [catch {set ::tracelog::_logFile [open $filename w+]} msg] == 1} {
    tracelog::print_message $::tracelog::_ERROR "$msg"
    set ::tracelog::_logFile ""
    return
  }
  fconfigure $::tracelog::_logFile -buffering line
  print_log_header
  set ::tracelog::_logFileName $filename
  setup_variable_traces
  setup_command_traces
  tracelog::print_message $::tracelog::_INFO "Application command trace set to file $filename."
}
define_proc_attributes ::tracelog::start -dont_abbrev -info "start trace logging" -define_args {
     {-file "string specifying the file to contain the tracelog" "" string optional}
} -command_group $::tracelog::_tracelogCmdGroup 

#-------------------------------------------------------------------------------
#
# Turn off Tracing of Application commands and variables and close the log file
#
proc tracelog::stop { args } {
  parse_proc_arguments -args $args options
  if { [string equal $::tracelog::_logFile "" ] } {
    tracelog::print_message $::tracelog::_ERROR "Tracing not enabled."
    return
  }
  tracelog::print_message $::tracelog::_INFO "Closed trace log file $::tracelog::_logFileName."
  # close the log file and cleanup the traces
  close $::tracelog::_logFile
  set ::tracelog::_logFile ""
  set ::tracelog::_logFileName ""
  setup_command_traces 1
  setup_variable_traces 1
}
define_proc_attributes ::tracelog::stop -dont_abbrev -info "stop trace logging and close the log" -define_args {
} -command_group $::tracelog::_tracelogCmdGroup 

#-------------------------------------------------------------------------------
#
# modify the tracelog options
#
proc tracelog::set_options { args } {
  array set options {}
  parse_proc_arguments -args $args options
  if { ![string equal $::tracelog::_logFile "" ] } {
    tracelog::print_message $::tracelog::_ERROR "Tracing is already started. Tracing options must be set before starting a trace log."
    return
  }
  if { [info exists options(-echo_cmds)] } {
    if { [string equal $options(-echo_cmds) "on"] } {
      set ::tracelog::_echoCmds 1
    } else {
      set ::tracelog::_echoCmds 0
    }
  }
  if { [info exists options(-suppress_unknown_clct)] } {
    if { [string equal $options(-suppress_unknown_clct) "on"] } {
      set ::tracelog::_suppressUntracedClct 1
    } else {
      set ::tracelog::_suppressUntracedClct 0
    }
  }
  if { [info exists options(-echo_cmds_with_performance)] } {
    if { [string equal $options(-echo_cmds_with_performance) "on"] } {
      set ::tracelog::_echoPerformance 1
    } else {
      set ::tracelog::_echoPerformance 0
    }
  }
  if { [info exists options(-variable_trace_type)] } {
    if { [string equal $options(-variable_trace_type) "application"] } {
      set ::tracelog::_traceAllGlobalsVars 0
    } else {
      set ::tracelog::_traceAllGlobalsVars 1
    }
  }
  if { [info exists options(-performance_echo_cpu_threshold)] } {
    set ::tracelog::_echoPerformanceThreshold $options(-performance_echo_cpu_threshold)
  }
  if { [info exists options(-trace_commands)] } {
    set ::tracelog::_moreCmds [concat $::tracelog::_moreCmds $options(-trace_commands)]
  }
  if { [info exists options(-trace_variables)] } {
    set ::tracelog::_moreVars [concat $::tracelog::_moreVars $options(-trace_variables)]
  }
  if { [info exists options(-dont_trace_commands)] } {
    foreach cmd $options(-dont_trace_commands) {
      set ::tracelog::_skipCmds($cmd) 1
    }
  }
  if { [info exists options(-dont_trace_variables)] } {
    foreach var $options(-dont_trace_variables) {
      set ::tracelog::_skipVars($var) 1
    }
  }
}
define_proc_attributes ::tracelog::set_options -dont_abbrev -info "modify the tracelog options" -define_args {
  {-echo_cmds "echo commands as they are traced to stdout" bool_val one_of_string {optional  value_help {values {on off}} }}
  {-echo_cmds_with_performance "add time/memory/cpu to echo'd commands" bool_val one_of_string {optional  value_help {values {on off}} }}
  {-performance_echo_cpu_threshold "cpu limit exceeded to get performance echo'd" int_val int {optional} }
  {-variable_trace_type "determine what variables are traced" trace_type one_of_string {optional  value_help {values {application all_global}} }}
  {-trace_commands "specify a list of additional commands that should be traced" list_of_cmds string {optional}}
  {-dont_trace_commands "specify a list of commands that should not be traced" list_of_cmds string {optional}}
  {-trace_variables "specify a list of additional variables that should be traced" list_of_vars string {optional}}
  {-dont_trace_variables "specify a list of variables that should not be traced" list_of_vars string {optional}}
  {-suppress_unknown_clct "for clct that were not traced - don't log commands that use them - hide gui internals" bool_val one_of_string {optional  value_help {values {on off}} }}
} -command_group $::tracelog::_tracelogCmdGroup 

# also setup some ICC-specific fixes for convention violations
tracelog::icc_fix_conventions

#-------------------------------------------------------------------------------
# when the package is loaded, cache the set of app commands and 
# variables to be processed
tracelog::initialze_commands_and_global_vars
