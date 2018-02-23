component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        controller.getInterceptorService().registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "Eager Loading Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can eager load a belongs to relationship", function() {
                var posts = getInstance( "Post" ).with( "author" ).get();
                expect( posts.get() ).toBeArray();
                expect( posts.get() ).toHaveLength( 2 );
                var authors = posts.map( function( post ) {
                    return post.getAuthor();
                } );
                expect( authors.get() ).toBeArray();
                expect( authors.get() ).toHaveLength( 2 );
                expect( authors.get( 1 ) ).notToBeArray();
                expect( authors.get( 1 ) ).toBeInstanceOf( "app.models.User" );
                expect( authors.get( 2 ) ).notToBeArray();
                expect( authors.get( 2 ) ).toBeInstanceOf( "app.models.User" );
                if ( arrayLen( variables.queries ) != 2 ) {
                    debug( variables.queries );
                    expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
                }
            } );

            it( "can eager load a has many relationship", function() {
                var users = getInstance( "User" ).with( "posts" ).latest().get();
                expect( users.get() ).toBeArray();
                expect( users.get() ).toHaveLength( 2, "Two users should be returned" );

                var johndoe = users.get()[ 1 ];
                expect( johndoe.getUsername() ).toBe( "johndoe" );
                expect( johndoe.getPosts().get() ).toBeArray();
                expect( johndoe.getPosts().get() ).toHaveLength( 0, "No posts should belong to johndoe" );

                var elpete = users.get()[ 2 ];
                expect( elpete.getUsername() ).toBe( "elpete" );
                expect( elpete.getPosts().get() ).toBeArray();
                expect( elpete.getPosts().get() ).toHaveLength( 2, "Two posts should belong to elpete" );

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}
