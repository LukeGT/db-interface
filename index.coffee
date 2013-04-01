
# Libraries

jsonCheck   = require 'json-checker'

# Private variables

_interface = undefined
_executeQuery = undefined
_escapeString = undefined

_conversions =
	'Date': (val) ->
		val.getTime() / 1000

# Private methods

checkParams = jsonCheck.verify

# Public methods

# Callback must be in the form _executeQuery( query, callback(data, [errors]) )
@setupQuerying = (executeQuery) ->
	_executeQuery = executeQuery

# Defines the function used for escaping values in preparation for insertion within query statements
@setupEscaping = (escapeString) ->
	_escapeString = escapeString

# Adds conversion rules for going from a Javascript object to a database representation
@setupConversions = (conversions) ->
	$.extend _conversions, conversions

# Sets up the database interface using the definition passed in
@setupInterface = (interface) ->
	_interface = interface

	for method, definition of _interface
		
		@[method] = do (definition) -> (params, callback) ->

			unless _executeQuery?
				callback null, [ "You must setup the querying method first using the 'setupQuerying' method" ]
			unless _setupEscaping?
				callback null, [ "You must setup the escaping method first using the 'setupEscaping' method" ]

			errors = checkParams definition.params, params

			if errors
				callback null, errors
				return

			for name, type of definition.params
				if _conversions[type]?
					params[name] = _conversions[type] params[name]
			
			query = definition.query.replace /\$([a-z_$][a-z_0-9$]+)/g, (match, group) -> _escapeString params[group]

			console.log "Performing #{query}"

			_executeQuery query, callback
