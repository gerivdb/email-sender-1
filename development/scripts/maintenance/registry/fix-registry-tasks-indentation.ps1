# Script pour corriger l'indentation des tÃ¢ches de registre dans le document actif

# Chemin du document actif
$documentPath = "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/docs/plans/plan-modes-stepup.md"

# VÃ©rifier que le document existe
if (-not (Test-Path -Path $documentPath)) {
    Write-Error "Le document actif n'existe pas : $documentPath"
    exit 1
}

try {
    # Lire le contenu du document
    $content = Get-Content -Path $documentPath -Encoding UTF8
    $modified = $false
    $tasksUpdated = 0

    # Lignes Ã  corriger avec leur indentation correcte
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

    # Parcourir chaque ligne Ã  corriger
    foreach ($lineInfo in $linesToFix) {
        $lineNumber = $lineInfo.LineNumber - 1  # Ajuster pour l'index 0-based
        $line = $content[$lineNumber]
        $taskId = $lineInfo.TaskId
        $indentation = $lineInfo.Indentation

        # Extraire le texte de la tÃ¢che (tout ce qui suit la case Ã  cocher)
        if ($line -match '^\s*-\s+\[x\]\s+(.*)') {
            $taskText = $matches[1]
            
            # CrÃ©er la nouvelle ligne avec l'indentation correcte
            $newLine = "$indentation- [x] $taskText"
            $content[$lineNumber] = $newLine
            $modified = $true
            $tasksUpdated++
            
            Write-Verbose "Indentation corrigÃ©e pour la tÃ¢che : $taskId"
        }
    }

    # Enregistrer les modifications si nÃ©cessaire
    if ($modified) {
        $content | Set-Content -Path $documentPath -Encoding UTF8
        Write-Output "$tasksUpdated lignes ont Ã©tÃ© corrigÃ©es avec l'indentation appropriÃ©e dans le document : $documentPath"
    } else {
        Write-Output "Aucune ligne n'a Ã©tÃ© modifiÃ©e dans le document : $documentPath"
    }
}
catch {
    Write-Error "Erreur lors de la correction des indentations : $_"
}
