nb_proc=nb_proc_Filino_[17]
source(file.path(chem_routine,"FILINO_17_12_Difference_Filtree.R"))

cat("\014")
cat("FILINO_17_12_Differences.R\n")
if (nCalcDiff[1]==0){NomDIFF=NomDirDIFF}else{NomDIFF=NomDirVEGEDIFF}
FILINO_Creat_Dir(file.path(NomDIFF,NomDossDalles))

# Lecture de la table d'assemblage 2
nomTA2_=file.path(paramTARaster2$Doss,paramTARaster2$NomTA)
TA2=st_read(nomTA2_)
nb=st_intersects(TA2,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA2_=TA2[n_int,]
  # Lecture de la table d'assemblage 1
  nomTA1_=file.path(paramTARaster1$Doss,paramTARaster1$NomTA)
  TA1=st_read(nomTA1_)
  nb=st_intersects(TA1,st_buffer(TA2,10))
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA1_=TA1[n_int,]
    
    if(nb_proc==0)
    {
      for (idalle in 1:dim(TA2_)[1])
      {
        FILINO_17_12_Job(idalle,nomTA1_,nomTA2_,TA1,TA2_[idalle,],nCalcDiff)
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      foreach(idalle = 1:dim(TA1_)[1],
              .combine = 'c',
              .inorder = FALSE,
              .packages = c("sf")) %dopar%
        {
          FILINO_17_12_Job(idalle,nomTA1_,nomTA2_,TA1,TA2_[idalle,],nCalcDiff)
        }
      
      stopCluster(cl)
    }
  }
}    