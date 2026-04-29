#Paramètres à ajouter
# 04_01b association ecoulement et canaux
# 02_00 calcul du nbre de points très longs
# pq il relance des calculs sur des endroits où il est déjà passé...

Sys.unsetenv("PROJ_LIB") # Suppression uniquement dans R d'une variable environnement associée à PostGre qui posait des problème de projection dans R
library(sf) # si vous avez des problème avec st_crs et PROJ.LIB, merci de réinstaller le package sf après avoir relancer la 1ère ligne
library(dplyr)
library(rjson)
library(ggplot2)
library(ggrepel)
library(xml2)
library(readxl) 
library(jpeg)
library(png)

library(foreach)
library(doParallel)
library(raster)
# library(purrr)

cat("##################### FILINO A LIRE SVP ##############################\n")
cat("SI VOUS AVEZ CETTE ERREUR AU DESSOUS\n")
cat("Erreur dans file(filename, r, encoding = encoding) : \n")
cat("impossible d'ouvrir la connexion\n")
cat("De plus : Message davis :\n")
cat("Dans file(filename, r, encoding = encoding) :\n")
cat("impossible d ouvrir le fichier xxx/FILINO__User_LienOutilsPC.R : No such file or directory\n")
cat("\n")
cat("===> RELANCER             'Source'           de RStudio\n")
cat("##################### FILINO Fin ##############################\n")

chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
print(chem_routine)
source(file.path(chem_routine,"FILINO__User_LienOutilsPC.R"))
source(file.path(chem_routine,"FILINO__User_Parametres.R"))
cat("\014") # Nettoyage de la console
listSect=list.files(file.path(chem_routine), pattern="FILINO__User_Chemin_et_Nom")
if (length(listSect)>1)
{
  nchoixZS = select.list(
    listSect,
    title = "Choix de la zone des secteurs à traiter",
    multiple = F,
    graphics = T
  )
  nlal = which(listSect %in% nchoixZS)
  listSect=listSect[nlal]
}

cat("#-----------------------------------------------------------------------------------\n")
cat("Si vous n'arrivez pas à disposer de la table d'assemblage des dalles de points Lidar HD IGN\n")
cat("disponible avec \n")
cat("lien WFS: https://data.geopf.fr/wfs/ows?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities\n")
cat("Couche: IGNF_NUAGES-DE-POINTS-LIDAR-HD:dalle\n")
cat("\n")
cat("Vous pouvez utiliser manuellement la routine: FILINO_Charge_WFS.R\n")
cat("#-----------------------------------------------------------------------------------\n")

cat("FILINO__User_Chemin_et_Nom choisi: ",listSect,"\n")
source(file.path(chem_routine,listSect), encoding="utf-8")

source(file.path(chem_routine,"FILINO_Utils.R"))

ChoixFILINO = cbind(
  "01_00b.     Téléchargement des données LidarHD classifiées IGN",
  "02_00c.     Table d'assemblage des données Lidar (LAZ)",
  "03_01a.     Masques Vides et Eau / Ponts / Végétation trop dense par dalles",
  "04_01b.     Masques Fusion des masques et identification avec BDTopo (étape manuelle avant 1c)",
  "05_01c.     Masques Relations des masques 2 (un peu plus large) et 1 (bords sur lesquels des points virtuels sont créés)",
  "06_02ab.    SurfEau Exctraction des points Lidar des masques 2 et calculs des points virtuels",
  "07_05a.     Récupération Sol ancien d'autres Lidar dans la végétation trop dense",
  "08_06.      Table d'assemblage des points virtuels (à refaire après 09_03 et 10_04)",
  "09_03.      NON FAIT Gestion des thalwegs secs (voir travaux avec Univ G.Eiffel",
  "10_04.      En COURS DE DVT - Traitement des ponts",
  "11_07.      MNT TIN s'appyant sur TA LidarHD et TA virtuels",
  "12_08.      MNT Statistiques Raster (non continu)",# On peut faire un MN sol, un MN batiment, un MN végétation un MN Ponts, un min max...
  "13_00c.     Table d'assemblage des données Raster (TIF ou GPKG)",
  "14_10.      Palette de couleur",
  "15_11.      Videos démonstration",
  "16_12.      Création de vrt et gpkg par zone",
  "17_12.      Différences entre deux types de données",
  "18_13.      Raster GpsTime",
  "19_14.      Herbe sur champs à faible relief",
  "20_15.      Copie vers autre disques durs",
  "21_16.      Ré-échantillonage Raster",
  "22_17.      En développement - Ajouts Sections Manuelles ou profils géomètres"
)
titre="Menu principal FILINO"
preselec=NULL

nFILINO=FILINO_BDD(titre,preselec,ChoixFILINO)

#-----------------------------------------------------------------------------------
# Gestion des menus pour les diverses étapes
Auto=c(1,1)

# "01_0b. Téléchargement des données LidarHD classifiées IGN",
if (nFILINO[1]==1){Auto=apply(rbind(Auto,c(0,0)), 2,min)}

# "02_00c. Table d'assemblage des données Lidar (classifiées ou autre)",
if (nFILINO[2]==1)
{ 
  Auto=apply(rbind(Auto,c(0,1)), 2,min)
  titre="Menu FILINO_04_01b"
  preselec=".laz$"
  extension=cbind(".laz$")#☺,".tif$",".gpkg$")
  Etap_02_00c=FILINO_BDD(titre,preselec,extension)
  extensionLAZ=extension[which(Etap_02_00c==1)]
}

# "03_01a. Masques Vides et Eau par dalles",
if (nFILINO[3]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  Etap3a=1 # 1 si fusion à la fin sinon O à voir si on le sort...
  ChoixFILINO_03_01a = cbind(
    "Calcul des masques des Vides et Eau, Végétation trop dense et Ponts",
    "Fusion des végétations trop dense (peut-être très/trop long - Petite centaine de dalles maxi) - Inutile pour la suite, juste plus sympa dans qgis",
    "Fusion des ponts (peut-être très/trop long",
    "Aucune fusion"
  )
  titre="Menu FILINO_04_01b"
  preselec=ChoixFILINO_03_01a[1:3]
  Etap3a=FILINO_BDD(titre,preselec,ChoixFILINO_03_01a)
}

# "04_01b. Masques Fusion des  et identification avec BDTopo (étape manuelle avant 1c)",
if (nFILINO[4]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  ChoixFILINO_04_01b = cbind(
    "Fusion des masques VIDE/EAU calculé par dalles en Masques1 (intérieur) et Masques2(tampon)",
    "Selection Masques2 dans surfaces Eau BDTopo et> Seuil + recup BDTopo",
    "Fusion des Masques2 proches les uns des autres",
    "Appareillage BDTopo SurfaceEau Tronconhydro et Mer",
    "Gestion des limites Mer / Surfaces en Eau",
    "Gestion des confluences simples (2 rivières maxi par Masques2)"
  )
  titre="Menu FILINO_04_01b"
  preselec=ChoixFILINO_04_01b
  Etap1b=FILINO_BDD(titre,preselec,ChoixFILINO_04_01b)
}

# "05_01c. Masques Relations des 2 (un peu plus large) et 1 (bords sur lesquelq des points virtuels sont créés)",
if (nFILINO[5]==1){Auto=apply(rbind(Auto,c(0,1)), 2,min)}

# "06_02ab.SurfEau Exctraction des points Lidar des masques 2 et calculs des points virtuels",
if (nFILINO[6]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  ChoixFILINO_06_02ab = cbind(
    "Extraction des points Laz dans les masques VIDE/EAU par dalles Lidar de base - LANCER SEUL en parallèle et PASSAGE FINAL en mode classique",
    "Fusion des Laz Masques/Dalles",
    "Travail sur les Laz et création des points virtuels"
  )
  titre="Menu FILINO_06_02ab"
  preselec=ChoixFILINO_06_02ab
  
  Etap2=FILINO_BDD(titre,preselec,ChoixFILINO_06_02ab)
  
  # TRDRG=c(1,2,3) # ancienne version avec 4 graph, longue, problème de calcul rive droite rive gauche, long si bcp de point
  TRDRG=1
}

# "07_03.  NON FAIT Gestion des thalwegs secs (voir travaux avec Univ G.Eiffel",
# if (nFILINO[7]==1 ){source(file.path(chem_routine,""))}

# "07_05a. Vegetaion/Sol ancien Récupération sol dans d'autres Lidar",
if (nFILINO[7]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  # Choix des tables lidar à traiter
  choixold_=paste(paramTALidar[,2],paramTALidar[,3],paramTALidar[,4],sep=" - ")
  nchoixold = select.list(choixold_,preselect = choixold_[which(paramTALidar[,1] != 1)],
                          title = "Choix du Lidar ancien (NUALID IGN par exemple)",multiple = T,graphics = T)
  nlalaold = which(choixold_ %in% nchoixold)
  if (length(nlalaold)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
}

# "08_06.  Table d'assemblage des points virutels",
if (nFILINO[8]==1){Auto=apply(rbind(Auto,c(0,1)), 2,min)}



# "08_04.  Gestion de l'interpolation sous les ponts",
if (nFILINO[10]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  ChoixFILINO_06_02ab = cbind(
    "Extraction des points Laz dans les masques PONTS par dalles Lidar de base",
    "Fusion des Laz Masques/Dalles",
    "Travail sur les Laz et création des points virtuels"
  )
  titre="Menu FILINO_10_04"
  preselec=ChoixFILINO_06_02ab[1]
  
  Etap10_04=FILINO_BDD(titre,preselec,ChoixFILINO_06_02ab)
  
  # TRDRG=c(1,2,3) # ancienne version avec 4 graph, longue, problème de calcul rive droite rive gauche, long si bcp de point
  TRDRG=1
}




TypeTIN=cbind("TIN_Filino","TIN_Direct")
# "11_07.  MNT TIN s'appyant sur TA LidarHD et TA virtuels",
if (nFILINO[11]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  
  nTypeTIN = select.list(TypeTIN,preselect = TypeTIN[1],
                         title = "Choix du type de TIN",multiple = T,graphics = T)
  nTypeTIN = which(TypeTIN %in% nTypeTIN)
  if (length(nTypeTIN)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  
  CalcTaudem=cbind("Oui","Non")
  nCalcTaudem = select.list(CalcTaudem,preselect = CalcTaudem[1],
                            title = "Cuvettes par dalles",multiple = F,graphics = T)
  nCalcTaudem = which(CalcTaudem %in% nCalcTaudem)
  if (length(nCalcTaudem)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  
}

# "12_08.  MNT Minimum Raster (non continu)"
if (nFILINO[12]==1){Auto=apply(rbind(Auto,c(0,0)), 2,min)}


# "13_00c. Table d'assemblage des données Raster",
if (nFILINO[13]==1)
{ 
  Auto=apply(rbind(Auto,c(1,1)), 2,min)
  # titre="Menu FILINO_04_01b"
  # preselec=".gpkg$"
  # extensionRAST=cbind(".gpkg$",".tif$")
  # Etap_02_00c1=FILINO_BDD(titre,preselec,extensionRAST)
  # extensionRAST=extension[which(Etap_02_00c1==1)]
  
  chois=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Menu FILINO_13_00c"
  preselec=chois[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois)
  paramTARaster=paramTARaster[which(Etap_02_00c2==1),]
}

# ""14_09   FILINO_14_09_CycleCouleur.R"
if (nFILINO[14]==1){Auto=apply(rbind(Auto,c(1,1)), 2,min)}

# ""15_10 FILINO_15_10_VideosDemoProcess.R"
if (nFILINO[15]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  CalcVideo=cbind("Oui","Non")
  nCalcVideo = select.list(CalcVideo,preselect = CalcVideo[2],
                           title = "faire une vidéo",multiple = F,graphics = T)
  nCalcVideo = which(CalcVideo %in% nCalcVideo)
  if (length(nCalcVideo)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
}


# 16_11 FILINO_16_11_VRTGPKG.R
if (nFILINO[16]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  # titre="Menu FILINO_04_01b"
  # preselec=".gpkg$"
  # extensionRAST=cbind(".gpkg$",".tif$")
  # Etap_02_00c1=FILINO_BDD(titre,preselec,extensionRAST)
  # extensionRAST=extension[which(Etap_02_00c1==1)]
  
  chois=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Menu FILINO_16_11_VRTGPKG.R"
  preselec=chois[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois)
  paramTARaster=paramTARaster[which(Etap_02_00c2==1),]
  
  CalcVRTtoGPKG=cbind("Oui","Non")
  nCalcVRTtoGPKG = select.list(CalcVRTtoGPKG,preselect = CalcVRTtoGPKG[1],
                               title = "Convertir le vrt en GPKG avec tuilage",multiple = F,graphics = T)
  nCalcVRTtoGPKG = which(CalcVRTtoGPKG %in% nCalcVRTtoGPKG)
  if (length(nCalcVRTtoGPKG)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  
}

# "17_12.      Différences entre deux types de données"
if (nFILINO[17]==1)
{
  cat("\n")
  cat("\014")
  cat("########################################################################################################\n")
  cat("######################### A LIRE SVP ###############################################################\n")
  cat("\n")
  cat("Ce menu permet de faire des différences entre Raster en analysant les voisinages pour éviter des écarts sur des pentes fortes\n")
  cat("A priori, cela peut être utile pour:\n")
  cat("     - analyser si des points de végétations basses peuvent être en dessous du modèle numérique de terrain\n")
  cat("       Dans ce cas, des points virtuels laz peuvent être créés et intégrer au MNT FILINO\n")
  cat("\n")
  cat("     - des comparaisons des MNT avant/après des évènements morphologiques (inondations torrentielles, submersions de plages ou mouvements de terrain)\n")
  cat("\n")
  cat("La première option du menu est prioritaire sur les options 2 et 3\n")
  cat("Les options 2 et 3 peuvent être choisies ensemble\n")
  cat("\n")
  cat("Les données Raster 1 et 2 sont demandées à la suite de ce menu\n")
  cat("\n")
  cat("######################### Fin A LIRE ###############################################################\n")
  
  CalcDiffPlus=cbind("Travail sur Raster 2 VEGETATION_MIN < Raster 1 TIN et possible création de points virtuels (végétation plus basse que le TIN, et si ça peut exister!)",
                     "Raster 2 > Raster 1 par voisinage",
                     "Travail sur Raster 2 < Raster 1 par voisinage",
                     "Difference directe Raster 2 - Raster 1")
  nCalcDiffPlus = select.list(CalcDiffPlus,preselect = CalcDiffPlus[1],
                              title = "Lire dans la consolle quelques explications svp",multiple = T,graphics = T)
  # nCalcDiffPlus = which(CalcDiffPlus %in% nCalcDiffPlus)
  
  if (length(which(CalcDiffPlus %in% nCalcDiffPlus))==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  nCalcDiff=c(0,0,0,0)
  nCalcDiff[which(CalcDiffPlus %in% nCalcDiffPlus)]=1
  
  if (nCalcDiff[1]==1 & nCalcDiff[2]==1){nCalcDiff[2]=0}
  if (nCalcDiff[1]==1 & nCalcDiff[3]==1){nCalcDiff[3]=0}
  
  Auto=apply(rbind(Auto,c(1,0)), 2,min)
  chois1=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Choix du Raster n°1"
  preselec=chois1[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois1)
  paramTARaster1=paramTARaster[which(Etap_02_00c2==1)[1],]
  
  chois2=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Choix du Raster n°2"
  preselec=chois2[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois2)
  paramTARaster2=paramTARaster[which(Etap_02_00c2==1),]
}


# 18_13.Raster GpsTime
if (nFILINO[18]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
}

# 19_14.      Herbe sur champs à faible relief
if (nFILINO[19]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
}


# 
if (nFILINO[20]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  # dsnlayerRaster=choose.dir(default = "", caption = "Select folder")
}

# "21_16. Ré-échantillonage",
if (nFILINO[21]==1)
{ 
  Auto=apply(rbind(Auto,c(1,0)), 2,min)
  # titre="Menu FILINO_04_01b"
  # preselec=".gpkg$"
  # extensionRAST=cbind(".gpkg$",".tif$")
  # Etap_02_00c1=FILINO_BDD(titre,preselec,extensionRAST)
  # extensionRAST=extension[which(Etap_02_00c1==1)]
  
  chois=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Menu FILINO_21_16"
  preselec=chois[which(paramTARaster$Lancement==1)]
  Etap_21_16=FILINO_BDD(titre,preselec,chois)
  paramTARaster=paramTARaster[which(Etap_21_16==1),]
  
  ResoNew=c(5,25)
}

# Ce serait bien de ne pas ouvrir si pas de besoin...
Choixmode=FILINO_BDD("Mode de calcul",preselect_nb_proc_Filino,colnames(nb_proc_Filino))
nb_proc_Filino_=nb_proc_Filino[,which(Choixmode==1)[1]]

source(file.path(chem_routine,"FILINO_00_00a_Initialisation.R"))

#-----------------------------------------------------------------------------------
# boucle sur les fonctions

# Boucle sur tous les types de dalles Lidar
for (iTA in 1:length(dsnTALidar))
{
  # Recuperation des parametres de chaque table d'assemblage
  dsnlayerTA=dsnTALidar[iTA]
  nomlayerTA=nomTALidar[iTA]
  reso=as.numeric(resoTALidar[iTA])
  
  paramXYTA=paraXYLidar[iTA,]
  racilayerTA=strsplit(nomlayerTA,"\\.")[[1]][1]
  
  # "01_0b. Téléchargement des données LidarHD classifiées IGN",
  if (nFILINO[1]==1){source(file.path(chem_routine,"FILINO_01_00b_DownloadSiteIGN.R"))}
  
  # "02_00c. Table d'assemblage des données Lidar (classifiées ou autre)",
  if (nFILINO[2]==1)
  {
    source(file.path(chem_routine,"FILINO_02_00c_TablesAssemblagesLazIGN.R"))
    Doss_ExpRastCount=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles) # doffiser pour l'export du nombre de points
    FILINO_00c_TA(chem_routine,dsnlayerTA,nomlayerTA,extensionLAZ,paramXYTA,qgis_process,Doss_ExpRastCount,pdal_exe)
    cat("\n")
    cat("\n")
    cat("########################################################################################################\n")
    cat("######################### FILINO A LIRE SVP ###############################################################\n")
    cat("---------------- ETAPE FILINO_02_00c_TablesAssemblagesLazIGN.R #######################################\n")
    cat("\n")
    cat("Votre table d'assemblage est: ",file.path(dsnlayerTA,nomlayerTA),"\n")
    cat("Dans Qgis, vous pouvez l'ouvrir et utiliser les actions pour ouvrir les nuages de points.\n")
    cat("\n")
    cat("Des fichiers associés permettent de voir s'il n'y a pas des manques de chargements.\n")
    cat("\n")
    cat("Parfois, rien ne s'affiche, changez la symbologie dans QGIS\n")
    cat("\n")
    cat("######################### Fin FILINO A LIRE ###############################################################\n")
    cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
    cat("\n")
  }
  
  # "03_01a. Masques Vides et Eau par dalles",
  if (nFILINO[3]==1)
  {
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles))
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles))
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles))
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles))
    source(file.path(chem_routine,"FILINO_03_01a_MasqueDalle_Pilotage.R"))
  }
  
  # "04_01b. Masques Fusion des  et identification avec BDTopo (étape manuelle avant 1c)",
  if (nFILINO[4]==1){source(file.path(chem_routine,"FILINO_04_01b_MasqueEau.R"))}
  
  # "05_01c. Masques Relations des 2 (un peu plus large) et 1 (bords sur lesquelq des points virtuels sont créés)",
  if (nFILINO[5]==1){suppressWarnings(source(file.path(chem_routine,"FILINO_05_01c_MasqueEau.R")))}
  
  # "06_02ab.SurfEau Exctraction des points Lidar des masques 2 et calculs des points virtuels",
  if (nFILINO[6]==1)
  {
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirSurfEAU,racilayerTA))
    source(file.path(chem_routine,"FILINO_06_02ab_ExtraitLazMasquesEau_Pilotage.R"))  
    # FILINO_06_02ab_Pilotage(chem_routine)
  }
  
  # "07_05a. Vegetaion/Sol ancien Récupération sol dans d'autres Lidar",
  if (nFILINO[7]==1)
  {
    FILINO_Creat_Dir(file.path(dsnlayer,nomDirViSOLssVEGE,racilayerTA,NomDossDalles))
    source(file.path(chem_routine,"FILINO_07_05a_SolVieuxLazSousVege_Pilotage.R"))
    # FILINO_07_05a_Pilotage(chem_routine)
  }
  
  # "08_06.  Table d'assemblage des points virutels",
  if (nFILINO[8]==1){source(file.path(chem_routine,"FILINO_08_06_TA_PtsVirtuelsLaz_Pilotage.R"))}
  
  # "07_03.  NON FAIT Gestion des thalwegs secs (voir travaux avec Univ G.Eiffel",
  # if (nFILINO[9]==1 ){source(file.path(chem_routine,""))}
  
  # "11_04.  Gestion de l'interpolation sous les ponts",
  if (nFILINO[10]==1 ){source(file.path(chem_routine,"FILINO_10_04_ExtraitLazPonts_Pilotage.R"))}
  
  # "11_07.  MNT TIN s'appyant sur TA LidarHD et TA virtuels",
  if (nFILINO[11]==1)
  {
    source(file.path(chem_routine,"FILINO_11_07_CreationMNT_TIN_Pilotage.R"))
    # FILINO_11_07_Pilotage(chem_routine)
  }
  
  # "12_08.  MNT Minimum Raster (non continu)"
  if (nFILINO[12]==1)
  {
    FILINO_Creat_Dir(file.path(dsnlayer,NomDirMNTGDAL,racilayerTA))
    source(file.path(chem_routine,"FILINO_12_08_CreationMNT_Raster_Pilotage.R"))
  }
  
  # 18_13.Raster GpsTime
  if (nFILINO[18]==1)
  {
    source(file.path(chem_routine,"FILINO_18_13_GpsTime_Pilotage.R"))
  }
  
  if (nFILINO[20]==1)
  { 
    source(file.path(chem_routine,"FILINO_20_99_CopieDonnees.R"))
  }
}

# "13_00c. Table d'assemblage des données produites"
if (nFILINO[13]==1)
{
  source(file.path(chem_routine,"FILINO_02_00c_TablesAssemblagesLazIGN.R"))
  
  for (ita in 1:dim(paramTARaster)[1])
  {
    FILINO_00c_TA(chem_routine,paramTARaster$Doss[ita],paramTARaster$NomTA[ita],paramTARaster$extension[ita],cbind(0,0,paramTARaster[ita,cbind("Xdeb","Xfin","Ydeb","Yfin")]),qgis_process,"","")
  }
  cat("\n")
  cat("########################################################################################################\n")
  cat("######################### FILINO A LIRE SVP ###############################################################\n")
  cat("---------------- ETAPE Table d'assemblage des données Raster (TIF ou GPKG) #######################################\n")
  cat("\n")
  cat("Votre dernière table d'assemblage est: ",paramTARaster$Doss[ita],paramTARaster$NomTA[ita],"\n")
  cat("Dans Qgis, vous pouvez l'ouvrir et utiliser les actions pour ouvrir les données.\n")
  cat("\n")
  cat("Ensuite, vous pouvez refusionner sur vos secteurs avec l'option 'Création de vrt et gpkg par zone'\n")
  cat("\n")
  cat("######################### Fin FILINO A LIRE ###############################################################\n")
  cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
  cat("\n")
}

# ""14_09   FILINO_14_09_CycleCouleur.R"
if (nFILINO[14]==1){source(file.path(chem_routine,"FILINO_14_09_CycleCouleur.R"))}

# ""15_10 FILINO_15_10_VideosDemoProcess.R"
if (nFILINO[15]==1)
{
  FILINO_Creat_Dir(file.path(dsnlayer,NomDirVideo,racilayerTA))
  source(file.path(chem_routine,"FILINO_15_10_VideosDemoProcess.R"))
}

# 16_11 FILINO_16_11_VRTGPKG.R
if (nFILINO[16]==1)
{ 
  source(file.path(chem_routine,"FILINO_16_11_VRTGPKG.R"))
}

# "17_12.      Différences entre deux types de données"
if (nFILINO[17]==1)
{ 
  source(file.path(chem_routine,"FILINO_17_12_Differences_Pilotage.R"))
}

# 19_14.      Herbe sur champs à faible relief
if (nFILINO[19]==1)
{
  source(file.path(chem_routine,"FILINO_19_14_Herbe_Pilotage.R"))
}

if (nFILINO[21]==1)
{ 
  
  # reso=0.5
  # reso=1
  # browser()
  for (ita in 1:dim(paramTARaster)[1])
  {
    source(file.path(chem_routine,"FILINO_21_Re_Echantillonage_Pilotage.R"))
  }
}

# "22_17.      Ajouts Sections Manuelles ou profils géomètres"
if (nFILINO[22]==1)
{ 
  cat("\n")
  cat("\n")
  cat("########################################################################################################\n")
  cat("######################### FILINO A LIRE SVP ###############################################################\n")
  cat("---------------- ETAPE En développement - Ajouts Sections Manuelles ou profils géomètres #######################################\n")
  cat("\n")
  cat("Vous devez renseigner des fichiers de paramétrages dans le dossier\n")
  cat(file.path(chem_routine,"Users"),"\n")
  cat("\n")
  cat("######################### Fin FILINO A LIRE ###############################################################\n")
  cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
  cat("\n")
  file.path(chem_routine,"Users")
  
  source(file.path(chem_routine,"Topo_Mano","PreC2D_RUN_Topo_Manuel_pour_MNT.R"),encoding = "utf-8")
}
