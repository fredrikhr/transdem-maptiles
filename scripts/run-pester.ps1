[CmdletBinding()]
param ()

$pesterTestPath = Join-Path (Join-Path $PSScriptRoot "..") "test"
$pesterTestPath = Join-Path $pesterTestPath "*"

$dtNow = [datetime]::UtcNow
$dateString = $dtNow.ToString("yyyy'-'MM'-'dd")
$timeString = $dtNow.ToString("HH'-'mm'-'ss")
$outputFileName = "TEST-date-$dateString-utc-$timeString.xml"
$outputDirectory = Join-Path (Join-Path $PSScriptRoot "..") "TestResult"
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory $outputDirectory | Out-Null
}
$outputFilePath = Join-Path $outputDirectory $outputFileName

Import-Module Pester -Verbose:$false
$pesterModule = Get-Module Pester
if ($pesterModule.Version -lt [version]::Parse("4.0")) {
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module Pester -Force -Verbose:$false
}
Invoke-Pester -Script $pesterTestPath -EnableExit -OutputFormat NUnitXml `
    -OutputFile $outputFilePath
