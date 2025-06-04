# Error Manager API Documentation

## Overview

The Error Manager package provides a comprehensive solution for error handling, analysis, and reporting in the EMAIL_SENDER_1 project. This document details all public functions and their usage.

## Table of Contents

1. [Core Error Management](#core-error-management)
2. [Error Analysis](#error-analysis)
3. [Pattern Recognition](#pattern-recognition)
4. [Report Generation](#report-generation)
5. [Storage Management](#storage-management)
6. [Validation](#validation)
7. [Data Types](#data-types)

---

## Core Error Management

### WrapError

**Function Signature:**
```go
func WrapError(err error, message string) error
```

**Description:**
Enriches an error with additional context using the `github.com/pkg/errors` package.

**Parameters:**
- `err` (error): The original error to wrap
- `message` (string): Additional context message

**Returns:**
- `error`: The wrapped error with enhanced context

**Example:**
```go
originalErr := errors.New("database connection failed")
wrappedErr := WrapError(originalErr, "failed to connect to user database")
```

### CatalogError

**Function Signature:**
```go
func CatalogError(entry ErrorEntry)
```

**Description:**
Prepares and logs an error entry using structured logging with Zap logger.

**Parameters:**
- `entry` (ErrorEntry): Complete error entry with all metadata

**Example:**
```go
entry := ErrorEntry{
    ID:             "123e4567-e89b-12d3-a456-426614174000",
    Timestamp:      time.Now(),
    Message:        "Failed to send email",
    Module:         "email-sender",
    ErrorCode:      "EMAIL_001",
    ManagerContext: "SMTP connection timeout",
    Severity:       "high",
}
CatalogError(entry)
```

### InitializeLogger

**Function Signature:**
```go
func InitializeLogger() error
```

**Description:**
Initializes the Zap logger in production mode for structured logging.

**Returns:**
- `error`: Error if initialization fails, nil otherwise

### LogError

**Function Signature:**
```go
func LogError(err error, module string, code string)
```

**Description:**
Logs an error with additional metadata using the structured logger.

**Parameters:**
- `err` (error): The error to log
- `module` (string): Module where error occurred
- `code` (string): Error code identifier

---

## Error Analysis

### AnalyzeErrorPatterns

**Function Signature:**
```go
func (pa *PatternAnalyzer) AnalyzeErrorPatterns() ([]PatternMetrics, error)
```

**Description:**
Analyzes error patterns from the database to detect recurring errors. Implements micro-task 4.1.1.

**Returns:**
- `[]PatternMetrics`: Array of detected error patterns with metrics
- `error`: Error if analysis fails

**Features:**
- Groups errors by code, module, and severity
- Calculates frequency metrics
- Tracks first and last occurrence timestamps
- Aggregates context information

### CreateFrequencyMetrics

**Function Signature:**
```go
func (pa *PatternAnalyzer) CreateFrequencyMetrics() (map[string]map[string]int, error)
```

**Description:**
Creates frequency metrics by module and error code. Implements micro-task 4.1.2.

**Returns:**
- `map[string]map[string]int`: Nested map [module][error_code] = frequency
- `error`: Error if metrics creation fails

### IdentifyTemporalCorrelations

**Function Signature:**
```go
func (pa *PatternAnalyzer) IdentifyTemporalCorrelations(timeWindow time.Duration) ([]TemporalCorrelation, error)
```

**Description:**
Identifies temporal correlations between different errors within a specified time window. Implements micro-task 4.1.3.

**Parameters:**
- `timeWindow` (time.Duration): Time window for correlation analysis

**Returns:**
- `[]TemporalCorrelation`: Array of temporal correlations found
- `error`: Error if correlation analysis fails

---

## Pattern Recognition

### NewPatternAnalyzer

**Function Signature:**
```go
func NewPatternAnalyzer(db *sql.DB) *PatternAnalyzer
```

**Description:**
Creates a new instance of PatternAnalyzer with database connection.

**Parameters:**
- `db` (*sql.DB): Database connection for pattern analysis

**Returns:**
- `*PatternAnalyzer`: New pattern analyzer instance

---

## Report Generation

### GeneratePatternReport

**Function Signature:**
```go
func (rg *ReportGenerator) GeneratePatternReport() (*PatternReport, error)
```

**Description:**
Generates a comprehensive pattern analysis report. Implements micro-task 4.2.1.

**Returns:**
- `*PatternReport`: Complete pattern analysis report
- `error`: Error if report generation fails

**Report Contents:**
- Total error count and unique patterns
- Top error patterns by frequency
- Frequency metrics by module
- Temporal correlations
- Automated recommendations
- Critical findings

### NewReportGenerator

**Function Signature:**
```go
func NewReportGenerator(analyzer *PatternAnalyzer) *ReportGenerator
```

**Description:**
Creates a new instance of ReportGenerator with pattern analyzer.

**Parameters:**
- `analyzer` (*PatternAnalyzer): Pattern analyzer for report generation

**Returns:**
- `*ReportGenerator`: New report generator instance

---

## Storage Management

### InitializePostgres

**Function Signature:**
```go
func InitializePostgres(connStr string) error
```

**Description:**
Initializes PostgreSQL database connection for error storage.

**Parameters:**
- `connStr` (string): PostgreSQL connection string

**Returns:**
- `error`: Error if connection fails, nil otherwise

### PersistErrorToSQL

**Function Signature:**
```go
func PersistErrorToSQL(entry ErrorEntry) error
```

**Description:**
Persists an error entry to PostgreSQL database.

**Parameters:**
- `entry` (ErrorEntry): Error entry to persist

**Returns:**
- `error`: Error if persistence fails, nil otherwise

---

## Validation

### ValidateErrorEntry

**Function Signature:**
```go
func ValidateErrorEntry(entry ErrorEntry) error
```

**Description:**
Validates all required fields of an ErrorEntry structure.

**Parameters:**
- `entry` (ErrorEntry): Error entry to validate

**Returns:**
- `error`: Validation error if entry is invalid, nil if valid

**Validation Rules:**
- ID cannot be empty
- Timestamp cannot be zero
- Message cannot be empty
- Module cannot be empty
- ErrorCode cannot be empty
- Severity must be one of: "low", "medium", "high", "critical"

---

## Data Types

### ErrorEntry

Main structure for representing errors in the system.

```go
type ErrorEntry struct {
    ID             string    `json:"id"`
    Timestamp      time.Time `json:"timestamp"`
    Message        string    `json:"message"`
    StackTrace     string    `json:"stack_trace"`
    Module         string    `json:"module"`
    ErrorCode      string    `json:"error_code"`
    ManagerContext string    `json:"manager_context"`
    Severity       string    `json:"severity"`
}
```

### PatternMetrics

Structure for error pattern analysis metrics.

```go
type PatternMetrics struct {
    TotalErrors      int                    `json:"total_errors"`
    UniquePatterns   int                    `json:"unique_patterns"`
    MostFrequentCode string                 `json:"most_frequent_code"`
    TimeWindow       string                 `json:"time_window"`
    ErrorCode        string                 `json:"error_code"`
    Module           string                 `json:"module"`
    Frequency        int                    `json:"frequency"`
    LastOccurred     time.Time              `json:"last_occurred"`
    FirstOccurred    time.Time              `json:"first_occurred"`
    Severity         string                 `json:"severity"`
    Context          map[string]interface{} `json:"context"`
}
```

### TemporalCorrelation

Structure for temporal correlation analysis.

```go
type TemporalCorrelation struct {
    ErrorCode1    string        `json:"error_code_1"`
    ErrorCode2    string        `json:"error_code_2"`
    Module1       string        `json:"module_1"`
    Module2       string        `json:"module_2"`
    Correlation   float64       `json:"correlation"`
    TimeWindow    time.Duration `json:"time_window"`
    OccurrenceGap time.Duration `json:"occurrence_gap"`
}
```

### PatternReport

Complete pattern analysis report structure.

```go
type PatternReport struct {
    GeneratedAt          time.Time                 `json:"generated_at"`
    TotalErrors          int                       `json:"total_errors"`
    UniquePatterns       int                       `json:"unique_patterns"`
    TopPatterns          []PatternMetrics          `json:"top_patterns"`
    FrequencyMetrics     map[string]map[string]int `json:"frequency_metrics"`
    TemporalCorrelations []TemporalCorrelation     `json:"temporal_correlations"`
    Recommendations      []string                  `json:"recommendations"`
    CriticalFindings     []string                  `json:"critical_findings"`
}
```

---

## Usage Examples

### Basic Error Handling

```go
// Initialize the error manager
err := InitializeLogger()
if err != nil {
    log.Fatal("Failed to initialize logger:", err)
}

// Handle and catalog an error
originalErr := errors.New("database timeout")
wrappedErr := WrapError(originalErr, "failed to fetch user data")

entry := ErrorEntry{
    ID:             uuid.New().String(),
    Timestamp:      time.Now(),
    Message:        wrappedErr.Error(),
    Module:         "user-service",
    ErrorCode:      "DB_TIMEOUT_001",
    ManagerContext: "User data retrieval",
    Severity:       "high",
}

if err := ValidateErrorEntry(entry); err != nil {
    log.Printf("Invalid error entry: %v", err)
    return
}

CatalogError(entry)
```

### Pattern Analysis

```go
// Initialize database connection
db, err := sql.Open("postgres", connectionString)
if err != nil {
    log.Fatal("Database connection failed:", err)
}

// Create analyzer and generate report
analyzer := NewPatternAnalyzer(db)
generator := NewReportGenerator(analyzer)

report, err := generator.GeneratePatternReport()
if err != nil {
    log.Printf("Report generation failed: %v", err)
    return
}

// Process recommendations
for _, recommendation := range report.Recommendations {
    log.Printf("Recommendation: %s", recommendation)
}
```

---

## Error Codes Reference

| Module | Code | Description | Severity |
|--------|------|-------------|----------|
| EMAIL_SENDER | EMAIL_001 | SMTP connection timeout | high |
| EMAIL_SENDER | EMAIL_002 | Invalid recipient address | medium |
| DATABASE | DB_001 | Connection pool exhausted | critical |
| DATABASE | DB_002 | Query timeout | high |
| AUTH | AUTH_001 | Token validation failed | medium |
| AUTH | AUTH_002 | Rate limit exceeded | low |

---

## Best Practices

1. **Always validate error entries** before cataloging
2. **Use descriptive error codes** that include module prefix
3. **Set appropriate severity levels** based on impact
4. **Include contextual information** in ManagerContext field
5. **Generate reports regularly** for proactive error management
6. **Monitor temporal correlations** to identify cascading failures
7. **Implement recommendations** from pattern analysis reports
