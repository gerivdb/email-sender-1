// Package main implements a development plan generator in Go.
package main

import (
	"fmt"
	"plan-generator/pkg/generator"
	"plan-generator/pkg/io"
	"plan-generator/pkg/models"
)

func main() {
	// Example: Generate a development plan with nested tasks
	baseTask := models.Task{
		ID:          "1",
		Label:       "Main Task",
		Description: "This is the main task",
		Done:        false,
	}

	// Generate nested tasks for the base task
	nestedTasks := generator.GenerateNestedTasks(baseTask.ID, baseTask.Label, baseTask.Description, 1, 3)
	baseTask.NestedTasks = nestedTasks

	// Convert the base task into a phase structure
	phase := models.Phase{
		Number:      1,
		Description: "Main Phase",
		Tasks:       []models.Task{baseTask},
	}

	// Create a plan structure
	plan := &models.Plan{
		Version:     "1.0",
		Title:       "Development Plan",
		Description: "Generated development plan",
		PhaseCount:  1,
		Date:        "2025-05-23",
		Progress:    0,
		PhaseDetails: map[string]interface{}{
			"phase1": "Details about phase 1",
		},
		GeneratedPhases: []models.Phase{phase},
	}

	// Export the plan to JSON
	outputFile := "development_plan.json"
	status, err := io.ExportPlanToJSON(plan, outputFile, "author", "version-1")
	if err != nil {
		fmt.Printf("Error exporting plan to JSON: %v\n", err)
		return
	}

	fmt.Printf("Export status: %s\n", status)
	fmt.Printf("Development plan successfully exported to %s\n", outputFile)
}
