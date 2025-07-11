package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

// Structure pour représenter un manager
type Manager struct {
	Name        string   `json:"name"`
	Path        string   `json:"path"`
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Hooks       []string `json:"hooks,omitempty"`
	Endpoints   []string `json:"endpoints,omitempty"`
}

// Structure pour représenter un hook
type Hook struct {
	Name        string   `json:"name"`
	Path        string   `json:"path"`
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Events      []string `json:"events,omitempty"`
}

// Structure pour représenter un script
type Script struct {
	Name        string   `json:"name"`
	Path        string   `json:"path"`
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Triggers    []string `json:"triggers,omitempty"`
}

// Structure pour représenter un événement
type Event struct {
	Name        string   `json:"name"`
	Type        string   `json:"type"`
	Description string   `json:"description"`
	Producers   []string `json:"producers,omitempty"`
	Consumers   []string `json:"consumers,omitempty"`
}

// Structure pour le rapport complet
type OrchestratorInventory struct {
	Managers []Manager `json:"managers"`
	Hooks    []Hook    `json:"hooks"`
	Scripts  []Script  `json:"scripts"`
	Events   []Event   `json:"events"`
	Metadata struct {
		GeneratedAt string `json:"generated_at"`
		Version     string `json:"version"`
	} `json:"metadata"`
}

// Patterns pour identifier les différents composants
var (
	managerPattern = regexp.MustCompile(`(?i)(manager|orchestrator|controller)\.go$`)
	hookPattern    = regexp.MustCompile(`(?i)(hook|trigger|listener)\.go$`)
	scriptPattern  = regexp.MustCompile(`(?i)\.(go|sh|ps1|py)$`)
	eventPattern   = regexp.MustCompile(`(?i)(event|message|notification|signal)`)
)

func main() {
	fmt.Println("Démarrage de l'inventaire des managers, hooks, scripts et endpoints événementiels...")
	
	// Initialiser l'inventaire
	inventory := OrchestratorInventory{}
	inventory.Metadata.GeneratedAt = time.Now().Format(time.RFC3339)
	inventory.Metadata.Version = "1.0.0"
	
	// Chemin racine du projet
	rootPath := findProjectRoot()
	fmt.Printf("Analyse du projet à partir de: %s\n", rootPath)
	
	// Parcourir le dépôt
	err := filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		// Ignorer les dossiers .git, node_modules, etc.
		if info.IsDir() && (strings.Contains(path, ".git") || 
			strings.Contains(path, "node_modules") || 
			strings.Contains(path, ".vscode")) {
			return filepath.SkipDir
		}
		
		// Traiter uniquement les fichiers
		if !info.IsDir() {
			relPath, _ := filepath.Rel(rootPath, path)
			
			// Identifier les managers
			if managerPattern.MatchString(info.Name()) {
				description := extractDescription(path)
				manager := Manager{
					Name:        info.Name(),
					Path:        relPath,
					Type:        "Go",
					Description: description,
					Hooks:       []string{},
					Endpoints:   []string{},
				}
				
				// Extraire les hooks et endpoints associés
				hooks, endpoints := extractHooksAndEndpoints(path)
				manager.Hooks = hooks
				manager.Endpoints = endpoints
				
				inventory.Managers = append(inventory.Managers, manager)
			}
			
			// Identifier les hooks
			if hookPattern.MatchString(info.Name()) {
				description := extractDescription(path)
				hook := Hook{
					Name:        info.Name(),
					Path:        relPath,
					Type:        "Go",
					Description: description,
					Events:      extractEvents(path),
				}
				inventory.Hooks = append(inventory.Hooks, hook)
			}
			
			// Identifier les scripts
			if scriptPattern.MatchString(info.Name()) && !managerPattern.MatchString(info.Name()) && !hookPattern.MatchString(info.Name()) {
				// Déterminer le type de script
				scriptType := "Unknown"
				switch {
				case strings.HasSuffix(info.Name(), ".go"):
					scriptType = "Go"
				case strings.HasSuffix(info.Name(), ".sh"):
					scriptType = "Bash"
				case strings.HasSuffix(info.Name(), ".ps1"):
					scriptType = "PowerShell"
				case strings.HasSuffix(info.Name(), ".py"):
					scriptType = "Python"
				}
				
				description := extractDescription(path)
				script := Script{
					Name:        info.Name(),
					Path:        relPath,
					Type:        scriptType,
					Description: description,
					Triggers:    extractTriggers(path),
				}
				inventory.Scripts = append(inventory.Scripts, script)
			}
			
			// Collecter les événements
			if eventPattern.MatchString(info.Name()) {
				events := extractAllEvents(path)
				for _, evt := range events {
					// Vérifier si l'événement existe déjà
					exists := false
					for i, existingEvt := range inventory.Events {
						if existingEvt.Name == evt {
							exists = true
							// Ajouter le fichier comme producteur
							inventory.Events[i].Producers = append(inventory.Events[i].Producers, relPath)
							break
						}
					}
					
					if !exists {
						event := Event{
							Name:        evt,
							Type:        "System",
							Description: "Événement détecté dans " + relPath,
							Producers:   []string{relPath},
							Consumers:   []string{},
						}
						inventory.Events = append(inventory.Events, event)
					}
				}
			}
		}
		return nil
	})
	
	if err != nil {
		fmt.Printf("Erreur lors du parcours du dépôt: %v\n", err)
		os.Exit(1)
	}
	
	// Générer le fichier JSON
	jsonData, err := json.MarshalIndent(inventory, "", "  ")
	if err != nil {
		fmt.Printf("Erreur lors de la génération du JSON: %v\n", err)
		os.Exit(1)
	}
	
	// Écrire le fichier JSON
	err = ioutil.WriteFile("event_hooks.json", jsonData, 0644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture du fichier JSON: %v\n", err)
		os.Exit(1)
	}
	
	// Générer le rapport Markdown
	markdownReport := generateMarkdownReport(inventory)
	
	// Afficher le rapport sur la sortie standard
	fmt.Println(markdownReport)
	
	// Écrire le fichier Markdown
	err = ioutil.WriteFile("manager_inventory.md", []byte(markdownReport), 0644)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture du fichier Markdown: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Println("\nInventaire terminé avec succès!")
	fmt.Printf("Managers trouvés: %d\n", len(inventory.Managers))
	fmt.Printf("Hooks trouvés: %d\n", len(inventory.Hooks))
	fmt.Printf("Scripts trouvés: %d\n", len(inventory.Scripts))
	fmt.Printf("Événements trouvés: %d\n", len(inventory.Events))
	fmt.Println("Fichiers générés: manager_inventory.md, event_hooks.json")
}

// Trouver la racine du projet
func findProjectRoot() string {
	// Par défaut, utiliser le répertoire courant
	dir, err := os.Getwd()
	if err != nil {
		fmt.Printf("Erreur lors de la récupération du répertoire courant: %v\n", err)
		os.Exit(1)
	}
	
	// Remonter jusqu'à trouver un fichier go.mod ou .git
	for {
		// Vérifier si go.mod existe
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		
		// Vérifier si .git existe
		if _, err := os.Stat(filepath.Join(dir, ".git")); err == nil {
			return dir
		}
		
		// Remonter d'un niveau
		parent := filepath.Dir(dir)
		if parent == dir {
			// Nous sommes à la racine du système de fichiers
			break
		}
		dir = parent
	}
	
	// Si aucun marqueur de projet n'est trouvé, utiliser le répertoire courant
	cwd, _ := os.Getwd()
	return cwd
}

// Extraire la description d'un fichier
func extractDescription(filePath string) string {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "Pas de description disponible"
	}
	
	// Rechercher les commentaires de description
	lines := strings.Split(string(content), "\n")
	for i, line := range lines {
		if strings.Contains(line, "// Description:") || strings.Contains(line, "# Description:") {
			return strings.TrimSpace(strings.Split(line, "Description:")[1])
		}
		
		// Limiter la recherche aux 30 premières lignes
		if i > 30 {
			break
		}
	}
	
	// Si aucune description explicite n'est trouvée, essayer d'extraire le premier commentaire
	for i, line := range lines {
		if (strings.HasPrefix(strings.TrimSpace(line), "//") || 
			strings.HasPrefix(strings.TrimSpace(line), "#")) && 
			len(strings.TrimSpace(line)) > 3 {
			
			comment := strings.TrimSpace(line)
			if strings.HasPrefix(comment, "//") {
				comment = strings.TrimSpace(comment[2:])
			} else if strings.HasPrefix(comment, "#") {
				comment = strings.TrimSpace(comment[1:])
			}
			
			if len(comment) > 0 && !strings.HasPrefix(comment, "@") && !strings.HasPrefix(comment, "TODO") {
				return comment
			}
		}
		
		// Limiter la recherche aux 30 premières lignes
		if i > 30 {
			break
		}
	}
	
	return "Pas de description disponible"
}

// Extraire les hooks et endpoints d'un manager
func extractHooksAndEndpoints(filePath string) ([]string, []string) {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return []string{}, []string{}
	}
	
	hooks := []string{}
	endpoints := []string{}
	
	// Patterns pour détecter les hooks et endpoints
	hookRegex := regexp.MustCompile(`(?i)(RegisterHook|AddHook|Hook\()\s*["']([^"']+)["']`)
	endpointRegex := regexp.MustCompile(`(?i)(RegisterEndpoint|AddEndpoint|Endpoint\()\s*["']([^"']+)["']`)
	
	// Rechercher les hooks
	hookMatches := hookRegex.FindAllStringSubmatch(string(content), -1)
	for _, match := range hookMatches {
		if len(match) > 2 {
			hooks = append(hooks, match[2])
		}
	}
	
	// Rechercher les endpoints
	endpointMatches := endpointRegex.FindAllStringSubmatch(string(content), -1)
	for _, match := range endpointMatches {
		if len(match) > 2 {
			endpoints = append(endpoints, match[2])
		}
	}
	
	return hooks, endpoints
}

// Extraire les événements d'un hook
func extractEvents(filePath string) []string {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return []string{}
	}
	
	events := []string{}
	
	// Pattern pour détecter les événements
	eventRegex := regexp.MustCompile(`(?i)(Subscribe|Listen|On|HandleEvent)\s*["']([^"']+)["']`)
	
	// Rechercher les événements
	eventMatches := eventRegex.FindAllStringSubmatch(string(content), -1)
	for _, match := range eventMatches {
		if len(match) > 2 {
			events = append(events, match[2])
		}
	}
	
	return events
}

// Extraire les déclencheurs d'un script
func extractTriggers(filePath string) []string {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return []string{}
	}
	
	triggers := []string{}
	
	// Pattern pour détecter les déclencheurs
	triggerRegex := regexp.MustCompile(`(?i)(Trigger|RunOn|ExecuteOn|When)\s*["']([^"']+)["']`)
	
	// Rechercher les déclencheurs
	triggerMatches := triggerRegex.FindAllStringSubmatch(string(content), -1)
	for _, match := range triggerMatches {
		if len(match) > 2 {
			triggers = append(triggers, match[2])
		}
	}
	
	return triggers
}

// Extraire tous les événements d'un fichier
func extractAllEvents(filePath string) []string {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return []string{}
	}
	
	events := []string{}
	
	// Pattern pour détecter les événements
	eventRegex := regexp.MustCompile(`(?i)(Event|Message|Notification|Signal)\s*["']([^"']+)["']`)
	
	// Rechercher les événements
	eventMatches := eventRegex.FindAllStringSubmatch(string(content), -1)
	for _, match := range eventMatches {
		if len(match) > 2 {
			events = append(events, match[2])
		}
	}
	
	return events
}

// Générer le rapport Markdown
func generateMarkdownReport(inventory OrchestratorInventory) string {
	var report strings.Builder
	
	// En-tête
	report.WriteString("# Inventaire des Managers, Hooks, Scripts et Événements\n\n")
	report.WriteString(fmt.Sprintf("*Généré automatiquement le %s*\n\n", inventory.Metadata.GeneratedAt))
	
	// Résumé
	report.WriteString("## Résumé\n\n")
	report.WriteString(fmt.Sprintf("- **Managers**: %d\n", len(inventory.Managers)))
	report.WriteString(fmt.Sprintf("- **Hooks**: %d\n", len(inventory.Hooks)))
	report.WriteString(fmt.Sprintf("- **Scripts**: %d\n", len(inventory.Scripts)))
	report.WriteString(fmt.Sprintf("- **Événements**: %d\n\n", len(inventory.Events)))
	
	// Managers
	report.WriteString("## Managers\n\n")
	if len(inventory.Managers) > 0 {
		report.WriteString("| Nom | Chemin | Type | Description | Hooks | Endpoints |\n")
		report.WriteString("|-----|--------|------|-------------|-------|-----------|\n")
		
		for _, manager := range inventory.Managers {
			hooks := strings.Join(manager.Hooks, ", ")
			endpoints := strings.Join(manager.Endpoints, ", ")
			
			report.WriteString(fmt.Sprintf("| %s | %s | %s | %s | %s | %s |\n", 
				manager.Name, manager.Path, manager.Type, manager.Description, hooks, endpoints))
		}
	} else {
		report.WriteString("*Aucun manager trouvé*\n")
	}
	report.WriteString("\n")
	
	// Hooks
	report.WriteString("## Hooks\n\n")
	if len(inventory.Hooks) > 0 {
		report.WriteString("| Nom | Chemin | Type | Description | Événements |\n")
		report.WriteString("|-----|--------|------|-------------|-----------|\n")
		
		for _, hook := range inventory.Hooks {
			events := strings.Join(hook.Events, ", ")
			
			report.WriteString(fmt.Sprintf("| %s | %s | %s | %s | %s |\n", 
				hook.Name, hook.Path, hook.Type, hook.Description, events))
		}
	} else {
		report.WriteString("*Aucun hook trouvé*\n")
	}
	report.WriteString("\n")
	
	// Scripts
	report.WriteString("## Scripts\n\n")
	if len(inventory.Scripts) > 0 {
		report.WriteString("| Nom | Chemin | Type | Description | Déclencheurs |\n")
		report.WriteString("|-----|--------|------|-------------|-------------|\n")
		
		for _, script := range inventory.Scripts {
			triggers := strings.Join(script.Triggers, ", ")
			
			report.WriteString(fmt.Sprintf("| %s | %s | %s | %s | %s |\n", 
				script.Name, script.Path, script.Type, script.Description, triggers))
		}
	} else {
		report.WriteString("*Aucun script trouvé*\n")
	}
	report.WriteString("\n")
	
	// Événements
	report.WriteString("## Événements\n\n")
	if len(inventory.Events) > 0 {
		report.WriteString("| Nom | Type | Description | Producteurs | Consommateurs |\n")
		report.WriteString("|-----|------|-------------|------------|--------------|\n")
		
		for _, event := range inventory.Events {
			producers := strings.Join(event.Producers, ", ")
			consumers := strings.Join(event.Consumers, ", ")
			
			report.WriteString(fmt.Sprintf("| %s | %s | %s | %s | %s |\n", 
				event.Name, event.Type, event.Description, producers, consumers))
		}
	} else {
		report.WriteString("*Aucun événement trouvé*\n")
	}
	
	// Pied de page
	report.WriteString("\n---\n\n")
	report.WriteString("*Ce document est généré automatiquement par l'outil orchestrator-scanner. Ne pas modifier manuellement.*\n")
	
	return report.String()
}
