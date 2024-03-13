FILINO1a_Vege_Grass=function(iLAZ,NomLaz,nom_RastTSF,nom_Rast_VEGE,SecteurGRASS,Nord,Sud,Est,Ouest)
{

  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  # Récupération du raster, création d'un masque inversé et export en adoicissant les bords.
  nomMNT_Reste=paste0("MNT_ToutSaufVege",iLAZ)
  nomMNT_Vege=paste0("MNT_Vege",iLAZ)
  if (file.exists(file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_Rast_VEGE))==T)
  {
    # Import du raster
    cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_Rast_VEGE)," output=",nomMNT_Vege)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Limitation de la région de travail et gestion de la résolution
    cmd=paste0("g.region --quiet --overwrite raster=",nomMNT_Vege," n=",Nord," s=",Sud," e=",Est," w=",Ouest," res=",as.character(reso))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
    NomUnivar=file.path(dsnlayer,paste0(raci,"_runivarv1.txt"))
    cmd=paste0("r.univar --quiet --overwrite map=",nomMNT_Vege," output=",NomUnivar)
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
    unlink(NomUnivar)
    # S'il y a plus d'une valeur non nulle...
    if (nvaleur>0)
    {
      cmd=paste0("g.region --overwrite --quiet"," zoom=",nomMNT_Vege)
      nomoutput=file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,NomDossDalles, paste0(raci,"_VEGE_min",".gpkg"))
      cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomMNT_Vege," output=",nomoutput," type=Float32 format=GPKG nodata=-9999")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Suppression du masque (s'il existe)
      cmd=paste0("r.mask -r")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Création d'un masque
      cmd=paste0("r.mask --quiet --overwrite raster=",nomMNT_Vege)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Creation d'un raster remplissant le masque inversé
      nomMNT_VegeMasque=paste0("MNT_VegeDense_",iLAZ)
      cmd=paste0("r.resample --quiet --overwrite input=MASK output=",nomMNT_VegeMasque)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Suppression du masque (s'il existe)
      cmd=paste0("r.mask -r")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Import du raster
      cmd=paste0("r.in.gdal -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_RastTSF)," output=",nomMNT_Reste)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Création d'un masque inversé
      cmd=paste0("r.mask -i --quiet --overwrite raster=",nomMNT_Reste)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Creation d'un raster remplissant le masque inversé
      nomMNT_Sol=paste0("MNT_VegeDense_",iLAZ)
      cmd=paste0("r.resample --quiet --overwrite input=",nomMNT_VegeMasque," output=",nomMNT_VegeMasque)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Import du masque eau pour ne pas prendre de point sol dans cette zone particulière
      nom_masque_eau=paste0(raci,"_Masque2.gpkg")
      nomEAU=gsub(".copc","_copc",paste0(raci,"_Eau"))
      cmd=paste0("v.in.ogr -o --quiet --overwrite input=",file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,NomDossDalles,nom_masque_eau)," output=",nomEAU," min_area=0.000000001")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.mask -i --quiet --overwrite vector=",nomEAU)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      
      nom_masque_gpkg=paste0(raci,"_VegeTropDense.gpkg")
      dir_tmp_=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA)
      FILINO_Creat_Dir(dir_tmp_)
      
      # Test pour voir s'il y a des zones sinon on crée un fichier vide
      NomUnivar=file.path(dsnlayer,paste0(raci,"_runivarv2.txt"))
      cmd=paste0("r.univar --quiet --overwrite map=",nomMNT_VegeMasque," output=",NomUnivar)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      nvaleur=as.numeric(scan(file=NomUnivar,NomUnivar,sep=":",skip=5,nlines=1,dec=".")[2])
      unlink(NomUnivar)
      
      nommasqueveget=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_masque_gpkg)
      if (nvaleur>0)
      {
        cmd=paste0("r.to.vect --quiet --overwrite input=",nomMNT_VegeMasque," output=",nomMNT_VegeMasque," type=area")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        cmd=paste0("v.out.ogr --quiet --overwrite input=",nomMNT_VegeMasque," output=",nommasqueveget," format=GPKG")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      }else{
        write("VIDE",file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"_VegeTropDense.vide")))
      }
      
      # Suppression du masque
      cmd=paste0("r.mask -r")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      return(nommasqueveget)
      
    }else{
      write("VIDE",file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"_VegeTropDense.vide")))
    }
  }
}