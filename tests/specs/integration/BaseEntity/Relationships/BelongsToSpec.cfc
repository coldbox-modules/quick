component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Belongs To Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the owning entity", function() {
                var post = getInstance( "Post" ).find( 1245 );
                var user = post.getAuthor();
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "caches the result of fetching the owning entity", function() {
                controller.getInterceptorService().registerInterceptor( interceptorObject = this );
                var post = getInstance( "Post" ).find( 1245 );
                post.getAuthor();
                post.getAuthor();
                post.getAuthor();
                post.getAuthor();
                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );

            it( "can associate a new entity", function() {
                var newPost = getInstance( "Post" );
                newPost.setBody( "A new post by me!" );
                var user = getInstance( "User" ).find( 1 );
                newPost.author().associate( user ).save();
                expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
                expect( user.posts().count() ).toBe( 3 );
            } );

            it( "can disassociate the existing entity", function() {
                var post = getInstance( "Post" ).find( 1245 );
                expect( post.retrieveAttribute( "user_id" ) ).notToBe( "" );
                var userId = post.retrieveAttribute( "user_id" );
                expect( getInstance( "User" ).find( userId ).posts().count() ).toBe( 2 );
                post.author().dissociate().save();
                expect( post.retrieveAttribute( "user_id" ) ).toBe( "" );
                expect( getInstance( "User" ).find( userId ).posts().count() ).toBe( 1 );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}
