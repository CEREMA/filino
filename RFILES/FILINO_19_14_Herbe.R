FILINO_19_14_Herbe_Job=function(iZone,ZONE)
{
  
  Zone_tmp=ZONE$ZONE[iZone]
  
  NomMax=file.path(dsnlayer,NomDirMNTGDAL,paste0(Zone_tmp,"_SOLetEAU_max.gpkg"))
  NomMin=file.path(dsnlayer,NomDirMNTGDAL,paste0(Zone_tmp,"_SOLetEAU_min.gpkg"))
  if (file.exists(NomMax)==T & file.exists(NomMin)==T)
  { 
    SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",Zone_tmp,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
    system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
    system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
    NomMaxg="NomMaxg"
    NomMing="NomMing"
    
    # Import du raster Min
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",NomMin," output=",NomMing)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Import du raster Max
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",NomMax," output=",NomMaxg)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --quiet --overwrite raster=",NomMing,",",NomMaxg)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    #---- Filtre
    nfiltreChamps=c(5,7,9)
    for (ifiltre in nfiltreChamps)
    {
      nomMinMaxg=paste0("nomMinMaxg",ifiltre)
      cmd=paste0("r.neighbors --quiet --overwrite input=",NomMaxg," output=",nomMinMaxg," size=",ifiltre," method=minimum")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      nomDiff="DiffMin_moins_MindesMax"
      exp=paste0(nomDiff,"=if( ",nomMinMaxg," - ",NomMing,">0 , 0.01*round(100*(",nomMinMaxg," - ",NomMing,")),null())")
      cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      nomsortie=file.path(dsnlayer,NomDirMNTGDAL,paste0(Zone_tmp,"_Champs_Filtre",ifiltre,".gpkg"))
      cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff," output=",nomsortie," type=Float32 format=GPKG nodata=-9999")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd = paste0(shQuote(OSGeo4W_path)," gdaladdo ","--config OGR_SQLITE_SYNCHRONOUS OFF ", "-r AVERAGE ",nomsortie," 2 4 8 16 32 64 128 256")
      print(cmd);system(cmd)
      
      file.copy(file.path(dsnlayer,NomDirSIGBase,"Champs.qml"),
                paste0(substr(nomsortie,1,nchar(nomsortie)-5),".qml"),
                overwrite = T)
    }
    
    unlink(SecteurGRASS)
  }
}