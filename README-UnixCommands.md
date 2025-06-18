# Enable Unix Commands for PowerShell

Ce script permet d'utiliser les commandes Unix (bash) directement dans PowerShell Windows.

## 🚀 Installation Rapide

```powershell
# Installation automatique
.\Install-UnixCommands.ps1

# Activation manuelle (session courante uniquement)
. .\Enable-UnixCommands.ps1
```

## 📋 Commandes Disponibles

| Commande Unix | Description | Exemple |
|---------------|-------------|---------|
| `grep` | Rechercher du texte | `grep "pattern" file.txt` |
| `find` | Trouver des fichiers | `find . -name "*.go"` |
| `cat` | Afficher le contenu | `cat file.txt` |
| `head` | Premières lignes | `head -n 5 file.txt` |
| `tail` | Dernières lignes | `tail -n 5 file.txt` |
| `wc` | Compter lignes/mots | `wc -l file.txt` |
| `sort` | Trier les lignes | `sort file.txt` |
| `awk` | Traitement de texte | `awk '{print $1}' file.txt` |
| `sed` | Édition de flux | `sed 's/old/new/g' file.txt` |

## 💡 Aide Rapide

```powershell
# Afficher l'aide des commandes Unix
uh
# ou
unix-help
```

## 🔧 Alternatives PowerShell Natives

| Unix | PowerShell |
|------|------------|
| `grep "pattern" file.txt` | `Get-Content file.txt \| Select-String "pattern"` |
| `find . -name "*.go"` | `Get-ChildItem -Recurse -Filter "*.go"` |
| `wc -l file.txt` | `(Get-Content file.txt).Count` |
| `head -n 5 file.txt` | `Get-Content file.txt \| Select-Object -First 5` |

## ⚙️ Configuration

### Installation Automatique

Le script s'ajoute automatiquement au profil PowerShell (`$PROFILE`) pour être chargé à chaque session.

### Désinstallation

```powershell
.\Install-UnixCommands.ps1 -Remove
```

### Vérification

```powershell
grep --version    # Doit afficher la version de GNU grep
```

## 🛠️ Dépannage

### Erreur "Git Bash non trouvé"

- Installer Git for Windows : <https://git-scm.com/download/win>
- Vérifier que Git est dans le PATH

### Commandes ne fonctionnent pas

- Recharger le profil : `. $PROFILE`
- Ou redémarrer PowerShell

### Chemins Windows

Le script convertit automatiquement les chemins Windows (`C:\path`) en chemins Unix (`/c/path`) pour Git Bash.

## 📁 Fichiers

- `Enable-UnixCommands.ps1` - Script principal
- `Install-UnixCommands.ps1` - Installation automatique
- `README-UnixCommands.md` - Cette documentation

## 🔗 Liens

- [Git for Windows](https://git-scm.com/download/win)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [GNU Grep Manual](https://www.gnu.org/software/grep/manual/grep.html)
