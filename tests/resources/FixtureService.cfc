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
				try {
					acc[ listFirst( fileName, ". " ) ] = {
						"fileName": fileName,
						"contents": deserializeJSON( fileRead( expandPath( getFixturesDirectory() ) & "/#fileName#" ) )
					};
					return acc;
				} catch ( any e ) {
					throw(
						message = "Error trying to deserialize [#fileName#]",
						detail = e.message & " - " & e.detail
					)
				}
				
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

	public FixtureQuery function with( required string mapping ) {
		var mappingFileName = arguments.mapping & ".json";

		if ( !variables.fixtureDefinitions.keyExists( arguments.mapping ) ) {
			throw( "No fixture definitions found for [#mapping#].  Define a [#mappingFileName#] inside [#getFixturesDirectory()#]." );
		}

		return new FixtureQuery(
			mapping = arguments.mapping,
			mappingFileName = mappingFileName,
			definitions = variables.fixtureDefinitions[ mapping ].contents,
			entityService = getEntityService( arguments.mapping )
		);
	}
	
	private any function getEntityService( required string mapping ) {
		return variables.wirebox.containsInstance( arguments.mapping ) ?
			variables.wirebox.getInstance( arguments.mapping ) :
			javacast( "null", "" );
	}

}
