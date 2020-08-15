package middleware

import (
	"context"
	"log"

	"github.com/s-you/yo-templates/internal/pkg/cache"
)

type cacheKey struct{}

func CacheFromContext(ctx context.Context) *cache.Cache {
	if m, ok := ctx.Value(cacheKey{}).(*cache.Cache); ok {
		return m
	}
	log.Println("cache did not set in context")
	return cache.New()
}
