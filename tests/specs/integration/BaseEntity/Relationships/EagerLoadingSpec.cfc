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
                expect( posts ).toBeArray();
                expect( posts ).toHaveLength( 2 );
                var authors = posts.map( function( post ) {
                    return post.getAuthor();
                } );
                expect( authors ).toBeArray();
                expect( authors ).toHaveLength( 2 );
                if ( arrayLen( variables.queries ) != 2 ) {
                    debug( variables.queries );
                    expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
                }
            } );

            it( "can eager load a has many relationship", function() {
                var users = getInstance( "User" ).with( "posts" ).get();
                expect( users ).toBeArray();
                expect( users ).toHaveLength( 2, "Two users should be returned" );

                var elpete = users[ 1 ];
                expect( elpete.getUsername() ).toBe( "elpete" );
                expect( elpete.getPosts() ).toBeArray();
                expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

                var johndoe = users[ 2 ];
                expect( johndoe.getUsername() ).toBe( "johndoe" );
                expect( johndoe.getPosts() ).toBeArray();
                expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

                if ( arrayLen( variables.queries ) != 2 ) {
                    expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
                }
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}