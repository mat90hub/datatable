#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#-----------------------------------------------------------------------------
namespace eval datatable {

    namespace export format
    namespace ensemble create
    
    #-------------------------------------------------------------------------
    # datatable format ?opt? data
    #-------------------------------------------------------------------------
    # Format a dataset to display it with options.
    # 
    # The options are:
    # ----------------
    #  -data        : option way to give data (can be give as last argument otherwise)
    #  -semigraphic : data is presented in semigraphic form. (exclude -csv)
    #  -csv         : data is presented with Caracter Separating Value.
    #                 (exclude -semigraphic)
    #  -fmt {…}     : the list of formatting string fore each columns
    #  -sep "…"     : the separating character between values, default is " "
    #  -eol "…"     : possible string to add at each end of line.
    #                 (typically \\\\ for LaTeX table)
    #  -except {…}  : list of strings accepted in numeric formatting
    #  -NA {…}        (useful for exceptions strings such as 'NA' '-' 'tbd')
    #  -NonApp*
    #
    # The sign -- marks the end of options.
    #-------------------------------------------------------------------------
    # _discussion:_
    # 
    # If the formatting list is not given, it will be guessed based on type of the
    # components of a columns and their max width.
    #
    # The type of adapting too long width by FIXEDSTRING or STRICTSTRING is guessed
    # automatically by the function `datatable frame line` according to the data
    # type.
    # ------------------------------------------------------------------------
    proc format args {
	set STR "csv"
	set SEP ""
	while {[::string index $args 0] eq "-"} {
	    set WORD [lshift args]
	    switch -nocase -glob -- $WORD {
		"-sem*"   {set STR "semigraphic"}
		"-csv*"   {set STR "csv"}
		"-fmt"    {set FMT [lshift args]}
		"-sep*"   {set SEP [lshift args]}
		"-eol"    {set EOL [lshift args]}
		"-exc*" - "-NA" - "NotApplicable" {set EXCEPT [lshift args]}
		"-data"   {set DATA [lshift args]}
		"--"      {set DATA [lshift args]}
	    }
	}
	
	if ![info exists DATA] {set DATA {*}$args}
	# ::log::log debug "DATA: $DATA"
		
	# Suppress possible accolades remaining arround args
	# if {[llength $DATA] == 1} {set DATA {*}$DATA}
	
	if {[llength $DATA] == 0} {return}

	# ::log::log debug "DATA = $DATA // LEN -> [llength $DATA]"
	
	# if ![datatable isnormalized $DATA] {error "datatable format applicable for llist only."}	
	
	if [info exists FMT] {
	    if {[set FMTLN [llength $FMT]] != [set NBCOL [datatable column count $DATA]]} {
		error "$FMTLN format strings for $NBCOL columns"
	    }
	} {
	    # guess format based on wider element
	    if [info exists EXCEPT] {
		foreach LN [transpose $DATA] {lappend FMT [datatable column fmt $LN $EXCEPT]}
	    } {
		foreach LN [transpose $DATA] {lappend FMT [datatable column fmt $LN]}
	    }
	}
	# ::log::log debug "FMT = $FMT"
	
	if {$STR eq "semigraphic"} {
	    # Has priority if defined	
	    set SEP "│"
	    
	    # draw the framed datatable starting by the datatable body
	    # set BODY [lmap L $DATA {datatable frame line $FMT $L $SEP}]
	    foreach L $DATA {
		append BODY [datatable frame line $FMT $L $SEP]
	    }
	    append RES [datatable frame top $BODY]
	    append RES $BODY
	    append RES [datatable frame bottom $BODY]
	    return $RES
	} {
	    # set BODY [lmap L $DATA {datatable frame line $FMT $L $SEP $EOL}]
	    # if [dict exists $ARG eol] {set EOL [dict get $ARG eol]} {set EOL ""}
	    if [info exists EOL] {
		foreach L $DATA {    
		    append BODY [datatable frame line $FMT $L $SEP $EOL]
		}
	    } {
		foreach L $DATA {
		    # ::log::log debug "L=$L"
		    append BODY [datatable frame line $FMT $L $SEP]
		}
	    }
	    return $BODY
	}
    }
    #-------------------------------------------------------------------------
}
#-----------------------------------------------------------------------------

 
#-----------------------------------------------------------------------------
namespace eval datatable::line {
    
    namespace export format
    namespace ensemble create

    #--------------------------------------------------------------------------
    # datatable line format ?-options?  ?--? $data 
    # --------------------------------------------------------------------------
    # This procedure is an interface to the lower level procedure `datatable
    # frame line` adding all the options possible with the other formatting
    # procedures. It is formatting a single and isolated line: for semigraphic
    # option it will add the tob and bottom frame.
    #
    # The options are:
    # ----------------
    #  -data        : option way to give data (can be give as last argument otherwise)
    #  -semigraphic : data is presented in semigraphic form. (exclude -csv)
    #  -csv         : data is presented with Caracter Separating Value.
    #                 (exclude -semigraphic)
    #  -fmt {…}     : the list of formatting string fore each columns
    #  -sep "…"     : the separating character between values, default is " "
    #  -eol "…"     : possible string to add at each end of line.
    #                 (typically \\\\ for LaTeX table)
    #  -exc* {…}    : list of strings accepted in numeric formatting
    #  -NA            (useful for exceptions strings such as 'NA' '-' 'tbd')
    #
    # The sign -- marks the end of options.
    # --------------------------------------------------------------------------
    proc format args {
	set STR "csv"
	set SEP ""
	set EOL ""
	
	while {[::string index $args 0] eq "-"} {
	    set WORD [lshift args]
	    # ::log::log debug "WORD: $WORD"
	    switch -nocase -glob -- $WORD {
		"-sem*"   {set STR "semigraphic"}
		"-csv*"   {set STR "csv"}
		"-fmt"    {set FMT [lshift args]}
		"-sep*"   {set SEP [lshift args]}
		"-eol"    {set EOL [lshift args]}
		"-exc*" - "NA" - "NonApplicable" {set EXCEPT [lshift args]}
		"-data"   {set DATA [lshift args]}
		"--"      {set DATA [lshift args]}
	    }
	}
	
	if ![info exists DATA] {set DATA {*}$args}
	# ::log::log debug "DATA: $DATA"

	if {[llength $DATA] == 0} {return}
	
	if [info exists FMT] {
	    if {[set FMTLN [llength $FMT]] != [set NBEL [llength $DATA]]} {
		error "$FMTLN format strings for $NBEL columns"
	    }
	} {
	    set FMT [datatable line fmt $DATA]
	}
	# ::log::log debug "FMT=$FMT"
	
	if {$STR eq "semigraphic"} {
	    # we need to define first the BODY (the line), which is the format used
	    # to draw the lines at bottom and top.	    
	    set BODY [datatable frame line $FMT $DATA "│"]
	    # ::log::log debug "BODY=$BODY"

	    set RES "[datatable frame top $BODY]$BODY[datatable frame bottom $BODY]"
	    return $RES
	    
	} {
	    if [lsearch -glob $args -sep*] {lappend OPT $SEP}
	    if [lsearch -exact $args -eol] {lappend OPT $EOL}	    
	    # ::log::log debug "OPT = $OPT"
	    return [datatable frame line $FMT $DATA {*}$OPT]
	}	
    }    
}
#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
namespace eval datatable::ldict {

    namespace export format
    namespace ensemble create

    #--------------------------------------------------------------------------
    # datatable ldict format $data ?options?
    # --------------------------------------------------------------------------
    # format a datatable which is given as a ldict.  Options are the same as for
    # datatable format plus the option -noheader if one don't want to get the
    # columns headers in semigraphic.
    #                                                                          
    # Normally if one would use this command with ldict, one would expect to be
    # able to benefit from the name of the fields to build automatically the
    # line of titels for the semigraphic.
    #                                                                           
    # The options are:
    # ----------------
    #  -data        : option way to give data (can be give as last argument otherwise)    
    #  -semigraphic : data is presented in semigraphic form. (exclude -csv)
    #  -csv         : data is presented with Caracter Separating Value.
    #                 (exclude -semigraphic)
    #  -fmt {…}     : the list of formatting string fore each columns
    #  -sep "…"     : the separating character between values, default is " "
    #  -eol "…"     : possible string to add at each end of line.
    #                 (typically \\\\ for LaTeX table)
    #  -NA {…}      : list of strings accepted in numeric formatting
    #  -exc* {…}    : list of strings accepted in numeric formatting
    #  -NA            (useful for exceptions strings such as 'NA' '-' 'tbd')
    #  -nohead*     : do not include the titel line
    #
    # The sign -- marks the end of options.    
    # --------------------------------------------------------------------------
    proc format args {
	
	# get the data with option -data
	if {[set DI [lsearch -glob $args -data]] >= 0} {
	    set DATA [lindex $args $DI+1]
	    if {$DI > 0} {
		if {$DI == 1} {
		    set ARG1 [lindex $args 0]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]
		} {
		    set ARG1 [lrange $args 0 $DI-1]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]		    
		}
	    } {
		set args [lrange $args 2 end]
	    }
	    
	} elseif {[set DI [lsearch -glob $args --]] >= 0} {
	    set DATA [lindex $args $DI+1]
	    if {$DI > 0} {
		if {$DI == 1} {
		    set ARG1 [lindex $args 0]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]
		} {
		    set ARG1 [lrange $args 0 $DI-1]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]		    
		}
	    } {
		set args [lrange $args 2 end]
	    }
	} else {
	    # otherwise we expect data to the be last element
	    set DATA [lindex $args end]
	    set args [lrange $args 0 end-1]
	}

	set LL [datatable from ldict $DATA]
	set BODY [datatable format {*}$args -data $LL]
	# check if -nohead with in optional arguments, then it's over
	if {[lsearch -glob $args -nohead*] >= 0} {return $BODY}
	
	set HEADERS [datatable ldict headers list $DATA]
	# ::log::log debug "HEADERS=$HEADERS"

	if {[lsearch -glob $args -sem*] >= 0} {
	    return [datatable frame addHeaders $BODY $HEADERS]
	} {
	    # recover options to build the titel line
	    set OPT {}
	    if {[set ID [lsearch -glob $args -sep*]] >= 0} {
		lappend OPT [lindex $args [incr ID]]
	    }
	    if {[set ID [lsearch $args -eol]] >=0} {
		lappend OPT [lindex $args [incr ID]]
	    }
	    if {[set ID [lsearch -glob $args -fmt]] >=0} {
		# if a fmt is given, we try to respect it
		set FMT [lindex $args [incr ID]]
		set FMT [::datatable::frame::FMTL2STRL $FMT]
	    } {
		set FMT [datatable line fmt $HEADERS]
	    }
	    set RES [datatable frame line $FMT $HEADERS {*}$OPT]	    
	    return "$RES$BODY"
	}
    }
    #--------------------------------------------------------------------------    
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
namespace eval datatable::dcol {

    namespace export format
    namespace ensemble create

    #--------------------------------------------------------------------------
    # datatable dcol format $data ?options?
    #--------------------------------------------------------------------------
    # format a datatable which is given as a dcol.
    # Options are the same as for datatable format plus the option -noheader
    # to no add the columns headers
    # The options are:
    # ---------------- 
    #  -data        : option way to give data (can be give as last argument otherwise)   
    #  -semigraphic : data is presented in semigraphic form. (exclude -csv)
    #  -csv         : data is presented with Caracter Separating Value.
    #                 (exclude -semigraphic)
    #  -fmt {…}     : the list of formatting string fore each columns
    #  -sep "…"     : the separating character between values, default is " "
    #  -eol "…"     : possible string to add at each end of line.
    #                 (typically \\\\ for LaTeX table)
    #  -exc* {…}    : list of strings accepted in numeric formatting
    #  -NA            (useful for exceptions strings such as 'NA' '-' 'tbd')
    #  -nohead*     : do not include the titel line
    #
    # The sign -- marks the end of options.    
    #--------------------------------------------------------------------------
    # note: the procedure will transfer to `datatable format` with it argument.
    # Only particular arguments applicable to dcol will be treated.
    #--------------------------------------------------------------------------
    proc format args {

	# get the data with option -data
	if {[set DI [lsearch -glob $args -data]] >= 0} {
	    set DATA [lindex $args $DI+1]
	    if {$DI > 0} {
		if {$DI == 1} {
		    set ARG1 [lindex $args 0]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]
		} {
		    set ARG1 [lrange $args 0 $DI-1]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]		    
		}
	    } {
		set args [lrange $args 2 end]
	    }	     
	} elseif {[set DI [lsearch -glob $args --]] >= 0} {
	    set DATA [lindex $args $DI+1]
	    if {$DI > 0} {
		if {$DI == 1} {
		    set ARG1 [lindex $args 0]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]
		} {
		    set ARG1 [lrange $args 0 $DI-1]
		    set ARG2 [lrange $args [expr $DI +2] end]
		    set args [concat $ARG1 $ARG2]		    
		}
	    } {
		set args [lrange $args 2 end]
	    }
	} else {
	    # otherwise we expect data to the be last element
	    set DATA [lindex $args end]
	    set args [lrange $args 0 end-1]
	}
	
	set LL [datatable from dcol $DATA]
	set BODY [datatable format {*}$args -data $LL]
	# check if -nohead with in optional arguments, then it's over
	if {[lsearch -glob $args -nohead*] >= 0} {return $BODY}
	
	set HEADERS [datatable dcol headers list $DATA]
	# ::log::log debug "HEADERS=$HEADERS"       
	
	if {[lsearch -glob $args -sem*] >= 0} {
	    return [datatable frame addHeaders $BODY $HEADERS]
	} {
	    # recover options to build the titel line
	    set OPT {}
	    if {[set ID [lsearch -glob $args -sep*]] >= 0} {
		lappend OPT [lindex $args [incr ID]]
	    }
	    if {[set ID [lsearch $args -eol]] >=0} {
		lappend OPT [lindex $args [incr ID]]
	    }
	    if {[set ID [lsearch -glob $args -fmt]] >=0} {
		# if a fmt is given, we try to respect it
		set FMT [lindex $args [incr ID]]
		set FMT [::datatable::frame::FMTL2STRL $FMT]
	    } {
		set FMT [datatable line fmt $HEADERS]
	    }	    	    
	    set RES [datatable frame line $FMT $HEADERS {*}$OPT]	    
	    return "$RES$BODY"
	}
    }
    #--------------------------------------------------------------------------
}
#------------------------------------------------------------------------------
