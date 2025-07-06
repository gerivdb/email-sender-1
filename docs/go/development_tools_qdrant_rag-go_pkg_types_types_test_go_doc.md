# Package types

## Types

### Collection

Collection represents a QDrant collection


#### Methods

##### Collection.FromJSON

FromJSON deserializes the collection from JSON


```go
func (c *Collection) FromJSON(data []byte) error
```

##### Collection.GetAge

GetAge returns the age of the collection


```go
func (c *Collection) GetAge() time.Duration
```

##### Collection.GetLastUpdateAge

GetLastUpdateAge returns the time since last update


```go
func (c *Collection) GetLastUpdateAge() time.Duration
```

##### Collection.IncrementDocumentCount

IncrementDocumentCount increments the document count by the given amount


```go
func (c *Collection) IncrementDocumentCount(increment int)
```

##### Collection.IsEmpty

IsEmpty checks if the collection is empty


```go
func (c *Collection) IsEmpty() bool
```

##### Collection.SetIndexingConfig

SetIndexingConfig sets the indexing configuration


```go
func (c *Collection) SetIndexingConfig(config *IndexingConfig)
```

##### Collection.SetOptimizationConfig

SetOptimizationConfig sets the optimization configuration


```go
func (c *Collection) SetOptimizationConfig(config *OptimizationConfig)
```

##### Collection.ToConfig

ToConfig creates a collection config from this collection


```go
func (c *Collection) ToConfig() CollectionConfig
```

##### Collection.ToJSON

ToJSON serializes the collection to JSON


```go
func (c *Collection) ToJSON() ([]byte, error)
```

##### Collection.Update

Update updates the collection with new data


```go
func (c *Collection) Update(other *Collection)
```

##### Collection.UpdateDocumentCount

UpdateDocumentCount updates the document count


```go
func (c *Collection) UpdateDocumentCount(count int)
```

##### Collection.Validate

Validate checks if the collection is valid


```go
func (c *Collection) Validate() error
```

### CollectionConfig

CollectionConfig represents configuration for creating a collection


### CollectionManager

CollectionManager handles operations on collections


#### Methods

##### CollectionManager.CollectionExists

CollectionExists checks if a collection exists


```go
func (cm *CollectionManager) CollectionExists(name string) bool
```

##### CollectionManager.CreateCollection

CreateCollection creates a new collection with the given configuration


```go
func (cm *CollectionManager) CreateCollection(config CollectionConfig) (*Collection, error)
```

##### CollectionManager.CreateOrUpdateCollection

CreateOrUpdateCollection creates a new collection or updates an existing one


```go
func (cm *CollectionManager) CreateOrUpdateCollection(config CollectionConfig) (*Collection, error)
```

##### CollectionManager.DeleteCollection

DeleteCollection deletes a collection with the given name


```go
func (cm *CollectionManager) DeleteCollection(name string) error
```

##### CollectionManager.FromJSON

FromJSON deserializes the collection manager from JSON


```go
func (cm *CollectionManager) FromJSON(data []byte) error
```

##### CollectionManager.GetCollection

GetCollection gets a collection with the given name


```go
func (cm *CollectionManager) GetCollection(name string) (*Collection, error)
```

##### CollectionManager.GetCollectionCount

GetCollectionCount returns the number of collections


```go
func (cm *CollectionManager) GetCollectionCount() int
```

##### CollectionManager.IncrementDocumentCount

IncrementDocumentCount increments the document count for a collection


```go
func (cm *CollectionManager) IncrementDocumentCount(name string, increment int) error
```

##### CollectionManager.ListCollections

ListCollections lists all collections


```go
func (cm *CollectionManager) ListCollections() []*Collection
```

##### CollectionManager.ToJSON

ToJSON serializes the collection manager to JSON


```go
func (cm *CollectionManager) ToJSON() ([]byte, error)
```

##### CollectionManager.UpdateCollection

UpdateCollection updates a collection with new data


```go
func (cm *CollectionManager) UpdateCollection(name string, updated *Collection) error
```

##### CollectionManager.UpdateDocumentCount

UpdateDocumentCount updates the document count for a collection


```go
func (cm *CollectionManager) UpdateDocumentCount(name string, count int) error
```

### IndexingConfig

IndexingConfig contains parameters for indexing


### OptimizationConfig

OptimizationConfig contains optimization parameters


### QdrantDocument

Document represents a document in the RAG system


#### Methods

##### QdrantDocument.FromJSON

FromJSON deserializes the document from JSON


```go
func (d *QdrantDocument) FromJSON(data []byte) error
```

##### QdrantDocument.GetCreatedAt

GetCreatedAt gets the creation timestamp


```go
func (d *QdrantDocument) GetCreatedAt() *time.Time
```

##### QdrantDocument.GetFileType

GetFileType gets the file type metadata


```go
func (d *QdrantDocument) GetFileType() string
```

##### QdrantDocument.GetMetadata

GetMetadata gets a metadata field


```go
func (d *QdrantDocument) GetMetadata(key string) (interface{}, bool)
```

##### QdrantDocument.GetModifiedAt

GetModifiedAt gets the modification timestamp


```go
func (d *QdrantDocument) GetModifiedAt() *time.Time
```

##### QdrantDocument.GetOriginalSize

GetOriginalSize gets the original document size


```go
func (d *QdrantDocument) GetOriginalSize() int64
```

##### QdrantDocument.GetSource

GetSource gets the source metadata


```go
func (d *QdrantDocument) GetSource() string
```

##### QdrantDocument.GetVectorDimension

GetVectorDimension returns the dimension of the vector


```go
func (d *QdrantDocument) GetVectorDimension() int
```

##### QdrantDocument.SetCreatedAt

SetCreatedAt sets the creation timestamp


```go
func (d *QdrantDocument) SetCreatedAt(t time.Time)
```

##### QdrantDocument.SetFileType

SetFileType sets the file type metadata


```go
func (d *QdrantDocument) SetFileType(fileType string)
```

##### QdrantDocument.SetMetadata

SetMetadata sets a metadata field


```go
func (d *QdrantDocument) SetMetadata(key string, value interface{})
```

##### QdrantDocument.SetModifiedAt

SetModifiedAt sets the modification timestamp


```go
func (d *QdrantDocument) SetModifiedAt(t time.Time)
```

##### QdrantDocument.SetOriginalSize

SetOriginalSize sets the original document size


```go
func (d *QdrantDocument) SetOriginalSize(size int64)
```

##### QdrantDocument.SetSource

SetSource sets the source metadata


```go
func (d *QdrantDocument) SetSource(source string)
```

##### QdrantDocument.SetVector

SetVector sets the embedding vector


```go
func (d *QdrantDocument) SetVector(vector []float32)
```

##### QdrantDocument.ToJSON

ToJSON serializes the document to JSON


```go
func (d *QdrantDocument) ToJSON() ([]byte, error)
```

##### QdrantDocument.Validate

Validate checks if the document is valid


```go
func (d *QdrantDocument) Validate() error
```

##### QdrantDocument.ValidateVectorDimension

ValidateVectorDimension checks if the vector has the expected dimension


```go
func (d *QdrantDocument) ValidateVectorDimension(expectedDim int) error
```

### SearchResult

SearchResult represents a search result from the RAG system


#### Methods

##### SearchResult.ConvertDistanceToScore

ConvertDistanceToScore converts distance to score based on distance metric


```go
func (sr *SearchResult) ConvertDistanceToScore(metric string)
```

##### SearchResult.FromJSON

FromJSON deserializes the search result from JSON


```go
func (sr *SearchResult) FromJSON(data []byte) error
```

##### SearchResult.GenerateSnippet

GenerateSnippet generates a snippet highlighting the query terms


```go
func (sr *SearchResult) GenerateSnippet(query string, maxLength int) string
```

##### SearchResult.GenerateSnippetWithHighlight

GenerateSnippetWithHighlight generates a snippet with HTML highlighting


```go
func (sr *SearchResult) GenerateSnippetWithHighlight(query string, maxLength int) string
```

##### SearchResult.GetCollectionName

GetCollectionName gets the collection name where the document was found


```go
func (sr *SearchResult) GetCollectionName() string
```

##### SearchResult.GetDistance

GetDistance gets the distance value


```go
func (sr *SearchResult) GetDistance() (float64, bool)
```

##### SearchResult.GetSearchMetadata

GetSearchMetadata gets a search metadata field


```go
func (sr *SearchResult) GetSearchMetadata(key string) (interface{}, bool)
```

##### SearchResult.GetSearchQuery

GetSearchQuery gets the original search query


```go
func (sr *SearchResult) GetSearchQuery() string
```

##### SearchResult.GetSearchTime

GetSearchTime gets the search execution time


```go
func (sr *SearchResult) GetSearchTime() time.Duration
```

##### SearchResult.IsRelevant

IsRelevant checks if the result is relevant based on a threshold score


```go
func (sr *SearchResult) IsRelevant(threshold float32) bool
```

##### SearchResult.SetCollectionName

SetCollectionName sets the collection name where the document was found


```go
func (sr *SearchResult) SetCollectionName(collectionName string)
```

##### SearchResult.SetDistance

SetDistance sets the distance value


```go
func (sr *SearchResult) SetDistance(distance float64)
```

##### SearchResult.SetSearchMetadata

SetSearchMetadata sets a search metadata field


```go
func (sr *SearchResult) SetSearchMetadata(key string, value interface{})
```

##### SearchResult.SetSearchQuery

SetSearchQuery sets the original search query


```go
func (sr *SearchResult) SetSearchQuery(query string)
```

##### SearchResult.SetSearchTime

SetSearchTime sets the search execution time


```go
func (sr *SearchResult) SetSearchTime(duration time.Duration)
```

##### SearchResult.ToJSON

ToJSON serializes the search result to JSON


```go
func (sr *SearchResult) ToJSON() ([]byte, error)
```

##### SearchResult.Validate

Validate checks if the search result is valid


```go
func (sr *SearchResult) Validate() error
```

### SearchResults

SearchResults represents a collection of search results


#### Methods

##### SearchResults.AddResult

AddResult adds a search result to the collection


```go
func (sr *SearchResults) AddResult(result *SearchResult) error
```

##### SearchResults.FilterByFileType

FilterByFileType filters results by document file type


```go
func (sr *SearchResults) FilterByFileType(fileType string) *SearchResults
```

##### SearchResults.FilterByScore

FilterByScore filters results by minimum score


```go
func (sr *SearchResults) FilterByScore(minScore float64) *SearchResults
```

##### SearchResults.FilterBySource

FilterBySource filters results by document source


```go
func (sr *SearchResults) FilterBySource(source string) *SearchResults
```

##### SearchResults.FromJSON

FromJSON deserializes the search results from JSON


```go
func (sr *SearchResults) FromJSON(data []byte) error
```

##### SearchResults.GetResultCount

GetResultCount returns the number of results


```go
func (sr *SearchResults) GetResultCount() int
```

##### SearchResults.GetResults

GetResults returns all search results


```go
func (sr *SearchResults) GetResults() []*SearchResult
```

##### SearchResults.GetTopResults

GetTopResults returns the top N results


```go
func (sr *SearchResults) GetTopResults(n int) []*SearchResult
```

##### SearchResults.SortByScore

SortByScore sorts results by score in descending order


```go
func (sr *SearchResults) SortByScore()
```

##### SearchResults.ToJSON

ToJSON serializes the search results to JSON


```go
func (sr *SearchResults) ToJSON() ([]byte, error)
```

##### SearchResults.Validate

Validate checks if the search results are valid


```go
func (sr *SearchResults) Validate() error
```

## Functions

### ValidateCollectionConfig

ValidateCollectionConfig validates the collection configuration


```go
func ValidateCollectionConfig(config CollectionConfig) error
```

## Constants

### DistanceCosine, DistanceEuclidean, DistanceDot

Supported distance metrics


```go
const (
	DistanceCosine		= "cosine"
	DistanceEuclidean	= "euclidean"
	DistanceDot		= "dot"
)
```

### MaxContentSize

MaxContentSize defines the maximum size for document content (100KB)


```go
const MaxContentSize = 100 * 1024
```

