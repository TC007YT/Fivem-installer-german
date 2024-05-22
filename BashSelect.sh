#!/usr/bin/env bash

# BashSelect: Ein interaktives Auswahlsystem für Bash-Skripte
# Dieses Skript ermöglicht es dem Benutzer, interaktiv aus einer Liste von Optionen auszuwählen.

# Funktion, um das Auswahlmenü anzuzeigen
select_option() {
  # Argumente: Optionen als Array
  options=("$@")

  # Aktuelle Auswahlindex
  local selected=0

  # ANSI Escape-Sequenzen für Farben
  local ESC=$(printf "\033")
  local NORMAL="${ESC}[0m"
  local SELECTED="${ESC}[1;32m"

  # Funktion, um das Menü anzuzeigen
  show_menu() {
    for i in "${!options[@]}"; do
      if [ $i -eq $selected ]; then
        printf "${SELECTED}> %s${NORMAL}\n" "${options[i]}"
      else
        printf "  %s\n" "${options[i]}"
      fi
    done
  }

  # Unendliche Schleife, um die Benutzereingaben zu verarbeiten
  while true; do
    clear
    show_menu

    # Warten auf eine Benutzereingabe
    IFS= read -rsn1 input

    case $input in
      # Pfeil nach oben
      A)
        selected=$((selected - 1))
        if [ $selected -lt 0 ]; then
          selected=$((${#options[@]} - 1))
        fi
        ;;
      # Pfeil nach unten
      B)
        selected=$((selected + 1))
        if [ $selected -ge ${#options[@]}; then
          selected=0
        fi
        ;;
      # Eingabetaste
      "")
        break
        ;;
    esac
  done

  # Rückgabe der ausgewählten Option
  echo ${options[$selected]}
}

# Beispiel für die Verwendung der Funktion
options=("Option 1" "Option 2" "Option 3" "Option 4")
echo "Bitte wählen Sie eine Option:"
selected_option=$(select_option "${options[@]}")
echo "Sie haben '$selected_option' ausgewählt"
