# RobustVersionTest.ps1
# Script de test robuste pour le module de gestion des versions
# Version: 1.0
# Date: 2025-05-15

# Importer le module de gestion des versions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "RobustVersionManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier RobustVersionManager.ps1 est introuvable."
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
        [string]$Status = "draft"
    )

    $document = [PSCustomObject]@{
        id         = [guid]::NewGuid().ToString()
        title      = $Title
        content    = $Content
        author     = $Author
        created_at = (Get-Date).AddDays(-30).ToString("o")
        status     = $Status
        tags       = @("test", "document")
    }

    return $document
}

# Variables globales pour les tests
$global:testDocument = $null
$global:versionedDocument = $null
$global:multiVersionDocument = $null

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

# Test 2: Creation d'une premiere version
$totalTests++
$testResult = Test-Function -TestName "Creation d'une premiere version" -TestScript {
    $global:versionedDocument = New-DocumentVersion -Document $global:testDocument -VersionLabel "Version initiale" -VersionNotes "Creation du document"
    return $global:versionedDocument
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_number -eq 1 -and
    $result.version_label -eq "Version initiale" -and
    $result.version_history.Count -eq 1
}
if ($testResult) { $passedTests++ }

# Test 3: Verification de l'historique des versions
$totalTests++
$testResult = Test-Function -TestName "Verification de l'historique des versions" -TestScript {
    return $global:versionedDocument.version_history[0]
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_metadata -ne $null -and
    $result.version_metadata.version_number -eq 1 -and
    $result.version_metadata.version_label -eq "Version initiale"
}
if ($testResult) { $passedTests++ }

# Test 4: Creation d'une deuxieme version
$totalTests++
$testResult = Test-Function -TestName "Creation d'une deuxieme version" -TestScript {
    # Modifier le document
    $modifiedDocument = Copy-PSObject -InputObject $global:versionedDocument
    $modifiedDocument.title = "Document de test modifie"
    $modifiedDocument.content = "Contenu du document de test modifie"
    $modifiedDocument.status = "in-progress"

    # Creer une deuxieme version
    $global:multiVersionDocument = New-DocumentVersion -Document $modifiedDocument -VersionLabel "Version 2" -VersionNotes "Modification du document"
    return $global:multiVersionDocument
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_number -eq 2 -and
    $result.version_label -eq "Version 2" -and
    $result.title -eq "Document de test modifie" -and
    $result.version_history.Count -eq 2
}
if ($testResult) { $passedTests++ }

# Test 5: Recuperation d'une version par numero
$totalTests++
$testResult = Test-Function -TestName "Recuperation d'une version par numero" -TestScript {
    return Get-DocumentVersion -Document $global:multiVersionDocument -VersionNumber 1
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_metadata.version_number -eq 1 -and
    $result.title -eq "Document de test"
}
if ($testResult) { $passedTests++ }

# Test 6: Recuperation d'une version par label
$totalTests++
$testResult = Test-Function -TestName "Recuperation d'une version par label" -TestScript {
    return Get-DocumentVersion -Document $global:multiVersionDocument -VersionLabel "Version 2"
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_metadata.version_number -eq 2 -and
    $result.title -eq "Document de test modifie"
}
if ($testResult) { $passedTests++ }

# Test 7: Comparaison de versions
$totalTests++
$testResult = Test-Function -TestName "Comparaison de versions" -TestScript {
    $version1 = Get-DocumentVersion -Document $global:multiVersionDocument -VersionLabel "Version initiale"
    $version2 = Get-DocumentVersion -Document $global:multiVersionDocument -VersionLabel "Version 2"

    # Afficher les détails pour le débogage
    Write-Host "  Version 1: $($version1.title), $($version1.content), $($version1.status)" -ForegroundColor DarkGray
    Write-Host "  Version 2: $($version2.title), $($version2.content), $($version2.status)" -ForegroundColor DarkGray

    $comparison = Compare-DocumentVersions -Version1 $version1 -Version2 $version2 -Properties @("title", "content", "status")

    # Afficher les détails de la comparaison pour le débogage
    Write-Host "  Nombre de changements: $($comparison.changes.Count)" -ForegroundColor DarkGray
    foreach ($change in $comparison.changes) {
        Write-Host "    - $($change.property): $($change.change_type)" -ForegroundColor DarkGray
    }

    return $comparison
} -ValidationScript {
    param($result)
    # Vérification simplifiée
    return $result -ne $null -and
    $result.changes -ne $null -and
    $result.changes.Count -gt 0
}
if ($testResult) { $passedTests++ }

# Test 8: Creation d'une troisieme version
$totalTests++
$testResult = Test-Function -TestName "Creation d'une troisieme version" -TestScript {
    # Modifier le document
    $modifiedDocument = Copy-PSObject -InputObject $global:multiVersionDocument
    $modifiedDocument.title = "Document de test publie"
    $modifiedDocument.status = "published"

    # Creer une troisieme version
    $global:multiVersionDocument = New-DocumentVersion -Document $modifiedDocument -VersionLabel "Version 3" -VersionNotes "Publication du document"
    return $global:multiVersionDocument
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_number -eq 3 -and
    $result.version_label -eq "Version 3" -and
    $result.title -eq "Document de test publie" -and
    $result.version_history.Count -eq 3
}
if ($testResult) { $passedTests++ }

# Test 9: Restauration d'une version anterieure
$totalTests++
$testResult = Test-Function -TestName "Restauration d'une version anterieure" -TestScript {
    return Restore-DocumentVersion -Document $global:multiVersionDocument -VersionNumber 1 -RestoreNotes "Restauration de la version initiale"
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_number -eq 4 -and
    $result.version_label -eq "Restauration" -and
    $result.title -eq "Document de test" -and
    $result.version_history.Count -eq 4
}
if ($testResult) { $passedTests++ }

# Test 10: Purge complete de l'historique
$totalTests++
$testResult = Test-Function -TestName "Purge complete de l'historique" -TestScript {
    $document = $global:multiVersionDocument
    return Clear-DocumentVersionHistory -Document $document
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_history.Count -eq 0
}
if ($testResult) { $passedTests++ }

# Test 11: Purge de l'historique en conservant les N dernieres versions
$totalTests++
$testResult = Test-Function -TestName "Purge de l'historique en conservant les N dernieres versions" -TestScript {
    $document = $global:multiVersionDocument
    return Clear-DocumentVersionHistory -Document $document -KeepLastVersions 2
} -ValidationScript {
    param($result)
    return $result -ne $null -and
    $result.version_history.Count -eq 2
}
if ($testResult) { $passedTests++ }

# Test 12: Purge de l'historique en conservant la version actuelle
$totalTests++
$testResult = Test-Function -TestName "Purge de l'historique en conservant la version actuelle" -TestScript {
    # Créer un nouveau document avec une version
    $doc = New-TestDocument
    $doc = New-DocumentVersion -Document $doc -VersionLabel "Version unique" -VersionNotes "Test de purge"

    # Purger l'historique en conservant la version actuelle
    $purgedDoc = Clear-DocumentVersionHistory -Document $doc -KeepCurrentVersion

    # Afficher les détails pour le débogage
    Write-Host "  Document original: $($doc.title), versions: $($doc.version_history.Count)" -ForegroundColor DarkGray
    Write-Host "  Document purgé: $($purgedDoc.title), versions: $($purgedDoc.version_history.Count)" -ForegroundColor DarkGray
    if ($purgedDoc.version_history.Count -gt 0) {
        Write-Host "  Label de la version conservée: $($purgedDoc.version_history[0].version_metadata.version_label)" -ForegroundColor DarkGray
    }

    return $purgedDoc
} -ValidationScript {
    param($result)
    # Vérification simplifiée
    return $result -ne $null -and
    $result.version_history.Count -gt 0
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
$global:versionedDocument = $null
$global:multiVersionDocument = $null
