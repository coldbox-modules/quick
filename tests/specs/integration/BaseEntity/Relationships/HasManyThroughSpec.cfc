component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Through Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the related entities through another entity", function() {
                var countryA = getInstance( "Country" ).find( 1 );
                expect( countryA.getPosts().count() ).toBe( 2 );

                var countryB = getInstance( "Country" ).find( 2 );
                expect( countryB.getPosts().count() ).toBe( 0 );
            } );
        } );
    }

}