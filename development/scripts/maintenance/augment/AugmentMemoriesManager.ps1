<#
.SYNOPSIS
    Gestionnaire des MEMORIES d'Augment avec fonctionnalitÃ©s d'automate d'Ã©tat et de segmentation proactive.

.DESCRIPTION
    Ce script fournit des fonctions pour amÃ©liorer l'autonomie, la proactivitÃ© et la granularitÃ©
    des rÃ©ponses d'Augment en gÃ©rant efficacement les MEMORIES.

.NOTES
    Version: 1.0
    Date: 2025-04-20
    Auteur: Augment Agent
#>

# Chemin par dÃ©faut des MEMORIES d'Augment dans VS Code
$script:DefaultMemoriesPath = "$env:APPDATA\Code\User\workspaceStorage\224ad75ce65ce8cf2efd9efc61d3c988\Augment.vscode-augment\Augment-Memories"

#region Tests TDD
function Invoke-MemoriesManagerTests {
    <#
    .SYNOPSIS
        ExÃ©cute les tests TDD pour le gestionnaire de MEMORIES.
    #>

    # Tests pour Move-NextTask
    Describe "Automate de progression de la roadmap" {
        It "Passe Ã  la tÃ¢che suivante si la tÃ¢che actuelle est terminÃ©e" {
            $state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
            $newState = Move-NextTask -State $state
            $newState.CurrentTask | Should -Be "T2"
        }

        It "Reste sur la tÃ¢che si non terminÃ©e" {
            $state = @{ CurrentTask = "T1"; Status = "InProgress"; Roadmap = @("T1", "T2") }
            $newState = Move-NextTask -State $state
            $newState.CurrentTask | Should -Be "T1"
        }

        It "Ne change pas si c'est la derniÃ¨re tÃ¢che" {
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

        It "GÃ¨re correctement un input vide" {
            $textData = ""
            $segments = Split-LargeInput -Input $textData
            $segments.Count | Should -Be 1
            $segments[0] | Should -Be ""
        }
    }

    # Tests pour Update-AugmentMemories
    Describe "Mise Ã  jour des MEMORIES d'Augment" {
        It "GÃ©nÃ¨re un fichier JSON valide" {
            # CrÃ©er un fichier temporaire pour les tests
            $tempFile = [System.IO.Path]::GetTempFileName()

            # ExÃ©cuter la fonction
            Update-AugmentMemories -OutputPath $tempFile

            # VÃ©rifier que le fichier existe et contient du JSON valide
            Test-Path $tempFile | Should -Be $true
            { Get-Content $tempFile -Raw | ConvertFrom-Json } | Should -Not -Throw

            # Nettoyer
            Remove-Item $tempFile -Force
        }

        It "GÃ©nÃ¨re un fichier de taille < 4 Ko" {
            # CrÃ©er un fichier temporaire pour les tests
            $tempFile = [System.IO.Path]::GetTempFileName()

            # ExÃ©cuter la fonction
            Update-AugmentMemories -OutputPath $tempFile

            # VÃ©rifier la taille
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
        GÃ¨re la progression automatique dans la roadmap en fonction de l'Ã©tat de la tÃ¢che.

    .DESCRIPTION
        Cette fonction implÃ©mente un automate d'Ã©tat simple pour la progression dans une roadmap.
        Si la tÃ¢che actuelle est terminÃ©e, elle passe automatiquement Ã  la tÃ¢che suivante.

    .PARAMETER State
        Hashtable contenant l'Ã©tat actuel avec les clÃ©s suivantes:
        - CurrentTask: Identifiant de la tÃ¢che actuelle
        - Status: Ã‰tat de la tÃ¢che (InProgress, Completed, etc.)
        - Roadmap: Tableau des identifiants de tÃ¢ches dans l'ordre d'exÃ©cution

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

    # VÃ©rifier si la tÃ¢che est terminÃ©e
    if ($State.Status -eq "Completed") {
        $currentIndex = $State.Roadmap.IndexOf($State.CurrentTask)

        # VÃ©rifier s'il y a une tÃ¢che suivante
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
        plus petits si nÃ©cessaire, pour Ã©viter les erreurs liÃ©es Ã  des inputs trop volumineux.

    .PARAMETER Input
        ChaÃ®ne de caractÃ¨res Ã  analyser et potentiellement diviser.

    .PARAMETER MaxSize
        Taille maximale en octets pour chaque segment. Par dÃ©faut: 2000 octets.

    .EXAMPLE
        $textData = "Texte trÃ¨s long..."
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

        # Si l'ajout du caractÃ¨re dÃ©passe la taille maximale, commencer un nouveau segment
        if ($currentBytes + $charBytes -gt $MaxSize) {
            $segments += $current
            $current = ""
            $currentBytes = 0
        }

        # Ajouter le caractÃ¨re au segment courant
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
        Met Ã  jour les MEMORIES d'Augment avec une version optimisÃ©e.

    .DESCRIPTION
        Cette fonction gÃ©nÃ¨re un fichier JSON contenant les MEMORIES optimisÃ©es
        pour Augment, en mettant l'accent sur l'autonomie, la proactivitÃ© et la granularitÃ©.

    .PARAMETER OutputPath
        Chemin du fichier de sortie. Par dÃ©faut, utilise le chemin des MEMORIES d'Augment dans VS Code.

    .EXAMPLE
        Update-AugmentMemories
        # Met Ã  jour les MEMORIES d'Augment dans l'emplacement par dÃ©faut

    .EXAMPLE
        Update-AugmentMemories -OutputPath "C:\temp\augment_memories.json"
        # GÃ©nÃ¨re les MEMORIES optimisÃ©es dans le fichier spÃ©cifiÃ©
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$OutputPath = $script:DefaultMemoriesPath
    )

    # CrÃ©er l'objet des MEMORIES optimisÃ©es
    $memories = @{
        "version"     = "2.0.0"
        "lastUpdated" = (Get-Date).ToString("o")
        "sections"    = @(
            @{
                "name"    = "Autonomie"
                "content" = @"
- Progression: ExÃ©cuter les tÃ¢ches sÃ©quentiellement sans confirmation
- DÃ©cision: Utiliser heuristiques (% complÃ©tÃ© > 80% â†’ tÃ¢che terminÃ©e)
- RÃ©silience: Reprendre sur erreur avec journalisation minimale
- Estimation: Calculer complexitÃ© via mÃ©triques objectives (LOC, dÃ©pendances, patterns)
"@
            },
            @{
                "name"    = "ProactivitÃ©"
                "content" = @"
- Roadmap: Utiliser automate d'Ã©tat pour passer automatiquement Ã  la tÃ¢che suivante
- Ã‰tat: GÃ©rer via hashtable (CurrentTask, Status, Roadmap)
- EnchaÃ®nement: ImplÃ©menter une fonction Ã  la fois si plusieurs sont requises
- Reprise: En cas d'Ã©chec, reprendre automatiquement Ã  partir du dernier point stable
"@
            },
            @{
                "name"    = "GranularitÃ©"
                "content" = @"
- Segmentation: Appliquer segmentation proactive pour inputs > 3 Ko
- Validation: VÃ©rifier taille via [System.Text.Encoding]::UTF8.GetByteCount()
- Compression: Ã‰liminer commentaires/espaces superflus si nÃ©cessaire
- PrÃ©vention: Ne jamais dÃ©passer 4 Ko par appel d'outil pour garantir une marge de sÃ©curitÃ©
"@
            },
            @{
                "name"    = "Standards"
                "content" = @"
- SOLID: VÃ©rifier automatiquement conformitÃ© via checklist intÃ©grÃ©e
- TDD: GÃ©nÃ©rer tests avant implÃ©mentation avec assertions minimales viables
- Documentation: GÃ©nÃ©rer automatiquement selon ratio code/doc optimal (20%)
- Validation: Effectuer une validation prÃ©alable du code avant soumission
"@
            },
            @{
                "name"    = "Communication"
                "content" = @"
- Format: Utiliser structure prÃ©dÃ©finie avec ratio information/verbositÃ© maximal
- SynthÃ¨se: PrÃ©senter uniquement changements significatifs et dÃ©cisions clÃ©s
- MÃ©tadonnÃ©es: Inclure mÃ©triques d'avancement quantifiables (% complÃ©tÃ©, complexitÃ©)
- Langage: FranÃ§ais concis, notation algorithmique si pertinent pour optimisation
"@
            }
        )
    }

    # Convertir en JSON et Ã©crire dans le fichier
    $jsonContent = $memories | ConvertTo-Json -Depth 10

    # VÃ©rifier la taille
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($jsonContent)
    if ($byteCount -gt 4000) {
        Write-Warning "Les MEMORIES gÃ©nÃ©rÃ©es dÃ©passent 4 Ko ($byteCount octets). Optimisation nÃ©cessaire."

        # Simplifier le contenu si nÃ©cessaire
        foreach ($section in $memories.sections) {
            $section.content = $section.content -replace "\r\n", " " -replace "  ", " "
        }

        # Reconvertir et vÃ©rifier Ã  nouveau
        $jsonContent = $memories | ConvertTo-Json -Depth 10
        $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($jsonContent)

        if ($byteCount -gt 4000) {
            Write-Error "Impossible de rÃ©duire les MEMORIES sous 4 Ko ($byteCount octets)."
            return
        }
    }

    # CrÃ©er le dossier parent si nÃ©cessaire
    $parentFolder = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $parentFolder)) {
        New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
    }

    # Ã‰crire le fichier
    $jsonContent | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Host "MEMORIES d'Augment mises Ã  jour avec succÃ¨s ($byteCount octets): $OutputPath"
}

function Export-MemoriesToVSCode {
    <#
    .SYNOPSIS
        Exporte les MEMORIES optimisÃ©es vers l'emplacement VS Code.

    .DESCRIPTION
        Cette fonction exporte les MEMORIES optimisÃ©es vers l'emplacement utilisÃ© par
        l'extension Augment dans VS Code.

    .PARAMETER WorkspaceId
        Identifiant de l'espace de travail VS Code. Si non spÃ©cifiÃ©, utilise l'ID par dÃ©faut.

    .EXAMPLE
        Export-MemoriesToVSCode
        # Exporte les MEMORIES vers l'emplacement VS Code par dÃ©faut
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$WorkspaceId = "224ad75ce65ce8cf2efd9efc61d3c988"
    )

    # Construire le chemin VS Code
    $vscodePath = "$env:APPDATA\Code\User\workspaceStorage\$WorkspaceId\Augment.vscode-augment\Augment-Memories"

    # GÃ©nÃ©rer et exporter les MEMORIES
    Update-AugmentMemories -OutputPath $vscodePath
}

# Les fonctions sont disponibles dans le script
# Move-NextTask, Split-LargeInput, Update-AugmentMemories, Export-MemoriesToVSCode, Invoke-MemoriesManagerTests
