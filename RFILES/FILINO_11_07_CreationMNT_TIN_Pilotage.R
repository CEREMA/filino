nb_proc=nb_proc_Filino_[11]

# FILINO_11_07_Pilotage=function(chem_routine)
# {

source(file.path(chem_routine,"FILINO_11_07_CreationMNT_TIN.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_11_07_CreationMNT_TIN_Grass.R"),encoding = "utf-8")
source(file.path(chem_routine,"FILINO_Utils.R"),encoding = "utf-8")

cat("\014")
cat("FILINO_11_07_CreationMNT_TIN.R\n")

TA=st_read(file.path(dsnlayerTA,nomlayerTA))

for (iTypeTIN in nTypeTIN)
{
  
  type=TypeTIN[iTypeTIN]
  
  if (iTypeTIN==1) NomDirMNTTIN=NomDirMNTTIN_F else NomDirMNTTIN=NomDirMNTTIN_D 
  FILINO_Creat_Dir(file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles))
  
  nomPtsVirt=file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp"))
  if (file.exists(nomPtsVirt)==T & iTypeTIN==1)
  {
    TAPtsVirtu=st_read(file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")))
    # TAPtsVirtu=st_read(file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")))
  }else{
    # on crée une fausse table vide
    TAPtsVirtu=TA
    inc=1:dim(TAPtsVirtu)[1]
    TAPtsVirtu=TAPtsVirtu[-inc,]
  }
  
  listeMasq2=list.files(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA),pattern=paste0("Masques2_FILINO",".gpkg"))
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
  if (length(listeMasq2)>0)
  {
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2[1]))
    # On ne garde que les masques 2 en bord de mer! pour un nettoyage
    Masques2Mer=Masques2[which(substr(Masques2$FILINO,1,3)=="Mer"),]
  }
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA_Zone=TA[n_int,]
    
    if(nb_proc==0)
    {
      for (idalle in 1:dim(TA_Zone)[1])
      {
        FILINO_11_07_Job(idalle,TA_Zone,NomDirMNTTIN,type,TA,TAPtsVirtu,listeMasq2,Masques2Mer)
      }
    }else{
      cat("------ ",nb_proc," CALCULS MODE PARALLELE -------------\n")
      require(foreach)
      cl <- parallel::makeCluster(nb_proc)
      registerDoParallel(cl)
      foreach(idalle = 1:dim(TA_Zone)[1]) %dopar% 
        {
          library(sf)
          FILINO_11_07_Job(idalle,TA_Zone,NomDirMNTTIN,type,TA,TAPtsVirtu,listeMasq2,Masques2Mer)
        }
      
      stopCluster(cl)
    }
  }
}