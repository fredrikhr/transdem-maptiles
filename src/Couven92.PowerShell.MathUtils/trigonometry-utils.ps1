$RadiansToDegreesFactor = [double](180 / [Math]::PI)
$DegreesToRadiansFactor = [double]([Math]::PI / 180)

function Convert-DegreesToRadians {
    <#
        .SYNOPSIS
            Converts an angle from degrees to radians.

        .DESCRIPTION
            Conversion from degrees to radians is defined by the following
            formula: $degrees * (180 / [Math]::PI)

        .PARAMETER Value
            The value of the angle in degrees. Alias: Degrees

        .INPUTS
            A double value that will be bound to the Value parameter, or
            an object with a Value (or Degrees) property

        .OUTPUTS
            The angle in radians as a double value.

        .NOTES
            Both negative values and values greater than 360 degrees are acceptable.
            Conversion uses the .NET definition for the Pi constant and is
            limited to its precision.

        .LINK
            https://en.wikipedia.org/wiki/Radian#Conversion_between_radians_and_degrees
    #>
    [OutputType([double])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Degrees")]
        [double]$Value
    )
    process {
        $Value * $DegreesToRadiansFactor
    }
}
Export-ModuleMember -Function Convert-DegreesToRadians

function Convert-RadiansToDegrees {
    <#
        .SYNOPSIS
            Converts an angle from radians to degrees.

        .DESCRIPTION
            Conversion from degrees to radians is defined by the following
            formula: $radians * ([Math]::PI / 180)

        .PARAMETER Value
            The value of the angle in radians. Alias: Radians

        .INPUTS
            A double value that will be bound to the Value parameter, or
            an object with a Value (or Radians) property

        .OUTPUTS
            The angle in degrees as a double value.

        .NOTES
            Both negative values and values greater than 2 * Pi are acceptable.
            Conversion uses the .NET definition for the Pi constant and is
            limited to its precision.

        .LINK
            https://en.wikipedia.org/wiki/Radian#Conversion_between_radians_and_degrees
    #>
    [OutputType([double])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Radians")]
        [double]$Value
    )
    process {
        $Value * $RadiansToDegreesFactor
    }
}
Export-ModuleMember -Function Convert-RadiansToDegrees
