# =============================================================================
# FILINO - PARAMÈTRES GÉNÉRAUX
# =============================================================================
# Instructions :
# - Aucun espace dans les chemins de dossiers.
# - Les séparateurs "/" ou "\\" dépendent des outils utilisés.
# - Pour rechercher une variable dans RStudio : "Ctrl + Shift + F".
# =============================================================================

# =============================================================================
# PARAMÈTRES GLOBAUX
# =============================================================================

# Largeur des dalles (en mètres)
largdalle <- 1000

# Nettoyage des fichiers temporaires (1 = activé, 0 = désactivé)
Nettoyage <- 0

# =============================================================================
# PARAMÈTRES POUR FILINO_03_01a_MasqueDalle.R
# =============================================================================

# Seuil pour garder les points non classés dans les masques :
# - 1 : Garde à partir de 1 point non classé (plus permissif).
# - 2 : Garde à partir de 2 points non classés (évite les "trous" mais peut créer plus de masques).
ClassDeb <- 1

# Activation du masque EAU (en plus des vides)
PDAL_EAU <- 1

# Multiplicateur de résolution pour éloigner les points "ancien sol" des points "sol actuels"
Mult_Reso <- 2

# =============================================================================
# PARAMÈTRES POUR FILINO_04_01b_MasqueEau.R
# =============================================================================

# Seuil pour conserver les masques (en m²)
seuilSup1 <- 1000  # Seuil 1 pour garder les masques supérieurs à ce seuil d'aire
seuilSup2 <- 1000  # Seuil 2 pour fusionner les masques 2 à partir de ce seuil d'aire
seuilSup3 <- 5     # Seuil 3
seuilSup4 <- 0     # Seuil 4 pour garder les masques 2

# Activation de la vérification (0 = désactivé, 1 = activé)
verif <- 0

# Paramètres pour les secteurs "Mer"
seuilmerdec <- 500000  # Seuil de réassemblage des zones de masques (en m²)
seuillgtrhydrodanssurface <- 20  # Seuil minimum de croisement entre un tronçon linéaire et une surface en eau

# Valeur utilisateur pour un plan d'eau
ValPlanEAU <- "-99.99"

# Paramètres de balayage pour la détection des pentes d'eau (type Ecou)
CE_BalPas <- 5   # Déplacement du balayage (en pixels)
CE_BalFen <- 50  # Moyenne sur X pixels
CE_PenteMax <- 1/100  # Pente maximale
NumCourBox <- 1 # Nombre de courbe (1 marche, plus?)

# Facteur de réduction pour le calcul des buffers
reduction <- 95/100

# Distances de buffer (en mètres)
distbufAssoE <- 15  # Pour associer les polygones de type "Écoulement"
distbufAssoC <- 10  # Pour associer les polygones de type "Canal"
bufMer <- 10         # Buffer autour des surfaces hydrographiques pour identifier les estuaires
SeuilRecombine <- 50000  # Seuil d'aire (en m²) pour fusionner les petits morceaux de mer

# =============================================================================
# PARAMÈTRES POUR FILINO_06_02ab_ExtraitLazMasquesEau.R
# =============================================================================

# Classes à utiliser pour les surfaces en eau (ex: sol et eau)
ClassPourSurfEau <- "Classification[2:2],Classification[9:9]"

# Suppression des fichiers virtuels LAZ déjà créés (1 = activé) lors de la relance des calculs
Supp_PtsVirt_copc_laz <- 1

# =============================================================================
# PARAMÈTRES POUR FILINO_06_02c_creatPtsVirtuels.R
# =============================================================================

# Pourcentage des points retenus depuis le bas (pour l'analyse des horsains)
PourcPtsBas <- 3/10

# Nombre minimum de points à garder (même si ClassesUtilisees n'utilise que 2 et 9)
NptsMINI <- c(100, 10, 20)  # À diviser par 4 pour du LiDAR à 2 impulsions/m²

# Classes utilisées pour le LiDAR HD classé
ClassesUtilisees <- c(9, 2)  # Pour LiDAR HD classé (9 = eau, 2 = sol)
# ClassesUtilisees <- c(1, 9, 2)  # Si LiDAR non classé

# Nombre maximum de points à afficher dans le simages jpg (très longues)
nmaxpointaff <- 1000000

# =============================================================================
# PARAMÈTRES POUR FILINO_07_05a_SolVieuxLazSousVege.R
# =============================================================================

# Classes pour les anciens sols (ex: 2 = sol, 10 = autre)
Classe_Old <- "Classification[2:2],Classification[10:10]"

# =============================================================================
# PARAMÈTRES POUR FILINO_11_07_CreationMNT_TIN.R
# =============================================================================

# Limite du nombre de fichiers ouverts dans PDAL (regroupement par paquets)
nLimit <- 250

# Buffer pour l'interpolation des bords de dalle (recommandation IGN : 100m)
Buf_TIN <- 100

# Classes pour le MNT TIN (ex: sol, points virtuels, etc.)
ClassPourMNTTIN <- "Classification[2:2],Classification[66:66],Classification[81:90]"

# =============================================================================
# PARAMÈTRES POUR FILINO_12_08_CreationMNT_Raster.R
# =============================================================================

# Classes pour le MNT GDAL (ex: sol + eau, impulsions, etc.)
ClassPourMNTGDAL <- rbind(
  cbind("ReturnNumber[1:1]", "count", "NbreIMPULSIONS")
  # cbind("Classification[2:2],Classification[9:9]", "min", "SOLetEAU"),
  # cbind("Classification[2:2],Classification[9:9]", "max", "SOLetEAU"),
  # cbind("Classification[3:5]", "max", "VEGE"),
  # cbind("Classification[6:6]", "max", "BATI"),
  # canopée pas utile pour nous cbind("Classification[3:5]","max","VEGE"),
  # inutile, déjà fait cbind("Classification[17:17]","max","PONT")
  # cbind("Classification[6:6]","max","BATI")
  # cbind("Classification[2:2],Classification[9:9]","stdev","SOLetEAU")
)

# =============================================================================
# PARAMÈTRES POUR FILINO_13_09_CycleCouleur.R
# =============================================================================

# Chemin vers le fichier de palette de couleurs
nompalcoul <- file.path(chem_routine, "couleurpourpalette.csv")

# Paramètres pour les palettes (exemples commentés)
Mini <- -10; Maxi <- 1000; PasDz <- c(0.1, 0.2, 0.5, 1)  # Multi-Topographie fine
# Mini <- -10; Maxi <- 2000; PasDz <- 0.25  # Topographie générale
# Mini <- 0; Maxi <- 10*24*3600; PasDz <- 5*60  # Temps
# Mini <- -5; Maxi <- 0; PasDz <- 0.25  # Négatif
# Mini <- -2.5; Maxi <- 2.5; PasDz <- 0.25  # Symétrique
# Mini <- 1401000; Maxi <- 2612000; PasDz <- 10  # Dates

# =============================================================================
# NOMBRE DE PROCESSEURS EN MODE PARALLÈLE
# =============================================================================
# Codification :
# - NaN : Pas d'option définie
# - 0 : Mode non parallèle
# - 1 et plus : Mode parallèle (nombre de processeurs)

# Matrice des configurations processeurs (par type de machine)
nb_proc_Filino=rbind(
  cbind(0,  1,  1,  1,  2),#1
  cbind(0,  2,  2,  2,  2),#2
  cbind(0,  6, 15, 20, 50),#3  #FILINO_03_01a_MasqueDalle.R
  cbind(0,NaN,NaN,NaN,NaN),#4
  cbind(0,NaN,NaN,NaN,NaN),#5
  cbind(0,  6, 15, 10, 65),#6  #FILINO_06_02ab_ExtraitLazMasquesEau
  cbind(0,  6, 15, 10, 65),#7  #FILINO_07_05a_SolVieuxLazSousVege 
  cbind(0,  9, 15, 10, 65),#8  #FILINO_08_06_TA_PtsVirtuelsLaz
  cbind(0,NaN,NaN,NaN,NaN),#9
  cbind(0,  6, 15, 10, 65),#10 #FILINO_10_04_ExtraitLazPonts_Pilotage
  cbind(0,  1,  4, 3, 40),#11 #FILINO_11_07_CreationMNT_TIN.R
  cbind(0,  8, 15, 10, 50),#12 #FILINO_12_08_CreationMNT_Raster.R limité par accès au disque si pas SSD
  cbind(0,  6, 15, 10, 16),#13
  cbind(0,NaN,NaN,NaN,NaN),#14
  cbind(0,NaN,NaN,NaN,NaN),#15
  cbind(0,NaN,NaN,NaN,NaN),#16
  cbind(0,  4, 16, 10, 55),#17
  cbind(0,  4, 16, 20, 50),#18
  cbind(0,  1,  1,  4,  6),#19
  cbind(0,NaN,NaN,NaN,NaN),#20
  cbind(0,  1,  3,  5, 10),#62),#21
  cbind(0,NaN,NaN,NaN,NaN),#22
  cbind(0,NaN,NaN,NaN,NaN) #23
)

# Noms des colonnes (types de machines)
colnames(nb_proc_Filino) <- c(
  "Mode Classique",
  "PC Basique",
  "PC HP 2019 (16Go RAM)",
  "PC DELL 2024 (64Go RAM)",
  "Station DELL"
)

# Configuration présélectionnée (ex: 3ème colonne pour PC DELL 2024)
preselect_nb_proc_Filino <- colnames(nb_proc_Filino)[1]

# =============================================================================
# NOMS DES RÉPERTOIRES D'EXPORT (À NE PAS CHANGER SAUF SI BESOIN)
# =============================================================================

# Répertoires pour les masques et résultats
NomDirMasqueVIDE   <- "01a_MASQUE_VIDEetEAU"
NomDirMasqueVEGE   <- "01b_MASQUE_VEGEDENSE"
NomDirMasquePONT   <- "01c_MASQUE_PONT"
NomDirSurfEAU      <- "02_SURFACEEAU"
NomDirCoursEAU     <- "03_COURSEAU"
NomDirPonts        <- "04_PONTS"
nomDirViSOLssVEGE  <- "05_VieuxSOL_ss_VEGE"
NomDirMNTTIN_F     <- "06_MNTTIN_FILINO"
NomDirMNTTIN_D     <- "06_MNTTIN_Direct"
NomDirMNTGDAL      <- "07_MNTGDAL00"
NomDirVideo        <- "08_Videos"
NomDirDIFF         <- "09_Differe"
NomDirVEGEDIFF     <- "09_Vege_InfMNT"
NomDirGpsTime      <- "10_GpsTime"

# Noms des fichiers de base
raciSurfEau    <- "SurfEAU"
raciPCoursEau  <- "PCoursEAU"
raciPonts      <- "Ponts"
NomDossDalles  <- "Dalles"

# =============================================================================
# CODES DES POINTS VIRTUELS
# =============================================================================

# Code de base pour les points virtuels
CodeVirtbase <- 80

# Liste des codes et types de points virtuels
CodeVirtuels <- data.frame(
  Code = c(1, 2, 3, 4, 5, 6, 7, 8),
  Type = c(
    "Mer",
    "Plan eau",
    "Canaux",
    "GCoursEauBERGE",
    "GCoursEauEAU",#non fait
    "PCoursEau",#non fait
    "SousPonts", #non fait
    "SousForets"
  )
)

# =============================================================================
# LÉGENDE DES CLASSIFICATIONS (COULEURS)
# =============================================================================

legClassification <- cbind(
  "#aaaaaa",  # 1 (Non classé)
  "#aa5500",  # 2 (Sol)
  "#00aaaa",  # 3 (Végétation basse)
  "#55ff55",  # 4 (Végétation moyenne)
  "#00aa00",  # 5 (Végétation haute)
  "#ff5555",  # 6 (Bâtiments)
  "#aa0000",  # 7 (Bruit)
  "yellow",   # 8 (Points virtuels)
  "#55ffff",  # 9 (Eau)
  "yellow",   # 10
  "yellow",   # 11
  "yellow",   # 12
  "yellow",   # 13
  "yellow",   # 14
  "yellow",   # 15
  "yellow",   # 16
  "#5555ff",  # 17 (Ponts)
  "yellow"    # 18
)
