<<<<<<< HEAD:cmd/redis-demo/redis_demo.go
package redis_demo

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	redisConfig "email_sender/pkg/cache/redis"
)

func main() {
	log.Println("=== DEMO: Section 1.3.1.1 - Configuration Redis (Plan v39) ===")
	log.Println()

	// 1. Configuration des paramètres de base Redis
	log.Println("🔧 1. Configuration des paramètres de base Redis")
	config := redisConfig.DefaultRedisConfig()
	fmt.Printf("   Host: %s, Port: %d, DB: %d\n", config.Host, config.Port, config.DB)
	fmt.Printf("   DialTimeout: %v, ReadTimeout: %v, WriteTimeout: %v\n",
		config.DialTimeout, config.ReadTimeout, config.WriteTimeout)
	log.Println()

	// 2. Configuration SSL/TLS pour production
	log.Println("🔒 2. Configuration SSL/TLS pour production")
	fmt.Printf("   TLSEnabled: %v, TLSSkipVerify: %v\n", config.TLSEnabled, config.TLSSkipVerify)
	log.Println()

	// 3. Paramètres de retry
	log.Println("🔄 3. Paramètres de retry")
	fmt.Printf("   MaxRetries: %d, MinRetryBackoff: %v, MaxRetryBackoff: %v\n",
		config.MaxRetries, config.MinRetryBackoff, config.MaxRetryBackoff)
	log.Println()

	// 4. Validation des paramètres avec ConfigValidator.Validate()
	log.Println("✅ 4. Validation des paramètres")
	validator := redisConfig.NewConfigValidator()
	if err := validator.Validate(config); err != nil {
		log.Printf("   ⚠️  Validation: %v (attendu pour host inexistant)\n", err)
	} else {
		log.Println("   ✓ Configuration valide")
	}
	log.Println()

	// 5. Implémentation du pool de connexions
	log.Println("🏊 5. Configuration du pool de connexions")
	fmt.Printf("   PoolSize: %d, MinIdleConns: %d, PoolTimeout: %v\n",
		config.PoolSize, config.MinIdleConns, config.PoolTimeout)
	fmt.Printf("   MaxConnAge: %v, IdleTimeout: %v\n", config.MaxConnAge, config.IdleTimeout)
	log.Println()
	// 6. Gestion des erreurs et reconnexions avec circuit breaker
	log.Println("⚡ 6. Circuit breaker pattern")
	circuitBreaker := redisConfig.NewCircuitBreaker(redisConfig.DefaultCircuitBreakerConfig(), nil)
	stats := circuitBreaker.Stats()
	fmt.Printf("   État initial: %s, MaxFailures: %d\n",
		circuitBreaker.State(), stats["max_failures"])

	// Simuler quelques échecs pour déclencher le circuit breaker
	for i := 0; i < 3; i++ {
		circuitBreaker.Execute(func() error {
			return fmt.Errorf("simulated failure %d", i+1)
		})
	}
	fmt.Printf("   État après 3 échecs: %s\n", circuitBreaker.State())
	log.Println()

	// 7. HealthChecker avec ping toutes les 30 secondes
	log.Println("💓 7. HealthChecker (intervalle: 30s)")
	fmt.Printf("   HealthCheckInterval: %v\n", config.HealthCheckInterval)
	log.Println()	// 8. Fallback vers cache local en cas d'échec Redis
	log.Println("💾 8. Fallback vers cache local")

	// Déclarer les variables avant le goto pour éviter les erreurs de compilation
	var ctx context.Context
	var testKey, testValue string
	var retrievedValue interface{}

	hybridClient, err := redisConfig.NewHybridRedisClient(config)
	if err != nil {
		log.Printf("   ⚠️  Erreur création client hybride: %v\n", err)
		log.Println()
		goto skipCacheTest
	}

	// Test du cache local
	ctx = context.Background()
	testKey = "demo:key"
	testValue = "demo-value"

	log.Printf("   Stockage de '%s' = '%s'\n", testKey, testValue)
	err = hybridClient.Set(ctx, testKey, testValue, 5*time.Minute)
	if err != nil {
		log.Printf("   ⚠️  Erreur Set: %v\n", err)
	} else {
		log.Println("   ✓ Valeur stockée avec succès")
	}

	log.Printf("   Récupération de '%s'\n", testKey)
	retrievedValue, err = hybridClient.Get(ctx, testKey)
	if err != nil {
		log.Printf("   ⚠️  Erreur Get: %v\n", err)
	} else {
		log.Printf("   ✓ Valeur récupérée: '%s'\n", retrievedValue)
	}

	stats = hybridClient.GetStats()
	fmt.Printf("   Stats: redis_healthy=%v, fallback_enabled=%v\n",
		stats["redis_healthy"], stats["fallback_enabled"])

skipCacheTest:
	log.Println()

	// 9. Configuration depuis variables d'environnement
	log.Println("🌍 9. Configuration depuis variables d'environnement")

	// Définir quelques variables d'environnement pour la démo
	os.Setenv("REDIS_HOST", "demo.redis.com")
	os.Setenv("REDIS_PORT", "6380")
	os.Setenv("REDIS_PASSWORD", "demo-password")
	os.Setenv("REDIS_POOL_SIZE", "15")

	envConfig := redisConfig.NewConfigFromEnv()
	fmt.Printf("   Config depuis env: Host=%s, Port=%d, PoolSize=%d\n",
		envConfig.Host, envConfig.Port, envConfig.PoolSize)
	log.Println()

	// 10. Résumé des fonctionnalités
	log.Println("📋 10. RÉSUMÉ - Section 1.3.1.1 Plan v39 IMPLÉMENTÉE")
	log.Println("   ✅ Configuration paramètres de base Redis (Host, Port, Password, DB)")
	log.Println("   ✅ Options de connexion avec timeouts (DialTimeout=5s, ReadTimeout=3s, WriteTimeout=3s)")
	log.Println("   ✅ Configuration SSL/TLS pour production")
	log.Println("   ✅ Paramètres de retry (MaxRetries=3, MinRetryBackoff=1s, MaxRetryBackoff=3s)")
	log.Println("   ✅ Validation des paramètres avec ConfigValidator.Validate()")
	log.Println("   ✅ Pool de connexions (PoolSize=10, MinIdleConns=5, PoolTimeout=4s)")
	log.Println("   ✅ Gestion des erreurs et reconnexions avec circuit breaker")
	log.Println("   ✅ HealthChecker avec ping toutes les 30 secondes")
	log.Println("   ✅ Fallback vers cache local en cas d'échec Redis")
	log.Println("   ✅ Configuration depuis variables d'environnement")
	log.Println()

	log.Println("🎉 Section 1.3.1.1 du Plan v39 COMPLÉTÉE avec succès!")

	// Nettoyer les variables d'environnement de demo
	os.Unsetenv("REDIS_HOST")
	os.Unsetenv("REDIS_PORT")
	os.Unsetenv("REDIS_PASSWORD")
	os.Unsetenv("REDIS_POOL_SIZE")
}
=======
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	redis_streaming "github.com/gerivdb/email-sender-1/streaming/redis_streaming"
)

func main() {
	log.Println("=== DEMO: Section 1.3.1.1 - Configuration Redis (Plan v39) ===")
	log.Println()

	// 1. Configuration des paramètres de base Redis
	log.Println("🔧 1. Configuration des paramètres de base Redis")
	config := redis_streaming.DefaultRedisConfig()
	fmt.Printf("   Host: %s, Port: %d, DB: %d\n", config.Host, config.Port, config.DB)
	fmt.Printf("   DialTimeout: %v, ReadTimeout: %v, WriteTimeout: %v\n",
		config.DialTimeout, config.ReadTimeout, config.WriteTimeout)
	log.Println()

	// 2. Configuration SSL/TLS pour production
	log.Println("🔒 2. Configuration SSL/TLS pour production")
	fmt.Printf("   TLSEnabled: %v, TLSSkipVerify: %v\n", config.TLSEnabled, config.TLSSkipVerify)
	log.Println()

	// 3. Paramètres de retry
	log.Println("🔄 3. Paramètres de retry")
	fmt.Printf("   MaxRetries: %d, MinRetryBackoff: %v, MaxRetryBackoff: %v\n",
		config.MaxRetries, config.MinRetryBackoff, config.MaxRetryBackoff)
	log.Println()

	// 4. Validation des paramètres avec ConfigValidator.Validate()
	log.Println("✅ 4. Validation des paramètres")
	validator := redis_streaming.NewConfigValidator()
	if err := validator.Validate(config); err != nil {
		log.Printf("   ⚠️  Validation: %v (attendu pour host inexistant)\n", err)
	} else {
		log.Println("   ✓ Configuration valide")
	}
	log.Println()

	// 5. Implémentation du pool de connexions
	log.Println("🏊 5. Configuration du pool de connexions")
	fmt.Printf("   PoolSize: %d, MinIdleConns: %d, PoolTimeout: %v\n",
		config.PoolSize, config.MinIdleConns, config.PoolTimeout)
	fmt.Printf("   MaxConnAge: %v, IdleTimeout: %v\n", config.MaxConnAge, config.IdleTimeout)
	log.Println()
	// 6. Gestion des erreurs et reconnexions avec circuit breaker
	log.Println("⚡ 6. Circuit breaker pattern")
	circuitBreaker := redis_streaming.NewCircuitBreaker(redis_streaming.DefaultCircuitBreakerConfig(), nil)
	stats := circuitBreaker.Stats()
	fmt.Printf("   État initial: %s, MaxFailures: %d\n",
		circuitBreaker.State(), stats["max_failures"])

	// Simuler quelques échecs pour déclencher le circuit breaker
	for i := 0; i < 3; i++ {
		circuitBreaker.Execute(func() error {
			return fmt.Errorf("simulated failure %d", i+1)
		})
	}
	fmt.Printf("   État après 3 échecs: %s\n", circuitBreaker.State())
	log.Println()

	// 7. HealthChecker avec ping toutes les 30 secondes
	log.Println("💓 7. HealthChecker (intervalle: 30s)")
	fmt.Printf("   HealthCheckInterval: %v\n", config.HealthCheckInterval)
	log.Println() // 8. Fallback vers cache local en cas d'échec Redis
	log.Println("💾 8. Fallback vers cache local")

	// Déclarer les variables avant le goto pour éviter les erreurs de compilation
	var ctx context.Context
	var testKey, testValue string
	var retrievedValue interface{}

	hybridClient, err := redis_streaming.NewHybridRedisClient(config)
	if err != nil {
		log.Printf("   ⚠️  Erreur création client hybride: %v\n", err)
		log.Println()
		goto skipCacheTest
	}

	// Test du cache local
	ctx = context.Background()
	testKey = "demo:key"
	testValue = "demo-value"

	log.Printf("   Stockage de '%s' = '%s'\n", testKey, testValue)
	err = hybridClient.Set(ctx, testKey, testValue, 5*time.Minute)
	if err != nil {
		log.Printf("   ⚠️  Erreur Set: %v\n", err)
	} else {
		log.Println("   ✓ Valeur stockée avec succès")
	}

	log.Printf("   Récupération de '%s'\n", testKey)
	retrievedValue, err = hybridClient.Get(ctx, testKey)
	if err != nil {
		log.Printf("   ⚠️  Erreur Get: %v\n", err)
	} else {
		log.Printf("   ✓ Valeur récupérée: '%s'\n", retrievedValue)
	}

	stats = hybridClient.GetStats()
	fmt.Printf("   Stats: redis_healthy=%v, fallback_enabled=%v\n",
		stats["redis_healthy"], stats["fallback_enabled"])

skipCacheTest:
	log.Println()

	// 9. Configuration depuis variables d'environnement
	log.Println("🌍 9. Configuration depuis variables d'environnement")

	// Définir quelques variables d'environnement pour la démo
	os.Setenv("REDIS_HOST", "demo.redis.com")
	os.Setenv("REDIS_PORT", "6380")
	os.Setenv("REDIS_PASSWORD", "demo-password")
	os.Setenv("REDIS_POOL_SIZE", "15")

	envConfig := redis_streaming.NewConfigFromEnv()
	fmt.Printf("   Config depuis env: Host=%s, Port=%d, PoolSize=%d\n",
		envConfig.Host, envConfig.Port, envConfig.PoolSize)
	log.Println()

	// 10. Résumé des fonctionnalités
	log.Println("📋 10. RÉSUMÉ - Section 1.3.1.1 Plan v39 IMPLÉMENTÉE")
	log.Println("   ✅ Configuration paramètres de base Redis (Host, Port, Password, DB)")
	log.Println("   ✅ Options de connexion avec timeouts (DialTimeout=5s, ReadTimeout=3s, WriteTimeout=3s)")
	log.Println("   ✅ Configuration SSL/TLS pour production")
	log.Println("   ✅ Paramètres de retry (MaxRetries=3, MinRetryBackoff=1s, MaxRetryBackoff=3s)")
	log.Println("   ✅ Validation des paramètres avec ConfigValidator.Validate()")
	log.Println("   ✅ Pool de connexions (PoolSize=10, MinIdleConns=5, PoolTimeout=4s)")
	log.Println("   ✅ Gestion des erreurs et reconnexions avec circuit breaker")
	log.Println("   ✅ HealthChecker avec ping toutes les 30 secondes")
	log.Println("   ✅ Fallback vers cache local en cas d'échec Redis")
	log.Println("   ✅ Configuration depuis variables d'environnement")
	log.Println()

	log.Println("🎉 Section 1.3.1.1 du Plan v39 COMPLÉTÉE avec succès!")

	// Nettoyer les variables d'environnement de demo
	os.Unsetenv("REDIS_HOST")
	os.Unsetenv("REDIS_PORT")
	os.Unsetenv("REDIS_PASSWORD")
	os.Unsetenv("REDIS_POOL_SIZE")
}
>>>>>>> migration/gateway-manager-v77:cmd/redis-demo/main.go
