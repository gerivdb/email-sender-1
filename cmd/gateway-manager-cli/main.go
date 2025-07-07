package main

import (
	"fmt"
	"os"

	gatewaymanager "github.com/gerivdb/email-sender-1/development/managers/gateway-manager"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: gateway-manager-cli <command>")
		fmt.Println("Available commands: discover")
		os.Exit(1)
	}

	command := os.Args[1]

	switch command {
	case "discover":
		outputFile := "detected-servers.json"
		if len(os.Args) > 2 {
			outputFile = os.Args[2]
		}
		err := gatewaymanager.RunDiscovery(outputFile)
		if err != nil {
			fmt.Printf("Error during discovery: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Printf("Unknown command: %s\n", command)
		os.Exit(1)
	}
}
