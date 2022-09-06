set eraser "white"
set tagpfx "l"
proc Tag {{num "new"}} {
    global tagpfx currentpage
    if [string match $num "new"] {
        set num [expr 1+[Elements::Last $currentpage]]
    } elseif [string match $num "current"] {
        set num [expr [Elements::Last $currentpage]]
    }
    return "$tagpfx$num"
}
proc PathToIndex {path} {
    return [lindex [split $path .] end]
}
proc GetPage {tag} {
    global tagpfx
    set x [split $tag .]
    if [llength $x]>1 {
        return [regsub pg [lindex $x 2] ""]
    } else {
        return [lindex [split $tag $tagpfx] 0]
    }
}
proc GetIndex {tag} {
    global tagpfx
    return $tagpfx[lindex [split [PathToIndex $tag] $tagpfx] end]
}

namespace eval Drawing {
    namespace export StartLine Line Delete Clear Redrawtexts

    proc WhereToDraw {} {
        if [winfo exists .print] {
            return .print
        } elseif [winfo exists .mirror] {
            return ".mirror .c"
        } else {return .c}
    }
    
    proc StartLine {coords {width ""} {color ""} {dash ""}} {
        global currentpage
        log "StartLine: $dash"
        set tag [Tag new]
        
        set idx [Elements::Add $currentpage "Line $tag [list $coords] $width $color $dash"]
        Line $tag $coords $width $color $dash
        
    }
    proc ContinueLine {coords {width ""} {color ""} {dash ""}} {
        global currentpage
        set coords [Elements::Append $currentpage {*}$coords]
        set tag [Tag current]
        if [llength [.c.pg$currentpage find withtag $tag]] {
            foreach f [WhereToDraw] {
                set w $f.pg$currentpage
                $w coords $tag {*}[ScaleCoords $f $coords]
            }
        } else {
            log "In ContinueLine: $dash"

            Line $tag $coords $width $color $dash; #this is mostly for undo stuff
        }
    }
    proc Line {tag coords {width ""} {color ""} {dash ""}} {
        global currentpage
        log "Line: $dash"
        if [llength $coords]<4 {return}
        foreach f [WhereToDraw] {
            $f.pg$currentpage create line [ScaleCoords $f $coords] -fill $color -width $width -tag $tag -dash $dash
        }
    }
    set defaultfont "Baskerville 18"
    set defaultwidth 40
    proc StartText {x y text {font "Baskerville 18"} {width 40} {color ""}} {
        if ![llength $color] {
            if ![string match $::currentcolor white] {
                set color $::currentcolor
        } else {set color $::lastpencolor}
        }
        global currentpage
        #    puts "Drawing::StartText"
        set tag [Tag new]
        
        set idx [Elements::Add $currentpage "Text $tag $x $y $text $font $width"]
        Text $tag $x $y $text $font $width $color
    }
    proc Text {tag x y text font width color} {
        global currentpage
        puts "Drawing::Text: $tag,$x,$y,$font,$width,$color"
        foreach f [WhereToDraw] {
            set w $f.pg$currentpage.$tag
            #FIX: Change the font size
            entry $w -font $font -width $width -textvariable [Elements::AddText $currentpage $tag $text] -borderwidth 0 -foreground $color
            if [string match $f .c] {
                focus $w 
                set Elements::texts($currentpage$tag) $text
            }
            TextBind $w
            $f.pg$currentpage create window {*}[ScaleCoords $f "$x $y"] -window $w -tags $tag
        }
        #    puts "End Drawing::Text"
    }
    proc Delete {page index} {
        if [llength $index] {
            foreach f [WhereToDraw] {
                $f.pg$page delete $index; #[Tag $index]
                destroy $f.pg$page.$index 
            }
            #        destroy .c.pg$page.$index; #[Tag $index]
        }
    }
    proc Clear {page} {
        foreach w [WhereToDraw] {
            $w.pg$page delete all
            foreach x [winfo children $w.pg$page] {destroy $x}
        }
    }
    
    proc Pass {} {
        ; #to replace deleted things
    }
    proc Redraw {cmd {pg ""}} {
        if {[llength $pg] && $pg!=$::currentpage} {
            ShowPages $pg
            set ::currentpage $pg
        }
        eval $cmd; #Running this here means it is in the Drawing namespace, cool!
    }
}
