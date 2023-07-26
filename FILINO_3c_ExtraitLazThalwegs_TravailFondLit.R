library(sf)
library(ggplot2)
source(file.path(chem_routine,"Sous_Routine_Cartino2D","GGPLOT_MULTIPLOT.R"))
# rep_COURSEAU="D:/IGN/DTM_produits/01_COURSEAU/COURDEAU0000002000888894"
# 
# nomPtsLAZ="PtsLAZ.gpkg"
# 
# PtsLAZ=st_read(file.path(rep_COURSEAU,nomPtsLAZ))
PtsLAZ=st_sf(cbind(PtsCSV,geometry=st_cast(st_sfc(geometry=st_multipoint(x = as.matrix(PtsCSV[,1:3]), dim = "XYZ")),"POINT")))

st_crs(PtsLAZ)=st_crs(2154)
# PtsLAZ$Classification=as.numeric(PtsLAZ$Classification)
PtsLAZ$Distance2=NA

coul=cbind("grey","brown","red","blue")
# Découpe par troncon hydrographique continu

if (dim(Tronhydro)[1]>1)
{
  
}
for (idecoup in 1:dim(Tronhydro)[1])
{
  cat(idecoup,"/",dim(Tronhydro)[1],"\n")
  Tronhydro_Pts=st_cast(st_segmentize(Tronhydro[idecoup,],0.5),"POINT")
  Tronhydro_Pts$Distance2=1:dim(Tronhydro_Pts)[1]
  # st_write(Tronhydro_Pts,
  # file.path(dsnlayer,rep_COURSEAU,paste0("Tronhydro_","_",racilayerTA,"_Pts.gpkg")), delete_layer=T, quiet=T)
  
  #### Buffer hazardeux pour trouver le plus proche...
  nb=st_intersects(PtsLAZ,st_buffer(Tronhydro[idecoup,],30))
  n_int = which(sapply(nb, length)>0)
  if (length(n_int)>0)
  {
    
    PtsLAZ_tmp=PtsLAZ[n_int,]
    cat("st_nearest_feature","cela peut être long","\n")
    PtsLAZ_tmp$Distance1=st_distance(PtsLAZ_tmp,Tronhydro[idecoup,])
    PtsLAZ_tmp$Distance2=st_nearest_feature(PtsLAZ_tmp,Tronhydro_Pts)

    cat("st_nearest_feature","fini","\n")
    
    racinomPtsLaz=paste0("PtsLAZ","_",racilayerTA,"_",formatC(idecoup,width=2, flag="0"))
    nomPtsLAZ=paste0(racinomPtsLaz,".gpkg")
    
    PtsLAZ_tmp$Classification2=factor(PtsLAZ_tmp$Classification,levels=unique(PtsLAZ_tmp$Classification))
    
    PtsLAZ_tmp=PtsLAZ_tmp[order(PtsLAZ_tmp$Distance2),]
    PtsLAZ_tmp$Fond=0
    
    
    Gp1=ggplot()+
      geom_point(data=PtsLAZ_tmp,aes(x=Distance2,y=Z,colour=Classification2),size=0.25)+
      scale_color_manual(values = legClassification[as.numeric(levels(PtsLAZ_tmp$Classification2))])
    # Récupération du bas sur chaque distance
    Mini_absc=data.frame(X=1:max(PtsLAZ_tmp$Distance2))
    Mini_absc=data.frame(X=1:max(PtsLAZ_tmp$Distance2),Y=sapply(1:max(PtsLAZ_tmp$Distance2), function(x) {min(PtsLAZ_tmp$Z[which(PtsLAZ_tmp$Distance2==x)])}))
    Mini_absc$Yfond1=sapply(Mini_absc$X, function(x) {min(Mini_absc$Y[1:x])})
    
    # Mini_absc=Mini_absc[which(is.na(Mini_absc$Y)==F),]
    decalS=2
    decalZ=c(0.25,0.25,0.25,0.25,0.25,0.25)
    
    PtsLAZ_tmp_=PtsLAZ_tmp
    for (iz in 1:length(decalZ))
    {
      # Récupération du bas sur chaque distance
      Mini_absc=data.frame(X=1:max(PtsLAZ_tmp_$Distance2))
      Mini_absc=data.frame(X=1:max(PtsLAZ_tmp_$Distance2),Y=sapply(1:max(PtsLAZ_tmp_$Distance2), function(x) {min(PtsLAZ_tmp_$Z[which(PtsLAZ_tmp_$Distance2==x)])}))
      Mini_absc$Yfond1=sapply(Mini_absc$X, function(x) {min(Mini_absc$Y[1:x])})
      
      Gp1=Gp1+
        geom_line(data=Mini_absc,mapping=aes(x=X,y=Yfond1),color="magenta",size=1)
      for (inc in Mini_absc[,1])
      {
        nb=which(PtsLAZ_tmp$Distance2==inc)
        nbMini=which(Mini_absc[,1]==inc)
        
        nb2=which(PtsLAZ_tmp$Z[nb]<=as.numeric(Mini_absc$Yfond1[max(nbMini-decalS,1)])+decalZ[iz] & PtsLAZ_tmp$Fond[nb]==0)
        PtsLAZ_tmp$Fond[nb[nb2]]=sum(decalZ[1:iz])
      }
      nb=which(PtsLAZ_tmp$Fond!=0)
      PtsLAZ_tmp_=PtsLAZ_tmp[-nb,]
    }
    
    raci_exp=basename(paste0(racinomPtsLaz,"_cherchefond"))
    Gp0=ggplot()+
      geom_rect(aes(x=0:1, y=0:1, geom="blank")+xlim(0,1)+ylim(0,1))+
      annotate("text",x = 0.5, y = 0.5, label = raci_exp,hjust=0.5,vjust=0.5,size=5)+
      theme(panel.background = element_blank())+
      xlab(NULL)+ylab(NULL)+theme(axis.ticks=element_blank(),axis.text = element_blank())
    
        st_write(PtsLAZ_tmp[nb,],
             file.path(paste0(racinomPtsLaz,"_fond.gpkg")), delete_layer=T, quiet=T)
    
    jpeg(filename = file.path(paste0(raci_exp,".jpg")), width = 59.8*2/3 , height = 33.6*2/3, units = "cm", quality = 75, res = 300)
    mise_en_page3=matrix(c(1,2,2,2,2,2,2,2),
                         8, 1, byrow = TRUE)
    multiplot(Gp0,Gp1,layout=mise_en_page3)
    dev.off()
    

  }
}
