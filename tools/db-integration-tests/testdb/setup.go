package testdb

import (
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

// SetupTestDB configure une base de données de test (KISS)
func SetupTestDB() (*sqlx.DB, func(), error) {
	connStr := "postgres://user:password@localhost:5432/testdb?sslmode=disable"
	db, err := sqlx.Connect("postgres", connStr)
	if err != nil {
		return nil, nil, err
	}

	// Créer la table events
	_, err = db.Exec(`
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            source TEXT,
            target TEXT,
            payload TEXT
        )
    `)
	if err != nil {
		return nil, nil, err
	}

	// Fonction de nettoyage
	cleanup := func() {
		db.Exec("DROP TABLE IF EXISTS events")
		db.Close()
	}

	return db, cleanup, nil
}
