#!/bin/bash

#Author=mazajo90

#Colors
green="\e[0:32m\033[1m"
red="\e[0:31m\033[1m"
yellow="\e[0:33m\033[1m"
blue="\e[0;34m\033[1m"

echo -ne "${blue}
_______ ___       __________    ______ _______ _________________
___    |__ |     / /__  ___/    ___  / __  __ \__  ____/__  ___/
__  /| |__ | /| / / _____ \     __  /  _  / / /_  / __  _____ \ 
_  ___ |__ |/ |/ /  ____/ /     _  /___/ /_/ / / /_/ /  ____/ / 
/_/  |_|____/|__/   /____/      /_____/\____/  \____/   /____/                                                                  
               
		${yellow}<mazajo90 v.0.0.1>${end}                                                                          
${end}"

#Salir del flujo con control + c
function ctrl_c() {
    echo -e "\n\n${red}\nSaliendo...!!${end}"
    tput cnorm
    exit 1
}

trap ctrl_c INT

sleep 3

#Panel de Ayúda
function helpPanel() {
    echo -e "${green}\n\nUso de la herramienta $0${end}"
    for i in $(seq 1 30); do echo -ne "${green} -"; done
    echo -ne "${end}"
    echo -e "\t\t\n${yellow}\tPanel de ayuda para buen uso de le herramienta${end}"
    for i in $(seq 1 30); do echo -ne "${green} -"; done
    echo -ne "${end}"
    echo -e "\t\t\n${yellow}[+] Lista de todos los usuarios conectados${end} ${green}(Ejemplo: $0 -a user )${end}"
    echo -e "\t\t\n${yellow}[+] Limite de busqueda usuario conectado${end} ${green}(Ejemplo: $0 -a user -n 10 )${end}"
    exit 1
}

#Variables globales
ip_instance="$(sudo cat /var/log/auth.log | awk '{print $4}' | sort -u)"

#Inicio de Tabla
function printTable() {

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]; then
        local -r numberOfLines="$(wc -l <<<"${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]; then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1)); do
                local line=''
                line="$(sed "${i}q;d" <<<"${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<<"${line}")"

                if [[ "${i}" -eq '1' ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1)); do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<<"${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]; then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]; then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines() {

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString() {

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]; then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString() {

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]; then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString() {

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<<"${string}" | sed 's,[[:blank:]]*$,,'
}
#Fin de la Tabla

function showAllUsers() {
    tput civis
    echo "Usuario | Terminal |IP o Instancia | Fecha de Conexión | Tiempo de Conexión" >useraws
    number_user=$1
    if [ $number_user == 1 ] || [ $number_user == 0 ]; then
        echo -e "\n${red}Debe ingresar 2 o mas usuarios${end} ${green}Ejemplo: -n 2${end}"
        tput cnorm && helpPanel
    else
        allus="$(cat /var/run/utmp | who | last | grep -vE "wtmp|reboot" | head -n $number_user)"

        if [ "$allus" ]; then
            echo -e "${yellow}\t\t\nEstos son los ultimos usuarios conectados en la instancia: ${blue}$ip_instance${end}"
            echo -ne "${green}"
            printTable '_' "$(cat useraws)\n$allus"
            echo -ne "${end}"
            tput cnorm
            echo
            read -p "¿Desea guardar la información en un archivo de texto? (S/n): " choice
            if [ "$choice" == "S" ] || [ "$choice" == "s" ]; then
                printTable '_' "$(cat useraws)\n${allus}" >ssh_user.txt
                echo -e "\n\n${green}La información ha sido guardada en el archivo${end} ${yellow}'ssh_user.txt'${end}"
            else
                if [ "$choice" == "N" ] || [ "$choice" == "n" ]; then
                    echo -e "\n\n${red}No se guardó la información${end}"
                else
                    echo -e "\n\n${red}Opción inválida. Por favor, introduce 'S' o 'N'${end}\n"
                    while true; do
                        read -p "¿Desea guardar la información en un archivo de texto? (S/n): " choice
                        if [ "$choice" == "S" ] || [ "$choice" == "s" ]; then
                            printTable '_' "$(cat useraws)\n${allus}" >ssh_user.txt
                            echo -e "\n\n${green}La información ha sido guardada en el archivo${end} ${yellow}'ssh_user.txt'${end}"
                            break
                        elif [ "$choice" == "N" ] || [ "$choice" == "n" ]; then
                            echo -e "\n\n${red}No se guardó la información${end}"
                            break
                        else
                            echo -e "\n\n${red}Por favor ingrese una entrada válida (S/n)${end}"
                        fi
                    done
                fi
            fi
            rm useraws
        else
            echo -e "\n\n${red}No existen conexiones por ssh a esta instancia${end}${blue}$ip_instance${end}"
        fi
    fi
    tput cnorm
}

my_funct=0

while getopts "a:n:h" arg; do
    case $arg in
    a)
        explorer="$OPTARG"
        let my_funct+=1
        ;;
    n)
        number_user="$OPTARG"
        let my_funct+=1
        ;;
    h) ;;
    esac
done

if [ $my_funct -eq 0 ]; then
    helpPanel
else
    if [ "$explorer" == "user" ]; then
        if [ -z "$number_user" ]; then
            number_user=100
            showAllUsers $number_user
        else
            showAllUsers $number_user
        fi

    else
        helpPanel
    fi
fi
