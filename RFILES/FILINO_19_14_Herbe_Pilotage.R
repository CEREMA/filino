nb_proc=nb_proc_Filino_[19]
source(file.path(chem_routine,"FILINO_19_14_Herbe.R"))

if(nb_proc==0)
{
  for (iZone in 1:dim(ZONE)[1])
  {
    FILINO_19_14_Herbe_Job(iZone,ZONE)
  }
}else{
  cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
  require(foreach)
  cl <- parallel::makeCluster(nb_proc)
  registerDoParallel(cl)
  foreach(iZone = 1:dim(ZONE)[1],
          .combine = 'c',
          .inorder = FALSE) %dopar% 
    {
      FILINO_19_14_Herbe_Job(iZone,ZONE)
    }
  
  stopCluster(cl)
}

