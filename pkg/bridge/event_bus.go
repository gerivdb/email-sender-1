package bridge

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/redis/go-redis/v9"
)

// EventType représente les types d'événements
type EventType string

const (
	WorkflowStarted   EventType = "workflow_started"
	WorkflowCompleted EventType = "workflow_completed"
	WorkflowFailed    EventType = "workflow_failed"
	WorkflowCancelled EventType = "workflow_cancelled"
	WorkflowRetried   EventType = "workflow_retried"
)

// Event représente un événement dans le système
type Event struct {
	ID          string                 `json:"id"`
	Type        EventType              `json:"type"`
	WorkflowID  string                 `json:"workflow_id"`
	ExecutionID string                 `json:"execution_id"`
	Data        map[string]interface{} `json:"data"`
	Timestamp   time.Time              `json:"timestamp"`
	Source      string                 `json:"source"`
	TTL         time.Duration          `json:"ttl,omitempty"`
}

// EventSubscriber interface pour les abonnés aux événements
type EventSubscriber interface {
	OnEvent(event Event) error
	GetSubscriberID() string
	GetEventTypes() []EventType
}

// EventBus interface pour le bus d'événements
type EventBus interface {
	Publish(ctx context.Context, event Event) error
	Subscribe(subscriber EventSubscriber) error
	Unsubscribe(subscriberID string) error
	Start() error
	Stop() error
	GetStats() EventBusStats
}

// EventBusStats statistiques du bus d'événements
type EventBusStats struct {
	TotalPublished   int64     `json:"total_published"`
	TotalSubscribers int       `json:"total_subscribers"`
	ActiveChannels   int       `json:"active_channels"`
	LastActivity     time.Time `json:"last_activity"`
	RedisConnected   bool      `json:"redis_connected"`
}

// ChannelEventBus implémentation du bus d'événements basée sur des channels
type ChannelEventBus struct {
	subscribers    map[string]EventSubscriber
	subscribersMux sync.RWMutex
	eventChan      chan Event
	ctx            context.Context
	cancel         context.CancelFunc
	wg             sync.WaitGroup
	stats          EventBusStats
	statsMux       sync.RWMutex
	redisClient    *redis.Client
	useRedis       bool
}

// EventBusConfig configuration du bus d'événements
type EventBusConfig struct {
	BufferSize    int           `json:"buffer_size"`
	UseRedis      bool          `json:"use_redis"`
	RedisAddr     string        `json:"redis_addr"`
	RedisPassword string        `json:"redis_password"`
	RedisDB       int           `json:"redis_db"`
	TTLDefault    time.Duration `json:"ttl_default"`
}

// NewChannelEventBus crée un nouveau bus d'événements
func NewChannelEventBus(config EventBusConfig) (*ChannelEventBus, error) {
	ctx, cancel := context.WithCancel(context.Background())

	bufferSize := config.BufferSize
	if bufferSize == 0 {
		bufferSize = 1000 // Valeur par défaut
	}

	bus := &ChannelEventBus{
		subscribers:    make(map[string]EventSubscriber),
		subscribersMux: sync.RWMutex{},
		eventChan:      make(chan Event, bufferSize),
		ctx:            ctx,
		cancel:         cancel,
		stats: EventBusStats{
			LastActivity: time.Now(),
		},
		useRedis: config.UseRedis,
	}

	// Configuration Redis pour persistance
	if config.UseRedis {
		rdb := redis.NewClient(&redis.Options{
			Addr:     config.RedisAddr,
			Password: config.RedisPassword,
			DB:       config.RedisDB,
		})

		// Test de connexion
		if err := rdb.Ping(ctx).Err(); err != nil {
			return nil, fmt.Errorf("failed to connect to Redis: %w", err)
		}

		bus.redisClient = rdb
		bus.stats.RedisConnected = true
	}

	return bus, nil
}

// Publish publie un événement
func (b *ChannelEventBus) Publish(ctx context.Context, event Event) error {
	if event.ID == "" {
		event.ID = fmt.Sprintf("%s_%d", event.Type, time.Now().UnixNano())
	}

	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	// Persistance Redis si activée
	if b.useRedis && b.redisClient != nil {
		if err := b.persistEvent(ctx, event); err != nil {
			// Log l'erreur mais continue (failover gracieux)
			fmt.Printf("Failed to persist event to Redis: %v\n", err)
		}
	}

	// Publication dans le channel interne
	select {
	case b.eventChan <- event:
		b.updateStats(true, false)
		return nil
	case <-ctx.Done():
		return ctx.Err()
	default:
		return fmt.Errorf("event bus is full, dropping event %s", event.ID)
	}
}

// Subscribe ajoute un abonné
func (b *ChannelEventBus) Subscribe(subscriber EventSubscriber) error {
	b.subscribersMux.Lock()
	defer b.subscribersMux.Unlock()

	b.subscribers[subscriber.GetSubscriberID()] = subscriber
	b.updateStats(false, true)
	return nil
}

// Unsubscribe supprime un abonné
func (b *ChannelEventBus) Unsubscribe(subscriberID string) error {
	b.subscribersMux.Lock()
	defer b.subscribersMux.Unlock()

	delete(b.subscribers, subscriberID)
	b.updateStats(false, true)
	return nil
}

// Start démarre le bus d'événements
func (b *ChannelEventBus) Start() error {
	b.wg.Add(1)
	go b.processEvents()

	// Si Redis est activé, démarrer aussi la récupération des événements persistés
	if b.useRedis && b.redisClient != nil {
		b.wg.Add(1)
		go b.processPersistedEvents()
	}

	return nil
}

// Stop arrête le bus d'événements
func (b *ChannelEventBus) Stop() error {
	b.cancel()
	close(b.eventChan)
	b.wg.Wait()

	if b.redisClient != nil {
		return b.redisClient.Close()
	}

	return nil
}

// GetStats retourne les statistiques
func (b *ChannelEventBus) GetStats() EventBusStats {
	b.statsMux.RLock()
	defer b.statsMux.RUnlock()

	b.stats.TotalSubscribers = len(b.subscribers)
	b.stats.ActiveChannels = 1 // Pour l'instant, un seul channel

	return b.stats
}

// processEvents traite les événements de manière asynchrone
func (b *ChannelEventBus) processEvents() {
	defer b.wg.Done()

	for {
		select {
		case event, ok := <-b.eventChan:
			if !ok {
				return // Channel fermé
			}

			b.distributeEvent(event)

		case <-b.ctx.Done():
			return
		}
	}
}

// distributeEvent distribue un événement à tous les abonnés pertinents
func (b *ChannelEventBus) distributeEvent(event Event) {
	b.subscribersMux.RLock()
	relevantSubscribers := make([]EventSubscriber, 0)

	for _, subscriber := range b.subscribers {
		eventTypes := subscriber.GetEventTypes()
		for _, eventType := range eventTypes {
			if eventType == event.Type {
				relevantSubscribers = append(relevantSubscribers, subscriber)
				break
			}
		}
	}
	b.subscribersMux.RUnlock()

	// Distribuer l'événement en parallèle
	var wg sync.WaitGroup
	for _, subscriber := range relevantSubscribers {
		wg.Add(1)
		go func(sub EventSubscriber) {
			defer wg.Done()

			// Timeout pour éviter les blocages
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()

			done := make(chan error, 1)
			go func() {
				done <- sub.OnEvent(event)
			}()

			select {
			case err := <-done:
				if err != nil {
					fmt.Printf("Subscriber %s failed to process event %s: %v\n",
						sub.GetSubscriberID(), event.ID, err)
				}
			case <-ctx.Done():
				fmt.Printf("Subscriber %s timed out processing event %s\n",
					sub.GetSubscriberID(), event.ID)
			}
		}(subscriber)
	}

	wg.Wait()
}

// persistEvent persiste un événement dans Redis
func (b *ChannelEventBus) persistEvent(ctx context.Context, event Event) error {
	if b.redisClient == nil {
		return fmt.Errorf("redis client not initialized")
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		return fmt.Errorf("failed to marshal event: %w", err)
	}

	key := fmt.Sprintf("event:%s", event.ID)
	ttl := event.TTL
	if ttl == 0 {
		ttl = 24 * time.Hour // TTL par défaut
	}

	return b.redisClient.Set(ctx, key, eventJSON, ttl).Err()
}

// processPersistedEvents traite les événements persistés dans Redis
func (b *ChannelEventBus) processPersistedEvents() {
	defer b.wg.Done()

	ticker := time.NewTicker(30 * time.Second) // Vérification toutes les 30 secondes
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			b.recoverPersistedEvents()
		case <-b.ctx.Done():
			return
		}
	}
}

// recoverPersistedEvents récupère les événements persistés
func (b *ChannelEventBus) recoverPersistedEvents() {
	if b.redisClient == nil {
		return
	}

	ctx := context.Background()

	// Récupérer les clés d'événements
	keys, err := b.redisClient.Keys(ctx, "event:*").Result()
	if err != nil {
		fmt.Printf("Failed to get event keys from Redis: %v\n", err)
		return
	}

	for _, key := range keys {
		eventJSON, err := b.redisClient.Get(ctx, key).Result()
		if err != nil {
			continue
		}

		var event Event
		if err := json.Unmarshal([]byte(eventJSON), &event); err != nil {
			continue
		}

		// Redistribuer l'événement
		b.distributeEvent(event)

		// Supprimer l'événement traité
		b.redisClient.Del(ctx, key)
	}
}

// updateStats met à jour les statistiques
func (b *ChannelEventBus) updateStats(published, subscriberChanged bool) {
	b.statsMux.Lock()
	defer b.statsMux.Unlock()

	if published {
		b.stats.TotalPublished++
	}

	if subscriberChanged {
		b.stats.TotalSubscribers = len(b.subscribers)
	}

	b.stats.LastActivity = time.Now()
}

// SimpleEventSubscriber exemple d'implémentation d'abonné
type SimpleEventSubscriber struct {
	ID         string
	EventTypes []EventType
	Handler    func(Event) error
}

// NewSimpleEventSubscriber crée un abonné simple
func NewSimpleEventSubscriber(id string, eventTypes []EventType, handler func(Event) error) *SimpleEventSubscriber {
	return &SimpleEventSubscriber{
		ID:         id,
		EventTypes: eventTypes,
		Handler:    handler,
	}
}

// GetSubscriberID retourne l'ID de l'abonné
func (s *SimpleEventSubscriber) GetSubscriberID() string {
	return s.ID
}

// GetEventTypes retourne les types d'événements suivis
func (s *SimpleEventSubscriber) GetEventTypes() []EventType {
	return s.EventTypes
}

// OnEvent traite un événement
func (s *SimpleEventSubscriber) OnEvent(event Event) error {
	if s.Handler != nil {
		return s.Handler(event)
	}
	return nil
}
