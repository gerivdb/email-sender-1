# Error Manager User Guide

## Table of Contents

1. [Getting Started](#getting-started)

2. [Basic Usage](#basic-usage)

3. [Advanced Features](#advanced-features)

4. [Pattern Analysis](#pattern-analysis)

5. [Report Generation](#report-generation)

6. [Configuration](#configuration)

7. [Best Practices](#best-practices)

8. [Troubleshooting](#troubleshooting)

9. [Examples](#examples)

---

## Getting Started

### Prerequisites

Before using the Error Manager, ensure you have:

- Go 1.19 or higher
- PostgreSQL 14+ database
- Qdrant vector database (optional, for advanced features)
- Required Go packages (see `go.mod`)

### Installation

1. **Import the package**
   ```go
   import "email_sender/development/managers/error-manager"
   ```

2. **Initialize the logger**
   ```go
   err := errormanager.InitializeLogger()
   if err != nil {
       log.Fatal("Failed to initialize logger:", err)
   }
   ```

3. **Set up database connection**
   ```go
   import "email_sender/development/managers/error-manager/storage"
   
   connStr := "host=localhost port=5432 user=postgres password=postgres dbname=email_sender_errors sslmode=disable"
   err := errormanager.InitializePostgres(connStr)
   if err != nil {
       log.Fatal("Database connection failed:", err)
   }
   ```

### Quick Start Example

```go
package main

import (
    "log"
    "time"
    "github.com/google/uuid"
    "email_sender/development/managers/error-manager"
)

func main() {
    // Initialize the error manager
    if err := errormanager.InitializeLogger(); err != nil {
        log.Fatal("Logger initialization failed:", err)
    }

    // Create an error entry
    entry := errormanager.ErrorEntry{
        ID:             uuid.New().String(),
        Timestamp:      time.Now(),
        Message:        "Failed to send email to user",
        Module:         "email-sender",
        ErrorCode:      "EMAIL_001",
        ManagerContext: "SMTP timeout during delivery",
        Severity:       "high",
        StackTrace:     "stack trace here...",
    }

    // Validate and catalog the error
    if err := errormanager.ValidateErrorEntry(entry); err != nil {
        log.Printf("Invalid error entry: %v", err)
        return
    }

    errormanager.CatalogError(entry)
    log.Println("Error cataloged successfully")
}
```plaintext
---

## Basic Usage

### 1. Error Entry Creation

The `ErrorEntry` struct is the core data structure for representing errors:

```go
type ErrorEntry struct {
    ID             string    `json:"id"`             // Unique identifier
    Timestamp      time.Time `json:"timestamp"`      // When error occurred
    Message        string    `json:"message"`        // Error description
    StackTrace     string    `json:"stack_trace"`    // Call stack (optional)
    Module         string    `json:"module"`         // Source module
    ErrorCode      string    `json:"error_code"`     // Categorization code
    ManagerContext string    `json:"manager_context"` // Additional context
    Severity       string    `json:"severity"`       // Severity level
}
```plaintext
### 2. Error Validation

Always validate error entries before processing:

```go
entry := errormanager.ErrorEntry{
    ID:             uuid.New().String(),
    Timestamp:      time.Now(),
    Message:        "Database connection failed",
    Module:         "database",
    ErrorCode:      "DB_001",
    ManagerContext: "Connection pool exhausted",
    Severity:       "critical",
}

if err := errormanager.ValidateErrorEntry(entry); err != nil {
    log.Printf("Validation failed: %v", err)
    return
}
```plaintext
**Validation Rules:**
- `ID`: Must not be empty
- `Timestamp`: Must not be zero
- `Message`: Must not be empty
- `Module`: Must not be empty
- `ErrorCode`: Must not be empty
- `Severity`: Must be one of: "low", "medium", "high", "critical"

### 3. Error Wrapping

Use `WrapError` to add context to existing errors:

```go
originalErr := errors.New("connection refused")
wrappedErr := errormanager.WrapError(originalErr, "failed to connect to database")
// Result: "failed to connect to database: connection refused"
```plaintext
### 4. Error Logging

Log errors with structured metadata:

```go
err := errors.New("authentication failed")
errormanager.LogError(err, "auth-service", "AUTH_001")
```plaintext
---

## Advanced Features

### 1. Error Pattern Analysis

Analyze error patterns to identify trends and recurring issues:

```go
// Set up pattern analyzer
db, err := sql.Open("postgres", connectionString)
if err != nil {
    log.Fatal("Database connection failed:", err)
}

analyzer := errormanager.NewPatternAnalyzer(db)

// Analyze patterns
patterns, err := analyzer.AnalyzeErrorPatterns()
if err != nil {
    log.Printf("Pattern analysis failed: %v", err)
    return
}

// Process results
for _, pattern := range patterns {
    log.Printf("Pattern: %s:%s, Frequency: %d, Last: %v",
        pattern.Module, pattern.ErrorCode, pattern.Frequency, pattern.LastOccurred)
}
```plaintext
### 2. Frequency Metrics

Generate frequency metrics by module and error code:

```go
metrics, err := analyzer.CreateFrequencyMetrics()
if err != nil {
    log.Printf("Metrics creation failed: %v", err)
    return
}

// Display metrics
for module, errorCodes := range metrics {
    log.Printf("Module: %s", module)
    for code, frequency := range errorCodes {
        log.Printf("  %s: %d occurrences", code, frequency)
    }
}
```plaintext
### 3. Temporal Correlation Analysis

Identify correlations between different errors occurring within time windows:

```go
timeWindow := 1 * time.Hour
correlations, err := analyzer.IdentifyTemporalCorrelations(timeWindow)
if err != nil {
    log.Printf("Correlation analysis failed: %v", err)
    return
}

for _, corr := range correlations {
    log.Printf("Correlation: %s:%s ↔ %s:%s (Score: %.2f, Gap: %v)",
        corr.Module1, corr.ErrorCode1,
        corr.Module2, corr.ErrorCode2,
        corr.Correlation, corr.OccurrenceGap)
}
```plaintext
---

## Pattern Analysis

### Understanding Pattern Metrics

The `PatternMetrics` structure provides comprehensive information about error patterns:

```go
type PatternMetrics struct {
    TotalErrors      int                    // Total errors in pattern
    UniquePatterns   int                    // Number of unique patterns
    MostFrequentCode string                 // Most common error code
    TimeWindow       string                 // Analysis time window
    ErrorCode        string                 // Specific error code
    Module           string                 // Source module
    Frequency        int                    // Occurrence frequency
    LastOccurred     time.Time              // Most recent occurrence
    FirstOccurred    time.Time              // First occurrence
    Severity         string                 // Severity level
    Context          map[string]interface{} // Additional context
}
```plaintext
### Pattern Analysis Workflow

1. **Data Collection**: Gather historical error data from database
2. **Pattern Detection**: Group errors by code, module, and severity
3. **Frequency Analysis**: Calculate occurrence frequencies
4. **Temporal Analysis**: Identify time-based patterns
5. **Correlation Analysis**: Find relationships between different errors
6. **Report Generation**: Create actionable insights

### Example: Comprehensive Pattern Analysis

```go
func performComprehensiveAnalysis() {
    // Initialize components
    db, _ := sql.Open("postgres", connectionString)
    analyzer := errormanager.NewPatternAnalyzer(db)
    generator := errormanager.NewReportGenerator(analyzer)

    // Generate comprehensive report
    report, err := generator.GeneratePatternReport()
    if err != nil {
        log.Printf("Report generation failed: %v", err)
        return
    }

    // Display key findings
    log.Printf("Analysis Report Generated at: %v", report.GeneratedAt)
    log.Printf("Total Errors: %d", report.TotalErrors)
    log.Printf("Unique Patterns: %d", report.UniquePatterns)

    // Top patterns
    log.Println("\nTop Error Patterns:")
    for i, pattern := range report.TopPatterns {
        if i >= 5 { break } // Show top 5
        log.Printf("%d. %s:%s - %d occurrences",
            i+1, pattern.Module, pattern.ErrorCode, pattern.Frequency)
    }

    // Recommendations
    log.Println("\nRecommendations:")
    for _, rec := range report.Recommendations {
        log.Printf("• %s", rec)
    }

    // Critical findings
    if len(report.CriticalFindings) > 0 {
        log.Println("\nCritical Findings:")
        for _, finding := range report.CriticalFindings {
            log.Printf("⚠️  %s", finding)
        }
    }
}
```plaintext
---

## Report Generation

### Report Types

The Error Manager generates several types of reports:

1. **Pattern Analysis Report**: Comprehensive error pattern analysis
2. **Frequency Report**: Error frequency by module and code
3. **Correlation Report**: Temporal correlation analysis
4. **Trend Report**: Time-based trend analysis

### Report Structure

```go
type PatternReport struct {
    GeneratedAt          time.Time                 // Report generation time
    TotalErrors          int                       // Total error count
    UniquePatterns       int                       // Number of unique patterns
    TopPatterns          []PatternMetrics          // Most frequent patterns
    FrequencyMetrics     map[string]map[string]int // Frequency by module/code
    TemporalCorrelations []TemporalCorrelation     // Time-based correlations
    Recommendations      []string                  // Automated recommendations
    CriticalFindings     []string                  // Critical issues found
}
```plaintext
### Generating Reports

```go
// Basic report generation
generator := errormanager.NewReportGenerator(analyzer)
report, err := generator.GeneratePatternReport()
if err != nil {
    log.Printf("Report generation failed: %v", err)
    return
}

// Save report to file
reportJSON, _ := json.MarshalIndent(report, "", "  ")
err = ioutil.WriteFile("error_analysis_report.json", reportJSON, 0644)
if err != nil {
    log.Printf("Failed to save report: %v", err)
}
```plaintext
### Custom Report Processing

```go
func processReport(report *errormanager.PatternReport) {
    // Identify high-impact modules
    highImpactModules := make(map[string]int)
    for module, codes := range report.FrequencyMetrics {
        total := 0
        for _, freq := range codes {
            total += freq
        }
        if total > 50 { // Threshold for high impact
            highImpactModules[module] = total
        }
    }

    // Process critical correlations
    criticalCorrelations := []errormanager.TemporalCorrelation{}
    for _, corr := range report.TemporalCorrelations {
        if corr.Correlation > 0.7 { // High correlation threshold
            criticalCorrelations = append(criticalCorrelations, corr)
        }
    }

    // Generate action items
    actionItems := generateActionItems(highImpactModules, criticalCorrelations)
    
    // Send alerts for critical findings
    if len(report.CriticalFindings) > 0 {
        sendCriticalAlert(report.CriticalFindings)
    }
}
```plaintext
---

## Configuration

### Environment Configuration

Set up environment variables for different deployments:

```bash
# Database configuration

export ERROR_DB_HOST=localhost
export ERROR_DB_PORT=5432
export ERROR_DB_USER=postgres
export ERROR_DB_PASSWORD=your_password
export ERROR_DB_NAME=email_sender_errors

# Qdrant configuration (optional)

export QDRANT_HOST=localhost
export QDRANT_PORT=6333

# Analysis configuration

export ANALYSIS_TIME_WINDOW=1h
export PATTERN_MIN_FREQUENCY=5
export CORRELATION_THRESHOLD=0.5

# Report configuration

export REPORT_OUTPUT_DIR=/var/reports
export REPORT_FORMAT=json,html,csv
export REPORT_RETENTION_DAYS=30
```plaintext
### Configuration Struct

```go
type Config struct {
    Database struct {
        Host     string `env:"ERROR_DB_HOST" default:"localhost"`
        Port     int    `env:"ERROR_DB_PORT" default:"5432"`
        User     string `env:"ERROR_DB_USER" default:"postgres"`
        Password string `env:"ERROR_DB_PASSWORD"`
        Name     string `env:"ERROR_DB_NAME" default:"email_sender_errors"`
    }
    
    Analysis struct {
        TimeWindow      time.Duration `env:"ANALYSIS_TIME_WINDOW" default:"1h"`
        MinFrequency    int          `env:"PATTERN_MIN_FREQUENCY" default:"5"`
        CorrelationThreshold float64 `env:"CORRELATION_THRESHOLD" default:"0.5"`
    }
    
    Reports struct {
        OutputDir      string   `env:"REPORT_OUTPUT_DIR" default:"./reports"`
        Format         []string `env:"REPORT_FORMAT" default:"json"`
        RetentionDays  int      `env:"REPORT_RETENTION_DAYS" default:"30"`
    }
}
```plaintext
### Database Setup

Create the required database schema:

```sql
-- Create database
CREATE DATABASE email_sender_errors;

-- Switch to the database
\c email_sender_errors;

-- Create main errors table
CREATE TABLE project_errors (
    id UUID PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL,
    message TEXT NOT NULL,
    stack_trace TEXT,
    module VARCHAR(100) NOT NULL,
    error_code VARCHAR(50) NOT NULL,
    manager_context TEXT,
    severity VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_project_errors_timestamp ON project_errors(timestamp);
CREATE INDEX idx_project_errors_module ON project_errors(module);
CREATE INDEX idx_project_errors_error_code ON project_errors(error_code);
CREATE INDEX idx_project_errors_severity ON project_errors(severity);
CREATE INDEX idx_project_errors_module_code ON project_errors(module, error_code);
```plaintext
---

## Best Practices

### 1. Error Code Convention

Use a consistent naming convention for error codes:

```plaintext
Format: [MODULE]_[CATEGORY]_[NUMBER]
Examples:
- EMAIL_SMTP_001: SMTP connection failure
- AUTH_TOKEN_002: Invalid JWT token
- DB_CONN_001: Connection pool exhausted
```plaintext
### 2. Severity Levels

Choose appropriate severity levels:

- **low**: Minor issues that don't affect functionality
- **medium**: Issues that may impact user experience
- **high**: Significant issues that affect core functionality
- **critical**: System-wide failures or security breaches

### 3. Context Information

Provide meaningful context in the `ManagerContext` field:

```go
// Good context examples
"User ID: 12345, Email: user@example.com, SMTP Server: smtp.gmail.com"
"Database: users_db, Query: SELECT * FROM users WHERE id = $1, Timeout: 30s"
"API Endpoint: /api/v1/users, Request ID: req_123, User Agent: Chrome/95.0"

// Poor context examples
"Error occurred"
"Something went wrong"
"Failed"
```plaintext
### 4. Error Handling Patterns

#### Pattern 1: Wrap and Escalate

```go
func processUser(userID string) error {
    user, err := getUserFromDB(userID)
    if err != nil {
        return errormanager.WrapError(err, fmt.Sprintf("failed to get user %s", userID))
    }
    // Process user...
    return nil
}
```plaintext
#### Pattern 2: Log and Continue

```go
func processUsers(userIDs []string) {
    for _, userID := range userIDs {
        if err := processUser(userID); err != nil {
            errormanager.LogError(err, "user-processor", "USER_PROC_001")
            continue // Continue processing other users
        }
    }
}
```plaintext
#### Pattern 3: Catalog and Alert

```go
func criticalOperation() error {
    if err := performCriticalTask(); err != nil {
        entry := errormanager.ErrorEntry{
            ID:             uuid.New().String(),
            Timestamp:      time.Now(),
            Message:        err.Error(),
            Module:         "critical-service",
            ErrorCode:      "CRIT_001",
            ManagerContext: "Critical operation failed during peak hours",
            Severity:       "critical",
        }
        
        errormanager.CatalogError(entry)
        // Trigger immediate alert
        alertSystem.SendCriticalAlert(entry)
        return err
    }
    return nil
}
```plaintext
### 5. Performance Considerations

- **Batch Operations**: Use batch inserts for high-volume error logging
- **Async Processing**: Perform pattern analysis asynchronously
- **Connection Pooling**: Use database connection pooling
- **Caching**: Cache frequently accessed patterns and metrics

```go
// Example: Async error processing
type ErrorProcessor struct {
    queue chan errormanager.ErrorEntry
    db    *sql.DB
}

func (ep *ErrorProcessor) Start() {
    go func() {
        for entry := range ep.queue {
            // Process error entry asynchronously
            if err := errormanager.PersistErrorToSQL(entry); err != nil {
                log.Printf("Failed to persist error: %v", err)
            }
        }
    }()
}

func (ep *ErrorProcessor) QueueError(entry errormanager.ErrorEntry) {
    select {
    case ep.queue <- entry:
        // Queued successfully
    default:
        // Queue full, handle accordingly
        log.Printf("Error queue full, dropping error: %s", entry.ID)
    }
}
```plaintext
---

## Troubleshooting

### Common Issues

#### 1. Database Connection Errors

**Problem**: "Failed to connect to database"
**Solutions**:
- Verify connection string format
- Check database server status
- Ensure firewall allows connections
- Validate credentials

```go
// Test database connection
func testDBConnection(connStr string) error {
    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return fmt.Errorf("failed to open connection: %w", err)
    }
    defer db.Close()
    
    if err = db.Ping(); err != nil {
        return fmt.Errorf("failed to ping database: %w", err)
    }
    
    log.Println("Database connection successful")
    return nil
}
```plaintext
#### 2. Validation Errors

**Problem**: "Invalid error entry"
**Solutions**:
- Check all required fields are populated
- Verify severity level is valid
- Ensure timestamp is not zero

```go
// Debug validation
func debugValidation(entry errormanager.ErrorEntry) {
    if entry.ID == "" {
        log.Println("❌ ID is empty")
    }
    if entry.Timestamp.IsZero() {
        log.Println("❌ Timestamp is zero")
    }
    if entry.Message == "" {
        log.Println("❌ Message is empty")
    }
    if entry.Module == "" {
        log.Println("❌ Module is empty")
    }
    if entry.ErrorCode == "" {
        log.Println("❌ ErrorCode is empty")
    }
    
    validSeverities := []string{"low", "medium", "high", "critical"}
    isValidSeverity := false
    for _, s := range validSeverities {
        if entry.Severity == s {
            isValidSeverity = true
            break
        }
    }
    if !isValidSeverity {
        log.Printf("❌ Invalid severity: %s", entry.Severity)
    }
}
```plaintext
#### 3. Performance Issues

**Problem**: Slow pattern analysis
**Solutions**:
- Add database indexes
- Limit analysis time window
- Use connection pooling
- Consider data partitioning

```go
// Optimized pattern analysis with limits
func optimizedPatternAnalysis(analyzer *errormanager.PatternAnalyzer) {
    // Limit analysis to recent data
    cutoffTime := time.Now().AddDate(0, 0, -30) // Last 30 days
    
    patterns, err := analyzer.AnalyzeErrorPatternsWithTimeLimit(cutoffTime)
    if err != nil {
        log.Printf("Pattern analysis failed: %v", err)
        return
    }
    
    // Process patterns...
}
```plaintext
#### 4. Memory Issues

**Problem**: High memory usage during analysis
**Solutions**:
- Process data in chunks
- Use streaming queries
- Implement pagination
- Clear unused variables

```go
// Memory-efficient pattern analysis
func memoryEfficientAnalysis(analyzer *errormanager.PatternAnalyzer) {
    const batchSize = 1000
    offset := 0
    
    for {
        patterns, err := analyzer.AnalyzeErrorPatternsBatch(batchSize, offset)
        if err != nil {
            log.Printf("Batch analysis failed: %v", err)
            break
        }
        
        if len(patterns) == 0 {
            break // No more data
        }
        
        // Process batch
        processPatternsChunk(patterns)
        
        offset += batchSize
        runtime.GC() // Force garbage collection
    }
}
```plaintext
### Debugging Tools

#### 1. Error Entry Validator

```go
func validateAndReport(entry errormanager.ErrorEntry) {
    if err := errormanager.ValidateErrorEntry(entry); err != nil {
        log.Printf("Validation failed: %v", err)
        debugValidation(entry)
        return
    }
    log.Println("✅ Error entry is valid")
}
```plaintext
#### 2. Pattern Analysis Debugger

```go
func debugPatternAnalysis(analyzer *errormanager.PatternAnalyzer) {
    start := time.Now()
    
    patterns, err := analyzer.AnalyzeErrorPatterns()
    duration := time.Since(start)
    
    if err != nil {
        log.Printf("❌ Analysis failed: %v", err)
        return
    }
    
    log.Printf("✅ Analysis completed in %v", duration)
    log.Printf("Found %d patterns", len(patterns))
    
    for i, pattern := range patterns {
        if i >= 3 { break } // Show first 3
        log.Printf("Pattern %d: %s:%s (freq: %d)", 
            i+1, pattern.Module, pattern.ErrorCode, pattern.Frequency)
    }
}
```plaintext
#### 3. Database Query Monitor

```go
func monitorDatabaseQueries(db *sql.DB) {
    // Monitor slow queries
    rows, err := db.Query(`
        SELECT query, mean_time, calls 
        FROM pg_stat_statements 
        WHERE mean_time > 1000 
        ORDER BY mean_time DESC
    `)
    if err != nil {
        log.Printf("Failed to monitor queries: %v", err)
        return
    }
    defer rows.Close()
    
    log.Println("Slow queries detected:")
    for rows.Next() {
        var query string
        var meanTime, calls float64
        
        if err := rows.Scan(&query, &meanTime, &calls); err != nil {
            continue
        }
        
        log.Printf("Query: %s, Mean time: %.2fms, Calls: %.0f", 
            query[:100], meanTime, calls)
    }
}
```plaintext
---

## Examples

### Example 1: Simple Error Handling

```go
package main

import (
    "errors"
    "log"
    "time"
    "github.com/google/uuid"
    "email_sender/development/managers/error-manager"
)

func sendEmail(to string) error {
    // Simulate email sending
    if to == "" {
        return errors.New("recipient email is empty")
    }
    
    // Simulate network error
    if to == "fail@example.com" {
        return errors.New("SMTP connection timeout")
    }
    
    return nil
}

func main() {
    // Initialize error manager
    if err := errormanager.InitializeLogger(); err != nil {
        log.Fatal("Logger initialization failed:", err)
    }
    
    recipients := []string{"user@example.com", "", "fail@example.com", "success@example.com"}
    
    for _, recipient := range recipients {
        if err := sendEmail(recipient); err != nil {
            // Wrap error with context
            wrappedErr := errormanager.WrapError(err, 
                fmt.Sprintf("failed to send email to %s", recipient))
            
            // Create error entry
            entry := errormanager.ErrorEntry{
                ID:             uuid.New().String(),
                Timestamp:      time.Now(),
                Message:        wrappedErr.Error(),
                Module:         "email-sender",
                ErrorCode:      determineErrorCode(err),
                ManagerContext: fmt.Sprintf("Recipient: %s, Attempt: 1", recipient),
                Severity:       determineSeverity(err),
                StackTrace:     fmt.Sprintf("%+v", wrappedErr),
            }
            
            // Validate and catalog
            if validationErr := errormanager.ValidateErrorEntry(entry); validationErr != nil {
                log.Printf("Invalid error entry: %v", validationErr)
                continue
            }
            
            errormanager.CatalogError(entry)
            log.Printf("Cataloged error for %s", recipient)
        } else {
            log.Printf("Successfully sent email to %s", recipient)
        }
    }
}

func determineErrorCode(err error) string {
    if strings.Contains(err.Error(), "empty") {
        return "EMAIL_INVALID_001"
    }
    if strings.Contains(err.Error(), "timeout") {
        return "EMAIL_SMTP_001"
    }
    return "EMAIL_UNKNOWN_001"
}

func determineSeverity(err error) string {
    if strings.Contains(err.Error(), "timeout") {
        return "high"
    }
    if strings.Contains(err.Error(), "empty") {
        return "medium"
    }
    return "low"
}
```plaintext
### Example 2: Pattern Analysis Dashboard

```go
package main

import (
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "time"
    "email_sender/development/managers/error-manager"
)

type Dashboard struct {
    analyzer  *errormanager.PatternAnalyzer
    generator *errormanager.ReportGenerator
}

func NewDashboard(db *sql.DB) *Dashboard {
    analyzer := errormanager.NewPatternAnalyzer(db)
    generator := errormanager.NewReportGenerator(analyzer)
    
    return &Dashboard{
        analyzer:  analyzer,
        generator: generator,
    }
}

func (d *Dashboard) handlePatterns(w http.ResponseWriter, r *http.Request) {
    patterns, err := d.analyzer.AnalyzeErrorPatterns()
    if err != nil {
        http.Error(w, fmt.Sprintf("Pattern analysis failed: %v", err), 
            http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(patterns)
}

func (d *Dashboard) handleMetrics(w http.ResponseWriter, r *http.Request) {
    metrics, err := d.analyzer.CreateFrequencyMetrics()
    if err != nil {
        http.Error(w, fmt.Sprintf("Metrics creation failed: %v", err), 
            http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(metrics)
}

func (d *Dashboard) handleReport(w http.ResponseWriter, r *http.Request) {
    report, err := d.generator.GeneratePatternReport()
    if err != nil {
        http.Error(w, fmt.Sprintf("Report generation failed: %v", err), 
            http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(report)
}

func (d *Dashboard) handleCorrelations(w http.ResponseWriter, r *http.Request) {
    timeWindow := 1 * time.Hour
    correlations, err := d.analyzer.IdentifyTemporalCorrelations(timeWindow)
    if err != nil {
        http.Error(w, fmt.Sprintf("Correlation analysis failed: %v", err), 
            http.StatusInternalServerError)
        return
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(correlations)
}

func main() {
    // Database connection
    db, err := sql.Open("postgres", 
        "host=localhost port=5432 user=postgres password=postgres dbname=email_sender_errors sslmode=disable")
    if err != nil {
        log.Fatal("Database connection failed:", err)
    }
    defer db.Close()
    
    // Create dashboard
    dashboard := NewDashboard(db)
    
    // Setup routes
    http.HandleFunc("/api/patterns", dashboard.handlePatterns)
    http.HandleFunc("/api/metrics", dashboard.handleMetrics)
    http.HandleFunc("/api/report", dashboard.handleReport)
    http.HandleFunc("/api/correlations", dashboard.handleCorrelations)
    
    // Serve static files
    http.Handle("/", http.FileServer(http.Dir("./static/")))
    
    log.Println("Dashboard server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```plaintext
### Example 3: Automated Error Monitoring

```go
package main

import (
    "database/sql"
    "log"
    "time"
    "email_sender/development/managers/error-manager"
)

type ErrorMonitor struct {
    analyzer     *errormanager.PatternAnalyzer
    generator    *errormanager.ReportGenerator
    alertChannel chan Alert
}

type Alert struct {
    Type        string
    Severity    string
    Message     string
    Timestamp   time.Time
    Data        interface{}
}

func NewErrorMonitor(db *sql.DB) *ErrorMonitor {
    analyzer := errormanager.NewPatternAnalyzer(db)
    generator := errormanager.NewReportGenerator(analyzer)
    
    return &ErrorMonitor{
        analyzer:     analyzer,
        generator:    generator,
        alertChannel: make(chan Alert, 100),
    }
}

func (em *ErrorMonitor) Start() {
    // Start alert processor
    go em.processAlerts()
    
    // Start monitoring ticker
    ticker := time.NewTicker(5 * time.Minute)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            em.checkErrorPatterns()
            em.checkFrequencyThresholds()
            em.checkCorrelations()
        }
    }
}

func (em *ErrorMonitor) checkErrorPatterns() {
    patterns, err := em.analyzer.AnalyzeErrorPatterns()
    if err != nil {
        log.Printf("Pattern analysis failed: %v", err)
        return
    }
    
    for _, pattern := range patterns {
        // Check for high frequency patterns
        if pattern.Frequency > 50 && 
           time.Since(pattern.LastOccurred) < 10*time.Minute {
            em.alertChannel <- Alert{
                Type:      "high_frequency",
                Severity:  "warning",
                Message:   fmt.Sprintf("High frequency error detected: %s:%s (%d occurrences)", 
                           pattern.Module, pattern.ErrorCode, pattern.Frequency),
                Timestamp: time.Now(),
                Data:      pattern,
            }
        }
        
        // Check for critical errors
        if pattern.Severity == "critical" && pattern.Frequency > 1 {
            em.alertChannel <- Alert{
                Type:      "critical_error",
                Severity:  "critical",
                Message:   fmt.Sprintf("Multiple critical errors: %s:%s", 
                           pattern.Module, pattern.ErrorCode),
                Timestamp: time.Now(),
                Data:      pattern,
            }
        }
    }
}

func (em *ErrorMonitor) checkFrequencyThresholds() {
    metrics, err := em.analyzer.CreateFrequencyMetrics()
    if err != nil {
        log.Printf("Metrics creation failed: %v", err)
        return
    }
    
    for module, errorCodes := range metrics {
        totalErrors := 0
        for _, frequency := range errorCodes {
            totalErrors += frequency
        }
        
        if totalErrors > 100 { // Threshold for module
            em.alertChannel <- Alert{
                Type:      "module_threshold",
                Severity:  "warning",
                Message:   fmt.Sprintf("Module %s exceeded error threshold (%d errors)", 
                           module, totalErrors),
                Timestamp: time.Now(),
                Data:      map[string]interface{}{
                    "module": module,
                    "total_errors": totalErrors,
                    "error_codes": errorCodes,
                },
            }
        }
    }
}

func (em *ErrorMonitor) checkCorrelations() {
    correlations, err := em.analyzer.IdentifyTemporalCorrelations(30 * time.Minute)
    if err != nil {
        log.Printf("Correlation analysis failed: %v", err)
        return
    }
    
    for _, corr := range correlations {
        if corr.Correlation > 0.8 && corr.OccurrenceGap < 5*time.Minute {
            em.alertChannel <- Alert{
                Type:      "high_correlation",
                Severity:  "info",
                Message:   fmt.Sprintf("High correlation detected: %s:%s ↔ %s:%s (%.2f)", 
                           corr.Module1, corr.ErrorCode1, 
                           corr.Module2, corr.ErrorCode2, corr.Correlation),
                Timestamp: time.Now(),
                Data:      corr,
            }
        }
    }
}

func (em *ErrorMonitor) processAlerts() {
    for alert := range em.alertChannel {
        switch alert.Severity {
        case "critical":
            em.sendCriticalAlert(alert)
        case "warning":
            em.sendWarningAlert(alert)
        case "info":
            em.logInfoAlert(alert)
        }
    }
}

func (em *ErrorMonitor) sendCriticalAlert(alert Alert) {
    log.Printf("🚨 CRITICAL ALERT: %s", alert.Message)
    // Send to PagerDuty, Slack, email, etc.
}

func (em *ErrorMonitor) sendWarningAlert(alert Alert) {
    log.Printf("⚠️  WARNING: %s", alert.Message)
    // Send to monitoring dashboard, Slack, etc.
}

func (em *ErrorMonitor) logInfoAlert(alert Alert) {
    log.Printf("ℹ️  INFO: %s", alert.Message)
    // Log to monitoring system
}

func main() {
    // Database connection
    db, err := sql.Open("postgres", 
        "host=localhost port=5432 user=postgres password=postgres dbname=email_sender_errors sslmode=disable")
    if err != nil {
        log.Fatal("Database connection failed:", err)
    }
    defer db.Close()
    
    // Create and start monitor
    monitor := NewErrorMonitor(db)
    log.Println("Starting error monitor...")
    monitor.Start()
}
```plaintext
---

## Integration Examples

### Example 4: Middleware Integration

```go
package main

import (
    "net/http"
    "time"
    "github.com/google/uuid"
    "email_sender/development/managers/error-manager"
)

func errorMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if err := recover(); err != nil {
                // Create error entry for panic
                entry := errormanager.ErrorEntry{
                    ID:             uuid.New().String(),
                    Timestamp:      time.Now(),
                    Message:        fmt.Sprintf("Panic recovered: %v", err),
                    Module:         "http-server",
                    ErrorCode:      "HTTP_PANIC_001",
                    ManagerContext: fmt.Sprintf("URL: %s, Method: %s", r.URL.Path, r.Method),
                    Severity:       "critical",
                    StackTrace:     string(debug.Stack()),
                }
                
                if validationErr := errormanager.ValidateErrorEntry(entry); validationErr == nil {
                    errormanager.CatalogError(entry)
                }
                
                http.Error(w, "Internal Server Error", http.StatusInternalServerError)
            }
        }()
        
        next.ServeHTTP(w, r)
    })
}

func main() {
    // Initialize error manager
    errormanager.InitializeLogger()
    
    mux := http.NewServeMux()
    mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello, World!"))
    })
    
    // Apply error middleware
    handler := errorMiddleware(mux)
    
    log.Println("Server starting on :8080")
    log.Fatal(http.ListenAndServe(":8080", handler))
}
```plaintext
This comprehensive user guide provides everything needed to effectively use the Error Manager package, from basic setup to advanced pattern analysis and monitoring.
