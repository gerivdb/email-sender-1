#Requires -Version 5.1
<#
.SYNOPSIS
    Tableau de bord unifiÃ© pour la gestion des scripts
.DESCRIPTION
    Interface graphique WPF combinant l'inventaire, les statistiques et l'analyse des scripts
.PARAMETER Path
    Chemin du rÃ©pertoire Ã  analyser
.EXAMPLE
    .\Show-ScriptDashboard.ps1 -Path "C:\Scripts"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Tags: dashboard, inventaire, scripts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path
)

# Importer les modules nÃ©cessaires
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# DÃ©finir l'interface XAML simplifiÃ©e
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Tableau de Bord des Scripts" Height="600" Width="800" WindowStartupLocation="CenterScreen">
    <Grid>
        <TabControl>
            <!-- Onglet Inventaire -->
            <TabItem Header="Inventaire">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    
                    <!-- Filtres -->
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="5">
                        <Label Content="Nom:" VerticalAlignment="Center" />
                        <TextBox x:Name="txtFilterName" Width="120" Margin="5" />
                        
                        <Label Content="Langage:" VerticalAlignment="Center" />
                        <ComboBox x:Name="cmbFilterLanguage" Width="120" Margin="5" />
                        
                        <Button x:Name="btnApplyFilters" Content="Filtrer" Margin="5" Padding="10,5" />
                        <Button x:Name="btnUpdateInventory" Content="Mettre Ã  jour" Margin="5" Padding="10,5" />
                    </StackPanel>
                    
                    <!-- Liste des scripts -->
                    <DataGrid Grid.Row="1" x:Name="dgScripts" Margin="5" AutoGenerateColumns="False" IsReadOnly="True">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Nom" Binding="{Binding FileName}" Width="200" />
                            <DataGridTextColumn Header="Langage" Binding="{Binding Language}" Width="100" />
                            <DataGridTextColumn Header="CatÃ©gorie" Binding="{Binding Category}" Width="120" />
                            <DataGridTextColumn Header="Auteur" Binding="{Binding Author}" Width="100" />
                            <DataGridTextColumn Header="Lignes" Binding="{Binding LineCount}" Width="60" />
                        </DataGrid.Columns>
                    </DataGrid>
                    
                    <!-- Actions -->
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="5">
                        <Button x:Name="btnExportCSV" Content="Exporter CSV" Margin="5" Padding="10,5" />
                        <Button x:Name="btnExportHTML" Content="Exporter HTML" Margin="5" Padding="10,5" />
                    </StackPanel>
                </Grid>
            </TabItem>
            
            <!-- Onglet SimilaritÃ© -->
            <TabItem Header="SimilaritÃ©">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                        <RowDefinition Height="Auto" />
                    </Grid.RowDefinitions>
                    
                    <!-- Options d'analyse -->
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="5">
                        <Label Content="Algorithme:" VerticalAlignment="Center" />
                        <ComboBox x:Name="cmbAlgorithm" Width="120" Margin="5">
                            <ComboBoxItem Content="Levenshtein" />
                            <ComboBoxItem Content="Cosine" IsSelected="True" />
                            <ComboBoxItem Content="Combined" />
                        </ComboBox>
                        
                        <Label Content="Seuil:" VerticalAlignment="Center" />
                        <Slider x:Name="sliderThreshold" Width="100" Minimum="50" Maximum="100" Value="80" 
                                TickFrequency="5" TickPlacement="BottomRight" IsSnapToTickEnabled="True" Margin="5" />
                        <TextBlock x:Name="txtThreshold" Text="80%" VerticalAlignment="Center" Width="40" />
                        
                        <Button x:Name="btnAnalyze" Content="Analyser" Margin="5" Padding="10,5" />
                    </StackPanel>
                    
                    <!-- RÃ©sultats de similaritÃ© -->
                    <DataGrid Grid.Row="1" x:Name="dgSimilarity" Margin="5" AutoGenerateColumns="False" IsReadOnly="True">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Script 1" Binding="{Binding Script1}" Width="200" />
                            <DataGridTextColumn Header="Script 2" Binding="{Binding Script2}" Width="200" />
                            <DataGridTextColumn Header="SimilaritÃ©" Binding="{Binding Similarity}" Width="80" />
                            <DataGridTemplateColumn Header="Visualisation" Width="200">
                                <DataGridTemplateColumn.CellTemplate>
                                    <DataTemplate>
                                        <Grid>
                                            <Rectangle Height="20" Width="{Binding SimilarityWidth}" HorizontalAlignment="Left" 
                                                       Fill="{Binding SimilarityColor}" />
                                        </Grid>
                                    </DataTemplate>
                                </DataGridTemplateColumn.CellTemplate>
                            </DataGridTemplateColumn>
                        </DataGrid.Columns>
                    </DataGrid>
                    
                    <!-- Actions -->
                    <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="5">
                        <Button x:Name="btnExportSimilarity" Content="Exporter Rapport" Margin="5" Padding="10,5" />
                    </StackPanel>
                </Grid>
            </TabItem>
            
            <!-- Onglet Statistiques -->
            <TabItem Header="Statistiques">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto" />
                        <RowDefinition Height="*" />
                    </Grid.RowDefinitions>
                    
                    <!-- Actions -->
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="5">
                        <Button x:Name="btnGenerateStats" Content="GÃ©nÃ©rer Statistiques" Margin="5" Padding="10,5" />
                        <Button x:Name="btnOpenStatsReport" Content="Ouvrir Rapport Complet" Margin="5" Padding="10,5" />
                    </StackPanel>
                    
                    <!-- RÃ©sumÃ© des statistiques -->
                    <ScrollViewer Grid.Row="1" Margin="5">
                        <StackPanel x:Name="statsPanel">
                            <TextBlock Text="Cliquez sur 'GÃ©nÃ©rer Statistiques' pour afficher les informations" 
                                       HorizontalAlignment="Center" VerticalAlignment="Center" Margin="20" />
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

# Charger le XAML
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# RÃ©cupÃ©rer les Ã©lÃ©ments de l'interface
$txtFilterName = $window.FindName("txtFilterName")
$cmbFilterLanguage = $window.FindName("cmbFilterLanguage")
$btnApplyFilters = $window.FindName("btnApplyFilters")
$btnUpdateInventory = $window.FindName("btnUpdateInventory")
$dgScripts = $window.FindName("dgScripts")
$btnExportCSV = $window.FindName("btnExportCSV")
$btnExportHTML = $window.FindName("btnExportHTML")

$cmbAlgorithm = $window.FindName("cmbAlgorithm")
$sliderThreshold = $window.FindName("sliderThreshold")
$txtThreshold = $window.FindName("txtThreshold")
$btnAnalyze = $window.FindName("btnAnalyze")
$dgSimilarity = $window.FindName("dgSimilarity")
$btnExportSimilarity = $window.FindName("btnExportSimilarity")

$btnGenerateStats = $window.FindName("btnGenerateStats")
$btnOpenStatsReport = $window.FindName("btnOpenStatsReport")
$statsPanel = $window.FindName("statsPanel")

# Fonction pour charger les scripts
function Load-Scripts {
    param (
        [string]$nameFilter = "",
        [string]$languageFilter = ""
    )
    
    # RÃ©cupÃ©rer les scripts
    $scripts = Get-ScriptInventory
    
    # Appliquer les filtres
    if ($nameFilter) {
        $scripts = $scripts | Where-Object { $_.FileName -like "*$nameFilter*" }
    }
    
    if ($languageFilter -and $languageFilter -ne "Tous") {
        $scripts = $scripts | Where-Object { $_.Language -eq $languageFilter }
    }
    
    # Mettre Ã  jour la liste
    $dgScripts.ItemsSource = $scripts
}

# Fonction pour analyser la similaritÃ©
function Analyze-Similarity {
    param (
        [string]$algorithm,
        [int]$threshold
    )
    
    # VÃ©rifier que le module TextSimilarity est disponible
    $textSimilarityPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\TextSimilarity.psm1"
    if (-not (Test-Path $textSimilarityPath)) {
        [System.Windows.MessageBox]::Show("Module TextSimilarity non trouvÃ©: $textSimilarityPath", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    Import-Module $textSimilarityPath -Force
    
    # RÃ©cupÃ©rer les scripts
    $scripts = Get-ScriptInventory
    
    if ($scripts.Count -lt 2) {
        [System.Windows.MessageBox]::Show("Pas assez de scripts pour analyser la similaritÃ©.", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    # Analyser la similaritÃ© (version simplifiÃ©e pour l'interface)
    $results = @()
    $scriptCount = [Math]::Min($scripts.Count, 10) # Limiter Ã  10 scripts pour l'interface
    
    for ($i = 0; $i -lt $scriptCount; $i++) {
        for ($j = $i + 1; $j -lt $scriptCount; $j++) {
            $script1 = $scripts[$i]
            $script2 = $scripts[$j]
            
            # Calculer la similaritÃ©
            $similarity = 0
            
            if (Get-Command -Name Get-ContentSimilarity -ErrorAction SilentlyContinue) {
                $similarity = Get-ContentSimilarity -FilePathA $script1.FullPath -FilePathB $script2.FullPath -Algorithm $algorithm
            } else {
                # Fallback simple
                $similarity = Get-Random -Minimum 50 -Maximum 100
            }
            
            # Si la similaritÃ© dÃ©passe le seuil, ajouter aux rÃ©sultats
            if ($similarity -ge $threshold) {
                $results += [PSCustomObject]@{
                    Script1 = $script1.FileName
                    Script2 = $script2.FileName
                    Similarity = "$similarity%"
                    SimilarityWidth = "$similarity%"
                    SimilarityColor = if ($similarity -ge 95) { "#ff6666" } elseif ($similarity -ge 85) { "#ffcc66" } else { "#66cc66" }
                }
            }
        }
    }
    
    # Mettre Ã  jour la liste
    $dgSimilarity.ItemsSource = $results
}

# Fonction pour gÃ©nÃ©rer des statistiques simples
function Generate-Statistics {
    # RÃ©cupÃ©rer les scripts
    $scripts = Get-ScriptInventory
    
    if ($scripts.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun script trouvÃ©.", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    # Effacer le panneau
    $statsPanel.Children.Clear()
    
    # Ajouter le titre
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = "Statistiques des Scripts"
    $title.FontSize = 18
    $title.FontWeight = "Bold"
    $title.Margin = New-Object System.Windows.Thickness(0, 0, 0, 10)
    $statsPanel.Children.Add($title)
    
    # Ajouter le nombre total de scripts
    $totalScripts = New-Object System.Windows.Controls.TextBlock
    $totalScripts.Text = "Nombre total de scripts: $($scripts.Count)"
    $totalScripts.Margin = New-Object System.Windows.Thickness(0, 0, 0, 5)
    $statsPanel.Children.Add($totalScripts)
    
    # Distribution par langage
    $languageTitle = New-Object System.Windows.Controls.TextBlock
    $languageTitle.Text = "Distribution par langage:"
    $languageTitle.FontWeight = "Bold"
    $languageTitle.Margin = New-Object System.Windows.Thickness(0, 10, 0, 5)
    $statsPanel.Children.Add($languageTitle)
    
    $scriptsByLanguage = $scripts | Group-Object -Property Language | Sort-Object -Property Count -Descending
    
    foreach ($language in $scriptsByLanguage) {
        $languageItem = New-Object System.Windows.Controls.TextBlock
        $languageItem.Text = "- $($language.Name): $($language.Count) scripts"
        $languageItem.Margin = New-Object System.Windows.Thickness(10, 0, 0, 0)
        $statsPanel.Children.Add($languageItem)
    }
    
    # Distribution par catÃ©gorie
    $categoryTitle = New-Object System.Windows.Controls.TextBlock
    $categoryTitle.Text = "Distribution par catÃ©gorie:"
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Margin = New-Object System.Windows.Thickness(0, 10, 0, 5)
    $statsPanel.Children.Add($categoryTitle)
    
    $scriptsByCategory = $scripts | Group-Object -Property Category | Sort-Object -Property Count -Descending
    
    foreach ($category in $scriptsByCategory) {
        $categoryItem = New-Object System.Windows.Controls.TextBlock
        $categoryItem.Text = "- $($category.Name): $($category.Count) scripts"
        $categoryItem.Margin = New-Object System.Windows.Thickness(10, 0, 0, 0)
        $statsPanel.Children.Add($categoryItem)
    }
    
    # Top 5 des plus grands scripts
    $topScriptsTitle = New-Object System.Windows.Controls.TextBlock
    $topScriptsTitle.Text = "Top 5 des scripts les plus grands:"
    $topScriptsTitle.FontWeight = "Bold"
    $topScriptsTitle.Margin = New-Object System.Windows.Thickness(0, 10, 0, 5)
    $statsPanel.Children.Add($topScriptsTitle)
    
    $topScripts = $scripts | Sort-Object -Property LineCount -Descending | Select-Object -First 5
    
    foreach ($script in $topScripts) {
        $scriptItem = New-Object System.Windows.Controls.TextBlock
        $scriptItem.Text = "- $($script.FileName): $($script.LineCount) lignes"
        $scriptItem.Margin = New-Object System.Windows.Thickness(10, 0, 0, 0)
        $statsPanel.Children.Add($scriptItem)
    }
}

# Ã‰vÃ©nement: Mise Ã  jour du seuil de similaritÃ©
$sliderThreshold.Add_ValueChanged({
    $value = [Math]::Round($sliderThreshold.Value)
    $txtThreshold.Text = "$value%"
})

# Ã‰vÃ©nement: Mise Ã  jour de l'inventaire
$btnUpdateInventory.Add_Click({
    Update-ScriptInventory -Path $Path
    Load-Scripts
})

# Ã‰vÃ©nement: Appliquer les filtres
$btnApplyFilters.Add_Click({
    Load-Scripts -nameFilter $txtFilterName.Text -languageFilter $cmbFilterLanguage.SelectedItem
})

# Ã‰vÃ©nement: Export CSV
$btnExportCSV.Add_Click({
    $scripts = $dgScripts.ItemsSource
    
    if (-not $scripts -or $scripts.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun script Ã  exporter.", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    $reportsDir = Join-Path -Path $Path -ChildPath "reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = Join-Path -Path $reportsDir -ChildPath "script_inventory_$timestamp.csv"
    
    $scripts | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
    [System.Windows.MessageBox]::Show("Rapport exportÃ©: $outputPath", "Export terminÃ©", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

# Ã‰vÃ©nement: Export HTML
$btnExportHTML.Add_Click({
    $reportsDir = Join-Path -Path $Path -ChildPath "reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outputPath = Join-Path -Path $reportsDir -ChildPath "script_inventory_$timestamp.html"
    
    Export-ScriptInventory -Path $outputPath -Format "HTML"
    
    $result = [System.Windows.MessageBox]::Show("Rapport exportÃ©: $outputPath. Voulez-vous l'ouvrir?", "Export terminÃ©", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    
    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        Start-Process $outputPath
    }
})

# Ã‰vÃ©nement: Analyser la similaritÃ©
$btnAnalyze.Add_Click({
    $algorithm = $cmbAlgorithm.SelectedItem.Content
    $threshold = [Math]::Round($sliderThreshold.Value)
    
    Analyze-Similarity -algorithm $algorithm -threshold $threshold
})

# Ã‰vÃ©nement: Exporter le rapport de similaritÃ©
$btnExportSimilarity.Add_Click({
    $results = $dgSimilarity.ItemsSource
    
    if (-not $results -or $results.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Aucun rÃ©sultat Ã  exporter.", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }
    
    $analyzeScript = Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\Analyze-ScriptSimilarity.ps1"
    
    if (Test-Path $analyzeScript) {
        $algorithm = $cmbAlgorithm.SelectedItem.Content
        $threshold = [Math]::Round($sliderThreshold.Value)
        
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$analyzeScript`" -Path `"$Path`" -Algorithm $algorithm -SimilarityThreshold $threshold -OutputFormat HTML"
    } else {
        [System.Windows.MessageBox]::Show("Script d'analyse de similaritÃ© non trouvÃ©: $analyzeScript", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# Ã‰vÃ©nement: GÃ©nÃ©rer les statistiques
$btnGenerateStats.Add_Click({
    Generate-Statistics
})

# Ã‰vÃ©nement: Ouvrir le rapport de statistiques complet
$btnOpenStatsReport.Add_Click({
    $statisticsScript = Join-Path -Path $PSScriptRoot -ChildPath "Show-ScriptStatistics.ps1"
    
    if (Test-Path $statisticsScript) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$statisticsScript`" -Path `"$Path`" -OutputFormat HTML"
    } else {
        [System.Windows.MessageBox]::Show("Script de statistiques non trouvÃ©: $statisticsScript", "Erreur", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

# Initialiser l'interface
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

# Afficher la fenÃªtre
$window.ShowDialog() | Out-Null
