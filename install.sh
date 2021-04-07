#!/bin/bash
#Possibilité de lancer le script avec la commande :
#sudo wget -O - https://raw.githubusercontent.com/AntoineHugo/ProjetMultimedia/5682924dc658452d378ff8a74998ca31205808e8/install.sh | sudo bash


GREEN='\033[0;32m'
NORMAL='\033[0m' # No Color
BOLD=$(tput bold) #Text en gras
RED='\033[0;31m'
ping -c 1 8.8.8.8 &> /dev/null

#Mise en place de garde fou en fonction de l'accès réseau et check si l'user=ROOT
if [[ $? -ne 0 ]];
then
        echo -e "${RED}${BOLD}ERROR this VM can't reach internet the script can't be lauch${NORMAL}"
else
#Début du script, demande d'informations :
if [ $(id -u) -eq 0 ]; then
echo -e "${GREEN}${BOLD}Le script va commencer :${NORMAL}"
echo ""
sleep 2
else
        echo -e "${RED}${BOLD}Only root can execute script on the system.${NORMAL}"
        exit 2
fi

#Récupération de l'@ ip
IP=$(hostname -I)

#Installatin de docker :
apt update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

var1=$( cat /etc/issue )
if [[ $var1 == *"Debian"* ]];
then
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
echo $var1
else
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
fi
apt update
apt install docker-ce -y


#Installation Docker Compose :
curl -L https://github.com/docker/compose/releases/download/1.25.3/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


#Mise en place des fichiers :
wget https://github.com/AntoineHugo/ProjetMultimedia/raw/main/docker.tar.gz 
tar -xzvf docker.tar.gz -C /opt 
rm docker.tar.gz
truncate -s 0 /opt/docker/docker-compose.yml
chown $username:$username -R /opt/docker/

#Mise en place du docker-compose :
cat << EOF |sudo tee -a /opt/docker/docker-compose.yml
version: "2.1"
services:

####
#FlareSolverr
####
  flaresolverr:
    # depends_on:
    #   - watchtower 
    image: flaresolverr:latest
    container_name: flaresolverr
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
    ports:
      - "8191:8191"
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
    restart: unless-stopped 


####
#Radarr
####
  radarr:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/radarr
    container_name: radarr
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/radarr/data:/config
      - /opt/docker/radarr/movies:/movies
      - /opt/docker/transmission/downloads:/downloads
    expose:
      - 7878
    labels:
      - "traefik.http.routers.radarr-http.entrypoints=web"
      - "traefik.http.routers.radarr-http.rule=Host(`\radarr.projet-multimedia.com\`)"
      - "traefik.http.routers.radarr-http.middlewares=radarr-https"
      - "traefik.http.middlewares.radarr-https.redirectscheme.scheme=https"
      - "traefik.http.routers.radarr.entrypoints=websecure"
      - "traefik.http.routers.radarr.rule=Host(`radarr.projet-multimedia.com`)"
      - "traefik.http.services.radarr.loadbalancer.server.port=7878"
      - "traefik.http.routers.radarr.tls=true"
    restart: unless-stopped 


####
#Jellyfin
####
  jellyfin:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/jellyfin
    container_name: jellyfin
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/jellyfin/config:/config
      - /opt/docker/sonarr/tvseries:/data/tvshows
      - /opt/docker/radarr/movies:/data/movies
    expose:
      - 8096
    labels:
      - "traefik.http.routers.jellyfin-http.entrypoints=web"
      - "traefik.http.routers.jellyfin-http.rule=Host(\`jellyfin.projet-multimedia.com\`)"
      - "traefik.http.routers.jellyfin-http.middlewares=jellyfin-https"
      - "traefik.http.middlewares.jellyfin-https.redirectscheme.scheme=https"
      - "traefik.http.routers.jellyfin.entrypoints=websecure"
      - "traefik.http.routers.jellyfin.rule=Host(\`jellyfin.projet-multimedia.com\`)"
      - "traefik.http.services.jellyfin.loadbalancer.server.port=8096"
      - "traefik.http.routers.jellyfin.tls=true"
    restart: unless-stopped   


####
#Sonarr
####
  sonarr:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/sonarr 
    container_name: sonarr
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/sonarr/data:/config
      - /opt/docker/sonarr/tvseries:/tv
      - /opt/docker/transmission/downloads:/downloads
    expose:
      - 8989
    labels:
      - "traefik.http.routers.sonarr-http.entrypoints=web"
      - "traefik.http.routers.sonarr-http.rule=Host(\`sonarr.projet-multimedia.com\`)"
      - "traefik.http.routers.sonarr-http.middlewares=sonarr-https"
      - "traefik.http.middlewares.sonarr-https.redirectscheme.scheme=https"
      - "traefik.http.routers.sonarr.entrypoints=websecure"
      - "traefik.http.routers.sonarr.rule=Host(\`sonarr.projet-multimedia.com\`)"
      - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
      - "traefik.http.routers.sonarr.tls=true"
    restart: unless-stopped


####
#Jackett
####
  jackett:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/jackett
    container_name: jackett
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/jackett/config:/config
      - /opt/docker/jackett/downloads:/downloads
    expose:
      - 9117
    labels:
      - "traefik.http.routers.jackett-http.entrypoints=web"
      - "traefik.http.routers.jackett-http.rule=Host(\`jackett.projet-multimedia.com\`)"
      - "traefik.http.routers.jackett-http.middlewares=jackett-https"
      - "traefik.http.middlewares.jackett-https.redirectscheme.scheme=https"
      - "traefik.http.routers.jackett.entrypoints=websecure"
      - "traefik.http.routers.jackett.rule=Host(\`jackett.projet-multimedia.com\`)"
      - "traefik.http.services.jackett.loadbalancer.server.port=9117"
      - "traefik.http.routers.jackett.tls=true"
    restart: unless-stopped


####
#Transmission
####
  transmission:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
      - USER=administrateur 
      - PASS=passroot
    volumes:
      - /opt/docker/transmission/config:/config
      - /opt/docker/transmission/downloads:/downloads
      - /opt/docker/transmission/watch:/watch
    expose:
      - 9091
      - 51413
    labels:
      - "traefik.http.routers.transmission-http.entrypoints=web"
      - "traefik.http.routers.transmission-http.rule=Host(\`transmission.projet-multimedia.com\`)"
      - "traefik.http.routers.transmission-http.middlewares=transmission-https"
      - "traefik.http.middlewares.transmission-https.redirectscheme.scheme=https"
      - "traefik.http.routers.transmission.entrypoints=websecure"
      - "traefik.http.routers.transmission.rule=Host(\`transmission.projet-multimedia.com\`)"
      - "traefik.http.services.transmission.loadbalancer.server.port=9091"
      - "traefik.http.routers.transmission.tls=true"
    restart: unless-stopped


####
#Bazzar
####
  bazarr:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/bazarr
    container_name: bazarr
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/bazarr/config:/config
      - /opt/docker/radarr/movies:/movies
      - /opt/docker/sonarr/tvseries:/tv
    expose:
      - 6767
    labels:
      - "traefik.http.routers.bazarr-http.entrypoints=web"
      - "traefik.http.routers.bazarr-http.rule=Host(\`bazarr.projet-multimedia.com\`)"
      - "traefik.http.routers.bazarr-http.middlewares=bazarr-https"
      - "traefik.http.middlewares.bazarr-https.redirectscheme.scheme=https"
      - "traefik.http.routers.bazarr.entrypoints=websecure"
      - "traefik.http.routers.bazarr.rule=Host(\`bazarr.projet-multimedia.com\`)"
      - "traefik.http.services.bazarr.loadbalancer.server.port=6767"
      - "traefik.http.routers.bazarr.tls=true"
    restart: unless-stopped



####
#Organizr
####
  organizr:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/organizr
    container_name: organizr
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/organizr/config:/config
      - /opt/docker/organizr/images:/var/www/html/images
    expose:
      - 80
    labels:
      - "traefik.http.routers.organizr-http.entrypoints=web"
      - "traefik.http.routers.organizr-http.rule=Host(\`organizr.projet-multimedia.com\`)"
      - "traefik.http.routers.organizr-http.middlewares=organizr-https"
      - "traefik.http.middlewares.organizr-https.redirectscheme.scheme=https"
      - "traefik.http.routers.organizr.entrypoints=websecure"
      - "traefik.http.routers.organizr.rule=Host(\`organizr.projet-multimedia.com\`)"
      - "traefik.http.services.organizr.loadbalancer.server.port=80"
      - "traefik.http.routers.organizr.tls=true"
    restart: unless-stopped


####
#Nzbhydra2
####
  nzbhydra2:
    depends_on:
      # - watchtower 
      - traefik
    image: linuxserver/nzbhydra2 
    container_name: nzbhydra2
    environment:
      - PUID=1001
      - PGID=1001
      - TZ=Europe/Paris
    volumes:
      - /opt/docker/nzbhydra2/data:/config
      - /opt/docker/nzbhydra2/download:/downloads
    expose:
      - 5076
    labels:
      - "traefik.http.routers.nzbhydra2-http.entrypoints=web"
      - "traefik.http.routers.nzbhydra2-http.rule=Host(\`nzbhydra.projet-multimedia.com\`)"
      - "traefik.http.routers.nzbhydra2-http.middlewares=nzbhydra2-https"
      - "traefik.http.middlewares.nzbhydra2-https.redirectscheme.scheme=https"
      - "traefik.http.routers.nzbhydra2.entrypoints=websecure"
      - "traefik.http.routers.nzbhydra2.rule=Host(\`nzbhydra.projet-multimedia.com\`)"
      - "traefik.http.services.nzbhydra2.loadbalancer.server.port=5076"
      - "traefik.http.routers.nzbhydra2.tls=true"
    restart: unless-stopped
    


####
#Portainer
####
  portainer:
    depends_on:
      # - watchtower 
      - traefik 
    image: portainer/portainer
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    restart: always
    expose:
      - 9000
      - 8000
    labels:
      - "traefik.http.routers.portainer-http.entrypoints=web"
      - "traefik.http.routers.portainer-http.rule=Host(\`portainer.projet-multimedia.com\`)"
      - "traefik.http.routers.portainer-http.middlewares=portainer-https"
      - "traefik.http.middlewares.portainer-https.redirectscheme.scheme=https"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.rule=Host(\`portainer.projet-multimedia.com\`)"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      - "traefik.http.routers.portainer.tls=true"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/docker/portainer/data:/data

      
# ####
# #Watchtower
# ####
#   watchtower:
#     command: --label-enable --cleanup --interval 300
#     image: containrrr/watchtower
#     container_name: watchtower
#     labels:
#       - "com.centurylinklabs.watchtower.enable=true"
#     network_mode: none
#     restart: always
#     volumes:
#       - /var/run/docker.sock:/var/run/docker.sock


####
#Traefik
####
  traefik:
    # depends_on:
      # - watchtower
    image: traefik:v2.2
    container_name: traefik
    command:
      - "--providers.docker"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      # - /opt/docker/traefik:/etc/traefik
      # - /opt/docker/traefik:/acme.json
    labels:
    # - "com.centurylinklabs.watchtower.enable=true"
    - "traefik.http.routers.api.rule=Host()"
    - "traefik.http.routers.api.service=api@internal"
    - "traefik.http.routers.api.entrypoints=websecure"
    - "traefik.http.routers.api.tls=true"
    - "traefik.http.routers.api.tls.certresolver=projet-multimedia"
    - "traefik.http.routers.api.middlewares=auth"
    - "traefik.http.middlewares.auth.basicauth.users=administrateur:1357apr11357SgawlZIX1357UAWNdBNHwQwKT5a3NW7cO."

####
#Cadvisor
####
  cadvisor:
    depends_on:
      # - watchtower
      - traefik 
    image: google/cadvisor
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    expose:
      - 8080
    labels:
      - "traefik.http.routers.cadvisor-http.entrypoints=web"
      - "traefik.http.routers.cadvisor-http.rule=Host(\`cadvisor.projet-multimedia.com\`)"
      - "traefik.http.routers.cadvisor-http.middlewares=cadvisor-https"
      - "traefik.http.middlewares.cadvisor-https.redirectscheme.scheme=https"
      - "traefik.http.routers.cadvisor.entrypoints=websecure"
      - "traefik.http.routers.cadvisor.rule=Host(\`cadvisor.projet-multimedia.com\`)"
      - "traefik.http.services.cadvisor.loadbalancer.server.port=8080"
      - "traefik.http.routers.cadvisor.tls=true"


####
#Prometheus
####  
  prometheus:
    depends_on:
      # - watchtower
      - traefik 
      - cadvisor
    image: prometheus:v2.0.0
    container_name: prometheus
    volumes:
      - /opt/docker/prometheus:/etc/prometheus/
      - /opt/docker/prometheus/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention=200h'
    expose:
      - 9090
    labels:
      - "traefik.http.routers.prometheus-http.entrypoints=web"
      - "traefik.http.routers.prometheus-http.rule=Host(\`prometheus.projet-multimedia.com\`)"
      - "traefik.http.routers.prometheus-http.middlewares=prometheus-https"
      - "traefik.http.middlewares.prometheus-https.redirectscheme.scheme=https"
      - "traefik.http.routers.prometheus.entrypoints=websecure"
      - "traefik.http.routers.prometheus.rule=Host(\`prometheus.projet-multimedia.com\`)"
      - "traefik.http.services.prometheus.loadbalancer.server.port=9090"
      - "traefik.http.routers.prometheus.tls=true"

####
#Grafana
####  
  grafana:
    depends_on:
      # - watchtower
      - traefik 
      - cadvisor
    image: grafana/grafana
    container_name: grafana
    volumes:
      - /opt/docker/grafana/data:/var/lib/grafana
    expose:
      - 3000
    labels:
      - "traefik.http.routers.grafana-http.entrypoints=web"
      - "traefik.http.routers.grafana-http.rule=Host(\`grafana.projet-multimedia.com\`)"
      - "traefik.http.routers.grafana-http.middlewares=grafana-https"
      - "traefik.http.middlewares.grafana-https.redirectscheme.scheme=https"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.rule=Host(\`grafana.projet-multimedia.com\`)"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
      - "traefik.http.routers.grafana.tls=true"
    extra_hosts:
      - "prometheus.projet-multimedia.com:192.168.5.12"

EOF

#Lancement du docker-compose
docker-compose -f /opt/docker/docker-compose.yml up -d

#Mise en place du DNS
sed -i "1s/^/${IP:0:13} traefik.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} radarr.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} sonarr.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} nzbhydra.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} portainer.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} organizr.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} bazarr.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} transmission.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} jackett.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} jellyfin.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} cadvisor.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} prometheus.projet-multimedia.com \n/" /etc/hosts
sed -i "1s/^/${IP:0:13} grafana.projet-multimedia.com \n/" /etc/hosts


echo ""
echo ""
echo -e "${GREEN}${BOLD}Le script s'est terminé.${NORMAL}"
echo ""
echo -e "${GREEN}${BOLD}Vous pouvez accéder à l'URL"${NORMAL} ${BOLD}"radarr.projet-multimedia.com" ${GREEN}${BOLD}pour télécharger des films et"${NORMAL} ${BOLD}"sonarr.projet-multimedia.com" ${GREEN}${BOLD}pour télécharger des séries (les mots de passes à utiliser --> user :${NORMAL} ${BOLD}administration ${GREEN}${BOLD}/ mot de passe :${NORMAL} ${BOLD}passroot)${NORMAL}"
echo ""
echo -e "${GREEN}${BOLD}Vous pouvez accéder à l'URL"${NORMAL} ${BOLD}"grafana.projet-multimedia.com" ${GREEN}${BOLD}pour superviser l\'environnement et"${NORMAL} ${BOLD}"portainer.projet-multimedia.com" ${GREEN}${BOLD}pour relancer des services. ${NORMAL}"
echo ""
fi
