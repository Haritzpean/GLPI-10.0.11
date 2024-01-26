![image](https://github.com/Haritzpean/GLPI-10.0.11/assets/118851071/fc9bddea-b890-48e8-b86d-f7e241df79c5)

# GLPI-10.0.11

## Installation complète automatique 

Ce script automatisé déploie et configure une installation de ``GLPI`` ***(Gestionnaire Libre de Parc Informatique)*** sur des machines virtuelles de laboratoire.
Il met à jour la pile LAMP, installe les dépendances nécessaires, installe et configure la base de données MariaDB, télécharge et configure GLPI, 
crée un fichier de configuration Apache vhost, et effectue d'autres tâches liées à la sécurité et à la configuration du serveur web pour le déploiement de GLPI.
Il a été développé et testé sur Debian 12, et il peut également être compatible avec d'autres distributions Linux.


### Ce script s'éxécute en **``root``**

## Options du script :

- `-d` : Nom de la base de données GLPI (par défaut: glpi)
- `-u` : Nom de l'utilisateur de la base de données (par défaut: glpi)
- `-p` : Mot de passe de la base de données (par défaut: glpi)
- `-v` : Nom du fichier de configuration Apache vhost (par défaut: barzini-glpi.config)
- `-s` : Nom du serveur (par défaut: barzini-glpi)
- `-h` : Affiche cette aide

Exemple d'utilisation :

```bash
./add_glpi.sh -d ma_base -u mon_utilisateur -p mon_mot_de_passe -v mon_vhost -s mon_serveur
```
## Téléchargement et Installation

Pour télécharger et installer le script `add_glpi.sh`, suivez ces étapes simples :

1. Utilisez la commande wget pour télécharger le script depuis le dépôt GitHub :

    ```bash
    wget https://raw.githubusercontent.com/Haritzpean/GLPI-10.0.11/main/add_glpi.sh
    ```

2. Exécutez le script avec la commande bash pour effectuer l'installation :

    ```bash
    bash add_glpi.sh
    ```

Assurez-vous d'avoir les droits nécessaires pour exécuter le script. Si vous rencontrez des problèmes lors de l'installation, veuillez consulter la documentation du projet ou les problèmes associés sur le dépôt GitHub.
