nb_proc=nb_proc_Filino_[17]
source(file.path(chem_routine,"FILINO_17_12_Differences.R"))

cat("\014")
cat("FILINO_17_12_Differences.R\n")

FILINO_Creat_Dir(NomDirDIFF)

# Lecture de la table d'assemblage
TA1=st_read(file.path(paramTARaster1$Doss,paramTARaster1$NomTA))
nb=st_intersects(TA1,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA1_=TA1[n_int,]
  
  TA2=st_read(file.path(paramTARaster2$Doss,paramTARaster2$NomTA))
  nb=st_intersects(TA2,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA2_=TA2[n_int,]
    
    
    raci=substr(TA1_$NOM_ASC,1,nchar(TA1_$NOM_ASC)-5)
    #Creation d'un monde GRASS
    
    if(nb_proc==0)
    {
      for (idalle in 1:dim(TA1_)[1])
      {
        FILINO_17_12_Job(idalle)
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      foreach(idalle = 1:dim(TA1_)[1],
              .packages = c("sf")) %dopar% 
        {
          FILINO_17_12_Job(idalle)
        }
      
      stopCluster(cl)
    }
  }
}    