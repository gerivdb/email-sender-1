# Format markdown files selon les règles définies dans .markdownlint.json
# Ce script transforme les blocs de code sans langage spécifié en blocs avec 'plaintext'

$markdownFiles = Get-ChildItem -Path . -Recurse -Include "*.md" -Exclude "*.markdown-config-readme.md"

foreach ($file in $markdownFiles) {
   Write-Host "Traitement du fichier: $($file.FullName)"
    
   # Lecture du contenu
   $content = Get-Content -Path $file.FullName -Raw
    
   # Remplacement des blocs de code sans langage par 'plaintext'
   $newContent = $content -replace '(?m)^```\s*$', '```plaintext'
    
   # Remplacement des titres italiques/gras en h2/h3
   $newContent = $newContent -replace '(?m)^\*\*\*(.+?)\*\*\*$', '### $1'
   $newContent = $newContent -replace '(?m)^\*\*(.+?)\*\*$', '## $1'
    
   # Correction des sauts de ligne
   $newContent = $newContent -replace '(?m)(\#{1,6}.+?)(\r?\n)(?!\r?\n)', '$1$2$2'
    
   # Écriture du contenu modifié
   $newContent | Set-Content -Path $file.FullName -NoNewline
    
   Write-Host "Format terminé: $($file.FullName)"
}

Write-Host "Tous les fichiers markdown ont été formatés selon les règles définies!"
