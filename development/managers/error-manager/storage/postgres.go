package errormanager

import (
	"database/sql"
	"fmt"

	errormanager "github.com/gerivdb/email-sender-1/managers/error-manager"

	_ "github.com/lib/pq"
)

var db *sql.DB

// InitializePostgres initializes the PostgreSQL connection
func InitializePostgres(connStr string) error {
	var err error
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}
	if err = db.Ping(); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}
	return nil
}

// PersistErrorToSQL inserts an ErrorEntry into the PostgreSQL database
func PersistErrorToSQL(entry errormanager.ErrorEntry) error {
	if db == nil {
		return fmt.Errorf("database connection is not initialized")
	}

	query := `INSERT INTO project_errors (
		id, timestamp, message, stack_trace, module, error_code, manager_context, severity
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`

	_, err := db.Exec(query,
		entry.ID,
		entry.Timestamp,
		entry.Message,
		entry.StackTrace,
		entry.Module,
		entry.ErrorCode,
		entry.ManagerContext,
		entry.Severity,
	)
	if err != nil {
		return fmt.Errorf("failed to insert error entry: %w", err)
	}

	return nil
}
