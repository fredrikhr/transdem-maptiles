function Select-OpenStreetMapSubDomain {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()][AllowNull()][AllowEmptyCollection()]
        [string[]]$SubDomains = @("a", "b", "c"),
        [Parameter()]
        [ValidateScript({
            if ((-not $SubDomains) -and ($_ -ne $null)) {
                throw "Cannot validate argument on parameter 'Index'. Parameter 'SubDomains' is null, but $_ argument is not null. Either specify a value for 'SubDomains' or omit the 'Index' parameter."
            } elseif ($_ -lt 0) {
                throw "Cannot validate argument on parameter 'Index'. The $_ argument is less than the minimum allowed range of 0. Supply an argument that is greater than or equal to 0 and then try the command again."
            } elseif ($_ -ge $SubDomains.Count) {
                throw "Cannot validate argument on parameter 'Index'. The $_ argument is greater than or equal to the number of items in the 'SubDomains' parameter. Supply an argument that is less than $($SubDomains.Count) and then try the command again."
            } else {
                $true
            }
        })]
        [int]$Index
    )
    if (-not $SubDomains) {
        $null
    } elseif (-not $Index) {
        $randomIdx = Get-Random -Maximum $SubDomains.Count
        $SubDomains[$randomIdx]
    } else {
        $SubDomains[$Index]
    }
}
Export-ModuleMember -Function Select-OpenStreetMapSubDomain

function Get-OpenStreetMapTileUrl {
    [CmdletBinding()]
    [OutputType([uri])]
    param (
        [Parameter()][ValidateNotNullOrEmpty()]
        [string]$UrlFormat = "https://tile.openstreetmap.org/{0}/{1}/{2}.png",
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$SubDomainArgumentIdx,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$ZoomLevelArgumentIdx = 0,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$XArgumentIdx = 1,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$YArgumentIdx = 2,
        [Parameter()][AllowNull()][AllowEmptyCollection()]
        [string[]]$SubDomains = @("a", "b", "c"),
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0, 22)]
        [int]$ZoomLevel,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$TileX,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$TileY
    )

    begin {
        [int]$MaxIdx = (@($SubDomainArgumentIdx, $ZoomLevelArgumentIdx, $XArgumentIdx, $YArgumentIdx) | Measure-Object -Maximum).Maximum
        [object[]]$Arguments = [object[]]::new($MaxIdx + 1)
        $invariant = [System.Globalization.CultureInfo]::InvariantCulture
    }

    process {
        if ($SubDomainArgumentIdx -ne $null) {
            $Arguments[$SubDomainArgumentIdx] = [System.Uri]::EscapeUriString((Select-OpenStreetMapSubDomain -SubDomains $SubDomains))
        }
        if ($ZoomLevelArgumentIdx -ne $null) {
            $Arguments[$ZoomLevelArgumentIdx] = $ZoomLevel.ToString($invariant)
        }
        if ($XArgumentIdx -ne $null) {
            $Arguments[$XArgumentIdx] = $TileX.ToString($invariant)
        }
        if ($YArgumentIdx -ne $null) {
            $Arguments[$YArgumentIdx] = $TileY.ToString($invariant)
        }
        $Url = [string]::Format($UrlFormat, $Arguments)
        [uri]$Url
    }
}
Export-ModuleMember -Function Get-OpenStreetMapTileUrl

function Add-OpenStreetMapTileUrl {
    [CmdletBinding()]
    param (
        [Parameter()][ValidateNotNullOrEmpty()]
        [string]$UrlFormat = "https://tile.openstreetmap.org/{0}/{1}/{2}.png",
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$SubDomainArgumentIdx,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$ZoomLevelArgumentIdx = 0,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$XArgumentIdx = 1,
        [Parameter()][AllowNull()]
        [System.Nullable[int]]$YArgumentIdx = 2,
        [Parameter()][AllowNull()][AllowEmptyCollection()]
        [string[]]$SubDomains = @("a", "b", "c"),
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [PSCustomObject]$TileRef
    )

    process {
        $url = $TileRef | Get-OpenStreetMapTileUrl -UrlFormat $UrlFormat `
            -SubDomainArgumentIdx $SubDomainArgumentIdx `
            -ZoomLevelArgumentIdx $ZoomLevelArgumentIdx `
            -XArgumentIdx $XArgumentIdx -YArgumentIdx $YArgumentIdx `
            -SubDomains $SubDomains
        $TileRef | Add-Member @{ TileUrl = $url }
    }
}
Export-ModuleMember -Function Add-OpenStreetMapTileUrl

function Out-OpenStreetMapTileCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("PSPath")]
        [string]$CacheFilePath,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$TileFilePath,
        [Parameter(Mandatory=$true, Position=2, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNull()]
        $Response
    )

    process {
        $creationDate = $null
        $lastModifiedDate = $null
        $expireDate = $null
        $etag = $null

        try { [datetime]$lastModifiedDate = $Response.Headers["Date"] } catch { }
        try { [datetime]$creationDate = $Response.Headers["Last-Modified"] } catch { }
        try { [datetime]$expireDate = $Response.Headers["Expires"] } catch { }
        try {
            $cacheControl = $Response.Headers["Cache-Control"]
            if ($cacheControl) {
                [System.Net.Http.Headers.CacheControlHeaderValue]$cacheControlValue = [System.Net.Http.Headers.CacheControlHeaderValue]::Parse($cacheControl)
                if (-not $lastModifiedDate) {
                    [datetime]$expireDate = [datetime]::UtcNow + $cacheControlValue.MaxAge.GetValueOrDefault()
                } else {
                    [datetime]$expireDate = $lastModifiedDate + $cacheControlValue.MaxAge.GetValueOrDefault()
                }
            }
        } catch { }
        try { [string]$etag = $Response.Headers["ETag"] } catch { }

        $cacheDetails = @{}
        if ($expireDate) {
            $cacheDetails["ExpireDate"] = $expireDate.ToString("r")
        }
        if (-not [string]::IsNullOrWhiteSpace($etag)) {
            $cacheDetails["ETag"] = [string]$etag
        }
        $cacheDetails | ConvertTo-Json | Out-File $CacheFilePath -Encoding utf8
        $tileFileItem = Get-Item $TileFilePath
        if ($creationDate) {
            $tileFileItem.CreationTimeUtc = $creationDate
        } elseif ($lastModifiedDate) {
            $tileFileItem.CreationTimeUtc = $lastModifiedDate
        }
        if ($lastModifiedDate) {
            $tileFileItem.LastWriteTimeUtc = $lastModifiedDate
        }
    }
}

function Invoke-DownloadOpenStreetMapTile {
    [CmdletBinding(DefaultParameterSetName="ByTileName")]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Url")][Alias("Uri")]
        [uri]$TileUrl,
        [Parameter(Mandatory=$true, ParameterSetName="ByFileName", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("PSPath")]
        [string]$FilePath,
        [Parameter(Mandatory=$true, ParameterSetName="ByTileName", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Name")]
        [string]$TileName,
        [Parameter(Mandatory=$true, ParameterSetName="ByTileName", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$DirectoryPath,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Collections.Generic.IDictionary[string, string]]$Headers
    )

    begin {
        $firstWebRequest = $true
        $osmWebSession = $null
        # Load HTTP Assembly for Cache Control validation
        try {
            Add-Type -AssemblyName System.Net.Http
        } catch { }
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq "ByFileName") {
            $itemTileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
            $itemExtension = [System.IO.Path]::GetExtension($FilePath)
            $itemDirectoryPath = Join-Path $FilePath ".."
        } else {
            $itemTileName = $TileName
            $itemExtension = ".png"
            $itemDirectoryPath = $DirectoryPath
        }
        if (-not (Test-Path $itemDirectoryPath -PathType Container)) {
            New-Item $itemDirectoryPath -ItemType Directory
        }

        if (-not $Headers) {
            $itemHeaders = [System.Collections.Generic.Dictionary[string, string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
        } else {
            $itemHeaders = [System.Collections.Generic.Dictionary[string, string]]::new(
                $Headers,
                [System.StringComparer]::OrdinalIgnoreCase
            )
        }

        $itemTileFilePath = Join-Path $itemDirectoryPath "$itemTileName$itemExtension"
        $itemCacheFilePath = Join-Path $itemDirectoryPath "$itemTileName.cache.json"
        if ((Test-Path $itemCacheFilePath -PathType Leaf) -and (Test-Path $itemTileFilePath -PathType Leaf)) {
            try {
                $cacheDetails = Get-Content $itemCacheFilePath | ConvertFrom-Json
                try {
                    [datetime]$expireDate = $cacheDetails.ExpireDate
                    if ([datetime]::UtcNow -lt $expireDate) {
                        Write-Verbose "Skipping previously downloaded tile $itemTileName"
                        return
                    }
                    $itemHeaders["If-Modified-Since"] = $expireDate.ToString("r")
                } catch { }
                $etag = $cacheDetails.ETag
                if (-not [string]::IsNullOrWhiteSpace($etag)) {
                    $itemHeaders.Remove("If-Modified-Since") | Out-Null
                    $itemHeaders["If-None-Match"] = $etag
                }
            } catch { }
        }
        try {
            if ($firstWebRequest) {
                $firstWebRequest = $false
                $response = Invoke-WebRequest -Uri $TileUrl `
                    -SessionVariable "osmWebSession" -Headers $itemHeaders
            } else {
                $response = Invoke-WebRequest -Uri $TileUrl `
                    -WebSession $osmWebSession -Headers $itemHeaders
            }
        }
        catch [System.Net.WebException] {
            [System.Net.WebException]$except = $_.Exception
            if ($except.Status -ne [System.Net.WebExceptionStatus]::ProtocolError) {
                throw
            }
            [int]$NotModifiedStatusCode = [System.Net.HttpStatusCode]::NotModified
            $response = $except.Response
            if ($response.StatusCode -ne $NotModifiedStatusCode) {
                throw
            }
            Out-OpenStreetMapTileCache -CacheFilePath $itemCacheFilePath `
                -TileFilePath $itemTileFilePath -Response $response
            Write-Verbose "received $($NotModifiedStatusCode) $($Response.StatusDescription) response"
            return
        }
        Set-Content $itemTileFilePath -Value $response.Content -Encoding Byte
        Out-OpenStreetMapTileCache -CacheFilePath $itemCacheFilePath `
            -TileFilePath $itemTileFilePath -Response $response
    }
}
Export-ModuleMember -Function Invoke-DownloadOpenStreetMapTile

function Invoke-JoinOpenStreetMapTile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ImageMagickConvert,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("PSPath")]
        [string]$DirectoryPath,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("Name")]
        [string]$TileName,
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [AllowNull()][AllowEmptyCollection()]
        [PSCustomObject[,]]$Tiles
    )

    begin {
        $convertCommand = Get-Command $ImageMagickConvert | Select-Object -First 1
        $lineFileNames = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if (-not $Tiles) {
            return
        }

        $itemWidth = $Tiles.GetLength(0)
        $itemHeight = $Tiles.GetLength(1)

        if (($itemWidth -lt 2) -and ($itemHeight -lt 2)) {
            $singleTilePath = Join-Path $DirectoryPath "$TileName.png"
            $tileItem = Get-Item $singleTilePath
            Copy-Item $previousPartialTilePath ($tileItem.Directory | Join-Path "$TileName.png")
        }

        $lineFileNames.Capacity = $itemWidth
        $previousPartialTilePath = $null
        for ($y = 0; $y -lt $itemHeight; $y++) {
            $lineFileNames.Clear()
            for ($x = 0; $x -lt $itemWidth; $x++) {
                $singleTile = $Tiles[$x, $y]
                $singleTileName = $singleTile.TileName
                $singleTilePath = Join-Path $DirectoryPath "$singleTileName.png"
                $singleTileItem = Get-Item $singleTilePath
                $singleTileItem | Out-Null
                $lineFileNames.Add("`"$singleTilePath`"") | Out-Null
            }

            $lineOnlyTileName = $Tiles[0, $y] | Get-MapTileJoinedName `
                -TileWidth $itemWidth -TileHeight 1
            $lineOnlyTilePath = Join-Path $DirectoryPath "$lineOnlyTileName.png"
            Write-Verbose "Performing the ImageMagick operation `"convert.exe +append`" on target `"Path: $lineOnlyTilePath`"."
            # Invoke-Command $convertCommand $lineFileNames, "+append", "$lineOnlyTilePath"
            & $convertCommand $lineFileNames "+append" "$lineOnlyTilePath"
            if ($y -gt 0) {
                $partialTileName = $Tiles[0, 0] | Get-MapTileJoinedName `
                    -TileWidth $itemWidth -TileHeight ($y + 1)
                $partialTilePath = Join-Path $DirectoryPath "$partialTileName.png"
                Write-Verbose "Performing the ImageMagick operation `"convert.exe -append`" on target `"Path: $partialTilePath`"."
                & $convertCommand "$previousPartialTilePath" "$lineOnlyTilePath" "-append" "$partialTilePath"
                Remove-Item $lineOnlyTilePath
                Remove-Item $previousPartialTilePath
                $previousPartialTilePath = $partialTilePath
            } else {
                $previousPartialTilePath = $lineOnlyTilePath
            }
        }
        $tileItem = Get-Item $previousPartialTilePath
        if ($tileItem.BaseName -ine $TileName) {
            Copy-Item $previousPartialTilePath (Join-Path $DirectoryPath "$TileName.png")
        }
    }
}
Export-ModuleMember -Function Invoke-JoinOpenStreetMapTile
