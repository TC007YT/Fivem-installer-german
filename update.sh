#!/bin/bash

red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
nc="$(tput sgr0)"

runtime_link=$1

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
      echo -e "${red}Ein Fehler ist aufgetreten:${reset} ${white}${COMMAND}${reset}${red} hat den Code${reset} ${white}${BASH_CODE}${reset} zurückgegeben"
      exit ${BASH_CODE}
    fi
}

source <(curl -s https://raw.githubusercontent.com/GermanJag/BashSelect.sh/main/BashSelect.sh)
clear

status "Wähle das Alpine-Verzeichnis"
readarray -t directorys <<<$(find / -name "alpine")
export OPTIONS=(${directorys[*]})

bashSelect

dir=${directorys[$?]}/..

lsof -i :40120
if [[ $( echo $? ) == 0 ]]; then

  status "Es sieht so aus, als ob etwas auf dem Standard-TxAdmin-Port läuft. Können wir es stoppen/töten?" "/"
  export OPTIONS=("PID auf Port 40120 töten" "Skript beenden")
  bashSelect
  case $? in
    0 )
      status "Töte PID auf 40120"
      runCommand "apt -y install psmisc"
      runCommand "fuser -4 40120/tcp -k"
      ;;
    1 )
      exit 0
      ;;
  esac
fi

echo "${red}Lösche ${nc}alpine"
sleep 1
rm -rf $dir/alpine
clear

echo "${red}Lösche ${nc}run.sh"
sleep 1
rm -f $dir/run.sh
clear

echo "Herunterladen von ${yellow}fx.tar.xz${nc}"
wget --directory-prefix=$dir $1
echo "${green}Erfolg${nc}"

sleep 1
clear

echo "Entpacken von ${yellow}fx.tar.xz${nc}"
tar xf $dir/fx.tar.xz -C $dir

echo "${green}Erfolg${nc}"
sleep 1

clear

rm -r $dir/fx.tar.xz
echo "${red}Lösche ${nc}fx.tar.xz"

sleep 1
clear

echo "${green}Update erfolgreich${nc}"
