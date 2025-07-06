package gatewaymanager

import (
	"encoding/json"
	"fmt"
	"io/ioutil"

	"github.com/gerivdb/email-sender-1/development/managers/gateway-manager/discovery"
)

// RunDiscovery scans for MCP servers and saves the results to a file.
func RunDiscovery(outputFile string) error {
	servers := discovery.FindLocalMCPServers()

	if len(servers) > 0 {
		file, err := json.MarshalIndent(servers, "", " ")
		if err != nil {
			return fmt.Errorf("failed to marshal servers to JSON: %w", err)
		}

		err = ioutil.WriteFile(outputFile, file, 0644)
		if err != nil {
			return fmt.Errorf("failed to write servers to file: %w", err)
		}

		fmt.Printf("Detected servers saved to %s\n", outputFile)
	} else {
		fmt.Println("No MCP servers detected.")
	}

	return nil
}