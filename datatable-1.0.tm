#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔═══════════════════════════╗
#║ *** datatable-1.0.tm  *** ║
#╚═══════════════════════════╝

#
# license GPL 3.0
#
# Copyright (c) 
# 


package provide datatable 1.0

# we gives the path to other source files in relation to the location
# of this file.
if {[string length [set SCRIPT [info script]]] > 0} {
    set tabDir [file dirname [file normalize $SCRIPT]]
} {
    set tabDir [pwd]
}


namespace eval datatable {

    # the subnamespace must be exported, if we want them accessible
    namespace export to from frame list dcol ldict

    namespace ensemble create
    
    # Datatable are lists of lists drawn line by lines.
    # We do here datatable based either on list of dict or list of list.
    # The most internal structure (dict or list) represent the structure of a record split
    # into different fields corresponding to columns in the datatable representation.            

    # procedures to draw semigraphic element for datatable in text form in ::datatable::frame
    source "$tabDir/datatable-1.0-frame.tcl"

    # procedures to handle lists in namespace ::datatable::list
    source "$tabDir/datatable-1.0-list.tcl"

    # procedures to handle lists in namespace ::datatable::llist
    source "$tabDir/datatable-1.0-llist.tcl"

    
    #╔═════════════════════════════════════════════════════════════════════╗
    #║ PROCEDURES TO TRANSFER BETWEEN LLIST - LDICT - DCOL                 ║
    #╚═════════════════════════════════════════════════════════════════════╝

    # llist is the default structure for datatable, but under certains
    # circumstances other type of format may be useful.

    # ldict: list of dictionaries is an alternative usual structure give by
    # tdbc.

    # dcol :: dictionaries of columns. The keys are the columns title and the
    # valus are list giving the content of the column.

    # No check on the input to keep speed. It must be manage by the user (see
    # subnamespace ldic or dcol

    # we define a subnamespace for the transform from llist to other strutures.
    namespace eval to {

	namespace export ldict dcol 
	namespace ensemble create
	
	#------------------------------------------------------------------
	# datatable to ldict $data $headers
	#------------------------------------------------------------------
	# transform the data to a list of dicts with given headers as keys
	#------------------------------------------------------------------
	proc ldict {data headers} {
	    if {[llength $data] == 0} {return}
	    foreach L $data {
		foreach h $headers e $L {
		    dict set record $h $e
		}
		lappend result $record
	    }	
	    return $result
	}
	#----------------------------------------------------------------------

	#----------------------------------------------------------------------
	# datatable to dcol $data $headers
	#----------------------------------------------------------------------
	# Transform the llist of a datatable to a cdict with given headers.
	# The llist is first transposed, giving a llist of columns and then
	# converted to a dictionary.
	#----------------------------------------------------------------------
	proc dcol {data headers} {
	    if {[llength $data] == 0} {return}
	    set CL [datatable transpose $data]
	    foreach H $headers L $CL {dict set DL $H $L}
	    return $DL
	}
	#----------------------------------------------------------------------
    }

    # we define a subnamespace for the reverse transform, from other strutures
    # to llist.
    namespace eval from {

	namespace export ldict dcol
	namespace ensemble create
	
	#----------------------------------------------------------------------
	# datatable from ldict $data
	#----------------------------------------------------------------------
	# transform a list of dicts to a list of lists
	#----------------------------------------------------------------------
	# The order of a dictionary is not granted. To keep reproductibility,
	# the keys of the dictionary are ordered in lexical order at conversion
	# to a list of values (done in `datatable ldict headers list`)
	#----------------------------------------------------------------------	
	proc ldict data {
	    # we iterate first to now the exact list of expected headers
	    set HDR [datatable ldict headers list $data]

	    if {[llength $data] == 0} {return}
	    foreach D $data {
		# we need to check if each header is filled or empty
		set L {}
		foreach H $HDR {
		    if [dict exists $D $H] {
			lappend L [dict get $D $H]
		    } {
			lappend L {}
		    }
		}
		lappend RES $L		
	    }
	    return $RES
	}
	#----------------------------------------------------------------------

	#----------------------------------------------------------------------
	# datatable from dcol $data
	#----------------------------------------------------------------------
	# Retrieve a datatable llist from a dictionary of columns.
	#----------------------------------------------------------------------
	proc dcol data {
	    return [datatable transpose [dict values $data]]	
	}
	#----------------------------------------------------------------------
	
    }
       

    #╔════════════════════════════════════════════════════════════════════════╗
    #║ PROCEDURES BASED ON LIST OF DICTS                ( ldict )             ║
    #╚════════════════════════════════════════════════════════════════════════╝

    source "$tabDir/datatable-1.0-ldict.tcl"

    #╔════════════════════════════════════════════════════════════════════════╗
    #║ PROCEDURES BASED ON A DICTIONARY OF COLUMNS      ( dcol )              ║
    #╚════════════════════════════════════════════════════════════════════════╝

    source "$tabDir/datatable-1.0-dcol.tcl"

}


#╔═════════════════════════════════════════════════════════════════╗
#║ FORMAT PROCEDURES ARE GATHERED IN SEPARATE FILE                 ║
#╚═════════════════════════════════════════════════════════════════╝

# Either the simple options handling proposed here (no extra package required)

source "$tabDir/datatable-1.0-format.tcl"

# Either using the package parse_args, but it needs to be installed
# source "$tabDir/datatable-1.0-format-with-parse_args.tcl"


#╔═════════════════════════════════════════════════════════════════╗
#║ SIDE SET OF USEFUL PROCEDURES LOADED ON THE SAME TIME           ║
#╚═════════════════════════════════════════════════════════════════╝

# procedures for strings in namesspace ::datatable::string
source "$tabDir/datatable-1.0-string.tcl"
