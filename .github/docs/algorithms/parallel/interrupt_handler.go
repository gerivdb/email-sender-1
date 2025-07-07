// File: .github/docs/algorithms/parallel/interrupt_handler.go
// EMAIL_SENDER_1 Interrupt Handler
// Module de gestion des interruptions et signaux d'arrêt pour le pipeline parallélisé

package parallel

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"sync"
	"syscall"
	"time"
)

// InterruptReason définit les raisons d'interruption possibles
type InterruptReason string

const (
	// UserInterrupt indique que l'utilisateur a interrompu le traitement
	UserInterrupt InterruptReason = "user_interrupt"
	// Timeout indique que le traitement a dépassé le délai imparti
	Timeout InterruptReason = "timeout"
	// ResourceExhaustion indique que les ressources du système sont épuisées
	ResourceExhaustion InterruptReason = "resource_exhaustion"
	// Error indique qu'une erreur a causé l'interruption
	Error InterruptReason = "error"
	// Shutdown indique un arrêt normal du système
	Shutdown InterruptReason = "shutdown"
)

// InterruptAction définit les actions à prendre lors d'une interruption
type InterruptAction string

const (
	// GracefulStop indique de terminer proprement le traitement en cours avant de s'arrêter
	GracefulStop InterruptAction = "graceful_stop"
	// ImmediateStop indique de s'arrêter immédiatement sans finir le traitement en cours
	ImmediateStop InterruptAction = "immediate_stop"
	// Pause indique de mettre le traitement en pause avec possibilité de reprise
	Pause InterruptAction = "pause"
	// Checkpoint indique de sauvegarder l'état actuel puis s'arrêter
	Checkpoint InterruptAction = "checkpoint"
)

// InterruptHandlerConfig définit la configuration du gestionnaire d'interruptions
type InterruptHandlerConfig struct {
	EnableSignalHandling bool            // Activer la gestion des signaux OS
	EnableTimeouts       bool            // Activer les timeouts
	DefaultAction        InterruptAction // Action par défaut à prendre
	ShutdownTimeout      time.Duration   // Délai maximum pour l'arrêt gracieux
	CheckpointInterval   time.Duration   // Intervalle entre les points de sauvegarde
	CheckpointDir        string          // Répertoire pour les points de sauvegarde
	EnablePause          bool            // Activer la possibilité de pause/reprise
	AutoRestartOnFailure bool            // Redémarrer automatiquement en cas d'échec
	MaxRestartAttempts   int             // Nombre maximum de tentatives de redémarrage
	NotifyOnInterrupt    bool            // Envoyer des notifications sur interruption
}

// DefaultInterruptHandlerConfig retourne une configuration par défaut
func DefaultInterruptHandlerConfig() InterruptHandlerConfig {
	return InterruptHandlerConfig{
		EnableSignalHandling: true,
		EnableTimeouts:       true,
		DefaultAction:        GracefulStop,
		ShutdownTimeout:      30 * time.Second,
		CheckpointInterval:   5 * time.Minute,
		CheckpointDir:        "./checkpoints",
		EnablePause:          true,
		AutoRestartOnFailure: true,
		MaxRestartAttempts:   3,
		NotifyOnInterrupt:    true,
	}
}

// InterruptEvent représente un événement d'interruption
type InterruptEvent struct {
	Reason      InterruptReason
	Action      InterruptAction
	Timestamp   time.Time
	Source      string
	Message     string
	Recoverable bool
}

// InterruptHandler gère les interruptions du pipeline
type InterruptHandler struct {
	config         InterruptHandlerConfig
	eventListeners []func(InterruptEvent)
	sigChan        chan os.Signal
	events         []InterruptEvent
	isPaused       bool
	restartCount   int
	mu             sync.RWMutex
	ctx            context.Context
	cancel         context.CancelFunc
	wg             sync.WaitGroup
}

// NewInterruptHandler crée un nouveau gestionnaire d'interruptions
func NewInterruptHandler(config InterruptHandlerConfig) *InterruptHandler {
	ctx, cancel := context.WithCancel(context.Background())

	handler := &InterruptHandler{
		config:         config,
		eventListeners: make([]func(InterruptEvent), 0),
		events:         make([]InterruptEvent, 0),
		ctx:            ctx,
		cancel:         cancel,
	}

	return handler
}

// Start démarre le gestionnaire d'interruptions
func (ih *InterruptHandler) Start() {
	// Configurer la gestion des signaux OS si activée
	if ih.config.EnableSignalHandling {
		ih.sigChan = make(chan os.Signal, 1)
		signal.Notify(ih.sigChan, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)

		ih.wg.Add(1)
		go func() {
			defer ih.wg.Done()
			ih.handleSignals()
		}()

		log.Printf("Gestionnaire d'interruptions démarré avec gestion des signaux")
	}

	// Configurer les points de sauvegarde périodiques si configurés
	if ih.config.CheckpointInterval > 0 {
		ih.wg.Add(1)
		go func() {
			defer ih.wg.Done()
			ih.checkpointLoop()
		}()
	}
}

// Stop arrête le gestionnaire d'interruptions
func (ih *InterruptHandler) Stop() {
	// Annuler le contexte pour arrêter toutes les goroutines
	ih.cancel()

	// Arrêter la notification des signaux
	if ih.config.EnableSignalHandling && ih.sigChan != nil {
		signal.Stop(ih.sigChan)
		close(ih.sigChan)
	}

	// Attendre que toutes les goroutines se terminent
	ih.wg.Wait()
}

// AddEventListener ajoute un écouteur d'événements d'interruption
func (ih *InterruptHandler) AddEventListener(listener func(InterruptEvent)) {
	ih.mu.Lock()
	defer ih.mu.Unlock()

	ih.eventListeners = append(ih.eventListeners, listener)
}

// HandleInterrupt gère une interruption
func (ih *InterruptHandler) HandleInterrupt(reason InterruptReason, source string, message string) InterruptAction {
	ih.mu.Lock()
	defer ih.mu.Unlock()

	action := ih.config.DefaultAction
	recoverable := true

	// Déterminer l'action en fonction de la raison
	switch reason {
	case UserInterrupt:
		// L'utilisateur peut choisir entre arrêt immédiat ou gracieux
		action = GracefulStop
	case Timeout:
		// Les timeouts sont généralement non récupérables
		action = ImmediateStop
		recoverable = false
	case ResourceExhaustion:
		// En cas de ressources épuisées, on peut essayer une pause ou un checkpoint
		if ih.config.EnablePause {
			action = Pause
		} else {
			action = Checkpoint
		}
	case Error:
		// Tenter un checkpoint si possible, sinon arrêt gracieux
		action = Checkpoint
	case Shutdown:
		// Arrêt normal et gracieux
		action = GracefulStop
	}

	// Créer l'événement d'interruption
	event := InterruptEvent{
		Reason:      reason,
		Action:      action,
		Timestamp:   time.Now(),
		Source:      source,
		Message:     message,
		Recoverable: recoverable,
	}

	// Enregistrer l'événement
	ih.events = append(ih.events, event)

	// Notifier tous les écouteurs
	for _, listener := range ih.eventListeners {
		go listener(event)
	}

	// Logger l'interruption
	log.Printf("⚠️ Interruption: %s de %s - %s (action: %s)",
		reason, source, message, action)

	// Exécuter l'action d'interruption
	ih.executeAction(event)

	return action
}

// executeAction exécute l'action associée à l'événement d'interruption
func (ih *InterruptHandler) executeAction(event InterruptEvent) {
	switch event.Action {
	case GracefulStop:
		// Annuler le contexte pour signaler l'arrêt
		ih.cancel()

	case ImmediateStop:
		// Forcer l'arrêt immédiat
		ih.cancel()
		// Dans un cas réel, on pourrait aussi appeler des fonctions d'arrêt forcé
		// sur les composants critiques qui ne répondent pas assez vite

	case Pause:
		if ih.config.EnablePause {
			ih.setPaused(true)
			log.Printf("Pipeline en pause suite à une interruption: %s", event.Reason)
		} else {
			// Si la pause n'est pas supportée, faire un arrêt gracieux
			ih.cancel()
		}

	case Checkpoint:
		// Créer un point de sauvegarde
		if err := ih.createCheckpoint(); err != nil {
			log.Printf("Erreur lors de la création du checkpoint: %v", err)
			// En cas d'échec du checkpoint, faire un arrêt gracieux
			ih.cancel()
		} else if !event.Recoverable {
			// Si l'événement n'est pas récupérable, arrêter après le checkpoint
			ih.cancel()
		}
	}
}

// SetPause met le pipeline en pause ou reprend son exécution
func (ih *InterruptHandler) SetPause(pause bool) {
	if !ih.config.EnablePause {
		log.Printf("La fonctionnalité de pause n'est pas activée")
		return
	}

	ih.setPaused(pause)
}

// setPaused met à jour l'état de pause interne
func (ih *InterruptHandler) setPaused(pause bool) {
	ih.mu.Lock()
	defer ih.mu.Unlock()

	if ih.isPaused == pause {
		return
	}

	ih.isPaused = pause

	if pause {
		log.Printf("Pipeline mis en pause")
		event := InterruptEvent{
			Reason:      UserInterrupt,
			Action:      Pause,
			Timestamp:   time.Now(),
			Source:      "manual",
			Message:     "Pipeline mis en pause manuellement",
			Recoverable: true,
		}
		ih.events = append(ih.events, event)
	} else {
		log.Printf("Reprise du pipeline")
		event := InterruptEvent{
			Reason:      UserInterrupt,
			Action:      GracefulStop, // Pas vraiment un arrêt, mais une reprise
			Timestamp:   time.Now(),
			Source:      "manual",
			Message:     "Pipeline repris manuellement",
			Recoverable: true,
		}
		ih.events = append(ih.events, event)
	}
}

// IsPaused retourne true si le pipeline est actuellement en pause
func (ih *InterruptHandler) IsPaused() bool {
	ih.mu.RLock()
	defer ih.mu.RUnlock()

	return ih.isPaused
}

// handleSignals gère les signaux du système d'exploitation
func (ih *InterruptHandler) handleSignals() {
	for {
		select {
		case <-ih.ctx.Done():
			return
		case sig, ok := <-ih.sigChan:
			if !ok {
				return
			}

			switch sig {
			case syscall.SIGINT, syscall.SIGTERM:
				ih.HandleInterrupt(UserInterrupt, "signal", fmt.Sprintf("Signal %s reçu", sig))
			case syscall.SIGHUP:
				// SIGHUP peut être utilisé pour recharger la configuration ou créer un checkpoint
				ih.HandleInterrupt(UserInterrupt, "signal", "Signal HUP reçu - création d'un checkpoint")
			}
		}
	}
}

// checkpointLoop crée périodiquement des points de sauvegarde
func (ih *InterruptHandler) checkpointLoop() {
	ticker := time.NewTicker(ih.config.CheckpointInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ih.ctx.Done():
			return
		case <-ticker.C:
			if ih.IsPaused() {
				continue
			}

			if err := ih.createCheckpoint(); err != nil {
				log.Printf("Erreur lors de la création du checkpoint périodique: %v", err)
			} else {
				log.Printf("Checkpoint périodique créé avec succès")
			}
		}
	}
}

// createCheckpoint crée un point de sauvegarde de l'état actuel
func (ih *InterruptHandler) createCheckpoint() error {
	// Dans une implémentation réelle, cette fonction sauvegarderait l'état du pipeline
	// dans un fichier ou une base de données pour permettre une reprise ultérieure

	// Vérifier que le répertoire de checkpoint existe
	if err := os.MkdirAll(ih.config.CheckpointDir, 0755); err != nil {
		return fmt.Errorf("impossible de créer le répertoire de checkpoint: %w", err)
	}

	// Simuler la création d'un checkpoint
	checkpointFile := filepath.Join(ih.config.CheckpointDir,
		fmt.Sprintf("checkpoint_%s.json", time.Now().Format("20060102_150405")))

	// Dans une implémentation réelle, on écrirait ici l'état du pipeline
	dummyData := []byte("{\"checkpoint_time\":\"" + time.Now().String() + "\", \"status\":\"simulated\"}")

	if err := os.WriteFile(checkpointFile, dummyData, 0644); err != nil {
		return fmt.Errorf("erreur lors de l'écriture du checkpoint: %w", err)
	}

	return nil
}

// GetEvents retourne tous les événements d'interruption enregistrés
func (ih *InterruptHandler) GetEvents() []InterruptEvent {
	ih.mu.RLock()
	defer ih.mu.RUnlock()

	// Faire une copie pour éviter les modifications concurrentes
	events := make([]InterruptEvent, len(ih.events))
	copy(events, ih.events)

	return events
}
