FILINO_08_06_TA_PtsVirtuelsLaz_Job=function(iLAZ,nomlaz,nb_proc)
{
  tour=list()
  
  nomjson=paste0(basename(nomlaz))
  nomjson=paste0(substr(nomjson,1,nchar(nomjson)-4),iLAZ,".json")
  cmd=paste0(shQuote(pdal_exe)," info ",shQuote(file.path(dsnlayer,nomlaz))," --summary")
  toto=system(cmd,intern=T)
  write(toto,nomjson)
  
  myData <- rjson::fromJSON(file=nomjson)
  
  
  Xmin=myData$summary$bounds$minx
  Xmax=myData$summary$bounds$maxx
  Ymin=myData$summary$bounds$miny
  Ymax=myData$summary$bounds$maxy
  
  xabs=c(Xmin,Xmax,Xmax,Xmin,Xmin)
  yabs=c(Ymin,Ymin,Ymax,Ymax,Ymin)
  tour[[1]]=matrix(c(xabs,yabs),5,2)
  
  listType=list.files(file.path(dsnlayer,dirname(nomlaz)),pattern="Type_",recursive = F)
  nomType=ifelse(length(listType)==0,"",listType[1])
  
  chem=dirname(file.path(dsnlayer,nomlaz))
  doss=substr(chem,nchar(dsnlayer)+2,nchar(chem))
  
  if (verif==0){unlink(nomjson)}
  
  voila=st_sf(data.frame(CHEMIN=chem,DOSSIER=doss,NOM=basename(nomlaz),TypeLidar=racilayerTA,Type=nomType),"geometry" =st_sfc(st_polygon(tour,dim="XY"),crs=nEPSG))
  if (nb_proc>0){st_write(voila,file.path(dir_tmp,paste0(iLAZ,".gpkg")), delete_layer=T, quiet=T)}
  # return(st_sf(data.frame(CHEMIN=chem,DOSSIER=doss,NOM=basename(nomlaz),TypeLidar=racilayerTA,Type=nomType),"geometry" =st_sfc(st_polygon(tour,dim="XY"),crs=nEPSG)))
}