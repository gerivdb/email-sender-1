<#
.SYNOPSIS
    Module pour convertir une roadmap existante vers le nouveau format de template.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser une roadmap existante au format Markdown,
    extraire les informations pertinentes et gÃ©nÃ©rer une nouvelle roadmap selon le template spÃ©cifiÃ©.

.NOTES
    Auteur: Ã‰quipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

function Get-RoadmapStructure {
    <#
    .SYNOPSIS
        Analyse une roadmap existante et extrait sa structure.

    .DESCRIPTION
        Cette fonction lit un fichier Markdown contenant une roadmap, analyse sa structure
        et extrait les informations pertinentes (sections, sous-sections, tÃ¢ches, etc.).

    .PARAMETER Path
        Chemin vers le fichier Markdown de la roadmap.

    .EXAMPLE
        $roadmapStructure = Get-RoadmapStructure -Path "Roadmap/roadmap_complete.md"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        throw "Le fichier '$Path' n'existe pas."
    }

    # Lire le contenu du fichier avec l'encodage UTF8
    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    
    # Extraire le nom du projet (titre de niveau 1)
    $projectNameMatch = [regex]::Match($content, '# (.+)')
    $projectName = if ($projectNameMatch.Success) { $projectNameMatch.Groups[1].Value } else { "Projet inconnu" }
    
    # Structure de base pour la roadmap
    $roadmapStructure = @{
        project = $projectName
        sections = @()
    }
    
    # Extraire les sections principales (niveau 2)
    $sectionMatches = [regex]::Matches($content, '## (\d+)\. (.+?)(?=\r?\n)')
    
    foreach ($sectionMatch in $sectionMatches) {
        $sectionId = $sectionMatch.Groups[1].Value
        $sectionName = $sectionMatch.Groups[2].Value
        
        # Extraire la description et le responsable de la section
        $sectionText = $content.Substring($sectionMatch.Index)
        $nextSectionMatch = [regex]::Match($sectionText.Substring($sectionMatch.Length), '## \d+\.')
        if ($nextSectionMatch.Success) {
            $sectionText = $sectionText.Substring(0, $sectionMatch.Length + $nextSectionMatch.Index)
        }
        
        $sectionDescMatch = [regex]::Match($sectionText, '\*\*Description\*\*: (.+?)(?=\r?\n)')
        $sectionRespMatch = [regex]::Match($sectionText, '\*\*Responsable\*\*: (.+?)(?=\r?\n)')
        $sectionStatusMatch = [regex]::Match($sectionText, '\*\*Statut global\*\*: (.+?) - (\d+)%')
        
        $sectionDesc = if ($sectionDescMatch.Success) { $sectionDescMatch.Groups[1].Value } else { "Modules et fonctionnalitÃ©s de la section $sectionName." }
        $sectionResp = if ($sectionRespMatch.Success) { $sectionRespMatch.Groups[1].Value } else { "Ã‰quipe de dÃ©veloppement" }
        $sectionStatus = if ($sectionStatusMatch.Success) { $sectionStatusMatch.Groups[1].Value } else { "En cours" }
        $sectionProgress = if ($sectionStatusMatch.Success) { [int]$sectionStatusMatch.Groups[2].Value } else { 0 }
        
        $section = @{
            id = $sectionId
            name = $sectionName
            description = $sectionDesc
            responsible = $sectionResp
            status = $sectionStatus
            progress = $sectionProgress
            subsections = @()
        }
        
        # Extraire les sous-sections (niveau 3)
        # Essayer plusieurs patterns pour capturer diffÃ©rents formats
        $subsectionPatterns = @(
            "### $sectionId\.(\d+) (.+?)(?=\r?\n)",
            "### (\d+\.\d+) (.+?)(?=\r?\n)",
            "### (.+?)(?=\r?\n)"
        )
        
        $subsectionMatches = $null
        foreach ($pattern in $subsectionPatterns) {
            $subsectionMatches = [regex]::Matches($sectionText, $pattern)
            if ($subsectionMatches.Count -gt 0) {
                break
            }
        }
        
        foreach ($subsectionMatch in $subsectionMatches) {
            # Adapter l'extraction selon le pattern qui a fonctionnÃ©
            if ($pattern -eq "### $sectionId\.(\d+) (.+?)(?=\r?\n)") {
                $subsectionId = "$sectionId." + $subsectionMatch.Groups[1].Value
                $subsectionName = $subsectionMatch.Groups[2].Value
            }
            elseif ($pattern -eq "### (\d+\.\d+) (.+?)(?=\r?\n)") {
                $subsectionId = $subsectionMatch.Groups[1].Value
                $subsectionName = $subsectionMatch.Groups[2].Value
            }
            else {
                $subsectionId = "$sectionId.1" # Valeur par dÃ©faut
                $subsectionName = $subsectionMatch.Groups[1].Value
            }
            
            # Extraire le texte de la sous-section
            $subsectionText = $sectionText.Substring($subsectionMatch.Index)
            $nextSubsectionMatch = [regex]::Match($subsectionText.Substring($subsectionMatch.Length), "###")
            if ($nextSubsectionMatch.Success) {
                $subsectionText = $subsectionText.Substring(0, $subsectionMatch.Length + $nextSubsectionMatch.Index)
            }
            
            # Extraire les mÃ©tadonnÃ©es de la sous-section
            $subsectionComplexityMatch = [regex]::Match($subsectionText, '\*\*ComplexitÃ©\*\*: (.+?)(?=\r?\n)')
            $subsectionTimeMatch = [regex]::Match($subsectionText, '\*\*Temps estimÃ© total\*\*: (\d+) jours')
            $subsectionProgressMatch = [regex]::Match($subsectionText, '\*\*Progression globale\*\*: (\d+)%')
            $subsectionDependenciesMatch = [regex]::Match($subsectionText, '\*\*DÃ©pendances\*\*: (.+?)(?=\r?\n)')
            
            $subsectionComplexity = if ($subsectionComplexityMatch.Success) { $subsectionComplexityMatch.Groups[1].Value } else { "Moyenne" }
            $subsectionTime = if ($subsectionTimeMatch.Success) { [int]$subsectionTimeMatch.Groups[1].Value } else { 0 }
            $subsectionProgress = if ($subsectionProgressMatch.Success) { [int]$subsectionProgressMatch.Groups[1].Value } else { 0 }
            $subsectionDependencies = if ($subsectionDependenciesMatch.Success) { $subsectionDependenciesMatch.Groups[1].Value } else { "Aucune" }
            
            $subsection = @{
                id = $subsectionId
                name = $subsectionName
                complexity = $subsectionComplexity
                estimated_days = $subsectionTime
                progress = $subsectionProgress
                dependencies = $subsectionDependencies
                tasks = @()
            }
            
            # Extraire les tÃ¢ches (niveau 4)
            $taskPatterns = @(
                "#### $subsectionId\.(\d+) (.+?)(?=\r?\n)",
                "#### (\d+\.\d+\.\d+) (.+?)(?=\r?\n)",
                "#### (.+?)(?=\r?\n)"
            )
            
            $taskMatches = $null
            foreach ($taskPattern in $taskPatterns) {
                $taskMatches = [regex]::Matches($subsectionText, $taskPattern)
                if ($taskMatches.Count -gt 0) {
                    break
                }
            }
            
            foreach ($taskMatch in $taskMatches) {
                # Adapter l'extraction selon le pattern qui a fonctionnÃ©
                if ($taskPattern -eq "#### $subsectionId\.(\d+) (.+?)(?=\r?\n)") {
                    $taskId = "$subsectionId." + $taskMatch.Groups[1].Value
                    $taskName = $taskMatch.Groups[2].Value
                }
                elseif ($taskPattern -eq "#### (\d+\.\d+\.\d+) (.+?)(?=\r?\n)") {
                    $taskId = $taskMatch.Groups[1].Value
                    $taskName = $taskMatch.Groups[2].Value
                }
                else {
                    $taskId = "$subsectionId.1" # Valeur par dÃ©faut
                    $taskName = $taskMatch.Groups[1].Value
                }
                
                # Extraire le texte de la tÃ¢che
                $taskText = $subsectionText.Substring($taskMatch.Index)
                $nextTaskMatch = [regex]::Match($taskText.Substring($taskMatch.Length), "####")
                if ($nextTaskMatch.Success) {
                    $taskText = $taskText.Substring(0, $taskMatch.Length + $nextTaskMatch.Index)
                }
                
                # Extraire les mÃ©tadonnÃ©es de la tÃ¢che
                $taskComplexityMatch = [regex]::Match($taskText, '\*\*ComplexitÃ©\*\*: (.+?)(?=\r?\n)')
                $taskTimeMatch = [regex]::Match($taskText, '\*\*Temps estimÃ©\*\*: (\d+) jours')
                $taskProgressMatch = [regex]::Match($taskText, '\*\*Progression\*\*: (\d+)% - \*(.+?)\*')
                $taskStartMatch = [regex]::Match($taskText, '\*\*Date de dÃ©but prÃ©vue\*\*: (\d{2}/\d{2}/\d{4})')
                $taskEndMatch = [regex]::Match($taskText, '\*\*Date d''achÃ¨vement prÃ©vue\*\*: (\d{2}/\d{2}/\d{4})')
                
                $taskComplexity = if ($taskComplexityMatch.Success) { $taskComplexityMatch.Groups[1].Value } else { "Moyenne" }
                $taskTime = if ($taskTimeMatch.Success) { [int]$taskTimeMatch.Groups[1].Value } else { 0 }
                $taskProgress = if ($taskProgressMatch.Success) { [int]$taskProgressMatch.Groups[1].Value } else { 0 }
                $taskStatus = if ($taskProgressMatch.Success) { $taskProgressMatch.Groups[2].Value } else { "Non commencÃ©" }
                $taskStart = if ($taskStartMatch.Success) { $taskStartMatch.Groups[1].Value } else { "" }
                $taskEnd = if ($taskEndMatch.Success) { $taskEndMatch.Groups[1].Value } else { "" }
                
                $task = @{
                    id = $taskId
                    name = $taskName
                    complexity = $taskComplexity
                    estimated_days = $taskTime
                    progress = $taskProgress
                    status = $taskStatus
                    start_date = $taskStart
                    end_date = $taskEnd
                    subtasks = @()
                }
                
                # Extraire les sous-tÃ¢ches
                $subtaskPattern = "- \[([ x])\] \*\*Sous-tÃ¢che (\d+\.\d+)\*\*: (.+?) \((\d+)h\)"
                $subtaskMatches = [regex]::Matches($taskText, $subtaskPattern)
                
                foreach ($subtaskMatch in $subtaskMatches) {
                    $subtaskCompleted = $subtaskMatch.Groups[1].Value -eq "x"
                    $subtaskId = $subtaskMatch.Groups[2].Value
                    $subtaskName = $subtaskMatch.Groups[3].Value
                    $subtaskHours = [int]$subtaskMatch.Groups[4].Value
                    
                    $subtask = @{
                        id = $subtaskId
                        name = $subtaskName
                        estimated_hours = $subtaskHours
                        completed = $subtaskCompleted
                    }
                    
                    $task.subtasks += $subtask
                }
                
                $subsection.tasks += $task
            }
            
            $section.subsections += $subsection
        }
        
        $roadmapStructure.sections += $section
    }
    
    return $roadmapStructure
}

function Get-TemplateContent {
    <#
    .SYNOPSIS
        Extrait la structure du template de roadmap.

    .DESCRIPTION
        Cette fonction lit un fichier Markdown contenant un template de roadmap
        et extrait sa structure pour servir de base Ã  la gÃ©nÃ©ration de la nouvelle roadmap.

    .PARAMETER Path
        Chemin vers le fichier Markdown du template.

    .EXAMPLE
        $templateStructure = Get-TemplateContent -Path "Roadmap/roadmap_template.md"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        throw "Le fichier '$Path' n'existe pas."
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    
    # Extraire les sections d'exemple
    $sectionExample = [regex]::Match($content, '```markdown\r?\n(# Roadmap.+?)```', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if (-not $sectionExample.Success) {
        throw "Impossible de trouver l'exemple de section dans le template."
    }
    
    return $sectionExample.Groups[1].Value
}

function ConvertTo-NewRoadmap {
    <#
    .SYNOPSIS
        Transforme la structure de la roadmap selon le template.

    .DESCRIPTION
        Cette fonction prend la structure extraite de la roadmap existante et la transforme
        selon le format du template spÃ©cifiÃ©.

    .PARAMETER RoadmapStructure
        Structure de la roadmap existante (hashtable).

    .PARAMETER TemplateContent
        Contenu du template (string).

    .EXAMPLE
        $newRoadmap = ConvertTo-NewRoadmap -RoadmapStructure $roadmapStructure -TemplateContent $templateContent
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$RoadmapStructure,
        
        [Parameter(Mandatory = $true)]
        [string]$TemplateContent
    )
    
    # CrÃ©er la nouvelle roadmap
    $newRoadmap = "# Roadmap $($RoadmapStructure.project)`n`n"
    
    foreach ($section in $RoadmapStructure.sections) {
        $newRoadmap += "## $($section.id). $($section.name)`n"
        $newRoadmap += "**Description**: $($section.description)`n"
        $newRoadmap += "**Responsable**: $($section.responsible)`n"
        $newRoadmap += "**Statut global**: $($section.status) - $($section.progress)%`n`n"
        
        foreach ($subsection in $section.subsections) {
            $newRoadmap += "### $($subsection.id) $($subsection.name)`n"
            $newRoadmap += "**ComplexitÃ©**: $($subsection.complexity)`n"
            $newRoadmap += "**Temps estimÃ© total**: $($subsection.estimated_days) jours`n"
            $newRoadmap += "**Progression globale**: $($subsection.progress)%`n"
            $newRoadmap += "**DÃ©pendances**: $($subsection.dependencies)`n`n"
            
            # Ajouter les sections standard du template
            $newRoadmap += "#### Outils et technologies`n"
            $newRoadmap += "- **Langages**: PowerShell 5.1/7, Python 3.11+`n"
            $newRoadmap += "- **Frameworks**: Pester, pytest`n"
            $newRoadmap += "- **Outils IA**: MCP, Augment`n"
            $newRoadmap += "- **Outils d'analyse**: PSScriptAnalyzer, pylint`n"
            $newRoadmap += "- **Environnement**: VS Code avec extensions PowerShell et Python`n`n"
            
            $newRoadmap += "#### Fichiers principaux`n"
            $newRoadmap += "| Chemin | Description |`n"
            $newRoadmap += "|--------|-------------|`n"
            $newRoadmap += "| `modules/$($subsection.id)/$($subsection.name -replace ' ', '').psm1` | Module principal |`n"
            $newRoadmap += "| `tests/unit/$($subsection.name -replace ' ', '').Tests.ps1` | Tests unitaires |`n`n"
            
            $newRoadmap += "#### Guidelines`n"
            $newRoadmap += "- **Codage**: Suivre les conventions PowerShell (PascalCase pour fonctions, verbes approuvÃ©s)`n"
            $newRoadmap += "- **Tests**: Appliquer TDD avec Pester, viser 100% de couverture`n"
            $newRoadmap += "- **Documentation**: Utiliser le format d'aide PowerShell et XML pour la documentation`n"
            $newRoadmap += "- **SÃ©curitÃ©**: Valider tous les inputs, Ã©viter l'utilisation d'Invoke-Expression`n"
            $newRoadmap += "- **Performance**: Optimiser pour les grands volumes de donnÃ©es`n`n"
            
            foreach ($task in $subsection.tasks) {
                $newRoadmap += "#### $($task.id) $($task.name)`n"
                $newRoadmap += "**ComplexitÃ©**: $($task.complexity)`n"
                $newRoadmap += "**Temps estimÃ©**: $($task.estimated_days) jours`n"
                $newRoadmap += "**Progression**: $($task.progress)% - *$($task.status)*`n"
                
                if ($task.start_date) {
                    $newRoadmap += "**Date de dÃ©but prÃ©vue**: $($task.start_date)`n"
                    $newRoadmap += "**Date d'achÃ¨vement prÃ©vue**: $($task.end_date)`n"
                }
                
                $newRoadmap += "**Responsable**: Ã‰quipe de dÃ©veloppement`n"
                $newRoadmap += "**Tags**: #dÃ©veloppement #qualitÃ© #performance`n`n"
                
                $newRoadmap += "##### Fichiers Ã  crÃ©er/modifier`n"
                $newRoadmap += "| Chemin | Description | Statut |`n"
                $newRoadmap += "|--------|-------------|--------|`n"
                $newRoadmap += "| `modules/$($subsection.id)/$($task.name -replace ' ', '').ps1` | Module principal | Ã€ crÃ©er |`n"
                $newRoadmap += "| `tests/unit/$($task.name -replace ' ', '').Tests.ps1` | Tests unitaires | Ã€ crÃ©er |`n`n"
                
                $newRoadmap += "##### Format de journalisation`n"
                $newRoadmap += '```json`n'
                $newRoadmap += '{`n'
                $newRoadmap += '  "module": "' + ($task.name -replace ' ', '') + '",`n'
                $newRoadmap += '  "version": "1.0.0",`n'
                $newRoadmap += '  "date": "' + (Get-Date -Format 'yyyy-MM-dd') + '",`n'
                $newRoadmap += '  "changes": [`n'
                $newRoadmap += '    {"feature": "ImplÃ©mentation", "status": "' + $task.status + '"}`n'
                $newRoadmap += '  ]`n'
                $newRoadmap += '}`n'
                $newRoadmap += '```' + "`n`n"
                
                # Ajouter les sous-tÃ¢ches regroupÃ©es par jour
                if ($task.subtasks.Count -gt 0) {
                    $dayGroups = $task.subtasks | Group-Object -Property { [int]($_.id -split '\.')[0] }
                    
                    foreach ($dayGroup in $dayGroups) {
                        $dayNumber = $dayGroup.Name
                        $totalHours = ($dayGroup.Group | Measure-Object -Property estimated_hours -Sum).Sum
                        
                        $newRoadmap += "##### Jour $dayNumber - DÃ©veloppement et tests ($totalHours`h)`n"
                        
                        foreach ($subtask in $dayGroup.Group) {
                            $checkBox = if ($subtask.completed) { "[x]" } else { "[ ]" }
                            $newRoadmap += "- $checkBox **Sous-tÃ¢che $($subtask.id)**: $($subtask.name) ($($subtask.estimated_hours)h)`n"
                            $newRoadmap += "  - **Description**: DÃ©velopper la fonctionnalitÃ© $($subtask.name)`n"
                            $newRoadmap += "  - **Livrable**: FonctionnalitÃ© implÃ©mentÃ©e et testÃ©e`n"
                            $newRoadmap += "  - **Fichier**: `modules/$($subsection.id)/$($task.name -replace ' ', '').ps1``n"
                            $newRoadmap += "  - **Outils**: VS Code, PowerShell`n"
                            $newRoadmap += "  - **Statut**: " + (if ($subtask.completed) { "TerminÃ©" } else { "Non commencÃ©" }) + "`n`n"
                        }
                    }
                }
            }
        }
    }
    
    return $newRoadmap
}

function Out-RoadmapFile {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re une nouvelle roadmap Ã  partir du contenu transformÃ©.

    .DESCRIPTION
        Cette fonction enregistre le contenu de la nouvelle roadmap dans un fichier.

    .PARAMETER Content
        Contenu de la nouvelle roadmap.

    .PARAMETER Path
        Chemin oÃ¹ la nouvelle roadmap sera enregistrÃ©e.

    .EXAMPLE
        Out-RoadmapFile -Content $newRoadmap -Path "Roadmap/roadmap_complete_new.md"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    # Enregistrer le contenu dans le fichier de sortie avec l'encodage UTF8
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBomEncoding)
    
    Write-Host "Nouvelle roadmap gÃ©nÃ©rÃ©e avec succÃ¨s: $Path"
}

# Exporter les fonctions
Export-ModuleMember -Function Get-RoadmapStructure, Get-TemplateContent, ConvertTo-NewRoadmap, Out-RoadmapFile
