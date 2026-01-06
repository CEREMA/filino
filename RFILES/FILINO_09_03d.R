library(sf)

reso=0.5

chem_routine=dirname(rstudioapi::getActiveDocumentContext()$path)
# Initialisation des chemins et variables
source(file.path(chem_routine,"FILINO_0_Initialisation.R"))

# rep_COURSEAU="D:/IGN/DTM_produits/01_COURSEAU/COURDEAU0000002000888894"
#masse agen
rep_COURSEAU=file.path(dsnlayer,NomDirCoursEAU,"COURDEAU0000002000888894")

#luynes
rep_COURSEAU=file.path(dsnlayer,NomDirCoursEAU,"COURDEAU0000002000804233")

#luynes
rep_COURSEAU=file.path(dsnlayer,NomDirCoursEAU,"COURDEAU0000002000806989")

# Liste des points
listefond=list.files(rep_COURSEAU,pattern="_01_fond.gpkg")
if (length(listefond)>1)
{
  # PointsBas=do.call(rbind,lapply(file.path(rep_COURSEAU,listefond[c(2,3)]), function(x) {cbind(st_read(x),File=basename(x))}))
  PointsBas=do.call(rbind,lapply(file.path(rep_COURSEAU,listefond), function(x) {cbind(st_read(x),File=basename(x))}))
}else{
  PointsBas=cbind(st_read(file.path(rep_COURSEAU,listefond)),File=listefond)
}

st_write(PointsBas,file.path(rep_COURSEAU,"PointsBas.gpkg"), delete_layer=T, quiet=T)

nTrB="Tron_tampon_TA_LidarHD_LAZ_Classif.gpkg"
nTrB="Tron_tampon_TA_LidarHD_LAZ.gpkg"
TronconBuffer=st_cast(st_read(file.path(rep_COURSEAU,nTrB)),"POLYGON")
# Zones blanches
nZB="ZonesBlanches_TA_LidarHD_LAZ_Classif.gpkg"
if (file.exists(file.path(rep_COURSEAU,nZB))) 
{
  ZonesBlanches=st_read(file.path(rep_COURSEAU,nZB))
  
  # 
  nb=st_within(ZonesBlanches,st_cast(TronconBuffer,"POLYGON"))
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    ZonesBlanches=ZonesBlanches[n_int,]
    ZonesBlanches_Pts=st_cast(st_segmentize(ZonesBlanches,1.01*reso),"POINT")
    
    # X       Y     Z Classification Distance2 Distance1 Classification2 Fond                                       File
    ZonesBlanches_Pts=ZonesBlanches_Pts[,1]
    
    ZonesBlanches_Pts$X=st_coordinates(ZonesBlanches_Pts)[,1]
    ZonesBlanches_Pts=ZonesBlanches_Pts[,"X"]
    ZonesBlanches_Pts$Y=st_coordinates(ZonesBlanches_Pts)[,2]
    ZonesBlanches_Pts$Z=-99
    ZonesBlanches_Pts$Classification=-99
    ZonesBlanches_Pts$Distance2=-99
    ZonesBlanches_Pts$Distance1=-99
    ZonesBlanches_Pts$Classification2=-99
    ZonesBlanches_Pts$Fond=min(PointsBas$Fond)
    ZonesBlanches_Pts$File=nZB
    PointsBas=rbind(st_zm(PointsBas),ZonesBlanches_Pts)
  }
}
# Tampon=st_buffer(st_union(st_buffer(PointsBas,largBuf),st_buffer(ZonesBlanches,largBuf)),-largBuf)

largBuf=10

for (ifond in sort(unique(PointsBas$Fond)))
{
  nbfond=which(PointsBas$Fond<=ifond)
  Tampon=st_buffer(st_union(st_buffer(PointsBas[nbfond,],largBuf)),-largBuf)
  st_write(Tampon,file.path(rep_COURSEAU,paste0("Tampon",formatC(ifond*100, width = 3, flag = "0"),"cm.gpkg")), delete_layer=T, quiet=T)
  
  Dista=st_distance(PointsBas[nbfond,],
                    st_cast(st_cast(Tampon,"POLYGON"),"LINESTRING"))
  
  seuil=0.1
  units(seuil)="m"
  
  lala=which(Dista<seuil)
  
  st_write(PointsBas[lala,],file.path(rep_COURSEAU,"PointsBas_lala.gpkg"), delete_layer=T, quiet=T)
  
}
# PointsBas$Fusion=1
# st_cast(PointsBas[,"Fusion"],"MULTIPOINT")


x=10

fun_BOUTS =
  function(PointsBas,x) {
    print(x)
    nbx=which(PointsBas$Distance2==x)
    
    
    if (length(nbx)==0)
    {
      res=NaN
    }
    
    PointsBasCalc=st_geometry(PointsBas[nbx,])
    if (length(nbx)==1 | length(nbx)==2)
    {
      # res=cbind(PointsBas[nbx,],Dist=x)
      res=PointsBasCalc
    }
    if (length(nbx)>2){
      # indice=which(st_distance(PointsBas[nbx,1],PointsBas[nbx,1])==max(st_distance(PointsBas[nbx,1],PointsBas[nbx,1])))
      tmp_=st_distance(PointsBasCalc,PointsBasCalc)
      indice=which(tmp_==max(tmp_))
      ndeux=indice-length(nbx)*floor(indice/length(nbx))
      # res=cbind(PointsBas[nbx[ndeux],],Dist=x) 
      res=PointsBasCalc[ndeux]
    }
    # print(res)
    return(res)
  }

fun_BOUTS(PointsBas,286)
listeBouts=lapply(sort(unique(PointsBas$Distance2)), function(x) {fun_BOUTS(PointsBas,x)})
# 
# # listeBouts=lapply(c(193,194,195), function(x) {fun_BOUTS(PointsBas,x)})
# 
# PtsBouts=do.call(rbind,listeBouts)
# st_write(PtsBouts,file.path(rep_COURSEAU,paste0("PtsBouts.gpkg")), delete_layer=T, quiet=T)
