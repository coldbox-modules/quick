component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Through Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the related entities through another entity", function() {
                var countryA = getInstance( "Country" ).find( '02B84D66-0AA0-F7FB-1F71AFC954843861' );
                expect( countryA.getPosts().count() ).toBe( 2 );
                expect( countryA.getPosts().get( 1 ).getBody() ).toBe( "My awesome post body" );
                expect( countryA.getPosts().get( 2 ).getBody() ).toBe( "My second awesome post body" );

                var countryB = getInstance( "Country" ).find( '02BA2DB0-EB1E-3F85-5F283AB5E45608C6' );
                expect( countryB.getPosts().count() ).toBe( 0 );
            } );
        } );
    }

}
