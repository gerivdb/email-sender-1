# Les 16 Bases de la Programmation en Go

Ce document présente les 16 bases fondamentales de la programmation en Go qui guident le développement de notre projet.

## 1. Modularité

En Go, la modularité s'appuie sur les packages. Chaque package doit avoir une responsabilité unique et bien définie.

**Principes clés :**
- Un package = une responsabilité
- Interfaces publiques claires (noms commençant par une majuscule)
- Faible couplage, forte cohésion
- Réutilisabilité des packages

**Exemple :**
```go
// Package fileutils - Gestion des fichiers
package fileutils

import (
    "io/ioutil"
    "os"
)

// GetFileContent lit le contenu d'un fichier
func GetFileContent(filename string) ([]byte, error) {
    return ioutil.ReadFile(filename)
}

// SaveFileContent sauvegarde du contenu dans un fichier
func SaveFileContent(filename string, data []byte) error {
    return ioutil.WriteFile(filename, data, 0644)
}

// FileExists vérifie si un fichier existe
func FileExists(filename string) bool {
    _, err := os.Stat(filename)
    return !os.IsNotExist(err)
}
```

## 2. Abstraction

L'abstraction en Go utilise les interfaces pour masquer les détails d'implémentation complexes derrière des contrats simples.

**Principes clés :**
- Interfaces pour définir des comportements
- Implémentation implicite des interfaces
- Composition plutôt qu'héritage
- Séparation des préoccupations

**Exemple :**
```go
package datasource

import "context"

// DataSource interface abstraite pour différentes sources de données
type DataSource interface {
    Connect(ctx context.Context) error
    Disconnect() error
    Query(ctx context.Context, query string) ([]byte, error)
}

// DatabaseSource implémentation pour base de données
type DatabaseSource struct {
    connectionString string
}

func (d *DatabaseSource) Connect(ctx context.Context) error {
    // Implémentation de connexion DB
    return nil
}

func (d *DatabaseSource) Disconnect() error {
    // Implémentation de déconnexion DB
    return nil
}

func (d *DatabaseSource) Query(ctx context.Context, query string) ([]byte, error) {
    // Implémentation de requête DB
    return nil, nil
}

// APISource implémentation pour API REST
type APISource struct {
    baseURL string
}

func (a *APISource) Connect(ctx context.Context) error {
    // Implémentation de connexion API
    return nil
}

func (a *APISource) Disconnect() error {
    // Implémentation de déconnexion API
    return nil
}

func (a *APISource) Query(ctx context.Context, endpoint string) ([]byte, error) {
    // Implémentation d'appel API
    return nil, nil
}

// GetData utilise n'importe quelle source de données
func GetData(ctx context.Context, source DataSource, query string) ([]byte, error) {
    if err := source.Connect(ctx); err != nil {
        return nil, err
    }
    defer source.Disconnect()
    
    return source.Query(ctx, query)
}
```

## 3. Encapsulation

L'encapsulation en Go utilise les conventions de nommage (majuscule/minuscule) et les packages pour contrôler l'accès aux données.

**Principes clés :**
- Champs privés (minuscule) et publics (majuscule)
- Méthodes de validation
- Contrôle d'accès via les packages
- Protection de l'intégrité des données

**Exemple :**
```go
package user

import (
    "crypto/sha256"
    "errors"
    "fmt"
    "regexp"
)

// User encapsule les données d'un utilisateur
type User struct {
    Name     string // Public
    Age      int    // Public
    password string // Privé
}

// NewUser constructeur pour créer un utilisateur
func NewUser(name string, age int) (*User, error) {
    if age < 0 || age > 150 {
        return nil, errors.New("âge invalide")
    }
    
    if len(name) == 0 {
        return nil, errors.New("nom requis")
    }
    
    return &User{
        Name: name,
        Age:  age,
    }, nil
}

// SetPassword définit le mot de passe avec validation
func (u *User) SetPassword(password string) error {
    if len(password) < 8 {
        return errors.New("le mot de passe doit contenir au moins 8 caractères")
    }
    
    // Validation complexité
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasDigit := regexp.MustCompile(`\d`).MatchString(password)
    
    if !hasUpper || !hasLower || !hasDigit {
        return errors.New("le mot de passe doit contenir majuscules, minuscules et chiffres")
    }
    
    // Hachage du mot de passe
    hash := sha256.Sum256([]byte(password))
    u.password = fmt.Sprintf("%x", hash)
    
    return nil
}

// ValidatePassword vérifie le mot de passe
func (u *User) ValidatePassword(inputPassword string) bool {
    hash := sha256.Sum256([]byte(inputPassword))
    return u.password == fmt.Sprintf("%x", hash)
}

// HasPassword vérifie si un mot de passe est défini
func (u *User) HasPassword() bool {
    return u.password != ""
}
```

## 4. Héritage et Composition

Go privilégie la composition à l'héritage. On utilise l'embedding pour réutiliser le code.

**Principes clés :**
- Embedding de structs
- Interfaces pour le polymorphisme
- Composition over inheritance
- Promotion de méthodes

**Exemple :**
```go
package vehicle

import "fmt"

// Vehicle struct de base
type Vehicle struct {
    Speed int
    Color string
}

// Start démarre le véhicule
func (v *Vehicle) Start() {
    fmt.Println("Véhicule démarré")
}

// Stop arrête le véhicule
func (v *Vehicle) Stop() {
    fmt.Println("Véhicule arrêté")
}

// GetInfo retourne les informations du véhicule
func (v *Vehicle) GetInfo() string {
    return fmt.Sprintf("Couleur: %s, Vitesse: %d km/h", v.Color, v.Speed)
}

// Car compose Vehicle (embedding)
type Car struct {
    Vehicle // Embedding
    Doors   int
    Model   string
}

// NewCar constructeur pour Car
func NewCar(model, color string, doors int) *Car {
    return &Car{
        Vehicle: Vehicle{
            Speed: 0,
            Color: color,
        },
        Doors: doors,
        Model: model,
    }
}

// Start surcharge la méthode de Vehicle
func (c *Car) Start() {
    fmt.Printf("Démarrage de la voiture %s\n", c.Model)
    c.Vehicle.Start() // Appel à la méthode de base
}

// OpenTrunk méthode spécifique à Car
func (c *Car) OpenTrunk() {
    fmt.Println("Coffre ouvert")
}

// GetInfo surcharge avec informations spécifiques
func (c *Car) GetInfo() string {
    baseInfo := c.Vehicle.GetInfo()
    return fmt.Sprintf("%s, Modèle: %s, Portes: %d", baseInfo, c.Model, c.Doors)
}

// Motorcycle compose aussi Vehicle
type Motorcycle struct {
    Vehicle
    HasSidecar bool
}

// NewMotorcycle constructeur pour Motorcycle
func NewMotorcycle(color string, hasSidecar bool) *Motorcycle {
    return &Motorcycle{
        Vehicle: Vehicle{
            Speed: 0,
            Color: color,
        },
        HasSidecar: hasSidecar,
    }
}

// Start surcharge pour Motorcycle
func (m *Motorcycle) Start() {
    fmt.Println("Démarrage de la moto")
    m.Vehicle.Start()
}
```

## 5. Polymorphisme

Le polymorphisme en Go s'appuie sur les interfaces pour traiter différents types de manière uniforme.

**Principes clés :**
- Interfaces pour définir des comportements communs
- Implémentation implicite
- Type assertions et type switches
- Interface{} pour les types génériques

**Exemple :**
```go
package shapes

import (
    "fmt"
    "math"
)

// Shape interface commune pour toutes les formes
type Shape interface {
    Area() float64
    Perimeter() float64
    String() string
}

// Circle implémente Shape
type Circle struct {
    Radius float64
}

func (c Circle) Area() float64 {
    return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
    return 2 * math.Pi * c.Radius
}

func (c Circle) String() string {
    return fmt.Sprintf("Cercle(rayon=%.2f)", c.Radius)
}

// Rectangle implémente Shape
type Rectangle struct {
    Width  float64
    Height float64
}

func (r Rectangle) Area() float64 {
    return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
    return 2 * (r.Width + r.Height)
}

func (r Rectangle) String() string {
    return fmt.Sprintf("Rectangle(%.2fx%.2f)", r.Width, r.Height)
}

// Triangle implémente Shape
type Triangle struct {
    Base   float64
    Height float64
    Side1  float64
    Side2  float64
}

func (t Triangle) Area() float64 {
    return 0.5 * t.Base * t.Height
}

func (t Triangle) Perimeter() float64 {
    return t.Base + t.Side1 + t.Side2
}

func (t Triangle) String() string {
    return fmt.Sprintf("Triangle(base=%.2f, hauteur=%.2f)", t.Base, t.Height)
}

// PrintShapeInfo fonction polymorphique
func PrintShapeInfo(s Shape) {
    fmt.Printf("Forme: %s\n", s.String())
    fmt.Printf("Aire: %.2f\n", s.Area())
    fmt.Printf("Périmètre: %.2f\n", s.Perimeter())
    fmt.Println("---")
}

// CalculateTotalArea calcule l'aire totale de plusieurs formes
func CalculateTotalArea(shapes []Shape) float64 {
    total := 0.0
    for _, shape := range shapes {
        total += shape.Area()
    }
    return total
}

// GetShapesByType filtre les formes par type
func GetShapesByType(shapes []Shape, shapeType string) []Shape {
    var result []Shape
    
    for _, shape := range shapes {
        switch shapeType {
        case "circle":
            if _, ok := shape.(Circle); ok {
                result = append(result, shape)
            }
        case "rectangle":
            if _, ok := shape.(Rectangle); ok {
                result = append(result, shape)
            }
        case "triangle":
            if _, ok := shape.(Triangle); ok {
                result = append(result, shape)
            }
        }
    }
    
    return result
}
```

## 6. Composition

La composition en Go permet de créer des objets complexes en combinant des objets plus simples.

**Principes clés :**
- Embedding pour la composition
- Interfaces pour définir les contrats
- Flexibilité et modularité
- "A a" plutôt que "A est un"

**Exemple :**
```go
package automotive

import "fmt"

// Engine composant moteur
type Engine struct {
    Power      int
    FuelType   string
    isRunning  bool
}

func (e *Engine) Start() error {
    if e.isRunning {
        return fmt.Errorf("moteur déjà démarré")
    }
    e.isRunning = true
    fmt.Printf("Moteur %s de %d ch démarré\n", e.FuelType, e.Power)
    return nil
}

func (e *Engine) Stop() error {
    if !e.isRunning {
        return fmt.Errorf("moteur déjà arrêté")
    }
    e.isRunning = false
    fmt.Println("Moteur arrêté")
    return nil
}

func (e *Engine) IsRunning() bool {
    return e.isRunning
}

// Transmission composant transmission
type Transmission struct {
    Type         string
    CurrentGear  int
    MaxGears     int
}

func (t *Transmission) ChangeGear(gear int) error {
    if gear < 0 || gear > t.MaxGears {
        return fmt.Errorf("vitesse invalide: %d (max: %d)", gear, t.MaxGears)
    }
    
    t.CurrentGear = gear
    if gear == 0 {
        fmt.Println("Point mort engagé")
    } else {
        fmt.Printf("Vitesse %d engagée\n", gear)
    }
    return nil
}

// GPS composant GPS
type GPS struct {
    IsEnabled bool
    CurrentLocation string
}

func (g *GPS) Enable() {
    g.IsEnabled = true
    fmt.Println("GPS activé")
}

func (g *GPS) Disable() {
    g.IsEnabled = false
    fmt.Println("GPS désactivé")
}

func (g *GPS) Navigate(destination string) error {
    if !g.IsEnabled {
        return fmt.Errorf("GPS désactivé")
    }
    
    fmt.Printf("Navigation vers %s depuis %s\n", destination, g.CurrentLocation)
    return nil
}

// Car compose plusieurs composants
type Car struct {
    Model        string
    Year         int
    Engine       *Engine
    Transmission *Transmission
    GPS          *GPS
}

// NewCar constructeur qui compose les différents éléments
func NewCar(model string, year int) *Car {
    return &Car{
        Model: model,
        Year:  year,
        Engine: &Engine{
            Power:    150,
            FuelType: "Essence",
        },
        Transmission: &Transmission{
            Type:     "Manuelle",
            MaxGears: 5,
        },
        GPS: &GPS{
            CurrentLocation: "Position inconnue",
        },
    }
}

// Start démarre la voiture
func (c *Car) Start() error {
    fmt.Printf("Démarrage de %s %d\n", c.Model, c.Year)
    return c.Engine.Start()
}

// Stop arrête la voiture
func (c *Car) Stop() error {
    if err := c.Transmission.ChangeGear(0); err != nil {
        return err
    }
    return c.Engine.Stop()
}

// Drive conduit la voiture
func (c *Car) Drive(gear int) error {
    if !c.Engine.IsRunning() {
        return fmt.Errorf("moteur arrêté")
    }
    
    return c.Transmission.ChangeGear(gear)
}

// NavigateTo utilise le GPS pour naviguer
func (c *Car) NavigateTo(destination string) error {
    if !c.GPS.IsEnabled {
        c.GPS.Enable()
    }
    
    return c.GPS.Navigate(destination)
}

// GetStatus retourne le statut de la voiture
func (c *Car) GetStatus() string {
    return fmt.Sprintf(
        "Voiture: %s %d\nMoteur: %s (%d ch) - En marche: %t\nTransmission: %s - Vitesse: %d\nGPS: Activé: %t",
        c.Model, c.Year,
        c.Engine.FuelType, c.Engine.Power, c.Engine.IsRunning(),
        c.Transmission.Type, c.Transmission.CurrentGear,
        c.GPS.IsEnabled,
    )
}
```

## 7. Interfaces

Les interfaces en Go définissent des contrats que les types doivent respecter, permettant le polymorphisme et le découplage.

**Principes clés :**
- Interfaces implicites (duck typing)
- Petites interfaces spécialisées
- Composition d'interfaces
- Interface segregation principle

**Exemple :**
```go
package storage

import (
    "context"
    "fmt"
    "io"
)

// Reader interface pour la lecture
type Reader interface {
    Read(ctx context.Context, key string) ([]byte, error)
}

// Writer interface pour l'écriture
type Writer interface {
    Write(ctx context.Context, key string, data []byte) error
}

// Deleter interface pour la suppression
type Deleter interface {
    Delete(ctx context.Context, key string) error
}

// Storage interface complète (composition d'interfaces)
type Storage interface {
    Reader
    Writer
    Deleter
    Close() error
}

// Lister interface pour lister les clés
type Lister interface {
    List(ctx context.Context, prefix string) ([]string, error)
}

// AdvancedStorage interface étendue
type AdvancedStorage interface {
    Storage
    Lister
    Exists(ctx context.Context, key string) (bool, error)
}

// FileStorage implémentation fichier
type FileStorage struct {
    basePath string
}

func NewFileStorage(basePath string) *FileStorage {
    return &FileStorage{basePath: basePath}
}

func (f *FileStorage) Read(ctx context.Context, key string) ([]byte, error) {
    // Implémentation lecture fichier
    fmt.Printf("Lecture fichier: %s\n", key)
    return nil, nil
}

func (f *FileStorage) Write(ctx context.Context, key string, data []byte) error {
    // Implémentation écriture fichier
    fmt.Printf("Écriture fichier: %s (%d bytes)\n", key, len(data))
    return nil
}

func (f *FileStorage) Delete(ctx context.Context, key string) error {
    // Implémentation suppression fichier
    fmt.Printf("Suppression fichier: %s\n", key)
    return nil
}

func (f *FileStorage) Close() error {
    fmt.Println("Fermeture FileStorage")
    return nil
}

func (f *FileStorage) List(ctx context.Context, prefix string) ([]string, error) {
    // Implémentation listage fichiers
    fmt.Printf("Listage fichiers avec préfixe: %s\n", prefix)
    return []string{"file1.txt", "file2.txt"}, nil
}

func (f *FileStorage) Exists(ctx context.Context, key string) (bool, error) {
    // Implémentation vérification existence
    fmt.Printf("Vérification existence: %s\n", key)
    return true, nil
}

// MemoryStorage implémentation mémoire
type MemoryStorage struct {
    data map[string][]byte
}

func NewMemoryStorage() *MemoryStorage {
    return &MemoryStorage{
        data: make(map[string][]byte),
    }
}

func (m *MemoryStorage) Read(ctx context.Context, key string) ([]byte, error) {
    data, exists := m.data[key]
    if !exists {
        return nil, fmt.Errorf("clé non trouvée: %s", key)
    }
    return data, nil
}

func (m *MemoryStorage) Write(ctx context.Context, key string, data []byte) error {
    m.data[key] = data
    return nil
}

func (m *MemoryStorage) Delete(ctx context.Context, key string) error {
    delete(m.data, key)
    return nil
}

func (m *MemoryStorage) Close() error {
    m.data = nil
    return nil
}

// StorageManager utilise les interfaces
type StorageManager struct {
    primary   Storage
    secondary Storage
}

func NewStorageManager(primary, secondary Storage) *StorageManager {
    return &StorageManager{
        primary:   primary,
        secondary: secondary,
    }
}

// BackupData utilise l'interface Reader/Writer
func (sm *StorageManager) BackupData(ctx context.Context, key string) error {
    data, err := sm.primary.Read(ctx, key)
    if err != nil {
        return fmt.Errorf("erreur lecture: %w", err)
    }
    
    if err := sm.secondary.Write(ctx, key+".backup", data); err != nil {
        return fmt.Errorf("erreur sauvegarde: %w", err)
    }
    
    return nil
}

// Close ferme les deux storages
func (sm *StorageManager) Close() error {
    if err := sm.primary.Close(); err != nil {
        return err
    }
    return sm.secondary.Close()
}
```

## 8. Gestion des erreurs

Go utilise des valeurs d'erreur explicites pour une gestion robuste des erreurs.

**Principes clés :**
- Erreurs comme valeurs de retour
- Types d'erreurs personnalisés
- Wrapping d'erreurs (Go 1.13+)
- Validation des entrées

**Exemple :**
```go
package userservice

import (
    "errors"
    "fmt"
    "regexp"
    "context"
    "time"
)

// Erreurs personnalisées
var (
    ErrUserNotFound     = errors.New("utilisateur non trouvé")
    ErrInvalidEmail     = errors.New("adresse email invalide")
    ErrInvalidPassword  = errors.New("mot de passe invalide")
    ErrUserExists       = errors.New("utilisateur existe déjà")
    ErrDatabaseError    = errors.New("erreur de base de données")
)

// ValidationError erreur de validation avec détails
type ValidationError struct {
    Field   string
    Value   string
    Message string
}

func (e ValidationError) Error() string {
    return fmt.Sprintf("validation échouée pour le champ '%s': %s", e.Field, e.Message)
}

// DatabaseError erreur de base de données avec contexte
type DatabaseError struct {
    Operation string
    Err       error
}

func (e DatabaseError) Error() string {
    return fmt.Sprintf("erreur base de données lors de %s: %v", e.Operation, e.Err)
}

func (e DatabaseError) Unwrap() error {
    return e.Err
}

// User structure utilisateur
type User struct {
    ID       int
    Email    string
    Name     string
    password string
}

// UserRepository interface pour l'accès aux données
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id int) (*User, error)
    GetByEmail(ctx context.Context, email string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int) error
}

// UserService service de gestion des utilisateurs
type UserService struct {
    repo UserRepository
}

func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}

// validateEmail valide une adresse email
func validateEmail(email string) error {
    if email == "" {
        return &ValidationError{
            Field:   "email",
            Value:   email,
            Message: "email requis",
        }
    }
    
    emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
    if !emailRegex.MatchString(email) {
        return &ValidationError{
            Field:   "email",
            Value:   email,
            Message: "format d'email invalide",
        }
    }
    
    return nil
}

// validatePassword valide un mot de passe
func validatePassword(password string) error {
    if len(password) < 8 {
        return &ValidationError{
            Field:   "password",
            Value:   "***",
            Message: "mot de passe doit contenir au moins 8 caractères",
        }
    }
    
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasDigit := regexp.MustCompile(`\d`).MatchString(password)
    
    if !hasUpper || !hasLower || !hasDigit {
        return &ValidationError{
            Field:   "password",
            Value:   "***",
            Message: "mot de passe doit contenir majuscules, minuscules et chiffres",
        }
    }
    
    return nil
}

// CreateUser crée un nouvel utilisateur avec gestion d'erreurs complète
func (s *UserService) CreateUser(ctx context.Context, email, name, password string) (*User, error) {
    // Validation des entrées
    if err := validateEmail(email); err != nil {
        return nil, fmt.Errorf("validation échouée: %w", err)
    }
    
    if name == "" {
        return nil, &ValidationError{
            Field:   "name",
            Value:   name,
            Message: "nom requis",
        }
    }
    
    if err := validatePassword(password); err != nil {
        return nil, fmt.Errorf("validation échouée: %w", err)
    }
    
    // Vérifier si l'utilisateur existe déjà
    existing, err := s.repo.GetByEmail(ctx, email)
    if err != nil && !errors.Is(err, ErrUserNotFound) {
        return nil, fmt.Errorf("erreur lors de la vérification de l'utilisateur: %w", err)
    }
    
    if existing != nil {
        return nil, fmt.Errorf("utilisateur avec email %s: %w", email, ErrUserExists)
    }
    
    // Créer l'utilisateur
    user := &User{
        Email:    email,
        Name:     name,
        password: password, // Devrait être haché en réalité
    }
    
    if err := s.repo.Create(ctx, user); err != nil {
        return nil, fmt.Errorf("erreur lors de la création de l'utilisateur: %w", err)
    }
    
    return user, nil
}

// GetUser récupère un utilisateur avec timeout
func (s *UserService) GetUser(ctx context.Context, id int) (*User, error) {
    if id <= 0 {
        return nil, &ValidationError{
            Field:   "id",
            Value:   fmt.Sprintf("%d", id),
            Message: "ID doit être positif",
        }
    }
    
    // Créer un contexte avec timeout
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    user, err := s.repo.GetByID(ctx, id)
    if err != nil {
        if errors.Is(err, context.DeadlineExceeded) {
            return nil, fmt.Errorf("timeout lors de la récupération de l'utilisateur %d: %w", id, err)
        }
        
        if errors.Is(err, ErrUserNotFound) {
            return nil, fmt.Errorf("utilisateur avec ID %d: %w", id, err)
        }
        
        return nil, fmt.Errorf("erreur lors de la récupération de l'utilisateur %d: %w", id, err)
    }
    
    return user, nil
}

// UpdateUser met à jour un utilisateur
func (s *UserService) UpdateUser(ctx context.Context, id int, updates map[string]interface{}) error {
    user, err := s.GetUser(ctx, id)
    if err != nil {
        return fmt.Errorf("impossible de récupérer l'utilisateur pour mise à jour: %w", err)
    }
    
    // Valider et appliquer les mises à jour
    for field, value := range updates {
        switch field {
        case "email":
            if email, ok := value.(string); ok {
                if err := validateEmail(email); err != nil {
                    return fmt.Errorf("mise à jour échouée: %w", err)
                }
                user.Email = email
            } else {
                return &ValidationError{
                    Field:   "email",
                    Value:   fmt.Sprintf("%v", value),
                    Message: "doit être une chaîne de caractères",
                }
            }
        case "name":
            if name, ok := value.(string); ok {
                if name == "" {
                    return &ValidationError{
                        Field:   "name",
                        Value:   name,
                        Message: "nom ne peut pas être vide",
                    }
                }
                user.Name = name
            } else {
                return &ValidationError{
                    Field:   "name",
                    Value:   fmt.Sprintf("%v", value),
                    Message: "doit être une chaîne de caractères",
                }
            }
        default:
            return &ValidationError{
                Field:   field,
                Value:   fmt.Sprintf("%v", value),
                Message: "champ non supporté pour la mise à jour",
            }
        }
    }
    
    if err := s.repo.Update(ctx, user); err != nil {
        return fmt.Errorf("erreur lors de la mise à jour de l'utilisateur %d: %w", id, err)
    }
    
    return nil
}
```

## 9. Tests unitaires

Go propose un framework de test intégré avec le package `testing`.

**Principes clés :**
- Tests dans des fichiers `*_test.go`
- Fonction de test commençant par `Test`
- Table-driven tests
- Benchmarks et examples

**Exemple :**
```go
package calculator

import "errors"

// Calculator structure simple pour les calculs
type Calculator struct{}

// Add additionne deux nombres
func (c Calculator) Add(a, b float64) float64 {
    return a + b
}

// Subtract soustrait deux nombres
func (c Calculator) Subtract(a, b float64) float64 {
    return a - b
}

// Multiply multiplie deux nombres
func (c Calculator) Multiply(a, b float64) float64 {
    return a * b
}

// Divide divise deux nombres
func (c Calculator) Divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division par zéro")
    }
    return a / b, nil
}
```

```go
// calculator_test.go
package calculator

import (
    "math"
    "testing"
)

func TestCalculator_Add(t *testing.T) {
    calc := Calculator{}
    
    // Table-driven test
    tests := []struct {
        name     string
        a, b     float64
        expected float64
    }{
        {"Nombres positifs", 2, 3, 5},
        {"Nombres négatifs", -2, -3, -5},
        {"Positif et négatif", 2, -3, -1},
        {"Avec zéro", 5, 0, 5},
        {"Nombres décimaux", 2.5, 3.7, 6.2},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := calc.Add(tt.a, tt.b)
            if math.Abs(result-tt.expected) > 0.0001 {
                t.Errorf("Add(%f, %f) = %f; attendu %f", 
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

func TestCalculator_Subtract(t *testing.T) {
    calc := Calculator{}
    
    tests := []struct {
        name     string
        a, b     float64
        expected float64
    }{
        {"Nombres positifs", 5, 3, 2},
        {"Nombres négatifs", -2, -3, 1},
        {"Résultat négatif", 2, 5, -3},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := calc.Subtract(tt.a, tt.b)
            if math.Abs(result-tt.expected) > 0.0001 {
                t.Errorf("Subtract(%f, %f) = %f; attendu %f", 
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

func TestCalculator_Multiply(t *testing.T) {
    calc := Calculator{}
    
    tests := []struct {
        name     string
        a, b     float64
        expected float64
    }{
        {"Nombres positifs", 3, 4, 12},
        {"Avec zéro", 5, 0, 0},
        {"Nombres négatifs", -2, -3, 6},
        {"Positif et négatif", -2, 3, -6},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := calc.Multiply(tt.a, tt.b)
            if math.Abs(result-tt.expected) > 0.0001 {
                t.Errorf("Multiply(%f, %f) = %f; attendu %f", 
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}

func TestCalculator_Divide(t *testing.T) {
    calc := Calculator{}
    
    tests := []struct {
        name        string
        a, b        float64
        expected    float64
        expectError bool
    }{
        {"Division normale", 10, 2, 5, false},
        {"Division par zéro", 5, 0, 0, true},
        {"Division négative", -10, 2, -5, false},
        {"Division de zéro", 0, 5, 0, false},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := calc.Divide(tt.a, tt.b)
            
            if tt.expectError {
                if err == nil {
                    t.Errorf("Divide(%f, %f) attendait une erreur mais n'en a pas eu", 
                        tt.a, tt.b)
                }
            } else {
                if err != nil {
                    t.Errorf("Divide(%f, %f) erreur inattendue: %v", 
                        tt.a, tt.b, err)
                }
                if math.Abs(result-tt.expected) > 0.0001 {
                    t.Errorf("Divide(%f, %f) = %f; attendu %f", 
                        tt.a, tt.b, result, tt.expected)
                }
            }
        })
    }
}

// Benchmark pour mesurer les performances
func BenchmarkCalculator_Add(b *testing.B) {
    calc := Calculator{}
    
    for i := 0; i < b.N; i++ {
        calc.Add(10.5, 20.3)
    }
}

func BenchmarkCalculator_Multiply(b *testing.B) {
    calc := Calculator{}
    
    for i := 0; i < b.N; i++ {
        calc.Multiply(10.5, 20.3)
    }
}

// Example pour la documentation
func ExampleCalculator_Add() {
    calc := Calculator{}
    result := calc.Add(2, 3)
    println(result)
    // Output: 5
}

func ExampleCalculator_Divide() {
    calc := Calculator{}
    result, err := calc.Divide(10, 2)
    if err != nil {
        println("Erreur:", err.Error())
        return
    }
    println(result)
    // Output: 5
}

// Test avec setup et teardown
func TestCalculatorWithSetup(t *testing.T) {
    // Setup
    calc := Calculator{}
    
    t.Cleanup(func() {
        // Teardown - exécuté après le test
        t.Log("Nettoyage après le test")
    })
    
    // Test
    result := calc.Add(1, 1)
    if result != 2 {
        t.Errorf("Expected 2, got %f", result)
    }
}

// Subtest pour organiser les tests
func TestCalculatorOperations(t *testing.T) {
    calc := Calculator{}
    
    t.Run("Addition", func(t *testing.T) {
        if calc.Add(2, 2) != 4 {
            t.Error("Addition failed")
        }
    })
    
    t.Run("Division", func(t *testing.T) {
        t.Run("Normal", func(t *testing.T) {
            result, err := calc.Divide(4, 2)
            if err != nil || result != 2 {
                t.Error("Division failed")
            }
        })
        
        t.Run("By zero", func(t *testing.T) {
            _, err := calc.Divide(4, 0)
            if err == nil {
                t.Error("Expected error for division by zero")
            }
        })
    })
}
```

## 10. Documentation

Go utilise `godoc` pour générer automatiquement la documentation à partir des commentaires.

**Principes clés :**
- Commentaires directement au-dessus des déclarations
- Format spécifique pour godoc
- Examples exécutables
- Package documentation

**Exemple :**
```go
// Package mathutils fournit des utilitaires mathématiques avancés.
//
// Ce package contient des fonctions pour effectuer des calculs mathématiques
// complexes, des conversions d'unités et des opérations statistiques.
//
// Exemple d'utilisation:
//
//    calc := mathutils.NewCalculator()
//    result := calc.Factorial(5)
//    fmt.Printf("5! = %d\n", result)
//
package mathutils

import (
    "errors"
    "fmt"
    "math"
)

// ErrNegativeInput est retournée quand une fonction reçoit une valeur négative
// alors qu'elle n'accepte que des valeurs positives.
var ErrNegativeInput = errors.New("valeur d'entrée négative non autorisée")

// Calculator représente une calculatrice avec des fonctions mathématiques étendues.
// Elle maintient un historique des dernières opérations effectuées.
type Calculator struct {
    // history stocke les dernières opérations
    history []Operation
    // maxHistory définit le nombre maximum d'opérations à conserver
    maxHistory int
}

// Operation représente une opération mathématique avec son résultat.
type Operation struct {
    Type   string    // Type d'opération (Add, Multiply, etc.)
    Input  []float64 // Valeurs d'entrée
    Result float64   // Résultat de l'opération
}

// NewCalculator crée une nouvelle instance de Calculator.
//
// Le paramètre maxHistory détermine combien d'opérations sont conservées
// dans l'historique. Si maxHistory est 0 ou négatif, aucun historique
// n'est conservé.
//
// Exemple:
//    calc := NewCalculator(10) // Garde les 10 dernières opérations
//    calc2 := NewCalculator(0) // Pas d'historique
func NewCalculator(maxHistory int) *Calculator {
    return &Calculator{
        history:    make([]Operation, 0),
        maxHistory: maxHistory,
    }
}

// Factorial calcule la factorielle d'un nombre entier positif.
//
// La factorielle de n (notée n!) est le produit de tous les entiers
// positifs inférieurs ou égaux à n. Par convention, 0! = 1.
//
// Paramètres:
//   n: Le nombre dont on veut calculer la factorielle (doit être >= 0)
//
// Retour:
//   Le résultat de n! et une erreur si n est négatif
//
// Complexité temporelle: O(n)
// Complexité spatiale: O(1)
//
// Exemple:
//    calc := NewCalculator(5)
//    result, err := calc.Factorial(5)
//    if err != nil {
//        log.Fatal(err)
//    }
//    fmt.Printf("5! = %d\n", result) // Affiche: 5! = 120
func (c *Calculator) Factorial(n int) (int64, error) {
    if n < 0 {
        return 0, fmt.Errorf("factorial(%d): %w", n, ErrNegativeInput)
    }
    
    if n == 0 || n == 1 {
        c.addToHistory("Factorial", []float64{float64(n)}, 1)
        return 1, nil
    }
    
    var result int64 = 1
    for i := 2; i <= n; i++ {
        result *= int64(i)
    }
    
    c.addToHistory("Factorial", []float64{float64(n)}, float64(result))
    return result, nil
}

// GetHistory retourne l'historique des opérations effectuées.
//
// L'historique contient les dernières opérations jusqu'à la limite
// définie par maxHistory lors de la création du Calculator.
//
// Retour:
//   Une copie de l'historique des opérations
//
// Exemple:
//    calc := NewCalculator(5)
//    calc.Factorial(5)
//    calc.Fibonacci(10)
//    
//    history := calc.GetHistory()
//    for _, op := range history {
//        fmt.Printf("Opération: %s, Résultat: %.2f\n", op.Type, op.Result)
//    }
func (c *Calculator) GetHistory() []Operation {
    // Retourner une copie pour éviter les modifications externes
    history := make([]Operation, len(c.history))
    copy(history, c.history)
    return history
}

// addToHistory ajoute une opération à l'historique interne.
// Cette méthode est privée (commence par une minuscule).
func (c *Calculator) addToHistory(opType string, input []float64, result float64) {
    if c.maxHistory <= 0 {
        return
    }
    
    operation := Operation{
        Type:   opType,
        Input:  make([]float64, len(input)),
        Result: result,
    }
    copy(operation.Input, input)
    
    c.history = append(c.history, operation)
    
    // Limiter la taille de l'historique
    if len(c.history) > c.maxHistory {
        c.history = c.history[len(c.history)-c.maxHistory:]
    }
}
```

## 11. Gestion de la configuration

Go utilise diverses approches pour la gestion de configuration : variables d'environnement, fichiers JSON/YAML, flags de ligne de commande.

**Principes clés :**
- Configuration par variables d'environnement
- Fichiers de configuration structurés
- Validation de la configuration
- Configuration par environnement

**Exemple :**
```go
package config

import (
    "encoding/json"
    "errors"
    "fmt"
    "os"
    "strconv"
    "strings"
    "time"
)

// DatabaseConfig configuration de base de données
type DatabaseConfig struct {
    Host         string        `json:"host" env:"DB_HOST"`
    Port         int           `json:"port" env:"DB_PORT"`
    Username     string        `json:"username" env:"DB_USERNAME"`
    Password     string        `json:"password" env:"DB_PASSWORD"`
    Database     string        `json:"database" env:"DB_DATABASE"`
    MaxConns     int           `json:"max_connections" env:"DB_MAX_CONNECTIONS"`
    Timeout      time.Duration `json:"timeout" env:"DB_TIMEOUT"`
    SSLMode      string        `json:"ssl_mode" env:"DB_SSL_MODE"`
}

// ServerConfig configuration du serveur
type ServerConfig struct {
    Host         string        `json:"host" env:"SERVER_HOST"`
    Port         int           `json:"port" env:"SERVER_PORT"`
    ReadTimeout  time.Duration `json:"read_timeout" env:"SERVER_READ_TIMEOUT"`
    WriteTimeout time.Duration `json:"write_timeout" env:"SERVER_WRITE_TIMEOUT"`
    TLSEnabled   bool          `json:"tls_enabled" env:"SERVER_TLS_ENABLED"`
    CertFile     string        `json:"cert_file" env:"SERVER_CERT_FILE"`
    KeyFile      string        `json:"key_file" env:"SERVER_KEY_FILE"`
}

// Config configuration complète de l'application
type Config struct {
    Environment string         `json:"environment" env:"ENVIRONMENT"`
    Debug       bool           `json:"debug" env:"DEBUG"`
    Database    DatabaseConfig `json:"database"`
    Server      ServerConfig   `json:"server"`
}

// DefaultConfig retourne une configuration par défaut
func DefaultConfig() *Config {
    return &Config{
        Environment: "development",
        Debug:       true,
        Database: DatabaseConfig{
            Host:     "localhost",
            Port:     5432,
            Username: "postgres",
            Database: "myapp",
            MaxConns: 10,
            Timeout:  30 * time.Second,
            SSLMode:  "disable",
        },
        Server: ServerConfig{
            Host:         "localhost",
            Port:         8080,
            ReadTimeout:  15 * time.Second,
            WriteTimeout: 15 * time.Second,
            TLSEnabled:   false,
        },
    }
}

// LoadConfig charge la configuration depuis différentes sources
func LoadConfig(configFile string) (*Config, error) {
    config := DefaultConfig()
    
    // 1. Charger depuis le fichier de configuration si spécifié
    if configFile != "" {
        if err := loadFromFile(config, configFile); err != nil {
            return nil, fmt.Errorf("erreur lors du chargement du fichier de config: %w", err)
        }
    }
    
    // 2. Surcharger avec les variables d'environnement
    if err := loadFromEnv(config); err != nil {
        return nil, fmt.Errorf("erreur lors du chargement des variables d'environnement: %w", err)
    }
    
    // 3. Valider la configuration
    if err := config.Validate(); err != nil {
        return nil, fmt.Errorf("configuration invalide: %w", err)
    }
    
    return config, nil
}

// loadFromFile charge la configuration depuis un fichier JSON
func loadFromFile(config *Config, filename string) error {
    file, err := os.Open(filename)
    if err != nil {
        if os.IsNotExist(err) {
            return nil // Fichier optionnel
        }
        return err
    }
    defer file.Close()
    
    decoder := json.NewDecoder(file)
    return decoder.Decode(config)
}

// loadFromEnv charge la configuration depuis les variables d'environnement
func loadFromEnv(config *Config) error {
    // Variables principales
    if env := os.Getenv("ENVIRONMENT"); env != "" {
        config.Environment = env
    }
    
    if env := os.Getenv("DEBUG"); env != "" {
        debug, err := strconv.ParseBool(env)
        if err != nil {
            return fmt.Errorf("DEBUG doit être un booléen: %w", err)
        }
        config.Debug = debug
    }
    
    // Configuration base de données
    if env := os.Getenv("DB_HOST"); env != "" {
        config.Database.Host = env
    }
    
    if env := os.Getenv("DB_PORT"); env != "" {
        port, err := strconv.Atoi(env)
        if err != nil {
            return fmt.Errorf("DB_PORT doit être un entier: %w", err)
        }
        config.Database.Port = port
    }
    
    if env := os.Getenv("DB_USERNAME"); env != "" {
        config.Database.Username = env
    }
    
    if env := os.Getenv("DB_PASSWORD"); env != "" {
        config.Database.Password = env
    }
    
    if env := os.Getenv("DB_DATABASE"); env != "" {
        config.Database.Database = env
    }
    
    // Configuration serveur
    if env := os.Getenv("SERVER_HOST"); env != "" {
        config.Server.Host = env
    }
    
    if env := os.Getenv("SERVER_PORT"); env != "" {
        port, err := strconv.Atoi(env)
        if err != nil {
            return fmt.Errorf("SERVER_PORT doit être un entier: %w", err)
        }
        config.Server.Port = port
    }
    
    if env := os.Getenv("SERVER_TLS_ENABLED"); env != "" {
        enabled, err := strconv.ParseBool(env)
        if err != nil {
            return fmt.Errorf("SERVER_TLS_ENABLED doit être un booléen: %w", err)
        }
        config.Server.TLSEnabled = enabled
    }
    
    return nil
}

// Validate valide la configuration
func (c *Config) Validate() error {
    var errorList []string
    
    // Valider l'environnement
    validEnvs := []string{"development", "staging", "production"}
    if !contains(validEnvs, c.Environment) {
        errorList = append(errorList, fmt.Sprintf("environment invalide: %s (valides: %v)", 
            c.Environment, validEnvs))
    }
    
    // Valider la base de données
    if c.Database.Host == "" {
        errorList = append(errorList, "database.host requis")
    }
    
    if c.Database.Port <= 0 || c.Database.Port > 65535 {
        errorList = append(errorList, "database.port doit être entre 1 et 65535")
    }
    
    if c.Database.Username == "" {
        errorList = append(errorList, "database.username requis")
    }
    
    if c.Database.Database == "" {
        errorList = append(errorList, "database.database requis")
    }
    
    // Valider le serveur
    if c.Server.Port <= 0 || c.Server.Port > 65535 {
        errorList = append(errorList, "server.port doit être entre 1 et 65535")
    }
    
    if c.Server.TLSEnabled {
        if c.Server.CertFile == "" {
            errorList = append(errorList, "server.cert_file requis quand TLS est activé")
        }
        if c.Server.KeyFile == "" {
            errorList = append(errorList, "server.key_file requis quand TLS est activé")
        }
    }
    
    if len(errorList) > 0 {
        return errors.New(strings.Join(errorList, "; "))
    }
    
    return nil
}

// GetDSN retourne la chaîne de connexion à la base de données
func (c *Config) GetDSN() string {
    return fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
        c.Database.Host,
        c.Database.Port,
        c.Database.Username,
        c.Database.Password,
        c.Database.Database,
        c.Database.SSLMode,
    )
}

// contains vérifie si une slice contient une valeur
func contains(slice []string, item string) bool {
    for _, s := range slice {
        if s == item {
            return true
        }
    }
    return false
}
```

## 12. Journalisation

Go utilise des packages de journalisation comme le package standard `log` ou des bibliothèques tierces comme `logrus` ou `zap`.

**Principes clés :**
- Niveaux de journalisation structurés
- Formats JSON pour la production
- Rotation et archivage des logs
- Contexte et corrélation

**Exemple :**
```go
package logging

import (
    "context"
    "encoding/json"
    "fmt"
    "io"
    "os"
    "runtime"
    "strings"
    "time"
)

// LogLevel représente le niveau de log
type LogLevel int

const (
    DebugLevel LogLevel = iota
    InfoLevel
    WarnLevel
    ErrorLevel
    FatalLevel
)

// String retourne la représentation string du niveau
func (l LogLevel) String() string {
    switch l {
    case DebugLevel:
        return "DEBUG"
    case InfoLevel:
        return "INFO"
    case WarnLevel:
        return "WARN"
    case ErrorLevel:
        return "ERROR"
    case FatalLevel:
        return "FATAL"
    default:
        return "UNKNOWN"
    }
}

// LogEntry représente une entrée de log
type LogEntry struct {
    Timestamp time.Time              `json:"timestamp"`
    Level     string                 `json:"level"`
    Message   string                 `json:"message"`
    Fields    map[string]interface{} `json:"fields,omitempty"`
    Source    string                 `json:"source,omitempty"`
    RequestID string                 `json:"request_id,omitempty"`
}

// Logger interface pour différents types de loggers
type Logger interface {
    Debug(msg string, fields ...Field)
    Info(msg string, fields ...Field)
    Warn(msg string, fields ...Field)
    Error(msg string, fields ...Field)
    Fatal(msg string, fields ...Field)
    WithFields(fields ...Field) Logger
    WithContext(ctx context.Context) Logger
}

// Field représente un champ de log
type Field struct {
    Key   string
    Value interface{}
}

// String crée un champ string
func String(key, value string) Field {
    return Field{Key: key, Value: value}
}

// Int crée un champ int
func Int(key string, value int) Field {
    return Field{Key: key, Value: value}
}

// Error crée un champ error
func Error(err error) Field {
    return Field{Key: "error", Value: err.Error()}
}

// Duration crée un champ duration
func Duration(key string, value time.Duration) Field {
    return Field{Key: key, Value: value.String()}
}

// StandardLogger implémentation standard du logger
type StandardLogger struct {
    level     LogLevel
    writer    io.Writer
    formatter Formatter
    fields    map[string]interface{}
    context   context.Context
}

// Formatter interface pour formater les logs
type Formatter interface {
    Format(entry *LogEntry) ([]byte, error)
}

// JSONFormatter formateur JSON
type JSONFormatter struct{}

func (f *JSONFormatter) Format(entry *LogEntry) ([]byte, error) {
    return json.Marshal(entry)
}

// TextFormatter formateur texte
type TextFormatter struct {
    TimestampFormat string
}

func (f *TextFormatter) Format(entry *LogEntry) ([]byte, error) {
    timestamp := entry.Timestamp.Format(f.TimestampFormat)
    if f.TimestampFormat == "" {
        timestamp = entry.Timestamp.Format(time.RFC3339)
    }
    
    var fieldsStr strings.Builder
    for key, value := range entry.Fields {
        fieldsStr.WriteString(fmt.Sprintf(" %s=%v", key, value))
    }
    
    line := fmt.Sprintf("[%s] [%s] %s%s\n",
        timestamp,
        entry.Level,
        entry.Message,
        fieldsStr.String(),
    )
    
    return []byte(line), nil
}

// NewLogger crée un nouveau logger
func NewLogger(level LogLevel, writer io.Writer, formatter Formatter) *StandardLogger {
    return &StandardLogger{
        level:     level,
        writer:    writer,
        formatter: formatter,
        fields:    make(map[string]interface{}),
    }
}

// NewJSONLogger crée un logger avec formatter JSON
func NewJSONLogger(level LogLevel, writer io.Writer) *StandardLogger {
    return NewLogger(level, writer, &JSONFormatter{})
}

// NewTextLogger crée un logger avec formatter texte
func NewTextLogger(level LogLevel, writer io.Writer) *StandardLogger {
    return NewLogger(level, writer, &TextFormatter{})
}

// log méthode interne pour écrire les logs
func (l *StandardLogger) log(level LogLevel, msg string, fields ...Field) {
    if level < l.level {
        return
    }
    
    // Créer l'entrée de log
    entry := &LogEntry{
        Timestamp: time.Now(),
        Level:     level.String(),
        Message:   msg,
        Fields:    make(map[string]interface{}),
    }
    
    // Ajouter les champs du logger
    for key, value := range l.fields {
        entry.Fields[key] = value
    }
    
    // Ajouter les champs spécifiques
    for _, field := range fields {
        entry.Fields[field.Key] = field.Value
    }
    
    // Ajouter les informations de source
    if level >= ErrorLevel {
        _, file, line, ok := runtime.Caller(2)
        if ok {
            entry.Source = fmt.Sprintf("%s:%d", file, line)
        }
    }
    
    // Ajouter l'ID de requête depuis le contexte
    if l.context != nil {
        if requestID := l.context.Value("request_id"); requestID != nil {
            entry.RequestID = fmt.Sprintf("%v", requestID)
        }
    }
    
    // Formater et écrire
    formatted, err := l.formatter.Format(entry)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Erreur de formatage du log: %v\n", err)
        return
    }
    
    l.writer.Write(formatted)
    
    // Exit sur Fatal
    if level == FatalLevel {
        os.Exit(1)
    }
}

// Debug log niveau debug
func (l *StandardLogger) Debug(msg string, fields ...Field) {
    l.log(DebugLevel, msg, fields...)
}

// Info log niveau info
func (l *StandardLogger) Info(msg string, fields ...Field) {
    l.log(InfoLevel, msg, fields...)
}

// Warn log niveau warning
func (l *StandardLogger) Warn(msg string, fields ...Field) {
    l.log(WarnLevel, msg, fields...)
}

// Error log niveau error
func (l *StandardLogger) Error(msg string, fields ...Field) {
    l.log(ErrorLevel, msg, fields...)
}

// Fatal log niveau fatal (exit après log)
func (l *StandardLogger) Fatal(msg string, fields ...Field) {
    l.log(FatalLevel, msg, fields...)
}

// WithFields crée un nouveau logger avec des champs additionnels
func (l *StandardLogger) WithFields(fields ...Field) Logger {
    newFields := make(map[string]interface{})
    
    // Copier les champs existants
    for key, value := range l.fields {
        newFields[key] = value
    }
    
    // Ajouter les nouveaux champs
    for _, field := range fields {
        newFields[field.Key] = field.Value
    }
    
    return &StandardLogger{
        level:     l.level,
        writer:    l.writer,
        formatter: l.formatter,
        fields:    newFields,
        context:   l.context,
    }
}

// WithContext crée un nouveau logger avec un contexte
func (l *StandardLogger) WithContext(ctx context.Context) Logger {
    return &StandardLogger{
        level:     l.level,
        writer:    l.writer,
        formatter: l.formatter,
        fields:    l.fields,
        context:   ctx,
    }
}

// FileRotator gère la rotation des fichiers de log
type FileRotator struct {
    filename   string
    maxSize    int64
    maxBackups int
    maxAge     int
    file       *os.File
}

// NewFileRotator crée un nouveau rotateur de fichiers
func NewFileRotator(filename string, maxSize int64, maxBackups, maxAge int) *FileRotator {
    return &FileRotator{
        filename:   filename


# Les 16 Bases de la Programmation en Go (Suite)

## 12. Journalisation (suite et fin)

```go
// FileRotator gère la rotation des fichiers de log
type FileRotator struct {
    filename   string
    maxSize    int64
    maxBackups int
    maxAge     int
    file       *os.File
    size       int64
}

// NewFileRotator crée un nouveau rotateur de fichiers
func NewFileRotator(filename string, maxSize int64, maxBackups, maxAge int) *FileRotator {
    return &FileRotator{
        filename:   filename,
        maxSize:    maxSize,
        maxBackups: maxBackups,
        maxAge:     maxAge,
    }
}

// Write implémente io.Writer avec rotation automatique
func (fr *FileRotator) Write(p []byte) (n int, err error) {
    if fr.file == nil {
        if err := fr.openFile(); err != nil {
            return 0, err
        }
    }
    
    // Vérifier si rotation nécessaire
    if fr.size+int64(len(p)) > fr.maxSize {
        if err := fr.rotate(); err != nil {
            return 0, err
        }
    }
    
    n, err = fr.file.Write(p)
    fr.size += int64(n)
    return n, err
}

func (fr *FileRotator) openFile() error {
    file, err := os.OpenFile(fr.filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
    if err != nil {
        return err
    }
    
    info, err := file.Stat()
    if err != nil {
        file.Close()
        return err
    }
    
    fr.file = file
    fr.size = info.Size()
    return nil
}

func (fr *FileRotator) rotate() error {
    if fr.file != nil {
        fr.file.Close()
    }
    
    // Renommer les fichiers existants
    for i := fr.maxBackups - 1; i >= 1; i-- {
        oldName := fmt.Sprintf("%s.%d", fr.filename, i)
        newName := fmt.Sprintf("%s.%d", fr.filename, i+1)
        
        if _, err := os.Stat(oldName); err == nil {
            os.Rename(oldName, newName)
        }
    }
    
    // Renommer le fichier actuel
    backupName := fmt.Sprintf("%s.1", fr.filename)
    if _, err := os.Stat(fr.filename); err == nil {
        os.Rename(fr.filename, backupName)
    }
    
    return fr.openFile()
}

// Close ferme le fichier
func (fr *FileRotator) Close() error {
    if fr.file != nil {
        return fr.file.Close()
    }
    return nil
}

// Exemple d'utilisation complète
func ExampleLogging() {
    // Logger pour la console (développement)
    consoleLogger := NewTextLogger(DebugLevel, os.Stdout)
    
    // Logger pour fichier avec rotation (production)
    rotator := NewFileRotator("app.log", 10*1024*1024, 5, 30) // 10MB, 5 backups, 30 jours
    fileLogger := NewJSONLogger(InfoLevel, rotator)
    
    // Utilisation basique
    consoleLogger.Info("Application démarrée")
    fileLogger.Info("Application démarrée", String("version", "1.0.0"))
    
    // Logger avec contexte
    ctx := context.WithValue(context.Background(), "request_id", "req-123")
    contextLogger := fileLogger.WithContext(ctx)
    
    // Logger avec champs persistants
    userLogger := contextLogger.WithFields(
        String("user_id", "user-456"),
        String("action", "login"),
    )
    
    userLogger.Info("Utilisateur connecté")
    userLogger.Warn("Tentative de connexion échouée", Int("attempts", 3))
    
    // Gestion d'erreur
    err := fmt.Errorf("erreur de base de données")
    userLogger.Error("Erreur lors de la sauvegarde", Error(err))
    
    // Mesure de performance
    start := time.Now()
    // ... opération
    duration := time.Since(start)
    userLogger.Info("Opération terminée", Duration("duration", duration))
}
```

## 13. Performance

L'optimisation des performances en Go s'appuie sur les outils intégrés de profiling et les bonnes pratiques du langage.

**Principes clés :**
- Profiling avec pprof
- Benchmarks pour mesurer
- Optimisation mémoire et CPU
- Concurrence efficace

**Exemple :**
```go
package performance

import (
    "context"
    "fmt"
    "runtime"
    "sync"
    "time"
    _ "net/http/pprof" // Import pour activer pprof
    "net/http"
)

// Cache simple avec gestion de performance
type Cache struct {
    mu    sync.RWMutex
    items map[string]*CacheItem
    stats CacheStats
}

type CacheItem struct {
    Value      interface{}
    Expiration int64
    AccessTime int64
}

type CacheStats struct {
    Hits       int64
    Misses     int64
    Evictions  int64
    Operations int64
}

// NewCache crée un nouveau cache optimisé
func NewCache() *Cache {
    c := &Cache{
        items: make(map[string]*CacheItem),
    }
    
    // Démarrer le nettoyage périodique
    go c.startCleanup()
    
    return c
}

// Get récupère une valeur du cache (optimisé pour la lecture)
func (c *Cache) Get(key string) (interface{}, bool) {
    c.mu.RLock()
    item, exists := c.items[key]
    c.mu.RUnlock()
    
    if !exists {
        c.stats.Misses++
        return nil, false
    }
    
    now := time.Now().UnixNano()
    if item.Expiration > 0 && now > item.Expiration {
        c.Delete(key)
        c.stats.Misses++
        return nil, false
    }
    
    // Mise à jour du temps d'accès (sans verrou pour optimiser)
    item.AccessTime = now
    c.stats.Hits++
    return item.Value, true
}

// Set stocke une valeur dans le cache
func (c *Cache) Set(key string, value interface{}, duration time.Duration) {
    var expiration int64
    if duration > 0 {
        expiration = time.Now().Add(duration).UnixNano()
    }
    
    c.mu.Lock()
    c.items[key] = &CacheItem{
        Value:      value,
        Expiration: expiration,
        AccessTime: time.Now().UnixNano(),
    }
    c.mu.Unlock()
    
    c.stats.Operations++
}

// Delete supprime une clé du cache
func (c *Cache) Delete(key string) {
    c.mu.Lock()
    delete(c.items, key)
    c.mu.Unlock()
    
    c.stats.Evictions++
}

// startCleanup démarre le nettoyage périodique
func (c *Cache) startCleanup() {
    ticker := time.NewTicker(5 * time.Minute)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            c.cleanup()
        }
    }
}

// cleanup nettoie les éléments expirés
func (c *Cache) cleanup() {
    now := time.Now().UnixNano()
    
    c.mu.Lock()
    for key, item := range c.items {
        if item.Expiration > 0 && now > item.Expiration {
            delete(c.items, key)
            c.stats.Evictions++
        }
    }
    c.mu.Unlock()
}

// GetStats retourne les statistiques de performance
func (c *Cache) GetStats() CacheStats {
    return c.stats
}

// PerformanceMonitor monitore les performances de l'application
type PerformanceMonitor struct {
    metrics map[string]*Metric
    mu      sync.RWMutex
}

type Metric struct {
    Count    int64
    Total    time.Duration
    Min      time.Duration
    Max      time.Duration
    Average  time.Duration
}

// NewPerformanceMonitor crée un nouveau moniteur
func NewPerformanceMonitor() *PerformanceMonitor {
    return &PerformanceMonitor{
        metrics: make(map[string]*Metric),
    }
}

// Measure mesure le temps d'exécution d'une fonction
func (pm *PerformanceMonitor) Measure(name string, fn func()) {
    start := time.Now()
    fn()
    duration := time.Since(start)
    
    pm.Record(name, duration)
}

// Record enregistre une métrique de performance
func (pm *PerformanceMonitor) Record(name string, duration time.Duration) {
    pm.mu.Lock()
    defer pm.mu.Unlock()
    
    metric, exists := pm.metrics[name]
    if !exists {
        metric = &Metric{
            Min: duration,
            Max: duration,
        }
        pm.metrics[name] = metric
    }
    
    metric.Count++
    metric.Total += duration
    metric.Average = metric.Total / time.Duration(metric.Count)
    
    if duration < metric.Min {
        metric.Min = duration
    }
    if duration > metric.Max {
        metric.Max = duration
    }
}

// GetMetrics retourne toutes les métriques
func (pm *PerformanceMonitor) GetMetrics() map[string]Metric {
    pm.mu.RLock()
    defer pm.mu.RUnlock()
    
    result := make(map[string]Metric)
    for name, metric := range pm.metrics {
        result[name] = *metric
    }
    
    return result
}

// MemoryPool pool d'objets pour réduire les allocations
type MemoryPool struct {
    pool sync.Pool
}

// NewMemoryPool crée un nouveau pool d'objets
func NewMemoryPool(newFunc func() interface{}) *MemoryPool {
    return &MemoryPool{
        pool: sync.Pool{
            New: newFunc,
        },
    }
}

// Get récupère un objet du pool
func (mp *MemoryPool) Get() interface{} {
    return mp.pool.Get()
}

// Put remet un objet dans le pool
func (mp *MemoryPool) Put(obj interface{}) {
    mp.pool.Put(obj)
}

// Worker pool pour traitement parallèle efficace
type WorkerPool struct {
    workerCount int
    jobQueue    chan Job
    quit        chan bool
    wg          sync.WaitGroup
}

type Job interface {
    Execute() error
}

// SimpleJob implémentation simple de Job
type SimpleJob struct {
    Task func() error
}

func (j SimpleJob) Execute() error {
    return j.Task()
}

// NewWorkerPool crée un nouveau pool de workers
func NewWorkerPool(workerCount, queueSize int) *WorkerPool {
    return &WorkerPool{
        workerCount: workerCount,
        jobQueue:    make(chan Job, queueSize),
        quit:        make(chan bool),
    }
}

// Start démarre le pool de workers
func (wp *WorkerPool) Start() {
    for i := 0; i < wp.workerCount; i++ {
        wp.wg.Add(1)
        go wp.worker(i)
    }
}

// worker fonction du worker
func (wp *WorkerPool) worker(id int) {
    defer wp.wg.Done()
    
    for {
        select {
        case job := <-wp.jobQueue:
            if err := job.Execute(); err != nil {
                fmt.Printf("Worker %d: erreur lors de l'exécution du job: %v\n", id, err)
            }
        case <-wp.quit:
            fmt.Printf("Worker %d arrêté\n", id)
            return
        }
    }
}

// Submit soumet un job au pool
func (wp *WorkerPool) Submit(job Job) {
    select {
    case wp.jobQueue <- job:
        // Job ajouté à la queue
    default:
        fmt.Println("Queue pleine, job ignoré")
    }
}

// Stop arrête le pool de workers
func (wp *WorkerPool) Stop() {
    close(wp.quit)
    wp.wg.Wait()
    close(wp.jobQueue)
}

// CircuitBreaker implémentation du pattern Circuit Breaker
type CircuitBreaker struct {
    maxFailures int
    resetTime   time.Duration
    mu          sync.RWMutex
    
    failures    int
    lastFailure time.Time
    state       CircuitState
}

type CircuitState int

const (
    Closed CircuitState = iota
    Open
    HalfOpen
)

// NewCircuitBreaker crée un nouveau circuit breaker
func NewCircuitBreaker(maxFailures int, resetTime time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        maxFailures: maxFailures,
        resetTime:   resetTime,
        state:       Closed,
    }
}

// Execute exécute une fonction à travers le circuit breaker
func (cb *CircuitBreaker) Execute(ctx context.Context, fn func() error) error {
    if !cb.canExecute() {
        return fmt.Errorf("circuit breaker ouvert")
    }
    
    err := fn()
    cb.recordResult(err)
    
    return err
}

func (cb *CircuitBreaker) canExecute() bool {
    cb.mu.RLock()
    defer cb.mu.RUnlock()
    
    switch cb.state {
    case Closed:
        return true
    case Open:
        return time.Since(cb.lastFailure) >= cb.resetTime
    case HalfOpen:
        return true
    default:
        return false
    }
}

func (cb *CircuitBreaker) recordResult(err error) {
    cb.mu.Lock()
    defer cb.mu.Unlock()
    
    if err != nil {
        cb.failures++
        cb.lastFailure = time.Now()
        
        if cb.failures >= cb.maxFailures {
            cb.state = Open
        }
    } else {
        cb.failures = 0
        cb.state = Closed
    }
}

// EnableProfiling active le profiling HTTP
func EnableProfiling(addr string) {
    go func() {
        fmt.Printf("Serveur de profiling démarré sur %s\n", addr)
        fmt.Printf("Profils disponibles:\n")
        fmt.Printf("  CPU: http://%s/debug/pprof/profile\n", addr)
        fmt.Printf("  Heap: http://%s/debug/pprof/heap\n", addr)
        fmt.Printf("  Goroutines: http://%s/debug/pprof/goroutine\n", addr)
        
        if err := http.ListenAndServe(addr, nil); err != nil {
            fmt.Printf("Erreur serveur profiling: %v\n", err)
        }
    }()
}

// PrintMemStats affiche les statistiques mémoire
func PrintMemStats() {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    
    fmt.Printf("=== Statistiques Mémoire ===\n")
    fmt.Printf("Allocs: %d KB\n", m.Alloc/1024)
    fmt.Printf("Total Allocs: %d KB\n", m.TotalAlloc/1024)
    fmt.Printf("Sys: %d KB\n", m.Sys/1024)
    fmt.Printf("Lookups: %d\n", m.Lookups)
    fmt.Printf("Mallocs: %d\n", m.Mallocs)
    fmt.Printf("Frees: %d\n", m.Frees)
    fmt.Printf("Heap Alloc: %d KB\n", m.HeapAlloc/1024)
    fmt.Printf("Heap Sys: %d KB\n", m.HeapSys/1024)
    fmt.Printf("Heap Idle: %d KB\n", m.HeapIdle/1024)
    fmt.Printf("Heap Inuse: %d KB\n", m.HeapInuse/1024)
    fmt.Printf("Stack Inuse: %d KB\n", m.StackInuse/1024)
    fmt.Printf("Stack Sys: %d KB\n", m.StackSys/1024)
    fmt.Printf("GC Runs: %d\n", m.NumGC)
    fmt.Printf("===========================\n")
}
```

## 14. Sécurité

La sécurité en Go implique la validation des entrées, la cryptographie, l'authentification et la protection contre les vulnérabilités communes.

**Principes clés :**
- Validation et sanitisation des entrées
- Cryptographie avec crypto/*
- Authentification et autorisation
- Protection contre les attaques courantes

**Exemple :**
```go
package security

import (
    "crypto/aes"
    "crypto/cipher"
    "crypto/hmac"
    "crypto/rand"
    "crypto/sha256"
    "crypto/subtle"
    "encoding/base64"
    "encoding/hex"
    "errors"
    "fmt"
    "html"
    "io"
    "net/url"
    "regexp"
    "strings"
    "time"
    "unicode"
)

// InputValidator valide et sanitise les entrées utilisateur
type InputValidator struct {
    emailRegex    *regexp.Regexp
    phoneRegex    *regexp.Regexp
    alphanumRegex *regexp.Regexp
}

// NewInputValidator crée un nouveau validateur
func NewInputValidator() *InputValidator {
    return &InputValidator{
        emailRegex:    regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`),
        phoneRegex:    regexp.MustCompile(`^\+?[1-9]\d{1,14}$`),
        alphanumRegex: regexp.MustCompile(`^[a-zA-Z0-9_-]+$`),
    }
}

// ValidateEmail valide une adresse email
func (iv *InputValidator) ValidateEmail(email string) error {
    if len(email) == 0 {
        return errors.New("email requis")
    }
    
    if len(email) > 254 {
        return errors.New("email trop long")
    }
    
    if !iv.emailRegex.MatchString(email) {
        return errors.New("format d'email invalide")
    }
    
    return nil
}

// ValidatePassword valide un mot de passe selon les critères de sécurité
func (iv *InputValidator) ValidatePassword(password string) error {
    if len(password) < 8 {
        return errors.New("mot de passe doit contenir au moins 8 caractères")
    }
    
    if len(password) > 128 {
        return errors.New("mot de passe trop long")
    }
    
    var (
        hasUpper   bool
        hasLower   bool
        hasDigit   bool
        hasSpecial bool
    )
    
    for _, r := range password {
        switch {
        case unicode.IsUpper(r):
            hasUpper = true
        case unicode.IsLower(r):
            hasLower = true
        case unicode.IsDigit(r):
            hasDigit = true
        case unicode.IsPunct(r) || unicode.IsSymbol(r):
            hasSpecial = true
        }
    }
    
    if !hasUpper {
        return errors.New("mot de passe doit contenir au moins une majuscule")
    }
    if !hasLower {
        return errors.New("mot de passe doit contenir au moins une minuscule")
    }
    if !hasDigit {
        return errors.New("mot de passe doit contenir au moins un chiffre")
    }
    if !hasSpecial {
        return errors.New("mot de passe doit contenir au moins un caractère spécial")
    }
    
    return nil
}

// SanitizeInput sanitise une entrée utilisateur
func (iv *InputValidator) SanitizeInput(input string) string {
    // Échapper HTML
    sanitized := html.EscapeString(input)
    
    // Supprimer les caractères de contrôle
    sanitized = strings.Map(func(r rune) rune {
        if r < 32 && r != '\t' && r != '\n' && r != '\r' {
            return -1
        }
        return r
    }, sanitized)
    
    // Limiter la longueur
    if len(sanitized) > 1000 {
        sanitized = sanitized[:1000]
    }
    
    return strings.TrimSpace(sanitized)
}

// ValidateURL valide une URL
func (iv *InputValidator) ValidateURL(rawURL string) (*url.URL, error) {
    if len(rawURL) == 0 {
        return nil, errors.New("URL requise")
    }
    
    if len(rawURL) > 2048 {
        return nil, errors.New("URL trop longue")
    }
    
    parsedURL, err := url.Parse(rawURL)
    if err != nil {
        return nil, fmt.Errorf("URL invalide: %w", err)
    }
    
    // Vérifier le schéma
    if parsedURL.Scheme != "http" && parsedURL.Scheme != "https" {
        return nil, errors.New("seuls les schémas HTTP et HTTPS sont autorisés")
    }
    
    // Vérifier l'hôte
    if parsedURL.Host == "" {
        return nil, errors.New("hôte requis dans l'URL")
    }
    
    return parsedURL, nil
}

// Encryptor gère le chiffrement symétrique
type Encryptor struct {
    key []byte
}

// NewEncryptor crée un nouveau chiffreur avec une clé
func NewEncryptor(key []byte) (*Encryptor, error) {
    if len(key) != 32 {
        return nil, errors.New("la clé doit faire 32 bytes pour AES-256")
    }
    
    return &Encryptor{key: key}, nil
}

// GenerateKey génère une clé aléatoire sécurisée
func GenerateKey() ([]byte, error) {
    key := make([]byte, 32)
    if _, err := io.ReadFull(rand.Reader, key); err != nil {
        return nil, err
    }
    return key, nil
}

// Encrypt chiffre des données
func (e *Encryptor) Encrypt(plaintext []byte) (string, error) {
    block, err := aes.NewCipher(e.key)
    if err != nil {
        return "", err
    }
    
    // Créer un IV aléatoire
    ciphertext := make([]byte, aes.BlockSize+len(plaintext))
    iv := ciphertext[:aes.BlockSize]
    if _, err := io.ReadFull(rand.Reader, iv); err != nil {
        return "", err
    }
    
    // Chiffrer avec CFB
    stream := cipher.NewCFBEncrypter(block, iv)
    stream.XORKeyStream(ciphertext[aes.BlockSize:], plaintext)
    
    // Encoder en base64
    return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// Decrypt déchiffre des données
func (e *Encryptor) Decrypt(ciphertext string) ([]byte, error) {
    // Décoder depuis base64
    data, err := base64.StdEncoding.DecodeString(ciphertext)
    if err != nil {
        return nil, err
    }
    
    if len(data) < aes.BlockSize {
        return nil, errors.New("ciphertext trop court")
    }
    
    block, err := aes.NewCipher(e.key)
    if err != nil {
        return nil, err
    }
    
    // Extraire IV et données
    iv := data[:aes.BlockSize]
    data = data[aes.BlockSize:]
    
    // Déchiffrer
    stream := cipher.NewCFBDecrypter(block, iv)
    stream.XORKeyStream(data, data)
    
    return data, nil
}

// TokenManager gère les tokens d'authentification
type TokenManager struct {
    signingKey []byte
    validator  *InputValidator
}

// NewTokenManager crée un nouveau gestionnaire de tokens
func NewTokenManager(signingKey []byte) *TokenManager {
    return &TokenManager{
        signingKey: signingKey,
        validator:  NewInputValidator(),
    }
}

// Token représente un token d'authentification
type Token struct {
    UserID    string    `json:"user_id"`
    Email     string    `json:"email"`
    Role      string    `json:"role"`
    IssuedAt  time.Time `json:"issued_at"`
    ExpiresAt time.Time `json:"expires_at"`
}

// GenerateToken génère un token signé
func (tm *TokenManager) GenerateToken(userID, email, role string, duration time.Duration) (string, error) {
    token := Token{
        UserID:    userID,
        Email:     email,
        Role:      role,
        IssuedAt:  time.Now(),
        ExpiresAt: time.Now().Add(duration),
    }
    
    // Créer la charge utile
    payload := fmt.Sprintf("%s|%s|%s|%d|%d",
        token.UserID, token.Email, token.Role,
        token.IssuedAt.Unix(), token.ExpiresAt.Unix())
    
    // Créer la signature HMAC
    h := hmac.New(sha256.New, tm.signingKey)
    h.Write([]byte(payload))
    signature := h.Sum(nil)
    
    // Combiner payload et signature
    tokenString := base64.StdEncoding.EncodeToString([]byte(payload)) + "." +
        base64.StdEncoding.EncodeToString(signature)
    
    return tokenString, nil
}

// ValidateToken valide et parse un token
func (tm *TokenManager) ValidateToken(tokenString string) (*Token, error) {
    parts := strings.Split(tokenString, ".")
    if len(parts) != 2 {
        return nil, errors.New("format de token invalide")
    }
    
    // Décoder le payload
    payloadBytes, err := base64.StdEncoding.DecodeString(parts[0])
    if err != nil {
        return nil, errors.New("payload invalide")
    }
    
    // Décoder la signature
    signature, err := base64.StdEncoding.DecodeString(parts[1])
    if err != nil {
        return nil, errors.New("signature invalide")
    }
    
    // Vérifier la signature
    h := hmac.New(sha256.New, tm.signingKey)
    h.Write(payloadBytes)
    expectedSignature := h.Sum(nil)
    
    if !hmac.Equal(signature, expectedSignature) {
        return nil, errors.New("signature invalide")
    }
    
    // Parser le payload
    payload := string(payloadBytes)
    parts = strings.Split(payload, "|")
    if len(parts) != 5 {
        return nil, errors.New("format de payload invalide")
    }
    
    token := &Token{
        UserID: parts[0],
        Email:  parts[1],
        Role:   parts[2],
    }
    
    // Parser les timestamps
    if issuedAt, err := time.Parse("1136239445", parts[3]); err == nil {
        token.IssuedAt = time.Unix(issuedAt.Unix(), 0)
    }
    
    if expiresAt, err := time.Parse("1136239445", parts[4]); err == nil {
        token.ExpiresAt = time.Unix(expiresAt.Unix(), 0)
    }
    
    // Vérifier l'expiration
    if time.Now().After(token.ExpiresAt) {
        return nil, errors.New("token expiré")
    }
    
    return token, nil
}

// PasswordHasher gère le hachage sécurisé des mots de passe
type PasswordHasher struct {
    iterations int
    keyLength  int
    saltLength int
}

// NewPasswordHasher crée un nouveau hasheur
func NewPasswordHasher() *PasswordHasher {
    return &PasswordHasher{
        iterations: 100000,
        keyLength:  64,
        saltLength: 32,
    }
}

// HashPassword hache un mot de passe avec sel
func (ph *PasswordHasher) HashPassword(password string) (string, error) {
    // Générer un sel aléatoire
    salt := make([]byte, ph.saltLength)
    if _, err := rand.Read(salt); err != nil {
        return "", err
    }
    
    // Hacher avec PBKDF2
    hash := ph.pbkdf2([]byte(password), salt, ph.iterations, ph.keyLength)
    
    // Combiner sel et hash
    result := append(salt, hash...)
    
    return hex.EncodeToString(result), nil
}

// VerifyPassword vérifie un mot de passe contre un hash
func (ph *PasswordHasher) VerifyPassword(password, hashedPassword string) bool {
    // Décoder le hash
    decoded, err := hex.DecodeString(hashedPassword)
    if err != nil {
        return false
    }
    
    if len(decoded) < ph.saltLength {
        return false
    }
    
    // Extraire sel et hash
    salt := decoded[:ph.saltLength]
    hash := decoded[ph.saltLength:]
    
    // Hacher le mot de passe fourni
    providedHash := ph.pbkdf2([]byte(password), salt, ph.iterations, ph.keyLength)
    
    // Comparaison sécurisée
    return subtle.ConstantTimeCompare(hash, providedHash) == 1
}

// pbkdf2 implémentation simplifiée de PBKDF2
func (ph *PasswordHasher) pbkdf2(password, salt []byte, iterations, keyLength int) []byte {
    h := hmac.New(sha256.New, password)
    h.Write(salt)
    h.Write([]byte{0, 0, 0, 1})
    u := h.Sum(nil)
    
    result := make([]byte, len(u))
    copy(result, u)
    
    for i := 1; i < iterations; i++ {
        h.Reset()
        h.Write(u)
        u = h.Sum(nil)
        
        for j := range result {
            result[j] ^= u[j]
        }
    }
    
    if len(result) > keyLength {
        return result[:keyLength]
    }
    
    return result
}

// RateLimiter implémente la limitation de taux
type RateLimiter struct {
    requests map[string][]time.Time
    mu       sync.RWMutex
    limit    int
    window   time.Duration
}

// NewRateLimiter crée un nouveau limiteur de taux
func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
    rl := &RateLimiter{
        requests: make(map[string][]time.Time),
        limit:    limit,
        window:   window,
    }
    
    // Nettoyage périodique
    go rl.cleanup()
    
    return rl
}

// Allow vérifie si une requête est autorisée
func (rl *RateLimiter) Allow(identifier string) bool {
    rl.mu.Lock()
    defer rl.mu.Unlock()
    
    now := time.Now()
    
    // Nettoyer les anciennes requêtes
    if requests, exists := rl.requests[identifier]; exists {
        var validRequests []time.Time
        for _, reqTime := range requests {
            if now.Sub(reqTime) <= rl.window {
                validRequests = append(validRequests, reqTime)
            }
        }
        rl.requests[identifier] = validRequests
    }
    
    // Vérifier la limite
    if len(rl.requests[identifier]) >= rl.limit {
        return false
    }
    
    // Ajouter la nouvelle requête
    rl.requests[identifier] = append(rl.requests[identifier], now)
    
    return true
}

func (rl *RateLimiter) cleanup() {
    ticker := time.NewTicker(time.Minute)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            rl.mu.Lock()
            now := time.Now()
            for identifier, requests := range rl.requests {
                var validRequests []time.Time
                for _, reqTime := range requests {
                    if now.Sub(reqTime) <= rl.window {
                        validRequests = append(validRequests, reqTime)
                    }
                }
                
                if len(validRequests) == 0 {
                    delete(rl.requests, identifier)
                } else {
                    rl.requests[identifier] = validRequests
                }
            }
            rl.mu.Unlock()
        }
    }
}
```

## 15. Concurrence

Go excelle dans la gestion de la concurrence avec les goroutines et les channels.

**Principes clés :**
- Goroutines légères
- Communication par channels
- Patterns de concurrence
- Synchronisation avec sync

**Exemple :**
```go
package concurrency

import (
    "context"
    "fmt"
    "runtime"
    "sync"
    "sync/atomic"
    "time"
)

// Pipeline pattern - traitement en pipeline
func Pipeline(ctx context.Context, input <-chan int) <-chan int {
    output := make(chan int)
    
    go func() {
        defer close(output)
        
        for {
            select {
            case value, ok := <-input:
                if !ok {
                    return
                }
                
                // Traitement (exemple: multiplication par 2)
                result := value * 2
                
                select {
                case output <- result:
                case <-ctx.Done():
                    return
                }
                
            case <-ctx.Done():
                return
            }
        }
    }()
    
    return output
}

// Fan-out pattern - distribuer le travail
func FanOut(ctx context.Context, input <-chan int, workerCount int) []<-chan int {
    outputs := make([]<-chan int, workerCount)
    
    for i := 0; i < workerCount; i++ {
        output := make(chan int)
        outputs[i] = output
        
        go func(out chan<- int) {
            defer close(out)
            
            for {
                select {
                case value, ok := <-input:
                    if !ok {
                        return
                    }
                    
                    select {
                    case out <- value:
                    case <-ctx.Done():
                        return
                    }
                    
                case <-ctx.Done():
                    return
                }
            }
        }(output)
    }
    
    return outputs
}

// Fan-in pattern - consolider les résultats
func FanIn(ctx context.Context, inputs ...<-chan int) <-chan int {
    output := make(chan int)
    var wg sync.WaitGroup
    
    multiplex := func(input <-chan int) {
        defer wg.Done()
        
        for {
            select {
            case value, ok := <-input:
                if !ok {
                    return
                }
                
                select {
                case output <- value:
                case <-ctx.Done():
                    return
                }
                
            case <-ctx.Done():
                return
            }
        }
    }
    
    wg.Add(len(inputs))
    for _, input := range inputs {
        go multiplex(input)
    }
    
    go func() {
        wg.Wait()
        close(output)
    }()
    
    return output
}

// WorkerPool pattern avancé avec priorités
type PriorityWorkItem struct {
    Priority int
    Task     func() error
    Result   chan error
}

type PriorityWorkerPool struct {
    workerCount int
    jobQueue    chan PriorityWorkItem
    quit        chan struct{}
    wg          sync.WaitGroup
    stats       WorkerStats
}

type WorkerStats struct {
    JobsProcessed int64
    JobsSucceeded int64
    JobsFailed    int64
    AverageTime   time.Duration
    totalTime     int64
}

// NewPriorityWorkerPool crée un pool avec priorités
func NewPriorityWorkerPool(workerCount int) *PriorityWorkerPool {
    return &PriorityWorkerPool{
        workerCount: workerCount,
        jobQueue:    make(chan PriorityWorkItem, workerCount*2),
        quit:        make(chan struct{}),
    }
}

// Start démarre le pool
func (pwp *PriorityWorkerPool) Start() {
    for i := 0; i < pwp.workerCount; i++ {
        pwp.wg.Add(1)
        go pwp.worker(i)
    }
}

func (pwp *PriorityWorkerPool) worker(id int) {
    defer pwp.wg.Done()
    
    for {
        select {
        case job := <-pwp.jobQueue:
            start := time.Now()
            err := job.Task()
            duration := time.Since(start)
            
            // Mettre à jour les statistiques
            atomic.AddInt64(&pwp.stats.JobsProcessed, 1)
            atomic.AddInt64(&pwp.stats.totalTime, int64(duration))
            
            if err != nil {
                atomic.AddInt64(&pwp.stats.JobsFailed, 1)
            } else {
                atomic.AddInt64(&pwp.stats.JobsSucceeded, 1)
            }
            
            // Calculer la moyenne
            totalJobs := atomic.LoadInt64(&pwp.stats.JobsProcessed)
            totalTime := atomic.LoadInt64(&pwp.stats.totalTime)
            if totalJobs > 0 {
                pwp.stats.AverageTime = time.Duration(totalTime / totalJobs)
            }
            
            job.Result <- err
            close(job.Result)
            
        case <-pwp.quit:
            return
        }
    }
}

// Submit soumet un job avec priorité
func (pwp *PriorityWorkerPool) Submit(priority int, task func() error) <-chan error {
    result := make(chan error, 1)
    
    job := PriorityWorkItem{
        Priority: priority,
        Task:     task,
        Result:   result,
    }
    
    select {
    case pwp.jobQueue <- job:
        return result
    default:
        // Queue pleine
        result <- fmt.Errorf("worker pool saturé")
        close(result)
        return result
    }
}

// Stop arrête le pool
func (pwp *PriorityWorkerPool) Stop() {
    close(pwp.quit)
    pwp.wg.Wait()
}

// GetStats retourne les statistiques
func (pwp *PriorityWorkerPool) GetStats() WorkerStats {
    return pwp.stats
}

// Semaphore implémentation d'un sémaphore
type Semaphore struct {
    ch chan struct{}
}

// NewSemaphore crée un nouveau sémaphore
func NewSemaphore(capacity int) *Semaphore {
    return &Semaphore{
        ch: make(chan struct{}, capacity),
    }
}

// Acquire acquiert une ressource
func (s *Semaphore) Acquire(ctx context.Context) error {
    select {
    case s.ch <- struct{}{}:
        return nil
    case <-ctx.Done():
        return ctx.Err()
    }
}

// Release libère une ressource
func (s *Semaphore) Release() {
    select {
    case <-s.ch:
    default:
        panic("semaphore: release called more times than acquire")
    }
}

// TryAcquire tente d'acquérir sans bloquer
func (s *Semaphore) TryAcquire() bool {
    select {
    case s.ch <- struct{}{}:
        return true
    default:
        return false
    }
}

// Barrier synchronisation par barrière
type Barrier struct {
    n      int
    count  int
    mu     sync.Mutex
    cond   *sync.Cond
    broken bool
}

// NewBarrier crée une nouvelle barrière
func NewBarrier(n int) *Barrier {
    b := &Barrier{n: n}
    b.cond = sync.NewCond(&b.mu)
    return b
}

// Wait attend que toutes les goroutines atteignent la barrière
func (b *Barrier) Wait() error {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    if b.broken {
        return fmt.Errorf("barrière cassée")
    }
    
    b.count++
    
    if b.count == b.n {
        // Dernière goroutine, réveiller tout le monde
        b.cond.Broadcast()
        return nil
    }
    
    // Attendre les autres
    for b.count < b.n && !b.broken {
        b.cond.Wait()
    }
    
    if b.broken {
        return fmt.Errorf("barrière cassée")
    }
    
    return nil
}

// Break casse la barrière
func (b *Barrier) Break() {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    b.broken = true
    b.cond.Broadcast()
}

// Reset remet à zéro la barrière
func (b *Barrier) Reset() {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    b.count = 0
    b.broken = false
}

// ConcurrentMap map thread-safe
type ConcurrentMap struct {
    shards []*MapShard
    count  int
}

type MapShard struct {
    mu    sync.RWMutex
    items map[string]interface{}
}

// NewConcurrentMap crée une nouvelle map concurrente
func NewConcurrentMap() *ConcurrentMap {
    shardCount := runtime.NumCPU() * 2
    cm := &ConcurrentMap{
        shards: make([]*MapShard, shardCount),
        count:  shardCount,
    }
    
    for i := 0; i < shardCount; i++ {
        cm.shards[i] = &MapShard{
            items: make(map[string]interface{}),
        }
    }
    
    return cm
}

func (cm *ConcurrentMap) getShard(key string) *MapShard {
    hash := fnv32(key)
    return cm.shards[hash%uint32(cm.count)]
}

func fnv32(key string) uint32 {
    hash := uint32(2166136261)
    const prime32 = uint32(16777619)
    for i := 0; i < len(key); i++ {
        hash *= prime32
        hash ^= uint32(key[i])
    }
    return hash
}

// Set stocke une valeur
func (cm *ConcurrentMap) Set(key string, value interface{}) {
    shard := cm.getShard(key)
    shard.mu.Lock()
    shard.items[key] = value
    shard.mu.Unlock()
}

// Get récupère une valeur
func (cm *ConcurrentMap) Get(key string) (interface{}, bool) {
    shard := cm.getShard(key)
    shard.mu.RLock()
    value, exists := shard.items[key]
    shard.mu.RUnlock()
    return value, exists
}

// Delete supprime une valeur
func (cm *ConcurrentMap) Delete(key string) {
    shard := cm.getShard(key)
    shard.mu.Lock()
    delete(shard.items, key)
    shard.mu.Unlock()
}

// Keys retourne toutes les clés
func (cm *ConcurrentMap) Keys() []string {
    var keys []string
    
    for _, shard := range cm.shards {
        shard.mu.RLock()
        for key := range shard.items {
            keys = append(keys, key)
        }
        shard.mu.RUnlock()
    }
    
    return keys
}

// BroadcastChannel diffuse des messages à plusieurs listeners
type BroadcastChannel struct {
    mu        sync.RWMutex
    listeners map[int]chan interface{}
    nextID    int
    closed    bool
}

// NewBroadcastChannel crée un nouveau canal de diffusion
func NewBroadcastChannel() *BroadcastChannel {
    return &BroadcastChannel{
        listeners: make(map[int]chan interface{}),
    }
}

// Subscribe s'abonne aux messages
func (bc *BroadcastChannel) Subscribe() (<-chan interface{}, func()) {
    bc.mu.Lock()
    defer bc.mu.Unlock()
    
    if bc.closed {
        ch := make(chan interface{})
        close(ch)
        return ch, func() {}
    }
    
    id := bc.nextID
    bc.nextID++
    
    ch := make(chan interface{}, 10)
    bc.listeners[id] = ch
    
    unsubscribe := func() {
        bc.mu.Lock()
        defer bc.mu.Unlock()
        
        if listener, exists := bc.listeners[id]; exists {
            close(listener)
            delete(bc.listeners, id)
        }
    }
    
    return ch, unsubscribe
}

// Broadcast diffuse un message à tous les listeners
func (bc *BroadcastChannel) Broadcast(message interface{}) {
    bc.mu.RLock()
    defer bc.mu.RUnlock()
    
    if bc.closed {
        return
    }
    
    for _, listener := range bc.listeners {
        select {
        case listener <- message:
        default:
            // Listener saturé, on ignore
        }
    }
}

// Close ferme le canal de diffusion
func (bc *BroadcastChannel) Close() {
    bc.mu.Lock()
    defer bc.mu.Unlock()
    
    if bc.closed {
        return
    }
    
    bc.closed = true
    
    for _, listener := range bc.listeners {
        close(listener)
    }
    
    bc.listeners = nil
}
```

## 16. Versionnement

Go utilise go.mod pour la gestion des dépendances et le versionnement sémantique.

**Principes clés :**
- Versionnement sémantique (SemVer)
- Go modules pour les dépendances
- Compatibilité et migration
- Documentation des changements

**Exemple :**
```go
// go.mod
module github.com/monprojet/myapp

go 1.21

require (
    github.com/gorilla/mux v1.8.0
    github.com/lib/pq v1.10.9
    github.com/sirupsen/logrus v1.9.3
)

require (
    golang.org/x/sys v0.0.0-20220715151400-c0bba94af5f8 // indirect
)
```

```go
package version

import (
    "fmt"
    "runtime"
    "time"
)

// Version informations de version de l'application
type Version struct {
    Major      int       `json:"major"`
    Minor      int       `json:"minor"`
    Patch      int       `json:"patch"`
    PreRelease string    `json:"pre_release,omitempty"`
    BuildMeta  string    `json:"build_meta,omitempty"`
    GitCommit  string    `json:"git_commit,omitempty"`
    BuildTime  time.Time `json:"build_time"`
    GoVersion  string    `json:"go_version"`
}

// Variables définies au moment de la compilation
var (
    // Ces variables sont définies par ldflags lors du build
    // go build -ldflags "-X main.version=1.0.0 -X main.gitCommit=abc123"
    version   = "dev"
    gitCommit = "unknown"
    buildTime = "unknown"
)

// Current version actuelle de l'application
var Current = Version{
    Major:     1,
    Minor:     0,
    Patch:     0,
    GitCommit: gitCommit,
    GoVersion: runtime.Version(),
}

func init() {
    // Parser la version
    if version != "dev" {
        Current.parseVersion(version)
    }
    
    // Parser le temps de build
    if buildTime != "unknown" {
        if t, err := time.Parse(time.RFC3339, buildTime); err == nil {
            Current.BuildTime = t
        }
    } else {
        Current.BuildTime = time.Now()
    }
}

// parseVersion parse une chaîne de version sémantique
func (v *Version) parseVersion(versionStr string) {
    // Implémentation simplifiée du parsing SemVer
    // Dans un vrai projet, utilisez une bibliothèque comme semver
    fmt.Sscanf(versionStr, "%d.%d.%d", &v.Major, &v.Minor, &v.Patch)
}

// String retourne la version sous forme de chaîne
func (v Version) String() string {
    version := fmt.Sprintf("%d.%d.%d", v.Major, v.Minor, v.Patch)
    
    if v.PreRelease != "" {
        version += "-" + v.PreRelease
    }
    
    if v.BuildMeta != "" {
        version += "+" + v.BuildMeta
    }
    
    return version
}

// FullVersion retourne les informations complètes de version
func (v Version) FullVersion() string {
    return fmt.Sprintf("%s (commit: %s, built: %s, go: %s)",
        v.String(),
        v.GitCommit,
        v.BuildTime.Format("2006-01-02 15:04:05"),
        v.GoVersion,
    )
}

// IsCompatible vérifie la compatibilité avec une autre version
func (v Version) IsCompatible(other Version) bool {
    // Selon SemVer, les versions sont compatibles si:
    // 1. Même version majeure (pour v1+)
    // 2. Version mineure >= à la version requise
    
    if v.Major == 0 || other.Major == 0 {
        // Version 0.x.x considérée comme instable
        return v.Major == other.Major && v.Minor == other.Minor
    }
    
    if v.Major != other.Major {
        return false
    }
    
    return v.Minor >= other.Minor
}

// DependencyManager gère les dépendances et leur compatibilité
type DependencyManager struct {
    dependencies map[string]DependencyInfo
}

type DependencyInfo struct {
    Name            string    `json:"name"`
    CurrentVersion  Version   `json:"current_version"`
    RequiredVersion Version   `json:"required_version"`
    LastChecked     time.Time `json:"last_checked"`
    IsCompatible    bool      `json:"is_compatible"`
    UpdateAvailable bool      `json:"update_available"`
}

// NewDependencyManager crée un nouveau gestionnaire de dépendances
func NewDependencyManager() *DependencyManager {
    return &DependencyManager{
        dependencies: make(map[string]DependencyInfo),
    }
}

// AddDependency ajoute une dépendance
func (dm *DependencyManager) AddDependency(name string, current, required Version) {
    dm.dependencies[name] = DependencyInfo{
        Name:            name,
        CurrentVersion:  current,
        RequiredVersion: required,
        LastChecked:     time.Now(),
        IsCompatible:    current.IsCompatible(required),
    }
}

// CheckCompatibility vérifie la compatibilité de toutes les dépendances
func (dm *DependencyManager) CheckCompatibility() []string {
    var issues []string
    
    for name, dep := range dm.dependencies {
        if !dep.IsCompatible {
            issues = append(issues, fmt.Sprintf(
                "Dépendance incompatible: %s (actuelle: %s, requise: %s)",
                name, dep.CurrentVersion.String(), dep.RequiredVersion.String(),
            ))
        }
    }
    
    return issues
}

// Migration gère les migrations de version
type Migration struct {
    FromVersion Version
    ToVersion   Version
    Description string
    MigrateFunc func() error
}

// MigrationManager gère les migrations
type MigrationManager struct {
    migrations []Migration
    current    Version
}

// NewMigrationManager crée un nouveau gestionnaire de migrations
func NewMigrationManager(currentVersion Version) *MigrationManager {
    return &MigrationManager{
        current: currentVersion,
    }
}

// AddMigration ajoute une migration
func (mm *MigrationManager) AddMigration(from, to Version, description string, migrateFunc func() error) {
    mm.migrations = append(mm.migrations, Migration{
        FromVersion: from,
        ToVersion:   to,
        Description: description,
        MigrateFunc: migrateFunc,
    })
}

// RunMigrations exécute les migrations nécessaires
func (mm *MigrationManager) RunMigrations(targetVersion Version) error {
    fmt.Printf("Migration de %s vers %s\n", mm.current.String(), targetVersion.String())
    
    // Trouver et exécuter les migrations dans l'ordre
    for _, migration := range mm.migrations {
        // Vérifier si cette migration est nécessaire
        if mm.current.IsCompatible(migration.FromVersion) && 
           !targetVersion.IsCompatible(migration.ToVersion) {
            
            fmt.Printf("Exécution de la migration: %s\n", migration.Description)
            
            if err := migration.MigrateFunc(); err != nil {
                return fmt.Errorf("erreur lors de la migration %s: %w", 
                    migration.Description, err)
            }
            
            mm.current = migration.ToVersion
            fmt.Printf("Migration terminée vers %s\n", mm.current.String())
        }
    }
    
    return nil
}

// ChangelogEntry entrée de changelog
type ChangelogEntry struct {
    Version     Version   `json:"version"`
    Date        time.Time `json:"date"`
    Changes     []Change  `json:"changes"`
    Breaking    bool      `json:"breaking"`
    Description string    `json:"description"`
}

type Change struct {
    Type        string `json:"type"` // added, changed, deprecated, removed, fixed, security
    Description string `json:"description"`
    IssueNumber string `json:"issue_number,omitempty"`
}

// Changelog gestionnaire de changelog
type Changelog struct {
    entries []ChangelogEntry
}

// NewChangelog crée un nouveau changelog
func NewChangelog() *Changelog {
    return &Changelog{}
}

// AddEntry ajoute une entrée au changelog
func (cl *Changelog) AddEntry(entry ChangelogEntry) {
    cl.entries = append(cl.entries, entry)
}

// GetChanges retourne les changements entre deux versions
func (cl *Changelog) GetChanges(from, to Version) []ChangelogEntry {
    var changes []ChangelogEntry
    
    for _, entry := range cl.entries {
        // Inclure les changements entre from et to
        if (entry.Version.Major > from.Major || 
           (entry.Version.Major == from.Major && entry.Version.Minor > from.Minor) ||
           (entry.Version.Major == from.Major && entry.Version.Minor == from.Minor && entry.Version.Patch > from.Patch)) &&
           (entry.Version.Major < to.Major || 
           (entry.Version.Major == to.Major && entry.Version.Minor < to.Minor) ||
           (entry.Version.Major == to.Major && entry.Version.Minor == to.Minor && entry.Version.Patch <= to.Patch)) {
            
            changes = append(changes, entry)
        }
    }
    
    return changes
}

// BuildInfo informations de build
type BuildInfo struct {
    Version    Version           `json:"version"`
    BuildTime  time.Time         `json:"build_time"`
    GitCommit  string            `json:"git_commit"`
    GitBranch  string            `json:"git_branch"`
    BuildUser  string            `json:"build_user"`
    BuildHost  string            `json:"build_host"`
    GoVersion  string            `json:"go_version"`
    Platform   string            `json:"platform"`
    Tags       []string          `json:"tags"`
    Settings   map[string]string `json:"settings"`
}

// GetBuildInfo retourne les informations de build
func GetBuildInfo() BuildInfo {
    return BuildInfo{
        Version:   Current,
        BuildTime: Current.BuildTime,
        GitCommit: Current.GitCommit,
        GoVersion: runtime.Version(),
        Platform:  fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH),
        Settings:  make(map[string]string),
    }
}

// Example d'utilisation complète
func ExampleVersionManagement() {
    // Afficher la version actuelle
    fmt.Printf("Version actuelle: %s\n", Current.FullVersion())
    
    // Vérifier la compatibilité
    requiredVersion := Version{Major: 1, Minor: 0, Patch: 0}
    if Current.IsCompatible(requiredVersion) {
        fmt.Println("Version compatible")
    }
    
    // Gestionnaire de dépendances
    dm := NewDependencyManager()
    dm.AddDependency("github.com/gorilla/mux", 
        Version{Major: 1, Minor: 8, Patch: 0},
        Version{Major: 1, Minor: 7, Patch: 0})
    
    if issues := dm.CheckCompatibility(); len(issues) > 0 {
        for _, issue := range issues {
            fmt.Println("Problème de compatibilité:", issue)
        }
    }
    
    // Migrations
    mm := NewMigrationManager(Current)
    mm.AddMigration(
        Version{Major: 0, Minor: 9, Patch: 0},
        Version{Major: 1, Minor: 0, Patch: 0},
        "Migration vers v1.0 - Changements breaking dans l'API",
        func() error {
            fmt.Println("Exécution de la migration de l'API...")
            return nil
        },
    )
    
    // Changelog
    changelog := NewChangelog()
    changelog.AddEntry(ChangelogEntry{
        Version: Version{Major: 1, Minor: 0, Patch: 0},
        Date:    time.Now(),
        Changes: []Change{
            {Type: "added", Description: "Nouvelle API REST"},
            {Type: "changed", Description: "Format de configuration modifié"},
            {Type: "removed", Description: "Support des anciens endpoints"},
        },
        Breaking:    true,
        Description: "Version majeure avec changements breaking",
    })
}
```

## Conclusion

Ces 16 bases de la programmation en Go forment un socle solide pour développer des applications robustes, maintenables et performantes. Go, avec sa philosophie de simplicité et d'efficacité, offre des outils intégrés et des patterns idiomatiques qui facilitent l'application de ces principes.

### Points clés de Go pour chaque base :

1. **Modularité** : Les packages Go encouragent naturellement la séparation des responsabilités
2. **Abstraction** : Les interfaces implicites permettent un découplage élégant
3. **Encapsulation** : Convention de nommage simple pour contrôler la visibilité
4. **Composition** : Embedding et interfaces favorisent la composition over inheritance
5. **Polymorphisme** : Interfaces permettent un polymorphisme naturel et type-safe
6. **Composition** : Structures et embedding pour construire des objets complexes
7. **Interfaces** : Contrats implicites et petites interfaces spécialisées
8. **Gestion d'erreurs** : Erreurs explicites et wrapping pour un debugging efficace
9. **Tests** : Framework intégré avec table-driven tests et benchmarks
10. **Documentation** : godoc intégré pour une documentation automatique
11. **Configuration** : Variables d'environnement et validation structurée
12. **Journalisation** : Logs structurés avec rotation et niveaux
13. **Performance** : Profiling intégré, concurrence efficace et optimisations mémoire
14. **Sécurité** : Crypto robuste, validation stricte et patterns sécurisés
15. **Concurrence** : Goroutines et channels pour une concurrence simple et sûre
16. **Versionnement** : Go modules et SemVer pour une gestion moderne des dépendances

### Avantages spécifiques de Go :

- **Simplicité** : Syntaxe claire et idiomes bien définis
- **Performance** : Compilation native et garbage collector optimisé
- **Concurrence** : Modèle CSP avec goroutines légères
- **Tooling** : Outils intégrés (go fmt, go test, go mod, pprof)
- **Déploiement** : Binaires statiques pour un déploiement simplifié
- **Écosystème** : Bibliothèques standard riches et communauté active

### Recommandations pour l'application :

1. **Commencer simple** : Appliquer les bases progressivement
2. **Utiliser les outils Go** : go fmt, go vet, go test systématiquement
3. **Suivre les conventions** : gofmt, naming conventions, project layout
4. **Tester régulièrement** : Tests unitaires et benchmarks
5. **Mesurer avant d'optimiser** : Utiliser pprof pour identifier les goulots
6. **Privilégier la lisibilité** : Code clair plutôt que clever
7. **Gérer les erreurs explicitement** : Ne jamais ignorer les erreurs
8. **Documenter les APIs publiques** : Commentaires godoc systématiques

### Mise en pratique dans les projets :

Chaque mode opérationnel de notre projet s'appuie sur ces bases pour :
- **Résoudre des problèmes spécifiques** avec des solutions robustes
- **Accomplir des tâches particulières** de manière efficace
- **Maintenir la qualité du code** à long terme
- **Faciliter la collaboration** en équipe
- **Assurer la scalabilité** des applications

L'application systématique de ces 16 bases, combinée aux spécificités de Go, nous permet de développer des logiciels de haute qualité qui sont à la fois performants, sécurisés et maintenables.

**"Don't communicate by sharing memory; share memory by communicating."** - Rob Pike

Cette philosophie de Go, comme ces 16 bases, guide notre approche du développement vers plus de simplicité, de robustesse et d'efficacité.