component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Spec", function() {
            it( "can get the owned entities", function() {
                var user = getInstance( "User" ).find( 1 );
                var posts = user.getPosts();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );
            } );
        } );
    }

}