# Matrice d'Estimation d'Effort

Ce document présente une matrice d'estimation d'effort pour les améliorations logicielles. Cette matrice combine les facteurs de complexité, les niveaux de complexité technique et les métriques de ressources pour fournir une estimation globale de l'effort requis.

## Principe de la Matrice

La matrice d'estimation d'effort est un outil qui permet de calculer l'effort total requis pour une amélioration en fonction de plusieurs dimensions :

1. **Complexité technique** : Basée sur les facteurs identifiés dans le document [Facteurs Influençant la Complexité](complexity-factors.md)
2. **Ressources humaines** : Basées sur les métriques définies dans le document [Métriques pour l'Estimation des Ressources](resource-metrics.md)
3. **Durée** : Estimation du temps nécessaire pour l'implémentation

## Structure de la Matrice

La matrice est structurée selon trois axes principaux :

1. **Axe horizontal** : Niveaux de complexité technique (1 à 5)
2. **Axe vertical** : Taille de l'équipe (1 à 5+)
3. **Cellules** : Effort estimé en jours-personnes

## Matrice d'Estimation d'Effort (en jours-personnes)

| Taille de l'équipe | Complexité 1 (Très faible) | Complexité 2 (Faible) | Complexité 3 (Moyen) | Complexité 4 (Élevé) | Complexité 5 (Très élevé) |
|-------------------|---------------------------|----------------------|---------------------|---------------------|--------------------------|
| 1 personne        | 1-2                       | 3-5                  | 6-10                | N/A                 | N/A                      |
| 2-3 personnes     | 2-4                       | 5-10                 | 11-20               | 21-40               | N/A                      |
| 4-5 personnes     | N/A                       | 10-15                | 16-30               | 31-60               | 61-90                    |
| 6-8 personnes     | N/A                       | N/A                  | 25-45               | 46-80               | 81-120                   |
| 9+ personnes      | N/A                       | N/A                  | N/A                 | 70-100              | 101-200+                 |

*Note : "N/A" indique une combinaison non applicable ou inefficace (par exemple, une équipe trop grande pour une complexité faible ou une équipe trop petite pour une complexité élevée).*

## Facteurs d'Ajustement

L'estimation de base fournie par la matrice peut être ajustée en fonction de facteurs spécifiques :

| Facteur d'ajustement | Impact | Multiplicateur |
|----------------------|--------|---------------|
| Expertise élevée de l'équipe | Réduction de l'effort | 0.8 |
| Expertise faible de l'équipe | Augmentation de l'effort | 1.3 |
| Familiarité élevée avec le domaine | Réduction de l'effort | 0.9 |
| Familiarité faible avec le domaine | Augmentation de l'effort | 1.2 |
| Technologies bien maîtrisées | Réduction de l'effort | 0.9 |
| Technologies nouvelles | Augmentation de l'effort | 1.4 |
| Documentation existante de qualité | Réduction de l'effort | 0.9 |
| Documentation inexistante ou obsolète | Augmentation de l'effort | 1.2 |
| Contraintes organisationnelles fortes | Augmentation de l'effort | 1.3 |
| Dépendances externes nombreuses | Augmentation de l'effort | 1.3 |

## Formule de Calcul

L'effort total estimé peut être calculé selon la formule suivante :

```
Effort total = Effort de base × Multiplicateur 1 × Multiplicateur 2 × ... × Multiplicateur n
```

Où :
- Effort de base est la valeur issue de la matrice d'estimation
- Multiplicateur 1, 2, ..., n sont les facteurs d'ajustement applicables

## Exemples d'Application

### Exemple 1 : Amélioration de complexité faible

**Caractéristiques :**
- Complexité technique : 2 (Faible)
- Taille de l'équipe : 1 personne
- Facteurs d'ajustement : Expertise élevée (0.8), Technologies bien maîtrisées (0.9)

**Calcul :**
- Effort de base : 3-5 jours-personnes
- Effort ajusté : 3-5 × 0.8 × 0.9 = 2.16-3.6 jours-personnes
- Estimation finale : 2-4 jours-personnes

### Exemple 2 : Amélioration de complexité moyenne

**Caractéristiques :**
- Complexité technique : 3 (Moyen)
- Taille de l'équipe : 2-3 personnes
- Facteurs d'ajustement : Familiarité faible avec le domaine (1.2), Documentation inexistante (1.2)

**Calcul :**
- Effort de base : 11-20 jours-personnes
- Effort ajusté : 11-20 × 1.2 × 1.2 = 15.84-28.8 jours-personnes
- Estimation finale : 16-29 jours-personnes

### Exemple 3 : Amélioration de complexité élevée

**Caractéristiques :**
- Complexité technique : 4 (Élevé)
- Taille de l'équipe : 4-5 personnes
- Facteurs d'ajustement : Technologies nouvelles (1.4), Dépendances externes nombreuses (1.3)

**Calcul :**
- Effort de base : 31-60 jours-personnes
- Effort ajusté : 31-60 × 1.4 × 1.3 = 56.42-109.2 jours-personnes
- Estimation finale : 56-109 jours-personnes

## Conversion en Durée Calendaire

Pour convertir l'effort en jours-personnes en durée calendaire, on peut utiliser la formule suivante :

```
Durée calendaire = Effort total / (Nombre de personnes × Productivité)
```

Où :
- Nombre de personnes est le nombre de personnes travaillant simultanément sur l'amélioration
- Productivité est un facteur qui tient compte du temps effectif de travail (généralement entre 0.6 et 0.8)

### Exemple de Conversion

Pour une amélioration nécessitant 20 jours-personnes avec une équipe de 4 personnes et une productivité de 0.7 :

```
Durée calendaire = 20 / (4 × 0.7) = 7.14 jours
```

## Considérations Importantes

- **Fourchettes d'estimation** : Les estimations sont fournies sous forme de fourchettes pour refléter l'incertitude inhérente à l'estimation d'effort.
- **Révision régulière** : La matrice d'estimation doit être révisée régulièrement en fonction des retours d'expérience.
- **Contexte spécifique** : La matrice doit être adaptée au contexte spécifique de l'organisation et du projet.
- **Combinaison avec d'autres méthodes** : La matrice peut être combinée avec d'autres méthodes d'estimation (comme le Planning Poker ou les points de story) pour obtenir des estimations plus précises.
- **Transparence** : Les hypothèses et les méthodes utilisées pour les estimations doivent être clairement documentées.

## Limites de la Matrice

- La matrice ne prend pas en compte tous les facteurs qui peuvent influencer l'effort (comme les facteurs humains ou organisationnels).
- Les estimations sont basées sur des moyennes et peuvent varier significativement en fonction des individus et des équipes.
- La matrice ne remplace pas l'expertise et le jugement des personnes impliquées dans l'estimation.

## Processus d'Utilisation Recommandé

1. **Évaluation de la complexité** : Évaluer la complexité technique de l'amélioration selon les critères définis dans le document [Niveaux de Complexité Technique](complexity-levels.md).
2. **Détermination de la taille de l'équipe** : Déterminer la taille de l'équipe nécessaire en fonction de la complexité et des contraintes du projet.
3. **Consultation de la matrice** : Consulter la matrice pour obtenir l'effort de base en jours-personnes.
4. **Identification des facteurs d'ajustement** : Identifier les facteurs d'ajustement applicables.
5. **Calcul de l'effort ajusté** : Calculer l'effort ajusté en appliquant les facteurs d'ajustement.
6. **Conversion en durée calendaire** : Convertir l'effort en durée calendaire si nécessaire.
7. **Documentation** : Documenter les estimations et leurs justifications.
8. **Révision** : Réviser les estimations après l'implémentation pour améliorer les futures estimations.
