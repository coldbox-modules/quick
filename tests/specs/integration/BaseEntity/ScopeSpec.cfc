component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Scope Spec", function() {
            it( "looks for missing methods as scopes", function() {
                var users = getInstance( "User" ).latest().get();
                expect( users ).toHaveLength( 3, "Three users should exist in the database and be returned." );
                expect( users[ 1 ].getUsername() ).toBe( "janedoe" );
                expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
                expect( users[ 3 ].getUsername() ).toBe( "elpete" );
            } );

            it( "sends through extra parameters as arguments", function() {
                var users = getInstance( "User" ).ofType( "admin" ).get();
                expect( users ).toHaveLength( 1, "One user should exist in the database and be returned." );
                expect( users[ 1 ].getUsername() ).toBe( "elpete" );
            } );

            it( "allows for default arguments if none are passed in", function() {
                var users = getInstance( "User" ).ofType().get();
                expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
                expect( users[ 1 ].getUsername() ).toBe( "johndoe" );
                expect( users[ 2 ].getUsername() ).toBe( "janedoe" );
            } );

            it( "can return values from scopes as well as instances", function() {
                expect( getInstance( "User" ).ofType( "admin" ).resetPasswords() ).toBe( 1 );
            } );
        } );
    }

}
