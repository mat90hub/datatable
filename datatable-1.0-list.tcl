#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔═══════════════════════════════╗
#║ *** datatable-1.0-list.tm *** ║
#╚═══════════════════════════════╝
# 

# This package is meant to be subnamespace of datatable and gather all procedures linked
# to lists.

namespace eval list {

    namespace export id2int normalize
    namespace ensemble create

    
    # we start by general function useful at the upmost level and that will
    # become available for all when the namespace datatable is loaded.

    # Those commands set at upper level don't need to be exported to be accessible.
    
    uplevel #0 {
	#--------------------------------------------------------------------------
	# lshift list
	#--------------------------------------------------------------------------
	# from an orginal idea taken here: https://wiki.tcl-lang.org/page/lshift
	# ! arrgument by adress ...
	# Used in loops       
	#--------------------------------------------------------------------------
	proc lshift list {
	    upvar 1 $list L
	    set R [lindex $L 0]
	    set L [lreplace $L [set L 0] 0]
	    return $R	    
	}
	
	#--------------------------------------------------------------------------
	# rshift list
	#--------------------------------------------------------------------------
	# same as lshift but take the last element out of a list
	#--------------------------------------------------------------------------
	proc rshift list {
	    upvar 1 $list L
	    set R [lindex $L end]
	    set L [lreplace $L [set L end] end]
	    return $R	    
	}
	
	#--------------------------------------------------------------------------
	# reverse list
	#--------------------------------------------------------------------------
	# return a list in the reverse order
	#--------------------------------------------------------------------------
	proc reverse list {
	    while {[llength $list] > 0} {
		lappend R [rshift list]
	    }
	    return $R
	}
	#--------------------------------------------------------------------------
	
	#--------------------------------------------------------------------------
	# range max
	# range min max
	# range min max step
	#--------------------------------------------------------------------------
	# Generate an arithmetic progression, useful for creating an index list
	#--------------------------------------------------------------------------    
	proc range args {
	    switch [llength $args] {
		1 {
		    set begin 0
		    set end [lshift args]
		    set diff 1
		    if {$end < 0} {
			set begin [incr end 1]
			set end 1
		    }
		}		    
		2 {
		    set begin [lshift args]
		    set end [lshift args]
		    set diff 1
		    if {$begin > $end} {
			return [reverse [range $end $begin]]
		    } {
			set end [incr end]
		    }
		}
		3 {
		    set begin [lshift args]
		    set end [lshift args]
		    set diff [lshift args]		    
		    if {$diff < 0} {set diff -diff}		    
		    if {$begin > $end} {
			return [reverse [range $end $begin $diff]]
		    } {
			set end [incr end 1]
		    }
		}
		default {
		    error "range needs 1, 2 or 3 arguments"
		}
	    }
	    for {set i $begin} {$i < $end} {incr i $diff} {lappend res $i}
	    return $res
	}
	#--------------------------------------------------------------------------

	#--------------------------------------------------------------------------
	# lfilter x list expr
	#--------------------------------------------------------------------------
	# filter a list
	#--------------------------------------------------------------------------
	# entry is a variable, the list and expression using the variable 
	# output is the list filtered according to that expression
        #--------------------------------------------------------------------------
	# voir : http://wiki.tcl.tk/12850
	proc lfilter {fvar flist fexpr} {
	    upvar 1 $fvar var
	    set res {}
	    foreach var $flist {
		set varCopy $var
		if {[uplevel 1 [list expr $fexpr]]} {
		    lappend res $varCopy
		}
	    }
	    return $res
	}
	#-------------------------------------------------------------------------       
    }
    #-----------------------------------------------------------------------------
       
    #-----------------------------------------------------------------------------
    # datatable list id2int indexList listSize ?plus? ?check?
    # -----------------------------------------------------------------------------
    # Convert list identifiers into integer.  An id can use the keywords 'all'
    # and 'end' and derivatives such as 'end-N' where N is an integer. It's
    # useful to convert to integer when one needs to sort indexes.
    # 
    # Needs the list of indexes (indexList) and the actual size of the list (listSize).
    # If the indexList is incomplete (common when one used keyword 'end'), one cannot
    # guess its actual integer value without the actual size of the list.
    #
    # If 'fromEnd' is true, count position from end, meaning last position is
    # exactly at 'listSize' index instead of 'listeSize-1'. (insertion needs
    # this, while removal not)
    # 
    # If check is true, do boundary check (but doesn't seem necessary)
    #------------------------------------------------------------------------------
    proc id2int {indexList listSize {fromEnd f} {checkMax f}} {
    	# recognize 'all'
    	if [string equal [lindex $indexList 0] "all"] {
    	    return [range 0 [expr $listSize -1]]
    	}	
    	# recognize 'end-*' and replace by integer
    	set ENDLST [lsearch -glob -all $indexList "end*"]
	# ::log::log debug "ENDLST=$ENDLST"
	
    	if {[llength $ENDLST] > 0} {
    	    foreach ID $ENDLST {
    		set ENDSTR [lindex $indexList $ID]
    		if {[string length $ENDSTR] > 3} {
    		    if ![string equal [string index $ENDSTR 3] -] {
    			error "only integer and forms like all or end-N are accepted for index"
    		    }
    		    set N [expr [string range $ENDSTR 4 end]]
		    if ![string is integer $N] {
    			error "in index form end-N, when N is an integer"
    		    }
		    if $fromEnd {
			set ENDID [expr $listSize - $N]		
		    } {
			set ENDID [expr $listSize - $N -1]
		    }		    
    		    set indexList [lreplace $indexList $ID $ID $ENDID]
    		} {
		    if $fromEnd {
			set indexList [lreplace $indexList $ID $ID $listSize]
		    } {
			set indexList [lreplace $indexList $ID $ID [expr $listSize -1]]
		    }
    		}
    		# ::log::log debug "indexList=$indexList"
    	    }
    	}

	if $checkMax {
	    # forced to stay within boundaries, even if indexlist is disordered
	    set MIN 0
	    set MAX $listSize
	    for {set I 0} {$I < [llength $indexList]} {incr I} {
		if {[lindex $indexList $I] < $MIN} {
		    lset indexList $I $MIN
		}
		if {[lindex $indexList $I] >= $MAX} {    		
		    lset indexList $I $MAX
		}
	    }
	}
    	return $indexList
    }
    #--------------------------------------------------------------------------

    #----------------------------------------------------------------------
    # datatable list normalize line len
    #----------------------------------------------------------------------
    # normalize a list by adding empties ({}) if it is too short or cutting
    # it if too long compared to len
    #----------------------------------------------------------------------
    proc normalize {line len} {
	if {[set OVER [expr $len - [llength $line]]] < 0} {
	    return [lrange $line 0 $len-1]
	} elseif {$OVER > 0} {	    
	    return [concat $line [lrepeat $OVER {}]]
	} else {
	    return $line
	}
    }
    #----------------------------------------------------------------------    

}
