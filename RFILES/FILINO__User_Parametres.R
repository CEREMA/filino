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

# Parametre pour nettoyer des fichiers temporaires
Nettoyage=1

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

# Paramétrage pour les secteurs Mer
# Valeur pour reassembler les zones de masques plus petites que seuilmerdec
seuilmerdec=500000
# valeur de seuil minimum de croisment entre un troncon linéaire et une surface en eau pour donner le type de la surface en eau au lieu de garder mer
# doit être supérieur à 1 sinon ca plante dans les étapes d'après
seuillgtrhydrodanssurface=20

# Paramétrage pour la valeur utilisateur d'un plan d'eau ou des paramétrage de balayage
ValPlanEAU="-99.99"
CE_BalPas=5 # déplacement du balayage sur x pixels
CE_BalFen=50 # moyenne sur x pixels
CE_PenteMax=1/100 # pente max sur
NumCourBox=1

reduction=95/100 # Facteur de réduction pour calculer la distance de buffer autour des jonctions.
distbufAssoE=15 #Distance de buffer (en mètres) pour associer les polygones de type "Ecoulement".
distbufAssoC=10 # Distance de buffer (en mètres) pour associer les polygones de type "Canal".
bufMer=10  # Buffer (en mètres) autour des surfaces hydrographiques pour identifier les estuaires.
SeuilRecombine=50000 # Seuil d’aire (en m²) pour fusionner les petits morceaux de mer qui ont été découpé par le tampon sur les surfaces en eau BDTopo




#------------------------------------- Paramètres FILINO_06_02ab_ExtraitLazMasquesEau.R ------------------------------------------------------
# ClassPourSurfEau="Classification[1:2],Classification[9:9]"
ClassPourSurfEau="Classification[2:2],Classification[9:9]"
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

#------------------------------------- Paramètres FILINO_07_05a_SolVieuxLazSousVege.R ------------------------------------------------------
Classe_Old="Classification[2:2],Classification[10:10]"# 2 et 10 pour gérer tous les formats IGN

#------------------------------------- Paramètres FILINO_11_07_CreationMNT_TIN.R ------------------------------------------------------
nLimit=250 # Limite de nombre de fichier ouvert dans pdal, on regroupe par paquet de 250, limite windows à 500 a priori
Buf_TIN=100 # Distance pour gérer l'interpolation des bords d'une dalle (100m sur recommandation IGN)
# Un process étape FILINO_06_02c_creatPtsVirtuels.R permet de gérer si ce n'est pas suffisant
# ClassPourMNTTIN="Classification[0:0]" # Code pour du Lidar jamais classé
ClassPourMNTTIN="Classification[2:2],Classification[66:66],Classification[81:90]" # Code pour LidarHD IGN

#------------------------------------- Paramètres FILINO_12_08_CreationMNT_Raster.R ------------------------------------------------------
# virgule à la fin de chaque ligne sauf la dernière
ClassPourMNTGDAL=rbind(
  # cbind("Classification[2:2],Classification[9:9]","min","SOLetEAU"),
  # cbind("Classification[2:2],Classification[9:9]","max","SOLetEAU"),
  # cbind("Classification[2:2],Classification[9:9]","mean","SOLetEAU")
  # cbind("","count","NbrePOINTS")
  cbind("ReturnNumber[1:1]","count","NbreIMPULSIONS")
  # canopée pas utile pour nous cbind("Classification[3:5]","max","VEGE"),
  # inutile, déjà fait cbind("Classification[17:17]","max","PONT")
  # cbind("Classification[6:6]","max","BATI")
  # cbind("Classification[2:2],Classification[9:9]","stdev","SOLetEAU")
)

#------------------------------------- Paramètres FILINO_13_09_CycleCouleur.R ------------------------------------------------------
nompalcoul=file.path(chem_routine,"couleurpourpalette.csv")
Mini=-10
Maxi=0
PasDz=c(0.1,0.2,0.5,1) # On peut lancer avec plusieurs pas d'espace
Mini=-10;Maxi=2000;PasDz=0.25 # Topo
Mini=0;Maxi=10*24*3600;PasDz=5*60 # Temps
Mini=0;Maxi=3000;PasDz=c(10,5,2,1,0.5,0.25) # Temps
Mini=-5;Maxi=0;PasDz=0.25 # Négatif
Mini=-2.5;Maxi=2.5;PasDz=0.25 # Négatif
Mini=0;Maxi=500;PasDz=25 # Négatif
Mini=-10;Maxi=10;PasDz=0.01 # Négatif
Mini=1401000;Maxi=2612000;PasDz=10 # Négatif
# Mini=63;Maxi=65;PasDz=0.01 # Temps
Mini=-5.5;Maxi=4.5;PasDz=0.25 # Lafaute
#------------------------------------- Processeurs en mode parallèle ------------------------------------------------------
#----- Codification 
#------------- NaN pas d'option
#------------- 0 mode non parallèle
#------------- 1 et plus mode parallèle
# le mode parallèle semble mieux gérer la rame et mettre 1 semble permettre ded faire des calculs qui ne passent pas en mode classique...
nb_proc_Filino=c(
  NaN,
  NaN,
  20, #FILINO_03_01a_MasqueDalle.R
  NaN,
  NaN,
  20,#6, #FILINO_06_02ab_ExtraitLazMasquesEau
  20, #FILINO_07_05a_SolVieuxLazSousVege
  20,#9, #FILINO_08_06_TA_PtsVirtuelsLaz
  NaN,
  0, #6, #FILINO_10_04_ExtraitLazPonts_Pilotage
  4,#4, #1, #FILINO_11_07_CreationMNT_TIN.R
  8, #FILINO_12_08_CreationMNT_Raster.R
  NaN,
  NaN,
  NaN,
  NaN,
  20) #FILINO_03_01a_MasqueDalle_Pilotage


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
  cbind(0,  1,  4, 10, 40),#11 #FILINO_11_07_CreationMNT_TIN.R
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
colnames(nb_proc_Filino)=cbind("Mode Classique","PC HP 2019 16GoRam, 6*2 proc","PC DELL 2024 64GoRam, 24+8proc","Moitie PC DELL 2024 64GoRam, 24+8proc","STATION DELL")
preselect_nb_proc_Filino=colnames(nb_proc_Filino[3])

##############################################################################################################################################################
##############################################################################################################################################################
##############################################################################################################################################################
# A NE PAS CHANGER SAUF SI VOUS EN AVEZ VRAIMENT ENVIE!
# Nom des répertoires export
NomDirMasqueVIDE  ="01a_MASQUE_VIDEetEAUP"
NomDirMasqueVEGE  ="01b_MASQUE_VEGEDENSEP"
NomDirMasquePONT  ="01c_MASQUE_PONTP"
NomDirSurfEAU     ="02_SURFACEEAUP"   
NomDirCoursEAU    ="03_COURSEAUP"    
NomDirPonts       ="04_PONTSP"        
nomDirViSOLssVEGE ="05_VieuxSOL_ss_VEGEP" 
NomDirMNTTIN_F    ="06_MNTTIN_FILINOP"         
NomDirMNTTIN_D    ="06_MNTTIN_DirectP"         
# NomDirMNTTIN  ="06_MNTTIN00_Direct"
NomDirMNTGDAL ="07_MNTGDAL00P"    
NomDirVideo   ="08_VideosP"
NomDirDIFF    ="09_DiffereP"

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
NomDirVEGEDIFF  ="09_Vege_InfMNT"
NomDirGpsTime ="10_GpsTime"

# Nom de la racine de fichiers résultats
raciSurfEau="SurfEAU"
raciPCoursEau="PCoursEAU"
raciPonts="Ponts"
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


