##########################################################################################################
########################## Travail sur les parametres d'entree
##########################################################################################################

# Fonction pour vérifier l'existanece des chemins entrés par l'utilisateur
# fun_check_exists=
#   function(dir) if(!file.exists(dir)) {cat("REPERTOIRE OU FICHIER ",dir," INTROUVABLE\n")}#;break}

fun_check_exists=function(dir)
{
  if(!file.exists(dir)) {cat("REPERTOIRE OU FICHIER ",dir," INTROUVABLE\n")}#;break}
}
cat("#######################################################################\n")
cat("############ Début Vérification des liens des programmes ##############\n")
cat("---------------- FILINO__User_LienOutilsPC.R --------------------------\n")
fun_check_exists(OSGeo4W_path);OSGeo4W_path=shQuote(OSGeo4W_path)
fun_check_exists(BatGRASS);#BatGRASS=shQuote(BatGRASS)
fun_check_exists(pdal_exe);pdal_exe=shQuote(pdal_exe)
fun_check_exists(qgis_process);qgis_process=shQuote(qgis_process)
fun_check_exists(ffmpeg);ffmpeg=shQuote(ffmpeg)
cat("--------------- ",listSect," -------------------------\n")
fun_check_exists(dsnlayer)
if (file.exists(SecteurGRASS_)==F){dir.create(SecteurGRASS_,recursive = T)}
fun_check_exists(nomZONE)
fun_check_exists(NomDirSIGBase)
fun_check_exists(dsnDepartement)
# paramTALidar
for (ital in paramTALidar$DossLAZ){fun_check_exists(ital)}
fun_check_exists(file.path(paramTALidar$DossLAZ[1],nomTA_SiteIGN))
fun_check_exists(nomZICAD)
fun_check_exists(nomDpt)
fun_check_exists(nomBuf_pour_mer)
if (Opt_Manuel==1){fun_check_exists(nom_Manuel)}
if (exists("QueHydrometrie")){if (QueHydrometrie==1){fun_check_exists(NomStHydro)}}
cat("############## Fin Vérification des liens des programmes ##############\n")
cat("#######################################################################\n")
setwd(dsnlayer)

if (Auto[1]==0)
{
  # Choix des tables lidar à traiter
  choix_=paste(paramTALidar[,2],paramTALidar[,3],paramTALidar[,4],sep=" - ")
  nchoix = select.list(choix_,preselect = choix_[which(paramTALidar[,1] == 1)],
                       title = "Choix du Lidar principal (IGN HD le plus souvent)",multiple = T,graphics = T)
  nlala = which(choix_ %in% nchoix)
  if (length(nlala)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
}else{
  nlala = which(paramTALidar[,1]==1) 
}

paramTALidar[,1]=0
paramTALidar[nlala,1]=1

dsnTALidar =paramTALidar[which(paramTALidar[,1]==1),2]
nomTALidar =paramTALidar[which(paramTALidar[,1]==1),3]
resoTALidar=paramTALidar[which(paramTALidar[,1]==1),4]
paraXYLidar=paramTALidar[which(paramTALidar[,1]==1),5:10]

###############
# lecture de la zone à traiter
ZONE=st_read(nomZONE)
ZONE=arrange(ZONE,ZONE)
# Choix des secteurs à traiter
if (Auto[2]==0)
{
  # par choix en boite de dialogue
  nchoix = select.list(ZONE$ZONE,preselect = ZONE$ZONE[which(ZONE$ATRAITER==1)],
                       title = "Choisir les etapes a effectuer",multiple = T,graphics = T)
  nlala = which(ZONE$ZONE %in% nchoix)
  if (length(nlala)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  # On focalise sur le champ ATRAITER==1
  ZONE=ZONE[nlala,]
}else
{
  # en lecture directe du champ ATRAITER
  ZONE=ZONE[which(ZONE$ATRAITER==1),]
}


# Elements à garder en tête
# La valeur du temps (gps_time) du point correspond au nombre de seconde écoulées depuis le 14/09/2011 a 00:00:00 UTC. 
# strptime("14/09/2011 00:00:00",format="%d/%m/%Y %H:%M:%S")