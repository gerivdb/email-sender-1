package tool_manager

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

// ToolManager manages all Go-based tools in the project
type ToolManager struct {
	ProjectRoot	string
	Verbose		bool
	Parallel	bool
}

// Tool represents a Go-based tool
type Tool struct {
	Name		string
	Path		string
	Description	string
	Args		[]string
}

var availableTools = []Tool{
	{
		Name:		"build-production",
		Path:		"tools/build-production",
		Description:	"Build optimized production binaries",
	},
	{
		Name:		"project-cleanup",
		Path:		"tools/project-cleanup",
		Description:	"Clean and organize project files",
	},
	{
		Name:		"test-runner",
		Path:		"tools/test-runner",
		Description:	"Fast parallel test runner",
	},
	{
		Name:		"project-validator",
		Path:		"tools/project-validator",
		Description:	"Validate project setup and dependencies",
	},
	{
		Name:		"config-manager",
		Path:		"tools/config-manager",
		Description:	"Manage application configuration",
	},
}

func main() {
	manager := &ToolManager{}

	var (
		listTools	= flag.Bool("list", false, "List available tools")
		buildAll	= flag.Bool("build-all", false, "Build all tools")
		toolName	= flag.String("tool", "", "Tool to run")
		showHelp	= flag.Bool("help", false, "Show help")
	)

	flag.BoolVar(&manager.Verbose, "v", false, "Verbose output")
	flag.BoolVar(&manager.Parallel, "parallel", true, "Build tools in parallel")
	flag.Parse()
	// Get project root
	wd, err := os.Getwd()
	if err != nil {
		fmt.Printf("❌ Error getting working directory: %v\n", err)
		os.Exit(1)
	}

	// Find project root by looking for go.mod
	manager.ProjectRoot = findProjectRoot(wd)

	if *showHelp {
		printHelp()
		return
	}

	if *listTools {
		listAvailableTools()
		return
	}

	// Change to project root
	if err := os.Chdir(manager.ProjectRoot); err != nil {
		fmt.Printf("❌ Error changing to project root: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("🔧 Go Tools Manager")
	fmt.Println("==================")
	fmt.Printf("📁 Project root: %s\n", manager.ProjectRoot)

	if *buildAll {
		if err := buildAllTools(manager); err != nil {
			fmt.Printf("❌ Failed to build tools: %v\n", err)
			os.Exit(1)
		}
		return
	}

	if *toolName != "" {
		// Find and run the specified tool
		tool := findTool(*toolName)
		if tool == nil {
			fmt.Printf("❌ Tool '%s' not found\n", *toolName)
			fmt.Println("\nAvailable tools:")
			listAvailableTools()
			os.Exit(1)
		}

		if err := runTool(manager, tool, flag.Args()); err != nil {
			fmt.Printf("❌ Tool '%s' failed: %v\n", *toolName, err)
			os.Exit(1)
		}
		return
	}

	// Interactive mode
	runInteractiveMode(manager)
}

func printHelp() {
	fmt.Println("🔧 Go Tools Manager")
	fmt.Println("==================")
	fmt.Println()
	fmt.Println("USAGE:")
	fmt.Println("  tool-manager [OPTIONS] [COMMAND]")
	fmt.Println()
	fmt.Println("OPTIONS:")
	fmt.Println("  -list          List available tools")
	fmt.Println("  -build-all     Build all tools")
	fmt.Println("  -tool NAME     Run specific tool")
	fmt.Println("  -v             Verbose output")
	fmt.Println("  -parallel      Build tools in parallel (default: true)")
	fmt.Println("  -help          Show this help")
	fmt.Println()
	fmt.Println("EXAMPLES:")
	fmt.Println("  tool-manager -list")
	fmt.Println("  tool-manager -build-all")
	fmt.Println("  tool-manager -tool build-production -target linux")
	fmt.Println("  tool-manager -tool test-runner -v")
	fmt.Println("  tool-manager -tool project-cleanup -dry-run")
	fmt.Println()
	fmt.Println("AVAILABLE TOOLS:")
	for _, tool := range availableTools {
		fmt.Printf("  %-20s %s\n", tool.Name, tool.Description)
	}
}

func listAvailableTools() {
	fmt.Println("📋 Available Tools:")
	fmt.Println("==================")
	for i, tool := range availableTools {
		status := "⚠️  Not built"
		if toolExists(tool) {
			status = "✅ Ready"
		}
		fmt.Printf("%d. %-20s %s - %s\n", i+1, tool.Name, status, tool.Description)
	}
}

func buildAllTools(manager *ToolManager) error {
	fmt.Printf("🔄 Building all tools...\n")

	if manager.Parallel && runtime.NumCPU() > 1 {
		return buildToolsParallel(manager)
	}

	return buildToolsSequential(manager)
}

func buildToolsParallel(manager *ToolManager) error {
	fmt.Printf("🚀 Building tools in parallel (max %d goroutines)\n", runtime.NumCPU())

	type buildResult struct {
		tool	Tool
		err	error
	}

	results := make(chan buildResult, len(availableTools))
	semaphore := make(chan struct{}, runtime.NumCPU())

	// Start builds
	for _, tool := range availableTools {
		go func(t Tool) {
			semaphore <- struct{}{}	// Acquire
			err := buildTool(manager, &t)
			<-semaphore	// Release
			results <- buildResult{tool: t, err: err}
		}(tool)
	}

	// Collect results
	var failed []string
	for i := 0; i < len(availableTools); i++ {
		result := <-results
		if result.err != nil {
			failed = append(failed, result.tool.Name)
			fmt.Printf("❌ %s: %v\n", result.tool.Name, result.err)
		} else {
			fmt.Printf("✅ %s built successfully\n", result.tool.Name)
		}
	}

	if len(failed) > 0 {
		return fmt.Errorf("failed to build tools: %s", strings.Join(failed, ", "))
	}

	fmt.Printf("🎉 All tools built successfully!\n")
	return nil
}

func buildToolsSequential(manager *ToolManager) error {
	fmt.Printf("🔄 Building tools sequentially\n")

	for _, tool := range availableTools {
		fmt.Printf("🔄 Building %s...\n", tool.Name)
		if err := buildTool(manager, &tool); err != nil {
			return fmt.Errorf("building %s: %w", tool.Name, err)
		}
		fmt.Printf("✅ %s built successfully\n", tool.Name)
	}

	fmt.Printf("🎉 All tools built successfully!\n")
	return nil
}

func buildTool(manager *ToolManager, tool *Tool) error {
	toolPath := filepath.Join(manager.ProjectRoot, tool.Path)

	// Check if tool directory exists
	if _, err := os.Stat(toolPath); os.IsNotExist(err) {
		return fmt.Errorf("tool directory does not exist: %s", toolPath)
	}

	// Build the tool
	binaryName := tool.Name
	if runtime.GOOS == "windows" {
		binaryName += ".exe"
	}

	outputPath := filepath.Join("bin", binaryName)

	// Create bin directory
	if err := os.MkdirAll("bin", 0755); err != nil {
		return fmt.Errorf("creating bin directory: %w", err)
	}

	// Build command
	args := []string{
		"build",
		"-ldflags", "-s -w",
		"-trimpath",
		"-o", outputPath,
		"./" + tool.Path,
	}

	if manager.Verbose {
		fmt.Printf("   Command: go %s\n", strings.Join(args, " "))
	}

	cmd := exec.Command("go", args...)
	cmd.Dir = manager.ProjectRoot

	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	return nil
}

func runTool(manager *ToolManager, tool *Tool, args []string) error {
	binaryName := tool.Name
	if runtime.GOOS == "windows" {
		binaryName += ".exe"
	}

	binaryPath := filepath.Join("bin", binaryName)

	// Check if tool is built
	if !toolExists(*tool) {
		fmt.Printf("🔄 Tool not built, building %s...\n", tool.Name)
		if err := buildTool(manager, tool); err != nil {
			return fmt.Errorf("building tool: %w", err)
		}
		fmt.Printf("✅ %s built successfully\n", tool.Name)
	}

	// Run the tool
	fmt.Printf("🚀 Running %s...\n", tool.Name)

	cmd := exec.Command(binaryPath, args...)
	cmd.Dir = manager.ProjectRoot
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func runInteractiveMode(manager *ToolManager) {
	fmt.Println("\n🎮 Interactive Mode")
	fmt.Println("==================")
	fmt.Println("Choose a tool to run:")

	for {
		fmt.Println()
		listAvailableTools()

		fmt.Println()
		fmt.Println("Commands:")
		fmt.Println("  1-9       Run tool by number")
		fmt.Println("  build     Build all tools")
		fmt.Println("  quit/q    Exit")
		fmt.Print("\nChoice: ")

		var input string
		if _, err := fmt.Scanln(&input); err != nil {
			continue
		}

		input = strings.ToLower(strings.TrimSpace(input))

		switch input {
		case "quit", "q", "exit":
			fmt.Println("👋 Goodbye!")
			return
		case "build":
			if err := buildAllTools(manager); err != nil {
				fmt.Printf("❌ Build failed: %v\n", err)
			}
		case "1", "2", "3", "4", "5", "6", "7", "8", "9":
			idx := int(input[0] - '1')
			if idx >= 0 && idx < len(availableTools) {
				tool := &availableTools[idx]
				if err := runTool(manager, tool, []string{}); err != nil {
					fmt.Printf("❌ Tool failed: %v\n", err)
				}
			} else {
				fmt.Println("❌ Invalid tool number")
			}
		default:
			// Try to find tool by name
			tool := findTool(input)
			if tool != nil {
				if err := runTool(manager, tool, []string{}); err != nil {
					fmt.Printf("❌ Tool failed: %v\n", err)
				}
			} else {
				fmt.Println("❌ Invalid choice")
			}
		}
	}
}

func findTool(name string) *Tool {
	for i, tool := range availableTools {
		if tool.Name == name {
			return &availableTools[i]
		}
	}
	return nil
}

func toolExists(tool Tool) bool {
	binaryName := tool.Name
	if runtime.GOOS == "windows" {
		binaryName += ".exe"
	}

	binaryPath := filepath.Join("bin", binaryName)
	_, err := os.Stat(binaryPath)
	return err == nil
}

// findProjectRoot walks up the directory tree to find the project root (containing go.mod)
func findProjectRoot(startDir string) string {
	dir := startDir
	for {
		goModPath := filepath.Join(dir, "go.mod")
		if _, err := os.Stat(goModPath); err == nil {
			return dir
		}

		parent := filepath.Dir(dir)
		if parent == dir {
			// Reached filesystem root, fallback to original logic
			return filepath.Dir(filepath.Dir(startDir))
		}
		dir = parent
	}
}
