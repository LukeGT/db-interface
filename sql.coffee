mysql = require 'mysql'

toEqualsSeparatedPairs = (data) ->
  for field, value of data
    "#{ mysql.escape field } = #{ mysql.escape value }"

@insert =

  input:
    values: 'object'

  transform: (location, input) ->

    fields = []
    values = []
    for field, value of input.values
      fields.push mysql.escape field
      values.push mysql.escape value

    "INSERT INTO #{ mysql.escape location } (#{ fields.join ',' }) VALUES (#{ values.join ',' });"

@select =

  input:
    fields: [ 'string' ]
    filters: 'object'

  transform: (location, input) ->

    fields = mysql.escape field for field in input.fields
    conditions = toEqualsSeparatedPairs input.filters

    "SELECT #{ fields ? "*" } FROM #{ mysql.escape location }#{ if conditions.length " WHERE #{ conditions.join ' AND ' }" else "" };"

@update =

  input:
    values: 'object'
    filters: 'object'

  transform: (location, input) ->

    updates = toEqualsSeparatedPairs input.values
    conditions = toEqualsSeparatedPairs input.filters

    "UPDATE #{ mysql.escape location } SET #{ updates.join ',' }#{ if conditions.length " WHERE #{ conditions.join ' AND ' }" else "" };"

@delete =

  input:
    filters: 'object'

  transform: (location, input) ->

    conditions = toEqualsSeparatedPairs input.filters

    "DELETE FROM #{ mysql.escape location } WHERE #{ conditions.join ' AND ' };"

@custom =

  input:
    query: 'string'
    vars: 'object'

  transform: (location, input) ->

    input.vars.location = location
    input.query.replace /\$([a-z_$][a-z_0-9$]+)/gi, (match, group) -> mysql.escape input.vars[group]