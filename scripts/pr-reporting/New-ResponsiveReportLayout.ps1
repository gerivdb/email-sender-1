#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un layout responsif pour les rapports d'analyse de pull requests.

.DESCRIPTION
    Ce script génère un layout HTML responsif pour les rapports d'analyse
    de pull requests, avec différentes options de mise en page.

.PARAMETER LayoutType
    Le type de layout à générer.
    Valeurs possibles: "Standard", "Dashboard", "Compact", "Detailed"
    Par défaut: "Standard"

.PARAMETER OutputPath
    Le chemin où enregistrer le fichier de layout généré.
    Par défaut: "templates\layouts\{LayoutType}.html"

.PARAMETER Columns
    Le nombre de colonnes pour les sections principales.
    Valeurs possibles: 1, 2, 3, 4
    Par défaut: 2

.PARAMETER IncludeHeader
    Indique s'il faut inclure un en-tête dans le layout.
    Par défaut: $true

.PARAMETER IncludeFooter
    Indique s'il faut inclure un pied de page dans le layout.
    Par défaut: $true

.PARAMETER IncludeSidebar
    Indique s'il faut inclure une barre latérale dans le layout.
    Par défaut: $false

.PARAMETER SidebarPosition
    La position de la barre latérale.
    Valeurs possibles: "Left", "Right"
    Par défaut: "Left"

.PARAMETER SidebarWidth
    La largeur de la barre latérale en pourcentage.
    Par défaut: 25

.EXAMPLE
    .\New-ResponsiveReportLayout.ps1 -LayoutType "Dashboard" -Columns 3 -IncludeSidebar $true
    Génère un layout de type tableau de bord avec 3 colonnes et une barre latérale.

.EXAMPLE
    .\New-ResponsiveReportLayout.ps1 -LayoutType "Compact" -OutputPath "templates\layouts\custom_compact.html"
    Génère un layout compact et l'enregistre dans un fichier personnalisé.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet("Standard", "Dashboard", "Compact", "Detailed")]
    [string]$LayoutType = "Standard",

    [Parameter()]
    [string]$OutputPath = "",

    [Parameter()]
    [ValidateSet(1, 2, 3, 4)]
    [int]$Columns = 2,

    [Parameter()]
    [bool]$IncludeHeader = $true,

    [Parameter()]
    [bool]$IncludeFooter = $true,

    [Parameter()]
    [bool]$IncludeSidebar = $false,

    [Parameter()]
    [ValidateSet("Left", "Right")]
    [string]$SidebarPosition = "Left",

    [Parameter()]
    [ValidateRange(10, 40)]
    [int]$SidebarWidth = 25
)

# Déterminer le chemin de sortie si non spécifié
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = "templates\layouts\$LayoutType.html"
}

# Créer le répertoire de sortie s'il n'existe pas
$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Définir les styles CSS de base
$baseStyles = @"
:root {
    --primary-color: {{primaryColor}};
    --background-color: {{backgroundColor}};
    --text-color: {{textColor}};
    --border-color: {{borderColor}};
    --card-background: {{cardBackground}};
    --hover-color: {{hoverColor}};
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: Arial, sans-serif;
    background-color: var(--background-color);
    color: var(--text-color);
    line-height: 1.6;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

.card {
    background-color: var(--card-background);
    border: 1px solid var(--border-color);
    border-radius: 5px;
    padding: 20px;
    margin-bottom: 20px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.card-title {
    color: var(--primary-color);
    margin-bottom: 15px;
    font-size: 1.2rem;
    font-weight: bold;
}

.btn {
    display: inline-block;
    padding: 8px 16px;
    background-color: var(--primary-color);
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    text-decoration: none;
    font-size: 14px;
    transition: background-color 0.2s;
}

.btn:hover {
    background-color: var(--hover-color);
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}

table th, table td {
    padding: 10px;
    text-align: left;
    border-bottom: 1px solid var(--border-color);
}

table th {
    background-color: var(--card-background);
    font-weight: bold;
    color: var(--primary-color);
}

table tr:hover {
    background-color: var(--hover-color);
}

.badge {
    display: inline-block;
    padding: 3px 8px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: bold;
    text-transform: uppercase;
}

.badge-error {
    background-color: #f44336;
    color: white;
}

.badge-warning {
    background-color: #ff9800;
    color: white;
}

.badge-info {
    background-color: #2196f3;
    color: white;
}

.badge-success {
    background-color: #4caf50;
    color: white;
}

@media (max-width: 768px) {
    .container {
        padding: 10px;
    }
    
    .card {
        padding: 15px;
    }
    
    table th, table td {
        padding: 8px;
    }
}
"@

# Générer le HTML pour l'en-tête
$headerHtml = if ($IncludeHeader) {
    @"
<header class="header">
    <div class="container">
        <div class="header-content">
            <h1 class="header-title">{{title}}</h1>
            <div class="header-info">
                <span class="header-timestamp">Généré le {{timestamp}}</span>
            </div>
        </div>
    </div>
</header>
<style>
.header {
    background-color: var(--primary-color);
    color: white;
    padding: 15px 0;
    margin-bottom: 30px;
}

.header-content {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.header-title {
    margin: 0;
    font-size: 1.5rem;
}

.header-info {
    font-size: 0.9rem;
    opacity: 0.8;
}

@media (max-width: 768px) {
    .header-content {
        flex-direction: column;
        align-items: flex-start;
    }
    
    .header-info {
        margin-top: 10px;
    }
}
</style>
"@
} else {
    ""
}

# Générer le HTML pour le pied de page
$footerHtml = if ($IncludeFooter) {
    @"
<footer class="footer">
    <div class="container">
        <div class="footer-content">
            <p>Rapport généré par le système d'analyse de pull requests</p>
            <p>Version 1.0 - &copy; 2025</p>
        </div>
    </div>
</footer>
<style>
.footer {
    background-color: var(--card-background);
    border-top: 1px solid var(--border-color);
    padding: 20px 0;
    margin-top: 50px;
    text-align: center;
    font-size: 0.9rem;
    color: #666;
}

.footer-content {
    display: flex;
    flex-direction: column;
    gap: 5px;
}
</style>
"@
} else {
    ""
}

# Générer le HTML pour la barre latérale
$sidebarHtml = if ($IncludeSidebar) {
    $sidebarClass = if ($SidebarPosition -eq "Left") { "sidebar-left" } else { "sidebar-right" }
    $mainWidth = 100 - $SidebarWidth
    
    @"
<div class="layout-with-sidebar $sidebarClass">
    <aside class="sidebar" style="width: $($SidebarWidth)%;">
        <div class="card">
            <div class="card-title">Informations</div>
            <div class="sidebar-content">
                {{sidebar_content}}
            </div>
        </div>
    </aside>
    <main class="main-content" style="width: $($mainWidth)%;">
        {{main_content}}
    </main>
</div>
<style>
.layout-with-sidebar {
    display: flex;
    gap: 20px;
}

.sidebar-left {
    flex-direction: row;
}

.sidebar-right {
    flex-direction: row-reverse;
}

.sidebar {
    flex-shrink: 0;
}

.main-content {
    flex-grow: 1;
}

@media (max-width: 768px) {
    .layout-with-sidebar {
        flex-direction: column;
    }
    
    .sidebar, .main-content {
        width: 100% !important;
    }
}
</style>
"@
} else {
    @"
<main class="main-content">
    {{main_content}}
</main>
"@
}

# Générer le HTML pour les colonnes
$columnsHtml = @"
<div class="grid-layout columns-$Columns">
    {{grid_content}}
</div>
<style>
.grid-layout {
    display: grid;
    gap: 20px;
}

.columns-1 {
    grid-template-columns: 1fr;
}

.columns-2 {
    grid-template-columns: repeat(2, 1fr);
}

.columns-3 {
    grid-template-columns: repeat(3, 1fr);
}

.columns-4 {
    grid-template-columns: repeat(4, 1fr);
}

@media (max-width: 1024px) {
    .columns-4 {
        grid-template-columns: repeat(2, 1fr);
    }
}

@media (max-width: 768px) {
    .columns-3, .columns-4 {
        grid-template-columns: 1fr;
    }
}

@media (max-width: 576px) {
    .grid-layout {
        grid-template-columns: 1fr !important;
    }
}
</style>
"@

# Générer des styles spécifiques au type de layout
$layoutSpecificStyles = switch ($LayoutType) {
    "Dashboard" {
        @"
<style>
.dashboard-card {
    display: flex;
    flex-direction: column;
    height: 100%;
}

.dashboard-card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}

.dashboard-card-title {
    margin: 0;
    font-size: 1.1rem;
    color: var(--primary-color);
}

.dashboard-card-actions {
    display: flex;
    gap: 10px;
}

.dashboard-card-content {
    flex-grow: 1;
}

.dashboard-card-footer {
    margin-top: 15px;
    font-size: 0.9rem;
    color: #666;
    text-align: right;
}

.dashboard-stat {
    text-align: center;
    padding: 20px;
}

.dashboard-stat-value {
    font-size: 2.5rem;
    font-weight: bold;
    color: var(--primary-color);
    margin-bottom: 10px;
}

.dashboard-stat-label {
    font-size: 1rem;
    color: #666;
}
</style>
"@
    }
    "Compact" {
        @"
<style>
.compact-card {
    padding: 15px;
    margin-bottom: 15px;
}

.compact-card-title {
    font-size: 1rem;
    margin-bottom: 10px;
}

.compact-table th, .compact-table td {
    padding: 6px;
    font-size: 0.9rem;
}

.compact-badge {
    padding: 2px 6px;
    font-size: 10px;
}

.compact-btn {
    padding: 6px 12px;
    font-size: 12px;
}
</style>
"@
    }
    "Detailed" {
        @"
<style>
.detailed-section {
    margin-bottom: 30px;
}

.detailed-section-title {
    font-size: 1.3rem;
    color: var(--primary-color);
    margin-bottom: 20px;
    padding-bottom: 10px;
    border-bottom: 1px solid var(--border-color);
}

.detailed-card {
    padding: 25px;
    margin-bottom: 25px;
}

.detailed-card-title {
    font-size: 1.2rem;
    margin-bottom: 20px;
}

.detailed-table th, .detailed-table td {
    padding: 12px;
}

.detailed-info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
    margin-bottom: 20px;
}

.detailed-info-item {
    display: flex;
    flex-direction: column;
}

.detailed-info-label {
    font-size: 0.9rem;
    color: #666;
    margin-bottom: 5px;
}

.detailed-info-value {
    font-size: 1.1rem;
    font-weight: bold;
}
</style>
"@
    }
    default {
        ""
    }
}

# Assembler le HTML final
$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{title}}</title>
    <style>
$baseStyles
$layoutSpecificStyles
    </style>
</head>
<body>
$headerHtml
<div class="container">
$sidebarHtml
</div>
$footerHtml
</body>
</html>
"@

# Enregistrer le layout
Set-Content -Path $OutputPath -Value $html -Encoding UTF8

Write-Host "Layout responsif généré avec succès: $OutputPath" -ForegroundColor Green
Write-Host "  Type: $LayoutType" -ForegroundColor White
Write-Host "  Colonnes: $Columns" -ForegroundColor White
Write-Host "  En-tête: $IncludeHeader" -ForegroundColor White
Write-Host "  Pied de page: $IncludeFooter" -ForegroundColor White
Write-Host "  Barre latérale: $IncludeSidebar" -ForegroundColor White

if ($IncludeSidebar) {
    Write-Host "  Position de la barre latérale: $SidebarPosition" -ForegroundColor White
    Write-Host "  Largeur de la barre latérale: $SidebarWidth%" -ForegroundColor White
}

return $OutputPath
