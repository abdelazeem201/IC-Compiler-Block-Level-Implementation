## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/rtm_init_js_lsf.tcl#81 $
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
## rtm_job_cmd:
## -----------------------------------------------------------------------------

proc rtm_job_cmd { args } {

  global env SEV SVAR TEV

  set options(-aro_enable)             $SEV(aro_enable)
  set options(-job_enable)             $SEV(job_enable)
  set options(-job_app)                $SEV(job_app)
  set options(-job_queue)              ""
  set options(-job_options)            $SEV(job_options)
  set options(-job_resources)          $SEV(job_resources)
  set options(-job_num_cores)          1
  set options(-job_misc1)              $SEV(job_misc1)
  set options(-job_misc2)              $SEV(job_misc2)
  set options(-job_misc3)              $SEV(job_misc3)
  set options(-job_misc4)              $SEV(job_misc4)
  set options(-gui)                    0
  set options(-interactive)            0
  set options(-rtm_check_only)         0
  set options(-log_file)               ""
  set options(-sh_file)                ""
  set options(-jid_file)               ""
  set options(-tool)                   ""

  parse_proc_arguments -args $args options

  if { $options(-log_file) == "" } {
    return -code error "rtm_job_cmd: Argument for -log_file not specified."
  }
  if { $options(-sh_file) == "" } {
    return -code error "rtm_job_cmd: Argument for -sh_file not specified."
  }

  if { $options(-rtm_check_only) } {
    set options(-tool) tcl
  }

  ## -------------------------------------
  ## The argument for -log_file must be the absolute path to the log file.
  ## -------------------------------------

  set log_file_absolute [file normalize $options(-log_file)]

  set name(all)     [split $log_file_absolute /]
  set name(log)     [lindex $name(all) end-0]
  set name(dst)     [lindex $name(all) end-1]
  set name(step)    [lindex $name(all) end-3]
  set name(block)   [lindex $name(all) end-4]
  set name(techlib) [lindex $name(all) end-5]
  set name(work)    [lindex $name(all) end-7]
  set name(task)    [file rootname $name(log)]

  set log_file_relative ../logs/$name(dst)/$name(log)

  ## -------------------------------------
  ## Specify project_name and job_name
  ## -------------------------------------

  set project_name $SEV(project_name)

  set job_name LYNX:$name(techlib)/$name(block)/$name(step)/$name(dst)/$name(task)

  ## Some job distribution systems disallow specific characters.
  ## in the job name.  The following code replaces those characters.

  set job_name [regsub -all {:} $job_name {#}]
  set job_name [regsub -all {/} $job_name {#}]

  ## -------------------------------------
  ## Define some file references
  ## -------------------------------------

  set file_part_org [file tail $log_file_absolute]
  set dir_part_org  [file dirname $log_file_absolute]

  set file_part_new .[file rootname $file_part_org].pid
  set pid_file $dir_part_org/$file_part_new

  set file_part_new .[file rootname $file_part_org].js_main.log
  set js_main_log $dir_part_org/$file_part_new

  if { [info exists SEV(workarea_dir)] } {
    set wait_for_job_to_finish_script $SEV(workarea_dir)/scripts_global/conf/wait_for_job_to_finish_$SEV(job_app).tcl
  }

  set file_part_new .[file rootname $file_part_org].rtm_shell_cmd.log
  set rtm_shell_cmd_log $dir_part_org/$file_part_new

  if { $options(-rtm_check_only) } {
    set file_part_new .[file rootname $file_part_org].rtm_check_only.log
    set rtm_check_only_log $dir_part_org/$file_part_new
    set log_file_absolute $rtm_check_only_log
  }

  ## -------------------------------------
  ## The "tcl" tool_name is used to run a Tcl script without job distribution.
  ## The job distribution variables and parameters are not altered (turned off),
  ## which allows the Tcl script to distribute child jobs per the normal job settings.
  ## -------------------------------------

  if { $options(-tool) == "tcl" } {
    set options(-job_enable) 0
  }

  ## -------------------------------------
  ## Local execution is an optimization available if:
  ## - Job distribution is enabled
  ## - SEV(job_misc2) is set to "local_exec:<num_cores>:<min_mem_mb>:<min_swap_mb>"
  ## -------------------------------------

  if { $options(-job_enable) && [regexp {^local_exec:(\d+):(\d+):(\d+)$} $options(-job_misc2) match cpu mem swap] } {
    set result [rtm_host_query -cpu_cores $options(-job_num_cores) -max_cpu_limit $cpu -min_mem_free $mem -min_swap_free $swap -pid_file $pid_file]
    if { $result == "HOST_IDLE" } {
      set options(-aro_enable) 0
      set options(-job_enable) 0
    }
  }

  ## -------------------------------------
  ## Create sh_part
  ## -------------------------------------

  set window_name LYNX:$name(block)/$name(step)/$name(dst)/$name(task)

  if { $options(-interactive) || $options(-gui) } {
    ## PREVIOUS_CODE set sh_part "xterm -T $window_name -e $SEV(exec_cmd) -c \". $options(-sh_file) 2>&1 | tee $log_file_absolute\""
    set sh_part "xterm -T $window_name -e $SEV(exec_cmd) -c \". $options(-sh_file)\""
  } else {
    ## PREVIOUS_CODE set sh_part "$SEV(exec_cmd) -c \"echo BEGIN_RTM_SHELL_CMD; . $options(-sh_file) > $log_file_absolute 2>&1; echo END_RTM_SHELL_CMD\""
    set sh_part "$SEV(exec_cmd) -c \"echo BEGIN_RTM_SHELL_CMD; . $options(-sh_file); echo END_RTM_SHELL_CMD\""
  }

  set sh_part "$sh_part > $rtm_shell_cmd_log 2>&1"

  ## -------------------------------------
  ## Create job_part
  ## -------------------------------------

  if { $options(-job_enable) } {

    ## -------------------------------------
    ## Determine queue
    ## -------------------------------------

    if { $options(-job_queue) != "" } {
      set queue $options(-job_queue)
    } else {
      if { $options(-interactive) } {
        set queue $SEV(job_queue_interactive)
      } else {
        set queue $SEV(job_queue_batch)
      }
    }

    ## -------------------------------------
    ## Determine the remaining job distribution options.
    ## -------------------------------------

    switch $options(-job_app) {

      lsf {

        ## -------------------------------------
        ## Determine base command
        ## -------------------------------------

        if { $options(-aro_enable) } {
          if { $options(-job_misc3) == "-aro_no_opt" } {
            set job_part "$SEV(gscript_dir)/conf/aro_sub_lsf -aro_server $SEV(aro_server) -aro_port $SEV(aro_port) -aro_no_opt 1"
          } else {
            set job_part "$SEV(gscript_dir)/conf/aro_sub_lsf -aro_server $SEV(aro_server) -aro_port $SEV(aro_port) -aro_no_opt 0"
          }
        } else {
          set job_part "bsub"
        }

        ## -------------------------------------
        ## Batch/Interactive options
        ## -------------------------------------

        if { $options(-interactive) } {
          set job_part "$job_part -o /dev/null"
        } else {
          set job_part "$job_part -o /dev/null"
        }

        ## -------------------------------------
        ## Determine options
        ## -------------------------------------

        set job_opts $options(-job_options)

        set job_res $options(-job_resources)

        if { $options(-job_num_cores) > 1 } {
          set job_opts "$job_opts -n $options(-job_num_cores)"
          set job_res "$job_res span((hosts=1))"
        }

        if { $job_res != "" } {
          set job_opts "$job_opts -R '$job_res'"
        }

        ## -------------------------------------
        ## Square brackets in Tcl have special meaning.
        ## Their usage as normal characters in Tcl is problematic.
        ## For this reason, we use alternate characters that are Tcl-friendly.
        ##   "((" is used to represent "[".
        ##   "))" is used to represent ")".
        ## These special characters need to be mapped
        ## back into square brackets for the final result.
        ## -------------------------------------

        set job_opts [regsub -all {\(\(} $job_opts {[}]
        set job_opts [regsub -all {\)\)} $job_opts {]}]

        ## -------------------------------------
        ## Create final command
        ## -------------------------------------

        ## Create the command

        set cmd "$job_part -P $project_name -J $job_name -q $queue $job_opts '$sh_part'"

        if { $options(-jid_file) == "" } {
          set cmd "$cmd &> $js_main_log && $wait_for_job_to_finish_script -queue_name $SEV(job_queue_sync) -log_file $log_file_absolute -job_name $job_name -project_name $project_name < $js_main_log"
        } else {
          set cmd "$cmd &> $js_main_log && $wait_for_job_to_finish_script -queue_name $SEV(job_queue_sync) -log_file $log_file_absolute -job_name $job_name -project_name $project_name -jid_file $options(-jid_file) < $js_main_log"
        }

      }

      default {
        return -code error "rtm_job_cmd: Unrecognized value for -job_app"
      }

    }

  } else {

    set cmd $sh_part

  }

  return $cmd

}

define_proc_attributes rtm_job_cmd \
  -info "Customizable procedure for defining how the RTM runs tools." \
  -define_args {
  {-aro_enable             "Enable ARO job distribution" AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
  {-job_enable             "Enable job distribution"     AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
  {-job_app                "Application for job dist"    AnOos one_of_string
  {optional value_help {values { lsf }}}}
  {-job_queue              "Queue name"                  AString string optional}
  {-job_options            "Job options"                 AString string optional}
  {-job_resources          "Job resources"               AString string optional}
  {-job_num_cores          "Number of CPUs to reserve"   AInt   int optional}
  {-job_misc1              "Expansion argument"          AString string optional}
  {-job_misc2              "Expansion argument"          AString string optional}
  {-job_misc3              "Expansion argument"          AString string optional}
  {-job_misc4              "Expansion argument"          AString string optional}
  {-gui                    "Selects GUI mode"            AnOos one_of_string
  {optional value_help {values { 1 0 }}}}
  {-interactive            "Selects interactive mode"    "" boolean optional}
  {-rtm_check_only         "Only run rtm_check."         "" boolean optional}
  {-log_file               "Absolute path to Log file"   AString string required}
  {-sh_file                "Sh file"                     AString string required}
  {-jid_file               "Absolute path to JID file"   AString string optional}
  {-tool                   "Tool name"                   AString string optional}
}

## -----------------------------------------------------------------------------
## rtm_kill_cmd:
## -----------------------------------------------------------------------------

proc rtm_kill_cmd { args } {

  global env SEV SVAR TEV

  set options(-task_log_file_list) ""

  parse_proc_arguments -args $args options

  set jid_list ""
  set pid_list ""

  foreach log_file $options(-task_log_file_list) {

    ## -------------------------------------
    ## Define the jid_file and pid_file
    ## -------------------------------------

    set file_part_org [file tail $log_file]
    set dir_part_org  [file dirname $log_file]

    set file_part_new .[file rootname $file_part_org].jid
    set jid_file $dir_part_org/$file_part_new

    set file_part_new .[file rootname $file_part_org].pid
    set pid_file $dir_part_org/$file_part_new

    ## -------------------------------------
    ## Process jid_file if it exists
    ## -------------------------------------

    set lines [list]
    if { [file exists $jid_file] } {
      set fid [open $jid_file r]
      set lines [read $fid]
      close $fid
      set lines [split $lines \n]
      foreach line $lines {
        if { [regexp {^LSF_JOBID\s+(\d+)\s+EOL} $line match jid] } {
          set jid_list [concat $jid_list $jid]
        }
      }
    }

    ## -------------------------------------
    ## Process pid_file if it exists
    ## -------------------------------------

    set rtm_host [exec uname -n]

    set lines [list]
    if { [file exists $pid_file] } {
      set fid [open $pid_file r]
      set lines [read $fid]
      close $fid
      set lines [split $lines \n]
      foreach line $lines {
        if { [regexp {^PID\s+(\S+)\s+(\d+)\s+EOL} $line match app_host pid] } {
          if { $rtm_host == $app_host } {
            ## Get the PIDs for all child processes as well
            set cmd "pstree -p $pid"
            catch { exec $SEV(exec_cmd) -c "$cmd" } results
            set pids [regexp -all -inline {\(\d+\)} $results]
            set pids [regexp -all -inline {\d+} $pids]
            set pids [lsort -unique -integer -decreasing $pids]
            set pid_list [concat $pid_list $pids]
          }
        }
      }
    }

  }

  if { [llength $jid_list] > 0 } {
    set cmd "bkill $jid_list"
    puts stderr "rtm_kill_cmd: $cmd"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
  }

  if { [llength $pid_list] > 0 } {
    set cmd "kill -9 $pid_list"
    puts stderr "rtm_kill_cmd: $cmd"
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
    catch { exec $SEV(exec_cmd) -c "$cmd" } results
  }

  set retval 1
  return $retval

}

define_proc_attributes rtm_kill_cmd \
  -info "Customizable procedure for killing jobs." \
  -hidden \
  -define_args {
  {-task_log_file_list "File name" AString string required}
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
