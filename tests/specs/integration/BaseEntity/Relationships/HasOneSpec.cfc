component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Belongs To Spec", function() {
            it( "can get the owning entity", function() {
                var user = getInstance( "User" ).find( 1 );
                var post = user.getLatestPost();
                expect( post.getPost_Pk() ).toBe( 523526 );
            } );
        } );
    }

}
