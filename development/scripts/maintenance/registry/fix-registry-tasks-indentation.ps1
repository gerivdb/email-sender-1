# Script pour corriger l'indentation des tâches de registre dans le document actif

# Chemin du document actif
$documentPath = "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/docs/plans/plan-modes-stepup.md"

# Vérifier que le document existe
if (-not (Test-Path -Path $documentPath)) {
    Write-Error "Le document actif n'existe pas : $documentPath"
    exit 1
}

try {
    # Lire le contenu du document
    $content = Get-Content -Path $documentPath -Encoding UTF8
    $modified = $false
    $tasksUpdated = 0

    # Lignes à corriger avec leur indentation correcte
    $linesToFix = @(
        @{
            LineNumber = 493
            TaskId = "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.1"
            Indentation = "                                "
        },
        @{
            LineNumber = 494
            TaskId = "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.2"
            Indentation = "                                "
        },
        @{
            LineNumber = 495
            TaskId = "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.3"
            Indentation = "                                "
        },
        @{
            LineNumber = 496
            TaskId = "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.4"
            Indentation = "                                "
        },
        @{
            LineNumber = 497
            TaskId = "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.5"
            Indentation = "                                "
        }
    )

    # Parcourir chaque ligne à corriger
    foreach ($lineInfo in $linesToFix) {
        $lineNumber = $lineInfo.LineNumber - 1  # Ajuster pour l'index 0-based
        $line = $content[$lineNumber]
        $taskId = $lineInfo.TaskId
        $indentation = $lineInfo.Indentation

        # Extraire le texte de la tâche (tout ce qui suit la case à cocher)
        if ($line -match '^\s*-\s+\[x\]\s+(.*)') {
            $taskText = $matches[1]
            
            # Créer la nouvelle ligne avec l'indentation correcte
            $newLine = "$indentation- [x] $taskText"
            $content[$lineNumber] = $newLine
            $modified = $true
            $tasksUpdated++
            
            Write-Verbose "Indentation corrigée pour la tâche : $taskId"
        }
    }

    # Enregistrer les modifications si nécessaire
    if ($modified) {
        $content | Set-Content -Path $documentPath -Encoding UTF8
        Write-Output "$tasksUpdated lignes ont été corrigées avec l'indentation appropriée dans le document : $documentPath"
    } else {
        Write-Output "Aucune ligne n'a été modifiée dans le document : $documentPath"
    }
}
catch {
    Write-Error "Erreur lors de la correction des indentations : $_"
}
