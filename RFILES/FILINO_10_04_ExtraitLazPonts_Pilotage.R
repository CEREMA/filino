source(file.path(chem_routine,"FILINO_06_02ab_ExtraitLazMasquesEau.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_06_02c_creatPtsVirtuels.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_Utils.R"),encoding = "utf-8")
# FILINO_06_02ab_Pilotage=function(chem_routine)#,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
# {
cat("\014")
cat("FILINO_06_02ab_ExtraitLazPontsEau\n")

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))


# Il manque intersection Ponts2filino et zone en qgis

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  if (Supp_PtsVirt_copc_laz==1)
  {
    Liste_PtsVirt_copc_laz=list.files(file.path(dsnlayer,NomDirPonts,racilayerTA),pattern="SurfEAU_PtsVirt.copc.laz",full.names = TRUE,recursive=T)
    unlink(Liste_PtsVirt_copc_laz)
  }  
  
  cat("##################################################################\n")
  cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
  cat("##################################################################\n")
  TA=TA[n_int,]
  
  # On ne prend pas le masque de chaque TA car les objets 'auront pas la même numérotation
  # travail à faire pour mieux gérer cette problématique
  Ponts1=st_read(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,"Dalles",paste0("Empr_PONT_Qgis",".gpkg")))
  Ponts2=st_buffer(st_buffer(Ponts1,10),-5)
  # 20240306 ne garder que des gros Ponts
  # faire un buffer positif négatif pou élargir la zone de récupération en lissant
  
  Ponts2$IdGlobal=FILINO_NomMasque(Ponts2)
  
  # NbCharIdGlobal=nchar(Ponts2$IdGlobal[1])
  # 
  # nvieux=grep(Ponts2$FILINO,pattern="Vieux")
  # if (length(nvieux)>0) {Ponts2=Ponts2[-nvieux,]}
  # 
  # # Ponts1=st_read(file.path(dsnlayer,NomDirMasquePONT,paste0("Ponts1_FILINO","_",racilayerTA,".gpkg")))
  # Ponts1=st_read(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,"Ponts1_FILINO.gpkg"))
  nb=st_intersects(TA,Ponts2)
  n_int = which(sapply(nb, length)>0)
  TA=TA[n_int,]
  
  if (Etap10_04[1]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazPontsEau - Etap10_04[1]\n")
    nb_proc=min(nb_proc_Filino_[10],dim(TA)[1])
    if(nb_proc==0)
    {
      for (iLAZ in 1:dim(TA)[1])
      {
        TA_tmp=TA[iLAZ,]
        FILINO_06_02ab_Job1(iLAZ,TA_tmp,TA,Ponts2,NomDirPonts,raciPonts,NULL)
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      foreach(iLAZ = 1:dim(TA)[1],
              .combine = 'c',
              .inorder = FALSE,
              .packages = c("sf")) %dopar% 
        {
          TA_tmp=TA[iLAZ,]
          # library(sf)
          FILINO_06_02ab_Job1(iLAZ,TA_tmp,TA,Ponts2,NomDirPonts,raciPonts,NULL)
        }
      stopCluster(cl)
    }
  }
  
  if (Etap10_04[2]==1 | Etap10_04[3]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazPontsEau - Etap10_04[2]==1 | Etap10_04[3]==1\n")
    
    if(nb_proc==0)
    {
      for (iMasq in paste0(raciSurfEau,Ponts2$IdGlobal))
      {
        FILINO_06_02ab_Job23(iMasq,Ponts1,Ponts2,NbCharIdGlobal,NomDirPonts,raciPonts)
        
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      
      foreach(iMasq = paste0(raciSurfEau,Ponts2$IdGlobal),
              .combine = 'c',
              .inorder = FALSE,
              .packages = c("sf","ggplot2")) %dopar% 
        {
          
          FILINO_06_02ab_Job23(iMasq,Ponts1,Ponts2,NbCharIdGlobal,NomDirPonts,raciPonts)
        }
      
      stopCluster(cl)
    }
  }
}