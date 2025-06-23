# QDrant Vectorizer - Procédure de configuration et validation

# QDrant Integration – Documentation Technique

## 1. Analyse de la documentation QDrant

---

## 2. Indexation vectorielle (IndexDocument)

### 2.1 Décomposition du processus d’indexation

1. **Prétraitement et normalisation du document**
   - Nettoyage du texte (suppression des caractères spéciaux, lowercasing, etc.)
   - Découpage en tokens ou phrases si nécessaire
   - Gestion des métadonnées

2. **Conversion du document en vecteur**
   - Utilisation du vectorizer (embedding model)
   - Vérification de la dimension du vecteur
   - Gestion des erreurs de conversion

3. **Construction du payload QDrant**
   - Mapping des champs du document vers le payload (title, content, tags, etc.)
   - Ajout des métadonnées utiles à la recherche

4. **Indexation dans QDrant**
   - Appel à l’API `UpsertPoints` ou équivalent
   - Gestion des erreurs réseau ou API
   - Validation du retour (succès/échec)

5. **Tests d’indexation**
   - Jeu d’exemples variés (documents courts, longs, avec/​sans métadonnées)
   - Vérification de la présence dans l’index QDrant

### 2.2 Exemple de pipeline d’indexation (Go)

```go
func (qv *QDrantVectorizer) IndexDocument(ctx context.Context, doc *Document) error {
    // 1. Prétraitement
    cleanText := normalizeText(doc.Content)
    if cleanText == "" {
        return fmt.Errorf("empty content after normalization")
    }

    // 2. Conversion en vecteur
    vector, err := qv.vectorizer.GenerateEmbedding(cleanText)
    if err != nil {
        return fmt.Errorf("embedding error: %w", err)
    }
    if len(vector) != qv.vectorSize {
        return fmt.Errorf("invalid vector size: got %d, want %d", len(vector), qv.vectorSize)
    }

    // 3. Construction du payload
    payload := map[string]interface{}{
        "title":   doc.Title,
        "content": cleanText,
        "tags":    doc.Tags,
        // autres champs utiles
    }

    // 4. Indexation dans QDrant
    err = qv.client.UpsertPoints(ctx, qv.collection, []QDrantVector{{
        ID:      doc.ID,
        Vector:  vector,
        Payload: payload,
    }})
    if err != nil {
        return fmt.Errorf("qdrant upsert error: %w", err)
    }

    return nil
}
```

### 2.3 Normalisation et prétraitement

```go
func normalizeText(text string) string {
    text = strings.ToLower(text)
    text = strings.TrimSpace(text)
    // Suppression caractères spéciaux, etc.
    text = regexp.MustCompile(`[^\w\s]`).ReplaceAllString(text, "")
    return text
}
```

### 2.4 Gestion des erreurs

- Retourner des erreurs explicites à chaque étape (prétraitement, embedding, upsert)
- Logger les erreurs pour audit
- Retenter l’indexation si erreur réseau/transitoire

### 2.5 Tests d’indexation

- Créer des tests unitaires avec des documents variés
- Vérifier la robustesse face aux entrées vides, corrompues, ou très volumineuses
- Mock QDrant pour les tests unitaires

---

## 3. Recherche sémantique (SemanticSearch)

### 3.1 Définition des critères de recherche sémantique

- **Similarité vectorielle** : score de similarité (cosine, dot, euclidean selon config QDrant)
- **Filtres** : métadonnées (tags, manager_type, date, etc.)
- **Limite de résultats** : pagination, top-N
- **Payload enrichi** : retour des champs utiles pour l’application cible

### 3.2 Pipeline de recherche sémantique (Go)

1. **Prétraitement de la requête**
   - Nettoyage et normalisation du texte de la requête
   - Extraction éventuelle de filtres avancés

2. **Vectorisation de la requête**
   - Utilisation du même vectorizer que pour l’indexation
   - Vérification de la dimension du vecteur

3. **Construction de la requête QDrant**
   - Création d’un `SearchRequest` avec :
     - `vector` : vecteur de la requête
     - `filter` : filtres éventuels (tags, manager_type, etc.)
     - `limit` : nombre de résultats
     - `with_payload` : true pour retour enrichi

4. **Appel à l’API QDrant**
   - Utilisation de `SearchPoints` (Go SDK ou REST)
   - Gestion des erreurs réseau/API

5. **Traitement des résultats**
   - Parsing des résultats : score, payload, id
   - Formatage pour l’application cible (struct locale)
   - Tri éventuel, enrichissement, logs

6. **Logs et métriques**
   - Logging des requêtes, temps de réponse, nombre de résultats
   - Export métriques pour monitoring

### 3.3 Exemple de code Go : recherche sémantique

```go
func (qv *QDrantVectorizer) SemanticSearch(ctx context.Context, query string, filters map[string]interface{}, limit int) ([]QDrantSearchResult, error) {
    // 1. Prétraitement
    cleanQuery := normalizeText(query)
    if cleanQuery == "" {
        return nil, fmt.Errorf("empty query after normalization")
    }

    // 2. Vectorisation
    vector, err := qv.vectorizer.GenerateEmbedding(cleanQuery)
    if err != nil {
        return nil, fmt.Errorf("embedding error: %w", err)
    }
    if len(vector) != qv.vectorSize {
        return nil, fmt.Errorf("invalid vector size: got %d, want %d", len(vector), qv.vectorSize)
    }

    // 3. Construction de la requête QDrant
    searchReq := QDrantSearchRequest{
        Vector:      vector,
        Filter:      buildQDrantFilter(filters),
        Limit:       limit,
        WithPayload: true,
    }

    // 4. Appel à QDrant
    results, err := qv.client.SearchPoints(ctx, qv.collection, searchReq)
    if err != nil {
        return nil, fmt.Errorf("qdrant search error: %w", err)
    }

    // 5. Traitement des résultats
    var searchResults []QDrantSearchResult
    for _, r := range results {
        searchResults = append(searchResults, QDrantSearchResult{
            ID:      r.ID,
            Score:   r.Score,
            Payload: r.Payload,
        })
    }

    // 6. Logs et métriques (exemple)
    qv.logger.Infof("SemanticSearch: query=%q, filters=%v, results=%d", cleanQuery, filters, len(searchResults))

    return searchResults, nil
}
```

#### Exemple de construction de filtre QDrant

```go
func buildQDrantFilter(filters map[string]interface{}) *Filter {
    // Construction dynamique selon les filtres fournis
    // Exemple : tags, manager_type, date_range, etc.
    // Retourne nil si aucun filtre
    return nil // À implémenter selon besoins
}
```

### 3.4 Logs et métriques

- Logger chaque requête (query, filtres, nb résultats, durée)
- Exporter métriques (temps de réponse, taux d’erreur, distribution scores)
- Intégration possible avec Prometheus, Grafana, etc.

### 3.5 Validation sur cas d’usage réels

- Tester la pertinence sur des requêtes variées (simples, complexes, bruitées)
- Vérifier la cohérence des scores et du ranking
- Ajuster les filtres et la normalisation selon les besoins métier

---

*Étape 2 de l’intégration QDrant documentée sur la branche consolidation-v65.*

## 4. Configuration et connexion QDrant

### 4.1 Paramètres de configuration nécessaires

- `host` : adresse du serveur QDrant (ex : "localhost")
- `port` : port d’écoute (ex : 6333)
- `api_key` : clé API d’authentification (optionnelle selon config)
- `collection` : nom de la collection QDrant à utiliser
- `vector_size` : dimension des vecteurs (doit correspondre au modèle d’embedding)
- `distance` : métrique de similarité ("Cosine", "Dot", "Euclidean")
- `timeout` : délai de connexion (ms ou s)
- (optionnel) `retries` : nombre de tentatives de reconnexion
- (optionnel) `tls` : activer TLS/SSL (booléen)
- (optionnel) `log_level` : niveau de log pour le client

**Exemple de fichier : `qdrant_config_example.json`**

```json
{
  "host": "localhost",
  "port": 6333,
  "api_key": "",
  "collection": "my_collection",
  "vector_size": 384,
  "distance": "Cosine",
  "timeout": 3000,
  "retries": 3,
  "tls": false,
  "log_level": "info"
}
```

### 4.2 Lecture sécurisée de la configuration

- Lecture prioritaire depuis un fichier JSON (`qdrant_config.json`)
- Surcharge possible par variables d’environnement :  
  - `QDRANT_HOST`, `QDRANT_PORT`, `QDRANT_API_KEY`, etc.
- Validation automatique des champs obligatoires (host, port, collection, vector_size, distance)
- Gestion des valeurs par défaut pour les champs optionnels

**Exemple de struct Go :**

```go
type QDrantConfig struct {
    Host        string `json:"host"`
    Port        int    `json:"port"`
    APIKey      string `json:"api_key"`
    Collection  string `json:"collection"`
    VectorSize  int    `json:"vector_size"`
    Distance    string `json:"distance"`
    Timeout     int    `json:"timeout"`
    Retries     int    `json:"retries"`
    TLS         bool   `json:"tls"`
    LogLevel    string `json:"log_level"`
}
```

### 4.3 Connexion et reconnexion automatique

- Initialisation du client QDrant à partir de la configuration
- Gestion des erreurs de connexion (timeout, refus, mauvais paramètres)
- Retry automatique configurable (`retries`)
- Support TLS si activé
- Logs détaillés lors de la connexion/déconnexion

### 4.4 Tests unitaires de la configuration

- Cas de configuration complète et minimale
- Cas d’erreur : champ manquant, mauvais type, port invalide, etc.
- Surcharge par variables d’environnement
- Simulation d’échec de connexion (mauvais host/port)
- Validation des valeurs par défaut

### 4.5 Documentation développeur

- Documenter le format du fichier de configuration et les variables d’environnement supportées
- Expliquer la priorité de lecture (env > fichier > défauts)
- Fournir un exemple d’utilisation dans le code Go

---

*Étape 3 de l’intégration QDrant documentée sur la branche consolidation-v65.*

## Validation

- Lancer les tests unitaires :

  ```sh
  go test ./pkg/docmanager/ -v -run QDrantVectorizer
  ```

- Vérifier que tous les tests passent (création, indexation, recherche, gestion d'erreur, configuration).

## Dépendances

- Go 1.21+
- Module `github.com/stretchr/testify` pour les assertions de test

## Bonnes pratiques

- Toujours mocker QDrant pour les tests unitaires.
