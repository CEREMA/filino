source(file.path(chem_routine,"FILINO_08_06_TA_PtsVirtuelsLaz.R"),encoding = "utf-8")

cat("\014")
cat("FILINO_10_06_TA_PtsVirtuelsLaz.R\n")
cat(" Liste des fichiers _PtsVirt_copc.laz\n")

# listeLazVirt=list.files(dsnlayer,pattern="_PtsVirt.copc.laz",recursive = T)

listeVirt=function(dsnlayer,SousDir)
{
  
  cat(paste0("Analyse ",SousDir," - Parfois long...\n"))
  listeLazVirt=list.files(file.path(dsnlayer,SousDir),pattern="_PtsVirt.copc.laz",recursive = T)
  listeLazVirt=file.path(SousDir,listeLazVirt)
}
listeLazVirtl=list()
inc=1
liste=listeVirt(dsnlayer,NomDirSurfEAU)
if (length(liste)>0){listeLazVirtl[[inc]]=data.frame(liste);inc=inc+1}
liste=listeVirt(dsnlayer,nomDirViSOLssVEGE)
if (length(liste)>0){listeLazVirtl[[inc]]=data.frame(liste)}
listeLazVirt=do.call(rbind,listeLazVirtl)

listeLazVirt_tmp=listeLazVirt[grep(listeLazVirt,pattern=racilayerTA)]
ici=grep(listeLazVirt_tmp,pattern="old")
if (length(ici)>0){listeLazVirt_tmp=listeLazVirt_tmp[-ici]}

ici=grep(listeLazVirt_tmp,pattern=paste0("/",racilayerTA,"/"))
if (length(ici)>0){listeLazVirt_tmp=listeLazVirt_tmp[ici]}else{listeLazVirt_tmp=NULL}

#Bidouille pour changer le data frame en qqch de mieux...
listeLazVirt_tmp=listeLazVirt_tmp[1:nrow(listeLazVirt_tmp),]
cat("Nombre de fichiers trouves",length(listeLazVirt_tmp),"\n")

if (length(listeLazVirt_tmp)>0)
{
  Res=list()
  nb_proc=min(floor(0.6*detectCores()),nb_proc_Filino_[8],length(listeLazVirt_tmp))
  if(nb_proc==0)
  { 
    pgb <- txtProgressBar(min = 0, max = length(listeLazVirt_tmp),style=3)
    for (iLAZ in 1:length(listeLazVirt_tmp))
    {
      setTxtProgressBar(pgb, iLAZ)
      Res[[iLAZ]]=FILINO_08_06_TA_PtsVirtuelsLaz_Job(iLAZ,listeLazVirt_tmp[iLAZ],nb_proc)
    }
    cat("\nFusion\n")
    TA=dplyr::bind_rows(Res, .id = NULL)
    
  }else{
    dir_tmp=file.path(dsnlayer,"TEMP")
    FILINO_Creat_Dir(dir_tmp)
    cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
    require(foreach)
    cl <- parallel::makeCluster(nb_proc)
    registerDoParallel(cl)
    foreach(iLAZ=1:length(listeLazVirt_tmp),
            .combine = 'c',
            .packages = c("rjson","sf"))  %dopar% 
      {
        Res[[iLAZ]]=FILINO_08_06_TA_PtsVirtuelsLaz_Job(iLAZ,listeLazVirt_tmp[iLAZ],nb_proc)
        # FILINO_08_06_TA_PtsVirtuelsLaz_Job(iLAZ,listeLazVirt_tmp[iLAZ])
      }
    stopCluster(cl)
    setwd(dir_tmp)
    FILINO_FusionMasque(dir_tmp,NULL,"","")
    setwd(chem_routine)
    
    TA=st_read(file.path(dir_tmp,"_Concat_Qgis.gpkg"))
    Sys.sleep(0.1);unlink(dir_tmp,recursive=TRUE)
  }
  
  # TA=do.call(rbind,Res)
  
  st_write(TA,file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")), delete_layer=T, quiet=T)
  file.copy(file.path(dsnlayer,NomDirSIGBase,"TA_ACTION_LAZ.qml"),
            file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.qml")),
            overwrite = T)
}

cat("\n")
cat("\n")
cat("########################################################################################################\n")
cat("######################### FILINO A LIRE SVP ###############################################################\n")
cat("---------------- ETAPE FILINO_08_06_TA_PtsVirtuelsLaz_Pilotage.R #######################################\n")
cat("---------------- Table d'assemblage des points virtuels: \n")
cat("\n")
cat("\ Ouvrir :  ",file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")),"    \n")
cat("La table d'assemblage créée à cette étape permet d'ouvrir dans Qgis avec des actions\n")
cat("   - les points virtuels crées\n")
cat("   - les répertoires pour voir les fichiers images\n")
cat("\n")
cat("\n")
cat("######################### Fin FILINO A LIRE ###############################################################\n")
cat("######################### Ne pas lire les messages d'avis ou warnings en dessous###########################\n")
cat("\n")
