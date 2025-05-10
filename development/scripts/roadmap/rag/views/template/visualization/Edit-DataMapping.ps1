# Edit-DataMapping.ps1
# Script pour l'interface de mappage de données
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$MappingPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Fonction pour charger un mappage existant
function Get-DataMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$MappingPath
    )
    
    if (-not [string]::IsNullOrEmpty($MappingPath) -and (Test-Path -Path $MappingPath)) {
        try {
            $mapping = Get-Content -Path $MappingPath -Raw | ConvertFrom-Json
            return $mapping
        } catch {
            Write-Log "Error loading data mapping: $_" -Level "Error"
            return $null
        }
    }
    
    # Mappage par défaut
    $defaultMapping = @{
        Version = "1.0"
        CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ModifiedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Mappings = @(
            @{
                Name = "Status Distribution"
                Description = "Distribution des tâches par statut"
                Type = "PieChart"
                DataSource = "RoadmapTasks"
                GroupBy = "Status"
                ValueField = "Count"
                Labels = @{
                    todo = "À faire"
                    in_progress = "En cours"
                    done = "Terminé"
                    blocked = "Bloqué"
                }
                Colors = @{
                    todo = "#f39c12"
                    in_progress = "#3498db"
                    done = "#2ecc71"
                    blocked = "#e74c3c"
                }
                TemplateVariables = @{
                    tasks_todo = "{{COUNT:Status=todo}}"
                    tasks_in_progress = "{{COUNT:Status=in_progress}}"
                    tasks_done = "{{COUNT:Status=done}}"
                    tasks_blocked = "{{COUNT:Status=blocked}}"
                    percentage_todo = "{{PERCENTAGE:Status=todo}}"
                    percentage_in_progress = "{{PERCENTAGE:Status=in_progress}}"
                    percentage_done = "{{PERCENTAGE:Status=done}}"
                    percentage_blocked = "{{PERCENTAGE:Status=blocked}}"
                }
            },
            @{
                Name = "Priority Distribution"
                Description = "Distribution des tâches par priorité"
                Type = "BarChart"
                DataSource = "RoadmapTasks"
                GroupBy = "Priority"
                ValueField = "Count"
                Labels = @{
                    high = "Haute"
                    medium = "Moyenne"
                    low = "Basse"
                }
                Colors = @{
                    high = "#e74c3c"
                    medium = "#f39c12"
                    low = "#2ecc71"
                }
                TemplateVariables = @{
                    tasks_high = "{{COUNT:Priority=high}}"
                    tasks_medium = "{{COUNT:Priority=medium}}"
                    tasks_low = "{{COUNT:Priority=low}}"
                    percentage_high = "{{PERCENTAGE:Priority=high}}"
                    percentage_medium = "{{PERCENTAGE:Priority=medium}}"
                    percentage_low = "{{PERCENTAGE:Priority=low}}"
                }
            },
            @{
                Name = "Assignee Distribution"
                Description = "Distribution des tâches par assigné"
                Type = "DoughnutChart"
                DataSource = "RoadmapTasks"
                GroupBy = "Assignee"
                ValueField = "Count"
                DynamicLabels = $true
                DynamicColors = $true
                TemplateVariables = @{
                    assignees = "{{LABELS:Assignee}}"
                    assignee_counts = "{{VALUES:Assignee}}"
                    assignee_colors = "{{COLORS:Assignee}}"
                }
            },
            @{
                Name = "Due Date Distribution"
                Description = "Distribution des tâches par date d'échéance"
                Type = "LineChart"
                DataSource = "RoadmapTasks"
                GroupBy = "DueDate"
                ValueField = "Count"
                TimeGrouping = "Week"
                Labels = @{
                    this_week = "Cette semaine"
                    next_week = "Semaine prochaine"
                    this_month = "Ce mois"
                    next_month = "Mois prochain"
                    later = "Plus tard"
                }
                Colors = @{
                    this_week = "#e74c3c"
                    next_week = "#f39c12"
                    this_month = "#3498db"
                    next_month = "#2ecc71"
                    later = "#95a5a6"
                }
                TemplateVariables = @{
                    tasks_due_this_week = "{{COUNT:DueDate=this_week}}"
                    tasks_due_next_week = "{{COUNT:DueDate=next_week}}"
                    tasks_due_this_month = "{{COUNT:DueDate=this_month}}"
                    tasks_due_next_month = "{{COUNT:DueDate=next_month}}"
                    tasks_due_later = "{{COUNT:DueDate=later}}"
                }
            }
        )
    }
    
    return $defaultMapping
}

# Fonction pour extraire les champs disponibles à partir d'un fichier de roadmap
function Get-RoadmapFields {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath
    )
    
    if (-not [string]::IsNullOrEmpty($RoadmapPath) -and (Test-Path -Path $RoadmapPath)) {
        try {
            $extension = [System.IO.Path]::GetExtension($RoadmapPath).ToLower()
            
            switch ($extension) {
                ".json" {
                    $data = Get-Content -Path $RoadmapPath -Raw | ConvertFrom-Json
                    
                    if ($data.Count -gt 0) {
                        $firstItem = $data[0]
                        $fields = $firstItem.PSObject.Properties.Name
                        
                        $result = @{
                            Fields = $fields
                            SampleValues = @{}
                        }
                        
                        foreach ($field in $fields) {
                            $uniqueValues = $data | ForEach-Object { $_.$field } | Where-Object { $_ } | Select-Object -Unique
                            $result.SampleValues[$field] = $uniqueValues
                        }
                        
                        return $result
                    }
                }
                ".md" {
                    # Pour les fichiers markdown, nous devons extraire les métadonnées des tâches
                    # Cette implémentation est simplifiée et pourrait nécessiter une analyse plus sophistiquée
                    $content = Get-Content -Path $RoadmapPath -Raw
                    
                    $fields = @("id", "title", "status", "priority", "assignee", "due_date", "description")
                    $result = @{
                        Fields = $fields
                        SampleValues = @{}
                    }
                    
                    foreach ($field in $fields) {
                        $pattern = "$field\s*[:=]\s*(\w+)"
                        $matches = [regex]::Matches($content, $pattern)
                        
                        $uniqueValues = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
                        $result.SampleValues[$field] = $uniqueValues
                    }
                    
                    return $result
                }
                default {
                    Write-Log "Unsupported roadmap file format: $extension" -Level "Warning"
                }
            }
        } catch {
            Write-Log "Error extracting fields from roadmap: $_" -Level "Error"
        }
    }
    
    # Champs par défaut si aucun fichier de roadmap n'est spécifié
    return @{
        Fields = @("id", "title", "status", "priority", "assignee", "due_date", "description", "created_at", "updated_at", "tags", "parent_id", "indent_level", "has_children", "has_blockers", "is_milestone", "estimated_hours", "actual_hours", "progress", "start_date", "end_date")
        SampleValues = @{
            status = @("todo", "in_progress", "done", "blocked")
            priority = @("high", "medium", "low")
            assignee = @("john", "jane", "bob", "alice")
        }
    }
}

# Fonction pour afficher l'interface utilisateur de mappage
function Show-MappingUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Mapping,
        
        [Parameter(Mandatory = $true)]
        [object]$RoadmapFields
    )
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Éditeur de mappage de données"
    $form.Size = New-Object System.Drawing.Size(900, 700)
    $form.StartPosition = "CenterScreen"
    
    # Liste des mappages
    $mappingsLabel = New-Object System.Windows.Forms.Label
    $mappingsLabel.Text = "Mappages disponibles:"
    $mappingsLabel.Location = New-Object System.Drawing.Point(20, 20)
    $mappingsLabel.Size = New-Object System.Drawing.Size(150, 20)
    
    $mappingsListBox = New-Object System.Windows.Forms.ListBox
    $mappingsListBox.Location = New-Object System.Drawing.Point(20, 50)
    $mappingsListBox.Size = New-Object System.Drawing.Size(250, 200)
    
    foreach ($map in $Mapping.Mappings) {
        $mappingsListBox.Items.Add($map.Name)
    }
    
    # Panneau de détails
    $detailsPanel = New-Object System.Windows.Forms.Panel
    $detailsPanel.Location = New-Object System.Drawing.Point(300, 50)
    $detailsPanel.Size = New-Object System.Drawing.Size(550, 500)
    $detailsPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    
    # Nom du mappage
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "Nom:"
    $nameLabel.Location = New-Object System.Drawing.Point(10, 20)
    $nameLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.Location = New-Object System.Drawing.Point(120, 20)
    $nameTextBox.Size = New-Object System.Drawing.Size(400, 20)
    
    # Description
    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Text = "Description:"
    $descriptionLabel.Location = New-Object System.Drawing.Point(10, 50)
    $descriptionLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $descriptionTextBox = New-Object System.Windows.Forms.TextBox
    $descriptionTextBox.Location = New-Object System.Drawing.Point(120, 50)
    $descriptionTextBox.Size = New-Object System.Drawing.Size(400, 20)
    
    # Type de graphique
    $chartTypeLabel = New-Object System.Windows.Forms.Label
    $chartTypeLabel.Text = "Type de graphique:"
    $chartTypeLabel.Location = New-Object System.Drawing.Point(10, 80)
    $chartTypeLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $chartTypeComboBox = New-Object System.Windows.Forms.ComboBox
    $chartTypeComboBox.Location = New-Object System.Drawing.Point(120, 80)
    $chartTypeComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $chartTypeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("PieChart", "BarChart", "LineChart", "RadarChart", "DoughnutChart", "ScatterChart") | ForEach-Object {
        $chartTypeComboBox.Items.Add($_)
    }
    
    # Champ de regroupement
    $groupByLabel = New-Object System.Windows.Forms.Label
    $groupByLabel.Text = "Regrouper par:"
    $groupByLabel.Location = New-Object System.Drawing.Point(10, 110)
    $groupByLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $groupByComboBox = New-Object System.Windows.Forms.ComboBox
    $groupByComboBox.Location = New-Object System.Drawing.Point(120, 110)
    $groupByComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $groupByComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    foreach ($field in $RoadmapFields.Fields) {
        $groupByComboBox.Items.Add($field)
    }
    
    # Champ de valeur
    $valueFieldLabel = New-Object System.Windows.Forms.Label
    $valueFieldLabel.Text = "Champ de valeur:"
    $valueFieldLabel.Location = New-Object System.Drawing.Point(10, 140)
    $valueFieldLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    $valueFieldComboBox = New-Object System.Windows.Forms.ComboBox
    $valueFieldComboBox.Location = New-Object System.Drawing.Point(120, 140)
    $valueFieldComboBox.Size = New-Object System.Drawing.Size(200, 20)
    $valueFieldComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    
    @("Count", "Sum", "Average", "Min", "Max") | ForEach-Object {
        $valueFieldComboBox.Items.Add($_)
    }
    
    # Étiquettes dynamiques
    $dynamicLabelsCheckBox = New-Object System.Windows.Forms.CheckBox
    $dynamicLabelsCheckBox.Text = "Étiquettes dynamiques"
    $dynamicLabelsCheckBox.Location = New-Object System.Drawing.Point(10, 170)
    $dynamicLabelsCheckBox.Size = New-Object System.Drawing.Size(200, 20)
    
    # Couleurs dynamiques
    $dynamicColorsCheckBox = New-Object System.Windows.Forms.CheckBox
    $dynamicColorsCheckBox.Text = "Couleurs dynamiques"
    $dynamicColorsCheckBox.Location = New-Object System.Drawing.Point(10, 200)
    $dynamicColorsCheckBox.Size = New-Object System.Drawing.Size(200, 20)
    
    # Mappages d'étiquettes et de couleurs
    $labelsColorsLabel = New-Object System.Windows.Forms.Label
    $labelsColorsLabel.Text = "Mappages d'étiquettes et de couleurs:"
    $labelsColorsLabel.Location = New-Object System.Drawing.Point(10, 230)
    $labelsColorsLabel.Size = New-Object System.Drawing.Size(250, 20)
    
    $labelsColorsDataGridView = New-Object System.Windows.Forms.DataGridView
    $labelsColorsDataGridView.Location = New-Object System.Drawing.Point(10, 260)
    $labelsColorsDataGridView.Size = New-Object System.Drawing.Size(530, 200)
    $labelsColorsDataGridView.AutoGenerateColumns = $false
    $labelsColorsDataGridView.AllowUserToAddRows = $true
    $labelsColorsDataGridView.AllowUserToDeleteRows = $true
    
    $valueColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $valueColumn.HeaderText = "Valeur"
    $valueColumn.Name = "Value"
    $valueColumn.Width = 150
    
    $labelColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $labelColumn.HeaderText = "Étiquette"
    $labelColumn.Name = "Label"
    $labelColumn.Width = 150
    
    $colorColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colorColumn.HeaderText = "Couleur"
    $colorColumn.Name = "Color"
    $colorColumn.Width = 150
    
    $labelsColorsDataGridView.Columns.Add($valueColumn)
    $labelsColorsDataGridView.Columns.Add($labelColumn)
    $labelsColorsDataGridView.Columns.Add($colorColumn)
    
    # Ajouter les contrôles au panneau de détails
    $detailsPanel.Controls.Add($nameLabel)
    $detailsPanel.Controls.Add($nameTextBox)
    $detailsPanel.Controls.Add($descriptionLabel)
    $detailsPanel.Controls.Add($descriptionTextBox)
    $detailsPanel.Controls.Add($chartTypeLabel)
    $detailsPanel.Controls.Add($chartTypeComboBox)
    $detailsPanel.Controls.Add($groupByLabel)
    $detailsPanel.Controls.Add($groupByComboBox)
    $detailsPanel.Controls.Add($valueFieldLabel)
    $detailsPanel.Controls.Add($valueFieldComboBox)
    $detailsPanel.Controls.Add($dynamicLabelsCheckBox)
    $detailsPanel.Controls.Add($dynamicColorsCheckBox)
    $detailsPanel.Controls.Add($labelsColorsLabel)
    $detailsPanel.Controls.Add($labelsColorsDataGridView)
    
    # Boutons d'action
    $addButton = New-Object System.Windows.Forms.Button
    $addButton.Text = "Ajouter"
    $addButton.Location = New-Object System.Drawing.Point(20, 260)
    $addButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Text = "Supprimer"
    $removeButton.Location = New-Object System.Drawing.Point(105, 260)
    $removeButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = "Enregistrer"
    $saveButton.Location = New-Object System.Drawing.Point(190, 260)
    $saveButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Boutons OK/Annuler
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(700, 600)
    $okButton.Size = New-Object System.Drawing.Size(75, 30)
    
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Annuler"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(800, 600)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 30)
    
    # Événement de sélection de mappage
    $mappingsListBox.Add_SelectedIndexChanged({
        if ($mappingsListBox.SelectedIndex -ge 0) {
            $selectedMapping = $Mapping.Mappings[$mappingsListBox.SelectedIndex]
            
            $nameTextBox.Text = $selectedMapping.Name
            $descriptionTextBox.Text = $selectedMapping.Description
            $chartTypeComboBox.SelectedItem = $selectedMapping.Type
            $groupByComboBox.SelectedItem = $selectedMapping.GroupBy
            $valueFieldComboBox.SelectedItem = $selectedMapping.ValueField
            $dynamicLabelsCheckBox.Checked = $selectedMapping.DynamicLabels -eq $true
            $dynamicColorsCheckBox.Checked = $selectedMapping.DynamicColors -eq $true
            
            # Remplir la grille d'étiquettes et de couleurs
            $labelsColorsDataGridView.Rows.Clear()
            
            if ($selectedMapping.Labels -and $selectedMapping.Colors) {
                foreach ($key in $selectedMapping.Labels.PSObject.Properties.Name) {
                    $label = $selectedMapping.Labels.$key
                    $color = $selectedMapping.Colors.$key
                    
                    $labelsColorsDataGridView.Rows.Add($key, $label, $color)
                }
            }
        }
    })
    
    # Événement d'ajout de mappage
    $addButton.Add_Click({
        $newMapping = @{
            Name = "Nouveau mappage"
            Description = "Description du nouveau mappage"
            Type = "PieChart"
            DataSource = "RoadmapTasks"
            GroupBy = "Status"
            ValueField = "Count"
            DynamicLabels = $false
            DynamicColors = $false
            Labels = @{}
            Colors = @{}
            TemplateVariables = @{}
        }
        
        $Mapping.Mappings += $newMapping
        $mappingsListBox.Items.Add($newMapping.Name)
        $mappingsListBox.SelectedIndex = $mappingsListBox.Items.Count - 1
    })
    
    # Événement de suppression de mappage
    $removeButton.Add_Click({
        if ($mappingsListBox.SelectedIndex -ge 0) {
            $index = $mappingsListBox.SelectedIndex
            $Mapping.Mappings = $Mapping.Mappings | Where-Object { $_ -ne $Mapping.Mappings[$index] }
            $mappingsListBox.Items.RemoveAt($index)
            
            if ($mappingsListBox.Items.Count -gt 0) {
                $mappingsListBox.SelectedIndex = [Math]::Min($index, $mappingsListBox.Items.Count - 1)
            }
        }
    })
    
    # Événement d'enregistrement de mappage
    $saveButton.Add_Click({
        if ($mappingsListBox.SelectedIndex -ge 0) {
            $index = $mappingsListBox.SelectedIndex
            
            $Mapping.Mappings[$index].Name = $nameTextBox.Text
            $Mapping.Mappings[$index].Description = $descriptionTextBox.Text
            $Mapping.Mappings[$index].Type = $chartTypeComboBox.SelectedItem
            $Mapping.Mappings[$index].GroupBy = $groupByComboBox.SelectedItem
            $Mapping.Mappings[$index].ValueField = $valueFieldComboBox.SelectedItem
            $Mapping.Mappings[$index].DynamicLabels = $dynamicLabelsCheckBox.Checked
            $Mapping.Mappings[$index].DynamicColors = $dynamicColorsCheckBox.Checked
            
            # Mettre à jour les étiquettes et les couleurs
            $labels = @{}
            $colors = @{}
            
            foreach ($row in $labelsColorsDataGridView.Rows) {
                if (-not [string]::IsNullOrEmpty($row.Cells[0].Value)) {
                    $value = $row.Cells[0].Value
                    $label = $row.Cells[1].Value
                    $color = $row.Cells[2].Value
                    
                    if (-not [string]::IsNullOrEmpty($label)) {
                        $labels[$value] = $label
                    }
                    
                    if (-not [string]::IsNullOrEmpty($color)) {
                        $colors[$value] = $color
                    }
                }
            }
            
            $Mapping.Mappings[$index].Labels = $labels
            $Mapping.Mappings[$index].Colors = $colors
            
            # Mettre à jour les variables de template
            $templateVariables = @{}
            $groupBy = $groupByComboBox.SelectedItem
            
            foreach ($key in $labels.Keys) {
                $variableName = "tasks_" + $key.ToLower()
                $templateVariables[$variableName] = "{{COUNT:$groupBy=$key}}"
                
                $percentageVariableName = "percentage_" + $key.ToLower()
                $templateVariables[$percentageVariableName] = "{{PERCENTAGE:$groupBy=$key}}"
            }
            
            if ($dynamicLabelsCheckBox.Checked) {
                $templateVariables["labels"] = "{{LABELS:$groupBy}}"
                $templateVariables["values"] = "{{VALUES:$groupBy}}"
            }
            
            if ($dynamicColorsCheckBox.Checked) {
                $templateVariables["colors"] = "{{COLORS:$groupBy}}"
            }
            
            $Mapping.Mappings[$index].TemplateVariables = $templateVariables
            
            # Mettre à jour l'élément dans la liste
            $mappingsListBox.Items[$index] = $nameTextBox.Text
        }
    })
    
    # Ajouter les contrôles au formulaire
    $form.Controls.Add($mappingsLabel)
    $form.Controls.Add($mappingsListBox)
    $form.Controls.Add($detailsPanel)
    $form.Controls.Add($addButton)
    $form.Controls.Add($removeButton)
    $form.Controls.Add($saveButton)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)
    
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    
    # Sélectionner le premier mappage par défaut
    if ($mappingsListBox.Items.Count -gt 0) {
        $mappingsListBox.SelectedIndex = 0
    }
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $Mapping.ModifiedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        return $Mapping
    } else {
        return $null
    }
}

# Fonction principale
function Edit-DataMapping {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$MappingPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath
    )
    
    # Charger le mappage existant ou créer un nouveau
    $mapping = Get-DataMapping -MappingPath $MappingPath
    
    if ($null -eq $mapping) {
        Write-Log "Creating new data mapping" -Level "Info"
        $mapping = Get-DataMapping
    } else {
        Write-Log "Loaded existing data mapping" -Level "Info"
    }
    
    # Extraire les champs disponibles à partir du fichier de roadmap
    $roadmapFields = Get-RoadmapFields -RoadmapPath $RoadmapPath
    
    # Afficher l'interface utilisateur de mappage
    $updatedMapping = Show-MappingUI -Mapping $mapping -RoadmapFields $roadmapFields
    
    if ($null -eq $updatedMapping) {
        Write-Log "Data mapping cancelled by user" -Level "Info"
        return $null
    }
    
    # Sauvegarder le mappage
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $updatedMapping | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-Log "Data mapping saved to: $OutputPath" -Level "Info"
        } catch {
            Write-Log "Error saving data mapping: $_" -Level "Error"
        }
    }
    
    return $updatedMapping
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Edit-DataMapping -MappingPath $MappingPath -OutputPath $OutputPath -RoadmapPath $RoadmapPath
}
