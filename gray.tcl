#this does the snap behavior when you hold down command
namespace eval Gray {
    proc dobind {w} {
        bind $w <Command-Motion> {Gray::show %x %y}
        bind $w <Command-Shift-Motion> {Gray::show %x %y 1}
    }
    proc hide {} {
        global currentpage
        set w .c.pg$currentpage
        $w coords gray 0 0 0 0
        $w coords horizontal 0 0 0 0
        $w coords vertical 0 0 0 0
    }
    proc show {x y {constrained 0}} {
        global currentpage
        set w .c.pg$currentpage
        set lastobject [Elements::Last $currentpage]
        $w coords horizontal -1000 $y 10000 $y
        $w coords vertical $x -1000 $x 10000
        if {$lastobject<0} {return}
        set coords [Elements::GetCoords $currentpage $lastobject]
#        set coords [$w coords LastObject]; #How to get last object
        if [llength $coords] {
            lassign [lrange $coords end-1 end] ox oy
            if $constrained {
                if abs($x-$ox)>abs($y-$oy) {set y $oy} else {set x $ox}
            }
            $w coords gray $ox $oy $x $y
        }
    }
    
}
