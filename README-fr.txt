# Mod Minetest : Mesecons Remote

Par Luffy0805
Version : 1.0.0
Licence : MIT

---

---

## Installation

1. Placer le dossier du mod dans le répertoire `mods/`
2. Activer le mod dans le monde souhaité
3. Le mod `mesecons` est obligatoire

---

## Description

Ce mod permet aux joueurs de **contrôler des récepteurs à distance** grâce à une télécommande (`remote`).
Chaque récepteur possède un **ID unique** et peut être activé ou désactivé en mode **bouton** (momentary) ou **levier** (toggle).

La configuration des canaux de la télécommande est **mémorisée dans son inventaire** et peut être modifiée via un formulaire de configuration.
Les récepteurs affichent leur état actuel (`ON` ou `OFF`) directement dans leur infotext.

---

## Fonctionnalités

* Récepteurs distants `ON/OFF` pour Mesecons
* Formulaire de configuration accessible en faisant `Aux1 + lic gauche`  avec la télécommande
* Télécommande configurable avec **4 canaux** :

  * Left Click
  * Right Click
  * Shift+Left Click
  * Shift+Right Click
* Modes : **bouton** (3 secondes) ou **levier** (toggle)
* Affichage dynamique de l'état des récepteurs
* Stockage automatique des récepteurs dans le fichier du monde
* Commande chat `/receiver <ID>` pour localiser un récepteur par ID

---

## Commandes

```bash
/receiver <ID>
```

* Affiche la position et l’état (`ON/OFF`) du récepteur correspondant à l’ID fourni.
* Exemple : `/receiver R0001` → `Receiver R0001 : (x, y, z), ON`

---

## Télécommande

* **Left Click** → Active le canal gauche
* **Right Click** → Active le canal droit
* **Shift+Left Click** → Active le 3e canal
* **Shift+Right Click** → Active le 4e canal
* **Ctrl/Shift+Click** → Accès au formulaire de configuration
* Configuration des canaux et des modes via formulaire

---

## Stockage & persistance

* Les récepteurs sont sauvegardés automatiquement dans `mesecons_remote_receivers.data` dans le répertoire du monde
* Les IDs des récepteurs sont **normalisés** (ex : R0001)
* Les récepteurs détruits sont automatiquement supprimés de la base de données

---

## Structure recommandée

```
mods/
└── mesecons_remote/
    ├── mod.conf
    ├── init.lua
    ├── README-fr.txt
    ├── README.md
    ├── textures/
    │   ├── receiver_off.png
    │   ├── receiver_on.png
    │   └── remote.png
```

---

## Remarques

* Tous les sons et textures doivent être compatibles avec Minetest
* Le mod fonctionne uniquement avec Mesecons activé
* Les IDs sont uniques et générés automatiquement
* Le volume des sons et les paramètres Mesecons peuvent être modifiés dans le code

---

## Licence

Code : MIT
Media License: CC0 1.0 Universal
Note: Toutes les textures ont été généré par l'IA
