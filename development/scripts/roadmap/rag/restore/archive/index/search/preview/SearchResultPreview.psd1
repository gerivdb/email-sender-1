# SearchResultPreview.psd1
# Fichier manifeste pour le module SearchResultPreview
# Version: 1.0
# Date: 2025-05-15

@{
    # Informations sur le module
    RootModule = 'SearchResultPreview.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    Author = 'Augment'
    CompanyName = 'Augment'
    Copyright = '(c) 2025 Augment. All rights reserved.'
    Description = 'Module pour la previsualisation des resultats de recherche'
    
    # Fonctions a exporter
    FunctionsToExport = @(
        'Get-TextSnippet',
        'Get-DocumentPreview',
        'Get-SearchResultPreviews',
        'Format-PreviewsAsText',
        'Format-PreviewsAsHtml',
        'Format-PreviewsAsJson'
    )
    
    # Alias a exporter
    AliasesToExport = @()
    
    # Variables a exporter
    VariablesToExport = @()
    
    # Cmdlets a exporter
    CmdletsToExport = @()
    
    # Informations sur la compatibilite
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Tags pour la recherche
    Tags = @('Search', 'Preview', 'Snippet', 'Result', 'Format')
    
    # URL du projet
    ProjectUri = 'https://github.com/augment/SearchResultPreview'
    
    # URL de la licence
    LicenseUri = 'https://github.com/augment/SearchResultPreview/blob/main/LICENSE'
    
    # URL de l'icone
    IconUri = 'https://github.com/augment/SearchResultPreview/blob/main/icon.png'
    
    # Notes de version
    ReleaseNotes = @'
# Version 1.0.0
- Version initiale du module
- Fonctions pour generer des extraits de texte
- Fonctions pour generer des previsualisations de documents
- Fonctions pour formater les previsualisations en texte, HTML et JSON
'@
}
