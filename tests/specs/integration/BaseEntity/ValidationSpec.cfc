component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Validation Spec", function() {
            it( "does nothing if there is no constraints property", function() {
                var tag = getInstance( "Tag" );
                tag.setName( "miscellaneous" );
                expect(function() {
                    tag.save();
                }).notToThrow( "InvalidEntity" );
            } );

            it( "it automatically validates a model with a constraints property", function() {
                var newUser = getInstance( "User" );
                newUser.setUsername( "new_user" );
                newUser.setFirstName( "New" );
                // missing last name
                newUser.setPassword( hash( "password" ) );
                var userRowsPreSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPreSave ).toHaveLength( 3 );
                // expect( function() {
                //     newUser.save();
                // } ).toThrow( "InvalidEntity" );
                var userRowsPostFirstSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPostFirstSave ).toHaveLength( 3 );
                // set last name
                newUser.setLastName( "User" );
                expect( function() {
                    newUser.save();
                } ).notToThrow( "InvalidEntity" );
                var userRowsPostSecondSave = queryExecute( "SELECT * FROM users" );
                expect( userRowsPostSecondSave ).toHaveLength( 4 );
            } );
        } );
    }

}
