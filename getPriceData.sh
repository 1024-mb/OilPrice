#!/bin/bash

# opens website (preparing to fetch oil prices)
curl -o "response.html" "https://oilprice.com/"

# gets the current record index and increments it - this is to be used as the primary key
index=$(cat index.txt | awk '{print $1+0}')
index=$((index + 1))
echo "$index" > "index.txt"

#gets four prices corresponding to WTI, Brent and Murban at the current time.
prices_str=($(grep -m 5 'class="value"' 'response.html' | awk -F '<[^>]*>' '{print $2}'))
prices=()
price1=0

# converts the prices from string to integer and adds it to a prices list
for price in "${prices_str[@]}"; do
	price1=$(echo "$price" | awk '{print $1+0.0}')
	prices+=($price1)
done


#gets current date and time, to be used to filter records in the database
datetime=$(date +"%H:%M:%S")
date=$((date +"%D/%M/%Y") | awk -F "/" '{ print $5 "-" $1 "-" $2 }')

#inserts the data for the fuel prices, as well as the timestamp into the OILPRICES table
mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
INSERT INTO CW_1314.OILPRICES(RecordID, WTI, Brent, Murban, TimeReading, DateReading) 
VALUES ($index, ${prices[0]}, ${prices[1]}, ${prices[2]}, '$datetime', '$date');
EOFMYSQL
 
