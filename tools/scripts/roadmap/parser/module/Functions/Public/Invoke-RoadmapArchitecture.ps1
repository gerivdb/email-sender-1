<#
.SYNOPSIS
    Fonction principale du mode ARCHI qui permet de concevoir l'architecture d'un projet.

.DESCRIPTION
    Cette fonction analyse un projet et gÃ©nÃ¨re des diagrammes d'architecture
    en fonction des tÃ¢ches spÃ©cifiÃ©es dans un fichier de roadmap.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  traiter.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (optionnel). Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront traitÃ©es.

.PARAMETER ProjectPath
    Chemin vers le rÃ©pertoire du projet Ã  analyser.

.PARAMETER OutputPath
    Chemin oÃ¹ seront gÃ©nÃ©rÃ©s les fichiers de sortie.

.PARAMETER DiagramType
    Type de diagramme Ã  gÃ©nÃ©rer. Les valeurs possibles sont : C4, UML, Mermaid.

.PARAMETER IncludeComponents
    Indique si les composants doivent Ãªtre inclus dans les diagrammes.

.PARAMETER IncludeInterfaces
    Indique si les interfaces doivent Ãªtre incluses dans les diagrammes.

.PARAMETER IncludeDependencies
    Indique si les dÃ©pendances doivent Ãªtre incluses dans les diagrammes.

.PARAMETER DependencyGraph
    Chemin vers un fichier de graphe de dÃ©pendances existant Ã  utiliser.

.EXAMPLE
    Invoke-RoadmapArchitecture -FilePath "roadmap.md" -TaskIdentifier "1.1" -ProjectPath "project" -OutputPath "output" -DiagramType "C4"

.OUTPUTS
    System.Collections.Hashtable
#>
function Invoke-RoadmapArchitecture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("C4", "UML", "Mermaid")]
        [string]$DiagramType = "C4",
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeComponents = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeInterfaces = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeDependencies = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$DependencyGraph
    )
    
    # Initialiser les rÃ©sultats
    $result = @{
        Success = $false
        DiagramCount = 0
        ComponentCount = 0
        InterfaceCount = 0
        DependencyCount = 0
        OutputFiles = @()
    }
    
    # Extraire les tÃ¢ches de la roadmap
    $tasks = Get-RoadmapTasks -FilePath $FilePath -TaskIdentifier $TaskIdentifier
    
    if ($tasks.Count -eq 0) {
        Write-LogWarning "Aucune tÃ¢che trouvÃ©e dans le fichier de roadmap pour l'identifiant : $TaskIdentifier"
        return $result
    }
    
    Write-LogInfo "Nombre de tÃ¢ches trouvÃ©es : $($tasks.Count)"
    
    # Analyser le projet
    Write-LogInfo "Analyse du projet : $ProjectPath"
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        Write-LogInfo "RÃ©pertoire de sortie crÃ©Ã© : $OutputPath"
    }
    
    # Analyser les fichiers du projet
    $files = Get-ChildItem -Path $ProjectPath -Recurse -File | Where-Object { $_.Extension -in ".ps1", ".psm1", ".psd1", ".py", ".js", ".ts", ".cs", ".java", ".cpp", ".h", ".hpp" }
    
    Write-LogInfo "Nombre de fichiers trouvÃ©s : $($files.Count)"
    
    # Analyser les composants
    $components = @()
    $interfaces = @()
    $dependencies = @()
    
    foreach ($file in $files) {
        Write-LogVerbose "Analyse du fichier : $($file.FullName)"
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw
        
        # Analyser le contenu en fonction du type de fichier
        switch ($file.Extension) {
            ".ps1" {
                # Analyser les fonctions PowerShell
                $functionMatches = [regex]::Matches($content, 'function\s+([A-Za-z0-9_-]+)\s*{')
                foreach ($match in $functionMatches) {
                    $functionName = $match.Groups[1].Value
                    $components += @{
                        Name = $functionName
                        Type = "Function"
                        File = $file.FullName
                        Language = "PowerShell"
                    }
                }
                
                # Analyser les appels de fonctions
                $callMatches = [regex]::Matches($content, '([A-Za-z0-9_-]+)\s*\(')
                foreach ($match in $callMatches) {
                    $calledFunction = $match.Groups[1].Value
                    if ($components | Where-Object { $_.Name -eq $calledFunction }) {
                        $dependencies += @{
                            Source = $file.Name
                            Target = $calledFunction
                            Type = "Call"
                        }
                    }
                }
            }
            ".py" {
                # Analyser les classes Python
                $classMatches = [regex]::Matches($content, 'class\s+([A-Za-z0-9_]+)')
                foreach ($match in $classMatches) {
                    $className = $match.Groups[1].Value
                    $components += @{
                        Name = $className
                        Type = "Class"
                        File = $file.FullName
                        Language = "Python"
                    }
                }
                
                # Analyser les fonctions Python
                $functionMatches = [regex]::Matches($content, 'def\s+([A-Za-z0-9_]+)')
                foreach ($match in $functionMatches) {
                    $functionName = $match.Groups[1].Value
                    $components += @{
                        Name = $functionName
                        Type = "Function"
                        File = $file.FullName
                        Language = "Python"
                    }
                }
                
                # Analyser les imports
                $importMatches = [regex]::Matches($content, 'import\s+([A-Za-z0-9_.]+)')
                foreach ($match in $importMatches) {
                    $importedModule = $match.Groups[1].Value
                    $dependencies += @{
                        Source = $file.Name
                        Target = $importedModule
                        Type = "Import"
                    }
                }
                
                # Analyser les from imports
                $fromImportMatches = [regex]::Matches($content, 'from\s+([A-Za-z0-9_.]+)\s+import')
                foreach ($match in $fromImportMatches) {
                    $importedModule = $match.Groups[1].Value
                    $dependencies += @{
                        Source = $file.Name
                        Target = $importedModule
                        Type = "Import"
                    }
                }
            }
            # Ajouter d'autres extensions selon les besoins
        }
    }
    
    Write-LogInfo "Nombre de composants trouvÃ©s : $($components.Count)"
    Write-LogInfo "Nombre de dÃ©pendances trouvÃ©es : $($dependencies.Count)"
    
    # Mettre Ã  jour les rÃ©sultats
    $result.ComponentCount = $components.Count
    $result.InterfaceCount = $interfaces.Count
    $result.DependencyCount = $dependencies.Count
    
    # GÃ©nÃ©rer les diagrammes
    Write-LogInfo "GÃ©nÃ©ration des diagrammes de type : $DiagramType"
    
    # Chemin du fichier de diagramme
    $diagramFileName = "architecture_diagram"
    
    switch ($DiagramType) {
        "C4" {
            # GÃ©nÃ©rer un diagramme C4 en Markdown
            $diagramPath = Join-Path -Path $OutputPath -ChildPath "$diagramFileName.md"
            
            # CrÃ©er le contenu du diagramme
            $diagramContent = @"
# Diagramme d'architecture C4

## Contexte

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

title Architecture du projet

Person(user, "Utilisateur", "Utilisateur du systÃ¨me")
System(system, "SystÃ¨me", "Le systÃ¨me complet")

Rel(user, system, "Utilise")
@enduml
```

## Conteneurs

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

title Conteneurs du systÃ¨me

Person(user, "Utilisateur", "Utilisateur du systÃ¨me")
System_Boundary(system, "SystÃ¨me") {
    Container(api, "API", "PowerShell", "Fournit les fonctionnalitÃ©s via une API")
    Container(core, "Core", "PowerShell", "Logique mÃ©tier principale")
    Container(data, "Data", "Fichiers", "Stockage des donnÃ©es")
}

Rel(user, api, "Utilise", "HTTP")
Rel(api, core, "Appelle")
Rel(core, data, "Lit/Ã‰crit")
@enduml
```

"@
            
            # Ajouter les composants si demandÃ©
            if ($IncludeComponents) {
                $diagramContent += @"

## Composants

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

title Composants du systÃ¨me

Container_Boundary(api, "API") {
    Component(api_controller, "ContrÃ´leur API", "PowerShell", "GÃ¨re les requÃªtes API")
    Component(api_validator, "Validateur", "PowerShell", "Valide les entrÃ©es")
}

Container_Boundary(core, "Core") {
    Component(core_service, "Service", "PowerShell", "ImplÃ©mente la logique mÃ©tier")
    Component(core_helper, "Helper", "PowerShell", "Fonctions utilitaires")
}

Container_Boundary(data, "Data") {
    Component(data_repository, "Repository", "PowerShell", "AccÃ¨s aux donnÃ©es")
    Component(data_model, "ModÃ¨le", "PowerShell", "ModÃ¨le de donnÃ©es")
}

Rel(api_controller, api_validator, "Utilise")
Rel(api_controller, core_service, "Appelle")
Rel(core_service, core_helper, "Utilise")
Rel(core_service, data_repository, "Utilise")
Rel(data_repository, data_model, "Utilise")
@enduml
```

"@
            }
            
            # Ajouter les composants rÃ©els
            if ($components.Count -gt 0) {
                $diagramContent += @"

## Composants rÃ©els

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

title Composants rÃ©els du systÃ¨me

"@
                
                # Ajouter les composants par type
                $componentsByType = $components | Group-Object -Property Type
                
                foreach ($type in $componentsByType) {
                    $diagramContent += "`nPackage ""$($type.Name)"" {`n"
                    
                    foreach ($component in $type.Group) {
                        $diagramContent += "    Component($($component.Name.Replace('-', '_')), ""$($component.Name)"", ""$($component.Language)"", ""$($component.Type)"")`n"
                    }
                    
                    $diagramContent += "}`n"
                }
                
                # Ajouter les dÃ©pendances
                if ($IncludeDependencies -and $dependencies.Count -gt 0) {
                    $diagramContent += "`n"
                    
                    foreach ($dependency in $dependencies) {
                        $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                        $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                        $diagramContent += "Rel($source, $target, ""$($dependency.Type)"")`n"
                    }
                }
                
                $diagramContent += @"
@enduml
```

"@
            }
            
            # Ã‰crire le contenu dans le fichier
            Set-Content -Path $diagramPath -Value $diagramContent -Encoding UTF8
            
            # Ajouter le fichier Ã  la liste des fichiers gÃ©nÃ©rÃ©s
            $result.OutputFiles += $diagramPath
            $result.DiagramCount++
        }
        "UML" {
            # GÃ©nÃ©rer un diagramme UML en Markdown
            $diagramPath = Join-Path -Path $OutputPath -ChildPath "$diagramFileName.md"
            
            # CrÃ©er le contenu du diagramme
            $diagramContent = @"
# Diagramme d'architecture UML

## Diagramme de classes

```plantuml
@startuml
title Diagramme de classes

"@
            
            # Ajouter les composants
            foreach ($component in $components) {
                if ($component.Type -eq "Class") {
                    $diagramContent += "class $($component.Name) {`n"
                    $diagramContent += "    +methods()`n"
                    $diagramContent += "}`n"
                }
            }
            
            # Ajouter les dÃ©pendances
            if ($IncludeDependencies -and $dependencies.Count -gt 0) {
                $diagramContent += "`n"
                
                foreach ($dependency in $dependencies) {
                    $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                    $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                    $diagramContent += "$source --> $target : $($dependency.Type)`n"
                }
            }
            
            $diagramContent += @"
@enduml
```

## Diagramme de packages

```plantuml
@startuml
title Diagramme de packages

"@
            
            # Ajouter les packages
            $filesByDirectory = $files | Group-Object -Property DirectoryName
            
            foreach ($directory in $filesByDirectory) {
                $directoryName = Split-Path -Leaf $directory.Name
                $diagramContent += "package ""$directoryName"" {`n"
                
                foreach ($file in $directory.Group) {
                    $fileName = $file.Name.Replace('-', '_').Replace('.', '_')
                    $diagramContent += "    class $fileName`n"
                }
                
                $diagramContent += "}`n"
            }
            
            $diagramContent += @"
@enduml
```

"@
            
            # Ã‰crire le contenu dans le fichier
            Set-Content -Path $diagramPath -Value $diagramContent -Encoding UTF8
            
            # Ajouter le fichier Ã  la liste des fichiers gÃ©nÃ©rÃ©s
            $result.OutputFiles += $diagramPath
            $result.DiagramCount++
        }
        "Mermaid" {
            # GÃ©nÃ©rer un diagramme Mermaid en Markdown
            $diagramPath = Join-Path -Path $OutputPath -ChildPath "$diagramFileName.md"
            
            # CrÃ©er le contenu du diagramme
            $diagramContent = @"
# Diagramme d'architecture Mermaid

## Diagramme de flux

```mermaid
graph TD
    User[Utilisateur] --> System[SystÃ¨me]
    System --> API[API]
    API --> Core[Core]
    Core --> Data[Data]
"@
            
            # Ajouter les composants
            if ($IncludeComponents -and $components.Count -gt 0) {
                $diagramContent += "`n"
                
                foreach ($component in $components) {
                    $componentId = $component.Name.Replace('-', '_').Replace('.', '_')
                    $diagramContent += "    $($component.Type)_$componentId[$($component.Name)]`n"
                }
            }
            
            # Ajouter les dÃ©pendances
            if ($IncludeDependencies -and $dependencies.Count -gt 0) {
                $diagramContent += "`n"
                
                foreach ($dependency in $dependencies) {
                    $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                    $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                    $diagramContent += "    $source --> $target`n"
                }
            }
            
            $diagramContent += @"
```

## Diagramme de classes

```mermaid
classDiagram
"@
            
            # Ajouter les classes
            foreach ($component in $components) {
                if ($component.Type -eq "Class") {
                    $diagramContent += "`n    class $($component.Name) {`n"
                    $diagramContent += "        +methods()`n"
                    $diagramContent += "    }`n"
                }
            }
            
            # Ajouter les relations
            if ($IncludeDependencies -and $dependencies.Count -gt 0) {
                $diagramContent += "`n"
                
                foreach ($dependency in $dependencies) {
                    if ($dependency.Type -eq "Inheritance") {
                        $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                        $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                        $diagramContent += "    $source --|> $target`n"
                    } elseif ($dependency.Type -eq "Composition") {
                        $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                        $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                        $diagramContent += "    $source --* $target`n"
                    } else {
                        $source = $dependency.Source.Replace('-', '_').Replace('.', '_')
                        $target = $dependency.Target.Replace('-', '_').Replace('.', '_')
                        $diagramContent += "    $source --> $target : $($dependency.Type)`n"
                    }
                }
            }
            
            $diagramContent += @"
```

"@
            
            # Ã‰crire le contenu dans le fichier
            Set-Content -Path $diagramPath -Value $diagramContent -Encoding UTF8
            
            # Ajouter le fichier Ã  la liste des fichiers gÃ©nÃ©rÃ©s
            $result.OutputFiles += $diagramPath
            $result.DiagramCount++
        }
    }
    
    # GÃ©nÃ©rer un document d'architecture
    $architectureDocPath = Join-Path -Path $OutputPath -ChildPath "architecture_document.md"
    
    # CrÃ©er le contenu du document
    $documentContent = @"
# Document d'architecture

## Vue d'ensemble

Ce document dÃ©crit l'architecture du projet situÃ© dans le rÃ©pertoire : $ProjectPath

## Structure du projet

Le projet est structurÃ© comme suit :

"@
    
    # Ajouter la structure des rÃ©pertoires
    $directories = Get-ChildItem -Path $ProjectPath -Directory -Recurse | Select-Object -ExpandProperty FullName | ForEach-Object { $_.Replace($ProjectPath, '').TrimStart('\') }
    
    foreach ($directory in $directories) {
        $documentContent += "- $directory`n"
    }
    
    # Ajouter les composants
    if ($components.Count -gt 0) {
        $documentContent += @"

## Composants

Le projet contient les composants suivants :

| Nom | Type | Langage | Fichier |
|-----|------|---------|---------|
"@
        
        foreach ($component in $components) {
            $relativePath = $component.File.Replace($ProjectPath, '').TrimStart('\')
            $documentContent += "| $($component.Name) | $($component.Type) | $($component.Language) | $relativePath |`n"
        }
    }
    
    # Ajouter les dÃ©pendances
    if ($dependencies.Count -gt 0) {
        $documentContent += @"

## DÃ©pendances

Le projet contient les dÃ©pendances suivantes :

| Source | Cible | Type |
|--------|-------|------|
"@
        
        foreach ($dependency in $dependencies) {
            $documentContent += "| $($dependency.Source) | $($dependency.Target) | $($dependency.Type) |`n"
        }
    }
    
    # Ajouter les diagrammes
    $documentContent += @"

## Diagrammes

Les diagrammes suivants ont Ã©tÃ© gÃ©nÃ©rÃ©s :

"@
    
    foreach ($file in $result.OutputFiles) {
        $relativePath = $file.Replace($OutputPath, '').TrimStart('\')
        $documentContent += "- [$relativePath]($relativePath)`n"
    }
    
    # Ã‰crire le contenu dans le fichier
    Set-Content -Path $architectureDocPath -Value $documentContent -Encoding UTF8
    
    # Ajouter le fichier Ã  la liste des fichiers gÃ©nÃ©rÃ©s
    $result.OutputFiles += $architectureDocPath
    
    # Mettre Ã  jour le rÃ©sultat
    $result.Success = $true
    
    return $result
}

# Exporter la fonction
Export-ModuleMember -Function Invoke-RoadmapArchitecture
