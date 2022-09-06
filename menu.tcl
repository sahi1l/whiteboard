destroy .menubar
#----------------------------------------
proc MakeMItem {menu label command key} {
    if {[string length $key]>1} {
	set Acc $key; set acc $key
    } elseif {[string length $key]==0} {
	set Acc {}; set acc {};
    } elseif {[string is lower $key]} {
	set Acc "Command-[string toupper $key]"
	set acc "Command-$key"
    } elseif {[string is upper $key]} {
	set Acc "Command-Shift-$key"
	set acc "Command-$key"
    } else {
	set Acc $key
	set acc $key
    }
    if {$Acc ne ""} {set Acc "-accelerator $Acc"}
    .menubar$menu add command -label $label -command $command {*}$Acc
#    if {[string length $command]>0 && [string length $acc]>0} {
#	bind all <$acc> "$command"
#    }
}
#----------------------------------------
menu .menubar
. configure -menu .menubar
menu .menubar.mFile -tearoff 0
menu .menubar.mDisplay -tearoff 0

.menubar add cascade -menu .menubar.mFile -label File
.menubar add cascade -menu .menubar.mDisplay -label Display
MakeMItem .mDisplay "Undo" {Undo} z
MakeMItem .mDisplay "Redo" {Redo} y
MakeMItem .mFile "Save as PDF" {File::SavePDF} p; bind . <Command-p> {File::SavePDF}
MakeMItem .mFile "Save as Text" {File::Save 0} s; bind . <Command-s> {File::Save 0}
MakeMItem .mFile "Load" {File::Load} o; bind . <Command-o> {File::Load}
MakeMItem .mFile "Insert..." {File::PromptLoad} I; bind . <Command-I> {File::PromptLoad}
MakeMItem .mFile "Save To Clipboard" {} c; bind . <Command-c> {File::SaveToClipboard}
.menubar.mDisplay add separator
MakeMItem .mDisplay "Previous Page" {MovePage -1} "Left"
MakeMItem .mDisplay "Next Page" {MovePage +1} "Right"
.menubar.mDisplay add separator
MakeMItem .mDisplay "Show Mirror" {ShowMirror} 0
