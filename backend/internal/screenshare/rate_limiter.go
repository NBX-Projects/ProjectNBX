package screenshare

import (
	"sync"
	"time"

	"github.com/projectnbx/backend/internal/models"
)

type tokenBucket struct {
	tokens         float64
	maxTokens      float64
	refillRate     float64 // tokens por segundo
	lastRefillTime time.Time
}

func (tb *tokenBucket) allow(cost float64, now time.Time) bool {
	elapsed := now.Sub(tb.lastRefillTime).Seconds()
	tb.tokens += elapsed * tb.refillRate
	if tb.tokens > tb.maxTokens {
		tb.tokens = tb.maxTokens
	}
	tb.lastRefillTime = now

	if tb.tokens >= cost {
		tb.tokens -= cost
		return true
	}
	return false
}

// RateLimiter gerencia limites de taxa por usuário e por tipo de evento
type RateLimiter struct {
	mu      sync.Mutex
	buckets map[string]*tokenBucket // chave: "userID:eventType"
}

func NewRateLimiter() *RateLimiter {
	return &RateLimiter{
		buckets: make(map[string]*tokenBucket),
	}
}

func (rl *RateLimiter) Allow(userID string, eventType models.EventType) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	key := userID + ":" + string(eventType)

	bucket, exists := rl.buckets[key]
	if !exists {
		bucket = rl.createBucketForEvent(eventType, now)
		rl.buckets[key] = bucket
	}

	return bucket.allow(1.0, now)
}

func (rl *RateLimiter) createBucketForEvent(eventType models.EventType, now time.Time) *tokenBucket {
	switch eventType {
	case models.EventWebRTCOffer, models.EventWebRTCAnswer:
		// 10 ops/sec com burst de 15
		return &tokenBucket{
			tokens:         15,
			maxTokens:      15,
			refillRate:     10.0,
			lastRefillTime: now,
		}
	case models.EventWebRTCICECandidate:
		// 100 ops/sec com burst de 150
		return &tokenBucket{
			tokens:         150,
			maxTokens:      150,
			refillRate:     100.0,
			lastRefillTime: now,
		}
	case models.EventScreenShareStart:
		// 5 ops/min (refill: 5/60 = 0.0833 ops/s) com burst de 5
		return &tokenBucket{
			tokens:         5,
			maxTokens:      5,
			refillRate:     5.0 / 60.0,
			lastRefillTime: now,
		}
	case models.EventScreenShareJoin:
		// 15 ops/min (refill: 15/60 = 0.25 ops/s) com burst de 15
		return &tokenBucket{
			tokens:         15,
			maxTokens:      15,
			refillRate:     15.0 / 60.0,
			lastRefillTime: now,
		}
	default:
		// Padrão genérico de 30 ops/s
		return &tokenBucket{
			tokens:         30,
			maxTokens:      30,
			refillRate:     30.0,
			lastRefillTime: now,
		}
	}
}

// Cleanup remove buckets inativos há mais de 10 minutos
func (rl *RateLimiter) Cleanup(now time.Time) {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	for k, bucket := range rl.buckets {
		if now.Sub(bucket.lastRefillTime) > 10*time.Minute {
			delete(rl.buckets, k)
		}
	}
}
