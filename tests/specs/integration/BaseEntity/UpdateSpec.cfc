component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Update Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try { arguments.spec.body(); }
                    catch ( any e ) { rethrow; }
                    finally { transaction action="rollback"; }
                }
            } );

            it( "update a model directly (without calling save)", function() {
                var user = getInstance( "User" ).find( 2 );
                expect( user.getUsername() ).toBe( "johndoe" );
                expect( user.getFirstName() ).toBe( "John" );
                expect( user.getLastName() ).toBe( "Doe" );
                user.update( {
                    "username" = "janedoe",
                    "first_name" = "Jane"
                } );
                user.refresh();
                expect( user.getUsername() ).toBe( "janedoe" );
                expect( user.getFirstName() ).toBe( "Jane" );
                expect( user.getLastName() ).toBe( "Doe" );
            } );
        } );
    }

}