package adapters

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/pkg/errors"
)

// ScriptInventoryAdapter gère l'intégration avec l'infrastructure PowerShell existante
type ScriptInventoryAdapter struct {
	scriptPath       string
	pythonPath       string
	workingDirectory string
	timeout          time.Duration
	ctx              context.Context
}

// ScriptInventoryConfig configuration pour l'adaptateur
type ScriptInventoryConfig struct {
	ScriptInventoryPath string `json:"script_inventory_path"`
	PythonExecutable    string `json:"python_executable"`
	WorkingDirectory    string `json:"working_directory"`
	TimeoutSeconds      int    `json:"timeout_seconds"`
}

// ScriptInventoryResult résultat de l'exécution du script d'inventaire
type ScriptInventoryResult struct {
	Success       bool                   `json:"success"`
	Scripts       []ScriptInfo           `json:"scripts"`
	Errors        []string               `json:"errors"`
	ExecutionTime time.Duration          `json:"execution_time"`
	Metadata      map[string]interface{} `json:"metadata"`
}

// ScriptInfo informations sur un script détecté
type ScriptInfo struct {
	Path         string            `json:"path"`
	Type         string            `json:"type"`
	Size         int64             `json:"size"`
	LastModified time.Time         `json:"last_modified"`
	Hash         string            `json:"hash"`
	Dependencies []string          `json:"dependencies"`
	Metadata     map[string]string `json:"metadata"`
}

// NewScriptInventoryAdapter crée un nouvel adaptateur
func NewScriptInventoryAdapter(config ScriptInventoryConfig) *ScriptInventoryAdapter {
	timeout := 30 * time.Second
	if config.TimeoutSeconds > 0 {
		timeout = time.Duration(config.TimeoutSeconds) * time.Second
	}

	return &ScriptInventoryAdapter{
		scriptPath:       config.ScriptInventoryPath,
		pythonPath:       config.PythonExecutable,
		workingDirectory: config.WorkingDirectory,
		timeout:          timeout,
		ctx:              context.Background(),
	}
}

// ConnectToScriptInventory établit la connexion avec le module PowerShell
// Micro-étape 8.1.2 : Implémenter ConnectToScriptInventory() pour interfacer avec le module PowerShell
func (s *ScriptInventoryAdapter) ConnectToScriptInventory() error {
	// Vérifier que les chemins existent
	if err := s.validatePaths(); err != nil {
		return errors.Wrap(err, "validation des chemins échouée")
	}

	// Tester la connectivité PowerShell
	if err := s.testPowerShellConnectivity(); err != nil {
		return errors.Wrap(err, "test de connectivité PowerShell échoué")
	}

	return nil
}

// validatePaths valide l'existence des chemins requis
func (s *ScriptInventoryAdapter) validatePaths() error {
	paths := map[string]string{
		"ScriptInventoryPath": s.scriptPath,
		"WorkingDirectory":    s.workingDirectory,
	}

	for name, path := range paths {
		if path == "" {
			return fmt.Errorf("%s ne peut pas être vide", name)
		}

		if _, err := os.Stat(path); os.IsNotExist(err) {
			return fmt.Errorf("%s n'existe pas: %s", name, path)
		}
	}

	return nil
}

// testPowerShellConnectivity teste la connectivité avec PowerShell
func (s *ScriptInventoryAdapter) testPowerShellConnectivity() error {
	ctx, cancel := context.WithTimeout(s.ctx, s.timeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "pwsh", "-Command", "Get-Host | Select-Object Version")

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("PowerShell non accessible: %v, stderr: %s", err, stderr.String())
	}

	return nil
}

// ExecuteScriptInventory exécute le module ScriptInventoryManager
// Micro-étape 8.1.3 : Créer des bindings Go-PowerShell via os/exec pour appeler les fonctions du module
func (s *ScriptInventoryAdapter) ExecuteScriptInventory(targetPath string) (*ScriptInventoryResult, error) {
	startTime := time.Now()

	ctx, cancel := context.WithTimeout(s.ctx, s.timeout)
	defer cancel()

	// Construire la commande PowerShell
	psCommand := fmt.Sprintf(`
		Import-Module '%s' -Force;
		$result = Get-ScriptInventory -Path '%s' -Detailed;
		$result | ConvertTo-Json -Depth 10
	`, s.scriptPath, targetPath)

	cmd := exec.CommandContext(ctx, "pwsh", "-Command", psCommand)
	cmd.Dir = s.workingDirectory

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	executionTime := time.Since(startTime)

	result := &ScriptInventoryResult{
		Success:       err == nil,
		ExecutionTime: executionTime,
		Metadata: map[string]interface{}{
			"target_path":    targetPath,
			"execution_time": executionTime.String(),
			"timestamp":      startTime.Unix(),
		},
	}

	if err != nil {
		result.Errors = append(result.Errors, fmt.Sprintf("Erreur d'exécution: %v", err))
		if stderr.Len() > 0 {
			result.Errors = append(result.Errors, fmt.Sprintf("Stderr: %s", stderr.String()))
		}
		return result, errors.Wrap(err, "échec de l'exécution du script d'inventaire")
	}

	// Parser le résultat JSON
	if err := s.parseScriptInventoryOutput(stdout.String(), result); err != nil {
		result.Success = false
		result.Errors = append(result.Errors, fmt.Sprintf("Erreur de parsing: %v", err))
		return result, errors.Wrap(err, "échec du parsing du résultat")
	}

	return result, nil
}

// parseScriptInventoryOutput parse la sortie JSON du script PowerShell
func (s *ScriptInventoryAdapter) parseScriptInventoryOutput(output string, result *ScriptInventoryResult) error {
	output = strings.TrimSpace(output)
	if output == "" {
		return errors.New("sortie vide du script PowerShell")
	}

	var rawResult map[string]interface{}
	if err := json.Unmarshal([]byte(output), &rawResult); err != nil {
		return errors.Wrap(err, "échec du décodage JSON")
	}

	// Convertir les scripts trouvés
	if scriptsData, exists := rawResult["Scripts"]; exists {
		if scriptsArray, ok := scriptsData.([]interface{}); ok {
			for _, scriptData := range scriptsArray {
				if scriptMap, ok := scriptData.(map[string]interface{}); ok {
					script := s.convertToScriptInfo(scriptMap)
					result.Scripts = append(result.Scripts, script)
				}
			}
		}
	}

	return nil
}

// convertToScriptInfo convertit les données brutes en ScriptInfo
func (s *ScriptInventoryAdapter) convertToScriptInfo(data map[string]interface{}) ScriptInfo {
	script := ScriptInfo{
		Metadata: make(map[string]string),
	}

	if path, ok := data["Path"].(string); ok {
		script.Path = path
	}
	if scriptType, ok := data["Type"].(string); ok {
		script.Type = scriptType
	}
	if size, ok := data["Size"].(float64); ok {
		script.Size = int64(size)
	}
	if hash, ok := data["Hash"].(string); ok {
		script.Hash = hash
	}
	if deps, ok := data["Dependencies"].([]interface{}); ok {
		for _, dep := range deps {
			if depStr, ok := dep.(string); ok {
				script.Dependencies = append(script.Dependencies, depStr)
			}
		}
	}

	// Conversion des métadonnées
	if metadata, ok := data["Metadata"].(map[string]interface{}); ok {
		for key, value := range metadata {
			if strValue, ok := value.(string); ok {
				script.Metadata[key] = strValue
			}
		}
	}

	return script
}

// GetScriptDependencies récupère les dépendances d'un script spécifique
func (s *ScriptInventoryAdapter) GetScriptDependencies(scriptPath string) ([]string, error) {
	ctx, cancel := context.WithTimeout(s.ctx, s.timeout)
	defer cancel()

	psCommand := fmt.Sprintf(`
		Import-Module '%s' -Force;
		Get-ScriptDependencies -ScriptPath '%s' | ConvertTo-Json
	`, s.scriptPath, scriptPath)

	cmd := exec.CommandContext(ctx, "pwsh", "-Command", psCommand)
	var stdout bytes.Buffer
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		return nil, errors.Wrap(err, "échec de récupération des dépendances")
	}

	var dependencies []string
	if err := json.Unmarshal(stdout.Bytes(), &dependencies); err != nil {
		return nil, errors.Wrap(err, "échec du parsing des dépendances")
	}

	return dependencies, nil
}
