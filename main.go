package _

import (
	"fmt"
	"log"
	"net/http"

	"os"

	"github.com/gin-gonic/gin"
	"gopkg.in/yaml.v3"
)

type Config struct {
	App struct {
		Name    string `yaml:"name"`
		Version string `yaml:"version"`
		Env     string `yaml:"env"`
	} `yaml:"app"`
	Server struct {
		Host string `yaml:"host"`
		Port int    `yaml:"port"`
	} `yaml:"server"`
}

func loadConfig() (*Config, error) {
	var config Config

	data, err := os.ReadFile("config.yaml")
	if err != nil {
		return nil, err
	}

	err = yaml.Unmarshal(data, &config)
	return &config, err
}

func main() {
	// Charger la configuration
	config, err := loadConfig()
	if err != nil {
		log.Printf("Erreur lors du chargement de la configuration: %v", err)
		// Utiliser des valeurs par défaut
		config = &Config{}
		config.App.Name = "Email Sender Application"
		config.App.Version = "1.0.0"
		config.Server.Host = "localhost"
		config.Server.Port = 8080
	}

	fmt.Printf("Démarrage de %s v%s\n", config.App.Name, config.App.Version)

	// Initialiser Gin
	r := gin.Default()

	// Routes de base
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Email Sender Application",
			"version": config.App.Version,
			"status":  "running",
		})
	})

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy",
		})
	})

	// Démarrer le serveur
	addr := fmt.Sprintf("%s:%d", config.Server.Host, config.Server.Port)
	fmt.Printf("Serveur démarré sur http://%s\n", addr)
	log.Fatal(r.Run(addr))
}
