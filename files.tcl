namespace eval File {
    proc init {} {
        variable id [clock seconds]; #identifies the session
        variable tmpdir "/tmp/hill-whiteboard"
        if {![file exists $tmpdir]} {
            file mkdir $tmpdir
        }
        variable autosavefile [file join $tmpdir $id]
    }
    proc Duplicate {n} {
        #This creates a duplicate of the current page in a window called .print, for printing
        set w ".c.pg$n"
        destroy .print; toplevel .print
        ::tk::unsupported::MacWindowStyle style .print plain noTitleBar
        #FIX: Check for Mac; if not, just toplevel it?
        wm geometry .print +0+0
        lower .print
        wm title .print "Print"
        pack [canvas .print.pg$n -width [expr 200+[winfo width $w]] -height [expr 200+[winfo height $w]]]
        #Now recreate all the objects in elements
        Redraw $n
        #Drawing parameters might need to take a parameter for the right canvas
        .print.pg$n lower grid
        TextUnfocus
    }
    
    proc Save {{autosave 1}} {
        #Saves to a file, possibly a backup file
        if $autosave {
            set fname $File::autosavefile
        } else {
            set fname [tk_getSaveFile]
        }
        if ![llength $fname] {return}
        if ![file extension $fname] {set fname $fname.pdf}
    set F [open $fname "w"]
        puts $F [array get Elements::elements]
        close $F
    }
    #IDEA: Need a file to load one page
    proc ClearAll {} {
        global Npages
        Elements::ClearAll
        for {set n 1} {$n<=$Npages} {incr n} {
            Drawing::Clear $n
        }
        for {set n 3} {$n<=$Npages} {incr n} {
            foreach w [Drawing::WhereToDraw] {
                destroy $w.pg$n $w.n$n
            }
        }
        set Npages 2
        ShowPages 1
        #select page 1 I think
    }
    proc PromptLoad {} {
        set fname [tk_getOpenFile]
        if ![llength $fname] {return}
        set allpages {}
        set F [open $fname "r"]
        set slurp [read $F]
        close $F
        foreach {key val} $slurp {
            set pg [GetPage $key]
            if {[lsearch -exact $allpages $pg]==-1} {
                lappend allpages $pg
            }
        }
        puts $allpages
        set allpages [lsort -integer $allpages]
        destroy .choosepage
        toplevel .choosepage
        pack  [label .choosepage.top -text "Choose a page to insert"] -side top
        #    pack  [button .choosepage.all -text "Replace All" -command "File::Load $fname"]
        foreach pg $allpages {
            pack [button .choosepage.p$pg -text "Page $pg" -command "File::Load $fname $pg"]
        }
        pack [button .choosepage.cancel -text "Cancel" -command "destroy .choosepage"]
        bind .choosepage <FocusOut> {destroy .choosepage}
    }
    
    proc Load {{fname ""} {pages ""}} {
        #pages is a list of pages to load
        #if "", then load them all
        global Npages currentpage
        if ![llength $fname] {
            set fname [tk_getOpenFile]
            if ![llength $fname] {return}
        }
        set F [open $fname "r"]
        set slurp [read $F]
        close $F
        if ![llength $pages] { #load the entire file
            ClearAll
            array set ::Elements::elements $slurp
            set keys [::Elements::SortedKeys]
            set lastpage [lindex [split [lindex $keys end] "l"] 0]
            while {($Npages<$lastpage)} {
                NewPage
            }
            foreach key $keys {
                set page [lindex [split $key $::tagpfx] 0]
                ::Drawing::Redraw $::Elements::elements($key) $page
            }
        } else { #single page
            set result {}
            ClearCanvas $currentpage noprompt
            foreach {key val} [lsort -stride 2 -command Elements::sortcommand $slurp] {
                lassign [split $key $::tagpfx] pg idx
                set idx $::tagpfx$idx
                if {$pg==$pages} {
                    set ::Elements::elements($currentpage$idx) $val
                    ::Drawing::Redraw $val $currentpage
                }
            }
        }
        set ::currentpage [expr $Npages-1]
    }

    proc Redraw {pg} {
        set keys [::Elements::SortedKeys]
        
        foreach key $keys {
            set page [lindex [split $key $::tagpfx] 0]
            if {$page == $pg} {
                ::Drawing::Redraw $::Elements::elements($key) $page
            }
        }
    }
    proc Autosave {} {
    bind .palette.autosave <1> {}
    Save
    .palette.autosave config -text "Autosaved [clock format [clock seconds] -format %H:%M]"
    after 5000 {.palette.autosave config -text ""}
    after 60000 {File::Autosave}; #save every minute
}

proc UseScreenCapture {fname dir} {
    global Npages
    set cmd "./join.sh \"$fname\""
    for {set pg 1} {$pg<=$Npages} {incr pg} {
        Duplicate $pg
        focus .
        update
        set wid [exec ./GetWindowID [file tail [info nameofexecutable]] Print]
        exec /usr/sbin/screencapture -o -l $wid -t pdf $dir/page$pg.pdf
        append cmd " " $dir/page$pg.pdf
    }
    destroy .print
    puts $cmd
    exec {*}"$cmd" 
}
proc UsePostScript {fname dir} {
    global Npages
    set ps {}; #filenames now
    set pdf {}
#    set border "\nfalse 0 startjob pop\n"
    for {set pg 1} {$pg<=$Npages} {incr pg} {
        if {[Elements::Last $pg]>=0} { #page is not empty
            set tmpfname $dir/hill-WB$pg.ps
            lappend ps $tmpfname
            .c.pg$pg postscript -file $tmpfname; #-x 0 -y 0 -width [winfo width .c.pg$pg] -height [winfo height .c.pg$pg]
            lappend pdf $dir/hill-WB$pg.pdf
            exec /usr/local/bin/ps2pdf -dEPSCrop $dir/hill-WB$pg.ps $dir/hill-WB$pg.pdf
            
#            append ps $border
        }
    }
#    set F [open "$dir/hill-WB.ps" "w"]
#    puts $F $ps
    #    close $F
    
    exec -ignorestderr /Library/TeX/texbin/pdfjoin -o $fname {*}$pdf 
#    exec /opt/homebrew/bin/psmerge -o $dir/hill-WB.ps {*}$ps
#    exec /usr/local/bin/ps2pdf $dir/hill-WB.ps $fname
    exec /usr/bin/open -a Preview $fname
}
proc SavePDF {} {
    variable tmpdir
    set fname [tk_getSaveFile]
    if [llength $fname] {
        set dir $tmpdir
        file mkdir $dir
        UsePostScript $fname $dir
#        set env(PATH) "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Library/TeX/texbin"
    }
}
proc SaveToClipboard {} {
    global Npages env
    set pg $::currentpage
    Duplicate $pg
    update
    set wid [exec ./GetWindowID [file tail [info nameofexecutable]] Print]
    exec screencapture -c -i -o -l $wid -t pdf 
    destroy .print
}

    
}
