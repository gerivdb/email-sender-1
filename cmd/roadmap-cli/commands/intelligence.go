package commands

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/rag"
	"email_sender/cmd/roadmap-cli/storage"

	"github.com/spf13/cobra"
)

// loadRoadmapData loads roadmap data using JSONStorage
func loadRoadmapData() (*storage.RoadmapData, error) {
	jsonStorage, err := storage.NewJSONStorage("roadmap.json")
	if err != nil {
		return nil, fmt.Errorf("failed to create storage: %w", err)
	}
	defer jsonStorage.Close()

	items, err := jsonStorage.GetAllItems()
	if err != nil {
		return nil, fmt.Errorf("failed to get items: %w", err)
	}

	milestones, err := jsonStorage.GetAllMilestones()
	if err != nil {
		return nil, fmt.Errorf("failed to get milestones: %w", err)
	}

	return &storage.RoadmapData{
		Items:      items,
		Milestones: milestones,
		LastUpdate: time.Now(),
	}, nil
}

// intelligenceCmd provides AI-powered roadmap analysis using EMAIL_SENDER_1 RAG
var intelligenceCmd = &cobra.Command{
	Use:   "intelligence",
	Short: "🧠 AI-powered roadmap analysis using EMAIL_SENDER_1 RAG ecosystem",
	Long: `Leverage the EMAIL_SENDER_1 RAG (Retrieval Augmented Generation) ecosystem 
to get intelligent insights about your roadmap:

• Similar items and patterns analysis
• Dependency detection using vector search  
• Risk assessment and optimization recommendations
• Integration with QDrant vector database`,
	Example: `  # Analyze similarities and get recommendations
  roadmap-cli intelligence analyze "API development"
  
  # Find dependencies for a specific item
  roadmap-cli intelligence dependencies "Build user authentication"
  
  # Get optimization suggestions
  roadmap-cli intelligence optimize
  
  # Check RAG system health
  roadmap-cli intelligence health`,
}

var analyzeCmd = &cobra.Command{
	Use:   "analyze [query]",
	Short: "🔍 Analyze roadmap items using vector similarity search",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		query := args[0]

		ragClient := createRAGClient()
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		fmt.Printf("🔍 Analyzing roadmap items similar to: \"%s\"\n\n", query)

		// Find similar items using vector search
		insights, err := ragClient.GetSimilarItems(ctx, query, 5)
		if err != nil {
			return fmt.Errorf("failed to analyze roadmap: %w", err)
		}

		if len(insights) == 0 {
			fmt.Println("No similar items found. Try a different query or add more roadmap items.")
			return nil
		}

		fmt.Printf("Found %d similar items:\n\n", len(insights))
		for i, insight := range insights {
			confidence := int(insight.Confidence * 100)
			title := insight.Context["title"]
			description := insight.Context["description"]

			fmt.Printf("%d. 📋 %v (Confidence: %d%%)\n", i+1, title, confidence)
			if description != nil {
				desc := fmt.Sprintf("%v", description)
				if len(desc) > 80 {
					desc = desc[:77] + "..."
				}
				fmt.Printf("   %s\n", desc)
			}
			fmt.Println()
		}

		return nil
	},
}

var dependenciesCmd = &cobra.Command{
	Use:   "dependencies [item-title]",
	Short: "🔗 Detect potential dependencies using RAG analysis",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		itemTitle := args[0]

		ragClient := createRAGClient()
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		fmt.Printf("🔗 Analyzing dependencies for: \"%s\"\n\n", itemTitle)

		// Analyze dependencies using RAG
		dependencies, err := ragClient.AnalyzeDependencies(ctx, itemTitle, "")
		if err != nil {
			return fmt.Errorf("failed to analyze dependencies: %w", err)
		}

		if len(dependencies) == 0 {
			fmt.Println("✅ No obvious dependencies detected.")
			fmt.Println("💡 This item appears to be independent or foundational.")
			return nil
		}

		fmt.Printf("Found %d potential dependencies:\n\n", len(dependencies))
		for i, dep := range dependencies {
			confidence := int(dep.Confidence * 100)
			title := dep.Context["title"]

			fmt.Printf("%d. ⚠️  %v (Confidence: %d%%)\n", i+1, title, confidence)
			fmt.Printf("   Reason: %s\n", dep.Message)
			fmt.Println()
		}

		fmt.Println("💡 Consider ordering these items before starting the main task.")
		return nil
	},
}

var optimizeCmd = &cobra.Command{
	Use:   "optimize",
	Short: "⚡ Get AI-powered optimization recommendations",
	RunE: func(cmd *cobra.Command, args []string) error {
		ragClient := createRAGClient()
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel() // Load current roadmap for context
		roadmapData, err := loadRoadmapData()
		if err != nil {
			return fmt.Errorf("failed to load roadmap: %w", err)
		}

		fmt.Println("⚡ Generating optimization recommendations...")
		fmt.Println()

		// Build context from current roadmap
		var contextBuilder strings.Builder
		contextBuilder.WriteString(fmt.Sprintf("Roadmap with %d items and %d milestones. ",
			len(roadmapData.Items), len(roadmapData.Milestones)))

		for _, item := range roadmapData.Items {
			contextBuilder.WriteString(fmt.Sprintf("Item: %s (%s priority). ", item.Title, item.Priority))
		}

		// Get AI recommendations
		recommendations, err := ragClient.GenerateRecommendations(ctx, contextBuilder.String())
		if err != nil {
			return fmt.Errorf("failed to generate recommendations: %w", err)
		}

		if len(recommendations) == 0 {
			fmt.Println("✅ Your roadmap appears well-optimized!")
			return nil
		}

		fmt.Printf("Generated %d optimization recommendations:\n\n", len(recommendations))

		for i, rec := range recommendations {
			var emoji string
			switch rec.Type {
			case "optimization":
				emoji = "⚡"
			case "risk":
				emoji = "⚠️"
			case "recommendation":
				emoji = "💡"
			default:
				emoji = "📝"
			}

			confidence := int(rec.Confidence * 100)
			fmt.Printf("%d. %s %s (Confidence: %d%%)\n", i+1, emoji, rec.Message, confidence)
			fmt.Println()
		}

		fmt.Println("💡 Tip: Use 'roadmap-cli view' to see your roadmap and apply these suggestions.")
		return nil
	},
}

var healthCmd = &cobra.Command{
	Use:   "health",
	Short: "🏥 Check RAG system health and connectivity",
	RunE: func(cmd *cobra.Command, args []string) error {
		ragClient := createRAGClient()
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()

		fmt.Println("🏥 Checking RAG system health...")
		fmt.Println()

		// Check QDrant connectivity
		fmt.Print("📊 QDrant Vector Database: ")
		if err := ragClient.HealthCheck(ctx); err != nil {
			fmt.Printf("❌ FAILED (%v)\n", err)
			fmt.Println("\n💡 Make sure QDrant is running:")
			fmt.Println("   docker run -p 6333:6333 qdrant/qdrant")
			return nil
		}
		fmt.Println("✅ HEALTHY")

		// Check collection initialization
		fmt.Print("🗂️  Roadmap Collection: ")
		if err := ragClient.InitializeCollection(ctx); err != nil {
			fmt.Printf("❌ FAILED (%v)\n", err)
			return nil
		}
		fmt.Println("✅ INITIALIZED") // Check roadmap data availability
		fmt.Print("📋 Roadmap Data: ")
		roadmapData, err := loadRoadmapData()
		if err != nil {
			fmt.Printf("❌ NO DATA (%v)\n", err)
			fmt.Println("\n💡 Create some roadmap items first:")
			fmt.Println("   roadmap-cli create item \"My first task\"")
			return nil
		}
		fmt.Printf("✅ %d ITEMS, %d MILESTONES\n", len(roadmapData.Items), len(roadmapData.Milestones))

		fmt.Println("\n🎉 RAG system is fully operational!")
		fmt.Println("💡 Try: roadmap-cli intelligence analyze \"your query here\"")
		return nil
	},
}

var syncRAGCmd = &cobra.Command{
	Use:   "sync",
	Short: "🔄 Sync roadmap data to RAG vector database",
	RunE: func(cmd *cobra.Command, args []string) error {
		ragClient := createRAGClient()
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
		defer cancel()

		fmt.Println("🔄 Syncing roadmap data to RAG vector database...")
		fmt.Println()

		// Initialize collection
		if err := ragClient.InitializeCollection(ctx); err != nil {
			return fmt.Errorf("failed to initialize collection: %w", err)
		} // Load roadmap data
		roadmapData, err := loadRoadmapData()
		if err != nil {
			return fmt.Errorf("failed to load roadmap: %w", err)
		}

		// Index all roadmap items
		indexedCount := 0
		for _, item := range roadmapData.Items {
			metadata := map[string]interface{}{
				"priority":    item.Priority,
				"status":      item.Status,
				"progress":    item.Progress,
				"target_date": item.TargetDate,
			}

			if err := ragClient.IndexRoadmapItem(ctx, item.ID, item.Title, item.Description, metadata); err != nil {
				fmt.Printf("⚠️  Failed to index item '%s': %v\n", item.Title, err)
				continue
			}

			fmt.Printf("✅ Indexed: %s\n", item.Title)
			indexedCount++
		}

		fmt.Printf("\n🎉 Successfully indexed %d/%d roadmap items!\n", indexedCount, len(roadmapData.Items))
		fmt.Println("💡 Now you can use AI-powered analysis:")
		fmt.Println("   roadmap-cli intelligence analyze \"API development\"")
		return nil
	},
}

// createRAGClient creates a new RAG client with EMAIL_SENDER_1 configuration
func createRAGClient() *rag.RAGClient {
	// Default to local QDrant instance (EMAIL_SENDER_1 setup)
	qdrantURL := os.Getenv("QDRANT_URL")
	if qdrantURL == "" {
		qdrantURL = "http://localhost:6333"
	}

	openaiURL := os.Getenv("OPENAI_URL")
	if openaiURL == "" {
		openaiURL = "https://api.openai.com/v1"
	}

	apiKey := os.Getenv("OPENAI_API_KEY")

	return rag.NewRAGClient(qdrantURL, openaiURL, apiKey)
}

func init() {
	// Add subcommands to intelligence
	intelligenceCmd.AddCommand(analyzeCmd)
	intelligenceCmd.AddCommand(dependenciesCmd)
	intelligenceCmd.AddCommand(optimizeCmd)
	intelligenceCmd.AddCommand(healthCmd)
	intelligenceCmd.AddCommand(syncRAGCmd)
}
