package main

import "fmt"

type Event struct {
	ID      string
	Type    string
	Payload string
}

func main() {
	fmt.Println("Génération du modèle Event Bus (Go struct, JSON schema)")
	// TODO: Générer event_bus.go, event_bus.schema.json
}
