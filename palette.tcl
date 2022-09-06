pack [label .help.buttons -text "1:color  2:white  3:pointer" -bg grey -fg white] -anchor w

#----PALETTE----------------------------------------
foreach w [winfo children .palette] {destroy $w}
pack [button .palette.prevpage -text "<<" -command "MovePage -1" -padx 10] -side left
pack [button .palette.newpage -text "+" -command "NewPage" -padx 10] -side left
pack [button .palette.nextpage -text ">>" -command "MovePage 1" -padx 10] -side right
pack [button .palette.clear -text "Clear" -command ClearCanvas] -side left
bind . <Left> "MovePage -1"
bind . <Right> "MovePage +1"
#FIX: Clear should be undoable or at least have a confirm
#set colors "black red blue purple white"
set colors "black #cc6677 #332288 #DDCC77 #117733 white"
set currentcolor "black"
set lastpencolor "black"; #if currentcolor is white, last color that's not black
proc SelectColor {color} {
    global colors currentcolor lastpencolor
    foreach c $colors {
        .palette.$c config -relief raised
    }
    .palette.$color config -relief sunken
    if {$currentcolor!="white" && $currentcolor!="pointer"} {
        if {$color=="white" || $color=="pointer"} {
            set lastpencolor $currentcolor
        } else {
            set lastpencolor $color
        }
    }
    set currentcolor $color
}
foreach color $colors {
    pack [frame .palette.$color -bg $color -bd 4 -width 30 -height 30] -side left
    bind .palette.$color <1> "SelectColor $color"
}
lappend colors pointer
pack [label .palette.pointer -text "☜" -font "Times 24" -fg purple -bg grey] -side left
bind .palette.pointer <1> "SelectColor pointer"
bind . <Command-i> {SelectColor $lastpencolor}
bind . <Command-e> {SelectColor white}
bind . <Key-1> {SelectColor $lastpencolor}
bind . <Key-2> {SelectColor white}
bind . <Key-3> {SelectColor pointer}
SelectColor "black"
set widths "1 2 4 6 8"
set currentwidth 2
proc SelectWidth {width} {
    global widths currentwidth
    foreach w $widths {
        .palette.w$w config -bg grey
    }
    .palette.w$width config -bg white
    set currentwidth $width
}
foreach width $widths {
    pack [frame .palette.w$width -relief solid -bg white -bd $width -width 20 -height 20 ] -side left -padx 5
    bind .palette.w$width <1> "SelectWidth $width"
}
SelectWidth [lindex $widths 1]
####DASHES#####
pack [label .palette.dSolid -text "——" -relief solid -bg white -bd 1] -side left -padx 5
pack [label .palette.dDashed -text "- - -" -relief solid -bg white -bd 1] -side left -padx 5
bind .palette.dSolid <1> {SelectDash ""}
bind .palette.dDashed <1> {SelectDash "-"}
set currentdash ""
set dashes {"" "-"}
set dashbtns {dSolid dDashed}
proc SelectDash {pattern} {
    global currentdash dashes dashbtns
    foreach W $dashbtns {.palette.$W config -relief raised -bg gray}
    set btn [lindex $dashbtns [lsearch $dashes $pattern]]
    .palette.$btn config -relief sunken -bg white
    set currentdash $pattern
}
proc ToggleDash {} {
    global currentdash dashes
    set idx [expr ([lsearch $dashes $currentdash]+1)%([llength $dashes])]
    SelectDash [lindex $dashes $idx]
}
SelectDash ""
bind . <Command-d> {ToggleDash}
##########
pack [label .palette.autosave -text "Autosave?" -fg blue -bg grey]
bind .palette.autosave <1> {File::Autosave}
