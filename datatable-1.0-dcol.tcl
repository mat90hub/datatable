#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔════════════════════════════╗
#║  datatable::dcol-1.0.tm    ║
#╚════════════════════════════╝

# In a dictionary of column, the keys are the columns titel and the values are
# the contents of the columns.

# ------------------------------------------------------------------------------
# Discussion:
#
# The pro:
#
# 1°) It is the most efficient way to save a table with titel in term of space used.
#
# The con:
#
# 1°) In contrary to ldict, it may require empties like for llist.
#
# 2°) It is not the natural way for writing the table, since we write them line per
#     line and not per columns.
# 
#
# ------------------------------------------------------------------------------

namespace eval dcol {

    namespace export to headers merge
    namespace ensemble create
        
    namespace eval to {
	
	namespace export ldict
	namespace ensemble create
	
	#----------------------------------------------------------------------
	# datatable dcol to ldict $data
	#----------------------------------------------------------------------    
	# transform a dictionary of columns in a list of dictionaries 
	# passing by llist as intermediate
	#----------------------------------------------------------------------
	proc ldict data {
	    set HEADERS [dict keys $data]
	    set LL [datatable from dcol $data]
	    set DC [datatable to ldict $LL $HEADERS]
	    return $DC
	}
	#----------------------------------------------------------------------
    }

    namespace eval headers {

	namespace export list
	namespace ensemble create
	
	#----------------------------------------------------------------------
	# datatable dcol headers list $data
	#----------------------------------------------------------------------
	# Return the list of header for data.
	#----------------------------------------------------------------------
	# Very direct and simple
	#---------------------------------------------------------------------
	proc list data {	    
	    return [dict keys $data]
	}
	#----------------------------------------------------------------------
    }

    #--------------------------------------------------------------------------
    # datatable dcol merge $data1 $data2
    #--------------------------------------------------------------------------
    # merge two dcol in one dcol
    #--------------------------------------------------------------------------
    proc merge {data1 data2} {
	return [dict merge $data1 data2]
    }
    #--------------------------------------------------------------------------
    # not totally tested...
}
