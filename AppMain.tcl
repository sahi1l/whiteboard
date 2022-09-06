package require Tk
wm title . "WHITEBOARD"
wm geometry . +20+0
cd [file dirname [info script]]
source main.tcl
#source console.tcl
#bind . <Control-c> {::tk::console show}

