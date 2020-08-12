component accessors="true" {

	property name="fixturesDirectory" default="/tests/resources/database/fixtures";
	property name="wirebox" inject="wirebox";

	function init() {
		variables.entityMap = {};
		discoverFixtureDefinitions();
		return this;
	}

	private void function discoverFixtureDefinitions() {
		if ( structKeyExists( variables, "fixtureDefinitions" ) ) {
			return;
		}

		variables.fixtureDefinitions = directoryList( expandPath( getFixturesDirectory() ), false, "name" )
			.reduce( function( acc, fileName ) {
				acc[ listFirst( fileName, ". " ) ] = {
					"fileName": fileName,
					"contents": deserializeJSON( fileRead( expandPath( getFixturesDirectory() ) & "/#fileName#" ) )
				};
				return acc;
			}, {} );
	 }

	public void function seedDatabase() {
		for ( var mapping in variables.fixtureDefinitions ) {
			if ( !variables.entityMap.keyExists( mapping ) ) {
				variables.entityMap[ mapping ] = {};
			}
			if ( variables.wirebox.containsInstance( mapping ) ) {
				var entityService = variables.wirebox.getInstance( mapping );
				for ( var key in variables.fixtureDefinitions[ mapping ].contents ) {
					var attributes = variables.fixtureDefinitions[ mapping ].contents[ key ];
					variables.entityMap[ mapping ][ key ] = entityService.create( attributes );
				}
			} else {
				for ( var key in variables.fixtureDefinitions[ mapping ].contents ) {
					var attributes = variables.fixtureDefinitions[ mapping ].contents[ key ];
					variables.wirebox.getInstance( "QueryBuilder@qb" )
						.table( mapping )
						.insert( attributes );
				}
			}
		}
	}

	public any function onMissingMethod( required string missingMethodName, struct missingMethodArguments = {} ) {
		var mapping = arguments.missingMethodName;
		var mappingFileName = mapping & ".json";

		if ( !variables.fixtureDefinitions.keyExists( mapping ) ) {
			throw( "No fixture definitions found for [#mapping#].  Define a [#mappingFileName#] inside [#getFixturesDirectory()#]." );
		}

		var entityDefinitions = variables.fixtureDefinitions[ mapping ];

		if ( isNull( arguments.missingMethodArguments ) || structCount( arguments.missingMethodArguments ) == 0 ) {
			// return all
		}

		if ( structCount( arguments.missingMethodArguments ) == 1 ) {
			arguments.missingMethodArguments[ 2 ] = false; // asEntity
		}

		var asEntity = arguments.missingMethodArguments[ 2 ];

		if (
			!isArray( arguments.missingMethodArguments[ 1 ] ) ||
			arrayLen( arguments.missingMethodArguments[ 1 ] == 1 )
		) {
			var key = isArray( arguments.missingMethodArguments[ 1 ] ) ?
				arguments.missingMethodArguments[ 1 ][ 1 ] :
				arguments.missingMethodArguments[ 1 ];

			return asEntity ? loadEntity( mapping, key ) : entityDefinitions.contents[ key ];
		}

		return arguments.missingMethodArguments[ 1 ].map( function( key ) {
			if ( !entityDefinitions.contents.keyExists( key ) ) {
				throw( "No definition exists for [#key#] in the [#mappingFileName#] fixture file." );
			}

			return asEntity ? loadEntity( mapping, key ) : entityDefinitions.contents[ key ];
		} );
	}

	private any function loadEntity( mapping, key ) {
		if ( !variables.entityMap.keyExists( mapping ) ) {
			variables.entityMap[ mapping ] = {};
		}
		if ( !variables.entityMap[ mapping ].keyExists( key ) ) {
			var entityService = variables.wirebox.getInstance( mapping );
			var keyValues = entityService.keyNames().map( function( keyName ) {
				return variables.fixtureDefinitions[ mapping ].contents[ key ][ keyName ];
			} );
			variables.entityMap[ mapping ][ key ] = entityService.findOrFail( keyValues );
		}
		return variables.entityMap[ mapping ][ key ];

	}

}
