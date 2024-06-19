#!/bin/bash

# Definición de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

nmapTrue() {
    echo -e  "${BLUE}\nComprobando si nmap está instalado en el sistema\n${NC}"
    sleep 2

    test -f /usr/bin/nmap 
    if [ $? -eq 0 ]; then 
        echo -e "${GREEN}Nmap está instalado${NC}"
    else 
        read -p "¿Qué sistema de paquetes utilizas (apt, dnf, pacman)? -> " os
        case $os in
            apt)
                sudo apt install nmap -y >/dev/null 2>&1
                ;;
            dnf)
                sudo dnf install nmap -y >/dev/null 2>&1
                ;;
            pacman)
                sudo pacman -S nmap -y >/dev/null 2>&1
                ;;
            *)
                echo -e "${RED}La opción no es correcta${NC}"
        esac
    fi
}

nmapFunction() {
    while true; do
        echo -e "${YELLOW}\n1) Escaneo básico de nmap"
        echo -e "2) Escaneo rápido y ruidoso -> (no hacer en entornos empresariales)"
        echo -e "3) Escaneo silencioso -> (Escaneo lento pero eficaz)"
        echo -e "4) Escaneo avanzado -> (añadimos búsqueda de versiones y uso de scripts)"
        echo -e "5) Escaneo total"
        echo -e "6) Escaneo de puertos UDP"
        echo -e "7) Salir${NC}"
        read -p "Debes indicar el tipo de escaneo que deseas realizar: " opcion

        case $opcion in
            1)
                nmap -p- --open $ip | grep -E "^[0-9]+\/[a-z]+\s+open\s+[a-z]+"
                ;;
            2)
                nmap -p- --open -sS --min-rate 5000 -n -v -Pn $ip | grep -E "^[0-9]+\/[a-z]+\s+open\s+[a-z]+"
                ;;
            3)
                nmap -p- --open -sS -T2 -f -Pn $ip | grep -E "^[0-9]+\/[a-z]+\s+open\s+[a-z]+"
                ;;
            4)
                nmap -p- --open -sC -sV $ip 
                ;;
            5)
                nmap -p- --open -sCV -sS --min-rate 5000 -Pn -n -vvv $ip -oN escaneo.txt 
                ;;
            6)
                nmap --top-ports 200 -sU --min-rate 5000 -Pn -n -oN escaneo.txt
                ;;
            7)
             echo -e "$RED[!] Saliendo......"
             sleep 2
                break 
                ;;
            *)
                echo -e "${RED}La opción que has indicado no es correcta${NC}"
        esac
    done
}

root=$(id -u)
if [ $root -ne 0 ]; then 
    echo -e "${RED}Necesitas ser sudo para ejecutar el script${NC}"
    exit 1
else 
    echo -e "${BLUE}\nComenzamos con el reconocimiento del sistema\n${NC}"
fi
sleep 2

test -f /usr/sbin/arp-scan
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Arp-scan está instalado${NC}"
else
    read -p "¿Qué sistema de paquetes utilizas (apt, dnf, pacman)? -> " sistema
    case $sistema in 
        apt)
            sudo apt install arp-scan -y >/dev/null 2>&1
            ;;
        dnf)
            sudo dnf install arp-scan -y >/dev/null 2>&1
            ;;
        pacman)
            sudo pacman -S arp-scan -y >/dev/null 2>&1
            ;;
        *)
            echo -e "${RED}La opción no es correcta${NC}"
    esac
fi

read -p "Indica cuál es tu interfaz de red -> " interfaz
sleep 2

# Obtener la MAC de la interfaz de red especificada
mac=$(ifconfig $interfaz 2>/dev/null | awk '/ether/{print $2}')

# Realizar el escaneo ARP y obtener la IP y MAC de las máquinas
result=$(sudo arp-scan -I $interfaz --localnet --ignoredups | grep -v "$mac" | grep -E '00:0c|08:00')
ip=$(echo $result | awk '{print $1}') 

if [ -z $ip ]; then
    echo -e "${RED}\nLa dirección IP no ha sido encontrada\n${NC}"
    exit 1
else 
    echo -e "${GREEN}\nLa dirección IP de la máquina víctima es -> $ip\n${NC}"
fi

ttl=$(ping -c 1 $ip | grep -oP 'ttl=\K[0-9]{1,3}')
if [ $ttl -eq 64 ]; then
    echo -e "${GREEN}\nEstamos ante una máquina Linux, su ttl es -> 64\n${NC}"
elif [ $ttl -eq 128 ]; then
    echo -e "${GREEN}\nEstamos ante una máquina Windows, su ttl es -> 128\n${NC}"
fi

nmapTrue
nmapFunction
