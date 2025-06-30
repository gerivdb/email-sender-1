package main

import (
	"flag"
	"fmt"
)

func RunMinimalCli() {
	command := flag.String("command", "help", "Command to execute")
	flag.Parse()

	fmt.Printf("Command: %s\n", *command)

	switch *command {
	case "help":
		fmt.Println("Contextual Memory Manager CLI")
		fmt.Println("Commands:")
		fmt.Println("  help    - Show this help")
		fmt.Println("  version - Show version")
	case "version":
		fmt.Println("Version 1.0.0")
	default:
		fmt.Printf("Unknown command: %s\n", *command)
	}
}
