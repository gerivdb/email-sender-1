<#
.SYNOPSIS
    Interface utilisateur pour sÃ©lectionner et mettre Ã  jour le statut des tÃ¢ches dans un fichier de roadmap.

.DESCRIPTION
    Ce script fournit une interface utilisateur pour sÃ©lectionner un fichier de roadmap,
    choisir les lignes Ã  vÃ©rifier, et mettre Ã  jour le statut des tÃ¢ches en cochant les cases
    des tÃ¢ches implÃ©mentÃ©es.

.PARAMETER RoadmapDirectory
    RÃ©pertoire contenant les fichiers de roadmap. Par dÃ©faut, utilise le rÃ©pertoire "Roadmap" Ã  la racine du projet.

.PARAMETER VerifyOnly
    Si spÃ©cifiÃ©, le script vÃ©rifie seulement les tÃ¢ches sans modifier le fichier de roadmap.

.PARAMETER GenerateReport
    Si spÃ©cifiÃ©, gÃ©nÃ¨re un rapport dÃ©taillÃ© des tÃ¢ches vÃ©rifiÃ©es.

.EXAMPLE
    .\Invoke-RoadmapCheck.ps1

.EXAMPLE
    .\Invoke-RoadmapCheck.ps1 -RoadmapDirectory ".\Documents\Roadmaps" -VerifyOnly

.NOTES
    Auteur: Roadmap Tools Team
    Version: 1.0
    Date de crÃ©ation: 2023-11-15
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

# Ajouter les assemblies nÃ©cessaires pour l'interface utilisateur
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Fonction pour sÃ©lectionner un fichier de roadmap
function Select-RoadmapFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$InitialDirectory
    )

    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.InitialDirectory = $InitialDirectory
    $openFileDialog.Filter = "Fichiers Markdown (*.md)|*.md|Tous les fichiers (*.*)|*.*"
    $openFileDialog.Title = "SÃ©lectionner un fichier de roadmap"

    if ($openFileDialog.ShowDialog() -eq "OK") {
        return $openFileDialog.FileName
    }

    return $null
}

# Fonction pour crÃ©er un formulaire de sÃ©lection des lignes
function New-LineSelectionForm {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # CrÃ©er le formulaire principal
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "SÃ©lection des lignes de la roadmap"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.StartPosition = "CenterScreen"
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    # CrÃ©er le label pour le chemin du fichier
    $labelPath = New-Object System.Windows.Forms.Label
    $labelPath.Location = New-Object System.Drawing.Point(10, 10)
    $labelPath.Size = New-Object System.Drawing.Size(780, 20)
    $labelPath.Text = "Fichier : $RoadmapPath"
    $form.Controls.Add($labelPath)

    # CrÃ©er le label d'instructions
    $labelInstructions = New-Object System.Windows.Forms.Label
    $labelInstructions.Location = New-Object System.Drawing.Point(10, 35)
    $labelInstructions.Size = New-Object System.Drawing.Size(780, 20)
    $labelInstructions.Text = "SÃ©lectionnez les lignes Ã  vÃ©rifier (utilisez Ctrl ou Shift pour sÃ©lectionner plusieurs lignes)"
    $form.Controls.Add($labelInstructions)

    # CrÃ©er la liste des lignes
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 60)
    $listBox.Size = New-Object System.Drawing.Size(780, 450)
    $listBox.SelectionMode = "MultiExtended"
    $listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $form.Controls.Add($listBox)

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8
    
    # Ajouter les lignes au ListBox avec leur numÃ©ro
    for ($i = 0; $i -lt $content.Count; $i++) {
        $lineNumber = $i + 1
        $line = $content[$i]
        $listBox.Items.Add("$lineNumber : $line")
    }

    # CrÃ©er le bouton OK
    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(620, 520)
    $buttonOK.Size = New-Object System.Drawing.Size(80, 30)
    $buttonOK.Text = "OK"
    $buttonOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($buttonOK)
    $form.AcceptButton = $buttonOK

    # CrÃ©er le bouton Annuler
    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = New-Object System.Drawing.Point(710, 520)
    $buttonCancel.Size = New-Object System.Drawing.Size(80, 30)
    $buttonCancel.Text = "Annuler"
    $buttonCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($buttonCancel)
    $form.CancelButton = $buttonCancel

    # CrÃ©er le bouton Tout sÃ©lectionner
    $buttonSelectAll = New-Object System.Windows.Forms.Button
    $buttonSelectAll.Location = New-Object System.Drawing.Point(10, 520)
    $buttonSelectAll.Size = New-Object System.Drawing.Size(120, 30)
    $buttonSelectAll.Text = "Tout sÃ©lectionner"
    $buttonSelectAll.Add_Click({
        for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
            $listBox.SetSelected($i, $true)
        }
    })
    $form.Controls.Add($buttonSelectAll)

    # CrÃ©er le bouton SÃ©lectionner les tÃ¢ches
    $buttonSelectTasks = New-Object System.Windows.Forms.Button
    $buttonSelectTasks.Location = New-Object System.Drawing.Point(140, 520)
    $buttonSelectTasks.Size = New-Object System.Drawing.Size(150, 30)
    $buttonSelectTasks.Text = "SÃ©lectionner les tÃ¢ches"
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

    # Afficher le formulaire et retourner les lignes sÃ©lectionnÃ©es
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

# Fonction pour exÃ©cuter le script de mise Ã  jour de la roadmap
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
        Write-Error "Le script de mise Ã  jour de la roadmap n'a pas Ã©tÃ© trouvÃ© : $updateScriptPath"
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
    # VÃ©rifier si le rÃ©pertoire des roadmaps existe
    if (-not (Test-Path -Path $RoadmapDirectory)) {
        Write-Error "Le rÃ©pertoire des roadmaps n'existe pas : $RoadmapDirectory"
        return
    }

    # SÃ©lectionner un fichier de roadmap
    $roadmapPath = Select-RoadmapFile -InitialDirectory $RoadmapDirectory
    if ($null -eq $roadmapPath) {
        Write-Warning "Aucun fichier de roadmap sÃ©lectionnÃ©."
        return
    }

    # SÃ©lectionner les lignes Ã  vÃ©rifier
    $lineNumbers = New-LineSelectionForm -RoadmapPath $roadmapPath
    if ($null -eq $lineNumbers -or $lineNumbers.Count -eq 0) {
        Write-Warning "Aucune ligne sÃ©lectionnÃ©e."
        return
    }

    # ExÃ©cuter le script de mise Ã  jour de la roadmap
    Invoke-UpdateRoadmapStatus -RoadmapPath $roadmapPath -LineNumbers $lineNumbers -VerifyOnly:$VerifyOnly -GenerateReport:$GenerateReport
}

# ExÃ©cuter le script principal
Invoke-RoadmapCheck
