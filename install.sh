#!/bin/bash
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"


runtime_link=$1

source <(curl -s https://raw.githubusercontent.com/JulianGransee/BashSelect.sh/main/BashSelect.sh)
clear
status(){
  clear
  echo -e $green$@'...'$reset
  sleep 1
}

runCommand(){
    COMMAND=$1

    if [[ ! -z "$2" ]]; then
      status $2
    fi

    eval $COMMAND;
    BASH_CODE=$?
    if [ $BASH_CODE -ne 0 ]; then
      echo -e "${red}Ein Fehler ist aufgetreten:${reset} ${white}${COMMAND}${reset}${red} returned${reset} ${white}${BASH_CODE}${reset}"
      exit ${BASH_CODE}
    fi
}


source <(curl -s https://raw.githubusercontent.com/TC007YT/Fivem-installer-german/main/BashSelect.sh)

status "MariaDB/MySQL und phpmyadmin Installieren?"

export OPTIONS=("ja" "nein")

bashSelect

case $? in
     0 )
        phpmaInstall=0;;
     1 )
        ;;
esac


function examServData() {

  runCommand "mkdir -p $dir/server-data"

  runCommand "git clone -q https://github.com/citizenfx/cfx-server-data.git $dir/server-data" "Die server-data wird heruntergeladen"

  status "Creating example server.cfg"

  cat << EOF > $dir/server-data/server.cfg
  # Only change the IP if you're using a server with multiple network interfaces, otherwise change the port only.
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"
# These resources will start by default.
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap
ensure rconlog
# This allows players to use scripthook-based plugins such as the legacy Lambda Menu.
# Set this to 1 to allow scripthook. Do note that this does _not_ guarantee players won't be able to use external plugins.
sv_scriptHookAllowed 0
# Uncomment this and set a password to enable RCON. Make sure to change the password - it should look like rcon_password "YOURPASSWORD"
#rcon_password ""
# A comma-separated list of tags for your server.
# For example:
# - sets tags "drifting, cars, racing"
# Or:
# - sets tags "roleplay, military, tanks"
sets tags "default"
# A valid locale identifier for your server's primary language.
# For example "en-US", "fr-CA", "nl-NL", "de-DE", "en-GB", "pt-BR"
sets locale "root-AQ"
# please DO replace root-AQ on the line ABOVE with a real language! :)
# Set an optional server info and connecting banner image url.
# Size doesn't matter, any banner sized image will be fine.
#sets banner_detail "https://url.to/image.png"
#sets banner_connecting "https://url.to/image.png"
# Set your server's hostname. This is not usually shown anywhere in listings.
sv_hostname "FXServer, but unconfigured"
# Set your server's Project Name
sets sv_projectName "My FXServer Project"
# Set your server's Project Description
sets sv_projectDesc "Default FXServer requiring configuration"
# Nested configs!
#exec server_internal.cfg
# Loading a server icon (96x96 PNG file)
#load_server_icon myLogo.png
# convars which can be used in scripts
set temp_convar "hey world!"
# Remove the `#` from the below line if you do not want your server to be listed in the server browser.
# Do not edit it if you *do* want your server listed.
#sv_master1 ""
# Add system admins
add_ace group.admin command allow # allow all commands
add_ace group.admin command.quit deny # but don't allow quit
add_principal identifier.fivem:1 group.admin # add the admin to the group
# enable OneSync (required for server-side state awareness)
set onesync on
# Server player slot limit (see https://fivem.net/server-hosting for limits)
sv_maxclients 48
# Steam Web API key, if you want to use Steam authentication (https://steamcommunity.com/dev/apikey)
# -> replace "" with the key
set steam_webApiKey ""
# License key for your server (https://keymaster.fivem.net)
sv_licenseKey changeme
EOF

}

if [ "$EUID" -ne 0 ]; then
	echo -e "${red}Bitte als Root ausführen";
	exit
fi


status "Select deployment type"
export OPTIONS=("Vorlage über TxAdmin installieren" "Verwenden Sie die cfx-server-data")
bashSelect
deployType=$( echo $? )

runCommand "apt -y update" "Updatet"

runCommand "apt -y upgrade " "Upgrade wird durchgeführt"

runCommand "apt install -y wget git curl dos2unix net-tools sed screen tmux xz-utils lsof" "Installation notwendiger Pakete"

clear

dir=/home/FiveM

lsof -i :40120
if [[ $( echo $? ) == 0 ]]; then

  status "Es sieht so aus, als ob auf dem Standard-TxAdmin-Port bereits etwas läuft. Können wir es stoppen?" "/"
  export OPTIONS=("PID auf Port 40120 beenden" "Beenden Sie das Skript")
  bashSelect
  case $? in
    0 )
      status "PID auf 40120 Stoppen"
      runCommand "apt -y install psmisc"
	  runCommand "fuser -4 40120/tcp -k"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

if [[ -e $dir ]]; then
  status "It looks like there already is a $dir Ordner, Können wir es Löschen?" "/"
  export OPTIONS=("Alles Löschen in $dir" "Beenden Sie das Skript ")
  bashSelect
  case $? in
    0 )
      status "Lösche $dir"
      runCommand "rm -r $dir"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

if [[ $phpmaInstall == 0 ]]; then
  bash <(curl -s https://raw.githubusercontent.com/TC007YT/Fivem-installer-german/main/phpinstaller.sh) -s
fi

runCommand "mkdir -p $dir/server" "Erstellen Sie Verzeichnisse für den FiveM-Server"
runCommand "cd $dir/server/"


runCommand "wget $runtime_link" "FxServer wird heruntergeladen"

runCommand "tar xf fx.tar.xz" "Entpacken des FxServer-Archivs"
runCommand "rm fx.tar.xz"

case $deployType in
  0 )
    sleep 0;;# do nothing
  1 )
    examServData
    ;;
esac

status "Erstellen eines Start-, Stopp- und Zugriffsskripts"
cat << EOF > $dir/start.sh
#!/bin/bash
red="\e[0;91m"
green="\e[0;92m"
bold="\e[1m"
reset="\e[0m"
port=\$(lsof -Pi :40120 -sTCP:LISTEN -t)
if [ -z "\$port" ]; then
    screen -dmS fivem sh $dir/server/run.sh
    echo -e "\n\${green}TxAdmin wurde gestartet!\${reset}"
else
    echo -e "\n\${red}Das Standard \${reset}\${bold}TxAdmin\${reset}\${red} ist schon in benutzung -> ist ein \${reset}\${bold}FiveM Server\${reset}\${red} Schon Gestartet?\${reset}"
fi
EOF
runCommand "chmod +x $dir/start.sh"

runCommand "echo \"screen -xS fivem\" > $dir/attach.sh"
runCommand "chmod +x $dir/attach.sh"

runCommand "echo \"screen -XS fivem quit\" > $dir/stop.sh"
runCommand "chmod +x $dir/stop.sh"

status "Erstellen Sie eine Crontab, um txadmin automatisch zu starten (empfohlen)"
  export OPTIONS=("ja" "nein")
  bashSelect
  case $? in
    0 )
      status "Crontab-Eintrag erstellen"
      runCommand "echo \"@reboot         root    cd /home/FiveM/ && bash start.sh\" >> /etc/crontab"
      ;;
    1 )
      sleep 0;;
  esac

port=$(lsof -Pi :40120 -sTCP:LISTEN -t)

if [[ -z "$port" ]]; then

	if [[ -e '/tmp/fivem.log' ]]; then
    rm /tmp/fivem.log
	fi
    screen -L -Logfile /tmp/fivem.log -dmS fivem $dir/server/run.sh

    sleep 2

    line_counter=0
    while true; do
      while read -r line; do
        echo $line
        if [[ "$line" == *"zugreifen können"* ]]; then
          break 2
        fi
      done < /tmp/fivem.log
      sleep 1
    done

    cat -v /tmp/fivem.log > /tmp/fivem.log.tmp

    while read -r line; do
      echo $line_counter
      if [[ "$line" == *"PIN"*  ]]; then
        let "line_counter += 2"
        break 2
      fi
      let "line_counter += 1"
    done < /tmp/fivem.log.tmp

    pin_line=$( head -n $line_counter /tmp/fivem.log | tail -n +$line_counter )
    echo $line_counter
    echo $pin_line > /tmp/fivem.log.tmp
    pin=$( cat -v /tmp/fivem.log.tmp | sed --regexp-extended --expression='s/\^\[\[([0-9][0-9][a-z])|([0-9][a-z])|(\^\[\[)|(\[.*\])|(M-bM-\^TM-\^C)|(\^M)//g' )
    pin=$( echo $pin | sed --regexp-extend --expression='s/[\ ]//g' )

    echo $pin
    rm /tmp/fivem.log.tmp
    clear

    echo -e "\n${green}${bold}TxAdmin${reset}${green} was started successfully${reset}"
    txadmin="http://$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'):40120"
    echo -e "\n\n${red}${uline}Commands just usable via SSH\n"
    echo -e "${red}To ${reset}${blue}start${reset}${red} TxAdmin run -> ${reset}${bold}sh $dir/start.sh${reset} ${red}!\n"
    echo -e "${red}To ${reset}${blue}stop${reset}${red} TxAdmin run -> ${reset}${bold}sh $dir/stop.sh${reset} ${red}!\n"
    echo -e "${red}To see the ${reset}${blue}\"Live Console\"${reset}${red} run -> ${reset}${bold}sh $dir/attach.sh${reset} ${red}!\n"

    echo -e "\n${green}TxAdmin Webinterface: ${reset}${blue}${txadmin}\n"

    echo -e "${green}Pin: ${reset}${blue}${pin:(-4)}${reset}${green} (Benutze es in den nächsten 5 Minuten!)"

    echo -e "\n${green}Server-Data Pfad: ${reset}${blue}$dir/server-data${reset}"

    if [[ $phpmaInstall == 0 ]]; then
      echo
      echo "MariaDB and PHPMyAdmin data:"
      runCommand "cat /root/.mariadbPhpma"
      runCommand "rm /root/.mariadbPhpma"
      rootPasswordMariaDB=$( cat /root/.mariadbRoot )
      rm /root/.mariadbRoot
      fivempasswd=$( pwgen 32 1 );
      mariadb -u root -p$rootPasswordMariaDB -e "CREATE DATABASE fivem;"
      mariadb -u root -p$rootPasswordMariaDB -e "GRANT ALL PRIVILEGES ON fivem.* TO 'fivem'@'localhost' IDENTIFIED BY '${fivempasswd}';"
      echo "
FiveM MySQL-Data
    User: fivem
    Password: ${fivempasswd}
    Database name: fivem
      FiveM MySQL Connection-String:
        set mysql_connection_string \"server=127.0.0.1;database=fivem;userid=fivem;password=${fivempasswd}\""

    fi
    sleep 2

else
    echo -e "\n${red}Der Standard ${reset}${bold}TxAdmin${reset}${red} Port wird bereits Verwendet -> ist ein ${reset}${bold}FiveM Server${reset}${red} Schon gestartet?${reset}"
fi
