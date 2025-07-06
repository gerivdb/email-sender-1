package retrieval

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

<<<<<<< HEAD
	baseInterfaces "./interfaces"
	"EMAIL_SENDER_1/development/managers/contextual-memory-manager/interfaces"
=======
	"github.com/gerivdb/email-sender-1/development/managers/contextual-memory-manager/interfaces"
	baseInterfaces "github.com/gerivdb/email-sender-1/development/managers/interfaces"
>>>>>>> migration/gateway-manager-v77
)

// retrievalManagerImpl implÃ©mente RetrievalManager en utilisant PostgreSQL et SQLite
type retrievalManagerImpl struct {
	storageManager baseInterfaces.StorageManager
	configManager  baseInterfaces.ConfigManager
	errorManager   baseInterfaces.ErrorManager

	pgDB        *sql.DB
	initialized bool
}

// NewRetrievalManager crÃ©e une nouvelle instance de RetrievalManager
func NewRetrievalManager(
	storageManager baseInterfaces.StorageManager,
	errorManager baseInterfaces.ErrorManager,
	configManager baseInterfaces.ConfigManager,
	indexManager interfaces.IndexManager,
	monitoringManager interfaces.MonitoringManager,
) (*retrievalManagerImpl, error) {
	return &retrievalManagerImpl{
		storageManager: storageManager,
		configManager:  configManager,
		errorManager:   errorManager,
	}, nil
}

// Initialize implÃ©mente BaseManager.Initialize
func (rm *retrievalManagerImpl) Initialize(ctx context.Context) error {
	if rm.initialized {
		return nil
	}

	// RÃ©cupÃ©rer la connexion PostgreSQL
	pgConn, err := rm.storageManager.GetPostgreSQLConnection()
	if err != nil {
		return fmt.Errorf("failed to get PostgreSQL connection: %w", err)
	}

	var ok bool
	rm.pgDB, ok = pgConn.(*sql.DB)
	if !ok {
		return fmt.Errorf("invalid PostgreSQL connection type")
	}

	// VÃ©rifier que les tables existent
	err = rm.ensureTablesExist(ctx)
	if err != nil {
		return fmt.Errorf("failed to ensure tables exist: %w", err)
	}

	rm.initialized = true
	return nil
}

// QueryContext recherche le contexte selon une requÃªte
func (rm *retrievalManagerImpl) QueryContext(ctx context.Context, query interfaces.ContextQuery) ([]interfaces.ContextResult, error) {
	if !rm.initialized {
		return nil, fmt.Errorf("RetrievalManager not initialized")
	}

	// Construction de la requÃªte SQL dynamique
	sqlQuery, args := rm.buildContextQuery(query)

	rows, err := rm.pgDB.QueryContext(ctx, sqlQuery, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to execute context query: %w", err)
	}
	defer rows.Close()

	var results []interfaces.ContextResult
	for rows.Next() {
		var result interfaces.ContextResult
		var action interfaces.Action

		err := rows.Scan(
			&result.ID,
			&action.ID,
			&action.Type,
			&action.Text,
			&action.WorkspacePath,
			&action.FilePath,
			&action.LineNumber,
			&action.Timestamp,
			&result.Score,
			&result.SimilarityType,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan context result: %w", err)
		}

		result.Action = action
		results = append(results, result)
	}

	return results, nil
}

// GetActionMetadata rÃ©cupÃ¨re les mÃ©tadonnÃ©es d'une action
func (rm *retrievalManagerImpl) GetActionMetadata(ctx context.Context, actionID string) (*interfaces.Action, error) {
	if !rm.initialized {
		return nil, fmt.Errorf("RetrievalManager not initialized")
	}

	query := `
		SELECT id, action_type, action_text, workspace_path, file_path, line_number, timestamp
		FROM contextual_actions 
		WHERE id = $1`

	var action interfaces.Action
	err := rm.pgDB.QueryRowContext(ctx, query, actionID).Scan(
		&action.ID,
		&action.Type,
		&action.Text,
		&action.WorkspacePath,
		&action.FilePath,
		&action.LineNumber,
		&action.Timestamp,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("action not found: %s", actionID)
		}
		return nil, fmt.Errorf("failed to get action metadata: %w", err)
	}

	return &action, nil
}

// SearchByText recherche des actions par texte
func (rm *retrievalManagerImpl) SearchByText(ctx context.Context, text string, workspacePath string, limit int) ([]interfaces.ContextResult, error) {
	if !rm.initialized {
		return nil, fmt.Errorf("RetrievalManager not initialized")
	}

	// RequÃªte de recherche textuelle avec PostgreSQL full-text search
	query := `
		SELECT 
			a.id,
			a.id as action_id,
			a.action_type,
			a.action_text,
			a.workspace_path,
			a.file_path,
			a.line_number,
			a.timestamp,
			ts_rank(to_tsvector('english', a.action_text), plainto_tsquery('english', $1)) as score,
			'text' as similarity_type
		FROM contextual_actions a
		WHERE to_tsvector('english', a.action_text) @@ plainto_tsquery('english', $1)
		AND ($2 = '' OR a.workspace_path = $2)
		ORDER BY score DESC
		LIMIT $3`

	rows, err := rm.pgDB.QueryContext(ctx, query, text, workspacePath, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to execute text search: %w", err)
	}
	defer rows.Close()

	var results []interfaces.ContextResult
	for rows.Next() {
		var result interfaces.ContextResult
		var action interfaces.Action

		err := rows.Scan(
			&result.ID,
			&action.ID,
			&action.Type,
			&action.Text,
			&action.WorkspacePath,
			&action.FilePath,
			&action.LineNumber,
			&action.Timestamp,
			&result.Score,
			&result.SimilarityType,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan text search result: %w", err)
		}

		result.Action = action
		results = append(results, result)
	}

	return results, nil
}

// GetActionsBySession rÃ©cupÃ¨re les actions d'une session
func (rm *retrievalManagerImpl) GetActionsBySession(ctx context.Context, sessionID string) ([]interfaces.Action, error) {
	if !rm.initialized {
		return nil, fmt.Errorf("RetrievalManager not initialized")
	}

	query := `
		SELECT id, action_type, action_text, workspace_path, file_path, line_number, timestamp
		FROM contextual_actions 
		WHERE session_id = $1
		ORDER BY timestamp ASC`

	rows, err := rm.pgDB.QueryContext(ctx, query, sessionID)
	if err != nil {
		return nil, fmt.Errorf("failed to get actions by session: %w", err)
	}
	defer rows.Close()

	var actions []interfaces.Action
	for rows.Next() {
		var action interfaces.Action

		err := rows.Scan(
			&action.ID,
			&action.Type,
			&action.Text,
			&action.WorkspacePath,
			&action.FilePath,
			&action.LineNumber,
			&action.Timestamp,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan action: %w", err)
		}

		actions = append(actions, action)
	}

	return actions, nil
}

// DeleteContext supprime un contexte de la base de donnÃ©es
func (rm *retrievalManagerImpl) DeleteContext(ctx context.Context, contextID string) error {
	if !rm.initialized {
		return fmt.Errorf("retrieval manager not initialized")
	}

	// Commencer une transaction
	tx, err := rm.pgDB.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			tx.Commit()
		}
	}()

	// Supprimer toutes les actions liÃ©es Ã  ce contexte
	deleteActionsQuery := `
		DELETE FROM contextual_actions 
		WHERE id = $1 OR session_id = $1 OR metadata->>'context_id' = $1
	`

	result, err := tx.ExecContext(ctx, deleteActionsQuery, contextID)
	if err != nil {
		return fmt.Errorf("failed to delete contextual actions: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	// Log du nombre d'enregistrements supprimÃ©s
	if rowsAffected > 0 {
		if rm.errorManager != nil {
			rm.errorManager.LogError(ctx, fmt.Sprintf("Deleted %d contextual actions for context ID: %s", rowsAffected, contextID), nil)
		}
	}

	return nil
}

// Cleanup implÃ©mente BaseManager.Cleanup
func (rm *retrievalManagerImpl) Cleanup() error {
	// Les connexions DB sont gÃ©rÃ©es par StorageManager
	return nil
}

// HealthCheck implÃ©mente BaseManager.HealthCheck
func (rm *retrievalManagerImpl) HealthCheck(ctx context.Context) error {
	if !rm.initialized {
		return fmt.Errorf("RetrievalManager not initialized")
	}

	// VÃ©rifier la connexion PostgreSQL
	err := rm.pgDB.PingContext(ctx)
	if err != nil {
		return fmt.Errorf("PostgreSQL connection unhealthy: %w", err)
	}

	// Test de requÃªte simple
	var count int
	err = rm.pgDB.QueryRowContext(ctx, "SELECT COUNT(*) FROM contextual_actions").Scan(&count)
	if err != nil {
		return fmt.Errorf("failed to query contextual_actions table: %w", err)
	}

	return nil
}

// MÃ©thodes privÃ©es

func (rm *retrievalManagerImpl) ensureTablesExist(ctx context.Context) error {
	// VÃ©rifier que la table contextual_actions existe
	var exists bool
	err := rm.pgDB.QueryRowContext(ctx,
		"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'contextual_actions')").Scan(&exists)
	if err != nil {
		return fmt.Errorf("failed to check if contextual_actions table exists: %w", err)
	}

	if !exists {
		return fmt.Errorf("contextual_actions table does not exist - run migrations first")
	}

	return nil
}

func (rm *retrievalManagerImpl) buildContextQuery(query interfaces.ContextQuery) (string, []interface{}) {
	var whereClauses []string
	var args []interface{}
	argIndex := 1

	baseQuery := `
		SELECT 
			a.id,
			a.id as action_id,
			a.action_type,
			a.action_text,
			a.workspace_path,
			a.file_path,
			a.line_number,
			a.timestamp,
			1.0 as score,
			'exact' as similarity_type
		FROM contextual_actions a`

	// Filtre par texte
	if query.Text != "" {
		whereClauses = append(whereClauses, fmt.Sprintf("a.action_text ILIKE $%d", argIndex))
		args = append(args, "%"+query.Text+"%")
		argIndex++
	}

	// Filtre par workspace
	if query.WorkspacePath != "" {
		whereClauses = append(whereClauses, fmt.Sprintf("a.workspace_path = $%d", argIndex))
		args = append(args, query.WorkspacePath)
		argIndex++
	}

	// Filtre par types d'action
	if len(query.ActionTypes) > 0 {
		placeholders := make([]string, len(query.ActionTypes))
		for i, actionType := range query.ActionTypes {
			placeholders[i] = fmt.Sprintf("$%d", argIndex)
			args = append(args, actionType)
			argIndex++
		}
		whereClauses = append(whereClauses, fmt.Sprintf("a.action_type IN (%s)", strings.Join(placeholders, ",")))
	}

	// Filtre par intervalle de temps
	if !query.TimeRange.Start.IsZero() {
		whereClauses = append(whereClauses, fmt.Sprintf("a.timestamp >= $%d", argIndex))
		args = append(args, query.TimeRange.Start)
		argIndex++
	}

	if !query.TimeRange.End.IsZero() {
		whereClauses = append(whereClauses, fmt.Sprintf("a.timestamp <= $%d", argIndex))
		args = append(args, query.TimeRange.End)
		argIndex++
	}

	// Construire la requÃªte complÃ¨te
	var sqlQuery string
	if len(whereClauses) > 0 {
		sqlQuery = baseQuery + " WHERE " + strings.Join(whereClauses, " AND ")
	} else {
		sqlQuery = baseQuery
	}

	// Ajouter l'ordre et la limite
	sqlQuery += " ORDER BY a.timestamp DESC"

	if query.Limit > 0 {
		sqlQuery += fmt.Sprintf(" LIMIT $%d", argIndex)
		args = append(args, query.Limit)
	}

	return sqlQuery, args
}
