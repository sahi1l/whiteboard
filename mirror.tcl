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
