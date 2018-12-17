Import-Module (Join-Path $PSScriptRoot "StringUtils.psm1")

function Get-CoordinatePair {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    begin {
        $invariant = [System.Globalization.CultureInfo]::InvariantCulture
    }
    process {
        $commaIdx = $Value.IndexOf(',')
        if ($commaIdx -lt 0) {
            return
        }
        $lonString = $Value.Substring(0, $commaIdx)
        $latString = $Value.Substring($commaIdx + 1)
        [double]$degreesLongitude = [double]::Parse($lonString, $invariant)
        [double]$degreesLatitude = [double]::Parse($latString, $invariant)
        [PSCustomObject]@{
            DegreesLongitude = $degreesLongitude
            DegreesLatitude = $degreesLatitude
        }
    }
}
Export-ModuleMember -Function Get-CoordinatePair

function Get-PathFromPlacemarkNode {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({
            ([System.Xml.XmlElement]$_).LocalName -ieq "Placemark"
        })]
        [System.Xml.XmlElement]$PlacemarkNode
    )

    process {
        [System.Xml.XmlElement]$coordinatesNode = $PlacemarkNode.SelectSingleNode("LineString/coordinates")
        if (-not $coordinatesNode) {
            return
        }
        [string[]]$coordinateLines = $coordinatesNode.InnerText | Get-Lines -Trim
        [PSCustomObject[]]$coordinatePairs = $coordinateLines | Get-CoordinatePair
        [PSCustomObject]@{
            Coordinates = $coordinatePairs
        }
    }
}

function Get-AllPathsFromKml {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory=$true, ParameterSetName="ByItem", Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [psobject]$KmlItem,
        [Parameter(Mandatory=$true, ParameterSetName="ByPath", Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$KmlPath
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq "ByPath") {
            $KmlItem = Get-Item $KmlPath
        }
        [xml]$kmlXml = $KmlItem | Get-Content
        $nodes = $kmlXml.SelectNodes("/kml/Document/Folder/Placemark")
        if ($nodes.Count -lt 1) {
            Write-Warning "KML file '$_' does not contain any placemark XML nodes."
            return
        }

        foreach ($item in $nodes) {
            $item | Get-PathFromPlacemarkNode
        }
    }
}
Export-ModuleMember -Function Get-AllPathsFromKml
