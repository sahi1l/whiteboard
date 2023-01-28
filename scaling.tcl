set scale 1
proc ScaleCoords {win coords} {
    global scale
    if {$win == ".c"} {
        return $coords
    } else {
        set ncoords []
        foreach co $coords {
            lappend ncoords [expr $co*$scale]
        }
        return $ncoords
    }
}
                   
proc SetScale {newscale} {
    global scale mirrorW mirrorH Npages cX cY
    set ratio [expr $newscale/$scale]
    set scale $newscale
    puts "SetScale $scale,$ratio"
    if ![winfo exists .mirror] {return 0}
    puts $Npages,[winfo children .mirror]
    for {set n 1} {$n<=$Npages} {incr n} {
        grid forget .mirror.pg$n
        grid forget .mirror.n$n
        set ncX [expr round($cX*$scale)]
        set ncY [expr round($cY*$scale)]
        puts "nc:$ncX,$ncY"
        .mirror.pg$n config -width $ncX -height $ncY
        .mirror.pg$n scale all 0 0 $ratio $ratio
    }
    ShowPages $::currentpage
}

proc ShrinkMirror {} {SetScale [expr $::scale*0.8]}
proc GrowMirror {} {SetScale [expr $::scale*1.25]}

bind . <Command-plus> {GrowMirror}
bind . <Command-minus> {ShrinkMirror}
bind .mirror <Command-plus> {GrowMirror}
bind .mirror <Command-minus> {ShrinkMirror}
