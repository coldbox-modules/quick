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
                expect( posts.toArray() ).toBeArray();
                expect( posts.toArray() ).toHaveLength( 2 );
                var authors = posts.map( function( post ) {
                    return post.getAuthor();
                } );
                expect( authors.toArray() ).toBeArray();
                expect( authors.toArray() ).toHaveLength( 2 );
                if ( arrayLen( variables.queries ) != 2 ) {
                    debug( variables.queries );
                    expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
                }
            } );

            it( "can eager load a has many relationship", function() {
                var users = getInstance( "User" ).with( "posts" ).latest().get();
                expect( users.toArray() ).toBeArray();
                expect( users.toArray() ).toHaveLength( 2, "Two users should be returned" );

                var johndoe = users.toArray()[ 1 ];
                expect( johndoe.getUsername() ).toBe( "johndoe" );
                expect( johndoe.getPosts().toArray() ).toBeArray();
                expect( johndoe.getPosts().toArray() ).toHaveLength( 0, "No posts should belong to johndoe" );

                var elpete = users.toArray()[ 2 ];
                expect( elpete.getUsername() ).toBe( "elpete" );
                expect( elpete.getPosts().toArray() ).toBeArray();
                expect( elpete.getPosts().toArray() ).toHaveLength( 2, "Two posts should belong to elpete" );

                expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}
