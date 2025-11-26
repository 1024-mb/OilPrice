#!/bin/bash
MYSQLPASS="344117ABc#"

gnuplot <<EOF
set terminal png size 800,600
set output 'image.png'

set ylabel "Price / USD"
set timefmt "%H:%M:%S"
set xdata time
set format x "%H:%M"
plot "data_BRENT.dat" using 1:2 title "Brent Crude" with linespoints linetype 2, \
     "data_WTI.dat" using 1:2 title "WTI Crude" with linespoints linetype 1, \
     "data_MURBAN.dat" using 1:2 title "Murban Crude" with linespoints linetype 3

EOF


WTI=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT WTI, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

WTI=$(echo "$WTI" | grep -v "WTI TimeReading")
echo "$WTI" | grep -v "WTI	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_WTI.dat"



WTI=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Brent, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

WTI=$(echo "$WTI" | grep -v "Brent TimeReading")
echo "$WTI" | grep -v "Brent	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_BRENT.dat"



WTI=$(mysql -u "${moiz}" -p"${MYSQLPASS}" "${CW_1314}" <<EOFMYSQL
              SELECT Murban, TimeReading FROM CW_1314.OILPRICES
              ORDER BY TimeReading DESC
              LIMIT 20;
EOFMYSQL
)

WTI=$(echo "$WTI" | grep -v "Murban TimeReading")
echo "$WTI" | grep -v "Murban	TimeReading" | awk '{ printf "%s%s %s\n", $2, $3, $1 }' > "data_MURBAN.dat"



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