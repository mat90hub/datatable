#!/usr/bin/env tclsh
#-*- mode: Tcl; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔═══════════════════╗
#║  array2d-1.0.tm   ║
#╚═══════════════════╝

# This module provides the namespace arra2d to facilitate operation on 2D array.
# It is stored in the directory of datatable, since it is using the procedure
# format of the datatable package (see the code for more details).

# Instead of being referered by a line number and a field (a column titel) as
# they are in a datatable, the elements of an array2d are referenced by a double
# indices.

# The indices are sepearated by comma, lines first, columns second:

#  tab(1,1)   tab(1,2)   tab(1,3)
#  tab(2,1)   tab(2,2)   tab(2,3)
#  tab(3,1)   tab(3,2)   tab(3,3)

# Apart from this order line,column this type of referencing is totally
# symetrical, as it is for a mathematical matrix (I used here the term array to
# remind of the itnernal structure).

# There are gateways to datatable with the procedure 2llist or 2ldict and this
# allows then to re-use the procedure format developped in the datatable
# package.


package provide array2d 1.0

package require tab::datatable 1.0
# used for format command (see at the end)

namespace eval array2d {

    namespace export *
    namespace ensemble create

    #--------------------------------------------------------------------------
    # array2d declare data
    #--------------------------------------------------------------------------
    # declare data to be an array (to avoid, it would be declare as non-array)
    #--------------------------------------------------------------------------
    proc declare data {
	upvar 1 $data TAB
	catch {unset TAB}
	array set TAB {}
    }
    #--------------------------------------------------------------------------
    
    #--------------------------------------------------------------------------
    # array2d names data
    #--------------------------------------------------------------------------
    # retrieve the names of the array2d
    #--------------------------------------------------------------------------
    proc names data {
	upvar 1 $data TAB
	return [lsort [array names TAB]]
    }
    #--------------------------------------------------------------------------

    
    namespace eval lines {

	namespace export *
	namespace ensemble create	
	
	#---------------------------------------------------------------------
	# array2d lines names
	#---------------------------------------------------------------------
	# retrieve the ordered list of names of lines
	#---------------------------------------------------------------------
	proc names data {
	    upvar 1 $data TAB
	    set NAMES [lsort [array names TAB]]
	    set NAMES [lmap X $NAMES {string range $X 0 [string first "," $X]-1}]

	    # for retrieving list of unique element see:
	    # https://wiki.tcl-lang.org/page/Unique+Element+List	    
	    set RES {}	    
	    foreach X $NAMES {
		if {$X ni $RES} {
		    lappend RES $X
		}
	    }
	    return $RES
	}
	#---------------------------------------------------------------------

	#---------------------------------------------------------------------
	# array2d lines length data
	#---------------------------------------------------------------------
	# length of the lines, in number of columns
	#---------------------------------------------------------------------
	proc length data {
	    upvar 1 $data TAB	 
	    return [llength [array2d columns names TAB]]
	}
	#---------------------------------------------------------------------
	
    }

    namespace eval columns {

	namespace export *
	namespace ensemble create

	#---------------------------------------------------------------------
	# array2d columns names
	#---------------------------------------------------------------------
	# retrieve the ordered list of names of columns
	#---------------------------------------------------------------------
	proc names data {
	    upvar 1 $data TAB
	    set NAMES [lsort [array names TAB]]
	    set NAMES [lmap X $NAMES {string range $X [string first "," $X]+1 end}]

	    # for retrieving list of unique element see:
	    # https://wiki.tcl-lang.org/page/Unique+Element+List	    
	    set RES {}	    
	    foreach X $NAMES {
		if {$X ni $RES} {
		    lappend RES $X
		}
	    }
	    return $RES
	}
	#---------------------------------------------------------------------
	
	#---------------------------------------------------------------------
	# array2 columns length
	#---------------------------------------------------------------------
	# length of the columns, in number of lines
	#---------------------------------------------------------------------
	proc length data {
	    upvar 1 $data TAB
	    return [llength [array2d lines names TAB]]
	}
	#---------------------------------------------------------------------
    }

    #--------------------------------------------------------------------------
    # array2d 2llist data
    #--------------------------------------------------------------------------
    # convert an array2d to a list of list (Llist)
    #--------------------------------------------------------------------------
    proc 2llist data {
	upvar 1 $data TAB
	set LINNAMES [array2d lines names TAB]
	set COLNAMES [array2d columns names TAB]

	set RES {}
	foreach L $LINNAMES {
	    set LST {}
	    foreach C $COLNAMES {
		lappend LST $TAB([join "$L $C" ","])
	    }
	    lappend RES $LST
	}
	return $RES
    }
    #--------------------------------------------------------------------------

    #--------------------------------------------------------------------------
    # array2d 2ldict data
    #--------------------------------------------------------------------------
    # convert an array2d to a list of dict (ldict)
    #--------------------------------------------------------------------------
    proc 2ldict data {
	upvar 1 $data TAB
	set LINNAMES [array2d lines names TAB]
	set COLNAMES [array2d columns names TAB]

	set RES {}
	foreach L $LINNAMES {
	    set DICT {}
	    foreach C $COLNAMES {
		dict set DICT $C $TAB([join "$L $C" ","])
	    }
	    lappend RES $DICT
	}
	return $RES
    }
    #--------------------------------------------------------------------------

    
    #--------------------------------------------------------------------------
    # array2d format data ?opt?
    #--------------------------------------------------------------------------
    # format a table with options.
    #
    # The options are:
    # ----------------
    #  -semigraphic : dataset is presented in semigraphic form. (exclude -csv)
    #  -csv         : dataset is presented with Caracter Separating Value.
    #                 (exclude -semigraphic, this is default)
    #  -fmt {...}   : the list of formatting string fore each columns
    #  -sep ".."    : the separating character between values, default is " "
    #  -eol ".."    : possible string to add at each end of line.
    #                 (typically \\\\ for LaTeX table)
    #
    # We re-use `datatable format` and its options.
    #--------------------------------------------------------------------------
    proc format {data args} {
	upvar 1 $data TAB
	return [datatable format -data [2llist TAB] {*}$args]
    }
    #--------------------------------------------------------------------------
}
