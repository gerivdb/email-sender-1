# Points de Communication - Analyse Système

**Date de scan**: 2025-06-18 20:43:49  
**Branche**: dev  
**Fichiers scannés**: 761  
**Points trouvés**: 1893

## 📊 Vue d'Ensemble par Catégorie
### 📡 CHANNELS

- **Points trouvés**: 1049 (55.4%)
- **Fichiers concernés**: 98
- **Patterns recherchés**: 4
### 📡 GRPC_CALLS

- **Points trouvés**: 4 (0.2%)
- **Fichiers concernés**: 2
- **Patterns recherchés**: 4
### 📡 HTTP_ENDPOINTS

- **Points trouvés**: 457 (24.1%)
- **Fichiers concernés**: 61
- **Patterns recherchés**: 9
### 📡 MESSAGE_QUEUES

- **Points trouvés**: 2 (0.1%)
- **Fichiers concernés**: 2
- **Patterns recherchés**: 5
### 📡 REDIS_PUBSUB

- **Points trouvés**: 155 (8.2%)
- **Fichiers concernés**: 17
- **Patterns recherchés**: 6
### 📡 WEBSOCKETS

- **Points trouvés**: 226 (11.9%)
- **Fichiers concernés**: 22
- **Patterns recherchés**: 4

## 🔍 Détail par Catégorie

### 📡 CHANNELS

#### 📄 `adaptive_engine.go`

**Ligne 27** - bidirectional - Package: unknown

```go
stopChan         chan struct{}
```

**Ligne 93** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 93** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

#### 📄 `advanced_autonomy_manager.go`

**Ligne 476** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 476** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 478** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 478** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 492** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 492** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 511** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 511** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 513** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 513** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `advanced-autonomy-manager.go`

**Ligne 339** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 339** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 341** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 341** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `advanced-infrastructure-monitor.go`

**Ligne 335** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 335** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 337** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 337** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `ai_template_manager.go`

**Ligne 569** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 569** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 571** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 571** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `alert_manager.go`

**Ligne 32** - bidirectional - Package: unknown

```go
stopEvaluation     chan struct{}
```

**Ligne 71** - bidirectional - Package: unknown

```go
stopEvaluation:     make(chan struct{}),
```

**Ligne 71** - bidirectional - Package: unknown

```go
stopEvaluation:     make(chan struct{}),
```

**Ligne 483** - receive - Package: unknown

```go
case <-am.evaluationTicker.C:
```

**Ligne 483** - receive - Package: unknown

```go
case <-am.evaluationTicker.C:
```

**Ligne 488** - receive - Package: unknown

```go
case <-am.stopEvaluation:
```

**Ligne 488** - receive - Package: unknown

```go
case <-am.stopEvaluation:
```

**Ligne 501** - bidirectional - Package: unknown

```go
am.stopEvaluation = make(chan struct{}) // Reset for next initialization
```

**Ligne 501** - bidirectional - Package: unknown

```go
am.stopEvaluation = make(chan struct{}) // Reset for next initialization
```

#### 📄 `alert-system.go`

**Ligne 259** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 259** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 261** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 261** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `analyzer.go`

**Ligne 251** - receive - Package: unknown

```go
fmt.Printf("Corrélation %d: %s:%s <-> %s:%s (Score: %.2f, Écart moyen: %s)\n",
```

**Ligne 387** - receive - Package: unknown

```go
fmt.Printf("Corrélation %d: %s:%s <-> %s:%s (Score: %.2f, Écart moyen: %s)\n",
```

**Ligne 525** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 525** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 527** - receive - Package: unknown

```go
case <-time.After(interval):
```

**Ligne 527** - receive - Package: unknown

```go
case <-time.After(interval):
```

#### 📄 `api.go`

**Ligne 24** - receive - Package: unknown

```go
watchers  map[chan<- *config.MCPConfig]struct{}
```

**Ligne 36** - receive - Package: unknown

```go
watchers:  make(map[chan<- *config.MCPConfig]struct{}),
```

**Ligne 63** - receive - Package: unknown

```go
case ch <- mcpConfig:
```

**Ligne 63** - receive - Package: unknown

```go
case ch <- mcpConfig:
```

**Ligne 74** - receive - Package: unknown

```go
case ch <- nil:
```

**Ligne 74** - receive - Package: unknown

```go
case ch <- nil:
```

**Ligne 103** - receive - Package: unknown

```go
func (n *APINotifier) Watch(ctx context.Context) (<-chan *config.MCPConfig, error) {
```

**Ligne 111** - bidirectional - Package: unknown

```go
ch := make(chan *config.MCPConfig, 10)
```

**Ligne 116** - receive - Package: unknown

```go
<-ctx.Done()
```

#### 📄 `batch_indexer.go`

**Ligne 102** - bidirectional - Package: unknown

```go
sem := make(chan struct{}, 4)
```

**Ligne 102** - bidirectional - Package: unknown

```go
sem := make(chan struct{}, 4)
```

**Ligne 110** - receive - Package: unknown

```go
sem <- struct{}{}
```

**Ligne 110** - receive - Package: unknown

```go
sem <- struct{}{}
```

**Ligne 111** - receive - Package: unknown

```go
defer func() { <-sem }()
```

#### 📄 `batch_storage.go`

**Ligne 37** - bidirectional - Package: unknown

```go
flushChan      chan struct{}
```

**Ligne 38** - bidirectional - Package: unknown

```go
closeChan      chan struct{}
```

**Ligne 60** - bidirectional - Package: unknown

```go
flushChan: make(chan struct{}, 1),
```

**Ligne 60** - bidirectional - Package: unknown

```go
flushChan: make(chan struct{}, 1),
```

**Ligne 61** - bidirectional - Package: unknown

```go
closeChan: make(chan struct{}),
```

**Ligne 61** - bidirectional - Package: unknown

```go
closeChan: make(chan struct{}),
```

**Ligne 171** - receive - Package: unknown

```go
case bs.flushChan <- struct{}{}:
```

**Ligne 171** - receive - Package: unknown

```go
case bs.flushChan <- struct{}{}:
```

**Ligne 257** - receive - Package: unknown

```go
case <-bs.flushChan:
```

**Ligne 257** - receive - Package: unknown

```go
case <-bs.flushChan:
```

**Ligne 266** - receive - Package: unknown

```go
case <-bs.closeChan:
```

**Ligne 266** - receive - Package: unknown

```go
case <-bs.closeChan:
```

#### 📄 `branching_manager.go`

**Ligne 30** - bidirectional - Package: unknown

```go
eventQueue        chan interfaces.BranchingEvent
```

**Ligne 40** - bidirectional - Package: unknown

```go
stopChan chan struct{}
```

**Ligne 128** - bidirectional - Package: unknown

```go
eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
```

**Ligne 128** - bidirectional - Package: unknown

```go
eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
```

**Ligne 133** - bidirectional - Package: unknown

```go
stopChan:          make(chan struct{}),
```

**Ligne 133** - bidirectional - Package: unknown

```go
stopChan:          make(chan struct{}),
```

**Ligne 147** - bidirectional - Package: unknown

```go
eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
```

**Ligne 147** - bidirectional - Package: unknown

```go
eventQueue:        make(chan interfaces.BranchingEvent, config.EventQueueSize),
```

**Ligne 152** - bidirectional - Package: unknown

```go
stopChan:          make(chan struct{}),
```

**Ligne 152** - bidirectional - Package: unknown

```go
stopChan:          make(chan struct{}),
```

**Ligne 460** - receive - Package: unknown

```go
case bm.eventQueue <- event:
```

**Ligne 460** - receive - Package: unknown

```go
case bm.eventQueue <- event:
```

**Ligne 495** - receive - Package: unknown

```go
case bm.eventQueue <- event:
```

**Ligne 495** - receive - Package: unknown

```go
case bm.eventQueue <- event:
```

**Ligne 1622** - bidirectional - Package: unknown

```go
resultChan := make(chan interfaces.ApproachResult, len(quantumBranch.Approaches))
```

**Ligne 1622** - bidirectional - Package: unknown

```go
resultChan := make(chan interfaces.ApproachResult, len(quantumBranch.Approaches))
```

**Ligne 1623** - bidirectional - Package: unknown

```go
errorChan := make(chan error, len(quantumBranch.Approaches))
```

**Ligne 1623** - bidirectional - Package: unknown

```go
errorChan := make(chan error, len(quantumBranch.Approaches))
```

**Ligne 1636** - receive - Package: unknown

```go
case result := <-resultChan:
```

**Ligne 1638** - receive - Package: unknown

```go
case err := <-errorChan:
```

**Ligne 1640** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 1640** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2073** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2073** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2077** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2077** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2125** - bidirectional - Package: unknown

```go
func (bm *BranchingManagerImpl) executeApproach(ctx context.Context, approach interfaces.BranchApproach, resultChan chan interfaces.ApproachResult, errorChan chan error) {
```

**Ligne 2151** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 2151** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 2388** - receive - Package: unknown

```go
case event := <-bm.eventQueue:
```

**Ligne 2392** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2392** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2395** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2395** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2422** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2422** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2424** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2424** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2427** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2427** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2471** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2471** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 2473** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2473** - receive - Package: unknown

```go
case <-bm.stopChan:
```

**Ligne 2476** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 2476** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `bridge_server.go`

**Ligne 466** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 466** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 476** - receive - Package: unknown

```go
<-sigChan
```

#### 📄 `cachemetrics.go`

**Ligne 30** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 30** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 32** - receive - Package: unknown

```go
case <-time.After(interval):
```

**Ligne 32** - receive - Package: unknown

```go
case <-time.After(interval):
```

#### 📄 `circuit_breaker.go`

**Ligne 161** - bidirectional - Package: unknown

```go
resultChan := make(chan error, 1)
```

**Ligne 161** - bidirectional - Package: unknown

```go
resultChan := make(chan error, 1)
```

**Ligne 166** - receive - Package: unknown

```go
resultChan <- fmt.Errorf("panic recovered: %v", r)
```

**Ligne 166** - receive - Package: unknown

```go
resultChan <- fmt.Errorf("panic recovered: %v", r)
```

**Ligne 169** - receive - Package: unknown

```go
resultChan <- fn()
```

**Ligne 169** - receive - Package: unknown

```go
resultChan <- fn()
```

**Ligne 173** - receive - Package: unknown

```go
case err := <-resultChan:
```

**Ligne 175** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 175** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `client.go`

**Ligne 309** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 309** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 311** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 311** - receive - Package: unknown

```go
case <-time.After(delay):
```

#### 📄 `complete_ecosystem_integration.go`

**Ligne 128** - bidirectional - Package: unknown

```go
subscribers map[string][]chan interface{}
```

**Ligne 138** - bidirectional - Package: unknown

```go
connections chan interface{}
```

**Ligne 148** - bidirectional - Package: unknown

```go
eventBus:       &EventBus{subscribers: make(map[string][]chan interface{}), logger: logger},
```

**Ligne 150** - bidirectional - Package: unknown

```go
connectionPool: &ConnectionPool{connections: make(chan interface{}, 20), logger: logger},
```

**Ligne 150** - bidirectional - Package: unknown

```go
connectionPool: &ConnectionPool{connections: make(chan interface{}, 20), logger: logger},
```

**Ligne 282** - bidirectional - Package: unknown

```go
errors := make(chan error, vectorsToInsert)
```

**Ligne 282** - bidirectional - Package: unknown

```go
errors := make(chan error, vectorsToInsert)
```

**Ligne 291** - receive - Package: unknown

```go
errors <- nil
```

**Ligne 291** - receive - Package: unknown

```go
errors <- nil
```

**Ligne 322** - bidirectional - Package: unknown

```go
requestErrors := make(chan error, totalRequests)
```

**Ligne 322** - bidirectional - Package: unknown

```go
requestErrors := make(chan error, totalRequests)
```

**Ligne 331** - receive - Package: unknown

```go
requestErrors <- nil
```

**Ligne 331** - receive - Package: unknown

```go
requestErrors <- nil
```

#### 📄 `composite.go`

**Ligne 16** - receive - Package: unknown

```go
watchers  map[chan<- *config.MCPConfig]struct{}
```

**Ligne 24** - receive - Package: unknown

```go
watchers:  make(map[chan<- *config.MCPConfig]struct{}),
```

**Ligne 50** - receive - Package: unknown

```go
go func(notifierCh <-chan *config.MCPConfig) {
```

**Ligne 50** - receive - Package: unknown

```go
go func(notifierCh <-chan *config.MCPConfig) {
```

**Ligne 53** - receive - Package: unknown

```go
case cfg := <-notifierCh:
```

**Ligne 55** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 55** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 70** - receive - Package: unknown

```go
case watcher <- cfg:
```

**Ligne 70** - receive - Package: unknown

```go
case watcher <- cfg:
```

**Ligne 79** - receive - Package: unknown

```go
func (n *CompositeNotifier) Watch(ctx context.Context) (<-chan *config.MCPConfig, error) {
```

**Ligne 83** - bidirectional - Package: unknown

```go
ch := make(chan *config.MCPConfig, 10)
```

**Ligne 88** - receive - Package: unknown

```go
<-ctx.Done()
```

#### 📄 `connection_pool.go`

**Ligne 16** - bidirectional - Package: unknown

```go
available   chan Connection
```

**Ligne 52** - bidirectional - Package: unknown

```go
available:   make(chan Connection, maxSize),
```

**Ligne 52** - bidirectional - Package: unknown

```go
available:   make(chan Connection, maxSize),
```

**Ligne 71** - receive - Package: unknown

```go
pool.available <- conn
```

**Ligne 71** - receive - Package: unknown

```go
pool.available <- conn
```

**Ligne 88** - receive - Package: unknown

```go
case conn := <-cp.available:
```

**Ligne 104** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 104** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 129** - receive - Package: unknown

```go
case conn := <-cp.available:
```

**Ligne 139** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 139** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 141** - receive - Package: unknown

```go
case <-time.After(time.Second * 30): // Timeout après 30s
```

**Ligne 141** - receive - Package: unknown

```go
case <-time.After(time.Second * 30): // Timeout après 30s
```

**Ligne 154** - receive - Package: unknown

```go
case cp.available <- conn:
```

**Ligne 154** - receive - Package: unknown

```go
case cp.available <- conn:
```

#### 📄 `consistency-validator.go`

**Ligne 160** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 160** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `context.go`

**Ligne 494** - bidirectional - Package: unknown

```go
recoveryChan     chan RecoveryResult
```

**Ligne 536** - bidirectional - Package: unknown

```go
recoveryChan:     make(chan RecoveryResult, 10),
```

**Ligne 536** - bidirectional - Package: unknown

```go
recoveryChan:     make(chan RecoveryResult, 10),
```

**Ligne 583** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

**Ligne 583** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

**Ligne 596** - receive - Package: unknown

```go
func (sr *SessionRestore) LoadLastAsync(options *RecoveryOptions) <-chan RecoveryResult {
```

**Ligne 596** - receive - Package: unknown

```go
func (sr *SessionRestore) LoadLastAsync(options *RecoveryOptions) <-chan RecoveryResult {
```

**Ligne 597** - bidirectional - Package: unknown

```go
result := make(chan RecoveryResult, 1)
```

**Ligne 597** - bidirectional - Package: unknown

```go
result := make(chan RecoveryResult, 1)
```

**Ligne 603** - receive - Package: unknown

```go
result <- RecoveryResult{
```

**Ligne 603** - receive - Package: unknown

```go
result <- RecoveryResult{
```

**Ligne 627** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 627** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 631** - receive - Package: unknown

```go
case result := <-sr.recoveryChan:
```

**Ligne 644** - receive - Package: unknown

```go
func (sr *SessionRestore) GetRecoveryChannel() <-chan RecoveryResult {
```

**Ligne 644** - receive - Package: unknown

```go
func (sr *SessionRestore) GetRecoveryChannel() <-chan RecoveryResult {
```

**Ligne 944** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

**Ligne 944** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

**Ligne 953** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

**Ligne 953** - receive - Package: unknown

```go
sr.recoveryChan <- RecoveryResult{
```

#### 📄 `coordinator.go`

**Ligne 106** - bidirectional - Package: unknown

```go
errors := make(chan error, len(cc.managers))
```

**Ligne 106** - bidirectional - Package: unknown

```go
errors := make(chan error, len(cc.managers))
```

**Ligne 113** - receive - Package: unknown

```go
errors <- fmt.Errorf("failed to start manager %s: %w", n, err)
```

**Ligne 113** - receive - Package: unknown

```go
errors <- fmt.Errorf("failed to start manager %s: %w", n, err)
```

**Ligne 146** - bidirectional - Package: unknown

```go
errors := make(chan error, len(cc.managers))
```

**Ligne 146** - bidirectional - Package: unknown

```go
errors := make(chan error, len(cc.managers))
```

**Ligne 153** - receive - Package: unknown

```go
errors <- fmt.Errorf("failed to stop manager %s: %w", n, err)
```

**Ligne 153** - receive - Package: unknown

```go
errors <- fmt.Errorf("failed to stop manager %s: %w", n, err)
```

#### 📄 `cross_manager_event_bus.go`

**Ligne 282** - bidirectional - Package: unknown

```go
cmeb.eventChannels[channelName] = make(chan *CoordinationEvent, cmeb.config.BufferSize)
```

**Ligne 317** - receive - Package: unknown

```go
case cmeb.eventChannels[target] <- event:
```

**Ligne 409** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 409** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 411** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 411** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 423** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 423** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 425** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 425** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 438** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 438** - receive - Package: unknown

```go
case <-cmeb.ctx.Done():
```

**Ligne 440** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 440** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 449** - receive - Package: unknown

```go
case event := <-channel:
```

#### 📄 `detector.go`

**Ligne 141** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 141** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `drift-detector.go`

**Ligne 101** - receive - Package: unknown

```go
case <-dd.ctx.Done():
```

**Ligne 101** - receive - Package: unknown

```go
case <-dd.ctx.Done():
```

**Ligne 104** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 104** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `duplicate_type_detector.go`

**Ligne 110** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 110** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `duplication_handler.go`

**Ligne 88** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 88** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `email_manager.go`

**Ligne 37** - bidirectional - Package: unknown

```go
workerPool     chan struct{}
```

**Ligne 46** - bidirectional - Package: unknown

```go
stopChan       chan struct{}
```

**Ligne 92** - bidirectional - Package: unknown

```go
emailQueue:      make(chan *interfaces.Email, config.QueueSize),
```

**Ligne 93** - bidirectional - Package: unknown

```go
workerPool:      make(chan struct{}, config.Workers),
```

**Ligne 93** - bidirectional - Package: unknown

```go
workerPool:      make(chan struct{}, config.Workers),
```

**Ligne 98** - bidirectional - Package: unknown

```go
stopChan:        make(chan struct{}),
```

**Ligne 98** - bidirectional - Package: unknown

```go
stopChan:        make(chan struct{}),
```

**Ligne 313** - receive - Package: unknown

```go
case em.emailQueue <- email:
```

**Ligne 313** - receive - Package: unknown

```go
case em.emailQueue <- email:
```

**Ligne 316** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 316** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 508** - receive - Package: unknown

```go
case email := <-em.emailQueue:
```

**Ligne 521** - receive - Package: unknown

```go
case <-em.stopChan:
```

**Ligne 521** - receive - Package: unknown

```go
case <-em.stopChan:
```

**Ligne 523** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 523** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `embeddings.go`

**Ligne 54** - bidirectional - Package: unknown

```go
errChan       = make(chan error, 1)
```

**Ligne 54** - bidirectional - Package: unknown

```go
errChan       = make(chan error, 1)
```

**Ligne 55** - bidirectional - Package: unknown

```go
semaphore     = make(chan struct{}, em.config.Batch.MaxConcurrent)
```

**Ligne 55** - bidirectional - Package: unknown

```go
semaphore     = make(chan struct{}, em.config.Batch.MaxConcurrent)
```

**Ligne 70** - receive - Package: unknown

```go
semaphore <- struct{}{}        // Acquire semaphore
```

**Ligne 70** - receive - Package: unknown

```go
semaphore <- struct{}{}        // Acquire semaphore
```

**Ligne 71** - receive - Package: unknown

```go
defer func() { <-semaphore }() // Release semaphore
```

**Ligne 83** - receive - Package: unknown

```go
case errChan <- fmt.Errorf("error generating embeddings for batch starting at %d: %v", startIdx, err):
```

**Ligne 83** - receive - Package: unknown

```go
case errChan <- fmt.Errorf("error generating embeddings for batch starting at %d: %v", startIdx, err):
```

**Ligne 123** - receive - Package: unknown

```go
case err := <-errChan:
```

#### 📄 `emergency_response_system.go`

**Ligne 609** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 609** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 611** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 611** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 623** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 623** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 625** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 625** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 637** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 637** - receive - Package: unknown

```go
case <-ers.ctx.Done():
```

**Ligne 639** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 639** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `engine.go`

**Ligne 124** - bidirectional - Package: unknown

```go
jobs    chan VectorizationRequest
```

**Ligne 125** - bidirectional - Package: unknown

```go
results chan VectorizationResult
```

**Ligne 145** - bidirectional - Package: unknown

```go
jobs:    make(chan VectorizationRequest, 100),
```

**Ligne 145** - bidirectional - Package: unknown

```go
jobs:    make(chan VectorizationRequest, 100),
```

**Ligne 146** - bidirectional - Package: unknown

```go
results: make(chan VectorizationResult, 100),
```

**Ligne 146** - bidirectional - Package: unknown

```go
results: make(chan VectorizationResult, 100),
```

**Ligne 280** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 280** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 282** - receive - Package: unknown

```go
case <-time.After(ve.retryDelay * time.Duration(attempt)):
```

**Ligne 282** - receive - Package: unknown

```go
case <-time.After(ve.retryDelay * time.Duration(attempt)):
```

**Ligne 302** - receive - Package: unknown

```go
case ve.workerPool.jobs <- req:
```

**Ligne 302** - receive - Package: unknown

```go
case ve.workerPool.jobs <- req:
```

**Ligne 303** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 303** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 312** - receive - Package: unknown

```go
case result := <-ve.workerPool.results:
```

**Ligne 314** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 314** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 342** - receive - Package: unknown

```go
case req, ok := <-ve.workerPool.jobs:
```

**Ligne 351** - receive - Package: unknown

```go
case ve.workerPool.results <- result:
```

**Ligne 351** - receive - Package: unknown

```go
case ve.workerPool.results <- result:
```

**Ligne 352** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 352** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 356** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

**Ligne 356** - receive - Package: unknown

```go
case <-ve.workerPool.ctx.Done():
```

#### 📄 `error_handler.go`

**Ligne 115** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 115** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 116** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 116** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `error_integration.go`

**Ligne 84** - bidirectional - Package: unknown

```go
errorQueue   chan ErrorEntry
```

**Ligne 118** - bidirectional - Package: unknown

```go
errorQueue:       make(chan ErrorEntry, 100),
```

**Ligne 118** - bidirectional - Package: unknown

```go
errorQueue:       make(chan ErrorEntry, 100),
```

**Ligne 181** - receive - Package: unknown

```go
case iem.errorQueue <- entry:
```

**Ligne 181** - receive - Package: unknown

```go
case iem.errorQueue <- entry:
```

**Ligne 300** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 300** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 302** - receive - Package: unknown

```go
case <-iem.ctx.Done():
```

**Ligne 302** - receive - Package: unknown

```go
case <-iem.ctx.Done():
```

#### 📄 `event_bus.go`

**Ligne 20** - bidirectional - Package: unknown

```go
shutdownCh     chan struct{}
```

**Ligne 41** - bidirectional - Package: unknown

```go
eventQueue:   make(chan *Event, 1000), // Buffered channel for events
```

**Ligne 45** - bidirectional - Package: unknown

```go
shutdownCh:   make(chan struct{}),
```

**Ligne 45** - bidirectional - Package: unknown

```go
shutdownCh:   make(chan struct{}),
```

**Ligne 61** - bidirectional - Package: unknown

```go
eb.workerPool[i] = make(chan *Event, 100)
```

**Ligne 64** - bidirectional - Package: unknown

```go
eventQueue:  make(chan *ManagerEvent, bufferSize),
```

**Ligne 130** - receive - Package: unknown

```go
case eb.eventQueue <- event:
```

**Ligne 130** - receive - Package: unknown

```go
case eb.eventQueue <- event:
```

**Ligne 147** - receive - Package: unknown

```go
case eb.eventQueue <- event:
```

**Ligne 147** - receive - Package: unknown

```go
case eb.eventQueue <- event:
```

**Ligne 153** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 153** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 155** - receive - Package: unknown

```go
case <-time.After(time.Second * 5): // Timeout après 5s
```

**Ligne 155** - receive - Package: unknown

```go
case <-time.After(time.Second * 5): // Timeout après 5s
```

**Ligne 157** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 157** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 159** - receive - Package: unknown

```go
case <-time.After(5 * time.Second): // Timeout
```

**Ligne 159** - receive - Package: unknown

```go
case <-time.After(5 * time.Second): // Timeout
```

**Ligne 169** - receive - Package: unknown

```go
case event := <-eb.eventQueue:
```

**Ligne 171** - receive - Package: unknown

```go
case <-eb.ctx.Done():
```

**Ligne 171** - receive - Package: unknown

```go
case <-eb.ctx.Done():
```

**Ligne 195** - bidirectional - Package: unknown

```go
errorChan := make(chan error, len(handlers))
```

**Ligne 195** - bidirectional - Package: unknown

```go
errorChan := make(chan error, len(handlers))
```

**Ligne 206** - receive - Package: unknown

```go
errorChan <- err
```

**Ligne 206** - receive - Package: unknown

```go
errorChan <- err
```

**Ligne 238** - receive - Package: unknown

```go
case event, ok := <-eb.eventQueue:
```

**Ligne 248** - receive - Package: unknown

```go
case eb.workerPool[workerIndex] <- event:
```

**Ligne 256** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

**Ligne 256** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

**Ligne 268** - receive - Package: unknown

```go
case event, ok := <-eventCh:
```

**Ligne 276** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

**Ligne 276** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

**Ligne 389** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 389** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 391** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

**Ligne 391** - receive - Package: unknown

```go
case <-eb.shutdownCh:
```

#### 📄 `gateway.go`

**Ligne 257** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 257** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 259** - receive - Package: unknown

```go
<-sigChan
```

#### 📄 `global_state_manager.go`

**Ligne 442** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 442** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 444** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 444** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 456** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 456** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 458** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 458** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 470** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 470** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 472** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 472** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 484** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 484** - receive - Package: unknown

```go
case <-gsm.ctx.Done():
```

**Ligne 486** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 486** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 605** - bidirectional - Package: unknown

```go
syncChannel: make(chan *StateUpdate, 100),
```

**Ligne 619** - receive - Package: unknown

```go
case ss.syncWorkers[workerIndex].syncChannel <- update:
```

**Ligne 619** - receive - Package: unknown

```go
case ss.syncWorkers[workerIndex].syncChannel <- update:
```

**Ligne 671** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 671** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 673** - receive - Package: unknown

```go
case update := <-sw.syncChannel:
```

#### 📄 `health_checker.go`

**Ligne 32** - bidirectional - Package: unknown

```go
stopCh          chan struct{}
```

**Ligne 47** - bidirectional - Package: unknown

```go
stopCh:          make(chan struct{}),
```

**Ligne 47** - bidirectional - Package: unknown

```go
stopCh:          make(chan struct{}),
```

**Ligne 292** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 292** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 298** - receive - Package: unknown

```go
case <-dhc.stopCh:
```

**Ligne 298** - receive - Package: unknown

```go
case <-dhc.stopCh:
```

#### 📄 `health_monitoring.go`

**Ligne 47** - bidirectional - Package: unknown

```go
stopCh:        make(chan struct{}),
```

**Ligne 47** - bidirectional - Package: unknown

```go
stopCh:        make(chan struct{}),
```

**Ligne 63** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 63** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 65** - receive - Package: unknown

```go
case <-m.stopCh:
```

**Ligne 65** - receive - Package: unknown

```go
case <-m.stopCh:
```

**Ligne 67** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 67** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `http-server.go`

**Ligne 154** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 154** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 156** - receive - Package: unknown

```go
<-quit
```

#### 📄 `import_conflict_resolver.go`

**Ligne 125** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 125** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `infrastructure_discovery.go`

**Ligne 63** - bidirectional - Package: unknown

```go
stopChan        chan struct{}
```

**Ligne 81** - bidirectional - Package: unknown

```go
stopChan:     make(chan struct{}),
```

**Ligne 81** - bidirectional - Package: unknown

```go
stopChan:     make(chan struct{}),
```

**Ligne 109** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 109** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 112** - receive - Package: unknown

```go
case <-ids.stopChan:
```

**Ligne 112** - receive - Package: unknown

```go
case <-ids.stopChan:
```

**Ligne 115** - receive - Package: unknown

```go
case <-ids.scanTicker.C:
```

**Ligne 115** - receive - Package: unknown

```go
case <-ids.scanTicker.C:
```

#### 📄 `infrastructure_orchestrator.go`

**Ligne 163** - bidirectional - Package: unknown

```go
stopCh        chan struct{}
```

**Ligne 199** - bidirectional - Package: unknown

```go
stopCh:        make(chan struct{}),
```

**Ligne 199** - bidirectional - Package: unknown

```go
stopCh:        make(chan struct{}),
```

**Ligne 587** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 587** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 590** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 590** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `integration_demo.go`

**Ligne 125** - receive - Package: unknown

```go
<-timeoutCtx.Done()
```

#### 📄 `integration_hub.go`

**Ligne 31** - bidirectional - Package: unknown

```go
shutdownCh      chan struct{}
```

**Ligne 166** - bidirectional - Package: unknown

```go
shutdownCh:       make(chan struct{}),
```

**Ligne 166** - bidirectional - Package: unknown

```go
shutdownCh:       make(chan struct{}),
```

**Ligne 546** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 546** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 548** - receive - Package: unknown

```go
case <-ih.shutdownCh:
```

**Ligne 548** - receive - Package: unknown

```go
case <-ih.shutdownCh:
```

**Ligne 593** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 593** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 595** - receive - Package: unknown

```go
case <-ih.shutdownCh:
```

**Ligne 595** - receive - Package: unknown

```go
case <-ih.shutdownCh:
```

#### 📄 `integration_manager.go`

**Ligne 51** - bidirectional - Package: unknown

```go
shutdownCh     chan struct{}
```

**Ligne 133** - bidirectional - Package: unknown

```go
shutdownCh:     make(chan struct{}),
```

**Ligne 133** - bidirectional - Package: unknown

```go
shutdownCh:     make(chan struct{}),
```

**Ligne 567** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 567** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 569** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 569** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 571** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 571** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 583** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 583** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 585** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 585** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 587** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 587** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 599** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 599** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 601** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 601** - receive - Package: unknown

```go
case <-im.shutdownCh:
```

**Ligne 603** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 603** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `main_simple.go`

**Ligne 86** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 86** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 99** - receive - Package: unknown

```go
case <-sigChan:
```

**Ligne 99** - receive - Package: unknown

```go
case <-sigChan:
```

**Ligne 114** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 114** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 133** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 133** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `main.go`

**Ligne 31** - bidirectional - Package: unknown

```go
signalChan := make(chan os.Signal, 1)
```

**Ligne 31** - bidirectional - Package: unknown

```go
signalChan := make(chan os.Signal, 1)
```

**Ligne 33** - bidirectional - Package: unknown

```go
shutdown chan os.Signal
```

**Ligne 35** - receive - Package: unknown

```go
<-signalChan
```

**Ligne 35** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 35** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 39** - receive - Package: unknown

```go
<-sigChan
```

**Ligne 52** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 52** - bidirectional - Package: unknown

```go
serverErrors := make(chan error, 1)
```

**Ligne 52** - bidirectional - Package: unknown

```go
c := make(chan os.Signal, 1)
```

**Ligne 52** - bidirectional - Package: unknown

```go
c := make(chan os.Signal, 1)
```

**Ligne 52** - bidirectional - Package: unknown

```go
serverErrors := make(chan error, 1)
```

**Ligne 52** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 53** - receive - Package: unknown

```go
<-ctx.Done()
```

**Ligne 54** - receive - Package: unknown

```go
serverErrors <- apiHandler.StartServer(*port)
```

**Ligne 54** - receive - Package: unknown

```go
serverErrors <- apiHandler.StartServer(*port)
```

**Ligne 56** - receive - Package: unknown

```go
<-c
```

**Ligne 58** - bidirectional - Package: unknown

```go
shutdown := make(chan os.Signal, 1)
```

**Ligne 58** - bidirectional - Package: unknown

```go
shutdown := make(chan os.Signal, 1)
```

**Ligne 62** - bidirectional - Package: unknown

```go
errChan := make(chan error, 3)
```

**Ligne 62** - receive - Package: unknown

```go
case err := <-serverErrors:
```

**Ligne 62** - bidirectional - Package: unknown

```go
errChan := make(chan error, 3)
```

**Ligne 63** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 63** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 65** - receive - Package: unknown

```go
case sig := <-shutdown:
```

**Ligne 66** - receive - Package: unknown

```go
<-sigChan
```

**Ligne 67** - bidirectional - Package: unknown

```go
shutdown: make(chan os.Signal, 1),
```

**Ligne 67** - bidirectional - Package: unknown

```go
shutdown: make(chan os.Signal, 1),
```

**Ligne 71** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 71** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 71** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 71** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 73** - receive - Package: unknown

```go
case err := <-errChan:
```

**Ligne 73** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 73** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 79** - receive - Package: unknown

```go
<-ctx.Done()
```

**Ligne 79** - receive - Package: unknown

```go
<-ctx.Done()
```

**Ligne 83** - receive - Package: unknown

```go
func startHTTPServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 83** - receive - Package: unknown

```go
func startHTTPServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 83** - receive - Package: unknown

```go
func startHTTPServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 86** - receive - Package: unknown

```go
errChan <- fmt.Errorf("HTTP server error: %w", err)
```

**Ligne 86** - receive - Package: unknown

```go
errChan <- fmt.Errorf("HTTP server error: %w", err)
```

**Ligne 89** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 89** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 90** - receive - Package: unknown

```go
func startStdioServer(_ context.Context, errChan chan<- error) {
```

**Ligne 90** - receive - Package: unknown

```go
func startStdioServer(_ context.Context, errChan chan<- error) {
```

**Ligne 90** - receive - Package: unknown

```go
func startStdioServer(_ context.Context, errChan chan<- error) {
```

**Ligne 91** - receive - Package: unknown

```go
<-quit
```

**Ligne 92** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 92** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 94** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 94** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 95** - receive - Package: unknown

```go
errChan <- fmt.Errorf("stdio server error: %w", err)
```

**Ligne 95** - receive - Package: unknown

```go
<-server.shutdown
```

**Ligne 95** - receive - Package: unknown

```go
errChan <- fmt.Errorf("stdio server error: %w", err)
```

**Ligne 99** - receive - Package: unknown

```go
func startSSEServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 99** - receive - Package: unknown

```go
func startSSEServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 99** - receive - Package: unknown

```go
func startSSEServer(_ context.Context, addr string, errChan chan<- error) {
```

**Ligne 105** - receive - Package: unknown

```go
errChan <- fmt.Errorf("SSE server error: %w", err)
```

**Ligne 105** - receive - Package: unknown

```go
errChan <- fmt.Errorf("SSE server error: %w", err)
```

**Ligne 109** - receive - Package: unknown

```go
<-sigChan
```

**Ligne 126** - receive - Package: unknown

```go
case <-shutdownCtx.Done():
```

**Ligne 126** - receive - Package: unknown

```go
case <-shutdownCtx.Done():
```

**Ligne 133** - receive - Package: unknown

```go
case <-analysisCtx.Done():
```

**Ligne 133** - receive - Package: unknown

```go
case <-analysisCtx.Done():
```

**Ligne 135** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 135** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 138** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 138** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 151** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 151** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 153** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 153** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 184** - bidirectional - Package: unknown

```go
sigCh := make(chan os.Signal, 1)
```

**Ligne 184** - bidirectional - Package: unknown

```go
sigCh := make(chan os.Signal, 1)
```

**Ligne 186** - bidirectional - Package: unknown

```go
results := make(chan buildResult, len(availableTools))
```

**Ligne 186** - bidirectional - Package: unknown

```go
results := make(chan buildResult, len(availableTools))
```

**Ligne 186** - receive - Package: unknown

```go
<-sigCh
```

**Ligne 187** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 187** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, runtime.NumCPU())
```

**Ligne 187** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, runtime.NumCPU())
```

**Ligne 187** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 188** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 188** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 190** - receive - Package: unknown

```go
<-quit
```

**Ligne 192** - receive - Package: unknown

```go
semaphore <- struct{}{} // Acquire
```

**Ligne 192** - receive - Package: unknown

```go
semaphore <- struct{}{} // Acquire
```

**Ligne 194** - receive - Package: unknown

```go
<-semaphore // Release
```

**Ligne 194** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 194** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 195** - receive - Package: unknown

```go
results <- buildResult{tool: t, err: err}
```

**Ligne 195** - receive - Package: unknown

```go
results <- buildResult{tool: t, err: err}
```

**Ligne 201** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 201** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 202** - receive - Package: unknown

```go
result := <-results
```

**Ligne 203** - bidirectional - Package: unknown

```go
results := make(chan TestResult, len(packages))
```

**Ligne 203** - bidirectional - Package: unknown

```go
results := make(chan TestResult, len(packages))
```

**Ligne 204** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, runtime.NumCPU())
```

**Ligne 204** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, runtime.NumCPU())
```

**Ligne 210** - receive - Package: unknown

```go
case <-quit:
```

**Ligne 210** - receive - Package: unknown

```go
case <-quit:
```

**Ligne 211** - receive - Package: unknown

```go
semaphore <- struct{}{} // Acquire
```

**Ligne 211** - receive - Package: unknown

```go
semaphore <- struct{}{} // Acquire
```

**Ligne 213** - receive - Package: unknown

```go
<-semaphore // Release
```

**Ligne 215** - receive - Package: unknown

```go
results <- result
```

**Ligne 215** - receive - Package: unknown

```go
results <- result
```

**Ligne 226** - receive - Package: unknown

```go
case updateMCPConfig := <-updateCh:
```

**Ligne 233** - bidirectional - Package: unknown

```go
batchChan := make(chan []Point, len(batches))
```

**Ligne 235** - bidirectional - Package: unknown

```go
errChan := make(chan error, numGoroutines)
```

**Ligne 235** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 235** - bidirectional - Package: unknown

```go
errChan := make(chan error, numGoroutines)
```

**Ligne 235** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 236** - bidirectional - Package: unknown

```go
resultChan := make(chan BatchResult, len(batches))
```

**Ligne 236** - bidirectional - Package: unknown

```go
resultChan := make(chan BatchResult, len(batches))
```

**Ligne 245** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: SET failed: %w", id, err)
```

**Ligne 245** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: SET failed: %w", id, err)
```

**Ligne 247** - receive - Package: unknown

```go
batchChan <- batch
```

**Ligne 247** - receive - Package: unknown

```go
batchChan <- batch
```

**Ligne 251** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: GET failed: %w", id, err)
```

**Ligne 251** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: GET failed: %w", id, err)
```

**Ligne 257** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: DEL failed: %w", id, err)
```

**Ligne 257** - receive - Package: unknown

```go
errChan <- fmt.Errorf("goroutine %d: DEL failed: %w", id, err)
```

**Ligne 261** - receive - Package: unknown

```go
errChan <- nil
```

**Ligne 261** - receive - Package: unknown

```go
errChan <- nil
```

**Ligne 267** - receive - Package: unknown

```go
if err := <-errChan; err != nil {
```

**Ligne 273** - receive - Package: unknown

```go
func (em *EmbeddingMigrator) worker(ctx context.Context, batchChan <-chan []Point, resultChan chan<- BatchResult, newCollectionName string, wg *sync.WaitGroup) {
```

**Ligne 273** - receive - Package: unknown

```go
func (em *EmbeddingMigrator) worker(ctx context.Context, batchChan <-chan []Point, resultChan chan<- BatchResult, newCollectionName string, wg *sync.WaitGroup) {
```

**Ligne 273** - receive - Package: unknown

```go
func (em *EmbeddingMigrator) worker(ctx context.Context, batchChan <-chan []Point, resultChan chan<- BatchResult, newCollectionName string, wg *sync.WaitGroup) {
```

**Ligne 280** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 280** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 370** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 370** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 379** - receive - Package: unknown

```go
case sig := <-sigChan:
```

**Ligne 396** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 396** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 400** - receive - Package: unknown

```go
case <-sigChan:
```

**Ligne 400** - receive - Package: unknown

```go
case <-sigChan:
```

**Ligne 403** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 403** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 572** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 572** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 574** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 574** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 636** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 636** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 638** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 638** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `maintenance_manager.go`

**Ligne 456** - receive - Package: unknown

```go
case <-mm.ctx.Done():
```

**Ligne 456** - receive - Package: unknown

```go
case <-mm.ctx.Done():
```

**Ligne 458** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 458** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 471** - receive - Package: unknown

```go
case <-mm.ctx.Done():
```

**Ligne 471** - receive - Package: unknown

```go
case <-mm.ctx.Done():
```

**Ligne 473** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 473** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `manager_discovery.go`

**Ligne 162** - bidirectional - Package: unknown

```go
resultsChan := make(chan *ManagerConnection, len(mds.config.ExpectedManagers))
```

**Ligne 163** - bidirectional - Package: unknown

```go
errorsChan := make(chan error, len(mds.config.ExpectedManagers))
```

**Ligne 163** - bidirectional - Package: unknown

```go
errorsChan := make(chan error, len(mds.config.ExpectedManagers))
```

**Ligne 173** - receive - Package: unknown

```go
errorsChan <- fmt.Errorf("failed to discover %s: %w", name, err)
```

**Ligne 173** - receive - Package: unknown

```go
errorsChan <- fmt.Errorf("failed to discover %s: %w", name, err)
```

**Ligne 178** - receive - Package: unknown

```go
resultsChan <- connection
```

**Ligne 178** - receive - Package: unknown

```go
resultsChan <- connection
```

**Ligne 196** - receive - Package: unknown

```go
case connection, ok := <-resultsChan:
```

**Ligne 212** - receive - Package: unknown

```go
case err, ok := <-errorsChan:
```

**Ligne 220** - receive - Package: unknown

```go
case <-discoveryCtx.Done():
```

**Ligne 220** - receive - Package: unknown

```go
case <-discoveryCtx.Done():
```

**Ligne 455** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 455** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 457** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 457** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `manager_proxies.go`

**Ligne 381** - receive - Package: unknown

```go
case <-time.After(10 * time.Millisecond):
```

**Ligne 381** - receive - Package: unknown

```go
case <-time.After(10 * time.Millisecond):
```

**Ligne 383** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 383** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 493** - receive - Package: unknown

```go
case <-time.After(50 * time.Millisecond):
```

**Ligne 493** - receive - Package: unknown

```go
case <-time.After(50 * time.Millisecond):
```

**Ligne 501** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 501** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `manager.go`

**Ligne 22** - bidirectional - Package: unknown

```go
commands        chan NavigationCommand
```

**Ligne 53** - bidirectional - Package: unknown

```go
commands:       make(chan NavigationCommand, 100),
```

**Ligne 53** - bidirectional - Package: unknown

```go
commands:       make(chan NavigationCommand, 100),
```

**Ligne 255** - receive - Package: unknown

```go
case <-tm.ctx.Done():
```

**Ligne 255** - receive - Package: unknown

```go
case <-tm.ctx.Done():
```

**Ligne 257** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 257** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 406** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 406** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 408** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 408** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 497** - receive - Package: unknown

```go
case cmd := <-nm.commands:
```

**Ligne 499** - receive - Package: unknown

```go
case <-nm.ctx.Done():
```

**Ligne 499** - receive - Package: unknown

```go
case <-nm.ctx.Done():
```

#### 📄 `master_coordination_layer.go`

**Ligne 95** - bidirectional - Package: unknown

```go
ResultChan  chan *OperationResult
```

**Ligne 327** - bidirectional - Package: unknown

```go
ResultChan:     make(chan *OperationResult, 1),
```

**Ligne 334** - receive - Package: unknown

```go
case mcl.orchestrator.operationQueue <- operation:
```

**Ligne 334** - receive - Package: unknown

```go
case mcl.orchestrator.operationQueue <- operation:
```

**Ligne 337** - receive - Package: unknown

```go
case result := <-operation.ResultChan:
```

**Ligne 355** - receive - Package: unknown

```go
case <-time.After(operation.Timeout):
```

**Ligne 355** - receive - Package: unknown

```go
case <-time.After(operation.Timeout):
```

**Ligne 357** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 357** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 361** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 361** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 474** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 474** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 476** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 476** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 488** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 488** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 490** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 490** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 502** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 502** - receive - Package: unknown

```go
case <-mcl.coordinationCtx.Done():
```

**Ligne 504** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 504** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `master_orchestrator.go`

**Ligne 107** - bidirectional - Package: unknown

```go
operationQueue:       make(chan *OrchestrationOperation, 1000),
```

**Ligne 352** - receive - Package: unknown

```go
case <-mo.ctx.Done():
```

**Ligne 352** - receive - Package: unknown

```go
case <-mo.ctx.Done():
```

**Ligne 354** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 354** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 367** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 367** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 369** - receive - Package: unknown

```go
case operation := <-ow.operationQueue:
```

**Ligne 391** - receive - Package: unknown

```go
case operation.ResultChan <- result:
```

**Ligne 391** - receive - Package: unknown

```go
case operation.ResultChan <- result:
```

**Ligne 527** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 527** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 529** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 529** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `mcp_gateway.go`

**Ligne 82** - bidirectional - Package: unknown

```go
tokens    chan struct{}
```

**Ligne 90** - bidirectional - Package: unknown

```go
tokens:    make(chan struct{}, requestsPerMinute),
```

**Ligne 90** - bidirectional - Package: unknown

```go
tokens:    make(chan struct{}, requestsPerMinute),
```

**Ligne 97** - receive - Package: unknown

```go
rl.tokens <- struct{}{}
```

**Ligne 97** - receive - Package: unknown

```go
rl.tokens <- struct{}{}
```

**Ligne 104** - receive - Package: unknown

```go
case rl.tokens <- struct{}{}:
```

**Ligne 104** - receive - Package: unknown

```go
case rl.tokens <- struct{}{}:
```

**Ligne 116** - receive - Package: unknown

```go
case <-rl.tokens:
```

**Ligne 116** - receive - Package: unknown

```go
case <-rl.tokens:
```

**Ligne 118** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 118** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `memory.go`

**Ligne 41** - bidirectional - Package: unknown

```go
queue: make(chan *Message, 100),
```

**Ligne 105** - receive - Package: unknown

```go
func (c *MemoryConnection) EventQueue() <-chan *Message {
```

**Ligne 112** - receive - Package: unknown

```go
case c.queue <- msg:
```

**Ligne 112** - receive - Package: unknown

```go
case c.queue <- msg:
```

#### 📄 `metrics_collector.go`

**Ligne 26** - bidirectional - Package: unknown

```go
stopChan          chan struct{}
```

**Ligne 73** - bidirectional - Package: unknown

```go
metricsBuffer:    make(chan *interfaces.MetricsCollection, config.BufferSize),
```

**Ligne 78** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 78** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 548** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 548** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `metrics.go`

**Ligne 561** - receive - Package: unknown

```go
<-ctx.Done()
```

**Ligne 582** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 582** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 584** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 584** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `monitoring_manager.go`

**Ligne 117** - bidirectional - Package: unknown

```go
stopChan        chan struct{}
```

**Ligne 152** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 152** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 227** - receive - Package: unknown

```go
case mm.stopChan <- struct{}{}:
```

**Ligne 227** - receive - Package: unknown

```go
case mm.stopChan <- struct{}{}:
```

**Ligne 241** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 241** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 243** - receive - Package: unknown

```go
case <-mm.stopChan:
```

**Ligne 243** - receive - Package: unknown

```go
case <-mm.stopChan:
```

**Ligne 245** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 245** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 402** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 402** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 404** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 404** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `monitoring.go`

**Ligne 20** - bidirectional - Package: unknown

```go
stopChan  chan struct{}
```

**Ligne 27** - bidirectional - Package: unknown

```go
stopChan: make(chan struct{}),
```

**Ligne 27** - bidirectional - Package: unknown

```go
stopChan: make(chan struct{}),
```

**Ligne 39** - receive - Package: unknown

```go
case <-m.stopChan:
```

**Ligne 39** - receive - Package: unknown

```go
case <-m.stopChan:
```

**Ligne 41** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 41** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `native.go`

**Ligne 166** - receive - Package: unknown

```go
case <-nm.ctx.Done():
```

**Ligne 166** - receive - Package: unknown

```go
case <-nm.ctx.Done():
```

**Ligne 168** - receive - Package: unknown

```go
case <-nm.collectionTicker.C:
```

**Ligne 168** - receive - Package: unknown

```go
case <-nm.collectionTicker.C:
```

#### 📄 `neural-auto-healing.go`

**Ligne 603** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 603** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 605** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 605** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `notification_manager.go`

**Ligne 41** - bidirectional - Package: unknown

```go
stopChan         chan struct{}
```

**Ligne 109** - bidirectional - Package: unknown

```go
notificationQueue: make(chan *interfaces.Notification, config.QueueSize),
```

**Ligne 112** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 112** - bidirectional - Package: unknown

```go
stopChan:         make(chan struct{}),
```

**Ligne 283** - receive - Package: unknown

```go
case nm.notificationQueue <- notification:
```

**Ligne 283** - receive - Package: unknown

```go
case nm.notificationQueue <- notification:
```

**Ligne 518** - receive - Package: unknown

```go
case notification := <-nm.notificationQueue:
```

**Ligne 522** - receive - Package: unknown

```go
case <-nm.stopChan:
```

**Ligne 522** - receive - Package: unknown

```go
case <-nm.stopChan:
```

#### 📄 `notifier.go`

**Ligne 12** - receive - Package: unknown

```go
Watch(ctx context.Context) (<-chan *config.MCPConfig, error)
```

#### 📄 `performance-test.go`

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `performance.go`

**Ligne 17** - bidirectional - Package: unknown

```go
stopChan         chan struct{}
```

**Ligne 53** - bidirectional - Package: unknown

```go
stopChan:       make(chan struct{}),
```

**Ligne 53** - bidirectional - Package: unknown

```go
stopChan:       make(chan struct{}),
```

**Ligne 95** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 95** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 97** - receive - Package: unknown

```go
case <-pm.stopChan:
```

**Ligne 97** - receive - Package: unknown

```go
case <-pm.stopChan:
```

**Ligne 99** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 99** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `phase_4_performance_validation.go`

**Ligne 90** - bidirectional - Package: unknown

```go
resultChan := make(chan SearchResult, len(queries)*topK)
```

**Ligne 90** - bidirectional - Package: unknown

```go
resultChan := make(chan SearchResult, len(queries)*topK)
```

**Ligne 91** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 91** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 97** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 97** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 98** - receive - Package: unknown

```go
defer func() { <-semaphore }()
```

**Ligne 112** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 112** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 131** - bidirectional - Package: unknown

```go
connections chan interface{}
```

**Ligne 137** - bidirectional - Package: unknown

```go
connections: make(chan interface{}, size),
```

**Ligne 137** - bidirectional - Package: unknown

```go
connections: make(chan interface{}, size),
```

**Ligne 143** - receive - Package: unknown

```go
pool.connections <- fmt.Sprintf("connection_%d", i)
```

**Ligne 143** - receive - Package: unknown

```go
pool.connections <- fmt.Sprintf("connection_%d", i)
```

**Ligne 150** - receive - Package: unknown

```go
return <-cp.connections
```

**Ligne 150** - receive - Package: unknown

```go
return <-cp.connections
```

**Ligne 154** - receive - Package: unknown

```go
cp.connections <- conn
```

**Ligne 154** - receive - Package: unknown

```go
cp.connections <- conn
```

**Ligne 186** - bidirectional - Package: unknown

```go
subscribers map[string][]chan interface{}
```

**Ligne 193** - bidirectional - Package: unknown

```go
subscribers: make(map[string][]chan interface{}),
```

**Ligne 198** - bidirectional - Package: unknown

```go
func (eb *EventBus) Subscribe(topic string, ch chan interface{}) {
```

**Ligne 210** - receive - Package: unknown

```go
case ch <- event:
```

**Ligne 210** - receive - Package: unknown

```go
case ch <- event:
```

**Ligne 308** - bidirectional - Package: unknown

```go
ch1 := make(chan interface{}, 10)
```

**Ligne 308** - bidirectional - Package: unknown

```go
ch1 := make(chan interface{}, 10)
```

**Ligne 309** - bidirectional - Package: unknown

```go
ch2 := make(chan interface{}, 10)
```

**Ligne 309** - bidirectional - Package: unknown

```go
ch2 := make(chan interface{}, 10)
```

**Ligne 347** - bidirectional - Package: unknown

```go
errors := make(chan error, 1000)
```

**Ligne 347** - bidirectional - Package: unknown

```go
errors := make(chan error, 1000)
```

**Ligne 372** - receive - Package: unknown

```go
errors <- err
```

**Ligne 372** - receive - Package: unknown

```go
errors <- err
```

#### 📄 `processor.go`

**Ligne 23** - bidirectional - Package: unknown

```go
stopChan        chan struct{}
```

**Ligne 74** - bidirectional - Package: unknown

```go
stopChan:        make(chan struct{}),
```

**Ligne 74** - bidirectional - Package: unknown

```go
stopChan:        make(chan struct{}),
```

**Ligne 99** - bidirectional - Package: unknown

```go
jobChan := make(chan BatchJob, len(batches))
```

**Ligne 99** - bidirectional - Package: unknown

```go
jobChan := make(chan BatchJob, len(batches))
```

**Ligne 100** - bidirectional - Package: unknown

```go
resultChan := make(chan BatchResult, len(batches))
```

**Ligne 100** - bidirectional - Package: unknown

```go
resultChan := make(chan BatchResult, len(batches))
```

**Ligne 114** - receive - Package: unknown

```go
case jobChan <- batch:
```

**Ligne 114** - receive - Package: unknown

```go
case jobChan <- batch:
```

**Ligne 115** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 115** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 162** - receive - Package: unknown

```go
jobChan <-chan BatchJob,
```

**Ligne 162** - receive - Package: unknown

```go
jobChan <-chan BatchJob,
```

**Ligne 162** - receive - Package: unknown

```go
jobChan <-chan BatchJob,
```

**Ligne 163** - receive - Package: unknown

```go
resultChan chan<- BatchResult,
```

**Ligne 163** - receive - Package: unknown

```go
resultChan chan<- BatchResult,
```

**Ligne 163** - receive - Package: unknown

```go
resultChan chan<- BatchResult,
```

**Ligne 170** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 170** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 174** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 174** - receive - Package: unknown

```go
resultChan <- result
```

#### 📄 `qdrant_client.go`

**Ligne 105** - receive - Package: unknown

```go
case <-time.After(latency * 3): // Extended timeout
```

**Ligne 105** - receive - Package: unknown

```go
case <-time.After(latency * 3): // Extended timeout
```

**Ligne 107** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 107** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 114** - receive - Package: unknown

```go
case <-time.After(latency):
```

**Ligne 114** - receive - Package: unknown

```go
case <-time.After(latency):
```

**Ligne 116** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 116** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `queue_manager.go`

**Ligne 57** - bidirectional - Package: unknown

```go
emailQueue:     make(chan *interfaces.Email, queueSize),
```

**Ligne 185** - receive - Package: unknown

```go
case qm.emailQueue <- email:
```

**Ligne 185** - receive - Package: unknown

```go
case qm.emailQueue <- email:
```

**Ligne 209** - receive - Package: unknown

```go
case email := <-qm.emailQueue:
```

**Ligne 216** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 216** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 294** - receive - Package: unknown

```go
case <-qm.emailQueue:
```

**Ligne 294** - receive - Package: unknown

```go
case <-qm.emailQueue:
```

**Ligne 326** - receive - Package: unknown

```go
case qm.emailQueue <- email:
```

**Ligne 326** - receive - Package: unknown

```go
case qm.emailQueue <- email:
```

**Ligne 399** - receive - Package: unknown

```go
case qm.emailQueue <- scheduledEmail.Email:
```

**Ligne 399** - receive - Package: unknown

```go
case qm.emailQueue <- scheduledEmail.Email:
```

#### 📄 `realtime_bridge.go`

**Ligne 293** - receive - Package: unknown

```go
case event, ok := <-rb.watcher.Events:
```

**Ligne 311** - receive - Package: unknown

```go
case err, ok := <-rb.watcher.Errors:
```

**Ligne 317** - receive - Package: unknown

```go
case <-rb.ctx.Done():
```

**Ligne 317** - receive - Package: unknown

```go
case <-rb.ctx.Done():
```

**Ligne 404** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 404** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 406** - receive - Package: unknown

```go
case <-rb.ctx.Done():
```

**Ligne 406** - receive - Package: unknown

```go
case <-rb.ctx.Done():
```

#### 📄 `reconnection_manager.go`

**Ligne 55** - bidirectional - Package: unknown

```go
stopChan          chan struct{}
```

**Ligne 81** - bidirectional - Package: unknown

```go
stopChan:       make(chan struct{}),
```

**Ligne 81** - bidirectional - Package: unknown

```go
stopChan:       make(chan struct{}),
```

**Ligne 132** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 132** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 134** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 134** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 192** - receive - Package: unknown

```go
case <-rm.healthCheckTicker.C:
```

**Ligne 192** - receive - Package: unknown

```go
case <-rm.healthCheckTicker.C:
```

**Ligne 194** - receive - Package: unknown

```go
case <-rm.stopChan:
```

**Ligne 194** - receive - Package: unknown

```go
case <-rm.stopChan:
```

**Ligne 273** - bidirectional - Package: unknown

```go
stopChan chan struct{}
```

**Ligne 297** - bidirectional - Package: unknown

```go
stopChan: make(chan struct{}),
```

**Ligne 297** - bidirectional - Package: unknown

```go
stopChan: make(chan struct{}),
```

**Ligne 316** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 316** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 318** - receive - Package: unknown

```go
case <-hc.stopChan:
```

**Ligne 318** - receive - Package: unknown

```go
case <-hc.stopChan:
```

#### 📄 `redis.go`

**Ligne 47** - receive - Package: unknown

```go
func (r *RedisNotifier) Watch(ctx context.Context) (<-chan *config.MCPConfig, error) {
```

**Ligne 52** - bidirectional - Package: unknown

```go
ch := make(chan *config.MCPConfig, 10)
```

**Ligne 63** - receive - Package: unknown

```go
case ch <- &cfg:
```

**Ligne 64** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 64** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 105** - receive - Package: unknown

```go
case conn.queue <- update.Message:
```

**Ligne 105** - receive - Package: unknown

```go
case conn.queue <- update.Message:
```

**Ligne 169** - bidirectional - Package: unknown

```go
queue: make(chan *Message, 100),
```

**Ligne 225** - bidirectional - Package: unknown

```go
queue: make(chan *Message, 100),
```

**Ligne 290** - bidirectional - Package: unknown

```go
queue: make(chan *Message, 100),
```

**Ligne 317** - receive - Package: unknown

```go
func (c *RedisConnection) EventQueue() <-chan *Message {
```

#### 📄 `report_generator.go`

**Ligne 123** - receive - Package: unknown

```go
fmt.Sprintf("ATTENTION: Corrélation forte détectée %s:%s <-> %s:%s (%.2f)",
```

#### 📄 `resolver.go`

**Ligne 172** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 172** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `scheduler.go`

**Ligne 87** - bidirectional - Package: unknown

```go
taskQueue:      make(chan *TaskExecution, 100), // Buffer for 100 tasks
```

**Ligne 274** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 274** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 276** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 276** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 312** - receive - Package: unknown

```go
case ms.taskQueue <- execution:
```

**Ligne 312** - receive - Package: unknown

```go
case ms.taskQueue <- execution:
```

**Ligne 342** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 342** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 345** - receive - Package: unknown

```go
case execution, ok := <-w.scheduler.taskQueue:
```

**Ligne 409** - receive - Package: unknown

```go
case w.scheduler.taskQueue <- execution:
```

**Ligne 409** - receive - Package: unknown

```go
case w.scheduler.taskQueue <- execution:
```

#### 📄 `script_manager.go`

**Ligne 647** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 647** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 648** - receive - Package: unknown

```go
case <-sm.ctx.Done():
```

**Ligne 648** - receive - Package: unknown

```go
case <-sm.ctx.Done():
```

#### 📄 `search.go`

**Ligne 92** - bidirectional - Package: unknown

```go
done := make(chan *ValidationResult, 1)
```

**Ligne 96** - receive - Package: unknown

```go
done <- result
```

**Ligne 96** - receive - Package: unknown

```go
done <- result
```

**Ligne 100** - receive - Package: unknown

```go
case result := <-done:
```

**Ligne 105** - receive - Package: unknown

```go
case <-timeout:
```

**Ligne 105** - receive - Package: unknown

```go
case <-timeout:
```

#### 📄 `security_manager.go`

**Ligne 507** - bidirectional - Package: unknown

```go
eventChan chan AuditEvent
```

**Ligne 515** - bidirectional - Package: unknown

```go
eventChan: make(chan AuditEvent, 100),
```

**Ligne 515** - bidirectional - Package: unknown

```go
eventChan: make(chan AuditEvent, 100),
```

**Ligne 555** - receive - Package: unknown

```go
case al.eventChan <- event:
```

**Ligne 555** - receive - Package: unknown

```go
case al.eventChan <- event:
```

**Ligne 565** - receive - Package: unknown

```go
case event, ok := <-al.eventChan:
```

**Ligne 571** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 571** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `server.go`

**Ligne 36** - bidirectional - Package: unknown

```go
shutdownCh chan struct{}
```

**Ligne 52** - bidirectional - Package: unknown

```go
shutdownCh:      make(chan struct{}),
```

**Ligne 52** - bidirectional - Package: unknown

```go
shutdownCh:      make(chan struct{}),
```

#### 📄 `session.go`

**Ligne 34** - receive - Package: unknown

```go
EventQueue() <-chan *Message
```

#### 📄 `signal.go`

**Ligne 51** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 51** - bidirectional - Package: unknown

```go
sigChan := make(chan os.Signal, 1)
```

**Ligne 56** - receive - Package: unknown

```go
case sig := <-sigChan:
```

**Ligne 60** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 60** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 74** - receive - Package: unknown

```go
case ch <- nil:
```

**Ligne 74** - receive - Package: unknown

```go
case ch <- nil:
```

**Ligne 83** - receive - Package: unknown

```go
func (n *SignalNotifier) Watch(ctx context.Context) (<-chan *config.MCPConfig, error) {
```

**Ligne 91** - bidirectional - Package: unknown

```go
ch := make(chan *config.MCPConfig, 10) // Buffered channel to prevent blocking
```

**Ligne 96** - receive - Package: unknown

```go
<-ctx.Done()
```

#### 📄 `simple_freeze_fix.go`

**Ligne 35** - bidirectional - Package: unknown

```go
done   chan struct{}
```

**Ligne 82** - bidirectional - Package: unknown

```go
done:   make(chan struct{}),
```

**Ligne 82** - bidirectional - Package: unknown

```go
done:   make(chan struct{}),
```

**Ligne 94** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 94** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 97** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 97** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 136** - bidirectional - Package: unknown

```go
workersDone := make(chan struct{})
```

**Ligne 136** - bidirectional - Package: unknown

```go
workersDone := make(chan struct{})
```

**Ligne 142** - receive - Package: unknown

```go
case <-worker.done:
```

**Ligne 142** - receive - Package: unknown

```go
case <-worker.done:
```

**Ligne 144** - receive - Package: unknown

```go
case <-time.After(2 * time.Second):
```

**Ligne 144** - receive - Package: unknown

```go
case <-time.After(2 * time.Second):
```

**Ligne 153** - receive - Package: unknown

```go
case <-workersDone:
```

**Ligne 153** - receive - Package: unknown

```go
case <-workersDone:
```

**Ligne 155** - receive - Package: unknown

```go
case <-time.After(5 * time.Second):
```

**Ligne 155** - receive - Package: unknown

```go
case <-time.After(5 * time.Second):
```

#### 📄 `smart_orchestrator.go`

**Ligne 371** - receive - Package: unknown

```go
case <-timeout.C:
```

**Ligne 371** - receive - Package: unknown

```go
case <-timeout.C:
```

**Ligne 373** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 373** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 377** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `smart_variable_manager.go`

**Ligne 501** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 501** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 503** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 503** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 515** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 515** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 517** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 517** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `sse.go`

**Ligne 120** - receive - Package: unknown

```go
case event := <-conn.EventQueue():
```

**Ligne 154** - receive - Package: unknown

```go
case <-c.Request.Context().Done():
```

**Ligne 154** - receive - Package: unknown

```go
case <-c.Request.Context().Done():
```

**Ligne 160** - receive - Package: unknown

```go
case <-s.shutdownCh:
```

**Ligne 160** - receive - Package: unknown

```go
case <-s.shutdownCh:
```

#### 📄 `startup_sequencer.go`

**Ligne 211** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 211** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 214** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 214** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `streamable.go`

**Ligne 70** - receive - Package: unknown

```go
case event := <-conn.EventQueue():
```

**Ligne 80** - receive - Package: unknown

```go
case <-c.Request.Context().Done():
```

**Ligne 80** - receive - Package: unknown

```go
case <-c.Request.Context().Done():
```

**Ligne 82** - receive - Package: unknown

```go
case <-s.shutdownCh:
```

**Ligne 82** - receive - Package: unknown

```go
case <-s.shutdownCh:
```

#### 📄 `struct_validator.go`

**Ligne 154** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 154** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `sync.go`

**Ligne 146** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, s.config.MaxConcurrency)
```

**Ligne 146** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, s.config.MaxConcurrency)
```

**Ligne 152** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 152** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 153** - receive - Package: unknown

```go
defer func() { <-semaphore }()
```

#### 📄 `templates.go`

**Ligne 514** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 514** - bidirectional - Package: unknown

```go
quit := make(chan os.Signal, 1)
```

**Ligne 516** - receive - Package: unknown

```go
<-quit
```

#### 📄 `unified_client.go`

**Ligne 185** - receive - Package: unknown

```go
case <-time.After(backoff):
```

**Ligne 185** - receive - Package: unknown

```go
case <-time.After(backoff):
```

**Ligne 186** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 186** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `validate_phase5.go`

**Ligne 222** - bidirectional - Package: unknown

```go
done := make(chan error, 1)
```

**Ligne 222** - bidirectional - Package: unknown

```go
done := make(chan error, 1)
```

**Ligne 228** - receive - Package: unknown

```go
done <- err
```

**Ligne 228** - receive - Package: unknown

```go
done <- err
```

**Ligne 232** - receive - Package: unknown

```go
case err = <-done:
```

**Ligne 250** - receive - Package: unknown

```go
case <-time.After(suite.Timeout):
```

**Ligne 250** - receive - Package: unknown

```go
case <-time.After(suite.Timeout):
```

#### 📄 `vector_client.go`

**Ligne 165** - bidirectional - Package: unknown

```go
resultChan := make(chan SearchResult, len(queries)*topK)
```

**Ligne 165** - bidirectional - Package: unknown

```go
resultChan := make(chan SearchResult, len(queries)*topK)
```

**Ligne 166** - bidirectional - Package: unknown

```go
errChan := make(chan error, len(queries))
```

**Ligne 166** - bidirectional - Package: unknown

```go
errChan := make(chan error, len(queries))
```

**Ligne 169** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 169** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 181** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 181** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 182** - receive - Package: unknown

```go
defer func() { <-semaphore }()
```

**Ligne 187** - receive - Package: unknown

```go
errChan <- fmt.Errorf("échec de la recherche pour la requête %d: %w", idx, err)
```

**Ligne 187** - receive - Package: unknown

```go
errChan <- fmt.Errorf("échec de la recherche pour la requête %d: %w", idx, err)
```

**Ligne 194** - receive - Package: unknown

```go
resultChan <- result
```

**Ligne 194** - receive - Package: unknown

```go
resultChan <- result
```

#### 📄 `vector_operations.go`

**Ligne 153** - bidirectional - Package: unknown

```go
resultChan := make(chan struct {
```

**Ligne 153** - bidirectional - Package: unknown

```go
resultChan := make(chan struct {
```

**Ligne 160** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 160** - bidirectional - Package: unknown

```go
semaphore := make(chan struct{}, 10) // Limiter à 10 goroutines concurrentes
```

**Ligne 167** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 167** - receive - Package: unknown

```go
semaphore <- struct{}{}
```

**Ligne 168** - receive - Package: unknown

```go
defer func() { <-semaphore }()
```

**Ligne 171** - receive - Package: unknown

```go
resultChan <- struct {
```

**Ligne 171** - receive - Package: unknown

```go
resultChan <- struct {
```

**Ligne 259** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 259** - receive - Package: unknown

```go
case <-time.After(delay):
```

**Ligne 260** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 260** - receive - Package: unknown

```go
case <-ctx.Done():
```

#### 📄 `vectorization-metrics.go`

**Ligne 298** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 298** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 300** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 300** - receive - Package: unknown

```go
case <-ticker.C:
```

#### 📄 `webhook_integration_manager.go`

**Ligne 379** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 379** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 381** - receive - Package: unknown

```go
case <-time.After(time.Duration(attempt) * time.Second):
```

**Ligne 381** - receive - Package: unknown

```go
case <-time.After(time.Duration(attempt) * time.Second):
```

#### 📄 `worker-pool.go`

**Ligne 26** - bidirectional - Package: unknown

```go
taskQueue chan Task
```

**Ligne 87** - bidirectional - Package: unknown

```go
taskQueue: make(chan Task, config.QueueSize),
```

**Ligne 87** - bidirectional - Package: unknown

```go
taskQueue: make(chan Task, config.QueueSize),
```

**Ligne 108** - receive - Package: unknown

```go
case wp.taskQueue <- task:
```

**Ligne 108** - receive - Package: unknown

```go
case wp.taskQueue <- task:
```

**Ligne 111** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 111** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 149** - receive - Package: unknown

```go
case task := <-wp.taskQueue:
```

**Ligne 168** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 168** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 177** - receive - Package: unknown

```go
case <-time.After(time.Second):
```

**Ligne 177** - receive - Package: unknown

```go
case <-time.After(time.Second):
```

**Ligne 198** - bidirectional - Package: unknown

```go
done := make(chan error, 1)
```

**Ligne 198** - bidirectional - Package: unknown

```go
done := make(chan error, 1)
```

**Ligne 201** - receive - Package: unknown

```go
done <- task.Execute(task.Payload)
```

**Ligne 201** - receive - Package: unknown

```go
done <- task.Execute(task.Payload)
```

**Ligne 205** - receive - Package: unknown

```go
case err := <-done:
```

**Ligne 207** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 207** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 219** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 219** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 221** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 221** - receive - Package: unknown

```go
case <-wp.ctx.Done():
```

**Ligne 273** - bidirectional - Package: unknown

```go
done := make(chan struct{})
```

**Ligne 273** - bidirectional - Package: unknown

```go
done := make(chan struct{})
```

**Ligne 280** - receive - Package: unknown

```go
case <-done:
```

**Ligne 280** - receive - Package: unknown

```go
case <-done:
```

**Ligne 282** - receive - Package: unknown

```go
case <-time.After(timeout):
```

**Ligne 282** - receive - Package: unknown

```go
case <-time.After(timeout):
```

#### 📄 `workflow_orchestrator.go`

**Ligne 665** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 665** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 668** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 668** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 692** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 692** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 695** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 695** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 749** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 749** - receive - Package: unknown

```go
case <-ctx.Done():
```

**Ligne 752** - receive - Package: unknown

```go
case <-ticker.C:
```

**Ligne 752** - receive - Package: unknown

```go
case <-ticker.C:
```

### 📡 GRPC_CALLS

#### 📄 `context.go`

**Ligne 1044** - bidirectional - Package: unknown

```go
FormatProtobuf ExportFormat = "protobuf"
```

#### 📄 `vector_registry.go`

**Ligne 65** - bidirectional - Package: unknown

```go
conn           *grpc.ClientConn
```

**Ligne 87** - bidirectional - Package: unknown

```go
conn, err := grpc.Dial(
```

**Ligne 89** - bidirectional - Package: unknown

```go
grpc.WithTransportCredentials(insecure.NewCredentials()),
```

### 📡 HTTP_ENDPOINTS

#### 📄 `api_analyzer.go`

**Ligne 305** - inbound - Package: unknown

```go
if authHeader := resp.Header.Get("WWW-Authenticate"); authHeader != "" {
```

**Ligne 350** - inbound - Package: unknown

```go
if value := resp.Header.Get(header); value != "" {
```

#### 📄 `api.go`

**Ligne 37** - bidirectional - Package: unknown

```go
router:    gin.Default(),
```

**Ligne 44** - inbound - Package: unknown

```go
n.router.POST("/_reload", func(c *gin.Context) {
```

**Ligne 44** - inbound - Package: unknown

```go
n.router.POST("/_reload", func(c *gin.Context) {
```

**Ligne 127** - inbound - Package: unknown

```go
resp, err := client.Get(s.url)
```

**Ligne 147** - inbound - Package: unknown

```go
result := gjson.Get(jsonString, s.configJSONPath)
```

#### 📄 `apikey.go`

**Ligne 18** - inbound - Package: unknown

```go
apiKey := r.Header.Get(a.Header)
```

#### 📄 `auth_security.go`

**Ligne 437** - inbound - Package: unknown

```go
if req.Header.Get(header) == "" {
```

**Ligne 444** - inbound - Package: unknown

```go
origin := req.Header.Get("Origin")
```

#### 📄 `auth.go`

**Ligne 122** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 189** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 208** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 241** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 470** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 519** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

#### 📄 `basic.go`

**Ligne 20** - inbound - Package: unknown

```go
auth := r.Header.Get("Authorization")
```

#### 📄 `bearer.go`

**Ligne 19** - inbound - Package: unknown

```go
token := r.Header.Get(a.Header)
```

#### 📄 `branching_manager.go`

**Ligne 32** - bidirectional - Package: unknown

```go
if err := router.ValidateRoutingDecision(decision); err != nil {
```

**Ligne 1242** - inbound - Package: unknown

```go
snapshotData, err := bm.storageManager.Get(ctx, "snapshots", snapshotID)
```

**Ligne 1966** - inbound - Package: unknown

```go
templateData, err := bm.storageManager.Get(ctx, "templates", templateID)
```

**Ligne 2561** - inbound - Package: unknown

```go
branchData, err := bm.storageManager.Get(ctx, "branches", branchID)
```

#### 📄 `bridge_server.go`

**Ligne 213** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/errors", pb.handleErrors)
```

**Ligne 216** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/health", pb.handleHealth)
```

**Ligne 219** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/stats", pb.handleStats)
```

**Ligne 222** - bidirectional - Package: unknown

```go
var handler http.Handler = mux
```

**Ligne 317** - bidirectional - Package: unknown

```go
func (pb *PowerShellBridge) corsMiddleware(next http.Handler) http.Handler {
```

**Ligne 318** - bidirectional - Package: unknown

```go
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
```

**Ligne 333** - bidirectional - Package: unknown

```go
func (pb *PowerShellBridge) loggingMiddleware(next http.Handler) http.Handler {
```

**Ligne 334** - bidirectional - Package: unknown

```go
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
```

#### 📄 `client.go`

**Ligne 91** - inbound - Package: unknown

```go
resp, err := c.HTTPClient.Get(fmt.Sprintf("%s/healthz", c.BaseURL))
```

**Ligne 117** - inbound - Package: unknown

```go
resp, err := shortClient.Get(fmt.Sprintf("%s/", c.BaseURL))
```

#### 📄 `conformity_api.go`

**Ligne 28** - bidirectional - Package: unknown

```go
gin.SetMode(gin.ReleaseMode)
```

**Ligne 29** - bidirectional - Package: unknown

```go
router := gin.New()
```

**Ligne 32** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 32** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 33** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 33** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 34** - bidirectional - Package: unknown

```go
router.Use(corsMiddleware())
```

**Ligne 35** - bidirectional - Package: unknown

```go
router.Use(authMiddleware())
```

**Ligne 51** - bidirectional - Package: unknown

```go
v1 := s.router.Group("/api/conformity")
```

**Ligne 54** - inbound - Package: unknown

```go
v1.GET("/managers/:name", s.getManagerConformity)
```

**Ligne 55** - inbound - Package: unknown

```go
v1.POST("/managers/:name/verify", s.verifyManagerConformity)
```

**Ligne 56** - inbound - Package: unknown

```go
v1.PUT("/managers/:name/status", s.updateManagerStatus)
```

**Ligne 59** - inbound - Package: unknown

```go
v1.GET("/ecosystem/status", s.getEcosystemStatus)
```

**Ligne 60** - inbound - Package: unknown

```go
v1.POST("/ecosystem/verify", s.verifyEcosystemConformity)
```

**Ligne 63** - inbound - Package: unknown

```go
v1.POST("/reports/generate", s.generateConformityReport)
```

**Ligne 64** - inbound - Package: unknown

```go
v1.GET("/reports/formats", s.getReportFormats)
```

**Ligne 67** - inbound - Package: unknown

```go
v1.GET("/badges/:manager/:type", s.generateConformityBadge)
```

**Ligne 68** - inbound - Package: unknown

```go
v1.GET("/badges/ecosystem/:type", s.generateEcosystemBadge)
```

**Ligne 71** - inbound - Package: unknown

```go
v1.GET("/config", s.getConformityConfig)
```

**Ligne 72** - inbound - Package: unknown

```go
v1.PUT("/config", s.updateConformityConfig)
```

**Ligne 75** - inbound - Package: unknown

```go
v1.GET("/health", s.healthCheck)
```

**Ligne 76** - inbound - Package: unknown

```go
v1.GET("/metrics", s.getMetrics)
```

**Ligne 80** - inbound - Package: unknown

```go
s.router.GET("/api/docs/conformity", s.getAPIDocumentation)
```

**Ligne 80** - inbound - Package: unknown

```go
s.router.GET("/api/docs/conformity", s.getAPIDocumentation)
```

#### 📄 `conformity_manager.go`

**Ligne 598** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 759** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 920** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1081** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1242** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1403** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1564** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1725** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

**Ligne 1887** - inbound - Package: unknown

```go
cm.cache.Delete(managerName)
```

#### 📄 `contextual_memory_manager.go`

**Ligne 111** - inbound - Package: unknown

```go
return c.indexManager.Delete(ctx, documentID)
```

#### 📄 `core.go`

**Ligne 113** - inbound - Package: unknown

```go
lang, exists := c.Get(cnst.XLang)
```

**Ligne 129** - inbound - Package: unknown

```go
lang := r.Header.Get(cnst.XLang)
```

**Ligne 135** - inbound - Package: unknown

```go
acceptLang := r.Header.Get("Accept-Language")
```

**Ligne 164** - inbound - Package: unknown

```go
lang, exists := c.Get(cnst.XLang)
```

#### 📄 `cross_manager_event_bus.go`

**Ligne 309** - bidirectional - Package: unknown

```go
targets, err := cmeb.eventRouter.GetTargets(event)
```

**Ligne 386** - bidirectional - Package: unknown

```go
if err := cmeb.eventRouter.cleanup(); err != nil {
```

**Ligne 487** - bidirectional - Package: unknown

```go
router.initializeDefaultRoutingTable()
```

#### 📄 `db.go`

**Ligne 297** - inbound - Package: unknown

```go
if err := tx.Delete(&v).Error; err != nil {
```

**Ligne 355** - inbound - Package: unknown

```go
if err := tx.Where("tenant = ? AND name = ?", tenant, name).Delete(&ActiveVersion{}).Error; err != nil {
```

**Ligne 360** - inbound - Package: unknown

```go
if err := tx.Where("tenant = ? AND name = ?", tenant, name).Delete(&MCPConfig{}).Error; err != nil {
```

**Ligne 427** - inbound - Package: unknown

```go
if err := tx.Where("tenant = ? AND name = ? AND version = ?", tenant, name, version).Delete(&MCPConfigVersion{}).Error; err != nil {
```

#### 📄 `engine.go`

**Ligne 185** - inbound - Package: unknown

```go
if cached, found := ve.cache.Get(text); found {
```

**Ligne 217** - inbound - Package: unknown

```go
if cached, found := ve.cache.Get(text); found {
```

#### 📄 `error.go`

**Ligne 113** - inbound - Package: unknown

```go
lang, exists := c.Get(cnst.XLang)
```

**Ligne 224** - inbound - Package: unknown

```go
lang, exists := c.Get(cnst.XLang)
```

#### 📄 `factory.go`

**Ligne 119** - inbound - Package: unknown

```go
resp, err := client.Get(cf.baseURL + "/")
```

#### 📄 `fallback_cache.go`

**Ligne 222** - inbound - Package: unknown

```go
result, err := hrc.client.Get(ctx, key).Result()
```

**Ligne 234** - inbound - Package: unknown

```go
return hrc.localCache.Get(ctx, key)
```

**Ligne 256** - inbound - Package: unknown

```go
if err := hrc.localCache.Delete(ctx, key); err != nil {
```

#### 📄 `gateway.go`

**Ligne 44** - bidirectional - Package: unknown

```go
gin.SetMode(gin.ReleaseMode)
```

**Ligne 45** - bidirectional - Package: unknown

```go
router := gin.New()
```

**Ligne 46** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 46** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 65** - bidirectional - Package: unknown

```go
ag.router.Use(ag.corsMiddleware())
```

**Ligne 66** - bidirectional - Package: unknown

```go
ag.router.Use(ag.rateLimitMiddleware())
```

**Ligne 67** - bidirectional - Package: unknown

```go
ag.router.Use(ag.loggingMiddleware())
```

**Ligne 68** - bidirectional - Package: unknown

```go
ag.router.Use(ag.authMiddleware())
```

**Ligne 71** - inbound - Package: unknown

```go
ag.router.GET("/health", ag.healthCheck)
```

**Ligne 71** - inbound - Package: unknown

```go
ag.router.GET("/health", ag.healthCheck)
```

**Ligne 72** - inbound - Package: unknown

```go
ag.router.GET("/ready", ag.readinessCheck)
```

**Ligne 72** - inbound - Package: unknown

```go
ag.router.GET("/ready", ag.readinessCheck)
```

**Ligne 75** - inbound - Package: unknown

```go
ag.router.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
```

**Ligne 75** - inbound - Package: unknown

```go
ag.router.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
```

**Ligne 78** - bidirectional - Package: unknown

```go
v1 := ag.router.Group("/api/v1")
```

**Ligne 81** - inbound - Package: unknown

```go
v1.GET("/managers", ag.listManagers)
```

**Ligne 82** - inbound - Package: unknown

```go
v1.GET("/managers/:name/status", ag.getManagerStatus)
```

**Ligne 83** - inbound - Package: unknown

```go
v1.POST("/managers/:name/action", ag.executeManagerAction)
```

**Ligne 84** - inbound - Package: unknown

```go
v1.GET("/managers/:name/metrics", ag.getManagerMetrics)
```

**Ligne 89** - inbound - Package: unknown

```go
vectors.POST("/search", ag.searchVectors)
```

**Ligne 90** - inbound - Package: unknown

```go
vectors.POST("/upsert", ag.upsertVectors)
```

**Ligne 91** - inbound - Package: unknown

```go
vectors.GET("/list", ag.listVectors)
```

**Ligne 92** - inbound - Package: unknown

```go
vectors.DELETE("/:id", ag.deleteVector)
```

**Ligne 98** - inbound - Package: unknown

```go
config.GET("/:key", ag.getConfig)
```

**Ligne 99** - inbound - Package: unknown

```go
config.POST("/:key", ag.setConfig)
```

**Ligne 100** - inbound - Package: unknown

```go
config.GET("/", ag.getAllConfigs)
```

**Ligne 106** - inbound - Package: unknown

```go
events.GET("/", ag.getEvents)
```

**Ligne 107** - inbound - Package: unknown

```go
events.POST("/", ag.publishEvent)
```

**Ligne 108** - inbound - Package: unknown

```go
events.GET("/subscribe/:topic", ag.subscribeToEvents)
```

**Ligne 114** - inbound - Package: unknown

```go
monitoring.GET("/status", ag.getSystemStatus)
```

**Ligne 115** - inbound - Package: unknown

```go
monitoring.GET("/metrics", ag.getSystemMetrics)
```

**Ligne 116** - inbound - Package: unknown

```go
monitoring.GET("/performance", ag.getPerformanceMetrics)
```

#### 📄 `generator.go`

**Ligne 347** - inbound - Package: unknown

```go
if cached, found := s.cache.Get(cacheKey); found {
```

#### 📄 `handler.go`

**Ligne 103** - inbound - Package: unknown

```go
contentType := resp.Header.Get("Content-Type")
```

**Ligne 121** - inbound - Package: unknown

```go
return mcp.NewCallToolResultImage(base64Image, resp.Header.Get("Content-Type")), nil
```

**Ligne 130** - inbound - Package: unknown

```go
contentType := resp.Header.Get("Content-Type")
```

**Ligne 148** - inbound - Package: unknown

```go
return mcp.NewCallToolResultAudio(base64Audio, resp.Header.Get("Content-Type")), nil
```

#### 📄 `handlers.go`

**Ligne 285** - bidirectional - Package: unknown

```go
// RegisterHandlers creates http.Handler with routing matching OpenAPI spec.
```

**Ligne 290** - bidirectional - Package: unknown

```go
// RegisterHandlersWithOptions creates http.Handler with additional options
```

**Ligne 305** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/collections", wrapper.ListCollections)
```

**Ligne 305** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/collections", wrapper.ListCollections)
```

**Ligne 306** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/collections", wrapper.CreateCollection)
```

**Ligne 306** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/collections", wrapper.CreateCollection)
```

**Ligne 307** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/documents", wrapper.ListDocuments)
```

**Ligne 307** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/documents", wrapper.ListDocuments)
```

**Ligne 308** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/documents", wrapper.IndexDocuments)
```

**Ligne 308** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/documents", wrapper.IndexDocuments)
```

**Ligne 309** - inbound - Package: unknown

```go
router.DELETE(options.BaseURL+"/documents/:document_id", wrapper.DeleteDocument)
```

**Ligne 309** - inbound - Package: unknown

```go
router.DELETE(options.BaseURL+"/documents/:document_id", wrapper.DeleteDocument)
```

**Ligne 310** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/documents/:document_id", wrapper.GetDocument)
```

**Ligne 310** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/documents/:document_id", wrapper.GetDocument)
```

**Ligne 311** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/health", wrapper.HealthCheck)
```

**Ligne 311** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/health", wrapper.HealthCheck)
```

**Ligne 312** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/metrics", wrapper.GetMetrics)
```

**Ligne 312** - inbound - Package: unknown

```go
router.GET(options.BaseURL+"/metrics", wrapper.GetMetrics)
```

**Ligne 313** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/search", wrapper.PerformSearch)
```

**Ligne 313** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/search", wrapper.PerformSearch)
```

**Ligne 314** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/search/stream", wrapper.PerformStreamingSearch)
```

**Ligne 314** - inbound - Package: unknown

```go
router.POST(options.BaseURL+"/search/stream", wrapper.PerformStreamingSearch)
```

#### 📄 `http-server.go`

**Ligne 48** - bidirectional - Package: unknown

```go
router := gin.Default()
```

**Ligne 51** - inbound - Package: unknown

```go
router.POST("/users", func(c *gin.Context) {
```

**Ligne 51** - inbound - Package: unknown

```go
router.POST("/users", func(c *gin.Context) {
```

**Ligne 75** - inbound - Package: unknown

```go
router.GET("/users/email/:email", func(c *gin.Context) {
```

**Ligne 75** - inbound - Package: unknown

```go
router.GET("/users/email/:email", func(c *gin.Context) {
```

**Ligne 87** - inbound - Package: unknown

```go
router.PUT("/users/:email/preferences", func(c *gin.Context) {
```

**Ligne 87** - inbound - Package: unknown

```go
router.PUT("/users/:email/preferences", func(c *gin.Context) {
```

**Ligne 112** - inbound - Package: unknown

```go
router.POST("/users/:email/avatar", func(c *gin.Context) {
```

**Ligne 112** - inbound - Package: unknown

```go
router.POST("/users/:email/avatar", func(c *gin.Context) {
```

#### 📄 `infrastructure_endpoints.go`

**Ligne 32** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/infrastructure/status", h.handleGetStatus)
```

**Ligne 33** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/infrastructure/health", h.handleHealthCheck)
```

**Ligne 34** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/infrastructure/start", h.handleStartServices)
```

**Ligne 35** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/infrastructure/stop", h.handleStopServices)
```

**Ligne 36** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/infrastructure/recover", h.handleAutoRecover)
```

**Ligne 39** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/monitoring/start", h.handleStartAdvancedMonitoring)
```

**Ligne 40** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/monitoring/stop", h.handleStopAdvancedMonitoring)
```

**Ligne 41** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/monitoring/status", h.handleGetMonitoringStatus)
```

**Ligne 42** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/monitoring/health-advanced", h.handleGetAdvancedHealthStatus)
```

**Ligne 45** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/auto-healing/enable", h.handleEnableAutoHealing)
```

**Ligne 46** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/v1/auto-healing/disable", h.handleDisableAutoHealing)
```

#### 📄 `main.go`

**Ligne 20** - bidirectional - Package: unknown

```go
http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
```

**Ligne 20** - bidirectional - Package: unknown

```go
http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
```

**Ligne 35** - inbound - Package: unknown

```go
fmt.Printf("mcp-gateway version %s\n", version.Get())
```

**Ligne 36** - inbound - Package: unknown

```go
fmt.Printf("apiserver version %s\n", version.Get())
```

**Ligne 42** - inbound - Package: unknown

```go
fmt.Printf("mock-server version %s\n", version.Get())
```

**Ligne 62** - bidirectional - Package: unknown

```go
routingDecision, err := ci.router.RouteCommit(analysis)
```

**Ligne 63** - bidirectional - Package: unknown

```go
gin.SetMode(gin.ReleaseMode)
```

**Ligne 64** - bidirectional - Package: unknown

```go
router:   mux.NewRouter(),
```

**Ligne 65** - inbound - Package: unknown

```go
retrievedValue, err := localCache.Get(ctx, key)
```

**Ligne 66** - bidirectional - Package: unknown

```go
gin.SetMode(gin.ReleaseMode)
```

**Ligne 66** - bidirectional - Package: unknown

```go
router := gin.New()
```

**Ligne 69** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 69** - bidirectional - Package: unknown

```go
router := gin.New()
```

**Ligne 69** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 70** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 70** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 72** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 72** - bidirectional - Package: unknown

```go
router.Use(gin.Logger())
```

**Ligne 73** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 73** - bidirectional - Package: unknown

```go
router.Use(func(c *gin.Context) {
```

**Ligne 73** - bidirectional - Package: unknown

```go
router.Use(gin.Recovery())
```

**Ligne 76** - bidirectional - Package: unknown

```go
router.Use(func(c *gin.Context) {
```

**Ligne 81** - bidirectional - Package: unknown

```go
r := mux.NewRouter()
```

**Ligne 87** - inbound - Package: unknown

```go
router.GET("/health", func(c *gin.Context) {
```

**Ligne 87** - inbound - Package: unknown

```go
router.GET("/health", func(c *gin.Context) {
```

**Ligne 90** - inbound - Package: unknown

```go
router.GET("/health", func(c *gin.Context) {
```

**Ligne 90** - inbound - Package: unknown

```go
router.GET("/health", func(c *gin.Context) {
```

**Ligne 94** - bidirectional - Package: unknown

```go
r.Handle("/metrics", promhttp.Handler())
```

**Ligne 97** - inbound - Package: unknown

```go
router.GET("/status", func(c *gin.Context) {
```

**Ligne 97** - inbound - Package: unknown

```go
router.GET("/status", func(c *gin.Context) {
```

**Ligne 98** - bidirectional - Package: unknown

```go
s.router = mux.NewRouter()
```

**Ligne 100** - inbound - Package: unknown

```go
retrievedValue, err = hybridClient.Get(ctx, testKey)
```

**Ligne 100** - inbound - Package: unknown

```go
router.GET("/status", func(c *gin.Context) {
```

**Ligne 100** - inbound - Package: unknown

```go
router.GET("/status", func(c *gin.Context) {
```

**Ligne 101** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/health", s.healthHandler).Methods("GET")
```

**Ligne 102** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/health/detailed", s.detailedHealthHandler).Methods("GET")
```

**Ligne 105** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/templates/{id}", s.getTemplateHandler).Methods("GET")
```

**Ligne 106** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/templates/{id}/invalidate", s.invalidateTemplateHandler).Methods("POST")
```

**Ligne 107** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/templates/invalidate-all", s.invalidateAllTemplatesHandler).Methods("POST")
```

**Ligne 110** - inbound - Package: unknown

```go
retrievedHybridValue, err := hybridClient.Get(ctx, hybridKey)
```

**Ligne 110** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/users/{id}/preferences", s.getUserPreferencesHandler).Methods("GET")
```

**Ligne 111** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/users/{id}/preferences", s.updateUserPreferencesHandler).Methods("PUT")
```

**Ligne 112** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/health", s.healthHandler).Methods("GET")
```

**Ligne 114** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/stats", s.getStatsHandler).Methods("GET")
```

**Ligne 115** - bidirectional - Package: unknown

```go
v1 := s.router.PathPrefix("/api/v1").Subrouter()
```

**Ligne 117** - inbound - Package: unknown

```go
router.GET("/", func(c *gin.Context) {
```

**Ligne 117** - inbound - Package: unknown

```go
router.GET("/", func(c *gin.Context) {
```

**Ligne 117** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/ml/{modelId}/results", s.getMLResultsHandler).Methods("GET")
```

**Ligne 118** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/ml/{modelId}/invalidate", s.invalidateMLResultsHandler).Methods("POST")
```

**Ligne 120** - inbound - Package: unknown

```go
router.GET("/", func(c *gin.Context) {
```

**Ligne 120** - inbound - Package: unknown

```go
router.GET("/", func(c *gin.Context) {
```

**Ligne 121** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/cache/metrics", s.getCacheMetricsHandler).Methods("GET")
```

**Ligne 122** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/cache/analysis", s.getCacheAnalysisHandler).Methods("GET")
```

**Ligne 123** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/cache/optimize", s.optimizeCacheHandler).Methods("POST")
```

**Ligne 124** - bidirectional - Package: unknown

```go
s.router.HandleFunc("/api/v1/cache/recommendations", s.getCacheRecommendationsHandler).Methods("GET")
```

**Ligne 127** - bidirectional - Package: unknown

```go
r := mux.NewRouter()
```

**Ligne 127** - bidirectional - Package: unknown

```go
s.router.Handle("/metrics", promhttp.Handler())
```

**Ligne 127** - bidirectional - Package: unknown

```go
s.router.Handle("/metrics", promhttp.Handler())
```

**Ligne 130** - bidirectional - Package: unknown

```go
s.router.Use(s.loggingMiddleware)
```

**Ligne 131** - bidirectional - Package: unknown

```go
s.router.Use(s.corsMiddleware)
```

**Ligne 132** - bidirectional - Package: unknown

```go
v1 := router.Group("/api/v1")
```

**Ligne 132** - bidirectional - Package: unknown

```go
s.router.Use(s.metrics.MetricsMiddleware())
```

**Ligne 133** - bidirectional - Package: unknown

```go
v1 := router.Group("/api/v1")
```

**Ligne 134** - inbound - Package: unknown

```go
retrievedEnvValue, err := hybridClient.Get(ctx, envKey)
```

**Ligne 134** - inbound - Package: unknown

```go
v1.GET("/infrastructure", func(c *gin.Context) {
```

**Ligne 135** - inbound - Package: unknown

```go
v1.GET("/infrastructure", func(c *gin.Context) {
```

**Ligne 136** - bidirectional - Package: unknown

```go
metricsRouter := mux.NewRouter()
```

**Ligne 137** - inbound - Package: unknown

```go
resp, err := http.Post(baseURL+"/events", "application/json", bytes.NewBuffer(eventJSON))
```

**Ligne 137** - bidirectional - Package: unknown

```go
metricsRouter.Handle("/metrics", promhttp.Handler())
```

**Ligne 137** - bidirectional - Package: unknown

```go
metricsRouter.Handle("/metrics", promhttp.Handler())
```

**Ligne 143** - bidirectional - Package: unknown

```go
r := gin.Default()
```

**Ligne 146** - inbound - Package: unknown

```go
v1.GET("/infrastructure/status", func(c *gin.Context) {
```

**Ligne 147** - inbound - Package: unknown

```go
v1.GET("/infrastructure/status", func(c *gin.Context) {
```

**Ligne 153** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 158** - inbound - Package: unknown

```go
logger.Info("Starting mcp-gateway", zap.String("version", version.Get()))
```

**Ligne 161** - inbound - Package: unknown

```go
authG.POST("/login", authH.Login)
```

**Ligne 165** - inbound - Package: unknown

```go
v1.GET("/monitoring/status", func(c *gin.Context) {
```

**Ligne 166** - inbound - Package: unknown

```go
v1.GET("/monitoring/status", func(c *gin.Context) {
```

**Ligne 167** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 168** - inbound - Package: unknown

```go
Query: r.URL.Query().Get("q"),
```

**Ligne 172** - inbound - Package: unknown

```go
protected.POST("/auth/change-password", authH.ChangePassword)
```

**Ligne 173** - inbound - Package: unknown

```go
protected.GET("/auth/user/info", authH.GetUserInfo)
```

**Ligne 173** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 174** - inbound - Package: unknown

```go
protected.GET("/auth/user", authH.GetUserWithTenants)
```

**Ligne 175** - inbound - Package: unknown

```go
protected.GET("/auth/tenants", authH.ListTenants)
```

**Ligne 176** - inbound - Package: unknown

```go
v1.POST("/auto-healing/enable", func(c *gin.Context) {
```

**Ligne 177** - inbound - Package: unknown

```go
v1.POST("/auto-healing/enable", func(c *gin.Context) {
```

**Ligne 181** - inbound - Package: unknown

```go
userMgmt.GET("", authH.ListUsers)
```

**Ligne 182** - inbound - Package: unknown

```go
userMgmt.POST("", authH.CreateUser)
```

**Ligne 183** - inbound - Package: unknown

```go
userMgmt.PUT("", authH.UpdateUser)
```

**Ligne 184** - inbound - Package: unknown

```go
userMgmt.DELETE("/:username", authH.DeleteUser)
```

**Ligne 185** - inbound - Package: unknown

```go
v1.POST("/auto-healing/disable", func(c *gin.Context) {
```

**Ligne 185** - inbound - Package: unknown

```go
userMgmt.GET("/:username", authH.GetUserWithTenants)
```

**Ligne 186** - inbound - Package: unknown

```go
userMgmt.PUT("/tenants", authH.UpdateUserTenants)
```

**Ligne 186** - inbound - Package: unknown

```go
v1.POST("/auto-healing/disable", func(c *gin.Context) {
```

**Ligne 186** - inbound - Package: unknown

```go
retrievedValue, err := client.Get(ctx, testKey).Result()
```

**Ligne 187** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 192** - inbound - Package: unknown

```go
tenantMgmt.POST("", authH.CreateTenant)
```

**Ligne 193** - inbound - Package: unknown

```go
tenantMgmt.GET("/:name", authH.GetTenantInfo)
```

**Ligne 194** - inbound - Package: unknown

```go
v1.GET("/infrastructure/health", func(c *gin.Context) {
```

**Ligne 195** - inbound - Package: unknown

```go
v1.GET("/infrastructure/health", func(c *gin.Context) {
```

**Ligne 197** - inbound - Package: unknown

```go
tenantMgmt.PUT("", authH.UpdateTenant)
```

**Ligne 198** - inbound - Package: unknown

```go
tenantMgmt.DELETE("/:name", authH.DeleteTenant)
```

**Ligne 204** - inbound - Package: unknown

```go
mcpGroup.GET("/configs/names", mcpHandler.HandleGetConfigNames)
```

**Ligne 205** - inbound - Package: unknown

```go
mcpGroup.GET("/configs/versions", mcpHandler.HandleGetConfigVersions)
```

**Ligne 206** - inbound - Package: unknown

```go
mcpGroup.POST("/configs/:tenant/:name/versions/:version/active", mcpHandler.HandleSetActiveVersion)
```

**Ligne 208** - inbound - Package: unknown

```go
mcpGroup.GET("/configs", mcpHandler.HandleListMCPServers)
```

**Ligne 209** - inbound - Package: unknown

```go
mcpGroup.POST("/configs", mcpHandler.HandleMCPServerCreate)
```

**Ligne 210** - inbound - Package: unknown

```go
mcpGroup.PUT("/configs", mcpHandler.HandleMCPServerUpdate)
```

**Ligne 211** - inbound - Package: unknown

```go
mcpGroup.DELETE("/configs/:tenant/:name", mcpHandler.HandleMCPServerDelete)
```

**Ligne 212** - inbound - Package: unknown

```go
mcpGroup.POST("/configs/sync", mcpHandler.HandleMCPServerSync)
```

**Ligne 216** - bidirectional - Package: unknown

```go
if err := router.Run(":" + port); err != nil {
```

**Ligne 216** - bidirectional - Package: unknown

```go
if err := router.Run(":" + port); err != nil {
```

**Ligne 216** - inbound - Package: unknown

```go
protected.POST("/openapi/import", openapiHandler.HandleImport)
```

**Ligne 218** - inbound - Package: unknown

```go
protected.GET("/chat/sessions", chatHandler.HandleGetChatSessions)
```

**Ligne 219** - inbound - Package: unknown

```go
protected.GET("/chat/sessions/:sessionId/messages", chatHandler.HandleGetChatMessages)
```

**Ligne 220** - inbound - Package: unknown

```go
protected.DELETE("/chat/sessions/:sessionId", chatHandler.HandleDeleteChatSession)
```

**Ligne 220** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 221** - inbound - Package: unknown

```go
resp, err := http.Get(baseURL + "/health")
```

**Ligne 221** - inbound - Package: unknown

```go
protected.PUT("/chat/sessions/:sessionId/title", chatHandler.HandleUpdateChatSessionTitle)
```

**Ligne 225** - inbound - Package: unknown

```go
r.GET("/api/ws/chat", wsHandler.HandleWebSocket)
```

**Ligne 233** - inbound - Package: unknown

```go
if err := c.manager.Delete(ctx, docID); err != nil {
```

**Ligne 234** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 239** - inbound - Package: unknown

```go
resp, err = http.Get(baseURL + "/status")
```

**Ligne 239** - bidirectional - Package: unknown

```go
if err := router.Run(":" + port); err != nil {
```

**Ligne 242** - bidirectional - Package: unknown

```go
md.router = mux.NewRouter()
```

**Ligne 245** - bidirectional - Package: unknown

```go
api := md.router.PathPrefix("/api/v1").Subrouter()
```

**Ligne 250** - inbound - Package: unknown

```go
if _, err := client.Get(ctx, key).Result(); err != nil {
```

**Ligne 254** - bidirectional - Package: unknown

```go
md.router.Handle("/metrics", promhttp.HandlerFor(md.metrics.registry, promhttp.HandlerOpts{}))
```

**Ligne 254** - bidirectional - Package: unknown

```go
md.router.Handle("/metrics", promhttp.HandlerFor(md.metrics.registry, promhttp.HandlerOpts{}))
```

**Ligne 257** - bidirectional - Package: unknown

```go
md.router.PathPrefix("/dashboard/").Handler(http.StripPrefix("/dashboard/", http.FileServer(http.Dir("./dashboard/"))))
```

**Ligne 258** - bidirectional - Package: unknown

```go
md.router.HandleFunc("/", md.handleRoot).Methods("GET")
```

**Ligne 267** - inbound - Package: unknown

```go
logger.Info("Starting apiserver", zap.String("version", version.Get()))
```

**Ligne 273** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 275** - inbound - Package: unknown

```go
inputHash := r.URL.Query().Get("input_hash")
```

**Ligne 293** - bidirectional - Package: unknown

```go
vars := mux.Vars(r)
```

**Ligne 293** - inbound - Package: unknown

```go
_, err := client.Get(ctx, "retry-test-key").Result()
```

**Ligne 295** - inbound - Package: unknown

```go
version := r.URL.Query().Get("version")
```

**Ligne 340** - bidirectional - Package: unknown

```go
http.Handle("/metrics", promhttp.Handler())
```

**Ligne 354** - bidirectional - Package: unknown

```go
func (s *Server) loggingMiddleware(next http.Handler) http.Handler {
```

**Ligne 355** - bidirectional - Package: unknown

```go
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
```

**Ligne 362** - bidirectional - Package: unknown

```go
func (s *Server) corsMiddleware(next http.Handler) http.Handler {
```

**Ligne 363** - bidirectional - Package: unknown

```go
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
```

#### 📄 `manager_discovery.go`

**Ligne 364** - inbound - Package: unknown

```go
resp, err := client.Get(fmt.Sprintf("http://%s/health", endpoint))
```

**Ligne 371** - inbound - Package: unknown

```go
managerType := resp.Header.Get("X-Manager-Type")
```

#### 📄 `manager_proxies.go`

**Ligne 133** - inbound - Package: unknown

```go
resp, err := nmp.client.Get(fmt.Sprintf("%s/health", nmp.endpoint))
```

#### 📄 `manager.go`

**Ligne 129** - inbound - Package: unknown

```go
pr, _, err := m.client.PullRequests.Get(ctx, m.owner, m.repo, prID)
```

**Ligne 180** - inbound - Package: unknown

```go
result, err := tm.redis.Get(ctx, key).Result()
```

**Ligne 404** - inbound - Package: unknown

```go
_, _, err := m.client.Users.Get(ctx, "")
```

#### 📄 `mcp.go`

**Ligne 52** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 157** - inbound - Package: unknown

```go
oldCfg, err := h.store.Get(c.Request.Context(), cfg.Tenant, cfg.Name)
```

**Ligne 244** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 408** - inbound - Package: unknown

```go
_, err = h.store.Get(c.Request.Context(), cfg.Tenant, cfg.Name)
```

**Ligne 480** - inbound - Package: unknown

```go
existingCfg, err := h.store.Get(c.Request.Context(), tenant, name)
```

**Ligne 500** - inbound - Package: unknown

```go
if err := h.store.Delete(c.Request.Context(), existingCfg.Tenant, name); err != nil {
```

**Ligne 523** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 570** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 706** - inbound - Package: unknown

```go
existingCfg, err := h.store.Get(c.Request.Context(), tenant, name)
```

**Ligne 761** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

#### 📄 `metrics.go`

**Ligne 491** - bidirectional - Package: unknown

```go
func (m *RAGMetrics) MetricsMiddleware() func(http.Handler) http.Handler {
```

**Ligne 492** - bidirectional - Package: unknown

```go
return func(next http.Handler) http.Handler {
```

**Ligne 493** - bidirectional - Package: unknown

```go
return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
```

**Ligne 532** - bidirectional - Package: unknown

```go
func (m *RAGMetrics) GetHandler() http.Handler {
```

**Ligne 533** - bidirectional - Package: unknown

```go
return promhttp.HandlerFor(m.registry, promhttp.HandlerOpts{
```

**Ligne 541** - bidirectional - Package: unknown

```go
mux.Handle("/metrics", m.GetHandler())
```

**Ligne 542** - bidirectional - Package: unknown

```go
mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
```

#### 📄 `middleware.go`

**Ligne 146** - inbound - Package: unknown

```go
origin := c.Request.Header.Get("Origin")
```

#### 📄 `monitoring_manager.go`

**Ligne 245** - inbound - Package: unknown

```go
hits := mm.cacheHits.Get()
```

**Ligne 246** - inbound - Package: unknown

```go
misses := mm.cacheMisses.Get()
```

#### 📄 `mysql.go`

**Ligne 141** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&User{}, "id = ?", id).Error
```

**Ligne 189** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&Tenant{}, "id = ?", id).Error
```

**Ligne 231** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ? AND tenant_id = ?", userID, tenantID).Delete(&UserTenant{}).Error
```

**Ligne 266** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ?", userID).Delete(&UserTenant{}).Error
```

#### 📄 `native.go`

**Ligne 122** - bidirectional - Package: unknown

```go
mux.Handle("/metrics", promhttp.Handler())
```

**Ligne 122** - bidirectional - Package: unknown

```go
mux.Handle("/metrics", promhttp.Handler())
```

**Ligne 123** - bidirectional - Package: unknown

```go
mux.HandleFunc("/health", monitor.healthHandler)
```

**Ligne 124** - bidirectional - Package: unknown

```go
mux.HandleFunc("/metrics/json", monitor.jsonMetricsHandler)
```

**Ligne 125** - bidirectional - Package: unknown

```go
mux.HandleFunc("/", monitor.dashboardHandler)
```

#### 📄 `oauth2.go`

**Ligne 33** - inbound - Package: unknown

```go
authHeader := r.Header.Get("Authorization")
```

#### 📄 `phase_4_performance_validation.go`

**Ligne 290** - inbound - Package: unknown

```go
cached, found := cache.Get("test_query")
```

**Ligne 359** - inbound - Package: unknown

```go
if _, found := cache.Get(cacheKey); found {
```

#### 📄 `phase_7_deployment_validation.go`

**Ligne 223** - inbound - Package: unknown

```go
resp, err := client.Get(healthURL)
```

**Ligne 293** - inbound - Package: unknown

```go
resp, err := client.Get(qdrantURL)
```

**Ligne 443** - inbound - Package: unknown

```go
resp, err := client.Get(metricsURL)
```

**Ligne 555** - inbound - Package: unknown

```go
resp, err := client.Get(apiURL)
```

#### 📄 `postgres.go`

**Ligne 148** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&User{}, "id = ?", id).Error
```

**Ligne 196** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&Tenant{}, "id = ?", id).Error
```

**Ligne 238** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ? AND tenant_id = ?", userID, tenantID).Delete(&UserTenant{}).Error
```

**Ligne 273** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ?", userID).Delete(&UserTenant{}).Error
```

#### 📄 `qdrant_manager.go`

**Ligne 364** - inbound - Package: unknown

```go
_, err := qm.client.Delete(ctx, &qdrant.DeletePoints{
```

#### 📄 `qdrant.go`

**Ligne 50** - inbound - Package: unknown

```go
resp, err := q.HTTPClient.Get(q.BaseURL + "/")
```

**Ligne 69** - inbound - Package: unknown

```go
resp, err := q.HTTPClient.Get(q.BaseURL + "/")
```

#### 📄 `real_time_monitoring_dashboard.go`

**Ligne 56** - bidirectional - Package: unknown

```go
type MiddlewareFunc func(http.Handler) http.Handler
```

**Ligne 153** - bidirectional - Package: unknown

```go
apiEndpoints  map[string]http.HandlerFunc
```

**Ligne 587** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/health", rtmd.handleHealthAPI)
```

**Ligne 588** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/metrics", rtmd.handleMetricsAPI)
```

**Ligne 589** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/alerts", rtmd.handleAlertsAPI)
```

**Ligne 590** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/events", rtmd.handleEventsAPI)
```

**Ligne 591** - bidirectional - Package: unknown

```go
mux.HandleFunc("/api/historical", rtmd.handleHistoricalAPI)
```

**Ligne 595** - bidirectional - Package: unknown

```go
mux.HandleFunc("/ws", rtmd.handleWebSocket)
```

**Ligne 599** - bidirectional - Package: unknown

```go
mux.HandleFunc("/", rtmd.webDashboard.ServeHTTP)
```

**Ligne 860** - inbound - Package: unknown

```go
manager := r.URL.Query().Get("manager")
```

**Ligne 861** - inbound - Package: unknown

```go
duration := r.URL.Query().Get("duration")
```

#### 📄 `realtime_bridge.go`

**Ligne 166** - bidirectional - Package: unknown

```go
mux.HandleFunc("/events", rb.handleEvents)
```

**Ligne 169** - bidirectional - Package: unknown

```go
mux.HandleFunc("/health", rb.handleHealth)
```

**Ligne 172** - bidirectional - Package: unknown

```go
mux.HandleFunc("/status", rb.handleStatus)
```

#### 📄 `realtime-dashboard.go`

**Ligne 83** - bidirectional - Package: unknown

```go
http.HandleFunc("/", rd.handleDashboardPage)
```

**Ligne 83** - bidirectional - Package: unknown

```go
http.HandleFunc("/", rd.handleDashboardPage)
```

**Ligne 84** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/metrics", rd.handleMetricsAPI)
```

**Ligne 84** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/metrics", rd.handleMetricsAPI)
```

**Ligne 85** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/health", rd.handleHealthAPI)
```

**Ligne 85** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/health", rd.handleHealthAPI)
```

**Ligne 86** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/alerts", rd.handleAlertsAPI)
```

**Ligne 86** - bidirectional - Package: unknown

```go
http.HandleFunc("/api/alerts", rd.handleAlertsAPI)
```

**Ligne 87** - bidirectional - Package: unknown

```go
http.HandleFunc("/ws", rd.handleWebSocket)
```

**Ligne 87** - bidirectional - Package: unknown

```go
http.HandleFunc("/ws", rd.handleWebSocket)
```

**Ligne 88** - bidirectional - Package: unknown

```go
http.HandleFunc("/static/", rd.handleStatic)
```

**Ligne 88** - bidirectional - Package: unknown

```go
http.HandleFunc("/static/", rd.handleStatic)
```

#### 📄 `redis_client.go`

**Ligne 80** - inbound - Package: unknown

```go
return r.client.Get(ctx, key).Result()
```

#### 📄 `redis.go`

**Ligne 197** - inbound - Package: unknown

```go
data, err := s.client.Get(ctx, key).Bytes()
```

**Ligne 271** - inbound - Package: unknown

```go
data, err := s.client.Get(ctx, key).Bytes()
```

#### 📄 `response.go`

**Ligne 16** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 51** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 83** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 116** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 137** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 158** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 179** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

**Ligne 205** - inbound - Package: unknown

```go
if logger, exists := c.Get("logger"); exists {
```

#### 📄 `searchservice.go`

**Ligne 120** - inbound - Package: unknown

```go
if cached, found := s.cache.Get(cacheKey); found {
```

**Ligne 129** - inbound - Package: unknown

```go
if cached, found := s.cache.Get(cacheKey); found {
```

#### 📄 `server.go`

**Ligne 48** - bidirectional - Package: unknown

```go
http.HandleFunc("/", s.handleHome)
```

**Ligne 48** - bidirectional - Package: unknown

```go
http.HandleFunc("/", s.handleHome)
```

**Ligne 48** - bidirectional - Package: unknown

```go
router:          gin.Default(),
```

**Ligne 49** - bidirectional - Package: unknown

```go
http.HandleFunc("/view/", s.handleView)
```

**Ligne 49** - bidirectional - Package: unknown

```go
http.HandleFunc("/view/", s.handleView)
```

**Ligne 55** - bidirectional - Package: unknown

```go
s.router.Use(s.loggerMiddleware())
```

**Ligne 56** - bidirectional - Package: unknown

```go
s.router.Use(s.recoveryMiddleware())
```

**Ligne 62** - inbound - Package: unknown

```go
s.router.GET("/health_check", func(c *gin.Context) {
```

**Ligne 62** - inbound - Package: unknown

```go
s.router.GET("/health_check", func(c *gin.Context) {
```

**Ligne 85** - bidirectional - Package: unknown

```go
s.router.NoRoute(s.handleRoot)
```

**Ligne 87** - inbound - Package: unknown

```go
if formatParam := r.URL.Query().Get("format"); formatParam != "" {
```

**Ligne 157** - bidirectional - Package: unknown

```go
if err := s.router.Run(fmt.Sprintf(":%d", s.port)); err != nil {
```

#### 📄 `service.go`

**Ligne 144** - inbound - Package: unknown

```go
found, err := s.cacheManager.Get(cacheKey, &template)
```

**Ligne 178** - inbound - Package: unknown

```go
return s.cacheManager.Delete(cacheKey)
```

**Ligne 193** - inbound - Package: unknown

```go
found, err := s.cacheManager.Get(cacheKey, &prefs)
```

**Ligne 231** - inbound - Package: unknown

```go
err := s.cacheManager.Delete(cacheKey)
```

**Ligne 255** - inbound - Package: unknown

```go
found, err := s.cacheManager.Get(cacheKey, &stats)
```

**Ligne 293** - inbound - Package: unknown

```go
found, err := s.cacheManager.Get(cacheKey, &model)
```

#### 📄 `sqlite.go`

**Ligne 148** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&User{}, "id = ?", id).Error
```

**Ligne 196** - inbound - Package: unknown

```go
return db.db.WithContext(ctx).Delete(&Tenant{}, "id = ?", id).Error
```

**Ligne 238** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ? AND tenant_id = ?", userID, tenantID).Delete(&UserTenant{}).Error
```

**Ligne 273** - inbound - Package: unknown

```go
return dbSession.Where("user_id = ?", userID).Delete(&UserTenant{}).Error
```

#### 📄 `sse.go`

**Ligne 51** - inbound - Package: unknown

```go
Version: version.Get(),
```

**Ligne 241** - inbound - Package: unknown

```go
conn, err := s.sessions.Get(c.Request.Context(), sessionId)
```

**Ligne 315** - inbound - Package: unknown

```go
Version: version.Get(),
```

#### 📄 `stdio.go`

**Ligne 62** - inbound - Package: unknown

```go
Version: version.Get(),
```

#### 📄 `streamable.go`

**Ligne 51** - inbound - Package: unknown

```go
Version: version.Get(),
```

**Ligne 125** - inbound - Package: unknown

```go
conn, err = s.sessions.Get(c.Request.Context(), sessionID)
```

**Ligne 155** - inbound - Package: unknown

```go
conn, err = s.sessions.Get(c.Request.Context(), sessionID)
```

**Ligne 201** - inbound - Package: unknown

```go
Version: version.Get(),
```

**Ligne 307** - inbound - Package: unknown

```go
conn, err := s.sessions.Get(c.Request.Context(), sessionID)
```

#### 📄 `suggestion_engine.go`

**Ligne 504** - inbound - Package: unknown

```go
c.Delete()
```

#### 📄 `sync_dashboard.go`

**Ligne 101** - bidirectional - Package: unknown

```go
gin.SetMode(gin.ReleaseMode)
```

**Ligne 105** - bidirectional - Package: unknown

```go
webServer:     gin.New(),
```

**Ligne 118** - bidirectional - Package: unknown

```go
sd.webServer.Use(gin.Recovery())
```

**Ligne 119** - bidirectional - Package: unknown

```go
sd.webServer.Use(gin.Logger())
```

**Ligne 143** - inbound - Package: unknown

```go
sd.webServer.GET("/", sd.handleDashboard)
```

**Ligne 144** - inbound - Package: unknown

```go
sd.webServer.GET("/api/sync/status", sd.handleSyncStatus)
```

**Ligne 145** - inbound - Package: unknown

```go
sd.webServer.GET("/api/sync/conflicts", sd.handleConflicts)
```

**Ligne 146** - inbound - Package: unknown

```go
sd.webServer.POST("/api/sync/resolve", sd.handleResolveConflict)
```

**Ligne 147** - inbound - Package: unknown

```go
sd.webServer.GET("/api/sync/history", sd.handleSyncHistory)
```

**Ligne 148** - inbound - Package: unknown

```go
sd.webServer.GET("/ws", sd.handleWebSocket)
```

**Ligne 151** - inbound - Package: unknown

```go
sd.webServer.GET("/health", sd.handleHealthCheck)
```

#### 📄 `templates.go`

**Ligne 195** - bidirectional - Package: unknown

```go
mux.HandleFunc("/{{.Package}}/{{.Name | lower}}", h.Handle{{.Name}})
```

**Ligne 196** - bidirectional - Package: unknown

```go
mux.HandleFunc("/{{.Package}}/{{.Name | lower}}/status", h.HandleStatus)
```

#### 📄 `tenant.go`

**Ligne 21** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

**Ligne 295** - inbound - Package: unknown

```go
claims, exists := c.Get("claims")
```

#### 📄 `vector_registry.go`

**Ligne 123** - inbound - Package: unknown

```go
info, err := collectionsClient.Get(ctx, &qdrant.GetCollectionInfoRequest{
```

**Ligne 436** - inbound - Package: unknown

```go
response, err := vr.client.Get(ctx, &qdrant.GetPoints{
```

**Ligne 507** - inbound - Package: unknown

```go
_, err := vr.client.Delete(ctx, &qdrant.DeletePoints{
```

**Ligne 539** - inbound - Package: unknown

```go
info, err := collectionsClient.Get(ctx, &qdrant.GetCollectionInfoRequest{
```

#### 📄 `webhook_management.go`

**Ligne 83** - inbound - Package: unknown

```go
"user_agent": request.Header.Get("User-Agent"),
```

**Ligne 242** - inbound - Package: unknown

```go
signature := request.Header.Get("X-Hub-Signature-256")
```

**Ligne 244** - inbound - Package: unknown

```go
signature = request.Header.Get("X-Signature-256")
```

**Ligne 269** - inbound - Package: unknown

```go
if eventType := request.Header.Get("X-Event-Type"); eventType != "" {
```

**Ligne 272** - inbound - Package: unknown

```go
if eventType := request.Header.Get("X-GitHub-Event"); eventType != "" {
```

**Ligne 275** - inbound - Package: unknown

```go
if eventType := request.Header.Get("X-GitLab-Event"); eventType != "" {
```

**Ligne 518** - inbound - Package: unknown

```go
if value := request.Header.Get(header); value != "" {
```

**Ligne 529** - inbound - Package: unknown

```go
if xff := request.Header.Get("X-Forwarded-For"); xff != "" {
```

**Ligne 536** - inbound - Package: unknown

```go
if xri := request.Header.Get("X-Real-IP"); xri != "" {
```

**Ligne 578** - inbound - Package: unknown

```go
"user_agent":       request.Header.Get("User-Agent"),
```

**Ligne 579** - inbound - Package: unknown

```go
"content_type":     request.Header.Get("Content-Type"),
```

### 📡 MESSAGE_QUEUES

#### 📄 `cross_manager_event_bus.go`

**Ligne 607** - bidirectional - Package: unknown

```go
ef.priorityQueue.Add(event, int(event.Priority))
```

#### 📄 `metrics.go`

**Ligne 456** - bidirectional - Package: unknown

```go
m.indexingQueue.Set(size)
```

### 📡 REDIS_PUBSUB

#### 📄 `complete_ecosystem_integration.go`

**Ligne 128** - bidirectional - Package: unknown

```go
subscribers map[string][]chan interface{}
```

**Ligne 148** - bidirectional - Package: unknown

```go
eventBus:       &EventBus{subscribers: make(map[string][]chan interface{}), logger: logger},
```

**Ligne 450** - bidirectional - Package: unknown

```go
"events":     {"/api/v1/events", "/api/v1/events/subscribe/test"},
```

#### 📄 `cross_manager_event_bus.go`

**Ligne 22** - bidirectional - Package: unknown

```go
subscribers     map[string][]EventSubscriber
```

**Ligne 215** - bidirectional - Package: unknown

```go
subscribers:   make(map[string][]EventSubscriber),
```

**Ligne 296** - bidirectional - Package: unknown

```go
// PublishEvent publie un événement dans le bus
```

**Ligne 297** - bidirectional - Package: unknown

```go
func (cmeb *CrossManagerEventBus) PublishEvent(event *CoordinationEvent) error {
```

**Ligne 318** - bidirectional - Package: unknown

```go
cmeb.logger.Debug(fmt.Sprintf("Event %s published to %s", event.ID, target))
```

**Ligne 330** - bidirectional - Package: unknown

```go
// SubscribeToManager souscrit aux événements d'un manager
```

**Ligne 331** - bidirectional - Package: unknown

```go
func (cmeb *CrossManagerEventBus) SubscribeToManager(managerName string, subscriber EventSubscriber) error {
```

**Ligne 335** - bidirectional - Package: unknown

```go
if cmeb.subscribers[managerName] == nil {
```

**Ligne 336** - bidirectional - Package: unknown

```go
cmeb.subscribers[managerName] = make([]EventSubscriber, 0)
```

**Ligne 339** - bidirectional - Package: unknown

```go
cmeb.subscribers[managerName] = append(cmeb.subscribers[managerName], subscriber)
```

**Ligne 340** - bidirectional - Package: unknown

```go
cmeb.logger.Info(fmt.Sprintf("Subscriber added for manager %s", managerName))
```

**Ligne 459** - bidirectional - Package: unknown

```go
if subscribers, exists := cmeb.subscribers[event.Target]; exists {
```

**Ligne 460** - bidirectional - Package: unknown

```go
for _, subscriber := range subscribers {
```

**Ligne 461** - bidirectional - Package: unknown

```go
go func(s EventSubscriber, e *CoordinationEvent) {
```

**Ligne 463** - bidirectional - Package: unknown

```go
cmeb.logger.Error(fmt.Sprintf("Subscriber failed to handle event %s: %v", e.ID, err))
```

**Ligne 465** - bidirectional - Package: unknown

```go
}(subscriber, event)
```

#### 📄 `event_bus.go`

**Ligne 14** - bidirectional - Package: unknown

```go
subscribers    map[string][]EventHandler
```

**Ligne 15** - bidirectional - Package: unknown

```go
subscribers map[string][]EventHandler
```

**Ligne 33** - bidirectional - Package: unknown

```go
SubscriberCount map[string]int             `json:"subscriber_count"`
```

**Ligne 40** - bidirectional - Package: unknown

```go
subscribers:  make(map[string][]EventHandler),
```

**Ligne 50** - bidirectional - Package: unknown

```go
SubscriberCount: make(map[string]int),
```

**Ligne 54** - bidirectional - Package: unknown

```go
Subscribers     int           `json:"subscribers"`
```

**Ligne 63** - bidirectional - Package: unknown

```go
subscribers: make(map[string][]EventHandler),
```

**Ligne 74** - bidirectional - Package: unknown

```go
Subscribers:     0,
```

**Ligne 75** - bidirectional - Package: unknown

```go
// Subscribe subscribes to specific event types
```

**Ligne 76** - bidirectional - Package: unknown

```go
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) {
```

**Ligne 80** - bidirectional - Package: unknown

```go
if eb.subscribers[eventType] == nil {
```

**Ligne 81** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = make([]EventHandler, 0)
```

**Ligne 84** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = append(eb.subscribers[eventType], handler)
```

**Ligne 85** - bidirectional - Package: unknown

```go
// Subscribe s'abonne à un type d'événement
```

**Ligne 85** - bidirectional - Package: unknown

```go
eb.metrics.SubscriberCount[eventType] = len(eb.subscribers[eventType])
```

**Ligne 86** - bidirectional - Package: unknown

```go
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) error {
```

**Ligne 89** - bidirectional - Package: unknown

```go
"subscribers": len(eb.subscribers[eventType]),
```

**Ligne 90** - bidirectional - Package: unknown

```go
if eb.subscribers[eventType] == nil {
```

**Ligne 91** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = make([]EventHandler, 0)
```

**Ligne 93** - bidirectional - Package: unknown

```go
// Unsubscribe removes a handler from event type (simplified implementation)
```

**Ligne 94** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = append(eb.subscribers[eventType], handler)
```

**Ligne 94** - bidirectional - Package: unknown

```go
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler) {
```

**Ligne 95** - bidirectional - Package: unknown

```go
eb.metrics.Subscribers = eb.getTotalSubscribers()
```

**Ligne 97** - bidirectional - Package: unknown

```go
eb.logger.Info("New subscriber registered",
```

**Ligne 98** - bidirectional - Package: unknown

```go
if handlers, exists := eb.subscribers[eventType]; exists {
```

**Ligne 99** - bidirectional - Package: unknown

```go
zap.Int("total_subscribers", eb.metrics.Subscribers))
```

**Ligne 102** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = handlers[:len(handlers)-1]
```

**Ligne 103** - bidirectional - Package: unknown

```go
eb.metrics.SubscriberCount[eventType] = len(eb.subscribers[eventType])
```

**Ligne 104** - bidirectional - Package: unknown

```go
// Unsubscribe se désabonne d'un type d'événement
```

**Ligne 105** - bidirectional - Package: unknown

```go
func (eb *EventBus) Unsubscribe(eventType string, handler EventHandler) error {
```

**Ligne 108** - bidirectional - Package: unknown

```go
// Publish publishes an event to the bus
```

**Ligne 109** - bidirectional - Package: unknown

```go
handlers := eb.subscribers[eventType]
```

**Ligne 109** - bidirectional - Package: unknown

```go
func (eb *EventBus) Publish(event *Event) error {
```

**Ligne 111** - bidirectional - Package: unknown

```go
return fmt.Errorf("no subscribers for event type: %s", eventType)
```

**Ligne 117** - bidirectional - Package: unknown

```go
eb.subscribers[eventType] = append(handlers[:i], handlers[i+1:]...)
```

**Ligne 118** - bidirectional - Package: unknown

```go
eb.metrics.Subscribers = eb.getTotalSubscribers()
```

**Ligne 120** - bidirectional - Package: unknown

```go
eb.logger.Info("Subscriber unregistered", zap.String("event_type", eventType))
```

**Ligne 128** - bidirectional - Package: unknown

```go
// Publish publie un événement sur le bus
```

**Ligne 129** - bidirectional - Package: unknown

```go
func (eb *EventBus) Publish(ctx context.Context, event *ManagerEvent) error {
```

**Ligne 139** - bidirectional - Package: unknown

```go
}).Debug("Event published")
```

**Ligne 148** - bidirectional - Package: unknown

```go
// PublishSync publishes an event synchronously and waits for processing
```

**Ligne 148** - bidirectional - Package: unknown

```go
eb.logger.Debug("Event published",
```

**Ligne 149** - bidirectional - Package: unknown

```go
func (eb *EventBus) PublishSync(ctx context.Context, event *Event) error {
```

**Ligne 150** - bidirectional - Package: unknown

```go
if err := eb.Publish(event); err != nil {
```

**Ligne 159** - bidirectional - Package: unknown

```go
return fmt.Errorf("timeout publishing event: queue is full")
```

**Ligne 183** - bidirectional - Package: unknown

```go
handlers := eb.subscribers[event.Type]
```

**Ligne 187** - bidirectional - Package: unknown

```go
eb.logger.Debug("No subscribers for event",
```

**Ligne 197** - bidirectional - Package: unknown

```go
SubscriberCount: make(map[string]int),
```

**Ligne 204** - bidirectional - Package: unknown

```go
for k, v := range eb.metrics.SubscriberCount {
```

**Ligne 205** - bidirectional - Package: unknown

```go
metrics.SubscriberCount[k] = v
```

**Ligne 244** - bidirectional - Package: unknown

```go
// getTotalSubscribers calcule le nombre total de souscripteurs
```

**Ligne 245** - bidirectional - Package: unknown

```go
func (eb *EventBus) getTotalSubscribers() int {
```

**Ligne 247** - bidirectional - Package: unknown

```go
for _, handlers := range eb.subscribers {
```

**Ligne 293** - bidirectional - Package: unknown

```go
// Get subscribers for this event type
```

**Ligne 295** - bidirectional - Package: unknown

```go
handlers := make([]EventHandler, len(eb.subscribers[event.Type]))
```

**Ligne 296** - bidirectional - Package: unknown

```go
copy(handlers, eb.subscribers[event.Type])
```

**Ligne 298** - bidirectional - Package: unknown

```go
// Also get wildcard subscribers (*)
```

**Ligne 299** - bidirectional - Package: unknown

```go
wildcardHandlers := make([]EventHandler, len(eb.subscribers["*"]))
```

**Ligne 300** - bidirectional - Package: unknown

```go
copy(wildcardHandlers, eb.subscribers["*"])
```

**Ligne 333** - bidirectional - Package: unknown

```go
// validateEvent validates an event before publishing
```

**Ligne 407** - bidirectional - Package: unknown

```go
"subscribers":      len(metrics.SubscriberCount),
```

**Ligne 425** - bidirectional - Package: unknown

```go
// Common event publishers
```

**Ligne 426** - bidirectional - Package: unknown

```go
func (eb *EventBus) PublishManagerRegistered(managerName string, capabilities []string) error {
```

**Ligne 427** - bidirectional - Package: unknown

```go
return eb.Publish(&Event{
```

**Ligne 439** - bidirectional - Package: unknown

```go
func (eb *EventBus) PublishOperationStarted(operationID string, operationType string, managers []string) error {
```

**Ligne 440** - bidirectional - Package: unknown

```go
return eb.Publish(&Event{
```

**Ligne 453** - bidirectional - Package: unknown

```go
func (eb *EventBus) PublishOperationCompleted(operationID string, success bool, duration time.Duration) error {
```

**Ligne 459** - bidirectional - Package: unknown

```go
return eb.Publish(&Event{
```

**Ligne 472** - bidirectional - Package: unknown

```go
func (eb *EventBus) PublishSystemAlert(level string, message string, component string) error {
```

**Ligne 473** - bidirectional - Package: unknown

```go
return eb.Publish(&Event{
```

#### 📄 `gateway.go`

**Ligne 107** - inbound - Package: unknown

```go
events.POST("/", ag.publishEvent)
```

**Ligne 108** - inbound - Package: unknown

```go
events.GET("/subscribe/:topic", ag.subscribeToEvents)
```

#### 📄 `handlers.go`

**Ligne 498** - bidirectional - Package: unknown

```go
// PublishEvent publie un nouvel événement
```

**Ligne 499** - bidirectional - Package: unknown

```go
// @Summary Publish event
```

**Ligne 507** - bidirectional - Package: unknown

```go
func (ag *APIGateway) publishEvent(c *gin.Context) {
```

**Ligne 519** - bidirectional - Package: unknown

```go
"message": "Event published successfully",
```

**Ligne 524** - bidirectional - Package: unknown

```go
// SubscribeToEvents souscrit aux événements d'un topic
```

**Ligne 525** - bidirectional - Package: unknown

```go
// @Summary Subscribe to events
```

**Ligne 532** - bidirectional - Package: unknown

```go
// @Router /api/v1/events/subscribe/{topic} [get]
```

**Ligne 533** - bidirectional - Package: unknown

```go
func (ag *APIGateway) subscribeToEvents(c *gin.Context) {
```

**Ligne 538** - bidirectional - Package: unknown

```go
"message":       "Subscribed to events",
```

#### 📄 `integration_hub.go`

**Ligne 221** - bidirectional - Package: unknown

```go
ih.eventBus.Publish(&Event{
```

**Ligne 297** - bidirectional - Package: unknown

```go
ih.eventBus.Publish(&Event{
```

**Ligne 369** - bidirectional - Package: unknown

```go
// SubscribeToEvents subscribes to specific event types
```

**Ligne 370** - bidirectional - Package: unknown

```go
func (ih *IntegrationHub) SubscribeToEvents(eventType string, handler EventHandler) {
```

**Ligne 371** - bidirectional - Package: unknown

```go
ih.eventBus.Subscribe(eventType, handler)
```

#### 📄 `manager_common.go`

**Ligne 79** - bidirectional - Package: unknown

```go
Publish(ctx context.Context, event *ManagerEvent) error
```

**Ligne 80** - bidirectional - Package: unknown

```go
Subscribe(ctx context.Context, eventType string, handler EventHandler) error
```

**Ligne 81** - bidirectional - Package: unknown

```go
Unsubscribe(ctx context.Context, eventType string, handler EventHandler) error
```

#### 📄 `master_coordination_layer.go`

**Ligne 309** - bidirectional - Package: unknown

```go
mcl.eventBus.SubscribeToManager(name, mcl.handleManagerEvent)
```

**Ligne 343** - bidirectional - Package: unknown

```go
mcl.eventBus.PublishEvent(&CoordinationEvent{
```

**Ligne 556** - bidirectional - Package: unknown

```go
mcl.eventBus.PublishEvent(&CoordinationEvent{
```

**Ligne 671** - bidirectional - Package: unknown

```go
// EventSubscriber représente un abonné aux événements
```

**Ligne 672** - bidirectional - Package: unknown

```go
type EventSubscriber interface {
```

#### 📄 `persistent_event_bus.go`

**Ligne 86** - bidirectional - Package: unknown

```go
eventBus.Subscribe("*", persistentBus.persistEventHandler)
```

**Ligne 322** - bidirectional - Package: unknown

```go
if err := peb.Publish(ctx, event); err != nil {
```

#### 📄 `phase_4_performance_validation.go`

**Ligne 186** - bidirectional - Package: unknown

```go
subscribers map[string][]chan interface{}
```

**Ligne 193** - bidirectional - Package: unknown

```go
subscribers: make(map[string][]chan interface{}),
```

**Ligne 198** - bidirectional - Package: unknown

```go
func (eb *EventBus) Subscribe(topic string, ch chan interface{}) {
```

**Ligne 201** - bidirectional - Package: unknown

```go
eb.subscribers[topic] = append(eb.subscribers[topic], ch)
```

**Ligne 204** - bidirectional - Package: unknown

```go
func (eb *EventBus) Publish(topic string, event interface{}) {
```

**Ligne 208** - bidirectional - Package: unknown

```go
for _, ch := range eb.subscribers[topic] {
```

**Ligne 311** - bidirectional - Package: unknown

```go
bus.Subscribe("test_topic", ch1)
```

**Ligne 312** - bidirectional - Package: unknown

```go
bus.Subscribe("test_topic", ch2)
```

**Ligne 318** - bidirectional - Package: unknown

```go
bus.Publish("test_topic", event)
```

**Ligne 360** - bidirectional - Package: unknown

```go
bus.Publish("cache_hit", fmt.Sprintf("query_%d", id))
```

**Ligne 378** - bidirectional - Package: unknown

```go
bus.Publish("search_completed", fmt.Sprintf("query_%d", id))
```

#### 📄 `phase_5_validation_simple.go`

**Ligne 55** - bidirectional - Package: unknown

```go
"GET /api/v1/events/subscribe/:topic - Souscription",
```

#### 📄 `redis.go`

**Ligne 54** - bidirectional - Package: unknown

```go
pubsub := r.client.Subscribe(ctx, r.topic)
```

**Ligne 57** - bidirectional - Package: unknown

```go
defer pubsub.Close()
```

**Ligne 59** - bidirectional - Package: unknown

```go
for msg := range pubsub.Channel() {
```

**Ligne 63** - bidirectional - Package: unknown

```go
// Subscribe to session updates
```

**Ligne 64** - bidirectional - Package: unknown

```go
store.pubsub = client.Subscribe(context.Background(), cfg.Topic)
```

**Ligne 72** - bidirectional - Package: unknown

```go
ch := s.pubsub.Channel()
```

**Ligne 85** - bidirectional - Package: unknown

```go
return r.client.Publish(ctx, r.topic, data).Err()
```

**Ligne 123** - bidirectional - Package: unknown

```go
// publishUpdate publishes a session update to the topic
```

**Ligne 124** - bidirectional - Package: unknown

```go
func (s *RedisStore) publishUpdate(ctx context.Context, action string, meta *Meta, msg *Message) error {
```

**Ligne 140** - bidirectional - Package: unknown

```go
return s.client.Publish(ctx, s.topic, data).Err()
```

**Ligne 177** - bidirectional - Package: unknown

```go
// Publish update
```

**Ligne 178** - bidirectional - Package: unknown

```go
if err := s.publishUpdate(ctx, "create", meta, nil); err != nil {
```

**Ligne 179** - bidirectional - Package: unknown

```go
return nil, fmt.Errorf("failed to publish session creation: %w", err)
```

**Ligne 255** - bidirectional - Package: unknown

```go
// Publish delete
```

**Ligne 257** - bidirectional - Package: unknown

```go
return s.publishUpdate(ctx, "delete", meta, nil)
```

**Ligne 300** - bidirectional - Package: unknown

```go
if err := s.pubsub.Close(); err != nil {
```

**Ligne 336** - bidirectional - Package: unknown

```go
return c.store.publishUpdate(ctx, "event", c.meta, msg)
```

#### 📄 `security_manager.go`

**Ligne 250** - bidirectional - Package: unknown

```go
PublishedAt: time.Now().Add(-30 * 24 * time.Hour), // Example date
```

**Ligne 262** - bidirectional - Package: unknown

```go
PublishedAt: time.Now().Add(-60 * 24 * time.Hour),
```

#### 📄 `server_types.go`

**Ligne 177** - bidirectional - Package: unknown

```go
Subscribe   bool `json:"subscribe"`
```

#### 📄 `service.go`

**Ligne 43** - bidirectional - Package: unknown

```go
UnsubscribeList []string  `json:"unsubscribe_list"`
```

**Ligne 54** - bidirectional - Package: unknown

```go
UnsubscribeRate float64   `json:"unsubscribe_rate"`
```

**Ligne 210** - bidirectional - Package: unknown

```go
UnsubscribeList: []string{},
```

**Ligne 236** - bidirectional - Package: unknown

```go
// Invalidate related patterns if user unsubscribed
```

**Ligne 237** - bidirectional - Package: unknown

```go
if len(prefs.UnsubscribeList) > 0 {
```

**Ligne 272** - bidirectional - Package: unknown

```go
UnsubscribeRate: 0.001,
```

#### 📄 `session.go`

**Ligne 33** - bidirectional - Package: unknown

```go
// EventQueue returns a read-only channel where outbound messages are published.
```

#### 📄 `types.go`

**Ligne 54** - bidirectional - Package: unknown

```go
PublishedAt time.Time `json:"published_at,omitempty"` // Added
```

### 📡 WEBSOCKETS

#### 📄 `advanced_autonomy_manager.go`

**Ligne 108** - bidirectional - Package: unknown

```go
WebSocketEnabled     bool          `yaml:"websocket_enabled" json:"websocket_enabled"`
```

#### 📄 `analyzer.go`

**Ligne 33** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 36** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 40** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 85** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 89** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 93** - bidirectional - Package: unknown

```go
err := rows.Scan(&module, &errorCode, &frequency)
```

**Ligne 128** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 133** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 137** - bidirectional - Package: unknown

```go
err := rows.Scan(&errorCode1, &module1, &errorCode2, &module2, &timeDiffSeconds)
```

#### 📄 `handlers.go`

**Ligne 540** - bidirectional - Package: unknown

```go
"websocket_url": "/ws/events/" + topic,
```

#### 📄 `integration_demo.go`

**Ligne 174** - bidirectional - Package: unknown

```go
map[string]interface{}{"server": "localhost:8080", "protocol": "websocket"},
```

#### 📄 `items.go`

**Ligne 54** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 57** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 60** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 160** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 163** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 165** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

#### 📄 `main.go`

**Ligne 224** - bidirectional - Package: unknown

```go
wsHandler := apiserverHandler.NewWebSocket(db, openaiClient, jwtService, logger)
```

**Ligne 225** - inbound - Package: unknown

```go
r.GET("/api/ws/chat", wsHandler.HandleWebSocket)
```

**Ligne 416** - bidirectional - Package: unknown

```go
sc create EmailSender binpath= "C:\Program Files\EmailSender\email-sender-windows.exe" ^
```

**Ligne 480** - bidirectional - Package: unknown

```go
1. Copy email-sender-windows.exe to C:\Program Files\EmailSender\
```

#### 📄 `object_storage.go`

**Ligne 110** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 113** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 115** - bidirectional - Package: unknown

```go
if err := rows.Scan(&key); err != nil {
```

#### 📄 `operations.go`

**Ligne 30** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 33** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 38** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

#### 📄 `plan_synchronizer.go`

**Ligne 445** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 448** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 450** - bidirectional - Package: unknown

```go
if err := rows.Scan(&planID); err != nil {
```

**Ligne 456** - bidirectional - Package: unknown

```go
if err := rows.Err(); err != nil {
```

#### 📄 `postgresql_storage.go`

**Ligne 333** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 336** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 340** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 360** - bidirectional - Package: unknown

```go
return sessions, rows.Err()
```

**Ligne 479** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 482** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 486** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 507** - bidirectional - Package: unknown

```go
return events, rows.Err()
```

**Ligne 554** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 557** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 561** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 580** - bidirectional - Package: unknown

```go
return snapshots, rows.Err()
```

**Ligne 711** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 713** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 717** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 740** - bidirectional - Package: unknown

```go
return qb, rows.Err()
```

#### 📄 `real_time_monitoring_dashboard.go`

**Ligne 21** - bidirectional - Package: unknown

```go
WebSocketEnabled     bool          `yaml:"websocket_enabled" json:"websocket_enabled"`
```

**Ligne 94** - bidirectional - Package: unknown

```go
// et fournit une visualisation web temps réel avec WebSocket.
```

**Ligne 94** - bidirectional - Package: unknown

```go
// et fournit une visualisation web temps réel avec WebSocket.
```

**Ligne 103** - bidirectional - Package: unknown

```go
websocketServer   *WebSocketServer
```

**Ligne 118** - bidirectional - Package: unknown

```go
wsConnections     map[string]*WebSocketConnection
```

**Ligne 157** - bidirectional - Package: unknown

```go
// WebSocketServer serveur WebSocket pour les mises à jour temps réel
```

**Ligne 158** - bidirectional - Package: unknown

```go
type WebSocketServer struct {
```

**Ligne 159** - bidirectional - Package: unknown

```go
config      *WebSocketConfig
```

**Ligne 161** - bidirectional - Package: unknown

```go
connections map[string]*WebSocketConnection
```

**Ligne 175** - bidirectional - Package: unknown

```go
// WebSocketConnection connexion WebSocket active
```

**Ligne 176** - bidirectional - Package: unknown

```go
type WebSocketConnection struct {
```

**Ligne 182** - bidirectional - Package: unknown

```go
Connection   interface{} // WebSocket connection
```

**Ligne 244** - bidirectional - Package: unknown

```go
wsConnections: make(map[string]*WebSocketConnection),
```

**Ligne 283** - bidirectional - Package: unknown

```go
// Initialiser le serveur WebSocket si activé
```

**Ligne 284** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 285** - bidirectional - Package: unknown

```go
if err := rtmd.websocketServer.Initialize(ctx); err != nil {
```

**Ligne 286** - bidirectional - Package: unknown

```go
return fmt.Errorf("failed to initialize WebSocket server: %w", err)
```

**Ligne 341** - bidirectional - Package: unknown

```go
// Vérifier le serveur WebSocket si activé
```

**Ligne 342** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 343** - bidirectional - Package: unknown

```go
if err := rtmd.websocketServer.HealthCheck(ctx); err != nil {
```

**Ligne 344** - bidirectional - Package: unknown

```go
return fmt.Errorf("WebSocket server health check failed: %w", err)
```

**Ligne 396** - bidirectional - Package: unknown

```go
// Fermer toutes les connexions WebSocket
```

**Ligne 399** - bidirectional - Package: unknown

```go
if err := rtmd.closeWebSocketConnection(conn); err != nil {
```

**Ligne 400** - bidirectional - Package: unknown

```go
rtmd.logger.WithError(err).Warn(fmt.Sprintf("Failed to close WebSocket connection %s", conn.ID))
```

**Ligne 403** - bidirectional - Package: unknown

```go
rtmd.wsConnections = make(map[string]*WebSocketConnection)
```

**Ligne 413** - bidirectional - Package: unknown

```go
{"WebSocketServer", rtmd.websocketServer.Cleanup},
```

**Ligne 488** - bidirectional - Package: unknown

```go
// ConnectWebSocket connecte un client WebSocket
```

**Ligne 489** - bidirectional - Package: unknown

```go
func (rtmd *RealTimeMonitoringDashboard) ConnectWebSocket(userID string, subscriptions []string) (*WebSocketConnection, error) {
```

**Ligne 490** - bidirectional - Package: unknown

```go
if !rtmd.config.WebSocketEnabled {
```

**Ligne 491** - bidirectional - Package: unknown

```go
return nil, fmt.Errorf("WebSocket is disabled")
```

**Ligne 494** - bidirectional - Package: unknown

```go
conn := &WebSocketConnection{
```

**Ligne 506** - bidirectional - Package: unknown

```go
rtmd.logger.Info(fmt.Sprintf("WebSocket client connected: %s (user: %s)", conn.ID, userID))
```

**Ligne 511** - bidirectional - Package: unknown

```go
// BroadcastUpdate diffuse une mise à jour à tous les clients WebSocket
```

**Ligne 513** - bidirectional - Package: unknown

```go
if !rtmd.config.WebSocketEnabled {
```

**Ligne 517** - bidirectional - Package: unknown

```go
return rtmd.websocketServer.BroadcastMessage(updateType, data)
```

**Ligne 571** - bidirectional - Package: unknown

```go
// Initialiser le serveur WebSocket si activé
```

**Ligne 572** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 573** - bidirectional - Package: unknown

```go
websocketServer, err := NewWebSocketServer(&WebSocketConfig{}, rtmd.logger)
```

**Ligne 575** - bidirectional - Package: unknown

```go
return fmt.Errorf("failed to create WebSocket server: %w", err)
```

**Ligne 577** - bidirectional - Package: unknown

```go
rtmd.websocketServer = websocketServer
```

**Ligne 593** - bidirectional - Package: unknown

```go
// Route WebSocket
```

**Ligne 594** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 595** - bidirectional - Package: unknown

```go
mux.HandleFunc("/ws", rtmd.handleWebSocket)
```

**Ligne 694** - bidirectional - Package: unknown

```go
// Diffuser les mises à jour via WebSocket
```

**Ligne 695** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 776** - bidirectional - Package: unknown

```go
// Diffuser l'alerte via WebSocket
```

**Ligne 777** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 812** - bidirectional - Package: unknown

```go
// Diffuser l'événement via WebSocket
```

**Ligne 813** - bidirectional - Package: unknown

```go
if rtmd.config.WebSocketEnabled {
```

**Ligne 885** - bidirectional - Package: unknown

```go
func (rtmd *RealTimeMonitoringDashboard) handleWebSocket(w http.ResponseWriter, r *http.Request) {
```

**Ligne 886** - bidirectional - Package: unknown

```go
// Ici serait implémentée la logique de mise à niveau WebSocket
```

**Ligne 887** - bidirectional - Package: unknown

```go
rtmd.logger.Info("WebSocket connection attempted")
```

**Ligne 1011** - bidirectional - Package: unknown

```go
func (rtmd *RealTimeMonitoringDashboard) closeWebSocketConnection(conn *WebSocketConnection) error {
```

**Ligne 1012** - bidirectional - Package: unknown

```go
// Ici serait implémentée la logique de fermeture de connexion WebSocket
```

**Ligne 1013** - bidirectional - Package: unknown

```go
rtmd.logger.Info(fmt.Sprintf("Closing WebSocket connection %s", conn.ID))
```

**Ligne 1054** - bidirectional - Package: unknown

```go
type WebSocketConfig struct {
```

#### 📄 `realtime-dashboard.go`

**Ligne 11** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 11** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 21** - bidirectional - Package: unknown

```go
// WebSocket connections
```

**Ligne 22** - bidirectional - Package: unknown

```go
upgrader      websocket.Upgrader
```

**Ligne 22** - bidirectional - Package: unknown

```go
upgrader      websocket.Upgrader
```

**Ligne 23** - bidirectional - Package: unknown

```go
connections   map[string]*websocket.Conn
```

**Ligne 23** - bidirectional - Package: unknown

```go
connections   map[string]*websocket.Conn
```

**Ligne 68** - bidirectional - Package: unknown

```go
upgrader: websocket.Upgrader{
```

**Ligne 68** - bidirectional - Package: unknown

```go
upgrader: websocket.Upgrader{
```

**Ligne 73** - bidirectional - Package: unknown

```go
connections: make(map[string]*websocket.Conn),
```

**Ligne 73** - bidirectional - Package: unknown

```go
connections: make(map[string]*websocket.Conn),
```

**Ligne 87** - bidirectional - Package: unknown

```go
http.HandleFunc("/ws", rd.handleWebSocket)
```

**Ligne 309** - bidirectional - Package: unknown

```go
function connectWebSocket() {
```

**Ligne 313** - bidirectional - Package: unknown

```go
ws = new WebSocket(wsUrl);
```

**Ligne 315** - bidirectional - Package: unknown

```go
ws.onopen = function() {
```

**Ligne 316** - bidirectional - Package: unknown

```go
console.log('WebSocket connected');
```

**Ligne 321** - bidirectional - Package: unknown

```go
ws.onmessage = function(event) {
```

**Ligne 326** - bidirectional - Package: unknown

```go
ws.onclose = function() {
```

**Ligne 327** - bidirectional - Package: unknown

```go
console.log('WebSocket connection closed');
```

**Ligne 330** - bidirectional - Package: unknown

```go
setTimeout(connectWebSocket, 2000 * connectionAttempts);
```

**Ligne 334** - bidirectional - Package: unknown

```go
ws.onerror = function(error) {
```

**Ligne 335** - bidirectional - Package: unknown

```go
console.error('WebSocket error:', error);
```

**Ligne 444** - bidirectional - Package: unknown

```go
// Fallback API polling if WebSocket fails
```

**Ligne 453** - bidirectional - Package: unknown

```go
connectWebSocket();
```

**Ligne 500** - bidirectional - Package: unknown

```go
// handleWebSocket handles WebSocket connections for real-time updates
```

**Ligne 501** - bidirectional - Package: unknown

```go
func (rd *RealtimeDashboard) handleWebSocket(w http.ResponseWriter, r *http.Request) {
```

**Ligne 504** - bidirectional - Package: unknown

```go
rd.logger.Printf("WebSocket upgrade failed: %v", err)
```

**Ligne 515** - bidirectional - Package: unknown

```go
rd.logger.Printf("New WebSocket connection: %s", connID)
```

**Ligne 528** - bidirectional - Package: unknown

```go
rd.logger.Printf("WebSocket connection closed: %s", connID)
```

**Ligne 535** - bidirectional - Package: unknown

```go
if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
```

**Ligne 535** - bidirectional - Package: unknown

```go
if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
```

**Ligne 536** - bidirectional - Package: unknown

```go
rd.logger.Printf("WebSocket error: %v", err)
```

**Ligne 549** - bidirectional - Package: unknown

```go
// broadcastUpdates sends periodic updates to all connected WebSocket clients
```

**Ligne 553** - bidirectional - Package: unknown

```go
rd.broadcastToWebSockets(data)
```

**Ligne 558** - bidirectional - Package: unknown

```go
// broadcastToWebSockets sends data to all connected WebSocket clients
```

**Ligne 559** - bidirectional - Package: unknown

```go
func (rd *RealtimeDashboard) broadcastToWebSockets(data *DashboardData) {
```

**Ligne 566** - bidirectional - Package: unknown

```go
rd.logger.Printf("Failed to send WebSocket message to %s: %v", connID, err)
```

**Ligne 621** - bidirectional - Package: unknown

```go
// GetConnectionCount returns the number of active WebSocket connections
```

#### 📄 `retrieval_manager.go`

**Ligne 79** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 82** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 86** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 170** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 173** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 177** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 216** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 219** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 222** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

#### 📄 `sql_storage.go`

**Ligne 275** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 278** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 282** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

#### 📄 `sqlite_index_manager.go`

**Ligne 371** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 374** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 379** - bidirectional - Package: unknown

```go
err := rows.Scan(&doc.ID, &doc.Content, &metadataJSON, &createdAt, &updatedAt)
```

**Ligne 391** - bidirectional - Package: unknown

```go
if err := rows.Err(); err != nil {
```

#### 📄 `sqlite.go`

**Ligne 122** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 125** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 127** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 143** - bidirectional - Package: unknown

```go
return values, rows.Err()
```

#### 📄 `storage_manager.go`

**Ligne 284** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 287** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 290** - bidirectional - Package: unknown

```go
err := rows.Scan(
```

**Ligne 302** - bidirectional - Package: unknown

```go
if err := rows.Err(); err != nil { return nil, fmt.Errorf("error reading dependency rows: %w", err) }
```

#### 📄 `sync_dashboard.go`

**Ligne 11** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 11** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 51** - bidirectional - Package: unknown

```go
wsConnections map[string]*websocket.Conn
```

**Ligne 51** - bidirectional - Package: unknown

```go
wsConnections map[string]*websocket.Conn
```

**Ligne 92** - bidirectional - Package: unknown

```go
// WebSocket upgrader
```

**Ligne 93** - bidirectional - Package: unknown

```go
var upgrader = websocket.Upgrader{
```

**Ligne 93** - bidirectional - Package: unknown

```go
var upgrader = websocket.Upgrader{
```

**Ligne 106** - bidirectional - Package: unknown

```go
wsConnections: make(map[string]*websocket.Conn),
```

**Ligne 106** - bidirectional - Package: unknown

```go
wsConnections: make(map[string]*websocket.Conn),
```

**Ligne 148** - inbound - Package: unknown

```go
sd.webServer.GET("/ws", sd.handleWebSocket)
```

**Ligne 226** - bidirectional - Package: unknown

```go
// Broadcast update to WebSocket clients
```

**Ligne 252** - bidirectional - Package: unknown

```go
// handleWebSocket handles WebSocket connections for real-time updates
```

**Ligne 253** - bidirectional - Package: unknown

```go
func (sd *SyncDashboard) handleWebSocket(c *gin.Context) {
```

**Ligne 256** - bidirectional - Package: unknown

```go
sd.logger.Printf("WebSocket upgrade failed: %v", err)
```

**Ligne 264** - bidirectional - Package: unknown

```go
sd.logger.Printf("WebSocket client connected: %s", clientID)
```

**Ligne 278** - bidirectional - Package: unknown

```go
sd.logger.Printf("WebSocket client disconnected: %s", clientID)
```

**Ligne 305** - bidirectional - Package: unknown

```go
// broadcastUpdate sends updates to all connected WebSocket clients
```

**Ligne 316** - bidirectional - Package: unknown

```go
sd.logger.Printf("Failed to send WebSocket message to %s: %v", clientID, err)
```

**Ligne 330** - bidirectional - Package: unknown

```go
// Close all WebSocket connections
```

#### 📄 `sync-integration-test.go`

**Ligne 462** - bidirectional - Package: unknown

```go
// Test WebSocket connection count
```

#### 📄 `sync.go`

**Ligne 39** - bidirectional - Package: unknown

```go
fmt.Println("Syncing with n8n workflows...")
```

#### 📄 `vectorization_utils.go`

**Ligne 224** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 226** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 228** - bidirectional - Package: unknown

```go
err := rows.Scan(&tableName, &comment)
```

**Ligne 274** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 276** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 280** - bidirectional - Package: unknown

```go
err := rows.Scan(&colName, &dataType, &isNullable, &defaultValue, &comment)
```

**Ligne 327** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 329** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 331** - bidirectional - Package: unknown

```go
err := rows.Scan(&fromTable, &fromColumn, &toTable, &toColumn)
```

**Ligne 374** - bidirectional - Package: unknown

```go
defer rows.Close()
```

**Ligne 376** - bidirectional - Package: unknown

```go
for rows.Next() {
```

**Ligne 381** - bidirectional - Package: unknown

```go
err := rows.Scan(&indexName, &tableName, &isUnique, &columns)
```

#### 📄 `websocket.go`

**Ligne 3** - bidirectional - Package: unknown

```go
// WebSocketMessage represents a message sent over WebSocket
```

**Ligne 4** - bidirectional - Package: unknown

```go
type WebSocketMessage struct {
```

**Ligne 14** - bidirectional - Package: unknown

```go
// WebSocketResponse represents a response sent over WebSocket
```

**Ligne 15** - bidirectional - Package: unknown

```go
type WebSocketResponse struct {
```

**Ligne 18** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 18** - bidirectional - Package: unknown

```go
"github.com/gorilla/websocket"
```

**Ligne 24** - bidirectional - Package: unknown

```go
type WebSocket struct {
```

**Ligne 31** - bidirectional - Package: unknown

```go
func NewWebSocket(db database.Database, openaiCli *openai.Client, jwtService *jwt.Service, logger *zap.Logger) *WebSocket {
```

**Ligne 32** - bidirectional - Package: unknown

```go
return &WebSocket{
```

**Ligne 36** - bidirectional - Package: unknown

```go
logger:     logger.Named("apiserver.handler.websocket"),
```

**Ligne 40** - bidirectional - Package: unknown

```go
var upgrader = websocket.Upgrader{
```

**Ligne 40** - bidirectional - Package: unknown

```go
var upgrader = websocket.Upgrader{
```

**Ligne 46** - bidirectional - Package: unknown

```go
func (h *WebSocket) HandleWebSocket(c *gin.Context) {
```

**Ligne 49** - bidirectional - Package: unknown

```go
h.logger.Warn("websocket connection attempt without token",
```

**Ligne 57** - bidirectional - Package: unknown

```go
h.logger.Warn("invalid token for websocket connection",
```

**Ligne 63** - bidirectional - Package: unknown

```go
// MsgType represents the type of WebSocket message
```

**Ligne 64** - bidirectional - Package: unknown

```go
h.logger.Debug("token validated successfully for websocket connection",
```

**Ligne 70** - bidirectional - Package: unknown

```go
h.logger.Warn("websocket connection attempt without sessionId",
```

**Ligne 121** - bidirectional - Package: unknown

```go
h.logger.Info("new websocket connection attempt",
```

**Ligne 128** - bidirectional - Package: unknown

```go
h.logger.Error("failed to upgrade websocket connection",
```

**Ligne 137** - bidirectional - Package: unknown

```go
h.logger.Info("websocket connection established",
```

**Ligne 143** - bidirectional - Package: unknown

```go
var message dto.WebSocketMessage
```

**Ligne 146** - bidirectional - Package: unknown

```go
h.logger.Warn("error reading websocket message",
```

**Ligne 155** - bidirectional - Package: unknown

```go
h.logger.Debug("websocket message received",
```

**Ligne 349** - bidirectional - Package: unknown

```go
response := dto.WebSocketResponse{
```

**Ligne 384** - bidirectional - Package: unknown

```go
response := dto.WebSocketResponse{
```

**Ligne 519** - bidirectional - Package: unknown

```go
response := dto.WebSocketResponse{
```

## 🏗️ Répartition Manager vs Non-Manager

### Fichiers Managers
- **Points de communication**: 336
- **Fichiers concernés**: 28

### Fichiers Non-Managers  
- **Points de communication**: 1557
- **Fichiers concernés**: 126

## 📈 TOP 5 Fichiers avec le Plus de Points
- `main.go`: 296 points
- `event_bus.go`: 106 points
- `real_time_monitoring_dashboard.go`: 67 points
- `realtime-dashboard.go`: 50 points
- `branching_manager.go`: 50 points

## 🔄 Recommandations

### Patterns de Communication Détectés
- **channels**: 1049 occurrences
- **http_endpoints**: 457 occurrences
- **websockets**: 226 occurrences
- **redis_pubsub**: 155 occurrences
- **grpc_calls**: 4 occurrences
- **message_queues**: 2 occurrences
### Actions Recommandées
- Centraliser la gestion des channels dans un manager dédié
- Standardiser les patterns HTTP avec middleware unifié
- Implémenter circuit breakers pour les appels externes
- Ajouter monitoring sur tous les points de communication

---
*Généré par Tâche Atomique 005 - 2025-06-18 20:44:11*
