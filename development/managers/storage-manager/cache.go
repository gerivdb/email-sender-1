package storage

// Cache operations

func (sm *StorageManagerImpl) setCache(key string, value interface{}) {
	sm.cacheMutex.Lock()
	defer sm.cacheMutex.Unlock()
	sm.cache[key] = value
}

func (sm *StorageManagerImpl) getCache(key string) interface{} {
	sm.cacheMutex.RLock()
	defer sm.cacheMutex.RUnlock()
	return sm.cache[key]
}

func (sm *StorageManagerImpl) deleteCache(key string) {
	sm.cacheMutex.Lock()
	defer sm.cacheMutex.Unlock()
	delete(sm.cache, key)
}

func (sm *StorageManagerImpl) clearCache() {
	sm.cacheMutex.Lock()
	defer sm.cacheMutex.Unlock()
	sm.cache = make(map[string]interface{})
}
