MYSQLPASS="344117ABc#"
product_url=""

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


echo "${prices[@]}"
datetime=$(date +"%Y-%m-%d %H:%M:%S")

mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
INSERT INTO CW_1314.OILPRICES(RecordID, DateTime_Record, WTI, Brent, Murban, Natural_Gas) 
VALUES ($index, '$datetime', ${prices[0]}, ${prices[1]}, ${prices[2]}, ${prices[3]});
EOFMYSQL
