setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
chem_routine=getwd()
###################### PARAMETRES
# chem_routine=R.home(component = "cerema")

# Paramètre pour ne pas ouvrir les boites de dialogue
Auto=c(1,1)

# #### Masque
# source(file.path(chem_routine,"FILINO_1a_MasqueEau.R"))
Etap1b=c(1,1,1,1,1,1)
# source(file.path(chem_routine,"FILINO_1b_MasqueEau.R"))
# 
# #######################################################################
# # ATTENTIOn PASSAGE MANUEL RECOMMANDE
# source(file.path(chem_routine,"FILINO_1c_MasqueEau.R"))
# #######################################################################

# grandes surfaces d'eau
Etap2=c(1,1,1)
source(file.path(chem_routine,"FILINO_2ab_ExtraitLazGrosMasquesEau.R"))

# petits cours d'eau
# Etap3=c(1,1)
# source(file.path(chem_routine,"FILINO_3ab_ExtraitLazThalwegs.R"))

#ponts

# #forets
# I_Lidar=c(2,4) # Nimes
# source(file.path(chem_routine,"FILINO_5a_SolVieuxLazSousVege.R"))

I_Lidar=c(3,5)# Agen Bonifacio Grenoble
source(file.path(chem_routine,"FILINO_5a_SolVieuxLazSousVege.R"))

# table d'assemblage
source(file.path(chem_routine,"FILINO_6_TA_PtsVirtuelsLaz.R"))

#  Creation du MNT
source(file.path(chem_routine,"FILINO_7_CreationMNT.R"))
