package cache

import (
	"time"

	gocache "github.com/patrickmn/go-cache"
)

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

func (c *Cache) Set(k string, v interface{}) {
	c.cache.Set(k, v, gocache.NoExpiration)
}
