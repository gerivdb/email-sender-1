#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation de MediaExtractedInfo.

.DESCRIPTION
Ce script montre comment créer et exporter des objets MediaExtractedInfo
dans différents formats (HTML, Markdown, JSON, etc.).

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\Media"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un fichier temporaire pour simuler un média
$tempImagePath = Join-Path -Path $env:TEMP -ChildPath "sample_image.jpg"
if (-not (Test-Path -Path $tempImagePath)) {
    # Créer un fichier vide pour simuler une image
    New-Item -Path $tempImagePath -ItemType File -Force | Out-Null
    # Ajouter quelques octets pour simuler un contenu
    [System.IO.File]::WriteAllBytes($tempImagePath, [byte[]]@(255, 216, 255, 224, 0, 16, 74, 70, 73, 70))
}

$tempVideoPath = Join-Path -Path $env:TEMP -ChildPath "sample_video.mp4"
if (-not (Test-Path -Path $tempVideoPath)) {
    # Créer un fichier vide pour simuler une vidéo
    New-Item -Path $tempVideoPath -ItemType File -Force | Out-Null
    # Ajouter quelques octets pour simuler un contenu
    [System.IO.File]::WriteAllBytes($tempVideoPath, [byte[]]@(0, 0, 0, 24, 102, 116, 121, 112, 109, 112, 52, 50))
}

# Exemple 1: Créer et exporter des informations sur une image
Write-Host "Exemple 1: Informations sur une image" -ForegroundColor Green
$imageInfo = New-MediaExtractedInfo -Source "photo.jpg" -MediaPath $tempImagePath -MediaType "Image"
$imageInfo = Add-ExtractedInfoMetadata -Info $imageInfo -Metadata @{
    Width = 1920
    Height = 1080
    Format = "JPEG"
    ColorSpace = "RGB"
    CameraMake = "Canon"
    CameraModel = "EOS 5D Mark IV"
    DateTaken = [datetime]::Now.AddDays(-30).ToString("o")
    Location = @{
        Latitude = 48.8566
        Longitude = 2.3522
        City = "Paris"
        Country = "France"
    }
}

# Exporter en HTML avec l'adaptateur générique
$htmlImageInfo = Export-GenericExtractedInfo -Info $imageInfo -Format "HTML" -IncludeMetadata
$htmlImageInfoPath = Join-Path -Path $outputDir -ChildPath "image_info.html"
$htmlImageInfo | Out-File -FilePath $htmlImageInfoPath -Encoding utf8
Write-Host "  Fichier HTML créé : $htmlImageInfoPath" -ForegroundColor Green

# Exporter en Markdown avec l'adaptateur générique
$mdImageInfo = Export-GenericExtractedInfo -Info $imageInfo -Format "MARKDOWN" -IncludeMetadata
$mdImageInfoPath = Join-Path -Path $outputDir -ChildPath "image_info.md"
$mdImageInfo | Out-File -FilePath $mdImageInfoPath -Encoding utf8
Write-Host "  Fichier Markdown créé : $mdImageInfoPath" -ForegroundColor Green

# Exemple 2: Informations sur une vidéo
Write-Host "Exemple 2: Informations sur une vidéo" -ForegroundColor Green
$videoInfo = New-MediaExtractedInfo -Source "video.mp4" -MediaPath $tempVideoPath -MediaType "Video"
$videoInfo = Add-ExtractedInfoMetadata -Info $videoInfo -Metadata @{
    Width = 3840
    Height = 2160
    Format = "MP4"
    Codec = "H.264"
    Duration = "00:05:30"
    FrameRate = 30
    AudioChannels = 2
    AudioSampleRate = 48000
    Director = "John Smith"
    DateCreated = [datetime]::Now.AddDays(-15).ToString("o")
    Tags = @("vacation", "family", "beach")
}

# Exporter en HTML avec thème sombre
$htmlVideoInfo = Export-GenericExtractedInfo -Info $videoInfo -Format "HTML" -IncludeMetadata -ExportOptions @{ Theme = "Dark" }
$htmlVideoInfoPath = Join-Path -Path $outputDir -ChildPath "video_info_dark.html"
$htmlVideoInfo | Out-File -FilePath $htmlVideoInfoPath -Encoding utf8
Write-Host "  Fichier HTML avec thème sombre créé : $htmlVideoInfoPath" -ForegroundColor Green

# Exemple 3: Exporter en JSON et XML
Write-Host "Exemple 3: Exportation en JSON et XML" -ForegroundColor Green
$jsonVideoInfo = Export-GenericExtractedInfo -Info $videoInfo -Format "JSON" -IncludeMetadata
$jsonVideoInfoPath = Join-Path -Path $outputDir -ChildPath "video_info.json"
$jsonVideoInfo | Out-File -FilePath $jsonVideoInfoPath -Encoding utf8
Write-Host "  Fichier JSON créé : $jsonVideoInfoPath" -ForegroundColor Green

$xmlVideoInfo = Export-GenericExtractedInfo -Info $videoInfo -Format "XML" -IncludeMetadata
$xmlVideoInfoPath = Join-Path -Path $outputDir -ChildPath "video_info.xml"
$xmlVideoInfo | Out-File -FilePath $xmlVideoInfoPath -Encoding utf8
Write-Host "  Fichier XML créé : $xmlVideoInfoPath" -ForegroundColor Green

# Exemple 4: Informations sur un fichier audio
Write-Host "Exemple 4: Informations sur un fichier audio" -ForegroundColor Green
$audioInfo = New-MediaExtractedInfo -Source "audio.mp3" -MediaPath "$env:TEMP\sample_audio.mp3" -MediaType "Audio"
$audioInfo = Add-ExtractedInfoMetadata -Info $audioInfo -Metadata @{
    Format = "MP3"
    Duration = "00:03:45"
    Bitrate = 320
    SampleRate = 44100
    Channels = 2
    Artist = "Jane Doe"
    Album = "Example Album"
    Title = "Example Song"
    Year = 2023
    Genre = "Rock"
}

# Exporter en TXT
$txtAudioInfo = Export-GenericExtractedInfo -Info $audioInfo -Format "TXT" -IncludeMetadata
$txtAudioInfoPath = Join-Path -Path $outputDir -ChildPath "audio_info.txt"
$txtAudioInfo | Out-File -FilePath $txtAudioInfoPath -Encoding utf8
Write-Host "  Fichier TXT créé : $txtAudioInfoPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlImageInfoPath
Start-Process $mdImageInfoPath
Start-Process $htmlVideoInfoPath
Start-Process $jsonVideoInfoPath
Start-Process $txtAudioInfoPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green
