set id [clock seconds]
set tmpdir "/tmp/hill-whiteboard"
if {![file exists $tmpdir]} {
    file mkdir $tmpdir
}
set autosavefile [file join $tmpdir autosave$id.txt]
proc Duplicate {n} {
    global objects
    set w ".c.pg$n"
    destroy .print
    toplevel .print
    ::tk::unsupported::MacWindowStyle style .print plain noTitleBar
    wm geometry .print +0+0
    lower .print
    wm title .print "Print"
    pack [canvas .print.c -width [winfo width $w] -height [winfo height $w]]
    for {set i 1} {$i<=$objects($n)} {incr i} {
        if [llength [$w coords o$i]] {
        }
        if [llength [$w coords l$i]] {
            .print.c create line [$w coords l$i] -tags l$i
            .print.c itemconfig l$i {*}[ItemConfig $w l$i]
        }
    }
    foreach num [$w find withtag grid] {
        .print.c create line [$w coords $num] -tag grid -dash .
    }
    .print.c lower grid
}
proc Save {{autosave 1}} {
    global Npages objects
    if $autosave {
        set fname $::autosavefile
    } else {
        set fname [tk_getSaveFile]
    }
    if ![llength $fname] {return}
    set tosave {}
    #structure of tosave 
    #list of pages
    #each page 
    set F [open $fname "w"]
    for {set pg 1} {$pg<=$Npages} {incr pg} {
        puts $F "#$pg"
        set w ".c.pg$pg"
        for {set i 1} {$i<=$objects($pg)} {incr i} {
            puts $F [$w coords o$i]
            puts $F [$w coords l$i]
            puts $F [ItemConfig $w o$i]
            puts $F [ItemConfig $w l$i]
        }
#        lappend tosave $thepage
    }
#    set F [open $fname "w"]
#    puts $F "set toload {$tosave}"
    close $F
}
proc Load {{fname ""}} {
    global Npages objects
    if ![llength $fname] {
        set fname [tk_getOpenFile]
        if ![llength $fname] {return}
    }
    set F [open $fname "r"]
    set Npages 0
    foreach w [winfo children .c] {destroy $w}; #delete all current pages
    array unset objects; array set objects {}; #reset object counts
    while {1} {
        set line [gets $F]
        if [eof $F] {close $F; break;}
        if [string match "#*" $line] {
            set pgno [NewPage]
            puts "NewPage: $pgno"
            set w .c.pg$pgno
            set i 1
        } else {
            set oc $line
            if ![llength $oc] {break}
            set lc [gets $F]
            set of [gets $F]
            set lf [gets $F]
            $w create oval $oc -tags o$i
            $w create line $lc -tags l$i
            $w itemconfig o$i {*}$of
            $w itemconfig l$i {*}$lf
            set currentpage($pgno) $i
            incr i
        }
    }
    ShowPages 1
}
proc Autosave {} {
    bind .palette.autosave <1> {}
    Save 
    .palette.autosave config -text "Autosaved [clock format [clock seconds] -format %H:%M]"
    after 5000 {.palette.autosave config -text ""}
    after 60000 {Autosave}; #save every minute
}
bind . <Command-p> {SavePDF}
bind . <Command-c> {SaveToClipboard}
bind . <Command-s> {Save 0}
bind . <Command-o> {Load}

proc SavePDF {} {
    global Npages env
    set fname [tk_getSaveFile]
    if [llength $fname] {
        set dir $::tmpdir
        set env(PATH) "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Library/TeX/texbin"
        #        set cmd "pdfjoin --outfile $fname"
        set cmd "./join.sh $fname"
        file mkdir $dir
        for {set pg 1} {$pg<=$Npages} {incr pg} {
            Duplicate $pg
            update
            set wid [exec ./GetWindowID [file tail [info nameofexecutable]] Print]
            exec screencapture -o -l $wid -t pdf $dir/page$pg.pdf
            append cmd " " $dir/page$pg.pdf
        }
        destroy .print
        exec {*}"$cmd" 

    }
}
proc SaveToClipboard {} {
    global Npages env
        set dir $::tmpdir
    set env(PATH) "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Library/TeX/texbin"
    set pg $::currentpage
    Duplicate $pg
    update
    set wid [exec ./GetWindowID [file tail [info nameofexecutable]] Print]
    exec screencapture -c -i -o -l $wid -t pdf 
    destroy .print
}
