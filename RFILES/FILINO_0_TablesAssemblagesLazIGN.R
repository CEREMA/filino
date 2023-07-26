library(sf)

# Initialisation des chemins et variables
# chem_routine = R.home(component = "cerema")
Auto=c(1,1)
source(file.path(chem_routine,"FILINO_0_InitVariable.R"))

cas_run=c(1,2,3,4,5,6,7)

dsnlayerLAZ=c("D:/IGN/IGN_Cerema_UGE/DTM_produits",
           "F:/Lidar2m",
           "F:/NUALID",
           "F:/LidarHD_copc",
           "F:/LIDARHD_Nimes",
           "F:/Lidar_MC",
           "F:/LidarHD_DC")


paramHD_2m=rbind(cbind(35,12,15,17,20),
                 cbind(18,1,3,8,11),
                 cbind(59,25,28,30,33),
                 cbind(45,9,12,14,17),
                 cbind(35,12,15,17,20),
                 cbind(24,1,4,9,12),
                 cbind(45,9,12,14,17))

nomTAexport=cbind("TA_LidarHD_LAZ_Classif.shp",
                  "TA_Lidar2m_LAZ.shp",
                  "TA_NUALID_LAZ.shp",
                  "TA_LidarHD_copc.shp",
                  "TA_LidaHD_Nimes.shp",
                  "TA_LidarMC_copc.shp",
                  "TA_LidarDC_Class_copc.shp")

COPC=c(0,
       0,
       0,
       1,
       0,
       1,
       1)


for (icas in 1:length(cas_run))
{
  # dsnlayerLAZ=dsnlayerLAZ[cas_run[icas]]
  # paramHD_2m=paramHD_2m[cas_run[icas],]
  # nomTAexport=nomTAexport[cas_run[icas]]
  # COPC=COPC[cas_run[icas]]
  
  listeLAZ=list.files(dsnlayerLAZ[cas_run[icas]],pattern=".laz",recursive="TRUE")
  if (COPC[cas_run[icas]]==0)
  {
    indcopc=grep(listeLAZ,pattern="copc")
    if( length(indcopc)>0){listeLAZ=listeLAZ[-indcopc]}
    listeLAZ=listeLAZ[nchar(basename(listeLAZ))==paramHD_2m[cas_run[icas],][1]]
  }
  
  Res=list()
  tour=list()
  for (i in 1:length(listeLAZ)[1])
  {  
    NLaz=basename(listeLAZ[i])
    largdalle=1
    xt=as.numeric(substr(NLaz,paramHD_2m[cas_run[icas],][2],paramHD_2m[cas_run[icas],][3]))
    yt=as.numeric(substr(NLaz,paramHD_2m[cas_run[icas],][4],paramHD_2m[cas_run[icas],][5]))
    xabs=1000*c(xt,xt,xt+largdalle,xt+largdalle,xt)
    yabs=1000*c(yt,yt-largdalle,yt-largdalle,yt,yt)
    tour[[1]]=matrix(c(xabs,yabs),5,2)
    
    
    Res[[i]]=st_sf(data.frame(ID=i,
                              CHEMIN=file.path(dsnlayerLAZ[cas_run[icas]],dirname(listeLAZ[i])),
                              DOSSIER=dirname(listeLAZ[i]),
                              NOM=basename(listeLAZ[i])),
                   "geometry" =st_sfc(st_polygon(tour,dim="XY")),
                   crs=2154)
  }
  
  cat(i,length(Res),"fusion","\n")
  Gagne = do.call(rbind, Res)
  
  st_write(Gagne,file.path(dsnlayerLAZ[cas_run[icas]],nomTAexport[cas_run[icas]]), delete_layer=T, quiet=T)
  file.copy(file.path(dsnlayer,NomDirSIGBase,"TA_ACTION_LAZ.qml"),
            file.path(dsnlayerLAZ[cas_run[icas]],paste0(substr(nomTAexport[cas_run[icas]],1,nchar(nomTAexport[cas_run[icas]])-4),".qml")),
            overwrite = T)
}