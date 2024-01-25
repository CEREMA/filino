##########################################################################################################
########################## Travail sur les parametres d'entree
##########################################################################################################

# Fonction pour vérifier l'existanece des chemins entrés par l'utilisateur
fun_check_exists=
  function(dir) if(!file.exists(dir)) {cat("REPERTOIRE OU FICHIER ",dir," INTROUVABLE\n")}#;break}

fun_check_exists(qgis_process)
fun_check_exists(BatGRASS)
fun_check_exists(dsnlayer)
fun_check_exists(dsnDepartement)
fun_check_exists(nomZICAD)
fun_check_exists(nomDpt)
fun_check_exists(nomBuf_pour_mer)
setwd(dsnlayer)


for (i in 1:dim(paramTALidar)[1])
{fun_check_exists(paramTALidar$DossLAZ[i])}

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