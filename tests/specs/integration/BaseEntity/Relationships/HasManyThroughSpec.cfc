component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Through Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the related entities through another entity", function() {
                var countryA = getInstance( "Country" ).find( 1 );
                expect( countryA.getPosts().count() ).toBe( 2 );
                expect( countryA.getPosts().get( 1 ).getBody() ).toBe( "My awesome post body" );
                expect( countryA.getPosts().get( 2 ).getBody() ).toBe( "My second awesome post body" );

                var countryB = getInstance( "Country" ).find( 2 );
                expect( countryB.getPosts().count() ).toBe( 0 );
            } );
        } );
    }

}