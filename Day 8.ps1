$Content = @(
"be cfbegad cbdgef fgaecd cgeb fdcge agebfd fecdb fabcd edb | fdgacbe cefdb cefbgd gcbe",
"edbfga begcd cbg gc gcadebf fbgde acbgfd abcde gfcbed gfec | fcgedb cgb dgebacf gc",
"fgaebd cg bdaec gdafb agbcfd gdcbef bgcad gfac gcb cdgabef | cg cg fdcagb cbg",
"fbegcd cbd adcefb dageb afcb bc aefdc ecdab fgdeca fcdbega | efabcd cedba gadfec cb",
"aecbfdg fbg gf bafeg dbefa fcge gcbea fcaegb dgceab fcbdga | gecf egdcabf bgf bfgea",
"fgeab ca afcebg bdacfeg cfaedg gcfdb baec bfadeg bafgc acf | gebdcfa ecba ca fadegcb",
"dbcfg fgd bdegcaf fgec aegbdf ecdfab fbedc dacgb gdcebf gf | cefg dcbef fcge gbcadfe",
"bdfegc cbegaf gecbf dfcage bdacg ed bedf ced adcbefg gebcd | ed bcgafe cdgba cbgef",
"egadfb cdbfeg cegd fecab cgb gbdefca cg fgcdab egfdb bfceg | gbdfcae bgc cg cgb",
"gcafb gcf dcaebfg ecagb gf abcdeg gaef cafbge fdbac fegbdc | fgae cfgab fg bagce")

#$Content = "acedgfb cdfbe gcdfa fbcad dab cefabd cdfgeb eafb cagedb ab | cdfeb fcadb cdfeb cdbaf"

cls
$Count = 0

$input = Get-Content "C:\Users\alexf\OneDrive\Documents\Powershell\Day 8.txt"
#$input.Count
$FinalArray = @()
Function Match {
    param(
        $Object,
        $Number
    )
    $pos = 0
    $match = 0
    while ($pos -ne $Object.Length) {
        $cnt = 0
        while ($cnt -ne $Number.Length) {
            if ($Object[$pos] -eq $Number[$cnt]) {
                $match++
                break
            }
            $cnt++
        }
        if ($match -eq $Object.Length) {
            return $Object
        }
        $pos++
    }
    return 1
}

foreach($line in $input) {
    $Numbers = @{}
    $LastLine = $line.Split("|")[1]
    $line = $line.Split("|")[0]
    foreach ($item in $line.Split(" ")) {
        switch ($item.Length) {
            2 { $Numbers.Add("1",$item) }
            3 { $Numbers.Add("7",$item) }
            4 { $Numbers.Add("4",$item) }
            7 { $Numbers.Add("8",$item) }
        }
    }
    # Calculate 9
    $sixitems = $line.Split(" ").Where({$_.Length -eq 6})
    foreach ($item in $sixitems) {
        $match = 0
        $pos = 0
        while ($pos -ne $item.Length) {
            $cnt = 0
            while ($cnt -ne $Numbers.'4'.Length) {
                if ($item[$pos] -eq $Numbers.'4'[$cnt]) {
                    $match++
                    break
                }
                $cnt++
            }
            $pos++
        }
        if ($match -eq 4) {
            $Numbers.Add("9",$item)
            break
        }
    }
    # Calculate 3
    $fiveitems = $line.Split(" ").Where({$_.Length -eq 5})
    foreach ($item in $fiveitems) {
        $match = 0
        $pos = 0
        while ($pos -ne $item.Length) {
            $cnt = 0
            while ($cnt -ne $Numbers.'7'.Length) {
                if ($item[$pos] -eq $Numbers.'7'[$cnt]) {
                    $match++
                    break
                }
                $cnt++
            }
            $pos++
        }
        if ($match -eq 3) {
            $Numbers.Add("3",$item)
            break
        }
    }
    # Calculate 0
    $sixitems = $line.Split(" ").Where({$_.Length -eq 6})
    foreach ($item in $sixitems) {
        if ($item -ne $Numbers.'9') {
            $match = 0
            $pos = 0
            while ($pos -ne $item.Length) {
                $cnt = 0
                while ($cnt -ne $Numbers.'7'.Length) {
                    if ($item[$pos] -eq $Numbers.'7'[$cnt]) {
                        $match++
                        break
                    }
                    $cnt++
                }
                $pos++
            }
            if ($match -eq 3) {
                $Numbers.Add("0",$item)
                break
            }
        }
    }
    # Calculate 6
    foreach ($item in $sixitems) {
        if ($item -ne $Numbers.'9' -and $item -ne $Numbers.'0') {
            $Numbers.Add("6",$item)
        }
    }
    # Calculate 5
    $fiveitems = $line.Split(" ").Where({$_.Length -eq 5})
    foreach ($item in $fiveitems) {
        $match = 0
        $pos = 0
        while ($pos -ne $item.Length) {
            $cnt = 0
            while ($cnt -ne $Numbers.'6'.Length) {
                if ($item[$pos] -eq $Numbers.'6'[$cnt]) {
                    $match++
                    break
                }
                $cnt++
            }
            $pos++
        }
        if ($match -eq 5) {
            $Numbers.Add("5",$item)
            break
        }
    }
    # Calculate 2
    foreach ($item in $fiveitems) {
        if ($item -ne $Numbers.'5' -and $item -ne $Numbers.'3') {
            $Numbers.Add("2",$item)
        }
    }
    ####
    #
    #
    ####
    $Code = ""
    $Output = $LastLine.Split(" ")[1..4]
    foreach ($Object in $Output) {
        switch ($Object.Length) {
            2 { $Code += "1" }
            3 { $Code += "7" }
            4 { $Code += "4" }
            5 {
                if ((Match -Object $Object -Number $Numbers.'3') -ne 1) {
                    $Code += "3"
                }
                if ((Match -Object $Object -Number $Numbers.'5') -ne 1) {
                    $Code += "5"
                }
                if ((Match -Object $Object -Number $Numbers.'2') -ne 1) {
                    $Code += "2"
                }
            }
            6 { 
                if ((Match -Object $Object -Number $Numbers.'0') -ne 1) {
                    $Code += "0"
                }
                if ((Match -Object $Object -Number $Numbers.'6') -ne 1) {
                    $Code += "6"
                }
                if ((Match -Object $Object -Number $Numbers.'9') -ne 1) {
                    $Code += "9"
                }
            }
            7 { $Code += "8" }
        }
    }
    $FinalArray += $Code
}
$Total = 0
foreach ($value in $FinalArray) {
    $Total += $value
}
$Total