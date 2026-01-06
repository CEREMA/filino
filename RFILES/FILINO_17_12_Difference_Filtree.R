FILINO_17_12_Job=function(idalle,nomTA1,nomTA2,TA1,TA2,nCalcDiff)
{
  nfiltre=9
  
  # tampon pour la gestion des bords
  nbtampon=st_intersects(TA1,st_buffer(TA2,nfiltre))
  bboxTA1=round(st_bbox(st_buffer(TA2,nfiltre)))
  n_inttampon = which(sapply(nbtampon, length)>0)
  TA1=TA1[n_inttampon,]
  
  if (length(n_inttampon)>0)
  {
    
    TypeFiltreDiff=" -c"
    
    # travail sur le signe
    Signe=""
    if (nCalcDiff[2]==1 & nCalcDiff[3]==0){Signe=">"}
    if (nCalcDiff[2]==0 & nCalcDiff[3]==1){Signe="<"}
    if (nCalcDiff[2]==1 & nCalcDiff[3]==1){Signe=c(">","<")}
    if (nCalcDiff[1]==1){Signe="<"}

    nomMNTb   =file.path(dirname(nomTA2)[1],TA2$DOSSIERASC,TA2$NOM_ASC)
    listMNTa  =file.path(dirname(nomTA1),TA1$DOSSIERASC,TA1$NOM_ASC)
    nomMNTa=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(strsplit(basename(nomMNTb),"\\.")[[1]][1],"pourcompa.vrt"))
    nom_liste_pour_vrt=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(strsplit(basename(nomMNTb),"\\.")[[1]][1],"pourcompa.txt"))
    
    
    raci_diff=basename(nomMNTb)
    raci_diff=substr(raci_diff,1,nchar(raci_diff)-5)
    if (nCalcDiff[1]==0)
    {
      nomMasque =""
      nomPtsVirt_GrassCsv=""
      nomPtsVirtLaz=""
    }else{
      raci_diff=substr(raci_diff,1,as.numeric(gregexpr(raci_diff,pattern="copc")[1])+3)
      nomMasque=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci_diff,"_VegeTropDense.gpkg"))
      # file.exists(nom_masque_gpkg)
      nomPtsVirt_GrassCsv=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"_PtsVirt_Grass.csv"))
      nomPtsVirtLaz=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"_PtsVirt.copc.laz"))
    }
    
    
    # if (file.exists(nomMNTa)==T & file.exists(nomMNTb)==T & (file.exists(nomMasque)==T|nchar(nomMasque)==0) & (nchar(nomMasque) | file.exists(nomPtsVirtLaz)==F))
    if (file.exists(nomMNTb)==T & (file.exists(nomMasque)==T|nchar(nomMasque)==0) & (nchar(nomMasque) | file.exists(nomPtsVirtLaz)==F))
    {
      nomPtsVirt_VIDE=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"Vege_InfMNT_",nfiltre,"_PtsVirt.vide"))
      if (file.exists(nomPtsVirtLaz)==T | file.exists(nomPtsVirt_VIDE)==T)
      {
        cat(raci_diff,": Points virtuels déjà faits ou résultats VIDE!\n")
      }else{
        Creat_vrt(listMNTa,nom_liste_pour_vrt,nomMNTa)
        
        Diff_MNT_Filtree(nomMNTa,
                         nomMNTb,
                         nomMasque,
                         nomPtsVirt_GrassCsv,
                         bboxTA1,
                         nfiltre,
                         TypeFiltreDiff,
                         raci_diff,
                         Signe,
                         0.5)
        
        
        nomPtsVirt_csv=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"_PtsVirt.csv"))
        nomjson=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"_PtsVirt.json"))
        
        
        if (file.exists(nomPtsVirt_GrassCsv)==T & file.exists(nomPtsVirtLaz)==F)
        {
          PtsVirtuels=read.csv(nomPtsVirt_GrassCsv,header=F)
          PtsVirtuels=cbind(PtsVirtuels,Classification=89)
          colnames(PtsVirtuels)=cbind("X","Y","Z","Classification")
          
          write.csv(PtsVirtuels,file=nomPtsVirt_csv,quote=FALSE,row.names = FALSE)
          
          cat("###############################################################\n")
          write("[",nomjson)
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("readers.text"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(nomPtsVirt_csv),","),nomjson,append=T)
          write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG))),nomjson,append=T)
          write("    },",nomjson,append=T)
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(nomPtsVirtLaz),","),nomjson,append=T)
          write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
          write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
          write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
          write("    }",nomjson,append=T)
          write("]",nomjson,append=T)
          
          cmd=paste(pdal_exe,"pipeline",nomjson)
          system(cmd)
          
          if (Nettoyage==1)
          {
            unlink(nomPtsVirt_GrassCsv)
            unlink(nomjson)
          }
        }
      }
      unlink(nomMNTa)
    }else{
      
      cat(raci_diff,": Il manque des fichiers d'entrée, il n'y a pas de végétation dense ou c'est déjà fait, on ne sait pas trop!\n")
    }
  }
}

Diff_MNT_Filtree=function(nomMNTa,nomMNTb,nomMasque,nomcsv,bbox,nfiltre,TypeVoisinage,raci_diff,Signe,Reso) # " -c" ou ""
{
  SecteurGRASS=paste0(dirname(SecteurGRASS_),"_","DIFF","_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"_",idalle,"/",basename(SecteurGRASS_))
  system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
  system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))      
  
  # Importation du MNTa
  nom_gMNTa="MNTa"
  cmd=paste0("r.in.gdal -o --quiet --overwrite input=",nomMNTa," output=",nom_gMNTa)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Importation du MNTb
  nom_gMNTb="MNTb"
  cmd=paste0("r.in.gdal -o --quiet --overwrite input=",nomMNTb," output=",nom_gMNTb)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Gestion de la région
  # cmd=paste0("g.region --overwrite --quiet"," raster=",nom_gMNTa)
  cmd=paste0("g.region --quiet --overwrite"," n=",bbox$ymax," s=",bbox$ymin," e=",bbox$xmax," w=",bbox$xmin," res=",Reso)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Différence directe
  if (nCalcDiff[4]==1)
  { 
    # Différences
    nomDiffDirect="DiffDirect"
    exp=paste0(nomDiffDirect," = ",nom_gMNTb," - ",nom_gMNTa )
    cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    
    # Export
    NomExport=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"DiffDirecte",".gpkg"))
    cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiffDirect," output=",NomExport," type=Float32 format=GPKG nodata=-9999")
    print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  }
  
  #------------------------------------------------
  # Travail Voisinage nfiltre
  # Calcul des minimum et maximum au niveau d'un voisinage avec un carré de 5 pixels, soit 5m en résolution 1m, 2m mètres de chaque côté du pixels
  # On aurait pu faire un voisinage circulaire mais sur 2 pixels, pas top
  nomMin=paste0("MNT_Nei",nfiltre,"_Min")
  nomMax=paste0("MNT_Nei",nfiltre,"_Max")
  
  cmd=paste0("r.neighbors --quiet --overwrite",TypeVoisinage," input=",nom_gMNTa," output=",nomMin,",",nomMax," size=",nfiltre," method=minimum,maximum")
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Gestion de la région
  cmd=paste0("g.region --overwrite --quiet"," raster=",nom_gMNTb)
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # Différences
  nomDiff1="Diff_1"
  exp=paste0(nomDiff1," = if( ",nom_gMNTb," > ",nomMin," & ",nom_gMNTb," < ",nomMax,",null(),",nom_gMNTb," - ",nom_gMNTa,")" )
  cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
  print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
  
  # On ne garde que les valeurs positives ou négatives
  if (nchar(Signe)[1]>0)
  {
    if (nchar(nomMasque)>0)
    {
      nomgMask="Masque"
      cmd=paste0("v.in.ogr -o --quiet --overwrite input=",nomMasque," output=",nomgMask," min_area=0.000000001")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    }
    
    for (iSigne in Signe)
    {
      if (iSigne==">"){ajtext="Positif"}
      if (iSigne=="<"){ajtext="Negatif"}
      nomDiff1Signe=paste0("Diff_1Signe",ajtext)
      exp=paste0(nomDiff1Signe," = if( ",nomDiff1,iSigne,0,",",nomDiff1,",null())" )
      cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Export
      # cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff1," output=",NomExport1," type=Float32 format=GPKG nodata=-9999")
      # print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      if (nchar(nomMasque)>0)
      {
        cmd=paste0("r.mask --quiet --overwrite vector=",nomgMask)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      }
      
      # On récupère la zone de différences
      # Puis faire un buffer de 2
      DistBuf=ceiling(nfiltre/2)*Reso
      NomBuf=  paste0("Buffer_",ceiling(nfiltre/2),"m_",ajtext)
      cmd=paste0("r.buffer --quiet --overwrite input=",nomDiff1Signe," output=",NomBuf," distance=",DistBuf)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      NomBuf2=  paste0(NomBuf,"_Masque")
      cmd=paste0("r.resample --quiet --overwrite input=",NomBuf," output=",NomBuf2)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      cmd=paste0("r.mask --quiet --overwrite raster=",NomBuf2)
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Puis faire la différence
      nomDiff2=paste0("Diff_2",ajtext)
      exp=paste0(nomDiff2,"= if( ",nom_gMNTb,iSigne,nom_gMNTa,",",nom_gMNTb,"-",nom_gMNTa,",null())")
      cmd=paste0("r.mapcalc --overwrite ",shQuote(exp))
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
      
      # Test pour voir si tout s'est bien passé, certaines dalles rendent des NULL...
      cmd=paste0("r.univar --quiet --overwrite map=",nomDiff2)
      print(cmd);toto=system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd),intern=T)
      nlig=grep(toto,pattern="n: ")[1]
      nvaleur=as.numeric(strsplit(toto[nlig],":")[[1]][2])
      cat(toto[nlig],"\n")
      cat("Nombre de valeur: ",nvaleur, "\n")
      
      if (nvaleur>0)
      {
        # Export
        NomExport2=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"Diff_",nfiltre,"_",ajtext,".gpkg"))
        cmd=paste0("r.out.gdal --quiet --overwrite -c -f input=",nomDiff2," output=",NomExport2," type=Float32 format=GPKG nodata=-9999")
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        nomDiff2_Masq=  paste0(nomDiff2,"_Masque",ajtext)
        cmd=paste0("r.resample --quiet --overwrite input=",nomDiff2," output=",nomDiff2_Masq)
        print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        
        
        if (nchar(nomcsv)>0)
        {
          cmd=paste0("r.mask --quiet --overwrite raster=",nomDiff2_Masq)
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
          
          # nomPtsVirt_csv=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"Vege_InfMNT_",nfiltre,"_",ajtext,"_PtsVirt.csv"))
          # Export
          cmd=paste0("r.out.xyz --quiet --overwrite input=",nom_gMNTb," output=",nomcsv," separator=comma")
          print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
        }
      }else{
        nomPtsVirt_VIDE=file.path(dsnlayer,NomDIFF,NomDossDalles,paste0(raci_diff,"Vege_InfMNT_",nfiltre,"_PtsVirt.vide"))
        write("VIDE",nomPtsVirt_VIDE)
      }
      cmd=paste0("r.mask -r --quiet --overwrite")
      print(cmd);system(paste0(BatGRASS," ",SecteurGRASS," --exec ",cmd))
    }
  }
  unlink(dirname(SecteurGRASS),recursive=TRUE)
}

Creat_vrt=function(listeASC,nom_liste_pour_vrt,vrtfile)
{
  # Creation du fichier virtuel
  file.create(nom_liste_pour_vrt)
  write(listeASC, file = nom_liste_pour_vrt, append = T)
  cmd = paste(shQuote(OSGeo4W_path),"gdalbuildvrt",vrtfile,"-input_file_list",nom_liste_pour_vrt)
  print(cmd);system(cmd)
  unlink(nom_liste_pour_vrt)
}
