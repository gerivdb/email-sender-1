package commands

import (
	"fmt"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"

	"github.com/spf13/cobra"
)

func newCreateCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create roadmap items",
		Long:  "Create new roadmap items, milestones, or epics",
	}

	// Add subcommands for different creation types
	cmd.AddCommand(newCreateItemCommand())
	cmd.AddCommand(newCreateEnrichedItemCommand())
	cmd.AddCommand(newCreateMilestoneCommand())

	return cmd
}

func newCreateItemCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "item [title]",
		Short: "Create a new roadmap item",
		Args:  cobra.MinimumNArgs(1),
		RunE:  runCreateItem,
	}

	cmd.Flags().String("description", "", "item description")
	cmd.Flags().String("priority", "medium", "priority level (low, medium, high)")
	cmd.Flags().String("target-date", "", "target date (YYYY-MM-DD, defaults to 30 days from now)")

	return cmd
}

func runCreateItem(cmd *cobra.Command, args []string) error {
	title := args[0]
	description, _ := cmd.Flags().GetString("description")
	priority, _ := cmd.Flags().GetString("priority")
	targetDateStr, _ := cmd.Flags().GetString("target-date")

	// Parse target date
	var targetDate time.Time
	if targetDateStr != "" {
		var err error
		targetDate, err = time.Parse("2006-01-02", targetDateStr)
		if err != nil {
			return fmt.Errorf("invalid target date format. Use YYYY-MM-DD: %v", err)
		}
	} else {
		targetDate = time.Now().AddDate(0, 0, 30) // Default to 30 days from now
	}

	// Validate priority
	if !isValidPriority(priority) {
		return fmt.Errorf("invalid priority '%s'. Valid options: low, medium, high, critical", priority)
	}

	// Get storage connection
	storagePath := storage.GetDefaultStoragePath()
	store, err := storage.NewJSONStorage(storagePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %v", err)
	}
	defer store.Close()

	// Create the item
	item, err := store.CreateItem(title, description, priority, targetDate)
	if err != nil {
		return fmt.Errorf("failed to create roadmap item: %v", err)
	}

	// Success output
	fmt.Printf("✅ Roadmap item created successfully!\n")
	fmt.Printf("   ID: %s\n", item.ID)
	fmt.Printf("   Title: %s\n", item.Title)
	fmt.Printf("   Priority: %s\n", item.Priority)
	fmt.Printf("   Target Date: %s\n", item.TargetDate.Format("2006-01-02"))
	fmt.Printf("\n💡 Tip: Use 'roadmap-cli view' to see your items in the TUI\n")

	return nil
}

func newCreateEnrichedItemCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "enriched [title]",
		Short: "Create a new enriched roadmap item with detailed metadata",
		Long: `Create a roadmap item with enriched metadata including inputs, outputs, scripts, 
prerequisites, methods, tools, frameworks, complexity levels, effort estimates, 
business value, and risk assessments.`,
		Args: cobra.MinimumNArgs(1),
		RunE: runCreateEnrichedItem,
	}

	// Basic fields
	cmd.Flags().String("description", "", "item description")
	cmd.Flags().String("priority", "medium", "priority level (low, medium, high, critical)")
	cmd.Flags().String("target-date", "", "target date (YYYY-MM-DD, defaults to 30 days from now)")
	cmd.Flags().String("status", "planned", "status (planned, in_progress, in_review, completed, blocked)")

	// Enriched fields
	cmd.Flags().StringSlice("inputs", []string{}, "input requirements (can be specified multiple times)")
	cmd.Flags().StringSlice("outputs", []string{}, "expected outputs (can be specified multiple times)")
	cmd.Flags().StringSlice("scripts", []string{}, "required scripts (can be specified multiple times)")
	cmd.Flags().StringSlice("prerequisites", []string{}, "prerequisites (can be specified multiple times)")
	cmd.Flags().StringSlice("methods", []string{}, "methods to be used (can be specified multiple times)")
	cmd.Flags().StringSlice("uris", []string{}, "relevant URIs (can be specified multiple times)")
	cmd.Flags().StringSlice("tools", []string{}, "required tools (can be specified multiple times)")
	cmd.Flags().StringSlice("frameworks", []string{}, "frameworks to be used (can be specified multiple times)")
	cmd.Flags().StringSlice("tags", []string{}, "tags for categorization (can be specified multiple times)")

	// Assessment fields
	cmd.Flags().String("complexity", "medium", "complexity level (low, medium, high)")
	cmd.Flags().Int("effort-estimate", 0, "effort estimate in hours")
	cmd.Flags().Int("business-value", 0, "business value score (1-10)")
	cmd.Flags().Int("technical-debt", 0, "technical debt impact score (1-10)")
	cmd.Flags().String("risk-level", "medium", "risk level (low, medium, high)")

	return cmd
}

func runCreateEnrichedItem(cmd *cobra.Command, args []string) error {
	title := args[0]
	description, _ := cmd.Flags().GetString("description")
	priority, _ := cmd.Flags().GetString("priority")
	status, _ := cmd.Flags().GetString("status")
	targetDateStr, _ := cmd.Flags().GetString("target-date")

	// Parse target date
	var targetDate time.Time
	if targetDateStr != "" {
		var err error
		targetDate, err = time.Parse("2006-01-02", targetDateStr)
		if err != nil {
			return fmt.Errorf("invalid target date format. Use YYYY-MM-DD: %v", err)
		}
	} else {
		targetDate = time.Now().AddDate(0, 0, 30) // Default to 30 days from now
	}

	// Validate priority
	if !isValidPriority(priority) {
		return fmt.Errorf("invalid priority '%s'. Valid options: low, medium, high, critical", priority)
	}

	// Validate status
	if !isValidStatus(status) {
		return fmt.Errorf("invalid status '%s'. Valid options: planned, in_progress, in_review, completed, blocked", status)
	}

	// Get enriched field values
	inputs, _ := cmd.Flags().GetStringSlice("inputs")
	outputs, _ := cmd.Flags().GetStringSlice("outputs")
	scripts, _ := cmd.Flags().GetStringSlice("scripts")
	prerequisites, _ := cmd.Flags().GetStringSlice("prerequisites")
	methods, _ := cmd.Flags().GetStringSlice("methods")
	uris, _ := cmd.Flags().GetStringSlice("uris")
	tools, _ := cmd.Flags().GetStringSlice("tools")
	frameworks, _ := cmd.Flags().GetStringSlice("frameworks")
	tags, _ := cmd.Flags().GetStringSlice("tags")

	// Get assessment fields
	complexity, _ := cmd.Flags().GetString("complexity")
	effortEstimate, _ := cmd.Flags().GetInt("effort-estimate")
	businessValue, _ := cmd.Flags().GetInt("business-value")
	technicalDebt, _ := cmd.Flags().GetInt("technical-debt")
	riskLevel, _ := cmd.Flags().GetString("risk-level")

	// Validate complexity and risk level
	if !isValidComplexity(complexity) {
		return fmt.Errorf("invalid complexity '%s'. Valid options: low, medium, high", complexity)
	}
	if !isValidRiskLevel(riskLevel) {
		return fmt.Errorf("invalid risk level '%s'. Valid options: low, medium, high", riskLevel)
	}

	// Convert string slices to structured types
	taskInputs := make([]types.TaskInput, len(inputs))
	for i, input := range inputs {
		taskInputs[i] = types.TaskInput{
			Name:        input,
			Description: input,
			Type:        "requirement",
		}
	}

	taskOutputs := make([]types.TaskOutput, len(outputs))
	for i, output := range outputs {
		taskOutputs[i] = types.TaskOutput{
			Name:        output,
			Description: output,
			Type:        "deliverable",
		}
	}

	taskScripts := make([]types.TaskScript, len(scripts))
	for i, script := range scripts {
		taskScripts[i] = types.TaskScript{
			Name:        script,
			Description: script,
			Language:    "bash", // Default language
			Path:        "",
		}
	}

	// Build options structure
	options := types.EnrichedItemOptions{
		Title:         title,
		Description:   description,
		Priority:      types.Priority(priority),
		Status:        types.Status(status),
		TargetDate:    targetDate,
		Inputs:        taskInputs,
		Outputs:       taskOutputs,
		Scripts:       taskScripts,
		Prerequisites: prerequisites,
		Methods:       methods,
		URIs:          uris,
		Tools:         tools,
		Frameworks:    frameworks,
		Tags:          tags,
		Complexity:    types.ComplexityLevel(complexity),
		Effort:        effortEstimate,
		BusinessValue: businessValue,
		TechnicalDebt: technicalDebt,
		RiskLevel:     types.RiskLevel(riskLevel),
	}

	// Get storage connection
	storagePath := storage.GetDefaultStoragePath()
	store, err := storage.NewJSONStorage(storagePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %v", err)
	}
	defer store.Close()

	// Create the enriched item
	item, err := store.CreateEnrichedItem(options)
	if err != nil {
		return fmt.Errorf("failed to create enriched roadmap item: %v", err)
	}

	// Success output
	fmt.Printf("✨ Enriched roadmap item created successfully!\n")
	fmt.Printf("   ID: %s\n", item.ID)
	fmt.Printf("   Title: %s\n", item.Title)
	fmt.Printf("   Priority: %s\n", item.Priority)
	fmt.Printf("   Status: %s\n", item.Status)
	fmt.Printf("   Complexity: %s\n", item.Complexity)
	fmt.Printf("   Risk Level: %s\n", item.RiskLevel)
	fmt.Printf("   Target Date: %s\n", item.TargetDate.Format("2006-01-02"))

	if len(item.Inputs) > 0 {
		fmt.Printf("   Inputs: %s\n", strings.Join(getInputNames(item.Inputs), ", "))
	}
	if len(item.Outputs) > 0 {
		fmt.Printf("   Outputs: %s\n", strings.Join(getOutputNames(item.Outputs), ", "))
	}
	if effortEstimate > 0 {
		fmt.Printf("   Effort Estimate: %d hours\n", item.Effort)
	}
	if businessValue > 0 {
		fmt.Printf("   Business Value: %d/10\n", item.BusinessValue)
	}

	fmt.Printf("\n💡 Tip: Use 'roadmap-cli view' to see your enriched items in the TUI\n")

	return nil
}

// Helper functions for validation
func isValidPriority(priority string) bool {
	validPriorities := map[string]bool{
		"low": true, "medium": true, "high": true, "critical": true,
	}
	return validPriorities[priority]
}

func isValidStatus(status string) bool {
	validStatuses := map[string]bool{
		"planned": true, "in_progress": true, "in_review": true, "completed": true, "blocked": true,
	}
	return validStatuses[status]
}

func isValidComplexity(complexity string) bool {
	validComplexities := map[string]bool{
		"low": true, "medium": true, "high": true,
	}
	return validComplexities[complexity]
}

func isValidRiskLevel(riskLevel string) bool {
	validRiskLevels := map[string]bool{
		"low": true, "medium": true, "high": true,
	}
	return validRiskLevels[riskLevel]
}

// Helper functions to extract names from structured types
func getInputNames(inputs []types.TaskInput) []string {
	names := make([]string, len(inputs))
	for i, input := range inputs {
		names[i] = input.Name
	}
	return names
}

func getOutputNames(outputs []types.TaskOutput) []string {
	names := make([]string, len(outputs))
	for i, output := range outputs {
		names[i] = output.Name
	}
	return names
}

func newCreateMilestoneCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "milestone [title]",
		Short: "Create a new milestone",
		Args:  cobra.MinimumNArgs(1),
		RunE:  runCreateMilestone,
	}

	cmd.Flags().String("description", "", "milestone description")
	cmd.Flags().String("target-date", "", "target date (YYYY-MM-DD, defaults to 3 months from now)")

	return cmd
}

func runCreateMilestone(cmd *cobra.Command, args []string) error {
	title := args[0]
	description, _ := cmd.Flags().GetString("description")
	targetDateStr, _ := cmd.Flags().GetString("target-date")

	// Parse target date
	var targetDate time.Time
	if targetDateStr != "" {
		var err error
		targetDate, err = time.Parse("2006-01-02", targetDateStr)
		if err != nil {
			return fmt.Errorf("invalid target date format. Use YYYY-MM-DD: %v", err)
		}
	} else {
		targetDate = time.Now().AddDate(0, 3, 0) // Default to 3 months from now
	}

	// Get storage connection
	storagePath := storage.GetDefaultStoragePath()
	store, err := storage.NewJSONStorage(storagePath)
	if err != nil {
		return fmt.Errorf("failed to initialize storage: %v", err)
	}
	defer store.Close()

	// Create the milestone
	milestone, err := store.CreateMilestone(title, description, targetDate)
	if err != nil {
		return fmt.Errorf("failed to create milestone: %v", err)
	}

	// Success output
	fmt.Printf("🎯 Milestone created successfully!\n")
	fmt.Printf("   ID: %s\n", milestone.ID)
	fmt.Printf("   Title: %s\n", milestone.Title)
	fmt.Printf("   Target Date: %s\n", milestone.TargetDate.Format("2006-01-02"))
	fmt.Printf("\n💡 Tip: Use milestones to group related roadmap items\n")

	return nil
}
