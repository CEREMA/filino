FILINO_7_CreationMNT_Grass_Mer = function(NomTIF,Val,reso)
{
  # Suppression du masque (s'il existe)
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Import du raster
  # Récupération du raster
  nomMNT="MNT"
  cmd=paste0("r.in.gdal -o --overwrite input=",NomTIF," output=",nomMNT)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Limitation de la région de travail et gestion de la résolution
  cmd=paste0("g.region --overwrite raster=",nomMNT)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  nomTerre="Terre"
  DeltaZ=0.01
  
  # passage en 2 coups (plus et moins) en utilisant les commandes de grass de la sorte sinon ca ne marche pas!
  nomMoins="MoinsVal"
  cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomMoins," =if(",nomMNT,"<",Val-DeltaZ,",",nomMNT,',null())')))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  nomPlus="PlusVal"
  cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomPlus," =if(",nomMNT,">",Val+DeltaZ,",",nomMNT,',null())')))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.series --overwrite input=",paste(nomMoins,nomPlus,sep=",")," output=",nomTerre," method=maximum")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Buffer sur le raster de 1 fois la résolution mise en paramètre 
  nomBuf="Buffer"
  cmd=paste0("r.buffer --quiet --overwrite input=",nomTerre," output=",nomBuf," distance=",reso)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # masque inversé
  cmd=paste0("r.mask --quiet --overwrite raster=",nomBuf)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("g.region --overwrite --quiet"," zoom=",nomMNT)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))

    cmd=paste0("r.out.gdal --quiet --overwrite -c input=",nomMNT," output=",NomTIF," format=GTiff nodata=-9999")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Suppression du masque (s'il existe)
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
}

###################################################################################

FILINO_7_CreationMNT_Grass_Boite_et_Cuvettes = function(NomTIF,NomGPKG,NomMNTFill,NomMNTCuv,Boite,reso)
{
  # Suppression du masque (s'il existe)
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Import du raster
  # Récupération du raster
  nomMNT="MNT"
  cmd=paste0("r.in.gdal -o --overwrite input=",NomTIF," output=",nomMNT)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Limitation de la région de travail et gestion de la résolution
  cmd=paste0("g.region --quiet --overwrite raster=",nomMNT," n=",Boite$ymax," s=",Boite$ymin," e=",Boite$xmax," w=",Boite$xmin," res=",as.character(reso))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomMNT," output=",NomGPKG," type=Float32 format=GPKG nodata=-9999")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))

  if (file.exists(NomMNTFill))
  {
    # Import du raster
    # Récupération du raster
    nomFill="MNTFill"
    cmd=paste0("r.in.gdal -o --overwrite input=",NomMNTFill," output=",nomFill)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd)) 

    nomCuv="Cuv"
    cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomCuv," =",nomFill,"-",nomMNT)))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomCuv," output=",NomMNTCuv," type=Float32 format=GPKG nodata=-9999")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    file.copy(file.path(dsnlayer,NomDirSIGBase,"H_cuvettes.qml"),
              paste0(substr(NomMNTCuv,1,nchar(NomMNTCuv)-5),".qml"),
              overwrite = T)

        #### Peut-être rajouter conversion en vecteur si sup à 0.15 cm... et travail sur thalwegs
  }
}