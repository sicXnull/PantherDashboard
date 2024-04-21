#!/bin/bash

# Function to retrieve the country based on IP address
get_country() {
    country=$(curl -s https://ipinfo.io/country)
    echo "$country"
}

# Function to determine LoRa antenna region based on country
lora_antenna_region() {
    local country="$1"
    case "$country" in
        # List of countries with their respective regions
        US|CA|AG|AI|AW|BB|BQ|BS|BZ|CR|CU|CW|DM|DO|GD|GL|GP|GT|GU|HN|HT|JM|KN|KY|LC|MF|MP|MQ|MS|NI|PA|PM|PR|SV|SX|TC|TT|VC|VG|VI|UY|VE)
            echo "US915"
            ;;
        # European countries
        AD|AL|AM|AT|AX|AZ|BA|BE|BG|BL|BY|CH|CI|CM|CY|CZ|DE|DK|EE|ES|FI|FO|FR|GB|GG|GI|GL|GR|HR|HU|IE|IM|IS|IT|JE|LI|LT|LU|LV|MC|MD|ME|MK|MT|NL|NO|PL|PT|RO|RS|RU|SE|SI|SJ|SK|SM|UA|VA|YT|ZA|ZW)
            echo "EU868"
            ;;
        # Asian countries
        AE|AF|AM|AR|AU|AZ|BD|BN|BR|BT|BW|CN|CO|ID|IL|IN|JO|JP|KH|KR|KW|LA|LK|MN|MO|MY|NP|NZ|OM|PA|PE|PG|PH|PK|QA|SG|TH|TJ|TL|TM|TW|TZ|UG|UZ|VN|YE)
            echo "AS923"
            ;;
        # Australian region countries
        AS|CK|FJ|FM|GU|KI|MH|MP|NC|NR|NU|NZ|PF|PG|PW|SB|TK|TO|TV|VU|WF|WS)
            echo "AU915"
            ;;
        IN)
            echo "IN865"
            ;;
        JP)
            echo "JP923"
            ;;
        KR)
            echo "KR920"
            ;;
        RU)
            echo "RU864"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

main() {
    country=$(get_country)
    if [ -n "$country" ]; then
        region=$(lora_antenna_region "$country")
        if [ "$region" != "Unknown" ]; then
            echo "Your LoRa antenna region is: $region"
        else
            echo "Your country is not mapped to a LoRa antenna region."
        fi
    else
        echo "Unable to determine your location."
    fi

    # Get the MAC address for eth0 and remove colons
    mac_address=$(ifconfig eth0 | grep -o -E '([0-9a-fA-F]{2}:){5}([0-9a-fA-F]{2})' | tr -d ':')

    # Insert 'fffe' in the middle of the MAC address
    mac_address_with_fffe="${mac_address:0:6}fffe${mac_address:6}"

    # Print the modified MAC address
    echo "Crankk ID is: $mac_address_with_fffe"

    # Check if "crankk-pktfwd" Docker container is running
    if ! docker ps | grep -q "crankk-pktfwd"; then
        docker run --name crankk-pktfwd --privileged -d \
	--restart always \
 	--network host \
        -e REGION="$region" \
        -e MODEL="panther" \
        -e SPI_DEV_PATH="/dev/spidev3.0" \
        -e MODEL_VARIANT="x2" \
        -e FORWARD="127.0.0.1:1700,127.0.0.1:1680" \
        -e ANTENNA_GAIN="2" \
        -e ID="$mac_address_with_fffe" \
        -e PORT="17000" \
        -e MULTIPLEXER="1" \
	-v crankk_data:/data \
        crankkster/pktfwd:latest
    fi
}

main
