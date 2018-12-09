Import-Module Pester -Verbose:$false
Import-Module (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "src") "TrigonometryUtils.psm1")

Describe "Convert-DegreesToRadians" {
    $examples = @(
        @{ Value = 0; Expected = 0 }
        @{ Value = 90; Expected = [Math]::PI * 0.5 }
        @{ Value = 180; Expected = [Math]::PI }
        @{ Value = 360; Expected = [Math]::PI * 2 }
    )
    It "Converts <Value> using the named parameter and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        Convert-DegreesToRadians -Value $Value | Should -Be $Expected
    }
    It "Converts <Value> using the named parameter alias and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        Convert-DegreesToRadians -Degrees $Value | Should -Be $Expected
    }
    It "Converts <Value> using the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        $Value | Convert-DegreesToRadians | Should -Be $Expected
    }
    It "Converts <Value> using the Value-property of an object in the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        [PSCustomObject]@{
            Value = $Value
        } | Convert-DegreesToRadians | Should -Be $Expected
    }
    It "Converts <Value> using the Degrees-property of an object in the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        [PSCustomObject]@{
            Degrees = $Value
        } | Convert-DegreesToRadians | Should -Be $Expected
    }
}

Describe "Convert-RadiansToDegrees" {
    $examples = @(
        @{ Expected = 0; Value = 0 }
        @{ Expected = 90; Value = [Math]::PI * 0.5 }
        @{ Expected = 180; Value = [Math]::PI }
        @{ Expected = 360; Value = [Math]::PI * 2 }
    )
    It "Converts <Value> using the named parameter and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        Convert-RadiansToDegrees -Value $Value | Should -Be $Expected
    }
    It "Converts <Value> using the named parameter alias and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        Convert-RadiansToDegrees -Radians $Value | Should -Be $Expected
    }
    It "Converts <Value> using the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        $Value | Convert-RadiansToDegrees | Should -Be $Expected
    }
    It "Converts <Value> using the Value-property of an object in the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        [PSCustomObject]@{
            Value = $Value
        } | Convert-RadiansToDegrees | Should -Be $Expected
    }
    It "Converts <Value> using the Radians-property of an object in the pipeline and returns <Expected>" -TestCases $examples {
        param($Value, $Expected)

        [PSCustomObject]@{
            Radians = $Value
        } | Convert-RadiansToDegrees | Should -Be $Expected
    }
}
