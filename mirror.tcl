set scale 1
destroy .mirror
set mirrorW [expr 2*$cX]
set mirrorH [expr $numwidth+$cY]
toplevel .mirror -width [expr $scale*$mirrorW]  -height [expr $scale*$mirrorH]
wm title .mirror "*MIRROR*"
set top .#dualMonitorCheck#
if {![winfo exists $top]} { toplevel $top; wm withdraw $top }
set sw [winfo screenwidth $top]
set mw [lindex [wm maxsize .] 0]
if {[expr {($sw * 1.1) < $mw}]} {
    wm geometry .mirror +[expr 50+$sw]+0; 
} else {
    wm geometry .mirror +[expr 2*$cX]+0
    wm iconify .mirror; 
}
proc ShowMirror {} {wm deiconify .mirror}
proc ResizeMirror {} {
    global mirrorW mirrorH scale
    if [winfo exists .mirror] {
        wm geometry .mirror [expr round($mirrorW*$scale)]x[expr round($mirrorH*$scale)]
    }
}
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
