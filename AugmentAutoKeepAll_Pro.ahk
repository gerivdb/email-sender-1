#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1  ; Exécution maximale pour une meilleure réactivité

; ========================================================
; Script AutoHotkey professionnel pour valider automatiquement 
; les boîtes de dialogue "Keep All" dans Augment Agent
; ========================================================

; ========== CONFIGURATION ==========
; Vous pouvez modifier ces paramètres selon vos préférences

; Paramètres généraux
global AutoKeepAllEnabled := true   ; État initial: activé
global CheckInterval := 250         ; Intervalle de vérification en ms (0.25 seconde)
global ClickCooldown := 1500        ; Temps minimum entre deux clics (1.5 secondes)
global DebugMode := false           ; Activer/désactiver le mode débogage

; Paramètres de détection
global ColorVariation := 30         ; Tolérance pour la détection de couleur (0-255)
global KeepAllColor := 0x2EA043     ; Couleur verte du bouton "Keep All" (format 0xRRGGBB)
global UndoAllColor := 0x6E7681     ; Couleur grise du bouton "Undo All" (pour référence)

; Raccourcis clavier
global ToggleHotkey := "!k"         ; Alt+K: Activer/désactiver la fonctionnalité
global ForceClickHotkey := "^!k"    ; Ctrl+Alt+K: Forcer un clic sur "Keep All"
global DebugHotkey := "^!d"         ; Ctrl+Alt+D: Activer/désactiver le mode débogage

; ========== VARIABLES INTERNES ==========
global LastClickTime := 0           ; Horodatage du dernier clic
global DetectionMethod := 1         ; Méthode de détection actuelle (rotation)
global DetectionAttempts := 0       ; Nombre de tentatives de détection

; ========== RACCOURCIS CLAVIER ==========
Hotkey, %ToggleHotkey%, ToggleAutoKeepAll
Hotkey, %ForceClickHotkey%, ForceClickKeepAll
Hotkey, %DebugHotkey%, ToggleDebugMode

; ========== FONCTIONS PRINCIPALES ==========

; Fonction pour activer/désactiver la fonctionnalité
ToggleAutoKeepAll() {
    global AutoKeepAllEnabled, CheckInterval
    AutoKeepAllEnabled := !AutoKeepAllEnabled
    
    if (AutoKeepAllEnabled) {
        SetTimer, CheckForKeepAllButton, %CheckInterval%
        ShowTooltip("Auto Keep All: ACTIVÉ", 1500)
    } else {
        SetTimer, CheckForKeepAllButton, Off
        ShowTooltip("Auto Keep All: DÉSACTIVÉ", 1500)
    }
}

; Fonction pour activer/désactiver le mode débogage
ToggleDebugMode() {
    global DebugMode
    DebugMode := !DebugMode
    ShowTooltip("Mode débogage: " . (DebugMode ? "ACTIVÉ" : "DÉSACTIVÉ"), 1500)
}

; Fonction pour forcer un clic sur "Keep All"
ForceClickKeepAll() {
    global DetectionMethod, DetectionAttempts
    
    ; Réinitialiser les compteurs pour essayer toutes les méthodes
    DetectionMethod := 1
    DetectionAttempts := 0
    
    ; Essayer chaque méthode de détection jusqu'à ce qu'une réussisse
    Loop, 3 {
        if (CheckAndClickKeepAll(true))
            return
        
        ; Passer à la méthode suivante
        DetectionMethod := Mod(DetectionMethod, 3) + 1
    }
    
    ShowTooltip("Impossible de trouver le bouton Keep All", 1500)
}

; Fonction pour afficher une infobulle temporaire
ShowTooltip(text, duration) {
    Tooltip, %text%
    SetTimer, RemoveTooltip, %duration%
}

; Fonction pour supprimer l'infobulle
RemoveTooltip() {
    Tooltip
}

; Fonction principale qui vérifie et clique sur le bouton "Keep All"
CheckForKeepAllButton:
    if (!AutoKeepAllEnabled)
        return
    
    ; Incrémenter le compteur de tentatives
    DetectionAttempts++
    
    ; Changer de méthode toutes les 10 tentatives
    if (Mod(DetectionAttempts, 10) = 0)
        DetectionMethod := Mod(DetectionMethod, 3) + 1
    
    CheckAndClickKeepAll(false)
return

; Fonction qui vérifie et clique sur le bouton "Keep All"
CheckAndClickKeepAll(force := false) {
    global LastClickTime, ClickCooldown, DetectionMethod, DebugMode
    global ColorVariation, KeepAllColor
    
    ; Vérifier le cooldown sauf si forcé
    if (!force) {
        currentTime := A_TickCount
        if (currentTime - LastClickTime < ClickCooldown)
            return false
    }
    
    ; Vérifier si VS Code est actif
    if (!WinActive("ahk_exe Code.exe") && !WinActive("ahk_exe VSCodium.exe"))
        return false
    
    ; Obtenir les dimensions de la fenêtre
    WinGetPos, WinX, WinY, WinWidth, WinHeight, A
    
    ; Méthode de détection en fonction de DetectionMethod
    found := false
    FoundX := 0
    FoundY := 0
    
    if (DetectionMethod = 1) {
        ; Méthode 1: Recherche par couleur dans toute la fenêtre
        if (DebugMode)
            ShowTooltip("Méthode 1: Recherche par couleur globale", 500)
        
        PixelSearch, FoundX, FoundY, WinX, WinY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, %ColorVariation%, Fast RGB
        found := !ErrorLevel
    }
    else if (DetectionMethod = 2) {
        ; Méthode 2: Recherche dans la barre d'état (bas de la fenêtre)
        if (DebugMode)
            ShowTooltip("Méthode 2: Recherche dans la barre d'état", 500)
        
        StatusBarY := WinHeight - 30
        PixelSearch, FoundX, FoundY, WinX, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, %ColorVariation%, Fast RGB
        found := !ErrorLevel
    }
    else if (DetectionMethod = 3) {
        ; Méthode 3: Recherche dans la zone spécifique où apparaît généralement le bouton
        if (DebugMode)
            ShowTooltip("Méthode 3: Recherche dans la zone spécifique", 500)
        
        StatusBarY := WinHeight - 30
        KeepAllX := WinWidth - 150
        PixelSearch, FoundX, FoundY, WinX + WinWidth - 200, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, %KeepAllColor%, %ColorVariation%, Fast RGB
        found := !ErrorLevel
    }
    
    ; Si le bouton est trouvé, cliquer dessus
    if (found) {
        ; Sauvegarder la position actuelle de la souris
        MouseGetPos, OldX, OldY
        
        ; Déplacer la souris et cliquer
        MouseMove, %FoundX%, %FoundY%, 0
        Click
        
        ; Mettre à jour l'horodatage du dernier clic
        LastClickTime := A_TickCount
        
        ; Revenir à la position précédente de la souris
        MouseMove, %OldX%, %OldY%, 0
        
        ; Afficher une notification
        methodName := "Méthode " . DetectionMethod
        ShowTooltip("Keep All validé (" . methodName . ")", 1000)
        return true
    }
    
    return false
}

; ========== INITIALISATION ==========
InitScript() {
    ; Démarrer la vérification périodique
    if (AutoKeepAllEnabled)
        SetTimer, CheckForKeepAllButton, %CheckInterval%
    
    ; Afficher un message de démarrage
    startupMsg := "Script Auto Keep All Pro démarré`n"
                . "Alt+K: activer/désactiver`n"
                . "Ctrl+Alt+K: forcer un clic`n"
                . "Ctrl+Alt+D: mode débogage"
    
    ShowTooltip(startupMsg, 3000)
}

; Exécuter l'initialisation
InitScript()
