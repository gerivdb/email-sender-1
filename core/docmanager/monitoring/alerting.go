// core/docmanager/monitoring/alerting.go
// Alerting et reporting monitoring DocManager v66

package monitoring

import "context"

func SendAlert(ctx context.Context, alertType string, details interface{}) error {
// Stub : simule l’envoi d’une alerte
return nil
}

func GenerateHealthReport(ctx context.Context) error {
// Stub : simule la génération d’un rapport de santé
return nil
}
