# Explications Rapides des Menus de FILINO

## Prérequis

Avant de commencer, il est nécessaire de télécharger la **table d'assemblage des nuages de points de l'IGN** avec la routine **`FILINO_Charge_WFS.R`**. Cette étape permet de disposer des liens URL et des noms des dalles.

Avec votre fichier `zone_de_travail`, vous allez télécharger uniquement les données nécessaires. Vous pouvez aussi charger les données sur le site de l'IGN, mais attention, les noms entre le site et ce fichier WFS peuvent parfois différer.

Il est conseillé de se rendre régulièrement sur le site [Expertise et Territoire LiDAR HD](https://www.expertises-territoires.fr/jcms/pl1_562084/fr/communaute-lidar-hd) pour vérifier les mises à jour.

---

## Menu des Traitements LiDAR et MNT

Voici la liste des options disponibles pour le traitement des données LiDAR et la création de Modèles Numériques de Terrain (MNT).

---

### 1. Téléchargement et Préparation des Données LiDAR

**01_00b. Téléchargement des données LiDARHD classifiées IGN**
- **Description** : Téléchargement des données LiDAR haute densité (LiDARHD) au format `copc.laz` classifiées fournies par l'IGN.
- **Objectif** : Obtenir les fichiers LAZ ou LAS classifiés (sol, végétation, bâtiments, etc.) pour une zone d'étude.

---

**02_00c. Table d'assemblage des données LiDAR (LAZ)**
- **Description** : Création d'une table d'assemblage pour les fichiers `copc.laz`. Une option permet de calculer le nombre de points de chaque dalle. En fonction des dalles, un ou plusieurs vols ont pu avoir lieu, ce qui entraîne parfois un très grand nombre de points. Ce fichier peut aider à limiter ou augmenter le nombre de processeurs de calcul utilisables en fonction de votre matériel informatique.
- **Objectif** : Organiser et référencer les fichiers LiDAR pour faciliter leur traitement ultérieur.
- **Utilité** : Permet de faire la table d'assemblage des données chargées précédemment et de calculer le nombre de points dans chaque dalle. Ce nombre de points est intéressant pour déterminer sur combien de processeurs lancer l'étape de création des MNT (étape 11_07).
- **La table d'assemblage dispose d'un style défini avec des actions QGIS** : en cliquant sur un polygone, le fichier `copc.laz` associé à ce polygone s'ouvre.

---

### 2. Masques

**03_01a. Masques Vides et Eau / Ponts / Végétation trop dense par dalles**
- **Description** : Création de masques pour les zones VIDES/EAU, les PONTS et la VÉGÉTATION TROP DENSE.
- **Objectif** : Identifier les zones problématiques pour le traitement des données LiDAR.
- **Il est préférable, si possible, de lancer ces calculs sur plusieurs processeurs**. Il se peut que les calculs "plantent". Vous pouvez relancer avec moins de processeurs et un dernier coup lancé sans mode parallèle pour être sûr du résultat.
- **Des fichiers BUG sont créés dans le répertoire de stockage de votre LiDAR**, indiquant un problème. Les supprimer si vous souhaitez relancer sur ces dalles.

---

**04_01b. Masques Fusion des masques et identification avec BDTopo (étape manuelle avant 1c)**
- **Description** : Fusion des masques VIDES/EAU créés précédemment et identification avec la BDTopo.
- **Objectif** : Combiner les masques et les appareiller avec des données de référence (BDTopo), pour définir les quatre types ECOULEMENT, MER, PLAN D'EAU et CANAUX.

---
Dans votre SIG **QGIS**, entre les deux menus,
**Travail manuel à réaliser pour reprendre l'appareillage automatique avec la BDTopo**
- Ouvrir le fichier `Masques.qgs` créé à l'étape précédente qui permet de disposer de nombreux styles (refermer le projet pour les étapes ultérieures).
- Utiliser le fichier `Travail_Manuelxxx`.

---

**05_01c. Masques Relations des masques 2 (un peu plus large) et 1 (bords sur lesquels des points virtuels sont créés)**
- **Description** : Modification des types des masques avec le travail manuel précédent et création de relations entre les masques de type 2 (plus larges) et de type 1 (bords pour points virtuels).
- **Objectif** : Préparer les masques dits "masque2" aux bords des zones VIDE/EAU pour les calculs de leur altitude et création des masques dits "masque1" pour affecter ces altitudes sur des points virtuels.
- Ouvrir le fichier `Masques.qgs` pour voir les nouveautés.

---

### 3. Extraction et Traitement des Points

**06_02ab. SurfEau Extraction des points LiDAR des masques 2 et calculs des points virtuels**
- **Description** : Extraction des points LiDAR dans les zones VIDE/EAU de type 2 et calcul des points virtuels appliqué aux masques de type 1.
- **Objectif** : Créer des points virtuels pour combler les zones VIDE/EAU et améliorer la précision du MNT.
- **De nombreux dossiers et fichiers sont créés**. Des fichiers `copc.laz` sont créés avec des numéros de classifications dépendant de leur type.

---

**07_05a. Récupération Sol ancien d'autres LiDAR dans la végétation trop dense**
- **Description** : Récupération des données de sol à partir d'autres jeux de données LiDAR dans les zones de végétation trop dense.
- **Objectif** : Améliorer la précision du MNT dans les zones où la végétation dense empêche une bonne détection du sol pour le LiDARHD.
- **De nombreux fichiers `copc.laz` avec les "vieux sols" sont créés**. Un changement de numéro de classification est appliqué.

---

### 4. Tables d'Assemblage

**08_06. Table d'assemblage des points virtuels (à refaire après 09_03 et 10_04)**
- **Description** : Création d'une table d'assemblage pour les points virtuels créés précédemment.
- **Objectif** : Organiser les points virtuels pour leur intégration dans le MNT.
- **Un fichier est créé, vous pouvez l'ouvrir dans QGIS**. Un style lui est associé avec des actions qui permettent d'ouvrir les fichiers `laz` ou le répertoire pour voir en détail les calculs effectués.

---

### 5. Traitements en réflexion depuis 2023...

**09_03. NON FAIT Gestion des thalwegs secs (voir travaux avec Univ G.Eiffel)**
- Non fonctionnel.

---

**10_04. En COURS DE DVT - Traitement des ponts**
- Non fonctionnel.

---

### 6. Création du MNT

**11_07. MNT TIN s'appuyant sur TA LiDARHD et TA virtuels**
- **Description** : Création d'un MNT par triangulation (TIN) à partir des tables d'assemblage LiDARHD et des points virtuels.
- **Objectif** : Générer un MNT précis en utilisant les données LiDAR et les points virtuels. Il est possible d'y associer des calculs de cuvettes, très utiles pour voir les obstacles à l'écoulement.
- **Le nombre de points dans chaque dalle, calculé à l'étape 02_00c, peut permettre de déterminer le nombre de processeurs à utiliser pour cette étape**.

---

### 7. Statistiques et Assemblage Raster

**12_08. MNT Statistiques Raster (non continu)**
- **Description** : Calcul de statistiques raster (ex : MNT sol, MNT bâtiments, MNT végétation, Nombre d'impulsions, etc.).
- **Objectif** : Produire des couches raster spécifiques pour différentes classes de données.

---

**13_00c. Table d'assemblage des données Raster (TIF ou GPKG)**
- **Description** : Création d'une table d'assemblage pour les données raster (TIF ou GPKG) créées lors des MNT ou des statistiques.
- **Objectif** : Organiser les fichiers raster pour faciliter leur gestion et leur utilisation.

---

### 8. Visualisation

**14_10. Palette de couleur**
- **Description** : Création de palettes de couleur redondantes, très performantes pour voir des micro-reliefs en zones planes.
- **Objectif** : Améliorer la visualisation des données raster.

---

**15_11. Vidéos démonstration**
- **Description** : Création de vidéos de démonstration des résultats.
- **Objectif** : Présenter les résultats de manière visuelle et dynamique.
- Non utilisé depuis longtemps...

---

### 9. Création de VRT et GPKG

**16_12. Création de vrt et gpkg par zone**
- **Description** : Création de fichiers VRT et GPKG par zone d'étude.
- **Objectif** : Faciliter l'analyse des données par zone géographique.

---

### 10. Comparaison et Traitement Complémentaire

**17_12. Différences entre deux types de données**
- **Description** : Calcul des différences entre deux types de données (ex : avant/après traitement).
- **Objectif** : Évaluer les changements et les améliorations apportées par les traitements.
- **Ce calcul des différences s'appuie sur des analyses de voisins pour limiter les potentiels "décalages" entre deux LiDAR produits par plusieurs opérateurs ou à plusieurs dates**.

---

**18_13. Raster GpsTime**
- **Description** : Création de rasters basés sur le temps GPS des données LiDAR.
- **Objectif** : Permettre d'avoir très rapidement les dates de vol et SURTOUT de voir les secteurs avec des passages à plusieurs dates. Majeur sur des secteurs morphogènes (torrents, plage...).

---

**19_14. Herbe sur champs à faible relief**
- **Description** : Traitement spécifique pour détecter l'herbe sur les champs à faible relief.
- **Objectif** : Détecter les endroits où les classifications SOL sont de la végétation basse.
- Pas sûr du résultat, non utilisé depuis longtemps...

---

### 11. Gestion des Données

**20_15. Copie vers autre disques durs**
- **Description** : Copie des données vers d'autres disques durs pour sauvegarde ou partage.
- **Objectif** : Assurer la sécurité et la disponibilité des données.

---

**21_16. Ré-échantillonnage Raster**
- **Description** : Ré-échantillonnage des données raster pour adapter leur résolution.
- **Objectif** : Optimiser la taille des fichiers et adapter leur résolution aux besoins spécifiques.

---
