FILINO_06_02c_creatPtsVirtuels=function(nomcsv,rep_COURSEAU,Cas,raci_exp,nomPtsVirt)
{
  cat("FILINO_06_02c_creatPtsVirtuels.R - Etap2[3]==1\n")
  # Lecture des fichiers de points csv provenant du Laz
  PtsCSV=read.csv(nomcsv)
  if (dim(PtsCSV)[1]>0)
  {
    # Lecture du masque intenes pour créer des points viruels
    
    Masque1=st_read(file.path(rep_COURSEAU,"Masque1.gpkg"))
    Masque2=st_read(file.path(rep_COURSEAU,"Masque2.gpkg"))
    
    #-------------------------------------------------------------------------------------------------------------
    
    # # Lecture du cas à traiter dans Masque2$FILINO, ordre important
    # Cas=0
    # if (substr(Masque2$FILINO,1,3)=="Mer")   {Cas=1}
    # if (substr(Masque2$FILINO,1,3)=="Eco")   {Cas=4}
    # if (substr(Masque2$FILINO,1,3)=="Can")   {Cas=3}
    # if (substr(Masque2$FILINO,1,3)=="Pla")   {Cas=2}
    
    if (Cas!=0)
    {
      ####################################################################
      # Travail sur la BDTopo pour détecter quel type de traitement est à effectuer
      # variable CodeVirtbase et CodeVirtuels
      
      # Si écoulement, lecture du fichier hydro
      if (Cas==3 | Cas==4)
      {
        # nomtrhydro=file.path(dirname(nomcsv),paste0("trhydro_",racilayerTA,".gpkg"))
        nomtrhydro=file.path(dirname(nomcsv),"trhydro.gpkg")
        
        if (file.exists(nomtrhydro)==T)
        {
          # Lecture des tronçons hydros à c^té du masque
          trhydroTout=st_read(nomtrhydro)
          
          # naretenir=which(trhydroTout$F_Tr=="Ecoulement")
          naretenir=which(trhydroTout$F_Tr=="Canal" | 
                            trhydroTout$F_Tr=="Ecoulement")
          # |
          #                   trhydroTout$F_Tr=="Retenue-barrage")
          trhydro=trhydroTout[naretenir,]
          
          trhydro=do.call(rbind,
                          lapply(sort(unique(trhydro$liens_vers_cours_d_eau )),
                                 function(x) {st_sf(data.frame(liens_vers_cours_d_eau =x),
                                                    geometry=st_line_merge(st_cast(st_union(trhydro[which(trhydro$liens_vers_cours_d_eau ==x),]),"MULTILINESTRING")))}))
          
          if (is.null(dim(trhydro)[1])==FALSE)
          {
            if (dim(trhydro)[1]>1)
            {
              cat("Test s'il y a plusieurs cours d'eau qui se croisent, résultats incertains","\n")
              IntertrhydroMasque2=st_intersection(trhydro, Masque2)
              IntertrhydroMasque2=IntertrhydroMasque2[which(st_length(IntertrhydroMasque2)==max(st_length(IntertrhydroMasque2))),]
              
              #### Ajout du 29/09/2023 lié à des discontinuité dans les champs ecoulement
              # Un cours d'eau nommé écoulement peut avoir au milieu d'autre nature comme retenue-barrage et ensuite redevenir un écoulement
              # On avait regardé le cours d'eau le + long, on capte son identifiant et
              # on reprend sur les troncons hydro de base touts les segments avec cet identiiant que l'on doit à nouveau fusionner...
              # un peu complexe mais on travaille sur la BDTopo...
              trhydro=trhydroTout[which(trhydroTout$liens_vers_cours_d_eau==IntertrhydroMasque2$liens_vers_cours_d_eau),]
              trhydro=st_sf(data.frame(liens_vers_cours_d_eau =trhydro$liens_vers_cours_d_eau[1]),
                            geometry=st_line_merge(st_cast(st_union(trhydro),"MULTILINESTRING")))
              
              trhydro=st_cast(st_line_merge(st_cast(trhydro,'MULTILINESTRING')),"LINESTRING")
              if (dim(trhydro)[1]>1)
              {
                trhydro=trhydro[st_length(trhydro)==max(st_length(trhydro)),]
              }
            } # Il faudra gérer quand il y a plusieurs troncçons dans un masque, intersection par exemple
            st_write(trhydro,file.path(rep_COURSEAU,"Polyligne_Calcul.gpkg"),delete_layer=TRUE)
          }else{
            Cas=0
          }
          
        }else{
          Cas=0
        }
      }
      
      
      ####################################################################
      # Travail des fichiers de points csv provenant du Laz
      if (Cas!=0)
      {    
        if (dim(PtsCSV)[1]>0)
        {
          ##### Limitation du nombre de point EAU à Nb_Eau_Max
          Nb_Eau_Max=500000
          nbEAU=which(PtsCSV$Classification==9)
          nbEAUIni=length(nbEAU)
          if (nbEAUIni>Nb_Eau_Max)
          {
            nbPasEAU=which(PtsCSV$Classification!=9)
            cat(length(nbEAU),dim(PtsCSV)[1],"\n")
            saut=seq(1,nbEAUIni,floor(nbEAUIni/Nb_Eau_Max))
            
            PtsCSV=PtsCSV[c(nbPasEAU,nbEAU[saut]),]
            nbEAU=which(PtsCSV$Classification==9)
            nbPasEAU=which(PtsCSV$Classification!=9)
            cat(length(nbEAU),dim(PtsCSV)[1],"\n")
          }
          
          # gestion pour les couleur de la légende, ne garder que les valeurs de 1 9 2 présente.*
          
          leve=ClassesUtilisees[which(is.na(match(ClassesUtilisees,unique(PtsCSV$Classification)))==F)]
          PtsCSV$Classification2=factor(PtsCSV$Classification,levels=leve)
          legClassification_tmp=legClassification #[leve]
          
          if (Cas==3 | Cas==4)
          {
            # pas de balayage, moyenne de balayage, pente maxi acceptée au début
            pasb=c(Masque2$CE_BalPas,Masque2$CE_BalFen,Masque2$CE_PenteMax)
            
            # Il faudra tester dans les cas avec une très grande densité de points en eau
            #densité
            # sinon avec les points de berge
            PtsCSV_sf=st_sf(cbind(PtsCSV,geometry=st_cast(st_sfc(geometry=st_multipoint(x = as.matrix(PtsCSV[,1:3]), dim = "XYZ")),"POINT")))
            
            st_crs(PtsCSV_sf)=st_crs(nEPSG)
            PtsCSV_sf$Distance1=st_distance(PtsCSV_sf,trhydro)
            PtsCSV_sf$Distance2=NA
            
            trhydro_Pts=st_cast(st_segmentize(trhydro,reso),"POINT")
            trhydro_Pts$Distance2=1:dim(trhydro_Pts)[1]
            #### gestion de la distance 2 pour diviser par la résolution
            cat("st_nearest_feature","cela peut être long","\n")
            PtsCSV_sf$Distance2=st_nearest_feature(PtsCSV_sf,trhydro_Pts)
            PtsCSV_sf$Distance3=PtsCSV_sf$Distance2*reso
            cat("st_nearest_feature","fini","\n")
          }
          
          ################################################################
          # s'il y a une classification sol
          if (length(which(sort(as.numeric(unique(PtsCSV$Classification)))==2)))
          {
            altitude=data.frame(Z=as.numeric(sort(PtsCSV$Z[which(as.numeric(PtsCSV$Classification)==2)])))
          }else{
            altitude=data.frame(Z=as.numeric(sort(PtsCSV$Z)))
          }
          cat("Min",min(altitude),"Max",max(altitude),"\n")
          ################################################################
          # Cas de la mer ou des plans intérieurs
          if (Cas==1 | Cas==2| Cas==3)
          {
            ######################################################################################
            # pour des tests de choix de PourcPtsBas
            # for (PourcPtsBas in seq(0.05,1,0.05))
            # {
            # altitude=data.frame(Z=as.numeric(sort(PtsCSV$Z[which(as.numeric(PtsCSV$Classification)==2)])))
            ######################################################################################
            
            #ON PEUT GERER FACILEMENT AVEC LES BERGES POUR PLAN EAU INTERIEUR ET MOYEN POINT EAU POUR LA MER A VOIR AVEC 1ER TESTS
            
            #Récupération d'un morceau des altitudes basses avec PourcPtsBas
            altitude=data.frame(Z=altitude[1:(round(dim(altitude)[1])*PourcPtsBas),])
            # Analyse des points et détections de artefacts
            TestBoxPlot=boxplot.stats(altitude$Z)
            print(TestBoxPlot$stats[1])
            # Altitude minimales hors atefacts/horsains des points virtuels
            print(Masque2$ValPlanEAU)
            
            AltPtsVirtuels=ifelse(Masque2$ValPlanEAU>-99.99,
                                  as.numeric(Masque2$ValPlanEAU),
                                  round(TestBoxPlot$stat[Masque2$NumCourBox],2))
            CoulPtsVirtuels=ifelse(Masque2$ValPlanEAU>-99.99,
                                   "red",
                                   "magenta")
            
            # Nom titre graph et export
            # raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],PourcPtsBas*100,"pcbas",sep="_")
            
            # Graphique Boxplot
            Gp1=ggplot(altitude, aes(y=Z)) + 
              geom_boxplot()+
              annotate("text",x = 0, y = AltPtsVirtuels, label = AltPtsVirtuels, hjust=0.5,vjust=0.5,size=8,color=CoulPtsVirtuels)+
              xlab(NULL)+
              # ggtitle(label = raci_exp)+
              theme(axis.text=element_text(size=10),
                    axis.text.x = element_blank(),
                    axis.ticks.x=element_blank(),
                    axis.title=element_text(size=10,face="bold"),
                    title =element_text(size=10, face='bold'),
                    panel.grid.minor.x = element_blank(),
                    panel.grid.major.x = element_blank())
            # On n'affiche que 1 millions de points au maximum
            nmaxpointaff=1000000
            coup=max(1,round(dim(PtsCSV)[1]/nmaxpointaff))
            npts=seq(1,dim(PtsCSV)[1],coup)
            
            if (Cas==1 | Cas==2)
            {
              # Graphique coupe en X et Z
              Gp2=ggplot(PtsCSV[npts,],aes(X,Z))+
                geom_point(aes(color=Classification2),size=0.5)+
                xlim(min(PtsCSV$X),max(PtsCSV$X))+
                # ylim(AltPtsVirtuels-1,AltPtsVirtuels+3)+
                scale_color_manual(values = legClassification_tmp[as.numeric(levels(PtsCSV$Classification2))])+
                geom_hline(aes(yintercept=AltPtsVirtuels),color=CoulPtsVirtuels)+
                theme(legend.title=element_blank(),legend.position = "right")
              
              # Graphique coupe en Y et Y
              Gp3=ggplot(PtsCSV[npts,],aes(Y,Z))+
                geom_point(aes(color=Classification2),size=0.5)+
                xlim(min(PtsCSV$Y),max(PtsCSV$Y))+
                # ylim(AltPtsVirtuels-1,AltPtsVirtuels+3)+
                scale_color_manual(values = legClassification_tmp[as.numeric(levels(PtsCSV$Classification2))])+
                geom_hline(aes(yintercept=AltPtsVirtuels),color=CoulPtsVirtuels)+
                theme(legend.title=element_blank(),legend.position = "right")
            }
            
            if(Cas==3)
            {
              Gp4=ggplot()+
                geom_point(data=PtsCSV_sf,aes(x=Distance3,y=Z,colour=Classification2),size=0.25)+
                scale_color_manual(values = legClassification_tmp[as.numeric(levels(PtsCSV_sf$Classification2))])+
                geom_hline(aes(yintercept=AltPtsVirtuels),color=CoulPtsVirtuels)+
                xlim(min(PtsCSV_sf$Distance3),max(PtsCSV_sf$Distance3))+  
                theme(legend.title=element_blank(),legend.position = "right")
            }
            
            Gp0=ggplot()+
              geom_rect(aes(x=0:1, y=0:1, geom="blank")+xlim(0,1)+ylim(0,1))+
              annotate("text",x = 0.5, y = 0.5,
                       label = paste(raci_exp,"-  FILINO:",Masque2$FILINO,
                                     "- NPointsEAU:", length(which(PtsCSV$Classification==9)),"/",nbEAUIni,
                                     "- NAutresPoints:", length(which(PtsCSV$Classification!=9))),
                       hjust=0.5,vjust=0.5,size=3)+
              theme(panel.background = element_blank())+
              xlab(NULL)+ylab(NULL)+theme(axis.ticks=element_blank(),axis.text = element_blank())
            
            
            # Niveau des points Eau
            MoyEAU=round(mean(PtsCSV$Z[which(PtsCSV$Classification2==9)]),2)
            if(is.na(mean(PtsCSV$Z[which(PtsCSV$Classification2==10)])==F))
            {
              Gp1=Gp1+
                geom_hline(aes(yintercept=MoyEAU),color="cyan")+
                annotate("text",x = 0, y = MoyEAU, label = MoyEAU, hjust=0.5,vjust=0.5,size=8,color="cyan")+
                xlab(NULL)
              if (Cas==1 | Cas==2)
              {
                Gp2=Gp2+
                  geom_hline(aes(yintercept=MoyEAU),color="cyan")
                Gp3=Gp3+
                  geom_hline(aes(yintercept=MoyEAU),color="cyan")
              }
              if(Cas==3)
              {
                Gp4=Gp4+
                  geom_hline(aes(yintercept=MoyEAU),color="cyan")
              }
            }
            
            jpeg(filename = file.path(rep_COURSEAU,paste0(raci_exp,".jpg")), width = 32, height = 18, units = "cm", quality = 75, res = 300)
            if (Cas==1 | Cas==2)
            {
              Gp2b=Gp2+
                ylim(TestBoxPlot$stats[1]-0.5,TestBoxPlot$stats[5]+0.5)
              
              Gp3b=Gp3+
                ylim(TestBoxPlot$stats[1]-0.5,TestBoxPlot$stats[5]+0.5)
              
              mise_en_page3=matrix(c(1,1,1,1,1,1,1,2,3,3,3,4,4,4,2,3,3,3,4,4,4,2,3,3,3,4,4,4,2,3,3,3,4,4,4,2,5,5,5,6,6,6,2,5,5,5,6,6,6,2,5,5,5,6,6,6,2,5,5,5,6,6,6),
                                   9, 7, byrow = TRUE)
              cat("Le plot est parfois long","\n")
              multiplot(Gp0,Gp1,Gp2,Gp3,Gp2b,Gp3b,layout=mise_en_page3)
              cat("Le plot est fini","\n")
            }else{
              
              Gp4b=Gp4+
                ylim(TestBoxPlot$stats[1]-0.5,TestBoxPlot$stats[5]+0.5)
              
              mise_en_page3=matrix(c(1,1,1,1,1,1,1,2,3,3,3,3,3,3,2,3,3,3,3,3,3,2,3,3,3,3,3,3,2,3,3,3,3,3,3,2,4,4,4,4,4,4,2,4,4,4,4,4,4,2,4,4,4,4,4,4,2,4,4,4,4,4,4),
                                   9, 7, byrow = TRUE)
              cat("Le plot est parfois long","\n")
              multiplot(Gp0,Gp1,Gp4,Gp4b,layout=mise_en_page3)
              cat("Le plot est fini","\n")
            }
            dev.off()
            
            ###########################################################
            PtsVirtuels=cbind(st_coordinates(st_segmentize(Masque1,1.01*reso))[,1:2],Z=AltPtsVirtuels,Classification=CodeVirtbase+CodeVirtuels[Cas,1])
            
            # Ecriture de la valeur appliquée (surtout pour la recup pour la mer)
            nomZ=file.path(rep_COURSEAU,paste0("Type_",CodeVirtuels$Type[Cas],".txt"))
            write(AltPtsVirtuels,nomZ)
          }
          
          
          if (Cas==4)
          {
            
            nomZ=file.path(rep_COURSEAU,paste0("Type_",CodeVirtuels$Type[Cas],".txt"))
            write(-99,nomZ)
            
            PtsCSV_sf$Rive=0
            
            if (length(TRDRG)>1)
            {
              # Decoupe RDRG
              # Bug rencontré, si on coupe, on eut créer de strès nombreux masques alors que l'on veut les deux rives
              # Solution on rajoute un petit buffer autour de l'axe au masque
              Masque2_et_Axe=st_union(Masque2[,1],st_buffer(trhydro[,1],0.5*reso))
              st_write(Masque2_et_Axe,file.path(rep_COURSEAU,"Masque2_et_Axe.gpkg"),delete_layer=TRUE)
              # On coupe avec un buffer plus petit autour de l'axe et un buffer plus grand au deux extrémité
              CoupCoup=st_union(rbind(st_buffer(trhydro[,1],0.25*reso),
                                      st_buffer(st_boundary(trhydro[,1]),1*reso)))
              
              
              MasqueRDRG=st_cast(st_difference(Masque2_et_Axe,CoupCoup),"POLYGON")
              # sicela plante là
              if (dim(MasqueRDRG)[1]!=2)#{browser()}
                # plot(MasqueRDRG[,1])
                # st_write(MasqueRDRG,file.path(rep_COURSEAU,paste0("MasqueRDRG_",racilayerTA,".gpkg")),delete_layer=TRUE)
                st_write(MasqueRDRG,file.path(rep_COURSEAU,"MasqueRDRG.gpkg"),delete_layer=TRUE)
              # 
              
              for (iRive in c(1,2))
              {
                nbR=st_intersects(PtsCSV_sf,MasqueRDRG[iRive,])
                n_intR = which(sapply(nbR, length)>0)
                if (length(n_intR)>0){PtsCSV_sf$Rive[n_intR]=iRive}
              }
              # st_write(PtsCSV_sf,file.path(rep_COURSEAU,paste0("PtsCSV_",racilayerTA,"sf.gpkg")),delete_layer=TRUE)
            }
            st_write(PtsCSV_sf,file.path(rep_COURSEAU,paste0("PtsCSV_sf.gpkg")),delete_layer=TRUE)
            
            classes=sort(unique(PtsCSV_sf$Classification))
            
            
            # PtsCSV_sf$Classification2=factor(PtsCSV_sf$Classification,levels=sort(unique(PtsCSV_sf$Classification)))
            PtsCSV_sf$Classification2=factor(PtsCSV_sf$Classification,levels=ClassesUtilisees)
            
            # prinicpe majeur de balayage et d'application de boxplot
            balayage=seq(max(min(PtsCSV_sf$Distance2),pasb[1]+1)-pasb[1],max(PtsCSV_sf$Distance2)+pasb[1],pasb[1])
            
            Rives=data.frame(balayage=balayage,Rives_1_et_2=0*balayage,Rives_1=0*balayage,Rives_2=0*balayage)
            
            colo=cbind("green","magenta","red")
            xlabt=cbind("Distance3 - Toutes les rives","Distance3 - Rive 1","Distance3 - Rive 2")
            
            for (igp in TRDRG)
            {
              print(igp)
              #data
              if (igp==1){PtsCSV_sf_tmp=PtsCSV_sf}
              if (igp==2){PtsCSV_sf_tmp=PtsCSV_sf[which(PtsCSV_sf$Rive==1),]}
              if (igp==3){PtsCSV_sf_tmp=PtsCSV_sf[which(PtsCSV_sf$Rive==2),]}
              
              NUNIEAU=data.frame(balayage=balayage,
                                 stats1=9999,
                                 stats2=9999,
                                 stats3=9999,
                                 stats4=9999,
                                 stats5=9999,
                                 Pente1=-99,
                                 Pente2=-99)
              
              for (ibal in 1:dim(NUNIEAU)[1])
              {
                balay=NUNIEAU[ibal,1]
                nptsLidar=which(PtsCSV_sf_tmp$Distance2>=balay-pasb[2] & PtsCSV_sf_tmp$Distance2<=balay)
                
                if (length(nptsLidar)>0)
                {
                  if (length(nptsLidar)>min(NptsMINI))
                  {
                    if ((length(which(PtsCSV_sf_tmp[nptsLidar,]$Classification2==1))>NptsMINI[1] |
                         length(which(PtsCSV_sf_tmp[nptsLidar,]$Classification2==2))>NptsMINI[2]|
                         length(which(PtsCSV_sf_tmp[nptsLidar,]$Classification2==9))>NptsMINI[3])==TRUE)
                    {
                      TestBoxPlotN=boxplot.stats(PtsCSV_sf_tmp[nptsLidar,]$Z)
                      NUNIEAU[ibal,2:6]=TestBoxPlotN$stats
                    }
                  }else{
                    # browser()
                  }
                }
              }
              for (icol in 2:6)
              {
                NUNIEAU[which(NUNIEAU[,icol]==9999),icol]=NUNIEAU[which(NUNIEAU[,icol]<9999)[1],icol]
              }
              
              # Pente descendante à partir des points consideré correct
              if (Cas==4)
              {
                NUNIEAU$Pente1=sapply(1:dim(NUNIEAU)[1], function(x) {min(NUNIEAU[1:x,1+Masque2$NumCourBox], na.rm = TRUE)})
                
              }
              # {NUNIEAU$Pente1=sapply(1:dim(NUNIEAU)[1], function(x) {min(NUNIEAU$stats1[1:x], na.rm = TRUE)})}
              
              if (Cas==3)
              {
                NUNIEAU$Pente1=sapply(balayage, function(x) {min(PtsCSV_sf_tmp$Z[which(PtsCSV_sf_tmp$Distance2<=x)], na.rm = TRUE)})
                NUNIEAU$Pente2=sapply(balayage, function(x) {min(PtsCSV_sf_tmp$Z[which(PtsCSV_sf_tmp$Distance2>=x)], na.rm = TRUE)})
              }
              
              # PAS HYPER SUR DANS TOUS LES CAS
              # Travail sur le début de la courbe avec une pente max autorisée
              nbug=is.infinite(NUNIEAU$Pente1)
              NUNIEAU$Pente1[nbug]=NA
              
              ndebAVerif=length(which(nbug))
              ndebAVerif=(ndebAVerif+1):(ndebAVerif+pasb[1])
              npb=which(NUNIEAU$Pente1[ndebAVerif]>(NUNIEAU$Pente1[max(ndebAVerif)+1]+pasb[1]*pasb[3]))
              NUNIEAU$Pente1[ndebAVerif[npb]]=NA
              NUNIEAU$Pente1[is.na(NUNIEAU$Pente1)]=max(NUNIEAU$Pente1, na.rm = TRUE)
              
              # Retour en distance et pas incrément
              NUNIEAU$distance=NUNIEAU$balayage*reso
              
              # if (Masque2$ValPlanEAU>-99.99)
              # {NUNIEAU$Pente1=min(NUNIEAU$Pente1,Masque2$ValPlanEAU)}
              
              Rives[,igp+1]=NUNIEAU$Pente1
              # Retour en distance et pas incrément
              Rives$distance=Rives$balayage*reso
              
              if (Masque2$ValPlanEAU>-99.99)
              {
                Rives$Rives_1_et_2=pmin(Rives$Rives_1_et_2,as.numeric(Masque2$ValPlanEAU))
              }
              
              if (length(TRDRG)>1)
              {
                Gp=ggplot()
                Gp=Gp+
                  geom_point(data=PtsCSV_sf_tmp,aes(x=Distance3,y=Z,colour=Classification2),size=0.5)+
                  scale_color_manual(values = legClassification_tmp[as.numeric(levels(PtsCSV_sf_tmp$Classification2))])+
                  geom_line(data=NUNIEAU,aes(x=distance,y=Pente1),color=colo[igp],linetype="solid",size=1)
                if (Cas==3)
                {
                  Gp=Gp+ 
                    geom_line(data=NUNIEAU,aes(x=distance,y=Pente2),color=colo[igp],linetype="dotdash",size=1)
                }
                Gp=Gp+  
                  geom_line(data=NUNIEAU,aes(x=distance,y=stats1),color="black",linetype="solid",size=0.25)+
                  geom_line(data=NUNIEAU,aes(x=distance,y=stats2),color="black",linetype="solid",size=0.25)+
                  geom_line(data=NUNIEAU,aes(x=distance,y=stats3),color="black",linetype="solid",size=0.25)+
                  geom_line(data=NUNIEAU,aes(x=distance,y=stats4),color="black",linetype="solid",size=0.25)+
                  geom_line(data=NUNIEAU,aes(x=distance,y=stats5),color="black",linetype="solid",size=0.25)+
                  xlim(min(NUNIEAU$distance),max(NUNIEAU$distance))+
                  ylim(min(NUNIEAU$Pente1)-0.25,max(NUNIEAU$Pente1)+0.5)+
                  xlab(xlabt[igp])+
                  theme(legend.title=element_blank(),legend.position = "right")
                
                # if (length(TRDRG)==1)
                # {
                Gp=Gp+  
                  annotate("text",x = Rives$distance[1], y = Rives$Rives_1_et_2[1], 
                           label = Rives$Rives_1_et_2[1], hjust=1,vjust=1,size=4,color="green")+
                  annotate("text",x = Rives$distance[dim(Rives)[1]], y = Rives$Rives_1_et_2[dim(Rives)[1]],
                           label = Rives$Rives_1_et_2[dim(Rives)[1]], hjust=0,vjust=1,size=4,color="green")
                # }
                if (igp==1){Gp1=Gp}
                if (igp==2){Gp2=Gp}
                if (igp==3){Gp3=Gp}
              }
            }
            
            # if (length(TRDRG)>1)
            # {
            Gp4=ggplot()+
              geom_point(data=PtsCSV_sf,aes(x=Distance3,y=Z,colour=Classification2),size=0.25)+
              scale_color_manual(values = legClassification_tmp[as.numeric(levels(PtsCSV_sf_tmp$Classification2))])
            if (length(TRDRG)>1)
            { 
              Gp4=Gp4+
                geom_line(Rives,mapping=aes(x=distance,y=Rives_1),color=colo[2],linetype="solid",size=0.75)+
                geom_line(Rives,mapping=aes(x=distance,y=Rives_2),color=colo[3],linetype="solid",size=0.75)+
                ylim(min(Rives$Rives_1_et_2, na.rm = TRUE)-0.25,max(Rives$Rives_1_et_2, na.rm = TRUE)+0.5)
            }else{
              Gp4=Gp4+
                geom_line(data=NUNIEAU,aes(x=distance,y=stats1),color="black",linetype="solid",size=0.25)+#20240306
                geom_line(data=NUNIEAU,aes(x=distance,y=stats2),color="black",linetype="solid",size=0.25)+#20240306
                geom_line(data=NUNIEAU,aes(x=distance,y=stats3),color="black",linetype="solid",size=0.25)+#20240306
                geom_line(data=NUNIEAU,aes(x=distance,y=stats4),color="black",linetype="solid",size=0.25)+#20240306
                geom_line(data=NUNIEAU,aes(x=distance,y=stats5),color="black",linetype="solid",size=0.25)+#20240306
                ylim(min(Rives$Rives_1_et_2, na.rm = TRUE)-0.25,max(NUNIEAU$Pente1, na.rm = TRUE)+0.5)
            }
            
            Gp4=Gp4+  
              geom_line(Rives,mapping=aes(x=distance,y=Rives_1_et_2),color=colo[1],linetype="solid",size=1.25)+
              xlim(min(NUNIEAU$distance),max(NUNIEAU$distance))+
              theme(legend.title=element_blank(),legend.position = "right")+
              annotate("text",x = Rives$distance[1], y = Rives$Rives_1_et_2[1], 
                       label = Rives$Rives_1_et_2[1], hjust=1,vjust=1,size=4,color="green")+
              annotate("text",x = Rives$distance[dim(Rives)[1]], y = Rives$Rives_1_et_2[dim(Rives)[1]],
                       label = Rives$Rives_1_et_2[dim(Rives)[1]], hjust=0,vjust=1,size=4,color="green")
            # }
            # raci_exp=paste(basename(rep_COURSEAU),racilayerTA,"Cas",CodeVirtuels[Cas,1],CodeVirtuels[Cas,2],sep="_")
            
            
            Gp0=ggplot()+
              geom_rect(aes(x=0:1, y=0:1, geom="blank")+xlim(0,1)+ylim(0,1))+
              annotate("text",x = 0.5, y = 0.5,
                       label = paste(raci_exp,"-  FILINO:",Masque2$FILINO,
                                     "- NPointsEAU:", length(which(PtsCSV$Classification==9)),"/",nbEAUIni,
                                     "- NAutresPoints:", length(which(PtsCSV$Classification!=9))),
                       hjust=0.5,vjust=0.5,size=3)+
              theme(panel.background = element_blank())+
              xlab(NULL)+ylab(NULL)+theme(axis.ticks=element_blank(),axis.text = element_blank())
            
            jpeg(filename = file.path(rep_COURSEAU,paste0(raci_exp,".jpg")), width = 32, height = 18, units = "cm", quality = 75, res = 300)
            
            cat("Le plot est parfois long","\n")
            if (length(TRDRG)>1)
            {
              mise_en_page3=matrix(c(1,2,2,3,3,4,4,5,5),
                                   9, 1, byrow = TRUE)
              multiplot(Gp0,Gp1,Gp2,Gp3,Gp4,layout=mise_en_page3)
            }else{
              mise_en_page3=matrix(c(1,2,2,2,2,2,2,2,2),
                                   9, 1, byrow = TRUE)
              multiplot(Gp0,Gp4,layout=mise_en_page3)
            }
            cat("Le plot est fini","\n")
            dev.off()
            
            PtsVirtuels_sf=st_cast(st_cast(st_cast(st_segmentize(Masque1,1.01*reso),"MULTILINESTRING"),"LINESTRING"),"POINT")
            PtsVirtuels_sf$balayage=st_nearest_feature(PtsVirtuels_sf,trhydro_Pts[Rives$balayage,])
            PtsVirtuels_sf$Z=Rives$Rives_1_et_2[PtsVirtuels_sf$balayage]
            
            PtsVirtuels=cbind(st_coordinates(PtsVirtuels_sf)[,1:2],Z=PtsVirtuels_sf$Z,Classification=CodeVirtbase+CodeVirtuels[Cas,1])
          }
        }
        write.csv(PtsVirtuels,file=nomPtsVirt,quote=FALSE,row.names = FALSE)
      }else{
        st_write(Masque2,file.path(rep_COURSEAU,paste0("PERTE_de_Type_a_reprendre_manuellement.gpkg")),delete_layer=TRUE)
      }
    }
  }
}