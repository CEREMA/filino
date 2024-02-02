cat("\014")
cat("FILINO_17_12_Differences.R\n")

FILINO_Creat_Dir(NomDirDIFF)

# Lecture de la table d'assemblage
TA1=st_read(file.path(paramTARaster1$Doss,paramTARaster1$NomTA))
nb=st_intersects(TA1,ZONE)
n_int = which(sapply(nb, length)>0)
if (length(n_int)>0)
{
  TA1_=TA1[n_int,]
  
  TA2=st_read(file.path(paramTARaster2$Doss,paramTARaster2$NomTA))
  nb=st_intersects(TA2,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA2_=TA2[n_int,]
    

    raci=substr(TA1_$NOM_ASC,1,nchar(TA1_$NOM_ASC)-5)
    #Creation d'un monde GRASS
    SecteurGRASS=paste0(dirname(SecteurGRASS_),"_","DIFF","_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
    system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
    system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
    
    for (idalle in 1:dim(TA1_)[1])
    {
      
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
    }
    unlink(dirname(SecteurGRASS),recursive=TRUE)
  }
}