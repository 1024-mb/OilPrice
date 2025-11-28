#!/bin/bash

#Gets day+month+year for title of graph
datetime=$(date +"%a, %B %d")
datedisplay=$(echo "$datetime")
date=$((date +"%D/%M/%Y") | awk -F "/" '{ print $5 "-" $1 "-" $2 }')

BRENTdata=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
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

BRENTdata=$(echo "$BRENTdata" | grep -v "BRENT")
BRENTLatest=$(echo "$BRENTdata" | awk 'NR==1 {print}')
BRENTHighest=$(echo "$BRENTdata" | awk 'NR==2 {print}')
BRENTLowest=$(echo "$BRENTdata" | awk 'NR==3 {print}')

WTIdata=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
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

WTIdata=$(echo "$WTIdata" | grep -v "WTI")
WTILatest=$(echo "$WTIdata" | awk 'NR==1 {print}')
WTIHighest=$(echo "$WTIdata" | awk 'NR==2 {print}')
WTILowest=$(echo "$WTIdata" | awk 'NR==3 {print}')


MURBANdata=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
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

MURBANdata=$(echo "$MURBANdata" | grep -v "MURBAN")
MURBANLatest=$(echo "$MURBANdata" | awk 'NR==1 {print}')
MURBANHighest=$(echo "$MURBANdata" | awk 'NR==2 {print}')
MURBANLowest=$(echo "$MURBANdata" | awk 'NR==3 {print}')

echo "s $MURBANHighest l $MURBANLowest o $MURBANLatest f"
#Plots data for all fuels
# add natural gas: \
#(West Texas Intermediate)
#     "data_NATURAL_GAS.dat" using 1:2 title "Natural Gas" with linespoints linetype 4
gnuplot <<EOF
set terminal png size 1000,600
set output 'image.png'
set label "TODAY" at graph 1.0225,0.66 textcolor rgbcolor "#0c0d0d" font ",18"
set label "Murban Latest:   \$${MURBANLatest}" at graph 1.0275,0.6 textcolor rgbcolor "#1c1c1c"
set label "Murban High:     \$${MURBANHighest}" at graph 1.0275,0.55 textcolor rgbcolor "#1c1c1c"
set label "Murban Low:      \$${MURBANLowest}" at graph 1.0275,0.5 textcolor rgbcolor "#1c1c1c"
set label "Brent Latest:      \$${BRENTLatest}" at graph 1.0275,0.4 textcolor rgbcolor "#1c1c1c"
set label "Brent High:        \$${BRENTHighest}" at graph 1.0275,0.35 textcolor rgbcolor "#1c1c1c"
set label "Brent Low:         \$${BRENTLowest}" at graph 1.0275,0.30 textcolor rgbcolor "#1c1c1c"
set label "WTI Latest:        \$${WTILatest}" at graph 1.0275,0.2 textcolor rgbcolor "#1c1c1c"
set label "WTI High:          \$${WTIHighest}" at graph 1.0275,0.15 textcolor rgbcolor "#1c1c1c"
set label "WTI Low:           \$${WTILowest}" at graph 1.0275,0.1 textcolor rgbcolor "#1c1c1c"

set ylabel "Price Per Barrel / US$" font ",15" offset 1
set xlabel "Time" font ",15"

set timefmt "%H:%M:%S"
set title "$datedisplay - Oil Prices" offset 10,0.0 font ",20"
set xdata time
set format x "%H:%M"
set grid

set key outside
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 1 linewidth 1.5 pointsize 0.9 , \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 2 linewidth 1.5 pointsize 0.9, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 3 linewidth 1.5 pointsize 0.9
EOF

WTI=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT WTI, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

WTI=$(echo "$WTI" | grep -v "WTI	TimeReading")
echo "$WTI" | grep -v "WTI	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"



Brent=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Brent, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

Brent=$(echo "$Brent" | grep -v "Brent TimeReading")
echo "$Brent" | grep -v "Brent	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"



Murban=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Murban, TimeReading FROM CW_1314.OILPRICES
              WHERE DateReading = '${date}'
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

Murban=$(echo "$Murban" | grep -v "Murban TimeReading")
echo "$Murban" | grep -v "Murban	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"


# gnuplot unset key
# plot "data.dat" title "yah blah" -sets the title for the graph
# linetype <value> linecolor <value(RGB)> with linespoints - for line with points
#                                         lines for just lines (no plotting)
# plot multiple graphs with commas in between
# set xrange[min:max] - sets the range on the x axis
# set xlabel "yah"
# set ylabel "yah"
# set terminal png size 800,600
# set ouput "image.png"
# replot to 