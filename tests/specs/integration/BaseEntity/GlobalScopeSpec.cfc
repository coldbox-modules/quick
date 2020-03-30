component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Global Scopes Spec", function() {
            it( "can add a global scope to an entity", function() {
                var admins = getInstance( "Admin" ).all();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 2 );
                expect( admins[ 1 ].getId() ).toBe( 1 );
                expect( admins[ 2 ].getId() ).toBe( 4 );
            } );

            it( "can run a query without a global scope", function() {
                var admins = getInstance( "Admin" )
                    .withoutGlobalScope( "ofType" )
                    .all();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 4 );
            } );

            it( "does not prevent adding a scope that was prevented from being global", function() {
                var admins = getInstance( "Admin" )
                    .withoutGlobalScope( "ofType" )
                    .ofType( "admin" )
                    .get();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 2 );
                expect( admins[ 1 ].getId() ).toBe( 1 );
                expect( admins[ 2 ].getId() ).toBe( 4 );
            } );

            it( "applies scopes at the beginning so you can execute in qb and it still has been applied", function() {
                var admins = getInstance( "Admin" ).retrieveQuery().get();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 2 );
                expect( admins[ 1 ].id ).toBe( 1 );
                expect( admins[ 2 ].id ).toBe( 4 );
            } );
        } );
    }

}
