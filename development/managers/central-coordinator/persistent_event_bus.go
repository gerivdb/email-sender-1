package coordinator

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.uber.org/zap"
)

// EventStore gère la persistance des événements critiques
type EventStore struct {
	mu         sync.RWMutex
	storePath  string
	logger     *zap.Logger
	buffer     []*ManagerEvent
	bufferSize int
	flushTimer *time.Ticker
}

// PersistentEventBus étend EventBus avec la persistance
type PersistentEventBus struct {
	*EventBus
	store *EventStore
}

// EventFilter définit les critères pour filtrer les événements à persister
type EventFilter struct {
	EventTypes      []string      `json:"event_types"`
	MinPriority     EventPriority `json:"min_priority"`
	Sources         []string      `json:"sources"`
	PersistCritical bool          `json:"persist_critical"`
}

// PersistedEvent représente un événement stocké sur disque
type PersistedEvent struct {
	Event    *ManagerEvent `json:"event"`
	StoredAt time.Time     `json:"stored_at"`
	Checksum string        `json:"checksum"`
}

// NewEventStore crée un nouveau store d'événements
func NewEventStore(storePath string, bufferSize int, logger *zap.Logger) (*EventStore, error) {
	// Créer le répertoire s'il n'existe pas
	if err := os.MkdirAll(filepath.Dir(storePath), 0755); err != nil {
		return nil, fmt.Errorf("failed to create store directory: %w", err)
	}

	store := &EventStore{
		storePath:  storePath,
		logger:     logger,
		buffer:     make([]*ManagerEvent, 0, bufferSize),
		bufferSize: bufferSize,
		flushTimer: time.NewTicker(time.Second * 30), // Flush toutes les 30s
	}

	// Démarrer la routine de flush périodique
	go store.flushRoutine()

	logger.Info("Event store initialized",
		zap.String("store_path", storePath),
		zap.Int("buffer_size", bufferSize))

	return store, nil
}

// NewPersistentEventBus crée un bus d'événements avec persistance
func NewPersistentEventBus(bufferSize int, storePath string, logger *zap.Logger) (*PersistentEventBus, error) {
	eventBus := NewEventBus(bufferSize, logger)

	store, err := NewEventStore(storePath, 100, logger)
	if err != nil {
		return nil, fmt.Errorf("failed to create event store: %w", err)
	}

	persistentBus := &PersistentEventBus{
		EventBus: eventBus,
		store:    store,
	}

	// S'abonner aux événements critiques pour les persister
	eventBus.Subscribe("*", persistentBus.persistEventHandler)

	return persistentBus, nil
}

// StoreEvent stocke un événement sur disque
func (es *EventStore) StoreEvent(event *ManagerEvent) error {
	es.mu.Lock()
	defer es.mu.Unlock()

	// Ajouter au buffer
	es.buffer = append(es.buffer, event)

	// Flush si le buffer est plein
	if len(es.buffer) >= es.bufferSize {
		return es.flushBuffer()
	}

	return nil
}

// flushBuffer écrit le buffer sur disque
func (es *EventStore) flushBuffer() error {
	if len(es.buffer) == 0 {
		return nil
	}

	// Créer le fichier avec timestamp
	timestamp := time.Now().Format("2006-01-02_15-04-05")
	filename := fmt.Sprintf("events_%s.json", timestamp)
	fullPath := filepath.Join(es.storePath, filename)

	// Créer le répertoire parent si nécessaire
	if err := os.MkdirAll(filepath.Dir(fullPath), 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Préparer les événements persistés
	persistedEvents := make([]*PersistedEvent, len(es.buffer))
	for i, event := range es.buffer {
		persistedEvents[i] = &PersistedEvent{
			Event:    event,
			StoredAt: time.Now(),
			Checksum: es.calculateChecksum(event),
		}
	}

	// Écrire sur disque
	file, err := os.Create(fullPath)
	if err != nil {
		return fmt.Errorf("failed to create event file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(persistedEvents); err != nil {
		return fmt.Errorf("failed to encode events: %w", err)
	}

	es.logger.Info("Events flushed to disk",
		zap.String("file", fullPath),
		zap.Int("event_count", len(es.buffer)))

	// Vider le buffer
	es.buffer = es.buffer[:0]

	return nil
}

// flushRoutine flush périodiquement le buffer
func (es *EventStore) flushRoutine() {
	for range es.flushTimer.C {
		es.mu.Lock()
		if len(es.buffer) > 0 {
			if err := es.flushBuffer(); err != nil {
				es.logger.Error("Failed to flush event buffer", zap.Error(err))
			}
		}
		es.mu.Unlock()
	}
}

// calculateChecksum calcule un checksum pour un événement
func (es *EventStore) calculateChecksum(event *ManagerEvent) string {
	data, _ := json.Marshal(event)
	return fmt.Sprintf("%x", len(data)) // Checksum simple basé sur la taille
}

// LoadEvents charge les événements depuis le disque
func (es *EventStore) LoadEvents(filter EventFilter) ([]*ManagerEvent, error) {
	es.mu.RLock()
	defer es.mu.RUnlock()

	var allEvents []*ManagerEvent

	// Parcourir tous les fichiers d'événements
	err := filepath.Walk(es.storePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if filepath.Ext(path) != ".json" {
			return nil
		}

		events, err := es.loadEventsFromFile(path)
		if err != nil {
			es.logger.Error("Failed to load events from file",
				zap.String("file", path),
				zap.Error(err))
			return nil // Continue avec les autres fichiers
		}

		// Appliquer le filtre
		for _, persistedEvent := range events {
			if es.matchesFilter(persistedEvent.Event, filter) {
				allEvents = append(allEvents, persistedEvent.Event)
			}
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to walk event store: %w", err)
	}

	es.logger.Info("Events loaded from store",
		zap.Int("total_events", len(allEvents)))

	return allEvents, nil
}

// loadEventsFromFile charge les événements d'un fichier spécifique
func (es *EventStore) loadEventsFromFile(filepath string) ([]*PersistedEvent, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	var events []*PersistedEvent
	decoder := json.NewDecoder(file)

	if err := decoder.Decode(&events); err != nil {
		return nil, fmt.Errorf("failed to decode events: %w", err)
	}

	return events, nil
}

// matchesFilter vérifie si un événement correspond au filtre
func (es *EventStore) matchesFilter(event *ManagerEvent, filter EventFilter) bool {
	// Vérifier le type d'événement
	if len(filter.EventTypes) > 0 {
		found := false
		for _, eventType := range filter.EventTypes {
			if eventType == "*" || eventType == event.Type {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Vérifier la priorité minimale
	if event.Priority < filter.MinPriority {
		return false
	}

	// Vérifier la source
	if len(filter.Sources) > 0 {
		found := false
		for _, source := range filter.Sources {
			if source == "*" || source == event.Source {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}

	// Vérifier si on doit persister les événements critiques
	if filter.PersistCritical && event.Priority != PriorityCritical {
		return false
	}

	return true
}

// persistEventHandler gère la persistance des événements
func (peb *PersistentEventBus) persistEventHandler(ctx context.Context, event *ManagerEvent) error {
	// Critères pour persister un événement
	shouldPersist := event.Priority >= PriorityHigh ||
		event.Type == "manager.error" ||
		event.Type == "system.critical" ||
		event.Type == "manager.started" ||
		event.Type == "manager.stopped"

	if shouldPersist {
		return peb.store.StoreEvent(event)
	}

	return nil
}

// GetPersistedEvents récupère les événements persistés selon un filtre
func (peb *PersistentEventBus) GetPersistedEvents(filter EventFilter) ([]*ManagerEvent, error) {
	return peb.store.LoadEvents(filter)
}

// Replay rejone les événements persistés
func (peb *PersistentEventBus) Replay(ctx context.Context, filter EventFilter) error {
	events, err := peb.store.LoadEvents(filter)
	if err != nil {
		return fmt.Errorf("failed to load events for replay: %w", err)
	}

	peb.logger.Info("Starting event replay", zap.Int("event_count", len(events)))

	for _, event := range events {
		// Marquer l'événement comme rejoué
		if event.Data == nil {
			event.Data = make(map[string]interface{})
		}
		event.Data["replayed"] = true
		event.Data["original_timestamp"] = event.Timestamp
		event.Timestamp = time.Now()

		// Republier l'événement
		if err := peb.Publish(ctx, event); err != nil {
			peb.logger.Error("Failed to replay event",
				zap.String("event_id", event.ID),
				zap.Error(err))
		}
	}

	peb.logger.Info("Event replay completed", zap.Int("replayed_count", len(events)))
	return nil
}

// Close ferme le bus persistant et le store
func (peb *PersistentEventBus) Close() error {
	// Flush final du buffer
	peb.store.mu.Lock()
	if err := peb.store.flushBuffer(); err != nil {
		peb.store.logger.Error("Failed final flush", zap.Error(err))
	}
	peb.store.flushTimer.Stop()
	peb.store.mu.Unlock()

	// Fermer le bus d'événements
	return peb.EventBus.Close()
}
