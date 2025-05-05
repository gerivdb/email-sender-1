#Requires -Version 5.1

<#
.SYNOPSIS
    Module pour l'extraction des mÃ©tadonnÃ©es de configuration.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser les fichiers de configuration,
    extraire leurs options, dÃ©pendances et contraintes.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
#>

# Variables globales du module
$script:SupportedFormats = @("JSON", "YAML", "XML", "INI", "PSD1")
$script:ConfigurationCache = @{}

# Importer les fonctions privÃ©es
$privateFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "Private"
if (Test-Path -Path $privateFunctionsPath) {
    $privateFiles = Get-ChildItem -Path $privateFunctionsPath -Filter "*.ps1" -File
    foreach ($file in $privateFiles) {
        . $file.FullName
    }
}

# Importer les fonctions publiques
$publicFunctionsPath = Join-Path -Path $PSScriptRoot -ChildPath "Public"
if (Test-Path -Path $publicFunctionsPath) {
    $publicFiles = Get-ChildItem -Path $publicFunctionsPath -Filter "*.ps1" -File
    foreach ($file in $publicFiles) {
        . $file.FullName
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ConfigurationFormat, 
                              Get-ConfigurationStructure, 
                              Get-ConfigurationOptions, 
                              Get-ConfigurationDependencies, 
                              Get-ConfigurationConstraints
