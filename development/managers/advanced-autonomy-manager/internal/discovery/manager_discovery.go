// Package discovery implements manager discovery and connection mechanisms
// for the AdvancedAutonomyManager to connect to all 20 ecosystem managers
package discovery

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"advanced-autonomy-manager/interfaces"
)

// ManagerDiscoveryService découvre et connecte aux 20 managers de l'écosystème FMOUA
type ManagerDiscoveryService struct {
	config          *DiscoveryConfig
	logger          interfaces.Logger
	discoveredManagers map[string]*ManagerConnection
	connectionPool     map[string]interfaces.BaseManager
	mutex              sync.RWMutex
	initialized        bool
}

// DiscoveryConfig configure le service de découverte des managers
type DiscoveryConfig struct {
	// Méthodes de découverte
	EnableFileSystemDiscovery bool          `yaml:"enable_filesystem_discovery" json:"enable_filesystem_discovery"`
	EnableNetworkDiscovery    bool          `yaml:"enable_network_discovery" json:"enable_network_discovery"`
	EnableRegistryDiscovery   bool          `yaml:"enable_registry_discovery" json:"enable_registry_discovery"`
	
	// Paramètres de recherche
	SearchPaths       []string      `yaml:"search_paths" json:"search_paths"`
	NetworkScanRange  string        `yaml:"network_scan_range" json:"network_scan_range"`
	DiscoveryTimeout  time.Duration `yaml:"discovery_timeout" json:"discovery_timeout"`
	ManagerPorts      []int         `yaml:"manager_ports" json:"manager_ports"`
	
	// Configuration de connexion
	ConnectionTimeout time.Duration `yaml:"connection_timeout" json:"connection_timeout"`
	RetryAttempts     int           `yaml:"retry_attempts" json:"retry_attempts"`
	RetryDelay        time.Duration `yaml:"retry_delay" json:"retry_delay"`
	
	// Registre des managers attendus
	ExpectedManagers  []string      `yaml:"expected_managers" json:"expected_managers"`
}

// ManagerConnection représente une connexion à un manager découvert
type ManagerConnection struct {
	Name         string
	Type         string
	Version      string
	Endpoint     string
	Port         int
	Status       ConnectionStatus
	Manager      interfaces.BaseManager
	LastPing     time.Time
	ConnectedAt  time.Time
	Capabilities []string
	Health       float64
	Metadata     map[string]interface{}
}

// ConnectionStatus définit l'état d'une connexion manager
type ConnectionStatus string

const (
	StatusDiscovered   ConnectionStatus = "discovered"
	StatusConnecting   ConnectionStatus = "connecting"
	StatusConnected    ConnectionStatus = "connected"
	StatusDisconnected ConnectionStatus = "disconnected"
	StatusError        ConnectionStatus = "error"
)

// Noms des 20 managers de l'écosystème FMOUA
var ExpectedEcosystemManagers = []string{
	"file-manager",
	"dependency-manager",
	"config-manager",
	"security-manager",
	"monitoring-manager",
	"storage-manager",
	"container-manager",
	"deployment-manager",
	"network-manager",
	"backup-manager",
	"log-manager",
	"cache-manager",
	"task-manager",
	"notification-manager",
	"workflow-manager",
	"template-manager",
	"error-manager",
	"maintenance-manager",
	"contextual-memory-manager",
	"mcp-manager",
}

// NewManagerDiscoveryService crée un nouveau service de découverte de managers
func NewManagerDiscoveryService(config *DiscoveryConfig, logger interfaces.Logger) (*ManagerDiscoveryService, error) {
	if config == nil {
		// Configuration par défaut
		config = &DiscoveryConfig{
			EnableFileSystemDiscovery: true,
			EnableNetworkDiscovery:    true,
			EnableRegistryDiscovery:   true,
			SearchPaths: []string{
				"../",
				"../../",
				"./development/managers/",
			},
			NetworkScanRange:  "127.0.0.1/32",
			DiscoveryTimeout:  30 * time.Second,
			ManagerPorts:      []int{8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087, 8088, 8089, 8090, 8091, 8092, 8093, 8094, 8095, 8096, 8097, 8098, 8099},
			ConnectionTimeout: 10 * time.Second,
			RetryAttempts:     3,
			RetryDelay:        2 * time.Second,
			ExpectedManagers:  ExpectedEcosystemManagers,
		}
	}

	service := &ManagerDiscoveryService{
		config:             config,
		logger:             logger,
		discoveredManagers: make(map[string]*ManagerConnection),
		connectionPool:     make(map[string]interfaces.BaseManager),
		initialized:        false,
	}

	return service, nil
}

// Initialize initialise le service de découverte
func (mds *ManagerDiscoveryService) Initialize(ctx context.Context) error {
	mds.mutex.Lock()
	defer mds.mutex.Unlock()

	if mds.initialized {
		return fmt.Errorf("manager discovery service already initialized")
	}

	mds.logger.Info("Initializing Manager Discovery Service for 20 ecosystem managers")

	mds.initialized = true
	mds.logger.Info("Manager Discovery Service initialized successfully")

	return nil
}

// DiscoverAllManagers découvre tous les managers de l'écosystème
func (mds *ManagerDiscoveryService) DiscoverAllManagers(ctx context.Context) (map[string]interfaces.BaseManager, error) {
	mds.logger.Info("Starting discovery of all 20 ecosystem managers")

	// Créer un contexte avec timeout pour la découverte
	discoveryCtx, cancel := context.WithTimeout(ctx, mds.config.DiscoveryTimeout)
	defer cancel()

	var wg sync.WaitGroup
	resultsChan := make(chan *ManagerConnection, len(mds.config.ExpectedManagers))
	errorsChan := make(chan error, len(mds.config.ExpectedManagers))

	// Lancer la découverte en parallèle pour chaque manager attendu
	for _, managerName := range mds.config.ExpectedManagers {
		wg.Add(1)
		go func(name string) {
			defer wg.Done()
			
			connection, err := mds.discoverSingleManager(discoveryCtx, name)
			if err != nil {
				errorsChan <- fmt.Errorf("failed to discover %s: %w", name, err)
				return
			}
			
			if connection != nil {
				resultsChan <- connection
			}
		}(managerName)
	}

	// Attendre la fin de toutes les découvertes
	go func() {
		wg.Wait()
		close(resultsChan)
		close(errorsChan)
	}()

	// Collecter les résultats
	discoveredCount := 0
	var discoveryErrors []error

	for {
		select {
		case connection, ok := <-resultsChan:
			if !ok {
				resultsChan = nil
				break
			}
			
			mds.mutex.Lock()
			mds.discoveredManagers[connection.Name] = connection
			if connection.Manager != nil {
				mds.connectionPool[connection.Name] = connection.Manager
			}
			mds.mutex.Unlock()
			
			discoveredCount++
			mds.logger.Info(fmt.Sprintf("Successfully discovered manager: %s (%s)", connection.Name, connection.Endpoint))

		case err, ok := <-errorsChan:
			if !ok {
				errorsChan = nil
				break
			}
			discoveryErrors = append(discoveryErrors, err)
			mds.logger.Error("Manager discovery error", "error", err.Error())

		case <-discoveryCtx.Done():
			mds.logger.Warn("Manager discovery timed out")
			goto finish
		}

		if resultsChan == nil && errorsChan == nil {
			break
		}
	}

finish:
	mds.logger.Info(fmt.Sprintf("Manager discovery completed: %d/%d managers discovered", discoveredCount, len(mds.config.ExpectedManagers)))

	if len(discoveryErrors) > 0 {
		mds.logger.Warn(fmt.Sprintf("Discovery completed with %d errors", len(discoveryErrors)))
	}

	// Retourner les connexions découvertes
	mds.mutex.RLock()
	defer mds.mutex.RUnlock()
	return mds.connectionPool, nil
}

// discoverSingleManager découvre un manager spécifique
func (mds *ManagerDiscoveryService) discoverSingleManager(ctx context.Context, managerName string) (*ManagerConnection, error) {
	mds.logger.Debug(fmt.Sprintf("Discovering manager: %s", managerName))

	var connection *ManagerConnection
	var err error

	// 1. Essayer la découverte par système de fichiers
	if mds.config.EnableFileSystemDiscovery {
		connection, err = mds.discoverByFileSystem(ctx, managerName)
		if err == nil && connection != nil {
			mds.logger.Debug(fmt.Sprintf("Manager %s discovered via filesystem", managerName))
			return connection, nil
		}
	}

	// 2. Essayer la découverte par réseau
	if mds.config.EnableNetworkDiscovery {
		connection, err = mds.discoverByNetwork(ctx, managerName)
		if err == nil && connection != nil {
			mds.logger.Debug(fmt.Sprintf("Manager %s discovered via network", managerName))
			return connection, nil
		}
	}

	// 3. Essayer la découverte par registre
	if mds.config.EnableRegistryDiscovery {
		connection, err = mds.discoverByRegistry(ctx, managerName)
		if err == nil && connection != nil {
			mds.logger.Debug(fmt.Sprintf("Manager %s discovered via registry", managerName))
			return connection, nil
		}
	}

	// 4. Créer une connexion mockée si aucune découverte réelle n'a fonctionné
	connection = mds.createMockConnection(managerName)
	mds.logger.Warn(fmt.Sprintf("Using mock connection for manager: %s", managerName))

	return connection, nil
}

// discoverByFileSystem découvre un manager via le système de fichiers
func (mds *ManagerDiscoveryService) discoverByFileSystem(ctx context.Context, managerName string) (*ManagerConnection, error) {
	for _, searchPath := range mds.config.SearchPaths {
		managerPath := filepath.Join(searchPath, managerName)
		
		if _, err := os.Stat(managerPath); err == nil {
			// Manager trouvé, essayer de créer une connexion
			connection := &ManagerConnection{
				Name:        managerName,
				Type:        "filesystem",
				Version:     "1.0.0",
				Endpoint:    managerPath,
				Status:      StatusDiscovered,
				ConnectedAt: time.Now(),
				Manager:     mds.createManagerProxy(managerName, managerPath),
				Capabilities: []string{"basic", "filesystem"},
				Health:      1.0,
				Metadata: map[string]interface{}{
					"discovery_method": "filesystem",
					"path":            managerPath,
				},
			}
			return connection, nil
		}
	}
	
	return nil, fmt.Errorf("manager %s not found in filesystem", managerName)
}

// discoverByNetwork découvre un manager via le réseau
func (mds *ManagerDiscoveryService) discoverByNetwork(ctx context.Context, managerName string) (*ManagerConnection, error) {
	for _, port := range mds.config.ManagerPorts {
		endpoint := fmt.Sprintf("127.0.0.1:%d", port)
		
		// Tester la connexion TCP
		conn, err := net.DialTimeout("tcp", endpoint, mds.config.ConnectionTimeout)
		if err != nil {
			continue
		}
		conn.Close()

		// Tester l'endpoint HTTP pour vérifier si c'est le bon manager
		if mds.testManagerEndpoint(ctx, endpoint, managerName) {
			connection := &ManagerConnection{
				Name:        managerName,
				Type:        "network",
				Version:     "1.0.0",
				Endpoint:    fmt.Sprintf("http://%s", endpoint),
				Port:        port,
				Status:      StatusConnected,
				ConnectedAt: time.Now(),
				Manager:     mds.createNetworkManagerProxy(managerName, endpoint),
				Capabilities: []string{"basic", "network", "http"},
				Health:      1.0,
				Metadata: map[string]interface{}{
					"discovery_method": "network",
					"endpoint":        endpoint,
					"port":           port,
				},
			}
			return connection, nil
		}
	}
	
	return nil, fmt.Errorf("manager %s not found on network", managerName)
}

// discoverByRegistry découvre un manager via un registre de services
func (mds *ManagerDiscoveryService) discoverByRegistry(ctx context.Context, managerName string) (*ManagerConnection, error) {
	// Implémentation future pour la découverte via registre (Consul, etcd, etc.)
	mds.logger.Debug(fmt.Sprintf("Registry discovery not yet implemented for %s", managerName))
	return nil, fmt.Errorf("registry discovery not implemented")
}

// testManagerEndpoint teste si un endpoint correspond au manager recherché
func (mds *ManagerDiscoveryService) testManagerEndpoint(ctx context.Context, endpoint, expectedManagerName string) bool {
	client := &http.Client{
		Timeout: mds.config.ConnectionTimeout,
	}

	resp, err := client.Get(fmt.Sprintf("http://%s/health", endpoint))
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	// Vérifier le header ou contenu pour identifier le manager
	managerType := resp.Header.Get("X-Manager-Type")
	return strings.Contains(strings.ToLower(managerType), strings.ToLower(expectedManagerName))
}

// createManagerProxy crée un proxy pour un manager basé sur le système de fichiers
func (mds *ManagerDiscoveryService) createManagerProxy(managerName, path string) interfaces.BaseManager {
	return &ManagerProxy{
		name:     managerName,
		endpoint: path,
		type_:    "filesystem",
		logger:   mds.logger,
	}
}

// createNetworkManagerProxy crée un proxy pour un manager réseau
func (mds *ManagerDiscoveryService) createNetworkManagerProxy(managerName, endpoint string) interfaces.BaseManager {
	return &NetworkManagerProxy{
		name:     managerName,
		endpoint: fmt.Sprintf("http://%s", endpoint),
		client:   &http.Client{Timeout: 30 * time.Second},
		logger:   mds.logger,
	}
}

// createMockConnection crée une connexion fictive pour les tests
func (mds *ManagerDiscoveryService) createMockConnection(managerName string) *ManagerConnection {
	return &ManagerConnection{
		Name:        managerName,
		Type:        "mock",
		Version:     "1.0.0-mock",
		Endpoint:    fmt.Sprintf("mock://%s", managerName),
		Status:      StatusConnected,
		ConnectedAt: time.Now(),
		Manager:     mds.createMockManagerProxy(managerName),
		Capabilities: []string{"mock", "testing"},
		Health:      0.8, // Santé réduite pour les mocks
		Metadata: map[string]interface{}{
			"discovery_method": "mock",
			"is_mock":         true,
		},
	}
}

// createMockManagerProxy crée un proxy fictif pour les tests
func (mds *ManagerDiscoveryService) createMockManagerProxy(managerName string) interfaces.BaseManager {
	return &MockManagerProxy{
		name:   managerName,
		logger: mds.logger,
	}
}

// GetDiscoveredManagers retourne tous les managers découverts
func (mds *ManagerDiscoveryService) GetDiscoveredManagers() map[string]*ManagerConnection {
	mds.mutex.RLock()
	defer mds.mutex.RUnlock()

	result := make(map[string]*ManagerConnection)
	for name, connection := range mds.discoveredManagers {
		result[name] = connection
	}

	return result
}

// GetConnectionPool retourne le pool de connexions actives
func (mds *ManagerDiscoveryService) GetConnectionPool() map[string]interfaces.BaseManager {
	mds.mutex.RLock()
	defer mds.mutex.RUnlock()

	result := make(map[string]interfaces.BaseManager)
	for name, manager := range mds.connectionPool {
		result[name] = manager
	}

	return result
}

// MonitorConnections surveille les connexions et maintient leur santé
func (mds *ManagerDiscoveryService) MonitorConnections(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			mds.performHealthChecks(ctx)
		}
	}
}

// performHealthChecks effectue des vérifications de santé sur toutes les connexions
func (mds *ManagerDiscoveryService) performHealthChecks(ctx context.Context) {
	mds.mutex.RLock()
	connections := make([]*ManagerConnection, 0, len(mds.discoveredManagers))
	for _, connection := range mds.discoveredManagers {
		connections = append(connections, connection)
	}
	mds.mutex.RUnlock()

	for _, connection := range connections {
		go mds.checkConnectionHealth(ctx, connection)
	}
}

// checkConnectionHealth vérifie la santé d'une connexion spécifique
func (mds *ManagerDiscoveryService) checkConnectionHealth(ctx context.Context, connection *ManagerConnection) {
	if connection.Manager == nil {
		return
	}

	healthCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := connection.Manager.HealthCheck(healthCtx); err != nil {
		mds.mutex.Lock()
		connection.Status = StatusError
		connection.Health = 0.0
		mds.mutex.Unlock()
		
		mds.logger.Warn("Health check failed for manager", "manager", connection.Name, "error", err.Error())
	} else {
		mds.mutex.Lock()
		connection.Status = StatusConnected
		connection.Health = 1.0
		connection.LastPing = time.Now()
		mds.mutex.Unlock()
	}
}

// Cleanup nettoie les ressources du service de découverte
func (mds *ManagerDiscoveryService) Cleanup() error {
	mds.mutex.Lock()
	defer mds.mutex.Unlock()

	mds.logger.Info("Cleaning up Manager Discovery Service")

	// Fermer toutes les connexions
	for name, connection := range mds.discoveredManagers {
		if connection.Manager != nil {
			if err := connection.Manager.Cleanup(); err != nil {
				mds.logger.Warn("Failed to cleanup manager", "manager", name, "error", err.Error())
			}
		}
	}

	// Vider les collections
	mds.discoveredManagers = make(map[string]*ManagerConnection)
	mds.connectionPool = make(map[string]interfaces.BaseManager)
	mds.initialized = false

	mds.logger.Info("Manager Discovery Service cleanup completed")
	return nil
}
