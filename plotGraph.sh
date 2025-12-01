#!/bin/bash

if command -v /usr/bin/echo >&2 && command -v /usr/bin/curl >&2 && command -v /usr/bin/cat >&2 && 
command -v /usr/bin/grep >&2 && command -v /usr/bin/awk >&2 && command -v /usr/bin/mysql >&2 && command -v /usr/bin/gnuplot >&2; then

if ! [ -f "/tmp/cron_log.txt" ]; then
	/usr/bin/echo "" > "/tmp/cron_log.txt"
fi

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
date=$(date +"%Y-%m-%d")

# gets the max, min and current brent prices for a specific day and stores it in a directory for that date
# to allow for historical comparison
BRENTdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
 			  WHERE DateReading = '${date}' AND OILTYPE='BRENT'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='BRENT'
              ORDER BY OilPrice DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='BRENT'
              ORDER BY OILPRICE ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses the data for Brent
BRENTdata=$(/usr/bin/echo "$BRENTdata" | /usr/bin/grep -v "OILPRICE")
BRENTLatest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==1 {print}')
BRENTHighest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==2 {print}')
BRENTLowest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==3 {print}')


# extracts the latest data for WTI from OILPRICES
WTIdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='WTI'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='WTI'
              ORDER BY OILPRICE DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='WTI'
              ORDER BY OILPRICE ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses this data
WTIdata=$(/usr/bin/echo "$WTIdata" | /usr/bin/grep -v "OILPRICE")
WTILatest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==1 {print}')
WTIHighest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==2 {print}')
WTILowest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==3 {print}')


#gets the data for Murban from OILPRICES
MURBANdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='MURBAN'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='MURBAN'
              ORDER BY OILPRICE DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT OILPRICE FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OILTYPE='MURBAN'
              ORDER BY OILPRICE ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses this data
MURBANdata=$(/usr/bin/echo "$MURBANdata" | /usr/bin/grep -v "OILPRICE")
MURBANLatest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==1 {print}')
MURBANHighest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==2 {print}')
MURBANLowest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==3 {print}')


# formats datetime for comparison
datetime=$(date +"%H:%M:%S")
dategraph=$(date +"%Y-%m-%d")

#if the day is almost over, will add the labels for the times when the stock market closed for
# Murban and WTI

if [[ "$datetime" < "23:00:00" && $MURBANdata != "" && $WTIdata != "" && $BRENTdata != "" ]]; then
/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output './database/image_${dategraph}.png'
set label "TODAY    \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",18"
set label "Murban Latest:   \$${MURBANLatest}" at graph 1.0275,0.6 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban High:     \$${MURBANHighest}" at graph 1.0275,0.55 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban Low:      \$${MURBANLowest}" at graph 1.0275,0.5 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Latest:      \$${BRENTLatest}" at graph 1.0275,0.4 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent High:        \$${BRENTHighest}" at graph 1.0275,0.35 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Low:         \$${BRENTLowest}" at graph 1.0275,0.30 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI Latest:        \$${WTILatest}" at graph 1.0275,0.2 textcolor rgbcolor "#1c1c1c" font ",11"
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
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 4 linewidth 1.5 pointsize 0.9 , \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 7 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 5 linewidth 1.5 pointsize 0.9
EOF

elif [[ $MURBANdata != "" || $WTIdata != "" || $BRENTdata != "" ]]; then
/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output './database/image_${date}.png'
set label "TODAY    \$USD" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",18"
set label "Murban Latest:   \$${MURBANLatest}" at graph 1.0275,0.6 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban High:     \$${MURBANHighest}" at graph 1.0275,0.55 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Murban Low:      \$${MURBANLowest}" at graph 1.0275,0.5 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Latest:      \$${BRENTLatest}" at graph 1.0275,0.4 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent High:        \$${BRENTHighest}" at graph 1.0275,0.35 textcolor rgbcolor "#1c1c1c" font ",11"
set label "Brent Low:         \$${BRENTLowest}" at graph 1.0275,0.30 textcolor rgbcolor "#1c1c1c" font ",11"
set label "WTI Latest:        \$${WTILatest}" at graph 1.0275,0.2 textcolor rgbcolor "#1c1c1c" font ",11"
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
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 4 linewidth 1.5 pointsize 0.9 , \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 7 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 5 linewidth 1.5 pointsize 0.9
EOF

else
echo "hello"

/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output './database/image_${date}.png'

set label "Sorry - No Data For ${date}" at graph 0.4,0.5 textcolor rgbcolor "#0c0d0d" font ",18"

plot 1 linecolor "black", \
1.005 linecolor "black"
EOF

fi


# extracts and puts the next set of price and time values into the .dat file for future reading
WTI=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'WTI'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

WTI=$(/usr/bin/echo "$WTI" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$WTI" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Brent=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'BRENT'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

Brent=$(/usr/bin/echo "$Brent" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$Brent" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Murban=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT OilPrice, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}' AND OilType = 'MURBAN'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

Murban=$(/usr/bin/echo "$Murban" | /usr/bin/grep -v "OilPrice")
/usr/bin/echo "$Murban" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"

fi
else
sudo /usr/bin/echo "Neccessary commands for plotGraph (echo, curl,cat, grep, awk) do not exist on your system" >> /tmp/cron_log.txt
fi
