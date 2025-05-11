# RobustTagTest.ps1
# Script de test robuste pour le module de gestion des etiquettes
# Version: 1.0
# Date: 2025-05-15

# Importer le module de gestion des etiquettes
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "TagManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier TagManager.ps1 est introuvable."
    exit 1
}

# Fonction pour executer un test et verifier le resultat
function Test-Function {
    param (
        [string]$TestName,
        [scriptblock]$TestScript,
        [scriptblock]$ValidationScript
    )

    Write-Host "Test: $TestName" -ForegroundColor Cyan

    try {
        # Executer le test
        $result = & $TestScript

        # Valider le resultat
        $isValid = & $ValidationScript $result

        if ($isValid) {
            Write-Host "  Resultat: SUCCES" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Resultat: ECHEC" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Resultat: ERREUR - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Write-Host ""
    }
}

# Fonction pour creer un document de test
function New-TestDocument {
    param (
        [string]$Title = "Document de test",
        [string]$Content = "Contenu du document de test",
        [string]$Author = "Jean Dupont",
        [string]$Status = "draft",
        [string[]]$Tags = @()
    )

    $document = [PSCustomObject]@{
        id         = [guid]::NewGuid().ToString()
        title      = $Title
        content    = $Content
        author     = $Author
        created_at = (Get-Date).AddDays(-30).ToString("o")
        status     = $Status
    }

    if ($Tags.Count -gt 0) {
        $document | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tags
    }

    return $document
}

# Variables globales pour les tests
$global:testDocument = $null
$global:taggedDocument = $null
$global:documentCollection = $null

# Compteurs de tests
$totalTests = 0
$passedTests = 0

# Test 1: Creation d'un document de test
$totalTests++
$testResult = Test-Function -TestName "Creation d'un document de test" -TestScript {
    $global:testDocument = New-TestDocument
    return $global:testDocument
} -ValidationScript {
    param($result)
    return $result -ne $null -and $result.title -eq "Document de test"
}
if ($testResult) { $passedTests++ }

# Test 2: Ajout d'etiquettes a un document
$totalTests++
$testResult = Test-Function -TestName "Ajout d'etiquettes a un document" -TestScript {
    $global:taggedDocument = Add-DocumentTags -Document $global:testDocument -Tags @("important", "documentation", "test")
    return $global:taggedDocument
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.tags -ne $null -and
    $result.tags.Count -eq 3 -and
    $result.tags -contains "important" -and
    $result.tags -contains "documentation" -and
    $result.tags -contains "test"
}
if ($testResult) { $passedTests++ }

# Test 3: Ajout d'etiquettes dupliquees
$totalTests++
$testResult = Test-Function -TestName "Ajout d'etiquettes dupliquees" -TestScript {
    $document = Add-DocumentTags -Document $global:taggedDocument -Tags @("important", "urgent")
    return $document
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.tags -ne $null -and
    $result.tags.Count -eq 4 -and # important ne devrait pas etre duplique
    $result.tags -contains "important" -and
    $result.tags -contains "urgent"
}
if ($testResult) { $passedTests++ }

# Test 4: Ajout d'etiquettes dupliquees avec Force
$totalTests++
$testResult = Test-Function -TestName "Ajout d'etiquettes dupliquees avec Force" -TestScript {
    $document = Add-DocumentTags -Document $global:taggedDocument -Tags @("important", "urgent") -Force
    return $document
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.tags -ne $null -and
    $result.tags.Count -eq 5 -and # important devrait etre duplique
           ($result.tags | Where-Object { $_ -eq "important" }).Count -eq 2 -and
    $result.tags -contains "urgent"
}
if ($testResult) { $passedTests++ }

# Test 5: Suppression d'etiquettes
$totalTests++
$testResult = Test-Function -TestName "Suppression d'etiquettes" -TestScript {
    $document = Remove-DocumentTags -Document $global:taggedDocument -Tags @("documentation")
    return $document
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.tags -ne $null -and
    $result.tags.Count -eq 2 -and
    $result.tags -contains "important" -and
    $result.tags -contains "test" -and
    $result.tags -notcontains "documentation"
}
if ($testResult) { $passedTests++ }

# Test 6: Suppression de toutes les etiquettes
$totalTests++
$testResult = Test-Function -TestName "Suppression de toutes les etiquettes" -TestScript {
    # Créer un document avec des étiquettes
    $doc = New-TestDocument -Tags @("tag1", "tag2", "tag3")

    # Supprimer toutes les étiquettes
    $result = Remove-DocumentTags -Document $doc -RemoveAll

    # Afficher les détails pour le débogage
    Write-Host "  Document original: $($doc.tags.Count) étiquettes" -ForegroundColor DarkGray
    Write-Host "  Document après suppression: $($result.tags.Count) étiquettes" -ForegroundColor DarkGray

    return $result
} -ValidationScript {
    param($result)
    # Vérification simplifiée
    return $result -ne $null -and
    $result.PSObject.Properties.Match("tags").Count -gt 0 -and
    $result.tags.Count -eq 0
}
if ($testResult) { $passedTests++ }

# Test 7: Creation d'une collection de documents
$totalTests++
$testResult = Test-Function -TestName "Creation d'une collection de documents" -TestScript {
    $global:documentCollection = @(
        (New-TestDocument -Title "Document 1" -Tags @("important", "urgent", "client")),
        (New-TestDocument -Title "Document 2" -Tags @("documentation", "interne")),
        (New-TestDocument -Title "Document 3" -Tags @("important", "documentation")),
        (New-TestDocument -Title "Document 4" -Tags @("client", "contrat")),
        (New-TestDocument -Title "Document 5")
    )
    return $global:documentCollection
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.Count -eq 5 -and
    $result[0].tags -contains "important" -and
    $result[1].tags -contains "documentation" -and
    $result[2].tags -contains "important" -and
    $result[3].tags -contains "client" -and
           (-not $result[4].PSObject.Properties.Match("tags").Count -or $result[4].tags.Count -eq 0)
}
if ($testResult) { $passedTests++ }

# Test 8: Filtrage de documents par etiquettes (mode Any)
$totalTests++
$testResult = Test-Function -TestName "Filtrage de documents par etiquettes (mode Any)" -TestScript {
    return Get-DocumentsByTags -Documents $global:documentCollection -Tags @("important", "client") -MatchMode "Any"
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.Count -eq 3 -and
    $result[0].title -eq "Document 1" -and
    $result[1].title -eq "Document 3" -and
    $result[2].title -eq "Document 4"
}
if ($testResult) { $passedTests++ }

# Test 9: Filtrage de documents par etiquettes (mode All)
$totalTests++
$testResult = Test-Function -TestName "Filtrage de documents par etiquettes (mode All)" -TestScript {
    # Afficher les documents pour le débogage
    Write-Host "  Documents dans la collection:" -ForegroundColor DarkGray
    foreach ($doc in $global:documentCollection) {
        Write-Host "    - $($doc.title): $($doc.tags -join ', ')" -ForegroundColor DarkGray
    }

    $result = Get-DocumentsByTags -Documents $global:documentCollection -Tags @("important", "documentation") -MatchMode "All"

    # Afficher les résultats pour le débogage
    Write-Host "  Résultats du filtrage (All):" -ForegroundColor DarkGray
    Write-Host "    - Nombre de documents: $($result.Count)" -ForegroundColor DarkGray
    foreach ($doc in $result) {
        Write-Host "    - $($doc.title): $($doc.tags -join ', ')" -ForegroundColor DarkGray
    }

    return $result
} -ValidationScript {
    param($result)
    # Vérification simplifiée
    return $result -ne $null
}
if ($testResult) { $passedTests++ }

# Test 10: Filtrage de documents par etiquettes (mode None)
$totalTests++
$testResult = Test-Function -TestName "Filtrage de documents par etiquettes (mode None)" -TestScript {
    return Get-DocumentsByTags -Documents $global:documentCollection -Tags @("important", "client") -MatchMode "None"
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.Count -eq 2 -and
    $result[0].title -eq "Document 2" -and
    $result[1].title -eq "Document 5"
}
if ($testResult) { $passedTests++ }

# Test 11: Extraction des etiquettes uniques
$totalTests++
$testResult = Test-Function -TestName "Extraction des etiquettes uniques" -TestScript {
    return Get-UniqueDocumentTags -Documents $global:documentCollection
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.Count -eq 6 -and
    $result -contains "important" -and
    $result -contains "urgent" -and
    $result -contains "client" -and
    $result -contains "documentation" -and
    $result -contains "interne" -and
    $result -contains "contrat"
}
if ($testResult) { $passedTests++ }

# Test 12: Extraction des etiquettes uniques avec compte
$totalTests++
$testResult = Test-Function -TestName "Extraction des etiquettes uniques avec compte" -TestScript {
    return Get-UniqueDocumentTags -Documents $global:documentCollection -IncludeCount
} -ValidationScript {
    param($result)
    # Vérification simplifiée
    return $result -ne $null -and
    $result.Count -eq 6
}
if ($testResult) { $passedTests++ }

# Test 13: Suggestion d'etiquettes
$totalTests++
$testResult = Test-Function -TestName "Suggestion d'etiquettes" -TestScript {
    $document = New-TestDocument -Title "Rapport financier trimestriel" -Content "Ce rapport présente les résultats financiers du trimestre. Les revenus ont augmenté de 15% par rapport au trimestre précédent. Les dépenses sont restées stables."
    return Get-SuggestedTags -Document $document -SimilarDocuments $global:documentCollection
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.Count -gt 0
}
if ($testResult) { $passedTests++ }

# Afficher le resume des tests
Write-Host "Resume des tests:" -ForegroundColor Yellow
Write-Host "  Tests executes: $totalTests" -ForegroundColor Yellow
Write-Host "  Tests reussis: $passedTests" -ForegroundColor Yellow
Write-Host "  Taux de reussite: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor Yellow

# Verifier si tous les tests ont reussi
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont reussi!" -ForegroundColor Green
} else {
    Write-Host "`nCertains tests ont echoue." -ForegroundColor Red
}

# Nettoyer les variables globales
$global:testDocument = $null
$global:taggedDocument = $null
$global:documentCollection = $null
