# C:\QGIS\apps\qgis\pdal_wrench build_vpc --output=merged.vpc 65DN1_07.LAZ 65DN1_08.LAZ 65DN1_12.LAZ 65DN1_13.LAZ

cat("\014")
cat("FILINO_15_10_VideosDemoProcess.R\n")


nomXLSX="FILINO_15_10_VideosDemoProcess.xlsx"

nimage=1

if (file.exists(file.path(chem_routine,nomXLSX))==T)
{
  listeExport <- read_excel(file.path(chem_routine,nomXLSX))
  
  naevaluer=which(is.na(listeExport$Chemin)==F)
  for (ieval in naevaluer)
  {
    listeExport$Chemin[ieval]=eval(parse(text = listeExport$Chemin[ieval]))
  }
  
  listeExport=listeExport[which(listeExport$Afaire==1),]
  
  TA=st_read(file.path(dsnlayerTA,nomlayerTA))
  
  RepQgs=file.path(dsnlayer,NomDirVideo,racilayerTA)
  vrtfile =file.path(RepQgs, "Virtuel.vrt") # nom de fihcier qui doit être pris dans projet Qgis
  shpfile=file.path(RepQgs, "Vect.shp") 
  nomjson=file.path(RepQgs, "PdalJson.json")
  nomLaz=file.path(RepQgs, "tmp.copc.laz")
  nomVPC=file.path(RepQgs, "tmp.vpc")
  
  repVIDEO=file.path(RepQgs,"VIDEO")
  FILINO_Creat_Dir(repVIDEO)
  
  Masques2=st_read(file.path(dsnlayer,NomDirMasqueVIDE,racilayerTA,"Masques2_FILINO.gpkg"))
  
  for (iZone in 1:dim(ZONE)[1])
  {
    ipng=1
    
    nb=st_intersects(TA,ZONE[iZone,])
    
    
    
    
    n_int = which(sapply(nb, length)>0)
    if (length(n_int)>0)
    {
      TA_Zone=TA[n_int,]
      
      ### Il faut intersecteur avec les masques 2 pour idglobal
      nbMV=st_intersects(Masques2,TA_Zone)
      n_intMV = which(sapply(nbMV, length)>0)
      if (length(n_intMV)>0)
      {
        Masques2V=Masques2[n_intMV,]
      }
      
      Limbox=st_bbox(TA_Zone)
      
      for (iexp in 1:dim(listeExport)[1])
      {
        Imprpng=0
        print(listeExport[iexp,])
        
        nom_Proj_Qgis=file.path(file.path(dsnlayer,NomDirSIGBase),listeExport$ProjQgis[iexp])
        nom_Proj_Qgis_tmp <- file.path(RepQgs,"FILINO_ProVideos_tmp.qgs")
        nom_MeP=listeExport$MeP[iexp]
        # Charger le fichier XML
        doc <- read_xml(nom_Proj_Qgis)
        # Trouver l'élément Extent
        extent_element <- xml_find_first(doc, "//Extent")
        LayoutItem_element <- xml_find_first(doc, "//LayoutItem")
        # Vérifier si l'élément Extent existe
        if (!is.null(extent_element) & !is.null(LayoutItem_element)) 
        {
          
          # Modifier la valeur de l'attribut ymax
          xml_set_attr(extent_element, "xmin", Limbox$xmin)
          xml_set_attr(extent_element, "xmax", Limbox$xmax)
          xml_set_attr(extent_element, "ymin", Limbox$ymin)
          xml_set_attr(extent_element, "ymax", Limbox$ymax)
          
          LayoutItem_element <- xml_find_all(doc, "//LayoutItem")
          
          xml_set_attr(LayoutItem_element[[2]],"labelText",listeExport$Titre1[iexp])
          xml_set_attr(LayoutItem_element[[3]],"labelText",ifelse(is.na(listeExport$Titre2[iexp]),"   ",listeExport$Titre2[iexp]))
          xml_set_attr(LayoutItem_element[[8]],"labelText",ZONE$ZONE[iZone])
          
          # Enregistrer les modifications dans le fichier
          nom_Proj_Qgis_tmp="Proj_Qgis_tmp.qgs"
          write_xml(doc, file.path(RepQgs,nom_Proj_Qgis_tmp))
          
          # Gestion des projets Raster
          if (listeExport$Type[iexp]=="RAST")
          {
            # listeExport$Chemin[iexp]=eval(parse(text = listeExport$Chemin[iexp]))
            listeRast=list.files(listeExport$Chemin[iexp],pattern=listeExport$Extension[iexp],recursive=T)
            print(listeRast)
            
            if (length(listeRast)>0)
            {
              racinomLazZone=substr(TA_Zone$NOM,1,nchar(TA_Zone$NOM)-4)
              racilisteRast=substr(listeRast,1,nchar(listeRast)-nchar(listeExport$Extension[iexp])+1)
              
              commun <- intersect(gsub(".copc","_copc",racinomLazZone), gsub(".copc","_copc",racilisteRast))
              
              if (length(commun)>0)
              {
                listeRast=file.path(listeExport$Chemin[iexp],paste0(commun,substr(listeExport$Extension[iexp],1,nchar(listeExport$Extension[iexp])-1)))
                nom_vrt = file.path(RepQgs, "listepourvrt.txt")
                file.create(nom_vrt)
                write(listeRast, file = nom_vrt, append = T)
                cmd = paste(shQuote(OSGeo4W_path),"gdalbuildvrt",vrtfile,"-input_file_list",nom_vrt)
                print(cmd);system(cmd)
                unlink(nom_vrt)
                Imprpng=1
              }
            }
          }
          # Gestion des projets Raster
          if (listeExport$Type[iexp]=="VECT")
          {
            # listeExport$Chemin[iexp]=eval(parse(text = listeExport$Chemin[iexp]))
            # Chemin vers le fichier texte contenant la liste des fichiers Shapefile
            listeVect=file.path(listeExport$Chemin[iexp],listeExport$Extension[iexp])
            Vect_tmp=st_read(listeVect)
            st_write(Vect_tmp,shpfile, delete_layer=T, quiet=T)
            Imprpng=1
          }
          
          if (substr(listeExport$Type[iexp],1,3)=="LAZ")
          {
            write("[",nomjson)
            
            if (listeExport$Type[iexp]=="LAZ1")
            {
              listeLAZ=file.path(dsnlayerTA,TA_Zone$DOSSIER,TA_Zone$NOM)
              
              # qgis_process run pdal:virtualpointcloud --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 --LAYERS='D:/FILINO_Travail/02_SURFACEEAU/TA_HD/SurfEAU000_002070kmX0775010Y6270330/SurfEAU.copc.laz' --LAYERS='D:/FILINO_Travail/02_SURFACEEAU/TA_HD/SurfEAU003_680589kmX0775752Y6269660/SurfEAU.copc.laz' --LAYERS='D:/FILINO_Travail/02_SURFACEEAU/TA_HD/SurfEAU001_452789kmX0773745Y6270044/SurfEAU.copc.laz' --BOUNDARY=false --STATISTICS=false --OVERVIEW=false --OUTPUT='D:/FILINO_Travail/vpc/cestpassimal.vpc'
              
              # cmd <- paste0(qgis_process, " run pdal:virtualpointcloud",
              #               " --distance_units=meters --area_units=m2 --ellipsoid=EPSG:7019 ")
              # for (ilLAZ in 1:length(listeLAZ))
              # {
              #   cmd=paste0(cmd," --LAYERS=",shQuote(listeLAZ[ilLAZ]))
              # }
              # cmd=paste0(cmd," --BOUNDARY=false --STATISTICS=false --OVERVIEW=false --OUTPUT=",
              #           shQuote(nomVPC))            
              # system(cmd)
            }
            if (listeExport$Type[iexp]=="LAZ2")
            {
              # listeExport$Chemin[iexp]=eval(parse(text = listeExport$Chemin[iexp]))
              listeLAZ=file.path(listeExport$Chemin[iexp],paste0(raciSurfEau,Masques2V$IdGlobal),listeExport$Extension[iexp])
              listeLAZ=listeLAZ[which(file.exists(listeLAZ)==T)]
            }
            if (listeExport$Type[iexp]=="LAZ3")
            {
              # listeExport$Chemin[iexp]=eval(parse(text = listeExport$Chemin[iexp]))
              
              listeLAZ=file.path(listeExport$Chemin[iexp],TA_Zone$NOM)
              
              listeVEGELAZ=file.path(listeExport$Chemin[iexp],list.files(listeExport$Chemin[iexp],pattern="_SolSsVegDens_PtsVirt.copc.laz"))
              commun <- match(substr(basename(listeVEGELAZ),1,paramXYTA$NbreCaratere),gsub(".copc","_copc",substr(basename(listeLAZ),1,paramXYTA$NbreCaratere)))
              listeLAZ=listeVEGELAZ[which(is.na(commun)==F)]
              
            }
            
            print(listeLAZ)
            
            VirutlaPointCloud=0
            if (VirutlaPointCloud==1)
            {
              nom_laz_pour_vpc = file.path(RepQgs, "listepourvpc.txt")
              nomVPC=file.path(RepQgs,"hello.vpc")
              # file.create(nom_laz_pour_vpc)
              write(listeLAZ, file = nom_laz_pour_vpc)
              
              
              nombat=file.path(RepQgs,"MonWrenchPdal.bat")
              write("C:",file = nombat)
              write("set PATH=C:\\QGIS\\bin;%PATH%",
                    file = nombat,append = T)
              # write(paste0("C:\\QGIS\\apps\\qgis\\pdal_wrench.exe",
              #       " build_vpc --output=",shQuote(nomVPC)," --file=",shQuote(listeLAZ)),
              #       file = nombat,
              #       append = T)
              write(paste0("C:\\QGIS\\apps\\qgis\\pdal_wrench.exe",
                           " build_vpc --output=","toto.vpc"," LHD_FXX_0781_6273_PTS_O_LAMB93_IGN69_copc_TA_NiMontpLid2m_SolSsVegDens_PtsVirt.copc.laz LHD_FXX_0509_6349_PTS_O_LAMB93_IGN69_copc_TA_NUALID_SolSsVegDens_PtsVirt.copc.laz"),
                    file = nombat,
                    append = T)
              setwd("D:\\FILINO_Travail\\08_Videos\\TA_HD")
              system(nombat)
              
            }else{
              ################ Import des fichiers Laz virtuels Cerema
              # for (NOMLAZ in file.path(TAPtsVirtu[n_intVirt,]$CHEMIN,TAPtsVirtu[n_intVirt,]$NOM))
              for (NOMLAZ in listeLAZ)
              {
                write("    {",nomjson,append=T)
                write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
                write(paste0("       ",shQuote("filename"),":",shQuote(NOMLAZ),","),nomjson,append=T)
                write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
                write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
                write("    },",nomjson,append=T)
              } 
              
              ############# Fusion des fichiers
              if (dim(TA_Zone)[1]>0)
              {
                write("    {",nomjson,append=T)
                write(paste0("       ",shQuote("type"),":",shQuote("filters.merge")),nomjson,append=T)
                write("    },",nomjson,append=T)
              }
              write("    {",nomjson,append=T)
              write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
              write(paste0("       ",shQuote("filename"),":",shQuote(nomLaz),","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
              write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
              write("    }",nomjson,append=T)
              write("]",nomjson,append=T)
              
              cmd=paste(pdal_exe,"pipeline",nomjson)
              print(cmd)
              
              system(cmd)
            }
            Imprpng=1
          }
          if (listeExport$Type[iexp]=="FIXE")
          {
            Imprpng=1
          }
          
          
          if (Imprpng==1 & listeExport$Type[iexp]!="JPG")
          {
            
            
            nompng=paste0(ZONE$ZONE[iZone],paste0(formatC(ipng,width=3, flag="0"),".png"))
            ipng=ipng+1
            
            setwd(RepQgs)
            cmd=paste0(shQuote(qgis_process),
                       " run native:printlayouttoimage project_path=",
                       basename(nom_Proj_Qgis_tmp),
                       " LAYOUT=",
                       nom_MeP,
                       " OUTPUT=",
                       nompng,
                       " DPI=",
                       100)
            system(cmd)
            setwd(chem_routine)
            unlink(vrtfile)
            unlink(shpfile)
            unlink(nomLaz)
            
            for (ima in 1:listeExport$VideoImageParSeconde[iexp])
            {
              nompng2=file.path(repVIDEO,paste0("Im",paste0(formatC(nimage,width=4, flag="0"),".png")))
              file.copy(file.path(RepQgs,nompng),nompng2)
              nimage=nimage+1
            }  
            
          }
        }
        # }else{
        if (listeExport$Type[iexp]=="JPG")
        {
          # listeExport$Chemin[iexp]=eval(parse(text = listeExport$Chemin[iexp]))
          # Chemin vers le fichier texte contenant la liste des fichiers Shapefile
          
          if (dim(Masques2V)[1]>0)
          {
            motclesMRM=cbind("Eco","Pla","Can","Mer")
            for (imotcle in motclesMRM)
            {
              print(imotcle)
              njpg_=which(substr(Masques2V$FILINO,1,3)==imotcle)
              if (length(njpg_)>0)
              {
                Ilyenaun=0
                indiJPG=0
                while (Ilyenaun==0 & indiJPG<=length(njpg_)-1)
                {
                  # 
                  indiJPG=indiJPG+1
                  repjpg=file.path(dsnlayer,NomDirSurfEAU,racilayerTA,paste0(raciSurfEau,Masques2V$IdGlobal[njpg_[indiJPG]]))
                  nomjpgacopier=list.files(repjpg,pattern=".jpg$")
                  # print(list.files(repjpg))
                  # print(nomjpgacopier)
                  if (length(nomjpgacopier)>0)
                  {
                    # print(imotcle)
                    # browser()
                    Ilyenaun=1
                  }
                }
                if (length(nomjpgacopier)>0)
                {
                  image <- readJPEG(file.path(repjpg,nomjpgacopier[1]))
                  nompng=paste0(ZONE$ZONE[iZone],paste0(formatC(ipng,width=3, flag="0"),".png"))
                  ipng=ipng+1
                  temppng=file.path(RepQgs,"Temp.png")
                  writePNG(image,temppng)
                  
                  setwd(RepQgs)
                  cmd=paste0(shQuote(qgis_process),
                             " run native:printlayouttoimage project_path=",
                             basename(nom_Proj_Qgis_tmp),
                             " LAYOUT=",
                             nom_MeP,
                             " OUTPUT=",
                             nompng,
                             " DPI=",
                             100)
                  system(cmd)
                  setwd(chem_routine)
                  unlink(temppng)
                  unlink(vrtfile)
                  unlink(shpfile)
                  unlink(nomLaz)
                  
                  
                  for (ima in 1:listeExport$VideoImageParSeconde[iexp])
                  {
                    nompng2=file.path(repVIDEO,paste0("Im",paste0(formatC(nimage,width=4, flag="0"),".png")))
                    file.copy(file.path(RepQgs,"Temp.png"),nompng2)
                    nimage=nimage+1
                  }  
                }
                
              }
            }
          }
          
        }
        
        
        
        
      }
    }
    
  }
  if (nCalcVideo==1 & file.exists(ffmpeg))
  {
    setwd(repVIDEO)
    cmd=paste0(shQuote(ffmpeg),
               " -f image2 -i ",
               shQuote(paste0("Im","%4d.png")),
               " -r 50  -vf ",
               shQuote("pad=ceil(iw/2)*2:ceil(ih/2)*2"),
               " -y ","FILINO_Expli",".mp4")
    
    system(cmd)
    
    setwd(chem_routine)
  }
}
