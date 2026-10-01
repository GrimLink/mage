MAGE_CLEAN_HANDLERS+=("redis|Clear the Redis caches of this project")

# How depends on the environment, a shared Redis is cleaned by the cache prefixes
function mage_clean_redis() {
  env_call clean_redis
}
