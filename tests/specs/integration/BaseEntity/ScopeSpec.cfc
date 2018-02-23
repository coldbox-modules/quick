component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Scope Spec", function() {
            it( "looks for missing methods as scopes", function() {
                var users = getInstance( "User" ).latest().get().get();
                expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
                expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
                expect( users[ 2 ].getUsername() ).toBe( "elpete" );
            } );
        } );
    }

}
