endpoints = Dict{String, Dict{String, String}}(
    "base"                => Dict("uri" => "https://api.tdameritrade.com/v1/",       "type" => "URL"),
# Orders
    "cancel_order"        => Dict("uri" => "accounts/{accountId}/orders/{orderId}",  "type" => "DELETE"),
    "get_order"           => Dict("uri" => "accounts/{accountId}/orders/{orderId}",  "type" => "GET"),
    "get_orders_by_path"  => Dict("uri" => "accounts/{accountId}/orders",            "type" => "GET"),
    "get_orders_by_query" => Dict("uri" => "orders",                                 "type" => "GET"),
    "place_order"         => Dict("uri" => "accounts/{accountId}/orders",            "type" => "POST"),
    "replace_order"       => Dict("uri" => "accounts/{accountId}/orders/{orderId}",  "type" => "PUT"),

# Saved Orders
    "create_saved_order"      => Dict("uri" => "accounts/{accountId}/savedorders",                "type" => "POST"),
    "delete_saved_order"      => Dict("uri" => "accounts/{accountId}/savedorders/{savedOrderId}", "type" => "DELETE"),
    "get_saved_order"         => Dict("uri" => "accounts/{accountId}/savedorders/{savedOrderId}", "type" => "GET"),
    "get_saved_order_by_path" => Dict("uri" => "accounts/{accountId}/savedorders",                "type" => "GET"),
    "replace_saved_order"     => Dict("uri" => "accounts/{accountId}/savedorders/{savedOrderId}", "type" => "PUT"),

# Accounts
    "get_account"         => Dict("uri" => "accounts/{accountId}", "type" => "GET"),
    "get_accounts"        => Dict("uri" => "accounts",             "type" => "GET"),

# Authentication
    "post_access_token"   => Dict("uri" => "oauth2/token",         "type" => "POST"),

# Instruments
    "search_instruments"  => Dict("uri" => "instruments",          "type" => "GET"),
    "get_instrument"      => Dict("uri" => "instruments/{cusip}",  "type" => "GET"),

# Market Hours
    "get_market_hours_for_multiple_markets" => Dict("uri" => "marketdata/hours",          "type" => "GET"),
    "get_market_hours_for_single_market"    => Dict("uri" => "marketdata/{market}/hours", "type" => "GET"),

# Movers
    "get_movers"          => Dict("uri" => "marketdata/{index}/movers",         "type" => "GET"),

# Option Chains
    "get_option_chain"    => Dict("uri" => "marketdata/chains",                 "type" => "GET"),

# Price History
    "get_price_history"   => Dict("uri" => "marketdata/{symbol}/pricehistory",  "type" => "GET"),

# Quotes
    "get_quote"           => Dict("uri" => "marketdata/{symbol}/quotes",        "type" => "GET"),
    "get_quotes"          => Dict("uri" => "marketdata/quotes",                 "type" => "GET"),

# Transaction History
    "get_transaction"     => Dict("uri" => "accounts/{accountId}/transactions/{transactionId}",  "type" => "GET"),
    "get_transactions"    => Dict("uri" => "accounts/{accountId}/transactions",                  "type" => "GET"),

# User Info & Preferences
    "get_preferences"                => Dict("uri" => "accounts/{accountId}/preferences",        "type" => "GET"),
    "get_streamer_subscription_keys" => Dict("uri" => "userprincipals/streamersubscriptionkeys", "type" => "GET"),
    "get_user_principals"            => Dict("uri" => "userprincipals",                          "type" => "GET"),
    "update_preferences"             => Dict("uri" => "accounts/{accountId}/preferences",        "type" => "PUT"),

# Watchlist
    "create_watchlist"                     => Dict("uri" => "accounts/{accountId}/watchlists",               "type" => "POST"),
    "delete_watchlist"                     => Dict("uri" => "accounts/{accountId}/watchlists/{watchlistId}", "type" => "DELETE"),
    "get_watchlist"                        => Dict("uri" => "accounts/{accountId}/watchlists/{watchlistId}", "type" => "GET"),
    "get_watchlists_for_multiple_accounts" => Dict("uri" => "accounts/watchlists",                           "type" => "GET"),
    "get_watchlists_for_single_account"    => Dict("uri" => "accounts/{accountId}/watchlists",               "type" => "GET"),
    "replace_watchlist"                    => Dict("uri" => "accounts/{accountId}/watchlists/{watchlistId}", "type" => "PUT"),
    "update_watchlist"                     => Dict("uri" => "accounts/{accountId}/watchlists/{watchlistId}", "type" => "PATCH")
)

"""
```julia
   listEndpoints()::Dict{String, Dict{String, String}}
```

Return a Dict of all valid TDAmeritrade API endpoints where 
```julia
endpoint_name => {"uri", "type"}
```

# Example
```julia
listEndpoints()
Dict{String, Dict{String, String}} with 37 entries:
  "get_quotes" => Dict("uri"=>"marketdata/quotes", "type"=>"GET")
```
"""
function listEndpoints()::Dict{String, Dict{String, String}}
    return(endpoints)
end

function doHTTPCall(apiEndpoint::String; queryParams::Vector{Pair{String, String}} = Vector{Pair{String, String}}(), 
                                         bodyParams::Dict{String, Union{Number, String, Bool}} = DictDict{String, Union{Number, String, Bool}}(), bearerToken::String = "")::Result{String, String}
    @argcheck haskey(endpoints, apiEndpoint)
    @argcheck length(queryParams) > 0 || length(bodyParams) > 0
    @argcheck (bearerToken == "" && haskey(bodyParams, "apikey")) || startswith(bearerToken, "Bearer ")
    
    ## Lookup the endpoint details 
    endpointURL        = endpoints["base"]["uri"] * endpoints[apiEndpoint]["uri"];
    endpointHTTPMethod = endpoints[apiEndpoint]["type"]

    ## All TDAmeritrade calls send content in application/json, except token refresh authorization calls 
    if apiEndpoint == "post_access_token"
        headers = ["Content-Type" => "application/x-www-form-urlencoded", "Accept" => "application/json"]
    else
        headers = ["Content-Type" => "application/json", "Accept" => "application/json"]
    end

    ## If a authorization token was passed in, include it in the header
    if bearerToken != "" 
        append!(headers, ["Authorization" => bearerToken]) 
    end

    ## Replace the {} placeholders in the URL
    for sub in queryParams
        endpointURL = replace(endpointURL, sub)
    end
    
    if endpointHTTPMethod == "GET"
        uri = HTTP.URI(HTTP.URI(endpointURL), query = bodyParams)
    else
        uri = HTTP.URI(endpointURL)
    end

    @debug "Calling" endpointHTTPMethod " for " uri

    result = endpointHTTPMethod == "GET"    ? HTTP.request("GET", string(uri), headers, status_exception=false)                      :
             endpointHTTPMethod == "PUT"    ? HTTP.request("PUT", string(uri), headers, body = bodyParams, status_exception=false)   :
             endpointHTTPMethod == "POST"   ? HTTP.request("POST", string(uri), headers, body = bodyParams, status_exception=false)  :
             endpointHTTPMethod == "PATCH"  ? HTTP.request("PATCH", string(uri), headers, body = bodyParams, status_exception=false) :
             endpointHTTPMethod == "DELETE" ? HTTP.request("DELETE", string(uri), headers, status_exception=false)                   : 
             Nothing;

    @debug "" result.status

    ## Status:
    ## 200 - OK; Success
    ## 400 - An error message indicating the validation problem with the request.
    ## 401 - An error message indicating the caller must pass valid credentials in the request body
    ## 403 - An error message indicating the caller doesn't have access to make the request.
    ## 404 - An error message indicating the object searched for was not found.
    ## 406 - An error message indicating an issue in the symbol regex, or number of symbols searched is over the maximum.
    ## 429 - An error message indicating the API throttle limit has been reached.
    ## 500 - An error message indicating there was an unexpected server error.
    ## 503 - An error message indicating there is a temporary problem responding.
    ##
    ## The Ameritrade API can return "NaN" for a number, which is not valid JSON, so replace it with null.
    result.status == 200 ? Ok(replace(String(result.body), "\"NaN\"" => "null")) : Err(string(result.status, "::", HTTP.statustext(result.status)))
                                                             
end
