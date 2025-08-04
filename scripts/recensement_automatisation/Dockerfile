# Dockerfile pour tests isolés du module recensement_automatisation
FROM golang:1.21-alpine

WORKDIR /app

COPY . .

RUN go mod tidy

CMD ["go", "test", "-cover", "-v"]
