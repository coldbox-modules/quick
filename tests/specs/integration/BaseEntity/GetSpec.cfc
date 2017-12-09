component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Get Spec", function() {
            it( "finds an entity by the primary key", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getLoaded() ).toBeTrue( "The user instance should be found and loaded, but was not." );
            } );

            it( "it returns null if the record cannot be found", function() {
                expect( getInstance( "User" ).find( 999 ) )
                    .toBeNull( "The user instance should be null because it could not be found, but was not." );
            } );

            it( "can refresh itself from the database", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "new_username", 1 ] );
                expect( user.getUsername() ).toBe( "elpete" );
                user.refresh();
                expect( user.getUsername() ).toBe( "new_username" );
            } );

            it( "can get a fresh instance from the database", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                queryExecute( "UPDATE `users` SET `username` = ? WHERE `id` = ?", [ "new_username", 1 ] );
                expect( user.getUsername() ).toBe( "elpete" );
                var freshUser = user.fresh();
                expect( user.getUsername() ).toBe( "elpete" );
                expect( freshUser.getUsername() ).toBe( "new_username" );
            } );

            describe( "loaded", function() {
                it( "a new entity returns false when asked if it loaded", function() {
                    expect( getInstance( "User" ).getLoaded() ).toBeFalse();
                } );

                it( "an entity loaded from the database returns true when asked if it loaded", function() {
                    expect( getInstance( "User" ).find( 1 ).getLoaded() ).toBeTrue();
                } );
            } );

            it( "throws an exception if no entity is found using find or fail", function() {
                expect( function() {
                    getInstance( "User" ).findOrFail( 1 );
                } ).notToThrow();

                expect( function() {
                    getInstance( "User" ).findOrFail( 999 );
                } ).toThrow( type = "ModelNotFound" );
            } );

            it( "throws an exception if no entity is found using first or fail", function() {
                expect( function() {
                    getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
                } ).notToThrow();

                expect( function() {
                    getInstance( "User" ).whereUsername( "doesnt-exist" ).firstOrFail();
                } ).toThrow( type = "ModelNotFound" );
            } );
        } );
    }

}
