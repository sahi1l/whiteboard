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
