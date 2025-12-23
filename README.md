# Oil Price Collector & Graphing System

### Example Graphs:
<img width="899" height="546" alt="image" src="https://github.com/user-attachments/assets/39d263b4-d068-4dd4-9f36-c5bc666083f2" />
<img width="907" height="534" alt="image" src="https://github.com/user-attachments/assets/0eb4d262-c878-45c8-a492-dd66c3e9a018" />


## Overview
This project is an automated system for collecting, storing, and visualizing crude oil prices from the web. It consists of UNIX shell scripts that scrape oil price data, store it in a MySQL database, and generate daily and weekly graphs using gnuplot.

## Features
- Automated web scraping of oil prices every 15 minutes
- Data validation and error handling
- MySQL database storage for historical data
- Daily and weekly graph generation (PNG format)
- Support for multiple oil types: WTI, Brent, and Murban
- Logging and error reporting

## How It Works

### Data Collection Script (`getPriceData.sh`)
Checks for required commands (`curl`, `grep`, `awk`, `mysql`), scrapes price data from `OilPrices` website, validates website response and data integrity, and inserts prices with timestamp into MySQL.

### Graph Plotting Script
Retrieves data from MySQL, generates daily price charts with latest values, produces weekly average charts, and adds market closure labels and error messages if data is missing.

### Database
Stores oil prices, timestamps, and oil type information. Used for historical queries and averaging.

## Database Schema
The system uses four main tables:

**OILPRICES**
- RecordID
- OilID
- DatapointID
- Price

**OILTYPE**
- OilID
- OilName

**READING**
- DatapointID
- TimeReading
- MarketDate

**DAY**
- MarketDate
- MaxPrice
- MinPrice

## Setup Instructions

### Prerequisites
- UNIX-like environment (Linux, macOS)
- MySQL server
- Required commands: `curl`, `grep`, `awk`, `cat`, `mysql`, `gnuplot`

### Installation
1. Clone the repository: git clone <repository-url>

2. Configure MySQL:
<img width="692" height="384" alt="image" src="https://github.com/user-attachments/assets/e3f4251c-627e-4918-84ca-b368b1e02222" />

- Create database `CW_1314`
- Create user `moiz` with appropriate permissions (or modify username in code)
- Set up tables as per schema above
- Set `MYSQLPASS` environment variable

3. Schedule the script via crontab:
- 15 * * * * /home/moiz/COMP1314_Linux/Assignment/getPriceData.sh

## Output
- Daily graph: `./database/image_YYYY-MM-DD.png`
- Weekly graph: `./database/week/image_week_YYYY-MM-DD.png`
- Log files: `./cron_log.log`, `/tmp/cron_log.txt`
- Data files: `./data_BRENT.dat`, `./data_WTI.dat`, `./data_MURBAN.dat`

## Development
- Version controlled via Git with 17 commits over 3 weeks
- Code hosted on GitHub
- Regular commits and reverts used during development

## Notes
- The system is configured for high-frequency updates due to volatile oil prices
- Includes error handling for website downtime, SQL issues, and missing data
- Graphs include labels for market closure times and daily summaries

## Author
Moiz Sajjad
