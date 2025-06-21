// 4.4.3.1 RedisStreamingDocSync : structure principale
package redisstreaming

import (
	"github.com/go-redis/redis/v8"
)

type RedisStreamingDocSync struct {
	client *redis.Client
}

func NewRedisStreamingDocSync(addr string) *RedisStreamingDocSync {
	client := redis.NewClient(&redis.Options{
		Addr: addr,
	})
	return &RedisStreamingDocSync{client: client}
}

func (r *RedisStreamingDocSync) Close() error {
	return r.client.Close()
}
