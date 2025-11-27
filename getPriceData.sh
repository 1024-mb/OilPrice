#!/bin/bash

curl -o "response.html" "https://oilprice.com/"

index=$(cat index.txt | awk '{print $1+0}')
index=$((index + 1))
echo "$index" > "index.txt"

prices_str=($(grep -m 5 'class="value"' 'response.html' | awk -F '<[^>]*>' '{print $2}'))
prices=()
price1=0

for price in "${prices_str[@]}"; do
	price1=$(echo "$price" | awk '{print $1+0.0}')
	prices+=($price1)
done


datetime=$(date +"%H:%M:%S")
date=$((date +"%D/%M/%Y") | awk -F "/" '{ print $5 "-" $1 "-" $2 }')
echo "$date"

mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
INSERT INTO CW_1314.OILPRICES(RecordID, WTI, Brent, Murban, TimeReading, DateReading) 
VALUES ($index, ${prices[0]}, ${prices[1]}, ${prices[2]}, '$datetime', '$date');
EOFMYSQL
