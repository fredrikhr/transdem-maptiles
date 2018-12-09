[CmdletBinding()]
param ()

$pesterTestPath = Join-Path (Join-Path $PSScriptRoot "..") "test"
$pesterTestPath = Join-Path $pesterTestPath "*"

$outputFileName = "TEST-date-$dateString-t-$timeString-Z.xml"
$outputDirectory = Join-Path (Join-Path $PSScriptRoot "..") "TestResult"
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory $outputDirectory | Out-Null
}
$outputFilePath = Join-Path $outputDirectory $outputFileName

Import-Module Pester
$pesterModule = Get-Module Pester
if ($pesterModule.Version -lt [version]::Parse("4.0")) {
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    Import-Module Pester -Force
}
Invoke-Pester -Script $pesterTestPath -EnableExit -OutputFormat NUnitXml `
    -OutputFile $outputFilePath
