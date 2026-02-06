source(file.path(chem_routine,"FILINO_21_Re_Echantillonage.R"),encoding = "utf-8")

cat("\014")
cat("FILINO_21_Re_Echantillonage_Job.R\n")

TA_Rast=st_read(file.path(paramTARaster$Doss,paramTARaster$NomTA))

nb=st_intersects(TA_Rast,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA_Rast_Zone=TA_Rast[n_int,]
  nb_proc=min(nb_proc_Filino_[21],dim(TA_Rast_Zone)[1])
  if(nb_proc==0)
  {
    for (idalle in 1:dim(TA_Rast_Zone)[1])
    {
      cat(round(idalle/nrow(TA_Rast_Zone)*100),"% - ")
      FILINO_21_Job(idalle,TA_Rast_Zone,ResoNew,SecteurGRASS_,nEPSG,paramTARaster$Doss)
    }
  }else{
    cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
    require(foreach)
    cl <- parallel::makeCluster(nb_proc)
    registerDoParallel(cl)
    foreach(idalle = 1:dim(TA_Rast_Zone)[1],
            .combine = 'c',
            .inorder = FALSE,
            .packages = c("sf")) %dopar%
      {
        library(sf)
        FILINO_21_Job(idalle,TA_Rast_Zone,ResoNew,SecteurGRASS_,nEPSG,paramTARaster$Doss)
      }
    
    stopCluster(cl)
  }
}
cat("\n")
cat("########################################\n")
cat("Création des tables d'assemblage\n")
for (iReso in c("_Ini",formatC(ResoNew,width=3, flag="0")))
{
  cat("Création de la table d'assemblage\n")
  source(file.path(chem_routine,"FILINO_02_00c_TablesAssemblagesLazIGN.R"))
  # colnames(paramRGEAlti)=cbind("0","0","Xdeb","Xfin","Ydeb","Yfin")
  # paramRGEAlti=as.data.frame(paramRGEAlti)
  dirReso=paste0("_Reso",iReso)
  FILINO_00c_TA(chem_routine,file.path(paramTARaster$Doss,dirReso),paste0("TA",dirReso,".gpkg"),".gpkg$",paramTARaster,qgis_process,"","")
  
  # TA_Reso=TA_Rast
  # # nomMNT_exp=paste0(strsplit(TA_Reso_Zone$NOM_ASC,"\\.")[[]][1],".gpkg")
  # nomMNT_exp=paste0(sapply(1:nrow(TA_Reso), function(x) {strsplit(TA_Reso$NOM_ASC[[x]],"\\.")[[1]][1]}),".gpkg")
  # 
  # 
  # TA_Reso$CHEMIN=file.path(paramTARaster$Doss,dirReso)
  # TA_Reso$DOSSIERASC=dirReso
  # TA_Reso$NOM_ASC=nomMNT_exp
  # 
  # listeGPKG=list.files( file.path(paramTARaster$Doss,dirReso),pattern=".gpkg$")
  # commun=intersect(TA_Reso$NOM_ASC,listeGPKG)
  # TA_Reso=TA_Reso[which(TA_Reso$NOM_ASC %in% commun),]
  # if (nrow(TA_Reso)>0)
  # {
  #   nomTA_Res=file.path(paramTARaster$Doss,paste0("TA",dirReso,".gpkg"))
  #   st_write(TA_Reso,nomTA_Res, delete_dsn = T,delete_layer = T, quiet = T)
  # }
}