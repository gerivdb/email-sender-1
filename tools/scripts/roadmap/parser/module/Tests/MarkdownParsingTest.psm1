# Module temporaire pour les tests
$functionsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\module\Functions\Parsing\MarkdownParsingFunctions.ps1"

# Charger le contenu du fichier
$content = Get-Content -Path $functionsPath -Raw

# Exécuter le contenu
$scriptBlock = [ScriptBlock]::Create($content)
. $scriptBlock

# Exporter les fonctions
Export-ModuleMember -Function Get-FileEncoding, Read-MarkdownFile, Get-MarkdownContent, Test-FileBOM, Parse-YamlFrontMatter
