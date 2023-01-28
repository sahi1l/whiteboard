#Goal: from the current canvas, copy the drawn figure to the clipboard using screencapture
#screencapture: -R captures rectange using format x,y,width,height

proc alphabbox {w} {
    set bbox [regsub -all -- "-\[0-9\]+" [$w bbox all] "0"]
    
    if [llength $bbox]==0 {
        return ""
    }
    
    set x [expr [lindex $bbox 0]+[winfo rootx $w]]
    set y [expr [lindex $bbox 1]+[winfo rooty $w]]
    set width  [expr [lindex $bbox 2]-[lindex $bbox 0]]
    set height [expr [lindex $bbox 3]-[lindex $bbox 1]]
    return "$x $y $width $height"
}
proc toclipboard {} {
    global curnum
    set R [join [alphabbox .c.pg$curnum] ,]
    if [llength $R] {
        exec screencapture -t pdf -c -R $R
    }
}
bind . <Command-c> {toclipboard}


    proc Duplicate {n} {
        #Creates a duplicate of the current page in a window called .print, for printing
        set w ".c.pg$n"
        destroy .print; toplevel .print
        ::tk::unsupported::MacWindowStyle style .print plain noTitleBar
        #FIX: Check for Mac; if not, just toplevel it?
        wm geometry .print +0+0
        lower .print
        wm title .print "Print"
        pack [canvas .print.pg$n -width [expr 200+[winfo width $w]] -height [expr 200+[winfo height $w]]]
        #Now recreate all the objects in elements
        Redraw $n
        #Drawing parameters might need to take a parameter for the right canvas
        .print.pg$n lower grid
        TextUnfocus
    }

proc SaveToClipboard {} {
    global Npages env
    set pg $::currentpage
    Duplicate $pg
    update
    set wid [exec ./GetWindowID [file tail [info nameofexecutable]] Print]
    exec screencapture -c -i -o -l $wid -t pdf 
    destroy .print
}
