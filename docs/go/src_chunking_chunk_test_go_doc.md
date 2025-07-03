# Package chunking

## Types

### AdaptiveChunker

AdaptiveChunker sélectionne automatiquement la meilleure stratégie de chunking


#### Methods

##### AdaptiveChunker.Chunk

Chunk implémente l'interface ChunkingStrategy


```go
func (ac *AdaptiveChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error)
```

##### AdaptiveChunker.GetDescription

GetDescription retourne une description de la stratégie


```go
func (ac *AdaptiveChunker) GetDescription() string
```

##### AdaptiveChunker.GetName

GetName retourne le nom de la stratégie


```go
func (ac *AdaptiveChunker) GetName() string
```

### ChunkingOptions

ChunkingOptions contient les options de configuration pour le chunking


### ChunkingStrategy

ChunkingStrategy détermine comment les documents sont découpés


### ContentType

ContentType représente le type de contenu détecté


### DocumentChunk

DocumentChunk représente un morceau d'un document source


### FixedSizeChunker

FixedSizeChunker implémente un chunking basé sur une taille fixe


#### Methods

##### FixedSizeChunker.Chunk

Chunk implémente l'interface ChunkingStrategy


```go
func (fs *FixedSizeChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error)
```

##### FixedSizeChunker.GetDescription

GetDescription retourne une description de la stratégie


```go
func (fs *FixedSizeChunker) GetDescription() string
```

##### FixedSizeChunker.GetName

GetName retourne le nom de la stratégie


```go
func (fs *FixedSizeChunker) GetName() string
```

### SemanticChunker

SemanticChunker implémente un chunking basé sur la structure sémantique du texte


#### Methods

##### SemanticChunker.Chunk

Chunk implémente l'interface ChunkingStrategy


```go
func (sc *SemanticChunker) Chunk(text string, options ChunkingOptions) ([]*DocumentChunk, error)
```

##### SemanticChunker.GetDescription

GetDescription retourne une description de la stratégie


```go
func (sc *SemanticChunker) GetDescription() string
```

##### SemanticChunker.GetName

GetName retourne le nom de la stratégie


```go
func (sc *SemanticChunker) GetName() string
```

