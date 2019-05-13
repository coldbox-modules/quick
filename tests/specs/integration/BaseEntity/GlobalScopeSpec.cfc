component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Global Scopes Spec", function() {
            it( "can add a global scope to an entity", function() {
                var admins = getInstance( "Admin" ).all();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 1 );
                expect( admins[ 1 ].getId() ).toBe( 1 );
            } );

            it( "can run a query without a global scope", function() {
                var admins = getInstance( "Admin" ).withoutGlobalScope( "ofType" ).all();
                expect( admins ).toBeArray();
                expect( admins ).toHaveLength( 3 );
            } );

            it( "can apply a global scope constraining a query correctly", function() {
                var users = getInstance( "UserWithGlobalScope" ).get();
                expect ( users ).toBeArray();
                expect( users ).toHaveLength( 2 );
            } );
        } );
    }

}
