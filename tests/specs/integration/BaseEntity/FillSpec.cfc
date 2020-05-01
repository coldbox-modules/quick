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
				var user = getInstance( "UserFill" );
				expect( user.retrieveAttribute( "firstName" ) ).toBe( "" );
				expect( user.retrieveAttribute( "lastName" ) ).toBe( "" );
				expect( user.retrieveAttribute( "email" ) ).toBe( "" );

				var rc = {
					"DOMAIN"          : "localtest.me",
					"SUBDOMAIN"       : "",
					"aboutMe"         : "I hate this old house...",
					"confirmPassword" : "123",
					"create"          : "",
					"csrf"            : "29DFD33D352C5CA0BF18CECF00B83D3E201CEBCB",
					"email"           : "bob@vila.com",
					"event"           : "registrations.create",
					"fieldnames"      : "firstName,lastName,email,password,confirmPassword,aboutMe,terms,csrf",
					"firstName"       : "Bob",
					"lastName"        : "Vila",
					"last_url"        : "registrations/new/",
					"password"        : "123",
					"terms"           : "on"
				};
				user.fill( attributes = rc, ignoreNonExistentAttributes = "true" );
				expect( user.retrieveAttribute( "firstName" ) ).toBe( "Bob" );
				expect( user.retrieveAttribute( "lastName" ) ).toBe( "Vila" );
				expect( user.retrieveAttribute( "email" ) ).toBe( "bob@vila.com" );
			} );
		} );
	}

}
