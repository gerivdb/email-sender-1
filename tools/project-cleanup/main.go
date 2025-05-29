package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// CleanupConfig holds configuration for cleanup operations
type CleanupConfig struct {
	ProjectRoot string
	DryRun     bool
	Verbose    bool
	CleanBuild bool
	CleanLogs  bool
	CleanTemp  bool
	CleanCache bool
	OrganizeFiles bool
}

func main() {
	config := &CleanupConfig{}
	
	// Parse command line flags
	flag.BoolVar(&config.DryRun, "dry-run", false, "Show what would be done without actually doing it")
	flag.BoolVar(&config.Verbose, "verbose", false, "Verbose output")
	flag.BoolVar(&config.CleanBuild, "clean-build", true, "Clean build artifacts")
	flag.BoolVar(&config.CleanLogs, "clean-logs", false, "Clean log files")
	flag.BoolVar(&config.CleanTemp, "clean-temp", true, "Clean temporary files")
	flag.BoolVar(&config.CleanCache, "clean-cache", false, "Clean cache files")
	flag.BoolVar(&config.OrganizeFiles, "organize", false, "Organize root files into appropriate directories")
	flag.Parse()

	// Get project root
	wd, err := os.Getwd()
	if err != nil {
		fmt.Printf("❌ Error getting working directory: %v\n", err)
		os.Exit(1)
	}
	
	// Go to project root (assuming we're in tools/cleanup)
	config.ProjectRoot = filepath.Dir(filepath.Dir(wd))
	
	fmt.Println("🧹 Project Cleanup and Organization")
	fmt.Println("==================================")
	fmt.Printf("📁 Project root: %s\n", config.ProjectRoot)
	
	if config.DryRun {
		fmt.Println("🔍 DRY RUN MODE - No files will be modified")
	}
	
	// Change to project root
	if err := os.Chdir(config.ProjectRoot); err != nil {
		fmt.Printf("❌ Error changing to project root: %v\n", err)
		os.Exit(1)
	}
	
	// Perform cleanup operations
	if err := performCleanup(config); err != nil {
		fmt.Printf("❌ Cleanup failed: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println("✅ Cleanup completed successfully!")
}

func performCleanup(config *CleanupConfig) error {
	var totalFilesRemoved int
	var totalSizeFreed int64
	
	if config.CleanBuild {
		removed, size, err := cleanBuildArtifacts(config)
		if err != nil {
			return fmt.Errorf("cleaning build artifacts: %w", err)
		}
		totalFilesRemoved += removed
		totalSizeFreed += size
	}
	
	if config.CleanTemp {
		removed, size, err := cleanTempFiles(config)
		if err != nil {
			return fmt.Errorf("cleaning temp files: %w", err)
		}
		totalFilesRemoved += removed
		totalSizeFreed += size
	}
	
	if config.CleanLogs {
		removed, size, err := cleanLogFiles(config)
		if err != nil {
			return fmt.Errorf("cleaning log files: %w", err)
		}
		totalFilesRemoved += removed
		totalSizeFreed += size
	}
	
	if config.CleanCache {
		removed, size, err := cleanCacheFiles(config)
		if err != nil {
			return fmt.Errorf("cleaning cache files: %w", err)
		}
		totalFilesRemoved += removed
		totalSizeFreed += size
	}
	
	if config.OrganizeFiles {
		if err := organizeRootFiles(config); err != nil {
			return fmt.Errorf("organizing files: %w", err)
		}
	}
	
	// Summary
	fmt.Printf("\n📊 Cleanup Summary:\n")
	fmt.Printf("   Files removed: %d\n", totalFilesRemoved)
	fmt.Printf("   Space freed: %.2f MB\n", float64(totalSizeFreed)/(1024*1024))
	
	return nil
}

func cleanBuildArtifacts(config *CleanupConfig) (int, int64, error) {
	fmt.Printf("🔄 Cleaning build artifacts...\n")
	
	patterns := []string{
		"*.exe",
		"*.dll", 
		"*.so",
		"*.dylib",
		"dist/*",
		".build/*",
		"output/*",
		"bin/*",
	}
	
	return cleanByPatterns(config, patterns, "build artifacts")
}

func cleanTempFiles(config *CleanupConfig) (int, int64, error) {
	fmt.Printf("🔄 Cleaning temporary files...\n")
	
	patterns := []string{
		"*.tmp",
		"*.temp",
		"temp/*",
		".tmp/*",
		"*/tmp/*",
		"*~",
		".DS_Store",
		"Thumbs.db",
	}
	
	return cleanByPatterns(config, patterns, "temporary files")
}

func cleanLogFiles(config *CleanupConfig) (int, int64, error) {
	fmt.Printf("🔄 Cleaning log files...\n")
	
	patterns := []string{
		"*.log",
		"logs/*.log",
		"*.log.*",
		"logs/*/*.log",
	}
	
	return cleanByPatterns(config, patterns, "log files")
}

func cleanCacheFiles(config *CleanupConfig) (int, int64, error) {
	fmt.Printf("🔄 Cleaning cache files...\n")
	
	patterns := []string{
		".cache/*",
		"*/.cache/*",
		"node_modules/.cache/*",
		".pytest_cache/*",
		"__pycache__/*",
		"*/__pycache__/*",
	}
	
	return cleanByPatterns(config, patterns, "cache files")
}

func cleanByPatterns(config *CleanupConfig, patterns []string, description string) (int, int64, error) {
	var filesRemoved int
	var sizeFreed int64
	
	for _, pattern := range patterns {
		matches, err := filepath.Glob(pattern)
		if err != nil {
			continue // Skip invalid patterns
		}
		
		for _, match := range matches {
			info, err := os.Stat(match)
			if err != nil {
				continue
			}
			
			if info.IsDir() {
				// For directories, calculate total size first
				dirSize, err := getDirSize(match)
				if err == nil {
					sizeFreed += dirSize
				}
				
				if config.Verbose {
					fmt.Printf("   Would remove directory: %s (%.2f MB)\n", match, float64(dirSize)/(1024*1024))
				}
				
				if !config.DryRun {
					if err := os.RemoveAll(match); err != nil {
						fmt.Printf("⚠️  Failed to remove directory %s: %v\n", match, err)
					}
				}
				filesRemoved++
			} else {
				sizeFreed += info.Size()
				
				if config.Verbose {
					fmt.Printf("   Would remove file: %s (%.2f KB)\n", match, float64(info.Size())/1024)
				}
				
				if !config.DryRun {
					if err := os.Remove(match); err != nil {
						fmt.Printf("⚠️  Failed to remove file %s: %v\n", match, err)
					}
				}
				filesRemoved++
			}
		}
	}
	
	if filesRemoved > 0 {
		fmt.Printf("✅ Cleaned %d %s (%.2f MB freed)\n", filesRemoved, description, float64(sizeFreed)/(1024*1024))
	}
	
	return filesRemoved, sizeFreed, nil
}

func organizeRootFiles(config *CleanupConfig) error {
	fmt.Printf("🔄 Organizing root files...\n")
	
	// Define organization rules
	rules := map[string]string{
		"*.md":    "docs",
		"*.txt":   "docs", 
		"*.ps1":   "scripts/legacy",
		"*.bat":   "scripts/legacy",
		"*.sh":    "scripts/legacy",
		"*.py":    "scripts/python",
		"*.js":    "scripts/node",
		"*.json":  "configs",
		"*.yaml":  "configs",
		"*.yml":   "configs",
		"*.toml":  "configs",
		"*.env*":  "configs",
		"*.log":   "logs",
		"*.exe":   "bin",
		"*.dll":   "bin",
	}
	
	// Get files in root directory
	entries, err := os.ReadDir(".")
	if err != nil {
		return fmt.Errorf("reading root directory: %w", err)
	}
	
	var filesMoved int
	
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		
		fileName := entry.Name()
		
		// Skip important files that should stay in root
		if shouldStayInRoot(fileName) {
			continue
		}
		
		// Find matching rule
		var targetDir string
		for pattern, dir := range rules {
			matched, err := filepath.Match(pattern, fileName)
			if err == nil && matched {
				targetDir = dir
				break
			}
		}
		
		if targetDir == "" {
			continue
		}
		
		// Create target directory
		if !config.DryRun {
			if err := os.MkdirAll(targetDir, 0755); err != nil {
				fmt.Printf("⚠️  Failed to create directory %s: %v\n", targetDir, err)
				continue
			}
		}
		
		// Move file
		targetPath := filepath.Join(targetDir, fileName)
		
		if config.Verbose {
			fmt.Printf("   Would move: %s -> %s\n", fileName, targetPath)
		}
		
		if !config.DryRun {
			if err := os.Rename(fileName, targetPath); err != nil {
				fmt.Printf("⚠️  Failed to move %s to %s: %v\n", fileName, targetPath, err)
			} else {
				filesMoved++
			}
		} else {
			filesMoved++
		}
	}
	
	if filesMoved > 0 {
		fmt.Printf("✅ Organized %d files\n", filesMoved)
	}
	
	return nil
}

func shouldStayInRoot(fileName string) bool {
	keepInRoot := []string{
		"go.mod",
		"go.sum", 
		"Makefile",
		"Dockerfile",
		"docker-compose.yml",
		"README.md",
		"LICENSE",
		"CHANGELOG.md",
		"CONTRIBUTING.md",
		".gitignore",
		".gitattributes",
		".editorconfig",
		"package.json",
		"package-lock.json",
		"yarn.lock",
		"tsconfig.json",
	}
	
	for _, keep := range keepInRoot {
		if strings.EqualFold(fileName, keep) {
			return true
		}
	}
	
	return false
}

func getDirSize(path string) (int64, error) {
	var size int64
	
	err := filepath.WalkDir(path, func(_ string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		
		if !d.IsDir() {
			info, err := d.Info()
			if err != nil {
				return err
			}
			size += info.Size()
		}
		
		return nil
	})
	
	return size, err
}
