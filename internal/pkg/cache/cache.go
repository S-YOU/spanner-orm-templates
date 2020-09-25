package cache

import (
	"time"

	gocache "github.com/patrickmn/go-cache"
)

const (
	NoExpiration      time.Duration = -1
	DefaultExpiration time.Duration = 0
)

var Default = New()

func New() *Cache {
	return &Cache{
		cache: gocache.New(0, 10*time.Minute),
	}
}

type Cache struct {
	cache *gocache.Cache
}

func (c *Cache) Get(k string) (interface{}, bool) {
	return c.cache.Get(k)
}

func (c *Cache) Set(k string, v interface{}, d time.Duration) {
	c.cache.Set(k, v, d)
}
