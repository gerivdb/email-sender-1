package main

import (
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// BuildConfig holds the configuration for building
type BuildConfig struct {
	Target      string
	Compress    bool
	Deploy      bool
	OutputDir   string
	Verbose     bool
	ProjectRoot string
	Version     string
	BuildTime   string
}

// Platform represents a target platform
type Platform struct {
	OS   string
	Arch string
	Ext  string
}

// DeploymentInfo contains build information
type DeploymentInfo struct {
	Version   string     `json:"version"`
	BuildTime string     `json:"buildTime"`
	Platforms []string   `json:"platforms"`
	Files     []FileInfo `json:"files"`
}

// FileInfo contains file metadata
type FileInfo struct {
	Name string `json:"name"`
	Size int64  `json:"size"`
	Hash string `json:"hash"`
}

var platforms = map[string]Platform{
	"linux":   {OS: "linux", Arch: "amd64", Ext: ""},
	"windows": {OS: "windows", Arch: "amd64", Ext: ".exe"},
	"darwin":  {OS: "darwin", Arch: "amd64", Ext: ""},
}

func main() {
	config := &BuildConfig{}

	// Parse command line flags
	flag.StringVar(&config.Target, "target", "all", "Target platform (all, linux, windows, darwin)")
	flag.BoolVar(&config.Compress, "compress", true, "Compress binaries with UPX")
	flag.BoolVar(&config.Deploy, "deploy", false, "Deploy after build")
	flag.StringVar(&config.OutputDir, "output", "dist", "Output directory")
	flag.BoolVar(&config.Verbose, "verbose", false, "Verbose output")
	flag.Parse()

	// Initialize build
	if err := initializeBuild(config); err != nil {
		fmt.Printf("❌ Initialization failed: %v\n", err)
		os.Exit(1)
	}

	// Run the build process
	if err := runBuild(config); err != nil {
		fmt.Printf("❌ Build failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("🎉 Production build completed successfully!")
}

func initializeBuild(config *BuildConfig) error {
	fmt.Println("🚀 Email Sender Production Build")
	fmt.Println("=================================")

	// Set project root
	wd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("getting working directory: %w", err)
	}

	// Go up two levels from tools/build-production to project root
	config.ProjectRoot = filepath.Dir(filepath.Dir(wd))

	// Set version and build time
	config.Version = time.Now().Format("2006.01.02.1504")
	config.BuildTime = time.Now().Format(time.RFC3339)

	fmt.Printf("🔄 Initializing build environment...\n")
	fmt.Printf("📁 Project root: %s\n", config.ProjectRoot)
	fmt.Printf("📋 Version: %s\n", config.Version)

	// Change to project root
	if err := os.Chdir(config.ProjectRoot); err != nil {
		return fmt.Errorf("changing to project root: %w", err)
	}

	// Clean and recreate output directory
	outputPath := filepath.Join(config.ProjectRoot, config.OutputDir)
	if err := os.RemoveAll(outputPath); err != nil {
		return fmt.Errorf("removing output directory: %w", err)
	}

	if err := os.MkdirAll(outputPath, 0o755); err != nil {
		return fmt.Errorf("creating output directory: %w", err)
	}

	// Verify Go installation
	if err := verifyGo(); err != nil {
		return fmt.Errorf("go verification failed: %w", err)
	}

	// Clean and tidy modules
	fmt.Printf("🔄 Cleaning previous builds...\n")
	if err := runCommand("go", "clean", "-cache"); err != nil {
		return fmt.Errorf("cleaning cache: %w", err)
	}

	if err := runCommand("go", "mod", "tidy"); err != nil {
		return fmt.Errorf("tidying modules: %w", err)
	}

	fmt.Printf("✅ Build environment initialized\n")
	return nil
}

func verifyGo() error {
	cmd := exec.Command("go", "version")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("go is not installed or not in PATH")
	}

	fmt.Printf("🔄 Go version: %s", string(output))
	return nil
}

func runBuild(config *BuildConfig) error {
	// Determine platforms to build
	var platformsToBuild []string
	if config.Target == "all" {
		for platform := range platforms {
			platformsToBuild = append(platformsToBuild, platform)
		}
	} else if _, exists := platforms[config.Target]; exists {
		platformsToBuild = []string{config.Target}
	} else {
		return fmt.Errorf("invalid target: %s", config.Target)
	}

	// Build main application
	mainPackage := "github.com/gerivdb/email-sender-1/cmd/email-server"
	for _, platform := range platformsToBuild {
		if err := buildBinary(config, platform, platforms[platform], mainPackage, "email-sender"); err != nil {
			return fmt.Errorf("building main binary for %s: %w", platform, err)
		}
	}

	// Build tools
	tools := map[string]string{
		"config-manager": "./tools/config-manager",
		"cache-analyzer": "./tools/cache-analyzer",
	}

	for toolName, toolPackage := range tools {
		if pathExists(filepath.Join(config.ProjectRoot, strings.TrimPrefix(toolPackage, "./"))) {
			fmt.Printf("🔄 Building tool: %s\n", toolName)
			for _, platform := range platformsToBuild {
				if err := buildBinary(config, platform, platforms[platform], toolPackage, toolName); err != nil {
					fmt.Printf("⚠️  Failed to build %s for %s: %v\n", toolName, platform, err)
				}
			}
		}
	}

	// Copy configurations and create deployment files
	if err := copyConfigs(config); err != nil {
		return fmt.Errorf("copying configs: %w", err)
	}

	if err := generateDeploymentInfo(config, platformsToBuild); err != nil {
		return fmt.Errorf("generating deployment info: %w", err)
	}

	// Create system service files
	for _, platform := range platformsToBuild {
		switch platform {
		case "linux":
			if err := createSystemdService(config); err != nil {
				fmt.Printf("⚠️  Failed to create systemd service: %v\n", err)
			}
		case "windows":
			if err := createWindowsService(config); err != nil {
				fmt.Printf("⚠️  Failed to create Windows service: %v\n", err)
			}
		}
	}

	if err := createDeploymentDoc(config, platformsToBuild); err != nil {
		return fmt.Errorf("creating deployment documentation: %w", err)
	}

	return nil
}

func buildBinary(config *BuildConfig, platform string, platformConfig Platform, packagePath, binaryName string) error {
	outputName := fmt.Sprintf("%s-%s%s", binaryName, platform, platformConfig.Ext)
	outputPath := filepath.Join(config.OutputDir, outputName)

	fmt.Printf("🔄 Building %s binary: %s\n", platform, outputName)

	// Set environment variables
	env := os.Environ()
	env = append(env, fmt.Sprintf("GOOS=%s", platformConfig.OS))
	env = append(env, fmt.Sprintf("GOARCH=%s", platformConfig.Arch))
	env = append(env, "CGO_ENABLED=0")

	// Build flags
	ldflags := fmt.Sprintf("-s -w -X main.version=%s -X main.buildTime=%s", config.Version, config.BuildTime)

	// Build command
	args := []string{
		"build",
		"-ldflags", ldflags,
		"-trimpath",
		"-tags", "netgo,osusergo",
		"-o", outputPath,
		packagePath,
	}

	if config.Verbose {
		fmt.Printf("Build command: go %s\n", strings.Join(args, " "))
	}

	cmd := exec.Command("go", args...)
	cmd.Env = env

	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("build failed: %w\nOutput: %s", err, string(output))
	}

	// Get file size
	fileInfo, err := os.Stat(outputPath)
	if err != nil {
		return fmt.Errorf("getting file info: %w", err)
	}

	fileSizeMB := float64(fileInfo.Size()) / (1024 * 1024)
	fmt.Printf("✅ Built %s binary: %s (%.2f MB)\n", platform, outputName, fileSizeMB)

	// Compress with UPX if available and requested
	if config.Compress {
		if err := compressWithUPX(outputPath, outputName); err != nil {
			fmt.Printf("⚠️  UPX compression failed for %s: %v\n", outputName, err)
		}
	}

	return nil
}

func compressWithUPX(filePath, fileName string) error {
	if !commandExists("upx") {
		return fmt.Errorf("UPX not available")
	}

	fmt.Printf("🔄 Compressing %s with UPX...\n", fileName)

	originalInfo, err := os.Stat(filePath)
	if err != nil {
		return fmt.Errorf("getting original file size: %w", err)
	}

	cmd := exec.Command("upx", "--best", "--lzma", filePath)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("UPX compression failed: %w", err)
	}

	compressedInfo, err := os.Stat(filePath)
	if err != nil {
		return fmt.Errorf("getting compressed file size: %w", err)
	}

	originalSizeMB := float64(originalInfo.Size()) / (1024 * 1024)
	compressedSizeMB := float64(compressedInfo.Size()) / (1024 * 1024)
	ratio := (1 - float64(compressedInfo.Size())/float64(originalInfo.Size())) * 100

	fmt.Printf("✅ Compressed %s (%.2f MB, %.1f%% reduction)\n", fileName, compressedSizeMB, ratio)
	return nil
}

func copyConfigs(config *BuildConfig) error {
	fmt.Printf("🔄 Copying configuration files...\n")

	configSrc := filepath.Join(config.ProjectRoot, "configs")
	configDst := filepath.Join(config.OutputDir, "configs")

	if pathExists(configSrc) {
		if err := copyDir(configSrc, configDst); err != nil {
			return fmt.Errorf("copying configs: %w", err)
		}
		fmt.Printf("✅ Configuration files copied\n")
	}

	return nil
}

func generateDeploymentInfo(config *BuildConfig, platforms []string) error {
	fmt.Printf("🔄 Generating deployment information...\n")

	deployInfo := DeploymentInfo{
		Version:   config.Version,
		BuildTime: config.BuildTime,
		Platforms: platforms,
		Files:     []FileInfo{},
	}

	outputPath := filepath.Join(config.ProjectRoot, config.OutputDir)
	err := filepath.Walk(outputPath, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}

		relPath, _ := filepath.Rel(outputPath, path)
		hash, err := calculateFileHash(path)
		if err != nil {
			return err
		}

		deployInfo.Files = append(deployInfo.Files, FileInfo{
			Name: relPath,
			Size: info.Size(),
			Hash: hash,
		})

		return nil
	})
	if err != nil {
		return fmt.Errorf("walking output directory: %w", err)
	}

	jsonData, err := json.MarshalIndent(deployInfo, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling deployment info: %w", err)
	}

	deployInfoPath := filepath.Join(outputPath, "deployment-info.json")
	if err := os.WriteFile(deployInfoPath, jsonData, 0o644); err != nil {
		return fmt.Errorf("writing deployment info: %w", err)
	}

	fmt.Printf("✅ Deployment info generated: deployment-info.json\n")
	return nil
}

func createSystemdService(config *BuildConfig) error {
	fmt.Printf("🔄 Creating systemd service file...\n")

	serviceContent := `[Unit]
Description=Email Sender Service
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/opt/email-sender/email-sender-linux
WorkingDirectory=/opt/email-sender
Restart=always
RestartSec=5
User=emailsender
Group=emailsender

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/email-sender/logs /opt/email-sender/data

# Environment
Environment=EMAIL_SENDER_ENV=production
EnvironmentFile=-/opt/email-sender/configs/.env

[Install]
WantedBy=multi-user.target
`

	servicePath := filepath.Join(config.OutputDir, "email-sender.service")
	if err := os.WriteFile(servicePath, []byte(serviceContent), 0o644); err != nil {
		return fmt.Errorf("writing systemd service: %w", err)
	}

	fmt.Printf("✅ Systemd service file created\n")
	return nil
}

func createWindowsService(config *BuildConfig) error {
	fmt.Printf("🔄 Creating Windows service installer...\n")

	serviceContent := `@echo off
echo Installing Email Sender Windows Service...

sc create EmailSender binpath= "C:\Program Files\EmailSender\email-sender-windows.exe" ^
    displayname= "Email Sender Service" ^
    description= "Native Email Sender Service" ^
    start= auto

sc config EmailSender obj= "NT AUTHORITY\LocalService"

echo Service installed. Starting service...
sc start EmailSender

echo.
echo Service installation complete.
echo You can manage the service using:
echo   sc start EmailSender
echo   sc stop EmailSender
echo   sc delete EmailSender
pause
`

	servicePath := filepath.Join(config.OutputDir, "install-windows-service.bat")
	if err := os.WriteFile(servicePath, []byte(serviceContent), 0o644); err != nil {
		return fmt.Errorf("writing Windows service installer: %w", err)
	}

	fmt.Printf("✅ Windows service installer created\n")
	return nil
}

func createDeploymentDoc(config *BuildConfig, platforms []string) error {
	outputPath := filepath.Join(config.ProjectRoot, config.OutputDir)

	// Get file list
	var files []string
	err := filepath.Walk(outputPath, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return err
		}

		relPath, _ := filepath.Rel(outputPath, path)
		files = append(files, fmt.Sprintf("- %s", relPath))
		return nil
	})
	if err != nil {
		return fmt.Errorf("walking output directory: %w", err)
	}

	docContent := fmt.Sprintf(`# Email Sender Native Deployment

## Built Version: %s
## Build Time: %s

## Files Included:
%s

## Deployment Instructions:

### Linux Deployment:
1. Copy email-sender-linux to /opt/email-sender/
2. Copy configs/ to /opt/email-sender/configs/
3. Install systemd service: sudo cp email-sender.service /etc/systemd/system/
4. Enable and start: sudo systemctl enable --now email-sender

### Windows Deployment:
1. Copy email-sender-windows.exe to C:\Program Files\EmailSender\
2. Copy configs/ to C:\Program Files\EmailSender\configs\
3. Run install-windows-service.bat as Administrator

### Configuration:
- Edit configs/production.yaml for production settings
- Set environment variables as needed
- Configure monitoring endpoints

## Monitoring:
- Health check: http://localhost:8080/health
- Metrics: http://localhost:8080/metrics
- Dashboard: http://localhost:8080/monitoring

`, config.Version, config.BuildTime, strings.Join(files, "\n"))

	deploymentDocPath := filepath.Join(outputPath, "DEPLOYMENT.md")
	if err := os.WriteFile(deploymentDocPath, []byte(docContent), 0o644); err != nil {
		return fmt.Errorf("writing deployment documentation: %w", err)
	}

	return nil
}

// Utility functions

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	return cmd.Run()
}

func commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func calculateFileHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

func copyDir(src, dst string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}

		dstPath := filepath.Join(dst, relPath)

		if info.IsDir() {
			return os.MkdirAll(dstPath, info.Mode())
		}

		return copyFile(path, dstPath)
	})
}

func copyFile(src, dst string) error {
	sourceFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sourceFile.Close()

	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		return err
	}

	destFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, sourceFile)
	return err
}
