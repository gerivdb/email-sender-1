# Package providers

## Types

### MockEmbeddingProvider

MockEmbeddingProvider simule un fournisseur d'embeddings pour les tests


#### Methods

##### MockEmbeddingProvider.Embed

Embed génère un embedding simulé pour un texte donné


```go
func (p *MockEmbeddingProvider) Embed(text string) ([]float32, error)
```

##### MockEmbeddingProvider.EmbedBatch

EmbedBatch génère des embeddings simulés pour un batch de textes


```go
func (p *MockEmbeddingProvider) EmbedBatch(texts []string) ([][]float32, error)
```

##### MockEmbeddingProvider.GetBatchSize

GetBatchSize retourne la taille maximum des batchs supportée


```go
func (p *MockEmbeddingProvider) GetBatchSize() int
```

##### MockEmbeddingProvider.GetCacheContents

GetCacheContents retourne les clés actuellement dans le cache (pour les tests)


```go
func (p *MockEmbeddingProvider) GetCacheContents() []string
```

##### MockEmbeddingProvider.GetCacheSize

GetCacheSize retourne la taille actuelle du cache


```go
func (p *MockEmbeddingProvider) GetCacheSize() int64
```

##### MockEmbeddingProvider.GetDimensions

GetDimensions retourne le nombre de dimensions des embeddings


```go
func (p *MockEmbeddingProvider) GetDimensions() int
```

##### MockEmbeddingProvider.GetEmbeddings

GetEmbeddings génère des embeddings pour un batch de textes (interface EmbeddingProvider)


```go
func (p *MockEmbeddingProvider) GetEmbeddings(ctx context.Context, texts []string) ([][]float32, error)
```

##### MockEmbeddingProvider.GetStats

GetStats retourne le nombre total de requêtes, le nombre de cache hits et la latence moyenne


```go
func (p *MockEmbeddingProvider) GetStats() (int64, int64, time.Duration)
```

##### MockEmbeddingProvider.IsInCache

IsInCache vérifie si un texte est présent dans le cache (pour les tests)


```go
func (p *MockEmbeddingProvider) IsInCache(text string) bool
```

##### MockEmbeddingProvider.SetMaxCacheSize

SetMaxCacheSize met à jour la taille maximale du cache et évince si nécessaire


```go
func (p *MockEmbeddingProvider) SetMaxCacheSize(size int64)
```

### MockOption

MockOption permet de configurer le provider simulé


### Stats

Stats contient les statistiques d'utilisation du provider


## Functions

### MD5Hash

MD5Hash calcule le hash MD5 d'un texte donné et retourne le résultat sous forme de tableau de float32


```go
func MD5Hash(text string) []float32
```

