#!/bin/bash


if command -v /usr/bin/echo >/dev/null >&2 && command -v /usr/bin/curl >/dev/null >&2 && command -v /usr/bin/cat >/dev/null >&2 && 
command -v /usr/bin/grep >/dev/null >&2 && command -v /usr/bin/awk >/dev/null >&2 && command -v /usr/bin/mysql >/dev/null >&2 && -v MYSQLPASS; then

# gets the date for later use
curr_time=$(/usr/bin/date)

if ! [ -f "./cron_log.log" ] || ! [ -f "./response.html" ]; then
	/usr/bin/echo "" > "./cron_log.log"
	/usr/bin/echo "" > "./response.html"
fi

# uses /usr/bin to ensure that the program does not malfunction in case the commands are not added to the PATH variable
# opens website (preparing to fetch oil prices)
/usr/bin/curl -o "response.html" "https://oilprice.com/"

result=$?
response=$(/usr/bin/cat "response.html")

if [[ "$result" -ne 0 ]] || echo "$response" | grep -qF "Sorry - the page you tried to reach is no longer here." || \
echo "$response" | grep -qF "Error" || echo "$response" | grep -qF "404"; then
# gets four prices corresponding to WTI, Brent and Murban at the current time.
prices_str=($(/usr/bin/grep -m 5 'class="value"' 'response.html' | /usr/bin/awk -F '<[^>]*>' '{print $2}'))
prices=()
price1=0

# checks if the values are numeric or not - and stores them depending on this check.
numcheck='^[0-9]+([.][0-9]{2})?$'
if [[ ${prices_str[0]} =~ $numcheck && ${prices_str[1]}  =~ $numcheck && ${prices_str[2]} =~ $numcheck ]]; then
# converts the prices from string to integer and adds it to a prices list
for price in "${prices_str[@]}"; do
	price1=$(/usr/bin/echo "$price" | /usr/bin/awk '{print $1+0.0}')
	prices+=($price1)
done


# gets current date and time in the required format, to be used to filter records in the database
datetime=$(/usr/bin/date +"%H:%M:%S")
date=$(/usr/bin/date +"%Y-%m-%d")


# inserts the data for the fuel prices, as well as the timestamp into the OILPRICES table
/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOF
SHOW TABLES LIKE 'OILPRICES';
EOF
# handles sql errors and logs them
sqlexists=$?

if [[ $sqlexists != 0 ]]; then

/usr/bin/echo "ERROR	MySQL is Not Functioning Correctly	getPriceData	${curr_time}	49" >> ./cron_log.log

else
# inserts the data for the fuel prices, as well as the timestamp into the OILPRICES table
/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
INSERT INTO CW_1314.READING(TimeReading, MarketDate) 
VALUES ('$datetime', '$date');

SET @DatapointID = LAST_INSERT_ID();

INSERT INTO CW_1314.OILPRICES(DatapointID, OilID, Price) 
VALUES (@DatapointID, 1, ROUND(${prices[0]}, 2)),
	   (@DatapointID, 2, ROUND(${prices[1]}, 2)),
	   (@DatapointID, 3, ROUND(${prices[2]}, 2));
EOFMYSQL

fi

fi

# condition if 
else
/usr/bin/echo "ERROR	Scraper Blocked/Website Down	getPriceData	${curr_time}	71" >> ./cron_log.log
exit 1

fi

# condition if the mysql password is not correctly configured
elif [ -z "${MYSQLPASS}" ]; then
curr_time=$(/usr/bin/date)
/usr/bin/echo "ERROR	Environment Variable for MYSQLPASS Does Not Exist	 getPriceData 	${curr_time}	77" >> ./cron_log.log
exit 1

# condition if the bash commands do not exist
else
curr_time=$(/usr/bin/date)

/usr/bin/echo "ERROR	Necessary commands/environment variables for plotGraph do not exist	plotGraph		$curr_time	310" >> ./cron_log.log
exit 1

fi