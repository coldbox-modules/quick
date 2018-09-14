component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Spec", function() {
            it( "can get the owned entities", function() {
                var user = getInstance( "User" ).find( 1 );
                var posts = user.getPosts();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );
            } );

            it( "can save and associate new entities", function() {
                var newPost = getInstance( "Post" );
                newPost.setBody( "A new post by me!" );
                expect( newPost.isLoaded() ).toBeFalse();
                var user = getInstance( "User" ).find( 1 );
                newPost = user.posts().save( newPost );
                expect( newPost.isLoaded() ).toBeTrue();
                expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
            } );

            it( "can create new related entities directly", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getPosts() ).toHaveLength( 2 );
                var newPost = user.posts().create( {
                    "body" = "A new post created directly here!"
                } );
                expect( newPost.isLoaded() ).toBeTrue();
                expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
                expect( newPost.getBody() ).toBe( "A new post created directly here!" );
                expect( user.getPosts() ).toHaveLength( 3 );
            } );
        } );
    }

}
