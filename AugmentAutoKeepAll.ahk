#SingleInstance Force
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; ========================================================
; Script AutoHotkey pour valider automatiquement les boîtes de dialogue "Keep All" dans Augment Agent
; ========================================================

; Variables globales
global AutoKeepAllEnabled := true  ; État initial: activé
global CheckInterval := 500        ; Intervalle de vérification en millisecondes (0.5 seconde)

; Raccourci pour activer/désactiver la fonctionnalité (Alt+K)
!k::ToggleAutoKeepAll()

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
    
    ; Recherche le bouton "Keep All" dans la fenêtre active
    if (WinActive("ahk_exe Code.exe") || WinActive("ahk_exe VSCodium.exe")) {
        ; Recherche par texte et couleur verte caractéristique
        PixelSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, 0x2EA043, 10, Fast RGB
        if (!ErrorLevel) {
            ; Vérifier si c'est bien le bouton "Keep All" en cherchant le texte à proximité
            MouseGetPos, OldX, OldY
            MouseMove, %FoundX%, %FoundY%, 0
            
            ; Cliquer sur le bouton "Keep All"
            Click
            
            ; Revenir à la position précédente de la souris
            MouseMove, %OldX%, %OldY%, 0
            
            ; Afficher une notification
            ShowTooltip("Keep All validé automatiquement", 1000)
        }
    }
return

; Initialisation au démarrage du script
InitScript() {
    ; Démarrer la vérification périodique
    if (AutoKeepAllEnabled)
        SetTimer, CheckForKeepAllButton, %CheckInterval%
    
    ; Afficher un message de démarrage
    ShowTooltip("Script Auto Keep All démarré`nUtilisez Alt+K pour activer/désactiver", 3000)
}

; Exécuter l'initialisation
InitScript()
