component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "RetrieveQuery Spec", function() {
			it( "Can call retrieveQuery and expect a query using default coldbox.cfc settings", function() {
				var users = getInstance( "User" )
					.retrieveQuery()
					.get();

				expect( users ).toBeQuery( "Return format should be a query" );
				expect( users ).toHaveLength(5);
			} );

			it( "Can set return format to query and retrieve a query", function() {
				var users = getInstance( "User" )
					.setReturnFormat('query')
					.retrieveQuery()
					.get();

				expect( users ).toBeQuery( "Return format should be a query" );
				expect( users ).toHaveLength(5);
			} );

			it( "Can set return format to array and retrieve a array", function() {
				var users = getInstance( "User" )
					.setReturnFormat('array')
					.retrieveQuery()
					.get();

				expect( users ).toBeArray( "Return format should be an array" );
				expect( users ).toHaveLength(5);
			} );


			it( "Can set return format to query and retrieve a quick entity", function() {
				 //NB! NB! NB!
				 //This test purposefully calls setReturn format AFTER the where clause
				var users = getInstance( "User" )
					.where( "username", "elpete" )
					.setReturnFormat('query')
					.get();

				expect( users ).toHaveLength( 1, "One user should be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
			});

			it( "Can set return format to array and retrieve a quick entity", function() {
				 //NB! NB! NB!
				 //This test purposefully calls setReturn format BEFORE the where clause
				var users = getInstance( "User" )
					.setReturnFormat('array')
					.where( "username", "elpete" )
					.get();

				expect( users ).toHaveLength( 1, "One user should be returned." );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 1 ].getUsername() ).toBe( "elpete" );
			});


		} );
	}

}
