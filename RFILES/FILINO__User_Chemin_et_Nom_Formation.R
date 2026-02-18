# =============================================================================
# FILINO - PARAMÈTRES GÉNÉRAUX ET CHEMINS
# =============================================================================
# Instructions :
# - Aucun espace dans les chemins de dossiers.
# - Les séparateurs "/" ou "\\" dépendent des outils utilisés.
# - Pour rechercher une variable dans RStudio : "Ctrl + Shift + F".
# =============================================================================

# =============================================================================
# PARAMÈTRES DE PROXY (DÉPENDANT DE L'ORGANISME)
# =============================================================================
# Exemples de configurations proxy (décommentez la ligne appropriée) :
# Sys.setenv(http_proxy = "direct.proxy.i2:8080")  # SPC-SCHAPi (Ministère Écologie)
# Sys.setenv(https_proxy = "direct.proxy.i2:8080") # SPC-SCHAPi (Ministère Écologie)
# Sys.setenv(http_proxy = "http://proxy.ign.fr:3128")  # IGN
# Sys.setenv(https_proxy = "http://proxy.ign.fr:3128") # IGN

# =============================================================================
# PARAMÈTRES GÉNÉRAUX
# =============================================================================

# Code EPSG du projet (valeur entière uniquement)
nEPSG <- 2154

# Répertoire de travail principal
dsnlayer="C:/AFFAIRES/FILINO_Formation"

# Répertoire GRASS (créé automatiquement)
SecteurGRASS_ <- "C:/GRASSDATA/FILINO/Temp"

# Fichier des zones à traiter (à placer dans dsnlayer)
nomZONE <- file.path(dsnlayer, "Zones_LAZ_a_traiter.gpkg")

# Répertoire de base SIG
NomDirSIGBase <- "00_SIGBase"

# Répertoire de la BDTopo
dsnDepartement="C:/BDD/BDTopo"

# =============================================================================
# PARAMÈTRES POUR LES TABLES D'ASSEMBLAGE LIDAR (paramTALidar)
# =============================================================================
# Structure :
# cbind(Lancement, DossLAZ, NomTALAZ, Reso, NbreCaratere, Xdeb, Xfin, Ydeb, Yfin, COPC)
# - Pré-selection : 1 (actif), 0 (inactif)
# - Reso : Résolution (ex: 0.5 pour 50 cm)
# - Position Carateres : Deux possibilités
#   - Exemple 1 : 41, 9, 12, 14, 17 → Nombre, Xdeb, Xfin, Ydeb, Yfin : Positions des caractères dans les noms de fichiers
#   - Exemple 2 : 1, 0, 4, 1, 4 → Nombre inutile, 0 pour indiquer cette option, longueur des coordonnées X, saut entre X et Y, longueur des coordonnées Y
# - COPC : 1 (fichiers COPC), 0 (autres formats)

paramTALidar <- as.data.frame(rbind(
   cbind(1,"C:/StockageLIDAR"     ,"TA_HD.gpkg"              ,0.5,41, 9,12,14,17,1),
  cbind(0,"C:/StockageLidarVieux","TA_4_1_4_Formation.gpkg" ,0.5,41, 9,12,14,17,1)
))

# Ne pas modifier le nom des colonnes
colnames(paramTALidar) <- c("Lancement", "DossLAZ", "NomTALAZ", "Reso", "NbreCaratere", "Xdeb", "Xfin", "Ydeb", "Yfin", "COPC")

# =============================================================================
# PARAMÈTRES POUR FILINO_01_00b_DownloadSiteIGN.R
# =============================================================================

# Nom de la table d'assemblage pour les données LiDARHD (à placer dans le répertoire défini dans paramTALidar)
nomTA_SiteIGN <- file.path("TA_IGN_WFS", "TA_Lidar_20260209_174912_IGN.gpkg")

# =============================================================================
# PARAMÈTRES POUR FILINO_02_00c_TablesAssemblagesLazIGN.R
# =============================================================================

# Calcul du nombre de points dans les fichiers LAZ (1 = oui, 0 = non)
CalcNptsLAZ <- 1

# Calcul du nombre de pixels par dalle si fichier RASTER (1 = oui, 0 = non)
CalcPixel <- 0

# =============================================================================
# PARAMÈTRES POUR FILINO_04_01b_MasqueEau.R
# =============================================================================

# Chemins vers les fichiers SIG de référence
# NomDirSIGBase est défini dans le fichier FILINO__User_Parametres.R tout comme les autres varibales avec une synthaxe proche
nomZICAD <- file.path(dsnlayer, NomDirSIGBase, "Arrete_ZICAD_01-2023.kml")
nomDpt <- file.path(dsnlayer, NomDirSIGBase, "DEPARTEMENT.shp")
nomBuf_pour_mer <- file.path(dsnlayer, NomDirSIGBase, "DEPARTEMENT_Buf_pour_mer.shp")

# =============================================================================
# PARAMÈTRES POUR FILINO_05_01c_MasqueEau.R
# =============================================================================

# Activation du mode manuel (1 = oui, 0 = non)
Opt_Manuel <- 1

# Chemin vers le fichier de travail manuel
nom_Manuel <- file.path(dsnlayer, "TravailMANUEL_Filino.gpkg")

# =============================================================================
# PARAMÈTRES POUR LA TABLE D'ASSEMBLAGE DES DONNÉES LIDAR (paramTARaster)
# =============================================================================
# Structure :
# cbind(Lancement, Dossier, NomTA, extension, Xdeb, Xfin, Ydeb, Yfin)
# - Lancement : 1 (actif), 0 (inactif)
# - extension : Format de sortie (ex: ".gpkg$", ".tif$"). Le $ permet de ne pas avoir des fichiers satellites

paramTARaster <- as.data.frame(rbind(
  # Masques
  cbind(0, file.path(dsnlayer, NomDirMasqueVIDE), "TA_Masque1.shp", "Masque1.gpkg", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, NomDirMasqueVIDE), "TA_Masque2.shp", "Masque2.gpkg", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, NomDirMasqueVIDE), "TA_INV_VIDEetEAU.shp", "INV_VIDEetEAU_AJeter.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, NomDirMasqueVIDE), "TA_SOL.shp", "SOL_AJeter.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, NomDirMasqueVIDE), "TA_ToutSaufVege.shp", "ToutSaufVege.tif$", 9, 12, 14, 17),
  # Ponts
  cbind(0, file.path(dsnlayer, NomDirPonts), "TA_PONT.shp", "PONT.tif$", 9, 12, 14, 17),
  # Végétation
  cbind(0, file.path(dsnlayer, nomDirViSOLssVEGE), "TA_Vege.shp", "Vege.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, nomDirViSOLssVEGE), "TA_VegeTropDense.shp", "VegeTropDense.gpkg$", 9, 12, 14, 17),
  # MNT TIN
  cbind(1, file.path(dsnlayer, NomDirMNTTIN_F), "TA_TIN_Filino.shp", "TIN_Filino.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTTIN_F), "TA_TIN_Filino_Cuvettes.shp", "TIN_Filino_cuvettes.gpkg$", 9, 12, 14, 17),
  # MNT Direct
  cbind(0, file.path(dsnlayer, NomDirMNTTIN_D), "TA_TIN_Direct.shp", "TIN_Direct.gpkg$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, NomDirMNTTIN_D), "TA_TIN_Direct_cuvettes.shp", "TIN_Direct_cuvettes.gpkg$", 9, 12, 14, 17),
  # MNT GDAL
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_SOLetEAU_min.shp", "SOLetEAU_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_SOLetEAU_max.shp", "SOLetEAU_max.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_SOLetEAU_stdev.shp", "SOLetEAU_stdev.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_NbrePOINTS_count.shp", "NbrePOINTS_count.tif$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_NbreIMPULSIONS_count.shp", "_NbreIMPULSIONS_count.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_TOUT_min.shp", "TOUT_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_VEGE_min.shp", "VEGE_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirMNTGDAL), "TA_BATI_max.shp", "BATI_max.gpkg$", 9, 12, 14, 17),
  # GPS Time
  cbind(1, file.path(dsnlayer, NomDirGpsTime), "TA_GpsTime_min.shp", "GpsTime_min.tif$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirGpsTime), "TA_GpsTime_max.shp", "GpsTime_max.tif$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirGpsTime), "TA_GpsTime_diff.shp", "GpsTime_Diff.tif$", 9, 12, 14, 17),
  # Autres données non FILINO
  # Différences
  cbind(1, file.path(dsnlayer, NomDirDIFF), "TA_TIN_Filino_moins_TIN_Direct_.shp", "TIN_Filino_moins_TIN_Direct_.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, NomDirDIFF), "TA_TIN_Filino_moins_VEGE_min_.shp", "TIN_Filino_moins_VEGE_min_.gpkg$", 9, 12, 14, 17),
  # Strickler
  cbind(0, "C:\\_D\\Strickler", "TA_ParamC2D_v2.shp", "000.gpkg$", 4, 1, 4, 0)
))

# Ne pas modifier le nom des colonnes
colnames(paramTARaster) <- c("Lancement", "Doss", "NomTA", "extension", "Xdeb", "Xfin", "Ydeb", "Yfin")

# =============================================================================
# PARAMÈTRES HYDROMÉTRIE
# =============================================================================
# Tests récents pour ne faire un travail que sur les zones détectées en Ecoulement
# Activation de l'hydrométrie (1 = oui, 0 = non)
QueHydrometrie <- 0 # mettre 0, 1 pour les très experts de FILINO...

# Chemin vers les stations hydrométriques pour comparer les mesures Lidar aux débits des stations le jour J
NomStHydro <- "I:\\HYDROMETRIE\\StationHydro_FXX_selectFILINO.gpkg"
