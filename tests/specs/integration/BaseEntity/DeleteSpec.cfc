component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Delete Spec", function() {
			it( "can delete an entity", function() {
				var user = getInstance( "User" ).findOrFail( 2 );
				user.delete();

				expect( getInstance( "User" ).count() ).toBe( 3 );
				expect( function() {
					getInstance( "User" ).findOrFail( 2 );
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "can delete multiple entities at once", function() {
				getInstance( "User" ).deleteAll();
				expect( getInstance( "User" ).count() ).toBe( 0 );
			} );

			it( "can delete off of a query", function() {
				getInstance( "User" ).whereUsername( "johndoe" ).deleteAll();
				expect( getInstance( "User" ).count() ).toBe( 3 );
				expect( function() {
					getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "can delete multiple ids at once", function() {
				getInstance( "User" ).deleteAll( [ 2 ] );
				expect( getInstance( "User" ).count() ).toBe( 3 );
				expect( function() {
					getInstance( "User" ).findOrFail( 2 );
				} ).toThrow( type = "EntityNotFound" );
			} );
		} );
	}

}
