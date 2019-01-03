component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Polymorphic Has Many Spec", function() {
            it( "can get the related polymorphic entities", function() {
                var postA = getInstance( "Post" ).find( 1245 );
                var postAComments = postA.getComments();
                expect( arrayLen( postAComments ) ).toBe( 2 );

                var postB = getInstance( "Post" ).find( 523526 );
                var postBComments = postB.getComments();
                expect( arrayLen( postBComments ) ).toBe( 0 );

                var videoA = getInstance( "Video" ).find( 1 );
                var videoAComments = videoA.getComments();
                expect( arrayLen( videoAComments ) ).toBe( 0 );

                var videoB = getInstance( "Video" ).find( 2 );
                var videoBComments = videoB.getComments();
                expect( arrayLen( videoBComments ) ).toBe( 1 );
                expect( videoBComments[ 1 ].getBody() ).toBe( "What a great video! So fun!" );
            } );
        } );
    }

}
