# Package mocks

Package mocks provides advanced mock implementations for RAG components
Time-Saving Method 2: Mock-First Strategy
ROI: +24h immediate + 18h/month (eliminates external dependencies during development)


## Types

### Contact

### Email

### MockConfig

MockConfig controls mock behavior and performance simulation


### MockEmailService

MockEmailService simule les workflows n8n pour Email Sender 1
ROI: +10h développement parallèle sans attendre n8n


#### Methods

##### MockEmailService.GetDeliveryStatus

```go
func (m *MockEmailService) GetDeliveryStatus(contactID string) string
```

##### MockEmailService.GetLastEmail

```go
func (m *MockEmailService) GetLastEmail() *Email
```

##### MockEmailService.GetSentCount

Test helpers


```go
func (m *MockEmailService) GetSentCount() int
```

##### MockEmailService.Reset

```go
func (m *MockEmailService) Reset()
```

##### MockEmailService.SendEmail

```go
func (m *MockEmailService) SendEmail(email Email) error
```

### MockNotionAPI

MockNotionAPI simule l'API Notion pour LOT1 (contacts/venues)
ROI: +8h développement sans quotas API


#### Methods

##### MockNotionAPI.GetContacts

```go
func (m *MockNotionAPI) GetContacts(filter string) ([]Contact, error)
```

##### MockNotionAPI.GetVenues

```go
func (m *MockNotionAPI) GetVenues() ([]Venue, error)
```

##### MockNotionAPI.UpdateContactStatus

```go
func (m *MockNotionAPI) UpdateContactStatus(contactID, status string) error
```

### MockQDrantClient

MockQDrantClient provides sophisticated QDrant simulation


#### Methods

##### MockQDrantClient.CreateCollection

CreateCollection simulates QDrant collection creation


```go
func (m *MockQDrantClient) CreateCollection(ctx context.Context, name string, config map[string]interface{}) error
```

##### MockQDrantClient.GetCollectionStats

GetCollectionStats returns statistics for a specific collection


```go
func (m *MockQDrantClient) GetCollectionStats(collection string) map[string]interface{}
```

##### MockQDrantClient.GetConfig

GetConfig returns current mock configuration


```go
func (m *MockQDrantClient) GetConfig() *MockConfig
```

##### MockQDrantClient.GetStats

GetStats returns current mock statistics


```go
func (m *MockQDrantClient) GetStats() *MockStats
```

##### MockQDrantClient.ResetStats

ResetStats resets all performance statistics


```go
func (m *MockQDrantClient) ResetStats()
```

##### MockQDrantClient.Search

Search simulates QDrant vector search with realistic behavior


```go
func (m *MockQDrantClient) Search(ctx context.Context, collection string, req *QDrantSearchRequest) (*QDrantSearchResponse, error)
```

##### MockQDrantClient.UpdateConfig

UpdateConfig updates mock behavior configuration


```go
func (m *MockQDrantClient) UpdateConfig(config *MockConfig)
```

##### MockQDrantClient.UpsertPoints

UpsertPoints simulates adding/updating vectors in QDrant


```go
func (m *MockQDrantClient) UpsertPoints(ctx context.Context, collection string, points []*QDrantPoint) error
```

### MockStats

MockStats tracks mock performance and usage


### QDrantPoint

QDrantPoint represents a vector point in QDrant


### QDrantSearchRequest

QDrantSearchRequest represents a search request to QDrant


### QDrantSearchResponse

QDrantSearchResponse represents QDrant search response


### Venue

