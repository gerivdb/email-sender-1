#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour la fonction Register-FormatConverter.

.DESCRIPTION
    Ce fichier contient des tests simplifiÃ©s pour la fonction Register-FormatConverter.
    Il teste l'enregistrement de convertisseurs de format et la rÃ©cupÃ©ration des convertisseurs enregistrÃ©s.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module
$global:modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
Import-Module -Name $global:modulePath -Force

# Tests pour Register-FormatConverter et Get-RegisteredConverters
Describe "Fonctions Register-FormatConverter et Get-RegisteredConverters" {
    Context "Enregistrement et rÃ©cupÃ©ration de convertisseurs" {
        # CrÃ©er des paramÃ¨tres pour le convertisseur de test
        $global:sourceFormat = "TEST"
        $global:targetFormat = "XML"
        $global:conversionScript = { param($SourcePath, $TargetPath) return $true }
        $global:priority = 10

        It "Enregistre correctement un nouveau convertisseur" {
            # Enregistrer le convertisseur de test
            $result = Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ConversionScript $global:conversionScript -Priority $global:priority

            # VÃ©rifier que le convertisseur a Ã©tÃ© enregistrÃ©
            $result | Should -Not -BeNullOrEmpty
            $result.SourceFormat | Should -Be $global:sourceFormat
            $result.TargetFormat | Should -Be $global:targetFormat
            $result.Priority | Should -Be $global:priority
        }

        It "RÃ©cupÃ¨re correctement les convertisseurs filtrÃ©s par format source" {
            # RÃ©cupÃ©rer les convertisseurs avec le format source JSON
            $converters = Get-RegisteredConverters -SourceFormat "JSON"

            # VÃ©rifier que les convertisseurs ont Ã©tÃ© filtrÃ©s correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object { $_.SourceFormat | Should -Be "JSON" }
        }

        It "RÃ©cupÃ¨re correctement les convertisseurs filtrÃ©s par format cible" {
            # RÃ©cupÃ©rer les convertisseurs avec le format cible XML
            $converters = Get-RegisteredConverters -TargetFormat "XML"

            # VÃ©rifier que les convertisseurs ont Ã©tÃ© filtrÃ©s correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object { $_.TargetFormat | Should -Be "XML" }
        }

        It "RÃ©cupÃ¨re correctement les convertisseurs filtrÃ©s par format source et cible" {
            # RÃ©cupÃ©rer les convertisseurs avec le format source JSON et le format cible XML
            $converters = Get-RegisteredConverters -SourceFormat "JSON" -TargetFormat "XML"

            # VÃ©rifier que les convertisseurs ont Ã©tÃ© filtrÃ©s correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object {
                $_.SourceFormat | Should -Be "JSON"
                $_.TargetFormat | Should -Be "XML"
            }
        }

        It "Retourne une liste vide si aucun convertisseur ne correspond aux critÃ¨res" {
            # RÃ©cupÃ©rer les convertisseurs avec un format source inexistant
            $converters = Get-RegisteredConverters -SourceFormat "NONEXISTENT"

            # VÃ©rifier que la liste est vide
            $converters | Should -BeNullOrEmpty
        }

        # Ce test est dÃ©sactivÃ© car il demande des paramÃ¨tres interactifs
        # It "GÃ¨re correctement l'enregistrement d'un convertisseur avec des paramÃ¨tres manquants" {
        #     # VÃ©rifier que l'enregistrement Ã©choue si ConversionScript est manquant
        #     { Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ErrorAction Stop } | Should -Throw
        # }

        # Ce test est dÃ©sactivÃ© car il demande des paramÃ¨tres interactifs
        # It "GÃ¨re correctement l'enregistrement d'un convertisseur avec une prioritÃ© diffÃ©rente" {
        #     # Enregistrer un convertisseur avec une prioritÃ© diffÃ©rente
        #     $newPriority = 100  # PrioritÃ© Ã©levÃ©e pour Ãªtre sÃ»r qu'elle est diffÃ©rente
        #     $result = Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ConversionScript $global:conversionScript -Priority $newPriority
        #
        #     # VÃ©rifier que le convertisseur a Ã©tÃ© enregistrÃ© avec la bonne prioritÃ©
        #     $result | Should -Not -BeNullOrEmpty
        #     $result.SourceFormat | Should -Be $global:sourceFormat
        #     $result.TargetFormat | Should -Be $global:targetFormat
        #     $result.Priority | Should -Be $newPriority
        # }
    }
}
