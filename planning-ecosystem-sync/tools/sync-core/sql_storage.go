package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"time"

	_ "github.com/go-sql-driver/mysql" // MySQL driver
	_ "github.com/lib/pq"              // PostgreSQL driver
	_ "github.com/mattn/go-sqlite3"    // SQLite driver
	_ "modernc.org/sqlite"             // Alternative SQLite driver
)

// SQLStorage handles SQL database operations
type SQLStorage struct {
	db     *sql.DB
	logger *log.Logger
}

// DatabaseConfig holds database connection configuration
type DatabaseConfig struct {
	Driver     string `yaml:"driver"`     // "postgres", "mysql", "sqlite3"
	Connection string `yaml:"connection"` // connection string
}

// NewSQLStorage creates a new SQL storage instance
func NewSQLStorage(config DatabaseConfig) (*SQLStorage, error) {
	db, err := sql.Open(config.Driver, config.Connection)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	storage := &SQLStorage{
		db:     db,
		logger: log.Default(),
	}

	// Initialize tables
	if err := storage.initializeTables(); err != nil {
		return nil, fmt.Errorf("failed to initialize tables: %w", err)
	}

	return storage, nil
}

// initializeTables creates necessary database tables if they don't exist
func (s *SQLStorage) initializeTables() error {
	s.logger.Printf("🔧 Initializing database tables")

	queries := []string{
		// Plans table
		`CREATE TABLE IF NOT EXISTS plans (
			id VARCHAR(255) PRIMARY KEY,
			title VARCHAR(500) NOT NULL,
			version VARCHAR(50),
			file_path VARCHAR(1000) UNIQUE NOT NULL,
			description TEXT,
			progression DECIMAL(5,2) DEFAULT 0.00,
			task_count INTEGER DEFAULT 0,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			metadata_json TEXT
		)`,

		// Tasks table
		`CREATE TABLE IF NOT EXISTS tasks (
			id VARCHAR(255) PRIMARY KEY,
			plan_id VARCHAR(255) NOT NULL,
			title VARCHAR(500) NOT NULL,
			description TEXT,
			status VARCHAR(50) DEFAULT 'pending',
			phase VARCHAR(200),
			level INTEGER DEFAULT 1,
			priority VARCHAR(50) DEFAULT 'medium',
			completed BOOLEAN DEFAULT FALSE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			dependencies_json TEXT,
			FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE CASCADE
		)`,

		// Sync logs table for tracking synchronization history
		`CREATE TABLE IF NOT EXISTS sync_logs (
			id SERIAL PRIMARY KEY,
			plan_id VARCHAR(255),
			operation VARCHAR(100) NOT NULL,
			status VARCHAR(50) NOT NULL,
			message TEXT,
			execution_time_ms INTEGER,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			FOREIGN KEY (plan_id) REFERENCES plans(id) ON DELETE SET NULL
		)`,

		// Create indexes for better performance
		`CREATE INDEX IF NOT EXISTS idx_plans_file_path ON plans(file_path)`,
		`CREATE INDEX IF NOT EXISTS idx_tasks_plan_id ON tasks(plan_id)`,
		`CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status)`,
		`CREATE INDEX IF NOT EXISTS idx_sync_logs_plan_id ON sync_logs(plan_id)`,
		`CREATE INDEX IF NOT EXISTS idx_sync_logs_created_at ON sync_logs(created_at)`,
	}

	for _, query := range queries {
		if _, err := s.db.Exec(query); err != nil {
			return fmt.Errorf("failed to execute query: %w\nQuery: %s", err, query)
		}
	}

	s.logger.Printf("✅ Database tables initialized successfully")
	return nil
}

// StorePlan stores a plan and its tasks in the SQL database
func (s *SQLStorage) StorePlan(plan *DynamicPlan) error {
	s.logger.Printf("💾 Storing plan in SQL database: %s", plan.ID)

	// Validate required fields
	if plan.ID == "" {
		return fmt.Errorf("plan ID cannot be empty")
	}
	if plan.Metadata.Title == "" {
		return fmt.Errorf("plan title cannot be empty")
	}

	// Begin transaction
	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback() // Will be ignored if tx.Commit() is called

	// Serialize metadata as JSON
	metadataJSON, err := json.Marshal(plan.Metadata)
	if err != nil {
		return fmt.Errorf("failed to serialize metadata: %w", err)
	}

	// Insert or update plan
	planQuery := `
		INSERT INTO plans (id, title, version, file_path, description, progression, task_count, created_at, updated_at, metadata_json)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		ON CONFLICT (id) DO UPDATE SET
			title = EXCLUDED.title,
			version = EXCLUDED.version,
			file_path = EXCLUDED.file_path,
			description = EXCLUDED.description,
			progression = EXCLUDED.progression,
			task_count = EXCLUDED.task_count,
			updated_at = EXCLUDED.updated_at,
			metadata_json = EXCLUDED.metadata_json
	`

	_, err = tx.Exec(planQuery,
		plan.ID,
		plan.Metadata.Title,
		plan.Metadata.Version,
		plan.Metadata.FilePath,
		plan.Metadata.Description,
		plan.Metadata.Progression,
		len(plan.Tasks),
		plan.CreatedAt,
		plan.UpdatedAt,
		string(metadataJSON),
	)
	if err != nil {
		return fmt.Errorf("failed to insert/update plan: %w", err)
	}

	// Delete existing tasks for this plan
	if _, err := tx.Exec("DELETE FROM tasks WHERE plan_id = $1", plan.ID); err != nil {
		return fmt.Errorf("failed to delete existing tasks: %w", err)
	}

	// Insert tasks
	taskQuery := `
		INSERT INTO tasks (id, plan_id, title, description, status, phase, level, priority, completed, created_at, updated_at, dependencies_json)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
	`

	for _, task := range plan.Tasks {
		// Generate task ID if not provided
		if task.ID == "" {
			task.ID = fmt.Sprintf("%s_task_%d", plan.ID, time.Now().UnixNano())
		}

		// Serialize dependencies as JSON
		dependenciesJSON, err := json.Marshal(task.Dependencies)
		if err != nil {
			return fmt.Errorf("failed to serialize task dependencies: %w", err)
		}

		_, err = tx.Exec(taskQuery,
			task.ID,
			plan.ID,
			task.Title,
			task.Description,
			task.Status,
			task.Phase,
			task.Level,
			task.Priority,
			task.Completed,
			task.CreatedAt,
			task.UpdatedAt,
			string(dependenciesJSON),
		)
		if err != nil {
			return fmt.Errorf("failed to insert task %s: %w", task.ID, err)
		}
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	// Log successful storage
	s.logSyncOperation(plan.ID, "store_plan", "success", fmt.Sprintf("Stored plan with %d tasks", len(plan.Tasks)), 0)

	s.logger.Printf("✅ Successfully stored plan: %s", plan.ID)
	return nil
}

// GetPlan retrieves a plan from the SQL database
func (s *SQLStorage) GetPlan(planID string) (*DynamicPlan, error) {
	s.logger.Printf("📖 Retrieving plan from SQL database: %s", planID)

	// Get plan data
	planQuery := `
		SELECT id, title, version, file_path, description, progression, created_at, updated_at, metadata_json
		FROM plans WHERE id = $1
	`

	var plan DynamicPlan
	var metadataJSON string

	err := s.db.QueryRow(planQuery, planID).Scan(
		&plan.ID,
		&plan.Metadata.Title,
		&plan.Metadata.Version,
		&plan.Metadata.FilePath,
		&plan.Metadata.Description,
		&plan.Metadata.Progression,
		&plan.CreatedAt,
		&plan.UpdatedAt,
		&metadataJSON,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("plan not found: %s", planID)
		}
		return nil, fmt.Errorf("failed to query plan: %w", err)
	}

	// Parse metadata JSON
	if err := json.Unmarshal([]byte(metadataJSON), &plan.Metadata); err != nil {
		return nil, fmt.Errorf("failed to parse metadata JSON: %w", err)
	}

	// Get tasks
	tasksQuery := `
		SELECT id, title, description, status, phase, level, priority, completed, created_at, updated_at, dependencies_json
		FROM tasks WHERE plan_id = $1 ORDER BY level, created_at
	`

	rows, err := s.db.Query(tasksQuery, planID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tasks: %w", err)
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		var dependenciesJSON string

		err := rows.Scan(
			&task.ID,
			&task.Title,
			&task.Description,
			&task.Status,
			&task.Phase,
			&task.Level,
			&task.Priority,
			&task.Completed,
			&task.CreatedAt,
			&task.UpdatedAt,
			&dependenciesJSON,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan task: %w", err)
		}

		// Parse dependencies JSON
		if err := json.Unmarshal([]byte(dependenciesJSON), &task.Dependencies); err != nil {
			return nil, fmt.Errorf("failed to parse dependencies JSON: %w", err)
		}

		tasks = append(tasks, task)
	}

	plan.Tasks = tasks

	s.logger.Printf("✅ Successfully retrieved plan: %s (%d tasks)", planID, len(tasks))
	return &plan, nil
}

// logSyncOperation logs a synchronization operation
func (s *SQLStorage) logSyncOperation(planID, operation, status, message string, executionTimeMS int) {
	query := `
		INSERT INTO sync_logs (plan_id, operation, status, message, execution_time_ms)
		VALUES ($1, $2, $3, $4, $5)
	`

	_, err := s.db.Exec(query, planID, operation, status, message, executionTimeMS)
	if err != nil {
		s.logger.Printf("⚠️  Failed to log sync operation: %v", err)
	}
}

// GetSyncStats returns synchronization statistics
func (s *SQLStorage) GetSyncStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Total plans count
	var planCount int
	err := s.db.QueryRow("SELECT COUNT(*) FROM plans").Scan(&planCount)
	if err != nil {
		return nil, fmt.Errorf("failed to get plan count: %w", err)
	}
	stats["total_plans"] = planCount

	// Total tasks count
	var taskCount int
	err = s.db.QueryRow("SELECT COUNT(*) FROM tasks").Scan(&taskCount)
	if err != nil {
		return nil, fmt.Errorf("failed to get task count: %w", err)
	}
	stats["total_tasks"] = taskCount

	// Completed tasks count
	var completedTaskCount int
	err = s.db.QueryRow("SELECT COUNT(*) FROM tasks WHERE completed = true").Scan(&completedTaskCount)
	if err != nil {
		return nil, fmt.Errorf("failed to get completed task count: %w", err)
	}
	stats["completed_tasks"] = completedTaskCount

	// Recent sync operations
	var recentSyncs int
	err = s.db.QueryRow("SELECT COUNT(*) FROM sync_logs WHERE created_at > NOW() - INTERVAL '24 hours'").Scan(&recentSyncs)
	if err != nil {
		// Try SQLite compatible syntax
		err = s.db.QueryRow("SELECT COUNT(*) FROM sync_logs WHERE created_at > datetime('now', '-24 hours')").Scan(&recentSyncs)
		if err != nil {
			s.logger.Printf("⚠️  Failed to get recent sync count: %v", err)
			recentSyncs = 0
		}
	}
	stats["recent_syncs_24h"] = recentSyncs

	return stats, nil
}

// Close closes the database connection
func (s *SQLStorage) Close() error {
	s.logger.Printf("🔌 Closing SQL database connection")
	return s.db.Close()
}
