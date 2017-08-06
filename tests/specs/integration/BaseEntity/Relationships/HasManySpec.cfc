component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Has Many Spec", function() {
            aroundEach( function( spec ) {
                transaction action="begin" {
                    try { arguments.spec.body(); }
                    catch ( any e ) { rethrow; }
                    finally { transaction action="rollback"; }
                }
            } );

            it( "can get the owned entities", function() {
                var user = getInstance( "User" ).find( 1 );
                var posts = user.getPosts();
                expect( posts.toArray() ).toBeArray();
                expect( posts.toArray() ).toHaveLength( 2 );
            } );

            it( "can save and associate new entities", function() {
                var newPost = getInstance( "Post" );
                newPost.setBody( "A new post by me!" );
                expect( newPost.getLoaded() ).toBeFalse();
                var user = getInstance( "User" ).find( 1 );
                newPost = user.posts().save( newPost );
                expect( newPost.getLoaded() ).toBeTrue();
                expect( newPost.getAttribute( "user_id" ) ).toBe( user.getId() );
            } );

            it( "can create new related entities directly", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getPosts().get() ).toHaveLength( 2 );
                var newPost = user.posts().create( {
                    "body" = "A new post created directly here!"
                } );
                expect( newPost.getLoaded() ).toBeTrue();
                expect( newPost.getAttribute( "user_id" ) ).toBe( user.getId() );
                expect( newPost.getBody() ).toBe( "A new post created directly here!" );
                expect( user.getPosts().get() ).toHaveLength( 3 );
            } );
        } );
    }

}