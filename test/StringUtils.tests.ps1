Import-Module Pester -Verbose:$false
Import-Module (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "src") "StringUtils.psm1")

Describe "Get-Lines" {
    It "Returns 1 non-empty string if given a single-line string" {
        "This is a test" | Get-Lines | Should -Not -BeNullOrEmpty
    }
    It "Returns multiple strings if given a multi-line string using <SeparatorName> as line feed" -TestCases @(
        @{ Separator = "`r"; SeparatorName = "CR" }
        @{ Separator = "`n"; SeparatorName = "LF" }
        @{ Separator = "`r`n"; SeparatorName = "CRLF" }
    ) {
        param ($Separator)
        [string[]]$lines = (1..10)
        $test = [string]::Join($Separator, $lines)
        $test | Get-Lines | Should -Be $lines
    }
    It "Returns multiple trimmed strings if give a multi-line string and -Trim" {
        [string[]]$lines = (1..10)
        $writer = [System.Text.StringBuilder]::new()
        foreach ($item in $lines) {
            $writer.AppendLine(" `t$item `t")
        }
        $writer | Get-Lines -Trim | Should -Be $lines
    }
    It "Removes empty lines if given a multi-line string and -Options RemoveEmptyEntries" {
        [string[]]$lines = (1..10)
        $writer = [System.Text.StringBuilder]::new()
        foreach ($item in $lines) {
            $writer.AppendLine($item)
            $writer.AppendLine([string]::Empty)
        }
        $writer | Get-Lines -Options RemoveEmptyEntries | Should -Be $lines
    }
}
