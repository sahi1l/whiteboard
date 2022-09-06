source menu.tcl
destroy .name .palette .c .dir .mirror
set id [clock seconds]; #use for backups
set aR [expr 11/8.5]; #height divided by width
set cX 600
set cY [expr $cX*$aR]
set ptrwidth 16
array set objects {}
set currentpage 1; #what page number we're on
set numwidth 15; #width of page number
label .dir -text "Directory" -anchor w
frame .palette -bg grey -height 30
frame .c -width [expr 2*$cX] -height [expr $numwidth+$cY]; #contains all canvases
toplevel .mirror -width [expr 2*$cX] -height [expr $numwidth+$cY]
wm title .mirror "*MIRROR*"
wm title . "Whiteboard"

set top .#dualMonitorCheck#
if {![winfo exists $top]} { toplevel $top; wm withdraw $top }
set sw [winfo screenwidth $top]
set mw [lindex [wm maxsize .] 0]
puts $sw,$mw
if {[expr {($sw * 1.1) < $mw}]} {
    wm geometry .mirror +[expr 50+$sw]+0; #Or should $sw be $mw? I need to experiment
} else {
    wm geometry .mirror +[expr 2*$cX]+0
    wm iconify .mirror; #don't need it if only a single screen, right?
#    bind . <Command-0> {ShowMirror}
}
pack  .palette .c -side top -fill x
#----PAGES------------------------------------------
proc ShowMirror {} {wm deiconify .mirror;break}
set Npages 0
proc NewPage {} {
    global Npages cX cY objects
    incr Npages
    set objects($Npages) 0
    foreach f {".c" ".mirror"} {
        canvas $f.pg$Npages -width $cX -height $cY -bd 1 -relief sunken
        label $f.n$Npages -text $Npages
    }
    bind .c.pg$Npages <B1-Motion> {DrawLine %x %y}
    bind .c.pg$Npages <ButtonRelease-1> {DoneDrawing}
    bind .c.pg$Npages <1> "Activate $Npages; DrawDot %x %y"
    bind .c.pg$Npages <Shift-1> {DrawLine %x %y}; #draws straight lines for free!
#    bind .c.pg$Npages <Key> {CreateText %W %A %K 0}
#    bind .c.pg$Npages <Command-Key> {CreateText %W %A %K 1}
    bind .c.n$Npages <1> "Activate $Npages 1"
    if {$Npages>1} {
        ShowPages [expr $Npages-1]
    }
    return $Npages
}
proc MovePage {dir} {
    global currentpage Npages
    set nnum [expr $currentpage+$dir]
    if {$nnum<1} {return}
    if {$nnum>$Npages} {return}
    ShowPages $nnum
    Activate $nnum 1
}
set displayN 1
proc ShowPages {n} {
    global Npages currentpage displayN

    foreach w [winfo children .c] {
        grid remove $w
    }
    foreach w [winfo children .mirror] {
        grid remove $w
    }
    set whichtoactivate $n
    if {$n+1>$Npages && $n>1} {incr n -1}
    set np [expr $n+1]
    
    foreach f {.c .mirror} {
        grid $f.n$n -row 0 -column 0 -sticky news
        grid $f.pg$n -row 1 -column 0 -sticky news
    }
    if {$n==1} {
        .palette.prevpage config -state disabled
    } else {
        .palette.prevpage config -state normal
    }
    if {$np<$Npages} {
        .palette.nextpage config -state normal
    } else {
        .palette.nextpage config -state disabled
    }
#    if {$np<=$Npages} {
        puts $np,$Npages
        foreach f {.c .mirror} {
            grid $f.n$np -row 0 -column 1 -sticky news
            grid $f.pg$np -row 1 -column 1 -sticky news
        }
        set whichtoactivate $np
#    } else {Activate $n 1}
}
proc PageExists {n} {
    global Npages
    return [expr $n<=$Npages]
}
proc ResetCanvas {n} {
    global cX cY
    if [PageExists $n] {
        foreach f {.c .mirror} {
            $f.pg$n create rect 0 0 [expr $cX+100] [expr $cY+100] -fill white -tags dummy
            after idle "$f.pg$n delete dummy"
            $f.pg$n delete cursor
            $f.pg$n delete pointer
        }
    }
}
proc Activate {n {refresh 0}} {
    global currentpage Npages
    if {$refresh || $currentpage!=$n} {ResetCanvas $n}
    if {$currentpage == $n} {return}
    .c.n$currentpage config -bg white
    if [PageExists $currentpage+1] {
        .c.n[expr $currentpage+1] config -bg white
    }
    if [PageExists $n] {
        .c.n$n config -bg yellow
    }
    set currentpage $n
#    focus .c.pg$n
#    ResetCanvas $n
}
bind .c <Configure> "after 100 {ResetCanvas $currentpage; ResetCanvas [expr $currentpage+1]}"
#----DRAWING----------------------------------------
set redo {}; #list of coords to redo
proc ItemConfig {c obj} {
    set result {}
#    if [$c type $obj]=="text" {
#        set ics "font text fill anchor"
#    } else {
        set ics "fill width"
#    }
    foreach ic $ics {
        lappend result "-$ic" [$c itemcget $obj -$ic]
    }
#    set result "-fill "[$c itemcget $obj -fill]
#    append $result "-width "[$c itemc
                        
#    foreach ic [$c itemconfig $obj] {
#        if ![string match [lindex $ic 0] "-tags"] {
#            lappend result "[lindex $ic 0]"
#            lappend result "[lindex $ic end]"
#        }
#    }
    return $result
}
proc Undo {} {
    global objects currentpage redo
    set w .c.pg$currentpage
    set wm .mirror.pg$currentpage
    if [llength [$w coords o$objects($currentpage)]] {
        lappend redo [$w coords o$objects($currentpage)] [ItemConfig $w o$objects($currentpage)] [$w coords l$objects($currentpage)] [ItemConfig $w l$objects($currentpage)]
        foreach f {.c .mirror} {
            $f.pg$currentpage delete o$objects($currentpage)
            $f.pg$currentpage delete l$objects($currentpage)
        }
        if {$objects($currentpage)>0} {
            incr objects($currentpage) -1
        }
    }
}
proc AllTags {} {
    set w .c.pg$::currentpage
    set result {}
    foreach n [$w find all] {
        lappend result [$w gettags $n]
    }
    return [lsort $result]
}
proc Redo {} {
    global objects currentpage redo
    foreach f {.c .mirror} {
        set w $f.pg$currentpage
        
        if [llength $redo] {
            incr objects($currentpage)
            $w create oval 0 0 0 0 -tag o$objects($currentpage)
            $w create line 0 0 0 0 -tag l$objects($currentpage)
            $w coords o$objects($currentpage) [lindex $redo end-3]
            $w itemconfig o$objects($currentpage) {*}[lindex $redo end-2]
            $w coords l$objects($currentpage) [lindex $redo end-1]
            $w itemconfig l$objects($currentpage) {*}[lindex $redo end]
        }
    }
    set redo [lreplace $redo end-3 end]
}
proc ClearRedo {} {
    global redo
    set redo {}
}
bind . <Command-z> {Undo}
bind . <Command-y> {Redo}
proc oco {x y {w 0}} {
    if {$w==0} {
        set width $::currentwidth
    } else {
        set width $w
    }
    if {$::currentcolor==$::eraser} {set width [expr $width*8]}
    set r [expr $width/2]
    return "[expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r]"
}
set eraser "white"
proc DrawDot {x y} {
    global objects currentpage 
    incr objects($currentpage)
    ClearRedo
    set width $::currentwidth
    set color $::currentcolor
    if {$color == $::eraser} {
        set width [expr $width*8]
    } elseif {$color == "pointer"} {
        set color "red"
    }
    foreach f {.c .mirror} {
        if {$::currentcolor != "pointer"} {
            $f.pg$currentpage create oval [oco $x $y] -fill $color -outline "" -tag "o$objects($currentpage)"
            $f.pg$currentpage create oval [oco $x $y] -fill $color -outline "" -tag "cursor"
            if {$color=="white"} {
                $f.pg$currentpage itemconfig cursor -outline "black"
            }
            $f.pg$currentpage create line "$x $y $x $y" -fill $color -width $width -tag "l$objects($currentpage)"
        } else {
            $f.pg$currentpage delete pointer
            $f.pg$currentpage create text $x $y -fill "purple" -text "☜" -font "Times 48" -tag pointer
            #        $f.pg$currentpage create oval [oco $x $y $::ptrwidth] -fill $color -outline "" -tag "pointer"
        }
    }
}
proc DrawLine {x y} {
#don't add a new line, just edit the old one
    global lastpos objects currentpage
    foreach f {.c .mirror} {
        if {$::currentcolor!="pointer"} {
            set coords [$f.pg$currentpage coords l$objects($currentpage)]
            lappend coords $x $y
            $f.pg$currentpage coords l$objects($currentpage) $coords
            $f.pg$currentpage coords cursor [oco $x $y]
        } else {
            $f.pg$currentpage coords pointer $x $y
            #        $f.pg$currentpage coords pointer [oco $x $y $::ptrwidth]
        }
    }
}
proc DoneDrawing {} {
    global currentpage
    foreach f {.c .mirror} {
        catch {$f.pg$currentpage config pointer -fill white} {}
        $f.pg$currentpage delete cursor
        after idle "$f.pg$currentpage delete pointer"
    }
}
bind . <Command-g> {AddGrid}
proc AddGrid {} {
    global currentpage cX cY
    set spacing [expr round($cX/30)]
    foreach f {.c .mirror} {
        for {set x 0} {$x<=$cX} {incr x $spacing} {
            $f.pg$currentpage create line $x 0 $x $cY -dash . -tag grid
        }
        for {set y 0} {$y<=$cY} {incr y $spacing} {
            $f.pg$currentpage create line 0 $y $cX $y -dash . -tag grid
        }
        $f.pg$currentpage lower grid
    }
    
}
proc RemoveGrid {} {
    global currentpage
    foreach f {.c .mirror} {
        $f.pg$currentpage delete withtag grid
    }
}

#----FILENAME----------------------------------------
source filing.tcl
proc ClearCanvas {{n -1}} {
    global objects currentpage; # xmax ymax
    if [tk_dialog .clearOK "Clear this canvas?" "Should I clear this canvas?"  "" 0 "No" "Yes"] {
        if {$n==-1} {
            set n $currentpage
        }
        .c.pg$n delete all
        .mirror.pg$n delete all
        set objects($currentpage) 0
    }
}
source palette.tcl
NewPage
NewPage
ShowPages 1
Autosave
source clipboard.tcl

