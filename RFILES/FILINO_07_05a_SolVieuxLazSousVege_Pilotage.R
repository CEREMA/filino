source(file.path(chem_routine,"FILINO_07_05a_SolVieuxLazSousVege.R"))
source(file.path(chem_routine,"FILINO_Utils.R"))

# FILINO_07_05a_Pilotage=function(chem_routine)#,reso,largdalle,paramXYTA,iTA,dsnTALidar,dsnlayer)
# {

cat("\014")
cat("FILINO_09_05a_SolVieuxLazSousVege.R\n")

Classe_New=CodeVirtbase+CodeVirtuels[8,1]

# Lecture de la table d'assemblage LidarHD
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
  
  ### boucle sur les ta old
  #############################################################################
  #############################################################################
  #############################################################################
  #############################################################################
  
  for (inlalaold in nlalaold)
  {
    # # Recuperation des parametres de la table d'assemblage NUALID ou 2 pts/m²
    dsnTALidarOld =paramTALidar[inlalaold,2]
    nomTALidarOld =paramTALidar[inlalaold,3]
    racilayerTAold=substr(nomTALidarOld,1,nchar(nomTALidarOld)-4)
    # Lecture de la table d'assemblage LidarHD
    TA_Old=st_read(file.path(dsnTALidarOld,nomTALidarOld))
    
    nb=st_intersects(TA,TA_Old)
    n_int = which(sapply(nb, length)>0)
    
    if (length(n_int)>0)
    {
      TA_TA_OLD=TA[n_int,]
      
      # Boucle sur les fichiers Laz
      nb_proc=min(floor(0.6*detectCores()),nb_proc_Filino_[7],dim(TA_TA_OLD)[1])
      
      if(nb_proc==0)
      {
        for (iLAZ in 1:dim(TA_TA_OLD)[1])
        {
          FILINO_07_05a_Job(iLAZ,TA_TA_OLD[iLAZ,],racilayerTAold,TA_Old,Classe_New)
        }
      }else{
        cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
        require(foreach)
        cl <- parallel::makeCluster(nb_proc)
        registerDoParallel(cl)
        
        foreach(iLAZ = 1:dim(TA_TA_OLD)[1],
                .combine = 'c',
                .inorder = FALSE,
                .packages = c("sf")) %dopar% 
          {
            FILINO_07_05a_Job(iLAZ,TA_TA_OLD[iLAZ,],racilayerTAold,TA_Old,Classe_New)
          }
        stopCluster(cl)
      }
    }
  }
}
cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_07_05a_SolVieuxLazSousVege_Pilotage.R #######################################\n")
cat("\n")
cat("Des fichiers Laz des anciens points SOL sont dans ce dossier:",file.path(dsnlayer,nomDirViSOLssVEGE,racilayerTA,NomDossDalles),"\n")
cat("\n")
cat("La meilleure solution sur des gros projets est de lancer l'étape 'FILINO_08_06_TA_PtsVirtuelsLaz.R'\n")
cat("La table d'assemblage créée à cette étape permet d'ouvrir dans Qgis avec des actions\n")
cat("   - les points virtuels crées\n")
cat("   - les répertoires pour voir les fichiers images\n")
cat("\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
cat("\n")