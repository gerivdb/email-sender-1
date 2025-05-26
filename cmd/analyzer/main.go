package main

import (
	"flag"
	"fmt"
	"log"
	"os"
)

func main() {
	// Gestion des flags CLI
	port := flag.Int("port", 8080, "Port du serveur HTTP")
	logLevel := flag.String("log", "info", "Niveau de log (info, debug, warn, error)")
	flag.Parse()

	fmt.Printf("[INFO] Lancement du serveur HTTP sur le port %d (log: %s)\n", *port, *logLevel)

	// Initialisation du logger (placeholder, à remplacer par logrus/zap)
	log.SetOutput(os.Stdout)
	log.SetPrefix("[analyzer] ")
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// TODO: Appeler le point d'entrée du serveur HTTP
	// server.Start(*port)
}
