#!/bin/bash

if command -v /usr/bin/echo >&2 && command -v /usr/bin/curl >&2 && command -v /usr/bin/cat >&2 && 
command -v /usr/bin/grep >&2 && command -v /usr/bin/awk >&2 && command -v /usr/bin/mysql >&2 && 
command -v /usr/bin/date && command -v /usr/bin/gnuplot >&2; then

if ! [ -f "/tmp/cron_log.txt" ]; then
	/usr/bin/echo "" > "/tmp/cron_log.txt"

elif ! [ -f "./data_BRENT.dat" ]; then
	/usr/bin/echo "" > "./data_BRENT.dat"

elif ! [ -f "./data_MURBAN.dat" ]; then
	/usr/bin/echo "" > "./data_MURBAN.dat"

elif ! [ -f "./data_WTI.dat" ]; then
	/usr/bin/echo "" > "./data_WTI.dat"

elif ! [ -f "./database/day" ]; then
	/usr/bin/mkdir "./database/day"

elif ! [ -f "./database/week" ]; then
	/usr/bin/mkdir ""
fi

#test to check if user's mysql is working correctly
/usr/bin/mysql -u"moiz" -p"${MYSQLPASS}" "CW_1314" <<EOF
SELECT * FROM CW_1314.OILPRICES;
EOF
# handles sql errors and logs them
sqlexists=$?

if [[ $sqlexists == 0 ]]; then

#Gets day+month+year for title of graph
datetime=$(/usr/bin/date +"%a, %B %d")
datedisplay=$(/usr/bin/echo "$datetime")

date=$(/usr/bin/date +"%Y-%m-%d")

data=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT OilID, MAX(Price), MIN(Price), MAX(RecordID)
FROM CW_1314.OILPRICES
WHERE DatapointID IN (SELECT DatapointID FROM READING WHERE MarketDate='${date}')
GROUP BY OilID;

EOFMYSQL
)

data=$(echo "$data" | grep -v "OilType")
BRENTdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==2 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==2 {print $3}'))
WTIdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==3 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==3 {print $3}'))
MURBANdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==4 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==4 {print $3}'))

# parses the data for Brent
BRENTHighest="${BRENTdata[0]}"
BRENTLowest="${BRENTdata[1]}"
BRENTLatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT Price
FROM CW_1314.OILPRICES
WHERE DatapointID = (SELECT DatapointID FROM READING WHERE MarketDate='${date}' ORDER BY READING.TimeReading DESC LIMIT 1)
AND OilID=2
EOFMYSQL
)
BRENTLatest=$(/usr/bin/echo "${BRENTLatest}" | /usr/bin/grep -v "Price")

# extracts the latest data for WTI from OILPRICES
WTIHighest="${WTIdata[0]}"
WTILowest="${WTIdata[1]}"
WTILatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT Price
FROM CW_1314.OILPRICES
WHERE DatapointID = (SELECT DatapointID FROM READING WHERE MarketDate='${date}' ORDER BY READING.TimeReading DESC LIMIT 1)
AND OilID=1
EOFMYSQL
)
WTILatest=$(/usr/bin/echo "${WTILatest}" | /usr/bin/grep -v "Price")


#gets the data for Murban from OILPRICES
MURBANHighest=${MURBANdata[0]}
MURBANLowest=${MURBANdata[1]}
MURBANLatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT Price
FROM CW_1314.OILPRICES
WHERE DatapointID = (SELECT DatapointID FROM READING WHERE MarketDate='${date}' ORDER BY READING.TimeReading DESC LIMIT 1)
AND OilID=3;

EOFMYSQL
)
MURBANLatest=$(/usr/bin/echo "${MURBANLatest}" | /usr/bin/grep -v "Price")


MURBANAvg=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT MarketDate, ROUND(avg(OILPRICES.Price), 2) AS "DAILY AVERAGE"
FROM OILPRICES
JOIN READING ON OILPRICES.DatapointID = READING.DatapointID
WHERE OilID=3
GROUP BY READING.MarketDate;
EOFMYSQL
)
MURBANAvg=$(/usr/bin/echo "$MURBANAvg" | /usr/bin/grep -v "MarketDate")
/usr/bin/echo "$MURBANAvg" | /usr/bin/awk '{ printf "%s %s\n", $1, $2 }' > "data_MURBAN_weekly.dat"


WTIAvg=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT MarketDate, ROUND(avg(OILPRICES.Price), 2) AS "DAILY AVERAGE"
FROM OILPRICES
JOIN READING ON OILPRICES.DatapointID = READING.DatapointID
WHERE OilID=1
GROUP BY READING.MarketDate;
EOFMYSQL
)
WTIAvg=$(/usr/bin/echo "$WTIAvg" | /usr/bin/grep -v "MarketDate")
/usr/bin/echo "$WTIAvg" | /usr/bin/awk '{ printf "%s %s\n", $1, $2 }' > "data_WTI_weekly.dat"


BRENTAvg=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT MarketDate, ROUND(avg(OILPRICES.Price), 2) AS "DAILY AVERAGE"
FROM OILPRICES
JOIN READING ON OILPRICES.DatapointID = READING.DatapointID
WHERE OilID=2
GROUP BY READING.MarketDate;
EOFMYSQL
)
BRENTAvg=$(/usr/bin/echo "$BRENTAvg" | /usr/bin/grep -v "MarketDate")
/usr/bin/echo "$BRENTAvg" | /usr/bin/awk '{ printf "%s %s\n", $1, $2 }' > "data_BRENT_weekly.dat"


# formats datetime for comparison
datetime=$(/usr/bin/date +"%H:%M:%S")

#if the day is almost over, will add the labels for the times when the stock market closed for
# Murban and WTI
if [[ "$datetime" < "23:00:00" && $MURBANdata != "" && $WTIdata != "" && $BRENTdata != "" ]]; then

/usr/bin/gnuplot<< EOF
set terminal png size 1000,600
set output './database/day/image_${date}.png'
set label "TODAY        \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",15"

set label "Murban Latest:   \$${MURBANLatest}" at graph 1.0275,0.6 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban High:     \$${MURBANHighest}" at graph 1.0275,0.55 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban Low:      \$${MURBANLowest}" at graph 1.0275,0.5 textcolor rgbcolor "#1c1c1c" font ",11"

set label "Brent Latest:     \$${BRENTLatest}" at graph 1.0275,0.4 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent High:        \$${BRENTHighest}" at graph 1.0275,0.35 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Low:         \$${BRENTLowest}" at graph 1.0275,0.30 textcolor rgbcolor "#1c1c1c" font ",11"

set label "WTI Latest:        \$${WTILatest}" at graph 1.0275,0.20 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI High:          \$${WTIHighest}" at graph 1.0275,0.15 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI Low:           \$${WTILowest}" at graph 1.0275,0.1 textcolor rgbcolor "#1c1c1c" font ",11"

set ylabel "Price Per Barrel / US$" font ",15" offset 1
set xlabel "Time" font ",15"

set timefmt "%H:%M:%S"
set title "$datedisplay - Oil Prices" offset 7,-0.7 font ",20"
set xdata time
set format x "%H:%M"
set grid

set key outside
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 4 linewidth 1.5 pointsize 0.9, \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 7 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 5 linewidth 1.5 pointsize 0.9

EOF


elif [[ $MURBANdata != "" || $WTIdata != "" || $BRENTdata != "" ]]; then
/usr/bin/gnuplot <<EOF
set terminal png size 1000,600
set output './database/day/image_${date}.png'
set label "TODAY        \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",15"

set label "Murban Latest:   \$${MURBANLatest}" at graph 1.0275,0.6 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban High:     \$${MURBANHighest}" at graph 1.0275,0.55 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban Low:      \$${MURBANLowest}" at graph 1.0275,0.5 textcolor rgbcolor "#1c1c1c" font ",11"

set label "Brent Latest:     \$${BRENTLatest}" at graph 1.0275,0.4 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent High:        \$${BRENTHighest}" at graph 1.0275,0.35 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Low:         \$${BRENTLowest}" at graph 1.0275,0.30 textcolor rgbcolor "#1c1c1c" font ",11"

set label "WTI Latest:        \$${WTILatest}" at graph 1.0275,0.20 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI High:          \$${WTIHighest}" at graph 1.0275,0.15 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI Low:           \$${WTILowest}" at graph 1.0275,0.1 textcolor rgbcolor "#1c1c1c" font ",11"

set label "Murban Closes (11:30)" at graph 0.5,0.05 textcolor rgbcolor "#1c1c1c" font ",7"
set label "WTI Closes (22:30)" at graph 0.75,0.05 textcolor rgbcolor "#1c1c1c" font ",7"

set ylabel "Price Per Barrel / US$" font ",15" offset 1
set xlabel "Time" font ",15"

set timefmt "%H:%M:%S"
set title "$datedisplay - Oil Prices" offset 7,-0.7 font ",20"
set xdata time
set format x "%H:%M"
set grid

set key outside
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 4 linewidth 1.5 pointsize 0.9, \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 7 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 5 linewidth 1.5 pointsize 0.9
EOF

else

/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output './database/day/image_${date}.png'

set label "Sorry - No Data For ${date}" at graph 0.4,0.5 textcolor rgbcolor "#0c0d0d" font ",18"
plot 1 linecolor "black", 1.005 linecolor "black"
EOF

fi
# plots the weekly graph of average prices (past 7 days for each of Brent, Murban and WTI )
if [[ "$datetime" < "23:00:00" && $BRENTAvg != "" && $WTIAvg != "" && $MURBANAvg != "" ]]; then
date_min=$(date -d "${date} - 7 days" +"%Y-%m-%d")
/usr/bin/gnuplot <<EOF
set terminal png size 1000,600
set output './database/week/image_week_${date}.png'

set ylabel "Price Per Barrel / US$" font ",15" offset 1
set xlabel "Date" font ",15"

set timefmt "%Y-%m-%d"
set title "Weekly Oil Prices" offset 7,-0.7 font ",20"
set xdata time
set format x "%Y-%m-%d"
set grid
set xrange ['${date_min}':'${date}']

set key outside
plot "data_BRENT_weekly.dat" using 1:2 title "Brent Crude" with linespoints linetype 4 linewidth 1.5 pointsize 0.9, \
     "data_WTI_weekly.dat" using 1:2 title "WTI Crude" with linespoints linetype 7 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN_weekly.dat" using 1:2 title "Murban Crude" with linespoints linetype 5 linewidth 1.5 pointsize 0.9
EOF


else
/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output './database/week/image_week_${date}.png'

set label "Sorry - No Data For ${date}" at graph 0.4,0.5 textcolor rgbcolor "#0c0d0d" font ",18"
plot 1 linecolor "black", 1.005 linecolor "black"
EOF

fi

BRENTHighest="${BRENTdata[0]}"
BRENTLowest="${BRENTdata[1]}"
BRENTLatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT Price
FROM CW_1314.OILPRICES
WHERE DatapointID = (SELECT DatapointID FROM READING WHERE MarketDate='${date}' ORDER BY TimeReading DESC LIMIT 1)
AND OilID=2;
EOFMYSQL
)
BRENTLatest=$(/usr/bin/echo "${BRENTLatest}" | /usr/bin/grep -v "Price")


# extracts and puts the next set of price and time values into the .dat file for future reading
WTI=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OILPRICES.Price, READING.TimeReading 
              FROM CW_1314.OILPRICES
              INNER JOIN READING
              ON READING.DatapointID = OILPRICES.DatapointID
              WHERE READING.MarketDate = '${date}' AND OILPRICES.OilID = 1;
EOFMYSQL
)

WTI=$(/usr/bin/echo "$WTI" | /usr/bin/grep -v "Price")
/usr/bin/echo "$WTI" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Brent=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OILPRICES.Price, READING.TimeReading 
              FROM CW_1314.OILPRICES
              INNER JOIN READING
              ON READING.DatapointID = OILPRICES.DatapointID
              WHERE READING.MarketDate = '${date}' AND OILPRICES.OilID = 2;
EOFMYSQL
)

Brent=$(/usr/bin/echo "$Brent" | /usr/bin/grep -v "Price")
/usr/bin/echo "$Brent" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Murban=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OILPRICES.Price, READING.TimeReading 
              FROM CW_1314.OILPRICES
              INNER JOIN READING
              ON READING.DatapointID = OILPRICES.DatapointID
              WHERE READING.MarketDate = '${date}' AND OILPRICES.OilID = 3;
EOFMYSQL
)

Murban=$(/usr/bin/echo "$Murban" | /usr/bin/grep -v "Price")
/usr/bin/echo "$Murban" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"

fi
else
sudo /usr/bin/echo "Neccessary commands for plotGraph (echo, curl,cat, grep, awk) do not exist on your system" >> /tmp/cron_log.txt
fi

#SELECT DATE_SUB("2017-06-15", INTERVAL -2 MONTH);