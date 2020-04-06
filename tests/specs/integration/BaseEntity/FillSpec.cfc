component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Fill Spec", function() {
			it( "can fill many properties at once", function() {
				var user = getInstance( "User" );
				expect( user.retrieveAttribute( "username" ) ).toBe( "" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "" );
				user.fill( {
					"username"   : "JaneDoe",
					"first_name" : "Jane",
					"last_name"  : "Doe"
				} );
				expect( user.retrieveAttribute( "username" ) ).toBe( "JaneDoe" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "Jane" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "Doe" );
			} );

			it( "throws an error when trying to fill non-existant properties", function() {
				var user = getInstance( "User" );
				expect( function() {
					user.fill( { "non-existant-property" : "any-value" } );
				} ).toThrow( type = "AttributeNotFound" );
			} );

			it( "can ignore non-existant properties", function() {
				var user = getInstance( "User" );
				expect( user.retrieveAttribute( "username" ) ).toBe( "" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "" );
				user.fill(
					{
						"username"              : "JaneDoe",
						"first_name"            : "Jane",
						"last_name"             : "Doe",
						"non-existant-property" : "any-value"
					},
					true
				);
				expect( user.retrieveAttribute( "username" ) ).toBe( "JaneDoe" );
				expect( user.retrieveAttribute( "first_name" ) ).toBe( "Jane" );
				expect( user.retrieveAttribute( "last_name" ) ).toBe( "Doe" );
			} );
		} );
	}

}
