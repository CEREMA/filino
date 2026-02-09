# Notice d’Installation de Filino
*(Février 2026)*
**Compatibilité** : Windows uniquement
**Langue** : Français

---

### 1. Prérequis
Avant de commencer, assurez-vous :
- D’avoir les **droits d’administration** sur votre machine.
- D’utiliser un **système d’exploitation Windows**.

---

### 2. Installation de QGIS
- Téléchargez et installez **QGIS** depuis : [https://qgis.org/](https://qgis.org/)
  **Chemin d’installation recommandé** : `C:\QGIS`
- **Attention** : Si le fichier `grassxxx.bat` appelé dans FILINO ne fonctionne pas correctement, installez **GRASS GIS** depuis : [https://grass.osgeo.org/](https://grass.osgeo.org/).
- Il peut être utile d'installer [ffmpeg](https://www.ffmpeg.org/) par l'intermédiaire du plugin [crayfish](https://plugins.qgis.org/plugins/crayfish/) (production de vidéo)

---

### 3. Installation de R et RStudio
- Téléchargez et installez **R** (dernière version) depuis : [https://cran.r-project.org/bin/windows/base/](https://cran.r-project.org/bin/windows/base/)
  **Chemin d’installation** : `C:\R\R-x.x.x`
- Téléchargez et installez **RStudio** depuis : [https://posit.co/download/rstudio-desktop/](https://posit.co/download/rstudio-desktop/)
  **Chemin d’installation** : `C:\RStudio`
- Installez **Rtools** depuis : [https://cran.r-project.org/bin/windows/Rtools/](https://cran.r-project.org/bin/windows/Rtools/). Attention, à chaque mise à jour de **R**, vous devrez mettre à jour **Rtools**
- Copiez les sources ce dépôt github dans un dossier **Cerema** (contenant les codes R) dans `C:\R\R-x.x.x`, puis :
  - Extrayez son contenu.
  - Renommez le dossier extrait en **Cerema**.
- Quelques astuces R-Studio
	- si vous voulez arrêter votre calcul 'Ctrl-C'
	- si vous voulez savoir où une variable est utilisée dans des fichiers 'Crtl-Shift-F' permet une recherche

---

### 4. Installation de TauDEM
- Téléchargez **TauDEM** (version complète) depuis : [https://hydrology.usu.edu/taudem/taudem5/downloads.html](https://hydrology.usu.edu/taudem/taudem5/downloads.html)
- Installez-le dans le répertoire suivant :
  **Chemin d’installation** : `C:\TauDEM`
- Lors de l’installation, choisissez l’option :
  **Type de configuration** : *Typical*
- l’**antivirus bloque l’exécutable TauDEM** de manière fréquente sous Windows. Sur les essais Cerema, TauDEM537_setup.exe fonctionne, TauDEM540_setup_x64.exe est bloqué

---

### 5. Vérification finale
- **Redémarrez votre machine** pour appliquer toutes les modifications.
- Vérifiez que tous les logiciels sont accessibles depuis leurs chemins respectifs.

---

### 6. Création d'un répertoire de stockage des nuages de points Lidar
- Créez un dossier vide nommé **StockageLidar** sur un disque
  **Exemple** : `D:\StockageLidar`

---

### 7. Création d'un répertoire de travail FILINOxxx
- Créez un dossier vide nommé **Filino_xxx** sur un disque (SSD à privilegier)
  **Exemple** : `E:\FILINO_xxx`
- dans ce dossier, décompresser [00_SIGBase_et_ZaT_TM.zip](https://github.com/CEREMA/filino/releases).
	- Le dossier SIG contient des projets type et des symbologies/actions (type qml de Qgis). Vous pouvez les modifier si besoin.
	- Le fichier Zone_a_traiterxxx est un exemple de zone à traiter, à vous de créer un polygone sur votre zone d'intérêt
	- Le fichier Travail_Manuel. Et oui, tout n'est pas automatique, quelques exemples de `travail manuel` sont disponibles sur le fichier avec le code qu'il faut absolument respecté (minuscules et majuscules). Le Cerema est intéressé pour récupérer vos ajouts à ce fichier.

---

### 8. Lancement de FILINO
- Allez dans `C:\R\R-x.x.x\Cerema\FILINO` et lancez **FILINO__Run**.
- **RStudio** s’ouvrira automatiquement.
- Dans l’interface, installez les librairies demandées.
- Cliquez sur **Source** pour commencer à utiliser FILINO de manière autonome.
- Les fichiers utilisateurs sont à modifier manuellement dans le dossier
	- `FILINO__User_LienOutilsPC.R`
	- `FILINO__User_Parametres.R`
	- `FILINO__User_Chemin_et_Nom_xxx.R` - seul le xxx peut être modifié, plusieurs fichiers peuvent co-exister

---

**Remarque** :
Les utilisateurs sont invités à suivre ces instructions avec attention pour une installation réussie. **Aucune hotline n’est fournie.**
Les auteurs ne s’engagent pas à prendre en compte les demandes externes et ne sont pas responsables des données produites par les utilisateurs.

Bonne utilisation !
