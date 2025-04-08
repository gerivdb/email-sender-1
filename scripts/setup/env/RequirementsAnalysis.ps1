# Script pour l'analyse des besoins du projet

# Configuration
$AnalysisConfig = @{
    # Dossier de stockage des documents d'analyse
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ProjectAnalysis"
    
    # Fichier des besoins du projet
    RequirementsFile = Join-Path -Path $env:TEMP -ChildPath "ProjectAnalysis\requirements.json"
    
    # Fichier des contraintes techniques
    ConstraintsFile = Join-Path -Path $env:TEMP -ChildPath "ProjectAnalysis\constraints.json"
    
    # Fichier des critères de succès
    SuccessCriteriaFile = Join-Path -Path $env:TEMP -ChildPath "ProjectAnalysis\success_criteria.json"
}

# Fonction pour initialiser l'analyse des besoins
function Initialize-RequirementsAnalysis {
    param (
        [string]$OutputFolder = "",
        [string]$RequirementsFile = "",
        [string]$ConstraintsFile = "",
        [string]$SuccessCriteriaFile = ""
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $AnalysisConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($RequirementsFile)) {
        $AnalysisConfig.RequirementsFile = $RequirementsFile
    }
    
    if (-not [string]::IsNullOrEmpty($ConstraintsFile)) {
        $AnalysisConfig.ConstraintsFile = $ConstraintsFile
    }
    
    if (-not [string]::IsNullOrEmpty($SuccessCriteriaFile)) {
        $AnalysisConfig.SuccessCriteriaFile = $SuccessCriteriaFile
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $AnalysisConfig.OutputFolder)) {
        New-Item -Path $AnalysisConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer les fichiers s'ils n'existent pas
    $files = @{
        $AnalysisConfig.RequirementsFile = @{
            Requirements = @()
            LastUpdate = Get-Date -Format "o"
        }
        $AnalysisConfig.ConstraintsFile = @{
            Constraints = @()
            LastUpdate = Get-Date -Format "o"
        }
        $AnalysisConfig.SuccessCriteriaFile = @{
            SuccessCriteria = @()
            LastUpdate = Get-Date -Format "o"
        }
    }
    
    foreach ($file in $files.Keys) {
        if (-not (Test-Path -Path $file)) {
            $files[$file] | ConvertTo-Json -Depth 5 | Set-Content -Path $file
        }
    }
    
    return $AnalysisConfig
}

# Fonction pour ajouter un besoin
function Add-Requirement {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Functional", "Non-Functional", "Technical", "Business")]
        [string]$Type = "Functional",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Must", "Should", "Could", "Won't")]
        [string]$Priority = "Must",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Stakeholders = @(),
        
        [Parameter(Mandatory = $false)]
        [string[]]$Dependencies = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $AnalysisConfig.RequirementsFile)) {
        Initialize-RequirementsAnalysis
    }
    
    # Charger les besoins existants
    $requirementsData = Get-Content -Path $AnalysisConfig.RequirementsFile -Raw | ConvertFrom-Json
    
    # Vérifier si le besoin existe déjà
    $existingRequirement = $requirementsData.Requirements | Where-Object { $_.Name -eq $Name }
    
    if ($existingRequirement) {
        Write-Warning "Un besoin avec ce nom existe déjà."
        return $null
    }
    
    # Créer le besoin
    $requirement = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Type = $Type
        Priority = $Priority
        Stakeholders = $Stakeholders
        Dependencies = $Dependencies
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
        Status = "Proposed"
    }
    
    # Ajouter le besoin
    $requirementsData.Requirements += $requirement
    $requirementsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les besoins
    $requirementsData | ConvertTo-Json -Depth 5 | Set-Content -Path $AnalysisConfig.RequirementsFile
    
    return $requirement
}

# Fonction pour ajouter une contrainte technique
function Add-Constraint {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Technical", "Business", "Legal", "Environmental", "Resource")]
        [string]$Type = "Technical",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("High", "Medium", "Low")]
        [string]$Impact = "Medium",
        
        [Parameter(Mandatory = $false)]
        [string]$Mitigation = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $AnalysisConfig.ConstraintsFile)) {
        Initialize-RequirementsAnalysis
    }
    
    # Charger les contraintes existantes
    $constraintsData = Get-Content -Path $AnalysisConfig.ConstraintsFile -Raw | ConvertFrom-Json
    
    # Vérifier si la contrainte existe déjà
    $existingConstraint = $constraintsData.Constraints | Where-Object { $_.Name -eq $Name }
    
    if ($existingConstraint) {
        Write-Warning "Une contrainte avec ce nom existe déjà."
        return $null
    }
    
    # Créer la contrainte
    $constraint = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Type = $Type
        Impact = $Impact
        Mitigation = $Mitigation
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
    }
    
    # Ajouter la contrainte
    $constraintsData.Constraints += $constraint
    $constraintsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les contraintes
    $constraintsData | ConvertTo-Json -Depth 5 | Set-Content -Path $AnalysisConfig.ConstraintsFile
    
    return $constraint
}

# Fonction pour ajouter un critère de succès
function Add-SuccessCriterion {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Functional", "Performance", "Usability", "Reliability", "Security")]
        [string]$Category = "Functional",
        
        [Parameter(Mandatory = $false)]
        [string]$Measurement = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetValue = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $AnalysisConfig.SuccessCriteriaFile)) {
        Initialize-RequirementsAnalysis
    }
    
    # Charger les critères existants
    $criteriaData = Get-Content -Path $AnalysisConfig.SuccessCriteriaFile -Raw | ConvertFrom-Json
    
    # Vérifier si le critère existe déjà
    $existingCriterion = $criteriaData.SuccessCriteria | Where-Object { $_.Name -eq $Name }
    
    if ($existingCriterion) {
        Write-Warning "Un critère avec ce nom existe déjà."
        return $null
    }
    
    # Créer le critère
    $criterion = @{
        ID = [Guid]::NewGuid().ToString()
        Name = $Name
        Description = $Description
        Category = $Category
        Measurement = $Measurement
        TargetValue = $TargetValue
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
        Status = "Proposed"
    }
    
    # Ajouter le critère
    $criteriaData.SuccessCriteria += $criterion
    $criteriaData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les critères
    $criteriaData | ConvertTo-Json -Depth 5 | Set-Content -Path $AnalysisConfig.SuccessCriteriaFile
    
    return $criterion
}

# Fonction pour générer un rapport d'analyse des besoins
function New-RequirementsAnalysisReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'analyse des besoins",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeConstraints,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSuccessCriteria,
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les données
    $requirementsData = Get-Content -Path $AnalysisConfig.RequirementsFile -Raw | ConvertFrom-Json
    $requirements = $requirementsData.Requirements
    
    $constraints = @()
    if ($IncludeConstraints) {
        $constraintsData = Get-Content -Path $AnalysisConfig.ConstraintsFile -Raw | ConvertFrom-Json
        $constraints = $constraintsData.Constraints
    }
    
    $successCriteria = @()
    if ($IncludeSuccessCriteria) {
        $criteriaData = Get-Content -Path $AnalysisConfig.SuccessCriteriaFile -Raw | ConvertFrom-Json
        $successCriteria = $criteriaData.SuccessCriteria
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "RequirementsAnalysis-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .section {
            margin-bottom: 30px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .priority-must {
            color: #d9534f;
            font-weight: bold;
        }
        
        .priority-should {
            color: #f0ad4e;
            font-weight: bold;
        }
        
        .priority-could {
            color: #5bc0de;
        }
        
        .priority-wont {
            color: #777;
        }
        
        .impact-high {
            color: #d9534f;
            font-weight: bold;
        }
        
        .impact-medium {
            color: #f0ad4e;
        }
        
        .impact-low {
            color: #5bc0de;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="section">
            <h2>Besoins du projet</h2>
            <p>Nombre total de besoins: $($requirements.Count)</p>
            
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Type</th>
                        <th>Priorité</th>
                        <th>Description</th>
                        <th>Statut</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($req in ($requirements | Sort-Object -Property Priority, Name)) {
                        $priorityClass = "priority-" + $req.Priority.ToLower()
                        
                        "<tr>
                            <td>$($req.Name)</td>
                            <td>$($req.Type)</td>
                            <td class='$priorityClass'>$($req.Priority)</td>
                            <td>$($req.Description)</td>
                            <td>$($req.Status)</td>
                        </tr>"
                    })
                </tbody>
            </table>
        </div>
        
        $(if ($IncludeConstraints) {
            "<div class='section'>
                <h2>Contraintes techniques</h2>
                <p>Nombre total de contraintes: $($constraints.Count)</p>
                
                <table>
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Type</th>
                            <th>Impact</th>
                            <th>Description</th>
                            <th>Mitigation</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($constraint in ($constraints | Sort-Object -Property Impact, Name)) {
                            $impactClass = "impact-" + $constraint.Impact.ToLower()
                            
                            "<tr>
                                <td>$($constraint.Name)</td>
                                <td>$($constraint.Type)</td>
                                <td class='$impactClass'>$($constraint.Impact)</td>
                                <td>$($constraint.Description)</td>
                                <td>$($constraint.Mitigation)</td>
                            </tr>"
                        })
                    </tbody>
                </table>
            </div>"
        })
        
        $(if ($IncludeSuccessCriteria) {
            "<div class='section'>
                <h2>Critères de succès</h2>
                <p>Nombre total de critères: $($successCriteria.Count)</p>
                
                <table>
                    <thead>
                        <tr>
                            <th>Nom</th>
                            <th>Catégorie</th>
                            <th>Description</th>
                            <th>Mesure</th>
                            <th>Valeur cible</th>
                        </tr>
                    </thead>
                    <tbody>
                        $(foreach ($criterion in ($successCriteria | Sort-Object -Property Category, Name)) {
                            "<tr>
                                <td>$($criterion.Name)</td>
                                <td>$($criterion.Category)</td>
                                <td>$($criterion.Description)</td>
                                <td>$($criterion.Measurement)</td>
                                <td>$($criterion.TargetValue)</td>
                            </tr>"
                        })
                    </tbody>
                </table>
            </div>"
        })
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-RequirementsAnalysis, Add-Requirement, Add-Constraint, Add-SuccessCriterion, New-RequirementsAnalysisReport
