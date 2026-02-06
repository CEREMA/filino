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
dsnlayer <- "D:/FILINO_Hydrometrie"

# Répertoire GRASS (créé automatiquement)
SecteurGRASS_ <- "C:/GRASSDATA/FILINO/Temp"

# Fichier des zones à traiter (à placer dans dsnlayer)
nomZONE <- file.path(dsnlayer, "Zones_LAZ_a_traiter_Clapiere.shp")

# Répertoire de base SIG
NomDirSIGBase <- "00_SIGBase"

# Répertoire de la BDTopo
dsnDepartement <- "G:/BDTopo"

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
  cbind(1, "H:/LidarHD_DC", "TA_HD.gpkg", 0.5, 41, 9, 12, 14, 17, 1),# Repertoire de stockage de votre Lidar
  cbind(0, "G:/2_IGNF_LIDAR_HD_TAmnt_dalle", "TA_MNT_HD_P.shp", 0.5, 41, 9, 12, 14, 17, 1)
  # cbind(0, "F:/LidarHD_DC", "TA_HD_surF.shp", 0.5, 41, 9, 12, 14, 17, 1),
  # cbind(0, "E:/LidarNonHD/Lidar2mTOUT/COPCLAZ", "TA_NiMontpLid2m.shp", 1, 18, 1, 3, 8, 11, 1),
  # cbind(0, "E:/LidarNonHD/Lidar2mTOUT/Laz_4_1_4", "TA_4_1_4.shp", 1, 0, 4, 1, 4, 0, 0),
  # cbind(0, "E:/LidarNonHD/LidarRestonica", "TA_Resto_Cerema.shp", 0.5, 37, 30, 33, 35, 38, 1)
)) 

# Ne pas modifier le nom des colonnes
colnames(paramTALidar) <- c("Lancement", "DossLAZ", "NomTALAZ", "Reso", "NbreCaratere", "Xdeb", "Xfin", "Ydeb", "Yfin", "COPC")

# =============================================================================
# PARAMÈTRES POUR FILINO_01_00b_DownloadSiteIGN.R
# =============================================================================

# Nom de la table d'assemblage pour les données LiDARHD (à placer dans le répertoire défini dans paramTALidar)
nomTA_SiteIGN <- file.path("0_0_TA_IGN_7z", "TA_Lidar20260105_161941_IGN.gpkg")

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
# - Lancement : Préselcetion 1 (actif), 0 (inactif)
# - extension : Format de sortie (ex: ".gpkg$", ".tif$"). Le $ permet de ne pas avoir des fichiers satellites

paramTARaster <- as.data.frame(rbind(
  # Masques
  cbind(0, file.path(dsnlayer, "01a_MASQUE_VIDEetEAU"), "TA_Masque1.shp", "Masque1.gpkg", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "01a_MASQUE_VIDEetEAU"), "TA_Masque2.shp", "Masque2.gpkg", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "01a_MASQUE_VIDEetEAU"), "TA_INV_VIDEetEAU.shp", "INV_VIDEetEAU_AJeter.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "01a_MASQUE_VIDEetEAU"), "TA_SOL.shp", "SOL_AJeter.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "01a_MASQUE_VIDEetEAU"), "TA_ToutSaufVege.shp", "ToutSaufVege.tif$", 9, 12, 14, 17),
  # Ponts
  cbind(0, file.path(dsnlayer, "04_PONTS"), "TA_PONT.shp", "PONT.tif$", 9, 12, 14, 17),
  # Végétation
  cbind(0, file.path(dsnlayer, "05_VieuxSOL_ss_VEGE"), "TA_Vege.shp", "Vege.tif$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "05_VieuxSOL_ss_VEGE"), "TA_VegeTropDense.shp", "VegeTropDense.gpkg$", 9, 12, 14, 17),
  # MNT TIN
  cbind(1, file.path(dsnlayer, "06_MNTTIN_FILINO"), "TA_TIN_Filino.shp", "TIN_Filino.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "06_MNTTIN_FILINO"), "TA_TIN_Filino_Cuvettes.shp", "TIN_Filino_cuvettes.gpkg$", 9, 12, 14, 17),
  # MNT Direct
  cbind(0, file.path(dsnlayer, "06_MNTTIN_Direct"), "TA_TIN_Direct.shp", "TIN_Direct.gpkg$", 9, 12, 14, 17),
  cbind(0, file.path(dsnlayer, "06_MNTTIN_Direct"), "TA_TIN_Direct_cuvettes.shp", "TIN_Direct_cuvettes.gpkg$", 9, 12, 14, 17),
  # MNT GDAL
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_SOLetEAU_min.shp", "SOLetEAU_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_SOLetEAU_max.shp", "SOLetEAU_max.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_SOLetEAU_stdev.shp", "SOLetEAU_stdev.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_TOUT_min.shp", "TOUT_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_VEGE_min.shp", "VEGE_min.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "07_MNTGDAL00"), "TA_BATI_max.shp", "BATI_max.gpkg$", 9, 12, 14, 17),
  # GPS Time
  cbind(1, file.path(dsnlayer, "10_GpsTime"), "TA_GpsTime_min.shp", "GpsTime_min.tif$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "10_GpsTime"), "TA_GpsTime_max.shp", "GpsTime_max.tif$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "10_GpsTime"), "TA_GpsTime_diff.shp", "GpsTime_Diff.tif$", 9, 12, 14, 17),
  # Autres données non FILINO
  # Différences
  cbind(1, file.path(dsnlayer, "09_Differe"), "TA_TIN_Filino_moins_TIN_Direct_.shp", "TIN_Filino_moins_TIN_Direct_.gpkg$", 9, 12, 14, 17),
  cbind(1, file.path(dsnlayer, "09_Differe"), "TA_TIN_Filino_moins_VEGE_min_.shp", "TIN_Filino_moins_VEGE_min_.gpkg$", 9, 12, 14, 17),
  # Strickler
  cbind(0, "C:\\_D\\Strickler", "TA_ParamC2D_v2.shp", "000.gpkg$", 4, 1, 4, 0)
  # ,
  # # Autres données
  # # RGEAlti
  # cbind(0, "E:\\RGEAlti1m\\France", "TA_RGEALTI_FR.shp", ".asc$", 4, 1, 4, 0),
  # # MNT divers
  # cbind(0, "G:\\LidarHD_MNTIGN_V_0_1", "LidarHD_MNTIGN_V_0_1.gpkg", ".tif$", 12, 15, 17, 20),
  # cbind(1, "G:\\LidarHD_MNTIGN_V_0_1", "TA_3a.gpkg", ".tif$", 12, 15, 17, 20),
  # cbind(1, "G:\\2_IGNF_LIDAR_HD_TAmnt_dalle", "TA_MNT_HD_P.gpkg", ".tif$", 9, 12, 14, 17),
  # # Données frontalières
  # cbind(1, "G:\\MNT_Frontaliers\\Allemagne\\Rhenanie_Palatinat", "TA_Allemagne_RLP.gpkg", ".tif$", 10, 12, 14, 17),
  # cbind(1, "G:\\MNT_Frontaliers\\Allemagne\\Baden_Wurttemberg\\Dalles", "TA_Allemagne_BW_XYZ.gpkg", ".xyz$", 9, 11, 13, 16),
  # cbind(1, "G:\\MNT_Frontaliers\\Allemagne\\Baden_Wurttemberg\\DallesGPKG", "TA_Allemagne_BW_GPKG.gpkg", ".gpkg$", 9, 11, 13, 16),
  # cbind(1, "G:\\MNT_Frontaliers\\Allemagne\\Sarre", "TA_Allemagne_Saar_GPKG.gpkg", ".tif$", 3, 1, 4, 0),
  # cbind(1, "G:\\MNT_Frontaliers\\Suisse", "TA_Suisse.gpkg", ".tif$", 4, 1, 4, 0),
  # cbind(1, "G:\\MNT_Frontaliers\\LUXEMBOURG\\Dalles2169", "TA_Luxembourg.gpkg", ".gpkg$", 9, 12, 14, 17),
  # cbind(1, "G:\\MNT_Frontaliers\\BELGIQUE\\FLANDRES\\Dalles31370", "TA_Belg_Fland.gpkg", ".gpkg$", 16, 19, 21, 24),
  # cbind(1, "G:\\MNT_Frontaliers\\BELGIQUE\\WALLONIE\\Dalles3812", "TA_Belg_Wallo.gpkg", ".gpkg$", 15, 18, 20, 23),
  # cbind(1, "G:\\MNT_Frontaliers\\_FusionMNT", "TA_Frontaliers.gpkg", "_NGF.gpkg$", 15, 18, 20, 23),
  # cbind(1, "G:\\MNT_Frontaliers\\_Frontieres\\Dalles", "TA_Frontieres.gpkg", ".gpkg$", 4, 1, 4, 0),
  # # Cartino2D
  # cbind(0, "C:\\Cartino2D\\France\\_MNT\\MAMP_2024", "TA_MNTC2D_MAMP2024.gpkg", ".gpkg$", 17, 20, 22, 25),
  # cbind(1, "C:\\Cartino2D\\France\\_Strickler\\CNIR", "TA_CN_CNIR.gpkg", ".gpkg$", 6, 9, 11, 14),
  # cbind(1, "C:\\Cartino2D\\France\\_Strickler\\EAIM\\Strickler", "TA_Strickler_Reso025.gpkg", ".gpkg$", 6, 9, 11, 14),
  # cbind(1, "G:\\MNT_Frontaliers\\Allemagne\\Sarre", "TA_Allemagne_Saar_GPKG.gpkg", ".tif$", 3, 1, 4, 0)
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
