# Animations et Transitions

## Introduction

Les animations et transitions améliorent l'expérience utilisateur en rendant l'interface plus fluide et plus intuitive. Cette documentation décrit les animations et transitions implémentées dans le système de journal de bord RAG.

## Fichier d'animations

Le fichier `frontend/src/assets/css/animations.css` contient toutes les animations et transitions utilisées dans l'application. Ce fichier est importé dans `main.js` pour être disponible globalement.

## Types d'animations

### Transitions de base

- **Fade**: Transition d'opacité pour faire apparaître/disparaître des éléments
- **Slide**: Transition de position pour faire glisser des éléments
- **Scale**: Transition de taille pour agrandir/réduire des éléments

### Animations continues

- **Bounce**: Animation de rebond pour attirer l'attention
- **Pulse**: Animation de pulsation pour mettre en évidence
- **Spin**: Animation de rotation pour les indicateurs de chargement
- **Shimmer**: Animation de scintillement pour les états de chargement

### Effets de survol

- **Hover Lift**: Effet de soulèvement au survol
- **Hover Scale**: Effet d'agrandissement au survol
- **Button Pulse**: Effet de pulsation pour les boutons

### Animations de page

- **Page Transitions**: Transitions entre les pages
- **Staggered List**: Animation décalée pour les listes

## Utilisation

### Transitions Vue

Pour utiliser les transitions avec Vue.js:

```html
<transition name="fade">
  <div v-if="show">Contenu</div>
</transition>
```plaintext
### Classes CSS

Pour utiliser les animations avec des classes CSS:

```html
<div class="spin">Chargement...</div>
<div class="hover-lift">Survol moi</div>
```plaintext
### Animations JavaScript

Pour utiliser les animations avec JavaScript:

```javascript
// Ajouter une classe d'animation
element.classList.add('bounce')

// Supprimer une classe d'animation
element.classList.remove('bounce')

// Ajouter une classe d'animation temporairement
element.classList.add('shake')
setTimeout(() => {
  element.classList.remove('shake')
}, 1000)
```plaintext
## Exemples d'utilisation

### Transition de chargement

```html
<transition name="fade" mode="out-in">
  <div v-if="loading" class="loading-state">
    <i class="fas fa-spinner fa-spin"></i>
    <p>Chargement...</p>
  </div>
  <div v-else class="content">
    Contenu chargé
  </div>
</transition>
```plaintext
### Animation de liste

```html
<transition-group name="staggered-list" tag="ul">
  <li v-for="(item, index) in items" :key="item.id" class="staggered-list-item" :style="{ '--i': index }">
    {{ item.name }}
  </li>
</transition-group>
```plaintext
### Animation de bouton

```html
<button class="btn-pulse" @click="submit">
  Soumettre
</button>
```plaintext
## Performance

Pour optimiser les performances des animations:

- Utilisez les propriétés `transform` et `opacity` qui sont accélérées par le GPU
- Évitez d'animer des propriétés qui déclenchent des reflows (layout, paint)
- Utilisez `will-change` pour les animations complexes
- Désactivez les animations pour les utilisateurs qui préfèrent les mouvements réduits

## Accessibilité

Pour garantir l'accessibilité des animations:

- Respectez la préférence `prefers-reduced-motion`
- Évitez les animations clignotantes qui peuvent déclencher des crises d'épilepsie
- Assurez-vous que l'interface reste utilisable sans animations

## Personnalisation

Les animations peuvent être personnalisées en modifiant le fichier `animations.css`. Vous pouvez ajuster:

- La durée des animations
- Le timing des animations
- L'amplitude des animations
- Les couleurs et les effets
