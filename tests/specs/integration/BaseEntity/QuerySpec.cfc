component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Query Spec", function() {
            it( "returns all records as array", function() {
                var users = getInstance( "User" ).all();
                expect( users ).toHaveLength( 4, "Four users should exist in the database and be returned." );
                expect( users[ 1 ].getId() ).toBe( 1 );
                expect( users[ 1 ].getUsername() ).toBe( "elpete" );
                expect( users[ 2 ].getId() ).toBe( 2 );
                expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
                expect( users[ 3 ].getId() ).toBe( 3 );
                expect( users[ 3 ].getUsername() ).toBe( "janedoe" );
                expect( users[ 4 ].getId() ).toBe( 4 );
                expect( users[ 4 ].getUsername() ).toBe( "elpete2" );
            } );

            it( "can execute an arbitrary get query", function() {
                var users = getInstance( "User" ).where( "username", "elpete" ).get();
                expect( users ).toHaveLength( 1, "One user should be returned." );
                expect( users[ 1 ].getId() ).toBe( 1 );
                expect( users[ 1 ].getUsername() ).toBe( "elpete" );
            } );

            it( "can execute an arbitrary first query", function() {
                var user = getInstance( "User" ).where( "username", "elpete" ).first();
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );
        } );
    }

}
