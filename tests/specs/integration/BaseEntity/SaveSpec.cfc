component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Save Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try {
                        arguments.spec.body();
                    }
                    catch ( any e ) {
                        rethrow;
                    }
                    finally {
                        transaction action="rollback";
                    }
                }
            } );

            it( "inserts the attributes as a new row if it has not been loaded", function() {
                var newUser = getInstance( "User" );
                newUser.setUsername( "new_user" );
                newUser.setFirstName( "New" );
                newUser.setLastName( "User" );
                var userRowsPreSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPreSave ).toHaveLength( 2 );
                newUser.save();
                var userRowsPostSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPostSave ).toHaveLength( 3 );
            } );

            it( "retrieves the generated key when saving a new record", function() {
                var newUser = getInstance( "User" );
                newUser.setUsername( "new_user" );
                newUser.setFirstName( "New" );
                newUser.setLastName( "User" );
                newUser.save();
                expect( newUser.getAttributes() ).toHaveKey( "id" );
            } );

            it( "a saved entity is not dirty", function() {
                var newUser = getInstance( "User" );
                newUser.setUsername( "new_user" );
                newUser.setFirstName( "New" );
                newUser.setLastName( "User" );
                newUser.save();
                expect( newUser.isDirty() ).toBeFalse();
            } );

            it( "updates the attributes of an existing row if it has been loaded", function() {
                var existingUser = getInstance( "User" ).find( 1 );
                existingUser.setUsername( "new_elpete_username" );
                var userRowsPreSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPreSave ).toHaveLength( 2 );
                existingUser.save();
                var userRowsPostSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPostSave ).toHaveLength( 2 );
            } );
        } );
    }

}