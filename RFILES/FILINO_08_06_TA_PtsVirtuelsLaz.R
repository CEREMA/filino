cat("\014")
cat("FILINO_10_06_TA_PtsVirtuelsLaz.R\n")
cat(" Liste des fichiers _PtsVirt_copc.laz\n")
cat("Parfois long...\n")
listeLazVirt=list.files(dsnlayer,pattern="_PtsVirt.copc.laz",recursive = T)

listeLazVirt_tmp=listeLazVirt[grep(listeLazVirt,pattern=racilayerTA)]
ici=grep(listeLazVirt_tmp,pattern="old")
if (length(ici)>0){listeLazVirt_tmp=listeLazVirt_tmp[-ici]}

ici=grep(listeLazVirt_tmp,pattern=paste0("/",racilayerTA,"/"))
if (length(ici)>0){listeLazVirt_tmp=listeLazVirt_tmp[ici]}else{listeLazVirt_tmp=NULL}

cat("Nombre de fichiers trouves",length(listeLazVirt_tmp),"\n")

if (length(listeLazVirt_tmp)>0)
{
  tour=list()
  Res=list()
  inc=0
  
  pgb <- txtProgressBar(min = 0, max = length(listeLazVirt_tmp),style=3)
  Iav=1
  for (nomlaz in listeLazVirt_tmp)
  {
    setTxtProgressBar(pgb, Iav)
    Iav=Iav+1
    
    nomjson=paste0(basename(nomlaz))
    nomjson=paste0(substr(nomjson,1,nchar(nomjson)-4),".json")
    cmd=paste0(shQuote(pdal_exe)," info ",shQuote(file.path(dsnlayer,nomlaz))," --summary")
    toto=system(cmd,intern=T)
    write(toto,nomjson)
    
    myData <- fromJSON(file=nomjson)
    
    if (Nettoyage==1){unlink(nomjson)}
    Xmin=myData$summary$bounds$minx
    Xmax=myData$summary$bounds$maxx
    Ymin=myData$summary$bounds$miny
    Ymax=myData$summary$bounds$maxy
    
    xabs=c(Xmin,Xmax,Xmax,Xmin,Xmin)
    yabs=c(Ymin,Ymin,Ymax,Ymax,Ymin)
    tour[[1]]=matrix(c(xabs,yabs),5,2)
    
    inc=inc+1
    
    listType=list.files(file.path(dsnlayer,dirname(nomlaz)),pattern="Type_",recursive = F)
    nomType=ifelse(length(listType)==0,"",listType[1])
    
    dsnlayer
    chem=dirname(file.path(dsnlayer,nomlaz))
    doss=substr(chem,nchar(dsnlayer)+2,nchar(chem))
    
    Res[[inc]]=st_sf(data.frame(CHEMIN=chem,DOSSIER=doss,NOM=basename(nomlaz),TypeLidar=racilayerTA,Type=nomType),"geometry" =st_sfc(st_polygon(tour,dim="XY"),crs=nEPSG))
    
    unlink(nomjson)
  }
  # TA=do.call(rbind,Res)
  cat("\nFusion\n")
  TA=dplyr::bind_rows(Res, .id = NULL)
  st_write(TA,paste0(racilayerTA,"_PtsVirt.shp"), delete_layer=T, quiet=T)
  file.copy(file.path(dsnlayer,NomDirSIGBase,"TA_ACTION_LAZ.qml"),
            paste0(racilayerTA,"_PtsVirt.qml"),
            overwrite = T)
}