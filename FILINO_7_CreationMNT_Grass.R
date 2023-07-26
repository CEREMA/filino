FILINO_7_CreationMNT_Grass =
  function(NomTIF,Val,reso) {
    nombat="myscriptgrass.bat"
    
    # Suppression du masque (s'il existe)
    exp=paste0("r.mask -r")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Import du raster
    # Récupération du raster
    nomMNT="MNT"
    exp=paste0("r.in.gdal -o --overwrite input=",NomTIF," output=",nomMNT)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    exp=paste0("g.region --overwrite raster=",nomMNT)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    # ne marche pas avec un croisement purement géographique, si on a des trous en mer...
    
    # Mise à la valeur 1
    nomTerre="Terre"
    DeltaZ=0.01
    exp=paste0(nomTerre,"=if(",nomMNT,">",Val-DeltaZ,",if(",nomMNT,"<",Val+DeltaZ,",null(),",nomMNT,"),",nomMNT,")")
    exp=paste0("r.mapcalc --overwrite ",shQuote(exp))
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Buffer sur le raster de 1 fois la résolution mise en paramètre 
    nomBuf="Buffer"
    exp=paste0("r.buffer --overwrite input=",nomTerre," output=",nomBuf," distance=",reso)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # masque inversé
    exp=paste0("r.mask -i --overwrite raster=",nomBuf)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # export du résultat, on écarse le fichier pdal avec le même nom
    exp=paste0("r.out.gdal --overwrite -c input=",nomMNT," output=",NomTIF," format=GTiff")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Suppression du masque (s'il existe)
    exp=paste0("r.mask -r")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  }