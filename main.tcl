# Input value
set packages "#SD#04102011;135515;5504.6025;S;03739.6834;E;35;315;110;7\r\n#M#груз доставлен\r\n#M#Ошибка\r\n"

proc getSignFromLetter {letter} {
    switch -regexp -- $letter {
        {^[S|W]$} {
            return -1
        }
        default {
            return 1
        }
    }
}

proc extractDegree {name data letter startRange endRange} {
    if {[regexp {^([0-9]{2,3})([0-9]{2}\.[0-9]+)$} $data fullMatch degree minute]} {
        set degreeDec [convertToDec $degree]
        
        if {[catch {
            checkRange $degreeDec $startRange $endRange  
        } errmsg]} {
            return -code error "Error convert '$name->degree': $errmsg"
        }
        
        set minuteDec [ expr { $minute / 60 } ]
        
        if {[catch {
            checkRange $minuteDec 0 1  
        } errmsg]} {
            return -code error "Error convert '$name->minute': $errmsg"
        }
        
        return [expr { [getSignFromLetter $letter] * ($degreeDec + $minuteDec) }]
    } {
        return -code error "Error convert '$name': Invalid value"
    }
}

proc extractFullDate {date time} {
    if {![regexp {^(0[1-9]|[1-2][0-9]|3[0-1])(0[1-9]|1[0-2])([0-9]{4})$} $date fullMatch day mounth year]} {
        return -code error "Error convert 'date': Invalid value"
    }
    
    if {![regexp {^([0-1][0-9]|2[0-3])([0-5][0-9])([0-5][0-9])$} $time fullMatch hour minute second]} {
        return -code error "Error convert 'time': Invalid value"
    }
    
    set fullDate [clock scan $date$time -format {%d%m%Y%H%M%S}]
    
    return [clock format $fullDate -format {%Y/%m/%d %H:%M:%S}]
}

proc extractDec {name value startRange {endRange ""}} {
    if {[catch {
        checkDec $value
    } errmsg]} {
        return -code error "Error convert '$name': $errmsg"
    }
    
    set valueDec [convertToDec $value]
    
    if {[catch {
        checkRange $valueDec $startRange $endRange  
    } errmsg]} {
        return -code error "Error convert '$name': $errmsg"
    }
    
    return $valueDec
}

proc checkDec {value} {
    if {![regexp {^-?[0-9]+$} $value]} {
        error "Invalid value"
    }
}

proc checkRange {value startRange {endRange ""}} {
    if {$endRange == ""} {
        if {$value < $startRange} {
            error "Value $value is out of range (value must be equal or greater then $startRange)"
        }
    } else {
        if {$value < $startRange || $value > $endRange } {
            error "Value $value is out of range \[$startRange\;$endRange\]"
        }
    } 
}

proc convertToDec {value} {
    scan $value %d decValue
    return $decValue
}

proc printField {name value} {
    puts [format "%10s: %-20s" $name $value]
}

proc printDB {db} {
    dict for {id info} $db {
        dict with info {
            puts "Package №$id type $type"
            foreach field [dict keys $data] {
                printField $field [dict get $data $field]
            }
        }
    }
}

proc clearDB {db} {
    foreach key [dict keys $db] {
        dict unset db $key
    }
    return $db
}

# Start parsing
set listPackages [regexp -all -inline -- {#[A-Z]+#[^\r\n]*\r\n} $packages]
set numPackage 1

foreach package $listPackages {
    regexp {([A-Z]+)#([^\r\n]*)} $package fullMatch typePackage data
    if {[catch {
        switch $typePackage {
            SD {
                set fields [split $data {;}]
               
                dict set db $numPackage type $typePackage
                dict set db $numPackage data date [
                    extractFullDate [lindex $fields 0] [lindex $fields 1]
                ]
                dict set db $numPackage data lat [
                    extractDegree "lat" [lindex $fields 2] [lindex $fields 3] 0 90
                ]
                dict set db $numPackage data lon [
                    extractDegree "lon" [lindex $fields 4] [lindex $fields 5] 0 180
                ]
                dict set db $numPackage data speed [
                    extractDec "speed" [lindex $fields 6] 0
                ]
                dict set db $numPackage data course [
                    extractDec "course" [lindex $fields 7] 0 360
                ]
                dict set db $numPackage data height [
                    extractDec "height" [lindex $fields 8] 0
                ]
                dict set db $numPackage data sats [
                    extractDec "height" [lindex $fields 9] 0
                ]
            }
            M {
                dict set db $numPackage type $typePackage
                dict set db $numPackage data message $data        
            }
            default {
                error "Package type '$typePackage' is unknow"
            }
        }
    } errmsg]} {
        puts "$errmsg"
        set db [clearDB $db]
        break 
    }
    
    incr numPackage
}

printDB $db



