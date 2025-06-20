// SPDX-License-Identifier: MIT
// Package i18n : gestion de l’internationalisation (v65)
package i18n

import (
	"sync"
)

// Translator gère les traductions multi-langues
type Translator struct {
	locales     map[string]*Locale
	defaultLang string
	detector    *LanguageDetector
	mu          sync.RWMutex
}

// Locale structure pour une langue donnée
type Locale struct {
	Messages map[string]string
}

// LanguageDetector détecte la langue utilisateur
type LanguageDetector struct{}

// LocalizedMessage message localisé avec arguments
type LocalizedMessage struct {
	Key     string
	Default string
	Args    map[string]string
}

// T retourne la traduction pour une clé et une langue
func (t *Translator) T(lang, key string, args ...interface{}) string {
	t.mu.RLock()
	defer t.mu.RUnlock()
	locale, ok := t.locales[lang]
	if !ok {
		locale = t.locales[t.defaultLang]
	}
	if translation, exists := locale.Messages[key]; exists {
		return translation // TODO: gestion des arguments
	}
	return key
}
