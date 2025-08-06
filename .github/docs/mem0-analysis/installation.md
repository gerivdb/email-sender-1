# Guide d’installation — mem0-analysis

Ce guide décrit l’installation complète de **mem0-analysis** pour tous les usages (standard, vector_stores, LLMs, développement, test).

---

## Prérequis

- **Python** : version >=3.9, <4.0
- **pip** : version récente recommandée
- Systèmes supportés : Linux, macOS, Windows (WSL conseillé sous Windows)
- Accès internet pour installation des dépendances
- (Optionnel) Accès aux credentials API (OpenAI, Qdrant, Pinecone, etc.)

---

## Étapes d’installation

### 1. Clonage du dépôt

```bash
git clone --recurse-submodules <url-du-repo-principal>
cd <repo-principal>/mem0-analysis/repo
```

> **Astuce** : Utilisez `--recurse-submodules` pour initialiser les sous-modules.

### 2. Création d’un environnement virtuel (recommandé)

```bash
python -m venv .venv
source .venv/bin/activate  # Linux/macOS
# ou
.venv\Scripts\activate     # Windows
```

### 3. Installation standard

```bash
pip install .
```

### 4. Installation avec extras (vector_stores, llms…)

```bash
pip install .[vector_stores,llms]
```

> Voir la liste complète des extras dans [`requirements.md`](requirements.md).

### 5. Installation pour développement et tests

```bash
pip install .[dev,test]
```

---

## Configuration initiale

- Copier le fichier `.env.example` en `.env` et renseigner les variables nécessaires (API keys, endpoints…).
- Exemple de variables à configurer :
  - `OPENAI_API_KEY`
  - `QDRANT_URL`
  - `PINECONE_API_KEY`
  - etc.

> Pour plus de détails, voir la documentation des connecteurs concernés.

---

## Vérification de l’installation

- Tester l’import Python :

```python
python -c "import mem0"
```

- Lancer les tests unitaires :

```bash
pytest
```

---

## Liens utiles

- [README mem0-analysis](README.md)
- [Liste des requirements](requirements.md)
- [Guide d’intégration GitHub](github-guide.md) *(à venir)*

---

## FAQ

- **Problème d’installation d’une dépendance ?**  
  Vérifiez la version de Python et de pip, consultez les issues du projet ou forcez la mise à jour de pip :  
  `pip install --upgrade pip`

- **Erreur de credentials ?**  
  Vérifiez le fichier `.env` et la documentation du connecteur utilisé.
