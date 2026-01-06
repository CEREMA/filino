FILINO_17_12_Job=function(idalle)
{
  SecteurGRASS=paste0(dirname(SecteurGRASS_),"_","DIFF","_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"_",idalle,"/",basename(SecteurGRASS_))
  system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
  system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))      
  Tampon=st_buffer(TA1_[idalle,1],-10)
  
  nbtampon=st_intersects(TA2_,Tampon)
  n_inttampon = which(sapply(nbtampon, length)>0)
  if (length(n_inttampon)>0)
  {
    
    # Import du raster
    nomRast1="Rast1"
    cmd=paste0("r.in.gdal -o --overwrite input=",file.path(TA1_$CHEMIN,TA1_$NOM_ASC)[idalle]," output=",nomRast1)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --overwrite raster=",nomRast1)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    nomRast2="Rast2"
    cmd=paste0("r.in.gdal -o --overwrite input=",file.path(TA2_$CHEMIN,TA2_$NOM_ASC)[n_inttampon[1]]," output=",nomRast2)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Mise à la valeur 1
    nomDiff="DIFF" 
    nomoutput=file.path(dsnlayer,NomDirDIFF,
                        paste0(raci,
                               # "_",substr(paramTARaster1$extension,1,nchar(paramTARaster1$extension)-6),
                               "_moins_",
                               substr(paramTARaster2$extension,1,nchar(paramTARaster2$extension)-6),
                               "_.gpkg"))[idalle]
    if (nCalcDiffPlus==1)
    {
      cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomDiff,"=",nomRast1,"-",nomRast2)))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      file.copy(file.path(dsnlayer,NomDirSIGBase,"DIFF.qml"),
                file.path(paste0(substr(nomoutput,1,nchar(nomoutput)-5),".qml")),
                overwrite = T)
    }else{
      cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomDiff,"=if(",nomRast1,"-",nomRast2,">0,",nomRast1,"-",nomRast2,",null())")))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      file.copy(file.path(dsnlayer,NomDirSIGBase,"H_cuvettes.qml"),
                file.path(paste0(substr(nomoutput,1,nchar(nomoutput)-5),".qml")),
                overwrite = T)
      
    }
    cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff," output=",nomoutput," type=Float32 format=GPKG nodata=-9999")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  }
  unlink(dirname(SecteurGRASS),recursive=TRUE)
}
