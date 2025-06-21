package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"

	_ "github.com/lib/pq"
)

// UserManager gère les utilisateurs
type UserManager struct {
	db *sql.DB
}

// NewUserManager crée un nouveau gestionnaire d'utilisateurs
func NewUserManager(dbURL string) (*UserManager, error) {
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	return &UserManager{db: db}, nil
}

// InitializeDatabase initialise la connexion à la base de données
func (um *UserManager) InitializeDatabase() error {
	if err := um.db.Ping(); err != nil {
		return fmt.Errorf("database connection failed: %w", err)
	}

	// Créer les tables si nécessaire
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		username VARCHAR(255) UNIQUE NOT NULL,
		email VARCHAR(255) UNIQUE NOT NULL,
		password_hash VARCHAR(255) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	if _, err := um.db.Exec(query); err != nil {
		return fmt.Errorf("failed to create users table: %w", err)
	}

	return nil
}

// AuthenticateUser authentifie un utilisateur
func (um *UserManager) AuthenticateUser(ctx context.Context, username, password string) (bool, error) {
	var storedHash string
	query := "SELECT password_hash FROM users WHERE username = $1"

	err := um.db.QueryRowContext(ctx, query, username).Scan(&storedHash)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, nil // Utilisateur non trouvé
		}
		return false, fmt.Errorf("database query failed: %w", err)
	}

	// Vérifier le mot de passe (simplifié pour l'exemple)
	return password == storedHash, nil
}

// CreateUser crée un nouvel utilisateur
func (um *UserManager) CreateUser(ctx context.Context, username, email, password string) error {
	query := `
	INSERT INTO users (username, email, password_hash)
	VALUES ($1, $2, $3)`

	_, err := um.db.ExecContext(ctx, query, username, email, password)
	if err != nil {
		return fmt.Errorf("failed to create user: %w", err)
	}

	return nil
}

// GetUser récupère un utilisateur par son nom d'utilisateur
func (um *UserManager) GetUser(ctx context.Context, username string) (*User, error) {
	user := &User{}
	query := "SELECT id, username, email, created_at FROM users WHERE username = $1"

	err := um.db.QueryRowContext(ctx, query, username).Scan(
		&user.ID, &user.Username, &user.Email, &user.CreatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

// User représente un utilisateur
type User struct {
	ID        int    `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	CreatedAt string `json:"created_at"`
}

// AuthHandler gère l'authentification HTTP
type AuthHandler struct {
	userManager *UserManager
}

// NewAuthHandler crée un nouveau gestionnaire d'authentification
func NewAuthHandler(um *UserManager) *AuthHandler {
	return &AuthHandler{userManager: um}
}

// LoginHandler gère les demandes de connexion
func (ah *AuthHandler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	username := r.FormValue("username")
	password := r.FormValue("password")

	if username == "" || password == "" {
		http.Error(w, "Username and password required", http.StatusBadRequest)
		return
	}

	authenticated, err := ah.userManager.AuthenticateUser(r.Context(), username, password)
	if err != nil {
		log.Printf("Authentication error: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	if !authenticated {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	// Authentification réussie
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Welcome, %s!", username)
}

// RegisterHandler gère l'enregistrement de nouveaux utilisateurs
func (ah *AuthHandler) RegisterHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	username := r.FormValue("username")
	email := r.FormValue("email")
	password := r.FormValue("password")

	if username == "" || email == "" || password == "" {
		http.Error(w, "All fields required", http.StatusBadRequest)
		return
	}

	err := ah.userManager.CreateUser(r.Context(), username, email, password)
	if err != nil {
		log.Printf("Registration error: %v", err)
		http.Error(w, "Failed to create user", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	fmt.Fprintf(w, "User %s created successfully", username)
}

func main() {
	// Initialize database connection
	userManager, err := NewUserManager("postgres://user:password@localhost/testdb?sslmode=disable")
	if err != nil {
		log.Fatal("Failed to create user manager:", err)
	}

	// Initialize database schema
	if err := userManager.InitializeDatabase(); err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Create authentication handler
	authHandler := NewAuthHandler(userManager)

	// Setup HTTP routes
	http.HandleFunc("/login", authHandler.LoginHandler)
	http.HandleFunc("/register", authHandler.RegisterHandler)

	// Start server
	fmt.Println("Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
