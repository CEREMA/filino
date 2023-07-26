FILINO5a_Grass =
  function(iLAZ) {
    browser()
    # Récupération du raster, création d'un masque inversé et export en adoicissant les bords.
    nomMNT_Reste=paste0("MNT_ToutSaufVege",iLAZ)
    nomMNT_Vege=paste0("MNT_Vege",iLAZ)
    # Import du raster
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(ChemLaz,nom_Rast2)," output=",nomMNT_Vege)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --quiet --overwrite raster=",nomMNT_Vege," n=",Nord," s=",Sud," e=",Est," w=",Ouest," res=",as.character(reso))
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
    NomUnivar=file.path(dsnlayer,"runivar.txt")
    cmd=paste0("r.univar --quiet --overwrite map=",nomMNT_Vege," output=",NomUnivar)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
    unlink(NomUnivar)
    # S'il y a plus d'une valeur non nulle...
    if (nvaleur>0)
    {
      # Suppression du masque (s'il existe)
      cmd=paste0("r.mask -r")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Création d'un masque
      cmd=paste0("r.mask --quiet --overwrite raster=",nomMNT_Vege)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Creation d'un raster remplissant le masque inversé
      nomMNT_VegeMasque=paste0("MNT_VegeDense_",iLAZ)
      cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNT_VegeMasque)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Suppression du masque (s'il existe)
      cmd=paste0("r.mask -r")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Import du raster
      cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(ChemLaz,nom_Rast1)," output=",nomMNT_Reste)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Création d'un masque inversé
      cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNT_Reste)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Creation d'un raster remplissant le masque inversé
      nomMNT_Sol=paste0("MNT_VegeDense_",iLAZ)
      cmd=paste0("r.resample --quiet --overwrite input=",nomMNT_VegeMasque," output=",nomMNT_VegeMasque)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Import du masque eau pour ne pas prendre de point sol dans cette zone particulière
      nom_masque_eau=paste0(raci,"_Masque2.gpkg")
      nomEAU=paste0(raci,"_Eau")
      cmd=paste0("v.in.ogr -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasque,raciTALidarHDCla,nom_masque_eau)," output=",nomEAU," min_area=0.000000001")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.mask -i --quiet --overwrite vector=",nomEAU)
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNT_VegeMasque," output=",nomMNT_VegeMasque," type=area")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      raci=substr(NomLaz_tmp,1,nchar(NomLaz_tmp)-4)
      nom_masque_gpkg=paste0(raci,"_VegeTropDense.gpkg")
      dir.create(file.path(dsnlayer,NomDirForet,raciTALidarHDCla))
      nommasqueveget=file.path(dsnlayer,NomDirForet,raciTALidarHDCla,nom_masque_gpkg)
      cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNT_VegeMasque," output=",nommasqueveget," format=GPKG")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Suppression du masque
      cmd=paste0("r.mask -r")
      system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      return(nommasqueveget)
    }
  }