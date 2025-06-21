package tracing

import (
	"context"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace" // Aliased to sdktrace
	semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
	"go.opentelemetry.io/otel/trace" // This will be the 'trace' package for API types like trace.Span
)

// InitTracer initialise OpenTelemetry TracerProvider (stdout ou OTLP)
func InitTracer(serviceName string) (func(context.Context) error, error) {
	exporter, err := stdouttrace.New(stdouttrace.WithPrettyPrint())
	if err != nil {
		return nil, err
	}
	// Use the aliased sdktrace for provider configuration
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(serviceName),
		)),
	)
	otel.SetTracerProvider(tp)
	return tp.Shutdown, nil
}

// StartSpan démarre un span pour une opération
// trace.Span here refers to go.opentelemetry.io/otel/trace.Span
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
