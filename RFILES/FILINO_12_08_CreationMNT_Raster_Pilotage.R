nb_proc=nb_proc_Filino_[12]
source(file.path(chem_routine,"FILINO_12_08_CreationMNT_Raster.R"))
source(file.path(chem_routine,"FILINO_Utils.R"))

cat("\014")
cat("FILINO_12_08_CreationMNT_Raster.R\n")

TAHDCla=st_read(file.path(dsnlayerTA,nomlayerTA))  
nb=st_intersects(TAHDCla,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TAHDCla=TAHDCla[n_int,]
  
  FILINO_Creat_Dir(file.path(dsnlayer,NomDirMNTGDAL,racilayerTA))
  
  
  if(nb_proc==0)
  {
    for (idalle in 1:dim(TAHDCla)[1])
    {
      # TA_tmp=TAHDCla[idalle,]
      
      FILINO_12_08_CreationMNT_Raster_Job(idalle)
    }
  }else{
    cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
    require(foreach)
    cl <- parallel::makeCluster(nb_proc)
    registerDoParallel(cl)
    
    foreach(idalle = 1:dim(TAHDCla)[1],
            .combine = 'c',
            .inorder = FALSE) %dopar% 
      {
        FILINO_12_08_CreationMNT_Raster_Job(idalle)
      }
    stopCluster(cl)
  }
}  
