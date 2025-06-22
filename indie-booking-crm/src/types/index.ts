// Types pour IndieBooking CRM

export type UserRole = 
  | 'apporteur_affaires'
  | 'booker_agent' 
  | 'charge_diffusion'
  | 'tourneur_manager'
  | 'label_management'
  | 'programmateur_promoteur'
  | 'attache_presse'
  | 'regisseur_general';

export type DealStatus = 
  | 'prospect'
  | 'offre'
  | 'negotiation'
  | 'confirme'
  | 'signe'
  | 'termine';

export type ContactType = 
  | 'venue'
  | 'agent'
  | 'promoteur'
  | 'label'
  | 'media'
  | 'artiste'
  | 'fournisseur';

export type PriorityLevel = 'low' | 'medium' | 'high' | 'urgent';

export type TaskStatus = 'todo' | 'in_progress' | 'completed' | 'cancelled';

// Interface pour les contacts
export interface Contact {
  id: string;
  nom: string;
  prenom?: string;
  entreprise: string;
  role: ContactType;
  email: string;
  telephone?: string;
  ville: string;
  pays: string;
  adresse?: string;
  site_web?: string;
  capacite?: number; // Pour les venues
  genre_musical?: string[];
  tags: string[];
  notes?: string;
  dernier_contact?: string;
  prochaine_action?: string;
  created_at: string;
  updated_at: string;
}

// Interface pour les deals
export interface Deal {
  id: string;
  titre: string;
  artiste: string;
  venue: string;
  contact_id: string;
  status: DealStatus;
  date_show?: string;
  fee_artistique: number;
  commission_pourcentage: number;
  commission_montant: number;
  budget_total?: number;
  priority: PriorityLevel;
  description?: string;
  notes?: string;
  documents?: string[];
  created_at: string;
  updated_at: string;
  date_limite?: string;
}

// Interface pour les tâches
export interface Task {
  id: string;
  titre: string;
  description?: string;
  assignee_role: UserRole;
  status: TaskStatus;
  priority: PriorityLevel;
  due_date?: string;
  deal_id?: string;
  contact_id?: string;
  created_at: string;
  updated_at: string;
}

// Interface pour les événements de tournée
export interface TourEvent {
  id: string;
  date: string;
  venue: string;
  ville: string;
  pays: string;
  fee: number;
  statut: DealStatus;
  contact_id: string;
  deal_id?: string;
  notes?: string;
}

// Interface pour les packages de tournée
export interface TourPackage {
  id: string;
  nom: string;
  artiste: string;
  date_debut: string;
  date_fin: string;
  events: TourEvent[];
  budget_transport: number;
  budget_hebergement: number;
  budget_per_diem: number;
  total_fees: number;
  profit_prevu: number;
  status: 'planification' | 'confirme' | 'en_cours' | 'termine';
}

// Interface pour les factures
export interface Invoice {
  id: string;
  numero: string;
  client: string;
  montant: number;
  tva: number;
  total: number;
  date_emission: string;
  date_echeance: string;
  status: 'brouillon' | 'envoye' | 'paye' | 'en_retard';
  deal_id?: string;
  description: string;
}

// Interface pour les contacts média
export interface MediaContact {
  id: string;
  nom: string;
  media: string;
  type: 'presse' | 'radio' | 'tv' | 'blog' | 'podcast';
  email: string;
  telephone?: string;
  specialite?: string[];
  derniere_interaction?: string;
  status_outreach: 'jamais_contacte' | 'contacte' | 'interesse' | 'decline' | 'collabore';
  notes?: string;
}

// Interface pour les KPIs du dashboard
export interface DashboardKPI {
  prochains_shows: number;
  deals_en_negociation: number;
  ca_ytd: number;
  taches_dues: number;
}

// Interface pour les statistiques par rôle
export interface RoleStats {
  role: UserRole;
  deals_actifs: number;
  ca_prevu: number;
  taches_en_cours: number;
  contacts_actifs: number;
}

// Interface pour la configuration utilisateur
export interface UserConfig {
  id: string;
  nom: string;
  email: string;
  role: UserRole;
  preferences: {
    langue: 'fr' | 'en';
    notifications: boolean;
    dashboard_layout: string[];
    filters_defaults: Record<string, any>;
  };
}

// Interface pour les filtres
export interface ContactFilters {
  search?: string;
  role?: ContactType[];
  pays?: string[];
  tags?: string[];
  dernier_contact_depuis?: number; // jours
}

export interface DealFilters {
  search?: string;
  status?: DealStatus[];
  priority?: PriorityLevel[];
  artiste?: string[];
  date_debut?: string;
  date_fin?: string;
}

// Types pour les options de navigation
export interface NavItem {
  id: string;
  label: string;
  icon: string;
  path: string;
  roles?: UserRole[]; // Rôles autorisés à voir cet élément
  badge?: number; // Nombre pour badge de notification
}

// Interface pour les actions rapides
export interface QuickAction {
  id: string;
  label: string;
  icon: string;
  action: () => void;
  roles?: UserRole[];
}
