library("rjson")
library("sf")

# Initialisation des chemins et variables
chem_routine = R.home(component = "cerema")
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))

listeLazVirt=list.files(pattern="_PtsVirt.laz",recursive = T)

# Boucle sur les différentes tables d'assemblage
for (iTA in 1:length(dsnTALidar))
{
  nomlayerTA=nomTALidar[iTA]
  racilayerTA=substr(nomlayerTA,1,nchar(nomlayerTA)-4)
  
  listeLazVirt_tmp=listeLazVirt[grep(listeLazVirt,pattern=racilayerTA)]
  ici=grep(listeLazVirt_tmp,pattern="old")
  if (length(ici)>0){listeLazVirt_tmp=listeLazVirt_tmp[-ici]}
  print(listeLazVirt_tmp)
  tour=list()
  Res=list()
  inc=0
  for (nomlaz in listeLazVirt_tmp)
  {
    nomjson=paste0(basename(nomlaz))
    nomjson=paste0(substr(nomjson,1,nchar(nomjson)-4),".json")
    cmd=paste0(shQuote("C:\\OSGeo4W\\bin\\pdal.exe")," info ",shQuote(file.path(dsnlayer,nomlaz))," --summary")
    toto=system(cmd,intern=T)
    write(toto,nomjson)
    
    myData <- fromJSON(file=nomjson)
    
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
    
    Res[[inc]]=st_sf(data.frame(CHEMIN=chem,DOSSIER=doss,NOM=basename(nomlaz),TypeLidar=racilayerTA,Type=nomType),"geometry" =st_sfc(st_polygon(tour,dim="XY"),crs=2154))
  }
  TA=do.call(rbind,Res)
  st_write(TA,paste0(racilayerTA,"_PtsVirt.shp"), delete_layer=T, quiet=T)
  file.copy(file.path(dsnlayer,NomDirSIGBase,"TA_ACTION_LAZ.qml"),
            paste0(racilayerTA,"_PtsVirt.qml"),
            overwrite = T)
}