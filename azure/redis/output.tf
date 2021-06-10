# -
# - Redis Cache
# -

output "redis_cache" {
  description = "Map output of the Redis Cache"
  value       = { for k, b in azurerm_redis_cache.redis1 : k => b }
}