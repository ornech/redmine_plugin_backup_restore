#!/bin/bash

# ------------------------------------------------------------------------------
# Script : recreate_backup_restore_plugin.sh
# Description : Désactive, supprime et recrée le plugin 'backup_restore' pour Redmine
# Usage : ./recreate_backup_restore_plugin.sh [NOM_DU_CONTENEUR]
# ------------------------------------------------------------------------------

# Vérifier si Docker est installé
if ! command -v docker &> /dev/null
then
    echo "Docker n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
    exit 1
fi

# Récupérer le nom du conteneur à partir des arguments ou utiliser un défaut
CONTAINER_NAME=${1:-redmine}

# Récupérer le nom du conteneur
CONTAINER_NAME=$(docker compose ps -a --format '{{.Name}}' | grep $CONTAINER_NAME)

echo "Utilisation du conteneur Redmine : $CONTAINER_NAME"

# Vérifier si le conteneur existe et est en cours d'exécution
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Le conteneur '$CONTAINER_NAME' n'est pas en cours d'exécution. Veuillez vérifier le nom du conteneur."
    exit 1
fi

# Étape 1 : Désactiver le plugin en renommant son répertoire
echo "Désactivation du plugin 'backup_restore'..."
docker exec -it "$CONTAINER_NAME" bash -c "if [ -d /bitnami/redmine/plugins/backup_restore ]; then mv /bitnami/redmine/plugins/backup_restore /bitnami/redmine/plugins/backup_restore_disabled; else echo 'Le plugin backup_restore n\'existe pas.'; fi"

# Redémarrer le conteneur pour appliquer les changements
echo "Redémarrage du conteneur Redmine..."
docker restart "$CONTAINER_NAME"

# Attendre que le conteneur redémarre
sleep 10

# Étape 2 : Supprimer complètement le plugin désactivé
echo "Suppression du plugin désactivé..."
docker exec -it "$CONTAINER_NAME" bash -c "if [ -d /bitnami/redmine/plugins/backup_restore_disabled ]; then rm -rf /bitnami/redmine/plugins/backup_restore_disabled; else echo 'Le plugin backup_restore_disabled n\'existe pas.'; fi"

# Étape 3 : Recréer le plugin 'backup_restore' en utilisant le générateur de plugins
echo "Création du nouveau plugin 'backup_restore' en utilisant le générateur de plugins..."

docker exec -it "$CONTAINER_NAME" bash -c "
    export RAILS_ENV=production && \
    cd /opt/bitnami/redmine && \
    bundle exec rails generate redmine_plugin backup_restore
"

# Vérifier si le générateur a réussi
if [ $? -ne 0 ]; then
    echo "Échec de la génération du plugin 'backup_restore'. Veuillez vérifier les erreurs ci-dessus."
    exit 1
fi

# Étape 4 : Exécuter les migrations des plugins
echo "Exécution des migrations des plugins..."
docker exec -it "$CONTAINER_NAME" bash -c "
    export RAILS_ENV=production && \
    cd /opt/bitnami/redmine && \
    bundle exec rake redmine:plugins:migrate
"

# Vérifier si les migrations ont réussi
if [ $? -ne 0 ]; then
    echo "Échec des migrations des plugins. Veuillez vérifier les erreurs ci-dessus."
    exit 1
fi

# Étape 5 : Redémarrer le conteneur Redmine pour appliquer les changements
echo "Redémarrage du conteneur Redmine pour appliquer les changements..."
docker restart "$CONTAINER_NAME"

# Attendre que le conteneur redémarre
sleep 10

# Étape 6 : Vérifier et Tester le Plugin
echo "Vérification des routes du plugin 'backup_restore'..."
docker compose exec -it "$CONTAINER_NAME" bash -c "cd /opt/bitnami/redmine && bundle exec rake routes | grep backup_restore"


# Copier les fichiers dans le conteneur
echo "Copie des fichiers nécessaires pour le plugin 'backup_restore' dans le conteneur..."

# Copier init.rb
docker cp init.rb "$CONTAINER_NAME":/bitnami/redmine/plugins/backup_restore/init.rb

# Copier routes.rb
docker cp routes.rb "$CONTAINER_NAME":/bitnami/redmine/plugins/backup_restore/config/routes.rb

# Copier backup_restore_controller.rb
docker cp backup_restore_controller.rb "$CONTAINER_NAME":/bitnami/redmine/plugins/backup_restore/app/controllers/backup_restore_controller.rb

# Copier index.html.erb
docker cp index.html.erb "$CONTAINER_NAME":/bitnami/redmine/plugins/backup_restore/app/views/backup_restore/index.html.erb

# Copier _backup_restore_settings.html.erb
docker exec -it "$CONTAINER_NAME" bash -c "mkdir -p /bitnami/redmine/plugins/backup_restore/app/views/settings"
docker cp _backup_restore_settings.html.erb "$CONTAINER_NAME":/bitnami/redmine/plugins/backup_restore/app/views/settings/_backup_restore_settings.html.erb


echo "Les fichiers nécessaires pour le plugin 'backup_restore' ont été copiés avec succès dans le conteneur."

# Créer le répertoire des sauvegardes et définir les permissions
docker exec -it "$CONTAINER_NAME" bash -c "mkdir -p /bitnami/redmine/backups && chown -R redmine:redmine /bitnami/redmine/backups/"

echo "Le répertoire des sauvegardes a été créé et les permissions ont été définies avec succès."

# Redémarrer le conteneur Redmine pour appliquer les changements
echo "Redémarrage du conteneur Redmine pour appliquer les changements..."
docker restart "$CONTAINER_NAME"

# Attendre que le conteneur redémarre
sleep 10

echo "Le conteneur Redmine a été redémarré avec succès."

