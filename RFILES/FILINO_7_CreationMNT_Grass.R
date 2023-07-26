FILINO_7_CreationMNT_Grass =
  function(NomTIF,Val,reso) {
    # Suppression du masque (s'il existe)
    
    cmd=paste0("r.mask -r")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Import du raster
    # Récupération du raster
    nomMNT="MNT"
    cmd=paste0("r.in.gdal -o --overwrite input=",NomTIF," output=",nomMNT)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --overwrite raster=",nomMNT)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    # ne marche pas avec un croisement purement géographique, si on a des trous en mer...
    # browser()
    # Mise à la valeur 1
    nomTerre="Terre"
    DeltaZ=0.01
    # exp=paste0(nomTerre,"=if(",nomMNT,">",Val+DeltaZ,",",nomMNT,",if(",nomMNT,"<",Val-DeltaZ,",",nomMNT,",null()))")
    # exp=paste0(nomTerre,"=if(",nomMNT,"<",Val+DeltaZ,",",nomMNT,",if(",nomMNT,">",Val-DeltaZ,",",nomMNT,"),null())")
    #     # exp=paste0(nomTerre,"=if(",nomMNT,">",Val-DeltaZ,",if(",nomMNT,"<",Val+DeltaZ,",null(),",nomMNT,"),",nomMNT,")")
    #     # exp=paste0(nomTerre,"=if(",nomMNT,">",Val-DeltaZ,",if(",nomMNT,"<",Val+DeltaZ,",null(),",nomMNT,"),",nomMNT,")")
    #     # exp=paste0(nomTerre,"=if(",nomMNT,"-(Val-DeltaZ)<0",",nomMNT,","if(",nomMNT,"-(",Val+DeltaZ,")>0,",nomMNT,",null()))")
    #     # nomTerre="Jupiter"
    # exp=paste0(nomTerre," =if(",nomMNT,"@Temp<",Val-DeltaZ,",",nomMNT,"@Temp,if(",nomMNT,"@Temp>",Val+DeltaZ,",",nomMNT,"@Temp,null()))")
    # # if( MNT@Temp<-0.27, MNT@Temp,if( MNT@Temp>-0.25, MNT@Temp,null() ) )
    # cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
    # system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    
    # passage en 2 coups (plus et moins) en utilisant les commandes de grass de la sorte sinon ca ne marche pas!
    nomMoins="MoinsVal"
    cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomMoins," =if(",nomMNT,"<",Val-DeltaZ,",",nomMNT,',null())')))
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    nomPlus="PlusVal"
    cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomPlus," =if(",nomMNT,">",Val+DeltaZ,",",nomMNT,',null())')))
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    cmd=paste0("r.series --overwrite input=",paste(nomMoins,nomPlus,sep=",")," output=",nomTerre," method=maximum")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Buffer sur le raster de 1 fois la résolution mise en paramètre 
    nomBuf="Buffer"
    cmd=paste0("r.buffer --quiet --overwrite input=",nomTerre," output=",nomBuf," distance=",reso)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # masque inversé
    cmd=paste0("r.mask --quiet --overwrite raster=",nomBuf)
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # export du résultat, on écarse le fichier pdal avec le même nom
    cmd=paste0("r.out.gdal --quiet --overwrite -c input=",nomMNT," output=",NomTIF," format=GTiff")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Suppression du masque (s'il existe)
    cmd=paste0("r.mask -r")
    system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  }