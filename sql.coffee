mysql = require 'mysql'

toEqualsSeparatedPairs = (data) ->
  for field, value of data
    "#{ mysql.escape field } = #{ mysql.escape value }"

@insert = (location, params) ->

  fields = []
  values = []
  for field, value of params.values
    fields.push mysql.escape field
    values.push mysql.escape value

  "INSERT INTO #{ mysql.escape location } (#{ fields.join ',' }) VALUES (#{ values.join ',' });"

@select = (location, params) ->

  fields = mysql.escape field for field in params.fields
  conditions = toEqualsSeparatedPairs params.where

  "SELECT #{ fields ? "*" } FROM #{ mysql.escape location }#{ if conditions.length " WHERE #{ conditions.join ' AND ' }" else "" };"

@update = (location, params) ->

  updates = toEqualsSeparatedPairs params.updates
  conditions = toEqualsSeparatedPairs params.where

  "UPDATE #{ mysql.escape location } SET #{ updates.join ',' }#{ if conditions.length " WHERE #{ conditions.join ' AND ' }" else "" };"

@delete = (location, params) ->

  conditions = toEqualsSeparatedPairs params

  "DELETE FROM #{ mysql.escape location } WHERE #{ conditions.join ' AND ' };"

@custom = (location, params) ->

  params.query.replace /\$([a-z_$][a-z_0-9$]+)/gi, (match, group) -> mysql.escape params.vars[group]