package main

import (
	"flag"
	"fmt"
	"os"
	"D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/core/config"
)

func main() {
	configPath := flag.String("config", "config.yaml", "Path to config file")
	flag.Parse()
	cfg, err := config.LoadConfigYAML(*configPath)
	if err != nil {
		fmt.Println("Error loading config:", err)
		os.Exit(1)
	}
	fmt.Println("Loaded config:", cfg)
}
