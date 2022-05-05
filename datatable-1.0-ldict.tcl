#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔═══════════════════════════════════╗
#║ ***  datatable::ldict-1.0.tcl *** ║
#╚═══════════════════════════════════╝

# In a list of dictionaries ldict, the dictionaries values are giving the
# content of the lines and the keys are reminding of the field names (or column
# titles).

# ------------------------------------------------------------------------------
# Discussion:
#
# The pros:
#
# 1°) The list of dictionaries are obtained without options from tdbc export
# 2°) The fields names are known and kept in the data structure.
# 2°) Empty values are not required, since one can deduct the missing values from
#     the list of keys (a ldict doesn't need to be normalize as llist)
#
# The cons:
#
# 1°) The record are more heavy since each time repeating the attributes names.
# 2°) Printing formatted lines as expected from a datatable is less direct than
#     with llist, since one need to identify empties.
# 3°) Order of the columns can be se upside down by the dictionary.
# ------------------------------------------------------------------------------

namespace eval ldict {

    namespace export check to headers column format
    namespace ensemble create

    #--------------------------------------------------------------------------
    # datatable ldict check $data
    #--------------------------------------------------------------------------
    # check if $data is a list and if all its member are dictionaries
    #--------------------------------------------------------------------------
    proc check data {       
	foreach L $data {if [catch {dict size $L}] {return false}}
	return true
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    namespace eval to {

	namespace export dcol
	namespace ensemble create
	
	#----------------------------------------------------------------------
	# datatable ldict to dcol data
	#----------------------------------------------------------------------    
	# transform a list of dictionaries into a dictionary of columns by
	# passing by llist as intermediate
	#----------------------------------------------------------------------
	proc dcol data {
	    set HEADERS [datatable ldict headers list $data]
	    set LL [datatable from ldict $data]
	    set DC [datatable to dcol $LL $HEADERS]
	    return $DC
	}
	#----------------------------------------------------------------------
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    namespace eval headers {

	namespace export list overwrite
	namespace ensemble create
	
	#----------------------------------------------------------------------
	# datatable ldict headers list $data
	# ----------------------------------------------------------------------
	# Return the list of header for data.
	# ----------------------------------------------------------------------
	# When records are retrieved as dict, some fields may be empty. When a
	# field is empty, its key is not created.  So the lines of the list of
	# dict could have different length and fields. For this reason, the
	# procedure goes over all lines and return the max list of headers.
	#
	# The order is not granted in a dictionary. To keep reproductibility of
        # the result, the headers are ordered in lexical order before being
        # returned.
        # ---------------------------------------------------------------------
	proc list data {
	    set RES {}
	    if {[llength $data] == 0} {return}
	    foreach L $data {
		foreach K [dict keys $L] {if {[lsearch -exact $RES $K] == -1} {lappend RES $K}}
	    }
	    # return [lsort $RES]
	    return $RES
	}
	#----------------------------------------------------------------------

	#----------------------------------------------------------------------
	# datatable ldict headers overwrite $data {p01 p01new p02 p02new ...}
	#----------------------------------------------------------------------
	# Overwrite the existing headers with a list of headers given
	# The change of headers are given in a dictionary:
	#     dict get $keychg OLD -> NEW
	# The key is the old headers and the value give the one which shall
	# replace it.
	#----------------------------------------------------------------------
	proc overwrite {data newHdrMapping} {
	    # to secure all cases, we pass through dcol in which fields name
	    # are easy and safe to get:  ldict -> dcol -> rewrite headers -> ldict	    
	    set DC [datatable ldict to dcol $data]
	    # now we are sure to get the exact list of keys
	    set KEYS [dict keys $DC]
	    # change the keys
	    set DC [string map $newHdrMapping $DC]
	    # come back to ldict
	    return [datatable dcol to ldict $DC]
	}
	#----------------------------------------------------------------------
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    namespace eval column {

	namespace export get width
	namespace ensemble create

	#----------------------------------------------------------------------
	# datatable ldict column get $data key ?key? ...
	#----------------------------------------------------------------------
	# Return the columns given by its key (titel).
	# If a single index is chosen, a list is returned.
	# If several indexes are chosen, return a dcol.
	#----------------------------------------------------------------------
	proc get {data args} {
	    # if for trailing argument, we accept with or without accolades
	    if {[llength $args] == 1} {set args {*}$args}

	    # if we use keyword all, do a shortcut
	    if [string equal $args "all"] {return $data}
	    # if no argument given, return list indexes
	    if {[llength $args] == 0} {return [range [datatable column count $data]]}

	    if {[llength $args] == 1} {
		foreach L $data {lappend RES [string trim [dict get $L $args]]}
		return $RES
	    } {
		# initialisation of RES as a dcol
		foreach K $args {
		    dict set RES $K ""		    
		}
		if {[llength $data] == 0} {return}
		foreach L $data {
		    foreach K $args {
			if [dict exists $L $K] { 
			    dict append RES $K "[string trim [dict get $L $K]] "
			} {
			    dict append RES $K "{} "
			}
		    }		    
		}
		# trim last space
		foreach K $args {
		    dict set RES $K [string trimright [dict get $RES $K]]
		}
		return $RES
	    }
	}
	#----------------------------------------------------------------------

	#----------------------------------------------------------------------
	# datatable ldict column width $data key
	#----------------------------------------------------------------------
	# return the width to not cut the field one given column
	#----------------------------------------------------------------------
	proc width {data key} {
	    variable STRLEN 0 MAXLEN 0
	    foreach L $data {
		if [dict exists $L $key] {
		    set STRLEN [string length [dict get $L $key]]
		    if {$STRLEN > $MAXLEN} {set MAXLEN $STRLEN}
		}
	    }
	    return $MAXLEN
	}
	#----------------------------------------------------------------------
    }
    #--------------------------------------------------------------------------
}
#------------------------------------------------------------------------------
# end of file
#------------------------------------------------------------------------------
