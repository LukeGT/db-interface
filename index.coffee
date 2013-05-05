
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
    language: language
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
    
    newInterface[method] = do (method, definition) -> (input, callback) ->

      unless callback?
        throw new Error "You must define a callback when calling a database method"

      unless definition.input
        throw new Error "No input validation information found for method '#{ method }'.  This must be included.  "

      # Verify that input to method is correct
      errors = jsonCheck.verify definition.input, input

      if errors
        return callback null, ("Invalid input to database interface method '#{ method }': #{ error }" for error in errors)

      # Transform the input if needed
      if definition.transform?
        input = definition.transform input

      # TODO: This needs to be completely redone
      for name, value of input
        if _conversions[value.constructor.name]?
          input[name] = _conversions[value.constructor.name] value

      language = _languages[database.language]

      unless language[definition.operation]?
        throw new Error "No language operation of the name '#{definition.operation}' exists for the language '#{ database.language }'.  Your options are: #{ key for key of database.language }"

      # Check that the input is valid for the given database operation
      errors = jsonCheck.verify language[definition.operation].input, input

      if errors
        return callback null, ("Invalid input to language '#{ languageName }' method '#{ method }': #{error}" for error in errors)

      # TODO: Allow users to define multiple database users, and specify which statements are executed by which users

      # Generate and perform the query
      queryString = language[definition.operation].transform location, input
      console.log "Performing: #{queryString}"
      database.query queryString, callback

  return newInterface