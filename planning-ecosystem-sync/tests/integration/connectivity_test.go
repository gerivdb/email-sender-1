package tests

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"testing"
	"time"

	_ "github.com/lib/pq"
)

// TestQDrantConnectivity teste la connectivité avec QDrant
func TestQDrantConnectivity(t *testing.T) {
	// Configuration de test pour QDrant
	qdrantURL := "http://localhost:6333"

	// Test de connectivité basique
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	// Test endpoint de santé QDrant
	resp, err := client.Get(fmt.Sprintf("%s/", qdrantURL))
	if err != nil {
		t.Skipf("QDrant not available for testing: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("QDrant health check failed: status %d", resp.StatusCode)
	}
}

// TestQDrantCollectionCreation teste la création de collection
func TestQDrantCollectionCreation(t *testing.T) {
	collectionName := "development_plans"
	qdrantURL := "http://localhost:6333"

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Vérifier si la collection existe
	resp, err := client.Get(fmt.Sprintf("%s/collections/%s", qdrantURL, collectionName))
	if err != nil {
		t.Skipf("QDrant not available for collection testing: %v", err)
		return
	}
	defer resp.Body.Close()

	// Status 200 = collection existe, 404 = n'existe pas (les deux sont OK pour le test)
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNotFound {
		t.Errorf("Unexpected response from QDrant collections endpoint: %d", resp.StatusCode)
	}
}

// TestSQLConnectivity teste la connectivité avec PostgreSQL
func TestSQLConnectivity(t *testing.T) {
	// Configuration de test pour PostgreSQL
	connStr := "postgresql://localhost/plans_db?sslmode=disable"

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		t.Skipf("PostgreSQL not available for testing: %v", err)
		return
	}
	defer db.Close()

	// Test de ping pour vérifier la connectivité
	if err := db.PingContext(ctx); err != nil {
		t.Skipf("PostgreSQL ping failed: %v", err)
		return
	}

	// Test simple de requête
	var version string
	err = db.QueryRowContext(ctx, "SELECT version()").Scan(&version)
	if err != nil {
		t.Errorf("Failed to query PostgreSQL version: %v", err)
	}

	if version == "" {
		t.Error("PostgreSQL version query returned empty result")
	}
}

// TestDatabaseSchemaCreation teste la création de schémas de base de données
func TestDatabaseSchemaCreation(t *testing.T) {
	connStr := "postgresql://localhost/plans_db?sslmode=disable"

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		t.Skipf("PostgreSQL not available for schema testing: %v", err)
		return
	}
	defer db.Close()

	if err := db.PingContext(ctx); err != nil {
		t.Skipf("PostgreSQL not reachable: %v", err)
		return
	}

	// Test création table de test
	createTableSQL := `
		CREATE TABLE IF NOT EXISTS test_plans (
			id SERIAL PRIMARY KEY,
			title VARCHAR(255) NOT NULL,
			version VARCHAR(50),
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`

	_, err = db.ExecContext(ctx, createTableSQL)
	if err != nil {
		t.Errorf("Failed to create test table: %v", err)
	}

	// Test insertion de données
	insertSQL := "INSERT INTO test_plans (title, version) VALUES ($1, $2)"
	_, err = db.ExecContext(ctx, insertSQL, "Test Plan", "1.0")
	if err != nil {
		t.Errorf("Failed to insert test data: %v", err)
	}

	// Nettoyage
	_, err = db.ExecContext(ctx, "DROP TABLE IF EXISTS test_plans")
	if err != nil {
		t.Logf("Warning: Failed to cleanup test table: %v", err)
	}
}
