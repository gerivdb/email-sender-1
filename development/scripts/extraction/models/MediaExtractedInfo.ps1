using namespace System.Collections.Generic
using namespace System.IO

<#
.SYNOPSIS
    Classe pour les informations mÃ©dias extraites.
.DESCRIPTION
    Ã‰tend la classe ValidatableExtractedInfo pour reprÃ©senter
    des informations extraites de fichiers mÃ©dias (images, audio, vidÃ©o).
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\ValidatableExtractedInfo.ps1"

class MediaExtractedInfo : ValidatableExtractedInfo {
    # PropriÃ©tÃ©s spÃ©cifiques aux informations mÃ©dias
    [string]$MediaPath
    [string]$MediaType
    [string]$MimeType
    [long]$FileSize
    [datetime]$FileCreatedDate
    [datetime]$FileModifiedDate
    [hashtable]$MediaMetadata
    [hashtable]$TechnicalInfo
    [string]$Checksum

    # Constructeur par dÃ©faut
    MediaExtractedInfo() : base() {
        $this.InitializeMediaInfo()
    }

    # Constructeur avec source
    MediaExtractedInfo([string]$source) : base($source) {
        $this.InitializeMediaInfo()
    }

    # Constructeur avec source et extracteur
    MediaExtractedInfo([string]$source, [string]$extractorName) : base($source, $extractorName) {
        $this.InitializeMediaInfo()
    }

    # Constructeur avec chemin de mÃ©dia
    MediaExtractedInfo([string]$source, [string]$extractorName, [string]$mediaPath) : base($source, $extractorName) {
        $this.InitializeMediaInfo()
        $this.SetMediaPath($mediaPath)
    }

    # MÃ©thode d'initialisation des informations mÃ©dias
    hidden [void] InitializeMediaInfo() {
        $this.MediaPath = ""
        $this.MediaType = ""
        $this.MimeType = ""
        $this.FileSize = 0
        $this.FileCreatedDate = [datetime]::MinValue
        $this.FileModifiedDate = [datetime]::MinValue
        $this.MediaMetadata = @{}
        $this.TechnicalInfo = @{}
        $this.Checksum = ""
        
        # Ajouter les rÃ¨gles de validation spÃ©cifiques aux mÃ©dias
        $this.AddMediaValidationRules()
    }

    # MÃ©thode pour ajouter les rÃ¨gles de validation spÃ©cifiques aux mÃ©dias
    hidden [void] AddMediaValidationRules() {
        # Validation du chemin du mÃ©dia
        $this.AddValidationRule("MediaPath", {
            param($target, $value)
            return -not [string]::IsNullOrEmpty($value)
        }, "Le chemin du mÃ©dia ne peut pas Ãªtre vide")

        # Validation du type de mÃ©dia
        $this.AddValidationRule("MediaType", {
            param($target, $value)
            $validTypes = @("Image", "Audio", "Video", "Document", "Other")
            return -not [string]::IsNullOrEmpty($value) -and $validTypes -contains $value
        }, "Le type de mÃ©dia doit Ãªtre l'un des suivants: Image, Audio, Video, Document, Other")

        # Validation de la taille du fichier
        $this.AddValidationRule("FileSize", {
            param($target, $value)
            return $value -ge 0
        }, "La taille du fichier doit Ãªtre positive ou nulle")
    }

    # MÃ©thode pour dÃ©finir le chemin du mÃ©dia et extraire les informations
    [void] SetMediaPath([string]$mediaPath) {
        if ([string]::IsNullOrEmpty($mediaPath)) {
            throw "Le chemin du mÃ©dia ne peut pas Ãªtre vide"
        }
        
        if (-not [File]::Exists($mediaPath)) {
            throw "Le fichier mÃ©dia n'existe pas: $mediaPath"
        }
        
        $this.MediaPath = $mediaPath
        $this.ExtractFileInfo()
    }

    # MÃ©thode pour extraire les informations de base du fichier
    [void] ExtractFileInfo() {
        try {
            $fileInfo = [FileInfo]::new($this.MediaPath)
            
            $this.FileSize = $fileInfo.Length
            $this.FileCreatedDate = $fileInfo.CreationTime
            $this.FileModifiedDate = $fileInfo.LastWriteTime
            
            # DÃ©terminer le type de mÃ©dia et le MIME type
            $extension = $fileInfo.Extension.ToLower()
            
            $this.DetermineMediaTypeAndMime($extension)
            $this.ExtractMediaMetadata()
            $this.CalculateChecksum()
        }
        catch {
            throw "Erreur lors de l'extraction des informations du fichier: $_"
        }
    }

    # MÃ©thode pour dÃ©terminer le type de mÃ©dia et le MIME type
    hidden [void] DetermineMediaTypeAndMime([string]$extension) {
        $mediaTypeMap = @{
            # Images
            ".jpg"  = @{ Type = "Image"; Mime = "image/jpeg" }
            ".jpeg" = @{ Type = "Image"; Mime = "image/jpeg" }
            ".png"  = @{ Type = "Image"; Mime = "image/png" }
            ".gif"  = @{ Type = "Image"; Mime = "image/gif" }
            ".bmp"  = @{ Type = "Image"; Mime = "image/bmp" }
            ".tiff" = @{ Type = "Image"; Mime = "image/tiff" }
            ".webp" = @{ Type = "Image"; Mime = "image/webp" }
            
            # Audio
            ".mp3"  = @{ Type = "Audio"; Mime = "audio/mpeg" }
            ".wav"  = @{ Type = "Audio"; Mime = "audio/wav" }
            ".ogg"  = @{ Type = "Audio"; Mime = "audio/ogg" }
            ".flac" = @{ Type = "Audio"; Mime = "audio/flac" }
            ".aac"  = @{ Type = "Audio"; Mime = "audio/aac" }
            
            # VidÃ©o
            ".mp4"  = @{ Type = "Video"; Mime = "video/mp4" }
            ".avi"  = @{ Type = "Video"; Mime = "video/x-msvideo" }
            ".mov"  = @{ Type = "Video"; Mime = "video/quicktime" }
            ".wmv"  = @{ Type = "Video"; Mime = "video/x-ms-wmv" }
            ".mkv"  = @{ Type = "Video"; Mime = "video/x-matroska" }
            
            # Documents
            ".pdf"  = @{ Type = "Document"; Mime = "application/pdf" }
            ".doc"  = @{ Type = "Document"; Mime = "application/msword" }
            ".docx" = @{ Type = "Document"; Mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
            ".xls"  = @{ Type = "Document"; Mime = "application/vnd.ms-excel" }
            ".xlsx" = @{ Type = "Document"; Mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
            ".ppt"  = @{ Type = "Document"; Mime = "application/vnd.ms-powerpoint" }
            ".pptx" = @{ Type = "Document"; Mime = "application/vnd.openxmlformats-officedocument.presentationml.presentation" }
        }
        
        if ($mediaTypeMap.ContainsKey($extension)) {
            $this.MediaType = $mediaTypeMap[$extension].Type
            $this.MimeType = $mediaTypeMap[$extension].Mime
        }
        else {
            $this.MediaType = "Other"
            $this.MimeType = "application/octet-stream"
        }
    }

    # MÃ©thode pour extraire les mÃ©tadonnÃ©es du mÃ©dia (implÃ©mentation simplifiÃ©e)
    [void] ExtractMediaMetadata() {
        # Initialiser les mÃ©tadonnÃ©es
        $this.MediaMetadata = @{
            FileName = [Path]::GetFileName($this.MediaPath)
            Extension = [Path]::GetExtension($this.MediaPath)
            Directory = [Path]::GetDirectoryName($this.MediaPath)
            CreatedDate = $this.FileCreatedDate.ToString("yyyy-MM-dd HH:mm:ss")
            ModifiedDate = $this.FileModifiedDate.ToString("yyyy-MM-dd HH:mm:ss")
            SizeBytes = $this.FileSize
            SizeKB = [math]::Round($this.FileSize / 1024, 2)
            SizeMB = [math]::Round($this.FileSize / (1024 * 1024), 2)
        }
        
        # Extraire des mÃ©tadonnÃ©es spÃ©cifiques selon le type de mÃ©dia
        switch ($this.MediaType) {
            "Image" {
                $this.ExtractImageMetadata()
            }
            "Audio" {
                $this.ExtractAudioMetadata()
            }
            "Video" {
                $this.ExtractVideoMetadata()
            }
            "Document" {
                $this.ExtractDocumentMetadata()
            }
        }
    }

    # MÃ©thode pour extraire les mÃ©tadonnÃ©es d'une image (implÃ©mentation simplifiÃ©e)
    hidden [void] ExtractImageMetadata() {
        # Dans une implÃ©mentation rÃ©elle, on utiliserait une bibliothÃ¨que comme System.Drawing
        # ou ExifTool pour extraire les mÃ©tadonnÃ©es EXIF, etc.
        
        $this.TechnicalInfo = @{
            Format = [Path]::GetExtension($this.MediaPath).TrimStart(".")
            Width = 0
            Height = 0
            ColorDepth = 0
            DPI = 0
        }
    }

    # MÃ©thode pour extraire les mÃ©tadonnÃ©es d'un fichier audio (implÃ©mentation simplifiÃ©e)
    hidden [void] ExtractAudioMetadata() {
        # Dans une implÃ©mentation rÃ©elle, on utiliserait une bibliothÃ¨que comme NAudio
        # ou TagLib# pour extraire les mÃ©tadonnÃ©es ID3, etc.
        
        $this.TechnicalInfo = @{
            Format = [Path]::GetExtension($this.MediaPath).TrimStart(".")
            Duration = 0
            Bitrate = 0
            SampleRate = 0
            Channels = 0
        }
    }

    # MÃ©thode pour extraire les mÃ©tadonnÃ©es d'une vidÃ©o (implÃ©mentation simplifiÃ©e)
    hidden [void] ExtractVideoMetadata() {
        # Dans une implÃ©mentation rÃ©elle, on utiliserait une bibliothÃ¨que comme MediaInfo
        # ou FFmpeg pour extraire les mÃ©tadonnÃ©es vidÃ©o
        
        $this.TechnicalInfo = @{
            Format = [Path]::GetExtension($this.MediaPath).TrimStart(".")
            Duration = 0
            Width = 0
            Height = 0
            FrameRate = 0
            Bitrate = 0
            VideoCodec = ""
            AudioCodec = ""
        }
    }

    # MÃ©thode pour extraire les mÃ©tadonnÃ©es d'un document (implÃ©mentation simplifiÃ©e)
    hidden [void] ExtractDocumentMetadata() {
        # Dans une implÃ©mentation rÃ©elle, on utiliserait une bibliothÃ¨que comme iTextSharp
        # ou DocumentFormat.OpenXml pour extraire les mÃ©tadonnÃ©es du document
        
        $this.TechnicalInfo = @{
            Format = [Path]::GetExtension($this.MediaPath).TrimStart(".")
            PageCount = 0
            Author = ""
            Title = ""
            Subject = ""
            Keywords = ""
            CreationDate = ""
            ModificationDate = ""
        }
    }

    # MÃ©thode pour calculer le checksum du fichier
    [void] CalculateChecksum() {
        try {
            $sha256 = [System.Security.Cryptography.SHA256]::Create()
            $fileStream = [System.IO.File]::OpenRead($this.MediaPath)
            
            $hashBytes = $sha256.ComputeHash($fileStream)
            $fileStream.Close()
            
            $this.Checksum = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        }
        catch {
            $this.Checksum = ""
            throw "Erreur lors du calcul du checksum: $_"
        }
    }

    # MÃ©thode pour vÃ©rifier l'intÃ©gritÃ© du fichier
    [bool] VerifyIntegrity([string]$expectedChecksum) {
        if ([string]::IsNullOrEmpty($this.Checksum)) {
            $this.CalculateChecksum()
        }
        
        return $this.Checksum -eq $expectedChecksum
    }

    # MÃ©thode pour obtenir le chemin absolu du fichier
    [string] GetAbsolutePath() {
        if ([string]::IsNullOrEmpty($this.MediaPath)) {
            return ""
        }
        
        return [Path]::GetFullPath($this.MediaPath)
    }

    # MÃ©thode pour obtenir l'extension du fichier
    [string] GetExtension() {
        if ([string]::IsNullOrEmpty($this.MediaPath)) {
            return ""
        }
        
        return [Path]::GetExtension($this.MediaPath)
    }

    # MÃ©thode pour obtenir le nom du fichier
    [string] GetFileName() {
        if ([string]::IsNullOrEmpty($this.MediaPath)) {
            return ""
        }
        
        return [Path]::GetFileName($this.MediaPath)
    }

    # MÃ©thode pour obtenir le nom du fichier sans extension
    [string] GetFileNameWithoutExtension() {
        if ([string]::IsNullOrEmpty($this.MediaPath)) {
            return ""
        }
        
        return [Path]::GetFileNameWithoutExtension($this.MediaPath)
    }

    # Surcharge de la mÃ©thode GetSummary
    [string] GetSummary() {
        $baseInfo = ([ValidatableExtractedInfo]$this).GetSummary()
        $sizeKB = [math]::Round($this.FileSize / 1024, 2)
        return "$baseInfo, MÃ©dia: $($this.MediaType), Taille: $sizeKB KB, CrÃ©Ã© le: $($this.FileCreatedDate.ToString('yyyy-MM-dd'))"
    }

    # Surcharge de la mÃ©thode Clone pour retourner un MediaExtractedInfo
    [MediaExtractedInfo] Clone() {
        $clone = [MediaExtractedInfo]::new()
        
        # Cloner les propriÃ©tÃ©s de base
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid
        
        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }
        
        # Cloner les rÃ¨gles de validation
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]
            
            foreach ($rule in $rules) {
                $clonedRule = $rule.Clone()
                
                if (-not $clone.ValidationRules.ContainsKey($propertyName)) {
                    $clone.ValidationRules[$propertyName] = [List[ValidationRule]]::new()
                }
                
                $clone.ValidationRules[$propertyName].Add($clonedRule)
            }
        }
        
        # Cloner les propriÃ©tÃ©s spÃ©cifiques
        $clone.MediaPath = $this.MediaPath
        $clone.MediaType = $this.MediaType
        $clone.MimeType = $this.MimeType
        $clone.FileSize = $this.FileSize
        $clone.FileCreatedDate = $this.FileCreatedDate
        $clone.FileModifiedDate = $this.FileModifiedDate
        $clone.Checksum = $this.Checksum
        
        # Cloner les hashtables
        $clone.MediaMetadata = @{}
        foreach ($key in $this.MediaMetadata.Keys) {
            $clone.MediaMetadata[$key] = $this.MediaMetadata[$key]
        }
        
        $clone.TechnicalInfo = @{}
        foreach ($key in $this.TechnicalInfo.Keys) {
            $clone.TechnicalInfo[$key] = $this.TechnicalInfo[$key]
        }
        
        return $clone
    }
}
