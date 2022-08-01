<#
# Alright... This is daunting as hell, right?
#
# My first thought was to create an actual 9x9 grid for which we can track if points are covered
# So I'm creating that first - which turned out to be fun because I've never used the New-Variable command before, but as typical of powershell it was easy to figure out
#    After a few minutes I can tell I'm going to have to use the Set-Variable cmdlet to solve this one - which I've never used before!
#    The reason why is because I need to be able to edit variables based on their names
# Grid of 100 variables. Each row has 10 variables, 10 rows
# Later... After wrapping up a script I didn't really know how it worked but it did on the sample set, I looked at the full input. Time to increase those variables!!!
# Which failed because powershell doesn't allow you to create that many variables... hmmmmmm, shit.
# No worries, a quick google revealed it's changeable!
# Another wall, you cannot create 100000+ variables in powershell. Am I really going to have to jump into visual studio for this one??
#
#
# Going to take a break now, I think answer isn't to create a million variables and then adjust them as you go, but to create the variables AS you need them
# Fun... Now I get to rewrite this bastard! -- And I thought this one would be a bit easier after the bingo one...
#
# Took a break, came back to it, now realise you can just create the variables as you need them, rather then prepopulating!!
# - Just had a thought, what if we just added the coordinates to a text document? That way, at the end we can just count how duplicate coordinates are added and tally them up
# --- Trying this now because you simply can't create enough variables for this to work.
# ---- Okay I'm going mental, what am I doing with a .txt document? Just add it to an array you nobhead
#
# Just running it again now after creating an array for all the coordinates, then creating a separate array of unique values, then loop through to filter the first count of each unique value
# Does that make sense? It works, I hope...
#
# CORRECT!!!!!!!! Oh my gosh that was interesting. Part 2 anyone?
#
# It was as I predicted.. now include the horizontals!
# I think the core of this solution will remain in effect where we tally up the verticals+horizontals and then add the values to the array.
# Also filtering the array at the end to work out double values is very simple and works. So it's just a case of adding in the diagonals. Easy, right?
# So I'm leaving the verticals and horizontals alone, I can filter those out and just add a diagonals part to the script.
#
# That was really easy solve. Had to let it run for AAAGES to get the answer though. A heck of a lot of input there!
#
#
#>
#$maximumVariableCount = 9999
$input = Get-Content C:\tmp\input.txt
cls

#if (Test-Path C:\tmp\tally.txt) {
#    Remove-Item C:\tmp\tally.txt -Force -ErrorAction Stop # Error stop because if you have it open and the file can't delete, no point running the script!!
#}

#New-Item C:\tmp\tally.txt -ItemType File
$Tally = @()

#$YCount = 0
#Get-Variable "x*","y*" | Remove-Variable
<# Create representative grid
while ($YCount -ne 1000) {
    $XCount = 0
    while ($XCount -ne 1000) {
        $Name = "y"+$YCount+"x"+$XCount
        New-Variable -Name $Name -Value 0
        $XCount++
    }
    $YCount++
}
#Get-Variable -Name "x*","y*" #Verify grid is created
#>

# First, convert the input into something a little easier to configure down the line
$CoordinatesFull = $input.Replace(" -> ",",")
#$Coordinates # This allows me to perform a foreach on them with easy indexing

foreach ($Command in $CoordinatesFull) {
    $Coordinates = $Command.split(",")
    $xone = [int]$Coordinates[0]
    $yone = [int]$Coordinates[1] + 1
    $xtwo = [int]$Coordinates[2]
    $ytwo = [int]$Coordinates[3] + 1
    
    # Part 1 wants us to only consider coordinates that move in one direction, so let's figure out which ones do
    $unidirectional = $false
    $direction = ""
    if ($xone -eq $xtwo) {
        $direction = "y" # It will be reverse, because X matches, therefore only Y moves
        $unidirectional = $true
    }
    if ($yone -eq $ytwo) {
        $direction = "x"
        $unidirectional = $true
    }
    
    if ($direction -ne "") {
        # Determine direction we're travelling
        if ($unidirectional -eq $true) {
            if ($direction -eq "x") {
                if ($xone -le $xtwo) { $direction = "right" }
                if ($xone -ge $xtwo) { $direction = "left" }
            }
        }
        if ($unidirectional -eq $true) {
            if ($direction -eq "y") {
                if ($yone -le $ytwo) { $direction = "up" }
                if ($yone -ge $ytwo) { $direction = "down" }
            }
        }
        $Move = 0
        # Calculate what we do with that direction
        switch ($direction) {
            "right" {
                while ($xone -ne ($xtwo + 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    #if (!(Get-Variable -Name $VarName -ErrorAction SilentlyContinue)) { New-Variable -Name $VarName -Value 0 }
                    #(Get-Variable -Name $VarName).Value += 1
                    $xone++
                }
            }
            "left"  { 
                while ($xone -ne ($xtwo - 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    #if (!(Get-Variable -Name $VarName -ErrorAction SilentlyContinue)) { New-Variable -Name $VarName -Value 0 }
                    #(Get-Variable -Name $VarName).Value += 1
                    $xone--
                } 
            }
            "up"    { 
                while ($yone -ne ($ytwo + 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    #if (!(Get-Variable -Name $VarName -ErrorAction SilentlyContinue)) { New-Variable -Name $VarName -Value 0 }
                    #(Get-Variable -Name $VarName).Value += 1
                    $yone++
                } 
            }
            "down"  { 
                while ($yone -ne ($ytwo - 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    #if (!(Get-Variable -Name $VarName -ErrorAction SilentlyContinue)) { New-Variable -Name $VarName -Value 0 }
                    #(Get-Variable -Name $VarName).Value += 1
                    $yone--
                } 
            }
        }
    }
}

######################
# Adding Part 2 code below
######################

foreach ($Command in $CoordinatesFull) {
    $Coordinates = $Command.split(",")
    $xone = [int]$Coordinates[0]
    $yone = [int]$Coordinates[1] + 1 #Had to plus 1 because y0x? just wouldn't print, so made the first line as y1 instead of y0
    $xtwo = [int]$Coordinates[2]
    $ytwo = [int]$Coordinates[3] + 1
    
    # Part 1 wants us to only consider coordinates that move in one direction, so let's figure out which ones do
    $unidirectional = $false
    $diagonal = 0
    $direction = ""
    $xright = $false
    $yup = $false
    if ($xone -ne $xtwo) {
        $diagonal++
        $xright = $xone -le $xtwo # If false, we know it must be left
    }
    if ($yone -ne $ytwo) {
        $diagonal++
        $yup = $yone -le $ytwo # If false, we know it must be left
    }
    
    if ($diagonal -eq 2) { #Success!
        # Calculate X
        $xmove = 0
        if ($xone -le $xtwo) {
            $xmove = $xtwo - $xone
        }else{
            $xmove = $xone - $xtwo
        }
        # Calculate Y
        $ymove = 0
        if ($yone -le $ytwo) {
            $ymove = $ytwo - $yone
        }else{
            $ymove = $yone - $ytwo
        }
        ###
        # Calculations done
        ###
        # Direction...
        ###
        if ($xright -eq $true) {
            if ($yup -eq $true) {
                $direction = "rightup"
            }else{
                $direction = "rightdown"
            }
        }else{
            if ($yup -eq $true) {
                $direction = "leftup"
            }else{
                $direction = "leftdown"
            }
        }
        ###
        # Let's count some tallies
        ###
        switch ($direction) {
            "rightup" {
                while ($xone -ne ($xtwo + 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    $yone++
                    $xone++
                }
            }
            "rightdown" {
                while ($xone -ne ($xtwo + 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    $yone--
                    $xone++
                }
            }
            "leftup" {
                while ($xone -ne ($xtwo - 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    $yone++
                    $xone--
                }
            }
            "leftdown" {
                while ($xone -ne ($xtwo - 1)) {
                    $VarName = "y$yone"+"x$xone"
                    $Tally += $VarName
                    $yone--
                    $xone--
                }
            }
        }
    }
}

#######################
#######################



Get-Variable "xone","xtwo","yone","ytwo" | Remove-Variable
#$Outcome = (Get-Variable "x*","y*").Value | ? {$_ -ne 0 -and $_ -ne 1}
#$Outcome.Count

$Tally = $Tally | Sort
$NewTally = @()
$pos = 0

while ($pos -ne ($Tally.Count)) {
    if ($Tally[$pos] -eq ($Tally[($pos - 1)])) {
        $NewTally += $Tally[$pos]
    }
    $pos++
}

($NewTally | Select -Unique).Count