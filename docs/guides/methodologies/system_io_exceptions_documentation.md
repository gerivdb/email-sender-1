# Documentation des exceptions du namespace System.IO

## Introduction

Le namespace `System.IO` contient les exceptions liées aux opérations d'entrée/sortie dans le framework .NET. Ces exceptions sont essentielles pour gérer les erreurs qui peuvent survenir lors de la manipulation de fichiers, de répertoires et de flux de données. Comprendre ces exceptions, leurs cas d'utilisation et leurs caractéristiques est crucial pour développer des applications robustes qui interagissent avec le système de fichiers.

Cette documentation présente en détail les exceptions principales du namespace `System.IO`, leurs hiérarchies, leurs cas d'utilisation typiques, et fournit des exemples concrets en PowerShell pour illustrer leur comportement.

## IOException et ses caractéristiques

### Vue d'ensemble

`IOException` est l'exception de base pour toutes les erreurs d'entrée/sortie dans le framework .NET. Elle est levée lorsqu'une opération d'entrée/sortie échoue, comme la lecture ou l'écriture dans un fichier, l'accès à un périphérique, ou toute autre opération impliquant des ressources externes.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IO.IOException
        ├── System.IO.FileNotFoundException
        ├── System.IO.DirectoryNotFoundException
        ├── System.IO.PathTooLongException
        ├── System.IO.DriveNotFoundException
        ├── System.IO.EndOfStreamException
        ├── System.IO.FileLoadException
        ├── System.IO.InternalBufferOverflowException
        └── System.IO.PipeException
```

### Description

`IOException` est une exception générique qui indique qu'une erreur s'est produite lors d'une opération d'entrée/sortie. Elle peut être causée par diverses raisons, telles que des problèmes de périphérique, des erreurs de réseau, des problèmes de permissions, ou des erreurs de système de fichiers.

### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| HResult | int | Code d'erreur numérique qui peut fournir des informations supplémentaires sur l'erreur |

### Constructeurs principaux

```csharp
IOException()
IOException(string message)
IOException(string message, Exception innerException)
IOException(string message, int hresult)
IOException(string message, int hresult, Exception innerException)
```

### Cas d'utilisation typiques

1. **Erreurs de lecture/écriture de fichier** : Problèmes lors de la lecture ou de l'écriture dans un fichier.

2. **Problèmes d'accès au périphérique** : Erreurs lors de l'accès à un périphérique de stockage.

3. **Erreurs de réseau** : Problèmes lors de la lecture ou de l'écriture sur un réseau.

4. **Fichier verrouillé** : Tentative d'accès à un fichier qui est déjà utilisé par un autre processus.

5. **Espace disque insuffisant** : Tentative d'écriture sur un disque qui n'a pas assez d'espace libre.

### Exemples en PowerShell

```powershell
# Exemple 1: Erreur de lecture de fichier
function Read-FileWithIOExceptionHandling {
    param (
        [string]$FilePath
    )
    
    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        $reader = [System.IO.StreamReader]::new($fileStream)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $fileStream.Close()
        return $content
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S lors de la lecture du fichier: $($_.Exception.Message)"
        return $null
    } finally {
        if ($reader -ne $null) { $reader.Dispose() }
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

# Tentative de lecture d'un fichier qui est peut-être verrouillé ou inaccessible
Read-FileWithIOExceptionHandling -FilePath "C:\Windows\System32\drivers\etc\hosts"

# Exemple 2: Erreur d'écriture de fichier
function Write-FileWithIOExceptionHandling {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Create)
        $writer = [System.IO.StreamWriter]::new($fileStream)
        $writer.Write($Content)
        $writer.Flush()
        $writer.Close()
        $fileStream.Close()
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S lors de l'écriture dans le fichier: $($_.Exception.Message)"
        return $false
    } finally {
        if ($writer -ne $null) { $writer.Dispose() }
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

# Tentative d'écriture dans un fichier qui est peut-être en lecture seule ou inaccessible
Write-FileWithIOExceptionHandling -FilePath "C:\Windows\System32\test.txt" -Content "Test"

# Exemple 3: Fichier verrouillé par un autre processus
function Demonstrate-LockedFileIOException {
    param (
        [string]$FilePath
    )
    
    try {
        # Créer un fichier et le garder ouvert
        $fileStream1 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        Write-Host "Fichier créé et verrouillé: $FilePath"
        
        # Tenter d'ouvrir le même fichier dans un autre flux
        Write-Host "Tentative d'ouverture du fichier verrouillé..."
        $fileStream2 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        
        # Cette ligne ne sera jamais exécutée
        Write-Host "Fichier ouvert avec succès (cela ne devrait pas se produire)"
        $fileStream2.Close()
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée: $($_.Exception.Message)"
        Write-Host "HResult: $($_.Exception.HResult)"
    } finally {
        if ($fileStream1 -ne $null) { 
            $fileStream1.Close() 
            Write-Host "Premier flux fermé, le fichier est maintenant déverrouillé"
        }
    }
}

$tempFile = [System.IO.Path]::GetTempFileName()
Demonstrate-LockedFileIOException -FilePath $tempFile
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

# Exemple 4: Espace disque insuffisant (simulation)
function Simulate-DiskFullIOException {
    param (
        [string]$Message = "There is not enough space on the disk."
    )
    
    # Simuler une IOException avec un message d'espace disque insuffisant
    $exception = [System.IO.IOException]::new($Message, -2147024784)  # 0x80070070 (ERROR_DISK_FULL)
    
    try {
        throw $exception
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée: $($_.Exception.Message)"
        Write-Host "HResult: $($_.Exception.HResult)"
        
        # Vérifier si c'est une erreur de disque plein
        if ($_.Exception.HResult -eq -2147024784) {
            Write-Host "Erreur spécifique: Espace disque insuffisant"
        }
    }
}

Simulate-DiskFullIOException

# Exemple 5: Utilisation de la classe File avec gestion des IOException
function Copy-FileWithIOExceptionHandling {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    try {
        [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
        Write-Host "Fichier copié avec succès de $SourcePath vers $DestinationPath"
        return $true
    } catch [System.IO.FileNotFoundException] {
        # Gestion spécifique pour FileNotFoundException
        Write-Host "Le fichier source n'existe pas: $SourcePath"
        return $false
    } catch [System.IO.IOException] {
        # Gestion générique pour les autres IOException
        Write-Host "Erreur d'E/S lors de la copie du fichier: $($_.Exception.Message)"
        return $false
    }
}

# Créer un fichier temporaire pour le test
$sourceFile = [System.IO.Path]::GetTempFileName()
$destinationFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "copied_file.tmp")

# Écrire du contenu dans le fichier source
[System.IO.File]::WriteAllText($sourceFile, "Contenu de test")

# Copier le fichier
Copy-FileWithIOExceptionHandling -SourcePath $sourceFile -DestinationPath $destinationFile

# Nettoyer
Remove-Item -Path $sourceFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $destinationFile -Force -ErrorAction SilentlyContinue
```

### Codes HResult courants pour IOException

Les codes HResult peuvent fournir des informations plus précises sur la nature de l'erreur d'E/S. Voici quelques codes courants :

| Code HResult | Valeur hexadécimale | Description |
|--------------|---------------------|-------------|
| -2147024784 | 0x80070070 | ERROR_DISK_FULL - Le disque est plein |
| -2147024864 | 0x80070020 | ERROR_SHARING_VIOLATION - Le fichier est utilisé par un autre processus |
| -2147024891 | 0x80070005 | ERROR_ACCESS_DENIED - Accès refusé |
| -2147024893 | 0x80070003 | ERROR_PATH_NOT_FOUND - Le chemin spécifié est introuvable |
| -2147024894 | 0x80070002 | ERROR_FILE_NOT_FOUND - Le fichier spécifié est introuvable |

### Prévention des IOException

Voici plusieurs techniques pour éviter les `IOException` :

#### 1. Utilisation de blocs try-catch-finally

```powershell
function Process-FileWithProperCleanup {
    param (
        [string]$FilePath
    )
    
    $fileStream = $null
    
    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        # Traitement du fichier...
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S: $($_.Exception.Message)"
        return $false
    } finally {
        # Toujours fermer et disposer des ressources, même en cas d'erreur
        if ($fileStream -ne $null) {
            $fileStream.Dispose()
        }
    }
}
```

#### 2. Utilisation de l'instruction using (en C#) ou de son équivalent en PowerShell

```powershell
function Process-FileWithUsing {
    param (
        [string]$FilePath
    )
    
    try {
        # En PowerShell 7+, vous pouvez utiliser le mot-clé 'using'
        # Pour PowerShell 5.1, nous simulons le comportement
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        try {
            # Traitement du fichier...
            return $true
        } finally {
            $fileStream.Dispose()
        }
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S: $($_.Exception.Message)"
        return $false
    }
}
```

#### 3. Vérification préalable des conditions

```powershell
function Write-FileWithPreCheck {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    # Vérifier si le répertoire existe
    $directory = [System.IO.Path]::GetDirectoryName($FilePath)
    if (-not [System.IO.Directory]::Exists($directory)) {
        Write-Host "Le répertoire n'existe pas: $directory"
        return $false
    }
    
    # Vérifier si le fichier est en lecture seule
    if ([System.IO.File]::Exists($FilePath)) {
        $fileInfo = [System.IO.FileInfo]::new($FilePath)
        if ($fileInfo.IsReadOnly) {
            Write-Host "Le fichier est en lecture seule: $FilePath"
            return $false
        }
    }
    
    # Vérifier l'espace disque disponible
    $driveInfo = [System.IO.DriveInfo]::new([System.IO.Path]::GetPathRoot($FilePath))
    if ($driveInfo.AvailableFreeSpace -lt $Content.Length) {
        Write-Host "Espace disque insuffisant sur $($driveInfo.Name)"
        return $false
    }
    
    # Maintenant, tenter d'écrire dans le fichier
    try {
        [System.IO.File]::WriteAllText($FilePath, $Content)
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S malgré les vérifications: $($_.Exception.Message)"
        return $false
    }
}
```

#### 4. Utilisation de FileShare pour éviter les conflits

```powershell
function Open-FileWithSharing {
    param (
        [string]$FilePath
    )
    
    try {
        # Ouvrir le fichier avec FileShare.ReadWrite pour permettre à d'autres processus de l'utiliser
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        
        # Traitement du fichier...
        $fileStream.Close()
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S malgré le partage: $($_.Exception.Message)"
        return $false
    }
}
```

#### 5. Implémentation de mécanismes de retry

```powershell
function Read-FileWithRetry {
    param (
        [string]$FilePath,
        [int]$MaxRetries = 3,
        [int]$RetryDelayMs = 1000
    )
    
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            $content = [System.IO.File]::ReadAllText($FilePath)
            return $content
        } catch [System.IO.IOException] {
            $retryCount++
            Write-Host "Tentative $retryCount/$MaxRetries a échoué: $($_.Exception.Message)"
            
            if ($retryCount -ge $MaxRetries) {
                Write-Host "Nombre maximum de tentatives atteint. Abandon."
                return $null
            }
            
            # Attendre avant de réessayer
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }
}
```

### Débogage des IOException

Lorsque vous rencontrez une `IOException`, voici quelques étapes pour la déboguer efficacement :

1. **Examiner le message d'exception** : Le message peut contenir des informations utiles sur la cause de l'erreur.

2. **Vérifier le code HResult** : Le code HResult peut fournir des informations plus précises sur la nature de l'erreur.

3. **Vérifier les permissions** : Assurez-vous que l'application a les permissions nécessaires pour accéder au fichier ou au répertoire.

4. **Vérifier si le fichier est verrouillé** : Utilisez des outils comme Process Explorer pour voir si le fichier est utilisé par un autre processus.

5. **Vérifier l'espace disque** : Assurez-vous qu'il y a suffisamment d'espace disque disponible.

```powershell
function Debug-IOException {
    param (
        [string]$FilePath,
        [string]$Operation = "Read"  # "Read" ou "Write"
    )
    
    Write-Host "Débogage d'opération d'E/S sur le fichier: $FilePath"
    
    # Vérifier si le fichier existe
    if (-not [System.IO.File]::Exists($FilePath)) {
        Write-Host "Le fichier n'existe pas"
        return
    }
    
    # Obtenir les informations sur le fichier
    $fileInfo = [System.IO.FileInfo]::new($FilePath)
    Write-Host "Taille du fichier: $($fileInfo.Length) octets"
    Write-Host "Dernière modification: $($fileInfo.LastWriteTime)"
    Write-Host "Attributs: $($fileInfo.Attributes)"
    
    # Vérifier si le fichier est en lecture seule
    if ($fileInfo.IsReadOnly) {
        Write-Host "ATTENTION: Le fichier est en lecture seule"
    }
    
    # Vérifier l'espace disque
    $driveInfo = [System.IO.DriveInfo]::new($fileInfo.Directory.Root.FullName)
    Write-Host "Espace disque disponible: $($driveInfo.AvailableFreeSpace) octets"
    
    # Tenter l'opération avec capture détaillée de l'exception
    try {
        if ($Operation -eq "Read") {
            $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        } else {
            $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
        }
        
        Write-Host "Opération réussie"
        $fileStream.Close()
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée:"
        Write-Host "  Message: $($_.Exception.Message)"
        Write-Host "  HResult: $($_.Exception.HResult) (0x$($_.Exception.HResult.ToString('X8')))"
        
        # Interpréter le code HResult
        switch ($_.Exception.HResult) {
            -2147024784 { Write-Host "  Interprétation: Espace disque insuffisant" }
            -2147024864 { Write-Host "  Interprétation: Le fichier est utilisé par un autre processus" }
            -2147024891 { Write-Host "  Interprétation: Accès refusé" }
            -2147024893 { Write-Host "  Interprétation: Chemin introuvable" }
            -2147024894 { Write-Host "  Interprétation: Fichier introuvable" }
            default { Write-Host "  Interprétation: Code d'erreur non reconnu" }
        }
    }
}

# Exemple d'utilisation
$tempFile = [System.IO.Path]::GetTempFileName()
Debug-IOException -FilePath $tempFile -Operation "Write"
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
```

### Bonnes pratiques pour gérer les IOException

1. **Toujours fermer les ressources** : Utilisez des blocs `try-finally` ou l'équivalent de `using` pour vous assurer que les ressources sont correctement fermées.

2. **Gérer les exceptions spécifiques** : Capturez les exceptions dérivées de `IOException` avant de capturer `IOException` elle-même.

3. **Implémenter des mécanismes de retry** : Pour les opérations qui peuvent échouer temporairement, implémentez une logique de retry.

4. **Vérifier les conditions préalables** : Vérifiez les conditions qui pourraient causer une `IOException` avant de tenter l'opération.

5. **Utiliser les modes de partage appropriés** : Utilisez les modes de partage appropriés pour éviter les conflits d'accès aux fichiers.

6. **Journaliser les détails de l'exception** : Journalisez le message et le code HResult pour faciliter le débogage.

7. **Nettoyer les ressources temporaires** : Assurez-vous de nettoyer les fichiers temporaires, même en cas d'erreur.

### Résumé

`IOException` est l'exception de base pour toutes les erreurs d'entrée/sortie dans le framework .NET. Elle est levée lorsqu'une opération d'entrée/sortie échoue, comme la lecture ou l'écriture dans un fichier, l'accès à un périphérique, ou toute autre opération impliquant des ressources externes.

En comprenant les caractéristiques de `IOException`, ses codes HResult courants, et en appliquant les bonnes pratiques pour la prévention et le débogage, vous pouvez développer des applications plus robustes qui gèrent efficacement les erreurs d'entrée/sortie.
