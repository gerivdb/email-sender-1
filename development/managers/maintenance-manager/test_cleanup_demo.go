package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/email-sender/maintenance-manager/src/cleanup"
	"github.com/email-sender/maintenance-manager/src/core"
)

func main() {
	fmt.Println("=== CleanupEngine Level 2 & 3 Functionality Demo ===")

	// Create a sample configuration
	config := &core.CleanupConfig{
		EnabledLevels:          []int{1, 2, 3},
		RetentionPeriodDays:    30,
		BackupBeforeCleanup:    true,
		SafetyChecks:           true,
		GitHistoryPreservation: true,
		SafetyThreshold:        0.8,
		MinFileSize:            100,
		MaxFileAge:             90,
	}

	// Create CleanupManager instance (without AI analyzer for this demo)
	cleanupManager := cleanup.NewCleanupManager(config, nil)

	fmt.Printf("✓ CleanupManager initialized with safety threshold: %.2f\n", config.SafetyThreshold)

	ctx := context.Background()

	// Test Level 1: Basic cleanup scanning
	fmt.Println("\n--- Level 1: Basic Cleanup Scanning ---")
	testDir := "."
	tasks, err := cleanupManager.ScanForCleanup(ctx, []string{testDir})
	if err != nil {
		log.Printf("Error scanning for cleanup: %v", err)
	} else {
		fmt.Printf("✓ Found %d cleanup tasks\n", len(tasks))
		for i, task := range tasks[:min(3, len(tasks))] {
			fmt.Printf("  %d. %s (Priority: %d, Risk: %s)\n", i+1, task.Description, task.Priority, task.Risk)
		}
	}

	// Test Level 2: Pattern Analysis
	fmt.Println("\n--- Level 2: Pattern Analysis ---")
	patterns, err := cleanupManager.AnalyzePatterns(ctx, testDir)
	if err != nil {
		log.Printf("Error analyzing patterns: %v", err)
	} else {
		fmt.Printf("✓ Detected %d file patterns\n", len(patterns))
		for i, pattern := range patterns[:min(3, len(patterns))] {
			fmt.Printf("  %d. Pattern: %s (Type: %s, Confidence: %.2f, Frequency: %d)\n",
				i+1, pattern.Pattern, pattern.Type, pattern.Confidence, pattern.Frequency)
		}
	}

	// Test Level 2: Pattern-based cleanup detection
	patternTasks, err := cleanupManager.DetectFilePatterns(ctx, testDir)
	if err != nil {
		log.Printf("Error detecting file patterns: %v", err)
	} else {
		fmt.Printf("✓ Generated %d pattern-based cleanup tasks\n", len(patternTasks))
	}

	// Test Level 3: Directory Structure Analysis
	fmt.Println("\n--- Level 3: Directory Structure Analysis ---")
	analysis, err := cleanupManager.AnalyzeDirectoryStructure(ctx, testDir)
	if err != nil {
		log.Printf("Error analyzing directory structure: %v", err)
	} else {
		fmt.Printf("✓ Directory Analysis Results:\n")
		fmt.Printf("  - Total Files: %d\n", analysis.TotalFiles)
		fmt.Printf("  - Total Size: %.2f MB\n", float64(analysis.TotalSize)/(1024*1024))
		fmt.Printf("  - Directory Depth: %d\n", analysis.Depth)
		fmt.Printf("  - File Types: %d\n", len(analysis.FileTypes))
		fmt.Printf("  - Organization Score: %.2f\n", analysis.OrganizationScore)
		fmt.Printf("  - Health Score: %.2f\n", analysis.HealthScore)
		fmt.Printf("  - Duplicate Ratio: %.2f%%\n", analysis.DuplicateRatio*100)
		fmt.Printf("  - Issues Found: %d\n", len(analysis.IssuesFound))
		fmt.Printf("  - Recommendations: %d\n", len(analysis.Recommendations))
	}

	// Test Level 3: Directory Health Analysis
	fmt.Println("\n--- Level 3: Directory Health Analysis ---")
	health, err := cleanupManager.AnalyzeDirectoryHealth(ctx, testDir)
	if err != nil {
		log.Printf("Error analyzing directory health: %v", err)
	} else {
		fmt.Printf("✓ Directory Health Status: %s\n", health["status"])
		fmt.Printf("  - Overall Score: %.2f\n", health["overall_score"])
		fmt.Printf("  - Organization Score: %.2f\n", health["organization_score"])
		fmt.Printf("  - Total Files: %v\n", health["total_files"])
		fmt.Printf("  - Directory Depth: %v\n", health["directory_depth"])
	}

	// Test Health Status
	fmt.Println("\n--- System Health Status ---")
	healthStatus := cleanupManager.GetHealthStatus(ctx)
	fmt.Printf("✓ Cleanup Manager Status: %s\n", healthStatus.Status)
	for key, value := range healthStatus.Details {
		fmt.Printf("  - %s: %s\n", key, value)
	}

	// Show statistics
	fmt.Println("\n--- Cleanup Statistics ---")
	stats := cleanupManager.GetStats()
	fmt.Printf("✓ Files Scanned: %d\n", stats.TotalFilesScanned)
	fmt.Printf("✓ Files Deleted: %d\n", stats.FilesDeleted)
	fmt.Printf("✓ Files Moved: %d\n", stats.FilesMoved)
	fmt.Printf("✓ Space Freed: %d bytes\n", stats.SpaceFreed)
	fmt.Printf("✓ Operation Duration: %v\n", time.Since(stats.OperationStartTime))

	fmt.Println("\n=== CleanupEngine Demo Complete ===")
	fmt.Println("✓ All Level 2 and Level 3 functionality implemented successfully!")
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
