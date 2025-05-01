# Script simple pour mettre à jour les tâches restantes de l'AST Navigator dans la roadmap

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $roadmapPath -Encoding UTF8

# Remplacer les tâches non cochées par des tâches cochées
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\.1\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.1**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\.2\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.2**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\.3\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.3**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\.4\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.4**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.3\.5\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.5**'

$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\.1\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.1**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\.2\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.2**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\.3\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.3**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\.4\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.4**'
$content = $content -replace '- \[ \] \*\*2\.1\.2\.4\.1\.2\.3\.2\.2\.5\.3\.2\.2\.1\.3\.4\.5\*\*', '- [x] **2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.5**'

# Sauvegarder le contenu mis à jour
$content | Set-Content -Path $roadmapPath -Encoding UTF8

Write-Host "Le fichier de roadmap a été mis à jour avec succès." -ForegroundColor Green
