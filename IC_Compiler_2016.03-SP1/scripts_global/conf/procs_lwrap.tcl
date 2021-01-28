## -----------------------------------------------------------------------------
## HEADER $Id: //sps/flow/ds/scripts_global/conf/procs_lwrap.tcl#5 $
## HEADER_MSG    Lynx Design System: Production Flow
## HEADER_MSG    Version 2015.06-SP1
## HEADER_MSG    Copyright (c) 2015 Synopsys
## HEADER_MSG    Perforce Label: lynx_flow_2015.06-SP1
## HEADER_MSG
## -----------------------------------------------------------------------------
## DESCRIPTION:
## * These are procedures for a Lynx-specific version of "enwrap".
## -----------------------------------------------------------------------------

proc lwrap_prefix { body tag } {
  global LYNX

  set index ${tag}_prefix
  set LYNX(lwrap,$index) $body
}

proc lwrap_postfix { body tag } {
  global LYNX

  set index ${tag}_postfix
  set LYNX(lwrap,$index) $body
}

proc lwrap_replace { body tag } {
  global LYNX

  set index ${tag}_replace
  set LYNX(lwrap,$index) $body
}

proc lwrap_run { body tag } {
  global LYNX

  set index_prefix  ""
  set index_replace ""
  set index_postfix ""

  foreach index [lsort [array names LYNX -glob lwrap,*]] {

    set overrideTag [regsub {lwrap,} $index {}]

    if { [string match $overrideTag ${tag}_prefix] } {
      set index_prefix $overrideTag
    }
    if { [string match $overrideTag ${tag}_replace] } {
      set index_replace $overrideTag
    }
    if { [string match $overrideTag ${tag}_postfix] } {
      set index_postfix $overrideTag
    }

  }

  if { $index_prefix != "" } {
    puts "SNPS_INFO   : LWRAP_PREFIX_START : $tag"
    set theCmd "\$\{LYNX(lwrap,$index_prefix)\}"
    uplevel 1 eval $theCmd
    puts "SNPS_INFO   : LWRAP_PREFIX_STOP : $tag"
  }

  if { $index_replace != "" } {
    puts "SNPS_INFO   : LWRAP_REPLACE_START : $tag"
    set theCmd "\$\{LYNX(lwrap,$index_replace)\}"
    uplevel 1 eval $theCmd
    puts "SNPS_INFO   : LWRAP_REPLACE_STOP : $tag"
  } else {
    uplevel 1 $body
  }

  if { $index_postfix != "" } {
    puts "SNPS_INFO   : LWRAP_POSTFIX_START : $tag"
    set theCmd "\$\{LYNX(lwrap,$index_postfix)\}"
    uplevel 1 eval $theCmd
    puts "SNPS_INFO   : LWRAP_POSTFIX_STOP : $tag"
  }
}

proc lwrap_report {} {
  global LYNX

  puts "The defined lwrap overrides are:"
  foreach index [lsort [array names LYNX -glob lwrap,*]] {
    set overrideTag [regsub {lwrap,} $index {}]
    puts "  $overrideTag"
  }
  puts "<end of lwrap overrides>"
}

## -----------------------------------------------------------------------------
## End Of File
## -----------------------------------------------------------------------------
