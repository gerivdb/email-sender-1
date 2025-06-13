# Workflow N8N "Email Sender 1" - Gestion Automatisée de Booking de Concerts

## Table des matières

1. [Workflow N8N "Email Sender 1" - Gestion Automatisée de Booking de Concerts](#section-1)

    1.1. [Vision Globale](#section-2)

        1.1.1. [. Gestion des Disponibilités](#section-3)

        1.1.2. [. Prospection et Campagne d'Emailing](#section-4)

        1.1.3. [. Suivi et Gestion des Réponses](#section-5)

        1.1.4. [. Phase de Négociation](#section-6)

        1.1.5. [. Confirmation et Planification (DEAL)](#section-7)

        1.1.6. [. Logistique Pré-Concert](#section-8)

        1.1.7. [. Rappels Concert](#section-9)

        1.1.8. [. Suivi Post-Concert](#section-10)

        1.1.9. [. Feedback et Analyse](#section-11)

    1.2. [Architecture Technique](#section-12)

    1.3. [Objectifs Futurs](#section-13)

    1.4. [Points d'Amélioration Potentiels](#section-14)

## 1. Workflow N8N "Email Sender 1" - Gestion Automatisée de Booking de Concerts <a name='section-1'></a>

### 1.1. Vision Globale <a name='section-2'></a>

Ce workflow N8N vise à automatiser l'ensemble du processus de booking de concerts pour le groupe Gribitch, depuis la prospection initiale jusqu'au suivi post-concert. Il orchestre les interactions entre plusieurs plateformes (Notion, Google Agenda, Gmail, Signal) pour créer un système cohérent et efficace de gestion des concerts.

#### 1.1.1. . Gestion des Disponibilités <a name='section-3'></a>

- **Collecte des indisponibilités** des musiciens depuis:
  - Base Notion "Dispo Membres" (saisie manuelle)
  - Google Agenda personnel des musiciens
- **Synchronisation bidirectionnelle** entre ces sources
- **Calcul automatique des plages disponibles** (priorité aux vendredis/samedis)
- **Stockage centralisé** des disponibilités pour référence future

#### 1.1.2. . Prospection et Campagne d'Emailing <a name='section-4'></a>

- **Source de contacts**: Base Notion "LOT1" (programmateurs/lieux)
- **Préparation des emails**:
  - Utilisation d'un template Gmail réutilisable
  - Injection des plages disponibles calculées
  - Personnalisation du contenu via DeepSeek (OpenRouter)
- **Stratégie d'envoi**:
  - Délais variables entre envois (30-60 min)
  - Variation des messages pour éviter la détection de spam
  - Suivi des envois dans Notion (mise à jour des statuts)

#### 1.1.3. . Suivi et Gestion des Réponses <a name='section-5'></a>

- **Surveillance automatique** de la boîte de réception
- **Notifications** par email et/ou Signal dès réception d'une réponse
- **Analyse du contenu** des réponses via DeepSeek pour déterminer:
  - Réponse favorable → statut "Négo"
  - Réponse défavorable → statut "Refus"
  - Réponse ambiguë → statut "À clarifier"
- **Mise à jour automatique** des statuts dans Notion

#### 1.1.4. . Phase de Négociation <a name='section-6'></a>

- Phase principalement manuelle (complexe à automatiser)
- **Critères à aligner**:
  - Exigences du groupe
  - Contraintes du lieu
  - Disponibilités confirmées
- **Validation manuelle** pour passage à l'étape suivante

#### 1.1.5. . Confirmation et Planification (DEAL) <a name='section-7'></a>

- **Déclencheur**: Validation manuelle du "bon pour accord"
- **Actions automatiques**:
  - Changement du statut dans Notion à "DEAL"
  - Création d'un événement dans Google Agenda "BOOKING1"
  - Création/mise à jour d'un enregistrement dans Notion Agenda
  - Synchronisation entre Google Agenda et Notion

#### 1.1.6. . Logistique Pré-Concert <a name='section-8'></a>

- **Rappel J-10** via Signal au manager pour initier le contact avec la régie
- **Gestion manuelle** des détails logistiques:
  - Hébergement
  - Catering
  - Backline
  - Fiches techniques
- **Validation manuelle** de la finalisation logistique

#### 1.1.7. . Rappels Concert <a name='section-9'></a>

- **Notifications automatiques**:
  - J-3 et J-1 (surtout pour concerts uniques ou débuts de tournée)
  - Soir du concert: rappel à toute l'équipe avec adresse d'hébergement et heure de réveil

#### 1.1.8. . Suivi Post-Concert <a name='section-10'></a>

- **Email de remerciement automatique** (J+1):
  - Généré via DeepSeek
  - Personnalisé avec image du groupe
  - Inclusion des prénoms de l'équipe du lieu (depuis base Notion)
- **Suivi du paiement**:
  - Mise à jour du statut dans Notion dès réception

#### 1.1.9. . Feedback et Analyse <a name='section-11'></a>

- **Évaluation** du succès du concert et de la relation avec le lieu
- **Décision** sur la pertinence d'une future collaboration
- **Archivage** des informations pour référence future

### 1.2. Architecture Technique <a name='section-12'></a>

- **N8N**: Orchestrateur central du workflow
- **Notion**: Bases de données principales
  - LOT1: Contacts programmateurs
  - Dispo Membres: Disponibilités des musiciens
  - bdd-Lieux: Informations sur les lieux de concert
- **Google Agenda**: Planification et rappels
- **Gmail**: Communication avec les programmateurs
- **Signal**: Notifications critiques
- **OpenRouter (DeepSeek)**: Génération et analyse de contenu

### 1.3. Objectifs Futurs <a name='section-13'></a>

- **Réutilisation** du workflow pour de nouvelles campagnes (LOT2, etc.)
- **Planification à long terme** (2-4 ans à l'avance)
- **Visualisation** de l'avancement via les vues dynamiques de Notion
- **Intégration future** avec les réseaux sociaux (Facebook, Instagram)

### 1.4. Points d'Amélioration Potentiels <a name='section-14'></a>

- Automatisation partielle de la phase de négociation
- Intégration de la publication sur réseaux sociaux (avec étape manuelle pour les images récentes)
- Système de feedback standardisé post-concert
- Automatisation de la mise à jour du statut "Payé"

---

Ce workflow représente une solution complète de gestion de booking, conçue pour optimiser le temps et les ressources du groupe tout en maintenant une communication professionnelle et personnalisée avec les programmateurs.

