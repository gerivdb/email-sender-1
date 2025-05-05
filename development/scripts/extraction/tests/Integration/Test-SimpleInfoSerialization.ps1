# Test-SimpleInfoSerialization.ps1
# Test d'intégration pour la sérialisation d'une information simple en JSON

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test du workflow de sérialisation d'une information simple
Write-Host "Test du workflow de sérialisation d'une information simple en JSON" -ForegroundColor Cyan

# Étape 1: Créer une information extraite simple
Write-Host "Étape 1: Créer une information extraite simple" -ForegroundColor Cyan
$simpleInfo = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
$simpleInfo.ProcessingState = "Processed"
$simpleInfo.ConfidenceScore = 85
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "TestKey1" -Value "TestValue1"
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "TestKey2" -Value 123
$simpleInfo = Add-ExtractedInfoMetadata -Info $simpleInfo -Key "TestKey3" -Value $true

# Vérifier que l'information a été créée correctement
$tests1 = @(
    @{ Test = "L'information n'est pas nulle"; Condition = $null -ne $simpleInfo }
    @{ Test = "L'information a un ID valide"; Condition = [guid]::TryParse($simpleInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information a une source correcte"; Condition = $simpleInfo.Source -eq "TestSource" }
    @{ Test = "L'information a un extracteur correct"; Condition = $simpleInfo.ExtractorName -eq "TestExtractor" }
    @{ Test = "L'information a un état de traitement correct"; Condition = $simpleInfo.ProcessingState -eq "Processed" }
    @{ Test = "L'information a un score de confiance correct"; Condition = $simpleInfo.ConfidenceScore -eq 85 }
    @{ Test = "L'information a des métadonnées TestKey1"; Condition = $simpleInfo.Metadata.ContainsKey("TestKey1") }
    @{ Test = "L'information a des métadonnées TestKey2"; Condition = $simpleInfo.Metadata.ContainsKey("TestKey2") }
    @{ Test = "L'information a des métadonnées TestKey3"; Condition = $simpleInfo.Metadata.ContainsKey("TestKey3") }
)

$success1 = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success1 = $false
    }
}

# Étape 2: Sérialiser l'information en JSON
Write-Host "Étape 2: Sérialiser l'information en JSON" -ForegroundColor Cyan
$jsonString = ConvertTo-ExtractedInfoJson -InputObject $simpleInfo

# Vérifier que la sérialisation a fonctionné correctement
$tests2 = @(
    @{ Test = "Le JSON n'est pas null"; Condition = $null -ne $jsonString }
    @{ Test = "Le JSON est une chaîne de caractères"; Condition = $jsonString -is [string] }
    @{ Test = "Le JSON n'est pas vide"; Condition = $jsonString.Length -gt 0 }
    @{ Test = "Le JSON contient l'ID"; Condition = $jsonString -match [regex]::Escape($simpleInfo.Id) }
    @{ Test = "Le JSON contient la source"; Condition = $jsonString -match [regex]::Escape($simpleInfo.Source) }
    @{ Test = "Le JSON contient l'extracteur"; Condition = $jsonString -match [regex]::Escape($simpleInfo.ExtractorName) }
    @{ Test = "Le JSON contient l'état de traitement"; Condition = $jsonString -match [regex]::Escape($simpleInfo.ProcessingState) }
    @{ Test = "Le JSON contient le score de confiance"; Condition = $jsonString -match [regex]::Escape($simpleInfo.ConfidenceScore.ToString()) }
    @{ Test = "Le JSON contient la métadonnée TestKey1"; Condition = $jsonString -match [regex]::Escape("TestKey1") -and $jsonString -match [regex]::Escape("TestValue1") }
    @{ Test = "Le JSON contient la métadonnée TestKey2"; Condition = $jsonString -match [regex]::Escape("TestKey2") -and $jsonString -match [regex]::Escape("123") }
    @{ Test = "Le JSON contient la métadonnée TestKey3"; Condition = $jsonString -match [regex]::Escape("TestKey3") -and ($jsonString -match [regex]::Escape("true") -or $jsonString -match [regex]::Escape("True")) }
)

$success2 = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success2 = $false
    }
}

# Étape 3: Sauvegarder le JSON dans un fichier
Write-Host "Étape 3: Sauvegarder le JSON dans un fichier" -ForegroundColor Cyan
$jsonFilePath = Join-Path -Path $testDir -ChildPath "simpleInfo.json"
Set-Content -Path $jsonFilePath -Value $jsonString

# Vérifier que le fichier a été créé correctement
$tests3 = @(
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $jsonFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $jsonFilePath).Length -gt 0 }
)

$success3 = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success3 = $false
    }
}

# Étape 4: Désérialiser le JSON en objet
Write-Host "Étape 4: Désérialiser le JSON en objet" -ForegroundColor Cyan
$jsonContent = Get-Content -Path $jsonFilePath -Raw
$deserializedInfo = ConvertFrom-ExtractedInfoJson -Json $jsonContent

# Vérifier que la désérialisation a fonctionné correctement
$tests4 = @(
    @{ Test = "L'objet désérialisé n'est pas null"; Condition = $null -ne $deserializedInfo }
    @{ Test = "L'objet désérialisé a le même ID"; Condition = $deserializedInfo.Id -eq $simpleInfo.Id }
    @{ Test = "L'objet désérialisé a la même source"; Condition = $deserializedInfo.Source -eq $simpleInfo.Source }
    @{ Test = "L'objet désérialisé a le même extracteur"; Condition = $deserializedInfo.ExtractorName -eq $simpleInfo.ExtractorName }
    @{ Test = "L'objet désérialisé a le même état de traitement"; Condition = $deserializedInfo.ProcessingState -eq $simpleInfo.ProcessingState }
    @{ Test = "L'objet désérialisé a le même score de confiance"; Condition = $deserializedInfo.ConfidenceScore -eq $simpleInfo.ConfidenceScore }
    @{ Test = "L'objet désérialisé a la même métadonnée TestKey1"; Condition = $deserializedInfo.Metadata.ContainsKey("TestKey1") -and $deserializedInfo.Metadata["TestKey1"] -eq $simpleInfo.Metadata["TestKey1"] }
    @{ Test = "L'objet désérialisé a la même métadonnée TestKey2"; Condition = $deserializedInfo.Metadata.ContainsKey("TestKey2") -and $deserializedInfo.Metadata["TestKey2"] -eq $simpleInfo.Metadata["TestKey2"] }
    @{ Test = "L'objet désérialisé a la même métadonnée TestKey3"; Condition = $deserializedInfo.Metadata.ContainsKey("TestKey3") -and $deserializedInfo.Metadata["TestKey3"] -eq $simpleInfo.Metadata["TestKey3"] }
)

$success4 = $true
foreach ($test in $tests4) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success4 = $false
    }
}

# Étape 5: Utiliser les fonctions de sérialisation/désérialisation intégrées
Write-Host "Étape 5: Utiliser les fonctions de sérialisation/désérialisation intégrées" -ForegroundColor Cyan
$integratedFilePath = Join-Path -Path $testDir -ChildPath "simpleInfo_integrated.json"

# Sauvegarder l'information dans un fichier
$saveResult = Save-ExtractedInfoToFile -Info $simpleInfo -FilePath $integratedFilePath

# Charger l'information depuis le fichier
$loadedInfo = Import-ExtractedInfoFromFile -FilePath $integratedFilePath

# Vérifier que les opérations intégrées ont fonctionné correctement
$tests5 = @(
    @{ Test = "La sauvegarde a réussi"; Condition = $saveResult -eq $true }
    @{ Test = "Le fichier existe"; Condition = Test-Path -Path $integratedFilePath }
    @{ Test = "Le fichier n'est pas vide"; Condition = (Get-Item -Path $integratedFilePath).Length -gt 0 }
    @{ Test = "L'objet chargé n'est pas null"; Condition = $null -ne $loadedInfo }
    @{ Test = "L'objet chargé a le même ID"; Condition = $loadedInfo.Id -eq $simpleInfo.Id }
    @{ Test = "L'objet chargé a la même source"; Condition = $loadedInfo.Source -eq $simpleInfo.Source }
    @{ Test = "L'objet chargé a le même extracteur"; Condition = $loadedInfo.ExtractorName -eq $simpleInfo.ExtractorName }
    @{ Test = "L'objet chargé a le même état de traitement"; Condition = $loadedInfo.ProcessingState -eq $simpleInfo.ProcessingState }
    @{ Test = "L'objet chargé a le même score de confiance"; Condition = $loadedInfo.ConfidenceScore -eq $simpleInfo.ConfidenceScore }
    @{ Test = "L'objet chargé a la même métadonnée TestKey1"; Condition = $loadedInfo.Metadata.ContainsKey("TestKey1") -and $loadedInfo.Metadata["TestKey1"] -eq $simpleInfo.Metadata["TestKey1"] }
    @{ Test = "L'objet chargé a la même métadonnée TestKey2"; Condition = $loadedInfo.Metadata.ContainsKey("TestKey2") -and $loadedInfo.Metadata["TestKey2"] -eq $simpleInfo.Metadata["TestKey2"] }
    @{ Test = "L'objet chargé a la même métadonnée TestKey3"; Condition = $loadedInfo.Metadata.ContainsKey("TestKey3") -and $loadedInfo.Metadata["TestKey3"] -eq $simpleInfo.Metadata["TestKey3"] }
)

$success5 = $true
foreach ($test in $tests5) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success5 = $false
    }
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
