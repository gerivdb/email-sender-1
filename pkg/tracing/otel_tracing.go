package tracing

import (
	"context"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace"
)

// InitTracer initialise OpenTelemetry TracerProvider (stdout ou OTLP)
func InitTracer(serviceName string) (func(context.Context) error, error) {
	exporter, err := stdouttrace.New(stdouttrace.WithPrettyPrint())
	if err != nil {
		return nil, err
	}
	tp := trace.NewTracerProvider(
		trace.WithBatcher(exporter),
		trace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(serviceName),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp.Shutdown, nil
}

// StartSpan démarre un span pour une opération
func StartSpan(ctx context.Context, name string) (context.Context, trace.Span) {
	tracer := otel.Tracer("go-n8n-infra")
	return tracer.Start(ctx, name)
}

// Example usage:
/*
func main() {
shutdown, err := tracing.InitTracer("go-n8n-infra")
if err != nil {
log.Fatal(err)
}
defer shutdown(context.Background())

ctx, span := tracing.StartSpan(context.Background(), "main-operation")
defer span.End()

// ... code à tracer ...

}
*/
