Import-Module Pester -Verbose:$false
Import-Module (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "src") "WebMercator.psm1") -Force

Describe "New-MapTileObject" {
    It "Throws if ZoomLevel is <ZoomLevel>" -TestCases @(
        @{ ZoomLevel = -1 }
        @{ ZoomLevel = 23 }
        @{ ZoomLevel = 400 }
    ) {
        param($ZoomLevel)

        { New-MapTileObject -ZoomLevel $ZoomLevel -X 0 -Y 0 } | Should -Throw
    }
    It "Returns a PSCustomObject with correct properties" {
        $note = [System.Management.Automation.PSMemberTypes]::NoteProperty
        $alias = [System.Management.Automation.PSMemberTypes]::AliasProperty

        $tile = New-MapTileObject -ZoomLevel 0 -TileX 0 -TileY 0
        $tile | Should -BeOfType [PSCustomObject]

        $tile.TileX | Should -Be 0
        $tile.TileY | Should -Be 0
        $tile.ZoomLevel | Should -Be 0
        $tile.TileName | Should -BeOfType [string]

        ($tile | Get-Member TileX, TileY, ZoomLevel, TileName).MemberType `
            | Should -Be @($note, $note, $note, $note)

        $tile.X | Should -Be $tile.TileX
        $tile.Y | Should -Be $tile.TileY
        $tile.Z | Should -Be $tile.ZoomLevel

        ($tile | Get-Member X, Y, Z, Name).MemberType `
            | Should -Be @($alias, $alias, $alias, $alias)
    }
}

Describe "Get-MapTileName" {
    $examples = @(
        @{ TileX =  0; TileY =   0; ZoomLevel =  0; Expected = "z0-y0-x0" }
        @{ TileX = 42; TileY =  42; ZoomLevel = 12; Expected = "z12-y42-x42" }
    )
    It "Returns '<Expected>' using named arguments" -TestCases $examples {
        param($TileX, $TileY, $ZoomLevel, $Expected)
        Get-MapTileName -ZoomLevel $ZoomLevel -TileX $TileX -TileY $TileY `
            | Should -Be $Expected
    }
    It "Returns '<Expected>' using alias arguments" -TestCases $examples {
        param($TileX, $TileY, $ZoomLevel, $Expected)
        Get-MapTileName -Z $ZoomLevel -X $TileX -Y $TileY `
            | Should -Be $Expected
    }
    It "Returns '<Expected>' using pipeline properties" -TestCases $examples {
        param($TileX, $TileY, $ZoomLevel, $Expected)
        [PSCustomObject]@{
            TileX = $TileX
            TileY = $TileY
            ZoomLevel = $ZoomLevel
        } | Get-MapTileName | Should -Be $Expected
    }
    It "Returns '<Expected>' using pipeline alias properties" -TestCases $examples {
        param($TileX, $TileY, $ZoomLevel, $Expected)
        [PSCustomObject]@{
            X = $TileX
            Y = $TileY
            Z = $ZoomLevel
        } | Get-MapTileName | Should -Be $Expected
    }
    It "Truncates arguments to int" {
        $src = [PSCustomObject]@{
            TileX = 42
            TileY = 42
            ZoomLevel = 12
        }
        $name = $src | Get-MapTileName
        Get-MapTileName -TileX ($src.TileX + 0.123) -TileY ($src.TileY + 0.123) `
            -ZoomLevel 12 | Should -Be $name
        Get-MapTileName -TileX ($src.TileX - 1 + 0.678) -TileY ($src.TileY - 1 + 0.678) `
            -ZoomLevel 12 | Should -Be $name
    }
}

Describe "Get-MapTileFromPoint" {
    It "Returns the correct map tile for a known point" {
        # Ishavskatedralen, Tromsdalen, Norway
        # The Artic Cathedral, Tromsdalen, Norway
        $point = [PSCustomObject]@{
            DegreesLatitude = 69.648
            DegreesLongitude = 18.9874
        }
        $tile = $point | Get-MapTileFromPoint -ZoomLevel 15
        $tile.TileX | Should -Be 18112
        $tile.TileY | Should -Be 7426
    }
}
