$input = Get-Content C:\tmp\input.txt
cls

# This one required re-writing 4 times
# The last reason being because I didn't read it correctly, and you have to check against columns as well as rows!
# I already created a good function which tests against rows, so now I decided instead of re-writing, I could just edit the scoreboard to reflect
#        10 rows instead of 5. Five of those rows being converted columns

Function WinningBall {
    param (
        $Scoreboard, # The full scoreboard with 10 rows, 5 are rows, 5 are columns
        $BingoBalls,
        $BoardNumber,
        $pos, # We use this to draw new balls
        $SumBoard # We need the original scoreboard so we can get an accurate sum of the unmarked numbers
    )
    $drawnballs = @()
    while (($drawnballs.Count - 1) -le $BingoBalls.Count) {
        $drawnballs += $BingoBalls[$pos]
        $pos++
        foreach ($line in $Scoreboard) {
            $match = 0
            foreach ($number in $line.split(" ")) {
                if ($number -ne "") {
                    foreach ($ball in $drawnballs) {
                        if ([int]$number -eq [int]$ball) {
                            $match++
                        }
                    }
                }
            }
            if ($match -eq 5) {
                $Sum = 0
                foreach ($line in $Sumboard) {
                    foreach ($number in $line.split(" ")) {
                        $Lose = 0
                        if ($number -ne "") {
                            if (($drawnballs.IndexOf($number)) -eq -1) {
                                $Sum += [int]$number
                            }
                        }
                    }
                }
                $Properties = [ordered]@{
                    "Board" = $BoardNumber # First line index from main input. If you typed in $input[$BoardNumber] it would return the first line of that board
                    "Winning Ball" = $drawnballs[($drawnballs.Count - 1)] # The loop breaks once we have 5 number matches, so we add the winning ball drawn to the object
                    "Ball Location" = ($drawnballs.Count - 1) # Index of the winning ball, we need this so we can work out which scoreboard won first, and which won last
                    "Losing Sum" = $Sum # From above, we whip through the 5 rows of numbers and check which numbers didn't match any winning balls
                }
                $Object = New-Object psobject -Property $Properties
                return $Object
            }
        }
    }
}

# Created a new function to return a scoreboard with the columns added on
Function CreateColumns {
    # We know that there are gaps between numbers, which are easily predicted at index points 2,5,8,11 - This helps us pick out the parts we want to cut and add to our converted columns
    param(
        $Scoreboard
    )
    $Count = 0 # We're going to loop through each line 5 times and cut out the parts we need, this will help us loop
    $TempBoard = $Scoreboard # Don't forget to copy the rows we already have so we can have all numbers!

    while ($Count -le 15) {
        $string = "" # This is the beginning of our custom column
        $12 = 0 # For some reason the last column got buggy and added an extra space at the start, I set this to remove it for the first entry on column 5
        foreach ($line in $Scoreboard) {
            switch ($Count) { # Decided a switch was best. I tried to create a catch all but it kept kicking me back so I created custom lines for each column
                0 { $string = $string+$line.Remove(3) } # Column one, remove all characters after the first break, add that to our custom string
                3 { $line = $line.Remove(0,$Count); $line = $line.Remove(3); $string = $string+$line } # Column two - four, remove all characters up to the column, and then all characters after the break, add to custom string
                6 { $line = $line.Remove(0,$Count); $line = $line.Remove(3); $string = $string+$line }
                9 { $line = $line.Remove(0,$Count); $line = $line.Remove(3); $string = $string+$line }
                12 { if ($12 -eq 0) {$line = $line.Remove(0,12)}else{$line = $line.Remove(0,11)}; $string = $string+$line; $12 = 1 } # Same as above but, the random space character at the start needs removing for the first column entry
            }
        }
        $TempBoard += $string # Add the custom strings made for each column to the TempBoard
        $Count += 3 # Prepare for next column
    }
    return $TempBoard # Return new custom board with 10 rows, 5 are rows, 5 are columns
}

$BingoBalls = $input[0].Split(",")
$BoardNumber = 2
$BingoWinners = @()

while ($BoardNumber -le $input.Count) {
    $pos = 0
    $CurrentBoard = $input[$BoardNumber..($BoardNumber + 4)]
    $FullBoard = CreateColumns -Scoreboard $CurrentBoard
    $Result = WinningBall -Scoreboard $FullBoard -BingoBalls $BingoBalls -BoardNumber $BoardNumber -pos $pos -SumBoard $CurrentBoard
    $BingoWinners += $Result
    $BoardNumber += 6
}

$BingoWinners = $BingoWinners | Sort -Property "Ball Location" #Sort the winning boards so we have a first win and last win
"Winning Boards are:"
$BingoWinners
""
"The answer to Part 1 is "+[int]($BingoWinners[0].'Winning Ball')*[int]($BingoWinners[0].'Losing Sum')
"The answer to Part 2 is "+[int]($BingoWinners[($BingoWinners.Count - 1)].'Winning Ball')*[int]($BingoWinners[($BingoWinners.Count - 1)].'Losing Sum')