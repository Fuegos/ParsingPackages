set packages "SD#04012011;135515;5544.6025;N;03739.6834;E;35;215;110;7\nM#груз доставлен"

set listPackages [split $packages \n]

set numPackage 1

foreach package $listPackages {
    set attributes [split $package #]
    set typePackage [lindex $attributes 0]
    
    puts "Package №$numPackage type $typePackage"
    switch $typePackage {
        SD {
            set fields [split [lindex $attributes 1] {;}]
    
            set date [lindex $fields 0]
            set time [lindex $fields 1]
            set lat [lindex $fields 2]
            set lon [lindex $fields 4]
            set speed [lindex $fields 6]
            set course [lindex $fields 7]
            set height [lindex $fields 8]
            set sats [lindex $fields 9]
            
            puts "date: $date"
            puts "time: $time"
            puts "lat: $lat"
            puts "lon: $lon"
            puts "speed: $speed"
            puts "course: $course"
            puts "height: $height"
            puts "sats: $sats"
        }
        M {
            set message [lindex $attributes 1]
        
            puts "message: $message"
        }
        default {
            puts "package type is unknow"
        }
    }
    
    incr numPackage
    
}
