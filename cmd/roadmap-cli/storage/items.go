//go:build database

package storage

import (
	"database/sql"
	"time"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/google/uuid"
)

// CreateItem inserts a new roadmap item into the database
func (rdb *RoadmapDB) CreateItem(title, description, priority string, targetDate time.Time) (*types.RoadmapItem, error) {
	id := uuid.New().String()
	now := time.Now()

	query := `
		INSERT INTO roadmap_items (id, title, description, priority, target_date, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`

	_, err := rdb.db.Exec(query, id, title, description, priority, targetDate, now, now)
	if err != nil {
		return nil, err
	}

	return &types.RoadmapItem{
		ID:          id,
		Title:       title,
		Description: description,
		Status:      types.StatusPlanned,
		Progress:    0,
		Priority:    types.Priority(priority),
		TargetDate:  targetDate,
		CreatedAt:   now,
		UpdatedAt:   now,
	}, nil
}

// GetAllItems retrieves all roadmap items from the database
func (rdb *RoadmapDB) GetAllItems() ([]types.RoadmapItem, error) {
	query := `
		SELECT id, title, description, status, progress, priority, target_date, created_at, updated_at
		FROM roadmap_items
		ORDER BY target_date ASC
	`

	rows, err := rdb.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []types.RoadmapItem
	for rows.Next() {
		var item types.RoadmapItem
		var status, priority string
		err := rows.Scan(
			&item.ID, &item.Title, &item.Description, &status,
			&item.Progress, &priority, &item.TargetDate,
			&item.CreatedAt, &item.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		item.Status = types.Status(status)
		item.Priority = types.Priority(priority)
		items = append(items, item)
	}

	return items, nil
}

// UpdateItemStatus updates the status and progress of a roadmap item
func (rdb *RoadmapDB) UpdateItemStatus(id, status string, progress int) error {
	query := `
		UPDATE roadmap_items 
		SET status = ?, progress = ?, updated_at = ?
		WHERE id = ?
	`

	_, err := rdb.db.Exec(query, status, progress, time.Now(), id)
	return err
}

// DeleteItem removes a roadmap item from the database
func (rdb *RoadmapDB) DeleteItem(id string) error {
	query := "DELETE FROM roadmap_items WHERE id = ?"
	_, err := rdb.db.Exec(query, id)
	return err
}

// GetItem retrieves a single roadmap item by ID
func (rdb *RoadmapDB) GetItem(id string) (*types.RoadmapItem, error) {
	query := `
		SELECT id, title, description, status, progress, priority, target_date, created_at, updated_at
		FROM roadmap_items
		WHERE id = ?
	`

	var item types.RoadmapItem
	var status, priority string
	err := rdb.db.QueryRow(query, id).Scan(
		&item.ID, &item.Title, &item.Description, &status,
		&item.Progress, &priority, &item.TargetDate,
		&item.CreatedAt, &item.UpdatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	item.Status = types.Status(status)
	item.Priority = types.Priority(priority)
	return &item, nil
}

// CreateMilestone inserts a new milestone into the database
func (rdb *RoadmapDB) CreateMilestone(title, description string, targetDate time.Time) (*types.Milestone, error) {
	id := uuid.New().String()
	now := time.Now()

	query := `
		INSERT INTO milestones (id, title, description, target_date, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`

	_, err := rdb.db.Exec(query, id, title, description, targetDate, now, now)
	if err != nil {
		return nil, err
	}

	return &types.Milestone{
		ID:          id,
		Title:       title,
		Description: description,
		TargetDate:  targetDate,
		CreatedAt:   now,
		UpdatedAt:   now,
	}, nil
}

// GetAllMilestones retrieves all milestones from the database
func (rdb *RoadmapDB) GetAllMilestones() ([]types.Milestone, error) {
	query := `
		SELECT id, title, description, target_date, created_at, updated_at
		FROM milestones
		ORDER BY target_date ASC
	`

	rows, err := rdb.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var milestones []types.Milestone
	for rows.Next() {
		var milestone types.Milestone
		err := rows.Scan(
			&milestone.ID, &milestone.Title, &milestone.Description,
			&milestone.TargetDate, &milestone.CreatedAt, &milestone.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		milestones = append(milestones, milestone)
	}

	return milestones, nil
}
