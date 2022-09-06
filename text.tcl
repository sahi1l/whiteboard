#Want to put keyboard commands in here
bind . <Command-t> {
#    puts $mousepg,$currentpage
    if {$mousepg == $currentpage} {
        Drawing::StartText $::mousex $::mousey ""
    }
}
set textdragx ""; set textdragy ""; #original click coordinates
#set textdragoffx ""; set textdragoffy ""
set textdragW ""
set textrootx ""; set textrooty ""; #original root coordinates
destroy .coords
#toplevel .coords
#grid [entry .coords.x -textvariable textdragx] [entry .coords.y -textvariable textdragy]
#grid [entry .coords.rx -textvariable textrootx] [entry .coords.ry -textvariable textrooty]
#grid [entry .coords.ox -textvariable textdragoffx] [entry .coords.oy -textvariable textdragoffy]
bind CanvasEntry <1> {
    set textdragW %W
    set textdragx %x
    set textdragy %y
    set page [GetPage %W]
    Activate $page
    set item [regsub ^.*\\. $textdragW ""]
    set coords [.c.pg$page coords $item]
    set textrootx [lindex $coords 0]
    set textrooty [lindex $coords 1]
    .c.pg$::page create text [lindex $coords 0] [lindex $coords 1] -text ▭ -font "Times 36" -tag "dragtmp"
}
bind CanvasEntry <B1-Motion> {
    global currentpage
    set nx [expr %x-$textdragx + $textrootx]
    set ny [expr %y-$textdragy + $textrooty]
    set item [regsub ^.*\\. $textdragW ""]
    .c.pg$currentpage coords dragtmp $nx $ny
#    foreach w [Drawing::WhereToDraw] {
#        $w.pg$currentpage coords $item $nx $ny
#    }
}
bind CanvasEntry <ButtonRelease-1> {
    global currentpage
    set nx [expr %x-$textdragx + $textrootx]
    set ny [expr %y-$textdragy + $textrooty]
    set item [regsub ^.*\\. $textdragW ""]
    .c.pg$currentpage delete dragtmp
    foreach w [Drawing::WhereToDraw] {
        $w.pg$currentpage coords $item $nx $ny
    }
    UpdateText $currentpage $item
}

bind CanvasEntry <Command-equal> {
    puts %W
    set value [set [%W cget -textvariable]]
    puts [%W cget -textvariable],$value,[string length $value]
    ChangeWidth %W [list to [string length [set [%W cget -textvariable]]]]
}
bind CanvasEntry <Command-Shift-equal> {ChangeFontSize %W 2}
bind CanvasEntry <Command-minus> {ChangeFontSize %W -2}
bind CanvasEntry <Command-Shift-comma> {ChangeWidth %W -2}
bind CanvasEntry <Command-Shift-period> {ChangeWidth %W 2}
bind CanvasEntry <FocusOut> {UpdateText [GetPage %W] [PathToIndex %W]}
bind CanvasEntry <Return> {TextUnfocus}
bind CanvasEntry <Command-Return> {AnotherBelow %W}
bind CanvasEntry <Command-Delete> {
    set tag [lindex [split %W .] end]
    set idx $currentpage$tag
    foreach w [Drawing::WhereToDraw] {
        $w.pg$currentpage coords $tag -1000 -1000; #move off the visible canvas by a lot?
        $w.pg$currentpage.$tag config -state disabled
    }
    set Elements::elements($idx) "Pass"
}
proc Insert {W A} {
    tk::CancelRepeat
    tk::EntryInsert $W $A
}
bind CanvasEntry <Control-Key> {
    array set replacements {a α b β g γ d δ e ε h η q θ k κ l λ m μ n ν p π r ρ s σ t τ f φ c ψ z ω}
    array set replacements {1 ₁ 2 ₂ 3 ₃ 4 ₄ 5 ₅ 6 ₆ 7 ₇ 8 ₈ 9 ₉ 0 ₀}
    array set replacements {G Γ D Δ Q Θ L Λ P Π S Σ F Φ C Ψ Z Ω}
    array set replacements {exclam ¹ at ² numbersign ³ dollar ⁴ percent ⁵}
    array set replacements {asciicircum ⁶ ampersand ⁷ asterisk ⁸ parenleft ⁹ parenright ⁰}

    if [info exists replacements(%K)] {
        Insert %W $replacements(%K)
    }
    break
}


    
bind CanvasEntry <Control-Key-l> {Insert %W λ; break}
proc TextUnfocus {} {
    global currentpage
    focus .c.pg$currentpage
}
proc TextBind {w} {
    bindtags $w {$w CanvasEntry Entry . all}
}

#Resize font
#Change width
#Add another text thingy right below this one (same size and all)I don

proc ChangeFontSize {w change} {
    #w should be the window itself
    set font [$w cget -font]
    set newsize [expr $change+[lindex $font 1]]
    if {$newsize<2} {set newsize 2}
    set font [lreplace $font 1 1 $newsize]
    set suffix [join [lrange [split $w .] 2 end] .]
    foreach f [Drawing::WhereToDraw] {
        $f.$suffix config -font $font
    }
    UpdateText $::currentpage [lindex [split $w .] end]
}
proc ChangeWidth {w change} {
    #If change is {to 10} then set to a specific value
    global currentpage
    set page .c.pg[GetPage $w]
    set id [PathToIndex $w]
    set x [lindex [$page coords $id] 0]
    set width [$w cget -width]
    if [llength $change]==1 {
        incr width $change
    } else {
        set width [lindex $change 1]
        puts "change=$change"
    }
    foreach f [Drawing::WhereToDraw] {
        $f.pg[GetPage $w].$id config -width $width
    }
    UpdateText $::currentpage $id
}
proc UpdateText {pg w} {
    #pg is 1, 2, 3
    #w is l0 etc
    set w [lindex [split $w .] end]; #just in case
    set idx $pg$w
    if [string match $Elements::elements($idx) "Pass"] {return}
    set widget .c.pg$pg.$w
    set width [$widget cget -width]
    set coords [.c.pg$pg coords $w]
    set font [$widget cget -font]
    set color [$widget cget -foreground]
    set result [list Text $w {*}$coords $Elements::texts($idx) $font $width $color]
    set Elements::elements($idx) $result
    return $result
}

proc AnotherBelow {w} {
    global currentpage
    set idx [lindex [split $w .] end]
    set cmd [UpdateText $currentpage $idx]
    set height [winfo height .c.pg$currentpage.$idx]
    set cmd [lreplace $cmd 3 3 [expr [lindex $cmd 3]+$height]]
    set cmd [lreplace $cmd 4 4 ""]
    set cmd [lreplace $cmd 0 1 StartText]
    Drawing::Redraw $cmd
    focus .c.pg$currentpage.[Tag current]
    #Use Drawing::StartText to generate a new one
    
    #Set the same font and width
}
