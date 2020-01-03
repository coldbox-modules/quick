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
            it ( "can save and associate new entities mapped by a field other than their primary keys", function () {
                var user = getInstance( "User" ).find( 1 );
                var externalThing = user.externalThings().create( {
                    userID = user.getID(),
                    externalID = user.getExternalID(),
                    value = 'I prefer other keys'
                } );
                expect( externalThing.isLoaded() ).toBeTrue();
                expect( externalThing.getExternalID() ).toBe( user.getExternalID() );
            } );

            it( "can save an id instead of an entity", function() {
                var newPost = getInstance( "Post" );
                newPost.setBody( "A new post by me!" );
                newPost.save();
                expect( newPost.isLoaded() ).toBeTrue();

                var user = getInstance( "User" ).find( 1 );
                newPost = user.posts().save( newPost.keyValue() );
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

            it( "can save many ids at a time", function() {
                var newPostA = getInstance( "Post" );
                newPostA.setBody( "A new post by me!" );
                newPostA.save();
                expect( newPostA.isLoaded() ).toBeTrue();

                var newPostB = getInstance( "Post" );
                newPostB.setBody( "Another new post by me!" );
                newPostB.save();
                expect( newPostB.isLoaded() ).toBeTrue();;

                var user = getInstance( "User" ).find( 1 );
                var posts = user.posts().saveMany( [ newPostA.keyValue(), newPostB ] );

                expect( posts[ 1 ].isLoaded() ).toBeTrue();
                expect( posts[ 1 ].getAuthor().getId() ).toBe( user.getId() );

                expect( posts[ 2 ].isLoaded() ).toBeTrue();
                expect( posts[ 2 ].getAuthor().getId() ).toBe( user.getId() );
            } );

            it( "can sync the array of ids using a relationship setter", function() {
                var newPost = getInstance( "Post" );
                newPost.setBody( "A new post by me!" );
                newPost.save();
                expect( newPost.isLoaded() ).toBeTrue();

                var user = getInstance( "User" ).find( 1 );
                expect( user.getPosts() ).toBeArray();
                expect( user.getPosts() ).toHaveLength( 2 );
                var posts = user.setPosts( newPost );

                var posts = user.fresh().getPosts();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 1 );
                expect( posts[ 1 ].keyValue() ).toBe( newPost.keyValue() );
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

            it( "can first off of the relationship", function() {
                var user = getInstance( "User" ).find( 1 );
                var post = user.posts().first();
                expect( post.keyValue() ).toBe( 1245 );
            } );

            it( "can firstOrFail off of the relationship", function() {
                var user = getInstance( "User" ).find( 2 );
                expect( function() {
                    var post = user.posts().firstOrFail( 7777 );
                } ).toThrow( "EntityNotFound" );
            } );

            it( "can find off of the relationship", function() {
                var user = getInstance( "User" ).find( 1 );
                var post = user.posts().find( 523526 );
                expect( post.keyValue() ).toBe( 523526 );
            } );

            it( "can findOrFail off of the relationship", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( function() {
                    var post = user.posts().findOrFail( 7777 );
                } ).toThrow( "EntityNotFound" );
            } );

            it( "can all off of the relationship", function() {
                var user = getInstance( "User" ).find( 1 );
                var posts = user.posts().all();
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 3 );
            } );
        } );
    }

}
