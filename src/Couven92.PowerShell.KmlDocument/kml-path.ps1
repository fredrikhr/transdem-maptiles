Import-Module (Join-Path (Join-Path $PSScriptRoot "..") "Couven92.PowerShell.StringUtils")

function Get-CoordinatePairAsHashTable {
    [CmdletBinding()]
    [OutputType([hashtable])]
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
        @{
            DegreesLongitude = $degreesLongitude
            DegreesLatitude = $degreesLatitude
        }
    }
}

function Get-CoordinatePair {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    process {
        [PSCustomObject](Get-CoordinatePairAsHashTable -value $Value)
    }
}

function Get-XmlNodesFromNodeList {
    [CmdletBinding()]
    [OutputType([System.Xml.XmlNode[]])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [System.Xml.XmlNodeList]$NodeList
    )

    process {
        foreach ($item in $NodeList) {
            $item
        }
    }
}

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
        [string[]]$coordinateLines = $coordinatesNode.InnerText | Get-TrimmedLines
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
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (Test-Path $_ -PathType Leaf) {
                $true
             } else {
                throw "Cannot find path '$_' because it is not a path to a file or because it does not exist."
             }
        })]
        [string]$KmlPath
    )
    process {
        [xml]$kmlXml = Get-Content $KmlPath
        $nodes = $kmlXml.SelectNodes("/kml/Document/Folder/Placemark")
        if ($nodes.Count -lt 1) {
            Write-Warning "KML file '$_' does not contain any placemark XML nodes."
            return
        }

        $nodes | Get-XmlNodesFromNodeList | Get-PathFromPlacemarkNode
    }
}
Export-ModuleMember -Function Get-AllPathsFromKml
