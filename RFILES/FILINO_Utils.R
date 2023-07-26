FILINO_NomMasque = function(Masque)
{
  Surf_km2 = st_area(Masque) / 1000000
  
  centre_coord <- Masque %>% 
    st_centroid() %>% 
    st_coordinates() %>% 
    floor()
  
  Smax=999
  units(Smax)="m^2"
  if (length(which(floor(Surf_km2)>Smax))>0){browser()}
  
  Identifiant = paste0(
    # "S",
    formatC(floor(Surf_km2), width = 3, flag = "0"),
    "_",
    formatC(
      round(1000000 * (Surf_km2 - floor(Surf_km2))),
      width = 6,
      flag = "0",
      format = "d"
    ),
    "km",
    "X",formatC(centre_coord[,1], width = 7, flag = "0",format="d"),
    "Y",formatC(centre_coord[,2], width = 7, flag = "0",format="d")
  )
  return(Identifiant)
}

FILINO_FusionMasque = function(nombre,TA)
{
  # Suppression des anciens découpages
  ListPart=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masque",nombre,"_Part"))
  if (length(ListPart)>0){unlink(ListPart)}
  
  decoup=100
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Début de fusion des masques ",nombre,"\n")
  listMasq=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("_Masque",nombre,".gpkg"))
  substr(listMasq,1,nchar(listMasq[1])-13)
  substr(TA$NOM,1,nchar(TA$NOM[1])-4)
  listMasq=paste0(intersect(substr(listMasq,1,nchar(listMasq[1])-13),substr(TA$NOM,1,nchar(TA$NOM[1])-4)),"_Masque",nombre,".gpkg")
  cat("Nombre de dalles:",length(listMasq),"\n")
  for (ibc in seq(1,length(listMasq),decoup))
  {
    cat(min(ibc:(min(ibc+decoup-1,length(listMasq))))," ",max(ibc:(min(ibc+decoup-1,length(listMasq)))))
    cmd=paste0(qgis_process, " run native:mergevectorlayers")
    for (iM in ibc:(min(ibc+decoup-1,length(listMasq))))
    {cmd=paste0(cmd," --LAYERS=",shQuote(listMasq[iM]))}
    cmd=paste0(cmd,
               " --CRS=QgsCoordinateReferenceSystem('EPSG:2154') ",
               " --OUTPUT=",shQuote(paste0("Masque",nombre,"_Part",ibc,".gpkg")))
    system(cmd)
  }
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin de fusion des masques\n")
  
  ListPart=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masque",nombre,"_Part"))
  cmd=paste0(qgis_process, " run native:mergevectorlayers")
  for (iM in 1:length(ListPart))
  {cmd=paste0(cmd," --LAYERS=",shQuote(ListPart[iM]))}
  cmd=paste0(cmd,
             " --CRS=QgsCoordinateReferenceSystem('EPSG:2154') ",
             " --OUTPUT=",shQuote(paste0("Masque",nombre,"_Concat_Qgis.gpkg")))
  system(cmd)
  
  cmd=paste0(qgis_process, " run native:buffer",
             " --INPUT=",shQuote(paste0("Masque",nombre,"_Concat_Qgis.gpkg")),
             " --DISTANCE=0 --SEGMENTS=5 --END_CAP_STYLE=0 --JOIN_STYLE=0 --MITER_LIMIT=2 --DISSOLVE=True",
             " --OUTPUT=",shQuote(paste0("Masque",nombre,"_Fusion_Qgis.gpkg")))
  system(cmd)
  
  cmd=paste0(qgis_process, " run native:multiparttosingleparts",
             " --INPUT=",shQuote(paste0("Masque",nombre,"_Fusion_Qgis.gpkg")),
             " --OUTPUT=",shQuote(paste0("Masque",nombre,"_Qgis.gpkg")))
  system(cmd)
  
  Masques=st_read(paste0("Masque",nombre,"_Qgis.gpkg"))
  Masques=Masques[,1]
  
  nb=st_intersects(Masques,ZICAD)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0){Masques=Masques[-n_int,]}
  Masques$Aire=round(st_area(Masques),2)
  st_geometry(Masques)="geometry"
  
  ListPart=list.files(file.path(dsnlayer,NomDirMasque,racilayerTA),pattern=paste0("Masque",nombre,"_Part"))
  if (length(ListPart)>0){unlink(ListPart)}
  
  return(Masques)
}


FILINO_Intersect_Qgis=function(nomA,nomB,NomC)
{
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial restant\n")
  
  cmd <- paste0(qgis_process, " run native:createspatialindex",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
                " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasque,racilayerTA,"trhydro_tmp.gpkg")))
  system(cmd)
  
  cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                " --INPUT=",shQuote(nomA),
                " --PREDICATE=0",
                " --JOIN=",shQuote(nomB),
                " --JOIN_FIELDS=Id --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
                " --OUTPUT=",shQuote(nomC))
  system(cmd)
  liaison=read.csv(nomC)
  return(liaison)
}