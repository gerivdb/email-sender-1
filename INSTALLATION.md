# Guide d'Installation - EMAIL_SENDER_1

## ✅ Installation Terminée avec Succès !

Le dépôt **EMAIL_SENDER_1** a été installé et configuré avec succès sur votre système Windows.

## 📋 Prérequis

- **Go 1.21+** ✅ (Version détectée: 1.21.5)
- **Node.js** ✅ (pour les dépendances TypeScript)
- **Git** ✅
- **PowerShell** ✅

## 🚀 Démarrage Rapide

### 1. Lancer l'application

```powershell
# Démarrage simple
.\start.ps1

# Ou directement l'exécutable
.\email-sender.exe
```

### 2. Vérifier le fonctionnement

Ouvrez votre navigateur et accédez à :

- **Application principale** : http://localhost:8080
- **Contrôle de santé** : http://localhost:8080/health

## 📊 Structure du Projet

```
EMAIL_SENDER_1/
├── 📄 main.go                 # Application principale Go
├── 📄 config.yaml            # Configuration de base
├── 📄 go.mod                 # Dépendances Go
├── 📄 package.json           # Dépendances Node.js
├── 📄 start.ps1              # Script de démarrage
├── 📄 email-sender.exe       # Application compilée
├── 📁 src/                   # Code source principal
├── 📁 pkg/                   # Packages réutilisables
├── 📁 development/           # Outils de développement
├── 📁 projet/                # Documentation et spécifications
└── 📁 tools/                 # Outils et utilitaires
```

## 🔧 Configuration

Le fichier `config.yaml` contient la configuration de base :

```yaml
app:
  name: "Email Sender Application"
  version: "1.0.0"
  env: "development"

server:
  host: "localhost"
  port: 8080
```

## 💻 Développement

### Compilation manuelle

```powershell
# Définir la toolchain locale
$env:GOTOOLCHAIN='local'

# Compiler l'application
go build -o email-sender.exe main.go
```

### Installation des dépendances

```powershell
# Dépendances Go
go mod tidy
go mod download

# Dépendances Node.js
npm install
```

## 🛠️ Fonctionnalités Disponibles

### ✅ Modules Actifs

- **API REST** avec Gin Framework
- **Configuration YAML**
- **Endpoints de santé**
- **Logging basique**

### ⚠️ Modules Désactivés (pour l'installation)

- **MCP Gateway** (nécessite Go 1.24+)
- **Outils de vectorisation** (dépendances complexes)
- **Gestionnaires avancés** (modules externes)

## 🎯 Prochaines Étapes

1. **Explorer le code source** dans `src/` et `pkg/`
2. **Lire la documentation** complète dans `projet/documentation/`
3. **Consulter les guides** dans `development/docs/`
4. **Activer les modules avancés** selon vos besoins

## 📚 Documentation Complète

- [README principal](README.md) - Vue d'ensemble du projet
- [Guide développeur](projet/guides/developer/) - Documentation technique
- [Architecture](projet/architecture/) - Structure du système
- [Outils](development/docs/) - Documentation des outils

## 🎉 Félicitations !

Votre installation d'**EMAIL_SENDER_1** est maintenant opérationnelle !

L'application fonctionne et vous pouvez commencer à explorer les fonctionnalités disponibles.

---

**Note** : Ce projet est un système complexe avec de nombreux composants. L'installation de base vous donne accès aux fonctionnalités essentielles. Les modules avancés peuvent être activés progressivement selon vos besoins.
