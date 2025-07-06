# Package main

Search API endpoints and types


## Types

### Cluster

Cluster represents a vector cluster


### ClusterConfig

### DateRange

DateRange represents a date filter range


### Filter

Filter represents search filters


### Highlight

Highlight represents highlighted text in search results


### IndexRequest

IndexRequest represents an indexing request


### IndexResponse

IndexResponse represents the response to an indexing request


### IndexingServer

IndexingServer handles the web interface and API


#### Methods

##### IndexingServer.Start

Start starts the HTTP server


```go
func (s *IndexingServer) Start(addr string) error
```

### SearchRequest

SearchRequest represents a document search request


### SearchResponse

SearchResponse represents the search results


### SearchResult

SearchResult represents a single search result


### ValidationResponse

ValidationResponse represents the response to a validation request


### VectorStats

VectorStats represents vector space statistics


### VisualizationConfig

