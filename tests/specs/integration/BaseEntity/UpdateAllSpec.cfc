component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Mass Create Spec", function() {
            it( "can mass update all entities that fit the query criteria", function() {
                var postA = getInstance( "Post" ).find( 1245 );
                var postB = getInstance( "Post" ).find( 523526 );

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
