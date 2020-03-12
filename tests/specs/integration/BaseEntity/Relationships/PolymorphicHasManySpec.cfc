component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Polymorphic Has Many Spec", function() {
            it( "can get the related polymorphic entities", function() {
                var postA = getInstance( "Post" ).find( 1245 );
                var postAComments = postA.getComments();
                expect( postAComments ).toBeArray();
                expect( postAComments ).toHaveLength( 1 );

                var postB = getInstance( "Post" ).find( 523526 );
                var postBComments = postB.getComments();
                expect( postBComments ).toBeArray();
                expect( postBComments ).toBeEmpty();

                var postC = getInstance( "Post" ).find( 321 );
                var postCComments = postC.getComments();
                expect( postCComments ).toBeArray();
                expect( postCComments ).toHaveLength( 1 );

                var videoA = getInstance( "Video" ).find( 1 );
                var videoAComments = videoA.getComments();
                expect( videoAComments ).toBeArray();
                expect( videoAComments ).toBeEmpty();

                var videoB = getInstance( "Video" ).find( 2 );
                var videoBComments = videoB.getComments();
                expect( videoBComments ).toBeArray();
                expect( videoBComments ).toHaveLength( 1 );
                expect( videoBComments[ 1 ].getBody() ).toBe(
                    "What a great video! So fun!"
                );
            } );
        } );
    }

}
