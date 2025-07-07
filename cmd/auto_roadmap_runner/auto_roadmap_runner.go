package auto_roadmap_runner

import (
	"bytes"
	"fmt"
	"os/exec"
	"time"
)

// Script represents a script to be executed by the orchestrator.
type Script struct {
	Name       string
	Path       string
	EntryPoint string // e.g., "go run", "bash", "pwsh -File"
	Args       []string
	DependsOn  []string // Names of other scripts this one depends on
	Executed   bool
	Success    bool
	Output     string
	Error      string
}

func main() {
	fmt.Println("# Orchestration globale : démarrage")

	// Define all scripts with their actual paths and entry points
	scripts := []Script{
		{Name: "audit_read_file", Path: "cmd/audit_read_file/audit_read_file.go", EntryPoint: "go run", Args: []string{}},
		{Name: "gap_analysis", Path: "cmd/gap_analysis/gap_analysis.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{"audit_read_file"}}, // Depends on audit report
		{Name: "gen_user_needs_template", Path: "scripts/gen_user_needs_template.sh", EntryPoint: "bash", Args: []string{}},
		{Name: "collect_user_needs", Path: "scripts/collect_user_needs.sh", EntryPoint: "bash", Args: []string{}, DependsOn: []string{"gen_user_needs_template"}},
		{Name: "validate_and_archive_user_needs", Path: "scripts/validate_and_archive_user_needs.sh", EntryPoint: "bash", Args: []string{}, DependsOn: []string{"collect_user_needs"}},
		{Name: "gen_read_file_spec", Path: "cmd/gen_read_file_spec/gen_read_file_spec.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{"validate_and_archive_user_needs"}},
		{Name: "archive_spec", Path: "scripts/archive_spec.sh", EntryPoint: "bash", Args: []string{}, DependsOn: []string{"gen_read_file_spec"}},
		{Name: "read_file_lib_tests", Path: "pkg/common/read_file_test.go", EntryPoint: "go test", Args: []string{"-v", "-cover"}, DependsOn: []string{}}, // Assuming common lib is built by now
		{Name: "read_file_navigator", Path: "cmd/read_file_navigator/read_file_navigator.go", EntryPoint: "go run", Args: []string{"--file", "test_large_file.txt", "--action", "first", "--block-size", "10"}, DependsOn: []string{"read_file_lib_tests"}},
		{Name: "vscode_extension_validation", Path: "scripts/vscode_read_file_selection.js", EntryPoint: "node", Args: []string{}, DependsOn: []string{"read_file_navigator"}}, // Placeholder for actual VSCode validation
		{Name: "gen_read_file_report", Path: "scripts/gen_read_file_report.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{"read_file_lib_tests", "vscode_extension_validation"}},
		{Name: "docs_update", Path: "docs/read_file_README.md", EntryPoint: "echo", Args: []string{"Documentation is updated."}, DependsOn: []string{"gen_read_file_report"}}, // Placeholder for actual doc update check
		{Name: "collect_user_feedback_bash", Path: "scripts/collect_user_feedback.sh", EntryPoint: "bash", Args: []string{}, DependsOn: []string{}},
		{Name: "collect_user_feedback_powershell", Path: "scripts/collect_user_feedback.ps1", EntryPoint: "pwsh -File", Args: []string{}, DependsOn: []string{}},
		{Name: "audit_rollback_points", Path: "cmd/audit_rollback_points/audit_rollback_points.go", EntryPoint: "go run", Args: []string{}},
		{Name: "gen_rollback_spec", Path: "cmd/gen_rollback_spec/gen_rollback_spec.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{"audit_rollback_points"}},
		{Name: "backup", Path: "scripts/backup/backup.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{}},
		{Name: "backup_tests", Path: "scripts/backup/backup_test.go", EntryPoint: "go test", Args: []string{"-v"}, DependsOn: []string{"backup"}},
		{Name: "git_versioning", Path: "scripts/git_versioning.sh", EntryPoint: "bash", Args: []string{}},
		{Name: "gen_rollback_report", Path: "scripts/gen_rollback_report/gen_rollback_report.go", EntryPoint: "go run", Args: []string{}, DependsOn: []string{"backup", "git_versioning"}},
		{Name: "collect_rollback_feedback_bash", Path: "scripts/collect_rollback_feedback.sh", EntryPoint: "bash", Args: []string{}, DependsOn: []string{}},
		{Name: "collect_rollback_feedback_powershell", Path: "scripts/collect_rollback_feedback.ps1", EntryPoint: "pwsh -File", Args: []string{}, DependsOn: []string{}},
	}

	// Prepare a map for quick access to scripts
	scriptMap := make(map[string]*Script)
	for i := range scripts {
		scriptMap[scripts[i].Name] = &scripts[i]
	}

	// Execute scripts based on dependencies
	for _, script := range scripts {
		if !script.Executed {
			executeScript(scriptMap, script.Name)
		}
	}

	fmt.Println("\n# Orchestration globale : terminée")
	// You might want to generate a final summary report here
}

func executeScript(scriptMap map[string]*Script, scriptName string) {
	script := scriptMap[scriptName]
	if script == nil || script.Executed {
		return
	}

	// Execute dependencies first
	for _, depName := range script.DependsOn {
		dep := scriptMap[depName]
		if dep != nil && !dep.Executed {
			executeScript(scriptMap, depName)
		}
	}

	fmt.Printf("\n--- Exécution du script: %s (%s %s) ---\n", script.Name, script.EntryPoint, script.Path)
	script.Executed = true // Mark as attempted

	var cmd *exec.Cmd
	fullArgs := append([]string{script.Path}, script.Args...)

	switch script.EntryPoint {
	case "go run":
		cmd = exec.Command("go", append([]string{"run"}, fullArgs...)...)
	case "go test":
		cmd = exec.Command("go", append([]string{"test"}, fullArgs...)...)
	case "bash":
		cmd = exec.Command("bash", fullArgs...)
	case "pwsh -File":
		cmd = exec.Command("pwsh", append([]string{"-File"}, fullArgs...)...)
	case "node":
		cmd = exec.Command("node", fullArgs...)
	case "echo": // For placeholder scripts like docs_update
		cmd = exec.Command("echo", fullArgs...)
	default:
		script.Success = false
		script.Error = fmt.Sprintf("Point d'entrée non reconnu: %s", script.EntryPoint)
		fmt.Printf("ERREUR: %s\n", script.Error)
		return
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	start := time.Now()
	err := cmd.Run()
	duration := time.Since(start)

	if err != nil {
		script.Success = false
		script.Error = fmt.Sprintf("Erreur d'exécution: %v\nStderr: %s", err, stderr.String())
		fmt.Printf("ERREUR: %s\n", script.Error)
	} else {
		script.Success = true
		fmt.Println("SUCCÈS.")
	}
	script.Output = stdout.String()
	fmt.Printf("Durée: %s\n", duration)
	fmt.Printf("Sortie standard:\n%s\n", script.Output)
	if stderr.Len() > 0 {
		fmt.Printf("Sortie d'erreur:\n%s\n", stderr.String())
	}
}
