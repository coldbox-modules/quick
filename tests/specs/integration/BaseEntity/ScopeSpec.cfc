component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Scope Spec", function() {
            it( "looks for missing methods as scopes", function() {
                var users = getInstance( "User" ).latest().get().get();
                expect( users ).toHaveLength( 3, "Three users should exist in the database and be returned." );
                expect( users[ 1 ].getUsername() ).toBe( "janedoe" );
                expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
                expect( users[ 3 ].getUsername() ).toBe( "elpete" );
            } );
        } );
    }

}
