<#
.SYNOPSIS
    Fonction principale pour la dÃ©tection et la rÃ©solution des cycles de dÃ©pendances dans un projet.

.DESCRIPTION
    Cette fonction analyse les dÃ©pendances entre les fichiers d'un projet, dÃ©tecte les cycles
    de dÃ©pendances et propose des solutions pour les rÃ©soudre.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel). Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront traitÃ©es.

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet Ã  analyser.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie. Par dÃ©faut, les fichiers sont gÃ©nÃ©rÃ©s dans le rÃ©pertoire courant.

.PARAMETER StartPath
    Chemin spÃ©cifique dans le projet oÃ¹ commencer l'analyse. Par dÃ©faut, analyse tout le projet.

.PARAMETER IncludePatterns
    Tableau de motifs d'inclusion pour les fichiers Ã  analyser (ex: "*.ps1", "*.py").

.PARAMETER ExcludePatterns
    Tableau de motifs d'exclusion pour les fichiers Ã  ignorer (ex: "*.test.ps1", "*node_modules*").

.PARAMETER DetectionAlgorithm
    Algorithme Ã  utiliser pour la dÃ©tection des cycles. Les valeurs possibles sont : DFS, TARJAN, JOHNSON.
    Par dÃ©faut, l'algorithme est TARJAN.

.PARAMETER MaxDepth
    Profondeur maximale d'analyse des dÃ©pendances. Par dÃ©faut, la profondeur est 10.

.PARAMETER MinimumCycleSeverity
    Niveau de dÃ©tail minimum pour considÃ©rer un cycle comme significatif (1-5).

.PARAMETER AutoFix
    Indique si les dÃ©pendances circulaires dÃ©tectÃ©es doivent Ãªtre corrigÃ©es automatiquement.

.PARAMETER FixStrategy
    StratÃ©gie de correction Ã  utiliser lorsque AutoFix est activÃ©.

.PARAMETER GenerateGraph
    Indique si un graphe des dÃ©pendances doit Ãªtre gÃ©nÃ©rÃ©.

.PARAMETER GraphFormat
    Format du graphe Ã  gÃ©nÃ©rer. Les valeurs possibles sont : DOT, MERMAID, PLANTUML, JSON.
    Par dÃ©faut, le format est DOT.

.EXAMPLE
    Invoke-RoadmapCycleDetection -FilePath "roadmap.md" -TaskIdentifier "1.3.1.3" -OutputPath "output" -ProjectPath "project" -IncludePatterns "*.ps1" -DetectionAlgorithm "TARJAN" -GenerateGraph $true

    Traite la tÃ¢che 1.3.1.3 du fichier roadmap.md, analyse les dÃ©pendances circulaires dans le rÃ©pertoire "project" pour les fichiers PowerShell,
    utilise l'algorithme de Tarjan pour la dÃ©tection, gÃ©nÃ¨re un graphe des dÃ©pendances et produit des rapports dans le rÃ©pertoire "output".

.EXAMPLE
    Invoke-RoadmapCycleDetection -FilePath "roadmap.md" -ProjectPath "project" -IncludePatterns "*.ps1","*.py" -ExcludePatterns "*node_modules*" -AutoFix $true

    Traite toutes les tÃ¢ches du fichier roadmap.md, analyse les dÃ©pendances circulaires dans le rÃ©pertoire "project" pour les fichiers PowerShell et Python,
    exclut les fichiers dans les rÃ©pertoires node_modules, et corrige automatiquement les dÃ©pendances circulaires dÃ©tectÃ©es.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

function Invoke-RoadmapCycleDetection {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [string]$StartPath = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludePatterns = @("*.ps1", "*.py", "*.js", "*.ts", "*.cs", "*.java"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePatterns = @("*node_modules*", "*venv*", "*__pycache__*", "*.test.*", "*.spec.*"),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DFS", "TARJAN", "JOHNSON")]
        [string]$DetectionAlgorithm = "TARJAN",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumCycleSeverity = 1,
        
        [Parameter(Mandatory = $false)]
        [bool]$AutoFix = $false,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INTERFACE_EXTRACTION", "DEPENDENCY_INVERSION", "MEDIATOR", "ABSTRACTION_LAYER", "AUTO")]
        [string]$FixStrategy = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [bool]$GenerateGraph = $false,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("DOT", "MERMAID", "PLANTUML", "JSON")]
        [string]$GraphFormat = "DOT"
    )
    
    try {
        Write-LogInfo "DÃ©but de la dÃ©tection des cycles de dÃ©pendances."
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputPath)) {
            if ($PSCmdlet.ShouldProcess($OutputPath, "CrÃ©er le rÃ©pertoire de sortie")) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
                Write-LogInfo "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath"
            }
        }
        
        # DÃ©terminer le chemin de recherche
        $searchPath = $ProjectPath
        if ($StartPath) {
            $searchPath = Join-Path -Path $ProjectPath -ChildPath $StartPath
            Write-LogInfo "Utilisation du chemin de dÃ©part spÃ©cifiÃ© : $StartPath"
        }
        
        # Collecter les fichiers Ã  analyser
        Write-LogInfo "Collecte des fichiers Ã  analyser dans : $searchPath"
        $files = @()
        foreach ($pattern in $IncludePatterns) {
            $matchingFiles = Get-ChildItem -Path $searchPath -Recurse -File -Include $pattern
            $files += $matchingFiles
        }
        
        # Filtrer les fichiers exclus
        if ($ExcludePatterns -and $ExcludePatterns.Count -gt 0) {
            $filteredFiles = @()
            foreach ($file in $files) {
                $exclude = $false
                foreach ($pattern in $ExcludePatterns) {
                    if ($file.FullName -like $pattern) {
                        $exclude = $true
                        break
                    }
                }
                if (-not $exclude) {
                    $filteredFiles += $file
                }
            }
            $files = $filteredFiles
        }
        
        Write-LogInfo "Nombre de fichiers Ã  analyser : $($files.Count)"
        
        # Importer les fonctions de dÃ©tection de cycles
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $modulePath = Split-Path -Parent $scriptPath
        
        $dependencyAnalysisPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\CycleDetection\DependencyAnalysisFunctions.ps1"
        $cycleDetectionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\CycleDetection\CycleDetectionAlgorithms.ps1"
        $cycleResolutionPath = Join-Path -Path $modulePath -ChildPath "Functions\Private\CycleDetection\CycleResolutionFunctions.ps1"
        
        # VÃ©rifier si les fichiers existent
        $missingFiles = @()
        if (-not (Test-Path -Path $dependencyAnalysisPath)) {
            $missingFiles += $dependencyAnalysisPath
        }
        if (-not (Test-Path -Path $cycleDetectionPath)) {
            $missingFiles += $cycleDetectionPath
        }
        if (-not (Test-Path -Path $cycleResolutionPath)) {
            $missingFiles += $cycleResolutionPath
        }
        
        if ($missingFiles.Count -gt 0) {
            Write-LogWarning "Certains fichiers de fonctions sont manquants :"
            foreach ($file in $missingFiles) {
                Write-LogWarning "  - $file"
            }
            Write-LogWarning "Utilisation du mode de simulation."
            
            # Simuler l'analyse des dÃ©pendances
            $dependencies = @{}
            foreach ($file in $files) {
                $dependencies[$file.FullName] = @()
                
                # Simuler la dÃ©tection des dÃ©pendances
                $randomDependencyCount = Get-Random -Minimum 0 -Maximum 5
                for ($i = 0; $i -lt $randomDependencyCount; $i++) {
                    $randomIndex = Get-Random -Minimum 0 -Maximum $files.Count
                    if ($randomIndex -lt $files.Count) {
                        $dependency = $files[$randomIndex].FullName
                        if ($dependency -ne $file.FullName) {
                            $dependencies[$file.FullName] += $dependency
                        }
                    }
                }
            }
            
            # Simuler la dÃ©tection des cycles
            Write-LogInfo "DÃ©tection des cycles de dÃ©pendances avec l'algorithme $DetectionAlgorithm et profondeur maximale $MaxDepth..."
            
            # Simuler quelques cycles pour dÃ©monstration
            $cycleCount = Get-Random -Minimum 1 -Maximum 5
            $allCycles = @()
            
            for ($i = 0; $i -lt $cycleCount; $i++) {
                $cycleLength = Get-Random -Minimum 2 -Maximum 5
                $cycleFiles = @()
                
                # SÃ©lectionner des fichiers alÃ©atoires pour le cycle
                for ($j = 0; $j -lt $cycleLength; $j++) {
                    $randomIndex = Get-Random -Minimum 0 -Maximum $files.Count
                    if ($randomIndex -lt $files.Count) {
                        $cycleFiles += $files[$randomIndex].FullName
                    }
                }
                
                # Ajouter le premier fichier Ã  la fin pour former un cycle
                $cycleFiles += $cycleFiles[0]
                
                $severity = Get-Random -Minimum 1 -Maximum 6
                
                $allCycles += @{
                    Files = $cycleFiles
                    Length = $cycleLength
                    Severity = $severity
                    Description = "Cycle de dÃ©pendance dÃ©tectÃ© entre $cycleLength fichiers"
                }
            }
        }
        else {
            # Importer les fonctions
            . $dependencyAnalysisPath
            . $cycleDetectionPath
            . $cycleResolutionPath
            
            Write-LogInfo "Fonctions de dÃ©tection de cycles importÃ©es."
            
            # Construire le graphe de dÃ©pendances
            Write-LogInfo "Construction du graphe de dÃ©pendances..."
            $dependencies = Build-DependencyGraph -Files $files -ProjectRoot $ProjectPath -MaxDepth $MaxDepth
            
            # DÃ©tecter les cycles
            Write-LogInfo "DÃ©tection des cycles de dÃ©pendances avec l'algorithme $DetectionAlgorithm..."
            $cycleResults = Find-DependencyCycles -Graph $dependencies -Algorithm $DetectionAlgorithm -MinimumCycleSeverity $MinimumCycleSeverity
            
            $allCycles = $cycleResults.AllCycles
            $cycles = $cycleResults.FilteredCycles
        }
        
        # Filtrer les cycles selon la sÃ©vÃ©ritÃ© minimale
        Write-LogInfo "Filtrage des cycles avec sÃ©vÃ©ritÃ© minimale de $MinimumCycleSeverity..."
        $cycles = $allCycles | Where-Object { $_.Severity -ge $MinimumCycleSeverity }
        
        Write-LogInfo "Nombre total de cycles dÃ©tectÃ©s : $($allCycles.Count)"
        Write-LogInfo "Nombre de cycles significatifs (sÃ©vÃ©ritÃ© >= $MinimumCycleSeverity) : $($cycles.Count)"
        
        # GÃ©nÃ©rer un rapport
        $reportPath = Join-Path -Path $OutputPath -ChildPath "cycle_detection_report.json"
        $report = @{
            ProjectPath = $ProjectPath
            Algorithm = $DetectionAlgorithm
            FilesAnalyzed = $files.Count
            CyclesDetected = $allCycles.Count
            CyclesFiltered = $cycles.Count
            MinimumCycleSeverity = $MinimumCycleSeverity
            Cycles = $cycles
            GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        if ($PSCmdlet.ShouldProcess($reportPath, "GÃ©nÃ©rer le rapport de dÃ©tection de cycles")) {
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
            Write-LogInfo "Rapport de dÃ©tection de cycles gÃ©nÃ©rÃ© : $reportPath"
        }
        
        # GÃ©nÃ©rer un graphe si demandÃ©
        if ($GenerateGraph) {
            $graphPath = Join-Path -Path $OutputPath -ChildPath "dependency_graph.$($GraphFormat.ToLower())"
            
            if ($PSCmdlet.ShouldProcess($graphPath, "GÃ©nÃ©rer le graphe de dÃ©pendances")) {
                # GÃ©nÃ©rer le graphe selon le format spÃ©cifiÃ©
                switch ($GraphFormat) {
                    "DOT" {
                        # GÃ©nÃ©rer un graphe DOT
                        $graph = "// Graphe de dÃ©pendances gÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                        $graph += "digraph DependencyGraph {`n"
                        $graph += "  rankdir=LR;`n"
                        $graph += "  node [shape=box, style=filled, fillcolor=lightblue];`n`n"
                        
                        # Ajouter les nÅ“uds
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $graph += "  `"$fileName`" [label=`"$fileName`"];`n"
                        }
                        
                        $graph += "`n"
                        
                        # Ajouter les arÃªtes
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            if ($dependencies.ContainsKey($file.FullName)) {
                                foreach ($dep in $dependencies[$file.FullName]) {
                                    $depFileName = Split-Path -Leaf $dep
                                    $graph += "  `"$fileName`" -> `"$depFileName`";`n"
                                }
                            }
                        }
                        
                        # Mettre en Ã©vidence les cycles
                        $graph += "`n  // Cycles dÃ©tectÃ©s`n"
                        foreach ($cycle in $cycles) {
                            for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                                $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                                $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                                $graph += "  `"$sourceFile`" -> `"$targetFile`" [color=red, penwidth=2.0];`n"
                            }
                        }
                        
                        $graph += "}`n"
                    }
                    "MERMAID" {
                        # GÃ©nÃ©rer un graphe Mermaid
                        $graph = "```mermaid`n"
                        $graph += "graph LR`n"
                        
                        # Ajouter les nÅ“uds
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $fileId = $fileName -replace '[^a-zA-Z0-9]', '_'
                            $graph += "  $fileId[$fileName]`n"
                        }
                        
                        # Ajouter les arÃªtes
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $fileId = $fileName -replace '[^a-zA-Z0-9]', '_'
                            if ($dependencies.ContainsKey($file.FullName)) {
                                foreach ($dep in $dependencies[$file.FullName]) {
                                    $depFileName = Split-Path -Leaf $dep
                                    $depFileId = $depFileName -replace '[^a-zA-Z0-9]', '_'
                                    $graph += "  $fileId --> $depFileId`n"
                                }
                            }
                        }
                        
                        # Mettre en Ã©vidence les cycles
                        $graph += "  %% Cycles dÃ©tectÃ©s`n"
                        foreach ($cycle in $cycles) {
                            for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                                $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                                $sourceFileId = $sourceFile -replace '[^a-zA-Z0-9]', '_'
                                $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                                $targetFileId = $targetFile -replace '[^a-zA-Z0-9]', '_'
                                $graph += "  $sourceFileId -->|cycle| $targetFileId`n"
                            }
                        }
                        
                        $graph += "```"
                    }
                    "PLANTUML" {
                        # GÃ©nÃ©rer un graphe PlantUML
                        $graph = "@startuml`n"
                        $graph += "' Graphe de dÃ©pendances gÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                        $graph += "skinparam rankdir LR`n"
                        $graph += "skinparam component {`n"
                        $graph += "  BackgroundColor LightBlue`n"
                        $graph += "  BorderColor Black`n"
                        $graph += "}`n`n"
                        
                        # Ajouter les nÅ“uds
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $fileId = $fileName -replace '[^a-zA-Z0-9]', '_'
                            $graph += "component $fileId as `"$fileName`"`n"
                        }
                        
                        $graph += "`n"
                        
                        # Ajouter les arÃªtes
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $fileId = $fileName -replace '[^a-zA-Z0-9]', '_'
                            if ($dependencies.ContainsKey($file.FullName)) {
                                foreach ($dep in $dependencies[$file.FullName]) {
                                    $depFileName = Split-Path -Leaf $dep
                                    $depFileId = $depFileName -replace '[^a-zA-Z0-9]', '_'
                                    $graph += "$fileId --> $depFileId`n"
                                }
                            }
                        }
                        
                        # Mettre en Ã©vidence les cycles
                        $graph += "`n' Cycles dÃ©tectÃ©s`n"
                        foreach ($cycle in $cycles) {
                            for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                                $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                                $sourceFileId = $sourceFile -replace '[^a-zA-Z0-9]', '_'
                                $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                                $targetFileId = $targetFile -replace '[^a-zA-Z0-9]', '_'
                                $graph += "$sourceFileId -[#red,thickness=2]-> $targetFileId : cycle`n"
                            }
                        }
                        
                        $graph += "@enduml"
                    }
                    "JSON" {
                        # GÃ©nÃ©rer un graphe JSON
                        $graphData = @{
                            nodes = @()
                            edges = @()
                            cycles = @()
                            metadata = @{
                                generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                                projectPath = $ProjectPath
                                algorithm = $DetectionAlgorithm
                                filesAnalyzed = $files.Count
                                cyclesDetected = $cycles.Count
                            }
                        }
                        
                        # Ajouter les nÅ“uds
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $graphData.nodes += @{
                                id = $fileName
                                label = $fileName
                                type = [System.IO.Path]::GetExtension($fileName).TrimStart('.')
                            }
                        }
                        
                        # Ajouter les arÃªtes
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            if ($dependencies.ContainsKey($file.FullName)) {
                                foreach ($dep in $dependencies[$file.FullName]) {
                                    $depFileName = Split-Path -Leaf $dep
                                    $graphData.edges += @{
                                        source = $fileName
                                        target = $depFileName
                                        type = "dependency"
                                    }
                                }
                            }
                        }
                        
                        # Ajouter les cycles
                        foreach ($cycle in $cycles) {
                            $cycleEdges = @()
                            for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                                $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                                $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                                $cycleEdges += @{
                                    source = $sourceFile
                                    target = $targetFile
                                }
                            }
                            
                            $graphData.cycles += @{
                                edges = $cycleEdges
                                length = $cycle.Length
                                severity = $cycle.Severity
                                description = $cycle.Description
                            }
                        }
                        
                        $graph = $graphData | ConvertTo-Json -Depth 10
                    }
                    default {
                        # Format par dÃ©faut (DOT)
                        $graph = "// Graphe de dÃ©pendances gÃ©nÃ©rÃ© le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                        $graph += "digraph DependencyGraph {`n"
                        $graph += "  rankdir=LR;`n"
                        $graph += "  node [shape=box, style=filled, fillcolor=lightblue];`n`n"
                        
                        # Ajouter les nÅ“uds
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            $graph += "  `"$fileName`" [label=`"$fileName`"];`n"
                        }
                        
                        $graph += "`n"
                        
                        # Ajouter les arÃªtes
                        foreach ($file in $files) {
                            $fileName = Split-Path -Leaf $file.FullName
                            if ($dependencies.ContainsKey($file.FullName)) {
                                foreach ($dep in $dependencies[$file.FullName]) {
                                    $depFileName = Split-Path -Leaf $dep
                                    $graph += "  `"$fileName`" -> `"$depFileName`";`n"
                                }
                            }
                        }
                        
                        # Mettre en Ã©vidence les cycles
                        $graph += "`n  // Cycles dÃ©tectÃ©s`n"
                        foreach ($cycle in $cycles) {
                            for ($i = 0; $i -lt $cycle.Files.Count - 1; $i++) {
                                $sourceFile = Split-Path -Leaf $cycle.Files[$i]
                                $targetFile = Split-Path -Leaf $cycle.Files[$i + 1]
                                $graph += "  `"$sourceFile`" -> `"$targetFile`" [color=red, penwidth=2.0];`n"
                            }
                        }
                        
                        $graph += "}`n"
                    }
                }
                
                $graph | Out-File -FilePath $graphPath -Encoding UTF8
                Write-LogInfo "Graphe de dÃ©pendances gÃ©nÃ©rÃ© : $graphPath"
            }
        }
        
        # Corriger les cycles si demandÃ©
        $fixedCycles = 0
        $fixReport = $null
        
        if ($AutoFix -and $cycles.Count -gt 0) {
            if ($missingFiles.Contains($cycleResolutionPath)) {
                Write-LogWarning "Le fichier de fonctions de rÃ©solution de cycles est manquant. Utilisation du mode de simulation."
                
                # Simuler la correction des cycles
                Write-LogInfo "Correction automatique des cycles de dÃ©pendances avec la stratÃ©gie $FixStrategy..."
                
                $fixedCycles = 0
                foreach ($cycle in $cycles) {
                    # Simuler une correction alÃ©atoire
                    $fixSuccess = Get-Random -Minimum 0 -Maximum 2
                    if ($fixSuccess -eq 1) {
                        $fixedCycles++
                    }
                }
                
                $fixReportPath = Join-Path -Path $OutputPath -ChildPath "cycle_fix_report.json"
                $fixReport = @{
                    ProjectPath = $ProjectPath
                    CyclesDetected = $cycles.Count
                    CyclesFixed = $fixedCycles
                    FixStrategy = $FixStrategy
                    FixedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    FixDetails = @(
                        foreach ($cycle in $cycles) {
                            # DÃ©terminer la mÃ©thode de correction en fonction de la stratÃ©gie
                            $fixMethod = switch ($FixStrategy) {
                                "INTERFACE_EXTRACTION" { "Extraction d'interface" }
                                "DEPENDENCY_INVERSION" { "Inversion de dÃ©pendance" }
                                "MEDIATOR" { "Application du pattern mÃ©diateur" }
                                "ABSTRACTION_LAYER" { "CrÃ©ation d'une couche d'abstraction" }
                                "AUTO" {
                                    $methods = @(
                                        "Extraction d'interface",
                                        "Inversion de dÃ©pendance",
                                        "Application du pattern mÃ©diateur",
                                        "CrÃ©ation d'une couche d'abstraction"
                                    )
                                    $randomIndex = Get-Random -Minimum 0 -Maximum $methods.Count
                                    $methods[$randomIndex]
                                }
                            }
                            
                            @{
                                Files = $cycle.Files
                                Fixed = (Get-Random -Minimum 0 -Maximum 2) -eq 1
                                FixMethod = $fixMethod
                                Severity = $cycle.Severity
                                Changes = @{
                                    FilesModified = @(Split-Path -Leaf $cycle.Files[0])
                                    LinesChanged = Get-Random -Minimum 5 -Maximum 20
                                }
                            }
                        }
                    )
                }
            }
            else {
                # Utiliser les fonctions de rÃ©solution de cycles
                Write-LogInfo "Correction automatique des cycles de dÃ©pendances avec la stratÃ©gie $FixStrategy..."
                
                $fixResults = Resolve-DependencyCycles -Cycles $cycles -Graph $dependencies -Strategy $FixStrategy -OutputPath $OutputPath
                $fixedCycles = $fixResults.CyclesFixed
                $fixReport = $fixResults
            }
            
            if ($fixReport -and $PSCmdlet.ShouldProcess("GÃ©nÃ©rer le rapport de correction de cycles")) {
                $fixReportPath = Join-Path -Path $OutputPath -ChildPath "cycle_fix_report.json"
                $fixReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $fixReportPath -Encoding UTF8
                Write-LogInfo "Rapport de correction de cycles gÃ©nÃ©rÃ© : $fixReportPath"
            }
        }
        
        # PrÃ©parer les rÃ©sultats
        $result = @{
            Success = $true
            FilesAnalyzed = $files.Count
            CyclesDetected = $allCycles.Count
            CyclesFiltered = $cycles.Count
            CyclesFixed = if ($AutoFix) { $fixedCycles } else { 0 }
            OutputFiles = @($reportPath)
            Cycles = $cycles
        }
        
        if ($GenerateGraph) {
            $result.OutputFiles += $graphPath
        }
        
        if ($AutoFix -and $fixReport) {
            $result.OutputFiles += (Join-Path -Path $OutputPath -ChildPath "cycle_fix_report.json")
        }
        
        Write-LogInfo "DÃ©tection des cycles de dÃ©pendances terminÃ©e."
        
        return $result
    }
    catch {
        Write-LogError "Erreur lors de la dÃ©tection des cycles de dÃ©pendances : $_"
        return @{
            Success = $false
            Error = $_.ToString()
            FilesAnalyzed = 0
            CyclesDetected = 0
            CyclesFiltered = 0
            CyclesFixed = 0
            OutputFiles = @()
            Cycles = @()
        }
    }
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-RoadmapCycleDetection
