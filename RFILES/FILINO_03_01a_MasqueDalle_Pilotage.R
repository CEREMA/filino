source(file.path(chem_routine,"FILINO_03_01a_MasqueDalle.R"))
source(file.path(chem_routine,"FILINO_03_01a_MasqueEau_Grass.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_03_01a_MasquePont_Grass.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_03_01a_MasqueVege_Grass.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_Utils.R"))

cat("\014")
cat("FILINO_03_01a_MasqueDalle.R\n")

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  cat("##################################################################\n")
  cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
  cat("##################################################################\n")
  
  TA=TA[n_int,]
  
  if (Etap3a[1]==1)
  {
    dimTA1=dim(TA)[1]
    
    nb_proc=min(nb_proc_Filino_[3],dimTA1)
    if(nb_proc==0)
    {
      
      for (iLAZ in 1:dimTA1)
      {
        # FILINO_03_01a_Job(iLAZ,TA[iLAZ,],dimTA1,NomLaz,reso)
        FILINO_03_01a_Job(iLAZ,TA[iLAZ,],dimTA1,NomLaz,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
      }
    }else{
      
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      
      foreach(iLAZ = 1:dimTA1,
              .combine = 'c',
              .inorder = FALSE) %dopar% 
        {
          FILINO_03_01a_Job(iLAZ,TA[iLAZ,],dimTA1,NomLaz,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
        }
      
      stopCluster(cl)
    }
  }
  
  # Fusion de toutes les zones de végétation
  # lecture des zones militaires pour les exclure
  ZICAD=st_transform(
    st_read(nomZICAD),
    st_crs(nEPSG))
  
  if (Etap3a[2]==1)
  {
    setwd(file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles))
    FILINO_FusionMasque(NomDirMasqueVEGE,TA,"VegeTropDense","")
  }
  if (Etap3a[3]==1)
  {
    setwd(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles))
    FILINO_FusionMasque(NomDirMasquePONT,TA,"Empr_PONT","")
  }
  setwd(chem_routine)
}