component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Mass Create Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try { arguments.spec.body(); }
                    catch ( any e ) { rethrow; }
                    finally { transaction action="rollback"; }
                }
            } );

            it( "can mass update all entities that fit the query criteria", function() {
                var postA = getInstance( "Post" ).find( 1 );
                var postB = getInstance( "Post" ).find( 2 );

                expect( postA.getBody() ).notToBe( "The new body" );
                expect( postB.getBody() ).notToBe( "The new body" );

                getInstance( "Post" ).updateAll( {
                    "body" = "The new body"
                } );

                postA.refresh();
                postB.refresh();

                expect( postA.getBody() ).toBe( "The new body" );
                expect( postB.getBody() ).toBe( "The new body" );
            } );
        } );
    }

}