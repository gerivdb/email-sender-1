# Real-time Monitoring and Alerts Documentation

## Composants

- **ConflictMonitor** : Surveillance temps réel (channels, goroutines)
- **AlertingSystem** : Seuils configurables, alertes
- **DashboardMetrics** : Endpoints HTTP
- **ExternalMonitoring** : Intégration systèmes externes
- **Logging** : Logs structurés (zap)
- **HealthCheck** : Auto-surveillance

## Exemple d'utilisation

```go
monitor := NewConflictMonitor()
monitor.Start()
monitor.Stop()
alert := NewAlertingSystem(5)
alert.Check(10)
```

## Tests

Tous les composants sont testés dans `monitoring_test.go`.
