# Transitions

Cette page décrit les transitions disponibles dans le système de journal de bord RAG.

## Transitions de base

### Fade

La transition `fade` fait apparaître/disparaître un élément en modifiant son opacité.

```css
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
```plaintext
Utilisation:

```html
<transition name="fade">
  <div v-if="show">Contenu</div>
</transition>
```plaintext
### Slide

Les transitions `slide-up`, `slide-down`, `slide-left` et `slide-right` font glisser un élément dans la direction spécifiée.

```css
.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(20px);
  opacity: 0;
}
```plaintext
Utilisation:

```html
<transition name="slide-up">
  <div v-if="show">Contenu</div>
</transition>
```plaintext
### Scale

La transition `scale` agrandit/réduit un élément.

```css
.scale-enter-active,
.scale-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}

.scale-enter-from,
.scale-leave-to {
  transform: scale(0.95);
  opacity: 0;
}
```plaintext
Utilisation:

```html
<transition name="scale">
  <div v-if="show">Contenu</div>
</transition>
```plaintext
## Transitions de page

La transition `page` est utilisée pour les transitions entre les pages.

```css
.page-enter-active,
.page-leave-active {
  transition: opacity 0.3s, transform 0.3s;
}

.page-enter-from {
  opacity: 0;
  transform: translateX(10px);
}

.page-leave-to {
  opacity: 0;
  transform: translateX(-10px);
}
```plaintext
Utilisation:

```html
<router-view v-slot="{ Component }">
  <transition name="page" mode="out-in">
    <component :is="Component" />
  </transition>
</router-view>
```plaintext
## Transitions de liste

La transition `staggered-list` est utilisée pour les listes avec un effet décalé.

```css
.staggered-list-item {
  transition: all 0.3s;
}

.staggered-list-enter-active {
  transition-delay: calc(0.05s * var(--i));
}

.staggered-list-leave-active {
  transition-delay: calc(0.05s * var(--i));
}

.staggered-list-enter-from,
.staggered-list-leave-to {
  opacity: 0;
  transform: translateY(15px);
}
```plaintext
Utilisation:

```html
<transition-group name="staggered-list" tag="ul">
  <li v-for="(item, index) in items" :key="item.id" class="staggered-list-item" :style="{ '--i': index }">
    {{ item.name }}
  </li>
</transition-group>
```plaintext
## Transitions de filtre

La transition `filter` est utilisée pour les panneaux de filtrage.

```css
.filter-transition {
  transition: max-height 0.3s ease, opacity 0.3s ease, transform 0.3s ease;
}

.filter-enter-from,
.filter-leave-to {
  max-height: 0;
  opacity: 0;
  transform: translateY(-10px);
}

.filter-enter-to,
.filter-leave-from {
  max-height: 500px;
  opacity: 1;
  transform: translateY(0);
}
```plaintext
Utilisation:

```html
<transition name="filter">
  <div v-if="showFilters" class="filter-panel">
    Contenu du filtre
  </div>
</transition>
```plaintext
## Transitions d'accordéon

La transition `accordion` est utilisée pour les panneaux d'accordéon.

```css
.accordion-content {
  transition: max-height 0.3s ease, opacity 0.3s ease;
  overflow: hidden;
}

.accordion-enter-from,
.accordion-leave-to {
  max-height: 0;
  opacity: 0;
}

.accordion-enter-to,
.accordion-leave-from {
  max-height: 1000px;
  opacity: 1;
}
```plaintext
Utilisation:

```html
<div class="accordion-item">
  <div class="accordion-header" @click="toggle">
    Titre
  </div>
  <transition name="accordion">
    <div v-if="isOpen" class="accordion-content">
      Contenu
    </div>
  </transition>
</div>
```plaintext
## Transitions de notification

La transition `notification` est utilisée pour les notifications.

```css
@keyframes slideIn {
  0% {
    transform: translateX(100%);
    opacity: 0;
  }
  100% {
    transform: translateX(0);
    opacity: 1;
  }
}

@keyframes slideOut {
  0% {
    transform: translateX(0);
    opacity: 1;
  }
  100% {
    transform: translateX(100%);
    opacity: 0;
  }
}

.notification-enter-active {
  animation: slideIn 0.3s ease forwards;
}

.notification-leave-active {
  animation: slideOut 0.3s ease forwards;
}
```plaintext
Utilisation:

```html
<transition-group name="notification">
  <div v-for="notification in notifications" :key="notification.id" class="notification">
    {{ notification.message }}
  </div>
</transition-group>
```plaintext
## Transitions de tooltip

La transition `tooltip` est utilisée pour les tooltips.

```css
.tooltip {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.tooltip-enter-from,
.tooltip-leave-to {
  opacity: 0;
  transform: translateY(5px);
}
```plaintext
Utilisation:

```html
<transition name="tooltip">
  <div v-if="showTooltip" class="tooltip">
    Contenu du tooltip
  </div>
</transition>
```plaintext
## Transitions de tab

La transition `tab` est utilisée pour les onglets.

```css
.tab-content {
  transition: opacity 0.3s ease, transform 0.3s ease;
}

.tab-enter-from,
.tab-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
```plaintext
Utilisation:

```html
<div class="tabs">
  <div class="tab-headers">
    <div v-for="tab in tabs" :key="tab.id" class="tab-header" @click="selectTab(tab.id)">
      {{ tab.name }}
    </div>
  </div>
  <transition name="tab" mode="out-in">
    <div :key="selectedTab" class="tab-content">
      Contenu de l'onglet
    </div>
  </transition>
</div>
```plaintext