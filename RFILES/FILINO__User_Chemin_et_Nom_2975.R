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
nEPSG = 2975

#------------------------------------- Paramètres pour FILINO------------------------------------------------------
SecteurGRASS_="C:/GRASSDATA/FILINO/Temp" # Creation automatique

# Repertoire de travail
dsnlayer="H:/Filino_Travail_REUNION"

# Zones a traiter à mettre dans le répertoire dsnlayer
nomZONE=file.path(dsnlayer,"Zones_LAZ_a_traiter_2975.shp")

NomDirSIGBase ="00_SIGBase" # à mettre dans le répertoire dsnlayer

# Repertoire de la BDTopo
dsnDepartement="G:\\BDTopo"

paramTALidar=as.data.frame(rbind(
  cbind(
    # cbind(1,"G:/REU_nuage_classe_auto_LHDV5/NUALHD_1-0_REU_RGR92UTM40S_REUN89_20250313","TA_Reu_HD.shp"     ,0.5,48, 12,15,17,20,1),
    cbind(1,"G:/REU_nuage_classe_auto_LHDV5/JOB_Cerema","TA_Reu_HD_copc.shp"     ,0.5,48, 12,15,17,20,1))
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
nomTA_SiteIGN=file.path("0_0_TA_IGN_7z","TA_diff_pkk_lidarhd_classe.gpkg")
# à mettre dans le répertoire défini dans paramTALidar où vous souhaitez mettre vos données LidarHD

#------------------------------------- Paramètres FILINO_04_01b_MasqueEau.R ------------------------------------------------------
nomZICAD=        file.path(dsnlayer,NomDirSIGBase,"Arrete_ZICAD_01-2023.kml")
nomDpt=          file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT.shp")
nomBuf_pour_mer= file.path(dsnlayer,NomDirSIGBase,"DEPARTEMENT_Buf_pour_mer.shp")

#------------------------------------- Paramètres FILINO_05_01c_MasqueEau.R ------------------------------------------------------
Opt_Manuel=1
nom_Manuel=file.path(dsnlayer,"TravailMANUEL_Filino_2975.gpkg")

#------------------------------------- Paramètres 13_00c. Table d'assemblage des données Lidar (classifiées ou autre)------------------------------------------------------
paramTARaster=as.data.frame(rbind(
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_Masque1.shp","Masque1.gpkg",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_Masque2.shp","Masque2.gpkg",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_INV_VIDEetEAU.shp","INV_VIDEetEAU_AJeter.tif$",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_SOL.shp","SOL_AJeter.tif$",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVIDE)  ,"TA_ToutSaufVege.shp","ToutSaufVege.tif",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirPonts)       ,"TA_PONT.shp","PONT.tif$",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVEGE) ,"TA_Vege.shp"               ,"Vege.tif$",12,15,17,20),
  cbind(0,file.path(dsnlayer,NomDirMasqueVEGE) ,"TA_VegeTropDense.shp"      ,"VegeTropDense.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_F)    ,"TA_TIN_Filino.shp"         ,"TIN_Filino.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_F)    ,"TA_TIN_Filino_Cuvettes.shp","TIN_Filino_cuvettes.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_D)    ,"TA_TIN_Direct.shp"         ,"TIN_Direct.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTTIN_D)    ,"TA_TIN_Direct_cuvettes.shp","TIN_Direct_cuvettes.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_min.shp"       ,"SOLetEAU_min.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_max.shp"       ,"SOLetEAU_max.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_SOLetEAU_stdev.shp"     ,"SOLetEAU_stdev.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_NbrePOINTS_count.shp"   ,"NbrePOINTS_count.tif$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)   ,"TA_NbreIMPULSIONS_count.shp","_NbreIMPULSIONS_count.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_TOUT_min.shp"           ,"TOUT_min.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_VEGE_min.shp"           ,"VEGE_min.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirMNTGDAL)     ,"TA_BATI_max.shp"           ,"BATI_max.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_min.shp"        ,"GpsTime_min.tif$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_max.shp"        ,"GpsTime_max.tif$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirGpsTime)     ,"TA_GpsTime_diff.shp"       ,"GpsTime_Diff.tif$",12,15,17,20),
  cbind(0,"C:\\_D\\Strickler"                   ,"TA_ParamC2D_v2.shp"        ,"000.gpkg$"    ,4,1,4,0),
  cbind(0,"modif dans la variable paramTARaster"," "," ","Xdeb","Xfin","Ydeb","Yfin"),
  cbind(0,"ou"                                  ," "," ","nx"  ,"saut","ny"  ,     0),
  cbind(1,file.path(dsnlayer,NomDirDIFF)        ,"TA_TIN_Filino_moins_TIN_Direct_.shp","TIN_Filino_moins_TIN_Direct_.gpkg$",12,15,17,20),
  cbind(1,file.path(dsnlayer,NomDirDIFF)        ,"TA_TIN_Filino_moins_VEGE_min_.shp"      ,"TIN_Filino_moins_VEGE_min_.gpkg$",12,15,17,20),
  cbind(1,"G:\\REU_nuage_classe_auto_LHDV5\\NUALHD_1-0_REU_RGR92UTM40S_REUN89_20250313\\modeles","TA_Reun_IGN_MNT.shp"       ,".tif$",12,15,17,20)
))


# Ne pas modifier le nom des colonnes
colnames(paramTARaster)=cbind("Lancement","Doss","NomTA","extension","Xdeb","Xfin","Ydeb","Yfin")
