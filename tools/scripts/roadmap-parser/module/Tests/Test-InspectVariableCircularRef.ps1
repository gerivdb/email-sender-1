<#
.SYNOPSIS
    Test spÃ©cifique pour la dÃ©tection des rÃ©fÃ©rences circulaires dans Inspect-Variable.

.DESCRIPTION
    Ce script teste spÃ©cifiquement la dÃ©tection des rÃ©fÃ©rences circulaires
    dans la fonction Inspect-Variable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Chemin vers la fonction Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable Ã  l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importÃ©e depuis : $functionPath" -ForegroundColor Green

# CrÃ©er un objet avec une rÃ©fÃ©rence circulaire
$parent = [PSCustomObject]@{
    Name = "Parent"
}
$child = [PSCustomObject]@{
    Name   = "Child"
    Parent = $parent
}
$parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

# Test 1: DÃ©tection des rÃ©fÃ©rences circulaires avec CircularReferenceHandling=Mark
Write-Host "`nTest 1: DÃ©tection des rÃ©fÃ©rences circulaires avec CircularReferenceHandling=Mark" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Mark"

# VÃ©rifier si la rÃ©fÃ©rence circulaire est dÃ©tectÃ©e
$circularRefDetected = $false

# Afficher la structure complÃ¨te de l'objet pour le dÃ©bogage
Write-Host "  Structure complÃ¨te de l'objet:" -ForegroundColor Yellow
Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Yellow

# VÃ©rifier si Child existe
if ($result.Properties -and $result.Properties.ContainsKey("Child")) {
    Write-Host "  Child existe" -ForegroundColor Yellow
    $child = $result.Properties["Child"]

    # Afficher les propriÃ©tÃ©s de Child
    Write-Host "  PropriÃ©tÃ©s de Child:" -ForegroundColor Yellow
    foreach ($key in $child.Keys) {
        Write-Host "    $key = $($child[$key])" -ForegroundColor Yellow
    }

    # VÃ©rifier si Child.Properties existe
    if ($child.Properties) {
        Write-Host "  Child.Properties existe" -ForegroundColor Yellow

        # VÃ©rifier si Parent existe dans Child.Properties
        if ($child.Properties.ContainsKey("Parent")) {
            Write-Host "  Child.Properties.Parent existe" -ForegroundColor Yellow
            $parentRef = $child.Properties["Parent"]

            # Afficher les propriÃ©tÃ©s de Parent
            Write-Host "  PropriÃ©tÃ©s de Parent:" -ForegroundColor Yellow
            foreach ($key in $parentRef.Keys) {
                Write-Host "    $key = $($parentRef[$key])" -ForegroundColor Yellow
            }

            # VÃ©rifier si IsCircularReference existe
            if ($parentRef.ContainsKey("IsCircularReference") -and $parentRef.IsCircularReference) {
                $circularRefDetected = $true
                Write-Host "  RÃ©fÃ©rence circulaire dÃ©tectÃ©e correctement!" -ForegroundColor Green
                Write-Host "  IsCircularReference = $($parentRef.IsCircularReference)" -ForegroundColor Green
                Write-Host "  CircularPath = $($parentRef.CircularPath)" -ForegroundColor Green
                Write-Host "  CurrentPath = $($parentRef.CurrentPath)" -ForegroundColor Green
            } else {
                Write-Host "  RÃ©fÃ©rence circulaire non dÃ©tectÃ©e." -ForegroundColor Red
                Write-Host "  PropriÃ©tÃ©s disponibles: $($parentRef | Format-List | Out-String)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Child.Properties.Parent n'existe pas" -ForegroundColor Red
        }
    } else {
        Write-Host "  Child.Properties n'existe pas" -ForegroundColor Red
    }
} else {
    Write-Host "  Child n'existe pas dans les propriÃ©tÃ©s" -ForegroundColor Red
}

# Test 2: Exception avec CircularReferenceHandling=Throw
Write-Host "`nTest 2: Exception avec CircularReferenceHandling=Throw" -ForegroundColor Cyan
try {
    $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Throw"
    Write-Host "  Ã‰chec: Aucune exception n'a Ã©tÃ© levÃ©e" -ForegroundColor Red
    $exceptionThrown = $false
} catch {
    Write-Host "  Exception levÃ©e correctement: $_" -ForegroundColor Green
    $exceptionThrown = $true
}

# Test 3: Ignorer les rÃ©fÃ©rences circulaires avec CircularReferenceHandling=Ignore
Write-Host "`nTest 3: Ignorer les rÃ©fÃ©rences circulaires avec CircularReferenceHandling=Ignore" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Ignore"

# VÃ©rifier que la rÃ©fÃ©rence circulaire est ignorÃ©e
$circularRefIgnored = $false
if ($result.Properties -and
    $result.Properties["Child"] -and
    $result.Properties["Child"].Properties -and
    $result.Properties["Child"].Properties["Parent"]) {

    $parentRef = $result.Properties["Child"].Properties["Parent"]
    if (-not $parentRef.IsCircularReference) {
        $circularRefIgnored = $true
        Write-Host "  RÃ©fÃ©rence circulaire ignorÃ©e correctement!" -ForegroundColor Green
    } else {
        Write-Host "  RÃ©fÃ©rence circulaire non ignorÃ©e." -ForegroundColor Red
    }
} else {
    Write-Host "  Structure de l'objet incorrecte:" -ForegroundColor Red
    Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Red
}

# Test 4: DÃ©sactiver la dÃ©tection des rÃ©fÃ©rences circulaires
Write-Host "`nTest 4: DÃ©sactiver la dÃ©tection des rÃ©fÃ©rences circulaires" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -DetectCircularReferences $false

# VÃ©rifier que la dÃ©tection des rÃ©fÃ©rences circulaires est dÃ©sactivÃ©e
$circularRefDisabled = $false
if ($result.Properties -and
    $result.Properties["Child"] -and
    $result.Properties["Child"].Properties -and
    $result.Properties["Child"].Properties["Parent"]) {

    $parentRef = $result.Properties["Child"].Properties["Parent"]
    if (-not $parentRef.IsCircularReference) {
        $circularRefDisabled = $true
        Write-Host "  DÃ©tection des rÃ©fÃ©rences circulaires dÃ©sactivÃ©e correctement!" -ForegroundColor Green
    } else {
        Write-Host "  DÃ©tection des rÃ©fÃ©rences circulaires non dÃ©sactivÃ©e." -ForegroundColor Red
    }
} else {
    Write-Host "  Structure de l'objet incorrecte:" -ForegroundColor Red
    Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Red
}

# RÃ©sumÃ© des tests
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Test 1 (DÃ©tection): $(if ($circularRefDetected) { "RÃ©ussi" } else { "Ã‰chouÃ©" })" -ForegroundColor $(if ($circularRefDetected) { "Green" } else { "Red" })
Write-Host "  Test 2 (Exception): $(if ($exceptionThrown) { "RÃ©ussi" } else { "Ã‰chouÃ©" })" -ForegroundColor $(if ($exceptionThrown) { "Green" } else { "Red" })
Write-Host "  Test 3 (Ignorer): $(if ($circularRefIgnored) { "RÃ©ussi" } else { "Ã‰chouÃ©" })" -ForegroundColor $(if ($circularRefIgnored) { "Green" } else { "Red" })
Write-Host "  Test 4 (DÃ©sactiver): $(if ($circularRefDisabled) { "RÃ©ussi" } else { "Ã‰chouÃ©" })" -ForegroundColor $(if ($circularRefDisabled) { "Green" } else { "Red" })

# RÃ©sultat global
if ($circularRefDetected -and $exceptionThrown -and $circularRefIgnored -and $circularRefDisabled) {
    Write-Host "`nTous les tests ont rÃ©ussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont Ã©chouÃ©." -ForegroundColor Red
    exit 1
}
