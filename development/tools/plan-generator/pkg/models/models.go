// Package models defines data structures used by the plan generator
package models

// Plan représente la structure de données principale d'un plan de développement
type Plan struct {
	Version         string                 `json:"version"`
	Title           string                 `json:"title"`
	Description     string                 `json:"description"`
	PhaseCount      int                    `json:"phaseCount"`
	Date            string                 `json:"date"`
	Progress        int                    `json:"progress"`
	PhaseDetails    map[string]interface{} `json:"phaseDetails"`
	GeneratedPhases []Phase                `json:"-"` // Pas sérialisé en JSON
}

// Phase représente une phase du plan de développement
type Phase struct {
	Number      int      `json:"number"`
	Description string   `json:"description"`
	Tasks       []Task   `json:"tasks"`
	Subtasks    []string `json:"subtasks"`
}

// Task représente une tâche dans une phase
type Task struct {
	ID          string   `json:"id"`
	Label       string   `json:"label"`
	Description string   `json:"description"`
	Done        bool     `json:"done"`
	Subtasks    []string `json:"subtaskStrings"` // Liste de descriptions simples (bullets)
	NestedTasks []Task   `json:"nestedTasks"`    // Sous-tâches structurées (hiérarchiques)
	Level       int      `json:"level"`          // Niveau de profondeur (1 = tâche principale, 2 = sous-tâche, etc.)
	MaxDepth    int      `json:"-"`              // Profondeur maximale des sous-tâches (calculé)
}
