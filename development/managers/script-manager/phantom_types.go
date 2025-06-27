// This file is used to force Go tools to recognize types defined in script_manager.go
// It is only needed if you encounter build errors about undefined types in executors.go
// You can safely delete this file if your build works without it.
package scriptmanager

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
