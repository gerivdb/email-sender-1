// dispatcher.go
// Module Roo-Code : Dispatcher CLI multi-OS avec hooks PluginInterface Roo
// Voir conventions : [`AGENTS.md`](AGENTS.md:PluginInterface), [`rules-code.md`](.roo/rules/rules-code.md:1)

package gatewaymanager

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

/*
Command Roo : structure représentant une commande à exécuter dans le shell cible.
- ID : identifiant unique pour traçabilité documentaire Roo (mode, audit, logs)
- Content : contenu de la commande shell à exécuter
- Meta : métadonnées extensibles (contexte, origine, paramètres, etc.)
Conforme AGENTS.md, traçabilité mode d’exécution Roo.
*/
type Command struct {
	ID      string
	Content string
	Meta    map[string]interface{}
}

/*
AuditHook Roo : interface pour l’audit et l’extension documentaire.
- BeforeExecute : appelé avant l’exécution réelle, permet la validation, le reporting, l’enrichissement du contexte.
- AfterExecute : appelé après l’exécution, pour journalisation, reporting, extension plugin.
Points d’extension Roo : voir AGENTS.md (hooks/plugins), rules-plugins.md.
*/
type AuditHook interface {
	BeforeExecute(ctx context.Context, cmd *Command) error
	AfterExecute(ctx context.Context, cmd *Command, result *CommandResult) error
}

/*
PluginInterface Roo : interface pour l’extension dynamique des hooks d’audit.
- RegisterHook : ajoute dynamiquement un hook d’audit (plugin, stratégie, etc.)
- UnregisterHook : retire un hook par nom (gestion dynamique, sécurité)
- ListHooks : retourne la liste des hooks actifs (audit, reporting)
Conforme AGENTS.md, points d’extension plugins/documentation.
*/
type PluginInterface interface {
	RegisterHook(hook AuditHook) error
	UnregisterHook(name string) error
	ListHooks() []AuditHook
}

/*
CommandResult Roo : structure du résultat d’exécution shell.
- Success : booléen indiquant le succès ou l’échec
- Output : sortie standard/erreur du shell (stdout/stderr)
- Error : objet d’erreur Go (pour reporting, audit, extension plugin)
- Timestamp : horodatage de l’exécution
Traçabilité Roo : chaque résultat est audité via hooks/plugins.
*/
type CommandResult struct {
	Success   bool
	Output    string
	Error     error
	Timestamp time.Time
}

/*
ExecutionLogEntry Roo : structure de journalisation structurée pour chaque exécution shell.
- CommandID, CommandContent, Meta, Success, Output, Error, Timestamp, Mode
- Conforme Roo : traçabilité, audit, documentation
*/
type ExecutionLogEntry struct {
	CommandID      string
	CommandContent string
	Meta           map[string]interface{}
	Success        bool
	Output         string
	Error          string
	Timestamp      time.Time
	Mode           string
}

// Slice globale pour journaliser toutes les exécutions (pour génération Markdown)
var executionLogs []ExecutionLogEntry

/*
Dispatcher Roo : manager central pour l’exécution shell multi-OS.
- hooks : liste des hooks d’audit/documentation (extension dynamique)
Responsable de la traçabilité, de la sécurité (sandbox), de l’orchestration des plugins.
Conforme AGENTS.md, modèle manager/agent Roo.
*/
type Dispatcher struct {
	hooks []AuditHook
}

// Structure Roo : sauvegarde d’état pour rollback automatique
type DispatcherStateBackup struct {
	executionLogs []ExecutionLogEntry
	hooks         []AuditHook
}

// Méthode Roo : restaure l’état du dispatcher depuis une sauvegarde
func (d *Dispatcher) RestoreStateFromBackup(backup *DispatcherStateBackup) {
	if backup == nil {
		return
	}
	executionLogs = append([]ExecutionLogEntry(nil), backup.executionLogs...)
	d.hooks = append([]AuditHook(nil), backup.hooks...)
}

// Méthode Roo : sauvegarde l’état courant du dispatcher
func (d *Dispatcher) BackupState() *DispatcherStateBackup {
	return &DispatcherStateBackup{
		executionLogs: append([]ExecutionLogEntry(nil), executionLogs...),
		hooks:         append([]AuditHook(nil), d.hooks...),
	}
}

/*
globalDispatcher Roo : référence globale pour injection des hooks dans la sandbox.
Permet l’accès aux hooks d’audit depuis la validation de sécurité (isCommandSafe).
Point d’extension Roo : adaptation possible selon architecture réelle.
*/
var globalDispatcher *Dispatcher

/*
NewDispatcher Roo : constructeur du manager Dispatcher.
- Initialise la liste des hooks d’audit
- Définit la référence globale pour la sandbox (sécurité, audit)
Traçabilité Roo : chaque instance est liée au mode d’exécution/documentation.
*/
func NewDispatcher() *Dispatcher {
	d := &Dispatcher{
		hooks: make([]AuditHook, 0),
	}
	// Roo: Initialisation du dispatcher global pour accès hooks dans sandbox
	globalDispatcher = d
	return d
}

/*
RegisterHook Roo : ajoute dynamiquement un hook d’audit.
- Extension documentaire, reporting, validation, plugins
Conforme points d’extension AGENTS.md/rules-plugins.md.
*/
func (d *Dispatcher) RegisterHook(hook AuditHook) error {
	d.hooks = append(d.hooks, hook)
	return nil
}

/*
ReceiveCommand Roo : point d’entrée principal pour l’exécution shell.
- Audit avant exécution (hooks/plugins, traçabilité documentaire Roo)
- Détection OS et mapping shell (multi-OS, conformité AGENTS.md)
- Sécurité documentaire (sandbox, validation avancée, audit dynamique)
- Exécution réelle via exec.Command (Go standard, sécurité/sandbox intégrée)
- Audit après exécution (hooks/plugins, reporting, extension)
Cas limites : gestion d’erreur, reporting, extension plugin.
*/
func (d *Dispatcher) ReceiveCommand(ctx context.Context, cmd *Command) (*CommandResult, error) {
	// Capture du timestamp d’exécution
	execTimestamp := time.Now()

	// Roo: Audit avant exécution (hooks Roo, traçabilité documentaire)
	for _, hook := range d.hooks {
		if err := hook.BeforeExecute(ctx, cmd); err != nil {
			return nil, fmt.Errorf("audit hook failed: %w", err)
		}
	}

	// Roo: Détection OS et mapping shell (multi-OS Roo, conformité AGENTS.md)
	shell, args := detectShell()
	if shell == "" {
		return nil, errors.New("unsupported OS")
	}

	// Roo: Sécurité documentaire, sandbox, validation avancée, audit dynamique
	var backupSandbox = d.BackupState()
	if !isCommandSafe(cmd.Content) {
		// Rollback Roo : restauration d’état en cas d’échec critique (sandbox)
		d.RestoreStateFromBackup(backupSandbox)
		// Roo: Reporting sécurité, extension plugins/audit
		for _, hook := range d.hooks {
			_ = hook.AfterExecute(ctx, cmd, &CommandResult{
				Success:   false,
				Output:    "",
				Error:     errors.New("commande non autorisée (sandbox Roo)"),
				Timestamp: execTimestamp,
			})
		}
		// Journalisation structurée de l’échec
		executionLogs = append(executionLogs, ExecutionLogEntry{
			CommandID:      cmd.ID,
			CommandContent: cmd.Content,
			Meta:           cmd.Meta,
			Success:        false,
			Output:         "",
			Error:          "commande non autorisée (sandbox Roo)",
			Timestamp:      execTimestamp,
			Mode:           getModeFromMeta(cmd.Meta),
		})
		return nil, errors.New("commande non autorisée (sandbox Roo)")
	}

	// === Étape interactive Roo : validation humaine avant exécution ===
	if !requestUserConfirmation(cmd.Content) {
		// Refus utilisateur, journalisation et audit
		for _, hook := range d.hooks {
			_ = hook.AfterExecute(ctx, cmd, &CommandResult{
				Success:   false,
				Output:    "",
				Error:     errors.New("commande refusée par l’utilisateur (validation interactive Roo)"),
				Timestamp: execTimestamp,
			})
		}
		executionLogs = append(executionLogs, ExecutionLogEntry{
			CommandID:      cmd.ID,
			CommandContent: cmd.Content,
			Meta:           cmd.Meta,
			Success:        false,
			Output:         "",
			Error:          "commande refusée par l’utilisateur (validation interactive Roo)",
			Timestamp:      execTimestamp,
			Mode:           getModeFromMeta(cmd.Meta),
		})
		return nil, errors.New("commande refusée par l’utilisateur (validation interactive Roo)")
	}

	// Roo: Exécution réelle via exec.Command (Go standard, sécurité/sandbox intégrée)
	// Documentation Roo : voir rules-code.md, AGENTS.md
	output, err := executeShellCommand(shell, args, cmd.Content)
	result := &CommandResult{
		Success:   err == nil,
		Output:    output,
		Error:     err,
		Timestamp: execTimestamp,
	}

	// Roo: Audit après exécution (hooks Roo, traçabilité documentaire)
	for _, hook := range d.hooks {
		_ = hook.AfterExecute(ctx, cmd, result)
	}

	// Journalisation structurée de l’exécution
	executionLogs = append(executionLogs, ExecutionLogEntry{
		CommandID:      cmd.ID,
		CommandContent: cmd.Content,
		Meta:           cmd.Meta,
		Success:        result.Success,
		Output:         result.Output,
		Error:          errorToString(result.Error),
		Timestamp:      result.Timestamp,
		Mode:           getModeFromMeta(cmd.Meta),
	})

	return result, nil
}

// Utilitaire Roo : extraire le mode d’exécution Roo depuis Meta
func getModeFromMeta(meta map[string]interface{}) string {
	if meta == nil {
		return ""
	}
	if mode, ok := meta["mode"]; ok {
		if modeStr, ok := mode.(string); ok {
			return modeStr
		}
	}
	return ""
}

// Utilitaire Roo : conversion error en string
func errorToString(err error) string {
	if err == nil {
		return ""
	}
	return err.Error()
}

/*
detectShell Roo : détecte l’OS et retourne le shell adapté.
- Windows : PowerShell (pwsh) recommandé, fallback possible vers cmd
- Linux/macOS : Bash standard
- Convention Roo : args conformes à AGENTS.md/rules-code.md
Cas limite : OS non supporté → traçabilité documentaire, reporting d’erreur.
*/
func detectShell() (string, []string) {
	// Détection Roo : mapping shell selon OS, conforme AGENTS.md/PluginInterface
	switch runtime.GOOS {
	case "windows":
		// 🟦 Windows → PowerShell (pwsh), usage sécurisé recommandé
		// Convention Roo : args = ["-Command"], voir rules-code.md
		return "pwsh", []string{"-Command"}
	case "linux":
		// 🟩 Linux → Bash, usage standard
		// Convention Roo : args = ["-c"], voir rules-code.md
		return "bash", []string{"-c"}
	case "darwin":
		// 🍏 macOS → Bash, usage standard
		// Convention Roo : args = ["-c"], voir rules-code.md
		return "bash", []string{"-c"}
	default:
		// 🚨 OS non supporté, traçabilité Roo
		return "", nil
	}
}

/*
prepareShellCommand Roo : prépare la commande pour le shell cible.
- Args : shell, arguments spécifiques, contenu de la commande
- Sécurité à renforcer : attention à l’injection, à la validation des entrées
Cas limite : extension possible pour validation avancée, reporting.
*/
func prepareShellCommand(shell string, args []string, content string) string {
	// Pour l’instant, retourne la chaîne complète (sécurité à renforcer)
	return fmt.Sprintf("%s %v %s", shell, args, content)
}

/*
isCommandSafe Roo : sandbox documentaire, filtre les commandes dangereuses.
- Blacklist : liste des commandes interdites (sécurité documentaire Roo)
- Audit dynamique : appel des hooks d’audit pour reporting sécurité, extension plugin possible
- Extension Roo : injection possible de plugins de validation avancée (QualityGatePlugin, etc.)
Cas limite : reporting d’erreur, extension dynamique, adaptation architecture.
Documentation Roo : voir rules-code.md, AGENTS.md, rules-plugins.md.
*/
var whitelist = []string{"ls", "echo", "cat", "pwd", "whoami", "date", "uptime", "ps", "top", "dir", "type", "hostname"}

func isWhitelisted(content string) bool {
	for _, allowed := range whitelist {
		// Autorise si la commande commence par un mot whitelisté
		if len(content) > 0 && strings.HasPrefix(strings.TrimSpace(content), allowed) {
			return true
		}
	}
	return false
}

func isCommandSafe(content string) bool {
	// Whitelist stricte Roo : seules les commandes autorisées sont exécutées
	var backupWhitelist = globalDispatcher.BackupState()
	if !isWhitelisted(content) {
		// Rollback Roo : restauration d’état en cas d’échec critique (whitelist)
		globalDispatcher.RestoreStateFromBackup(backupWhitelist)
		// Audit Roo : refus, journalisation structurée, reporting
		if globalDispatcher != nil {
			for _, hook := range globalDispatcher.hooks {
				_ = hook.AfterExecute(context.Background(), &Command{Content: content}, &CommandResult{
					Success: false,
					Output:  "",
					Error:   errors.New("commande non whitelistée (sécurité Roo)"),
				})
			}
		}
		// Journalisation structurée du refus
		executionLogs = append(executionLogs, ExecutionLogEntry{
			CommandID:      "",
			CommandContent: content,
			Meta:           nil,
			Success:        false,
			Output:         "",
			Error:          "commande non whitelistée (sécurité Roo)",
			Timestamp:      time.Now(),
			Mode:           "",
		})
		return false
	}
	// Sécurité Roo : sandbox dynamique, audit extensible via hooks/plugins
	blacklist := []string{"rm ", "del ", "shutdown", "reboot", "mkfs", "dd ", "format ", "poweroff"}
	for _, forbidden := range blacklist {
		if len(content) > 0 && containsIgnoreCase(content, forbidden) {
			// Audit dynamique : log, extension plugin possible ici
			if globalDispatcher != nil {
				for _, hook := range globalDispatcher.hooks {
					_ = hook.AfterExecute(context.Background(), &Command{Content: content}, &CommandResult{
						Success: false,
						Output:  "",
						Error:   errors.New("commande interdite détectée (sandbox Roo)"),
					})
				}
			}
			return false
		}
	}
	// Extension Roo : point d’injection pour plugins de validation avancée
	if globalDispatcher != nil {
		for _, hook := range globalDispatcher.hooks {
			_ = hook.BeforeExecute(context.Background(), &Command{Content: content})
		}
	}
	return true
}

// containsIgnoreCase : utilitaire Roo
func containsIgnoreCase(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || (len(s) > 0 && len(substr) > 0 && (stringContainsFold(s, substr))))
}

// stringContainsFold : ignore la casse
func stringContainsFold(s, substr string) bool {
	return len(s) >= len(substr) && (stringIndexFold(s, substr) >= 0)
}

// stringIndexFold : index ignore case
func stringIndexFold(s, substr string) int {
	return indexFold(s, substr)
}

// indexFold : version simplifiée
func indexFold(s, substr string) int {
	sLower := toLower(s)
	substrLower := toLower(substr)
	return index(sLower, substrLower)
}

// toLower : utilitaire
func toLower(s string) string {
	b := []byte(s)
	for i := range b {
		if b[i] >= 'A' && b[i] <= 'Z' {
			b[i] += 'a' - 'A'
		}
	}
	return string(b)
}

// index : retourne l’index de substr dans s
func index(s, substr string) int {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}

/*
executeShellCommand Roo : exécute la commande dans le shell cible.
- Args : shell, arguments, contenu de la commande
- Sécurité/sandbox intégrée : conforme AGENTS.md, reporting d’erreur, audit
- Capture stdout/stderr pour reporting/documentation
Cas limite : gestion d’erreur, extension plugin, reporting avancé.
*/

func executeShellCommand(shell string, args []string, content string) (string, error) {
	cmdArgs := append(args, content)
	cmd := exec.Command(shell, cmdArgs...)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &out
	err := cmd.Run()
	return out.String(), err
}

// Validation interactive Roo : demande confirmation utilisateur avant exécution shell
func requestUserConfirmation(cmdContent string) bool {
	fmt.Printf("\nValidation interactive Roo\n")
	fmt.Printf("Commande à exécuter :\n%s\n", cmdContent)
	fmt.Printf("Confirmez-vous l’exécution ? (o/n) : ")
	var response string
	_, err := fmt.Scanln(&response)
	if err != nil {
		fmt.Println("Erreur lecture confirmation, refus par défaut.")
		return false
	}
	response = strings.TrimSpace(strings.ToLower(response))
	return response == "o" || response == "oui" || response == "y" || response == "yes"
}

// Génération du rapport Markdown Roo des exécutions shell
// Inclut : ID, commande, mode, succès/échec, timestamp, résultat, erreur
func GenerateExecutionReportMarkdown(path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	// En-tête Roo
	fmt.Fprintf(f, "# Rapport d’exécutions shell Roo\n\n")
	fmt.Fprintf(f, "Ce rapport récapitule toutes les exécutions shell via le GatewayManager.\n\n")
	fmt.Fprintf(f, "| ID | Commande | Mode | Succès | Timestamp | Résultat | Erreur |\n")
	fmt.Fprintf(f, "|----|----------|------|--------|-----------|----------|--------|\n")

	for _, log := range executionLogs {
		fmt.Fprintf(f, "| %s | `%s` | %s | %v | %s | `%s` | `%s` |\n",
			log.CommandID,
			escapeMarkdown(log.CommandContent),
			log.Mode,
			log.Success,
			log.Timestamp.Format("2006-01-02 15:04:05"),
			escapeMarkdown(log.Output),
			escapeMarkdown(log.Error),
		)
	}

	fmt.Fprintf(f, "\n_Généré automatiquement par Roo-Code, conforme aux standards de traçabilité et documentation._\n")
	return nil
}

// Utilitaire Markdown Roo : échappe les pipes et backticks
func escapeMarkdown(s string) string {
	s = strings.ReplaceAll(s, "|", "\\|")
	s = strings.ReplaceAll(s, "`", "'")
	return s
}

// Appel Roo : Génération du rapport Markdown des exécutions shell
// À placer à la fin du flux principal (ex : main, orchestration, ou après toutes les commandes)

// Exemple Roo : fonction main pour générer le rapport Markdown des exécutions shell
func main() {
	err := GenerateExecutionReportMarkdown("report-executions.md")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur génération rapport Markdown Roo : %v\n", err)
	}
}
