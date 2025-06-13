# Guide de dépannage des dépendances Python pour le système RAG de roadmaps

## Introduction

Ce guide vous aidera à résoudre les problèmes courants liés aux dépendances Python utilisées par le système RAG de roadmaps, en particulier les problèmes de compatibilité entre les bibliothèques `sentence-transformers`, `huggingface-hub`, `transformers` et `torch`.

## Problèmes courants

### 1. Erreurs d'importation avec `sentence-transformers`

**Symptômes :**
```plaintext
ImportError: cannot import name 'modeling_utils' from 'transformers.modeling_utils'
```plaintext
ou
```plaintext
ImportError: cannot import name 'AutoModel' from 'transformers'
```plaintext
**Cause :**
Incompatibilité entre les versions de `sentence-transformers`, `huggingface-hub` et `transformers`.

**Solution :**
Installer des versions spécifiques et compatibles de ces bibliothèques :

```powershell
pip install huggingface-hub==0.19.4 transformers==4.36.2 torch==2.1.2 sentence-transformers==2.2.2
```plaintext
### 2. Erreurs avec `qdrant-client`

**Symptômes :**
```plaintext
ImportError: cannot import name 'models' from 'qdrant_client.http'
```plaintext
**Cause :**
Version incompatible ou obsolète de `qdrant-client`.

**Solution :**
Installer une version spécifique de `qdrant-client` :

```powershell
pip install qdrant-client==1.7.0
```plaintext
### 3. Erreurs de mémoire avec les modèles d'embedding

**Symptômes :**
```plaintext
RuntimeError: CUDA out of memory
```plaintext
ou
```plaintext
RuntimeError: [enforce fail at ..\c10\core\CPUAllocator.cpp:72] . DefaultCPUAllocator: not enough memory
```plaintext
**Cause :**
Les modèles d'embedding nécessitent beaucoup de mémoire, surtout lors de l'utilisation de GPU.

**Solution :**
- Utiliser un modèle plus petit (par exemple, `all-MiniLM-L6-v2` au lieu de `all-mpnet-base-v2`)
- Réduire la taille des lots (batch size)
- Forcer l'utilisation du CPU si la mémoire GPU est limitée :

```python
import os
os.environ["CUDA_VISIBLE_DEVICES"] = ""  # Désactiver CUDA

```plaintext
## Solution automatisée

Pour résoudre automatiquement les problèmes de compatibilité, exécutez le script d'installation avec l'option `-Force` :

```powershell
.\development\scripts\roadmap\rag\Install-Dependencies.ps1 -Force
```plaintext
Ce script installera des versions spécifiques et compatibles des bibliothèques nécessaires.

## Vérification de l'installation

Pour vérifier que les bibliothèques sont correctement installées et compatibles, exécutez :

```powershell
python -c "import sentence_transformers; import qdrant_client; print('Bibliothèques importées avec succès!')"
```plaintext
Si cette commande s'exécute sans erreur, l'installation est correcte.

## Versions compatibles recommandées

| Bibliothèque | Version |
|--------------|---------|
| huggingface-hub | 0.19.4 |
| transformers | 4.36.2 |
| torch | 2.1.2 |
| sentence-transformers | 2.2.2 |
| qdrant-client | 1.7.0 |

## Environnement virtuel (optionnel)

Si vous préférez isoler les dépendances du projet, vous pouvez utiliser un environnement virtuel Python :

### Création d'un environnement virtuel

```powershell
# Créer l'environnement virtuel

python -m venv venv

# Activer l'environnement virtuel

.\venv\Scripts\Activate.ps1

# Installer les dépendances

pip install huggingface-hub==0.19.4 transformers==4.36.2 torch==2.1.2 sentence-transformers==2.2.2 qdrant-client==1.7.0 matplotlib networkx pyvis
```plaintext
### Utilisation de l'environnement virtuel

Pour utiliser l'environnement virtuel, activez-le avant d'exécuter les scripts :

```powershell
# Activer l'environnement virtuel

.\venv\Scripts\Activate.ps1

# Exécuter les tests

cd development\scripts\roadmap\rag\tests
.\Invoke-AllTests.ps1 -TestType All -GenerateReport
```plaintext
Pour désactiver l'environnement virtuel :

```powershell
deactivate
```plaintext
## Problèmes spécifiques à Qdrant

### Connexion à Qdrant

Si vous rencontrez des problèmes de connexion à Qdrant, vérifiez que :

1. Qdrant est en cours d'exécution : `docker ps | findstr qdrant`
2. Qdrant est accessible : `Invoke-RestMethod -Uri "http://localhost:6333/collections" -Method Get`

### Démarrage de Qdrant

Si Qdrant n'est pas en cours d'exécution, démarrez-le avec :

```powershell
docker run -d --name qdrant -p 6333:6333 -p 6334:6334 -v qdrant_storage:/qdrant/storage qdrant/qdrant
```plaintext
ou utilisez le script fourni :

```powershell
.\development\scripts\roadmap\rag\Start-QdrantContainer.ps1 -Action Start
```plaintext
## Ressources supplémentaires

- [Documentation de sentence-transformers](https://www.sbert.net/)
- [Documentation de Qdrant](https://qdrant.tech/documentation/)
- [Documentation de Hugging Face Transformers](https://huggingface.co/docs/transformers/index)
- [Documentation de PyTorch](https://pytorch.org/docs/stable/index.html)
