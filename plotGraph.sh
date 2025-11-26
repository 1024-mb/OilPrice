#!/bin/bash
datetime=$(date +"%D/%M")
datetime=$(echo "$datetime" | awk -F "/" '{ print $2 "/" $1 "/" $3 }')

gnuplot <<EOF
set terminal png size 800,600
set output 'image.png'

set ylabel "Price / USD"
set timefmt "%H:%M:%S"
set title "Oil Prices -- Period $datetime" offset 0,0.3
set xdata time
set format x "%H:%M"

set key outside
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 1, \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 2, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 3, \
     "data_NATURAL_GAS.dat" using 1:2 title "Natural Gas" with linespoints linetype 4

EOF


WTI=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT WTI, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

WTI=$(echo "$WTI" | grep -v "WTI	TimeReading")
echo "$WTI" | grep -v "WTI	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"



Brent=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Brent, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

Brent=$(echo "$WTI" | grep -v "Brent TimeReading")
echo "$Brent" | grep -v "Brent	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"



Murban=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Murban, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

Murban=$(echo "$Murban" | grep -v "Murban TimeReading")
echo "$Murban" | grep -v "Murban	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"



Natural_Gas=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Natural_Gas, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

Natural_Gas=$(echo "$Natural_Gas" | grep -v "Natural_Gas TimeReading")
echo "$Natural_Gas" | grep -v "Natural_Gas	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_NATURAL_GAS.dat"

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