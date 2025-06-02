//go:build database

package storage

import (
	"database/sql"

	_ "github.com/mattn/go-sqlite3"
)

// RoadmapDB handles database operations for roadmap data
type RoadmapDB struct {
	db *sql.DB
}

// NewRoadmapDB creates a new database connection
func NewRoadmapDB(dbPath string) (*RoadmapDB, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}

	rdb := &RoadmapDB{db: db}
	if err := rdb.initTables(); err != nil {
		return nil, err
	}

	return rdb, nil
}

// initTables creates the necessary database tables
func (rdb *RoadmapDB) initTables() error {
	// Create roadmap_items table
	createItemsTable := `
	CREATE TABLE IF NOT EXISTS roadmap_items (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT,
		status TEXT DEFAULT 'planned',
		progress INTEGER DEFAULT 0,
		priority TEXT DEFAULT 'medium',
		target_date DATETIME,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	// Create milestones table
	createMilestonesTable := `
	CREATE TABLE IF NOT EXISTS milestones (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT,
		target_date DATETIME,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	// Create milestone_items junction table
	createMilestoneItemsTable := `
	CREATE TABLE IF NOT EXISTS milestone_items (
		milestone_id TEXT,
		item_id TEXT,
		PRIMARY KEY (milestone_id, item_id),
		FOREIGN KEY (milestone_id) REFERENCES milestones(id),
		FOREIGN KEY (item_id) REFERENCES roadmap_items(id)
	);`

	if _, err := rdb.db.Exec(createItemsTable); err != nil {
		return err
	}

	if _, err := rdb.db.Exec(createMilestonesTable); err != nil {
		return err
	}

	if _, err := rdb.db.Exec(createMilestoneItemsTable); err != nil {
		return err
	}

	return nil
}

// Close closes the database connection
func (rdb *RoadmapDB) Close() error {
	return rdb.db.Close()
}
