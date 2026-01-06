FILINO_Creat_Dir=function(chem_et_ou_nom)
{
  if (file.exists(chem_et_ou_nom)==F)    {dir.create(chem_et_ou_nom,recursive = T)}
}

################################################################################
################################################################################

FILINO_writers_gdal=function(nomjson,nominput,Ch_Classif,nom_method,reso,Ouest,Est,Sud,Nord,nom_Rast)
{
  write(paste0("["),nomjson)
  write(paste0("    {"),nomjson,append=T)
  write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
  write(paste0("       ",shQuote("filename"),":",shQuote(nominput),","),nomjson,append=T)
  write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
  write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
  write(paste0("    },"),nomjson,append=T)
  if (nom_method=="count"){reso=1000}
  if (nchar(Ch_Classif)>0)
  {
    write(paste0("    {"),nomjson,append=T)
    write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
    write(paste0("       ",shQuote("limits"),":",shQuote(Ch_Classif)),nomjson,append=T)
    write(paste0("    },"),nomjson,append=T)
  }else{
    reso=1000
  }
  write(paste0("    {"),nomjson,append=T)
  write(paste0("       ",shQuote("type"),":",shQuote("writers.gdal"),","),nomjson,append=T)
  write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)
  write(paste0("       ",shQuote("output_type"),":",shQuote(nom_method),","),nomjson,append=T)
  write(paste0("       ",shQuote("resolution"),": ",reso,","),nomjson,append=T)
  # Ancien
  # write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",as.numeric(Ouest)     ,",",as.numeric(Est)-reso,"],[",as.numeric(Sud)     ,",",as.numeric(Nord)-reso,"])")),","),nomjson,append=T)
  # # Nouveau du 05/08/2025 voir si cela ne plante pas pour d'autres choix que reso 0.5...
  # write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",as.numeric(Ouest)+reso,",",as.numeric(Est)-reso,"],[",as.numeric(Sud)+reso,",",as.numeric(Nord)-reso,"])")),","),nomjson,append=T)
  if (nom_method!="count")
  {
    write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",as.numeric(Ouest)     ,",",as.numeric(Est)     ,"],[",as.numeric(Sud)     ,",",as.numeric(Nord)     ,"])")),","),nomjson,append=T)
  }else{
    write(paste0("       ",shQuote("bounds"),":",shQuote(paste0("([",as.numeric(Ouest)     ,",",as.numeric(Ouest)     ,"],[",as.numeric(Sud)     ,",",as.numeric(Sud)     ,"])")),","),nomjson,append=T)  
  }
  write(paste0("       ",shQuote("filename"),":",shQuote(file.path(dirname(nomjson),nom_Rast))),nomjson,append=T)
  write(paste0("    }"),nomjson,append=T)
  write(paste0("]"),nomjson,append=T)
  
  cmd=paste(pdal_exe,"pipeline",nomjson)
  cat("---------------------------------------------\n")
  cat("PDAL ",nom_Rast,"\n")
  toto=system(cmd)
  
  # Test pour voir si Pdal passe, si ce n'est pas le cas, grande chance que le fichier soit corrompu
  if (toto!=0){file.create(paste0(nominput,"BUG"))}
  
  if (Nettoyage==1){unlink(nomjson)}
}

################################################################################
################################################################################

FILINO_BDD=function(titre,preselec,Choix)
{
  nChoix = select.list(
    Choix,
    title = titre,
    preselect = preselec,
    multiple = T,
    graphics = T
  )
  
  nFIL = which(Choix %in% nChoix)
  if (length(nFIL)==0){print("VOUSAVEZVOULUQUECAFASSEBADABOOM_CESTGAGNE");BOOM=BOOOM}
  n=matrix(0,length(Choix),1)
  n[nFIL]=1
  return(n)
}
################################################################################
################################################################################
FILINO_NomMasque = function(Masque)
{
  Surf_km2 = st_area(Masque) / 1000000
  
  centre_coord <- Masque %>% 
    st_centroid() %>% 
    st_coordinates() %>% 
    floor()
  
  Smax=999
  units(Smax)="m^2"
  # if (length(which(floor(Surf_km2)>Smax))>0){browser()}
  
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

################################################################################
################################################################################
FILINO_FusionMasque = function(nomDir,TA,motcle,nombre)
{
  # Suppression des anciens découpages
  ListPart=list.files(file.path(dsnlayer,nomDir,racilayerTA,"Dalles"),pattern=paste0(motcle,nombre,"_Part"))
  if (length(ListPart)>0)
  {
    unlink(ListPart)
    ListPart=list.files(file.path(dsnlayer,nomDir,racilayerTA,"Dalles"),pattern=paste0(motcle,nombre,"_Part"))
    if(length(ListPart)>0){cat("BUG, les fichiers ",ListPart,"ne veulent pas se supprimer, à faire manuellement\n");BOOM=SUPP_PART_XXX}
  }
  
  decoup=100
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Début de fusion des masques ",nombre,"\n")
  
  if(is.null(TA)==T)
  {
    nomdosstmp=nomDir
    listMasq=file.path(nomDir,list.files(nomDir,pattern=paste0(".gpkg")))
  }else{
    nomdosstmp=file.path(dsnlayer,nomDir,racilayerTA,NomDossDalles)
    listMasq=list.files(file.path(dsnlayer,nomDir,racilayerTA,NomDossDalles),pattern=paste0("_",motcle,nombre,".gpkg"))
    
    nbCaracFin=nchar(paste0("_",motcle,nombre,".gpkg")) 
    if (length(listMasq)>0)
    {
      listMasq=paste0(intersect(substr(listMasq,1,nchar(listMasq[1])-nbCaracFin),gsub(".copc","_copc",substr(TA$NOM,1,nchar(TA$NOM[1])-4))),"_",motcle,nombre,".gpkg")
    }
  }
  # substr(listMasq,1,nchar(listMasq[1])-nbCaracFin)
  # substr(TA$NOM,1,nchar(TA$NOM[1])-4)
  
  if (length(listMasq)>0)
  {    
    cat("Nombre de dalles:",length(listMasq),"\n")
    print(listMasq[1:min(10,length(listMasq))])
    for (ibc in seq(1,length(listMasq),decoup))
    {
      cat(min(ibc:(min(ibc+decoup-1,length(listMasq))))," ",max(ibc:(min(ibc+decoup-1,length(listMasq)))))
      cmd=paste0(qgis_process, " run native:mergevectorlayers")
      for (iM in ibc:(min(ibc+decoup-1,length(listMasq))))
      {cmd=paste0(cmd," --LAYERS=",shQuote(listMasq[iM]))}
      cmd=paste0(cmd,
                 paste0(" --CRS=QgsCoordinateReferenceSystem('EPSG:",nEPSG,"') "),
                 " --OUTPUT=",shQuote(paste0(motcle,nombre,"_Part",ibc,".gpkg")))
      paste(cmd);system(cmd)
    }
    cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Fin de fusion des masques\n")
    
    
    ListPart=list.files(nomdosstmp,pattern=paste0(motcle,nombre,"_Part"))
    cmd=paste0(qgis_process, " run native:mergevectorlayers")
    for (iM in 1:length(ListPart))
    {cmd=paste0(cmd," --LAYERS=",shQuote(ListPart[iM]))}
    
    cmd=paste0(cmd,
               paste0(" --CRS=QgsCoordinateReferenceSystem('EPSG:",nEPSG,"') "),
               " --OUTPUT=",shQuote(paste0(motcle,nombre,"_Concat_Qgis.gpkg")))
    system(cmd)

    if(is.null(TA)==F)
    {
      cat("----------------------------------------------------------------------\n")
      cat("Dissolve parfois très très trop long ","\n")
      cat("surtout pour la fusion de la végétation ","\n")
      cat("Pour la végétation, inutile pour la suite faites planter et passer à la suite ","\n")
      cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," - Date de début pour voir","\n")
      cmd=paste0(qgis_process, " run native:buffer",
                 " --INPUT=",shQuote(paste0(motcle,nombre,"_Concat_Qgis.gpkg")),
                 " --DISTANCE=0 --SEGMENTS=5 --END_CAP_STYLE=0 --JOIN_STYLE=0 --MITER_LIMIT=2 --DISSOLVE=True",
                 " --OUTPUT=",shQuote(paste0(motcle,nombre,"_Fusion_Qgis.gpkg")))
      system(cmd)
      
      cmd=paste0(qgis_process, " run native:multiparttosingleparts",
                 " --INPUT=",shQuote(paste0(motcle,nombre,"_Fusion_Qgis.gpkg")),
                 " --OUTPUT=",shQuote(paste0(motcle,nombre,"_Qgis.gpkg")))
      system(cmd)
      
      Masques=st_read(paste0(motcle,nombre,"_Qgis.gpkg"))
      Masques=Masques[,1]
      
      nb=st_intersects(Masques,ZICAD)
      n_int = which(sapply(nb, length)>0)
      if (length(n_int)>0){Masques=Masques[-n_int,]}
      Masques$Aire=round(st_area(Masques),2)
      st_geometry(Masques)="geometry"
      
      ListPart=list.files(file.path(dsnlayer,nomDir,racilayerTA,NomDossDalles),pattern=paste0(motcle,nombre,"_Part"))
      if (length(ListPart)>0){unlink(ListPart)}
      
      return(Masques)
    }
  }
}


################################################################################
################################################################################
FILINO_Intersect_Qgis=function(nom_A,nom_B,nom_C)
{
  cat("nomA ",nom_A,"\n")
  cat("nomB ",nom_B,"\n")
  cat("nomC ",nom_C,"\n")
  
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Export Index Spatial restant\n")
  
  # cmd <- paste0(qgis_process, " run native:createspatialindex",
  #               " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ",
  #               " --INPUT=",shQuote(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"trhydro_tmp.gpkg")))
  # system(cmd)
  
  cmd <- paste0(qgis_process," run native:joinattributesbylocation ",
                " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019",
                " --INPUT=",shQuote(nom_A),
                " --PREDICATE=0",
                " --JOIN=",shQuote(nom_B),
                " --JOIN_FIELDS=Id --METHOD=0 --DISCARD_NONMATCHING=true --PREFIX=",
                " --OUTPUT=",shQuote(nom_C))
  print(cmd)
  system(cmd)
  
  parties <- strsplit(nom_C, "\\.")[[1]]
  # Obtenir la dernière partie, qui est l'extension
  extension <- tolower(tail(parties, 1))
  if (extension=="csv")
  {
    liaison=read.csv(nom_C)
    return(liaison)
  }
}

###########################################################################################################
###########################################################################################################
#############
#FONCTION multiplot
multiplot <-   function(..., plotlist=NULL, file, cols=1, layout=NULL)
{
  require(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      if(inherits(plots[[i]], "gg")) {
        
        print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                        layout.pos.col = matchidx$col))
        
      } else if(inherits(plots[[i]], "gtable")) {
        
        pushViewport(viewport(layout.pos.row = matchidx$row, 
                              layout.pos.col = matchidx$col))
        grid.draw(plots[[i]])
        upViewport()
      }
      
    }
  }
}
############################################################################################
ConvertGPKG=function(NomInput,tuilage)
{
  
  ici=grep(NomInput,pattern="GpsTime")
  if (length(ici)>0)
  {
    NomInput2=paste0(substr(NomInput,1,nchar(NomInput)-4),"_Float32.vrt")
    cmd = paste0(shQuote(OSGeo4W_path)," gdal_translate ", "-ot Float32 ",shQuote(NomInput)," ",shQuote(NomInput2))
    print(cmd);system(cmd)
    # gdal_translate -ot Float32 "H:/FILINO_Travail/10_GpsTime/D34_LEZ_MOSSON_COMPLET_GpsTime_Diff.vrt" "H:/FILINO_Travail/10_GpsTime/D34_LEZ_MOSSON_COMPLET_GpsTime_Diff_Float32.vrt"
    NomInput=NomInput2
  }
  
  NomGPKG=paste0(substr(NomInput,1,nchar(NomInput)-4),".gpkg")
  
  if (file.exists(NomGPKG)){unlink(NomGPKG)}
  cat("#######################################################################\n")
  cmd = paste0(shQuote(OSGeo4W_path)," gdal_translate ", "-of GPKG ","--config OGR_SQLITE_SYNCHRONOUS OFF ", "-co  APPEND_SUBDATASET=YES ", "-co TILE_FORMAT=PNG_JPEG ",shQuote(NomInput)," ",shQuote(NomGPKG))
  print(cmd);system(cmd)
  if (tuilage==1)
  {
    cat("#######################################################################\n")
    cmd = paste0(shQuote(OSGeo4W_path)," gdaladdo ","--config OGR_SQLITE_SYNCHRONOUS OFF ", "-r AVERAGE ",NomGPKG," 2 4 8 16 32 64 128 256")
    print(cmd);system(cmd)
  }
}

############################################################################################
Func_RepSurfCoursEau=function(Bbox_SurfEau,nomRepDalles,dsnlayer,NomDirSurfEAU,racilayerTA,raciSurfEau,nomSurfIdGlobal)
{
  # browser()
  Bbox_SurfEau[1]=1000*floor(Bbox_SurfEau$xmin/1000)
  Bbox_SurfEau[2]=1000*floor(Bbox_SurfEau$ymin/1000)
  Bbox_SurfEau[3]=1000*(floor(Bbox_SurfEau$xmax/1000-0.00000001)+1)
  Bbox_SurfEau[4]=1000*(floor(Bbox_SurfEau$ymax/1000-0.00000001)+1)
  
  dx=Bbox_SurfEau[3]-Bbox_SurfEau[1]
  dy=Bbox_SurfEau[4]-Bbox_SurfEau[2]
  if (dx==1000 & dy==1000)
  {
    # nomRepDalles=paste0("Dalles","_Xmin",Bbox_SurfEau[1],"_Ymax",Bbox_SurfEau[4])
    cat(nomRepDalles,"\n")
    nomRepDalles=strsplit(nomRepDalles,"\\.")[[1]][1]
    rep_SURFEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,nomRepDalles)#,paste0(raciSurfEau,imasq))
  }else{
    rep_SURFEAU=file.path(dsnlayer,NomDirSurfEAU,racilayerTA)#,paste0(raciSurfEau,imasq))
  }
  return(rep_SURFEAU)
}

############################################################################################
TApourFunc_RepSurfCoursEau=function(TA,Masque2)
{
  nb=st_intersects(TA,Masque2)
  n_int = which(sapply(nb, length)>0)
  TA_tmp=TA[n_int,]
  
  nb=st_intersects(st_buffer(TA_tmp,-0.05),Masque2)
  n_int = which(sapply(nb, length)>0)
  TA_tmp=TA_tmp[n_int,]
  return(TA_tmp)
}