bind .c.pg1 <Key> {CreateText %W %A %K 0}
bind .c.pg1 <Command-Key> {CreateText %W %A %K 1}
proc KeyRelease {key} {
    if {[string match $key "Meta_L"]} {
        puts CommandRelease
        return
    }
}
proc CreateText {w k key cmd} {
    global curtxt
    if {[string match $key "Meta_L"]} {
        puts Command
        return
    }
    set x [expr [winfo pointerx $w]-[winfo rootx $w]]
    set y [expr [winfo pointery $w]-[winfo rooty $w]]
    set txtQ [$w find overlapping $x $y [expr $x+1] [expr $y+1]]
    foreach txt $txtQ {
        if {[$w type $txt]=="text"} {
            if $cmd {
                if {$k=="=" || $k=="-"} {
                    if {$k=="="} {set k "+"}
                    lassign [$w itemcget $txt -font] font size
                    set size [expr $size$k 2]
                    $w itemconfig $txt -font "$font $size"
                }
            } else {
                if {$key=="BackSpace"} {
                    set newtxt [string replace [$w itemcget $txt -text] end end]
                } else {
                    set newtxt [$w itemcget $txt -text]$k
                }
                $w itemconfig $txt -text $newtxt
            }
            return
        }
    }
    set txt [$w create text $x $y -text $k -tags "text" -fill $::currentcolor -font "Times 18" -anchor w]
    incr curtxt
}
