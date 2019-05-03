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
                expect( newPost.getAuthor().getId() ).toBe( user.getId() );
            } );

            it( "can saveMany entities at a time", function() {
                var newPostA = getInstance( "Post" );
                newPostA.setBody( "A new post by me!" );
                expect( newPostA.isLoaded() ).toBeFalse();

                var newPostB = getInstance( "Post" );
                newPostB.setBody( "Another new post by me!" );
                expect( newPostB.isLoaded() ).toBeFalse();

                var user = getInstance( "User" ).find( 1 );
                var posts = user.posts().saveMany( [ newPostA, newPostB ] );

                expect( posts[ 1 ].isLoaded() ).toBeTrue();
                expect( posts[ 1 ].getAuthor().getId() ).toBe( user.getId() );

                expect( posts[ 2 ].isLoaded() ).toBeTrue();
                expect( posts[ 2 ].getAuthor().getId() ).toBe( user.getId() );
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
                expect( user.fresh().getPosts() ).toHaveLength( 3 );
            } );
        } );
    }

}
