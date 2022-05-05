#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔════════════════════════════════╗
#║ *** datatable-1.0-frame.tm *** ║
#╚════════════════════════════════╝


#╔════════════════════════════════════════════════════════════════════════╗
#║ PROCEDURES TO DRAW ELEMENTS FOR SEMIGRAPHIC FRAME ARROUND TABLES       ║
#╚════════════════════════════════════════════════════════════════════════╝

# These procedures are used for formating table with semi-graphic characters as
# available in utf-8. To have a correct display of the result, a monospace
# characters set shall be used.

# The first line will define the table length (number of columns). When it
# is defined, we can deduct separation lines from the reading of the table
# being under construction and returned as a single string.

# ┌─┬┐ ┏━┳┓ ┍━┯┑ ┎─┰┒ ╔═╦╗ ╒═╤╕ ╓─╥╖
# │ ││ ┃ ┃┃ │ ││ ┃ ┃┃ ║ ║║ │ ││ ║ ║║
# ┝━┿┥ ┠─╂┨ ├─┼┤ ┣━╋┫ ╠═╬╣ ╞═╪╡ ╟─╫╢
# └─┴┘ ┗━┻┛ ┕━┷┙ ┖─┸┚ ╚═╩╝ ╘═╧╛ ╙─╨╜

# The formating string refered in this names space are following the conventions
# of the tcl procedure format : %8s %9.2f 

namespace eval frame {

    namespace export line addHeaders top bottom dotted plain thick double
    namespace ensemble create

    #------------------------------------------------------------------------------
    # datatable::frame::FMT2DICT fmt
    #------------------------------------------------------------------------------
    # Return key characteritics of a formatting string.
    # It's centralize the use of the regexp to ease debugging and maintenance.
    # Recognized only integer and double, all the rest is string
    #------------------------------------------------------------------------------
    proc FMT2DICT fmt {
	regexp {\{?(%([ +-0]?)(\d*)?.?(\d*)([cdiuefgGs]))\}?} $fmt -> FMT SIG LEN DEC TYP
	foreach K [list FMT SIG LEN DEC TYP] {dict set RES $K [set $K]}
	return $RES
    }
    #------------------------------------------------------------------------------

    #------------------------------------------------------------------------------
    # datatable::frame::FMTLEN fmt
    #------------------------------------------------------------------------------
    # Return the lenght wished by the formatting string fmt.
    # It is not always the LEN parameter: if the whole part is empty, we base the
    # length on the number of DEC.
    #------------------------------------------------------------------------------
    proc FMTLEN fmt {
	set FD [FMT2DICT $fmt]
	set LEN [dict get $FD LEN]	
	if {[string length $LEN] == 0} {
	    set DEC [dict get $FD DEC]
	    # no whole number, we add a space of the 0 and the decimal point
	    incr DEC 2
	    return $DEC
	} {
	    return $LEN
	}
    }
    #------------------------------------------------------------------------------
    
    #-----------------------------------------------------------------------------
    # datatable::frame::FMT2STR fmt 
    # datatable::frame::FMT2STR fmt right
    #-----------------------------------------------------------------------------
    # Transform a formatting string of a numeric field to a string formatting string
    # Option allow to precise justification: left by default, right if right is given
    #-----------------------------------------------------------------------------
    proc FMT2STR {fmt args} {
	if {[string range $fmt end end] == "s"} {return $fmt}
	set LEN [FMTLEN $fmt]
	if [string equal -length 2 $args -r] {set JUST ""} {set JUST "-"}
	return [join "% $JUST $LEN s" ""]
    }
    #-----------------------------------------------------------------------------

    #-----------------------------------------------------------------------------
    # datatable::frame::FMTL2STRL fmt
    #-----------------------------------------------------------------------------
    # Transform a list of formatting strings which may contain numeric fields to a list
    # of only string formatting string.
    #-----------------------------------------------------------------------------
    proc FMTL2STRL fmt {
	foreach F $fmt {
	    lappend RES [FMT2STR $F]
	}
	return $RES
    }
    #-----------------------------------------------------------------------------

    
    #--------------------------------------------------------------------------
    # datatable::frame::STRICTSTRING fmt str
    #--------------------------------------------------------------------------
    # Low level procedure. Replace string (str) by series of * if too wide.
    # Complete with left space if too thin.
    # Use preferably for numerics.
    #--------------------------------------------------------------------------
    proc STRICTSTRING {fmt str} {
	set STR [format $fmt $str]
	if {[string length $STR] > [set FLEN [FMTLEN $fmt]]} {
	    return [string repeat * $FLEN]
	} {
	    return $STR
	}
    }
    #--------------------------------------------------------------------------
    
    #--------------------------------------------------------------------------
    # datatable::frame::FIXEDSTRING fmt str
    #--------------------------------------------------------------------------
    # Low level procedure. Cut string (str) if too wide and append ➩.
    # Complete with left space if too thin.
    # Preferably use for alpha characters strings.
    #--------------------------------------------------------------------------
    proc FIXEDSTRING {fmt str} {
	set STR [format $fmt $str]
	set OVER [expr [set SLEN [string length $STR]] - [set FLEN [FMTLEN $fmt]]]
	# ::log::log debug "OVER=$OVER // SLEN=$SLEN // FLEN=$FLEN"
	if {$OVER <= 0} {
	    return $STR
	}
	incr FLEN -2

	switch $FLEN {
	    -1      {return "➩"}
	    0       {return "[string index $STR 0]➩"}
	    default {return "[string range $STR 0 $FLEN]➩"}
	}
    }
    #--------------------------------------------------------------------------

    
    #--------------------------------------------------------------------------
    # datatable frame line fmt data ?SEP? ?EOL?
    #--------------------------------------------------------------------------
    # Format a line and prepare its vertical alignment
    #--------------------------------------------------------------------------
    # Input a list (lst) and list of formats (fmt) for each of its members.
    # Optionnaly precise the separation character (SEP) and End Of Line (EOL)
    # string. Option ?EOL? cannot be present if option ?SEP? is absent and the
    # order of the option must be respected.
    # It return a formatted line always ending with \n
    #--------------------------------------------------------------------------
    # _discussion_:
    # Low level procedure, don't check fmt with dataset length.
    # Accept mix of numeric and strings thanks to `datatable string FMT2STR`.
    #--------------------------------------------------------------------------
    proc line {fmt data args} {
	# parse options
	set SEP [lshift args]
	set EOL [lshift args]
	
	set LN "$SEP"
	foreach E $data F $fmt {
	    # ::log::log debug "E=$E // F=$F"	    
	    if [string is double -strict $E] {		
		append LN " [STRICTSTRING $F $E] $SEP"
	    } {
		append LN " [FIXEDSTRING [FMT2STR $F] $E] $SEP"
	    }
	}
	# trim out the trailing spaces
	# set LN [string trim $LN]
	
	# trim out first and last char if not semigraphic
	if {$SEP in {" " "\t" "," ";" "&"}} {
	     set LN [string trim $LN $SEP]
	}
	if {[string length $EOL] > 0} {
	    set LN "$LN $EOL"
	}
	return "$LN\n"
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # datatable frame SHAPE fmtStr frame
    #--------------------------------------------------------------------------
    # Generic internal function to draw a separation line (low level)
    #--------------------------------------------------------------------------
    # input is a formated string representing a table or a line ending with \n
    # frame to be chosen among:  ┌─┬┐ ├─┼┤ └─┴┘ ├┄┼┤ ┝━┿┥ ╞═╪╡
    #--------------------------------------------------------------------------
    proc SHAPE {fmtStr frame } {
	set C0 [string range $frame 0 0]
	set C1 [string range $frame 1 1]
	set C2 [string range $frame 2 2]
	set C3 [string range $frame end end]
	set FRM [string range $fmtStr 0 [string first "\n" $fmtStr]]
	regsub -all -- {[^│\n]} $FRM $C1 FRM
	set FRM [string replace $FRM 0 0 $C0]
	set FRM [string replace $FRM end-1 end $C3]
	set FRM [string map "│ $C2" $FRM]
	return "$FRM\n"
    }
    #--------------------------------------------------------------------------
    
    #--------------------------------------------------------------------------
    # Return a top line to be put above a formated table string
    #--------------------------------------------------------------------------
    proc top {fmtStr} {
	return [SHAPE $fmtStr ┌─┬┐]
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # Return a bottom line to be put above a formated table string
    #--------------------------------------------------------------------------
    proc bottom {fmtStr} {
	return [SHAPE $fmtStr └─┴┘]
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # Return a dotted line aligned to a formated table string
    #--------------------------------------------------------------------------
    proc dotted {fmtStr} {
	return [SHAPE $fmtStr ├┄┼┤]
    }
    #--------------------------------------------------------------------------
    
    #--------------------------------------------------------------------------
    # Return a plain line aligned to a formated table string
    #--------------------------------------------------------------------------
    proc plain {fmtStr} {
	return [SHAPE $fmtStr ├─┼┤]
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # Return a thick line aligned to a formated table string
    #--------------------------------------------------------------------------
    proc thick {fmtStr} {
	return [SHAPE $fmtStr ┝━┿┥]
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # Return a double line aligned to a formated table string
    #--------------------------------------------------------------------------
    proc double {fmtStr} {
	return [SHAPE $fmtStr ╞═╪╡]
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # datatable frame addHeaders table titles
    # --------------------------------------------------------------------------
    # Add headers lines on top of a formatted table (table needs at least 2 lines).
    # --------------------------------------------------------------------------
    # Choice is to separate table formatting from adding a title line on top of
    # it to not overload the table formatting command with options.  But one
    # needs then to get the columns number & widths. This is obtained by giving
    # the formatted table instead of the llist (contains no formatting info).
    # The procedure recalculates the number of columns and their width.
    # --------------------------------------------------------------------------
    proc addHeaders {table titles} {
	set TTLNB [llength $titles]
	set LINLEN [string first "\n" $table]

	# semigraphic table are recognized by their upper left corner and lead
	# to error
	if {[string range $table 0 1] ne "┌─"} {
	    error "datatable frame addHeader works only for semigraphic table"
	}	
	set 1STLIN [string range $table [expr $LINLEN +1] [expr 2*$LINLEN +1]]
	set COLNB [expr [string length [regsub -all -- {[^│]} $1STLIN {}]] -1]
	if {$TTLNB != $COLNB} {
	    error "$TTLNB titles for $COLNB columns"
	}
	set RES ""
	append RES [top $1STLIN]

	# built a format list based on first line
	set id 1
	while t {
	    set id [string first "│" $1STLIN $id+1]
	    if {$id <= 0} {
		break
	    } {
		lappend idLst $id
	    }
	}
	lappend fmt "%-[expr [lindex $idLst 0] -3]s"
	for {set n 0} {$n < [llength $idLst]-1} {incr n} {
	    lappend fmt "%-[expr [lindex $idLst $n+1] - [lindex $idLst $n] -3]s"
	}	
	# print the titles
	append RES [line $fmt $titles "│"]
	# separation line
	append RES [plain $1STLIN]
	# add the rest of the table
	append RES [string range $table $LINLEN+1 end]
	
	return $RES
    }
    #--------------------------------------------------------------------------
}
