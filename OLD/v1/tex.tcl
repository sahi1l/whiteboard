proc Script {script} {
    puts $script
    exec osascript -e "tell app \"TeXShop\" to $script"
}
proc FileOpenQ {} {
    #check if TeXShop has any documents open
    return [expr [Script "number of documents"]>0]
}
proc GetDirectory {} {
    #Return the directory of the front window in TeXShop, if available
    if [FileOpenQ] {
        if [catch {set fname [file join [file dirname [Script "path of document of front window"]] "Doodles"]}] {return ""}
        file mkdir $fname
        return $fname
    } else {return ""}
}
proc UpdateDirectory {} {
    .dir config -text [GetDirectory]
}
proc AddReference {insert} {
    set cmd "set content of selection of document of front window to $insert"
    Script $cmd
    Script "latex document of front window"
    Script activate
}
bind .dir <1> {UpdateDirectory; exec open [GetDirectory]}
bind . <FocusIn> {UpdateDirectory}
