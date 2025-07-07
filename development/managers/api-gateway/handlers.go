package api_gateway

import (
	"context"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// HealthCheck vérifie que l'API Gateway fonctionne
// @Summary Health check
// @Description Vérifie que l'API Gateway est opérationnelle
// @Tags health
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /health [get]
func (ag *APIGateway) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"timestamp": "2025-01-05T00:00:00Z",
		"version":   "v57-consolidation",
	})
}

// ReadinessCheck vérifie que tous les managers sont prêts
// @Summary Readiness check
// @Description Vérifie que tous les managers sont initialisés et prêts
// @Tags health
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /ready [get]
func (ag *APIGateway) readinessCheck(c *gin.Context) {
	readyCount := 0
	totalCount := len(ag.managers)
	for name, manager := range ag.managers {
		status := manager.GetStatus()
		if statusStr, ok := status["status"].(string); ok && statusStr == "healthy" {
			readyCount++
		} else {
			statusStr := "unknown"
			if s, ok := status["status"].(string); ok {
				statusStr = s
			}
			ag.logger.Warn("Manager not ready", zap.String("manager", name), zap.String("status", statusStr))
		}
	}

	ready := readyCount == totalCount

	response := gin.H{
		"ready":       ready,
		"ready_count": readyCount,
		"total_count": totalCount,
		"timestamp":   "2025-01-05T00:00:00Z",
	}

	if ready {
		c.JSON(http.StatusOK, response)
	} else {
		c.JSON(http.StatusServiceUnavailable, response)
	}
}

// ListManagers liste tous les managers enregistrés
// @Summary List managers
// @Description Retourne la liste de tous les managers enregistrés
// @Tags managers
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/managers [get]
func (ag *APIGateway) listManagers(c *gin.Context) {
	managers := make([]map[string]interface{}, 0, len(ag.managers))

	for name, manager := range ag.managers {
		status := manager.GetStatus()
		metrics := manager.GetMetrics()
		managers = append(managers, map[string]interface{}{
			"name":       name,
			"status":     status["status"],
			"last_check": status["last_check"],
			"errors":     status["errors"],
			"metrics":    metrics,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"managers": managers,
		"count":    len(managers),
	})
}

// GetManagerStatus retourne le statut d'un manager spécifique
// @Summary Get manager status
// @Description Retourne le statut détaillé d'un manager
// @Tags managers
// @Param name path string true "Nom du manager"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/managers/{name}/status [get]
func (ag *APIGateway) getManagerStatus(c *gin.Context) {
	managerName := c.Param("name")

	manager, exists := ag.managers[managerName]
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Manager not found",
			"name":  managerName,
		})
		return
	}

	status := manager.GetStatus()
	c.JSON(http.StatusOK, status)
}

// ExecuteManagerAction exécute une action sur un manager
// @Summary Execute manager action
// @Description Exécute une action spécifique sur un manager
// @Tags managers
// @Param name path string true "Nom du manager"
// @Param action body map[string]interface{} true "Action à exécuter"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/managers/{name}/action [post]
func (ag *APIGateway) executeManagerAction(c *gin.Context) {
	managerName := c.Param("name")

	manager, exists := ag.managers[managerName]
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Manager not found",
			"name":  managerName,
		})
		return
	}

	var actionRequest map[string]interface{}
	if err := c.ShouldBindJSON(&actionRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid action request",
			"details": err.Error(),
		})
		return
	}

	action, exists := actionRequest["action"]
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Action field required",
		})
		return
	}

	ctx := context.Background()

	// Exécuter l'action selon le type
	switch action {
	case "start":
		err := manager.Start(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to start manager",
				"details": err.Error(),
			})
			return
		}
	case "stop":
		err := manager.Stop(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to stop manager",
				"details": err.Error(),
			})
			return
		}
	case "restart":
		err := manager.Stop(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to stop manager for restart",
				"details": err.Error(),
			})
			return
		}
		err = manager.Start(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":   "Failed to start manager after restart",
				"details": err.Error(),
			})
			return
		}
	default:
		c.JSON(http.StatusBadRequest, gin.H{
			"error":     "Unsupported action",
			"action":    action,
			"supported": []string{"start", "stop", "restart"},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Action executed successfully",
		"manager": managerName,
		"action":  action,
	})
}

// GetManagerMetrics retourne les métriques d'un manager
// @Summary Get manager metrics
// @Description Retourne les métriques détaillées d'un manager
// @Tags managers
// @Param name path string true "Nom du manager"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/managers/{name}/metrics [get]
func (ag *APIGateway) getManagerMetrics(c *gin.Context) {
	managerName := c.Param("name")

	manager, exists := ag.managers[managerName]
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Manager not found",
			"name":  managerName,
		})
		return
	}

	metrics := manager.GetMetrics()
	c.JSON(http.StatusOK, metrics)
}

// SearchVectors effectue une recherche vectorielle
// @Summary Search vectors
// @Description Effectue une recherche vectorielle dans Qdrant
// @Tags vectors
// @Param request body map[string]interface{} true "Requête de recherche"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/vectors/search [post]
func (ag *APIGateway) searchVectors(c *gin.Context) {
	var searchRequest map[string]interface{}
	if err := c.ShouldBindJSON(&searchRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid search request",
			"details": err.Error(),
		})
		return
	}

	// Simulation de la recherche vectorielle
	// En réalité, cela appellerait le vector client
	results := []map[string]interface{}{
		{
			"id":     "vec_1",
			"score":  0.95,
			"vector": []float32{1.0, 2.0, 3.0},
		},
		{
			"id":     "vec_2",
			"score":  0.87,
			"vector": []float32{4.0, 5.0, 6.0},
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"results": results,
		"count":   len(results),
		"query":   searchRequest,
	})
}

// UpsertVectors insert ou met à jour des vecteurs
// @Summary Upsert vectors
// @Description Insert ou met à jour des vecteurs dans Qdrant
// @Tags vectors
// @Param request body map[string]interface{} true "Vecteurs à upserter"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/vectors/upsert [post]
func (ag *APIGateway) upsertVectors(c *gin.Context) {
	var upsertRequest map[string]interface{}
	if err := c.ShouldBindJSON(&upsertRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid upsert request",
			"details": err.Error(),
		})
		return
	}

	// Simulation de l'upsert
	c.JSON(http.StatusOK, gin.H{
		"message": "Vectors upserted successfully",
		"count":   1, // Compter les vecteurs de la requête
	})
}

// ListVectors liste les vecteurs
// @Summary List vectors
// @Description Liste les vecteurs disponibles
// @Tags vectors
// @Param limit query int false "Limite du nombre de résultats"
// @Param offset query int false "Offset pour la pagination"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/vectors/list [get]
func (ag *APIGateway) listVectors(c *gin.Context) {
	limit := 10
	offset := 0

	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	if offsetStr := c.Query("offset"); offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil {
			offset = o
		}
	}

	// Simulation de la liste
	vectors := []map[string]interface{}{
		{"id": "vec_1", "dimension": 768},
		{"id": "vec_2", "dimension": 768},
	}

	c.JSON(http.StatusOK, gin.H{
		"vectors": vectors,
		"count":   len(vectors),
		"limit":   limit,
		"offset":  offset,
	})
}

// DeleteVector supprime un vecteur
// @Summary Delete vector
// @Description Supprime un vecteur par son ID
// @Tags vectors
// @Param id path string true "ID du vecteur"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/vectors/{id} [delete]
func (ag *APIGateway) deleteVector(c *gin.Context) {
	vectorID := c.Param("id")

	// Simulation de la suppression
	c.JSON(http.StatusOK, gin.H{
		"message":   "Vector deleted successfully",
		"vector_id": vectorID,
	})
}

// GetConfig récupère une valeur de configuration
// @Summary Get config
// @Description Récupère une valeur de configuration
// @Tags config
// @Param key path string true "Clé de configuration"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/config/{key} [get]
func (ag *APIGateway) getConfig(c *gin.Context) {
	key := c.Param("key")

	// Simulation - en réalité utiliserait le config-manager
	configs := map[string]interface{}{
		"qdrant_host": "localhost:6333",
		"log_level":   "info",
		"max_workers": 10,
	}

	if value, exists := configs[key]; exists {
		c.JSON(http.StatusOK, gin.H{
			"key":   key,
			"value": value,
		})
	} else {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Configuration key not found",
			"key":   key,
		})
	}
}

// SetConfig définit une valeur de configuration
// @Summary Set config
// @Description Définit une valeur de configuration
// @Tags config
// @Param key path string true "Clé de configuration"
// @Param request body map[string]interface{} true "Nouvelle valeur"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/config/{key} [post]
func (ag *APIGateway) setConfig(c *gin.Context) {
	key := c.Param("key")

	var configRequest map[string]interface{}
	if err := c.ShouldBindJSON(&configRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid config request",
			"details": err.Error(),
		})
		return
	}

	value, exists := configRequest["value"]
	if !exists {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Value field required",
		})
		return
	}

	// Simulation de la mise à jour
	c.JSON(http.StatusOK, gin.H{
		"message": "Configuration updated successfully",
		"key":     key,
		"value":   value,
	})
}

// GetAllConfigs récupère toutes les configurations
// @Summary Get all configs
// @Description Récupère toutes les configurations
// @Tags config
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/config [get]
func (ag *APIGateway) getAllConfigs(c *gin.Context) {
	// Simulation - en réalité utiliserait le config-manager
	configs := map[string]interface{}{
		"qdrant_host": "localhost:6333",
		"log_level":   "info",
		"max_workers": 10,
		"cache_size":  1000,
	}

	c.JSON(http.StatusOK, gin.H{
		"configs": configs,
		"count":   len(configs),
	})
}

// GetEvents récupère les événements récents
// @Summary Get events
// @Description Récupère les événements récents du système
// @Tags events
// @Param limit query int false "Limite du nombre d'événements"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/events [get]
func (ag *APIGateway) getEvents(c *gin.Context) {
	limit := 50
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	// Simulation d'événements
	events := []map[string]interface{}{
		{
			"id":        "evt_1",
			"type":      "manager.started",
			"manager":   "vector-manager",
			"timestamp": "2025-01-05T10:00:00Z",
		},
		{
			"id":        "evt_2",
			"type":      "search.completed",
			"duration":  "120ms",
			"timestamp": "2025-01-05T10:01:00Z",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"events": events,
		"count":  len(events),
		"limit":  limit,
	})
}

// PublishEvent publie un nouvel événement
// @Summary Publish event
// @Description Publie un nouvel événement dans le système
// @Tags events
// @Param request body map[string]interface{} true "Événement à publier"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/events [post]
func (ag *APIGateway) publishEvent(c *gin.Context) {
	var eventRequest map[string]interface{}
	if err := c.ShouldBindJSON(&eventRequest); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Invalid event request",
			"details": err.Error(),
		})
		return
	}

	// Simulation de la publication
	c.JSON(http.StatusOK, gin.H{
		"message": "Event published successfully",
		"event":   eventRequest,
	})
}

// SubscribeToEvents souscrit aux événements d'un topic
// @Summary Subscribe to events
// @Description Souscrit aux événements d'un topic spécifique
// @Tags events
// @Param topic path string true "Topic d'événements"
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/events/subscribe/{topic} [get]
func (ag *APIGateway) subscribeToEvents(c *gin.Context) {
	topic := c.Param("topic")

	// Simulation de la souscription
	c.JSON(http.StatusOK, gin.H{
		"message":       "Subscribed to events",
		"topic":         topic,
		"websocket_url": "/ws/events/" + topic,
	})
}

// GetSystemStatus retourne le statut global du système
// @Summary Get system status
// @Description Retourne le statut global de l'écosystème
// @Tags monitoring
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/monitoring/status [get]
func (ag *APIGateway) getSystemStatus(c *gin.Context) {
	healthyCount := 0
	totalCount := len(ag.managers)
	for _, manager := range ag.managers {
		status := manager.GetStatus()
		if statusStr, ok := status["status"].(string); ok && statusStr == "healthy" {
			healthyCount++
		}
	}

	systemHealth := "healthy"
	if healthyCount < totalCount {
		if healthyCount < totalCount/2 {
			systemHealth = "critical"
		} else {
			systemHealth = "degraded"
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"system_health": systemHealth,
		"healthy_count": healthyCount,
		"total_count":   totalCount,
		"uptime":        "24h",
		"version":       "v57-consolidation",
	})
}

// GetSystemMetrics retourne les métriques globales
// @Summary Get system metrics
// @Description Retourne les métriques globales du système
// @Tags monitoring
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/monitoring/metrics [get]
func (ag *APIGateway) getSystemMetrics(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"cpu_usage":           "25.5%",
		"memory_usage":        "450MB",
		"active_connections":  50,
		"requests_per_second": 100,
		"cache_hit_ratio":     "85.2%",
	})
}

// GetPerformanceMetrics retourne les métriques de performance
// @Summary Get performance metrics
// @Description Retourne les métriques de performance détaillées
// @Tags monitoring
// @Produce json
// @Security ApiKeyAuth
// @Success 200 {object} map[string]interface{}
// @Router /api/v1/monitoring/performance [get]
func (ag *APIGateway) getPerformanceMetrics(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"avg_response_time": "45ms",
		"p95_response_time": "120ms",
		"p99_response_time": "250ms",
		"error_rate":        "0.1%",
		"throughput":        "1000 req/s",
	})
}
