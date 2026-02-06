# =============================================================================
# FILINO - Configuration des chemins vers les outils externes
# =============================================================================
# Instructions :
# - Aucun espace dans les chemins de dossiers.
# - Les séparateurs "/" ou "\\" dépendent des outils utilisés.
# - Installer QGIS directement dans "C:/QGIS" pour éviter les conflits.
# =============================================================================

# ----------------------------------------------------------------------------
# 🔍 Astuce pour rechercher une variable dans RStudio :
#   - Utilisez "Ctrl + Shift + F" pour rechercher une variable dans un dossier.
# ----------------------------------------------------------------------------

# =============================================================================
# CHEMINS VERS LES OUTILS (À ADAPTER SELON VOTRE ENVIRONNEMENT)
# =============================================================================

# --------------------------
# 📌 OSGeo4W (pour QGIS/GRASS)
# --------------------------
# Chemin vers le fichier OSGeo4W.bat (nécessaire pour exécuter QGIS/GRASS en ligne de commande)
OSGeo4W_path <- "C:/QGIS/OSGeo4W.bat"

# --------------------------
# 🌿 GRASS GIS
# --------------------------
# Chemin vers le fichier batch de GRASS (version 8.4)
BatGRASS <- "C:\\QGIS\\bin\\grass84.bat"

# --------------------------
# 🗺️ PDAL (Point Data Abstraction Library)
# --------------------------
# Chemin vers l'exécutable PDAL (pour le traitement des nuages de points LiDAR)
pdal_exe <- "C:/QGIS/bin/pdal.exe"

# --------------------------
# 🖥️ QGIS (traitements en ligne de commande)
# --------------------------
# Chemin vers qgis_process (pour exécuter des algorithmes QGIS en script)
# Deux versions possibles selon votre installation :
# qgis_process <- "C:/QGIS/bin/qgis_process-qgis-ltr.bat"  # Version LTR (Long Term Release)
qgis_process <- "C:/QGIS/bin/qgis_process-qgis-qt6.bat"  # Version Qt6

# --------------------------
# 🎥 FFmpeg (pour les vidéos de démonstration)
# --------------------------
# Chemin vers ffmpeg (installé avec l'extension Crayfish dans QGIS)
# Note : FFmpeg est généralement installé automatiquement après la première utilisation de Crayfish.
ffmpeg <- "C:\\Users\\frederic.pons\\AppData\\Roaming\\QGIS\\QGIS3\\profiles\\default\\python\\plugins\\crayfish\\ffmpeg.exe"

# =============================================================================
# NOTES IMPORTANTES :
# =============================================================================
# 1. Vérifiez que tous les chemins correspondent à votre installation.
# 2. Si un outil n'est pas trouvé, vérifiez :
#    - L'orthographe du chemin.
#    - Que le fichier existe bien à l'emplacement indiqué.
# 3. Pour FFmpeg, si le chemin ne fonctionne pas, installez FFmpeg manuellement :
#    - Téléchargez FFmpeg depuis https://ffmpeg.org/
#    - Ajoutez-le à votre PATH ou spécifiez le chemin absolu ici.
# =============================================================================
