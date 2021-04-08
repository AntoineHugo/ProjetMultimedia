#!/bin/bash
#Possibilité de lancer le script avec la commande :
#sudo wget -O - https://raw.githubusercontent.com/AntoineHugo/ProjetMultimedia/5682924dc658452d378ff8a74998ca31205808e8/install.sh | sudo bash

BICyan="\033[1;96m"
GREEN='\033[0;32m'
NORMAL='\033[0m' # No Color
BOLD=$(tput bold) #Text en gras
RED='\033[0;31m'
ping -c 1 8.8.8.8 &> /dev/null
echo "alias startdocker=\"docker-compose -f /opt/docker/docker-compose.yml up -d\"" >> /etc/bash.bashrc
echo "alias stopdocker=\"docker-compose -f /opt/docker/docker-compose.yml down\"" >> /etc/bash.bashrc

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
rm /opt/docker/docker-compose.yml
chown $username:$username -R /opt/docker/

#Mise en place du docker-compose :
wget -O /opt/docker/docker-compose.yml https://raw.githubusercontent.com/AntoineHugo/ProjetMultimedia/main/docker-compose.yml

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

#Fin du script
echo ""
echo ""
echo -e "${GREEN}${BOLD}Le script s'est terminé.${NORMAL}"
echo ""
echo -e "${GREEN}${BOLD}Penser à renseigner les entrées hosts sur votre PC :${NORMAL}"
echo ""
head -n 13 /etc/hosts
echo ""
echo ""
echo -e "${GREEN}${BOLD}Vous pouvez accéder à l'URL"${NORMAL} ${BOLD}"radarr.projet-multimedia.com" ${GREEN}${BOLD}pour télécharger des films et"${NORMAL} ${BOLD}"sonarr.projet-multimedia.com" ${GREEN}${BOLD}pour télécharger des séries (les mots de passes à utiliser --> user :${NORMAL} ${BOLD}administration ${GREEN}${BOLD}/ mot de passe :${NORMAL} ${BOLD}passroot)${NORMAL}"
echo ""
echo -e "${GREEN}${BOLD}Vous pouvez accéder à l'URL"${NORMAL} ${BOLD}"grafana.projet-multimedia.com" ${GREEN}${BOLD}pour superviser l\'environnement et"${NORMAL} ${BOLD}"portainer.projet-multimedia.com" ${GREEN}${BOLD}pour relancer des services. ${NORMAL}"
echo ""
echo -e "${GREEN}${BOLD}Pour démarrer les containers du projet lancer la commande :${NORMAL}${BICyan} startdocker${NORMAL} ${GREEN}${BOLD}(il faut refresh le terminal)${NORMAL}"
echo -e "${GREEN}${BOLD}Pour stopper les containers du projet lancer la commande :${NORMAL}${BICyan} stopdocker${NORMAL} ${GREEN}${BOLD}(il faut refresh le terminal)${NORMAL}"

fi
