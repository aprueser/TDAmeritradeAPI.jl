# TDAmeritradeAPI

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aprueser.github.io/TDAmeritradeAPI.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aprueser.github.io/TDAmeritradeAPI.jl/dev)
[![Coverage](https://codecov.io/gh/aprueser/TDAmeritradeAPI.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/aprueser/TDAmeritradeAPI.jl)

## TD Ameritrade API
Julia implementation of the TD Ameritrade API.  This package provides convinience functions to format the return JSON into DataFrames.

API Defintion, and basic guides can be found at: https://developer.tdameritrade.com/apis

## Installation
```Julia
Pkg.add("TDAmeritradeAPI")
```

## Usage
```Julia
using TDAmeritradeAPI
using Dates

keys = TDAmeritradeAPI.apiKeys(<your cust key>, "", now(), "", now(), now() - Minute(30), "unauthorized");
```

Call the PriceHistory API and return a JSON String
```Julia
jsonQQQ = TDAmeritradeAPI.api_getPriceHistoryRaw("QQQ", keys)
```

Every method also has a DataFrames("DF") version that will parse the JSON and return a DataFrame
```Julia
dfQQQ = TDAmeritradeAPI.api_getPriceHistoryDF("QQQ", keys)
```

The Price History API additionally provides a "TS", and "TA" get function that return a Temporal.TS and TimeSeries.TimeArray respectivly 

## Ticker Symbol support
Any API call that uses the symbol as part of the URL will not support FUTURES, FOREX, or INDEX symbols with a / or $ in the symbol.  

Any API call that uses the query string, or the message body can encode the symbol and support FUTURES, FOREX, and INDEX symbols

## TimeZone Notes
All Dates are in the America/NewYork timezone as returned by the API  
The Price History DateTime values reflect when the candle was opened

## Symbol examples
- Index Symbols: $SPX.X, $COMPX, $DJI
- Forex Symbols: USD/CAD
- Futures Symbols: /ES, /NQ

## Implementation Notes
At this point only the API calls that do not require authentication are implemented.  Without authentication, these will all return 15 minute delayed data.
Here is the list of implemented API 
+ Quotes
+ Instruments
+ Price History
+ Options Chain
+ Movers
+ Market Hours

Additional API that require Authentication that I will focus on implementing in the near future
+ Authentication
+ Accounts and Trading (Order Creation)
+ Transaction History
+ User Info and Preferences
+ Watchlists
+ WebSocket Streaming Data (Allows access to real-time streaming data, as well as OHLC data for FOREX, and FUTURES not supported by the Price History API)

## Other Notes 
This is very much my first Julia project, and I am certain that there is oportunity to tune the performance of the to DataFrames functions.  
I try to make the output of each API call as "usable" as possible for the average person.  eg. all timeAsLong values are converted at a DateTime, or Date type.
