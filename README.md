# **FILINO**
**FIgnolage des données Lidar pour les INOdations**

---
*Un outil développé par le CEREMA pour automatiser le traitement des données Lidar et améliorer la modélisation des inondations.*

---

## **📌 Version**
- **Dernière mise à jour** : 04/02/2026
- **Dépôt APP** : [Certificat APP (Juillet 2023)](https://secure2.iddn.org/app.server/certificate/?sn=2023240031000&key=f1b340d417b4cbd12af52d26f7bdacee869d9477484e00c394e699e761733d67&lang=fr)
- **État du projet** : En développement (évolutions possibles, pas de garantie de prise en compte des demandes externes).

---

## **📂 Contenu du dépôt**
- **Code source** : Scripts en langage **R** (`FILINO_xxx.R`).
- [**Releases** :](https://github.com/CEREMA/filino/releases)
  - [Dossiers types pour FILINO](https://github.com/CEREMA/filino/releases/tag/DossiersTypePourFILINO) (exemples de structures de données).
  - [Installation](https://github.com/CEREMA/filino/blob/main/install.md).
  - [Prise en main](https://github.com/CEREMA/filino/blob/main/Prise_Main_Rapide.md)
- [**Documentation**](https://github.com/CEREMA/filino/releases) :
  - Rapport d'étude : *"FILINO - Fignolage des données Lidar pour les INOdations"* (Juillet 2023).
  - Présentation au Club Modélisation (Juin 2023).
  - Vidéo de démonstration (cas d'usage dans l'Hérault).

---

## **🎯 Objet de FILINO**
### **Contexte**
Le programme **[LidarHD](https://geoservices.ign.fr/lidarhd)** (IGN) vise à couvrir la France entière avec des données topographiques haute précision. Cependant, le traitement manuel des limites **Terre/Eau** (mer, plans d’eau, canaux, cours d’eau) est chronophage et sujet à des erreurs.

### **Solution proposée**
**FILINO** automatise ce processus en :
- Générant des **points virtuels** classifiés par type d’objet (mer, plans d’eau, canaux, grands cours d’eau, thalwegs secs, sous-couvert végétal).
- Améliorant la qualité des **Modèles Numériques de Terrain (MNT)** pour les études d’inondation.
- Intégrant des **Lidar anciens** pour combler les lacunes du LidarHD (zones à fort couvert végétal).

### **Résultats**
Les points virtuels produits par FILINO, combinés aux données Lidar initiales, permettent d’obtenir des **MNT plus précis**, essentiels pour :
- La modélisation des inondations.
- La gestion des risques naturels.
- L’aménagement du territoire.
- Les évolutions du littoral

---

## **🔧 Description technique**
### **Fonctionnalités clés**
- **Automatisation** : Calcul des limites Terre/Eau pour 4 types d’objets (mer, plans d’eau, canaux, grands cours d’eau).
- **Multi-sources** : Gestion de plusieurs jeux de données Lidar (LidarHD + anciens Lidar).
- **Interopérabilité** : Export des résultats pour une intégration dans des logiciels comme **QGIS**, **GRASS** ou **PDAL**.
- **Réalisation de MNT précis** avec des calculs de **cuvettes**
- Autres outils de **statistiques** (Min/Max/Date...), **différences de topographie optimisée**

### **Environnement requis**
- **Système** : Windows 11 (obligatoire).
- **Matériel** : 8 à 16 Go de RAM.
- **Dépendances** :
  - **Langage** : R (librairies spécifiques listées dans le code).
  - **Logiciels** : PDAL, GRASS, QGIS.

### **Limites et responsabilités**
- **Phase de développement** : Le dépôt évoluera, mais aucune garantie n’est donnée pour les demandes externes.
- **Responsabilité** : Les auteurs ne sont pas responsables des données produites par les utilisateurs.

---

## **📚 Partenariats et collaborations**
FILINO est développé dans le cadre de :
- **Projet ANR MUFFINS** [**ANR MUFFINS**](https://anr.fr/Projet-ANR-21-CE04-0021) (Projet-ANR-21-CE04-0021) piloté par l'[**INRAE**](https://www.inrae.fr/).
- Des travaux d'**aléas inondations** pour la [**DDTM34**](https://www.herault.gouv.fr/Actions-de-l-Etat/Environnement-eau-chasse-risques-naturels-et-technologiques/Risques-naturels-et-technologiques/Transmission-des-informations-aux-maires-TIM/Les-Porter-a-connaissance-PAC-de-l-Herault/MONTPELLIER)
- **Conventions R&D** :
- [**PAPI 3 Vistre**](https://papi3.vistre-vistrenque.fr/synthese-programme) (secteur de Nîmes).
- Des conventions de R&D sur le ruissellement pour la [**Métropole Aix-Marseille-Provence**](https://deliberations.ampmetropole.fr/documents/metropole/deliberations/2023/03/16/ANNEXE/49593_49593_cerema_annexe.pdf).
- L’expérimentation de la **cartographie nationale des inondations** (DGPR).
- **Collaborations scientifiques** : IGN, Université Gustave Eiffel, INRAE.

---

## **📢 Ressources complémentaires**
- **LidarHD (IGN)** : [https://geoservices.ign.fr/lidarhd](https://geoservices.ign.fr/lidarhd)
- **Documentation R** : Voir les commentaires dans les scripts `FILINO_xxx.R`.
- **Support** : Pour toute question, ouvrir une [Issue](https://github.com/CEREMA/filino/issues) sur GitHub.

---
*© CEREMA – Dernière mise à jour : 05/02/2026*
