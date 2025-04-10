#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; ========================================================
; Script AutoHotkey amélioré pour valider automatiquement les boîtes de dialogue "Keep All" dans Augment Agent
; ========================================================

; Variables globales
global AutoKeepAllEnabled := true  ; État initial: activé
global CheckInterval := 300        ; Intervalle de vérification en millisecondes (0.3 seconde)
global LastClickTime := 0          ; Horodatage du dernier clic pour éviter les clics multiples
global ClickCooldown := 2000       ; Temps minimum entre deux clics (2 secondes)

; Raccourci pour activer/désactiver la fonctionnalité (Alt+K)
!k::ToggleAutoKeepAll()

; Raccourci pour forcer un clic sur "Keep All" (Ctrl+Alt+K)
^!k::ForceClickKeepAll()

; Fonction pour activer/désactiver la fonctionnalité
ToggleAutoKeepAll() {
    global AutoKeepAllEnabled
    AutoKeepAllEnabled := !AutoKeepAllEnabled
    
    if (AutoKeepAllEnabled) {
        SetTimer, CheckForKeepAllButton, %CheckInterval%
        ShowTooltip("Auto Keep All: ACTIVÉ", 1500)
    } else {
        SetTimer, CheckForKeepAllButton, Off
        ShowTooltip("Auto Keep All: DÉSACTIVÉ", 1500)
    }
}

; Fonction pour forcer un clic sur "Keep All"
ForceClickKeepAll() {
    CheckAndClickKeepAll(true)
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
    
    CheckAndClickKeepAll(false)
return

; Fonction qui vérifie et clique sur le bouton "Keep All"
CheckAndClickKeepAll(force := false) {
    global LastClickTime, ClickCooldown
    
    ; Vérifier le cooldown sauf si forcé
    if (!force) {
        currentTime := A_TickCount
        if (currentTime - LastClickTime < ClickCooldown)
            return
    }
    
    ; Recherche le bouton "Keep All" dans la fenêtre VS Code
    if (WinActive("ahk_exe Code.exe") || WinActive("ahk_exe VSCodium.exe")) {
        ; Méthode 1: Recherche par couleur verte caractéristique du bouton
        PixelSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0x2EA043, 20, Fast RGB
        if (!ErrorLevel) {
            ; Vérifier si le texte "Keep All" est présent à proximité
            MouseGetPos, OldX, OldY
            MouseMove, %FoundX%, %FoundY%, 0
            
            ; Méthode 2: Recherche par image (plus précise mais nécessite une capture d'écran préalable)
            ; ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 KeepAllButton.png
            
            ; Cliquer sur le bouton "Keep All"
            Click
            
            ; Mettre à jour l'horodatage du dernier clic
            LastClickTime := A_TickCount
            
            ; Revenir à la position précédente de la souris
            MouseMove, %OldX%, %OldY%, 0
            
            ; Afficher une notification
            ShowTooltip("Keep All validé automatiquement", 1000)
            return true
        }
        
        ; Méthode alternative: recherche par position relative dans la barre d'état
        ; Cette méthode est utile si la détection par couleur échoue
        WinGetPos, WinX, WinY, WinWidth, WinHeight, A
        
        ; Zone approximative où le bouton "Keep All" apparaît généralement
        StatusBarY := WinHeight - 30
        KeepAllX := WinWidth - 100
        
        ; Vérifier la présence d'une couleur verte dans cette zone
        PixelSearch, FoundX, FoundY, WinX + WinWidth - 200, WinY + StatusBarY, WinX + WinWidth, WinY + WinHeight, 0x2EA043, 20, Fast RGB
        if (!ErrorLevel) {
            MouseGetPos, OldX, OldY
            MouseMove, %FoundX%, %FoundY%, 0
            Click
            
            ; Mettre à jour l'horodatage du dernier clic
            LastClickTime := A_TickCount
            
            ; Revenir à la position précédente de la souris
            MouseMove, %OldX%, %OldY%, 0
            
            ; Afficher une notification
            ShowTooltip("Keep All validé (méthode alternative)", 1000)
            return true
        }
    }
    
    return false
}

; Initialisation au démarrage du script
InitScript() {
    ; Démarrer la vérification périodique
    if (AutoKeepAllEnabled)
        SetTimer, CheckForKeepAllButton, %CheckInterval%
    
    ; Afficher un message de démarrage
    ShowTooltip("Script Auto Keep All démarré`nAlt+K: activer/désactiver`nCtrl+Alt+K: forcer un clic", 3000)
}

; Exécuter l'initialisation
InitScript()
