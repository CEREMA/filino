source(file.path(chem_routine,"FILINO_06_02ab_ExtraitLazMasquesEau.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_06_02c_creatPtsVirtuels.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_Utils.R"),encoding = "utf-8")
# FILINO_06_02ab_Pilotage=function(chem_routine)#,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
# {
cat("\014")
cat("FILINO_06_02ab_ExtraitLazMasquesEau\n")

# Lecture de la table d'assemblage
TA=st_read(file.path(dsnlayerTA,nomlayerTA))


# Il manque intersection masques2filino et zone en qgis

# Limitation de la table d'assemblage aux zones à traiter
nb=st_intersects(TA,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  if (Supp_PtsVirt_copc_laz==1)
  {
    Liste_PtsVirt_copc_laz=list.files(file.path(dsnlayer,NomDirSurfEAU,racilayerTA),pattern="SurfEAU_PtsVirt.copc.laz",full.names = TRUE,recursive=T)
    unlink(Liste_PtsVirt_copc_laz)
  }  
  
  cat("##################################################################\n")
  cat("Travail sur la TA:",file.path(dsnlayerTA,nomlayerTA),"\n")
  cat("##################################################################\n")
  TA=TA[n_int,]
  
  # On ne prend pas le masque de chaque TA car les objets 'auront pas la même numérotation
  # travail à faire pour mieux gérer cette problématique
  Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,paste0("Masques2_FILINO",".gpkg")))
  
  NbCharIdGlobal=nchar(Masques2$IdGlobal[1])
  
  nvieux=grep(Masques2$FILINO,pattern="Vieux")
  if (length(nvieux)>0) {Masques2=Masques2[-nvieux,]}
  
  # Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,paste0("Masques1_FILINO","_",racilayerTA,".gpkg")))
  Masques1=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques1_FILINO.gpkg"))
  
  nb=st_intersects(TA,Masques2)
  n_int = which(sapply(nb, length)>0)
  TA=TA[n_int,]
  
  if (Etap2[1]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazMasquesEau - Etap2[1]\n")
    nb_proc=min(nb_proc_Filino_[6],dim(TA)[1])
    if(nb_proc==0)
    {
      for (iLAZ in 1:dim(TA)[1])
      {
        TA_tmp=TA[iLAZ,]
        FILINO_06_02ab_Job1(iLAZ,TA_tmp,TA,Masques2,NomDirSurfEAU,raciSurfEau,ClassPourSurfEau)
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
          FILINO_06_02ab_Job1(iLAZ,TA_tmp,TA,Masques2,NomDirSurfEAU,raciSurfEau,ClassPourSurfEau)
        }
      stopCluster(cl)
    }
  }
  
  if (Etap2[2]==1 | Etap2[3]==1)
  {
    cat("\014")
    cat("FILINO_06_02ab_ExtraitLazMasquesEau - Etap2[2]==1 | Etap2[3]==1\n")
    
    if(nb_proc==0)
    {
      # browser()
      for (iMasq in paste0(raciSurfEau,Masques2$IdGlobal))
      {
        FILINO_06_02ab_Job23(iMasq,Masques1,Masques2,NbCharIdGlobal,NomDirSurfEAU,raciSurfEau,TA)
        
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      
      foreach(iMasq = paste0(raciSurfEau,Masques2$IdGlobal),
              .combine = 'c',
              .inorder = FALSE,
              .packages = c("sf","ggplot2","ggrepel","dplyr")) %dopar% 
        {
          
          FILINO_06_02ab_Job23(iMasq,Masques1,Masques2,NbCharIdGlobal,NomDirSurfEAU,raciSurfEau,TA)
        }
      
      stopCluster(cl)
    }
  }
}

cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_06_02ab_ExtraitLazMasquesEau_Pilotage #######################################\n")
cat("---------------- Fusion Extraction des points Lidar dans les Masques 2: \n")
cat("Etape a: Vérifier si des fichiers SurfEAU_xxxnomdalleLidarxxx.vide existent.\n")
cat("Deux solutions.\n")
cat("     - Il n'y a pas de points sol ou eau dans certains masques OK\n")
cat("     - Il y a eu un problème mémoire en mode parallèle - supprimer les xxx.vide et relancer\n")
cat("\n")
cat("Etape c: Vérifier si des fichiers .jpg ne sont pas à des valeurs de poids 0 - sinon supprimer et relancer\n")
cat("\n")
cat("    - Il est souvent utile de faire passer un coup en mode non parallèle à la fin pour être plus sûr...\n")
cat("\n")
cat("Il est souvent utile de regarder les images terminant par '_3_Canaux_30_pcbas.jpg'...\n")
cat("   - L'analyse des écluses est encore manuelle (pas d'analyse dans FILINO des données dans la BDTopo, un jour peut-être......\n")
cat("   - Reprendre le travail manuel et relancer de cette étape sans rien supprimer, la gestion est normalement automatique\n")
cat("\n")
cat("\n")
cat("Par exemple, le dernier travail se trouve dans le dossier:","","\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
