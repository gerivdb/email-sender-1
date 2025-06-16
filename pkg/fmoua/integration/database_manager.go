// Package integration provides DatabaseManager implementation for FMOUA Phase 2
package integration

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"

	"email_sender/pkg/fmoua/types"
)

// Database interface for database operations
type Database interface {
	Connect() error
	Close() error
	Ping() error
	Query(query string, args ...interface{}) (*sql.Rows, error)
	Exec(query string, args ...interface{}) (sql.Result, error)
	Begin() (*sql.Tx, error)
	GetStats() DatabaseStats
}

// ConnectionPoolManager interface for managing connection pools
type ConnectionPoolManager interface {
	GetConnection(name string) (Database, error)
	ReleaseConnection(name string, db Database) error
	GetStats() map[string]PoolStats
	CloseAll() error
}

// SchemaMigrator interface for database migrations
type SchemaMigrator interface {
	ApplyMigrations(db Database) error
	GetMigrationStatus(db Database) ([]MigrationStatus, error)
	CreateMigrationTable(db Database) error
}

// DatabaseManager manages database operations with multiple backends
type DatabaseManager struct {
	*BaseManager
	config      types.DatabaseManagerConfig
	connections map[string]Database
	poolManager ConnectionPoolManager
	migrator    SchemaMigrator
	mu          sync.RWMutex
}

// DatabaseStats represents database statistics
type DatabaseStats struct {
	OpenConnections   int           `json:"open_connections"`
	InUseConnections  int           `json:"in_use_connections"`
	IdleConnections   int           `json:"idle_connections"`
	WaitCount         int64         `json:"wait_count"`
	WaitDuration      time.Duration `json:"wait_duration"`
	MaxIdleClosed     int64         `json:"max_idle_closed"`
	MaxIdleTimeClosed int64         `json:"max_idle_time_closed"`
	MaxLifetimeClosed int64         `json:"max_lifetime_closed"`
}

// PoolStats represents connection pool statistics
type PoolStats struct {
	Active    int           `json:"active"`
	Idle      int           `json:"idle"`
	Total     int           `json:"total"`
	MaxActive int           `json:"max_active"`
	MaxIdle   int           `json:"max_idle"`
	WaitTime  time.Duration `json:"wait_time"`
	WaitCount int64         `json:"wait_count"`
}

// MigrationStatus represents migration status
type MigrationStatus struct {
	Version   string    `json:"version"`
	Applied   bool      `json:"applied"`
	AppliedAt time.Time `json:"applied_at,omitempty"`
	Checksum  string    `json:"checksum"`
}

// NewDatabaseManager creates a new DatabaseManager instance
func NewDatabaseManager(id string, config types.ManagerConfig, logger *zap.Logger, metrics MetricsCollector) (*DatabaseManager, error) {
	baseManager := NewBaseManager(id, config, logger, metrics)

	// Parse database-specific config
	dbConfig, err := parseDatabaseManagerConfig(config.Config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	dm := &DatabaseManager{
		BaseManager: baseManager,
		config:      dbConfig,
		connections: make(map[string]Database),
		poolManager: NewDefaultConnectionPoolManager(dbConfig.PoolConfig),
		migrator:    NewDefaultSchemaMigrator(dbConfig.Migration),
	}

	return dm, nil
}

// Initialize initializes the database manager with connections
func (dm *DatabaseManager) Initialize(config types.ManagerConfig) error {
	if err := dm.BaseManager.Initialize(config); err != nil {
		return err
	}

	// Initialize database connections
	for name, dbConfig := range dm.config.Connections {
		db, err := dm.createDatabase(name, dbConfig)
		if err != nil {
			dm.LogError("Failed to create database connection", err,
				zap.String("database", name))
			continue
		}

		if err := db.Connect(); err != nil {
			dm.LogError("Failed to connect to database", err,
				zap.String("database", name))
			continue
		}

		if err := db.Ping(); err != nil {
			dm.LogError("Database ping failed", err,
				zap.String("database", name))
			continue
		}

		dm.mu.Lock()
		dm.connections[name] = db
		dm.mu.Unlock()

		dm.LogInfo("Database connection established",
			zap.String("database", name),
			zap.String("type", dbConfig.Type))

		// Apply migrations if enabled
		if dm.config.Migration.Enabled && dm.config.Migration.AutoMigrate {
			if err := dm.migrator.ApplyMigrations(db); err != nil {
				dm.LogError("Failed to apply migrations", err,
					zap.String("database", name))
			}
		}
	}

	if len(dm.connections) == 0 {
		return fmt.Errorf("no valid database connections configured")
	}

	return nil
}

// Execute processes a database task
func (dm *DatabaseManager) Execute(ctx context.Context, task types.Task) (types.Result, error) {
	startTime := time.Now()

	result := types.Result{
		TaskID:    task.ID,
		Timestamp: startTime,
	}

	dm.LogInfo("Executing database task",
		zap.String("task_id", task.ID),
		zap.String("task_type", task.Type))

	switch task.Type {
	case "query":
		data, err := dm.handleQuery(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		} else {
			result.Data = map[string]interface{}{"query_result": data}
		}

	case "execute":
		affected, err := dm.handleExecute(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		} else {
			result.Data = map[string]interface{}{"rows_affected": affected}
		}

	case "migrate":
		err := dm.handleMigrate(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "backup":
		err := dm.handleBackup(ctx, task)
		result.Success = err == nil
		if err != nil {
			result.Error = err.Error()
		}

	case "get_stats":
		stats := dm.handleGetStats(ctx, task)
		result.Success = true
		result.Data = map[string]interface{}{"database_stats": stats}

	default:
		err := fmt.Errorf("unsupported task type: %s", task.Type)
		result.Success = false
		result.Error = err.Error()
	}

	result.Duration = time.Since(startTime)

	// Update metrics
	dm.metrics.Histogram("database_task_duration",
		float64(result.Duration.Milliseconds()),
		map[string]string{
			"task_type": task.Type,
			"success":   fmt.Sprintf("%t", result.Success),
		})

	return result, nil
}

// Start starts the database manager
func (dm *DatabaseManager) Start() error {
	if err := dm.BaseManager.Start(); err != nil {
		return err
	}

	dm.LogInfo("Database manager started",
		zap.Int("connections", len(dm.connections)))

	return nil
}

// Stop stops the database manager
func (dm *DatabaseManager) Stop() error {
	dm.LogInfo("Stopping database manager")

	// Close all database connections
	dm.mu.Lock()
	for name, db := range dm.connections {
		if err := db.Close(); err != nil {
			dm.LogError("Failed to close database connection", err,
				zap.String("database", name))
		}
	}
	dm.mu.Unlock()

	// Close connection pool
	if err := dm.poolManager.CloseAll(); err != nil {
		dm.LogError("Failed to close connection pool", err)
	}

	return dm.BaseManager.Stop()
}

// GetType returns the manager type
func (dm *DatabaseManager) GetType() string {
	return "database"
}

// createDatabase creates a database connection based on configuration
func (dm *DatabaseManager) createDatabase(name string, config types.DatabaseConfig) (Database, error) {
	switch config.Type {
	case "postgresql":
		return NewPostgreSQLDatabase(config), nil
	case "mysql":
		return NewMySQLDatabase(config), nil
	case "mongodb":
		return NewMongoDatabase(config), nil
	default:
		return nil, fmt.Errorf("unsupported database type: %s", config.Type)
	}
}

// handleQuery handles query tasks
func (dm *DatabaseManager) handleQuery(ctx context.Context, task types.Task) (interface{}, error) {
	dbName, ok := task.Payload["database"].(string)
	if !ok {
		return nil, fmt.Errorf("database name not specified")
	}

	query, ok := task.Payload["query"].(string)
	if !ok {
		return nil, fmt.Errorf("query not specified")
	}

	dm.mu.RLock()
	db, exists := dm.connections[dbName]
	dm.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("database connection not found: %s", dbName)
	}

	rows, err := db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("query execution failed: %w", err)
	}
	defer rows.Close()

	// Convert rows to map for JSON serialization
	// This is a simplified implementation
	var results []map[string]interface{}
	columns, err := rows.Columns()
	if err != nil {
		return nil, fmt.Errorf("failed to get columns: %w", err)
	}

	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range columns {
			valuePtrs[i] = &values[i]
		}

		if err := rows.Scan(valuePtrs...); err != nil {
			return nil, fmt.Errorf("failed to scan row: %w", err)
		}

		row := make(map[string]interface{})
		for i, col := range columns {
			row[col] = values[i]
		}
		results = append(results, row)
	}

	return results, nil
}

// handleExecute handles execute tasks
func (dm *DatabaseManager) handleExecute(ctx context.Context, task types.Task) (int64, error) {
	dbName, ok := task.Payload["database"].(string)
	if !ok {
		return 0, fmt.Errorf("database name not specified")
	}

	query, ok := task.Payload["query"].(string)
	if !ok {
		return 0, fmt.Errorf("query not specified")
	}

	dm.mu.RLock()
	db, exists := dm.connections[dbName]
	dm.mu.RUnlock()

	if !exists {
		return 0, fmt.Errorf("database connection not found: %s", dbName)
	}

	result, err := db.Exec(query)
	if err != nil {
		return 0, fmt.Errorf("execute failed: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return 0, fmt.Errorf("failed to get rows affected: %w", err)
	}

	return rowsAffected, nil
}

// handleMigrate handles migration tasks
func (dm *DatabaseManager) handleMigrate(ctx context.Context, task types.Task) error {
	dbName, ok := task.Payload["database"].(string)
	if !ok {
		return fmt.Errorf("database name not specified")
	}

	dm.mu.RLock()
	db, exists := dm.connections[dbName]
	dm.mu.RUnlock()

	if !exists {
		return fmt.Errorf("database connection not found: %s", dbName)
	}

	return dm.migrator.ApplyMigrations(db)
}

// handleBackup handles backup tasks
func (dm *DatabaseManager) handleBackup(ctx context.Context, task types.Task) error {
	// Simplified backup implementation
	// In production, this would create actual database backups
	dm.LogInfo("Backup task executed (not implemented)")
	return nil
}

// handleGetStats handles statistics retrieval
func (dm *DatabaseManager) handleGetStats(ctx context.Context, task types.Task) map[string]interface{} {
	stats := make(map[string]interface{})

	dm.mu.RLock()
	for name, db := range dm.connections {
		stats[name] = db.GetStats()
	}
	dm.mu.RUnlock()

	// Add pool stats
	poolStats := dm.poolManager.GetStats()
	stats["pool"] = poolStats

	return stats
}

// parseDatabaseManagerConfig parses database manager configuration
func parseDatabaseManagerConfig(config map[string]interface{}) (types.DatabaseManagerConfig, error) {
	// Simplified parser - in production, use proper YAML/JSON parsing
	dbConfig := types.DatabaseManagerConfig{
		Connections: make(map[string]types.DatabaseConfig),
		PoolConfig: types.ConnectionPoolConfig{
			MaxOpen:         10,
			MaxIdle:         5,
			ConnMaxLifetime: time.Hour,
			ConnMaxIdleTime: time.Minute * 30,
		},
		Migration: types.MigrationConfig{
			Enabled:     false,
			TableName:   "migrations",
			AutoMigrate: false,
		},
		Backup: types.BackupConfig{
			Enabled:     false,
			Schedule:    "0 2 * * *",         // Daily at 2 AM
			Retention:   time.Hour * 24 * 30, // 30 days
			Compression: true,
		},
	}

	// Parse connections
	if connectionsData, ok := config["connections"].(map[string]interface{}); ok {
		for name, connData := range connectionsData {
			if connMap, ok := connData.(map[string]interface{}); ok {
				connConfig := types.DatabaseConfig{}

				if typ, ok := connMap["type"].(string); ok {
					connConfig.Type = typ
				}
				if host, ok := connMap["host"].(string); ok {
					connConfig.Host = host
				}
				if port, ok := connMap["port"].(float64); ok {
					connConfig.Port = int(port)
				}
				if database, ok := connMap["database"].(string); ok {
					connConfig.Database = database
				}
				if username, ok := connMap["username"].(string); ok {
					connConfig.Username = username
				}
				if password, ok := connMap["password"].(string); ok {
					connConfig.Password = password
				}

				dbConfig.Connections[name] = connConfig
			}
		}
	}

	return dbConfig, nil
}
