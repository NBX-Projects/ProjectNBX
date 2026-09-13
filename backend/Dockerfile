# Etapa de Compilação
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Instala certificados SSL e git se necessário
RUN apk add --no-cache git ca-certificates

# Cache de dependências
COPY go.mod go.sum* ./
RUN go mod download || true

# Copia código fonte
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server cmd/api/main.go

# Etapa de Execução Final Leve
FROM alpine:3.19

WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata

COPY --from=builder /app/server /app/server

EXPOSE 8080

CMD ["/app/server"]
