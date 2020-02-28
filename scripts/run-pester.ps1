[CmdletBinding()]
param (
    [switch]$Install = $false
)

if ([string]::IsNullOrWhiteSpace($Env:BUILD_SOURCESDIRECTORY)) {
    $pesterTestPath = Join-Path (Join-Path $PSScriptRoot "..") "test"
}
else {
    $pesterTestPath = Join-Path $Env:BUILD_SOURCESDIRECTORY "test"
}
$pesterTestPath = Join-Path $pesterTestPath "*"

if ([string]::IsNullOrWhiteSpace($Env:COMMON_TESTRESULTSDIRECTORY)) {
    $outputDirectory = Join-Path (Join-Path $PSScriptRoot "..") "TestResult"
}
else {
    $outputDirectory = Join-Path $Env:COMMON_TESTRESULTSDIRECTORY "TestResult"
}
if ([string]::IsNullOrWhiteSpace($Env:BUILD_BUILDNUMBER)) {
    $dtNow = [datetime]::UtcNow
    $dateString = $dtNow.ToString("yyyy'-'MM'-'dd")
    $timeString = $dtNow.ToString("HH'-'mm'-'ss")
    $outputFileName = "TEST-pester-$dateString-utc-$timeString.xml"
}
else {
    $outputFileName = "TEST-pester-$Env:BUILD_BUILDNUMBER.xml"
}
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory $outputDirectory | Out-Null
}
$outputFilePath = Join-Path $outputDirectory $outputFileName

if ($Install) {
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}
Import-Module Pester -Force
Invoke-Pester -Script $pesterTestPath -EnableExit -OutputFormat NUnitXml `
    -OutputFile $outputFilePath
