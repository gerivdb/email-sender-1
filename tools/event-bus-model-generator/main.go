package main

// Ajout de l'import "time" dans le bloc principal
import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"time"
)

// EventModel représente la structure d'un événement pour la génération
type EventModel struct {
	ID        string `json:"id"`
	Type      string `json:"type"`
	Source    string `json:"source"`
	Payload   string `json:"payload"`
	Timestamp string `json:"timestamp"`
}

// EventBusSchema représente le schéma JSON du bus d'événements
type EventBusSchema struct {
	Events []EventModel `json:"events"`
}

// readFile lit le contenu d'un fichier
func readFile(path string) (string, error) {
	content, err := ioutil.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la lecture de %s: %v", path, err)
	}
	return string(content), nil
}

// writeFile écrit le contenu dans un fichier, avec logs et validation robuste
func writeFile(path, content string, onSuccess func(string)) error {
	log.Printf("[writeFile] Début écriture : %s", path)
	err := ioutil.WriteFile(path, []byte(content), 0o644)
	if err != nil {
		log.Printf("[writeFile] Échec écriture : %s, err=%v", path, err)
		return err
	}
	log.Printf("[writeFile] Écriture réussie : %s", path)
	if onSuccess != nil {
		onSuccess(path)
	} else {
		// Validation par attente contrôlée
		maxAttempts := 5
		for i := 0; i < maxAttempts; i++ {
			time.Sleep(100 * time.Millisecond)
			_, err := ioutil.ReadFile(path)
			if err == nil {
				log.Printf("[writeFile] Validation lecture OK : %s (tentative %d)", path, i+1)
				break
			}
			log.Printf("[writeFile] Validation lecture KO : %s (tentative %d)", path, i+1)
			if i == maxAttempts-1 {
				return fmt.Errorf("validation lecture échouée après %d tentatives : %s", maxAttempts, path)
			}
		}
	}
	return nil
}

// generateEventBusGo génère le fichier event_bus.go
func generateEventBusGo() (string, error) {
	content := `package eventbus

type Event struct {
	ID        string ` + "`" + `json:"id"` + "`" + `
	Type      string ` + "`" + `json:"type"` + "`" + `
	Source    string ` + "`" + `json:"source"` + "`" + `
	Payload   string ` + "`" + `json:"payload"` + "`" + `
	Timestamp string ` + "`" + `json:"timestamp"` + "`" + `
}

type EventBus struct {
	Events chan Event
}

func NewEventBus() *EventBus {
	return &EventBus{
		Events: make(chan Event, 100),
	}
}
`
	return content, nil
}

// generateEventBusSchema génère le schéma JSON
func generateEventBusSchema(events []EventModel) (string, error) {
	schema := EventBusSchema{Events: events}
	data, err := json.MarshalIndent(schema, "", "  ")
	if err != nil {
		return "", fmt.Errorf("erreur lors de la génération du schéma JSON: %v", err)
	}
	return string(data), nil
}

// generateEventBusSpec génère la documentation Markdown
func generateEventBusSpec() (string, error) {
	content := `# Spécification du Bus d'Événements

## Structure des Événements
- **ID**: Identifiant unique de l'événement (string)
- **Type**: Type d'événement (string)
- **Source**: Source de l'événement (string)
- **Payload**: Données de l'événement (string)
- **Timestamp**: Horodatage de l'événement (string)

## Canaux
- Le bus utilise un canal Go pour transmettre les événements.
- Capacité du canal: 100 événements.
`
	return content, nil
}

// parseEventHooks lit et parse le fichier event_hooks.json
func parseEventHooks(path string) ([]EventModel, error) {
	content, err := readFile(path)
	if err != nil {
		return nil, err
	}
	var events []EventModel
	if err := json.Unmarshal([]byte(content), &events); err != nil {
		return nil, fmt.Errorf("erreur lors du parsing de %s: %v", path, err)
	}
	return events, nil
}

func main() {
	// Lire event_hooks.json
	events, err := parseEventHooks("event_hooks.json")
	if err != nil {
		log.Fatalf("Erreur lors de la lecture de event_hooks.json: %v", err)
	}

	// Générer event_bus.go
	eventBusGoContent, err := generateEventBusGo()
	if err != nil {
		log.Fatalf("Erreur lors de la génération de event_bus.go: %v", err)
	}
	if err := writeFile("event_bus.go", eventBusGoContent, nil); err != nil {
		log.Fatalf("Erreur lors de l'écriture de event_bus.go: %v", err)
	}

	// Générer event_bus.schema.json
	schemaContent, err := generateEventBusSchema(events)
	if err != nil {
		log.Fatalf("Erreur lors de la génération de event_bus.schema.json: %v", err)
	}
	if err := writeFile("event_bus.schema.json", schemaContent, nil); err != nil {
		log.Fatalf("Erreur lors de l'écriture de event_bus.schema.json: %v", err)
	}

	// Générer EVENT_BUS_SPEC.md
	specContent, err := generateEventBusSpec()
	if err != nil {
		log.Fatalf("Erreur lors de la génération de EVENT_BUS_SPEC.md: %v", err)
	}
	if err := writeFile("EVENT_BUS_SPEC.md", specContent, nil); err != nil {
		log.Fatalf("Erreur lors de l'écriture de EVENT_BUS_SPEC.md: %v", err)
	}

	fmt.Println("Génération terminée avec succès.")
}
