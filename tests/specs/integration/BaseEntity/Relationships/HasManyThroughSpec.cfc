component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Through Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the related entities through another entity", function() {
                var countryA = getInstance( "Country@something" ).find(
                    "02B84D66-0AA0-F7FB-1F71AFC954843861"
                );
                expect( arrayLen( countryA.getPosts() ) ).toBe( 2 );
                expect( countryA.getPosts()[ 1 ].getPost_Pk() ).toBe( 1245 );
                expect( countryA.getPosts()[ 1 ].getBody() ).toBe(
                    "My awesome post body"
                );
                expect( countryA.getPosts()[ 2 ].getPost_Pk() ).toBe( 523526 );
                expect( countryA.getPosts()[ 2 ].getBody() ).toBe(
                    "My second awesome post body"
                );

                var countryB = getInstance( "Country" ).find(
                    "02BA2DB0-EB1E-3F85-5F283AB5E45608C6"
                );
                expect( countryB.getPosts() ).toHaveLength( 1 );
                expect( countryB.getPosts()[ 1 ].getPost_Pk() ).toBe( 321 );
                expect( countryB.getPosts()[ 1 ].getBody() ).toBe(
                    "My post with a different author"
                );
            } );

            xit( "can get the related entities through any number of intermediate entities including a belongsToMany relationship", function() {
                var country = getInstance( "Country" ).findOrFail(
                    "02B84D66-0AA0-F7FB-1F71AFC954843861"
                );
                var tags = country.getTags();
                expect( tags ).toBeArray();
                expect( tags ).toHaveLength( 2 );
                expect( tags[ 1 ].getId() ).toBe( 1 );
                expect( tags[ 1 ].getName() ).toBe( "programming" );
                expect( tags[ 2 ].getId() ).toBe( 2 );
                expect( tags[ 2 ].getName() ).toBe( "music" );
            } );

            xit( "can get the related entities through any number of intermediate entities including a polymorphic relationship", function() {
                var country = getInstance( "Country" ).findOrFail(
                    "02B84D66-0AA0-F7FB-1F71AFC954843861"
                );
                var comments = country.getComments();
                expect( comments ).toBeArray();
                expect( comments ).toHaveLength( 1 );
                expect( comments[ 1 ].getId() ).toBe( 1 );
                expect( comments[ 1 ].getBody() ).toBe(
                    "I thought this post was great"
                );
            } );
        } );
    }

}
