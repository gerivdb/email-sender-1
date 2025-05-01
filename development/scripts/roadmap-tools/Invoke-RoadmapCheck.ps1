<#
.SYNOPSIS
    Interface utilisateur pour sélectionner et mettre à jour le statut des tâches dans un fichier de roadmap.

.DESCRIPTION
    Ce script fournit une interface utilisateur pour sélectionner un fichier de roadmap,
    choisir les lignes à vérifier, et mettre à jour le statut des tâches en cochant les cases
    des tâches implémentées.

.PARAMETER RoadmapDirectory
    Répertoire contenant les fichiers de roadmap. Par défaut, utilise le répertoire "Roadmap" à la racine du projet.

.PARAMETER VerifyOnly
    Si spécifié, le script vérifie seulement les tâches sans modifier le fichier de roadmap.

.PARAMETER GenerateReport
    Si spécifié, génère un rapport détaillé des tâches vérifiées.

.EXAMPLE
    .\Invoke-RoadmapCheck.ps1

.EXAMPLE
    .\Invoke-RoadmapCheck.ps1 -RoadmapDirectory ".\Documents\Roadmaps" -VerifyOnly

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de création: 2023-11-15
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapDirectory = (Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath "Roadmap"),

    [Parameter(Mandatory = $false)]
    [switch]$VerifyOnly,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Ajouter les assemblies nécessaires pour l'interface utilisateur
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Fonction pour sélectionner un fichier de roadmap
function Select-RoadmapFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InitialDirectory
    )

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = $InitialDirectory
    $openFileDialog.Filter = "Fichiers Markdown (*.md)|*.md|Tous les fichiers (*.*)|*.*"
    $openFileDialog.Title = "Sélectionner un fichier de roadmap"

    if ($openFileDialog.ShowDialog() -eq "OK") {
        return $openFileDialog.FileName
    }

    return $null
}

# Fonction pour créer un formulaire de sélection des lignes
function New-LineSelectionForm {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # Créer le formulaire principal
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Sélection des lignes de la roadmap"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    # Créer le label pour le chemin du fichier
    $labelPath = New-Object System.Windows.Forms.Label
    $labelPath.Location = New-Object System.Drawing.Point(10, 10)
    $labelPath.Size = New-Object System.Drawing.Size(780, 20)
    $labelPath.Text = "Fichier : $RoadmapPath"
    $form.Controls.Add($labelPath)

    # Créer le label d'instructions
    $labelInstructions = New-Object System.Windows.Forms.Label
    $labelInstructions.Location = New-Object System.Drawing.Point(10, 35)
    $labelInstructions.Size = New-Object System.Drawing.Size(780, 20)
    $labelInstructions.Text = "Sélectionnez les lignes à vérifier (utilisez Ctrl ou Shift pour sélectionner plusieurs lignes)"
    $form.Controls.Add($labelInstructions)

    # Créer la liste des lignes
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 60)
    $listBox.Size = New-Object System.Drawing.Size(780, 450)
    $listBox.SelectionMode = "MultiExtended"
    $listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $form.Controls.Add($listBox)

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8
    
    # Ajouter les lignes au ListBox avec leur numéro
    for ($i = 0; $i -lt $content.Count; $i++) {
        $lineNumber = $i + 1
        $line = $content[$i]
        $listBox.Items.Add("$lineNumber : $line")
    }

    # Créer le bouton OK
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(620, 520)
    $buttonOK.Size = New-Object System.Drawing.Size(80, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($buttonOK)
    $form.AcceptButton = $buttonOK

    # Créer le bouton Annuler
    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = New-Object System.Drawing.Point(710, 520)
    $buttonCancel.Size = New-Object System.Drawing.Size(80, 30)
    $buttonCancel.Text = "Annuler"
    $buttonCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($buttonCancel)
    $form.CancelButton = $buttonCancel

    # Créer le bouton Tout sélectionner
    $buttonSelectAll = New-Object System.Windows.Forms.Button
    $buttonSelectAll.Location = New-Object System.Drawing.Point(10, 520)
    $buttonSelectAll.Size = New-Object System.Drawing.Size(120, 30)
    $buttonSelectAll.Text = "Tout sélectionner"
    $buttonSelectAll.Add_Click({
        for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
            $listBox.SetSelected($i, $true)
        }
    })
    $form.Controls.Add($buttonSelectAll)

    # Créer le bouton Sélectionner les tâches
    $buttonSelectTasks = New-Object System.Windows.Forms.Button
    $buttonSelectTasks.Location = New-Object System.Drawing.Point(140, 520)
    $buttonSelectTasks.Size = New-Object System.Drawing.Size(150, 30)
    $buttonSelectTasks.Text = "Sélectionner les tâches"
    $buttonSelectTasks.Add_Click({
        for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
            $line = $listBox.Items[$i]
            if ($line -match '^\d+ : \s*-\s+\[[ xX]\]\s+\d+(\.\d+)*\s+') {
                $listBox.SetSelected($i, $true)
            }
            else {
                $listBox.SetSelected($i, $false)
            }
        }
    })
    $form.Controls.Add($buttonSelectTasks)

    # Afficher le formulaire et retourner les lignes sélectionnées
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedLines = @()
        foreach ($selectedIndex in $listBox.SelectedIndices) {
            $selectedLine = $listBox.Items[$selectedIndex]
            $lineNumber = [int]($selectedLine -split ' : ')[0]
            $selectedLines += $lineNumber
        }
        return $selectedLines
    }

    return $null
}

# Fonction pour exécuter le script de mise à jour de la roadmap
function Invoke-UpdateRoadmapStatus {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $true)]
        [int[]]$LineNumbers,

        [Parameter(Mandatory = $false)]
        [switch]$VerifyOnly,

        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )

    $updateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-RoadmapStatus.ps1"
    
    if (-not (Test-Path -Path $updateScriptPath)) {
        Write-Error "Le script de mise à jour de la roadmap n'a pas été trouvé : $updateScriptPath"
        return
    }

    $params = @{
        RoadmapPath = $RoadmapPath
        LineNumbers = $LineNumbers
    }

    if ($VerifyOnly) {
        $params.Add("VerifyOnly", $true)
    }

    if ($GenerateReport) {
        $params.Add("GenerateReport", $true)
    }

    & $updateScriptPath @params
}

# Script principal
function Invoke-RoadmapCheck {
    # Vérifier si le répertoire des roadmaps existe
    if (-not (Test-Path -Path $RoadmapDirectory)) {
        Write-Error "Le répertoire des roadmaps n'existe pas : $RoadmapDirectory"
        return
    }

    # Sélectionner un fichier de roadmap
    $roadmapPath = Select-RoadmapFile -InitialDirectory $RoadmapDirectory
    if ($null -eq $roadmapPath) {
        Write-Warning "Aucun fichier de roadmap sélectionné."
        return
    }

    # Sélectionner les lignes à vérifier
    $lineNumbers = New-LineSelectionForm -RoadmapPath $roadmapPath
    if ($null -eq $lineNumbers -or $lineNumbers.Count -eq 0) {
        Write-Warning "Aucune ligne sélectionnée."
        return
    }

    # Exécuter le script de mise à jour de la roadmap
    Invoke-UpdateRoadmapStatus -RoadmapPath $roadmapPath -LineNumbers $lineNumbers -VerifyOnly:$VerifyOnly -GenerateReport:$GenerateReport
}

# Exécuter le script principal
Invoke-RoadmapCheck
