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

#------------------------------------- Paramètres de proxy dépendant de l'organisme------------------------------------------------------
##### PROXY PROXY######
# Sys.setenv(http_proxy="direct.proxy.i2:8080")  # SPC-SCHAPi-Ministère "Ecologie"
# Sys.setenv(https_proxy="direct.proxy.i2:8080") # SPC-SCHAPi-Ministère "Ecologie"
# Sys.setenv(http_proxy="http://proxy.ign.fr:3128")  # IGN
# Sys.setenv(https_proxy="http://proxy.ign.fr:3128") # IGN

# code EPSG du projet que des valeur entière
nEPSG = 2154

#------------------------------------- Paramètres pour FILINO------------------------------------------------------
SecteurGRASS_="C:/GRASSDATA/FILINO/Temp" # Creation automatique

# Repertoire de travail
dsnlayer="C:/AFFAIRES/FILINO_Formation"

# Zones a traiter à mettre dans le répertoire dsnlayer
nomZONE=file.path(dsnlayer,"Zones_LAZ_a_traiter.gpkg")

NomDirSIGBase ="00_SIGBase" # à mettre dans le répertoire dsnlayer

# Repertoire de la BDTopo
dsnDepartement="C:/BDD/BDTopo"

paramTALidar=as.data.frame(rbind(
  cbind(1,"C:/StockageLIDAR"     ,"TA_HD.gpkg"              ,0.5,41, 9,12,14,17,1),
  cbind(0,"C:/StockageLidarVieux","TA_4_1_4_Formation.gpkg" ,0.5,41, 9,12,14,17,1)
  # cbind(0,"F:/LidarHD_DC"                       ,"TA_HD_surF.shp"            ,0.5,41, 9,12,14,17,1),
  # cbind(0,"E:/VieuxLidarIGN_SMMAR_test"         ,"TA_4_1_4_FP_TestSMMAR.gpkg",1  , 0, 4, 1, 4, 0,0), #le 4 1 4  correspond à la recherche de 4 chiffres pour les X, un saut de 1 caractère et 4 chiffres pour les Y
  # cbind(0,"E:/VieuxLidarIGN_Orb"         ,"TA_4_1_4_IR_Orb.gpkg"      ,1  , 0, 4, 1, 4, 0,0) #le 4 1 4  correspond à la recherche de 4 chiffres pour les X, un saut de 1 caractère et 4 chiffres pour les Y
))
#le 4 1 4  correspond à la recherche de 4 chiffres pour les X, un saut de 1 caractère et 4 chiffres pour les Y
#ceci a été fait pour la gestion de divers chantiers lidar historique IGN
#  où les X et y ont à la fois une position et un nombre pour les X et Y pas identiques...
# 0, 4, 1, 4 NUALID_1-0_DI19R078_PTS_1188_6147_LAMB93_IGN69_20191031
# 0, 4, 1, 4 NUALID_1-0_VLIDVARLOT1C3_PTS_0911_6300_LAMB93_IGN69_20180606
# 0, 3, 4, 4 748000_6283000.copc.laz

# Ne pas modifier le nom des colonnes
colnames(paramTALidar)=cbind("Lancement","DossLAZ","NomTALAZ","Reso","NbreCaratere","Xdeb","Xfin","Ydeb","Yfin","COPC")

#------------------------------------- Paramètres FILINO_01_00b_DownloadSiteIGN.R ------------------------------------------------------
nomTA_SiteIGN=file.path("TA_IGN_WFS","TA_Lidar_20260209_174912_IGN.gpkg")
# à mettre dans le répertoire défini dans paramTALidar où vous souhaitez mettre vos données LidarHD

#------------------------------------- Paramètres FILINO_02_00c_TablesAssemblagesLazIGN.R -----------------------------------------
# QGIS Calul du nombre de points parfois long si fichier LAZ
# 1 oui
# 0 Non
CalcNptsLAZ=1
# PDAL calcul du nombre de pixels par dalles si fichier RASTER
CalcPixel=0
# 1 oui
# 0 Non


#------------------------------------- Paramètres FILINO_04_01b_MasqueEau.R ------------------------------------------------------
nomZICAD=        file.path(dsnlayer,NomDirSIGBase,"Arrete_ZICAD_01-2023.kml")
nomDpt=          file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT.shp")
nomBuf_pour_mer= file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT_Buf_pour_mer.shp")

#------------------------------------- Paramètres FILINO_05_01c_MasqueEau.R ------------------------------------------------------
Opt_Manuel=1
nom_Manuel=file.path(dsnlayer,"TravailMANUEL_Filino.gpkg")

#------------------------------------- Paramètres 13_00c. Table d'assemblage des données Lidar (classifiées ou autre)------------------------------------------------------
paramTARaster=as.data.frame(rbind(
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_Masque1.shp","Masque1.gpkg",9,12,14,17),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_Masque2.shp","Masque2.gpkg",9,12,14,17),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_INV_VIDEetEAU.shp","INV_VIDEetEAU_AJeter.tif$",9,12,14,17),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_SOL.shp","SOL_AJeter.tif$",9,12,14,17),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_ToutSaufVege.shp","ToutSaufVege.tif",9,12,14,17),
  
  cbind(0,file.path(dsnlayer,NomDirPonts)       ,"TA_PONT.shp","PONT.tif$",9,12,14,17),
  
  cbind(0,file.path(dsnlayer,nomDirViSOLssVEGE) ,"TA_Vege.shp"               ,"Vege.tif$",9,12,14,17),
  cbind(0,file.path(dsnlayer,nomDirViSOLssVEGE) ,"TA_VegeTropDense.shp"      ,"VegeTropDense.gpkg$",9,12,14,17),
  
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_F)    ,"TA_TIN_Filino.shp"         ,"TIN_Filino.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_F)    ,"TA_TIN_Filino_Cuvettes.shp","TIN_Filino_cuvettes.gpkg$",9,12,14,17),
  
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_D)    ,"TA_TIN_Direct.shp"         ,"TIN_Direct.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_D)    ,"TA_TIN_Direct_cuvettes.shp","TIN_Direct_cuvettes.gpkg$",9,12,14,17),
  
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_min.shp"       ,"SOLetEAU_min.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_max.shp"       ,"SOLetEAU_max.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_stdev.shp"       ,"SOLetEAU_stdev.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_NbrePOINTS_count.shp"   ,"NbrePOINTS_count.tif$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_NbreIMPULSIONS_count.shp","NbreIMPULSIONS_count.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_TOUT_min.shp"           ,"TOUT_min.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_VEGE_min.shp"           ,"VEGE_min.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_BATI_max.shp"           ,"BATI_max.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_min.shp"        ,"GpsTime_min.tif$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_max.shp"        ,"GpsTime_max.tif$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_diff.shp"       ,"GpsTime_Diff.tif$",9,12,14,17),
  
  
  cbind(0,"modif dans la variable paramTARaster"," "," ","Xdeb","Xfin","Ydeb","Yfin"),
  
  cbind(1,"C:\\Cartino2D\\France\\_Strickler","TA_Strickler_MTP20240705.gpkg"            ,".gpkg$",11,14,16,19),
  cbind(1,"C:\\Cartino2D\\France\\_Strickler\\CNIR","TA_CN_CNIR.gpkg"            ,".gpkg$",6,9,11,14),
  cbind(1,"C:\\Cartino2D\\France\\_MNT\\MAMP_2024","TA_MNTC2D_MAMP2024.gpkg"   ,".gpkg$",17,20,22,25),
  cbind(1,"G:\\MNT_Frontaliers\\Allemagne\\Rhenanie_Palatinat","TA_Allemagne_RLP.gpkg",".tif$",10,12,14,17),
  cbind(1,"G:\\MNT_Frontaliers\\Allemagne\\Baden_Wurttemberg\\Dalles","TA_Allemagne_BW_XYZ.gpkg",".xyz$",9,11,13,16),
  cbind(1,"G:\\MNT_Frontaliers\\Allemagne\\Baden_Wurttemberg\\DallesGPKG","TA_Allemagne_BW_GPKG.gpkg",".gpkg$",9,11,13,16),
  cbind(1,"G:\\MNT_Frontaliers\\Suisse","TA_Suisse.gpkg",".tif$",4,1,4,0),
  cbind(1,"G:\\MNT_Frontaliers\\LUXEMBOURG\\Dalles2169","TA_Luxembourg.gpkg",".gpkg$",9,12,14,17),
  cbind(1,"G:\\MNT_Frontaliers\\BELGIQUE\\FLANDRES\\Dalles31370","TA_Belg_Fland.gpkg",".gpkg$",16,19,21,24),
  cbind(1,"G:\\MNT_Frontaliers\\BELGIQUE\\WALLONIE\\Dalles3812","TA_Belg_Wallo.gpkg",".gpkg$",15,18,20,23),
  cbind(1,"G:\\MNT_Frontaliers\\_FusionMNT","TA_Frontaliers.gpkg","_NGF.gpkg$",4,1,4,0),
  cbind(1,"G:\\MNT_Frontaliers\\_Frontieres\\Dalles","TA_Frontieres.gpkg",".gpkg$",4,1,4,0)
))  

# Ne pas modifier le nom des colonnes
colnames(paramTARaster)=cbind("Lancement","Doss","NomTA","extension","Xdeb","Xfin","Ydeb","Yfin")

QueHydrometrie=0
NomStHydro="I:\\HYDROMETRIE\\StationHydro_FXX_selectFILINO.gpkg"