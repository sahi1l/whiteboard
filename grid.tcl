bind . <Command-g> {AddGrid}
proc AddGrid {} {
    global currentpage cX cY
    set spacing [expr round($cX/30)]
    foreach f [Drawing::WhereToDraw] {
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
    foreach f [Drawing::WhereToDraw] {
        $f.pg$currentpage delete withtag grid
    }
}
