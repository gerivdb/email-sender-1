# Package roadmapconnector

filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\planning-ecosystem-sync\tools\roadmap-connector\roadmap_manager_connector.go


## Types

### APIAnalysisResult

APIAnalysisResult contains the analysis results


### APIAnalyzer

APIAnalyzer analyzes existing Roadmap Manager API


#### Methods

##### APIAnalyzer.AnalyzeAPI

AnalyzeAPI performs comprehensive analysis of the Roadmap Manager API


```go
func (aa *APIAnalyzer) AnalyzeAPI(ctx context.Context) (*APIAnalysisResult, error)
```

### APIEndpoint

APIEndpoint represents an analyzed API endpoint


### APIParameter

APIParameter represents an API parameter


### APIResponse

APIResponse represents an API response


### AuthType

AuthType represents different authentication types


### AuthenticationManager

AuthenticationManager handles authentication with the Roadmap Manager


#### Methods

##### AuthenticationManager.AddAuthHeaders

AddAuthHeaders adds authentication headers to HTTP request


```go
func (am *AuthenticationManager) AddAuthHeaders(req *http.Request) error
```

##### AuthenticationManager.Initialize

Initialize sets up authentication


```go
func (am *AuthenticationManager) Initialize(ctx context.Context) error
```

##### AuthenticationManager.SanitizeCredentials

SanitizeCredentials removes sensitive data from credentials for logging


```go
func (am *AuthenticationManager) SanitizeCredentials(creds *Credentials) map[string]interface{}
```

### ConflictInfo

ConflictInfo represents conflict information


### ConnectorConfig

ConnectorConfig holds configuration for Roadmap Manager connection


### ConnectorStats

ConnectorStats tracks connector performance metrics


### Credentials

Credentials stores authentication credentials


### DataMapper

DataMapper handles conversion between different data formats


#### Methods

##### DataMapper.ConvertFromRoadmapFormat

ConvertFromRoadmapFormat converts roadmap manager format to dynamic plan


```go
func (dm *DataMapper) ConvertFromRoadmapFormat(roadmapPlan *RoadmapPlan) (*DynamicPlan, error)
```

##### DataMapper.ConvertToRoadmapFormat

ConvertToRoadmapFormat converts dynamic plan to roadmap manager format


```go
func (dm *DataMapper) ConvertToRoadmapFormat(dynamicPlan interface{}) (*RoadmapPlan, error)
```

##### DataMapper.MapWithCustomConfig

MapWithCustomConfig applies custom mapping configuration


```go
func (dm *DataMapper) MapWithCustomConfig(source interface{}, config *MappingConfig) (*MappingResult, error)
```

##### DataMapper.RegisterTransformer

RegisterTransformer registers a custom data transformer


```go
func (dm *DataMapper) RegisterTransformer(transformer DataTransformer)
```

### DataTransformer

DataTransformer interface for custom data transformations


### DateTransformer

#### Methods

##### DateTransformer.GetName

```go
func (dt *DateTransformer) GetName() string
```

##### DateTransformer.Transform

```go
func (dt *DateTransformer) Transform(input interface{}) (interface{}, error)
```

### DefaultLogger

DefaultLogger provides a basic logger implementation


#### Methods

##### DefaultLogger.Debug

```go
func (dl *DefaultLogger) Debug(msg string)
```

##### DefaultLogger.Error

```go
func (dl *DefaultLogger) Error(msg string)
```

##### DefaultLogger.Info

```go
func (dl *DefaultLogger) Info(msg string)
```

##### DefaultLogger.Printf

```go
func (dl *DefaultLogger) Printf(format string, args ...interface{})
```

### DynamicPhase

DynamicPhase represents a phase in the dynamic format


### DynamicPlan

DynamicPlan represents the internal dynamic plan format


### DynamicTask

DynamicTask represents a task in the dynamic format


### FieldMapping

FieldMapping defines how to map a specific field


### Logger

Logger interface for API analyzer


### MappingConfig

MappingConfig defines how to map between data structures


### MappingResult

MappingResult contains the result of a mapping operation


### OAuth2Config

OAuth2Config contains OAuth2 configuration


### ProgressTransformer

#### Methods

##### ProgressTransformer.GetName

```go
func (pt *ProgressTransformer) GetName() string
```

##### ProgressTransformer.Transform

```go
func (pt *ProgressTransformer) Transform(input interface{}) (interface{}, error)
```

### RateLimitInfo

RateLimitInfo represents rate limiting information


### RoadmapConnector

RoadmapConnector provides connectivity to roadmap systems


#### Methods

##### RoadmapConnector.Connect

Connect establishes connection with the roadmap system


```go
func (rc *RoadmapConnector) Connect() error
```

##### RoadmapConnector.Disconnect

Disconnect closes connection with the roadmap system


```go
func (rc *RoadmapConnector) Disconnect() error
```

##### RoadmapConnector.GetRoadmapItems

GetRoadmapItems retrieves roadmap items


```go
func (rc *RoadmapConnector) GetRoadmapItems() ([]interface{}, error)
```

### RoadmapManagerConnector

RoadmapManagerConnector provides interface with existing Roadmap Manager


#### Methods

##### RoadmapManagerConnector.Close

Close cleanly shuts down the connector


```go
func (rmc *RoadmapManagerConnector) Close() error
```

##### RoadmapManagerConnector.GetStats

GetStats returns current connector statistics


```go
func (rmc *RoadmapManagerConnector) GetStats() *ConnectorStats
```

##### RoadmapManagerConnector.Initialize

Initialize sets up the connector and validates connectivity


```go
func (rmc *RoadmapManagerConnector) Initialize(ctx context.Context) error
```

##### RoadmapManagerConnector.SyncFromRoadmapManager

SyncFromRoadmapManager fetches updates from the Roadmap Manager


```go
func (rmc *RoadmapManagerConnector) SyncFromRoadmapManager(ctx context.Context, planID string) (*RoadmapPlan, error)
```

##### RoadmapManagerConnector.SyncPlanToRoadmapManager

SyncPlanToRoadmapManager synchronizes a plan to the Roadmap Manager


```go
func (rmc *RoadmapManagerConnector) SyncPlanToRoadmapManager(ctx context.Context, dynamicPlan interface{}) (*SyncResponse, error)
```

### RoadmapPhase

RoadmapPhase represents a phase in the roadmap


### RoadmapPlan

RoadmapPlan represents a plan in the Roadmap Manager format


### RoadmapTask

RoadmapTask represents a task in the roadmap


### SecurityConfig

SecurityConfig defines security requirements


### SecurityInfo

SecurityInfo represents security configuration


### SecurityValidator

SecurityValidator validates security configurations


#### Methods

##### SecurityValidator.ValidateRequest

ValidateRequest validates a request for security compliance


```go
func (sv *SecurityValidator) ValidateRequest(req *http.Request) error
```

### StatusTransformer

#### Methods

##### StatusTransformer.GetName

```go
func (st *StatusTransformer) GetName() string
```

##### StatusTransformer.Transform

```go
func (st *StatusTransformer) Transform(input interface{}) (interface{}, error)
```

### StringTransformer

Built-in transformers


#### Methods

##### StringTransformer.GetName

```go
func (st *StringTransformer) GetName() string
```

##### StringTransformer.Transform

```go
func (st *StringTransformer) Transform(input interface{}) (interface{}, error)
```

### SyncResponse

SyncResponse represents the response from sync operations


### TLSConfig

TLSConfig contains TLS configuration


### TokenCache

TokenCache stores authentication tokens


### TransformationInfo

TransformationInfo tracks applied transformations


