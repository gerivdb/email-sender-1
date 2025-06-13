package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	_ "github.com/lib/pq"

	"github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces"
)

// PostgreSQLStorageManager implements StorageManager interface with PostgreSQL backend
type PostgreSQLStorageManager struct {
	db     *sql.DB
	config *PostgreSQLConfig
}

// PostgreSQLConfig holds PostgreSQL connection configuration
type PostgreSQLConfig struct {
	Host     string
	Port     int
	Database string
	Username string
	Password string
	SSLMode  string
}

// NewPostgreSQLStorageManager creates a new PostgreSQL storage manager
func NewPostgreSQLStorageManager(config *PostgreSQLConfig) (*PostgreSQLStorageManager, error) {
	connStr := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host, config.Port, config.Username, config.Password, config.Database, config.SSLMode)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %v", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %v", err)
	}

	manager := &PostgreSQLStorageManager{
		db:     db,
		config: config,
	}

	// Initialize database schema
	if err := manager.initializeSchema(); err != nil {
		return nil, fmt.Errorf("failed to initialize database schema: %v", err)
	}

	return manager, nil
}

// initializeSchema creates the necessary database tables
func (s *PostgreSQLStorageManager) initializeSchema() error {
	schemas := []string{
		// Sessions table
		`CREATE TABLE IF NOT EXISTS sessions (
			id UUID PRIMARY KEY,
			scope VARCHAR(255) NOT NULL,
			status VARCHAR(50) NOT NULL,
			duration INTERVAL NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB
		)`,

		// Branches table
		`CREATE TABLE IF NOT EXISTS branches (
			id UUID PRIMARY KEY,
			session_id UUID REFERENCES sessions(id),
			name VARCHAR(255) NOT NULL,
			base_branch VARCHAR(255) NOT NULL,
			status VARCHAR(50) NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB,
			git_hash VARCHAR(255)
		)`,

		// Events table
		`CREATE TABLE IF NOT EXISTS branching_events (
			id UUID PRIMARY KEY,
			event_type VARCHAR(100) NOT NULL,
			source VARCHAR(255) NOT NULL,
			branch_id UUID REFERENCES branches(id),
			session_id UUID REFERENCES sessions(id),
			timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			payload JSONB,
			processed BOOLEAN DEFAULT FALSE
		)`,

		// Temporal snapshots table
		`CREATE TABLE IF NOT EXISTS temporal_snapshots (
			id UUID PRIMARY KEY,
			branch_id UUID REFERENCES branches(id) NOT NULL,
			timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			git_hash VARCHAR(255) NOT NULL,
			metadata JSONB,
			changes_summary TEXT
		)`,

		// Branch dimensions table
		`CREATE TABLE IF NOT EXISTS branch_dimensions (
			id UUID PRIMARY KEY,
			branch_id UUID REFERENCES branches(id) NOT NULL,
			dimension_name VARCHAR(255) NOT NULL,
			dimension_value VARCHAR(255) NOT NULL,
			weight FLOAT DEFAULT 1.0,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		)`,

		// Branch tags table
		`CREATE TABLE IF NOT EXISTS branch_tags (
			id UUID PRIMARY KEY,
			branch_id UUID REFERENCES branches(id) NOT NULL,
			tag_name VARCHAR(255) NOT NULL,
			tag_value VARCHAR(255),
			tag_type VARCHAR(100),
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		)`,

		// Quantum branches table
		`CREATE TABLE IF NOT EXISTS quantum_branches (
			id UUID PRIMARY KEY,
			name VARCHAR(255) NOT NULL,
			description TEXT,
			base_branch VARCHAR(255) NOT NULL,
			status VARCHAR(50) NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB
		)`,

		// Quantum approaches table
		`CREATE TABLE IF NOT EXISTS quantum_approaches (
			id UUID PRIMARY KEY,
			quantum_branch_id UUID REFERENCES quantum_branches(id) NOT NULL,
			approach_name VARCHAR(255) NOT NULL,
			branch_name VARCHAR(255) NOT NULL,
			strategy VARCHAR(255) NOT NULL,
			status VARCHAR(50) NOT NULL,
			score FLOAT DEFAULT 0.0,
			confidence FLOAT DEFAULT 0.0,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			completed_at TIMESTAMP WITH TIME ZONE,
			metadata JSONB
		)`,

		// Branching as code configurations table
		`CREATE TABLE IF NOT EXISTS branching_configs (
			id UUID PRIMARY KEY,
			name VARCHAR(255) NOT NULL,
			language VARCHAR(50) NOT NULL,
			content TEXT NOT NULL,
			version INTEGER DEFAULT 1,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			metadata JSONB
		)`,

		// Execution results table
		`CREATE TABLE IF NOT EXISTS execution_results (
			id UUID PRIMARY KEY,
			config_id UUID REFERENCES branching_configs(id) NOT NULL,
			execution_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
			success BOOLEAN NOT NULL,
			duration INTERVAL,
			branches_created JSONB,
			error_message TEXT,
			metadata JSONB
		)`,
	}

	// Create indexes for better query performance
	indexes := []string{
		"CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status)",
		"CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON sessions(created_at)",
		"CREATE INDEX IF NOT EXISTS idx_branches_session_id ON branches(session_id)",
		"CREATE INDEX IF NOT EXISTS idx_branches_status ON branches(status)",
		"CREATE INDEX IF NOT EXISTS idx_branches_name ON branches(name)",
		"CREATE INDEX IF NOT EXISTS idx_events_type ON branching_events(event_type)",
		"CREATE INDEX IF NOT EXISTS idx_events_timestamp ON branching_events(timestamp)",
		"CREATE INDEX IF NOT EXISTS idx_events_processed ON branching_events(processed)",
		"CREATE INDEX IF NOT EXISTS idx_snapshots_branch_id ON temporal_snapshots(branch_id)",
		"CREATE INDEX IF NOT EXISTS idx_snapshots_timestamp ON temporal_snapshots(timestamp)",
		"CREATE INDEX IF NOT EXISTS idx_dimensions_branch_id ON branch_dimensions(branch_id)",
		"CREATE INDEX IF NOT EXISTS idx_dimensions_name ON branch_dimensions(dimension_name)",
		"CREATE INDEX IF NOT EXISTS idx_tags_branch_id ON branch_tags(branch_id)",
		"CREATE INDEX IF NOT EXISTS idx_tags_name ON branch_tags(tag_name)",
		"CREATE INDEX IF NOT EXISTS idx_quantum_status ON quantum_branches(status)",
		"CREATE INDEX IF NOT EXISTS idx_approaches_quantum_id ON quantum_approaches(quantum_branch_id)",
		"CREATE INDEX IF NOT EXISTS idx_approaches_status ON quantum_approaches(status)",
		"CREATE INDEX IF NOT EXISTS idx_configs_name ON branching_configs(name)",
		"CREATE INDEX IF NOT EXISTS idx_configs_language ON branching_configs(language)",
		"CREATE INDEX IF NOT EXISTS idx_results_config_id ON execution_results(config_id)",
		"CREATE INDEX IF NOT EXISTS idx_results_success ON execution_results(success)",
	}

	// Execute schema creation
	for _, schema := range schemas {
		if _, err := s.db.Exec(schema); err != nil {
			return fmt.Errorf("failed to create table: %v", err)
		}
	}

	// Execute index creation
	for _, index := range indexes {
		if _, err := s.db.Exec(index); err != nil {
			return fmt.Errorf("failed to create index: %v", err)
		}
	}

	return nil
}

// SaveSession implements StorageManager interface
func (s *PostgreSQLStorageManager) SaveSession(ctx context.Context, session *interfaces.Session) error {
	query := `
		INSERT INTO sessions (id, scope, status, duration, created_at, updated_at, metadata)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (id) DO UPDATE SET
			scope = EXCLUDED.scope,
			status = EXCLUDED.status,
			duration = EXCLUDED.duration,
			updated_at = EXCLUDED.updated_at,
			metadata = EXCLUDED.metadata
	`

	metadataJSON, err := json.Marshal(session.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %v", err)
	}

	_, err = s.db.ExecContext(ctx, query,
		session.ID,
		session.Scope,
		session.Status,
		session.Duration,
		session.CreatedAt,
		session.UpdatedAt,
		metadataJSON,
	)

	return err
}

// GetSession implements StorageManager interface
func (s *PostgreSQLStorageManager) GetSession(ctx context.Context, sessionID string) (*interfaces.Session, error) {
	query := `
		SELECT id, scope, status, duration, created_at, updated_at, metadata
		FROM sessions
		WHERE id = $1
	`

	session := &interfaces.Session{}
	var metadataJSON []byte

	err := s.db.QueryRowContext(ctx, query, sessionID).Scan(
		&session.ID,
		&session.Scope,
		&session.Status,
		&session.Duration,
		&session.CreatedAt,
		&session.UpdatedAt,
		&metadataJSON,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("session not found: %s", sessionID)
		}
		return nil, err
	}

	if err := json.Unmarshal(metadataJSON, &session.Metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
	}

	return session, nil
}

// ListSessions implements StorageManager interface
func (s *PostgreSQLStorageManager) ListSessions(ctx context.Context, filters interfaces.SessionFilters) ([]*interfaces.Session, error) {
	query := `
		SELECT id, scope, status, duration, created_at, updated_at, metadata
		FROM sessions
		WHERE 1=1
	`
	args := []interface{}{}
	argIndex := 1

	// Apply filters
	if filters.Status != "" {
		query += fmt.Sprintf(" AND status = $%d", argIndex)
		args = append(args, filters.Status)
		argIndex++
	}

	if filters.Scope != "" {
		query += fmt.Sprintf(" AND scope = $%d", argIndex)
		args = append(args, filters.Scope)
		argIndex++
	}

	if !filters.CreatedAfter.IsZero() {
		query += fmt.Sprintf(" AND created_at > $%d", argIndex)
		args = append(args, filters.CreatedAfter)
		argIndex++
	}

	if !filters.CreatedBefore.IsZero() {
		query += fmt.Sprintf(" AND created_at < $%d", argIndex)
		args = append(args, filters.CreatedBefore)
		argIndex++
	}

	// Add ordering and limit
	query += " ORDER BY created_at DESC"
	if filters.Limit > 0 {
		query += fmt.Sprintf(" LIMIT $%d", argIndex)
		args = append(args, filters.Limit)
	}

	rows, err := s.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sessions []*interfaces.Session
	for rows.Next() {
		session := &interfaces.Session{}
		var metadataJSON []byte

		err := rows.Scan(
			&session.ID,
			&session.Scope,
			&session.Status,
			&session.Duration,
			&session.CreatedAt,
			&session.UpdatedAt,
			&metadataJSON,
		)
		if err != nil {
			return nil, err
		}

		if err := json.Unmarshal(metadataJSON, &session.Metadata); err != nil {
			return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
		}

		sessions = append(sessions, session)
	}

	return sessions, rows.Err()
}

// SaveBranch implements StorageManager interface
func (s *PostgreSQLStorageManager) SaveBranch(ctx context.Context, branch *interfaces.Branch) error {
	query := `
		INSERT INTO branches (id, session_id, name, base_branch, status, created_at, updated_at, metadata, git_hash)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (id) DO UPDATE SET
			session_id = EXCLUDED.session_id,
			name = EXCLUDED.name,
			base_branch = EXCLUDED.base_branch,
			status = EXCLUDED.status,
			updated_at = EXCLUDED.updated_at,
			metadata = EXCLUDED.metadata,
			git_hash = EXCLUDED.git_hash
	`

	metadataJSON, err := json.Marshal(branch.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %v", err)
	}

	_, err = s.db.ExecContext(ctx, query,
		branch.ID,
		branch.SessionID,
		branch.Name,
		branch.BaseBranch,
		branch.Status,
		branch.CreatedAt,
		branch.UpdatedAt,
		metadataJSON,
		branch.GitHash,
	)

	return err
}

// GetBranch implements StorageManager interface
func (s *PostgreSQLStorageManager) GetBranch(ctx context.Context, branchID string) (*interfaces.Branch, error) {
	query := `
		SELECT id, session_id, name, base_branch, status, created_at, updated_at, metadata, git_hash
		FROM branches
		WHERE id = $1
	`

	branch := &interfaces.Branch{}
	var metadataJSON []byte

	err := s.db.QueryRowContext(ctx, query, branchID).Scan(
		&branch.ID,
		&branch.SessionID,
		&branch.Name,
		&branch.BaseBranch,
		&branch.Status,
		&branch.CreatedAt,
		&branch.UpdatedAt,
		&metadataJSON,
		&branch.GitHash,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("branch not found: %s", branchID)
		}
		return nil, err
	}

	if err := json.Unmarshal(metadataJSON, &branch.Metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
	}

	return branch, nil
}

// SaveEvent implements StorageManager interface
func (s *PostgreSQLStorageManager) SaveEvent(ctx context.Context, event *interfaces.BranchingEvent) error {
	query := `
		INSERT INTO branching_events (id, event_type, source, branch_id, session_id, timestamp, payload, processed)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`

	// Generate ID if not set
	if event.ID == "" {
		event.ID = uuid.New().String()
	}

	payloadJSON, err := json.Marshal(event.Payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}

	_, err = s.db.ExecContext(ctx, query,
		event.ID,
		event.Type,
		event.Source,
		event.BranchID,
		event.SessionID,
		event.Timestamp,
		payloadJSON,
		event.Processed,
	)

	return err
}

// GetPendingEvents implements StorageManager interface
func (s *PostgreSQLStorageManager) GetPendingEvents(ctx context.Context) ([]*interfaces.BranchingEvent, error) {
	query := `
		SELECT id, event_type, source, branch_id, session_id, timestamp, payload, processed
		FROM branching_events
		WHERE processed = FALSE
		ORDER BY timestamp ASC
	`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []*interfaces.BranchingEvent
	for rows.Next() {
		event := &interfaces.BranchingEvent{}
		var payloadJSON []byte

		err := rows.Scan(
			&event.ID,
			&event.Type,
			&event.Source,
			&event.BranchID,
			&event.SessionID,
			&event.Timestamp,
			&payloadJSON,
			&event.Processed,
		)
		if err != nil {
			return nil, err
		}

		if err := json.Unmarshal(payloadJSON, &event.Payload); err != nil {
			return nil, fmt.Errorf("failed to unmarshal payload: %v", err)
		}

		events = append(events, event)
	}

	return events, rows.Err()
}

// MarkEventProcessed implements StorageManager interface
func (s *PostgreSQLStorageManager) MarkEventProcessed(ctx context.Context, eventID string) error {
	query := `UPDATE branching_events SET processed = TRUE WHERE id = $1`
	_, err := s.db.ExecContext(ctx, query, eventID)
	return err
}

// SaveTemporalSnapshot implements StorageManager interface
func (s *PostgreSQLStorageManager) SaveTemporalSnapshot(ctx context.Context, snapshot *interfaces.TemporalSnapshot) error {
	query := `
		INSERT INTO temporal_snapshots (id, branch_id, timestamp, git_hash, metadata, changes_summary)
		VALUES ($1, $2, $3, $4, $5, $6)
	`

	metadataJSON, err := json.Marshal(snapshot.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %v", err)
	}

	_, err = s.db.ExecContext(ctx, query,
		snapshot.ID,
		snapshot.BranchID,
		snapshot.Timestamp,
		snapshot.GitHash,
		metadataJSON,
		snapshot.ChangesSummary,
	)

	return err
}

// GetTemporalSnapshots implements StorageManager interface
func (s *PostgreSQLStorageManager) GetTemporalSnapshots(ctx context.Context, branchID string, timeRange interfaces.TimeRange) ([]*interfaces.TemporalSnapshot, error) {
	query := `
		SELECT id, branch_id, timestamp, git_hash, metadata, changes_summary
		FROM temporal_snapshots
		WHERE branch_id = $1 AND timestamp BETWEEN $2 AND $3
		ORDER BY timestamp DESC
	`

	rows, err := s.db.QueryContext(ctx, query, branchID, timeRange.Start, timeRange.End)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var snapshots []*interfaces.TemporalSnapshot
	for rows.Next() {
		snapshot := &interfaces.TemporalSnapshot{}
		var metadataJSON []byte

		err := rows.Scan(
			&snapshot.ID,
			&snapshot.BranchID,
			&snapshot.Timestamp,
			&snapshot.GitHash,
			&metadataJSON,
			&snapshot.ChangesSummary,
		)
		if err != nil {
			return nil, err
		}

		if err := json.Unmarshal(metadataJSON, &snapshot.Metadata); err != nil {
			return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
		}

		snapshots = append(snapshots, snapshot)
	}

	return snapshots, rows.Err()
}

// SaveQuantumBranch implements StorageManager interface for Level 8
func (s *PostgreSQLStorageManager) SaveQuantumBranch(ctx context.Context, qb *interfaces.QuantumBranch) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Save quantum branch
	query := `
		INSERT INTO quantum_branches (id, name, description, base_branch, status, created_at, updated_at, metadata)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			description = EXCLUDED.description,
			base_branch = EXCLUDED.base_branch,
			status = EXCLUDED.status,
			updated_at = EXCLUDED.updated_at,
			metadata = EXCLUDED.metadata
	`

	metadataJSON, err := json.Marshal(qb.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %v", err)
	}

	_, err = tx.ExecContext(ctx, query,
		qb.ID,
		qb.Name,
		qb.Description,
		qb.BaseBranch,
		qb.Status,
		qb.CreatedAt,
		qb.UpdatedAt,
		metadataJSON,
	)
	if err != nil {
		return err
	}

	// Save approaches
	for _, approach := range qb.Approaches {
		approachQuery := `
			INSERT INTO quantum_approaches (id, quantum_branch_id, approach_name, branch_name, strategy, status, score, confidence, created_at, completed_at, metadata)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (id) DO UPDATE SET
				approach_name = EXCLUDED.approach_name,
				branch_name = EXCLUDED.branch_name,
				strategy = EXCLUDED.strategy,
				status = EXCLUDED.status,
				score = EXCLUDED.score,
				confidence = EXCLUDED.confidence,
				completed_at = EXCLUDED.completed_at,
				metadata = EXCLUDED.metadata
		`

		approachMetadataJSON, err := json.Marshal(approach.Metadata)
		if err != nil {
			return fmt.Errorf("failed to marshal approach metadata: %v", err)
		}

		_, err = tx.ExecContext(ctx, approachQuery,
			approach.ID,
			qb.ID,
			approach.Name,
			approach.BranchName,
			approach.Strategy,
			approach.Status,
			approach.Score,
			approach.Confidence,
			approach.CreatedAt,
			approach.CompletedAt,
			approachMetadataJSON,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit()
}

// GetQuantumBranch implements StorageManager interface for Level 8
func (s *PostgreSQLStorageManager) GetQuantumBranch(ctx context.Context, quantumBranchID string) (*interfaces.QuantumBranch, error) {
	// Get quantum branch
	query := `
		SELECT id, name, description, base_branch, status, created_at, updated_at, metadata
		FROM quantum_branches
		WHERE id = $1
	`

	qb := &interfaces.QuantumBranch{}
	var metadataJSON []byte

	err := s.db.QueryRowContext(ctx, query, quantumBranchID).Scan(
		&qb.ID,
		&qb.Name,
		&qb.Description,
		&qb.BaseBranch,
		&qb.Status,
		&qb.CreatedAt,
		&qb.UpdatedAt,
		&metadataJSON,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("quantum branch not found: %s", quantumBranchID)
		}
		return nil, err
	}

	if err := json.Unmarshal(metadataJSON, &qb.Metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata: %v", err)
	}

	// Get approaches
	approachQuery := `
		SELECT id, approach_name, branch_name, strategy, status, score, confidence, created_at, completed_at, metadata
		FROM quantum_approaches
		WHERE quantum_branch_id = $1
		ORDER BY created_at ASC
	`

	rows, err := s.db.QueryContext(ctx, approachQuery, quantumBranchID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		approach := &interfaces.BranchApproach{}
		var approachMetadataJSON []byte

		err := rows.Scan(
			&approach.ID,
			&approach.Name,
			&approach.BranchName,
			&approach.Strategy,
			&approach.Status,
			&approach.Score,
			&approach.Confidence,
			&approach.CreatedAt,
			&approach.CompletedAt,
			&approachMetadataJSON,
		)
		if err != nil {
			return nil, err
		}

		if err := json.Unmarshal(approachMetadataJSON, &approach.Metadata); err != nil {
			return nil, fmt.Errorf("failed to unmarshal approach metadata: %v", err)
		}

		qb.Approaches = append(qb.Approaches, approach)
	}

	return qb, rows.Err()
}

// Close closes the database connection
func (s *PostgreSQLStorageManager) Close() error {
	return s.db.Close()
}

// Health checks the database connection health
func (s *PostgreSQLStorageManager) Health(ctx context.Context) error {
	return s.db.PingContext(ctx)
}
