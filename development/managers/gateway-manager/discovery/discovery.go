
package discovery

import (
	"fmt"
	"net"
	"time"
)

// MCPServer represents a detected MCP server.
type MCPServer struct {
	Host    string `json:"host"`
	Port    int    `json:"port"`
	Type    string `json:"type"`
	Version string `json:"version"`
	Status  string `json:"status"`
}

// TestMCPServer checks if a given host and port correspond to a known MCP server type.
func TestMCPServer(host string, port int) *MCPServer {
	// For now, we'll just simulate the detection of a few server types.
	// In a real implementation, this would involve making HTTP requests to health check endpoints.
	if port == 5678 {
		return &MCPServer{Host: host, Port: port, Type: "n8n", Version: "1.0.0", Status: "Active"}
	}
	if port == 8080 {
		return &MCPServer{Host: host, Port: port, Type: "augment", Version: "1.0.0", Status: "Active"}
	}
	return nil
}

// FindLocalMCPServers scans the local network for MCP servers.
func FindLocalMCPServers() []MCPServer {
	fmt.Println("Searching for local MCP servers...")
	servers := []MCPServer{}
	ports := []int{5678, 8080, 3000, 3001, 5000, 5001, 8000, 8888}
	host := "localhost"

	for _, port := range ports {
		conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), 500*time.Millisecond)
		if err == nil {
			conn.Close()
			fmt.Printf("Port %d open on %s\n", port, host)
            if server := TestMCPServer(host, port); server != nil {
                fmt.Printf("MCP Server detected: %s v%s on %s:%d\n", server.Type, server.Version, server.Host, server.Port)
				servers = append(servers, *server)
			}
		}
	}
	return servers
}
