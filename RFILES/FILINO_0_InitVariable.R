# La valeur du temps (gps_time) du point correspond au nombre de seconde écoulées depuis le 14/09/2011 à 00:00:00 UTC. 
# strptime("14/09/2011 00:00:00",format="%d/%m/%Y %H:%M:%S")

library(sf)
library(dplyr)
# Paramètre pour ne pas ouvrir les boites de dialogue
if (exists("Auto")==F){Auto=c(0,0)}

# Lien pour utiliser des fonction Qgis
qgis_process <- "C:/OSGeo4W/bin/qgis_process-qgis.bat"

# Lien pour utiliser des fonction GRASS
BatGRASS="C:\\GRASS_GIS_8_3\\grass83.bat"
# BatGRASS="C:\\OSGeo4W\\bin\\grass78.bat"
SecteurGRASS="C:/GRASSDATA/Temporaire/Temp"

# Parametres pour garder les points non classé
ClassDeb=2 #1, cela garde à partir de 1 non classé, 2, cela arde à partir de 2!

# paramtre pour faire le masque EAU
PDAL_EAU=1

# Seuil pour garder les masques
seuilSup1=1000
seuilSup2=5
seuilSup3=0
# units(seuilSup1)="m^2"

# Paramtere pour ne rien garder dans les dossier sources
Nettoyage=1
# Vérification
verif=0 # que pour 1b mais à voir ailleurs?

# Repertoire de travail
dsnlayer="D:/IGN/IGN_Cerema_UGE"
dsnDepartement="F:\\BDTopo" #"D:/Nimes"
setwd(dsnlayer)

# Nom des répertoires export
NomDirSIGBase ="00_SIGBase" #; if (file.exists(NomDirSIGBase)==F){dir.create(NomDirSIGBase)}
NomDirMasque  ="01_MASQUEINV00"    ; if (file.exists(NomDirMasque)==F){dir.create(NomDirMasque)}
NomDirSurfEAU ="02_SURFACEEAU00"   ; if (file.exists(NomDirSurfEAU)==F){dir.create(NomDirSurfEAU)}
NomDirCoursEAU="03_COURSEAU00"     ; if (file.exists(NomDirCoursEAU)==F){dir.create(NomDirCoursEAU)}
NomDirPonts   ="04_PONTS00"         ; if (file.exists(NomDirPonts)==F){dir.create(NomDirPonts)}
NomDirForet   ="05_SOUSFORETSHD00" ; if (file.exists(NomDirForet)==F){dir.create(NomDirForet)}
NomDirMNT     ="06_MNT00"           ; if (file.exists(NomDirMNT)==F){dir.create(NomDirMNT)}

# Nom de la racine de fichiers résultats
raciSurfEau="SurfEAU"
raciPCoursEau="PCoursEAU"

###################### PARAMETRES
chem_routine=R.home(component = "cerema")
##Numero_de_calcul=number 1
Numero_de_calcul=1

# 4 colonnes, 0/1 pour lancer, chemin, nom et résolution associé pour masque et position des X et Y dans les noms de fichiers...
# Il faudra ajouter les laz copc qui vont être diffusé en Mars (mail Terry)
paramTALidar=as.data.frame(rbind(
  cbind(0,"F:/LidarHD_copc"                    ,"TA_LidarHD_copc.shp"       ,0.5,45, 9,12,14,17),#LidarHDclassifieCOPC
  cbind(0,"F:/LIDARHD_Nimes"                   ,"TA_LidaHD_Nimes.shp"        ,0.5,35,12,15,17,20),
  cbind(0,"D:/IGN/IGN_Cerema_UGE/DTM_produits" ,"TA_LidarHD_LAZ_Classif.shp" ,0.5,35,12,15,17,20),# lidar HD classifié
  cbind(0,"F:/Lidar2m"                         ,"TA_Lidar2m_LAZ.shp"        ,1  ,18, 1, 3, 8,11),# lidar 2m Nimes       
  cbind(0,"F:/NUALID"                          ,"TA_NUALID_LAZ.shp"         ,1  ,59,25,28,30,33),# Nualid 2m
  cbind(0,"G:/LidarHD"                         ,"TA_LidarHD_LAZ.shp"        ,0.5,35,12,15,17,20),# lidar hd brut)
  cbind(0,"F:/Lidar_MC"                        ,"TA_LidarMC_copc.shp"       ,1  ,24, 1, 4, 9,12),# lidar vieux test opérateur IGN)
  cbind(1,"F:/LidarHD_DC"                      ,"TA_LidarDC_Class_copc.shp" ,0.5,45, 9,12,14,17)
))

# Largeur des dalles
largdalle=1000

# Zones à traiter
nomZONE="Zones_LAZ_a_traiter.shp"

#Option 2c
# Pourcentage des points retenus depuis le bas dans les cas de plan d'eau pour faire une analyse des horsains
PourcPtsBas=3/10
# nbre de point non classifié, sol et eau
NptsMINI=c(100,10,20) #Diviser par 4 pour du Lidar2impuls/m2

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
                                          

##########################################################################################################
########################## Travail sur les paramèrtres d'entrée
##########################################################################################################
if (Auto[1]==0)
{
  # Choix des tables lidar à traiter
  nchoix = select.list(paramTALidar[,3],preselect = paramTALidar[which(paramTALidar[,1] == 1),3],
                       title = "Choisir les étapes à effectuer",multiple = T,graphics = T)
  nlala = which(paramTALidar[,3] %in% nchoix)
}else{
  nlala = which(paramTALidar[,1]==1) 
}

paramTALidar[,1]=0
paramTALidar[nlala,1]=1

dsnTALidar =paramTALidar[which(paramTALidar[,1]==1),2]
nomTALidar =paramTALidar[which(paramTALidar[,1]==1),3]
resoTALidar=paramTALidar[which(paramTALidar[,1]==1),4]
paraXYLidar=paramTALidar[which(paramTALidar[,1]==1),5:9]
# }else{
#   dsnTALidar =paramTALidar[,2]
#   nomTALidar =paramTALidar[,3]
#   resoTALidar=paramTALidar[,4]
#   paraXYLidar=paramTALidar[,5:9]
# }
###############
# lecture de la zone à traiter
ZONE=st_read(file.path(dsnlayer,nomZONE))
# Choix des secteurs à traiter
if (Auto[2]==0)
{
  # par choix en boite de dialogue
  nchoix = select.list(ZONE$ZONE,preselect = ZONE$ZONE[which(ZONE$ATRAITER==1)],
                       title = "Choisir les étapes à effectuer",multiple = T,graphics = T)
  nlala = which(ZONE$ZONE %in% nchoix)
  # On focalise sur le champ ATRAITER==1
  ZONE=ZONE[nlala,]
}else
{
  # en lecture directe du champ ATRAITER
  ZONE=ZONE[which(ZONE$ATRAITER==1),]
}