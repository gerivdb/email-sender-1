// This file is used to force Go tools to recognize types defined in script_manager.go
// It is only needed if you encounter build errors about undefined types in executors.go
// You can safely delete this file if your build works without it.
package scriptmanager

// --- Type Definitions for Package-wide Visibility ---
type Config struct {
	// Add fields as needed
}

type ManagedScript struct {
	ID   string
	Name string
	Type ScriptType
	// Add other fields as needed
}

type ExecutionResult struct {
	Success bool
	Output  string
	Error   error
	// Add other fields as needed
}

type ScriptType string

const (
	ScriptTypePowerShell ScriptType = "powershell"
	ScriptTypePython     ScriptType = "python"
	ScriptTypeJavaScript ScriptType = "javascript"
	ScriptTypeBash       ScriptType = "bash"
	ScriptTypeBatch      ScriptType = "batch"
)

var (
	_ *Config          = nil
	_ *ManagedScript   = nil
	_ *ExecutionResult = nil
	_ ScriptType       = ""
	_                  = ScriptTypePowerShell
	_                  = ScriptTypePython
	_                  = ScriptTypeJavaScript
	_                  = ScriptTypeBash
	_                  = ScriptTypeBatch
)
