function Get-Lines {
    <#
        .Synopsis
            Gets the individual lines in a string.

        .Description
            Uses a System.IO.StringReader object to read the individual lines of the
            specified string. New-line characters are not included in the result.
            Any line-termination sequence recognised by .NET are accepted, see
            documentation of the ReadLine method of the System.IO.TextReader class.

        .Parameter Value
            The String to extract the lines from.

        .Inputs
            The Value parameter can be piped into the Get-Lines function.

        .Outputs
            An array of each line in $Value in order of appearance.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string]$Value,
        [Parameter()]
        [switch]$Trim,
        [Parameter()]
        [System.StringSplitOptions]$Options = [System.StringSplitOptions]::None
    )
    $reader = [System.IO.StringReader]::new($Value)
    try {
        for ($line = $reader.ReadLine(); $line -ne $null; $line = $reader.ReadLine()) {
            if ($Trim) {
                $line = $line.Trim()
            }
            if (($Options -eq [System.StringSplitOptions]::RemoveEmptyEntries) `
                -and ($line.Length -lt 1)) {
                continue
            }
            $line
        }
    }
    finally {
        $reader.Close()
    }
}
Export-ModuleMember -Function Get-Lines
