package vectorization

import (
	"context"
	"fmt"
	"sync"
	"time"

	"go.uber.org/zap"
)

// ConnectionPool gère un pool de connexions pour Qdrant
type ConnectionPool struct {
	mu          sync.RWMutex
	connections []Connection
	available   chan Connection
	maxSize     int
	config      VectorConfig
	logger      *zap.Logger
	metrics     PoolMetrics
}

// Connection représente une connexion au serveur Qdrant
type Connection struct {
	ID         string
	CreatedAt  time.Time
	LastUsed   time.Time
	InUse      bool
	ErrorCount int
	// client   *qdrant.Client // Sera ajouté avec les dépendances Qdrant
}

// PoolMetrics contient les métriques du pool de connexions
type PoolMetrics struct {
	TotalConnections     int           `json:"total_connections"`
	AvailableConnections int           `json:"available_connections"`
	InUseConnections     int           `json:"in_use_connections"`
	AverageWaitTime      time.Duration `json:"average_wait_time"`
	ConnectionErrors     int64         `json:"connection_errors"`
	TotalRequests        int64         `json:"total_requests"`
}

// NewConnectionPool crée un nouveau pool de connexions
func NewConnectionPool(config VectorConfig, logger *zap.Logger) *ConnectionPool {
	maxSize := 20 // Valeur par défaut
	if config.BatchSize > 0 {
		maxSize = config.BatchSize
	}

	pool := &ConnectionPool{
		connections: make([]Connection, 0, maxSize),
		available:   make(chan Connection, maxSize),
		maxSize:     maxSize,
		config:      config,
		logger:      logger,
		metrics: PoolMetrics{
			TotalConnections:     0,
			AvailableConnections: 0,
			InUseConnections:     0,
		},
	}

	// Initialiser quelques connexions de base
	for i := 0; i < 5; i++ {
		conn, err := pool.createConnection()
		if err != nil {
			logger.Error("Failed to create initial connection", zap.Error(err))
			continue
		}
		pool.connections = append(pool.connections, conn)
		pool.available <- conn
	}

	pool.updateMetrics()
	logger.Info("Connection pool initialized",
		zap.Int("initial_connections", len(pool.connections)),
		zap.Int("max_size", maxSize))

	return pool
}

// GetConnection récupère une connexion du pool
func (cp *ConnectionPool) GetConnection(ctx context.Context) (Connection, error) {
	cp.metrics.TotalRequests++
	startTime := time.Now()

	select {
	case conn := <-cp.available:
		// Connexion disponible dans le pool
		cp.mu.Lock()
		conn.InUse = true
		conn.LastUsed = time.Now()
		cp.mu.Unlock()

		waitTime := time.Since(startTime)
		cp.updateWaitTime(waitTime)

		cp.logger.Debug("Connection retrieved from pool",
			zap.String("conn_id", conn.ID),
			zap.Duration("wait_time", waitTime))

		return conn, nil

	case <-ctx.Done():
		return Connection{}, ctx.Err()

	default:
		// Aucune connexion disponible, essayer d'en créer une nouvelle
		cp.mu.Lock()
		if len(cp.connections) < cp.maxSize {
			conn, err := cp.createConnection()
			if err != nil {
				cp.mu.Unlock()
				return Connection{}, fmt.Errorf("failed to create new connection: %w", err)
			}

			conn.InUse = true
			conn.LastUsed = time.Now()
			cp.connections = append(cp.connections, conn)
			cp.mu.Unlock()

			cp.logger.Debug("New connection created", zap.String("conn_id", conn.ID))
			return conn, nil
		}
		cp.mu.Unlock()

		// Pool plein, attendre qu'une connexion se libère
		select {
		case conn := <-cp.available:
			cp.mu.Lock()
			conn.InUse = true
			conn.LastUsed = time.Now()
			cp.mu.Unlock()

			waitTime := time.Since(startTime)
			cp.updateWaitTime(waitTime)

			return conn, nil
		case <-ctx.Done():
			return Connection{}, ctx.Err()
		case <-time.After(time.Second * 30): // Timeout après 30s
			return Connection{}, fmt.Errorf("timeout waiting for available connection")
		}
	}
}

// ReturnConnection remet une connexion dans le pool
func (cp *ConnectionPool) ReturnConnection(conn Connection) {
	cp.mu.Lock()
	conn.InUse = false
	cp.mu.Unlock()

	select {
	case cp.available <- conn:
		cp.logger.Debug("Connection returned to pool", zap.String("conn_id", conn.ID))
	default:
		// Canal plein, fermer la connexion
		cp.logger.Warn("Pool full, discarding connection", zap.String("conn_id", conn.ID))
	}

	cp.updateMetrics()
}

// createConnection crée une nouvelle connexion
func (cp *ConnectionPool) createConnection() (Connection, error) {
	conn := Connection{
		ID:         fmt.Sprintf("conn_%d_%d", time.Now().UnixNano(), len(cp.connections)),
		CreatedAt:  time.Now(),
		LastUsed:   time.Now(),
		InUse:      false,
		ErrorCount: 0,
	}

	// Simuler la création d'une connexion Qdrant
	// En production: conn.client, err = qdrant.NewClient(&qdrant.Config{...})

	return conn, nil
}

// updateMetrics met à jour les métriques du pool
func (cp *ConnectionPool) updateMetrics() {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	cp.metrics.TotalConnections = len(cp.connections)
	cp.metrics.AvailableConnections = len(cp.available)

	inUse := 0
	for _, conn := range cp.connections {
		if conn.InUse {
			inUse++
		}
	}
	cp.metrics.InUseConnections = inUse
}

// updateWaitTime met à jour le temps d'attente moyen
func (cp *ConnectionPool) updateWaitTime(waitTime time.Duration) {
	// Calcul de moyenne mobile simple
	cp.metrics.AverageWaitTime = (cp.metrics.AverageWaitTime + waitTime) / 2
}

// GetMetrics retourne les métriques actuelles du pool
func (cp *ConnectionPool) GetMetrics() PoolMetrics {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	cp.updateMetrics()
	return cp.metrics
}

// Close ferme le pool et toutes ses connexions
func (cp *ConnectionPool) Close() error {
	cp.mu.Lock()
	defer cp.mu.Unlock()

	close(cp.available)

	// Fermer toutes les connexions
	for _, conn := range cp.connections {
		// En production: conn.client.Close()
		cp.logger.Debug("Closing connection", zap.String("conn_id", conn.ID))
	}

	cp.connections = nil
	cp.logger.Info("Connection pool closed")

	return nil
}

// HealthCheck vérifie la santé du pool
func (cp *ConnectionPool) HealthCheck(ctx context.Context) error {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	// Vérifier qu'il y a au moins une connexion disponible
	if len(cp.connections) == 0 {
		return fmt.Errorf("no connections in pool")
	}

	// Vérifier que le pool n'est pas surchargé
	if cp.metrics.InUseConnections >= cp.maxSize {
		return fmt.Errorf("pool is at maximum capacity")
	}

	// Vérifier les erreurs de connexion
	errorThreshold := int64(100)
	if cp.metrics.ConnectionErrors > errorThreshold {
		return fmt.Errorf("too many connection errors: %d", cp.metrics.ConnectionErrors)
	}

	return nil
}
