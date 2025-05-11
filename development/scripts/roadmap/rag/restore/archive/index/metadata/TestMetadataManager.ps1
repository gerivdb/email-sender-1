# TestMetadataManager.ps1
# Script de test pour le module de gestion des metadonnees
# Version: 1.0
# Date: 2025-05-15

# Importer le module de gestion des metadonnees
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path $scriptPath -ChildPath "MetadataManager.ps1"

if (Test-Path -Path $modulePath) {
    . $modulePath
} else {
    Write-Error "Le fichier MetadataManager.ps1 est introuvable."
    exit 1
}

# Fonction pour creer un fichier markdown de test
function New-TestMarkdownFile {
    param (
        [string]$FilePath,
        [hashtable]$Metadata = @{},
        [switch]$WithYamlFrontmatter
    )

    # Creer le contenu du fichier
    $content = ""

    # Ajouter le frontmatter YAML si demande
    if ($WithYamlFrontmatter) {
        $yamlLines = @()
        foreach ($key in $Metadata.Keys) {
            $yamlLines += "$($key): $($Metadata[$key])"
        }
        $yamlContent = $yamlLines -join "`n"
        $content = "---`n$yamlContent`n---`n`n"
    }

    # Ajouter le contenu principal
    $content += "# Document de test`n`n"
    $content += "Ceci est un document de test pour le module de gestion des metadonnees.`n`n"

    # Ajouter des metadonnees inline
    $content += "## Section avec metadonnees inline`n`n"
    $content += "Cette section contient des metadonnees inline #priority:high #status:draft`n`n"
    $content += "Cette tache doit etre terminee (due:2024-05-15) par l'equipe (team:dev)`n`n"

    # Ecrire le contenu dans le fichier
    Set-Content -Path $FilePath -Value $content

    return $FilePath
}

# Creer un repertoire temporaire pour les tests
$testDir = Join-Path -Path $scriptPath -ChildPath "test_files"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory | Out-Null
}

# Tester la fonction Get-DocumentMetadata
Write-Output "Test de la fonction Get-DocumentMetadata:"
$document = [PSCustomObject]@{
    id         = "doc1"
    title      = "Document de test"
    content    = "Contenu du document de test"
    author     = "Jean Dupont"
    created_at = "2024-01-15T10:30:00Z"
    status     = "draft"
    priority   = "high"
}

# Extraire toutes les metadonnees sauf le contenu
$metadata = Get-DocumentMetadata -Document $document
Write-Output "Metadonnees extraites (sans le contenu):"
$metadata | Format-Table -AutoSize

# Extraire uniquement les metadonnees specifiees
$metadata = Get-DocumentMetadata -Document $document -IncludeFields @("title", "author", "status")
Write-Output "Metadonnees extraites (uniquement title, author, status):"
$metadata | Format-Table -AutoSize

# Tester la fonction Add-DocumentMetadata
Write-Output "`nTest de la fonction Add-DocumentMetadata:"
$newMetadata = @{
    category = "documentation"
    tags     = @("test", "metadata")
    language = "fr"
}

# Ajouter les nouvelles metadonnees
$updatedDocument = Add-DocumentMetadata -Document $document -Metadata $newMetadata
Write-Output "Document avec nouvelles metadonnees:"
$updatedDocument | Format-List

# Tester la mise a jour des metadonnees existantes
$updateMetadata = @{
    status   = "published"
    priority = "medium"
}

# Essayer de mettre a jour sans Force (ne devrait pas fonctionner)
$updatedDocument = Add-DocumentMetadata -Document $updatedDocument -Metadata $updateMetadata
Write-Output "Document apres tentative de mise a jour sans Force:"
$updatedDocument | Format-List

# Mettre a jour avec Force
$updatedDocument = Add-DocumentMetadata -Document $updatedDocument -Metadata $updateMetadata -Force
Write-Output "Document apres mise a jour avec Force:"
$updatedDocument | Format-List

# Tester la fonction Remove-DocumentMetadata
Write-Output "`nTest de la fonction Remove-DocumentMetadata:"
$fieldsToRemove = @("status", "priority", "tags")
$updatedDocument = Remove-DocumentMetadata -Document $updatedDocument -Fields $fieldsToRemove
Write-Output "Document apres suppression des metadonnees:"
$updatedDocument | Format-List

# Tester la fonction Get-MarkdownMetadata
Write-Output "`nTest de la fonction Get-MarkdownMetadata:"

# Creer un fichier markdown de test avec frontmatter YAML
$yamlMetadata = @{
    title    = "Document de test avec YAML"
    author   = "Jean Dupont"
    date     = "2024-01-15"
    status   = "draft"
    priority = "high"
}
$testFile1 = Join-Path -Path $testDir -ChildPath "test_yaml.md"
New-TestMarkdownFile -FilePath $testFile1 -Metadata $yamlMetadata -WithYamlFrontmatter

# Extraire les metadonnees du fichier
$fileMetadata = Get-MarkdownMetadata -FilePath $testFile1
Write-Output "Metadonnees extraites du fichier avec YAML:"
$fileMetadata | Format-Table -AutoSize

# Tester la fonction Add-MarkdownMetadata
Write-Output "`nTest de la fonction Add-MarkdownMetadata:"

# Creer un fichier markdown de test sans frontmatter
$testFile2 = Join-Path -Path $testDir -ChildPath "test_no_yaml.md"
New-TestMarkdownFile -FilePath $testFile2

# Ajouter des metadonnees au format YAML
$newFileMetadata = @{
    title    = "Document mis a jour"
    author   = "Marie Martin"
    date     = "2024-05-15"
    status   = "published"
    category = "test"
}
Add-MarkdownMetadata -FilePath $testFile2 -Metadata $newFileMetadata -Format "YAML"
Write-Output "Metadonnees ajoutees au format YAML:"
Get-Content -Path $testFile2 | Select-Object -First 10

# Ajouter des metadonnees au format Inline
$inlineMetadata = @{
    priority = "medium"
    team     = "qa"
    due      = "2024-06-30"
}
Add-MarkdownMetadata -FilePath $testFile2 -Metadata $inlineMetadata -Format "Inline"
Write-Output "`nMetadonnees ajoutees au format Inline:"
Get-Content -Path $testFile2 | Select-Object -Last 5

# Nettoyer les fichiers de test
Write-Output "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Output "`nTous les tests sont termines."
