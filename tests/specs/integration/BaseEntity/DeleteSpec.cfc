component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Delete Spec", function() {
			it( "can delete an entity", function() {
				var user = getInstance( "User" ).where( "username", "johndoe" ).firstOrFail();
				user.delete();

				expect( getInstance( "User" ).count() ).toBe( 4 );
				expect( function() {
					getInstance( "User" ).where( "username", "johndoe" ).firstOrFail();
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "can delete multiple entities at once", function() {
				getInstance( "User" ).deleteAll();
				expect( getInstance( "User" ).count() ).toBe( 0 );
			} );

			it( "can delete off of a query", function() {
				getInstance( "User" ).whereUsername( "johndoe" ).deleteAll();
				expect( getInstance( "User" ).count() ).toBe( 4 );
				expect( function() {
					getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
				} ).toThrow( type = "EntityNotFound" );
			} );

			it( "can delete multiple ids at once", function() {
				getInstance( "User" ).deleteAll( [ 2 ] );
				expect( getInstance( "User" ).count() ).toBe( 4 );
				expect( function() {
					getInstance( "User" ).where( "username", "johndoe" ).firstOrFail();
				} ).toThrow( type = "EntityNotFound" );
			} );

			// https://github.com/coldbox-modules/quick/issues/124
			it( "can deleteAll off of a hasMany relationship", () => {
				var elpete = getInstance( "User" ).findOrFail( 1 );
				elpete.posts().deleteAll();
				elpete.purchases().deleteAll();
			} );
		} );
	}

}
