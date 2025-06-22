package docmanager

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)

func SetupTestDB() (*sql.DB, func()) {
	db, _ := sql.Open("sqlite3", ":memory:")
	// Exemple de migration automatique
	db.Exec(`CREATE TABLE IF NOT EXISTS documents (id INTEGER PRIMARY KEY, title TEXT, content TEXT);`)
	cleanup := func() { db.Close() }
	return db, cleanup
}
