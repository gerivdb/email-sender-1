# Simple test script for the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "HypothesisTestQualityMetricsASCII.psm1"
Import-Module -Name $modulePath -Force

# Test the Get-ZScore function
$zScore = Get-ZScore -ConfidenceLevel 0.95
Write-Host "Z-score for 95% confidence level: $zScore"

# Test the Get-RequiredSampleSize function
$sampleSize = Get-RequiredSampleSize -EffectSize 0.5 -Power 0.8 -Alpha 0.05 -TestType "bilateral"
Write-Host "Required sample size for medium effect with 80% power: $sampleSize"

# Test the Get-StatisticalPower function
$power = Get-StatisticalPower -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilateral"
Write-Host "Statistical power for medium effect with 64 subjects: $([Math]::Round($power, 4))"

# Test the Get-PowerStatisticsCriteria function
$criteria = Get-PowerStatisticsCriteria -EffectSize 0.5 -SampleSize 64 -Alpha 0.05 -TestType "bilateral" -ApplicationDomain "Recherche standard"
Write-Host "Power criteria for medium effect with 64 subjects:"
Write-Host "  - Calculated power: $([Math]::Round($criteria.CalculatedPower, 4))"
Write-Host "  - Recommended power: $($criteria.RecommendedPower)"
Write-Host "  - Power sufficient: $($criteria.IsPowerSufficient)"
Write-Host "  - Recommendations:"
foreach ($recommendation in $criteria.Recommendations) {
    Write-Host "    * $recommendation"
}
