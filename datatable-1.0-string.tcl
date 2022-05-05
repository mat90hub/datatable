#!/usr/bin/env tclsh
#-*- mode: tcl; coding: utf-8-unix; fill-column: 80; ispell-local-dictionary: "american"; -*-

#╔══════════════════════════════╗
#║ *** datatable-1.0-str.tm *** ║
#╚══════════════════════════════╝


#╔═════════════════════════════════════╗
#║ PROCEDURES HANDLING SIMPLE STRINGS  ║
#╚═════════════════════════════════════╝


    
#------------------------------------------------------------------------------
# The following procedures are exported to be accessible at upmost level.
# But they are loaded only if the names space datatable is loaded.
#
# Note that we don't need to export those commands, for them to be accessible.
#------------------------------------------------------------------------------


#--------------------------------------------------------------------------
# capitalize $str
#--------------------------------------------------------------------------
# Capitalize the string str
#--------------------------------------------------------------------------
proc capitalize {str} {
    set RES [string toupper [string range $str 0 0]]
    append RES [string range $str 1 end]
    return $RES
}
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# ymd2dmy $dateStr
#--------------------------------------------------------------------------
# Reverse a date string Y-M-D -> D/M/Y
#--------------------------------------------------------------------------
proc ymd2dmy {dateStr} {
    set D ""; set M ""; set Y "";
    regexp {(20[0-9][0-9])-([0-1]?[0-9])-([0-3]?[0-9])} $dateStr -> Y M D    
    if { $Y != "" && $M != "" && $D != "" } {
	return $D/$M/$Y
    } else {
	return ""
    }
    # this version with clock is theortically possible but gives problems
    clock format [clock scan $dateStr -format %Y-%m-%d] -format %d/%m/%Y
}
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# dmy2ymd $dateStr
#--------------------------------------------------------------------------
# Reverse a date string D/M/Y -> Y-M-D
#--------------------------------------------------------------------------
proc dmy2ymd {dateStr} {        
    regexp {([0-3]?[0-9])/([0-1]?[0-9])/(20[0-9][0-9])} $dateStr -> D M Y
    return $Y-$M-$D
    # version with closk
    # clock format [clock scan $dateStr -format %d/%m/%Y] -format %Y-%m-%d
}
#--------------------------------------------------------------------------


#--------------------------------------------------------------------------
# ymd2clockFmt $dateStr ?format? ?locale?
#--------------------------------------------------------------------------
# format a date Y-M-D to whatever format accepted by clock format
#--------------------------------------------------------------------------
#  by default French full format
#
# just transmit to clock format (see general help for it)
# main usefeful format codes:
#  %a %A nom du jour en abrégé ou complet (selon localisation)
#  %b %B nom du moi en abrégé ou complet
#  %d numéro du jour du mois (01 - 31).
#  %y %Y année sur deux ou quatre chiffres
#  %m Numéro du mois (01 - 12).
#  %U Semaine de l 'année (00 - 52), Dimanche est le premier jour de la semaine.
#  %w Numéro du jour de la semaine. (Dimanche = 0).
#  %W Semaine de l 'année (00 - 52), Lundi est le premier jour de la semaine
proc ymd2clockFmt {dateStr {formatStr "%A %d %B %Y"} {locale fr_FR}} {
    return [clock format [clock scan $dateStr -format "%Y-%m-%d"] -format $formatStr -locale $locale]
}
#--------------------------------------------------------------------------


# -------------------------------------------------------------------------
# is_valid_date $str ?date_format?
# -------------------------------------------------------------------------
# Recognize if a given string is a valid date as per fmt string. Default
# format is %d/%m/%Y
# -------------------------------------------------------------------------
proc is_valid_date {date {date_format "%d/%m/%Y"}} {    
    return [string equal [clock format [clock scan $date -format $date_format] -format $date_format] $date]
}


# # If don't want to presuppose a date format, here an example (but more
# # permissive).
# #
# # YYYY-MM-DD   YYYY/MM/DD
# # DD/MM/YYYY   DD/MM/YY   DD-MM-YYYY  DD-MM-YY
# # MM-DD-YYYY   MM-DD-YY   MM/DD/YYYYY  MM/DD/YY
# if [regexp {([0-9]{4}|[0-9]{1,2})[-/]([0-9]{1,2})[-/]([0-9]{2}|[0-9]{4})} $CELL ->] {
#     return "date"
# } elseif [regexp {[0-2][0-9]:[0-5][0-9](:[0-5][0-9])}] {
#     return "time" 
# } elseif [regexp {([0-9]{4}|[0-3][0-9])[/-][0-3][3-9][/-]([0-9]{4}|[0-3][0-9]) [0-2][0-9]:[0-5][0-9](:[0-5][0-9])} $CELL ->] {
#     return "date&time"
# } {
#     return "not a recognized date"
# }
    
# -------------------------------------------------------------------------

