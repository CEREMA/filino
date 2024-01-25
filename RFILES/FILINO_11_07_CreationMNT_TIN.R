cat("\014")
cat("FILINO_11_07_CreationMNT_TIN.R\n")

TA=st_read(file.path(dsnlayerTA,nomlayerTA))

for (iTypeTIN in nTypeTIN)
{
  
  type=TypeTIN[iTypeTIN]
  
  if (iTypeTIN==1) NomDirMNTTIN=NomDirMNTTIN_F else NomDirMNTTIN=NomDirMNTTIN_D 
  FILINO_Creat_Dir(file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles))
  
  nomPtsVirt=file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp"))
  if (file.exists(nomPtsVirt)==T & iTypeTIN==1)
  {
    TAPtsVirtu=st_read(file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")))
    # TAPtsVirtu=st_read(file.path(dsnlayer,paste0(racilayerTA,"_PtsVirt.shp")))
  }else{
    # on crée une fausse table vide
    TAPtsVirtu=TA
    inc=1:dim(TAPtsVirtu)[1]
    TAPtsVirtu=TAPtsVirtu[-inc,]
  }
  
  listeMasq2=list.files(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA),pattern=paste0("Masques2_FILINO",".gpkg"))
  cat(format(Sys.time(),format="%Y%m%d_%H%M%S")," Lecture Masques 2\n")
  if (length(listeMasq2)>0)
  {
    Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,listeMasq2[1]))
    # On ne garde que les masques 2 en bord de mer! pour un nettoyage
    Masques2=Masques2[which(substr(Masques2$FILINO,1,3)=="Mer"),]
  }
  nb=st_intersects(TA,ZONE)
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    TA_Zone=TA[n_int,]
    
    for (idalle in 1:dim(TA_Zone)[1])
    {
      # print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
      racidalle=TA_Zone[idalle,]$NOM
      racidalle=substr(racidalle,1,nchar(racidalle)-4)  
      racidalle_=gsub(".copc","_copc",racidalle)
      cat(round(100*idalle/dim(TA_Zone)[1]), "% " ,racidalle)
      NomTIF    =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_",type,".tif"))
      nomBADPDAL=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_",type,".BADALLOCPDAL"))
      NomMNTFill=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_",type,"_fill.tif"))
      NomMNTCuv =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_",type,"_cuvettes.gpkg"))
      NomGPKG   =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_",type,".gpkg"))
      NomTXT    =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_Cerema.txt"))
      NomTXT_old=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle_,"_Cerema_old.txt"))
      Alancer=0
      # if (file.exists(NomTIF)==F)
      #   {
      #   Alancer=1
      #   }else{
      #     cat(" TIF déjà présent - test de fichiers Laz utilisé","\n")
      
      if (file.exists(NomTXT)==T & file.exists(NomGPKG)==T){file.copy(NomTXT,NomTXT_old)}
      
      # else{}
      
      
      
      # cat("\014")
      cat(round(100*idalle/dim(TA_Zone)[1]), "% " ,racidalle)
      cat("Procédure PDAL","\n")
      
      Tampon=st_buffer(TA_Zone[idalle,1],Buf_TIN)
      
      
      # Il faut tester s'il y a qqch pour augmenter la zone de calcul du TIn dans le fichier TravailMANUEL_Filino.gpkg'
      Manuel=st_read(nom_Manuel)
      ici=which(Manuel$FILINO=="TIN")
      if (length(ici)>0)
      {
        nbmanuel=st_intersects(Manuel[ici,],Tampon)
        n_intmanuel = which(sapply(nbmanuel, length)>0)
        if (length(n_intmanuel)>0)
        {
          Manuel=Manuel[n_intmanuel,]
          Tampon=st_union(Tampon,Manuel)
        }
      }
      
      # Création du polygone injecté dans PDAL pour limiter les calcul (CROP)
      Polygon_Contour_CE=st_as_text(st_geometry(Tampon))
      
      # Intersection entre cette dalle et la table initiale
      # Selection des sections dans le Lidar
      nb=st_intersects(TA,Tampon)
      n_intHD = which(sapply(nb, length)>0)
      cat("Dalles Lidar de base\n")
      print(TA[n_intHD,]$NOM)
      write(TA[n_intHD,]$NOM,NomTXT)
      
      # Intersection entre cette dalle et la table initiale
      # Selection des sections dans le Lidar
      nb=st_intersects(TAPtsVirtu,Tampon)
      n_intVirt = which(sapply(nb, length)>0)
      cat("Points Virtuels de FILINO\n")
      print(file.path(TAPtsVirtu[n_intVirt,]$DOSSIER,TAPtsVirtu[n_intVirt,]$NOM))
      write(file.path(basename(TAPtsVirtu[n_intVirt,]$DOSSIER),TAPtsVirtu[n_intVirt,]$NOM),NomTXT,append=T)
      
      if (file.exists(NomTXT_old)==T)
      {
        
        # Charger le contenu des deux fichiers texte
        fichier1 <- readLines(NomTXT)
        fichier2 <- readLines(NomTXT_old)
        
        # Comparer les fichiers
        differences <- setdiff(fichier1, fichier2)
        
        # Vérifier s'il y a des différences
        if (length(differences) == 0) {
          cat("Les fichiers Laz sont équivalents.\n")
          Alancer=0
        } else {
          cat("Les fichiers Laz sont différents:\n")
          Alancer=1
        }
        unlink(NomTXT_old)
      }else{
        cat("Pas de fichier de comparaison ou de fichier MNT:\n")
        Alancer=1
      }
      if (Alancer==1 & file.exists(nomBADPDAL)==F)
      {
        #Regroupement des fichiers de points virtuels s'il y en a trop pour éviter l'erreur
        
        NbreFichierVirt=length(file.path(dsnlayer,TAPtsVirtu[n_intVirt,]$DOSSIER,TAPtsVirtu[n_intVirt,]$NOM))
        NomFichierVirt=file.path(dsnlayer,TAPtsVirtu[n_intVirt,]$DOSSIER,TAPtsVirtu[n_intVirt,]$NOM)
        if (NbreFichierVirt>nLimit)
        {
          for (iRegroup in seq(1,NbreFichierVirt,nLimit))
          {
            nomjson          =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle,"_PtsVirts_Regroup", formatC(iRegroup ,width=4, flag="0"),"_Cerema.json"))
            NomLazRegroup_tmp=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle,"_PtsVirts_Regroup", formatC(iRegroup ,width=4, flag="0"),"_Cerema.copc.laz"))
            write("[",nomjson)
            for (NOMLAZ in NomFichierVirt[iRegroup:(min(iRegroup+nLimit,NbreFichierVirt))])
            {
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
              write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
              write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
              write("    },",nomjson,append=T)
            } 
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
            write("    },",nomjson,append=T)
            write("    {",nomjson,append=T)
            write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
            write(paste0("       ",shQuote("filename"),":",shQuote(NomLazRegroup_tmp)),nomjson,append=T)
            write("    }",nomjson,append=T)
            write("]",nomjson,append=T)
            cmd=paste(pdal_exe,"pipeline",nomjson)
            print(cmd);system(cmd)
            if (iRegroup==1){NomBouclePtsVirtuels=NomLazRegroup_tmp}else{NomBouclePtsVirtuels=c(NomBouclePtsVirtuels,NomLazRegroup_tmp)}
          }
          print(NomBouclePtsVirtuels)
        }else{
          NomBouclePtsVirtuels=file.path(dsnlayer,TAPtsVirtu[n_intVirt,]$DOSSIER,TAPtsVirtu[n_intVirt,]$NOM)
        }
        
        # Creation d'un pipeline pdal
        
        nomjson   =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle,"_Cerema.json"))
        NomLaz_tmp=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle,"_Cerema.laz"))
        
        write("[",nomjson)
        
        ############### Import des fichiers Laz IGN
        
        # for (NOMLAZ in file.path(TA[n_intHD,]$CHEMIN,TA[n_intHD,]$NOM))
        for (NOMLAZ in file.path(dsnlayerTA,TA[n_intHD,]$DOSSIER,TA[n_intHD,]$NOM))
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
          write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
          write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
          write("    },",nomjson,append=T)
        } 
        
        ################ Import des fichiers Laz virtuels Cerema
        # for (NOMLAZ in file.path(TAPtsVirtu[n_intVirt,]$CHEMIN,TAPtsVirtu[n_intVirt,]$NOM))
        for (NOMLAZ in NomBouclePtsVirtuels)
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
          write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
          write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
          write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
          write("    },",nomjson,append=T)
        } 
        
        ############## On ne garde que les classification sol, les 60 et + de 'IGN et 80 et plus du Cerema
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote("Classification[2:2],Classification[66:66],Classification[81:90]")),nomjson,append=T)
        write("    },",nomjson,append=T)
        
        ############# Fusion des fichiers
        if ((length(n_intHD)+length(n_intVirt))>1)
        {
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
          write("    },",nomjson,append=T)
        }
        
        if (nCalcTaudem==0)
        {
          ############# Découpage à 100m autour
          write("    {",nomjson,append=T)
          write(paste0("       ",shQuote("type"),":",shQuote("filters.crop"),","),nomjson,append=T)
          write(paste0("       ",shQuote("polygon"),":",shQuote(Polygon_Contour_CE)),nomjson,append=T)
          write("    },",nomjson,append=T)
        }
        
        ############### Filtre delaunay
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.delaunay")),nomjson,append=T)
        write("    },",nomjson,append=T)
        
        ############## Interpolation
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.faceraster"),","),nomjson,append=T)
        write(paste0("       ",shQuote("resolution"),":",reso,","),nomjson,append=T) 
        # if (iTypeTIN==1)
        # {
        # On interpole un peu plus large pour le calcul de cuvettes
        BoiteBuf=st_bbox(st_buffer(TA_Zone[idalle,1],Buf_TIN/2))  
        # }else{
        #   BoiteBuf=st_bbox(TA_Zone[idalle,])
        # }    
        write(paste0("       ",shQuote("width") ,":",(BoiteBuf$xmax-BoiteBuf$xmin)/reso,","),nomjson,append=T) 
        write(paste0("       ",shQuote("height"),":",(BoiteBuf$ymax-BoiteBuf$ymin)/reso,","),nomjson,append=T) 
        write(paste0("       ",shQuote("origin_x"),":",BoiteBuf[1],","),nomjson,append=T) 
        write(paste0("       ",shQuote("origin_y"),":",BoiteBuf[2]),nomjson,append=T) 
        write("    },",nomjson,append=T)
        
        ################# Export
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.raster"),","),nomjson,append=T)
        write(paste0("       ",shQuote("gdaldriver"),":",shQuote("GTiff"),","),nomjson,append=T)
        write(paste0("       ",shQuote("data_type"),":",shQuote("float32"),","),nomjson,append=T)  
        write(paste0("       ",shQuote("filename"),":",shQuote(NomTIF)),nomjson,append=T)
        write("    }",nomjson,append=T)
        write("]",nomjson,append=T)
        cmd=paste(pdal_exe,"pipeline",nomjson)
        print(cmd)
        
        toto=system(cmd)
        if (file.exists(NomTIF)==F){ write("VIDE",nomBADPDAL)}
        
        # Nettoyage des regroupements s'il y a de très nombreux fichiers
        if (NbreFichierVirt>nLimit)
        {
          for (iRegroup in seq(1,NbreFichierVirt,nLimit))
          {
            NomLazRegroup_tmp=file.path(dsnlayer,NomDirMNTTIN,racilayerTA,NomDossDalles,paste0(racidalle,"_PtsVirts_Regroup", formatC(iRegroup ,width=4, flag="0"),"_Cerema.copc.laz"))
            unlink(NomLazRegroup_tmp)
          }
        }
        
        if (Nettoyage==1 & file.exists(NomTIF)==T)
        {
          unlink(nomjson)
        }
        
        # Gestion du bord de mer si nécesaire
        if (length(listeMasq2)>0)
        {
          if (dim(Masques2)[1]>0){
            nbMasq=st_intersects(Masques2,TA_Zone[idalle,])
            
            n_intMasq = which(sapply(nbMasq, length)>0)
            if (length(n_intMasq)>0)
            {
              MasqMer=Masques2[n_intMasq,]
              
              nomType=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,MasqMer$IdGlobal),"Type_Mer.txt")
               nomType=nomType[file.exists(nomType)==T]
              if (length(nomType)>0)
              {
                if (iTypeTIN==1 & length(nomType)>0 & file.exists(NomTIF)==T)
                {
                  cat("Gestion de plusieurs niveaux marins sur une même dalle RESULTATS A VERIFIER")
                  for (iType in 1:length(nomType))
                  {
                    # Lecture de l'altitiude de la mer
                    Val=read.csv(nomType[iType],header = F)
                    
                    
                    #Creation d'un monde GRASS
                    SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",idalle,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
                    system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
                    system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
                    
                    source(file.path(chem_routine,"FILINO_11_07_CreationMNT_TIN_Grass.R"),encoding = "utf-8")
                    FILINO_7_CreationMNT_Grass_Mer(NomTIF,Val,reso)
                    
                    unlink(dirname(SecteurGRASS),recursive=TRUE)
                  }
                }
              }
            }
          }
        }
        
        if (nCalcTaudem==1 & file.exists(NomTIF)==T)
        {
          nproc=4
          cmd_str = paste("mpiexec -n", nproc, "PitRemove", "-z", NomTIF, "-fel", NomMNTFill)
          
          system(cmd_str)
          # fun_gpkg(felfile)
          
          # cmd =  paste(shQuote(OSGeo4W_path), "gdal_calc","--calc",'"A-B"', "--format", "GTiff", "--type", "Float32", "-A", NomMNTC, "--A_band", 1, "-B",
          #              NomTIF, "--B_band", 1, "--co", "COMPRESS=DEFLATE", "--co", "PREDICTOR=2", "--co" ,"ZLEVEL=9", "--co","BIGTIFF=YES","--outfile", NomCuv)
          # system(cmd) 
          # file.copy(file.path(dsnlayer,NomDirSIGBase,"H_cuvettes.qml"),
          #           paste0(substr(NomCuv,1,nchar(NomCuv)-4),".qml"),
          #           overwrite = T)
          # unlink(NomMNTC)
          # 
          # ConvertGPKG(NomCuv,0)
          # unlink(NomCuv)
          
        }
        
        Boite=st_bbox(TA_Zone[idalle,1])
        
        #Creation d'un monde GRASS
        SecteurGRASS=paste0(dirname(SecteurGRASS_),"_",idalle,"_",format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
        system(paste0(BatGRASS," -c EPSG:",nEPSG," ",dirname(SecteurGRASS)," --text"))
        system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
        
        source(file.path(chem_routine,"FILINO_11_07_CreationMNT_TIN_Grass.R"),encoding = "utf-8")
        FILINO_7_CreationMNT_Grass_Boite_et_Cuvettes(NomTIF,NomGPKG,NomMNTFill,NomMNTCuv,Boite,reso)
        
        unlink(dirname(SecteurGRASS),recursive=TRUE)
        
        # ConvertGPKG(NomTIF,0)
        unlink(NomTIF)
        unlink(NomMNTFill)
      }else{
        if (Alancer==0) cat("Déjà fait ",NomGPKG,"\n") else cat(" Bad alloc de pdal! ",NomGPKG,"\n")
      }
    }
  }
}