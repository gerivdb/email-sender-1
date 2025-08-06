# PowerShell - Générateur de template universel de mode Roo
# Usage : ./mode-scaffold.ps1
# Ce script crée un squelette de mode Roo avec prompts interactifs et documentation associée.

param(
   [string]$TemplatePath = ".roo/mode-template.md"
)

Write-Host "=== Générateur de mode Roo ==="
$slug = Read-Host "Slug du mode (ex: plandev-engineer)"
$emoji = Read-Host "Emoji du mode (ex: 🛠️)"
$description = Read-Host "Description courte"
$workflow = Read-Host "Workflow principal (Mermaid ou étapes)"
$overrides = Read-Host "Overrides spécifiques (ex: droits, restrictions)"
$capabilities = Read-Host "Matrice capabilities/groupes (séparés par virgule)"
$hooks = Read-Host "Hooks événementiels (séparés par virgule)"
$permissions = Read-Host "Permissions (ex: lecture, écriture, suppression)"
$multilingue_fr = Read-Host "Section multilingue FR"
$multilingue_en = Read-Host "Section multilingue EN"
$references = Read-Host "Liens utiles (séparés par virgule)"
$faq = Read-Host "FAQ / Glossaire"

$template = @"
#### Fiche Mode $slug

- **Slug** : $slug
- **Emoji** : $emoji
- **Description** : $description
- **Workflow principal** :
$workflow
- **Overrides** : $overrides
- **Matrice capabilities/groupes** : $capabilities
- **Hooks événementiels** : $hooks
- **Permissions** : $permissions
- **Section multilingue FR** : $multilingue_fr
- **Section multilingue EN** : $multilingue_en
- **Liens utiles** : $references
- **FAQ / Glossaire** : $faq

---

_Généré automatiquement par mode-scaffold.ps1_
"@

# Création du fichier template
New-Item -ItemType File -Path $TemplatePath -Force | Out-Null
Set-Content -Path $TemplatePath -Value $template -Encoding UTF8

Write-Host "Template universel généré dans $TemplatePath"
Write-Host "Vous pouvez compléter ou éditer le fichier selon vos besoins."