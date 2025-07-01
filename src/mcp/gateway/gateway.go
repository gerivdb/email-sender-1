package gateway

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// MCPResponse représente la structure de réponse MCP
type MCPResponse struct {
	Type	string		`json:"type"`
	Content	interface{}	`json:"content"`
}

// MCPRequest représente la structure de requête MCP
type MCPRequest struct {
	Type	string		`json:"type"`
	Content	json.RawMessage	`json:"content"`
}

// ToolCallRequest représente une requête d'appel d'outil
type ToolCallRequest struct {
	ToolName	string			`json:"tool_name"`
	Parameters	map[string]interface{}	`json:"parameters"`
}

// ToolCallResponse représente une réponse d'appel d'outil
type ToolCallResponse struct {
	Result interface{} `json:"result"`
}

// ListToolsResponse représente une réponse de liste d'outils
type ListToolsResponse struct {
	Tools []Tool `json:"tools"`
}

// Tool représente un outil MCP
type Tool struct {
	Name		string		`json:"name"`
	Description	string		`json:"description"`
	Schema		interface{}	`json:"schema"`
}

// DatabaseTool représente un outil de base de données
type DatabaseTool struct {
	Name		string
	Description	string
	Query		string
	Parameters	map[string]string
}

// Définition des outils disponibles
var databaseTools = []DatabaseTool{
	{
		Name:		"get_customers",
		Description:	"Récupère la liste des clients",
		Query:		"SELECT * FROM customers LIMIT :limit OFFSET :offset",
		Parameters: map[string]string{
			"limit":	"Nombre maximum de résultats à retourner",
			"offset":	"Nombre de résultats à ignorer",
		},
	},
	{
		Name:		"get_orders",
		Description:	"Récupère la liste des commandes",
		Query:		"SELECT * FROM orders LIMIT :limit OFFSET :offset",
		Parameters: map[string]string{
			"limit":	"Nombre maximum de résultats à retourner",
			"offset":	"Nombre de résultats à ignorer",
		},
	},
	{
		Name:		"search_products",
		Description:	"Recherche des produits par nom",
		Query:		"SELECT * FROM products WHERE name LIKE :name LIMIT :limit",
		Parameters: map[string]string{
			"name":		"Nom du produit à rechercher",
			"limit":	"Nombre maximum de résultats à retourner",
		},
	},
}

// Fonction principale
func main() {
	// Vérifier les arguments
	if len(os.Args) < 2 {
		fmt.Println("Usage: gateway [start|help]")
		os.Exit(1)
	}

	// Traiter les commandes
	switch os.Args[1] {
	case "start":
		// Vérifier le mode MCP
		if len(os.Args) >= 4 && os.Args[3] == "mcp-stdio" {
			runMCPServer()
		} else {
			fmt.Println("Mode non supporté. Utilisez 'mcp-stdio'.")
		}
	case "help":
		printHelp()
	default:
		fmt.Println("Commande inconnue. Utilisez 'start' ou 'help'.")
	}
}

// Affiche l'aide
func printHelp() {
	fmt.Println("Gateway - MCP Server pour n8n")
	fmt.Println("Usage:")
	fmt.Println("  gateway start --config <config_file> mcp-stdio  Démarre le serveur MCP en mode STDIO")
	fmt.Println("  gateway help                                   Affiche cette aide")
}

// Exécute le serveur MCP
func runMCPServer() {
	decoder := json.NewDecoder(os.Stdin)
	encoder := json.NewEncoder(os.Stdout)

	// Boucle principale
	for {
		var request MCPRequest
		err := decoder.Decode(&request)
		if err != nil {
			// Fin de l'entrée standard
			break
		}

		// Traiter la requête
		var response MCPResponse
		switch request.Type {
		case "list_tools":
			response = handleListTools()
		case "tool_call":
			response = handleToolCall(request.Content)
		default:
			response = MCPResponse{
				Type:		"error",
				Content:	fmt.Sprintf("Type de requête non supporté: %s", request.Type),
			}
		}

		// Envoyer la réponse
		err = encoder.Encode(response)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur lors de l'envoi de la réponse: %v\n", err)
			break
		}
	}
}

// Gère la requête list_tools
func handleListTools() MCPResponse {
	tools := make([]Tool, 0, len(databaseTools))
	for _, dbTool := range databaseTools {
		// Créer le schéma des paramètres
		schema := map[string]interface{}{
			"type":		"object",
			"properties":	map[string]interface{}{},
			"required":	[]string{},
		}
		properties := schema["properties"].(map[string]interface{})

		for paramName, paramDesc := range dbTool.Parameters {
			properties[paramName] = map[string]interface{}{
				"type":		"string",
				"description":	paramDesc,
			}
		}

		tools = append(tools, Tool{
			Name:		dbTool.Name,
			Description:	dbTool.Description,
			Schema:		schema,
		})
	}

	return MCPResponse{
		Type:	"list_tools_response",
		Content: ListToolsResponse{
			Tools: tools,
		},
	}
}

// Gère la requête tool_call
func handleToolCall(content json.RawMessage) MCPResponse {
	var toolCall ToolCallRequest
	err := json.Unmarshal(content, &toolCall)
	if err != nil {
		return MCPResponse{
			Type:		"error",
			Content:	fmt.Sprintf("Erreur lors du décodage de la requête tool_call: %v", err),
		}
	}

	// Rechercher l'outil
	var dbTool *DatabaseTool
	for i, tool := range databaseTools {
		if tool.Name == toolCall.ToolName {
			dbTool = &databaseTools[i]
			break
		}
	}

	if dbTool == nil {
		return MCPResponse{
			Type:		"error",
			Content:	fmt.Sprintf("Outil non trouvé: %s", toolCall.ToolName),
		}
	}

	// Simuler l'exécution de la requête
	query := dbTool.Query
	for paramName, paramValue := range toolCall.Parameters {
		placeholder := fmt.Sprintf(":%s", paramName)
		query = strings.Replace(query, placeholder, fmt.Sprintf("%v", paramValue), -1)
	}

	// Simuler des résultats
	var result interface{}
	switch dbTool.Name {
	case "get_customers":
		result = []map[string]interface{}{
			{"id": 1, "name": "Jean Dupont", "email": "jean.dupont@example.com"},
			{"id": 2, "name": "Marie Martin", "email": "marie.martin@example.com"},
			{"id": 3, "name": "Pierre Durand", "email": "pierre.durand@example.com"},
		}
	case "get_orders":
		result = []map[string]interface{}{
			{"id": 101, "customer_id": 1, "amount": 150.50, "date": "2025-04-01"},
			{"id": 102, "customer_id": 2, "amount": 75.20, "date": "2025-04-02"},
			{"id": 103, "customer_id": 1, "amount": 200.00, "date": "2025-04-03"},
		}
	case "search_products":
		result = []map[string]interface{}{
			{"id": 201, "name": "Ordinateur portable", "price": 999.99, "stock": 10},
			{"id": 202, "name": "Ordinateur de bureau", "price": 799.99, "stock": 5},
			{"id": 203, "name": "Ordinateur tout-en-un", "price": 1299.99, "stock": 3},
		}
	default:
		result = []map[string]interface{}{}
	}

	return MCPResponse{
		Type:	"tool_call_response",
		Content: ToolCallResponse{
			Result: map[string]interface{}{
				"query":	query,
				"results":	result,
			},
		},
	}
}
