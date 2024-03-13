FILINO_07_05a_Job=function(iLAZ,TA_tmp,racilayerTAold,TA_Old,Classe_New)
{
  # Gestion des noms de champs de mes tables d'assemblage
  
  if (is.null(TA_tmp$CHEMIN))
  {
    # Lidar Hd brut
    NomLaz=basename(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
    ChemLaz=dirname(file.path(dsnlayerTA,TA_tmp$DOSSIER,TA_tmp$NOM))
  }else{
    # Lidar HD classif
    NomLaz=TA_tmp$NOM
    ChemLaz=TA_tmp$CHEMIN
  }
  raci=gsub(".copc","_copc",paste0(substr(NomLaz,1,nchar(NomLaz)-4)))
  
  NomLaz_tmp= file.path(dsnlayer,nomDirViSOLssVEGE,racilayerTA,NomDossDalles,paste0(raci,"_",racilayerTAold,"_SolSsVegDens_PtsVirt.copc.laz"))
  
  nom_masque_gpkg=paste0(raci,"_VegeTropDense.gpkg")
  nommasqueveget =file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,nom_masque_gpkg)
  ###################### Récupération des vieux points sol
  if (is.null(nommasqueveget)==F)
  {
    if (file.exists(nommasqueveget)==T & file.exists(NomLaz_tmp)==F)
    {
      ###### Liaison pour aller récupérer les points sol des vieux Lidar
      nb=st_intersects(TA_Old,st_buffer(TA_tmp,-10))
      n_int = which(sapply(nb, length)>0)
      if (length(n_int)>0)
      {
        TA_Old_tmp=TA_Old[n_int,]
        NomOld=file.path(TA_Old_tmp$CHEMIN,TA_Old_tmp$NOM)
        
        nomjson=file.path(dsnlayer,nomDirViSOLssVEGE,racilayerTA,NomDossDalles,paste0(raci,"_",racilayerTAold,"_VegeTropDense.json"))
        
        VectVeget=st_read(nommasqueveget)
        unlink(nommasqueveget)
        VectVeget$value=Classe_New
        st_write(VectVeget,nommasqueveget, delete_layer=T, quiet=T)
        
        cat("###############################################################\n")
        print(NomLaz_tmp)
        write("[",nomjson)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("readers.las"),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(NomOld),","),nomjson,append=T)
        write(paste0("       ",shQuote("override_srs"),":",shQuote(paste0("EPSG:",nEPSG)),","),nomjson,append=T)
        write(paste0("       ",shQuote("nosrs"),":",shQuote("true")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote(Classe_Old)),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.overlay"),","),nomjson,append=T)
        write(paste0("       ",shQuote("column"),":",shQuote("value"),","),nomjson,append=T)
        write(paste0("       ",shQuote("datasource"),":",shQuote(nommasqueveget),","),nomjson,append=T)
        write(paste0("       ",shQuote("dimension"),":",shQuote("Classification")),nomjson,append=T)
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("filters.range"),","),nomjson,append=T)
        write(paste0("       ",shQuote("limits"),":",shQuote(paste0("Classification[",Classe_New,":",Classe_New,"]"))),nomjson,append=T) # 2 pour Lidar2m nimes et 10 pour NUALID, on s'y perd...
        write("    },",nomjson,append=T)
        write("    {",nomjson,append=T)
        write(paste0("       ",shQuote("type"),":",shQuote("writers.copc"),","),nomjson,append=T)
        write(paste0("       ",shQuote("filename"),":",shQuote(NomLaz_tmp),","),nomjson,append=T)
        write(paste0("       ",shQuote("scale_x"),":",0.01,","),nomjson,append=T)
        write(paste0("       ",shQuote("scale_y"),":",0.01,","),nomjson,append=T)
        write(paste0("       ",shQuote("scale_z"),":",0.01),nomjson,append=T)
        write("    }",nomjson,append=T)
        
        # RAJOUTER une creation gdal et ensuite un passage en grass (idem pont) pour avoir l'emprise
        
        write("]",nomjson,append=T)
        
        cmd=paste(pdal_exe,"pipeline",nomjson)
        cat("---------------------------------------------\n")
        cat("PDAL ",basename(NomLaz_tmp),"\n")
        toto=system(cmd)
        
        if (Nettoyage==1){unlink(nomjson)}
        
      }else{
        cat("Pas de vieille donnée","\n")
      }
      
    }else{
      cat("Lidar Sol ancien déjà présent",basename(NomLaz_tmp),"\n")
    }
  }
  if (is.null(nommasqueveget)==T)
  {
    nomVIDE=file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,NomDossDalles,paste0(raci,"_",racilayerTA,"_VegeTropDense.vide"))
    cat("Pas d'autres données Lidar ",nomVIDE,"\n")
    write("VIDE",nomVIDE)
  }
}