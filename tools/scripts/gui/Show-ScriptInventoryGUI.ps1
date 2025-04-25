#Requires -Version 5.1
<#
.SYNOPSIS
    Interface graphique pour visualiser l'inventaire des scripts
.DESCRIPTION
    Ce script fournit une interface graphique WPF pour visualiser l'inventaire des scripts,
    avec des filtres interactifs et des fonctionnalités d'export.
.PARAMETER Path
    Chemin du répertoire à analyser
.PARAMETER Update
    Indique s'il faut mettre à jour l'inventaire avant de l'afficher
.EXAMPLE
    .\Show-ScriptInventoryGUI.ps1 -Path "C:\Scripts" -Update
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: gui, inventaire, scripts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,
    
    [Parameter(Mandatory = $false)]
    [switch]$Update
)

# Importer les modules nécessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Mettre à jour l'inventaire si demandé
if ($Update) {
    Update-ScriptInventory -Path $Path
}

# Définir l'interface XAML
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Inventaire des Scripts" Height="700" Width="1000" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="5" />
            <Setter Property="Padding" Value="10,5" />
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Margin" Value="5" />
            <Setter Property="Padding" Value="5" />
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Margin" Value="5" />
            <Setter Property="Padding" Value="5" />
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="Margin" Value="5" />
            <Setter Property="AutoGenerateColumns" Value="False" />
            <Setter Property="IsReadOnly" Value="True" />
            <Setter Property="AlternatingRowBackground" Value="#f0f0f0" />
            <Setter Property="CanUserSortColumns" Value="True" />
            <Setter Property="CanUserResizeColumns" Value="True" />
            <Setter Property="CanUserReorderColumns" Value="True" />
            <Setter Property="GridLinesVisibility" Value="Horizontal" />
            <Setter Property="HeadersVisibility" Value="Column" />
            <Setter Property="BorderBrush" Value="#ddd" />
            <Setter Property="BorderThickness" Value="1" />
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        
        <!-- Barre d'outils -->
        <ToolBar Grid.Row="0">
            <Button x:Name="btnUpdate" Content="Mettre à jour l'inventaire" />
            <Separator />
            <Button x:Name="btnExportCSV" Content="Exporter en CSV" />
            <Button x:Name="btnExportJSON" Content="Exporter en JSON" />
            <Button x:Name="btnExportHTML" Content="Exporter en HTML" />
            <Separator />
            <Button x:Name="btnAnalyzeSimilarity" Content="Analyser la similarité" />
            <Button x:Name="btnShowStatistics" Content="Afficher les statistiques" />
        </ToolBar>
        
        <!-- Filtres -->
        <Grid Grid.Row="1" Margin="5">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>
            
            <Label Grid.Column="0" Content="Nom:" VerticalAlignment="Center" />
            <TextBox Grid.Column="1" x:Name="txtFilterName" />
            
            <Label Grid.Column="2" Content="Auteur:" VerticalAlignment="Center" />
            <TextBox Grid.Column="3" x:Name="txtFilterAuthor" />
            
            <Label Grid.Column="4" Content="Langage:" VerticalAlignment="Center" />
            <ComboBox Grid.Column="5" x:Name="cmbFilterLanguage" />
            
            <Button Grid.Column="6" x:Name="btnApplyFilters" Content="Appliquer les filtres" />
        </Grid>
        
        <!-- Liste des scripts -->
        <DataGrid Grid.Row="2" x:Name="dgScripts">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Nom" Binding="{Binding FileName}" Width="200" />
                <DataGridTextColumn Header="Chemin" Binding="{Binding FullPath}" Width="300" />
                <DataGridTextColumn Header="Langage" Binding="{Binding Language}" Width="100" />
                <DataGridTextColumn Header="Auteur" Binding="{Binding Author}" Width="100" />
                <DataGridTextColumn Header="Version" Binding="{Binding Version}" Width="80" />
                <DataGridTextColumn Header="Catégorie" Binding="{Binding Category}" Width="100" />
                <DataGridTextColumn Header="Sous-catégorie" Binding="{Binding SubCategory}" Width="120" />
                <DataGridTextColumn Header="Lignes" Binding="{Binding LineCount}" Width="60" />
                <DataGridTextColumn Header="Dernière modification" Binding="{Binding LastModified}" Width="150" />
            </DataGrid.Columns>
        </DataGrid>
        
        <!-- Détails du script sélectionné -->
        <GroupBox Grid.Row="3" Header="Détails du script sélectionné" Margin="5">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                </Grid.ColumnDefinitions>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                </Grid.RowDefinitions>
                
                <Label Grid.Row="0" Grid.Column="0" Content="Nom:" FontWeight="Bold" />
                <TextBlock Grid.Row="0" Grid.Column="1" x:Name="txtDetailName" Margin="5" />
                
                <Label Grid.Row="0" Grid.Column="2" Content="Langage:" FontWeight="Bold" />
                <TextBlock Grid.Row="0" Grid.Column="3" x:Name="txtDetailLanguage" Margin="5" />
                
                <Label Grid.Row="1" Grid.Column="0" Content="Auteur:" FontWeight="Bold" />
                <TextBlock Grid.Row="1" Grid.Column="1" x:Name="txtDetailAuthor" Margin="5" />
                
                <Label Grid.Row="1" Grid.Column="2" Content="Version:" FontWeight="Bold" />
                <TextBlock Grid.Row="1" Grid.Column="3" x:Name="txtDetailVersion" Margin="5" />
                
                <Label Grid.Row="2" Grid.Column="0" Content="Description:" FontWeight="Bold" />
                <TextBlock Grid.Row="2" Grid.Column="1" Grid.ColumnSpan="3" x:Name="txtDetailDescription" Margin="5" TextWrapping="Wrap" />
            </Grid>
        </GroupBox>
        
        <!-- Barre de statut -->
        <StatusBar Grid.Row="4">
            <StatusBarItem>
                <TextBlock x:Name="txtStatus" Text="Prêt" />
            </StatusBarItem>
        </StatusBar>
    </Grid>
</Window>
"@

# Charger le XAML
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Récupérer les éléments de l'interface
$btnUpdate = $window.FindName("btnUpdate")
$btnExportCSV = $window.FindName("btnExportCSV")
$btnExportJSON = $window.FindName("btnExportJSON")
$btnExportHTML = $window.FindName("btnExportHTML")
$btnAnalyzeSimilarity = $window.FindName("btnAnalyzeSimilarity")
$btnShowStatistics = $window.FindName("btnShowStatistics")
$txtFilterName = $window.FindName("txtFilterName")
$txtFilterAuthor = $window.FindName("txtFilterAuthor")
$cmbFilterLanguage = $window.FindName("cmbFilterLanguage")
$btnApplyFilters = $window.FindName("btnApplyFilters")
$dgScripts = $window.FindName("dgScripts")
$txtDetailName = $window.FindName("txtDetailName")
$txtDetailLanguage = $window.FindName("txtDetailLanguage")
$txtDetailAuthor = $window.FindName("txtDetailAuthor")
$txtDetailVersion = $window.FindName("txtDetailVersion")
$txtDetailDescription = $window.FindName("txtDetailDescription")
$txtStatus = $window.FindName("txtStatus")

# Fonction pour charger les scripts
function Load-Scripts {
    param (
        [string]$nameFilter = "",
        [string]$authorFilter = "",
        [string]$languageFilter = ""
    )
    
    $txtStatus.Text = "Chargement des scripts..."
    
    # Récupérer les scripts
    $scripts = Get-ScriptInventory
    
    # Appliquer les filtres
    if ($nameFilter) {
        $scripts = $scripts | Where-Object { $_.FileName -like "*$nameFilter*" }
    }
    
    if ($authorFilter) {
        $scripts = $scripts | Where-Object { $_.Author -like "*$authorFilter*" }
    }
    
    if ($languageFilter -and $languageFilter -ne "Tous") {
        $scripts = $scripts | Where-Object { $_.Language -eq $languageFilter }
    }
    
    # Mettre à jour la liste
    $dgScripts.ItemsSource = $scripts
    
    # Mettre à jour le statut
    $txtStatus.Text = "Nombre de scripts: $($scripts.Count)"
}

# Fonction pour mettre à jour les détails du script sélectionné
function Update-ScriptDetails {
    $script = $dgScripts.SelectedItem
    
    if ($script) {
        $txtDetailName.Text = $script.FileName
        $txtDetailLanguage.Text = $script.Language
        $txtDetailAuthor.Text = $script.Author
        $txtDetailVersion.Text = $script.Version
        $txtDetailDescription.Text = $script.Description
    } else {
        $txtDetailName.Text = ""
        $txtDetailLanguage.Text = ""
        $txtDetailAuthor.Text = ""
        $txtDetailVersion.Text = ""
        $txtDetailDescription.Text = ""
    }
}

# Fonction pour exporter les scripts
function Export-Scripts {
    param (
        [string]$format
    )
    
    $scripts = $dgScripts.ItemsSource
    
    if (-not $scripts -or $scripts.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun script à exporter.", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    # Créer le répertoire de rapports s'il n'existe pas
    $reportsDir = Join-Path -Path $Path -ChildPath "reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    switch ($format) {
        "CSV" {
            $outputPath = Join-Path -Path $reportsDir -ChildPath "script_inventory_$timestamp.csv"
            $scripts | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
        }
        "JSON" {
            $outputPath = Join-Path -Path $reportsDir -ChildPath "script_inventory_$timestamp.json"
            $scripts | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8
        }
        "HTML" {
            $outputPath = Join-Path -Path $reportsDir -ChildPath "script_inventory_$timestamp.html"
            Export-ScriptInventory -Path $outputPath -Format "HTML"
        }
    }
    
    $txtStatus.Text = "Rapport exporté: $outputPath"
    
    # Demander à l'utilisateur s'il veut ouvrir le rapport
    $result = [System.Windows.MessageBox]::Show("Rapport exporté avec succès. Voulez-vous l'ouvrir?", "Export terminé", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Start-Process $outputPath
    }
}

# Événement: Mise à jour de l'inventaire
$btnUpdate.Add_Click({
    $txtStatus.Text = "Mise à jour de l'inventaire..."
    Update-ScriptInventory -Path $Path
    Load-Scripts
    $txtStatus.Text = "Inventaire mis à jour."
})

# Événement: Export CSV
$btnExportCSV.Add_Click({
    Export-Scripts -format "CSV"
})

# Événement: Export JSON
$btnExportJSON.Add_Click({
    Export-Scripts -format "JSON"
})

# Événement: Export HTML
$btnExportHTML.Add_Click({
    Export-Scripts -format "HTML"
})

# Événement: Analyser la similarité
$btnAnalyzeSimilarity.Add_Click({
    $analyzeScript = Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\Analyze-ScriptSimilarity.ps1"
    
    if (Test-Path $analyzeScript) {
        $txtStatus.Text = "Lancement de l'analyse de similarité..."
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$analyzeScript`" -Path `"$Path`" -OutputFormat HTML"
    } else {
        [System.Windows.MessageBox]::Show("Script d'analyse de similarité non trouvé: $analyzeScript", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# Événement: Afficher les statistiques
$btnShowStatistics.Add_Click({
    $statisticsScript = Join-Path -Path $PSScriptRoot -ChildPath "Show-ScriptStatistics.ps1"
    
    if (Test-Path $statisticsScript) {
        $txtStatus.Text = "Lancement des statistiques..."
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$statisticsScript`" -Path `"$Path`""
    } else {
        [System.Windows.MessageBox]::Show("Script de statistiques non trouvé: $statisticsScript", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# Événement: Appliquer les filtres
$btnApplyFilters.Add_Click({
    Load-Scripts -nameFilter $txtFilterName.Text -authorFilter $txtFilterAuthor.Text -languageFilter $cmbFilterLanguage.SelectedItem
})

# Événement: Sélection d'un script
$dgScripts.Add_SelectionChanged({
    Update-ScriptDetails
})

# Initialiser l'interface
$txtStatus.Text = "Chargement des langages..."

# Charger les langages
$scripts = Get-ScriptInventory
$languages = $scripts | Select-Object -ExpandProperty Language -Unique | Sort-Object
$cmbFilterLanguage.Items.Add("Tous") | Out-Null
$cmbFilterLanguage.SelectedIndex = 0

foreach ($language in $languages) {
    $cmbFilterLanguage.Items.Add($language) | Out-Null
}

# Charger les scripts
Load-Scripts

# Afficher la fenêtre
$window.ShowDialog() | Out-Null
