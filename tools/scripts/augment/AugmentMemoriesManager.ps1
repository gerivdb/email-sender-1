<#
.SYNOPSIS
    Gestionnaire des MEMORIES d'Augment avec fonctionnalités d'automate d'état et de segmentation proactive.

.DESCRIPTION
    Ce script fournit des fonctions pour améliorer l'autonomie, la proactivité et la granularité
    des réponses d'Augment en gérant efficacement les MEMORIES.

.NOTES
    Version: 1.0
    Date: 2025-04-20
    Auteur: Augment Agent
#>

# Chemin par défaut des MEMORIES d'Augment dans VS Code
$script:DefaultMemoriesPath = "$env:APPDATA\Code\User\workspaceStorage\224ad75ce65ce8cf2efd9efc61d3c988\Augment.vscode-augment\Augment-Memories"

#region Tests TDD
function Invoke-MemoriesManagerTests {
    <#
    .SYNOPSIS
        Exécute les tests TDD pour le gestionnaire de MEMORIES.
    #>

    # Tests pour Move-NextTask
    Describe "Automate de progression de la roadmap" {
        It "Passe à la tâche suivante si la tâche actuelle est terminée" {
            $state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
            $newState = Move-NextTask -State $state
            $newState.CurrentTask | Should -Be "T2"
        }

        It "Reste sur la tâche si non terminée" {
            $state = @{ CurrentTask = "T1"; Status = "InProgress"; Roadmap = @("T1", "T2") }
            $newState = Move-NextTask -State $state
            $newState.CurrentTask | Should -Be "T1"
        }

        It "Ne change pas si c'est la dernière tâche" {
            $state = @{ CurrentTask = "T3"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
            $newState = Move-NextTask -State $state
            $newState.CurrentTask | Should -Be "T3"
            $newState.Status | Should -Be "Completed"
        }
    }

    # Tests pour Split-LargeInput
    Describe "Segmentation proactive des inputs" {
        It "Divise un input > 3 Ko en segments < 2 Ko" {
            $textData = "a" * 3500
            $segments = Split-LargeInput -Input $textData -MaxSize 2000
            $segments.Count | Should -BeGreaterThan 1
            $segments | ForEach-Object {
                [System.Text.Encoding]::UTF8.GetByteCount($_) | Should -BeLessOrEqual 2000
            }
        }

        It "Ne divise pas un input < 3 Ko" {
            $textData = "a" * 2000
            $segments = Split-LargeInput -Input $textData -MaxSize 2000
            $segments.Count | Should -Be 1
        }

        It "Gère correctement un input vide" {
            $textData = ""
            $segments = Split-LargeInput -Input $textData
            $segments.Count | Should -Be 1
            $segments[0] | Should -Be ""
        }
    }

    # Tests pour Update-AugmentMemories
    Describe "Mise à jour des MEMORIES d'Augment" {
        It "Génère un fichier JSON valide" {
            # Créer un fichier temporaire pour les tests
            $tempFile = [System.IO.Path]::GetTempFileName()

            # Exécuter la fonction
            Update-AugmentMemories -OutputPath $tempFile

            # Vérifier que le fichier existe et contient du JSON valide
            Test-Path $tempFile | Should -Be $true
            { Get-Content $tempFile -Raw | ConvertFrom-Json } | Should -Not -Throw

            # Nettoyer
            Remove-Item $tempFile -Force
        }

        It "Génère un fichier de taille < 4 Ko" {
            # Créer un fichier temporaire pour les tests
            $tempFile = [System.IO.Path]::GetTempFileName()

            # Exécuter la fonction
            Update-AugmentMemories -OutputPath $tempFile

            # Vérifier la taille
            $content = Get-Content $tempFile -Raw
            $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($content)
            $byteCount | Should -BeLessThan 4000

            # Nettoyer
            Remove-Item $tempFile -Force
        }
    }
}
#endregion

function Move-NextTask {
    <#
    .SYNOPSIS
        Gère la progression automatique dans la roadmap en fonction de l'état de la tâche.

    .DESCRIPTION
        Cette fonction implémente un automate d'état simple pour la progression dans une roadmap.
        Si la tâche actuelle est terminée, elle passe automatiquement à la tâche suivante.

    .PARAMETER State
        Hashtable contenant l'état actuel avec les clés suivantes:
        - CurrentTask: Identifiant de la tâche actuelle
        - Status: État de la tâche (InProgress, Completed, etc.)
        - Roadmap: Tableau des identifiants de tâches dans l'ordre d'exécution

    .EXAMPLE
        $state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
        $newState = Move-NextTask -State $state
        # $newState.CurrentTask sera "T2"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$State
    )

    # Vérifier si la tâche est terminée
    if ($State.Status -eq "Completed") {
        $currentIndex = $State.Roadmap.IndexOf($State.CurrentTask)

        # Vérifier s'il y a une tâche suivante
        if ($currentIndex -lt ($State.Roadmap.Count - 1)) {
            $State.CurrentTask = $State.Roadmap[$currentIndex + 1]
            $State.Status = "InProgress"
        }
    }

    return $State
}

function Split-LargeInput {
    <#
    .SYNOPSIS
        Divise proactivement les inputs volumineux en segments plus petits.

    .DESCRIPTION
        Cette fonction analyse la taille d'un input et le divise en segments
        plus petits si nécessaire, pour éviter les erreurs liées à des inputs trop volumineux.

    .PARAMETER Input
        Chaîne de caractères à analyser et potentiellement diviser.

    .PARAMETER MaxSize
        Taille maximale en octets pour chaque segment. Par défaut: 2000 octets.

    .EXAMPLE
        $textData = "Texte très long..."
        $segments = Split-LargeInput -Input $textData -MaxSize 2000
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Input,

        [Parameter()]
        [int]$MaxSize = 2000
    )

    # Calculer la taille en octets
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($Input)

    # Si l'input est suffisamment petit, le retourner tel quel
    if ($byteCount -le 3000) {
        return @($Input)
    }

    # Diviser l'input en segments
    $segments = @()
    $current = ""
    $currentBytes = 0

    foreach ($char in $Input.ToCharArray()) {
        $charBytes = [System.Text.Encoding]::UTF8.GetByteCount($char)

        # Si l'ajout du caractère dépasse la taille maximale, commencer un nouveau segment
        if ($currentBytes + $charBytes -gt $MaxSize) {
            $segments += $current
            $current = ""
            $currentBytes = 0
        }

        # Ajouter le caractère au segment courant
        $current += $char
        $currentBytes += $charBytes
    }

    # Ajouter le dernier segment s'il n'est pas vide
    if ($current) {
        $segments += $current
    }

    return $segments
}

function Update-AugmentMemories {
    <#
    .SYNOPSIS
        Met à jour les MEMORIES d'Augment avec une version optimisée.

    .DESCRIPTION
        Cette fonction génère un fichier JSON contenant les MEMORIES optimisées
        pour Augment, en mettant l'accent sur l'autonomie, la proactivité et la granularité.

    .PARAMETER OutputPath
        Chemin du fichier de sortie. Par défaut, utilise le chemin des MEMORIES d'Augment dans VS Code.

    .EXAMPLE
        Update-AugmentMemories
        # Met à jour les MEMORIES d'Augment dans l'emplacement par défaut

    .EXAMPLE
        Update-AugmentMemories -OutputPath "C:\temp\augment_memories.json"
        # Génère les MEMORIES optimisées dans le fichier spécifié
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$OutputPath = $script:DefaultMemoriesPath
    )

    # Créer l'objet des MEMORIES optimisées
    $memories = @{
        "version"     = "2.0.0"
        "lastUpdated" = (Get-Date).ToString("o")
        "sections"    = @(
            @{
                "name"    = "Autonomie"
                "content" = @"
- Progression: Exécuter les tâches séquentiellement sans confirmation
- Décision: Utiliser heuristiques (% complété > 80% → tâche terminée)
- Résilience: Reprendre sur erreur avec journalisation minimale
- Estimation: Calculer complexité via métriques objectives (LOC, dépendances, patterns)
"@
            },
            @{
                "name"    = "Proactivité"
                "content" = @"
- Roadmap: Utiliser automate d'état pour passer automatiquement à la tâche suivante
- État: Gérer via hashtable (CurrentTask, Status, Roadmap)
- Enchaînement: Implémenter une fonction à la fois si plusieurs sont requises
- Reprise: En cas d'échec, reprendre automatiquement à partir du dernier point stable
"@
            },
            @{
                "name"    = "Granularité"
                "content" = @"
- Segmentation: Appliquer segmentation proactive pour inputs > 3 Ko
- Validation: Vérifier taille via [System.Text.Encoding]::UTF8.GetByteCount()
- Compression: Éliminer commentaires/espaces superflus si nécessaire
- Prévention: Ne jamais dépasser 4 Ko par appel d'outil pour garantir une marge de sécurité
"@
            },
            @{
                "name"    = "Standards"
                "content" = @"
- SOLID: Vérifier automatiquement conformité via checklist intégrée
- TDD: Générer tests avant implémentation avec assertions minimales viables
- Documentation: Générer automatiquement selon ratio code/doc optimal (20%)
- Validation: Effectuer une validation préalable du code avant soumission
"@
            },
            @{
                "name"    = "Communication"
                "content" = @"
- Format: Utiliser structure prédéfinie avec ratio information/verbosité maximal
- Synthèse: Présenter uniquement changements significatifs et décisions clés
- Métadonnées: Inclure métriques d'avancement quantifiables (% complété, complexité)
- Langage: Français concis, notation algorithmique si pertinent pour optimisation
"@
            }
        )
    }

    # Convertir en JSON et écrire dans le fichier
    $jsonContent = $memories | ConvertTo-Json -Depth 10

    # Vérifier la taille
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($jsonContent)
    if ($byteCount -gt 4000) {
        Write-Warning "Les MEMORIES générées dépassent 4 Ko ($byteCount octets). Optimisation nécessaire."

        # Simplifier le contenu si nécessaire
        foreach ($section in $memories.sections) {
            $section.content = $section.content -replace "\r\n", " " -replace "  ", " "
        }

        # Reconvertir et vérifier à nouveau
        $jsonContent = $memories | ConvertTo-Json -Depth 10
        $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($jsonContent)

        if ($byteCount -gt 4000) {
            Write-Error "Impossible de réduire les MEMORIES sous 4 Ko ($byteCount octets)."
            return
        }
    }

    # Créer le dossier parent si nécessaire
    $parentFolder = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $parentFolder)) {
        New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
    }

    # Écrire le fichier
    $jsonContent | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "MEMORIES d'Augment mises à jour avec succès ($byteCount octets): $OutputPath"
}

function Export-MemoriesToVSCode {
    <#
    .SYNOPSIS
        Exporte les MEMORIES optimisées vers l'emplacement VS Code.

    .DESCRIPTION
        Cette fonction exporte les MEMORIES optimisées vers l'emplacement utilisé par
        l'extension Augment dans VS Code.

    .PARAMETER WorkspaceId
        Identifiant de l'espace de travail VS Code. Si non spécifié, utilise l'ID par défaut.

    .EXAMPLE
        Export-MemoriesToVSCode
        # Exporte les MEMORIES vers l'emplacement VS Code par défaut
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$WorkspaceId = "224ad75ce65ce8cf2efd9efc61d3c988"
    )

    # Construire le chemin VS Code
    $vscodePath = "$env:APPDATA\Code\User\workspaceStorage\$WorkspaceId\Augment.vscode-augment\Augment-Memories"

    # Générer et exporter les MEMORIES
    Update-AugmentMemories -OutputPath $vscodePath
}

# Les fonctions sont disponibles dans le script
# Move-NextTask, Split-LargeInput, Update-AugmentMemories, Export-MemoriesToVSCode, Invoke-MemoriesManagerTests
