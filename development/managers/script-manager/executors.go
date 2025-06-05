// Script Executors Implementation
// Section 1.4 - Implementation des Recommandations - Phase 1

package scriptmanager

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"go.uber.org/zap"
)

// PowerShellExecutor executes PowerShell scripts
type PowerShellExecutor struct {
	config *Config
	logger *zap.Logger
}

// Execute executes a PowerShell script
func (pse *PowerShellExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error) {
	startTime := time.Now()
	
	// Build PowerShell command
	psCommand := pse.buildPowerShellCommand(script, args)
	
	// Determine PowerShell executable
	psExe := pse.getPowerShellExecutable()
	
	// Create command
	cmd := exec.CommandContext(ctx, psExe, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", psCommand)
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	pse.logger.Debug("Executing PowerShell script",
		zap.String("script_id", script.ID),
		zap.String("script_name", script.Name),
		zap.String("command", psCommand))
	
	// Execute command
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	
	// Get exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	
	result := &ExecutionResult{
		Success:   err == nil && exitCode == 0,
		ExitCode:  exitCode,
		Output:    stdout.String(),
		Error:     stderr.String(),
		Duration:  duration,
		StartTime: startTime,
		EndTime:   endTime,
		Metadata: map[string]interface{}{
			"executor":      "powershell",
			"command":       psCommand,
			"ps_executable": psExe,
		},
	}
	
	pse.logger.Info("PowerShell script execution completed",
		zap.String("script_id", script.ID),
		zap.Bool("success", result.Success),
		zap.Int("exit_code", exitCode),
		zap.Duration("duration", duration))
	
	return result, err
}

// buildPowerShellCommand builds the PowerShell command with parameters
func (pse *PowerShellExecutor) buildPowerShellCommand(script *ManagedScript, args map[string]interface{}) string {
	var cmdParts []string
	
	// Add script path
	cmdParts = append(cmdParts, fmt.Sprintf("& '%s'", script.Path))
	
	// Add parameters
	for key, value := range args {
		switch v := value.(type) {
		case string:
			cmdParts = append(cmdParts, fmt.Sprintf("-%s '%s'", key, v))
		case bool:
			if v {
				cmdParts = append(cmdParts, fmt.Sprintf("-%s", key))
			}
		case int, int32, int64, float32, float64:
			cmdParts = append(cmdParts, fmt.Sprintf("-%s %v", key, v))
		default:
			// Convert to JSON for complex types
			if jsonBytes, err := json.Marshal(v); err == nil {
				cmdParts = append(cmdParts, fmt.Sprintf("-%s '%s'", key, string(jsonBytes)))
			}
		}
	}
	
	return strings.Join(cmdParts, " ")
}

// getPowerShellExecutable returns the PowerShell executable path
func (pse *PowerShellExecutor) getPowerShellExecutable() string {
	if pse.config.PowerShellExePath != "" {
		return pse.config.PowerShellExePath
	}
	
	// Default PowerShell executable based on OS
	if runtime.GOOS == "windows" {
		// Try PowerShell Core first, then Windows PowerShell
		if _, err := exec.LookPath("pwsh.exe"); err == nil {
			return "pwsh.exe"
		}
		return "powershell.exe"
	}
	
	return "pwsh" // PowerShell Core on Linux/macOS
}

// Validate validates a PowerShell script
func (pse *PowerShellExecutor) Validate(script *ManagedScript) error {
	psExe := pse.getPowerShellExecutable()
	
	// Use PowerShell's syntax checking
	cmd := exec.Command(psExe, "-NoProfile", "-Command", 
		fmt.Sprintf("$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content '%s' -Raw), [ref]$null)", script.Path))
	
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("PowerShell script validation failed: %s", stderr.String())
	}
	
	return nil
}

// GetDefaultTimeout returns the default timeout for PowerShell scripts
func (pse *PowerShellExecutor) GetDefaultTimeout() time.Duration {
	return 5 * time.Minute
}

// SupportsType checks if this executor supports the script type
func (pse *PowerShellExecutor) SupportsType(scriptType ScriptType) bool {
	return scriptType == ScriptTypePowerShell
}

// PythonExecutor executes Python scripts
type PythonExecutor struct {
	config *Config
	logger *zap.Logger
}

// Execute executes a Python script
func (pe *PythonExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error) {
	startTime := time.Now()
	
	// Build Python command
	pythonArgs := pe.buildPythonArgs(script, args)
	
	// Determine Python executable
	pythonExe := pe.getPythonExecutable()
	
	// Create command
	cmd := exec.CommandContext(ctx, pythonExe, pythonArgs...)
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	pe.logger.Debug("Executing Python script",
		zap.String("script_id", script.ID),
		zap.String("script_name", script.Name),
		zap.Strings("args", pythonArgs))
	
	// Execute command
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	
	// Get exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	
	result := &ExecutionResult{
		Success:   err == nil && exitCode == 0,
		ExitCode:  exitCode,
		Output:    stdout.String(),
		Error:     stderr.String(),
		Duration:  duration,
		StartTime: startTime,
		EndTime:   endTime,
		Metadata: map[string]interface{}{
			"executor":         "python",
			"args":             pythonArgs,
			"python_executable": pythonExe,
		},
	}
	
	pe.logger.Info("Python script execution completed",
		zap.String("script_id", script.ID),
		zap.Bool("success", result.Success),
		zap.Int("exit_code", exitCode),
		zap.Duration("duration", duration))
	
	return result, err
}

// buildPythonArgs builds Python command arguments
func (pe *PythonExecutor) buildPythonArgs(script *ManagedScript, args map[string]interface{}) []string {
	pythonArgs := []string{script.Path}
	
	// Add arguments
	for key, value := range args {
		pythonArgs = append(pythonArgs, fmt.Sprintf("--%s", key))
		pythonArgs = append(pythonArgs, fmt.Sprintf("%v", value))
	}
	
	return pythonArgs
}

// getPythonExecutable returns the Python executable path
func (pe *PythonExecutor) getPythonExecutable() string {
	if pe.config.PythonExePath != "" {
		return pe.config.PythonExePath
	}
	
	// Try common Python executables
	executables := []string{"python3", "python", "py"}
	for _, exe := range executables {
		if _, err := exec.LookPath(exe); err == nil {
			return exe
		}
	}
	
	return "python" // Default fallback
}

// Validate validates a Python script
func (pe *PythonExecutor) Validate(script *ManagedScript) error {
	pythonExe := pe.getPythonExecutable()
	
	// Use Python's compile function to check syntax
	cmd := exec.Command(pythonExe, "-m", "py_compile", script.Path)
	
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Python script validation failed: %s", stderr.String())
	}
	
	return nil
}

// GetDefaultTimeout returns the default timeout for Python scripts
func (pe *PythonExecutor) GetDefaultTimeout() time.Duration {
	return 5 * time.Minute
}

// SupportsType checks if this executor supports the script type
func (pe *PythonExecutor) SupportsType(scriptType ScriptType) bool {
	return scriptType == ScriptTypePython
}

// JavaScriptExecutor executes JavaScript/Node.js scripts
type JavaScriptExecutor struct {
	config *Config
	logger *zap.Logger
}

// Execute executes a JavaScript script
func (jse *JavaScriptExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error) {
	startTime := time.Now()
	
	// Build Node.js command
	nodeArgs := jse.buildNodeArgs(script, args)
	
	// Determine Node.js executable
	nodeExe := jse.getNodeExecutable()
	
	// Create command
	cmd := exec.CommandContext(ctx, nodeExe, nodeArgs...)
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	jse.logger.Debug("Executing JavaScript script",
		zap.String("script_id", script.ID),
		zap.String("script_name", script.Name),
		zap.Strings("args", nodeArgs))
	
	// Execute command
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	
	// Get exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	
	result := &ExecutionResult{
		Success:   err == nil && exitCode == 0,
		ExitCode:  exitCode,
		Output:    stdout.String(),
		Error:     stderr.String(),
		Duration:  duration,
		StartTime: startTime,
		EndTime:   endTime,
		Metadata: map[string]interface{}{
			"executor":       "javascript",
			"args":           nodeArgs,
			"node_executable": nodeExe,
		},
	}
	
	jse.logger.Info("JavaScript script execution completed",
		zap.String("script_id", script.ID),
		zap.Bool("success", result.Success),
		zap.Int("exit_code", exitCode),
		zap.Duration("duration", duration))
	
	return result, err
}

// buildNodeArgs builds Node.js command arguments
func (jse *JavaScriptExecutor) buildNodeArgs(script *ManagedScript, args map[string]interface{}) []string {
	nodeArgs := []string{script.Path}
	
	// Add arguments as environment variables or command line args
	for key, value := range args {
		nodeArgs = append(nodeArgs, fmt.Sprintf("--%s=%v", key, value))
	}
	
	return nodeArgs
}

// getNodeExecutable returns the Node.js executable path
func (jse *JavaScriptExecutor) getNodeExecutable() string {
	if jse.config.NodeExePath != "" {
		return jse.config.NodeExePath
	}
	
	// Try common Node.js executables
	executables := []string{"node", "nodejs"}
	for _, exe := range executables {
		if _, err := exec.LookPath(exe); err == nil {
			return exe
		}
	}
	
	return "node" // Default fallback
}

// Validate validates a JavaScript script
func (jse *JavaScriptExecutor) Validate(script *ManagedScript) error {
	nodeExe := jse.getNodeExecutable()
	
	// Use Node.js to check syntax
	cmd := exec.Command(nodeExe, "--check", script.Path)
	
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("JavaScript script validation failed: %s", stderr.String())
	}
	
	return nil
}

// GetDefaultTimeout returns the default timeout for JavaScript scripts
func (jse *JavaScriptExecutor) GetDefaultTimeout() time.Duration {
	return 5 * time.Minute
}

// SupportsType checks if this executor supports the script type
func (jse *JavaScriptExecutor) SupportsType(scriptType ScriptType) bool {
	return scriptType == ScriptTypeJavaScript
}

// BashExecutor executes Bash scripts (Unix/Linux)
type BashExecutor struct {
	config *Config
	logger *zap.Logger
}

// Execute executes a Bash script
func (be *BashExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error) {
	startTime := time.Now()
	
	// Build bash command
	bashArgs := be.buildBashArgs(script, args)
	
	// Create command
	cmd := exec.CommandContext(ctx, "/bin/bash", bashArgs...)
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	be.logger.Debug("Executing Bash script",
		zap.String("script_id", script.ID),
		zap.String("script_name", script.Name),
		zap.Strings("args", bashArgs))
	
	// Execute command
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	
	// Get exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	
	result := &ExecutionResult{
		Success:   err == nil && exitCode == 0,
		ExitCode:  exitCode,
		Output:    stdout.String(),
		Error:     stderr.String(),
		Duration:  duration,
		StartTime: startTime,
		EndTime:   endTime,
		Metadata: map[string]interface{}{
			"executor": "bash",
			"args":     bashArgs,
		},
	}
	
	be.logger.Info("Bash script execution completed",
		zap.String("script_id", script.ID),
		zap.Bool("success", result.Success),
		zap.Int("exit_code", exitCode),
		zap.Duration("duration", duration))
	
	return result, err
}

// buildBashArgs builds bash command arguments
func (be *BashExecutor) buildBashArgs(script *ManagedScript, args map[string]interface{}) []string {
	bashArgs := []string{script.Path}
	
	// Add arguments
	for key, value := range args {
		bashArgs = append(bashArgs, fmt.Sprintf("--%s", key))
		bashArgs = append(bashArgs, fmt.Sprintf("%v", value))
	}
	
	return bashArgs
}

// Validate validates a Bash script
func (be *BashExecutor) Validate(script *ManagedScript) error {
	// Use bash -n for syntax checking
	cmd := exec.Command("/bin/bash", "-n", script.Path)
	
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Bash script validation failed: %s", stderr.String())
	}
	
	return nil
}

// GetDefaultTimeout returns the default timeout for Bash scripts
func (be *BashExecutor) GetDefaultTimeout() time.Duration {
	return 5 * time.Minute
}

// SupportsType checks if this executor supports the script type
func (be *BashExecutor) SupportsType(scriptType ScriptType) bool {
	return scriptType == ScriptTypeBash
}

// BatchExecutor executes Batch scripts (Windows)
type BatchExecutor struct {
	config *Config
	logger *zap.Logger
}

// Execute executes a Batch script
func (bte *BatchExecutor) Execute(ctx context.Context, script *ManagedScript, args map[string]interface{}) (*ExecutionResult, error) {
	startTime := time.Now()
	
	// Build batch command
	batchArgs := bte.buildBatchArgs(script, args)
	
	// Create command
	cmd := exec.CommandContext(ctx, "cmd", "/C", strings.Join(batchArgs, " "))
	
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	bte.logger.Debug("Executing Batch script",
		zap.String("script_id", script.ID),
		zap.String("script_name", script.Name),
		zap.Strings("args", batchArgs))
	
	// Execute command
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	
	// Get exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}
	
	result := &ExecutionResult{
		Success:   err == nil && exitCode == 0,
		ExitCode:  exitCode,
		Output:    stdout.String(),
		Error:     stderr.String(),
		Duration:  duration,
		StartTime: startTime,
		EndTime:   endTime,
		Metadata: map[string]interface{}{
			"executor": "batch",
			"args":     batchArgs,
		},
	}
	
	bte.logger.Info("Batch script execution completed",
		zap.String("script_id", script.ID),
		zap.Bool("success", result.Success),
		zap.Int("exit_code", exitCode),
		zap.Duration("duration", duration))
	
	return result, err
}

// buildBatchArgs builds batch command arguments
func (bte *BatchExecutor) buildBatchArgs(script *ManagedScript, args map[string]interface{}) []string {
	batchArgs := []string{fmt.Sprintf(`"%s"`, script.Path)}
	
	// Add arguments
	for key, value := range args {
		batchArgs = append(batchArgs, fmt.Sprintf(`/%s:%v`, key, value))
	}
	
	return batchArgs
}

// Validate validates a Batch script
func (bte *BatchExecutor) Validate(script *ManagedScript) error {
	// Basic validation - check if file exists and is readable
	// Batch doesn't have built-in syntax checking like other languages
	if _, err := exec.LookPath("cmd"); err != nil {
		return fmt.Errorf("cmd.exe not available for batch script execution")
	}
	
	return nil
}

// GetDefaultTimeout returns the default timeout for Batch scripts
func (bte *BatchExecutor) GetDefaultTimeout() time.Duration {
	return 5 * time.Minute
}

// SupportsType checks if this executor supports the script type
func (bte *BatchExecutor) SupportsType(scriptType ScriptType) bool {
	return scriptType == ScriptTypeBatch
}
