FILINO_7_CreationMNT_Grass_Mer = function(NomTIF,Val,reso,SecteurGRASS,nomMasques2T,racidalle_,nomType,BoiteBuf_tmp)
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
  DeltaZ=0.05
  
  # passage en 2 coups (plus et moins) en utilisant les commandes de grass de la sorte sinon ca ne marche pas!
  nomMoins="MoinsVal"
  # cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomMoins," =if(",nomMNT,"<",Val-DeltaZ,",",nomMNT,',null())')))
  cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomMoins," =if(",nomMNT,"<",Val-DeltaZ,",",1,',null())')))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  nomPlus="PlusVal"
  # cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomPlus," =if(",nomMNT,">",Val+DeltaZ,",",nomMNT,',null())')))
  cmd=paste0("r.mapcalc --overwrite ",shQuote(paste0(nomPlus," =if(",nomMNT,">",Val+DeltaZ,",",1,',null())')))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  #------------------------------------------------------------
  # Ajout 26/01/2024 pour ne pas avoir de vide en terre suite au nettoyage
  if (file.exists(nomMasques2T))
  {
    nomMasques2TG="MasquesTerre"
    cmd=paste0("v.in.ogr -o --quiet --overwrite input=",nomMasques2T," output=",nomMasques2TG," min_area=0.000000001")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    cmd=paste0("v.to.rast --quiet --overwrite input=",nomMasques2TG," output=",nomMasques2TG," use=cat value=1")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    listeRg=paste(nomMoins,nomPlus,nomMasques2TG,sep=",")
  }else{
    listeRg=paste(nomMoins,nomPlus,sep=",")
  }
  
  cmd=paste0("r.series --overwrite input=",listeRg," output=",nomTerre," method=maximum")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  
  # Création d'un masque inversé
  cmd=paste0("r.mask -i --quiet --overwrite raster=",nomTerre)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  newmerG="nvlleMer"
  cmd=paste0("r.to.vect --quiet --overwrite input=","MASK"," output=",newmerG," type=area")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  # r.to.vect input=MASK output=Invers type=area
  
  # Suppression du masque
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  # r.mask -r
  
  newmer1=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_nvlleMer1.gpkg"))
  cmd=paste0("v.out.ogr --quiet --overwrite input=",newmerG," output=",newmer1," format=GPKG")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  # v.out.ogr input=Invers@Temp output=D:\FILINO_Travail\06_MNTTIN_FILINO\TA_HD\Dalles\zut.gpkg format=GPKG
  
  meretcequonveutpas=st_read(newmer1)
  masque2=st_read(file.path(dirname(nomType),"Masque2.gpkg"))
  
  nb=st_intersects(meretcequonveutpas,masque2)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    if (dim(meretcequonveutpas)[1]==length(n_int))
    {
      cat("On a regardé les vides pour rien\n")
    }else{
      meretcequonveutpas=meretcequonveutpas[n_int,1]
      newmer2=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_nvlleMer2.gpkg"))
      st_write(meretcequonveutpas,newmer2, delete_layer=T, quiet=T)
      
      cmd=paste0("v.in.ogr -o --quiet --overwrite input=",newmer2," output=",newmerG," min_area=0.000000001")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("v.to.rast --quiet --overwrite input=",newmerG," output=",newmerG," use=cat value=1")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.mask -r")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.mask -i --quiet --overwrite vector=",newmerG)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomTerre)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    }
  }
  
  # Buffer sur le raster de 1 fois la résolution mise en paramètre 
  nomBuf="Buffer"
  cmd=paste0("r.buffer --quiet --overwrite input=",nomTerre," output=",nomBuf," distance=",reso)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # cmd=paste0("r.to.vect --quiet --overwrite input=",nomTerre," output=",nomTerre," type=area")
  # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # masque inversé
  cmd=paste0("r.mask --quiet --overwrite raster=",nomBuf)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("g.region --overwrite --quiet"," zoom=",nomMNT)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  nomMNT2="MNT2"
  cmd=paste0("r.resample --quiet --overwrite input=",nomMNT," output=",nomMNT2)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  nomMNT=nomMNT2
  
  bbox_wkt <- paste0("POLYGON((",BoiteBuf_tmp$xmin, " ",BoiteBuf_tmp$ymin, ",",BoiteBuf_tmp$xmax, " ",BoiteBuf_tmp$ymin, ",",BoiteBuf_tmp$xmax, " ",BoiteBuf_tmp$ymax, ",",BoiteBuf_tmp$xmin, " ",BoiteBuf_tmp$ymax, ",",BoiteBuf_tmp$xmin, " ",BoiteBuf_tmp$ymin, "))")
  
  M2_FILINO_Mer=st_read(
    file.path(dsnlayer, NomDirMasqueVIDE, racilayerTA, "Masques2_FILINO.gpkg"),
    layer = "Masques2_FILINO",
    wkt_filter = bbox_wkt, 
    query = paste0('SELECT * FROM ', shQuote("Masques2_FILINO"), ' WHERE ', shQuote("FILINO"), ' = \'Mer\'')
  )
  
  nomM2_FILINO_Mer=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_M2_FILINO_Mer.gpkg"))
  st_write(M2_FILINO_Mer,nomM2_FILINO_Mer,delete_layer = T, quiet = T)
  
  Masque2F="Masque2F"
  cmd=paste0("v.in.ogr  -o --quiet --overwrite input=",nomM2_FILINO_Mer," output=",Masque2F," -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  nomM1=file.path(dsnlayer, NomDirMasqueVIDE, racilayerTA, "Dalles",paste0(racidalle_,"_Masque1.gpkg"))
  Masque1P="Masque1Poly"
  cmd=paste0("v.in.ogr  -o --quiet --overwrite input=",nomM1," output=",Masque1P," -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.mask --quiet --overwrite vector=",Masque2F)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Conversion de masques et masque buffer en vecteur
  cmd=paste0("v.to.rast --quiet --overwrite input=",Masque1P," output=",Masque1P," use=cat value=0")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.mask -i --quiet --overwrite vector=",Masque1P)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  
  cmd=paste0("r.out.gdal --quiet --overwrite -c input=",nomMNT," output=",NomTIF," format=GTiff nodata=-9999")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Suppression du masque (s'il existe)
  cmd=paste0("r.mask -r")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
}

###################################################################################

FILINO_7_CreationMNT_Grass_Boite_et_Cuvettes = function(NomTIF,NomGPKG,NomMNTFill,NomMNTCuv,Boite,reso,SecteurGRASS)
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