#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔════════════════════════════════╗
#║ *** datatable-1.0-llist.tm *** ║
#╚════════════════════════════════╝

#╔════════════════════════════════════╗
#║ PROCEDURES HANDLING LIST OF LISTS  ║
#╚════════════════════════════════════╝


# Procedure applies to a dataset (shorten to data), that must be a list of list.
# If necessary, the compliance of dataset to llist format must be checked
# prior to use with 'datatable check $data'.
# Parameters given in copy in all those procedures.

namespace export isnormalized normalize transpose orient column widths fmt overwrite line

#-------------------------------------------------------------------------------
# datatable isnormalized $data
# ------------------------------------------------------------------------------
# Check that we have a list of lists and that the number of items in the
# internal lists are identical.
# ------------------------------------------------------------------------------
proc isnormalized data {
    if {[llength [lindex $data 0]] <= 1} {
	return false
    } {
	set LEN [llength [lindex $data 0]]
	for {set I 1} {$I < [llength $data]} {incr I} {
	    if {[llength [lindex $data $I]] != $LEN} {return false}
	}
	return true
    }
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# datatable normalize $data
#-------------------------------------------------------------------------------
# Return a datatable in which lines are completed with empties if too short.
# This function shall be use, whenever there is a doubt.
#----------------------------------------------------------------------
proc normalize data {
    # we need first to identify the max number of columns
    set NBCOL [datatable column count $data]
    if {$NBCOL eq 0} {return}
    
    # reloop to complete lines
    foreach L $data {
	lappend RES [datatable list normalize $L $NBCOL]	
    }
    return $RES
}
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# datatable transpose $data
#-------------------------------------------------------------------------------
# (orginal idea: https://wiki.tcl-lang.org/page/Transposing+a+matrix)
# By default, we handle list of lines, but it might be interesting to
# get by columns, so to transpose simply the list of lines to get
# a list of columns (or reverse)
#-------------------------------------------------------------------------------
proc transpose data {
    if {[llength $data] == 0} {return}
    set NC [column count $data]
    for {set I 0} {$I < $NC} {incr I} {
	lappend res [lsearch -all -inline -subindices -index $I $data *]
    }
    return $res
}
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# datatable orient $data NbOf [columns/lines] toListType
# ------------------------------------------------------------------------------
# Re-orient a list of lines to a list of columns or a list of columns to a
# list lines to prepare merging of two datas.
#
# Input list is recognized by it number of lines or columns and type of
# conversion expected.
#
# When merging two datatable only one dimension needs to be fixed:
#
#  - to add lines, the number of columns must be fixed:
#                    xxxxxx          xxxxxx
#                    xxxxxx +      = xxxxxx
#                            xxxxxx  xxxxxx
# 
#  - to add columns, the number of lines must be fixed:
#                    xxxx   xx   xxxxxx
#                    xxxx + xx = xxxxxx
#                    xxxx   xx   xxxxxx
#-------------------------------------------------------------------------------
proc orient {data numberOf type toListType } {
    # this procedure is only for llist (not for simple List)
    if {[llength $data] == 0} {return}
    # recognize the data
    switch -glob -- $type {
	"c*" {
	    if {[llength $data] == $numberOf} {
		set TYP "CL"  
	    } elseif {[llength [lindex $data 0]] == $numberOf} {
		set TYP "LL"
	    } else {
		error "the elements of the set shall have $numberOf columns"
	    }	
	}
	"l*" {
	    if {[llength $data] == $numberOf} {
		set TYP "LL"  
	    } elseif {[llength [lindex $data 0]] == $numberOf} {
		set TYP "CL"
	    } else {
		error "the elements of the set shall have $numberOf lines"
	    }
	}
	default {
	    set msg "usage:"
	    append msg "\norient data N columns tocolumns"
	    append msg "\norient data N columns tolines"
	    append msg "\norient data N lines   tocolumns"			
	    append msg "\norient data N lines   tolines"	
	    error "msg"
	}
    }
    
    # return setof or its transposition according to analyses done
    switch -glob -- $toListType {
	"toc*" {
	    if {$TYP eq "CL"} {
		return $data
	    } {
		return [transpose $data]
	    }
	}
	"tol*" {
	    if {$TYP eq "LL"} {
		return $data
	    } {
		return [transpose $data]
	    }
	} 
	default {
	    set msg "usage:"
	    append msg "\norient data N columns tocolumns"
	    append msg "\norient data N columns tolines"
	    append msg "\norient data N lines   tocolumns"			
	    append msg "\norient data N lines   tolines"	
	    error "msg"
	}
    }
}
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Handling columns
# ------------------------------------------------------------------------------
namespace eval column {
    
    namespace export count append insert remove index width fmt overwrite cumul 

    namespace ensemble create

    #---------------------------------------------------------------------------
    # datatable column count data
    #---------------------------------------------------------------------------
    # return the max number of columns
    #---------------------------------------------------------------------------
    proc count data {
	set NBCOL 0
	foreach L $data {
	    if {[set LLgth [llength $L]] > $NBCOL} {
		set NBCOL $LLgth
	    }
	}
	return $NBCOL
	
    }
    #---------------------------------------------------------------------------
    
    #---------------------------------------------------------------------------
    # datatable column insert data id data
    #---------------------------------------------------------------------------
    # insert data at the place given by id. It can insert several columns
    # at several place if id is a list and data a llist.
    #---------------------------------------------------------------------------
    proc insert {data id args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	if {[set IDNB [llength $id]] == 0} {return $data}
	
	if ![datatable isnormalized $args] {
	    # we insert a single column
	    foreach L $data C $args {
		lappend RES [linsert $L $id $C]
	    }		
	} {
	    # we insert a llist (= several columns)
	    # insertion must start from the right of the datatable
	    set id [datatable list id2int $id [count $data] true]
	    # ::log::log debug "id=$id"
	    
	    set SORTEDID [lsort -decreasing -integer $id]
	    # ::log::log debug "SORTEDID=$SORTEDID"

	    # secure args given as List of lines
	    set LL [datatable orient $args [llength $data] lines tolines]

	    # we need to reverse columns, so they appear in good order
	    set LL [datatable transpose [reverse [datatable transpose $LL]]]

	    foreach L $data CL $LL {		    
		foreach I $SORTEDID C $CL {set L [linsert $L $I $C]}
		lappend RES $L	    
	    }
	}
	return $RES
    }
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # datatable column append data data
    #---------------------------------------------------------------------------
    # Append the given columns after the last columns of the llist.
    # Data to be added can be a list of lines or list of columns.
    # If single list, its a single column to append.
    # (indeed, it's a rewording of inserting)
    #---------------------------------------------------------------------------
    proc append {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	if ![datatable isnormalized $args] {
	    # we append a single column
	    foreach L $data E $args {
		lappend RES [lappend L $E]
	    }
	} {
	    # secure args given has the proper number of lines
	    set LL [datatable orient $args [llength $data] lines tolines]	   
	    foreach L $data E $LL {
		lappend RES [concat $L $E]
	    }	    
	}
	return $RES
    }
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # datatable column remove data id
    #---------------------------------------------------------------------------
    # return a datatable in which columns given by their id are removed
    # id can be a list of columns
    #---------------------------------------------------------------------------
    proc remove {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}

	# trivial cases
	if {[set IDLN [llength $args]] == 0} {return $data}
	if {$args eq "all"} {return}	
	
	if {$IDLN == 1} {
	    foreach L $data {lappend RES [lreplace $L $args $args]}
	    return $RES
	    
	} else {
	    # We have to remove starting from the right to let
	    # the column numbering untouched for the others.
	    set IDLST [datatable list id2int $args [count $data]]
	    set SORTEDID [lsort -decreasing -integer $IDLST]		
	    foreach L $data {
		foreach SID $SORTEDID {
		    set L [lreplace $L $SID $SID]
		}
		lappend RES $L
	    }
	    return $RES
	}
    }
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # datatable column index $data ?id?
    #---------------------------------------------------------------------------
    # return the columns given by their index
    #---------------------------------------------------------------------------
    proc index {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	# if we use keyword all, do a shortcut
	if [string equal $args "all"] {return $data}
	# if no argument given, return list indexes
	if {[llength $args] == 0} {return [range [datatable column count $data]]}

	# set id [datatable list id2int $args [datatable column count $data] false true]
	if {[llength $args] == 1} {
	    foreach L $data {lappend RES [lindex $L $args]}
	} {	    
	    foreach L $data {
		set NL {}	    
		foreach I $args {lappend NL [lindex $L $I]}
		lappend RES $NL			
	    }		
	}
	return $RES
    }
    #---------------------------------------------------------------------------

    #---------------------------------------------------------------------------
    # datatable column width $data ?numCol
    #---------------------------------------------------------------------------
    # return the characters width, that a given column should have to not cut
    # any member. If numCol is given, takes this column number.
    #---------------------------------------------------------------------------
    proc width {data {numCol 0}} {
	set RES 0
	foreach E $data {
	    if {[set WDTH [string length [lindex $E $numCol]]] > $RES} {
		set RES $WDTH
	    }
	}
	return $RES
    }
    #---------------------------------------------------------------------------
        
    #---------------------------------------------------------------------------
    # datatable column fmt $data ?except?
    #---------------------------------------------------------------------------
    # Guess a single string format that fits all elements of the column in order
    # they aligned vertically.  If all elements are decimals, aligns on the
    # decimal point. Align to left by default otherwise.
    #
    # If a string ?except? is given, it contains the string accepted in numeric
    # formatting (useful for exceptions strings such as 'NA' '-' 'tbd')
    # --------------------------------------------------------------------------
    #
    # discussion:
    #
    # Among numeric, only decimals are treated a. Case of engineering notation
    # could be useful to developp.
    # 
    # --------------------------------------------------------------------------
    proc fmt {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	set MAXLEN 0
	set MAXWHL 0
	set MAXDEC 0
	if {[llength $data] == 0} {return}
	foreach E $data {
	    # treat exceptions contained in args
	    if {[lsearch -exact $args $E] >= 0} {
	    	# ::log::log debug "E is exception"
	    	if {[set LEN [string length $E]] > $MAXLEN} {
	    	    set MAXLEN $LEN
	    	}
	    	continue
	    }
	    
	    if [string is double -strict $E] {
		# ::log::log debug "E is double"
		if {[set LEN [string length $E]]>$MAXLEN} {set MAXLEN $LEN}
		# ::log::log debug "MAXLEN=$MAXLEN"

		# if a string was detected
		if {$MAXDEC < 0} {continue}
		
		set I [string first . $E]
		if {$I > $MAXWHL} {
		    set MAXWHL $I
		    # ::log::log debug "MAXWHL=$MAXWHL"		    
		}
		
		if {$I >= 0} {
		    set DEC [expr [string length $E] - $I -1]
		    # ::log::log debug "DEC=$DEC"
		    if {$DEC>$MAXDEC} {set MAXDEC $DEC}
		    # ::log::log debug "MAXDEC=$MAXDEC"
		    
		} elseif {$I<=0} {
		    # it's an integer		 
		    if {$LEN>$MAXWHL} {set MAXWHL $LEN}
		    # ::log::log debug "MAXWHL=$MAXWHL"
		}		
	    } {
		# it's a string
		set LEN [string length $E]
		# when a string, all further checks will be cancelled
		set MAXDEC -1
		if {$LEN>$MAXLEN} {set MAXLEN $LEN}
	    }	    
	}
	# compile the format string
	if {$MAXLEN==0} {return %1s}
	
	if {$MAXDEC>0} {
	    set LEN [expr $MAXWHL + $MAXDEC +1]
	    return [join "% $LEN . $MAXDEC f" ""]
	} elseif {$MAXDEC < 0} {
	    # string
	    return [join "%- $MAXLEN s" ""]
	} {
	    # integer ($MAXDEC==0)
	    return [join "% $MAXLEN d" ""]
	}
    }
    #---------------------------------------------------------------------------
    
    #---------------------------------------------------------------------------
    # datatable column overwrite $data id data
    #---------------------------------------------------------------------------
    # entry: llist, index (list or single) and content to overwrite
    #---------------------------------------------------------------------------
    # overwrite the content of the given columns
    #---------------------------------------------------------------------------
    proc overwrite {data id args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	# check trivial cases    
	if {[set NBID [llength $id]] == 0} {return $data}	
	if {[llength $args] == 0} {return $data}

	# if all return args oriented to a list of lines if necessary
	if [string equal [lindex $id 0] "all"] {
	    return [datatable orient $args [llength $data] lines tolines]
	}

	set id [datatable list id2int $id [datatable column count $data] false true]
	# ::log::log debug "id=$id"
	if {$NBID == 1} {
	    foreach L $data E $args {lappend RES [lset L $id $E]}
	} {
	    # secure args as List of lines
	    set LL [datatable orient $args [llength $data] lines tolines]

	    foreach L $data CL $LL {
		foreach I $id C $CL {lset L $I $C}
		lappend RES $L
	    }				    
	}
	return $RES
    }
    #------------------------------------------------------------------------------
           
    #----------------------------------------------------------------------
    # datatable column cumul data ?id?
    #----------------------------------------------------------------------
    # entry: llist and index of column to be cumulated
    #----------------------------------------------------------------------
    # return a llist containing cumul of the given column
    #----------------------------------------------------------------------	
    proc cumul {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	# first of trailing parameters is the index
	if {[llength $args] == 0} {return}

	# ::log::log debug "args=$args // llength = [llength $args]"
	
	if {[llength $args] == 1} {
	    set SUM {}
	    set C [index $data $args]
	    set RES [lmap x $C {if {$x > 0} {set SUM [expr $SUM + $x]}}]
	    
	} {	    
	    # initialize the arrays containing sums	    
	    set ID [datatable list id2int $args [datatable column count $data]]
	    # ::log::log debug "ID=$ID"
	    # initialize counters
	    foreach I $ID {array set SUM [list $I 0]}
	    if {[llength $data] == 0} {return}
	    foreach L $data {
		set NL {}
		foreach I $ID {
		    set X [lindex $L $I]
		    if {[string length $X] >0} {
			set SUM($I) [expr $SUM($I) + $X]
		    }
		    lappend NL $SUM($I)
		}
		lappend RES $NL		    
	    }
	}
	return $RES	    
    }
    #----------------------------------------------------------------------	
    
    
}       
#---- (column )------------------------------------------------------------


# some procedures for the datatable using the procedures defined on columns

#----------------------------------------------------------------------
# datatable widths $data ?id?
#----------------------------------------------------------------------
# Return the list of widths of all columns.
# If id is given, return only for the columns given by their ids.
#----------------------------------------------------------------------
proc widths {data args} {
    # if for trailing argument, we accept with or without accolades
    if {[llength $args] == 1} {set args {*}$args}

    if {[llength $args] == 1} {
	set COL [datatable column index $data $args]
	# ::log::log debug "COL=$COL"
	return [datatable column width $COL]
    }
    
    if {[llength $args] == 0} {
	set COL [datatable transpose $data]
    } {
	set COL [datatable transpose [datatable column index $data $args]]
	# ::log::log debug "COL=$COL"
    }
    if {[llength $COL] == 0} {return}
    foreach C $COL {
	lappend RES [datatable column width $C]
	# ::log::log debug "RES=$RES"
    }		
    return $RES
}
#----------------------------------------------------------------------

#---------------------------------------------------------------------------
# datatable fmt $data ?id?
#---------------------------------------------------------------------------
# Return the default format string for all columns.  If an index is given (or
# index list), gives the format only for those columns
# --------------------------------------------------------------------------
proc fmt {data args} {
    # if for trailing argument, we accept with or without accolades
    if {[llength $args] == 1} {set args {*}$args}

    if {[llength $args] == 1} {
	set COL [datatable column index $data $args]
	# ::log::log debug "COL=$COL"
	return [datatable column fmt $COL]
    }
    
    if {[llength $args] == 0} {
	set COL [datatable transpose $data]
    } {
	set COL [datatable transpose [datatable column index $data $args]]
	# ::log::log debug "COL=$COL"
    }
    if {[llength $COL] == 0} {return}
    foreach C $COL {
	lappend RES [datatable column fmt $C]
	# ::log::log debug "RES=$RES"
    }		
    return $RES
}
#---------------------------------------------------------------------------


#--------------------------------------------------------------------------
# Handling lines
#--------------------------------------------------------------------------
namespace eval line {
    
    namespace export count insert append remove index overwrite sort fmt

    namespace ensemble create

    #----------------------------------------------------------------------
    # datatable line count data
    #----------------------------------------------------------------------
    # return the number of lines
    #----------------------------------------------------------------------
    proc count data {
	return [llength $data]
    }
    #----------------------------------------------------------------------
        
    #----------------------------------------------------------------------
    # datatable line insert data id data
    #----------------------------------------------------------------------
    # Insert a line at the place given by id.
    # Improvement to classical linsert:
    #  - it checks the length of the lines inserted or complete with empties
    #  - it can insert several lines at once
    #----------------------------------------------------------------------
    proc insert {data id args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	if {[set IDNB [llength $id]] == 0} {return $data}

	if ![datatable isnormalized $args] {
	    # we insert a single line
	    # return [linsert $data $id [datatable list normalize $args [datatable column count $data]]]
	    return [linsert $data $id $args]
	    
	} {
	    # we insert a llist (= several lines)
	    # insertion must start from the bottom of the datatable
	    set id [datatable list id2int $id [count $data] true]	    
	    set SORTEDID [lsort -decreasing -integer $id]
	    # ::log::log debug "SORTEDID=$SORTEDID"
	    
	    # secure data given as List of lines
	    set LL [datatable orient $args [datatable column count $data] columns tolines]	    
	    # we need to reverse lines
	    set LL [reverse $LL]
	    # ::log::log debug "LL=$LL"	    
		    
	    set RES $data
	    foreach I $SORTEDID L $LL {
		set RES [linsert $RES $I $L]
	    }
	}
	return $RES
    }
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------	
    # datatable line append data data
    #----------------------------------------------------------------------
    # Append the given lines after the last lines of the llist.
    # Data to be added can be a list of lines or list of lines.
    # If single list, its a single line to append.
    # (indeed, it's a rewording of inserting)
    #----------------------------------------------------------------------
    proc append {data args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	if ![datatable isnormalized $args] {
	    # we insert a single line
	    return [concat $data [list $args]]
	    
	} {
	    # secure args has the proper number of columns
	    set LL [datatable orient $args [datatable column count $data] columns tolines]	    
	    return [concat $data $LL] 
	}
    }
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------
    # datatable line remove data id
    #----------------------------------------------------------------------
    # return a datatable in which lines given by their id are removed
    # id can be a list of lines
    #----------------------------------------------------------------------	
    proc remove {data args} {
	# for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}

	# trivial cases
	if {[set IDLN [llength $args]] == 0} {return $data}
	if {$args eq "all"} {return}	
	
	if {$IDLN == 1} {	    
	    return [lreplace $data $args $args]
	    
	} else {
	    # We have to remove starting from the bottom to let
	    # the line numbering untouched for the others.
	    set IDLST [datatable list id2int $args [count $data]]
	    set SORTEDID [lsort -decreasing -integer $IDLST]		
	    foreach SID $SORTEDID {
		set data [lreplace $data $SID $SID]
	    }
	    return $data
	}
    }
    #----------------------------------------------------------------------	

    #----------------------------------------------------------------------
    # datatable line index data ?id?
    #----------------------------------------------------------------------
    # return the lines given by their index
    #----------------------------------------------------------------------
    proc index {data args} {
	# for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	# if we use keyword all, do a shortcut
	if [string equal $args "all"] {return $data}
	# if no argument given, return list indexes
	if {[llength $args] == 0} {return [range [datatable line count $data]]}
	
	# set id [datatable list id2int $args [datatable line count $data] false true]
	if {[llength $args] == 1} {
	    return [lindex $data $args]
	} {	    	    
	    foreach I $args {lappend RES [lindex $data $I]}
	    return $RES
	}
    }
    #----------------------------------------------------------------------
    
    #----------------------------------------------------------------------
    # datatable line overwrite $data id data
    #----------------------------------------------------------------------
    # entry: llist, index (list or single) and content to overwrite
    #----------------------------------------------------------------------
    # overwrite the content of the given lines
    #----------------------------------------------------------------------
    proc overwrite {data id args} {
	# if for trailing argument, we accept with or without accolades
	if {[llength $args] == 1} {set args {*}$args}
	
	# check trivial cases    
	if {[set NBID [llength $id]] == 0} {return $data}
	if {[llength $args] == 0} {return $data}

	# if all return args oriented to a list of lines if necessary
	if [string equal [lindex $id 0] "all"] {
	    return [datatable orient $args [table column count $data] columns tolines]
	}

	set id [datatable list id2int $id [datatable line count $data] false true]
	# ::log::log debug "id=$id"
	if {$NBID == 1} {
	    return [lreplace $data $id $id $args]
	} {
	    # secure args as List of lines
	    set LL [datatable orient $args [datatable column count $data] columns tolines]

	    foreach I $id L $LL {
		set data [lreplace $data $I $I $L]
	    }
	    return $data
	}
	
    }
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------    
    # datatable line sort -index I ?opt? $data
    #----------------------------------------------------------------------
    # To sort the lines of a datatable, we simply use the function lsort
    # that can sort a list with option index
    #----------------------------------------------------------------------
    proc sort args {
	eval ::lsort $args
    }
    #----------------------------------------------------------------------

    #----------------------------------------------------------------------    
    # datatable line fmt $data
    #----------------------------------------------------------------------
    # Propose a format for a line.
    #----------------------------------------------------------------------
    proc fmt data {
	
	foreach E $data {
	    set I [string first . $E]

	    if {$I >= 0} {
		set DEC [expr [string length $E] - $I -1]	           
	    }
	    
	    set LEN [string length $E]

	    if {$LEN == 0} {
		lappend RES "%1s"
	    } elseif {$I > 0} {
		lappend RES [join "% $LEN . $DEC f" ""]
	    } else {
		if [string is integer $E] {
		    lappend RES [join "% $LEN s" ""]
		} {
		    lappend RES [join "%- $LEN s" ""]
		}
	    }
	}
	return $RES	
    }
    #----------------------------------------------------------------------
}       
#---- (line )--------------------------------------------------------------




