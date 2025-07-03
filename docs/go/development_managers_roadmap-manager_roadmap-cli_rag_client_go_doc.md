# Package rag

Package rag provides intelligent roadmap analysis using EMAIL_SENDER_1's RAG ecosystem
Integration with QDrant vector database for roadmap insights and recommendations


## Types

### MilestoneContext

MilestoneContext represents milestone context for RAG operations


### QDrantPoint

QDrantPoint represents a vector point for roadmap data


### RAGClient

RAGClient provides intelligent roadmap analysis using EMAIL_SENDER_1 RAG ecosystem


#### Methods

##### RAGClient.AnalyzeDependencies

AnalyzeDependencies uses RAG to identify potential dependencies between roadmap items


```go
func (r *RAGClient) AnalyzeDependencies(ctx context.Context, itemTitle, itemDescription string) ([]RoadmapInsight, error)
```

##### RAGClient.AnalyzeRoadmapSimilarities

AnalyzeRoadmapSimilarities identifies similar patterns across roadmap items


```go
func (r *RAGClient) AnalyzeRoadmapSimilarities(ctx context.Context, items []RoadmapItemContext) ([]RoadmapInsight, error)
```

##### RAGClient.DetectDependencies

DetectDependencies analyzes roadmap items to identify potential dependencies


```go
func (r *RAGClient) DetectDependencies(ctx context.Context, items []RoadmapItemContext) ([]RoadmapInsight, error)
```

##### RAGClient.GenerateRecommendations

GenerateRecommendations provides AI-powered recommendations for roadmap optimization


```go
func (r *RAGClient) GenerateRecommendations(ctx context.Context, roadmapContext string) ([]RoadmapInsight, error)
```

##### RAGClient.GetSimilarItems

GetSimilarItems finds roadmap items similar to the given query using vector search


```go
func (r *RAGClient) GetSimilarItems(ctx context.Context, query string, limit int) ([]RoadmapInsight, error)
```

##### RAGClient.HealthCheck

HealthCheck verifies connection to QDrant


```go
func (r *RAGClient) HealthCheck(ctx context.Context) error
```

##### RAGClient.IndexRoadmapItem

IndexRoadmapItem stores a roadmap item as a vector in QDrant for future analysis


```go
func (r *RAGClient) IndexRoadmapItem(ctx context.Context, itemID, title, description string, metadata map[string]interface{}) error
```

##### RAGClient.InitializeCollection

InitializeCollection creates the roadmap vector collection in QDrant


```go
func (r *RAGClient) InitializeCollection(ctx context.Context) error
```

### RoadmapInsight

RoadmapInsight represents AI-generated insights about roadmap items


### RoadmapItemContext

RoadmapItemContext represents roadmap item context for RAG operations


### SearchRequest

SearchRequest for QDrant similarity search


