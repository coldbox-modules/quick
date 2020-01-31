component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function beforeAll() {
        super.beforeAll();
        controller
            .getInterceptorService()
            .registerInterceptor( interceptorObject = this );
    }

    function run() {
        describe( "Subqueries Spec", function() {
            beforeEach( function() {
                variables.queries = [];
            } );

            it( "can add a subquery to an entity", function() {
                var elpete = getInstance( "User" )
                    .withLatestPostId()
                    .findOrFail( 1 );
                expect( elpete.getLatestPostId() ).notToBeNull();
                expect( elpete.getLatestPostId() ).toBe( 523526 );
                expect( variables.queries ).toHaveLength(
                    1,
                    "Only one query should have been executed. #arrayLen( variables.queries )# were instead."
                );
            } );
        } );
    }

    function preQBExecute(
        event,
        interceptData,
        buffer,
        rc,
        prc
    ) {
        arrayAppend( variables.queries, interceptData );
    }

}
