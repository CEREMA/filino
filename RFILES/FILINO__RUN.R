library(sf)
library(dplyr)
library(rjson)
library(ggplot2)
library(xml2)
library(readxl) 
library(jpeg)
library(png)
library(foreach)
library(doParallel)

cat("\014") # Nettoyage de la console

chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
print(chem_routine)
source(file.path(chem_routine,"FILINO__User_LienOutilsPC.R"))
source(file.path(chem_routine,"FILINO__User_Parametres.R"))
source(file.path(chem_routine,"FILINO__User_Chemin_et_Nom.R"))
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
  "12_08.      MNT Minimum Raster (non continu)",# On peut faire un MN sol, un MN batiment, un MN végétation un MN Ponts
  "13_00c.     Table d'assemblage des données Raster (TIF ou GPKG)",
  "14_10.      Palette de couleur",
  "15_11.      Videos démonstration",
  "16_12.      Création de vrt et gpkg par zone",
  "17_12.      Différences entre deux types de données",
  "18_13.      Copie vers autre disques durs"
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
    "Fusion des végétations trop dense (peut-être très/trop long",
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
    "Extraction des points Laz dans les masques VIDE/EAU par dalles Lidar de base",
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





# "11_07.  MNT TIN s'appyant sur TA LidarHD et TA virtuels",
if (nFILINO[11]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  
  TypeTIN=cbind("TIN_Filino","TIN_Direct")
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
  Auto=apply(rbind(Auto,c(1,0)), 2,min)
  chois1=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Menu FILINO_16_11_VRTGPKG.R"
  preselec=chois1[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois1)
  paramTARaster1=paramTARaster[which(Etap_02_00c2==1)[1],]
  
  
  chois2=paste(paramTARaster$Doss,paramTARaster$NomTA)
  titre="Menu FILINO_16_11_VRTGPKG.R"
  preselec=chois2[which(paramTARaster$Lancement==1)]
  Etap_02_00c2=FILINO_BDD(titre,preselec,chois2)
  paramTARaster2=paramTARaster[which(Etap_02_00c2==1),]
  
  CalcDiffPlus=cbind("Garder toutes les valeurs","Ne garder que les valeurs positives")
  nCalcDiffPlus = select.list(CalcDiffPlus,preselect = CalcDiffPlus[1],
                              title = "Différences",multiple = F,graphics = T)
  nCalcDiffPlus = which(CalcDiffPlus %in% nCalcDiffPlus)
  if (length(nCalcDiffPlus)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
}

# "01_0b. Téléchargement des données LidarHD classifiées IGN",
if (nFILINO[18]==1)
{
  Auto=apply(rbind(Auto,c(0,0)), 2,min)
  # dsnlayerRaster=choose.dir(default = "", caption = "Select folder")
}

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
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  # "01_0b. Téléchargement des données LidarHD classifiées IGN",
  if (nFILINO[1]==1){source(file.path(chem_routine,"FILINO_01_00b_DownloadSiteIGN.R"))}
  
  # "02_00c. Table d'assemblage des données Lidar (classifiées ou autre)",
  if (nFILINO[2]==1)
  {
    source(file.path(chem_routine,"FILINO_02_00c_TablesAssemblagesLazIGN.R"))
    FILINO_00c_TA(dsnlayerTA,nomlayerTA,extensionLAZ,paramXYTA)
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
  if (nFILINO[5]==1){source(file.path(chem_routine,"FILINO_05_01c_MasqueEau.R"))}
  
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
  if (nFILINO[18]==1)
  { 
    source(file.path(chem_routine,"FILINO_18_99_CopieDonnees.R"))
  }
}

# "13_00c. Table d'assemblage des données Lidar (classifiées ou autre)",
if (nFILINO[13]==1)
{
  source(file.path(chem_routine,"FILINO_02_00c_TablesAssemblagesLazIGN.R"))
  
  for (ita in 1:dim(paramTARaster)[1])
  {
    FILINO_00c_TA(paramTARaster$Doss[ita],paramTARaster$NomTA[ita],paramTARaster$extension[ita],cbind(0,0,paramTARaster[ita,cbind("Xdeb","Xfin","Ydeb","Yfin")]))
  }
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

