#!/bin/bash

if command -v /usr/bin/echo >&2 && command -v /usr/bin/curl >&2 && command -v /usr/bin/cat >&2 && 
command -v /usr/bin/grep >&2 && command -v /usr/bin/awk >&2 && command -v /usr/bin/mysql >&2 && 
command -v /usr/bin/date && command -v /usr/bin/gnuplot >&2; then

if ! [ -f "/tmp/cron_log.txt" ]; then
	/usr/bin/echo "" > "/tmp/cron_log.txt"
fi

if ! [ -f "./data_BRENT.dat" ]; then
	/usr/bin/echo "" > "./data_BRENT.dat"
fi
if ! [ -f "./data_MURBAN.dat" ]; then
	/usr/bin/echo "" > "./data_MURBAN.dat"
fi
if ! [ -f "./data_WTI.dat" ]; then
	/usr/bin/echo "" > "./data_WTI.dat"
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

# must use longhand method to produce correct output date due to bug in date
date=$(/usr/bin/date +"%Y-%m-%d")


data=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT OilType, MAX(OILPRICE), MIN(OILPRICE), MAX(RecordID)
FROM CW_1314.OILPRICES
WHERE DateReading='${date}'
GROUP BY OilType;

EOFMYSQL
)

data=$(echo "$data" | grep -v "OilType")
BRENTdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==1 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==1 {print $3}'))
WTIdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==2 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==2 {print $3}'))
MURBANdata=($(/usr/bin/echo "$data" | /usr/bin/awk 'NR==3 {print $2}') $(/usr/bin/echo "$data" | /usr/bin/awk 'NR==3 {print $3}'))


# parses the data for Brent
BRENTHighest="${BRENTdata[0]}"
BRENTLowest="${BRENTdata[1]}"
BRENTLatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT OILPRICE
FROM CW_1314.OILPRICES
WHERE DateReading='${date}'
AND OilType='BRENT'
ORDER BY TimeReading DESC
LIMIT 1;
EOFMYSQL
)
BRENTLatest=$(echo "${BRENTLatest}" | grep -v "OILPRICE")
echo "$BRENTLatest"


# extracts the latest data for WTI from OILPRICES

WTIHighest="${WTIdata[0]}"
WTILowest="${WTIdata[1]}"
WTILatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT OILPRICE
FROM CW_1314.OILPRICES
WHERE DateReading='${date}'
AND OilType='WTI'
ORDER BY TimeReading DESC
LIMIT 1;
EOFMYSQL
)
WTILatest=$(echo "${WTILatest}" | grep -v "OILPRICE")


#gets the data for Murban from OILPRICES
MURBANHighest=${MURBANdata[0]}
MURBANLowest=${MURBANdata[1]}
MURBANLatest=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
SELECT OILPRICE
FROM CW_1314.OILPRICES
WHERE DateReading='${date}'
AND OilType='WTI'
ORDER BY TimeReading DESC
LIMIT 1;
EOFMYSQL
)
MURBANLatest=$(echo "${MURBANLatest}" | grep -v "OILPRICE")

# formats datetime for comparison
datetime=$(/usr/bin/date +"%H:%M:%S")

#if the day is almost over, will add the labels for the times when the stock market closed for
# Murban and WTI

if [[ "$datetime" < "23:00:00" && $MURBANdata != "" && $WTIdata != "" && $BRENTdata != "" ]]; then

/usr/bin/gnuplot<< EOF
set terminal png size 1000,600
set output './database/image_${date}.png'
set label "TODAY    \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",18"

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
set title "$datedisplay - Oil Prices" offset 10,0.0 font ",20"
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
set output './database/image_${date}.png'
set label "TODAY    \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",18"

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
set title "$datedisplay - Oil Prices" offset 10,0.0 font ",20"
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
set output './database/image_${date}.png'

set label "Sorry - No Data For ${date}" at graph 0.4,0.5 textcolor rgbcolor "#0c0d0d" font ",18"
plot 1 linecolor "black", 1.005 linecolor "black"
EOF

fi


# extracts and puts the next set of price and time values into the .dat file for future reading
WTI=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'WTI'
              ORDER BY TimeReading DESC
EOFMYSQL
)

WTI=$(/usr/bin/echo "$WTI" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$WTI" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Brent=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'BRENT'
              ORDER BY TimeReading DESC
EOFMYSQL
)

Brent=$(/usr/bin/echo "$Brent" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$Brent" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Murban=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'MURBAN'
              ORDER BY TimeReading DESC
EOFMYSQL
)

Murban=$(/usr/bin/echo "$Murban" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$Murban" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"


fi
else
sudo /usr/bin/echo "Neccessary commands for plotGraph (echo, curl,cat, grep, awk) do not exist on your system" >> /tmp/cron_log.txt
fi
