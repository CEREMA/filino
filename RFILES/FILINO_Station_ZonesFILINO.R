library(sf)

cat("\014")

chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
print(chem_routine)
source(file.path(chem_routine,"FILINO__User_LienOutilsPC.R"))
source(file.path(chem_routine,"FILINO__User_Parametres.R"))
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
cat("FILINO__User_Chemin_et_Nom choisi: ",listSect,"\n")
source(file.path(chem_routine,listSect), encoding="utf-8")
# Ancienne maniere 23/04/2025 source(file.path(chem_routine,"FILINO__User_Chemin_et_Nom.R"))

source(file.path(chem_routine,"FILINO_Utils.R"))



###############################################################################
################# ----------- NOUVEAU -----------------########################
###############################################################################

nomStation="C:\\AFFAIRES\\INRAE\\Hydrometrie\\StationHydro_FXX_selectFILINO.gpkg"
AutourStation=c(2500,25)
nomDirHYDROMETRIE="10_HYDROMETRIE"

dir.create(file.path(dsnlayer,nomDirHYDROMETRIE))

# Lecture des Stations Hydro sémlectionnées
Stations=st_read(nomStation)
Stations=st_cast(st_union(st_buffer(Stations,AutourStation[2])),"POLYGON")
BufStations=st_cast(st_union(st_buffer(Stations,AutourStation[1])),"POLYGON")

# Contour des Départements
Departement=st_read(nomDpt)

# Croisement de la table de département avec les stations
nb=st_intersects(Departement,BufStations)
n_int = which(sapply(nb, length)>0)
Dpt=Departement[n_int,]

# Boucle sur les départements qui intersectent la donnée
LSH=list()

# fusion des divers départements intersecté
# la BDTopo n'a pas la même structure, on doit gérer les champs...
for (iDpt in 1:dim(Dpt)[1])
{
  
  nb_=st_intersects(BufStations,Dpt[iDpt,])
  n_int_ = which(sapply(nb_, length)>0)
  BufStations_=BufStations[n_int_,]
  
  # Gestion pour la limitation de l'import
  bbox=st_bbox(BufStations_)
  bbox_wkt <- paste0("POLYGON((",bbox$xmin, " ",bbox$ymin, ",",bbox$xmax, " ",bbox$ymin, ",",bbox$xmax, " ",bbox$ymax, ",",bbox$xmin, " ",bbox$ymax, ",",bbox$xmin, " ",bbox$ymin, "))")
  
  # ouverture de la BDTopo
  listeDpt=list.files(dsnDepartement,pattern=paste0("_D",ifelse(nchar(Dpt$INSEE_DEP[iDpt])==2,paste0("0",Dpt$INSEE_DEP[iDpt]),Dpt$INSEE_DEP[1]),"-"),recursive=T)
  listeDpt=file.path(dsnDepartement,listeDpt[grep(listeDpt,pattern=".gpkg")])
  if (length(listeDpt)==0)
  {
    cat("BDTopo non présente ",Dpt$INSEE_DEP[iDpt]," Merci de la télécharger\n")
    Badaboom=boom
  }
  
  dsnlayerCE=dirname(listeDpt)
  nomgpkgCE=basename(listeDpt)
  ######################################################################################
  ##### Lecture des surfaces hydrographiques
  nomlayer="surface_hydrographique"
  cat("Si vous avez une erreur - (Erreur dans if (nchar(dsn) < 1) stop(dsn must point to a source, not an empty string.)\n" )
  cat("Cela veut dire que vous n'arrivez pas à récupérer des données de la BDTopo avec le découpage de votre zone de travail, agrandissez ou reduisez là!\n" )
  surfhydro=st_read(dsn=file.path(dsnlayerCE,nomgpkgCE),layer=nomlayer,wkt_filter = bbox_wkt)
  st_geometry(surfhydro)="geometry"
  LSH[[iDpt]]=surfhydro[,cbind("cleabs","nature")]
  # cat(nomlayer,dim(surfhydro),"\n"
  
}

# Fusion et nettoyage des doublons de deux départements...
surfhydro=do.call(rbind, LSH)
surfhydro=surfhydro[order(surfhydro$cleabs),]
surfhydro$doublons=0
for (i in 2:dim(surfhydro)[1])
{
  if (surfhydro$cleabs[i]==surfhydro$cleabs[i-1]){surfhydro$doublons[i]=1}
}
surfhydro=surfhydro[which(surfhydro$doublons==0),]

# Selection des surfaces en eau touchés
nb=st_intersects(surfhydro,Stations)
n_int = which(sapply(nb, length)>0)
surfhydro_=surfhydro[n_int,]

# MiniBuffer de ces zones
surfhydro_=st_buffer(surfhydro_,AutourStation[2])

# Nouvelle selection de ces zones touchées avec les surfaces en eau
nb=st_intersects(surfhydro,surfhydro_)
n_int = which(sapply(nb, length)>0)
surfhydro_=surfhydro[n_int,]
surfhydro_=surfhydro_[which(surfhydro_$nature=="Ecoulement naturel"),]

# fusion
surfhydro_=st_cast(st_union(st_buffer(surfhydro_,AutourStation[2])),"POLYGON")

# Découpe de 2.5km autour de la station
surfhydro_=st_intersection(surfhydro_,BufStations)

# export de la zone d'intérêt
st_write(surfhydro_,file.path(dsnlayer,nomDirHYDROMETRIE,"surfhydro_tmp.gpkg"),delete_layer=T, quiet=T)






