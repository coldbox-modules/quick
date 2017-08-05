component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Polymorphic Has Many Spec", function() {
            it( "can get the related polymorphic entities", function() {
                var postA = getInstance( "Post" ).find( 1 );
                var postAComments = postA.getComments();
                expect( postAComments.count() ).toBe( 2 );

                var postB = getInstance( "Post" ).find( 2 );
                var postBComments = postB.getComments();
                expect( postBComments.count() ).toBe( 0 );

                var videoA = getInstance( "Video" ).find( 1 );
                var videoAComments = videoA.getComments();
                expect( videoAComments.count() ).toBe( 0 );

                var videoB = getInstance( "Video" ).find( 2 );
                var videoBComments = videoB.getComments();
                expect( videoBComments.count() ).toBe( 1 );
                expect( videoBComments.get( 1 ).getBody() ).toBe( "What a great video! So fun!" );
            } );
        } );
    }

}