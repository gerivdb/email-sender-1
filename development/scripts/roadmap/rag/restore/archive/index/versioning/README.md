# Gestionnaire de Versions

Ce module PowerShell fournit des fonctionnalites pour gerer les versions des documents indexes.

## Fonctionnalites

- Creation de nouvelles versions de documents
- Recuperation de versions specifiques
- Comparaison de versions
- Restauration de versions anterieures
- Purge de l'historique des versions

## Installation

1. Copiez le fichier `VersionManager.ps1` dans votre projet.
2. Importez le module avec la commande suivante :

```powershell
. "chemin/vers/VersionManager.ps1"
```

## Utilisation

### Creation d'une nouvelle version

```powershell
$document = [PSCustomObject]@{
    id = "doc1"
    title = "Document de test"
    content = "Contenu du document de test"
    author = "Jean Dupont"
    status = "draft"
}

# Creer une premiere version
$document = New-DocumentVersion -Document $document -VersionLabel "Version initiale" -VersionNotes "Creation du document"

# Modifier le document
$document.title = "Document de test modifie"
$document.content = "Contenu du document de test modifie"

# Creer une deuxieme version
$document = New-DocumentVersion -Document $document -VersionLabel "Version 2" -VersionNotes "Modification du document"
```

### Recuperation d'une version specifique

```powershell
# Recuperer une version par numero
$version = Get-DocumentVersion -Document $document -VersionNumber 1

# Recuperer une version par label
$version = Get-DocumentVersion -Document $document -VersionLabel "Version initiale"

# Recuperer une version avec son historique
$version = Get-DocumentVersion -Document $document -VersionNumber 1 -IncludeVersionHistory
```

### Comparaison de versions

```powershell
# Recuperer les versions a comparer
$version1 = Get-DocumentVersion -Document $document -VersionNumber 1
$version2 = Get-DocumentVersion -Document $document -VersionNumber 2

# Comparer les versions
$differences = Compare-DocumentVersions -Version1 $version1 -Version2 $version2 -Properties @("title", "content", "status")

# Afficher les differences
foreach ($change in $differences.changes) {
    Write-Output "Propriete: $($change.property)"
    Write-Output "Type de changement: $($change.change_type)"
    Write-Output "Ancienne valeur: $($change.old_value)"
    Write-Output "Nouvelle valeur: $($change.new_value)"
}
```

### Restauration d'une version anterieure

```powershell
# Restaurer une version par numero
$restoredDocument = Restore-DocumentVersion -Document $document -VersionNumber 1 -RestoreNotes "Restauration de la version initiale"

# Restaurer une version par label
$restoredDocument = Restore-DocumentVersion -Document $document -VersionLabel "Version initiale" -RestoreNotes "Restauration de la version initiale"
```

### Purge de l'historique des versions

```powershell
# Purger tout l'historique
$purgedDocument = Clear-DocumentVersionHistory -Document $document

# Purger l'historique en conservant les N dernieres versions
$purgedDocument = Clear-DocumentVersionHistory -Document $document -KeepLastVersions 2

# Purger l'historique en conservant la version actuelle
$purgedDocument = Clear-DocumentVersionHistory -Document $document -KeepCurrentVersion
```

## Fonctions

### New-DocumentVersion

Cree une nouvelle version d'un document.

#### Parametres

- `Document` : Le document dont on veut creer une nouvelle version.
- `VersionLabel` : Le label de la version (par defaut : "").
- `VersionNotes` : Les notes de la version (par defaut : "").
- `Author` : L'auteur de la version (par defaut : l'utilisateur courant).
- `Timestamp` : La date et l'heure de la version (par defaut : la date et l'heure courantes).

### Get-DocumentVersion

Recupere une version specifique d'un document.

#### Parametres

- `Document` : Le document dont on veut recuperer une version.
- `VersionNumber` : Le numero de la version a recuperer.
- `VersionLabel` : Le label de la version a recuperer.
- `IncludeVersionHistory` : Indique si l'historique des versions doit etre inclus dans la version recuperee (par defaut : $false).

### Compare-DocumentVersions

Compare deux versions d'un document.

#### Parametres

- `Version1` : La premiere version a comparer.
- `Version2` : La deuxieme version a comparer.
- `Properties` : Les proprietes a comparer (par defaut : "content", "title").
- `IncludeUnchanged` : Indique si les proprietes inchangees doivent etre incluses dans les resultats (par defaut : $false).

### Restore-DocumentVersion

Restaure une version anterieure d'un document.

#### Parametres

- `Document` : Le document dont on veut restaurer une version.
- `VersionNumber` : Le numero de la version a restaurer.
- `VersionLabel` : Le label de la version a restaurer.
- `RestoreNotes` : Les notes de la restauration (par defaut : "Restauration d'une version anterieure").
- `Author` : L'auteur de la restauration (par defaut : l'utilisateur courant).
- `Timestamp` : La date et l'heure de la restauration (par defaut : la date et l'heure courantes).

### Clear-DocumentVersionHistory

Purge l'historique des versions d'un document.

#### Parametres

- `Document` : Le document dont on veut purger l'historique des versions.
- `KeepLastVersions` : Le nombre de dernieres versions a conserver (par defaut : 0).
- `KeepCurrentVersion` : Indique si la version actuelle doit etre conservee (par defaut : $false).

## Exemple complet

Voir le fichier `TestVersionManager.ps1` pour un exemple complet d'utilisation du module.

## Structure des donnees

### Document avec historique des versions

```
{
    "id": "doc1",
    "title": "Document de test",
    "content": "Contenu du document de test",
    "author": "Jean Dupont",
    "status": "draft",
    "version_number": 2,
    "version_label": "Version 2",
    "last_modified_by": "Jean Dupont",
    "last_modified_at": "2024-05-15T10:30:00Z",
    "version_history": [
        {
            "id": "doc1",
            "title": "Document de test",
            "content": "Contenu du document de test",
            "author": "Jean Dupont",
            "status": "draft",
            "version_metadata": {
                "version_number": 1,
                "version_label": "Version initiale",
                "version_notes": "Creation du document",
                "author": "Jean Dupont",
                "timestamp": "2024-05-10T10:30:00Z"
            }
        },
        {
            "id": "doc1",
            "title": "Document de test modifie",
            "content": "Contenu du document de test modifie",
            "author": "Jean Dupont",
            "status": "in-progress",
            "version_metadata": {
                "version_number": 2,
                "version_label": "Version 2",
                "version_notes": "Modification du document",
                "author": "Jean Dupont",
                "timestamp": "2024-05-15T10:30:00Z"
            }
        }
    ]
}
```

## Licence

Ce module est distribue sous licence MIT. Voir le fichier LICENSE pour plus d'informations.
