<#
.SYNOPSIS
    Module de styles prÃ©dÃ©finis pour les graphiques Excel.
.DESCRIPTION
    Ce module fournit une bibliothÃ¨que de styles prÃ©dÃ©finis pour les graphiques Excel,
    incluant les styles de lignes, marqueurs, couleurs, bordures et thÃ¨mes complets.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃ©ation: 2025-04-25
#>

# VÃ©rifier si le module excel_style_registry.ps1 est disponible
$RegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
if (-not (Test-Path -Path $RegistryPath)) {
    throw "Le module excel_style_registry.ps1 est requis mais n'a pas Ã©tÃ© trouvÃ©."
}

# Importer le module excel_style_registry.ps1
. $RegistryPath

#region Styles de lignes classiques

# Fonction pour initialiser les styles de lignes classiques
function Initialize-ExcelLineStyleLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ExcelStyleRegistry]$Registry = (Get-ExcelStyleRegistry)
    )

    # Styles de lignes continues
    $ContinuousThin = [ExcelLineStyle]::new()
    $ContinuousThin.Name = "Ligne continue fine"
    $ContinuousThin.Description = "Style de ligne continue fine"
    $ContinuousThin.Category = "Lignes continues"
    $ContinuousThin.AddTag("Standard")
    $ContinuousThin.AddTag("Ligne")
    $ContinuousThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Solid, "#000000")
    $ContinuousThin.IsBuiltIn = $true
    $Registry.Add($ContinuousThin) | Out-Null

    $ContinuousMedium = [ExcelLineStyle]::new()
    $ContinuousMedium.Name = "Ligne continue moyenne"
    $ContinuousMedium.Description = "Style de ligne continue d'Ã©paisseur moyenne"
    $ContinuousMedium.Category = "Lignes continues"
    $ContinuousMedium.AddTag("Standard")
    $ContinuousMedium.AddTag("Ligne")
    $ContinuousMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#000000")
    $ContinuousMedium.IsBuiltIn = $true
    $Registry.Add($ContinuousMedium) | Out-Null

    $ContinuousThick = [ExcelLineStyle]::new()
    $ContinuousThick.Name = "Ligne continue Ã©paisse"
    $ContinuousThick.Description = "Style de ligne continue Ã©paisse"
    $ContinuousThick.Category = "Lignes continues"
    $ContinuousThick.AddTag("Standard")
    $ContinuousThick.AddTag("Ligne")
    $ContinuousThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Solid, "#000000")
    $ContinuousThick.IsBuiltIn = $true
    $Registry.Add($ContinuousThick) | Out-Null

    # Styles de lignes pointillÃ©es standard
    $DottedThin = [ExcelLineStyle]::new()
    $DottedThin.Name = "Ligne pointillÃ©e fine"
    $DottedThin.Description = "Style de ligne pointillÃ©e fine"
    $DottedThin.Category = "Lignes pointillÃ©es"
    $DottedThin.AddTag("Standard")
    $DottedThin.AddTag("Ligne")
    $DottedThin.AddTag("PointillÃ©")
    $DottedThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
    $DottedThin.IsBuiltIn = $true
    $Registry.Add($DottedThin) | Out-Null

    $DottedMedium = [ExcelLineStyle]::new()
    $DottedMedium.Name = "Ligne pointillÃ©e moyenne"
    $DottedMedium.Description = "Style de ligne pointillÃ©e d'Ã©paisseur moyenne"
    $DottedMedium.Category = "Lignes pointillÃ©es"
    $DottedMedium.AddTag("Standard")
    $DottedMedium.AddTag("Ligne")
    $DottedMedium.AddTag("PointillÃ©")
    $DottedMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#000000")
    $DottedMedium.IsBuiltIn = $true
    $Registry.Add($DottedMedium) | Out-Null

    $DottedThick = [ExcelLineStyle]::new()
    $DottedThick.Name = "Ligne pointillÃ©e Ã©paisse"
    $DottedThick.Description = "Style de ligne pointillÃ©e Ã©paisse"
    $DottedThick.Category = "Lignes pointillÃ©es"
    $DottedThick.AddTag("Standard")
    $DottedThick.AddTag("Ligne")
    $DottedThick.AddTag("PointillÃ©")
    $DottedThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dot, "#000000")
    $DottedThick.IsBuiltIn = $true
    $Registry.Add($DottedThick) | Out-Null

    # Styles de pointillÃ©s avancÃ©s avec espacement rÃ©gulier
    $DottedDenseThin = [ExcelLineStyle]::new()
    $DottedDenseThin.Name = "PointillÃ©s fins denses"
    $DottedDenseThin.Description = "Style de ligne avec pointillÃ©s fins rapprochÃ©s"
    $DottedDenseThin.Category = "PointillÃ©s avancÃ©s"
    $DottedDenseThin.AddTag("AvancÃ©")
    $DottedDenseThin.AddTag("Ligne")
    $DottedDenseThin.AddTag("PointillÃ©")
    $DottedDenseThin.AddTag("Dense")
    $DottedDenseThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
    $DottedDenseThin.LineConfig.DashType = "DenseDot"
    $DottedDenseThin.IsBuiltIn = $true
    $Registry.Add($DottedDenseThin) | Out-Null

    $DottedSparseThin = [ExcelLineStyle]::new()
    $DottedSparseThin.Name = "PointillÃ©s fins espacÃ©s"
    $DottedSparseThin.Description = "Style de ligne avec pointillÃ©s fins espacÃ©s"
    $DottedSparseThin.Category = "PointillÃ©s avancÃ©s"
    $DottedSparseThin.AddTag("AvancÃ©")
    $DottedSparseThin.AddTag("Ligne")
    $DottedSparseThin.AddTag("PointillÃ©")
    $DottedSparseThin.AddTag("EspacÃ©")
    $DottedSparseThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
    $DottedSparseThin.LineConfig.DashType = "SparseDot"
    $DottedSparseThin.IsBuiltIn = $true
    $Registry.Add($DottedSparseThin) | Out-Null

    # Styles de pointillÃ©s moyens avec diffÃ©rentes densitÃ©s
    $DottedDenseMedium = [ExcelLineStyle]::new()
    $DottedDenseMedium.Name = "PointillÃ©s moyens denses"
    $DottedDenseMedium.Description = "Style de ligne avec pointillÃ©s moyens rapprochÃ©s"
    $DottedDenseMedium.Category = "PointillÃ©s avancÃ©s"
    $DottedDenseMedium.AddTag("AvancÃ©")
    $DottedDenseMedium.AddTag("Ligne")
    $DottedDenseMedium.AddTag("PointillÃ©")
    $DottedDenseMedium.AddTag("Dense")
    $DottedDenseMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#000000")
    $DottedDenseMedium.LineConfig.DashType = "DenseDot"
    $DottedDenseMedium.IsBuiltIn = $true
    $Registry.Add($DottedDenseMedium) | Out-Null

    $DottedMediumMedium = [ExcelLineStyle]::new()
    $DottedMediumMedium.Name = "PointillÃ©s moyens standard"
    $DottedMediumMedium.Description = "Style de ligne avec pointillÃ©s moyens espacement standard"
    $DottedMediumMedium.Category = "PointillÃ©s avancÃ©s"
    $DottedMediumMedium.AddTag("AvancÃ©")
    $DottedMediumMedium.AddTag("Ligne")
    $DottedMediumMedium.AddTag("PointillÃ©")
    $DottedMediumMedium.AddTag("Standard")
    $DottedMediumMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#000000")
    $DottedMediumMedium.LineConfig.DashType = "MediumDot"
    $DottedMediumMedium.IsBuiltIn = $true
    $Registry.Add($DottedMediumMedium) | Out-Null

    $DottedSparseMedium = [ExcelLineStyle]::new()
    $DottedSparseMedium.Name = "PointillÃ©s moyens espacÃ©s"
    $DottedSparseMedium.Description = "Style de ligne avec pointillÃ©s moyens espacÃ©s"
    $DottedSparseMedium.Category = "PointillÃ©s avancÃ©s"
    $DottedSparseMedium.AddTag("AvancÃ©")
    $DottedSparseMedium.AddTag("Ligne")
    $DottedSparseMedium.AddTag("PointillÃ©")
    $DottedSparseMedium.AddTag("EspacÃ©")
    $DottedSparseMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#000000")
    $DottedSparseMedium.LineConfig.DashType = "SparseDot"
    $DottedSparseMedium.IsBuiltIn = $true
    $Registry.Add($DottedSparseMedium) | Out-Null

    # Styles de pointillÃ©s larges pour mise en Ã©vidence
    $DottedLargeThick = [ExcelLineStyle]::new()
    $DottedLargeThick.Name = "PointillÃ©s larges Ã©pais"
    $DottedLargeThick.Description = "Style de ligne avec gros pointillÃ©s pour mise en Ã©vidence"
    $DottedLargeThick.Category = "PointillÃ©s avancÃ©s"
    $DottedLargeThick.AddTag("AvancÃ©")
    $DottedLargeThick.AddTag("Ligne")
    $DottedLargeThick.AddTag("PointillÃ©")
    $DottedLargeThick.AddTag("Large")
    $DottedLargeThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dot, "#000000")
    $DottedLargeThick.LineConfig.DashType = "LargeDot"
    $DottedLargeThick.IsBuiltIn = $true
    $Registry.Add($DottedLargeThick) | Out-Null

    $DottedExtraLargeThick = [ExcelLineStyle]::new()
    $DottedExtraLargeThick.Name = "PointillÃ©s extra-larges Ã©pais"
    $DottedExtraLargeThick.Description = "Style de ligne avec trÃ¨s gros pointillÃ©s pour forte mise en Ã©vidence"
    $DottedExtraLargeThick.Category = "PointillÃ©s avancÃ©s"
    $DottedExtraLargeThick.AddTag("AvancÃ©")
    $DottedExtraLargeThick.AddTag("Ligne")
    $DottedExtraLargeThick.AddTag("PointillÃ©")
    $DottedExtraLargeThick.AddTag("Extra-large")
    $DottedExtraLargeThick.LineConfig = [ExcelLineStyleConfig]::new(4, [ExcelLineStyle]::Dot, "#000000")
    $DottedExtraLargeThick.LineConfig.DashType = "ExtraLargeDot"
    $DottedExtraLargeThick.IsBuiltIn = $true
    $Registry.Add($DottedExtraLargeThick) | Out-Null

    # Styles de pointillÃ©s avec variations de taille des points
    $DottedVariableSizeThin = [ExcelLineStyle]::new()
    $DottedVariableSizeThin.Name = "PointillÃ©s taille variable fins"
    $DottedVariableSizeThin.Description = "Style de ligne avec pointillÃ©s de taille variable"
    $DottedVariableSizeThin.Category = "PointillÃ©s avancÃ©s"
    $DottedVariableSizeThin.AddTag("AvancÃ©")
    $DottedVariableSizeThin.AddTag("Ligne")
    $DottedVariableSizeThin.AddTag("PointillÃ©")
    $DottedVariableSizeThin.AddTag("Variable")
    $DottedVariableSizeThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
    $DottedVariableSizeThin.LineConfig.DashType = "VariableDot"
    $DottedVariableSizeThin.IsBuiltIn = $true
    $Registry.Add($DottedVariableSizeThin) | Out-Null

    $DottedVariableSizeMedium = [ExcelLineStyle]::new()
    $DottedVariableSizeMedium.Name = "PointillÃ©s taille variable moyens"
    $DottedVariableSizeMedium.Description = "Style de ligne avec pointillÃ©s moyens de taille variable"
    $DottedVariableSizeMedium.Category = "PointillÃ©s avancÃ©s"
    $DottedVariableSizeMedium.AddTag("AvancÃ©")
    $DottedVariableSizeMedium.AddTag("Ligne")
    $DottedVariableSizeMedium.AddTag("PointillÃ©")
    $DottedVariableSizeMedium.AddTag("Variable")
    $DottedVariableSizeMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#000000")
    $DottedVariableSizeMedium.LineConfig.DashType = "VariableDot"
    $DottedVariableSizeMedium.IsBuiltIn = $true
    $Registry.Add($DottedVariableSizeMedium) | Out-Null

    # Styles de lignes en tirets standard
    $DashedThin = [ExcelLineStyle]::new()
    $DashedThin.Name = "Ligne en tirets fine"
    $DashedThin.Description = "Style de ligne en tirets fine"
    $DashedThin.Category = "Lignes en tirets"
    $DashedThin.AddTag("Standard")
    $DashedThin.AddTag("Ligne")
    $DashedThin.AddTag("Tiret")
    $DashedThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $DashedThin.IsBuiltIn = $true
    $Registry.Add($DashedThin) | Out-Null

    $DashedMedium = [ExcelLineStyle]::new()
    $DashedMedium.Name = "Ligne en tirets moyenne"
    $DashedMedium.Description = "Style de ligne en tirets d'Ã©paisseur moyenne"
    $DashedMedium.Category = "Lignes en tirets"
    $DashedMedium.AddTag("Standard")
    $DashedMedium.AddTag("Ligne")
    $DashedMedium.AddTag("Tiret")
    $DashedMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#000000")
    $DashedMedium.IsBuiltIn = $true
    $Registry.Add($DashedMedium) | Out-Null

    $DashedThick = [ExcelLineStyle]::new()
    $DashedThick.Name = "Ligne en tirets Ã©paisse"
    $DashedThick.Description = "Style de ligne en tirets Ã©paisse"
    $DashedThick.Category = "Lignes en tirets"
    $DashedThick.AddTag("Standard")
    $DashedThick.AddTag("Ligne")
    $DashedThick.AddTag("Tiret")
    $DashedThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dash, "#000000")
    $DashedThick.IsBuiltIn = $true
    $Registry.Add($DashedThick) | Out-Null

    # Styles de tirets courts avec espacement rÃ©gulier
    $ShortDashThin = [ExcelLineStyle]::new()
    $ShortDashThin.Name = "Tirets courts fins"
    $ShortDashThin.Description = "Style de ligne avec tirets courts fins et espacement rÃ©gulier"
    $ShortDashThin.Category = "Tirets avancÃ©s"
    $ShortDashThin.AddTag("AvancÃ©")
    $ShortDashThin.AddTag("Ligne")
    $ShortDashThin.AddTag("Tiret")
    $ShortDashThin.AddTag("Court")
    $ShortDashThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $ShortDashThin.LineConfig.DashType = "ShortDash"
    $ShortDashThin.IsBuiltIn = $true
    $Registry.Add($ShortDashThin) | Out-Null

    $ShortDashMedium = [ExcelLineStyle]::new()
    $ShortDashMedium.Name = "Tirets courts moyens"
    $ShortDashMedium.Description = "Style de ligne avec tirets courts d'Ã©paisseur moyenne"
    $ShortDashMedium.Category = "Tirets avancÃ©s"
    $ShortDashMedium.AddTag("AvancÃ©")
    $ShortDashMedium.AddTag("Ligne")
    $ShortDashMedium.AddTag("Tiret")
    $ShortDashMedium.AddTag("Court")
    $ShortDashMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#000000")
    $ShortDashMedium.LineConfig.DashType = "ShortDash"
    $ShortDashMedium.IsBuiltIn = $true
    $Registry.Add($ShortDashMedium) | Out-Null

    # Styles de tirets moyens avec diffÃ©rentes longueurs
    $MediumDashThin = [ExcelLineStyle]::new()
    $MediumDashThin.Name = "Tirets moyens fins"
    $MediumDashThin.Description = "Style de ligne avec tirets de longueur moyenne et fins"
    $MediumDashThin.Category = "Tirets avancÃ©s"
    $MediumDashThin.AddTag("AvancÃ©")
    $MediumDashThin.AddTag("Ligne")
    $MediumDashThin.AddTag("Tiret")
    $MediumDashThin.AddTag("Moyen")
    $MediumDashThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $MediumDashThin.LineConfig.DashType = "MediumDash"
    $MediumDashThin.IsBuiltIn = $true
    $Registry.Add($MediumDashThin) | Out-Null

    $MediumDashMedium = [ExcelLineStyle]::new()
    $MediumDashMedium.Name = "Tirets moyens standard"
    $MediumDashMedium.Description = "Style de ligne avec tirets de longueur moyenne et d'Ã©paisseur moyenne"
    $MediumDashMedium.Category = "Tirets avancÃ©s"
    $MediumDashMedium.AddTag("AvancÃ©")
    $MediumDashMedium.AddTag("Ligne")
    $MediumDashMedium.AddTag("Tiret")
    $MediumDashMedium.AddTag("Moyen")
    $MediumDashMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#000000")
    $MediumDashMedium.LineConfig.DashType = "MediumDash"
    $MediumDashMedium.IsBuiltIn = $true
    $Registry.Add($MediumDashMedium) | Out-Null

    # Styles de tirets longs pour sÃ©paration visuelle
    $LongDashThin = [ExcelLineStyle]::new()
    $LongDashThin.Name = "Tirets longs fins"
    $LongDashThin.Description = "Style de ligne avec longs tirets fins pour sÃ©paration visuelle"
    $LongDashThin.Category = "Tirets avancÃ©s"
    $LongDashThin.AddTag("AvancÃ©")
    $LongDashThin.AddTag("Ligne")
    $LongDashThin.AddTag("Tiret")
    $LongDashThin.AddTag("Long")
    $LongDashThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $LongDashThin.LineConfig.DashType = "LongDash"
    $LongDashThin.IsBuiltIn = $true
    $Registry.Add($LongDashThin) | Out-Null

    $LongDashMedium = [ExcelLineStyle]::new()
    $LongDashMedium.Name = "Tirets longs moyens"
    $LongDashMedium.Description = "Style de ligne avec longs tirets d'Ã©paisseur moyenne"
    $LongDashMedium.Category = "Tirets avancÃ©s"
    $LongDashMedium.AddTag("AvancÃ©")
    $LongDashMedium.AddTag("Ligne")
    $LongDashMedium.AddTag("Tiret")
    $LongDashMedium.AddTag("Long")
    $LongDashMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#000000")
    $LongDashMedium.LineConfig.DashType = "LongDash"
    $LongDashMedium.IsBuiltIn = $true
    $Registry.Add($LongDashMedium) | Out-Null

    $LongDashThick = [ExcelLineStyle]::new()
    $LongDashThick.Name = "Tirets longs Ã©pais"
    $LongDashThick.Description = "Style de ligne avec longs tirets Ã©pais pour forte sÃ©paration visuelle"
    $LongDashThick.Category = "Tirets avancÃ©s"
    $LongDashThick.AddTag("AvancÃ©")
    $LongDashThick.AddTag("Ligne")
    $LongDashThick.AddTag("Tiret")
    $LongDashThick.AddTag("Long")
    $LongDashThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::Dash, "#000000")
    $LongDashThick.LineConfig.DashType = "LongDash"
    $LongDashThick.IsBuiltIn = $true
    $Registry.Add($LongDashThick) | Out-Null

    # Styles de tirets avec variations d'espacement
    $DashSpacedThin = [ExcelLineStyle]::new()
    $DashSpacedThin.Name = "Tirets espacÃ©s fins"
    $DashSpacedThin.Description = "Style de ligne avec tirets fins largement espacÃ©s"
    $DashSpacedThin.Category = "Tirets avancÃ©s"
    $DashSpacedThin.AddTag("AvancÃ©")
    $DashSpacedThin.AddTag("Ligne")
    $DashSpacedThin.AddTag("Tiret")
    $DashSpacedThin.AddTag("EspacÃ©")
    $DashSpacedThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $DashSpacedThin.LineConfig.DashType = "SparseDash"
    $DashSpacedThin.IsBuiltIn = $true
    $Registry.Add($DashSpacedThin) | Out-Null

    $DashDenseThin = [ExcelLineStyle]::new()
    $DashDenseThin.Name = "Tirets denses fins"
    $DashDenseThin.Description = "Style de ligne avec tirets fins rapprochÃ©s"
    $DashDenseThin.Category = "Tirets avancÃ©s"
    $DashDenseThin.AddTag("AvancÃ©")
    $DashDenseThin.AddTag("Ligne")
    $DashDenseThin.AddTag("Tiret")
    $DashDenseThin.AddTag("Dense")
    $DashDenseThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $DashDenseThin.LineConfig.DashType = "DenseDash"
    $DashDenseThin.IsBuiltIn = $true
    $Registry.Add($DashDenseThin) | Out-Null

    # Styles de lignes tiret-point standard
    $DashDotThin = [ExcelLineStyle]::new()
    $DashDotThin.Name = "Ligne tiret-point fine"
    $DashDotThin.Description = "Style de ligne tiret-point fine"
    $DashDotThin.Category = "Lignes tiret-point"
    $DashDotThin.AddTag("Standard")
    $DashDotThin.AddTag("Ligne")
    $DashDotThin.AddTag("Tiret-point")
    $DashDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotThin.IsBuiltIn = $true
    $Registry.Add($DashDotThin) | Out-Null

    $DashDotMedium = [ExcelLineStyle]::new()
    $DashDotMedium.Name = "Ligne tiret-point moyenne"
    $DashDotMedium.Description = "Style de ligne tiret-point d'Ã©paisseur moyenne"
    $DashDotMedium.Category = "Lignes tiret-point"
    $DashDotMedium.AddTag("Standard")
    $DashDotMedium.AddTag("Ligne")
    $DashDotMedium.AddTag("Tiret-point")
    $DashDotMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotMedium.IsBuiltIn = $true
    $Registry.Add($DashDotMedium) | Out-Null

    $DashDotThick = [ExcelLineStyle]::new()
    $DashDotThick.Name = "Ligne tiret-point Ã©paisse"
    $DashDotThick.Description = "Style de ligne tiret-point Ã©paisse"
    $DashDotThick.Category = "Lignes tiret-point"
    $DashDotThick.AddTag("Standard")
    $DashDotThick.AddTag("Ligne")
    $DashDotThick.AddTag("Tiret-point")
    $DashDotThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotThick.IsBuiltIn = $true
    $Registry.Add($DashDotThick) | Out-Null

    # Styles de lignes tiret-point-point standard
    $DashDotDotThin = [ExcelLineStyle]::new()
    $DashDotDotThin.Name = "Ligne tiret-point-point fine"
    $DashDotDotThin.Description = "Style de ligne tiret-point-point fine"
    $DashDotDotThin.Category = "Lignes tiret-point-point"
    $DashDotDotThin.AddTag("Standard")
    $DashDotDotThin.AddTag("Ligne")
    $DashDotDotThin.AddTag("Tiret-point-point")
    $DashDotDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDotDot, "#000000")
    $DashDotDotThin.IsBuiltIn = $true
    $Registry.Add($DashDotDotThin) | Out-Null

    $DashDotDotMedium = [ExcelLineStyle]::new()
    $DashDotDotMedium.Name = "Ligne tiret-point-point moyenne"
    $DashDotDotMedium.Description = "Style de ligne tiret-point-point d'Ã©paisseur moyenne"
    $DashDotDotMedium.Category = "Lignes tiret-point-point"
    $DashDotDotMedium.AddTag("Standard")
    $DashDotDotMedium.AddTag("Ligne")
    $DashDotDotMedium.AddTag("Tiret-point-point")
    $DashDotDotMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDotDot, "#000000")
    $DashDotDotMedium.IsBuiltIn = $true
    $Registry.Add($DashDotDotMedium) | Out-Null

    $DashDotDotThick = [ExcelLineStyle]::new()
    $DashDotDotThick.Name = "Ligne tiret-point-point Ã©paisse"
    $DashDotDotThick.Description = "Style de ligne tiret-point-point Ã©paisse"
    $DashDotDotThick.Category = "Lignes tiret-point-point"
    $DashDotDotThick.AddTag("Standard")
    $DashDotDotThick.AddTag("Ligne")
    $DashDotDotThick.AddTag("Tiret-point-point")
    $DashDotDotThick.LineConfig = [ExcelLineStyleConfig]::new(3, [ExcelLineStyle]::DashDotDot, "#000000")
    $DashDotDotThick.IsBuiltIn = $true
    $Registry.Add($DashDotDotThick) | Out-Null

    # Combinaisons tiret-point avancÃ©es
    $ShortDashDotThin = [ExcelLineStyle]::new()
    $ShortDashDotThin.Name = "Tiret court-point fin"
    $ShortDashDotThin.Description = "Style de ligne avec tirets courts et points fins"
    $ShortDashDotThin.Category = "Combinaisons tiret-point avancÃ©es"
    $ShortDashDotThin.AddTag("AvancÃ©")
    $ShortDashDotThin.AddTag("Ligne")
    $ShortDashDotThin.AddTag("Tiret-point")
    $ShortDashDotThin.AddTag("Court")
    $ShortDashDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $ShortDashDotThin.LineConfig.DashType = "ShortDashDot"
    $ShortDashDotThin.IsBuiltIn = $true
    $Registry.Add($ShortDashDotThin) | Out-Null

    $LongDashDotThin = [ExcelLineStyle]::new()
    $LongDashDotThin.Name = "Tiret long-point fin"
    $LongDashDotThin.Description = "Style de ligne avec tirets longs et points fins"
    $LongDashDotThin.Category = "Combinaisons tiret-point avancÃ©es"
    $LongDashDotThin.AddTag("AvancÃ©")
    $LongDashDotThin.AddTag("Ligne")
    $LongDashDotThin.AddTag("Tiret-point")
    $LongDashDotThin.AddTag("Long")
    $LongDashDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $LongDashDotThin.LineConfig.DashType = "LongDashDot"
    $LongDashDotThin.IsBuiltIn = $true
    $Registry.Add($LongDashDotThin) | Out-Null

    $LongDashDotMedium = [ExcelLineStyle]::new()
    $LongDashDotMedium.Name = "Tiret long-point moyen"
    $LongDashDotMedium.Description = "Style de ligne avec tirets longs et points d'Ã©paisseur moyenne"
    $LongDashDotMedium.Category = "Combinaisons tiret-point avancÃ©es"
    $LongDashDotMedium.AddTag("AvancÃ©")
    $LongDashDotMedium.AddTag("Ligne")
    $LongDashDotMedium.AddTag("Tiret-point")
    $LongDashDotMedium.AddTag("Long")
    $LongDashDotMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#000000")
    $LongDashDotMedium.LineConfig.DashType = "LongDashDot"
    $LongDashDotMedium.IsBuiltIn = $true
    $Registry.Add($LongDashDotMedium) | Out-Null

    # Variations avec tirets de diffÃ©rentes longueurs
    $DashDotVariableThin = [ExcelLineStyle]::new()
    $DashDotVariableThin.Name = "Tiret-point variable fin"
    $DashDotVariableThin.Description = "Style de ligne avec tirets de longueur variable et points fins"
    $DashDotVariableThin.Category = "Combinaisons tiret-point avancÃ©es"
    $DashDotVariableThin.AddTag("AvancÃ©")
    $DashDotVariableThin.AddTag("Ligne")
    $DashDotVariableThin.AddTag("Tiret-point")
    $DashDotVariableThin.AddTag("Variable")
    $DashDotVariableThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotVariableThin.LineConfig.DashType = "VariableDashDot"
    $DashDotVariableThin.IsBuiltIn = $true
    $Registry.Add($DashDotVariableThin) | Out-Null

    # Motifs personnalisÃ©s avec densitÃ©s variables
    $DashDotDenseThin = [ExcelLineStyle]::new()
    $DashDotDenseThin.Name = "Tiret-point dense fin"
    $DashDotDenseThin.Description = "Style de ligne avec tirets et points rapprochÃ©s"
    $DashDotDenseThin.Category = "Combinaisons tiret-point avancÃ©es"
    $DashDotDenseThin.AddTag("AvancÃ©")
    $DashDotDenseThin.AddTag("Ligne")
    $DashDotDenseThin.AddTag("Tiret-point")
    $DashDotDenseThin.AddTag("Dense")
    $DashDotDenseThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotDenseThin.LineConfig.DashType = "DenseDashDot"
    $DashDotDenseThin.IsBuiltIn = $true
    $Registry.Add($DashDotDenseThin) | Out-Null

    $DashDotSparseThin = [ExcelLineStyle]::new()
    $DashDotSparseThin.Name = "Tiret-point espacÃ© fin"
    $DashDotSparseThin.Description = "Style de ligne avec tirets et points largement espacÃ©s"
    $DashDotSparseThin.Category = "Combinaisons tiret-point avancÃ©es"
    $DashDotSparseThin.AddTag("AvancÃ©")
    $DashDotSparseThin.AddTag("Ligne")
    $DashDotSparseThin.AddTag("Tiret-point")
    $DashDotSparseThin.AddTag("EspacÃ©")
    $DashDotSparseThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $DashDotSparseThin.LineConfig.DashType = "SparseDashDot"
    $DashDotSparseThin.IsBuiltIn = $true
    $Registry.Add($DashDotSparseThin) | Out-Null

    # SÃ©quences rÃ©pÃ©titives complexes
    $ComplexDashDotThin = [ExcelLineStyle]::new()
    $ComplexDashDotThin.Name = "Tiret-point complexe fin"
    $ComplexDashDotThin.Description = "Style de ligne avec motif tiret-point complexe"
    $ComplexDashDotThin.Category = "Combinaisons tiret-point avancÃ©es"
    $ComplexDashDotThin.AddTag("AvancÃ©")
    $ComplexDashDotThin.AddTag("Ligne")
    $ComplexDashDotThin.AddTag("Tiret-point")
    $ComplexDashDotThin.AddTag("Complexe")
    $ComplexDashDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDot, "#000000")
    $ComplexDashDotThin.LineConfig.DashType = "ComplexDashDot"
    $ComplexDashDotThin.IsBuiltIn = $true
    $Registry.Add($ComplexDashDotThin) | Out-Null

    $ComplexDashDotDotThin = [ExcelLineStyle]::new()
    $ComplexDashDotDotThin.Name = "Tiret-point-point complexe fin"
    $ComplexDashDotDotThin.Description = "Style de ligne avec motif tiret-point-point complexe"
    $ComplexDashDotDotThin.Category = "Combinaisons tiret-point avancÃ©es"
    $ComplexDashDotDotThin.AddTag("AvancÃ©")
    $ComplexDashDotDotThin.AddTag("Ligne")
    $ComplexDashDotDotThin.AddTag("Tiret-point-point")
    $ComplexDashDotDotThin.AddTag("Complexe")
    $ComplexDashDotDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::DashDotDot, "#000000")
    $ComplexDashDotDotThin.LineConfig.DashType = "ComplexDashDotDot"
    $ComplexDashDotDotThin.IsBuiltIn = $true
    $Registry.Add($ComplexDashDotDotThin) | Out-Null

    # Variations d'espacement - MÃ©canismes de contrÃ´le d'espacement
    $CustomSpacingThin = [ExcelLineStyle]::new()
    $CustomSpacingThin.Name = "Espacement personnalisÃ© fin"
    $CustomSpacingThin.Description = "Style de ligne avec espacement personnalisÃ© entre segments"
    $CustomSpacingThin.Category = "Variations d'espacement"
    $CustomSpacingThin.AddTag("AvancÃ©")
    $CustomSpacingThin.AddTag("Ligne")
    $CustomSpacingThin.AddTag("Espacement")
    $CustomSpacingThin.AddTag("PersonnalisÃ©")
    $CustomSpacingThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $CustomSpacingThin.LineConfig.DashType = "CustomSpacing"
    $CustomSpacingThin.LineConfig.SpacingFactor = 1.5  # Facteur d'espacement personnalisÃ©
    $CustomSpacingThin.IsBuiltIn = $true
    $Registry.Add($CustomSpacingThin) | Out-Null

    $CustomSpacingMedium = [ExcelLineStyle]::new()
    $CustomSpacingMedium.Name = "Espacement personnalisÃ© moyen"
    $CustomSpacingMedium.Description = "Style de ligne d'Ã©paisseur moyenne avec espacement personnalisÃ©"
    $CustomSpacingMedium.Category = "Variations d'espacement"
    $CustomSpacingMedium.AddTag("AvancÃ©")
    $CustomSpacingMedium.AddTag("Ligne")
    $CustomSpacingMedium.AddTag("Espacement")
    $CustomSpacingMedium.AddTag("PersonnalisÃ©")
    $CustomSpacingMedium.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#000000")
    $CustomSpacingMedium.LineConfig.DashType = "CustomSpacing"
    $CustomSpacingMedium.LineConfig.SpacingFactor = 1.5  # Facteur d'espacement personnalisÃ©
    $CustomSpacingMedium.IsBuiltIn = $true
    $Registry.Add($CustomSpacingMedium) | Out-Null

    # Styles avec espacement progressif
    $ProgressiveSpacingThin = [ExcelLineStyle]::new()
    $ProgressiveSpacingThin.Name = "Espacement progressif fin"
    $ProgressiveSpacingThin.Description = "Style de ligne avec espacement progressivement croissant"
    $ProgressiveSpacingThin.Category = "Variations d'espacement"
    $ProgressiveSpacingThin.AddTag("AvancÃ©")
    $ProgressiveSpacingThin.AddTag("Ligne")
    $ProgressiveSpacingThin.AddTag("Espacement")
    $ProgressiveSpacingThin.AddTag("Progressif")
    $ProgressiveSpacingThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $ProgressiveSpacingThin.LineConfig.DashType = "ProgressiveSpacing"
    $ProgressiveSpacingThin.LineConfig.ProgressionFactor = 1.2  # Facteur de progression
    $ProgressiveSpacingThin.IsBuiltIn = $true
    $Registry.Add($ProgressiveSpacingThin) | Out-Null

    $ProgressiveSpacingDotThin = [ExcelLineStyle]::new()
    $ProgressiveSpacingDotThin.Name = "PointillÃ©s espacement progressif"
    $ProgressiveSpacingDotThin.Description = "Style de ligne pointillÃ©e avec espacement progressivement croissant"
    $ProgressiveSpacingDotThin.Category = "Variations d'espacement"
    $ProgressiveSpacingDotThin.AddTag("AvancÃ©")
    $ProgressiveSpacingDotThin.AddTag("Ligne")
    $ProgressiveSpacingDotThin.AddTag("PointillÃ©")
    $ProgressiveSpacingDotThin.AddTag("Espacement")
    $ProgressiveSpacingDotThin.AddTag("Progressif")
    $ProgressiveSpacingDotThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dot, "#000000")
    $ProgressiveSpacingDotThin.LineConfig.DashType = "ProgressiveDot"
    $ProgressiveSpacingDotThin.LineConfig.ProgressionFactor = 1.2  # Facteur de progression
    $ProgressiveSpacingDotThin.IsBuiltIn = $true
    $Registry.Add($ProgressiveSpacingDotThin) | Out-Null

    # Options d'espacement proportionnel
    $ProportionalSpacingThin = [ExcelLineStyle]::new()
    $ProportionalSpacingThin.Name = "Espacement proportionnel fin"
    $ProportionalSpacingThin.Description = "Style de ligne avec espacement proportionnel Ã  la longueur des segments"
    $ProportionalSpacingThin.Category = "Variations d'espacement"
    $ProportionalSpacingThin.AddTag("AvancÃ©")
    $ProportionalSpacingThin.AddTag("Ligne")
    $ProportionalSpacingThin.AddTag("Espacement")
    $ProportionalSpacingThin.AddTag("Proportionnel")
    $ProportionalSpacingThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Dash, "#000000")
    $ProportionalSpacingThin.LineConfig.DashType = "ProportionalSpacing"
    $ProportionalSpacingThin.LineConfig.ProportionFactor = 0.5  # Facteur de proportion
    $ProportionalSpacingThin.IsBuiltIn = $true
    $Registry.Add($ProportionalSpacingThin) | Out-Null

    # Personnalisation fine des motifs
    $CustomPatternThin = [ExcelLineStyle]::new()
    $CustomPatternThin.Name = "Motif personnalisÃ© fin"
    $CustomPatternThin.Description = "Style de ligne avec motif personnalisÃ© de segments et d'espacements"
    $CustomPatternThin.Category = "Variations d'espacement"
    $CustomPatternThin.AddTag("AvancÃ©")
    $CustomPatternThin.AddTag("Ligne")
    $CustomPatternThin.AddTag("Motif")
    $CustomPatternThin.AddTag("PersonnalisÃ©")
    $CustomPatternThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Custom, "#000000")
    $CustomPatternThin.LineConfig.DashType = "CustomPattern"
    $CustomPatternThin.LineConfig.Pattern = "5,2,1,2"  # Motif personnalisÃ© (longueur segment, espacement, etc.)
    $CustomPatternThin.IsBuiltIn = $true
    $Registry.Add($CustomPatternThin) | Out-Null

    $ComplexPatternThin = [ExcelLineStyle]::new()
    $ComplexPatternThin.Name = "Motif complexe fin"
    $ComplexPatternThin.Description = "Style de ligne avec motif complexe de segments et d'espacements"
    $ComplexPatternThin.Category = "Variations d'espacement"
    $ComplexPatternThin.AddTag("AvancÃ©")
    $ComplexPatternThin.AddTag("Ligne")
    $ComplexPatternThin.AddTag("Motif")
    $ComplexPatternThin.AddTag("Complexe")
    $ComplexPatternThin.LineConfig = [ExcelLineStyleConfig]::new(1, [ExcelLineStyle]::Custom, "#000000")
    $ComplexPatternThin.LineConfig.DashType = "ComplexPattern"
    $ComplexPatternThin.LineConfig.Pattern = "5,2,3,2,1,2,3,4"  # Motif complexe
    $ComplexPatternThin.IsBuiltIn = $true
    $Registry.Add($ComplexPatternThin) | Out-Null

    # Styles de lignes avec couleurs de base
    $RedLine = [ExcelLineStyle]::new()
    $RedLine.Name = "Ligne rouge"
    $RedLine.Description = "Style de ligne continue rouge"
    $RedLine.Category = "Lignes colorÃ©es"
    $RedLine.AddTag("Couleur")
    $RedLine.AddTag("Ligne")
    $RedLine.AddTag("Rouge")
    $RedLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#FF0000")
    $RedLine.IsBuiltIn = $true
    $Registry.Add($RedLine) | Out-Null

    $GreenLine = [ExcelLineStyle]::new()
    $GreenLine.Name = "Ligne verte"
    $GreenLine.Description = "Style de ligne continue verte"
    $GreenLine.Category = "Lignes colorÃ©es"
    $GreenLine.AddTag("Couleur")
    $GreenLine.AddTag("Ligne")
    $GreenLine.AddTag("Vert")
    $GreenLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#00FF00")
    $GreenLine.IsBuiltIn = $true
    $Registry.Add($GreenLine) | Out-Null

    $BlueLine = [ExcelLineStyle]::new()
    $BlueLine.Name = "Ligne bleue"
    $BlueLine.Description = "Style de ligne continue bleue"
    $BlueLine.Category = "Lignes colorÃ©es"
    $BlueLine.AddTag("Couleur")
    $BlueLine.AddTag("Ligne")
    $BlueLine.AddTag("Bleu")
    $BlueLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#0000FF")
    $BlueLine.IsBuiltIn = $true
    $Registry.Add($BlueLine) | Out-Null

    $YellowLine = [ExcelLineStyle]::new()
    $YellowLine.Name = "Ligne jaune"
    $YellowLine.Description = "Style de ligne continue jaune"
    $YellowLine.Category = "Lignes colorÃ©es"
    $YellowLine.AddTag("Couleur")
    $YellowLine.AddTag("Ligne")
    $YellowLine.AddTag("Jaune")
    $YellowLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#FFFF00")
    $YellowLine.IsBuiltIn = $true
    $Registry.Add($YellowLine) | Out-Null

    $PurpleLine = [ExcelLineStyle]::new()
    $PurpleLine.Name = "Ligne violette"
    $PurpleLine.Description = "Style de ligne continue violette"
    $PurpleLine.Category = "Lignes colorÃ©es"
    $PurpleLine.AddTag("Couleur")
    $PurpleLine.AddTag("Ligne")
    $PurpleLine.AddTag("Violet")
    $PurpleLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#800080")
    $PurpleLine.IsBuiltIn = $true
    $Registry.Add($PurpleLine) | Out-Null

    # Styles de lignes colorÃ©es en pointillÃ©s
    $RedDottedLine = [ExcelLineStyle]::new()
    $RedDottedLine.Name = "Ligne pointillÃ©e rouge"
    $RedDottedLine.Description = "Style de ligne pointillÃ©e rouge"
    $RedDottedLine.Category = "Lignes colorÃ©es"
    $RedDottedLine.AddTag("Couleur")
    $RedDottedLine.AddTag("Ligne")
    $RedDottedLine.AddTag("Rouge")
    $RedDottedLine.AddTag("PointillÃ©")
    $RedDottedLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#FF0000")
    $RedDottedLine.IsBuiltIn = $true
    $Registry.Add($RedDottedLine) | Out-Null

    $BlueDashedLine = [ExcelLineStyle]::new()
    $BlueDashedLine.Name = "Ligne en tirets bleue"
    $BlueDashedLine.Description = "Style de ligne en tirets bleue"
    $BlueDashedLine.Category = "Lignes colorÃ©es"
    $BlueDashedLine.AddTag("Couleur")
    $BlueDashedLine.AddTag("Ligne")
    $BlueDashedLine.AddTag("Bleu")
    $BlueDashedLine.AddTag("Tiret")
    $BlueDashedLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#0000FF")
    $BlueDashedLine.IsBuiltIn = $true
    $Registry.Add($BlueDashedLine) | Out-Null

    $GreenDashDotLine = [ExcelLineStyle]::new()
    $GreenDashDotLine.Name = "Ligne tiret-point verte"
    $GreenDashDotLine.Description = "Style de ligne tiret-point verte"
    $GreenDashDotLine.Category = "Lignes colorÃ©es"
    $GreenDashDotLine.AddTag("Couleur")
    $GreenDashDotLine.AddTag("Ligne")
    $GreenDashDotLine.AddTag("Vert")
    $GreenDashDotLine.AddTag("Tiret-point")
    $GreenDashDotLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#00FF00")
    $GreenDashDotLine.IsBuiltIn = $true
    $Registry.Add($GreenDashDotLine) | Out-Null

    # Paires style-couleur harmonieuses
    $HarmoniousRedLine = [ExcelLineStyle]::new()
    $HarmoniousRedLine.Name = "Ligne harmonieuse rouge"
    $HarmoniousRedLine.Description = "Style de ligne avec nuance de rouge harmonieuse"
    $HarmoniousRedLine.Category = "Combinaisons harmonieuses"
    $HarmoniousRedLine.AddTag("Couleur")
    $HarmoniousRedLine.AddTag("Ligne")
    $HarmoniousRedLine.AddTag("Harmonieux")
    $HarmoniousRedLine.AddTag("Rouge")
    $HarmoniousRedLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#C41E3A")  # Rouge carmÃ©sin
    $HarmoniousRedLine.IsBuiltIn = $true
    $Registry.Add($HarmoniousRedLine) | Out-Null

    $HarmoniousBlueLine = [ExcelLineStyle]::new()
    $HarmoniousBlueLine.Name = "Ligne harmonieuse bleue"
    $HarmoniousBlueLine.Description = "Style de ligne avec nuance de bleu harmonieuse"
    $HarmoniousBlueLine.Category = "Combinaisons harmonieuses"
    $HarmoniousBlueLine.AddTag("Couleur")
    $HarmoniousBlueLine.AddTag("Ligne")
    $HarmoniousBlueLine.AddTag("Harmonieux")
    $HarmoniousBlueLine.AddTag("Bleu")
    $HarmoniousBlueLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#1E90FF")  # Bleu dodger
    $HarmoniousBlueLine.IsBuiltIn = $true
    $Registry.Add($HarmoniousBlueLine) | Out-Null

    $HarmoniousGreenLine = [ExcelLineStyle]::new()
    $HarmoniousGreenLine.Name = "Ligne harmonieuse verte"
    $HarmoniousGreenLine.Description = "Style de ligne avec nuance de vert harmonieuse"
    $HarmoniousGreenLine.Category = "Combinaisons harmonieuses"
    $HarmoniousGreenLine.AddTag("Couleur")
    $HarmoniousGreenLine.AddTag("Ligne")
    $HarmoniousGreenLine.AddTag("Harmonieux")
    $HarmoniousGreenLine.AddTag("Vert")
    $HarmoniousGreenLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#228B22")  # Vert forÃªt
    $HarmoniousGreenLine.IsBuiltIn = $true
    $Registry.Add($HarmoniousGreenLine) | Out-Null

    $HarmoniousPurpleLine = [ExcelLineStyle]::new()
    $HarmoniousPurpleLine.Name = "Ligne harmonieuse violette"
    $HarmoniousPurpleLine.Description = "Style de ligne avec nuance de violet harmonieuse"
    $HarmoniousPurpleLine.Category = "Combinaisons harmonieuses"
    $HarmoniousPurpleLine.AddTag("Couleur")
    $HarmoniousPurpleLine.AddTag("Ligne")
    $HarmoniousPurpleLine.AddTag("Harmonieux")
    $HarmoniousPurpleLine.AddTag("Violet")
    $HarmoniousPurpleLine.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#9370DB")  # Violet moyen
    $HarmoniousPurpleLine.IsBuiltIn = $true
    $Registry.Add($HarmoniousPurpleLine) | Out-Null

    # Ensembles de styles coordonnÃ©s pour sÃ©ries multiples
    $CoordinatedSet1Line1 = [ExcelLineStyle]::new()
    $CoordinatedSet1Line1.Name = "Ensemble 1 - Ligne 1"
    $CoordinatedSet1Line1.Description = "PremiÃ¨re ligne de l'ensemble coordonnÃ© 1"
    $CoordinatedSet1Line1.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet1Line1.AddTag("Couleur")
    $CoordinatedSet1Line1.AddTag("Ligne")
    $CoordinatedSet1Line1.AddTag("Ensemble")
    $CoordinatedSet1Line1.AddTag("Ensemble1")
    $CoordinatedSet1Line1.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#4682B4")  # Bleu acier
    $CoordinatedSet1Line1.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet1Line1) | Out-Null

    $CoordinatedSet1Line2 = [ExcelLineStyle]::new()
    $CoordinatedSet1Line2.Name = "Ensemble 1 - Ligne 2"
    $CoordinatedSet1Line2.Description = "DeuxiÃ¨me ligne de l'ensemble coordonnÃ© 1"
    $CoordinatedSet1Line2.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet1Line2.AddTag("Couleur")
    $CoordinatedSet1Line2.AddTag("Ligne")
    $CoordinatedSet1Line2.AddTag("Ensemble")
    $CoordinatedSet1Line2.AddTag("Ensemble1")
    $CoordinatedSet1Line2.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#B22222")  # Rouge brique
    $CoordinatedSet1Line2.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet1Line2) | Out-Null

    $CoordinatedSet1Line3 = [ExcelLineStyle]::new()
    $CoordinatedSet1Line3.Name = "Ensemble 1 - Ligne 3"
    $CoordinatedSet1Line3.Description = "TroisiÃ¨me ligne de l'ensemble coordonnÃ© 1"
    $CoordinatedSet1Line3.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet1Line3.AddTag("Couleur")
    $CoordinatedSet1Line3.AddTag("Ligne")
    $CoordinatedSet1Line3.AddTag("Ensemble")
    $CoordinatedSet1Line3.AddTag("Ensemble1")
    $CoordinatedSet1Line3.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#228B22")  # Vert forÃªt
    $CoordinatedSet1Line3.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet1Line3) | Out-Null

    $CoordinatedSet1Line4 = [ExcelLineStyle]::new()
    $CoordinatedSet1Line4.Name = "Ensemble 1 - Ligne 4"
    $CoordinatedSet1Line4.Description = "QuatriÃ¨me ligne de l'ensemble coordonnÃ© 1"
    $CoordinatedSet1Line4.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet1Line4.AddTag("Couleur")
    $CoordinatedSet1Line4.AddTag("Ligne")
    $CoordinatedSet1Line4.AddTag("Ensemble")
    $CoordinatedSet1Line4.AddTag("Ensemble1")
    $CoordinatedSet1Line4.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#DAA520")  # Or foncÃ©
    $CoordinatedSet1Line4.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet1Line4) | Out-Null

    # DeuxiÃ¨me ensemble coordonnÃ©
    $CoordinatedSet2Line1 = [ExcelLineStyle]::new()
    $CoordinatedSet2Line1.Name = "Ensemble 2 - Ligne 1"
    $CoordinatedSet2Line1.Description = "PremiÃ¨re ligne de l'ensemble coordonnÃ© 2"
    $CoordinatedSet2Line1.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet2Line1.AddTag("Couleur")
    $CoordinatedSet2Line1.AddTag("Ligne")
    $CoordinatedSet2Line1.AddTag("Ensemble")
    $CoordinatedSet2Line1.AddTag("Ensemble2")
    $CoordinatedSet2Line1.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#6A5ACD")  # Bleu ardoise
    $CoordinatedSet2Line1.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet2Line1) | Out-Null

    $CoordinatedSet2Line2 = [ExcelLineStyle]::new()
    $CoordinatedSet2Line2.Name = "Ensemble 2 - Ligne 2"
    $CoordinatedSet2Line2.Description = "DeuxiÃ¨me ligne de l'ensemble coordonnÃ© 2"
    $CoordinatedSet2Line2.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet2Line2.AddTag("Couleur")
    $CoordinatedSet2Line2.AddTag("Ligne")
    $CoordinatedSet2Line2.AddTag("Ensemble")
    $CoordinatedSet2Line2.AddTag("Ensemble2")
    $CoordinatedSet2Line2.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#FF6347")  # Tomate
    $CoordinatedSet2Line2.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet2Line2) | Out-Null

    $CoordinatedSet2Line3 = [ExcelLineStyle]::new()
    $CoordinatedSet2Line3.Name = "Ensemble 2 - Ligne 3"
    $CoordinatedSet2Line3.Description = "TroisiÃ¨me ligne de l'ensemble coordonnÃ© 2"
    $CoordinatedSet2Line3.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet2Line3.AddTag("Couleur")
    $CoordinatedSet2Line3.AddTag("Ligne")
    $CoordinatedSet2Line3.AddTag("Ensemble")
    $CoordinatedSet2Line3.AddTag("Ensemble2")
    $CoordinatedSet2Line3.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#3CB371")  # Vert mer moyen
    $CoordinatedSet2Line3.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet2Line3) | Out-Null

    $CoordinatedSet2Line4 = [ExcelLineStyle]::new()
    $CoordinatedSet2Line4.Name = "Ensemble 2 - Ligne 4"
    $CoordinatedSet2Line4.Description = "QuatriÃ¨me ligne de l'ensemble coordonnÃ© 2"
    $CoordinatedSet2Line4.Category = "Ensembles coordonnÃ©s"
    $CoordinatedSet2Line4.AddTag("Couleur")
    $CoordinatedSet2Line4.AddTag("Ligne")
    $CoordinatedSet2Line4.AddTag("Ensemble")
    $CoordinatedSet2Line4.AddTag("Ensemble2")
    $CoordinatedSet2Line4.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#FFD700")  # Or
    $CoordinatedSet2Line4.IsBuiltIn = $true
    $Registry.Add($CoordinatedSet2Line4) | Out-Null

    # Variations de couleur par type de ligne
    # Variations pour lignes continues
    $SolidBlueGradient = [ExcelLineStyle]::new()
    $SolidBlueGradient.Name = "Ligne continue dÃ©gradÃ© bleu"
    $SolidBlueGradient.Description = "Style de ligne continue avec dÃ©gradÃ© de bleu"
    $SolidBlueGradient.Category = "Variations par type"
    $SolidBlueGradient.AddTag("Couleur")
    $SolidBlueGradient.AddTag("Ligne")
    $SolidBlueGradient.AddTag("Continu")
    $SolidBlueGradient.AddTag("DÃ©gradÃ©")
    $SolidBlueGradient.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#4169E1")  # Bleu royal
    $SolidBlueGradient.LineConfig.GradientEnabled = $true
    $SolidBlueGradient.LineConfig.GradientEndColor = "#87CEEB"  # Bleu ciel
    $SolidBlueGradient.IsBuiltIn = $true
    $Registry.Add($SolidBlueGradient) | Out-Null

    $SolidRedGradient = [ExcelLineStyle]::new()
    $SolidRedGradient.Name = "Ligne continue dÃ©gradÃ© rouge"
    $SolidRedGradient.Description = "Style de ligne continue avec dÃ©gradÃ© de rouge"
    $SolidRedGradient.Category = "Variations par type"
    $SolidRedGradient.AddTag("Couleur")
    $SolidRedGradient.AddTag("Ligne")
    $SolidRedGradient.AddTag("Continu")
    $SolidRedGradient.AddTag("DÃ©gradÃ©")
    $SolidRedGradient.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#8B0000")  # Rouge foncÃ©
    $SolidRedGradient.LineConfig.GradientEnabled = $true
    $SolidRedGradient.LineConfig.GradientEndColor = "#FF6347"  # Tomate
    $SolidRedGradient.IsBuiltIn = $true
    $Registry.Add($SolidRedGradient) | Out-Null

    # Variations pour lignes pointillÃ©es
    $DottedGreenVariation = [ExcelLineStyle]::new()
    $DottedGreenVariation.Name = "PointillÃ©s verts variables"
    $DottedGreenVariation.Description = "Style de ligne pointillÃ©e avec variation de vert"
    $DottedGreenVariation.Category = "Variations par type"
    $DottedGreenVariation.AddTag("Couleur")
    $DottedGreenVariation.AddTag("Ligne")
    $DottedGreenVariation.AddTag("PointillÃ©")
    $DottedGreenVariation.AddTag("Variable")
    $DottedGreenVariation.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#006400")  # Vert foncÃ©
    $DottedGreenVariation.LineConfig.VariableColorEnabled = $true
    $DottedGreenVariation.LineConfig.VariableColors = @("#006400", "#228B22", "#32CD32", "#90EE90")  # Verts de foncÃ© Ã  clair
    $DottedGreenVariation.IsBuiltIn = $true
    $Registry.Add($DottedGreenVariation) | Out-Null

    $DottedPurpleVariation = [ExcelLineStyle]::new()
    $DottedPurpleVariation.Name = "PointillÃ©s violets variables"
    $DottedPurpleVariation.Description = "Style de ligne pointillÃ©e avec variation de violet"
    $DottedPurpleVariation.Category = "Variations par type"
    $DottedPurpleVariation.AddTag("Couleur")
    $DottedPurpleVariation.AddTag("Ligne")
    $DottedPurpleVariation.AddTag("PointillÃ©")
    $DottedPurpleVariation.AddTag("Variable")
    $DottedPurpleVariation.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dot, "#4B0082")  # Indigo
    $DottedPurpleVariation.LineConfig.VariableColorEnabled = $true
    $DottedPurpleVariation.LineConfig.VariableColors = @("#4B0082", "#800080", "#9370DB", "#BA55D3")  # Violets de foncÃ© Ã  clair
    $DottedPurpleVariation.IsBuiltIn = $true
    $Registry.Add($DottedPurpleVariation) | Out-Null

    # Variations pour lignes en tirets
    $DashedOrangeVariation = [ExcelLineStyle]::new()
    $DashedOrangeVariation.Name = "Tirets oranges variables"
    $DashedOrangeVariation.Description = "Style de ligne en tirets avec variation d'orange"
    $DashedOrangeVariation.Category = "Variations par type"
    $DashedOrangeVariation.AddTag("Couleur")
    $DashedOrangeVariation.AddTag("Ligne")
    $DashedOrangeVariation.AddTag("Tiret")
    $DashedOrangeVariation.AddTag("Variable")
    $DashedOrangeVariation.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#FF8C00")  # Orange foncÃ©
    $DashedOrangeVariation.LineConfig.VariableColorEnabled = $true
    $DashedOrangeVariation.LineConfig.VariableColors = @("#FF8C00", "#FFA500", "#FFD700")  # Oranges de foncÃ© Ã  clair
    $DashedOrangeVariation.IsBuiltIn = $true
    $Registry.Add($DashedOrangeVariation) | Out-Null

    # Variations pour lignes tiret-point
    $DashDotCyanVariation = [ExcelLineStyle]::new()
    $DashDotCyanVariation.Name = "Tiret-point cyan variable"
    $DashDotCyanVariation.Description = "Style de ligne tiret-point avec variation de cyan"
    $DashDotCyanVariation.Category = "Variations par type"
    $DashDotCyanVariation.AddTag("Couleur")
    $DashDotCyanVariation.AddTag("Ligne")
    $DashDotCyanVariation.AddTag("Tiret-point")
    $DashDotCyanVariation.AddTag("Variable")
    $DashDotCyanVariation.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::DashDot, "#008B8B")  # Cyan foncÃ©
    $DashDotCyanVariation.LineConfig.VariableColorEnabled = $true
    $DashDotCyanVariation.LineConfig.VariableColors = @("#008B8B", "#20B2AA", "#00CED1", "#AFEEEE")  # Cyans de foncÃ© Ã  clair
    $DashDotCyanVariation.IsBuiltIn = $true
    $Registry.Add($DashDotCyanVariation) | Out-Null

    # DÃ©gradÃ©s et variations de teintes
    $RainbowGradient = [ExcelLineStyle]::new()
    $RainbowGradient.Name = "DÃ©gradÃ© arc-en-ciel"
    $RainbowGradient.Description = "Style de ligne avec dÃ©gradÃ© arc-en-ciel"
    $RainbowGradient.Category = "DÃ©gradÃ©s spÃ©ciaux"
    $RainbowGradient.AddTag("Couleur")
    $RainbowGradient.AddTag("Ligne")
    $RainbowGradient.AddTag("DÃ©gradÃ©")
    $RainbowGradient.AddTag("Arc-en-ciel")
    $RainbowGradient.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#FF0000")  # Rouge
    $RainbowGradient.LineConfig.SpecialGradientEnabled = $true
    $RainbowGradient.LineConfig.SpecialGradientColors = @("#FF0000", "#FFA500", "#FFFF00", "#008000", "#0000FF", "#4B0082", "#800080")  # Couleurs arc-en-ciel
    $RainbowGradient.IsBuiltIn = $true
    $Registry.Add($RainbowGradient) | Out-Null

    $HeatMapGradient = [ExcelLineStyle]::new()
    $HeatMapGradient.Name = "DÃ©gradÃ© carte de chaleur"
    $HeatMapGradient.Description = "Style de ligne avec dÃ©gradÃ© type carte de chaleur"
    $HeatMapGradient.Category = "DÃ©gradÃ©s spÃ©ciaux"
    $HeatMapGradient.AddTag("Couleur")
    $HeatMapGradient.AddTag("Ligne")
    $HeatMapGradient.AddTag("DÃ©gradÃ©")
    $HeatMapGradient.AddTag("Chaleur")
    $HeatMapGradient.LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Solid, "#0000FF")  # Bleu
    $HeatMapGradient.LineConfig.SpecialGradientEnabled = $true
    $HeatMapGradient.LineConfig.SpecialGradientColors = @("#0000FF", "#00FFFF", "#00FF00", "#FFFF00", "#FF0000")  # Bleu Ã  rouge
    $HeatMapGradient.IsBuiltIn = $true
    $Registry.Add($HeatMapGradient) | Out-Null

    # Retourner le nombre de styles ajoutÃ©s
    return $Registry.LineStyles.Count
}

# Fonction pour obtenir un style de ligne prÃ©dÃ©fini par nom
function Get-ExcelPredefinedLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    $Registry = Get-ExcelStyleRegistry
    $Style = $Registry.GetByName($Name)

    if ($null -eq $Style -or -not ($Style -is [ExcelLineStyle])) {
        Write-Warning "Style de ligne '$Name' non trouvÃ©."
        return $null
    }

    return $Style
}

# Fonction pour obtenir tous les styles de ligne prÃ©dÃ©finis
function Get-ExcelPredefinedLineStyles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string]$Tag
    )

    $Registry = Get-ExcelStyleRegistry

    if (-not [string]::IsNullOrEmpty($Category) -and -not [string]::IsNullOrEmpty($Tag)) {
        $Criteria = @{
            Category = $Category
            Tag      = $Tag
            Type     = "Line"
        }
        return $Registry.Search($Criteria)
    } elseif (-not [string]::IsNullOrEmpty($Category)) {
        $Styles = $Registry.GetByCategory($Category)
        return $Styles | Where-Object { $_ -is [ExcelLineStyle] }
    } elseif (-not [string]::IsNullOrEmpty($Tag)) {
        $Styles = $Registry.GetByTag($Tag)
        return $Styles | Where-Object { $_ -is [ExcelLineStyle] }
    } else {
        return $Registry.GetByType("Line")
    }
}

# Fonction pour appliquer un style de ligne prÃ©dÃ©fini Ã  une sÃ©rie
function Set-ExcelChartSeriesPredefinedLineStyle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [int]$SeriesIndex,

        [Parameter(Mandatory = $true)]
        [string]$StyleName
    )

    # Obtenir le style prÃ©dÃ©fini
    $Style = Get-ExcelPredefinedLineStyle -Name $StyleName

    if ($null -eq $Style) {
        Write-Error "Style de ligne '$StyleName' non trouvÃ©."
        return $false
    }

    # Appliquer le style Ã  la sÃ©rie
    return Set-ExcelChartSeriesStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex $SeriesIndex -StyleId $Style.Id
}

<#
.SYNOPSIS
    Applique un ensemble de styles coordonnÃ©s Ã  plusieurs sÃ©ries d'un graphique Excel.
.DESCRIPTION
    Cette fonction applique un ensemble de styles coordonnÃ©s Ã  plusieurs sÃ©ries d'un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER SetName
    Le nom de l'ensemble coordonnÃ© Ã  appliquer ("Ensemble1", "Ensemble2", etc.).
.PARAMETER StartSeriesIndex
    L'index de la premiÃ¨re sÃ©rie Ã  modifier (0-basÃ©).
.PARAMETER MaxSeries
    Le nombre maximum de sÃ©ries Ã  modifier (par dÃ©faut: 4).
.EXAMPLE
    Set-ExcelChartSeriesCoordinatedSet -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -SetName "Ensemble1" -StartSeriesIndex 0
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesCoordinatedSet {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Ensemble1", "Ensemble2")]
        [string]$SetName,

        [Parameter(Mandatory = $false)]
        [int]$StartSeriesIndex = 0,

        [Parameter(Mandatory = $false)]
        [int]$MaxSeries = 4
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier le nombre de sÃ©ries disponibles
        $SeriesCount = $Chart.Series.Count
        if ($StartSeriesIndex -lt 0 -or $StartSeriesIndex -ge $SeriesCount) {
            throw "Index de sÃ©rie de dÃ©part invalide: $StartSeriesIndex. Le graphique contient $SeriesCount sÃ©ries."
        }

        # Limiter le nombre de sÃ©ries Ã  modifier
        $AvailableSeries = $SeriesCount - $StartSeriesIndex
        $SeriesToModify = [Math]::Min($MaxSeries, $AvailableSeries)

        # Obtenir les styles de l'ensemble coordonnÃ©
        $Registry = Get-ExcelStyleRegistry
        $Criteria = @{
            Category = "Ensembles coordonnÃ©s"
            Tag      = $SetName
        }
        $Styles = $Registry.Search($Criteria) | Sort-Object -Property Name

        if ($Styles.Count -eq 0) {
            throw "Ensemble coordonnÃ© '$SetName' non trouvÃ©."
        }

        # Appliquer les styles aux sÃ©ries
        $Success = $true
        for ($i = 0; $i -lt $SeriesToModify; $i++) {
            $SeriesIndex = $StartSeriesIndex + $i
            $StyleIndex = $i % $Styles.Count
            $Style = $Styles[$StyleIndex]

            $Result = Set-ExcelChartSeriesStyle -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName $ChartName -SeriesIndex $SeriesIndex -StyleId $Style.Id
            if (-not $Result) {
                $Success = $false
                Write-Warning "Ã‰chec de l'application du style Ã  la sÃ©rie $SeriesIndex."
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $Success
    } catch {
        Write-Error "Erreur lors de l'application de l'ensemble coordonnÃ©: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Applique un dÃ©gradÃ© de couleurs Ã  plusieurs sÃ©ries d'un graphique Excel.
.DESCRIPTION
    Cette fonction applique un dÃ©gradÃ© de couleurs Ã  plusieurs sÃ©ries d'un graphique Excel.
.PARAMETER Exporter
    L'exporteur Excel Ã  utiliser.
.PARAMETER WorkbookId
    L'identifiant du classeur contenant le graphique.
.PARAMETER WorksheetId
    L'identifiant de la feuille contenant le graphique.
.PARAMETER ChartName
    Le nom du graphique Ã  modifier.
.PARAMETER StartColor
    La couleur de dÃ©part du dÃ©gradÃ© au format hexadÃ©cimal (#RRGGBB).
.PARAMETER EndColor
    La couleur de fin du dÃ©gradÃ© au format hexadÃ©cimal (#RRGGBB).
.PARAMETER StartSeriesIndex
    L'index de la premiÃ¨re sÃ©rie Ã  modifier (0-basÃ©).
.PARAMETER SeriesCount
    Le nombre de sÃ©ries Ã  modifier.
.PARAMETER LineStyle
    Le style de ligne Ã  utiliser (Solid, Dash, Dot, DashDot, DashDotDot).
.PARAMETER LineWidth
    L'Ã©paisseur de la ligne (1-5).
.EXAMPLE
    Set-ExcelChartSeriesGradient -Exporter $Exporter -WorkbookId $WorkbookId -WorksheetId $WorksheetId -ChartName "MonGraphique" -StartColor "#FF0000" -EndColor "#0000FF" -StartSeriesIndex 0 -SeriesCount 5
.OUTPUTS
    System.Boolean - True si l'application a rÃ©ussi, False sinon.
#>
function Set-ExcelChartSeriesGradient {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ExcelExporter]$Exporter,

        [Parameter(Mandatory = $true)]
        [string]$WorkbookId,

        [Parameter(Mandatory = $true)]
        [string]$WorksheetId,

        [Parameter(Mandatory = $true)]
        [string]$ChartName,

        [Parameter(Mandatory = $true)]
        [string]$StartColor,

        [Parameter(Mandatory = $true)]
        [string]$EndColor,

        [Parameter(Mandatory = $false)]
        [int]$StartSeriesIndex = 0,

        [Parameter(Mandatory = $false)]
        [int]$SeriesCount = 5,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Solid", "Dash", "Dot", "DashDot", "DashDotDot")]
        [string]$LineStyle = "Solid",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$LineWidth = 2
    )

    try {
        # VÃ©rifier si le classeur existe
        if (-not $Exporter.WorkbookExists($WorkbookId)) {
            throw "Classeur non trouvÃ©: $WorkbookId"
        }

        # VÃ©rifier si la feuille existe
        if (-not $Exporter.WorksheetExists($WorkbookId, $WorksheetId)) {
            throw "Feuille de calcul non trouvÃ©e: $WorksheetId"
        }

        # VÃ©rifier le format des couleurs
        if (-not ($StartColor -match '^#[0-9A-Fa-f]{6}$') -or -not ($EndColor -match '^#[0-9A-Fa-f]{6}$')) {
            throw "Format de couleur invalide. Utilisez le format hexadÃ©cimal (#RRGGBB)."
        }

        # AccÃ©der au classeur et Ã  la feuille
        $Workbook = $Exporter._workbooks[$WorkbookId]
        $Worksheet = $Workbook.Worksheets[$WorksheetId]

        # Trouver le graphique
        $Chart = $null
        foreach ($Drawing in $Worksheet.Drawings) {
            if ($Drawing.Name -eq $ChartName -and $Drawing.GetType().Name -match "ExcelChart") {
                $Chart = $Drawing
                break
            }
        }

        if ($null -eq $Chart) {
            throw "Graphique non trouvÃ©: $ChartName"
        }

        # VÃ©rifier le nombre de sÃ©ries disponibles
        $AvailableSeriesCount = $Chart.Series.Count
        if ($StartSeriesIndex -lt 0 -or $StartSeriesIndex -ge $AvailableSeriesCount) {
            throw "Index de sÃ©rie de dÃ©part invalide: $StartSeriesIndex. Le graphique contient $AvailableSeriesCount sÃ©ries."
        }

        # Limiter le nombre de sÃ©ries Ã  modifier
        $MaxSeries = $AvailableSeriesCount - $StartSeriesIndex
        $ActualSeriesCount = [Math]::Min($SeriesCount, $MaxSeries)

        # Convertir les couleurs hexadÃ©cimales en composantes RGB
        $StartR = [Convert]::ToInt32($StartColor.Substring(1, 2), 16)
        $StartG = [Convert]::ToInt32($StartColor.Substring(3, 2), 16)
        $StartB = [Convert]::ToInt32($StartColor.Substring(5, 2), 16)

        $EndR = [Convert]::ToInt32($EndColor.Substring(1, 2), 16)
        $EndG = [Convert]::ToInt32($EndColor.Substring(3, 2), 16)
        $EndB = [Convert]::ToInt32($EndColor.Substring(5, 2), 16)

        # Appliquer le dÃ©gradÃ© aux sÃ©ries
        $Success = $true
        for ($i = 0; $i -lt $ActualSeriesCount; $i++) {
            $SeriesIndex = $StartSeriesIndex + $i
            $Series = $Chart.Series[$SeriesIndex]

            # Calculer la couleur intermÃ©diaire
            $Factor = if ($ActualSeriesCount -eq 1) { 0 } else { $i / ($ActualSeriesCount - 1) }
            $R = [Math]::Round($StartR + ($EndR - $StartR) * $Factor)
            $G = [Math]::Round($StartG + ($EndG - $StartG) * $Factor)
            $B = [Math]::Round($StartB + ($EndB - $StartB) * $Factor)

            # Convertir en format hexadÃ©cimal
            $Color = "#{0:X2}{1:X2}{2:X2}" -f $R, $G, $B

            # CrÃ©er un style de ligne personnalisÃ©
            $LineStyleEnum = [ExcelLineStyle]::$LineStyle
            $LineConfig = [ExcelLineStyleConfig]::new($LineWidth, $LineStyleEnum, $Color)

            # Appliquer le style Ã  la sÃ©rie
            try {
                $LineConfig.ApplyToSeries($Series)
            } catch {
                $Success = $false
                Write-Warning "Echec de l'application du style a la serie ${SeriesIndex}: $($_.Exception.Message)"
            }
        }

        # Sauvegarder le classeur
        Save-ExcelWorkbook -Exporter $Exporter -WorkbookId $WorkbookId | Out-Null

        return $Success
    } catch {
        Write-Error "Erreur lors de l'application du dÃ©gradÃ©: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Initialisation des styles prÃ©dÃ©finis

# Fonction pour initialiser tous les styles prÃ©dÃ©finis
function Initialize-ExcelPredefinedStyles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    $Registry = Get-ExcelStyleRegistry

    # VÃ©rifier si les styles sont dÃ©jÃ  initialisÃ©s
    $ExistingStyles = $Registry.Search(@{ IsBuiltIn = $true })

    if ($ExistingStyles.Count -gt 0 -and -not $Force) {
        Write-Verbose "Les styles prÃ©dÃ©finis sont dÃ©jÃ  initialisÃ©s. Utilisez -Force pour rÃ©initialiser."
        return $ExistingStyles.Count
    }

    # Supprimer les styles prÃ©dÃ©finis existants si Force est spÃ©cifiÃ©
    if ($Force) {
        foreach ($Style in $ExistingStyles) {
            $Registry.Remove($Style.Id) | Out-Null
        }
    }

    # Initialiser les styles de lignes classiques
    $LineStylesCount = Initialize-ExcelLineStyleLibrary -Registry $Registry

    # Retourner le nombre total de styles initialisÃ©s
    return $LineStylesCount
}

#endregion

#region Personnalisation des styles prÃ©dÃ©finis

<#
.SYNOPSIS
    CrÃ©e une copie modifiÃ©e d'un style de ligne prÃ©dÃ©fini.
.DESCRIPTION
    Cette fonction crÃ©e une copie modifiÃ©e d'un style de ligne prÃ©dÃ©fini en permettant
    de changer certaines propriÃ©tÃ©s comme la couleur, l'Ã©paisseur ou le style de ligne.
.PARAMETER Name
    Le nom du style prÃ©dÃ©fini Ã  copier.
.PARAMETER NewName
    Le nom du nouveau style personnalisÃ©.
.PARAMETER Description
    La description du nouveau style personnalisÃ©.
.PARAMETER Color
    La nouvelle couleur au format hexadÃ©cimal (#RRGGBB).
.PARAMETER Width
    La nouvelle Ã©paisseur de ligne (1-5).
.PARAMETER LineStyle
    Le nouveau style de ligne (Solid, Dash, Dot, DashDot, DashDotDot).
.PARAMETER Category
    La catÃ©gorie du nouveau style personnalisÃ©.
.PARAMETER Tags
    Les tags du nouveau style personnalisÃ©.
.EXAMPLE
    $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisÃ©e" -Color "#00FF00" -Width 3
.OUTPUTS
    ExcelLineStyle - Le nouveau style de ligne personnalisÃ©.
#>
function Copy-ExcelLineStyleWithModifications {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Width,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Solid", "Dash", "Dot", "DashDot", "DashDotDot")]
        [string]$LineStyle,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags
    )

    # Obtenir le style prÃ©dÃ©fini
    $OriginalStyle = Get-ExcelPredefinedLineStyle -Name $Name

    if ($null -eq $OriginalStyle) {
        Write-Error "Style de ligne '$Name' non trouvÃ©."
        return $null
    }

    # Cloner le style
    $NewStyle = $OriginalStyle.Clone() -as [ExcelLineStyle]

    # Modifier les propriÃ©tÃ©s
    $NewStyle.Name = $NewName
    $NewStyle.IsBuiltIn = $false

    if (-not [string]::IsNullOrEmpty($Description)) {
        $NewStyle.Description = $Description
    } else {
        $NewStyle.Description = "Personnalisation de $($OriginalStyle.Name)"
    }

    if (-not [string]::IsNullOrEmpty($Category)) {
        $NewStyle.Category = $Category
    } else {
        $NewStyle.Category = "Styles personnalisÃ©s"
    }

    # Modifier les tags
    if ($null -ne $Tags -and $Tags.Count -gt 0) {
        $NewStyle.Tags = @()
        foreach ($Tag in $Tags) {
            $NewStyle.AddTag($Tag)
        }
    }
    $NewStyle.AddTag("PersonnalisÃ©")

    # Modifier la configuration de ligne
    if (-not [string]::IsNullOrEmpty($Color)) {
        # VÃ©rifier le format de la couleur
        if ($Color -match '^#[0-9A-Fa-f]{6}$') {
            $NewStyle.LineConfig.Color = $Color
        } else {
            Write-Warning "Format de couleur invalide. Utilisation de la couleur d'origine."
        }
    }

    if ($Width -gt 0) {
        $NewStyle.LineConfig.Width = $Width
    }

    if (-not [string]::IsNullOrEmpty($LineStyle)) {
        $NewStyle.LineConfig.Style = [ExcelLineStyle]::$LineStyle
    }

    # Ajouter le nouveau style au registre
    $Registry = Get-ExcelStyleRegistry
    $Registry.Add($NewStyle) | Out-Null

    return $NewStyle
}

<#
.SYNOPSIS
    Modifie un style de ligne existant dans le registre.
.DESCRIPTION
    Cette fonction modifie un style de ligne existant dans le registre en permettant
    de changer certaines propriÃ©tÃ©s comme la couleur, l'Ã©paisseur ou le style de ligne.
.PARAMETER Id
    L'ID du style Ã  modifier.
.PARAMETER Name
    Le nouveau nom du style (optionnel).
.PARAMETER Description
    La nouvelle description du style (optionnel).
.PARAMETER Color
    La nouvelle couleur au format hexadÃ©cimal (#RRGGBB) (optionnel).
.PARAMETER Width
    La nouvelle Ã©paisseur de ligne (1-5) (optionnel).
.PARAMETER LineStyle
    Le nouveau style de ligne (Solid, Dash, Dot, DashDot, DashDotDot) (optionnel).
.PARAMETER Category
    La nouvelle catÃ©gorie du style (optionnel).
.PARAMETER Tags
    Les nouveaux tags du style (optionnel).
.EXAMPLE
    Edit-ExcelLineStyle -Id "12345678-1234-1234-1234-123456789012" -Color "#00FF00" -Width 3
.OUTPUTS
    System.Boolean - True si la modification a rÃ©ussi, False sinon.
#>
function Edit-ExcelLineStyle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Color,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Width,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Solid", "Dash", "Dot", "DashDot", "DashDotDot")]
        [string]$LineStyle,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags
    )

    process {
        # Obtenir le style existant
        $Registry = Get-ExcelStyleRegistry
        $Style = $Registry.GetById($Id)

        if ($null -eq $Style) {
            Write-Error "Style avec ID '$Id' non trouvÃ©."
            return $false
        }

        # VÃ©rifier que c'est un style de ligne
        if (-not ($Style -is [ExcelLineStyle])) {
            Write-Error "Le style avec ID '$Id' n'est pas un style de ligne."
            return $false
        }

        # Cloner le style pour les modifications
        $ModifiedStyle = $Style.Clone() -as [ExcelLineStyle]

        # Modifier les propriÃ©tÃ©s
        $Modified = $false

        if (-not [string]::IsNullOrEmpty($Name)) {
            $ModifiedStyle.Name = $Name
            $Modified = $true
        }

        if (-not [string]::IsNullOrEmpty($Description)) {
            $ModifiedStyle.Description = $Description
            $Modified = $true
        }

        if (-not [string]::IsNullOrEmpty($Category)) {
            $ModifiedStyle.Category = $Category
            $Modified = $true
        }

        # Modifier les tags
        if ($null -ne $Tags -and $Tags.Count -gt 0) {
            $ModifiedStyle.Tags = @()
            foreach ($Tag in $Tags) {
                $ModifiedStyle.AddTag($Tag)
            }
            $Modified = $true
        }

        # Modifier la configuration de ligne
        if (-not [string]::IsNullOrEmpty($Color)) {
            # VÃ©rifier le format de la couleur
            if ($Color -match '^#[0-9A-Fa-f]{6}$') {
                $ModifiedStyle.LineConfig.Color = $Color
                $Modified = $true
            } else {
                Write-Warning "Format de couleur invalide. Utilisation de la couleur d'origine."
            }
        }

        if ($Width -gt 0) {
            $ModifiedStyle.LineConfig.Width = $Width
            $Modified = $true
        }

        if (-not [string]::IsNullOrEmpty($LineStyle)) {
            $ModifiedStyle.LineConfig.Style = [ExcelLineStyle]::$LineStyle
            $Modified = $true
        }

        # Si aucune modification n'a Ã©tÃ© faite, retourner
        if (-not $Modified) {
            Write-Warning "Aucune modification n'a Ã©tÃ© spÃ©cifiÃ©e."
            return $true
        }

        # Mettre Ã  jour la date de modification
        $ModifiedStyle.ModifiedDate = [datetime]::Now

        # Confirmer la modification
        if ($PSCmdlet.ShouldProcess("Style de ligne '$($Style.Name)'", "Modifier")) {
            # Mettre Ã  jour le style dans le registre
            return $Registry.Update($Id, $ModifiedStyle)
        }

        return $false
    }
}

<#
.SYNOPSIS
    Supprime un style de ligne du registre.
.DESCRIPTION
    Cette fonction supprime un style de ligne du registre.
.PARAMETER Id
    L'ID du style Ã  supprimer.
.EXAMPLE
    Remove-ExcelLineStyle -Id "12345678-1234-1234-1234-123456789012"
.OUTPUTS
    System.Boolean - True si la suppression a rÃ©ussi, False sinon.
#>
function Remove-ExcelLineStyle {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$Id
    )

    process {
        # Obtenir le style existant
        $Registry = Get-ExcelStyleRegistry
        $Style = $Registry.GetById($Id)

        if ($null -eq $Style) {
            Write-Error "Style avec ID '$Id' non trouvÃ©."
            return $false
        }

        # VÃ©rifier que c'est un style de ligne
        if (-not ($Style -is [ExcelLineStyle])) {
            Write-Error "Le style avec ID '$Id' n'est pas un style de ligne."
            return $false
        }

        # VÃ©rifier si c'est un style prÃ©dÃ©fini
        if ($Style.IsBuiltIn) {
            Write-Error "Impossible de supprimer un style prÃ©dÃ©fini. Utilisez Copy-ExcelLineStyleWithModifications pour crÃ©er une copie modifiÃ©e."
            return $false
        }

        # Confirmer la suppression
        if ($PSCmdlet.ShouldProcess("Style de ligne '$($Style.Name)'", "Supprimer")) {
            # Supprimer le style du registre
            return $Registry.Remove($Id)
        }

        return $false
    }
}

<#
.SYNOPSIS
    Annule les modifications apportÃ©es Ã  un style de ligne.
.DESCRIPTION
    Cette fonction annule les modifications apportÃ©es Ã  un style de ligne en restaurant
    sa version prÃ©cÃ©dente depuis l'historique des modifications.
.PARAMETER Id
    L'ID du style Ã  restaurer.
.EXAMPLE
    Undo-ExcelLineStyleChanges -Id "12345678-1234-1234-1234-123456789012"
.OUTPUTS
    System.Boolean - True si la restauration a rÃ©ussi, False sinon.
#>
function Undo-ExcelLineStyleChanges {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$Id
    )

    process {
        # Obtenir le style existant
        $Registry = Get-ExcelStyleRegistry
        $Style = $Registry.GetById($Id)

        if ($null -eq $Style) {
            Write-Error "Style avec ID '$Id' non trouvÃ©."
            return $false
        }

        # VÃ©rifier que c'est un style de ligne
        if (-not ($Style -is [ExcelLineStyle])) {
            Write-Error "Le style avec ID '$Id' n'est pas un style de ligne."
            return $false
        }

        # VÃ©rifier si c'est un style prÃ©dÃ©fini
        if ($Style.IsBuiltIn) {
            Write-Error "Impossible d'annuler les modifications d'un style prÃ©dÃ©fini."
            return $false
        }

        # VÃ©rifier si l'historique des modifications existe
        if (-not $Registry.HasHistory($Id)) {
            Write-Error "Aucun historique de modifications trouvÃ© pour le style avec ID '$Id'."
            return $false
        }

        # Confirmer la restauration
        if ($PSCmdlet.ShouldProcess("Style de ligne '$($Style.Name)'", "Annuler les modifications")) {
            # Restaurer la version prÃ©cÃ©dente du style
            return $Registry.RestorePreviousVersion($Id)
        }

        return $false
    }
}

#endregion

#region Sauvegarde des styles personnalisÃ©s

<#
.SYNOPSIS
    Exporte les styles personnalisÃ©s vers un fichier JSON.
.DESCRIPTION
    Cette fonction exporte les styles personnalisÃ©s (non prÃ©dÃ©finis) vers un fichier JSON
    pour permettre leur rÃ©utilisation ultÃ©rieure.
.PARAMETER Path
    Le chemin du fichier JSON oÃ¹ exporter les styles.
.PARAMETER IncludeBuiltIn
    Indique si les styles prÃ©dÃ©finis doivent Ã©galement Ãªtre exportÃ©s.
.PARAMETER Category
    Filtre les styles Ã  exporter par catÃ©gorie.
.PARAMETER Tag
    Filtre les styles Ã  exporter par tag.
.PARAMETER Force
    Ã‰crase le fichier s'il existe dÃ©jÃ .
.EXAMPLE
    Export-ExcelStyles -Path "C:\Styles\MesStyles.json"
.OUTPUTS
    System.Int32 - Le nombre de styles exportÃ©s.
#>
function Export-ExcelStyles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeBuiltIn,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string]$Tag,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if (Test-Path -Path $Path) {
        if (-not $Force) {
            Write-Error "Le fichier '$Path' existe dÃ©jÃ . Utilisez -Force pour Ã©craser."
            return 0
        } elseif (-not $PSCmdlet.ShouldProcess($Path, "Remplacer le fichier existant")) {
            return 0
        }
    }

    # Obtenir le registre de styles
    $Registry = Get-ExcelStyleRegistry

    # CrÃ©er les critÃ¨res de recherche
    $Criteria = @{}

    if (-not $IncludeBuiltIn) {
        $Criteria.IsBuiltIn = $false
    }

    if (-not [string]::IsNullOrEmpty($Category)) {
        $Criteria.Category = $Category
    }

    if (-not [string]::IsNullOrEmpty($Tag)) {
        $Criteria.Tag = $Tag
    }

    # Obtenir les styles Ã  exporter
    $Styles = $Registry.Search($Criteria)

    if ($Styles.Count -eq 0) {
        Write-Warning "Aucun style trouvÃ© correspondant aux critÃ¨res."
        return 0
    }

    # Convertir les styles en objets sÃ©rialisables
    $ExportData = @{
        Version    = "1.0"
        ExportDate = [datetime]::Now.ToString("o")
        Styles     = @()
    }

    foreach ($Style in $Styles) {
        $StyleData = @{
            Id          = $Style.Id
            Name        = $Style.Name
            Description = $Style.Description
            Category    = $Style.Category
            Tags        = $Style.Tags
            IsBuiltIn   = $Style.IsBuiltIn
            Type        = $Style.GetType().Name
        }

        # Ajouter les propriÃ©tÃ©s spÃ©cifiques au type de style
        if ($Style -is [ExcelLineStyle]) {
            $StyleData.LineConfig = @{
                Width                  = $Style.LineConfig.Width
                Style                  = $Style.LineConfig.Style.ToString()
                Color                  = $Style.LineConfig.Color
                DashType               = $Style.LineConfig.DashType
                SpacingFactor          = $Style.LineConfig.SpacingFactor
                ProgressionFactor      = $Style.LineConfig.ProgressionFactor
                ProportionFactor       = $Style.LineConfig.ProportionFactor
                Pattern                = $Style.LineConfig.Pattern
                GradientEnabled        = $Style.LineConfig.GradientEnabled
                GradientEndColor       = $Style.LineConfig.GradientEndColor
                VariableColorEnabled   = $Style.LineConfig.VariableColorEnabled
                VariableColors         = $Style.LineConfig.VariableColors
                SpecialGradientEnabled = $Style.LineConfig.SpecialGradientEnabled
                SpecialGradientColors  = $Style.LineConfig.SpecialGradientColors
            }
        } elseif ($Style -is [ExcelMarkerStyle]) {
            $StyleData.MarkerConfig = @{
                Type        = $Style.MarkerConfig.Type.ToString()
                Size        = $Style.MarkerConfig.Size
                Color       = $Style.MarkerConfig.Color
                BorderColor = $Style.MarkerConfig.BorderColor
                BorderWidth = $Style.MarkerConfig.BorderWidth
            }
        } elseif ($Style -is [ExcelBorderStyle]) {
            $StyleData.BorderConfig = @{
                Width = $Style.BorderConfig.Width
                Style = $Style.BorderConfig.Style.ToString()
                Color = $Style.BorderConfig.Color
            }
        } elseif ($Style -is [ExcelColorStyle]) {
            $StyleData.Colors = $Style.Colors
            $StyleData.PrimaryColor = $Style.PrimaryColor
            $StyleData.SecondaryColor = $Style.SecondaryColor
            $StyleData.AccentColor = $Style.AccentColor
        } elseif ($Style -is [ExcelCombinedStyle]) {
            $StyleData.LineStyleId = $Style.LineStyle?.Id
            $StyleData.MarkerStyleId = $Style.MarkerStyle?.Id
            $StyleData.BorderStyleId = $Style.BorderStyle?.Id
            $StyleData.ColorStyleId = $Style.ColorStyle?.Id
        }

        $ExportData.Styles += $StyleData
    }

    # SÃ©rialiser et enregistrer les donnÃ©es
    try {
        $JsonData = ConvertTo-Json -InputObject $ExportData -Depth 10
        Set-Content -Path $Path -Value $JsonData -Encoding UTF8
        Write-Verbose "$($Styles.Count) styles exportÃ©s vers '$Path'."
        return $Styles.Count
    } catch {
        Write-Error "Erreur lors de l'exportation des styles: $($_.Exception.Message)"
        return 0
    }
}

<#
.SYNOPSIS
    Importe des styles depuis un fichier JSON.
.DESCRIPTION
    Cette fonction importe des styles depuis un fichier JSON prÃ©cÃ©demment crÃ©Ã© avec Export-ExcelStyles.
.PARAMETER Path
    Le chemin du fichier JSON contenant les styles Ã  importer.
.PARAMETER SkipExisting
    Ne pas remplacer les styles existants avec le mÃªme ID.
.PARAMETER Category
    Filtre les styles Ã  importer par catÃ©gorie.
.PARAMETER Tag
    Filtre les styles Ã  importer par tag.
.EXAMPLE
    Import-ExcelStyles -Path "C:\Styles\MesStyles.json"
.OUTPUTS
    System.Int32 - Le nombre de styles importÃ©s.
#>
function Import-ExcelStyles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$SkipExisting,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string]$Tag
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return 0
    }

    # Lire et dÃ©sÃ©rialiser le fichier
    try {
        $JsonData = Get-Content -Path $Path -Encoding UTF8 -Raw
        $ImportData = ConvertFrom-Json -InputObject $JsonData
    } catch {
        Write-Error "Erreur lors de la lecture du fichier: $($_.Exception.Message)"
        return 0
    }

    # VÃ©rifier la version du format
    if (-not $ImportData.Version) {
        Write-Error "Format de fichier non reconnu."
        return 0
    }

    # Obtenir le registre de styles
    $Registry = Get-ExcelStyleRegistry

    # Compteur de styles importÃ©s
    $ImportedCount = 0

    # Importer les styles
    foreach ($StyleData in $ImportData.Styles) {
        # Filtrer par catÃ©gorie si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Category) -and $StyleData.Category -ne $Category) {
            continue
        }

        # Filtrer par tag si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Tag)) {
            $HasTag = $false
            foreach ($StyleTag in $StyleData.Tags) {
                if ($StyleTag -eq $Tag) {
                    $HasTag = $true
                    break
                }
            }
            if (-not $HasTag) {
                continue
            }
        }

        # VÃ©rifier si le style existe dÃ©jÃ 
        $ExistingStyle = $Registry.GetById($StyleData.Id)
        if ($null -ne $ExistingStyle -and $SkipExisting) {
            Write-Verbose "Style '$($StyleData.Name)' dÃ©jÃ  existant, ignorÃ©."
            continue
        }

        # CrÃ©er le style en fonction de son type
        $Style = $null

        switch ($StyleData.Type) {
            "ExcelLineStyle" {
                $Style = [ExcelLineStyle]::new()
                $Style.Id = $StyleData.Id
                $Style.Name = $StyleData.Name
                $Style.Description = $StyleData.Description
                $Style.Category = $StyleData.Category
                $Style.IsBuiltIn = $StyleData.IsBuiltIn

                # Configurer les propriÃ©tÃ©s spÃ©cifiques
                $Style.LineConfig = [ExcelLineStyleConfig]::new()
                $Style.LineConfig.Width = $StyleData.LineConfig.Width
                $Style.LineConfig.Style = [ExcelLineStyle]::($StyleData.LineConfig.Style)
                $Style.LineConfig.Color = $StyleData.LineConfig.Color
                $Style.LineConfig.DashType = $StyleData.LineConfig.DashType
                $Style.LineConfig.SpacingFactor = $StyleData.LineConfig.SpacingFactor
                $Style.LineConfig.ProgressionFactor = $StyleData.LineConfig.ProgressionFactor
                $Style.LineConfig.ProportionFactor = $StyleData.LineConfig.ProportionFactor
                $Style.LineConfig.Pattern = $StyleData.LineConfig.Pattern
                $Style.LineConfig.GradientEnabled = $StyleData.LineConfig.GradientEnabled
                $Style.LineConfig.GradientEndColor = $StyleData.LineConfig.GradientEndColor
                $Style.LineConfig.VariableColorEnabled = $StyleData.LineConfig.VariableColorEnabled
                $Style.LineConfig.VariableColors = $StyleData.LineConfig.VariableColors
                $Style.LineConfig.SpecialGradientEnabled = $StyleData.LineConfig.SpecialGradientEnabled
                $Style.LineConfig.SpecialGradientColors = $StyleData.LineConfig.SpecialGradientColors
            }
            "ExcelMarkerStyle" {
                $Style = [ExcelMarkerStyle]::new()
                $Style.Id = $StyleData.Id
                $Style.Name = $StyleData.Name
                $Style.Description = $StyleData.Description
                $Style.Category = $StyleData.Category
                $Style.IsBuiltIn = $StyleData.IsBuiltIn

                # Configurer les propriÃ©tÃ©s spÃ©cifiques
                $Style.MarkerConfig = [ExcelMarkerConfig]::new()
                $Style.MarkerConfig.Type = [ExcelMarkerStyle]::($StyleData.MarkerConfig.Type)
                $Style.MarkerConfig.Size = $StyleData.MarkerConfig.Size
                $Style.MarkerConfig.Color = $StyleData.MarkerConfig.Color
                $Style.MarkerConfig.BorderColor = $StyleData.MarkerConfig.BorderColor
                $Style.MarkerConfig.BorderWidth = $StyleData.MarkerConfig.BorderWidth
            }
            "ExcelBorderStyle" {
                $Style = [ExcelBorderStyle]::new()
                $Style.Id = $StyleData.Id
                $Style.Name = $StyleData.Name
                $Style.Description = $StyleData.Description
                $Style.Category = $StyleData.Category
                $Style.IsBuiltIn = $StyleData.IsBuiltIn

                # Configurer les propriÃ©tÃ©s spÃ©cifiques
                $Style.BorderConfig = [ExcelBorderStyleConfig]::new()
                $Style.BorderConfig.Width = $StyleData.BorderConfig.Width
                $Style.BorderConfig.Style = [ExcelBorderStyle]::($StyleData.BorderConfig.Style)
                $Style.BorderConfig.Color = $StyleData.BorderConfig.Color
            }
            "ExcelColorStyle" {
                $Style = [ExcelColorStyle]::new()
                $Style.Id = $StyleData.Id
                $Style.Name = $StyleData.Name
                $Style.Description = $StyleData.Description
                $Style.Category = $StyleData.Category
                $Style.IsBuiltIn = $StyleData.IsBuiltIn

                # Configurer les propriÃ©tÃ©s spÃ©cifiques
                $Style.Colors = $StyleData.Colors
                $Style.PrimaryColor = $StyleData.PrimaryColor
                $Style.SecondaryColor = $StyleData.SecondaryColor
                $Style.AccentColor = $StyleData.AccentColor
            }
            "ExcelCombinedStyle" {
                $Style = [ExcelCombinedStyle]::new()
                $Style.Id = $StyleData.Id
                $Style.Name = $StyleData.Name
                $Style.Description = $StyleData.Description
                $Style.Category = $StyleData.Category
                $Style.IsBuiltIn = $StyleData.IsBuiltIn

                # Configurer les propriÃ©tÃ©s spÃ©cifiques
                if (-not [string]::IsNullOrEmpty($StyleData.LineStyleId)) {
                    $Style.LineStyle = $Registry.GetById($StyleData.LineStyleId)
                }
                if (-not [string]::IsNullOrEmpty($StyleData.MarkerStyleId)) {
                    $Style.MarkerStyle = $Registry.GetById($StyleData.MarkerStyleId)
                }
                if (-not [string]::IsNullOrEmpty($StyleData.BorderStyleId)) {
                    $Style.BorderStyle = $Registry.GetById($StyleData.BorderStyleId)
                }
                if (-not [string]::IsNullOrEmpty($StyleData.ColorStyleId)) {
                    $Style.ColorStyle = $Registry.GetById($StyleData.ColorStyleId)
                }
            }
            default {
                Write-Warning "Type de style non reconnu: $($StyleData.Type)"
                continue
            }
        }

        # Ajouter les tags
        foreach ($Tag in $StyleData.Tags) {
            $Style.AddTag($Tag)
        }

        # Ajouter ou mettre Ã  jour le style dans le registre
        if ($null -ne $ExistingStyle) {
            if ($PSCmdlet.ShouldProcess("Style '$($StyleData.Name)'", "Remplacer")) {
                $Registry.Update($StyleData.Id, $Style) | Out-Null
                $ImportedCount++
            }
        } else {
            if ($PSCmdlet.ShouldProcess("Style '$($StyleData.Name)'", "Importer")) {
                $Registry.Add($Style) | Out-Null
                $ImportedCount++
            }
        }
    }

    Write-Verbose "$ImportedCount styles importÃ©s depuis '$Path'."
    return $ImportedCount
}

<#
.SYNOPSIS
    Sauvegarde les styles personnalisÃ©s dans un fichier de configuration.
.DESCRIPTION
    Cette fonction sauvegarde les styles personnalisÃ©s dans un fichier de configuration
    qui sera automatiquement chargÃ© au dÃ©marrage.
.PARAMETER Path
    Le chemin du fichier de configuration oÃ¹ sauvegarder les styles.
    Si non spÃ©cifiÃ©, utilise le fichier de configuration par dÃ©faut.
.PARAMETER IncludeBuiltIn
    Indique si les styles prÃ©dÃ©finis doivent Ã©galement Ãªtre sauvegardÃ©s.
.PARAMETER Force
    Ã‰crase le fichier s'il existe dÃ©jÃ .
.EXAMPLE
    Save-ExcelStylesConfiguration
.OUTPUTS
    System.Int32 - Le nombre de styles sauvegardÃ©s.
#>
function Save-ExcelStylesConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeBuiltIn,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # DÃ©terminer le chemin du fichier de configuration
    if ([string]::IsNullOrEmpty($Path)) {
        $ConfigDir = Join-Path -Path $env:APPDATA -ChildPath "ExcelStyles"
        if (-not (Test-Path -Path $ConfigDir)) {
            New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
        }
        $Path = Join-Path -Path $ConfigDir -ChildPath "UserStyles.json"
    }

    # Exporter les styles
    $ExportParams = @{
        Path           = $Path
        IncludeBuiltIn = $IncludeBuiltIn
        Force          = $Force
    }

    if ($PSCmdlet.ShouldProcess($Path, "Sauvegarder la configuration des styles")) {
        return Export-ExcelStyles @ExportParams
    }

    return 0
}

<#
.SYNOPSIS
    Charge les styles personnalisÃ©s depuis un fichier de configuration.
.DESCRIPTION
    Cette fonction charge les styles personnalisÃ©s depuis un fichier de configuration.
.PARAMETER Path
    Le chemin du fichier de configuration contenant les styles.
    Si non spÃ©cifiÃ©, utilise le fichier de configuration par dÃ©faut.
.PARAMETER SkipExisting
    Ne pas remplacer les styles existants avec le mÃªme ID.
.EXAMPLE
    Import-ExcelStylesConfiguration
.OUTPUTS
    System.Int32 - Le nombre de styles chargÃ©s.
#>
function Import-ExcelStylesConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$SkipExisting
    )

    # DÃ©terminer le chemin du fichier de configuration
    if ([string]::IsNullOrEmpty($Path)) {
        $ConfigDir = Join-Path -Path $env:APPDATA -ChildPath "ExcelStyles"
        $Path = Join-Path -Path $ConfigDir -ChildPath "UserStyles.json"
    }

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Warning "Le fichier de configuration '$Path' n'existe pas."
        return 0
    }

    # Importer les styles
    $ImportParams = @{
        Path         = $Path
        SkipExisting = $SkipExisting
    }

    if ($PSCmdlet.ShouldProcess($Path, "Charger la configuration des styles")) {
        return Import-ExcelStyles @ImportParams
    }

    return 0
}

#endregion

#region Fusion entre styles

# StratÃ©gie de fusion par dÃ©faut
$script:DefaultMergeStrategy = "MergeNonNull"

# RÃ¨gles de fusion personnalisÃ©es
$script:MergeRules = @{}

# PrioritÃ© des rÃ¨gles de fusion
$script:MergeRulePriorities = @{}

<#
.SYNOPSIS
    DÃ©finit la stratÃ©gie de fusion par dÃ©faut pour les styles Excel.
.DESCRIPTION
    Cette fonction dÃ©finit la stratÃ©gie de fusion par dÃ©faut qui sera utilisÃ©e
    lorsqu'aucune stratÃ©gie n'est spÃ©cifiÃ©e lors de la fusion de styles.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser par dÃ©faut (SourceWins, TargetWins, MergeNonNull).
.EXAMPLE
    Set-ExcelStyleMergeDefaultStrategy -Strategy "SourceWins"
.OUTPUTS
    System.String - La stratÃ©gie de fusion prÃ©cÃ©demment dÃ©finie.
#>
function Set-ExcelStyleMergeDefaultStrategy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull")]
        [string]$Strategy
    )

    $OldStrategy = $script:DefaultMergeStrategy
    $script:DefaultMergeStrategy = $Strategy

    Write-Verbose "StratÃ©gie de fusion par dÃ©faut changÃ©e de '$OldStrategy' Ã  '$Strategy'."

    return $OldStrategy
}

<#
.SYNOPSIS
    Obtient la stratÃ©gie de fusion par dÃ©faut pour les styles Excel.
.DESCRIPTION
    Cette fonction retourne la stratÃ©gie de fusion par dÃ©faut qui est utilisÃ©e
    lorsqu'aucune stratÃ©gie n'est spÃ©cifiÃ©e lors de la fusion de styles.
.EXAMPLE
    $Strategy = Get-ExcelStyleMergeDefaultStrategy
.OUTPUTS
    System.String - La stratÃ©gie de fusion par dÃ©faut.
#>
function Get-ExcelStyleMergeDefaultStrategy {
    [CmdletBinding()]
    param ()

    return $script:DefaultMergeStrategy
}

<#
.SYNOPSIS
    DÃ©finit une rÃ¨gle de fusion personnalisÃ©e pour les styles Excel.
.DESCRIPTION
    Cette fonction dÃ©finit une rÃ¨gle de fusion personnalisÃ©e qui sera utilisÃ©e
    lors de la fusion de styles pour dÃ©terminer comment fusionner une propriÃ©tÃ© spÃ©cifique.
.PARAMETER RuleName
    Le nom de la rÃ¨gle de fusion.
.PARAMETER PropertyName
    Le nom de la propriÃ©tÃ© Ã  laquelle la rÃ¨gle s'applique.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser pour cette propriÃ©tÃ© (SourceWins, TargetWins, MergeNonNull, MergeAll, Manual).
.PARAMETER Priority
    La prioritÃ© de la rÃ¨gle (plus la valeur est Ã©levÃ©e, plus la prioritÃ© est Ã©levÃ©e).
.PARAMETER Condition
    Une expression de condition qui dÃ©termine si la rÃ¨gle doit Ãªtre appliquÃ©e.
.EXAMPLE
    Set-ExcelStyleMergeRule -RuleName "ColorRule" -PropertyName "Color" -Strategy "SourceWins" -Priority 10
.OUTPUTS
    System.Boolean - True si la rÃ¨gle a Ã©tÃ© dÃ©finie avec succÃ¨s, False sinon.
#>
function Set-ExcelStyleMergeRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RuleName,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "MergeAll", "Manual")]
        [string]$Strategy,

        [Parameter(Mandatory = $false)]
        [int]$Priority = 0,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition
    )

    # CrÃ©er la rÃ¨gle
    $Rule = @{
        PropertyName = $PropertyName
        Strategy     = $Strategy
        Priority     = $Priority
        Condition    = $Condition
    }

    # Ajouter ou mettre Ã  jour la rÃ¨gle
    $script:MergeRules[$RuleName] = $Rule

    # Mettre Ã  jour la prioritÃ© de la rÃ¨gle
    $script:MergeRulePriorities[$RuleName] = $Priority

    Write-Verbose "RÃ¨gle de fusion '$RuleName' dÃ©finie pour la propriÃ©tÃ© '$PropertyName' avec la stratÃ©gie '$Strategy' et la prioritÃ© $Priority."

    return $true
}

<#
.SYNOPSIS
    Supprime une rÃ¨gle de fusion personnalisÃ©e pour les styles Excel.
.DESCRIPTION
    Cette fonction supprime une rÃ¨gle de fusion personnalisÃ©e.
.PARAMETER RuleName
    Le nom de la rÃ¨gle de fusion Ã  supprimer.
.EXAMPLE
    Remove-ExcelStyleMergeRule -RuleName "ColorRule"
.OUTPUTS
    System.Boolean - True si la rÃ¨gle a Ã©tÃ© supprimÃ©e avec succÃ¨s, False sinon.
#>
function Remove-ExcelStyleMergeRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RuleName
    )

    # VÃ©rifier si la rÃ¨gle existe
    if (-not $script:MergeRules.ContainsKey($RuleName)) {
        Write-Warning "La rÃ¨gle de fusion '$RuleName' n'existe pas."
        return $false
    }

    # Supprimer la rÃ¨gle
    $script:MergeRules.Remove($RuleName) | Out-Null
    $script:MergeRulePriorities.Remove($RuleName) | Out-Null

    Write-Verbose "RÃ¨gle de fusion '$RuleName' supprimÃ©e."

    return $true
}

<#
.SYNOPSIS
    Obtient une rÃ¨gle de fusion personnalisÃ©e pour les styles Excel.
.DESCRIPTION
    Cette fonction retourne une rÃ¨gle de fusion personnalisÃ©e.
.PARAMETER RuleName
    Le nom de la rÃ¨gle de fusion Ã  obtenir.
.EXAMPLE
    $Rule = Get-ExcelStyleMergeRule -RuleName "ColorRule"
.OUTPUTS
    System.Collections.Hashtable - La rÃ¨gle de fusion.
#>
function Get-ExcelStyleMergeRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RuleName
    )

    # VÃ©rifier si la rÃ¨gle existe
    if (-not $script:MergeRules.ContainsKey($RuleName)) {
        Write-Warning "La rÃ¨gle de fusion '$RuleName' n'existe pas."
        return $null
    }

    # Retourner la rÃ¨gle
    return $script:MergeRules[$RuleName]
}

<#
.SYNOPSIS
    Obtient toutes les rÃ¨gles de fusion personnalisÃ©es pour les styles Excel.
.DESCRIPTION
    Cette fonction retourne toutes les rÃ¨gles de fusion personnalisÃ©es.
.PARAMETER PropertyName
    Filtre les rÃ¨gles par nom de propriÃ©tÃ©.
.EXAMPLE
    $Rules = Get-ExcelStyleMergeRules
.OUTPUTS
    System.Collections.Hashtable[] - Les rÃ¨gles de fusion.
#>
function Get-ExcelStyleMergeRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PropertyName
    )

    # Filtrer les rÃ¨gles par nom de propriÃ©tÃ© si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($PropertyName)) {
        $FilteredRules = @{}
        foreach ($RuleName in $script:MergeRules.Keys) {
            $Rule = $script:MergeRules[$RuleName]
            if ($Rule.PropertyName -eq $PropertyName) {
                $FilteredRules[$RuleName] = $Rule
            }
        }
        return $FilteredRules
    }

    # Retourner toutes les rÃ¨gles
    return $script:MergeRules
}

<#
.SYNOPSIS
    DÃ©finit la prioritÃ© d'une rÃ¨gle de fusion.
.DESCRIPTION
    Cette fonction dÃ©finit la prioritÃ© d'une rÃ¨gle de fusion.
.PARAMETER RuleName
    Le nom de la rÃ¨gle de fusion.
.PARAMETER Priority
    La prioritÃ© de la rÃ¨gle (plus la valeur est Ã©levÃ©e, plus la prioritÃ© est Ã©levÃ©e).
.EXAMPLE
    Set-ExcelStyleMergeRulePriority -RuleName "ColorRule" -Priority 20
.OUTPUTS
    System.Boolean - True si la prioritÃ© a Ã©tÃ© dÃ©finie avec succÃ¨s, False sinon.
#>
function Set-ExcelStyleMergeRulePriority {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RuleName,

        [Parameter(Mandatory = $true)]
        [int]$Priority
    )

    # VÃ©rifier si la rÃ¨gle existe
    if (-not $script:MergeRules.ContainsKey($RuleName)) {
        Write-Warning "La rÃ¨gle de fusion '$RuleName' n'existe pas."
        return $false
    }

    # Mettre Ã  jour la prioritÃ© de la rÃ¨gle
    $script:MergeRules[$RuleName].Priority = $Priority
    $script:MergeRulePriorities[$RuleName] = $Priority

    Write-Verbose "PrioritÃ© de la rÃ¨gle de fusion '$RuleName' dÃ©finie Ã  $Priority."

    return $true
}

<#
.SYNOPSIS
    Obtient la prioritÃ© d'une rÃ¨gle de fusion.
.DESCRIPTION
    Cette fonction retourne la prioritÃ© d'une rÃ¨gle de fusion.
.PARAMETER RuleName
    Le nom de la rÃ¨gle de fusion.
.EXAMPLE
    $Priority = Get-ExcelStyleMergeRulePriority -RuleName "ColorRule"
.OUTPUTS
    System.Int32 - La prioritÃ© de la rÃ¨gle.
#>
function Get-ExcelStyleMergeRulePriority {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RuleName
    )

    # VÃ©rifier si la rÃ¨gle existe
    if (-not $script:MergeRules.ContainsKey($RuleName)) {
        Write-Warning "La rÃ¨gle de fusion '$RuleName' n'existe pas."
        return -1
    }

    # Retourner la prioritÃ© de la rÃ¨gle
    return $script:MergeRules[$RuleName].Priority
}

<#
.SYNOPSIS
    DÃ©finit une rÃ¨gle de fusion par dÃ©faut pour une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction dÃ©finit une rÃ¨gle de fusion par dÃ©faut pour une propriÃ©tÃ©.
.PARAMETER PropertyName
    Le nom de la propriÃ©tÃ©.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser par dÃ©faut pour cette propriÃ©tÃ©.
.PARAMETER Priority
    La prioritÃ© de la rÃ¨gle (par dÃ©faut: -10, prioritÃ© basse pour permettre aux autres rÃ¨gles de la remplacer).
.EXAMPLE
    Set-ExcelStyleMergeDefaultRule -PropertyName "Color" -Strategy "SourceWins"
.OUTPUTS
    System.Boolean - True si la rÃ¨gle a Ã©tÃ© dÃ©finie avec succÃ¨s, False sinon.
#>
function Set-ExcelStyleMergeDefaultRule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "MergeAll", "Manual")]
        [string]$Strategy,

        [Parameter(Mandatory = $false)]
        [int]$Priority = -10
    )

    # CrÃ©er le nom de la rÃ¨gle par dÃ©faut
    $RuleName = "Default_${PropertyName}"

    # DÃ©finir la rÃ¨gle
    return Set-ExcelStyleMergeRule -RuleName $RuleName -PropertyName $PropertyName -Strategy $Strategy -Priority $Priority
}

<#
.SYNOPSIS
    Exporte les rÃ¨gles de fusion vers un fichier JSON.
.DESCRIPTION
    Cette fonction exporte les rÃ¨gles de fusion vers un fichier JSON.
.PARAMETER Path
    Le chemin du fichier JSON oÃ¹ exporter les rÃ¨gles.
.PARAMETER PropertyName
    Filtre les rÃ¨gles par nom de propriÃ©tÃ©.
.PARAMETER Force
    Ã‰crase le fichier s'il existe dÃ©jÃ .
.EXAMPLE
    Export-ExcelStyleMergeRules -Path "C:\Rules\MesRegles.json"
.OUTPUTS
    System.Int32 - Le nombre de rÃ¨gles exportÃ©es.
#>
function Export-ExcelStyleMergeRules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$PropertyName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if (Test-Path -Path $Path) {
        if (-not $Force) {
            Write-Error "Le fichier '$Path' existe dÃ©jÃ . Utilisez -Force pour Ã©craser."
            return 0
        } elseif (-not $PSCmdlet.ShouldProcess($Path, "Remplacer le fichier existant")) {
            return 0
        }
    }

    # Obtenir les rÃ¨gles Ã  exporter
    $Rules = Get-ExcelStyleMergeRules -PropertyName $PropertyName

    if ($Rules.Count -eq 0) {
        Write-Warning "Aucune rÃ¨gle trouvÃ©e correspondant aux critÃ¨res."
        return 0
    }

    # Convertir les rÃ¨gles en objets sÃ©rialisables
    $ExportData = @{
        Version    = "1.0"
        ExportDate = [datetime]::Now.ToString("o")
        Rules      = @{}
    }

    foreach ($RuleName in $Rules.Keys) {
        $Rule = $Rules[$RuleName]

        # Convertir la condition en chaÃ®ne de caractÃ¨res si elle existe
        $ConditionString = $null
        if ($null -ne $Rule.Condition) {
            $ConditionString = $Rule.Condition.ToString()
        }

        $ExportData.Rules[$RuleName] = @{
            PropertyName = $Rule.PropertyName
            Strategy     = $Rule.Strategy
            Priority     = $Rule.Priority
            Condition    = $ConditionString
        }
    }

    # SÃ©rialiser et enregistrer les donnÃ©es
    try {
        $JsonData = ConvertTo-Json -InputObject $ExportData -Depth 10
        Set-Content -Path $Path -Value $JsonData -Encoding UTF8
        Write-Verbose "$($Rules.Count) rÃ¨gles exportÃ©es vers '$Path'."
        return $Rules.Count
    } catch {
        Write-Error "Erreur lors de l'exportation des rÃ¨gles: $($_.Exception.Message)"
        return 0
    }
}

<#
.SYNOPSIS
    Importe des rÃ¨gles de fusion depuis un fichier JSON.
.DESCRIPTION
    Cette fonction importe des rÃ¨gles de fusion depuis un fichier JSON.
.PARAMETER Path
    Le chemin du fichier JSON contenant les rÃ¨gles Ã  importer.
.PARAMETER SkipExisting
    Ne pas remplacer les rÃ¨gles existantes avec le mÃªme nom.
.PARAMETER PropertyName
    Filtre les rÃ¨gles Ã  importer par nom de propriÃ©tÃ©.
.EXAMPLE
    Import-ExcelStyleMergeRules -Path "C:\Rules\MesRegles.json"
.OUTPUTS
    System.Int32 - Le nombre de rÃ¨gles importÃ©es.
#>
function Import-ExcelStyleMergeRules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$SkipExisting,

        [Parameter(Mandatory = $false)]
        [string]$PropertyName
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return 0
    }

    # Lire et dÃ©sÃ©rialiser le fichier
    try {
        $JsonData = Get-Content -Path $Path -Encoding UTF8 -Raw
        $ImportData = ConvertFrom-Json -InputObject $JsonData
    } catch {
        Write-Error "Erreur lors de la lecture du fichier: $($_.Exception.Message)"
        return 0
    }

    # VÃ©rifier la version du format
    if (-not $ImportData.Version) {
        Write-Error "Format de fichier non reconnu."
        return 0
    }

    # Compteur de rÃ¨gles importÃ©es
    $ImportedCount = 0

    # Importer les rÃ¨gles
    foreach ($RuleName in $ImportData.Rules.PSObject.Properties.Name) {
        $RuleData = $ImportData.Rules.$RuleName

        # Filtrer par nom de propriÃ©tÃ© si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($PropertyName) -and $RuleData.PropertyName -ne $PropertyName) {
            continue
        }

        # VÃ©rifier si la rÃ¨gle existe dÃ©jÃ 
        if ($script:MergeRules.ContainsKey($RuleName) -and $SkipExisting) {
            Write-Verbose "RÃ¨gle '$RuleName' dÃ©jÃ  existante, ignorÃ©e."
            continue
        }

        # Convertir la chaÃ®ne de condition en scriptblock si elle existe
        $Condition = $null
        if (-not [string]::IsNullOrEmpty($RuleData.Condition)) {
            try {
                $Condition = [scriptblock]::Create($RuleData.Condition)
            } catch {
                Write-Warning "Erreur lors de la conversion de la condition pour la rÃ¨gle '$RuleName': $($_.Exception.Message)"
            }
        }

        # DÃ©finir la rÃ¨gle
        if ($PSCmdlet.ShouldProcess("RÃ¨gle '$RuleName'", "Importer")) {
            $Result = Set-ExcelStyleMergeRule -RuleName $RuleName -PropertyName $RuleData.PropertyName -Strategy $RuleData.Strategy -Priority $RuleData.Priority -Condition $Condition
            if ($Result) {
                $ImportedCount++
            }
        }
    }

    Write-Verbose "$ImportedCount rÃ¨gles importÃ©es depuis '$Path'."
    return $ImportedCount
}

<#
.SYNOPSIS
    Fusionne deux ensembles de rÃ¨gles de fusion.
.DESCRIPTION
    Cette fonction fusionne deux ensembles de rÃ¨gles de fusion en important des rÃ¨gles
    depuis un fichier et en les combinant avec les rÃ¨gles existantes.
.PARAMETER Path
    Le chemin du fichier JSON contenant les rÃ¨gles Ã  fusionner.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser (KeepExisting, ReplaceExisting, HigherPriorityWins).
.PARAMETER PropertyName
    Filtre les rÃ¨gles Ã  fusionner par nom de propriÃ©tÃ©.
.EXAMPLE
    Merge-ExcelStyleMergeRules -Path "C:\Rules\MesRegles.json" -Strategy "HigherPriorityWins"
.OUTPUTS
    System.Int32 - Le nombre de rÃ¨gles fusionnÃ©es.
#>
function Merge-ExcelStyleMergeRules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("KeepExisting", "ReplaceExisting", "HigherPriorityWins")]
        [string]$Strategy = "HigherPriorityWins",

        [Parameter(Mandatory = $false)]
        [string]$PropertyName
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return 0
    }

    # Lire et dÃ©sÃ©rialiser le fichier
    try {
        $JsonData = Get-Content -Path $Path -Encoding UTF8 -Raw
        $ImportData = ConvertFrom-Json -InputObject $JsonData
    } catch {
        Write-Error "Erreur lors de la lecture du fichier: $($_.Exception.Message)"
        return 0
    }

    # VÃ©rifier la version du format
    if (-not $ImportData.Version) {
        Write-Error "Format de fichier non reconnu."
        return 0
    }

    # Compteur de rÃ¨gles fusionnÃ©es
    $MergedCount = 0

    # Fusionner les rÃ¨gles
    foreach ($RuleName in $ImportData.Rules.PSObject.Properties.Name) {
        $RuleData = $ImportData.Rules.$RuleName

        # Filtrer par nom de propriÃ©tÃ© si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($PropertyName) -and $RuleData.PropertyName -ne $PropertyName) {
            continue
        }

        # VÃ©rifier si la rÃ¨gle existe dÃ©jÃ 
        $ExistingRule = $null
        if ($script:MergeRules.ContainsKey($RuleName)) {
            $ExistingRule = $script:MergeRules[$RuleName]

            # DÃ©terminer si la rÃ¨gle doit Ãªtre remplacÃ©e
            $ReplaceRule = $false

            switch ($Strategy) {
                "KeepExisting" {
                    $ReplaceRule = $false
                }
                "ReplaceExisting" {
                    $ReplaceRule = $true
                }
                "HigherPriorityWins" {
                    $ReplaceRule = $RuleData.Priority -gt $ExistingRule.Priority
                }
            }

            if (-not $ReplaceRule) {
                Write-Verbose "RÃ¨gle '$RuleName' conservÃ©e selon la stratÃ©gie '$Strategy'."
                continue
            }
        }

        # Convertir la chaÃ®ne de condition en scriptblock si elle existe
        $Condition = $null
        if (-not [string]::IsNullOrEmpty($RuleData.Condition)) {
            try {
                $Condition = [scriptblock]::Create($RuleData.Condition)
            } catch {
                Write-Warning "Erreur lors de la conversion de la condition pour la rÃ¨gle '$RuleName': $($_.Exception.Message)"
            }
        }

        # DÃ©finir la rÃ¨gle
        if ($PSCmdlet.ShouldProcess("RÃ¨gle '$RuleName'", "Fusionner")) {
            $Result = Set-ExcelStyleMergeRule -RuleName $RuleName -PropertyName $RuleData.PropertyName -Strategy $RuleData.Strategy -Priority $RuleData.Priority -Condition $Condition
            if ($Result) {
                $MergedCount++
            }
        }
    }

    Write-Verbose "$MergedCount rÃ¨gles fusionnÃ©es depuis '$Path'."
    return $MergedCount
}

<#
.SYNOPSIS
    DÃ©termine si une valeur est nulle ou vide.
.DESCRIPTION
    Cette fonction dÃ©termine si une valeur est nulle ou vide en fonction de son type.
.PARAMETER Value
    La valeur Ã  vÃ©rifier.
.PARAMETER Type
    Le type de la valeur (String, Number, Array, Object).
.EXAMPLE
    $IsEmpty = Test-ExcelStyleValueEmpty -Value $null -Type "Object"
.OUTPUTS
    System.Boolean - True si la valeur est nulle ou vide, False sinon.
#>

<#
.SYNOPSIS
    Obtient la stratÃ©gie de fusion Ã  utiliser pour une propriÃ©tÃ© spÃ©cifique en fonction des rÃ¨gles dÃ©finies.
.DESCRIPTION
    Cette fonction dÃ©termine la stratÃ©gie de fusion Ã  utiliser pour une propriÃ©tÃ© spÃ©cifique
    en Ã©valuant les rÃ¨gles de fusion dÃ©finies et en sÃ©lectionnant celle avec la prioritÃ© la plus Ã©levÃ©e.
.PARAMETER PropertyName
    Le nom de la propriÃ©tÃ© pour laquelle obtenir la stratÃ©gie de fusion.
.PARAMETER SourceValue
    La valeur source de la propriÃ©tÃ©.
.PARAMETER TargetValue
    La valeur cible de la propriÃ©tÃ©.
.PARAMETER DefaultStrategy
    La stratÃ©gie de fusion par dÃ©faut Ã  utiliser si aucune rÃ¨gle ne s'applique.
.EXAMPLE
    $Strategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName "Color" -SourceValue "#FF0000" -TargetValue "#0000FF"
.OUTPUTS
    System.String - La stratÃ©gie de fusion Ã  utiliser.
#>
function Get-ExcelStyleMergeStrategyForProperty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$PropertyName,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$SourceValue,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$TargetValue,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "MergeAll", "Manual")]
        [string]$DefaultStrategy = ""
    )

    # Si aucune stratÃ©gie par dÃ©faut n'est spÃ©cifiÃ©e, utiliser la stratÃ©gie globale par dÃ©faut
    if ([string]::IsNullOrEmpty($DefaultStrategy)) {
        $DefaultStrategy = $script:DefaultMergeStrategy
    }

    # Obtenir toutes les rÃ¨gles pour cette propriÃ©tÃ©
    $Rules = Get-ExcelStyleMergeRules -PropertyName $PropertyName

    # Si aucune rÃ¨gle n'est dÃ©finie, retourner la stratÃ©gie par dÃ©faut
    if ($Rules.Count -eq 0) {
        return $DefaultStrategy
    }

    # CrÃ©er un tableau pour stocker les rÃ¨gles applicables
    $ApplicableRules = @()

    # Ã‰valuer chaque rÃ¨gle pour dÃ©terminer si elle s'applique
    foreach ($RuleName in $Rules.Keys) {
        $Rule = $Rules[$RuleName]

        # Si la rÃ¨gle a une condition, l'Ã©valuer
        if ($null -ne $Rule.Condition) {
            # CrÃ©er un contexte pour l'Ã©valuation de la condition
            # (Le contexte est passÃ© directement Ã  la condition via les paramÃ¨tres)

            # Ã‰valuer la condition dans le contexte
            $ConditionResult = $false
            try {
                $ConditionResult = & $Rule.Condition -PropertyName $PropertyName -SourceValue $SourceValue -TargetValue $TargetValue
            } catch {
                Write-Warning "Erreur lors de l'Ã©valuation de la condition pour la rÃ¨gle '$RuleName': $($_.Exception.Message)"
            }

            # Si la condition est fausse, passer Ã  la rÃ¨gle suivante
            if (-not $ConditionResult) {
                continue
            }
        }

        # La rÃ¨gle s'applique, l'ajouter au tableau des rÃ¨gles applicables
        $ApplicableRules += @{
            Name = $RuleName
            Rule = $Rule
        }
    }

    # Si aucune rÃ¨gle ne s'applique, retourner la stratÃ©gie par dÃ©faut
    if ($ApplicableRules.Count -eq 0) {
        return $DefaultStrategy
    }

    # Trier les rÃ¨gles applicables par prioritÃ© (de la plus Ã©levÃ©e Ã  la plus basse)
    $SortedRules = $ApplicableRules | Sort-Object -Property { $_.Rule.Priority } -Descending

    # Retourner la stratÃ©gie de la rÃ¨gle avec la prioritÃ© la plus Ã©levÃ©e
    return $SortedRules[0].Rule.Strategy
}

function Test-ExcelStyleValueEmpty {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Number", "Array", "Object")]
        [string]$Type = "Object"
    )

    # VÃ©rifier si la valeur est null
    if ($null -eq $Value) {
        return $true
    }

    # VÃ©rifier en fonction du type
    switch ($Type) {
        "String" {
            return [string]::IsNullOrEmpty($Value)
        }
        "Number" {
            return $Value -eq 0
        }
        "Array" {
            return $Value.Count -eq 0
        }
        "Object" {
            # Pour les objets, on considÃ¨re qu'ils ne sont pas vides s'ils existent
            return $false
        }
    }

    return $false
}

<#
.SYNOPSIS
    Fusionne deux collections en Ã©liminant les doublons.
.DESCRIPTION
    Cette fonction fusionne deux collections en Ã©liminant les doublons.
.PARAMETER SourceCollection
    La premiÃ¨re collection Ã  fusionner.
.PARAMETER TargetCollection
    La deuxiÃ¨me collection Ã  fusionner.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser (SourceWins, TargetWins, MergeNonNull, MergeAll).
.EXAMPLE
    $MergedCollection = Merge-ExcelStyleCollections -SourceCollection @("A", "B") -TargetCollection @("B", "C") -Strategy "MergeAll"
.OUTPUTS
    System.Array - La collection fusionnÃ©e.
#>
function Merge-ExcelStyleCollections {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        [array]$SourceCollection,

        [Parameter(Mandatory = $false, Position = 1)]
        [AllowNull()]
        [array]$TargetCollection,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "MergeAll")]
        [string]$Strategy = "MergeAll"
    )

    # VÃ©rifier si les collections sont nulles
    if ($null -eq $SourceCollection -and $null -eq $TargetCollection) {
        return @()
    }

    if ($null -eq $SourceCollection) {
        return $TargetCollection
    }

    if ($null -eq $TargetCollection) {
        return $SourceCollection
    }

    # Fusionner les collections selon la stratÃ©gie
    switch ($Strategy) {
        "SourceWins" {
            return $SourceCollection
        }
        "TargetWins" {
            return $TargetCollection
        }
        "MergeNonNull" {
            if ($TargetCollection.Count -gt 0) {
                return $TargetCollection
            } else {
                return $SourceCollection
            }
        }
        "MergeAll" {
            $MergedCollection = @()
            $MergedCollection += $SourceCollection
            $MergedCollection += $TargetCollection
            return $MergedCollection | Select-Object -Unique
        }
    }

    return @()
}

<#
.SYNOPSIS
    Fusionne deux valeurs en fonction de leur type et de la stratÃ©gie de fusion.
.DESCRIPTION
    Cette fonction fusionne deux valeurs en fonction de leur type et de la stratÃ©gie de fusion.
.PARAMETER SourceValue
    La premiÃ¨re valeur Ã  fusionner.
.PARAMETER TargetValue
    La deuxiÃ¨me valeur Ã  fusionner.
.PARAMETER Type
    Le type des valeurs (String, Number, Array, Object).
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser (SourceWins, TargetWins, MergeNonNull, MergeAll, Manual).
.PARAMETER PropertyName
    Le nom de la propriÃ©tÃ© en cours de fusion (utilisÃ© pour la rÃ©solution manuelle).
.PARAMETER Interactive
    Indique si la fusion doit Ãªtre interactive (pour la rÃ©solution manuelle).
.EXAMPLE
    $MergedValue = Merge-ExcelStyleValues -SourceValue "A" -TargetValue "B" -Type "String" -Strategy "MergeNonNull"
.OUTPUTS
    System.Object - La valeur fusionnÃ©e.
#>
function Merge-ExcelStyleValues {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [AllowNull()]
        [object]$SourceValue,

        [Parameter(Mandatory = $false, Position = 1)]
        [AllowNull()]
        [object]$TargetValue,

        [Parameter(Mandatory = $false)]
        [ValidateSet("String", "Number", "Array", "Object")]
        [string]$Type = "Object",

        [Parameter(Mandatory = $false)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "MergeAll", "Manual")]
        [string]$Strategy = "MergeNonNull",

        [Parameter(Mandatory = $false)]
        [string]$PropertyName = "",

        [Parameter(Mandatory = $false)]
        [switch]$Interactive,

        [Parameter(Mandatory = $false)]
        [switch]$UseRules
    )

    # Si UseRules est spÃ©cifiÃ© et PropertyName n'est pas vide, utiliser les rÃ¨gles de fusion
    if ($UseRules -and -not [string]::IsNullOrEmpty($PropertyName)) {
        $RuleStrategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName $PropertyName -SourceValue $SourceValue -TargetValue $TargetValue -DefaultStrategy $Strategy

        if ($RuleStrategy -ne $Strategy) {
            Write-Verbose "Utilisation de la stratÃ©gie '$RuleStrategy' dÃ©finie par une rÃ¨gle pour la propriÃ©tÃ© '$PropertyName'."
            $Strategy = $RuleStrategy
        }
    }

    # VÃ©rifier si les valeurs sont nulles ou vides
    $SourceEmpty = Test-ExcelStyleValueEmpty -Value $SourceValue -Type $Type
    $TargetEmpty = Test-ExcelStyleValueEmpty -Value $TargetValue -Type $Type

    # Si les deux valeurs sont nulles ou vides, retourner la valeur par dÃ©faut
    if ($SourceEmpty -and $TargetEmpty) {
        switch ($Type) {
            "String" { return "" }
            "Number" { return 0 }
            "Array" { return @() }
            "Object" { return $null }
        }
    }

    # Fusionner les valeurs selon la stratÃ©gie
    switch ($Strategy) {
        "SourceWins" {
            return $SourceValue
        }
        "TargetWins" {
            return $TargetValue
        }
        "MergeNonNull" {
            if (-not $TargetEmpty) {
                return $TargetValue
            } else {
                return $SourceValue
            }
        }
        "MergeAll" {
            if ($Type -eq "Array") {
                return Merge-ExcelStyleCollections -SourceCollection $SourceValue -TargetCollection $TargetValue -Strategy "MergeAll"
            } else {
                # Pour les autres types, utiliser MergeNonNull
                if (-not $TargetEmpty) {
                    return $TargetValue
                } else {
                    return $SourceValue
                }
            }
        }
        "Manual" {
            # Si le mode interactif n'est pas activÃ©, utiliser MergeNonNull
            if (-not $Interactive) {
                if (-not $TargetEmpty) {
                    return $TargetValue
                } else {
                    return $SourceValue
                }
            }

            # Afficher les valeurs et demander Ã  l'utilisateur de choisir
            $PropertyDisplay = if ([string]::IsNullOrEmpty($PropertyName)) { "la propriÃ©tÃ©" } else { "'$PropertyName'" }

            Write-Host "Conflit dÃ©tectÃ© pour ${PropertyDisplay}:" -ForegroundColor Yellow
            Write-Host "  1. Source: ${SourceValue}" -ForegroundColor Cyan
            Write-Host "  2. Cible: ${TargetValue}" -ForegroundColor Magenta
            Write-Host "  3. Fusionner (pour les collections)" -ForegroundColor Green

            $Choice = Read-Host "Choisissez une option (1, 2, 3 ou q pour annuler)"

            switch ($Choice) {
                "1" { return $SourceValue }
                "2" { return $TargetValue }
                "3" {
                    if ($Type -eq "Array") {
                        return Merge-ExcelStyleCollections -SourceCollection $SourceValue -TargetCollection $TargetValue -Strategy "MergeAll"
                    } else {
                        Write-Warning "La fusion n'est disponible que pour les collections. Utilisation de la valeur cible."
                        return $TargetValue
                    }
                }
                "q" {
                    Write-Warning "Fusion annulÃ©e par l'utilisateur."
                    throw "Fusion annulÃ©e par l'utilisateur."
                }
                default {
                    Write-Warning "Option non valide. Utilisation de la valeur cible."
                    return $TargetValue
                }
            }
        }
    }

    return $null
}

<#
.SYNOPSIS
    Fusionne deux styles de ligne en un nouveau style.
.DESCRIPTION
    Cette fonction fusionne deux styles de ligne en un nouveau style en combinant leurs propriÃ©tÃ©s
    selon les options spÃ©cifiÃ©es.
.PARAMETER SourceStyle
    Le style source (premier style Ã  fusionner).
.PARAMETER TargetStyle
    Le style cible (deuxiÃ¨me style Ã  fusionner).
.PARAMETER NewName
    Le nom du nouveau style fusionnÃ©.
.PARAMETER Description
    La description du nouveau style fusionnÃ©.
.PARAMETER MergeStrategy
    La stratÃ©gie de fusion Ã  utiliser (SourceWins, TargetWins, MergeNonNull).
.PARAMETER MergeTags
    Indique si les tags doivent Ãªtre fusionnÃ©s.
.PARAMETER Category
    La catÃ©gorie du nouveau style fusionnÃ©.
.EXAMPLE
    $MergedStyle = Merge-ExcelLineStyles -SourceStyle $Style1 -TargetStyle $Style2 -NewName "Style fusionnÃ©" -MergeStrategy MergeNonNull
.OUTPUTS
    ExcelLineStyle - Le nouveau style de ligne fusionnÃ©.
#>
function Merge-ExcelLineStyles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ExcelLineStyle]$SourceStyle,

        [Parameter(Mandatory = $true, Position = 1)]
        [ExcelLineStyle]$TargetStyle,

        [Parameter(Mandatory = $true)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "Manual")]
        [string]$MergeStrategy,

        [Parameter(Mandatory = $false)]
        [switch]$MergeTags,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [switch]$Interactive,

        [Parameter(Mandatory = $false)]
        [switch]$UseRules
    )

    # Utiliser la stratÃ©gie par dÃ©faut si aucune n'est spÃ©cifiÃ©e
    if ([string]::IsNullOrEmpty($MergeStrategy)) {
        $MergeStrategy = $script:DefaultMergeStrategy
        Write-Verbose "Utilisation de la stratÃ©gie de fusion par dÃ©faut: $MergeStrategy"
    }

    # CrÃ©er un nouveau style
    $MergedStyle = [ExcelLineStyle]::new()
    $MergedStyle.Name = $NewName
    $MergedStyle.IsBuiltIn = $false

    # DÃ©finir la description
    if (-not [string]::IsNullOrEmpty($Description)) {
        $MergedStyle.Description = $Description
    } else {
        $MergedStyle.Description = "Fusion de $($SourceStyle.Name) et $($TargetStyle.Name)"
    }

    # DÃ©finir la catÃ©gorie
    if (-not [string]::IsNullOrEmpty($Category)) {
        $MergedStyle.Category = $Category
    } else {
        # Utiliser la catÃ©gorie selon la stratÃ©gie de fusion
        switch ($MergeStrategy) {
            "SourceWins" { $MergedStyle.Category = $SourceStyle.Category }
            "TargetWins" { $MergedStyle.Category = $TargetStyle.Category }
            "MergeNonNull" {
                if (-not [string]::IsNullOrEmpty($TargetStyle.Category)) {
                    $MergedStyle.Category = $TargetStyle.Category
                } else {
                    $MergedStyle.Category = $SourceStyle.Category
                }
            }
        }

        # Si aucune catÃ©gorie n'est dÃ©finie, utiliser "Styles fusionnÃ©s"
        if ([string]::IsNullOrEmpty($MergedStyle.Category)) {
            $MergedStyle.Category = "Styles fusionnÃ©s"
        }
    }

    # Fusionner les tags
    if ($MergeTags) {
        # Ajouter tous les tags uniques des deux styles
        $AllTags = @()
        $AllTags += $SourceStyle.Tags
        $AllTags += $TargetStyle.Tags
        $UniqueTags = $AllTags | Select-Object -Unique

        foreach ($Tag in $UniqueTags) {
            $MergedStyle.AddTag($Tag)
        }
    } else {
        # Utiliser les tags selon la stratÃ©gie de fusion
        switch ($MergeStrategy) {
            "SourceWins" {
                foreach ($Tag in $SourceStyle.Tags) {
                    $MergedStyle.AddTag($Tag)
                }
            }
            "TargetWins" {
                foreach ($Tag in $TargetStyle.Tags) {
                    $MergedStyle.AddTag($Tag)
                }
            }
            "MergeNonNull" {
                if ($TargetStyle.Tags.Count -gt 0) {
                    foreach ($Tag in $TargetStyle.Tags) {
                        $MergedStyle.AddTag($Tag)
                    }
                } else {
                    foreach ($Tag in $SourceStyle.Tags) {
                        $MergedStyle.AddTag($Tag)
                    }
                }
            }
        }
    }

    # Ajouter un tag spÃ©cial pour indiquer que c'est un style fusionnÃ©
    $MergedStyle.AddTag("FusionnÃ©")

    # Fusionner les configurations de ligne
    $MergedStyle.LineConfig = [ExcelLineStyleConfig]::new()

    # Fusionner la largeur
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.Width = $SourceStyle.LineConfig.Width }
        "TargetWins" { $MergedStyle.LineConfig.Width = $TargetStyle.LineConfig.Width }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.Width -gt 0) {
                $MergedStyle.LineConfig.Width = $TargetStyle.LineConfig.Width
            } else {
                $MergedStyle.LineConfig.Width = $SourceStyle.LineConfig.Width
            }
        }
    }

    # Fusionner le style de ligne
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.Style = $SourceStyle.LineConfig.Style }
        "TargetWins" { $MergedStyle.LineConfig.Style = $TargetStyle.LineConfig.Style }
        "MergeNonNull" {
            if ($null -ne $TargetStyle.LineConfig.Style) {
                $MergedStyle.LineConfig.Style = $TargetStyle.LineConfig.Style
            } else {
                $MergedStyle.LineConfig.Style = $SourceStyle.LineConfig.Style
            }
        }
    }

    # Fusionner la couleur
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.Color = $SourceStyle.LineConfig.Color }
        "TargetWins" { $MergedStyle.LineConfig.Color = $TargetStyle.LineConfig.Color }
        "MergeNonNull" {
            if (-not [string]::IsNullOrEmpty($TargetStyle.LineConfig.Color)) {
                $MergedStyle.LineConfig.Color = $TargetStyle.LineConfig.Color
            } else {
                $MergedStyle.LineConfig.Color = $SourceStyle.LineConfig.Color
            }
        }
    }

    # Fusionner le type de tiret
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.DashType = $SourceStyle.LineConfig.DashType }
        "TargetWins" { $MergedStyle.LineConfig.DashType = $TargetStyle.LineConfig.DashType }
        "MergeNonNull" {
            if (-not [string]::IsNullOrEmpty($TargetStyle.LineConfig.DashType)) {
                $MergedStyle.LineConfig.DashType = $TargetStyle.LineConfig.DashType
            } else {
                $MergedStyle.LineConfig.DashType = $SourceStyle.LineConfig.DashType
            }
        }
    }

    # Fusionner les propriÃ©tÃ©s avancÃ©es
    # Facteur d'espacement
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.SpacingFactor = $SourceStyle.LineConfig.SpacingFactor }
        "TargetWins" { $MergedStyle.LineConfig.SpacingFactor = $TargetStyle.LineConfig.SpacingFactor }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.SpacingFactor -gt 0) {
                $MergedStyle.LineConfig.SpacingFactor = $TargetStyle.LineConfig.SpacingFactor
            } else {
                $MergedStyle.LineConfig.SpacingFactor = $SourceStyle.LineConfig.SpacingFactor
            }
        }
    }

    # Facteur de progression
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.ProgressionFactor = $SourceStyle.LineConfig.ProgressionFactor }
        "TargetWins" { $MergedStyle.LineConfig.ProgressionFactor = $TargetStyle.LineConfig.ProgressionFactor }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.ProgressionFactor -gt 0) {
                $MergedStyle.LineConfig.ProgressionFactor = $TargetStyle.LineConfig.ProgressionFactor
            } else {
                $MergedStyle.LineConfig.ProgressionFactor = $SourceStyle.LineConfig.ProgressionFactor
            }
        }
    }

    # Facteur de proportion
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.ProportionFactor = $SourceStyle.LineConfig.ProportionFactor }
        "TargetWins" { $MergedStyle.LineConfig.ProportionFactor = $TargetStyle.LineConfig.ProportionFactor }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.ProportionFactor -gt 0) {
                $MergedStyle.LineConfig.ProportionFactor = $TargetStyle.LineConfig.ProportionFactor
            } else {
                $MergedStyle.LineConfig.ProportionFactor = $SourceStyle.LineConfig.ProportionFactor
            }
        }
    }

    # Motif
    switch ($MergeStrategy) {
        "SourceWins" { $MergedStyle.LineConfig.Pattern = $SourceStyle.LineConfig.Pattern }
        "TargetWins" { $MergedStyle.LineConfig.Pattern = $TargetStyle.LineConfig.Pattern }
        "MergeNonNull" {
            if (-not [string]::IsNullOrEmpty($TargetStyle.LineConfig.Pattern)) {
                $MergedStyle.LineConfig.Pattern = $TargetStyle.LineConfig.Pattern
            } else {
                $MergedStyle.LineConfig.Pattern = $SourceStyle.LineConfig.Pattern
            }
        }
    }

    # DÃ©gradÃ©
    switch ($MergeStrategy) {
        "SourceWins" {
            $MergedStyle.LineConfig.GradientEnabled = $SourceStyle.LineConfig.GradientEnabled
            $MergedStyle.LineConfig.GradientEndColor = $SourceStyle.LineConfig.GradientEndColor
        }
        "TargetWins" {
            $MergedStyle.LineConfig.GradientEnabled = $TargetStyle.LineConfig.GradientEnabled
            $MergedStyle.LineConfig.GradientEndColor = $TargetStyle.LineConfig.GradientEndColor
        }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.GradientEnabled) {
                $MergedStyle.LineConfig.GradientEnabled = $TargetStyle.LineConfig.GradientEnabled
                $MergedStyle.LineConfig.GradientEndColor = $TargetStyle.LineConfig.GradientEndColor
            } else {
                $MergedStyle.LineConfig.GradientEnabled = $SourceStyle.LineConfig.GradientEnabled
                $MergedStyle.LineConfig.GradientEndColor = $SourceStyle.LineConfig.GradientEndColor
            }
        }
    }

    # Couleurs variables
    switch ($MergeStrategy) {
        "SourceWins" {
            $MergedStyle.LineConfig.VariableColorEnabled = $SourceStyle.LineConfig.VariableColorEnabled
            $MergedStyle.LineConfig.VariableColors = $SourceStyle.LineConfig.VariableColors
        }
        "TargetWins" {
            $MergedStyle.LineConfig.VariableColorEnabled = $TargetStyle.LineConfig.VariableColorEnabled
            $MergedStyle.LineConfig.VariableColors = $TargetStyle.LineConfig.VariableColors
        }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.VariableColorEnabled) {
                $MergedStyle.LineConfig.VariableColorEnabled = $TargetStyle.LineConfig.VariableColorEnabled
                $MergedStyle.LineConfig.VariableColors = $TargetStyle.LineConfig.VariableColors
            } else {
                $MergedStyle.LineConfig.VariableColorEnabled = $SourceStyle.LineConfig.VariableColorEnabled
                $MergedStyle.LineConfig.VariableColors = $SourceStyle.LineConfig.VariableColors
            }
        }
    }

    # DÃ©gradÃ© spÃ©cial
    switch ($MergeStrategy) {
        "SourceWins" {
            $MergedStyle.LineConfig.SpecialGradientEnabled = $SourceStyle.LineConfig.SpecialGradientEnabled
            $MergedStyle.LineConfig.SpecialGradientColors = $SourceStyle.LineConfig.SpecialGradientColors
        }
        "TargetWins" {
            $MergedStyle.LineConfig.SpecialGradientEnabled = $TargetStyle.LineConfig.SpecialGradientEnabled
            $MergedStyle.LineConfig.SpecialGradientColors = $TargetStyle.LineConfig.SpecialGradientColors
        }
        "MergeNonNull" {
            if ($TargetStyle.LineConfig.SpecialGradientEnabled) {
                $MergedStyle.LineConfig.SpecialGradientEnabled = $TargetStyle.LineConfig.SpecialGradientEnabled
                $MergedStyle.LineConfig.SpecialGradientColors = $TargetStyle.LineConfig.SpecialGradientColors
            } else {
                $MergedStyle.LineConfig.SpecialGradientEnabled = $SourceStyle.LineConfig.SpecialGradientEnabled
                $MergedStyle.LineConfig.SpecialGradientColors = $SourceStyle.LineConfig.SpecialGradientColors
            }
        }
    }

    # Ajouter le style fusionnÃ© au registre
    $Registry = Get-ExcelStyleRegistry
    $Registry.Add($MergedStyle) | Out-Null

    return $MergedStyle
}

<#
.SYNOPSIS
    Fusionne deux styles de ligne en utilisant leurs noms.
.DESCRIPTION
    Cette fonction fusionne deux styles de ligne en utilisant leurs noms.
.PARAMETER SourceStyleName
    Le nom du style source (premier style Ã  fusionner).
.PARAMETER TargetStyleName
    Le nom du style cible (deuxiÃ¨me style Ã  fusionner).
.PARAMETER NewName
    Le nom du nouveau style fusionnÃ©.
.PARAMETER Description
    La description du nouveau style fusionnÃ©.
.PARAMETER MergeStrategy
    La stratÃ©gie de fusion Ã  utiliser (SourceWins, TargetWins, MergeNonNull).
.PARAMETER MergeTags
    Indique si les tags doivent Ãªtre fusionnÃ©s.
.PARAMETER Category
    La catÃ©gorie du nouveau style fusionnÃ©.
.EXAMPLE
    $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ©" -MergeStrategy MergeNonNull
.OUTPUTS
    ExcelLineStyle - Le nouveau style de ligne fusionnÃ©.
#>
function Merge-ExcelLineStylesByName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SourceStyleName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TargetStyleName,

        [Parameter(Mandatory = $true)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("SourceWins", "TargetWins", "MergeNonNull", "Manual")]
        [string]$MergeStrategy,

        [Parameter(Mandatory = $false)]
        [switch]$MergeTags,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [switch]$Interactive,

        [Parameter(Mandatory = $false)]
        [switch]$UseRules
    )

    # Obtenir les styles par leur nom
    $SourceStyle = Get-ExcelPredefinedLineStyle -Name $SourceStyleName
    $TargetStyle = Get-ExcelPredefinedLineStyle -Name $TargetStyleName

    if ($null -eq $SourceStyle) {
        Write-Error "Style source '$SourceStyleName' non trouvÃ©."
        return $null
    }

    if ($null -eq $TargetStyle) {
        Write-Error "Style cible '$TargetStyleName' non trouvÃ©."
        return $null
    }

    # Appeler la fonction de fusion avec les objets de style
    $MergeParams = @{
        SourceStyle   = $SourceStyle
        TargetStyle   = $TargetStyle
        NewName       = $NewName
        MergeStrategy = $MergeStrategy
    }

    if (-not [string]::IsNullOrEmpty($Description)) {
        $MergeParams.Description = $Description
    }

    if ($MergeTags) {
        $MergeParams.MergeTags = $true
    }

    if (-not [string]::IsNullOrEmpty($Category)) {
        $MergeParams.Category = $Category
    }

    if ($Interactive) {
        $MergeParams.Interactive = $true
    }

    if ($UseRules) {
        $MergeParams.UseRules = $true
    }

    return Merge-ExcelLineStyles @MergeParams
}

<#
.SYNOPSIS
    Fusionne deux styles de ligne de maniÃ¨re interactive.
.DESCRIPTION
    Cette fonction fusionne deux styles de ligne de maniÃ¨re interactive en demandant Ã  l'utilisateur
    de choisir pour chaque propriÃ©tÃ© en conflit.
.PARAMETER SourceStyleName
    Le nom du style source (premier style Ã  fusionner).
.PARAMETER TargetStyleName
    Le nom du style cible (deuxiÃ¨me style Ã  fusionner).
.PARAMETER NewName
    Le nom du nouveau style fusionnÃ©.
.PARAMETER Description
    La description du nouveau style fusionnÃ©.
.PARAMETER Category
    La catÃ©gorie du nouveau style fusionnÃ©.
.EXAMPLE
    $MergedStyle = Merge-ExcelLineStylesInteractive -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ© interactif"
.OUTPUTS
    ExcelLineStyle - Le nouveau style de ligne fusionnÃ©.
#>
function Merge-ExcelLineStylesInteractive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SourceStyleName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TargetStyleName,

        [Parameter(Mandatory = $true)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Category
    )

    # Appeler la fonction de fusion avec la stratÃ©gie Manual et le mode interactif
    $MergeParams = @{
        SourceStyleName = $SourceStyleName
        TargetStyleName = $TargetStyleName
        NewName         = $NewName
        MergeStrategy   = "Manual"
        Interactive     = $true
    }

    if (-not [string]::IsNullOrEmpty($Description)) {
        $MergeParams.Description = $Description
    }

    if (-not [string]::IsNullOrEmpty($Category)) {
        $MergeParams.Category = $Category
    }

    return Merge-ExcelLineStylesByName @MergeParams
}

#endregion

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ExcelPredefinedStyles, Get-ExcelPredefinedLineStyle, Get-ExcelPredefinedLineStyles, Set-ExcelChartSeriesPredefinedLineStyle, Set-ExcelChartSeriesCoordinatedSet, Set-ExcelChartSeriesGradient, Copy-ExcelLineStyleWithModifications, Edit-ExcelLineStyle, Remove-ExcelLineStyle, Undo-ExcelLineStyleChanges, Export-ExcelStyles, Import-ExcelStyles, Save-ExcelStylesConfiguration, Import-ExcelStylesConfiguration, Merge-ExcelLineStyles, Merge-ExcelLineStylesByName, Merge-ExcelLineStylesInteractive, Set-ExcelStyleMergeDefaultStrategy, Get-ExcelStyleMergeDefaultStrategy, Set-ExcelStyleMergeRule, Remove-ExcelStyleMergeRule, Get-ExcelStyleMergeRule, Get-ExcelStyleMergeRules, Set-ExcelStyleMergeRulePriority, Get-ExcelStyleMergeRulePriority, Set-ExcelStyleMergeDefaultRule, Export-ExcelStyleMergeRules, Import-ExcelStyleMergeRules, Merge-ExcelStyleMergeRules, Test-ExcelStyleValueEmpty, Merge-ExcelStyleCollections, Merge-ExcelStyleValues
