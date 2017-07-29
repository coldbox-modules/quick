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

            it( "throws an exception if no entity is found using find or fail", function() {
                expect( function() { 
                    getInstance( "User" ).findOrFail( 1 );
                } ).notToThrow();

                expect( function() { 
                    getInstance( "User" ).findOrFail( 999 );
                } ).toThrow( type = "ModelNotFound" );
            } );
        } );
    }

}