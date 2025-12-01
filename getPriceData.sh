#!/bin/bash

if command -v /usr/bin/echo >&2 && command -v /usr/bin/curl >&2 && command -v /usr/bin/cat >&2 && 
command -v /usr/bin/grep >&2 && command -v /usr/bin/awk >&2 && command -v /usr/bin/mysql >&2 && ! [ -z "${MYSQLPASS}" ]; then

if ! [ -f "/tmp/cron_log.txt" ] || ! [ -f "./response.html" ]; then
	/usr/bin/echo "" > "/tmp/cron_log.txt"
	/usr/bin/echo "" > "./response.html"

fi

# uses /usr/bin to ensure that the program does not malfunction in case the commands are not added to the PATH variable
# opens website (preparing to fetch oil prices)
/usr/bin/curl -o "response.html" "https://oilprice.com/"

/usr/bin/cat "response.html"
result=$?
response=$(/usr/bin/cat "response.html")

if [[ "$result" != 0 ]] || echo "$response" | grep -q "Sorry - the page you tried to reach is no longer here." || \
echo "$response" | grep -q "Error" || echo "$response" | grep -q "404"; then

# gets four prices corresponding to WTI, Brent and Murban at the current time.
prices_str=($(/usr/bin/grep -m 5 'class="value"' 'response.html' | /usr/bin/awk -F '<[^>]*>' '{print $2}'))
prices=()
price1=0

# checks if the list is empty - if so, then doesn't plot it
if [[ "${prices_str[1]}" != "" ]]; then
# converts the prices from string to integer and adds it to a prices list
for price in "${prices_str[@]}"; do
	price1=$(/usr/bin/echo "$price" | /usr/bin/awk '{print $1+0.0}')
	prices+=($price1)
done


# gets current date and time in the required format, to be used to filter records in the database
datetime=$(date +"%H:%M:%S")
date=$(date +"%Y-%m-%d")


# inserts the data for the fuel prices, as well as the timestamp into the OILPRICES table
/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOF
SELECT * FROM CW_1314.OILPRICES;
EOF
# handles sql errors and logs them
sqlexists=$?

if [[ $sqlexists != 0 ]]; then
sudo /usr/bin/echo "ERROR: MySQL is Not Functioning Correctly" >> /tmp/cron_log.txt

else

# inserts the data for the fuel prices, as well as the timestamp into the OILPRICES table
/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
INSERT INTO CW_1314.OILPRICES(TimeReading, DateReading, OilPrice, OilType) 
VALUES ('$datetime', '$date', ${prices[0]}, 'WTI'),
	   ('$datetime', '$date', ${prices[1]}, 'BRENT'),
	   ('$datetime', '$date',  ${prices[2]}, 'MURBAN');
EOFMYSQL

fi

fi

# condition if 
else
sudo /usr/bin/echo "ERROR: Scraper Blocked / Website Down" >> /tmp/cron_log.txt

fi

# condition if the mysql password is not correctly configured
elif [ -z "${MYSQLPASS}" ]; then
sudo /usr/bin/echo "Environment Variable for MYSQLPASS Does Not Exist" >>  /tmp/cron_log.txt

# condition if the bash commands do not exist
else
sudo /usr/bin/echo "Necessary Commands for getPriceData.sh Do Not Exist" >>  /tmp/cron_log.txt
fi