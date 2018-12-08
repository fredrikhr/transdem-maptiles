function Get-CoordinatePairName {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$X,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$Y
    )

    begin {
        $invariant = [System.Globalization.CultureInfo]::InvariantCulture
    }

    process {
        $xString = $X.ToString($invariant)
        $yString = $Y.ToString($invariant)
        "x$xString-y$yString"
    }
}

function Get-BresenhamLowCoordinates {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$X0,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$Y0,
        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$X1,
        [Parameter(Mandatory=$true, Position=3, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$Y1,
        [Parameter(Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$DeltaX = $X1 - $X0,
        [Parameter(Position=5, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$DeltaY = $Y1 - $Y0,
        [Parameter(Mandatory=$false)]
        [System.Collections.Generic.HashSet[string]]$UsedCoordinates
    )

    begin {
        if (-not $UsedCoordinates) {
            $UsedCoordinates = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
        }
    }

    process {
        $yInc = 1
        if ($DeltaY -lt 0) {
            $yInc = -1
            $DeltaY = -$DeltaY # Force positive
        }
        $d = 2 * $DeltaY - $DeltaX
        $yCurrent = $Y0
        for ($xCurrent = $X0; $xCurrent -le $X1; $xCurrent++) {
            $name = Get-CoordinatePairName -X $xCurrent -Y $yCurrent
            if ($UsedCoordinates.Add($name)) {
                [PSCustomObject]@{
                    X = $xCurrent
                    Y = $yCurrent
                }
            }
            if ($d -gt 0) {
                $yCurrent += $yInc
                $d -= 2 * $DeltaX
            }
            $d += 2 * $DeltaY
        }
    }
}

function Get-BresenhamHighCoordinates {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$X0,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$Y0,
        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$X1,
        [Parameter(Mandatory=$true, Position=3, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$Y1,
        [Parameter(Position=4, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$DeltaX = $X1 - $X0,
        [Parameter(Position=5, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$DeltaY = $Y1 - $Y0,
        [Parameter(Mandatory=$false)]
        [System.Collections.Generic.HashSet[string]]$UsedCoordinates
    )

    begin {
        if (-not $UsedCoordinates) {
            $UsedCoordinates = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
        }
    }

    process {
        $xInc = 1
        if ($DeltaX -lt 0) {
            $xInc = -1
            $DeltaX = -$DeltaX # Force positive
        }
        $d = 2 * $DeltaY - $DeltaX
        $xCurrent = $Y0
        for ($yCurrent = $Y0; $yCurrent -le $Y1; $yCurrent++) {
            $name = Get-CoordinatePairName -X $xCurrent -Y $yCurrent
            if ($UsedCoordinates.Add($name)) {
                [PSCustomObject]@{
                    X = $xCurrent
                    Y = $yCurrent
                }
            }
            if ($d -gt 0) {
                $xCurrent += $xInc
                $d -= 2 * $DeltaY
            }
            $d += 2 * $DeltaX
        }
    }
}

function Get-BresenhamLineCoordinates {
    <#
    .SYNOPSIS
        Gets all distinct integer coordinate pairs for a line between two
        points.
    .DESCRIPTION
        Returns a all distinct points along a line as determined by
        Bresenham's line algorithm.
    .PARAMETER X0
        The x-coordinate of the starting point.
    .PARAMETER Y0
        The y-coordinate of the starting point.
    .PARAMETER X1
        The x-coordinate of the ending point.
    .PARAMETER Y1
        The y-coordinate of the ending point.
    .PARAMETER UsedCoordinates
        Optional. A string hashset containing all coordinate pair names.
        Used to ensure point distinctness.
    .INPUTS
        [Int]
        A value that can be bound to one of the missing coordinate parameter
        values.

        [PSObject]
        An object whose properties can be bound to the function parameters.
    .OUTPUTS
        A collection of PSCustomObject instances, where each instance
        has an X and Y property with integer values.
    .NOTES
        For each point along the line, the algorithm determines a name
        built up of the x and y coordinates of the point. That name is
        added to the UsedCoordinates hash set if not already present.
        This way each point is guaranteed to only be output once.

        Multiple sequential invocations to Get-BresenhamLineCoordinates
        can share the same hash set.

        If the UsedCoordinates hash set is not provided at invocation it
        is created in the begin block of this function (using the
        Ordinal Case-Insensitive String Comparer).
    .LINK
        https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [int]$X0,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [int]$Y0,
        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [int]$X1,
        [Parameter(Mandatory=$true, Position=3, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        [int]$Y1,
        [Parameter(Mandatory=$false)]
        [System.Collections.Generic.HashSet[string]]$UsedCoordinates
    )

    begin {
        if (-not $UsedCoordinates) {
            $UsedCoordinates = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
        }
    }

    process {
        [int]$DeltaX = [Math]::Abs($X1 - $X0)
        [int]$DeltaY = [Math]::Abs($Y1 - $Y0)
        if ($DeltaY -lt $DeltaX) {
            # Line is steep
            if ($X0 -gt $X1) {
                # Switch Start with End point
                Get-BresenhamLowCoordinates -UsedCoordinates $UsedCoordinates `
                    -X0 $X1 -Y0 $Y1 -X1 $X0 -Y1 $Y0 `
                    -DeltaX $DeltaX -DeltaY $DeltaY
            } else {
                Get-BresenhamLowCoordinates -UsedCoordinates $UsedCoordinates `
                    -X0 $X0 -Y0 $Y0 -X1 $X1 -Y1 $Y1 `
                    -DeltaX $DeltaX -DeltaY $DeltaY
            }
        } else {
            # Line is shallow
            if ($Y0 -gt $Y1) {
                # Switch Start with End point
                Get-BresenhamHighCoordinates -UsedCoordinates $UsedCoordinates `
                    -X0 $X1 -Y0 $Y1 -X1 $X0 -Y1 $Y0 `
                    -DeltaX $DeltaX -DeltaY $DeltaY
            } else {
                Get-BresenhamHighCoordinates -UsedCoordinates $UsedCoordinates `
                    -X0 $X0 -Y0 $Y0 -X1 $X1 -Y1 $Y1 `
                    -DeltaX $DeltaX -DeltaY $DeltaY
            }
        }
    }
}
Export-ModuleMember -Function Get-BresenhamLineCoordinates
