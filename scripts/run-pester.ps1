# Enable -Verbose option
[CmdletBinding()]

$pesterTestPath = $null
if (-not $Env:BUILD_SOURCESDIRECTORY) {
    $pesterTestPath = Join-Path (Join-Path $PSScriptRoot "..") "test"
} else {
    $pesterTestPath = Join-Path $Env:BUILD_SOURCESDIRECTORY "test"
}
$pesterTestPath = Join-Path $pesterTestPath "*"

$outputFileName = $null
if (-not $Env:BUILD_BUILDNUMBER) {
    $dtNow = [datetime]::UtcNow
    $dateString = $dtNow.ToString("yyyy-MM-dd")
    $timeString = $dtNow.ToString("HH-mm-ss")
    $outputFileName = "TEST-pester-build-unknown-date-$dateString-t-$timeString-Z.xml"
} else {
    $outputFileName = "TEST-pester-$Env:BUILD_BUILDNUMBER.xml"
}
$outputDirectory = $null
if (-not $ENV:COMMON_TESTRESULTSDIRECTORY) {
    $outputDirectory = Join-Path (Join-Path $PSScriptRoot "..") "TestResult"
} else {
    $outputDirectory = $ENV:COMMON_TESTRESULTSDIRECTORY
}
if (-not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory $outputDirectory | Out-Null
}
$outputFilePath = Join-Path $outputDirectory $outputFileName

Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
Import-Module Pester -Force
Invoke-Pester -Script $pesterTestPath -EnableExit -OutputFormat NUnitXml `
    -OutputFile $outputFilePath
