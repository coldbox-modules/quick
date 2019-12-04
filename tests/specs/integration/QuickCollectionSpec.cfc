component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        controller.getInterceptorService().registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "Quick Collection Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can load a relationship lazily", function() {
                var posts = getInstance( "CollectionPost" ).all();
                expect( variables.queries ).toHaveLength( 1 );
                expectAll( posts.get() ).toSatisfy( function( post ) {
                    return ! post.isRelationshipLoaded( "author" );
                }, "The relationship should not be loaded." );
                posts.load( "author" );
                expect( variables.queries ).toHaveLength( 2 );
                expectAll( posts.get() ).toSatisfy( function( post ) {
                    return post.isRelationshipLoaded( "author" );
                }, "The relationship should now be loaded." );
            } );
        } );
    }

    function preQBExecute( event, interceptData, buffer, rc, prc ) {
        arrayAppend( variables.queries, interceptData );
    }

}
