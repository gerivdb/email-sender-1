# Error Manager Architecture Documentation

## System Architecture Overview

The Error Manager is a comprehensive error handling and analysis system designed with a modular architecture that supports real-time error cataloging, pattern analysis, and intelligent reporting.

## High-Level Architecture Diagram

```mermaid
graph TB
    subgraph "Application Layer"
        APP[Application Modules]
        EMAIL[Email Sender]
        AUTH[Auth Manager]
        DB_CLIENT[Database Client]
    end

    subgraph "Error Manager Core"
        VALIDATOR[Error Validator]
        CATALOGER[Error Cataloger]
        LOGGER[Structured Logger]
        WRAPPER[Error Wrapper]
    end

    subgraph "Analysis Engine"
        ANALYZER[Pattern Analyzer]
        CORRELATOR[Temporal Correlator]
        METRICS[Frequency Metrics]
    end

    subgraph "Reporting System"
        GENERATOR[Report Generator]
        TEMPLATE[Template Engine]
        EXPORT[Export Manager]
    end

    subgraph "Storage Layer"
        POSTGRES[(PostgreSQL)]
        QDRANT[(Qdrant Vector DB)]
        FILES[File Storage]
    end

    subgraph "Monitoring & Alerts"
        METRICS_COLLECTOR[Metrics Collector]
        DASHBOARD[Dashboard]
        ALERTS[Alert System]
    end

    APP --> VALIDATOR
    EMAIL --> CATALOGER
    AUTH --> WRAPPER
    DB_CLIENT --> LOGGER

    VALIDATOR --> CATALOGER
    CATALOGER --> LOGGER
    WRAPPER --> CATALOGER

    CATALOGER --> POSTGRES
    LOGGER --> POSTGRES
    
    ANALYZER --> POSTGRES
    ANALYZER --> CORRELATOR
    ANALYZER --> METRICS

    GENERATOR --> ANALYZER
    GENERATOR --> TEMPLATE
    TEMPLATE --> EXPORT
    EXPORT --> FILES

    POSTGRES --> METRICS_COLLECTOR
    METRICS_COLLECTOR --> DASHBOARD
    DASHBOARD --> ALERTS
```

## Component Architecture

### 1. Error Collection Layer

```mermaid
graph LR
    subgraph "Error Sources"
        APP_ERR[Application Errors]
        SYS_ERR[System Errors]
        EXT_ERR[External Service Errors]
    end

    subgraph "Error Processing"
        WRAP[Error Wrapper]
        VALIDATE[Validator]
        ENRICH[Context Enricher]
    end

    subgraph "Error Cataloging"
        STRUCT_LOG[Structured Logger]
        PERSIST[Persistence Layer]
        INDEX[Search Indexer]
    end

    APP_ERR --> WRAP
    SYS_ERR --> WRAP
    EXT_ERR --> WRAP

    WRAP --> VALIDATE
    VALIDATE --> ENRICH
    ENRICH --> STRUCT_LOG
    STRUCT_LOG --> PERSIST
    PERSIST --> INDEX
```

### 2. Pattern Analysis Architecture

```mermaid
graph TB
    subgraph "Data Sources"
        HISTORICAL[Historical Data]
        REALTIME[Real-time Stream]
        METADATA[Error Metadata]
    end

    subgraph "Analysis Pipeline"
        AGGREGATOR[Data Aggregator]
        PATTERN_DETECTOR[Pattern Detector]
        FREQUENCY_ANALYZER[Frequency Analyzer]
        TEMPORAL_ANALYZER[Temporal Analyzer]
    end

    subgraph "ML/AI Layer"
        CLUSTERING[Error Clustering]
        PREDICTION[Trend Prediction]
        ANOMALY[Anomaly Detection]
    end

    subgraph "Insights Engine"
        CORRELATOR[Correlation Engine]
        RECOMMENDER[Recommendation Engine]
        SCORER[Risk Scorer]
    end

    HISTORICAL --> AGGREGATOR
    REALTIME --> AGGREGATOR
    METADATA --> AGGREGATOR

    AGGREGATOR --> PATTERN_DETECTOR
    AGGREGATOR --> FREQUENCY_ANALYZER
    AGGREGATOR --> TEMPORAL_ANALYZER

    PATTERN_DETECTOR --> CLUSTERING
    FREQUENCY_ANALYZER --> PREDICTION
    TEMPORAL_ANALYZER --> ANOMALY

    CLUSTERING --> CORRELATOR
    PREDICTION --> RECOMMENDER
    ANOMALY --> SCORER
```

### 3. Storage Architecture

```mermaid
graph TB
    subgraph "Application Layer"
        ERROR_MANAGER[Error Manager]
        PATTERN_ANALYZER[Pattern Analyzer]
        REPORT_GEN[Report Generator]
    end

    subgraph "Storage Abstraction"
        STORAGE_INTERFACE[Storage Interface]
        POSTGRES_ADAPTER[PostgreSQL Adapter]
        QDRANT_ADAPTER[Qdrant Adapter]
        FILE_ADAPTER[File System Adapter]
    end

    subgraph "Physical Storage"
        POSTGRES_DB[(PostgreSQL Database)]
        QDRANT_DB[(Qdrant Vector Database)]
        FILE_SYSTEM[File System]
    end

    subgraph "Data Organization"
        ERROR_TABLES[Error Tables]
        PATTERN_TABLES[Pattern Tables]
        METRICS_TABLES[Metrics Tables]
        VECTOR_INDEX[Vector Index]
        SIMILARITY_INDEX[Similarity Index]
        REPORT_FILES[Report Files]
        EXPORT_FILES[Export Files]
    end

    ERROR_MANAGER --> STORAGE_INTERFACE
    PATTERN_ANALYZER --> STORAGE_INTERFACE
    REPORT_GEN --> STORAGE_INTERFACE

    STORAGE_INTERFACE --> POSTGRES_ADAPTER
    STORAGE_INTERFACE --> QDRANT_ADAPTER
    STORAGE_INTERFACE --> FILE_ADAPTER

    POSTGRES_ADAPTER --> POSTGRES_DB
    QDRANT_ADAPTER --> QDRANT_DB
    FILE_ADAPTER --> FILE_SYSTEM

    POSTGRES_DB --> ERROR_TABLES
    POSTGRES_DB --> PATTERN_TABLES
    POSTGRES_DB --> METRICS_TABLES
    QDRANT_DB --> VECTOR_INDEX
    QDRANT_DB --> SIMILARITY_INDEX
    FILE_SYSTEM --> REPORT_FILES
    FILE_SYSTEM --> EXPORT_FILES
```

## Data Flow Diagrams

### 1. Error Processing Flow

```mermaid
sequenceDiagram
    participant App as Application
    participant EM as Error Manager
    participant Val as Validator
    participant Cat as Cataloger
    participant Log as Logger
    participant DB as PostgreSQL
    participant Ana as Analyzer

    App->>EM: Error Occurs
    EM->>Val: Validate Error Entry
    Val->>Val: Check Required Fields
    Val->>Val: Validate Severity
    Val-->>EM: Validation Result
    
    alt Validation Success
        EM->>Cat: Catalog Error
        Cat->>Log: Structure Log Entry
        Log->>DB: Persist Error
        DB-->>Log: Confirmation
        Log-->>Cat: Log Success
        Cat-->>EM: Catalog Success
        
        Note over Ana: Async Process
        Ana->>DB: Query New Error
        Ana->>Ana: Update Patterns
        Ana->>Ana: Check Correlations
    else Validation Failure
        EM-->>App: Validation Error
    end
```

### 2. Pattern Analysis Flow

```mermaid
sequenceDiagram
    participant Sched as Scheduler
    participant Ana as Pattern Analyzer
    participant DB as PostgreSQL
    participant Rep as Report Generator
    participant Export as Export Manager
    participant File as File System

    Sched->>Ana: Trigger Analysis
    Ana->>DB: Query Error Data
    DB-->>Ana: Error Dataset
    
    Ana->>Ana: Analyze Patterns
    Ana->>Ana: Calculate Frequencies
    Ana->>Ana: Identify Correlations
    
    Ana->>Rep: Generate Report
    Rep->>Rep: Process Analytics
    Rep->>Rep: Generate Recommendations
    Rep->>Rep: Identify Critical Findings
    
    Rep->>Export: Export Report
    Export->>File: Save JSON Report
    Export->>File: Save HTML Report
    Export->>File: Save CSV Data
    
    File-->>Export: Confirmation
    Export-->>Rep: Export Success
    Rep-->>Ana: Report Complete
```

### 3. Real-time Monitoring Flow

```mermaid
sequenceDiagram
    participant App as Applications
    participant EM as Error Manager
    participant Stream as Event Stream
    participant Monitor as Monitor Service
    participant Dash as Dashboard
    participant Alert as Alert System

    loop Continuous Monitoring
        App->>EM: Error Event
        EM->>Stream: Publish Error Event
        Stream->>Monitor: Stream Error Data
        
        Monitor->>Monitor: Analyze Real-time Patterns
        Monitor->>Monitor: Check Thresholds
        
        alt Threshold Exceeded
            Monitor->>Alert: Trigger Alert
            Alert->>Alert: Send Notification
        end
        
        Monitor->>Dash: Update Metrics
        Dash->>Dash: Refresh Dashboard
    end
```

## Database Schema

### PostgreSQL Schema

```sql
-- Main errors table
CREATE TABLE project_errors (
    id UUID PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    module VARCHAR(100) NOT NULL,
    error_code VARCHAR(50) NOT NULL,
    manager_context TEXT,
    severity VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexing for performance
    INDEX idx_timestamp (timestamp),
    INDEX idx_module (module),
    INDEX idx_error_code (error_code),
    INDEX idx_severity (severity),
    INDEX idx_module_code (module, error_code)
);

-- Pattern analysis cache
CREATE TABLE error_patterns (
    id SERIAL PRIMARY KEY,
    pattern_hash VARCHAR(64) UNIQUE,
    module VARCHAR(100),
    error_code VARCHAR(50),
    frequency INTEGER,
    first_seen TIMESTAMPTZ,
    last_seen TIMESTAMPTZ,
    severity VARCHAR(20),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Correlation analysis results
CREATE TABLE error_correlations (
    id SERIAL PRIMARY KEY,
    error_code_1 VARCHAR(50),
    error_code_2 VARCHAR(50),
    module_1 VARCHAR(100),
    module_2 VARCHAR(100),
    correlation_score DECIMAL(5,4),
    time_window_seconds INTEGER,
    occurrence_gap_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Report metadata
CREATE TABLE analysis_reports (
    id SERIAL PRIMARY KEY,
    report_type VARCHAR(50),
    generated_at TIMESTAMPTZ,
    total_errors INTEGER,
    unique_patterns INTEGER,
    file_path TEXT,
    status VARCHAR(20),
    metadata JSONB
);
```

## Technology Stack

### Core Technologies

- **Language**: Go 1.19+
- **Database**: PostgreSQL 14+
- **Vector Database**: Qdrant
- **Logging**: Zap (uber-go/zap)
- **Error Handling**: pkg/errors
- **Testing**: Go standard testing + testify

### External Dependencies

```go
// Core dependencies
github.com/lib/pq              // PostgreSQL driver
go.uber.org/zap               // Structured logging
github.com/pkg/errors         // Enhanced error handling
github.com/google/uuid        // UUID generation

// Analysis dependencies
github.com/qdrant/go-client   // Qdrant vector database
encoding/json                 // JSON processing
html/template                 // Report templating
time                         // Time handling
```

## Security Architecture

### Data Protection

```mermaid
graph TB
    subgraph "Security Layers"
        AUTH[Authentication]
        AUTHZ[Authorization]
        ENCRYPT[Encryption]
        AUDIT[Audit Logging]
    end

    subgraph "Access Control"
        RBAC[Role-Based Access]
        API_KEY[API Key Management]
        SESSION[Session Management]
    end

    subgraph "Data Security"
        TLS[TLS Encryption]
        DB_ENCRYPT[Database Encryption]
        PII_MASK[PII Masking]
    end

    AUTH --> RBAC
    AUTHZ --> API_KEY
    ENCRYPT --> TLS
    AUDIT --> SESSION

    RBAC --> DB_ENCRYPT
    API_KEY --> PII_MASK
    TLS --> AUDIT
```

### Security Measures

1. **Data Encryption**
   - TLS 1.3 for data in transit
   - AES-256 for sensitive data at rest
   - PostgreSQL native encryption

2. **Access Control**
   - Role-based access control (RBAC)
   - API key authentication
   - Session-based authorization

3. **Data Privacy**
   - PII detection and masking
   - Configurable data retention policies
   - GDPR compliance features

4. **Audit Trail**
   - Complete access logging
   - Modification tracking
   - Security event monitoring

## Performance Architecture

### Scalability Design

```mermaid
graph TB
    subgraph "Load Balancing"
        LB[Load Balancer]
        APP1[App Instance 1]
        APP2[App Instance 2]
        APP3[App Instance N]
    end

    subgraph "Database Layer"
        MASTER[(Master DB)]
        REPLICA1[(Read Replica 1)]
        REPLICA2[(Read Replica 2)]
    end

    subgraph "Caching Layer"
        REDIS[(Redis Cache)]
        MEMCACHE[(Memcached)]
    end

    subgraph "Message Queue"
        QUEUE[Message Queue]
        WORKER1[Worker 1]
        WORKER2[Worker 2]
    end

    LB --> APP1
    LB --> APP2
    LB --> APP3

    APP1 --> REDIS
    APP2 --> REDIS
    APP3 --> REDIS

    APP1 --> MASTER
    APP2 --> REPLICA1
    APP3 --> REPLICA2

    APP1 --> QUEUE
    QUEUE --> WORKER1
    QUEUE --> WORKER2
```

### Performance Optimizations

1. **Database Optimization**
   - Strategic indexing on frequently queried columns
   - Connection pooling for efficient resource usage
   - Read replicas for analytics queries
   - Partitioning for large datasets

2. **Caching Strategy**
   - Redis for frequently accessed patterns
   - In-memory caching for recent error data
   - Report result caching

3. **Asynchronous Processing**
   - Queue-based pattern analysis
   - Background report generation
   - Non-blocking error logging

4. **Resource Management**
   - Connection pooling
   - Memory-efficient data structures
   - Garbage collection optimization

## Deployment Architecture

### Container Deployment

```mermaid
graph TB
    subgraph "Kubernetes Cluster"
        subgraph "Error Manager Namespace"
            EM_POD[Error Manager Pod]
            ANALYZER_POD[Analyzer Pod]
            REPORTER_POD[Reporter Pod]
        end

        subgraph "Database Namespace"
            PG_POD[PostgreSQL Pod]
            QDRANT_POD[Qdrant Pod]
        end

        subgraph "Monitoring Namespace"
            PROMETHEUS[Prometheus]
            GRAFANA[Grafana]
        end
    end

    subgraph "External Services"
        STORAGE[Cloud Storage]
        ALERTS[Alert Service]
    end

    EM_POD --> PG_POD
    ANALYZER_POD --> PG_POD
    REPORTER_POD --> QDRANT_POD

    PROMETHEUS --> EM_POD
    GRAFANA --> PROMETHEUS

    REPORTER_POD --> STORAGE
    EM_POD --> ALERTS
```

## Integration Points

### API Interfaces

1. **REST API**
   - Error submission endpoints
   - Pattern query endpoints
   - Report generation endpoints

2. **gRPC Services**
   - High-performance error streaming
   - Real-time pattern analysis
   - Bulk data operations

3. **Message Queue Integration**
   - Kafka for high-volume error streams
   - RabbitMQ for reliable delivery
   - Redis Streams for real-time processing

### External System Integration

1. **Monitoring Systems**
   - Prometheus metrics export
   - Grafana dashboard integration
   - DataDog APM integration

2. **Alert Systems**
   - PagerDuty integration
   - Slack notifications
   - Email alert delivery

3. **CI/CD Integration**
   - GitHub Actions integration
   - Jenkins pipeline hooks
   - Docker registry integration

---

## Architecture Decision Records (ADRs)

### ADR-001: Database Choice
**Decision**: Use PostgreSQL as primary database
**Rationale**: ACID compliance, JSON support, mature ecosystem
**Status**: Accepted

### ADR-002: Vector Database
**Decision**: Use Qdrant for similarity search
**Rationale**: High performance, Go client availability, cloud-native
**Status**: Accepted

### ADR-003: Logging Framework
**Decision**: Use Zap for structured logging
**Rationale**: High performance, structured output, Uber ecosystem
**Status**: Accepted

### ADR-004: Error Wrapping
**Decision**: Use pkg/errors for error enhancement
**Rationale**: Stack trace preservation, context addition, community standard
**Status**: Accepted
