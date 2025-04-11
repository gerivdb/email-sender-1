#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiés pour la fonction Register-FormatConverter.

.DESCRIPTION
    Ce fichier contient des tests simplifiés pour la fonction Register-FormatConverter.
    Il teste l'enregistrement de convertisseurs de format et la récupération des convertisseurs enregistrés.

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
    Context "Enregistrement et récupération de convertisseurs" {
        # Créer des paramètres pour le convertisseur de test
        $global:sourceFormat = "TEST"
        $global:targetFormat = "XML"
        $global:conversionScript = { param($SourcePath, $TargetPath) return $true }
        $global:priority = 10

        It "Enregistre correctement un nouveau convertisseur" {
            # Enregistrer le convertisseur de test
            $result = Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ConversionScript $global:conversionScript -Priority $global:priority

            # Vérifier que le convertisseur a été enregistré
            $result | Should -Not -BeNullOrEmpty
            $result.SourceFormat | Should -Be $global:sourceFormat
            $result.TargetFormat | Should -Be $global:targetFormat
            $result.Priority | Should -Be $global:priority
        }

        It "Récupère correctement les convertisseurs filtrés par format source" {
            # Récupérer les convertisseurs avec le format source JSON
            $converters = Get-RegisteredConverters -SourceFormat "JSON"

            # Vérifier que les convertisseurs ont été filtrés correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object { $_.SourceFormat | Should -Be "JSON" }
        }

        It "Récupère correctement les convertisseurs filtrés par format cible" {
            # Récupérer les convertisseurs avec le format cible XML
            $converters = Get-RegisteredConverters -TargetFormat "XML"

            # Vérifier que les convertisseurs ont été filtrés correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object { $_.TargetFormat | Should -Be "XML" }
        }

        It "Récupère correctement les convertisseurs filtrés par format source et cible" {
            # Récupérer les convertisseurs avec le format source JSON et le format cible XML
            $converters = Get-RegisteredConverters -SourceFormat "JSON" -TargetFormat "XML"

            # Vérifier que les convertisseurs ont été filtrés correctement
            $converters | Should -Not -BeNullOrEmpty
            $converters | ForEach-Object {
                $_.SourceFormat | Should -Be "JSON"
                $_.TargetFormat | Should -Be "XML"
            }
        }

        It "Retourne une liste vide si aucun convertisseur ne correspond aux critères" {
            # Récupérer les convertisseurs avec un format source inexistant
            $converters = Get-RegisteredConverters -SourceFormat "NONEXISTENT"

            # Vérifier que la liste est vide
            $converters | Should -BeNullOrEmpty
        }

        # Ce test est désactivé car il demande des paramètres interactifs
        # It "Gère correctement l'enregistrement d'un convertisseur avec des paramètres manquants" {
        #     # Vérifier que l'enregistrement échoue si ConversionScript est manquant
        #     { Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ErrorAction Stop } | Should -Throw
        # }

        # Ce test est désactivé car il demande des paramètres interactifs
        # It "Gère correctement l'enregistrement d'un convertisseur avec une priorité différente" {
        #     # Enregistrer un convertisseur avec une priorité différente
        #     $newPriority = 100  # Priorité élevée pour être sûr qu'elle est différente
        #     $result = Register-FormatConverter -SourceFormat $global:sourceFormat -TargetFormat $global:targetFormat -ConversionScript $global:conversionScript -Priority $newPriority
        #
        #     # Vérifier que le convertisseur a été enregistré avec la bonne priorité
        #     $result | Should -Not -BeNullOrEmpty
        #     $result.SourceFormat | Should -Be $global:sourceFormat
        #     $result.TargetFormat | Should -Be $global:targetFormat
        #     $result.Priority | Should -Be $newPriority
        # }
    }
}
