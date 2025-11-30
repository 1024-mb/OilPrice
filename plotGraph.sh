#!/bin/bash

#Gets day+month+year for title of graph
datetime=$(date +"%a, %B %d")
datedisplay=$(/usr/bin/echo "$datetime")
date=$((/usr/bin/date +"%D/%M/%Y") | /usr/bin/awk -F "/" '{ print $5 "-" $1 "-" $2 }')

# gets the max, min and current brent prices
BRENTdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT BRENT FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT BRENT FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY BRENT DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT BRENT FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY BRENT ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses the data for Brent
BRENTdata=$(/usr/bin/echo "$BRENTdata" | /usr/bin/grep -v "BRENT")
BRENTLatest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==1 {print}')
BRENTHighest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==2 {print}')
BRENTLowest=$(/usr/bin/echo "$BRENTdata" | /usr/bin/awk 'NR==3 {print}')


# extracts the latest data for WTI from OILPRICES
WTIdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT WTI FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT WTI FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY WTI DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT WTI FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY WTI ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses this data
WTIdata=$(/usr/bin/echo "$WTIdata" | /usr/bin/grep -v "WTI")
WTILatest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==1 {print}')
WTIHighest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==2 {print}')
WTILowest=$(/usr/bin/echo "$WTIdata" | /usr/bin/awk 'NR==3 {print}')


#gets the data for Murban from OILPRICES
MURBANdata=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              (
              SELECT MURBAN FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT MURBAN FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY MURBAN DESC
              LIMIT 1
              )
              UNION ALL
              (
              SELECT MURBAN FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY MURBAN ASC
              LIMIT 1
              );
EOFMYSQL
)

# parses this data
MURBANdata=$(/usr/bin/echo "$MURBANdata" | /usr/bin/grep -v "MURBAN")
MURBANLatest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==1 {print}')
MURBANHighest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==2 {print}')
MURBANLowest=$(/usr/bin/echo "$MURBANdata" | /usr/bin/awk 'NR==3 {print}')


# formats datetime for comparison
datetime=$(date +"%H:%M:%S")

#if the day is almost over, will add the labels for the times when the stock market closed for
# Murban and WTI

if [[ "$datetime" < "23:00:00" ]]; then
/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output 'image.png'
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

else
/usr/bin/gnuplot <<EOF
set encoding utf8
set terminal pngcairo enhanced
set terminal png size 1000,600
set output 'image.png'
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

fi

# extracts and puts the next set of price and time values into the .dat file for future reading
WTI=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT WTI, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

WTI=$(/usr/bin/echo "$WTI" | /usr/bin/grep -v "WTI	TimeReading")
/usr/bin/echo "$WTI" | /usr/bin/grep -v "WTI	TimeReading" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Brent=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT Brent, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

Brent=$(/usr/bin/echo "$Brent" | /usr/bin/grep -v "Brent TimeReading")
/usr/bin/echo "$Brent" | /usr/bin/grep -v "Brent	TimeReading" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"


# extracts and puts the next set of price and time values into the .dat file for future reading
Murban=$(/usr/bin/mysql -u "moiz" -p"${MYSQLPASS}" "CW_1314" <<EOFMYSQL
              SELECT Murban, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC;
EOFMYSQL
)

Murban=$(/usr/bin/echo "$Murban" | /usr/bin/grep -v "Murban TimeReading")
/usr/bin/echo "$Murban" | /usr/bin/grep -v "Murban	TimeReading" 
/usr/bin/echo "$Murban" | /usr/bin/grep -v "Murban	TimeReading" | /usr/bin/awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"

