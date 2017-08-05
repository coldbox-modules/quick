component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Delete Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try { arguments.spec.body(); }
                    catch ( any e ) { rethrow; }
                    finally { transaction action="rollback"; }
                }
            } );

            it( "can delete an entity", function() {
                var user = getInstance( "User" ).findOrFail( 2 );
                user.delete();

                expect( getInstance( "User" ).count() ).toBe( 1 );
                expect( function() {
                    getInstance( "User" ).findOrFail( 2 );
                } ).toThrow( type = "ModelNotFound" );
            } );

            it( "can delete multiple entities at once", function() {
                getInstance( "User" ).deleteAll();
                expect( getInstance( "User" ).count() ).toBe( 0 );
            } );

            it( "can delete off of a query", function() {
                getInstance( "User" ).whereUsername( "johndoe" ).deleteAll();
                expect( getInstance( "User" ).count() ).toBe( 1 );
                expect( function() {
                    getInstance( "User" ).whereUsername( "johndoe" ).firstOrFail();
                } ).toThrow( type = "ModelNotFound" );
            } );
        } );
    }

}