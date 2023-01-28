source log.tcl
source menu.tcl
source text.tcl
source gray.tcl
destroy .name .palette .c .dir .mirror
set scale 1; #amount by which mirror is scaled relative to the original
set id [clock seconds]; #use for backups
set aR [expr 11/8.5]; #height divided by width
set cX 700
set cY [expr $cX*$aR]
set Npages 0
set mirrorX 100; #the distance from the left edge for MIRROR
set ptrwidth 16
array set objects {}
set currentpage 1; #what page number we're on
set numwidth 15; #width of page number
label .dir -text "Directory" -anchor w
frame .help -bg grey -height 20
frame .palette -bg grey -height 30
frame .c -width [expr 2*$cX] -height [expr $numwidth+$cY]; #contains all canvases
toplevel .mirror -width [expr 2*$cX] -height [expr $numwidth+$cY]
wm title .mirror "*MIRROR*"
wm title . "Whiteboard"
pack  .palette .c -side top -fill x

source mirror.tcl
source scaling.tcl
source elements.tcl
source drawing.tcl
#----PAGES------------------------------------------
set mousex 0; set mousey 0; set mousepg 0
proc SaveMouse {x y w} {
    set ::mousex $x
    set ::mousey $y
    set ::mousepg [regsub "\.c\.pg" $w ""]
}
proc NewPage {} {
    global Npages cX cY scale
    incr Npages
    Elements::NewPage $Npages
    foreach f [Drawing::WhereToDraw] {
        set herescale 1
        if [string match $f ".mirror"] {set herescale $scale}
        canvas $f.pg$Npages -width [expr $cX*$herescale] -height [expr $cY*$herescale] -bd 3 -relief sunken -bg white
        label $f.n$Npages -text $Npages
    }
    .c.pg$Npages create line 0 0 0 0 -fill "black" -dash . -tag gray
    .c.pg$Npages create line 0 0 0 0 -fill "blue" -dash . -tag horizontal
    .c.pg$Npages create line 0 0 0 0 -fill "blue" -dash . -tag vertical
    bind .c.pg$Npages <Motion> {Gray::hide; SaveMouse %x %y %W}
    bind .c.pg$Npages <B1-Motion> {Drag %x %y}
    Gray::dobind .c.pg$Npages
    bind .c.pg$Npages <ButtonRelease-1> {DoneDrawing}
    bind .c.pg$Npages <1> "Activate $Npages; Click %x %y"
    bind .c.pg$Npages <Shift-1> {Drag %x %y;break}; #draws straight lines for free!
    bind .c.n$Npages <1> "Activate $Npages 1"

    if {$Npages>1} {
        ShowPages [expr $Npages-1]; #put the new page on the right-hand side
    }
    return $Npages
}

proc MovePage {dir} {
    #Move to a new page, this means
    global currentpage Npages
    TextUnfocus
    set nnum [expr $currentpage+$dir]
    if {$nnum<1} {return}
    if {$nnum>$Npages} {return}
    ShowPages $nnum
    Activate $nnum 1
}

proc ShowPages {n} {
    global Npages currentpage
    set wheretodraw [Drawing::WhereToDraw]
    if ![string match $wheretodraw ".print"] {
        foreach w [winfo children .c] {grid remove $w}
        if [winfo exists .mirror] {
            foreach w [winfo children .mirror] {grid remove $w}
        }
        
        if {$n+1>$Npages && $n>1} {incr n -1}
        set np [expr $n+1]
        set currentpage $n
        foreach f $wheretodraw {
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
        if {$np<=$Npages} {
            foreach f $wheretodraw {
                grid $f.n$np -row 0 -column 1 -sticky news
                grid $f.pg$np -row 1 -column 1 -sticky news
            }
        }
    }
    Activate $n 1
}

proc PageExists {n} {
    global Npages
    return [expr $n<=$Npages]
}

proc ResetCanvas {n} {
    #This is to prevent glitches
    global cX cY
    if [PageExists $n] {
        foreach f [Drawing::WhereToDraw] {
            $f.pg$n create rect 0 0 [expr $cX+100] [expr $cY+100] -fill white -tags dummy
            after idle "$f.pg$n delete dummy"
            $f.pg$n delete pointer
        }
    }
}
bind .c <Configure> "after 100 {ResetCanvas $currentpage; ResetCanvas [expr $currentpage+1]}"

proc Activate {n {refresh 0}} {
    global currentpage Npages
    TextUnfocus
    if {$refresh || $currentpage!=$n} {ResetCanvas $n}
    .c.n$currentpage config -bg white
    if [PageExists $currentpage+1] {
        .c.n[expr $currentpage+1] config -bg white
    }
    if [PageExists $n] {
        .c.n$n config -bg yellow
    }
    set currentpage $n
}
#----UNDO/REDO----------------------------------------
bind . <Command-z> {Undo}
bind . <Command-y> {Redo}
proc Undo {} {
    global currentpage
    set todelete [Elements::Undo $currentpage]
    if [llength $todelete]>=0 {
        Drawing::Delete $currentpage $todelete
    }
    if {[Elements::SanityCheck $currentpage]>0} {puts "Something is wrong"}
    
}

proc Redo {} {
    global currentpage
    set tomove [Elements::Redo $currentpage]
    if [llength $tomove] {
        Drawing::Redraw $tomove
    }
    if {[Elements::SanityCheck $currentpage]>0} {puts "Something is wrong"}
}
proc ClearCanvas {{n -1} {prompt "yes"}} {
    global currentpage; # xmax ymax
    if {$n==-1} {
        set n $currentpage
    }
    set noprompt [expr [llength [array get Elements::elements $n$::tagpfx*]]==0 || [string match $prompt noprompt]]
    
    if {$noprompt ||
        [tk_dialog .clearOK "Clear this canvas?" "Should I clear this canvas?"  "" 0 "No" "Yes"]} {
        Drawing::Clear $n
        Elements::Clear $n
    }
}

#--------------------MOUSE--------------------
proc ScaledCoords {win x y} {
    global scale
    if {$win == ".mirror"} {
        return "[expr $scale*$x] [expr $scale*$y]"
    } else {
        return "$x $y"
    }
}
proc Click {x y} {
    global currentpage currentdash
    TextUnfocus
    set width $::currentwidth
    set color $::currentcolor
    if {$color == $::eraser} {
            set width [expr $width*8]
    }
    if {$color == "pointer"} {
        foreach f [Drawing::WhereToDraw] {
            $f.pg$currentpage delete pointer
            $f.pg$currentpage create text [ScaledCoords $f $x $y] -fill purple -text "☜" -font "Times 48" -tag pointer
        }
    } else {
        Drawing::StartLine "$x $y" $width $color $currentdash
    }
}
proc Drag {x y} {
    global currentpage
    set width $::currentwidth
    set color $::currentcolor
    if {$color == $::eraser} {
            set width [expr $width*8]
    }
    if {$color=="pointer"} {
        foreach f [Drawing::WhereToDraw] {
            $f.pg$currentpage coords pointer {*}[ScaledCoords $f $x $y]
        }
    } else {
        Drawing::ContinueLine "$x $y" $width $color $::currentdash
    }
}
proc DoneDrawing {} {
    global currentpage
    foreach f [Drawing::WhereToDraw] {
        catch {$f.pg$currentpage config pointer -fill white} {}; #necessary?
        after idle "$f.pg$currentpage delete pointer"
    }
}

#source grid.tcl
source files.tcl
File::init
source palette.tcl
NewPage
NewPage
ShowPages 1
#Autosave
source clipboard.tcl

