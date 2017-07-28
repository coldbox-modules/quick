component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Belongs To Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can get the owning entity", function() {
                var post = getInstance( "Post" ).find( 1 );
                var user = post.getAuthor();
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "caches the result of fetching the owning entity", function() {
                controller.getInterceptorService().registerInterceptor( interceptorObject = this );
                var post = getInstance( "Post" ).find( 1 );
                post.getAuthor();
                post.getAuthor();
                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}