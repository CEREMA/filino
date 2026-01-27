source("C:/R/R-4.4.2/Cerema/Diff_MNT_Filtree.R")
cat("\014")
SecteurGRASS_="C:/GRASSDATA/aaaa/zzzz"
# Lien vers le logiciel GRASS
BatGRASS="C:\\QGIS\\bin\\grass84.bat"

# Lien pour utiliser Pdal
pdal_exe="C:/QGIS/bin/pdal.exe"

EPSG=2975
nEPSG=2975

dsnlayer= "H:/FILINO_Travail_Reunion"
NomDirMasqueVEGE  ="01b_MASQUE_VEGEDENSE"
NomDirMNTTIN_F    ="06_MNTTIN_FILINO"         
NomDirMNTTIN_D    ="06_MNTTIN_Direct"         
NomDirMNTGDAL ="07_MNTGDAL00"    

NomDirMNTTIN=NomDirMNTTIN_D
racilayerTA="TA_Reu_HD_copc"

textdeb="Semis_2023_" #"LHD_FXX_"
textfin="_RGR92UTM40S_REUN89_copc_" #_PTS_C_LAMB93_IGN69_copc_"
nomTIN="TIN_Direct" #TIN_Filino"
nfiltre=9

Nettoyage=1

# for (ix in (314:379))
# {
#   for (iy in 7635:7692)
#   {
for (ix in 322)
{
  for (iy in 7665)
  {
    ixy= paste0(formatC(ix ,width=4, flag="0"),"_", formatC(iy ,width=4, flag="0"))
    
    
    
    nomMNTa   =file.path(dsnlayer,NomDirMNTTIN,racilayerTA,"Dalles",paste0(textdeb,ixy,textfin,nomTIN,".gpkg"))
    nomMNTb   =file.path(dsnlayer,NomDirMNTGDAL,racilayerTA,"Dalles",paste0(textdeb,ixy,textfin,"VEGE_min.gpkg"))
    nomMasque =file.path(dsnlayer,NomDirMasqueVEGE,racilayerTA,"Dalles",paste0(textdeb,ixy,textfin,"VegeTropDense.gpkg"))
    NomExport1=file.path(dsnlayer,"08_Vege_InfMNT",paste0("Diff1_Nei",nfiltre,"_",ixy,".gpkg"))
    NomExport2=file.path(dsnlayer,"08_Vege_InfMNT",paste0("Diff2_Nei",nfiltre,"_",ixy,".gpkg"))
    nomPtsVirt_GrassCsv=file.path(dsnlayer,"08_Vege_InfMNT",paste0("Vege_InfMNT",nfiltre,"_",ixy,"_PtsVirt_Grass.csv"))
    
    nomPtsVirt_csv=file.path(dsnlayer,paste0("Vege_InfMNT",nfiltre,"_",ixy,"_PtsVirt.csv"))
    nomjson=file.path(dsnlayer,"08_Vege_InfMNT",paste0("Vege_InfMNT_Filt",nfiltre,"_",ixy,"_PtsVirt.json"))
    nomPtsVirtLaz=file.path(dsnlayer,"08_Vege_InfMNT",paste0("Vege_InfMNT",nfiltre,"_",ixy,"_PtsVirt.copc.laz"))
    
    if (file.exists(nomMNTa)==T & file.exists(nomMNTb)==T & file.exists(nomMasque)==T)
    {
      
      #Creation d'un monde GRASS
      SecteurGRASS=paste0(dirname(SecteurGRASS_),format(Sys.time(),format="%Y%m%d_%H%M%S"),"/",basename(SecteurGRASS_))
      unlink(dirname(SecteurGRASS),recursive=TRUE)
      toto=system(paste0(BatGRASS," -c EPSG:",EPSG," ",dirname(SecteurGRASS)," --text"))
      if (toto!=0){cat("Vous avez un problème dans ",BatGRASS,"\n");BUGDEGRASS=BOOM}
      system(paste0(BatGRASS," -c ",SecteurGRASS," --text"))
      
      Diff_MNT_Filtree(nomMNTa,
                       nomMNTb,
                       nomMasque,
                       nfiltre,
                       " -c",
                       NomExport1,
                       NomExport2,
                       nomPtsVirt_GrassCsv,
                       "<",
                       0.5)
      
      # unlink(dirname(SecteurGRASS),recursive=TRUE)
      
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
        
        if (Nettoyage==1){unlink(nomjson)}
      }
    }
  }
}
