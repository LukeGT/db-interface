
# Libraries

jsonCheck   = require 'json-checker'

# Private variables

_databases = {}

_languages =
  SQL: require "./sql"

_conversions =
  'Date': (val) ->
    val.getTime() / 1000

# Public methods

# TODO: Make setup follow something more like the builder pattern

# Define how to construct queries for a given language
@defineLangauge = (name, methods) ->
  _languages[name] = methods

# Define a particular database, set it's language, and provide a method which can perform queries on that database
# query: query(queryString, callback(rows, errors))
@defineDatabase = (name, language, query) ->
  _databases[name] =
    language:_languages[language]
    query: query

# Adds conversion rules for going from a Javascript object to a database representation
@setupConversions = (conversions) ->
  for key, value of conversions
    _conversions[key] = value

# Sets up a new database interface using the database, database location, and methods passed in
@createInterface = (database, location, methods) ->

  unless _databases[database]?
    throw new Error "The database '#{ database }' does not exist."

  database = _databases[database]
  newInterface = {}

  for method, definition of methods
    
    newInterface[method] = do (definition) -> (params, callback) ->

      unless callback?
        throw new Error "You must define a callback when calling a database method"

      errors = jsonCheck.verify definition.params, params
      return callback null, ("Database interface error: #{error}" for error in errors) if errors

      for name, value of params
        if _conversions[value.constructor.name]?
          params[name] = _conversions[value.constructor.name] value

      unless database.language[definition.operation]?
        throw new Error "No database operation of the name '#{definition.operation}' exists.  Your options are: #{ key for key of database.language }"

      queryString = database.language[definition.operation] location, params

      console.log "Performing: #{queryString}"

      # TODO: Allow users to define multiple database users, and specify which statements are executed by which users

      database.query queryString, callback

  return newInterface