
# Libraries

genericPool = require 'generic-pool'
jsonCheck   = require 'json-checker'

# Private variables

_interface = undefined
_doQuery = undefined

_conversions =
	'Date': (val) ->
		val.getTime() / 1000

# Private methods

checkParams = jsonCheck.verify

# Public methods

# Callback must be in the form _doQuery( query, callback(data, [errors]) )
@setupQuerying = (callback) ->

	_doQuery = callback

@setupConversions = (conversions) ->

	$.extend _conversions, conversions

@setupInterface = (interface) ->

	_interface = interface

	for method, definition of _interface
		
		@[method] = do (definition) -> (params, callback) ->

			unless _doQuery?
				callback null, [ "You must setup the querying method first using the 'setupQuerying' method" ]

			errors = checkParams definition.params, params

			if errors
				callback null, errors
				return

			for name, type of definition.params
				if _conversions[type]?
					params[name] = _conversions[type] params[name]
			
			query = definition.query.replace /\$([a-z_$][a-z_0-9$]+)/gi, (match, group) -> "'#{params[group]}'"

			console.log "Performing #{query}"

			_doQuery query, callback

@getInterface = ->

	_interface
