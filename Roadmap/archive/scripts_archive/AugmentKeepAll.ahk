#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 2
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

; Configuration
dialogTitle := "Augment"  ; Titre de la fenêtre Augment
checkInterval := 200  ; Vérifier toutes les 200ms
buttonText := "Keep All"  ; Texte du bouton à rechercher

; Raccourci manuel pour déclencher la recherche (Ctrl+Alt+K)
^!k::
    DetectAndClickKeepAll()
return

; Surveillance automatique
SetTimer, AutoDetectKeepAll, %checkInterval%

; Fonction de détection automatique
AutoDetectKeepAll:
    DetectAndClickKeepAll()
return

; Fonction principale pour détecter et cliquer sur le bouton Keep All
DetectAndClickKeepAll() {
    ; Vérifier si une fenêtre Augment est active
    if WinExist(dialogTitle) {
        ; Sauvegarder la position actuelle de la souris
        MouseGetPos, originalX, originalY

        ; Obtenir les dimensions de la fenêtre
        WinGetPos, winX, winY, winWidth, winHeight, %dialogTitle%

        ; Rechercher le bouton "Keep All" par sa couleur bleue caractéristique
        ; Coordonnées probables du bouton (partie inférieure droite de la fenêtre)
        buttonX := winX + winWidth * 0.75
        buttonY := winY + winHeight * 0.85

        ; Vérifier la présence du bouton bleu
        PixelSearch, foundX, foundY, winX + winWidth * 0.6, winY + winHeight * 0.7, winX + winWidth * 0.9, winY + winHeight * 0.9, 0x0078D4, 20, Fast RGB
        if (ErrorLevel = 0) {
            ; Bouton trouvé, cliquer dessus
            MouseClick, left, foundX, foundY

            ; Afficher une notification
            TrayTip, AutoHotkey, Bouton "Keep All" cliqué automatiquement, 1

            ; Restaurer la position de la souris
            MouseMove, originalX, originalY, 0
            return true
        }

        ; Méthode alternative: rechercher dans des positions prédéfinies
        buttonPositions := [
            [winX + winWidth * 0.75, winY + winHeight * 0.85],  ; Position probable 1
            [winX + winWidth * 0.8, winY + winHeight * 0.8],    ; Position probable 2
            [winX + winWidth * 0.7, winY + winHeight * 0.9]     ; Position probable 3
        ]

        ; Vérifier si un texte ressemblant à "Keep All" est présent
        for index, pos in buttonPositions {
            ; Déplacer la souris à la position
            MouseMove, pos[1], pos[2], 0
            Sleep, 50

            ; Cliquer à cette position
            MouseClick, left, pos[1], pos[2]
            Sleep, 100

            ; Vérifier si la boîte de dialogue a disparu
            if (!WinExist("A")) {
                TrayTip, AutoHotkey, Bouton "Keep All" cliqué (position alternative), 1

                ; Restaurer la position de la souris
                MouseMove, originalX, originalY, 0
                return true
            }
        }

        ; Restaurer la position de la souris si aucun bouton n'a été trouvé
        MouseMove, originalX, originalY, 0
    }

    return false
}

; Fonction pour détecter les boîtes de dialogue par leur contenu
DetectDialogByContent() {
    ; Capturer l'écran pour OCR (nécessite une bibliothèque OCR)
    ; Cette partie est commentée car elle nécessite des bibliothèques supplémentaires
    ; Vous pouvez l'implémenter si vous avez besoin d'une détection plus précise
    return false
}

; Afficher un message au démarrage
TrayTip, AutoHotkey, Script de validation automatique "Keep All" démarré, 2