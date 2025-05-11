# Test-TaskHistory.ps1
# Script de test pour les fonctions de génération d'historiques de modifications
# Version: 1.0
# Date: 2025-05-15

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\utils\Generate-TaskHistory.ps1"
Write-Host "Chargement du script: $scriptPath" -ForegroundColor Cyan
if (Test-Path $scriptPath) {
    Write-Host "Le fichier existe." -ForegroundColor Green
    . $scriptPath
    Write-Host "Script chargé avec succès." -ForegroundColor Green
} else {
    Write-Host "Le fichier n'existe pas!" -ForegroundColor Red
    exit
}

# Fonction pour exécuter tous les tests
function Invoke-AllTests {
    Write-Host "Exécution des tests pour les fonctions de génération d'historiques de modifications..." -ForegroundColor Cyan
    
    Test-TaskHistoryEntry
    Test-TaskHistory
    Test-TaskHistoryUpdate
    
    Write-Host "Tous les tests sont terminés." -ForegroundColor Green
}

# Test pour la fonction New-TaskHistoryEntry
function Test-TaskHistoryEntry {
    Write-Host "`nTest de la fonction New-TaskHistoryEntry:" -ForegroundColor Yellow
    
    # Test 1: Générer une entrée d'historique avec les paramètres par défaut
    Write-Host "  Test 1: Générer une entrée d'historique avec les paramètres par défaut" -ForegroundColor Gray
    $result1 = New-TaskHistoryEntry
    
    if ($null -ne $result1) {
        Write-Host "    Succès: Une entrée d'historique a été générée." -ForegroundColor Green
        Write-Host "      Date: $($result1.Date)" -ForegroundColor Gray
        Write-Host "      Utilisateur: $($result1.User)" -ForegroundColor Gray
        Write-Host "      Statut avant: $($result1.OldStatus)" -ForegroundColor Gray
        Write-Host "      Statut après: $($result1.NewStatus)" -ForegroundColor Gray
        Write-Host "      Progression avant: $($result1.OldProgress)%" -ForegroundColor Gray
        Write-Host "      Progression après: $($result1.NewProgress)%" -ForegroundColor Gray
        Write-Host "      Commentaire: $($result1.Comment)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Aucune entrée d'historique n'a été générée." -ForegroundColor Red
    }
    
    # Test 2: Générer une entrée d'historique avec des paramètres spécifiques
    Write-Host "  Test 2: Générer une entrée d'historique avec des paramètres spécifiques" -ForegroundColor Gray
    $result2 = New-TaskHistoryEntry -OldStatus "NotStarted" -NewStatus "InProgress" -OldProgress 0 -NewProgress 25 -Comment "Début du travail"
    
    if ($result2.OldStatus -eq "NotStarted" -and $result2.NewStatus -eq "InProgress" -and $result2.OldProgress -eq 0 -and $result2.NewProgress -eq 25 -and $result2.Comment -eq "Début du travail") {
        Write-Host "    Succès: L'entrée d'historique a été générée avec les paramètres spécifiés." -ForegroundColor Green
    } else {
        Write-Host "    Échec: L'entrée d'historique n'a pas été générée avec les paramètres spécifiés." -ForegroundColor Red
        Write-Host "      Statut avant: $($result2.OldStatus) (attendu: NotStarted)" -ForegroundColor Gray
        Write-Host "      Statut après: $($result2.NewStatus) (attendu: InProgress)" -ForegroundColor Gray
        Write-Host "      Progression avant: $($result2.OldProgress)% (attendu: 0%)" -ForegroundColor Gray
        Write-Host "      Progression après: $($result2.NewProgress)% (attendu: 25%)" -ForegroundColor Gray
        Write-Host "      Commentaire: $($result2.Comment) (attendu: Début du travail)" -ForegroundColor Gray
    }
    
    # Test 3: Générer une entrée d'historique avec une graine aléatoire
    Write-Host "  Test 3: Générer une entrée d'historique avec une graine aléatoire" -ForegroundColor Gray
    $result3a = New-TaskHistoryEntry -RandomSeed 12345
    $result3b = New-TaskHistoryEntry -RandomSeed 12345
    
    $sameUser = $result3a.User -eq $result3b.User
    $sameOldStatus = $result3a.OldStatus -eq $result3b.OldStatus
    $sameNewStatus = $result3a.NewStatus -eq $result3b.NewStatus
    $sameOldProgress = $result3a.OldProgress -eq $result3b.OldProgress
    $sameNewProgress = $result3a.NewProgress -eq $result3b.NewProgress
    $sameComment = $result3a.Comment -eq $result3b.Comment
    
    if ($sameUser -and $sameOldStatus -and $sameNewStatus -and $sameOldProgress -and $sameNewProgress -and $sameComment) {
        Write-Host "    Succès: Les entrées d'historique générées avec la même graine sont identiques." -ForegroundColor Green
    } else {
        Write-Host "    Échec: Les entrées d'historique générées avec la même graine sont différentes." -ForegroundColor Red
        Write-Host "      Même utilisateur: $sameUser" -ForegroundColor Gray
        Write-Host "      Même statut avant: $sameOldStatus" -ForegroundColor Gray
        Write-Host "      Même statut après: $sameNewStatus" -ForegroundColor Gray
        Write-Host "      Même progression avant: $sameOldProgress" -ForegroundColor Gray
        Write-Host "      Même progression après: $sameNewProgress" -ForegroundColor Gray
        Write-Host "      Même commentaire: $sameComment" -ForegroundColor Gray
    }
}

# Test pour la fonction New-TaskHistory
function Test-TaskHistory {
    Write-Host "`nTest de la fonction New-TaskHistory:" -ForegroundColor Yellow
    
    # Test 1: Générer un historique avec les paramètres par défaut
    Write-Host "  Test 1: Générer un historique avec les paramètres par défaut" -ForegroundColor Gray
    $result1 = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X"
    
    if ($null -ne $result1 -and $result1.Entries.Count -gt 0) {
        Write-Host "    Succès: Un historique a été généré avec $($result1.Entries.Count) entrées." -ForegroundColor Green
        Write-Host "      Tâche: $($result1.TaskId) - $($result1.TaskTitle)" -ForegroundColor Gray
        Write-Host "      Première entrée: $($result1.Entries[0].Date) - $($result1.Entries[0].OldStatus) -> $($result1.Entries[0].NewStatus)" -ForegroundColor Gray
        Write-Host "      Dernière entrée: $($result1.Entries[-1].Date) - $($result1.Entries[-1].OldStatus) -> $($result1.Entries[-1].NewStatus)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Aucun historique n'a été généré ou l'historique ne contient pas d'entrées." -ForegroundColor Red
    }
    
    # Test 2: Générer un historique pour une tâche complétée
    Write-Host "  Test 2: Générer un historique pour une tâche complétée" -ForegroundColor Gray
    $result2 = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X" -FinalStatus "Completed" -FinalProgress 100 -EntryCount 5
    
    if ($result2.Entries.Count -eq 5 -and $result2.Entries[-1].NewStatus -eq "Completed" -and $result2.Entries[-1].NewProgress -eq 100) {
        Write-Host "    Succès: Un historique a été généré pour une tâche complétée." -ForegroundColor Green
        Write-Host "      Nombre d'entrées: $($result2.Entries.Count) (attendu: 5)" -ForegroundColor Gray
        Write-Host "      Statut final: $($result2.Entries[-1].NewStatus) (attendu: Completed)" -ForegroundColor Gray
        Write-Host "      Progression finale: $($result2.Entries[-1].NewProgress)% (attendu: 100%)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: L'historique n'a pas été généré correctement pour une tâche complétée." -ForegroundColor Red
        Write-Host "      Nombre d'entrées: $($result2.Entries.Count) (attendu: 5)" -ForegroundColor Gray
        Write-Host "      Statut final: $($result2.Entries[-1].NewStatus) (attendu: Completed)" -ForegroundColor Gray
        Write-Host "      Progression finale: $($result2.Entries[-1].NewProgress)% (attendu: 100%)" -ForegroundColor Gray
    }
    
    # Test 3: Vérifier la cohérence des dates dans l'historique
    Write-Host "  Test 3: Vérifier la cohérence des dates dans l'historique" -ForegroundColor Gray
    $startDate = (Get-Date).AddMonths(-3)
    $endDate = Get-Date
    $result3 = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X" -StartDate $startDate -EndDate $endDate -EntryCount 10
    
    $datesInOrder = $true
    $previousDate = $null
    foreach ($entry in $result3.Entries) {
        if ($null -ne $previousDate -and $entry.Date -lt $previousDate) {
            $datesInOrder = $false
            break
        }
        $previousDate = $entry.Date
    }
    
    $firstDateAfterStart = $result3.Entries[0].Date -ge $startDate
    $lastDateBeforeEnd = $result3.Entries[-1].Date -le $endDate
    
    if ($datesInOrder -and $firstDateAfterStart -and $lastDateBeforeEnd) {
        Write-Host "    Succès: Les dates dans l'historique sont cohérentes." -ForegroundColor Green
        Write-Host "      Première date: $($result3.Entries[0].Date) (après $startDate)" -ForegroundColor Gray
        Write-Host "      Dernière date: $($result3.Entries[-1].Date) (avant $endDate)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Les dates dans l'historique ne sont pas cohérentes." -ForegroundColor Red
        Write-Host "      Dates en ordre chronologique: $datesInOrder" -ForegroundColor Gray
        Write-Host "      Première date après la date de début: $firstDateAfterStart" -ForegroundColor Gray
        Write-Host "      Dernière date avant la date de fin: $lastDateBeforeEnd" -ForegroundColor Gray
    }
}

# Test pour la fonction Update-TaskHistoryFromStatus
function Test-TaskHistoryUpdate {
    Write-Host "`nTest de la fonction Update-TaskHistoryFromStatus:" -ForegroundColor Yellow
    
    # Test 1: Mettre à jour un historique existant
    Write-Host "  Test 1: Mettre à jour un historique existant" -ForegroundColor Gray
    $history = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X" -EntryCount 3
    $initialEntryCount = $history.Entries.Count
    
    $updatedHistory = Update-TaskHistoryFromStatus -TaskHistory $history -NewStatus "Completed" -NewProgress 100 -Comment "Travail terminé"
    
    if ($updatedHistory.Entries.Count -eq $initialEntryCount + 1 -and $updatedHistory.Entries[-1].NewStatus -eq "Completed" -and $updatedHistory.Entries[-1].NewProgress -eq 100 -and $updatedHistory.Entries[-1].Comment -eq "Travail terminé") {
        Write-Host "    Succès: L'historique a été mis à jour correctement." -ForegroundColor Green
        Write-Host "      Nombre d'entrées: $($updatedHistory.Entries.Count) (attendu: $($initialEntryCount + 1))" -ForegroundColor Gray
        Write-Host "      Statut final: $($updatedHistory.Entries[-1].NewStatus) (attendu: Completed)" -ForegroundColor Gray
        Write-Host "      Progression finale: $($updatedHistory.Entries[-1].NewProgress)% (attendu: 100%)" -ForegroundColor Gray
        Write-Host "      Commentaire: $($updatedHistory.Entries[-1].Comment) (attendu: Travail terminé)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: L'historique n'a pas été mis à jour correctement." -ForegroundColor Red
        Write-Host "      Nombre d'entrées: $($updatedHistory.Entries.Count) (attendu: $($initialEntryCount + 1))" -ForegroundColor Gray
        Write-Host "      Statut final: $($updatedHistory.Entries[-1].NewStatus) (attendu: Completed)" -ForegroundColor Gray
        Write-Host "      Progression finale: $($updatedHistory.Entries[-1].NewProgress)% (attendu: 100%)" -ForegroundColor Gray
        Write-Host "      Commentaire: $($updatedHistory.Entries[-1].Comment) (attendu: Travail terminé)" -ForegroundColor Gray
    }
    
    # Test 2: Mettre à jour un historique vide
    Write-Host "  Test 2: Mettre à jour un historique vide" -ForegroundColor Gray
    $emptyHistory = [PSCustomObject]@{
        TaskId = "1.2.3"
        TaskTitle = "Implémenter la fonctionnalité X"
        Entries = @()
    }
    
    $updatedEmptyHistory = Update-TaskHistoryFromStatus -TaskHistory $emptyHistory -NewStatus "InProgress" -NewProgress 25 -Comment "Début du travail"
    
    if ($updatedEmptyHistory.Entries.Count -eq 1 -and $updatedEmptyHistory.Entries[0].OldStatus -eq "NotStarted" -and $updatedEmptyHistory.Entries[0].NewStatus -eq "InProgress" -and $updatedEmptyHistory.Entries[0].OldProgress -eq 0 -and $updatedEmptyHistory.Entries[0].NewProgress -eq 25 -and $updatedEmptyHistory.Entries[0].Comment -eq "Début du travail") {
        Write-Host "    Succès: L'historique vide a été mis à jour correctement." -ForegroundColor Green
        Write-Host "      Nombre d'entrées: $($updatedEmptyHistory.Entries.Count) (attendu: 1)" -ForegroundColor Gray
        Write-Host "      Statut initial: $($updatedEmptyHistory.Entries[0].OldStatus) (attendu: NotStarted)" -ForegroundColor Gray
        Write-Host "      Statut final: $($updatedEmptyHistory.Entries[0].NewStatus) (attendu: InProgress)" -ForegroundColor Gray
        Write-Host "      Progression initiale: $($updatedEmptyHistory.Entries[0].OldProgress)% (attendu: 0%)" -ForegroundColor Gray
        Write-Host "      Progression finale: $($updatedEmptyHistory.Entries[0].NewProgress)% (attendu: 25%)" -ForegroundColor Gray
        Write-Host "      Commentaire: $($updatedEmptyHistory.Entries[0].Comment) (attendu: Début du travail)" -ForegroundColor Gray
    } else {
        Write-Host "    Échec: L'historique vide n'a pas été mis à jour correctement." -ForegroundColor Red
        Write-Host "      Nombre d'entrées: $($updatedEmptyHistory.Entries.Count) (attendu: 1)" -ForegroundColor Gray
        if ($updatedEmptyHistory.Entries.Count -gt 0) {
            Write-Host "      Statut initial: $($updatedEmptyHistory.Entries[0].OldStatus) (attendu: NotStarted)" -ForegroundColor Gray
            Write-Host "      Statut final: $($updatedEmptyHistory.Entries[0].NewStatus) (attendu: InProgress)" -ForegroundColor Gray
            Write-Host "      Progression initiale: $($updatedEmptyHistory.Entries[0].OldProgress)% (attendu: 0%)" -ForegroundColor Gray
            Write-Host "      Progression finale: $($updatedEmptyHistory.Entries[0].NewProgress)% (attendu: 25%)" -ForegroundColor Gray
            Write-Host "      Commentaire: $($updatedEmptyHistory.Entries[0].Comment) (attendu: Début du travail)" -ForegroundColor Gray
        }
    }
    
    # Test 3: Mettre à jour un historique avec plusieurs mises à jour successives
    Write-Host "  Test 3: Mettre à jour un historique avec plusieurs mises à jour successives" -ForegroundColor Gray
    $history3 = New-TaskHistory -TaskId "1.2.3" -TaskTitle "Implémenter la fonctionnalité X" -EntryCount 1
    
    $history3 = Update-TaskHistoryFromStatus -TaskHistory $history3 -NewStatus "InProgress" -NewProgress 50 -Comment "Progression"
    $history3 = Update-TaskHistoryFromStatus -TaskHistory $history3 -NewStatus "Blocked" -NewProgress 50 -Comment "Blocage rencontré"
    $history3 = Update-TaskHistoryFromStatus -TaskHistory $history3 -NewStatus "InProgress" -NewProgress 75 -Comment "Blocage résolu"
    $history3 = Update-TaskHistoryFromStatus -TaskHistory $history3 -NewStatus "Completed" -NewProgress 100 -Comment "Travail terminé"
    
    $expectedStatuses = @("InProgress", "Blocked", "InProgress", "Completed")
    $expectedProgresses = @(50, 50, 75, 100)
    $expectedComments = @("Progression", "Blocage rencontré", "Blocage résolu", "Travail terminé")
    
    $statusesMatch = $true
    $progressesMatch = $true
    $commentsMatch = $true
    
    for ($i = 0; $i -lt 4; $i++) {
        $entry = $history3.Entries[$i + 1]  # +1 car il y a déjà une entrée initiale
        if ($entry.NewStatus -ne $expectedStatuses[$i]) {
            $statusesMatch = $false
        }
        if ($entry.NewProgress -ne $expectedProgresses[$i]) {
            $progressesMatch = $false
        }
        if ($entry.Comment -ne $expectedComments[$i]) {
            $commentsMatch = $false
        }
    }
    
    if ($statusesMatch -and $progressesMatch -and $commentsMatch) {
        Write-Host "    Succès: L'historique a été mis à jour correctement avec plusieurs mises à jour successives." -ForegroundColor Green
    } else {
        Write-Host "    Échec: L'historique n'a pas été mis à jour correctement avec plusieurs mises à jour successives." -ForegroundColor Red
        Write-Host "      Statuts correspondent: $statusesMatch" -ForegroundColor Gray
        Write-Host "      Progressions correspondent: $progressesMatch" -ForegroundColor Gray
        Write-Host "      Commentaires correspondent: $commentsMatch" -ForegroundColor Gray
    }
}

# Exécuter tous les tests
Write-Host "Démarrage des tests..." -ForegroundColor Cyan
Invoke-AllTests
Write-Host "Fin des tests." -ForegroundColor Cyan
