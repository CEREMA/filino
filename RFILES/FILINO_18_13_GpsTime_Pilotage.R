nb_proc=nb_proc_Filino_[18]
source(file.path(chem_routine,"FILINO_18_13_GpsTime.R"))

# NomLaz
resoGpsTime=25

FILINO_Creat_Dir(file.path(dsnlayer,NomDirGpsTime,racilayerTA,NomDossDalles))

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))

nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA_=TA[n_int,]
  if(nb_proc==0)
  {
    pgb <- txtProgressBar(min = 0, max = dim(TA_)[1],style=3)
    for (idalle in 1:dim(TA_)[1])
    { 
      setTxtProgressBar(pgb, idalle)
      FILINO_18_13_GpsTime_Job(idalle,TA_)
    }
  }else{
    cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
    require(foreach)
    cl <- parallel::makeCluster(nb_proc)
    registerDoParallel(cl)
    foreach(idalle = 1:dim(TA_)[1],
            .combine = 'c',
            .inorder = FALSE,
            .packages = c("sf","raster")) %dopar% 
      {
        FILINO_18_13_GpsTime_Job(idalle,TA_)
      }
    
    stopCluster(cl)
  }
}
