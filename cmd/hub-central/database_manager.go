package main

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"time"

	_ "github.com/go-sql-driver/mysql" // MySQL driver
	_ "github.com/lib/pq"              // PostgreSQL driver
	_ "github.com/mattn/go-sqlite3"    // SQLite driver
	"go.uber.org/zap"
)

// DatabaseManager manages database connections and operations
type DatabaseManager struct {
	connections map[string]*sql.DB
	pool        *ConnectionPool
	migrations  *MigrationManager
	backup      *BackupManager
	config      *DatabaseConfig
	logger      *zap.Logger
	mu          sync.RWMutex
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Primary   *DBConnConfig            `yaml:"primary"`
	Replicas  map[string]*DBConnConfig `yaml:"replicas"`
	Pool      *PoolConfig              `yaml:"pool"`
	Migration *MigrationConfig         `yaml:"migration"`
	Backup    *BackupConfig            `yaml:"backup"`
}

// DBConnConfig represents a single database connection configuration
type DBConnConfig struct {
	Driver   string `yaml:"driver"`
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Database string `yaml:"database"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
	SSLMode  string `yaml:"ssl_mode"`
	Timeout  int    `yaml:"timeout"`
}

// PoolConfig holds connection pool settings
type PoolConfig struct {
	MaxOpenConns    int           `yaml:"max_open_conns"`
	MaxIdleConns    int           `yaml:"max_idle_conns"`
	ConnMaxLifetime time.Duration `yaml:"conn_max_lifetime"`
	ConnMaxIdleTime time.Duration `yaml:"conn_max_idle_time"`
}

// ConnectionPool manages database connection pooling
type ConnectionPool struct {
	pools map[string]*sql.DB
	mu    sync.RWMutex
}

// MigrationManager handles database migrations
type MigrationManager struct {
	migrations []Migration
	db         *sql.DB
}

// Migration represents a database migration
type Migration struct {
	Version     int
	Description string
	UpSQL       string
	DownSQL     string
}

// BackupManager handles database backups
type BackupManager struct {
	config *BackupConfig
	logger *zap.Logger
}

// BackupConfig holds backup configuration
type BackupConfig struct {
	Schedule    string `yaml:"schedule"`
	Location    string `yaml:"location"`
	Retention   int    `yaml:"retention_days"`
	Compression bool   `yaml:"compression"`
}

// Query represents a database query
type Query struct {
	Database string
	SQL      string
	Args     []interface{}
	Timeout  time.Duration
}

// Result represents query results
type Result struct {
	Rows         *sql.Rows
	RowsAffected int64
	LastInsertID int64
	Error        error
}

// NewDatabaseManager creates a new database manager
func NewDatabaseManager(config *DatabaseConfig) *DatabaseManager {
	logger, _ := zap.NewProduction()
	
	return &DatabaseManager{
		connections: make(map[string]*sql.DB),
		pool:        &ConnectionPool{pools: make(map[string]*sql.DB)},
		migrations:  &MigrationManager{},
		backup:      &BackupManager{config: config.Backup, logger: logger},
		config:      config,
		logger:      logger,
	}
}

// Start initializes the database manager
func (dm *DatabaseManager) Start(ctx context.Context) error {
	dm.logger.Info("Starting Database Manager")
	
	// Initialize primary connection
	if err := dm.initializePrimaryConnection(); err != nil {
		return fmt.Errorf("failed to initialize primary connection: %w", err)
	}
	
	// Initialize replica connections
	if err := dm.initializeReplicaConnections(); err != nil {
		dm.logger.Warn("Failed to initialize some replica connections", zap.Error(err))
	}
	
	// Run migrations
	if err := dm.runMigrations(); err != nil {
		return fmt.Errorf("failed to run migrations: %w", err)
	}
	
	dm.logger.Info("Database Manager started successfully")
	return nil
}

// Stop shuts down the database manager
func (dm *DatabaseManager) Stop(ctx context.Context) error {
	dm.logger.Info("Stopping Database Manager")
	
	dm.mu.Lock()
	defer dm.mu.Unlock()
	
	for name, conn := range dm.connections {
		if err := conn.Close(); err != nil {
			dm.logger.Error("Failed to close connection", zap.String("name", name), zap.Error(err))
		}
	}
	
	dm.logger.Info("Database Manager stopped")
	return nil
}

// Health returns the health status of the database manager
func (dm *DatabaseManager) Health() HealthStatus {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	
	details := make(map[string]interface{})
	overallHealthy := true
	
	for name, conn := range dm.connections {
		if err := conn.Ping(); err != nil {
			details[name] = "unhealthy: " + err.Error()
			overallHealthy = false
		} else {
			details[name] = "healthy"
		}
	}
	
	status := "healthy"
	message := "All database connections are healthy"
	
	if !overallHealthy {
		status = "unhealthy"
		message = "Some database connections are unhealthy"
	}
	
	return HealthStatus{
		Status:    status,
		Message:   message,
		Timestamp: time.Now(),
		Details:   details,
	}
}

// Metrics returns database metrics
func (dm *DatabaseManager) Metrics() map[string]interface{} {
	dm.mu.RLock()
	defer dm.mu.RUnlock()
	
	metrics := make(map[string]interface{})
	
	for name, conn := range dm.connections {
		stats := conn.Stats()
		metrics[name] = map[string]interface{}{
			"open_connections":     stats.OpenConnections,
			"in_use":              stats.InUse,
			"idle":                stats.Idle,
			"wait_count":          stats.WaitCount,
			"wait_duration":       stats.WaitDuration.String(),
			"max_idle_closed":     stats.MaxIdleClosed,
			"max_idle_time_closed": stats.MaxIdleTimeClosed,
			"max_lifetime_closed": stats.MaxLifetimeClosed,
		}
	}
	
	return metrics
}

// GetName returns the manager name
func (dm *DatabaseManager) GetName() string {
	return "database"
}

// ExecuteQuery executes a database query
func (dm *DatabaseManager) ExecuteQuery(ctx context.Context, query Query) (*Result, error) {
	conn := dm.pool.Get(query.Database)
	if conn == nil {
		return nil, fmt.Errorf("no connection available for database: %s", query.Database)
	}
	
	// Set timeout if specified
	if query.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, query.Timeout)
		defer cancel()
	}
	
	// Execute query
	result, err := conn.ExecContext(ctx, query.SQL, query.Args...)
	if err != nil {
		return &Result{Error: err}, err
	}
	
	rowsAffected, _ := result.RowsAffected()
	lastInsertID, _ := result.LastInsertId()
	
	return &Result{
		RowsAffected: rowsAffected,
		LastInsertID: lastInsertID,
	}, nil
}

// QueryRows executes a query that returns rows
func (dm *DatabaseManager) QueryRows(ctx context.Context, query Query) (*Result, error) {
	conn := dm.pool.Get(query.Database)
	if conn == nil {
		return nil, fmt.Errorf("no connection available for database: %s", query.Database)
	}
	
	// Set timeout if specified
	if query.Timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, query.Timeout)
		defer cancel()
	}
	
	rows, err := conn.QueryContext(ctx, query.SQL, query.Args...)
	if err != nil {
		return &Result{Error: err}, err
	}
	
	return &Result{Rows: rows}, nil
}

// Get retrieves a connection from the pool
func (cp *ConnectionPool) Get(database string) *sql.DB {
	cp.mu.RLock()
	defer cp.mu.RUnlock()
	
	return cp.pools[database]
}

// initializePrimaryConnection sets up the primary database connection
func (dm *DatabaseManager) initializePrimaryConnection() error {
	if dm.config.Primary == nil {
		return fmt.Errorf("primary database configuration is required")
	}
	
	conn, err := dm.createConnection(dm.config.Primary)
	if err != nil {
		return fmt.Errorf("failed to create primary connection: %w", err)
	}
	
	dm.connections["primary"] = conn
	dm.pool.pools["primary"] = conn
	
	return nil
}

// initializeReplicaConnections sets up replica database connections
func (dm *DatabaseManager) initializeReplicaConnections() error {
	for name, config := range dm.config.Replicas {
		conn, err := dm.createConnection(config)
		if err != nil {
			dm.logger.Error("Failed to create replica connection", 
				zap.String("name", name), zap.Error(err))
			continue
		}
		
		dm.connections[name] = conn
		dm.pool.pools[name] = conn
	}
	
	return nil
}

// createConnection creates a new database connection
func (dm *DatabaseManager) createConnection(config *DBConnConfig) (*sql.DB, error) {
	dsn := dm.buildDSN(config)
	
	conn, err := sql.Open(config.Driver, dsn)
	if err != nil {
		return nil, err
	}
	
	// Configure connection pool
	if dm.config.Pool != nil {
		conn.SetMaxOpenConns(dm.config.Pool.MaxOpenConns)
		conn.SetMaxIdleConns(dm.config.Pool.MaxIdleConns)
		conn.SetConnMaxLifetime(dm.config.Pool.ConnMaxLifetime)
		conn.SetConnMaxIdleTime(dm.config.Pool.ConnMaxIdleTime)
	}
	
	// Test connection
	if err := conn.Ping(); err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}
	
	return conn, nil
}

// buildDSN builds a data source name from configuration
func (dm *DatabaseManager) buildDSN(config *DBConnConfig) string {
	switch config.Driver {
	case "postgres":
		return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
			config.Host, config.Port, config.Username, config.Password, 
			config.Database, config.SSLMode)
	case "mysql":
		return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s",
			config.Username, config.Password, config.Host, config.Port, config.Database)
	case "sqlite3":
		return config.Database
	default:
		return ""
	}
}

// runMigrations executes pending database migrations
func (dm *DatabaseManager) runMigrations() error {
	if dm.config.Migration == nil {
		return nil
	}
	
	primaryConn := dm.connections["primary"]
	if primaryConn == nil {
		return fmt.Errorf("primary connection required for migrations")
	}
	
	dm.migrations.db = primaryConn
	
	// Create migrations table if it doesn't exist
	if err := dm.createMigrationsTable(); err != nil {
		return err
	}
	
	// Run pending migrations
	return dm.runPendingMigrations()
}

// createMigrationsTable creates the migrations tracking table
func (dm *DatabaseManager) createMigrationsTable() error {
	query := `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version INTEGER PRIMARY KEY,
			description TEXT,
			applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`
	
	_, err := dm.migrations.db.Exec(query)
	return err
}

// runPendingMigrations executes all pending migrations
func (dm *DatabaseManager) runPendingMigrations() error {
	for _, migration := range dm.migrations.migrations {
		if applied, err := dm.isMigrationApplied(migration.Version); err != nil {
			return err
		} else if applied {
			continue
		}
		
		if err := dm.applyMigration(migration); err != nil {
			return fmt.Errorf("failed to apply migration %d: %w", migration.Version, err)
		}
		
		dm.logger.Info("Applied migration", 
			zap.Int("version", migration.Version),
			zap.String("description", migration.Description))
	}
	
	return nil
}

// isMigrationApplied checks if a migration has been applied
func (dm *DatabaseManager) isMigrationApplied(version int) (bool, error) {
	var count int
	err := dm.migrations.db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version = ?", version).Scan(&count)
	return count > 0, err
}

// applyMigration applies a single migration
func (dm *DatabaseManager) applyMigration(migration Migration) error {
	tx, err := dm.migrations.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	
	// Execute migration SQL
	if _, err := tx.Exec(migration.UpSQL); err != nil {
		return err
	}
	
	// Record migration
	if _, err := tx.Exec("INSERT INTO schema_migrations (version, description) VALUES (?, ?)",
		migration.Version, migration.Description); err != nil {
		return err
	}
	
	return tx.Commit()
}

// MigrationConfig holds migration settings
type MigrationConfig struct {
	Enabled bool   `yaml:"enabled"`
	Path    string `yaml:"path"`
}
