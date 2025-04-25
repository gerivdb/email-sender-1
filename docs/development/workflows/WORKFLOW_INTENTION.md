# Workflow N8N "Email Sender 1" - Gestion Automatisée de Booking de Concerts

## Vision Globale

Ce workflow N8N vise à automatiser l'ensemble du processus de booking de concerts pour le groupe Gribitch, depuis la prospection initiale jusqu'au suivi post-concert. Il orchestre les interactions entre plusieurs plateformes (Notion, Google Agenda, Gmail, Signal) pour créer un système cohérent et efficace de gestion des concerts.

## Phases du Workflow

### 1. Gestion des Disponibilités

- **Collecte des indisponibilités** des musiciens depuis:
  - Base Notion "Dispo Membres" (saisie manuelle)
  - Google Agenda personnel des musiciens
- **Synchronisation bidirectionnelle** entre ces sources
- **Calcul automatique des plages disponibles** (priorité aux vendredis/samedis)
- **Stockage centralisé** des disponibilités pour référence future

### 2. Prospection et Campagne d'Emailing

- **Source de contacts**: Base Notion "LOT1" (programmateurs/lieux)
- **Préparation des emails**:
  - Utilisation d'un template Gmail réutilisable
  - Injection des plages disponibles calculées
  - Personnalisation du contenu via DeepSeek (OpenRouter)
- **Stratégie d'envoi**:
  - Délais variables entre envois (30-60 min)
  - Variation des messages pour éviter la détection de spam
  - Suivi des envois dans Notion (mise à jour des statuts)

### 3. Suivi et Gestion des Réponses

- **Surveillance automatique** de la boîte de réception
- **Notifications** par email et/ou Signal dès réception d'une réponse
- **Analyse du contenu** des réponses via DeepSeek pour déterminer:
  - Réponse favorable → statut "Négo"
  - Réponse défavorable → statut "Refus"
  - Réponse ambiguë → statut "À clarifier"
- **Mise à jour automatique** des statuts dans Notion

### 4. Phase de Négociation

- Phase principalement manuelle (complexe à automatiser)
- **Critères à aligner**:
  - Exigences du groupe
  - Contraintes du lieu
  - Disponibilités confirmées
- **Validation manuelle** pour passage à l'étape suivante

### 5. Confirmation et Planification (DEAL)

- **Déclencheur**: Validation manuelle du "bon pour accord"
- **Actions automatiques**:
  - Changement du statut dans Notion à "DEAL"
  - Création d'un événement dans Google Agenda "BOOKING1"
  - Création/mise à jour d'un enregistrement dans Notion Agenda
  - Synchronisation entre Google Agenda et Notion

### 6. Logistique Pré-Concert

- **Rappel J-10** via Signal au manager pour initier le contact avec la régie
- **Gestion manuelle** des détails logistiques:
  - Hébergement
  - Catering
  - Backline
  - Fiches techniques
- **Validation manuelle** de la finalisation logistique

### 7. Rappels Concert

- **Notifications automatiques**:
  - J-3 et J-1 (surtout pour concerts uniques ou débuts de tournée)
  - Soir du concert: rappel à toute l'équipe avec adresse d'hébergement et heure de réveil

### 8. Suivi Post-Concert

- **Email de remerciement automatique** (J+1):
  - Généré via DeepSeek
  - Personnalisé avec image du groupe
  - Inclusion des prénoms de l'équipe du lieu (depuis base Notion)
- **Suivi du paiement**:
  - Mise à jour du statut dans Notion dès réception

### 9. Feedback et Analyse

- **Évaluation** du succès du concert et de la relation avec le lieu
- **Décision** sur la pertinence d'une future collaboration
- **Archivage** des informations pour référence future

## Architecture Technique

- **N8N**: Orchestrateur central du workflow
- **Notion**: Bases de données principales
  - LOT1: Contacts programmateurs
  - Dispo Membres: Disponibilités des musiciens
  - bdd-Lieux: Informations sur les lieux de concert
- **Google Agenda**: Planification et rappels
- **Gmail**: Communication avec les programmateurs
- **Signal**: Notifications critiques
- **OpenRouter (DeepSeek)**: Génération et analyse de contenu

## Objectifs Futurs

- **Réutilisation** du workflow pour de nouvelles campagnes (LOT2, etc.)
- **Planification à long terme** (2-4 ans à l'avance)
- **Visualisation** de l'avancement via les vues dynamiques de Notion
- **Intégration future** avec les réseaux sociaux (Facebook, Instagram)

## Points d'Amélioration Potentiels

- Automatisation partielle de la phase de négociation
- Intégration de la publication sur réseaux sociaux (avec étape manuelle pour les images récentes)
- Système de feedback standardisé post-concert
- Automatisation de la mise à jour du statut "Payé"

---

Ce workflow représente une solution complète de gestion de booking, conçue pour optimiser le temps et les ressources du groupe tout en maintenant une communication professionnelle et personnalisée avec les programmateurs.
