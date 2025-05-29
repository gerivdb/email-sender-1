package repository

import (
	"context"
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
	"time"
	"d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg\defaults\models"
)

// SQLiteRepository implements Repository interface using SQLite
type SQLiteRepository struct {
	db *sql.DB
}

// NewSQLiteRepository creates a new SQLite repository instance
func NewSQLiteRepository(dbPath string) (*SQLiteRepository, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		return nil, err
	}

	if err := createTable(db); err != nil {
		return nil, err
	}

	return &SQLiteRepository{db: db}, nil
}

func createTable(db *sql.DB) error {
	query := `CREATE TABLE IF NOT EXISTS default_values (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		key TEXT NOT NULL,
		value TEXT NOT NULL,
		context TEXT NOT NULL,
		confidence REAL DEFAULT 0.0,
		usage_count INTEGER DEFAULT 0,
		last_used DATETIME,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		UNIQUE(key, context)
	)`

	_, err := db.Exec(query)
	return err
}

// Create implements Repository.Create
func (r *SQLiteRepository) Create(ctx context.Context, value *models.DefaultValue) error {
	query := `INSERT INTO default_values (key, value, context, confidence, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?)`

	now := time.Now()
	_, err := r.db.ExecContext(ctx, query,
		value.Key,
		value.Value,
		value.Context,
		value.Confidence,
		now,
		now,
	)
	return err
}

// Get implements Repository.Get
func (r *SQLiteRepository) Get(ctx context.Context, key, context string) (*models.DefaultValue, error) {
	query := `SELECT * FROM default_values WHERE key = ? AND context = ?`
	
	value := &models.DefaultValue{}
	err := r.db.QueryRowContext(ctx, query, key, context).Scan(
		&value.ID,
		&value.Key,
		&value.Value,
		&value.Context,
		&value.Confidence,
		&value.UsageCount,
		&value.LastUsed,
		&value.CreatedAt,
		&value.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return value, err
}

// Update implements Repository.Update
func (r *SQLiteRepository) Update(ctx context.Context, value *models.DefaultValue) error {
	query := `UPDATE default_values 
			SET value = ?, confidence = ?, updated_at = ? 
			WHERE id = ?`

	_, err := r.db.ExecContext(ctx, query,
		value.Value,
		value.Confidence,
		time.Now(),
		value.ID,
	)
	return err
}

// Delete implements Repository.Delete
func (r *SQLiteRepository) Delete(ctx context.Context, id int64) error {
	query := `DELETE FROM default_values WHERE id = ?`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// List implements Repository.List
func (r *SQLiteRepository) List(ctx context.Context, context string) ([]*models.DefaultValue, error) {
	query := `SELECT * FROM default_values WHERE context = ?`
	
	rows, err := r.db.QueryContext(ctx, query, context)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var values []*models.DefaultValue
	for rows.Next() {
		value := &models.DefaultValue{}
		err := rows.Scan(
			&value.ID,
			&value.Key,
			&value.Value,
			&value.Context,
			&value.Confidence,
			&value.UsageCount,
			&value.LastUsed,
			&value.CreatedAt,
			&value.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		values = append(values, value)
	}
	return values, rows.Err()
}

// GetMostConfident implements Repository.GetMostConfident
func (r *SQLiteRepository) GetMostConfident(ctx context.Context, key string) (*models.DefaultValue, error) {
	query := `SELECT * FROM default_values 
			WHERE key = ? 
			ORDER BY confidence DESC 
			LIMIT 1`
	
	value := &models.DefaultValue{}
	err := r.db.QueryRowContext(ctx, query, key).Scan(
		&value.ID,
		&value.Key,
		&value.Value,
		&value.Context,
		&value.Confidence,
		&value.UsageCount,
		&value.LastUsed,
		&value.CreatedAt,
		&value.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return value, err
}

// IncrementUsage implements Repository.IncrementUsage
func (r *SQLiteRepository) IncrementUsage(ctx context.Context, id int64) error {
	query := `UPDATE default_values 
			SET usage_count = usage_count + 1, 
				last_used = ?, 
				updated_at = ?
			WHERE id = ?`

	now := time.Now()
	_, err := r.db.ExecContext(ctx, query, now, now, id)
	return err
}