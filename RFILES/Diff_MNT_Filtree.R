Diff_MNT_Filtree=function(nomMNTa,nomMNTb,nomMasque,nfiltre,TypeVoisinage,NomExport1,NomExport2,nomcsv,Signe,Reso) # " -c" ou ""
{
  
  # Importation du MNTa
  nom_gMNTa="MNTa"
  cmd=paste0("r.in.gdal -o --quiet --overwrite input=",nomMNTa," output=",nom_gMNTa)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Importation du MNTb
  nom_gMNTb="MNTb"
  cmd=paste0("r.in.gdal -o --quiet --overwrite input=",nomMNTb," output=",nom_gMNTb)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Gestion de la région
  cmd=paste0("g.region --overwrite --quiet"," raster=",nom_gMNTa,",",nom_gMNTb)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  #------------------------------------------------
  # Travail Voisinage nfiltre
  # Calcul des minimum et maximum au niveau d'un voisinage avec un carré de 5 pixels, soit 5m en résolution 1m, 2m mètres de chaque côté du pixels
  # On aurait pu faire un voisinage circulaire mais sur 2 pixels, pas top
  nomMin=paste0("MNT_Nei",nfiltre,"_Min")
  nomMax=paste0("MNT_Nei",nfiltre,"_Max")
  
  cmd=paste0("r.neighbors --quiet --overwrite",TypeVoisinage," input=",nom_gMNTa," output=",nomMin,",",nomMax," size=",nfiltre," method=minimum,maximum")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Différences
  nomDiff1="Diff_1"
  exp=paste0(nomDiff1," = if( ",nom_gMNTb," > ",nomMin," & ",nom_gMNTb," < ",nomMax,",null(),",nom_gMNTb," - ",nom_gMNTa,")" )
  cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # On ne garde que les valeurs positives ou négatives
  if (nchar(Signe)>0)
  {
    nomDiff1Signe="Diff_1Signe"
    exp=paste0(nomDiff1Signe," = if( ",nomDiff1,Signe,0,",",nomDiff1,",null())" )
    cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    nomDiff1=nomDiff1Signe
  }
  
  # Export
  cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff1," output=",NomExport1," type=Float32 format=GPKG nodata=-9999")
  # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  if (nchar(nomMasque)>0)
  {
    nomgMask="Masque"
    cmd=paste0("v.in.ogr -o --quiet --overwrite input=",nomMasque," output=",nomgMask," min_area=0.000000001")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))  
    
    cmd=paste0("r.mask --quiet --overwrite vector=",nomgMask)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  }
  
  # On récupère la zone de différences
  # Puis faire un buffer de 2
  DistBuf=ceiling(nfiltre/2)*Reso
  NomBuf=  paste0("Buffer_",ceiling(nfiltre/2),"m")
  cmd=paste0("r.buffer --quiet --overwrite input=",nomDiff1," output=",NomBuf," distance=",DistBuf)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  NomBuf2=  paste0(NomBuf,"_Masque")
  cmd=paste0("r.resample --quiet --overwrite input=",NomBuf," output=",NomBuf2)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  cmd=paste0("r.mask --quiet --overwrite raster=",NomBuf2)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Puis faire la différence
  nomDiff2="Diff_2"
  exp=paste0(nomDiff2,"= if( ",nom_gMNTb,Signe,nom_gMNTa,",",nom_gMNTb,"-",nom_gMNTa,",null())")
  cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
  cmd=paste0("r.univar --quiet --overwrite map=",nomDiff2)
  # print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
  print(cmd);toto = system2(command = BatGRASS,args = c(SecteurGRASS, "--exec", cmd),stdout = TRUE,stderr = TRUE)
  nlig=grep(toto,pattern="n: ")[1]
  nvaleur=as.numeric(strsplit(toto[nlig],":")[[1]][2])
  cat(toto[nlig])
  cat("Nombre de valeur: ",nvaleur, "\n")
  if (nvaleur>0)
  {
    # Export
    cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff2," output=",NomExport2," type=Float32 format=GPKG nodata=-9999")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    nomDiff2_Masq=  paste0(nomDiff2,"_Masque")
    cmd=paste0("r.resample --quiet --overwrite input=",nomDiff2," output=",nomDiff2_Masq)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    if (nchar(nomcsv)>0)
    {
      cmd=paste0("r.mask --quiet --overwrite raster=",nomDiff2_Masq)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Export
      cmd=paste0("r.out.xyz --quiet --overwrite input=",nom_gMNTb," output=",nomcsv," separator=comma")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    }
  }
}