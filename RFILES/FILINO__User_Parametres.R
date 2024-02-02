# Dans R, pour recherhcer où une variable est appliquées
#Ctrl Shift F, mettre le nom de la varianle et le dossier dans lequel chercher

#-------------------------------------Chemins des outils utilisés------------------------------------------------------
# Aucun espace n'est accepté dans les chemins des dossiers

##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 
# LES "/" OU "\\" DANS LES CHEMINS DES REPERTOIRES NE SONT PAS 
# LE FRUIT DU HASARD MAIS UN BESOIN DEPENDANT DES OUTILS UTILISES
##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 
##### ****************    TRES IMPORTANT    **************** ##### 

# Largeur des dalles
largdalle=1000

# code EPSG du projet que des valeur entière
nEPSG = 2154

# Parametre pour nettoyer des fichiers temporaires
Nettoyage=0

#------------------------------------- Paramètres FILINO_03_01a_MasqueDalle.R ------------------------------------------------------
# Parametres pour garder les points non classé dans les masques
ClassDeb=1 #1, cela garde a partir de 1 non classe, 2, cela garde a partir de 2! => Plus ou moins utile, dépend de la classification et du secteur
# en mettant 2 on ne fait pas de trou dans les surfaces en eau si on a des bateaux
# mais si la classif est moyenne, on créé énormement de masques...

# paramtre pour ajouter le masque EAU (en plus de masque des vides)
PDAL_EAU=1

Mult_Reso=2 # multiplication de la résolution pour éloigner les points ancien sol des points sol actuels

#------------------------------------- Paramètres FILINO_04_01b_MasqueEau.R ------------------------------------------------------
# Seuil pour garder les masques
seuilSup1=1000
seuilSup2=1000
seuilSup3=5
seuilSup4=0

# Vérification
verif=0 # que pour 1b mais a voir ailleurs?

# Paramétrage pour la valeur utilisateur d'un plan d'eau ou des paramétrage de balayage
ValPlanEAU="-99.99"
CE_BalPas=5 # déplacement du balayage sur x pixels
CE_BalFen=50 # moyenne sur x pixels
CE_PenteMax=1/100 # pente max sur
NumCourBox=1

#------------------------------------- Paramètres FILINO_06_02ab_ExtraitLazGrosMasquesEau.R ------------------------------------------------------
Supp_PtsVirt_copc_laz=1 # Ce paramètre permet de supprimer les fichiers virtuels Laz déjà créé
# Cette option est à utiliser car si on modifie des masques, les vieux points virtuels seraient conservés, très "dangereux"

#------------------------------------- Paramètres FILINO_06_02c_creatPtsVirtuels.R ------------------------------------------------------
# Pourcentage des points retenus depuis le bas dans les cas de plan d'eau pour faire une analyse des horsains
PourcPtsBas=3/10
# nbre de point non classifie, sol et eau, 
# NptsMINI à garder obligatoirement même si ClassesUtilisees n'utilise que 2 et 9'
NptsMINI=c(100,10,20) #Diviser par 4 pour du Lidar2impuls/m2
ClassesUtilisees=c(9,2) # si lidar hd classifié
#ClassesUtilisees=c(1,9,2) Garder les 1 si pas classifié
nmaxpointaff=1000000

#------------------------------------- Paramètres FILINO_09_05a_SolVieuxLazSousVege.R ------------------------------------------------------
Classe_Old="Classification[2:2],Classification[10:10]"# 2 et 10 pour gérer tous les formats IGN

#------------------------------------- Paramètres FILINO_11_07_CreationMNT_TIN.R ------------------------------------------------------
nLimit=250 # Limite de nombre de fichier ouvert dans pdal, on regroupe par paquet de 250, limite windows à 500 a priori
Buf_TIN=100 # Distance pour gérer l'interpolation des bords d'une dalle (100m sur recommandation IGN)
# Un process étape FILINO_06_02c_creatPtsVirtuels.R permet de gérer si ce n'est pas suffisant

#------------------------------------- Paramètres FILINO_12_08_CreationMNT_Raster.R ------------------------------------------------------
ClassPourMNTGDAL=rbind(
  cbind("Classification[2:2],Classification[9:9]","min","SOLetEAU"),
  # canopée pas utile pour nous cbind("Classification[3:5]","max","VEGE"),
  # inutile, déjà fait cbind("Classification[17:17]","max","PONT")
  cbind("Classification[6:6]","max","BATI")
)

#------------------------------------- Paramètres FILINO_13_09_CycleCouleur.R ------------------------------------------------------
nompalcoul=file.path(chem_routine,"couleurpourpalette.csv")
Mini=-50
Maxi=2000
PasDz=c(0.1,0.2,0.5,1) # On peut lancer avec plusieurs pas d'espace



##############################################################################################################################################################
##############################################################################################################################################################
##############################################################################################################################################################
# A NE PAS CHANGER SAUF SI VOUS EN AVEZ VRAIMENT ENVIE!
# Nom des répertoires export
NomDirMasqueVIDE  ="01a_MASQUE_VIDEetEAU"
NomDirMasqueVEGE  ="01b_MASQUE_VEGEDENSE"
NomDirMasquePONT  ="01c_MASQUE_PONT"
NomDirSurfEAU     ="02_SURFACEEAU"   
NomDirCoursEAU    ="03_COURSEAU"    
NomDirPonts       ="04_PONTS"        
nomDirViSOLssVEGE ="05_VieuxSOL_ss_VEGE" 
NomDirMNTTIN_F    ="06_MNTTIN_FILINO"         
NomDirMNTTIN_D    ="06_MNTTIN_Direct"         
# NomDirMNTTIN  ="06_MNTTIN00_Direct"
NomDirMNTGDAL ="07_MNTGDAL00"    
NomDirVideo   ="08_Videos"
NomDirDIFF    ="09_Differe"

# Nom de la racine de fichiers résultats
raciSurfEau="SurfEAU"
raciPCoursEau="PCoursEAU"
NomDossDalles="Dalles"


# code des points virtuels
CodeVirtbase=80
CodeVirtuels=data.frame(
  Code=rbind(    1,         2,       3,               4,             5,          6,          7,           8),
  Type=rbind("Mer","Plan eau","Canaux","GCoursEauBERGE","GCoursEauEAU","PCoursEau","SousPonts","SousForets"))

legClassification=cbind(         "#aaaaaa", # 1
                                 "#aa5500", # 2
                                 "#00aaaa", # 3
                                 "#55ff55", # 4
                                 "#00aa00", # 5
                                 "#ff5555", # 6
                                 "#aa0000" , # 7
                                 "yellow" , # 8
                                 "#55ffff", # 9
                                 "yellow" , #10
                                 "yellow" , #11
                                 "yellow" , #12
                                 "yellow" , #13
                                 "yellow" , #14
                                 "yellow" , #15
                                 "yellow" , #16
                                 "#5555ff", #17
                                 "yellow") #18


