# Démonstration de la détection des distributions à queues lourdes

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\HeavyTailDetection.ps1"

# Fonction utilitaire pour générer des échantillons de distribution normale
function Get-NormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,
        
        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )
    
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Méthode Box-Muller pour générer des nombres aléatoires suivant une distribution normale
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Mean + $StdDev * $z
    }
    
    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde (Pareto)
function Get-ParetoSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $false)]
        [double]$Alpha = 1.5,
        
        [Parameter(Mandatory = $false)]
        [double]$Scale = 1
    )
    
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        $u = Get-Random -Minimum 0 -Maximum 1
        $x = $Scale / [Math]::Pow(1 - $u, 1 / $Alpha)
        $sample += $x
    }
    
    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde (t de Student)
function Get-StudentTSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $false)]
        [double]$Df = 3
    )
    
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Générer un échantillon suivant une distribution t de Student
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)  # Distribution normale standard
        $chi2 = 0
        for ($j = 0; $j -lt $Df; $j++) {
            $v = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
            $chi2 -= 2 * [Math]::Log($v)
        }
        $t = $z / [Math]::Sqrt($chi2 / $Df)  # Distribution t de Student
        $sample += $t
    }
    
    return $sample
}

# Fonction utilitaire pour générer des échantillons de distribution à queue lourde (mélange)
function Get-MixtureSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,
        
        [Parameter(Mandatory = $false)]
        [double]$MixingProportion = 0.9
    )
    
    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        $u = Get-Random -Minimum 0 -Maximum 1
        if ($u -lt $MixingProportion) {
            # Composante normale
            $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
            $u2 = Get-Random -Minimum 0 -Maximum 1
            $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
            $sample += $z
        } else {
            # Composante Pareto
            $u = Get-Random -Minimum 0 -Maximum 1
            $x = 1 / [Math]::Pow(1 - $u, 1 / 1.5)
            $sample += $x
        }
    }
    
    return $sample
}

# Fonction utilitaire pour afficher les résultats
function Show-HeavyTailResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DistributionName,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Results
    )
    
    Write-Host "`n=== $DistributionName ===" -ForegroundColor Magenta
    
    Write-Host "Indice de queue de Hill: $([Math]::Round($Results.HillIndex, 4))" -ForegroundColor Cyan
    Write-Host "Intervalle de confiance: [$([Math]::Round($Results.LowerCI, 4)), $([Math]::Round($Results.UpperCI, 4))]" -ForegroundColor Cyan
    Write-Host "Nombre de statistiques d'ordre utilisées (K): $($Results.K)" -ForegroundColor Cyan
    Write-Host "Queue analysée: $($Results.Tail)" -ForegroundColor Cyan
    
    if ($Results.IsHeavyTailed) {
        Write-Host "Résultat: Distribution à queue lourde" -ForegroundColor Red
    } else {
        Write-Host "Résultat: Distribution à queue légère" -ForegroundColor Green
    }
    
    Write-Host "Interprétation: $($Results.Interpretation)" -ForegroundColor Yellow
}

# Générer des échantillons de différentes distributions
$normalSample = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1
$paretoSample1 = Get-ParetoSample -NumPoints 1000 -Alpha 0.8 -Scale 1  # Queue très lourde (indice < 1)
$paretoSample2 = Get-ParetoSample -NumPoints 1000 -Alpha 1.5 -Scale 1  # Queue lourde (1 <= indice < 2)
$studentTSample = Get-StudentTSample -NumPoints 1000 -Df 3  # Queue modérément lourde (2 <= indice < 3)
$mixtureSample = Get-MixtureSample -NumPoints 1000 -MixingProportion 0.9  # Mélange de distributions

# Analyser les distributions
$normalResults = Test-HeavyTail -Data $normalSample
$paretoResults1 = Test-HeavyTail -Data $paretoSample1
$paretoResults2 = Test-HeavyTail -Data $paretoSample2
$studentTResults = Test-HeavyTail -Data $studentTSample
$mixtureResults = Test-HeavyTail -Data $mixtureSample

# Afficher les résultats
Write-Host "`n=== Démonstration de la détection des distributions à queues lourdes ===" -ForegroundColor Magenta

Show-HeavyTailResults -DistributionName "Distribution normale" -Results $normalResults
Show-HeavyTailResults -DistributionName "Distribution de Pareto (alpha = 0.8)" -Results $paretoResults1
Show-HeavyTailResults -DistributionName "Distribution de Pareto (alpha = 1.5)" -Results $paretoResults2
Show-HeavyTailResults -DistributionName "Distribution t de Student (df = 3)" -Results $studentTResults
Show-HeavyTailResults -DistributionName "Distribution de mélange (90% normale, 10% Pareto)" -Results $mixtureResults

# Démonstration de l'analyse de la stabilité de l'indice de queue de Hill
Write-Host "`n=== Analyse de la stabilité de l'indice de queue de Hill ===" -ForegroundColor Magenta

$paretoPlot = Get-HillTailIndexPlot -Data $paretoSample2 -MinK 10 -MaxK 100
$normalPlot = Get-HillTailIndexPlot -Data $normalSample -MinK 10 -MaxK 100

Write-Host "`nDistribution de Pareto (alpha = 1.5):" -ForegroundColor Cyan
Write-Host "Valeur optimale de K: $($paretoPlot.OptimalK)" -ForegroundColor Yellow
Write-Host "Indice de queue de Hill pour K optimal: $([Math]::Round($paretoPlot.OptimalIndex.Index, 4))" -ForegroundColor Yellow
Write-Host "Intervalle de confiance: [$([Math]::Round($paretoPlot.OptimalIndex.LowerCI, 4)), $([Math]::Round($paretoPlot.OptimalIndex.UpperCI, 4))]" -ForegroundColor Yellow

Write-Host "`nDistribution normale:" -ForegroundColor Cyan
Write-Host "Valeur optimale de K: $($normalPlot.OptimalK)" -ForegroundColor Yellow
Write-Host "Indice de queue de Hill pour K optimal: $([Math]::Round($normalPlot.OptimalIndex.Index, 4))" -ForegroundColor Yellow
Write-Host "Intervalle de confiance: [$([Math]::Round($normalPlot.OptimalIndex.LowerCI, 4)), $([Math]::Round($normalPlot.OptimalIndex.UpperCI, 4))]" -ForegroundColor Yellow

# Démonstration de l'analyse des deux queues
Write-Host "`n=== Analyse des deux queues ===" -ForegroundColor Magenta

$rightTailResults = Test-HeavyTail -Data $studentTSample -Tail "Right"
$leftTailResults = Test-HeavyTail -Data $studentTSample -Tail "Left"
$bothTailsResults = Test-HeavyTail -Data $studentTSample -Tail "Both"

Write-Host "`nDistribution t de Student (df = 3):" -ForegroundColor Cyan
Write-Host "Queue droite - Indice de queue de Hill: $([Math]::Round($rightTailResults.HillIndex, 4))" -ForegroundColor Yellow
Write-Host "Queue gauche - Indice de queue de Hill: $([Math]::Round($leftTailResults.HillIndex, 4))" -ForegroundColor Yellow
Write-Host "Les deux queues - Indice de queue de Hill: $([Math]::Round($bothTailsResults.HillIndex, 4))" -ForegroundColor Yellow

# Démonstration de l'analyse d'un jeu de données réel (rendements boursiers)
Write-Host "`n=== Analyse d'un jeu de données simulé (rendements boursiers) ===" -ForegroundColor Magenta

# Simuler des rendements boursiers avec des sauts occasionnels
$stockReturns = @()
for ($i = 0; $i -lt 1000; $i++) {
    $u = Get-Random -Minimum 0 -Maximum 1
    if ($u -lt 0.95) {
        # Rendement normal
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $stockReturns += 0.001 + 0.01 * $z
    } else {
        # Saut (crash ou hausse soudaine)
        $u = Get-Random -Minimum 0 -Maximum 1
        if ($u -lt 0.5) {
            # Crash
            $stockReturns += -0.05 - 0.03 * (Get-Random -Minimum 0 -Maximum 1)
        } else {
            # Hausse soudaine
            $stockReturns += 0.05 + 0.03 * (Get-Random -Minimum 0 -Maximum 1)
        }
    }
}

$stockResults = Test-HeavyTail -Data $stockReturns
Show-HeavyTailResults -DistributionName "Rendements boursiers simulés" -Results $stockResults

# Analyser séparément les rendements positifs et négatifs
$positiveReturns = $stockReturns | Where-Object { $_ -gt 0 }
$negativeReturns = $stockReturns | Where-Object { $_ -lt 0 } | ForEach-Object { [Math]::Abs($_) }

$positiveResults = Test-HeavyTail -Data $positiveReturns
$negativeResults = Test-HeavyTail -Data $negativeReturns

Write-Host "`nRendements positifs:" -ForegroundColor Cyan
Write-Host "Indice de queue de Hill: $([Math]::Round($positiveResults.HillIndex, 4))" -ForegroundColor Yellow
Write-Host "Résultat: $(if ($positiveResults.IsHeavyTailed) { 'Distribution à queue lourde' } else { 'Distribution à queue légère' })" -ForegroundColor Yellow

Write-Host "`nRendements négatifs (valeur absolue):" -ForegroundColor Cyan
Write-Host "Indice de queue de Hill: $([Math]::Round($negativeResults.HillIndex, 4))" -ForegroundColor Yellow
Write-Host "Résultat: $(if ($negativeResults.IsHeavyTailed) { 'Distribution à queue lourde' } else { 'Distribution à queue légère' })" -ForegroundColor Yellow

Write-Host "`nConclusion: $(if ($negativeResults.HillIndex -lt $positiveResults.HillIndex) { 'Les pertes extrêmes sont plus probables que les gains extrêmes.' } else { 'Les gains extrêmes sont plus probables que les pertes extrêmes.' })" -ForegroundColor Green
