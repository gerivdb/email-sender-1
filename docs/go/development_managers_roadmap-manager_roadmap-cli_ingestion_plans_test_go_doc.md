# Package ingestion

Package ingestion provides functionality to ingest and process roadmap plans
from the EMAIL_SENDER_1 ecosystem consolidated plans directory


## Types

### AdvancedParserConfig

AdvancedParserConfig provides configuration for advanced parsing


### AdvancedPlanParser

AdvancedPlanParser handles sophisticated parsing of technical roadmap plans


#### Methods

##### AdvancedPlanParser.ParseAdvancedRoadmap

ParseAdvancedRoadmap parses a markdown file into an advanced roadmap structure


```go
func (p *AdvancedPlanParser) ParseAdvancedRoadmap(content string, filename string) (*types.AdvancedRoadmap, error)
```

### EnrichedIngestionResult

EnrichedIngestionResult extends the basic result with enriched item counts


### EnrichedPlanItem

EnrichedPlanItem represents a parsed plan item with enriched metadata


#### Methods

##### EnrichedPlanItem.ToEnrichedItemOptions

ToEnrichedItemOptions converts an EnrichedPlanItem to types.EnrichedItemOptions for storage


```go
func (item *EnrichedPlanItem) ToEnrichedItemOptions() types.EnrichedItemOptions
```

### IngestionResult

IngestionResult contains statistics about the ingestion process


### PlanChunk

PlanChunk represents a processed chunk of a plan file


### PlanIngester

PlanIngester handles the ingestion of consolidated roadmap plans


#### Methods

##### PlanIngester.GetIngestionSummary

GetIngestionSummary returns a summary of the last ingestion


```go
func (p *PlanIngester) GetIngestionSummary() map[string]interface{}
```

##### PlanIngester.IngestAllPlans

IngestAllPlans processes all markdown files in the consolidated plans directory


```go
func (p *PlanIngester) IngestAllPlans(ctx context.Context) (*IngestionResult, error)
```

##### PlanIngester.IngestAndStoreEnrichedPlans

IngestAndStoreEnrichedPlans processes plan files and stores enriched items to storage


```go
func (p *PlanIngester) IngestAndStoreEnrichedPlans(storageImpl Storage, planFiles []string) ([]types.RoadmapItem, error)
```

##### PlanIngester.IngestEnrichedPlans

IngestEnrichedPlans processes markdown files and extracts enriched metadata


```go
func (p *PlanIngester) IngestEnrichedPlans(ctx context.Context) (*EnrichedIngestionResult, error)
```

##### PlanIngester.SearchChunks

SearchChunks finds chunks matching a query (simple text search)


```go
func (p *PlanIngester) SearchChunks(query string) []PlanChunk
```

### RAGClient

RAGClient interface for vector storage operations


### Storage

Storage interface for dependency injection


