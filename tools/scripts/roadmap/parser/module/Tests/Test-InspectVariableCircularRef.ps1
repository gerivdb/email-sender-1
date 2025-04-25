<#
.SYNOPSIS
    Test spécifique pour la détection des références circulaires dans Inspect-Variable.

.DESCRIPTION
    Ce script teste spécifiquement la détection des références circulaires
    dans la fonction Inspect-Variable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Chemin vers la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$functionPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Inspect-Variable.ps1"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $functionPath)) {
    throw "Le fichier Inspect-Variable.ps1 est introuvable à l'emplacement : $functionPath"
}

# Importer la fonction
. $functionPath
Write-Host "Fonction Inspect-Variable importée depuis : $functionPath" -ForegroundColor Green

# Créer un objet avec une référence circulaire
$parent = [PSCustomObject]@{
    Name = "Parent"
}
$child = [PSCustomObject]@{
    Name   = "Child"
    Parent = $parent
}
$parent | Add-Member -MemberType NoteProperty -Name "Child" -Value $child

# Test 1: Détection des références circulaires avec CircularReferenceHandling=Mark
Write-Host "`nTest 1: Détection des références circulaires avec CircularReferenceHandling=Mark" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Mark"

# Vérifier si la référence circulaire est détectée
$circularRefDetected = $false

# Afficher la structure complète de l'objet pour le débogage
Write-Host "  Structure complète de l'objet:" -ForegroundColor Yellow
Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Yellow

# Vérifier si Child existe
if ($result.Properties -and $result.Properties.ContainsKey("Child")) {
    Write-Host "  Child existe" -ForegroundColor Yellow
    $child = $result.Properties["Child"]

    # Afficher les propriétés de Child
    Write-Host "  Propriétés de Child:" -ForegroundColor Yellow
    foreach ($key in $child.Keys) {
        Write-Host "    $key = $($child[$key])" -ForegroundColor Yellow
    }

    # Vérifier si Child.Properties existe
    if ($child.Properties) {
        Write-Host "  Child.Properties existe" -ForegroundColor Yellow

        # Vérifier si Parent existe dans Child.Properties
        if ($child.Properties.ContainsKey("Parent")) {
            Write-Host "  Child.Properties.Parent existe" -ForegroundColor Yellow
            $parentRef = $child.Properties["Parent"]

            # Afficher les propriétés de Parent
            Write-Host "  Propriétés de Parent:" -ForegroundColor Yellow
            foreach ($key in $parentRef.Keys) {
                Write-Host "    $key = $($parentRef[$key])" -ForegroundColor Yellow
            }

            # Vérifier si IsCircularReference existe
            if ($parentRef.ContainsKey("IsCircularReference") -and $parentRef.IsCircularReference) {
                $circularRefDetected = $true
                Write-Host "  Référence circulaire détectée correctement!" -ForegroundColor Green
                Write-Host "  IsCircularReference = $($parentRef.IsCircularReference)" -ForegroundColor Green
                Write-Host "  CircularPath = $($parentRef.CircularPath)" -ForegroundColor Green
                Write-Host "  CurrentPath = $($parentRef.CurrentPath)" -ForegroundColor Green
            } else {
                Write-Host "  Référence circulaire non détectée." -ForegroundColor Red
                Write-Host "  Propriétés disponibles: $($parentRef | Format-List | Out-String)" -ForegroundColor Red
            }
        } else {
            Write-Host "  Child.Properties.Parent n'existe pas" -ForegroundColor Red
        }
    } else {
        Write-Host "  Child.Properties n'existe pas" -ForegroundColor Red
    }
} else {
    Write-Host "  Child n'existe pas dans les propriétés" -ForegroundColor Red
}

# Test 2: Exception avec CircularReferenceHandling=Throw
Write-Host "`nTest 2: Exception avec CircularReferenceHandling=Throw" -ForegroundColor Cyan
try {
    $result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Throw"
    Write-Host "  Échec: Aucune exception n'a été levée" -ForegroundColor Red
    $exceptionThrown = $false
} catch {
    Write-Host "  Exception levée correctement: $_" -ForegroundColor Green
    $exceptionThrown = $true
}

# Test 3: Ignorer les références circulaires avec CircularReferenceHandling=Ignore
Write-Host "`nTest 3: Ignorer les références circulaires avec CircularReferenceHandling=Ignore" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -CircularReferenceHandling "Ignore"

# Vérifier que la référence circulaire est ignorée
$circularRefIgnored = $false
if ($result.Properties -and
    $result.Properties["Child"] -and
    $result.Properties["Child"].Properties -and
    $result.Properties["Child"].Properties["Parent"]) {

    $parentRef = $result.Properties["Child"].Properties["Parent"]
    if (-not $parentRef.IsCircularReference) {
        $circularRefIgnored = $true
        Write-Host "  Référence circulaire ignorée correctement!" -ForegroundColor Green
    } else {
        Write-Host "  Référence circulaire non ignorée." -ForegroundColor Red
    }
} else {
    Write-Host "  Structure de l'objet incorrecte:" -ForegroundColor Red
    Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Red
}

# Test 4: Désactiver la détection des références circulaires
Write-Host "`nTest 4: Désactiver la détection des références circulaires" -ForegroundColor Cyan
$result = Inspect-Variable -InputObject $parent -Format "Object" -DetectCircularReferences $false

# Vérifier que la détection des références circulaires est désactivée
$circularRefDisabled = $false
if ($result.Properties -and
    $result.Properties["Child"] -and
    $result.Properties["Child"].Properties -and
    $result.Properties["Child"].Properties["Parent"]) {

    $parentRef = $result.Properties["Child"].Properties["Parent"]
    if (-not $parentRef.IsCircularReference) {
        $circularRefDisabled = $true
        Write-Host "  Détection des références circulaires désactivée correctement!" -ForegroundColor Green
    } else {
        Write-Host "  Détection des références circulaires non désactivée." -ForegroundColor Red
    }
} else {
    Write-Host "  Structure de l'objet incorrecte:" -ForegroundColor Red
    Write-Host "  $($result | ConvertTo-Json -Depth 10)" -ForegroundColor Red
}

# Résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Test 1 (Détection): $(if ($circularRefDetected) { "Réussi" } else { "Échoué" })" -ForegroundColor $(if ($circularRefDetected) { "Green" } else { "Red" })
Write-Host "  Test 2 (Exception): $(if ($exceptionThrown) { "Réussi" } else { "Échoué" })" -ForegroundColor $(if ($exceptionThrown) { "Green" } else { "Red" })
Write-Host "  Test 3 (Ignorer): $(if ($circularRefIgnored) { "Réussi" } else { "Échoué" })" -ForegroundColor $(if ($circularRefIgnored) { "Green" } else { "Red" })
Write-Host "  Test 4 (Désactiver): $(if ($circularRefDisabled) { "Réussi" } else { "Échoué" })" -ForegroundColor $(if ($circularRefDisabled) { "Green" } else { "Red" })

# Résultat global
if ($circularRefDetected -and $exceptionThrown -and $circularRefIgnored -and $circularRefDisabled) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
