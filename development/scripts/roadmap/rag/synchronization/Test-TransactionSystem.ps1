<#
.SYNOPSIS
    Script de test pour le système de transactions avancé.

.DESCRIPTION
    Ce script teste le fonctionnement du système de transactions avancé,
    notamment les opérations ACID (Atomicité, Cohérence, Isolation, Durabilité).

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module de transactions
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$transactionSystemPath = Join-Path -Path $scriptDir -ChildPath "TransactionSystem.ps1"

if (Test-Path -Path $transactionSystemPath) {
    . $transactionSystemPath
} else {
    throw "Le module TransactionSystem.ps1 est requis mais n'a pas été trouvé à l'emplacement: $transactionSystemPath"
}

# Fonction pour afficher un message formaté
function Write-TestMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Success", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $colors = @{
        Info    = "White"
        Success = "Green"
        Warning = "Yellow"
        Error   = "Red"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Fonction pour créer un répertoire de test temporaire
function New-TestDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BasePath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [string]$DirectoryName = "TransactionSystemTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
    )

    $testDir = Join-Path -Path $BasePath -ChildPath $DirectoryName

    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    return $testDir
}

# Fonction pour tester les opérations de base du système de transactions
function Test-BasicTransactionOperations {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test des opérations de base du système de transactions" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer des fichiers de test
    $testFile1 = Join-Path -Path $testDir -ChildPath "file1.txt"
    $testFile2 = Join-Path -Path $testDir -ChildPath "file2.txt"

    "Contenu initial du fichier 1" | Out-File -FilePath $testFile1 -Encoding utf8
    "Contenu initial du fichier 2" | Out-File -FilePath $testFile2 -Encoding utf8

    Write-TestMessage "Fichiers de test créés" -Level "Info"

    # Créer une transaction
    $transaction = [AdvancedTransaction]::new("instance_test", 60000, @{}, $true)

    Write-TestMessage "Transaction créée: $($transaction.TransactionId)" -Level "Info"

    # Créer des ressources transactionnelles
    $resource1 = [FileTransactionalResource]::new($testFile1, $true)
    $resource2 = [FileTransactionalResource]::new($testFile2, $true)

    Write-TestMessage "Ressources transactionnelles créées" -Level "Info"

    # Ajouter les ressources à la transaction
    $transaction.AddResource($resource1.ResourceId, $resource1)
    $transaction.AddResource($resource2.ResourceId, $resource2)

    Write-TestMessage "Ressources ajoutées à la transaction" -Level "Info"

    # Test 1: Lire l'état initial des ressources
    Write-TestMessage "Test 1: Lecture de l'état initial des ressources" -Level "Info"

    $state1 = $transaction.Read($resource1.ResourceId)
    $state2 = $transaction.Read($resource2.ResourceId)

    Write-TestMessage "État lu du fichier 1: '$state1'" -Level "Info"
    Write-TestMessage "État lu du fichier 2: '$state2'" -Level "Info"

    if ($state1 -like "*Contenu initial du fichier 1*" -and $state2 -like "*Contenu initial du fichier 2*") {
        Write-TestMessage "États initiaux lus avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la lecture des états initiaux" -Level "Error"
    }

    # Test 2: Modifier l'état des ressources
    Write-TestMessage "Test 2: Modification de l'état des ressources" -Level "Info"

    $transaction.Write($resource1.ResourceId, "Nouveau contenu du fichier 1")
    $transaction.Write($resource2.ResourceId, "Nouveau contenu du fichier 2")

    # Vérifier que les fichiers n'ont pas encore été modifiés (les modifications sont en mémoire)
    $fileContent1 = Get-Content -Path $testFile1 -Raw
    $fileContent2 = Get-Content -Path $testFile2 -Raw

    Write-TestMessage "Contenu actuel du fichier 1: '$fileContent1'" -Level "Info"
    Write-TestMessage "Contenu actuel du fichier 2: '$fileContent2'" -Level "Info"

    if ($fileContent1 -like "*Contenu initial du fichier 1*" -and $fileContent2 -like "*Contenu initial du fichier 2*") {
        Write-TestMessage "Les fichiers n'ont pas encore été modifiés (attendu)" -Level "Success"
    } else {
        Write-TestMessage "Les fichiers ont été modifiés prématurément" -Level "Error"
    }

    # Test 3: Valider la transaction
    Write-TestMessage "Test 3: Validation de la transaction" -Level "Info"

    $committed = $transaction.Commit()

    if ($committed) {
        Write-TestMessage "Transaction validée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de la validation de la transaction" -Level "Error"
    }

    # Vérifier que les fichiers ont été modifiés
    $fileContent1 = Get-Content -Path $testFile1 -Raw
    $fileContent2 = Get-Content -Path $testFile2 -Raw

    Write-TestMessage "Contenu après commit du fichier 1: '$fileContent1'" -Level "Info"
    Write-TestMessage "Contenu après commit du fichier 2: '$fileContent2'" -Level "Info"

    if ($fileContent1 -like "*Nouveau contenu du fichier 1*" -and $fileContent2 -like "*Nouveau contenu du fichier 2*") {
        Write-TestMessage "Les fichiers ont été modifiés correctement" -Level "Success"
    } else {
        Write-TestMessage "Les fichiers n'ont pas été modifiés correctement" -Level "Error"
    }

    Write-TestMessage "Tests des opérations de base terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester l'atomicité des transactions
function Test-TransactionAtomicity {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test d'atomicité des transactions" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer des fichiers de test
    $testFile1 = Join-Path -Path $testDir -ChildPath "file1.txt"
    $testFile2 = Join-Path -Path $testDir -ChildPath "file2.txt"
    $testFile3 = Join-Path -Path $testDir -ChildPath "file3.txt"  # Ce fichier n'existera pas

    "Contenu initial du fichier 1" | Out-File -FilePath $testFile1 -Encoding utf8
    "Contenu initial du fichier 2" | Out-File -FilePath $testFile2 -Encoding utf8

    # Créer un répertoire inaccessible pour forcer l'échec de la validation
    $inaccessibleDir = Join-Path -Path $testDir -ChildPath "inaccessible"
    New-Item -Path $inaccessibleDir -ItemType Directory -Force | Out-Null
    $testFile4 = Join-Path -Path $inaccessibleDir -ChildPath "file4.txt"

    # Rendre le répertoire inaccessible en écriture (simuler un problème de permissions)
    try {
        # Créer un fichier temporaire pour tester l'accès
        "" | Out-File -FilePath $testFile4 -Encoding utf8 -Force

        # Simuler un problème d'accès en rendant le fichier en lecture seule
        Set-ItemProperty -Path $testFile4 -Name IsReadOnly -Value $true
    } catch {
        Write-TestMessage "Erreur lors de la préparation du fichier inaccessible: $_" -Level "Warning"
    }

    Write-TestMessage "Fichiers de test créés" -Level "Info"

    # Créer une transaction
    $transaction = [AdvancedTransaction]::new("instance_test", 60000, @{}, $true)

    Write-TestMessage "Transaction créée: $($transaction.TransactionId)" -Level "Info"

    # Créer des ressources transactionnelles
    $resource1 = [FileTransactionalResource]::new($testFile1, $true)
    $resource2 = [FileTransactionalResource]::new($testFile2, $true)
    $resource3 = [FileTransactionalResource]::new($testFile4, $true)  # Fichier dans un répertoire inaccessible

    Write-TestMessage "Ressources transactionnelles créées" -Level "Info"

    # Ajouter les ressources à la transaction
    $transaction.AddResource($resource1.ResourceId, $resource1)
    $transaction.AddResource($resource2.ResourceId, $resource2)
    $transaction.AddResource($resource3.ResourceId, $resource3)

    Write-TestMessage "Ressources ajoutées à la transaction" -Level "Info"

    # Modifier l'état des ressources
    $transaction.Write($resource1.ResourceId, "Nouveau contenu du fichier 1")
    $transaction.Write($resource2.ResourceId, "Nouveau contenu du fichier 2")

    # Tenter de valider la transaction (devrait échouer car le fichier 3 n'existe pas)
    Write-TestMessage "Test: Tentative de validation d'une transaction avec une ressource invalide" -Level "Info"

    $committed = $transaction.Commit()

    if (-not $committed) {
        Write-TestMessage "La transaction a échoué comme prévu" -Level "Success"
    } else {
        Write-TestMessage "La transaction a réussi alors qu'elle aurait dû échouer" -Level "Error"
    }

    # Vérifier que les fichiers n'ont pas été modifiés (atomicité)
    $fileContent1 = Get-Content -Path $testFile1 -Raw
    $fileContent2 = Get-Content -Path $testFile2 -Raw

    Write-TestMessage "Contenu après tentative de commit du fichier 1: '$fileContent1'" -Level "Info"
    Write-TestMessage "Contenu après tentative de commit du fichier 2: '$fileContent2'" -Level "Info"

    if ($fileContent1 -like "*Contenu initial du fichier 1*" -and $fileContent2 -like "*Contenu initial du fichier 2*") {
        Write-TestMessage "Les fichiers n'ont pas été modifiés (atomicité préservée)" -Level "Success"
    } else {
        Write-TestMessage "Les fichiers ont été modifiés malgré l'échec de la transaction (atomicité violée)" -Level "Error"
    }

    Write-TestMessage "Tests d'atomicité terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Fonction pour tester le rollback des transactions
function Test-TransactionRollback {
    [CmdletBinding()]
    param()

    Write-TestMessage "Démarrage du test de rollback des transactions" -Level "Info"

    # Créer un répertoire de test
    $testDir = New-TestDirectory
    Write-TestMessage "Répertoire de test créé: $testDir" -Level "Info"

    # Créer des fichiers de test
    $testFile1 = Join-Path -Path $testDir -ChildPath "file1.txt"
    $testFile2 = Join-Path -Path $testDir -ChildPath "file2.txt"

    "Contenu initial du fichier 1" | Out-File -FilePath $testFile1 -Encoding utf8
    "Contenu initial du fichier 2" | Out-File -FilePath $testFile2 -Encoding utf8

    Write-TestMessage "Fichiers de test créés" -Level "Info"

    # Créer une transaction
    $transaction = [AdvancedTransaction]::new("instance_test", 60000, @{}, $true)

    Write-TestMessage "Transaction créée: $($transaction.TransactionId)" -Level "Info"

    # Créer des ressources transactionnelles
    $resource1 = [FileTransactionalResource]::new($testFile1, $true)
    $resource2 = [FileTransactionalResource]::new($testFile2, $true)

    Write-TestMessage "Ressources transactionnelles créées" -Level "Info"

    # Ajouter les ressources à la transaction
    $transaction.AddResource($resource1.ResourceId, $resource1)
    $transaction.AddResource($resource2.ResourceId, $resource2)

    Write-TestMessage "Ressources ajoutées à la transaction" -Level "Info"

    # Modifier l'état des ressources
    $transaction.Write($resource1.ResourceId, "Nouveau contenu du fichier 1")
    $transaction.Write($resource2.ResourceId, "Nouveau contenu du fichier 2")

    # Annuler la transaction
    Write-TestMessage "Test: Annulation d'une transaction" -Level "Info"

    $rolledBack = $transaction.Rollback()

    if ($rolledBack) {
        Write-TestMessage "La transaction a été annulée avec succès" -Level "Success"
    } else {
        Write-TestMessage "Échec de l'annulation de la transaction" -Level "Error"
    }

    # Vérifier que les fichiers n'ont pas été modifiés
    $fileContent1 = Get-Content -Path $testFile1 -Raw
    $fileContent2 = Get-Content -Path $testFile2 -Raw

    Write-TestMessage "Contenu après rollback du fichier 1: '$fileContent1'" -Level "Info"
    Write-TestMessage "Contenu après rollback du fichier 2: '$fileContent2'" -Level "Info"

    if ($fileContent1 -like "*Contenu initial du fichier 1*" -and $fileContent2 -like "*Contenu initial du fichier 2*") {
        Write-TestMessage "Les fichiers n'ont pas été modifiés (rollback réussi)" -Level "Success"
    } else {
        Write-TestMessage "Les fichiers ont été modifiés malgré le rollback" -Level "Error"
    }

    Write-TestMessage "Tests de rollback terminés" -Level "Info"

    # Nettoyage
    Remove-Item -Path $testDir -Recurse -Force
}

# Exécuter les tests
Write-TestMessage "Démarrage des tests du système de transactions" -Level "Info"
Test-BasicTransactionOperations
Test-TransactionAtomicity
Test-TransactionRollback
Write-TestMessage "Tous les tests du système de transactions sont terminés" -Level "Info"
