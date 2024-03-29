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

#------------------------------------- Paramètres pour FILINO------------------------------------------------------
SecteurGRASS_="C:/GRASSDATA/FILINO/Temp" # Creation automatique

# Repertoire de travail
dsnlayer="D:/IGN/IGN_Cerema_UGE"
dsnlayer="C:/AFFAIRES/FILINO_Travail"

# Zones a traiter à mettre dans le répertoire dsnlayer
nomZONE=file.path(dsnlayer,"Zones_LAZ_a_traiter.shp")

NomDirSIGBase ="00_SIGBase" # à mettre dans le répertoire dsnlayer

# Repertoire de la BDTopo
dsnDepartement="E:\\BDTopo"

paramTALidar=as.data.frame(rbind(
  cbind(1,"E:/LidarHD_DC"                   ,"TA_HD.shp"           ,0.5,41, 9,12,14,17,1),
  cbind(0,"E:/NUALID"                       ,"TA_NUALID.shp"       ,1  ,59,25,28,30,33,1),# Nualid 2m
  cbind(0,"E:/Lidar2mTOUT/COPCLAZ"          ,"TA_NiMontpLid2m.shp" ,1  ,18, 1, 3, 8,11,1),# lidar 2m Nimes - Montpellier
  # cbind(0,"E:/Lidar2mTOUT/Laz_4_1_4"        ,"TA_nchar56_IVAR.shp" ,1  ,56,22,25,27,30,0),
  # cbind(0,"E:/Lidar2mTOUT/Laz_4_1_4"        ,"TA_nchar70_VLIDT.shp",1  ,70,36,39,41,44,0),
  # cbind(0,"E:/Lidar2mTOUT/Laz_4_1_4"        ,"TA_nchar60_VLIDV.shp",1  ,60,30,33,35,38,0),
  # cbind(0,"E:/Lidar2mTOUT/Laz_4_1_4"        ,"TA_nchar59.shp"      ,1  ,59,25,28,30,33,0),
  cbind(0,"E:/Lidar2mTOUT/Laz_4_1_4"        ,"TA_4_1_4.shp"        ,1  , 0, 4, 1, 4, 0,0),
  cbind(0,"E:/LidarRestonica"               ,"TA_Resto_Cerema.shp" ,0.5,37,30,33,35,38,1)
))


# Ne pas modifier le nom des colonnes
colnames(paramTALidar)=cbind("Lancement","DossLAZ","NomTALAZ","Reso","NbreCaratere","Xdeb","Xfin","Ydeb","Yfin","COPC")

#------------------------------------- Paramètres FILINO_01_00b_DownloadSiteIGN.R ------------------------------------------------------
nomTA_SiteIGN=file.path("0_0_TA_IGN_7z","TA_diff_pkk_lidarhd_classe.shp")
# à mettre dans le répertoire défini dans paramTALidar où vous souhaitez mettre vos données LidarHD

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
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_TOUT_min.shp"           ,"TOUT_min.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_VEGE_min.shp"           ,"VEGE_min.gpkg$",9,12,14,17),

  cbind(0,"C:\\_D\\Strickler"                   ,"TA_ParamC2D_v2.shp"        ,"000.gpkg$"    ,4,4,4,0),
  
  cbind(0,"modif dans la variable paramTARaster"," "," ","Xdeb","Xfin","Ydeb","Yfin"),
  cbind(0,"ou"                                  ," "," ","nx"  ,"saut","ny"  ,     0),
  cbind(1,file.path(dsnlayer,NomDirDIFF)        ,"TA_TIN_Filino_moins_TIN_Direct_.shp","TIN_Filino_moins_TIN_Direct_.gpkg$",9,12,14,17),
  cbind(1,file.path(dsnlayer,NomDirDIFF)        ,"TA_TIN_Filino_moins_VEGE_min_.shp"      ,"TIN_Filino_moins_VEGE_min_.gpkg$",9,12,14,17)
  
))  

# Ne pas modifier le nom des colonnes
colnames(paramTARaster)=cbind("Lancement","Doss","NomTA","extension","Xdeb","Xfin","Ydeb","Yfin")
