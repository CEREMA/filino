FILINO1a_Pont_Grass = function(iLAZ,NomLaz,nom_RastPONT,SecteurGRASS,Nord,Sud,Est,Ouest) 
{
  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  
  nomMNTPONT=paste0("MNTPONT",iLAZ)
  
  nombat="myscriptgrass.bat"
  
  #################################################\n")
  if (file.exists(file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,nom_RastPONT))==T)
  {
    # Import du raster
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,nom_RastPONT)," output=",nomMNTPONT)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --quiet --overwrite raster=",nomMNTPONT," n=",Nord," s=",Sud," e=",Est," w=",Ouest," res=",as.character(reso))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
    NomUnivar=file.path(dsnlayer,paste0(raci,"_runivarP1.txt"))
    cmd=paste0("r.univar --quiet --overwrite map=",nomMNTPONT," output=",NomUnivar)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    #Lancement GRASS externe
    # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
    unlink(NomUnivar)
    
    if (nvaleur>0)
    {
      # Mise à la valeur 1
      nomMNTPONT1=paste0("nomMNTPONTVal1_",iLAZ)
      cmd=paste0("r.mapcalc --quiet --overwrite ",shQuote(paste0(nomMNTPONT1,"=if(",nomMNTPONT,">",-99,",1,null())")))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Conversion de masques et masque buffer en vecteur
      cmd=paste0("r.to.vect -s --quiet --overwrite input=",nomMNTPONT1," output=",nomMNTPONT1," type=area")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      nom_masque_gpkg=paste0(raci,"_Empr_PONT.gpkg")
      cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNTPONT1," output=",file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,nom_masque_gpkg)," format=GPKG")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("g.region --overwrite --quiet"," zoom=",nomMNTPONT)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      nomoutput=paste0(raci,"_PONT.gpkg")
      cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomMNTPONT," output=",file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles,nomoutput)," type=Float32 format=GPKG nodata=-9999")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
    }else{
      cat("##################################################################\n")
      cat("Pas de Ponts","\n")
      nom_masque_vide=paste0(raci,".pasdepont")
      write("VIDE",file.path(dsnlayer,NomDirMasquePONT,racilayerTA,NomDossDalles,nom_masque_vide))
    }
    if (Nettoyage==1)
    {
      unlink(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_RastPONT))
    }
  }
}

