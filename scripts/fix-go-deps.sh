#!/bin/bash
# Script pour corriger automatiquement les dépendances Go manquantes et nettoyer les modules

set -e

echo "Ajout des dépendances externes manquantes..."
go get github.com/qdrant/go-client/qdrant \
  github.com/spf13/cobra \
  go.uber.org/zap \
  github.com/gorilla/mux \
  github.com/prometheus/client_golang/prometheus \
  github.com/prometheus/client_golang/prometheus/promhttp \
  github.com/prometheus/client_golang/prometheus/promauto \
  github.com/redis/go-redis/v9 \
  github.com/gin-gonic/gin \
  github.com/oapi-codegen/runtime \
  github.com/google/uuid \
  github.com/stretchr/testify/assert \
  github.com/stretchr/testify/require \
  github.com/stretchr/testify/mock \
  github.com/stretchr/testify/suite \
  github.com/cenkalti/backoff/v4 \
  github.com/go-redis/redis/v8 \
  github.com/mattn/go-sqlite3 \
  github.com/influxdata/influxdb-client-go/v2 \
  github.com/influxdata/influxdb-client-go/v2/api \
  github.com/golang-jwt/jwt/v5 \
  github.com/gomarkdown/markdown/ast \
  github.com/gomarkdown/markdown/parser \
  github.com/pdfcpu/pdfcpu/pkg/api \
  github.com/saintfish/chardet \
  github.com/schollz/progressbar/v3 \
  github.com/lib/pq \
  github.com/gorilla/websocket \
  go.opentelemetry.io/otel \
  go.opentelemetry.io/otel/exporters/stdout/stdouttrace \
  go.opentelemetry.io/otel/sdk/resource \
  go.opentelemetry.io/otel/sdk/trace \
  go.opentelemetry.io/otel/semconv/v1.17.0 \
  go.opentelemetry.io/otel/trace \
  golang.org/x/mod/modfile \
  golang.org/x/text/encoding \
  golang.org/x/text/encoding/charmap \
  golang.org/x/text/encoding/unicode \
  gopkg.in/yaml.v2 \
  gopkg.in/yaml.v3

echo "Nettoyage des modules (go mod tidy)..."
go mod tidy

echo "Vérification de la compilation..."
go build ./... || echo "Des erreurs de compilation subsistent, voir ci-dessus."

echo "Script terminé."
