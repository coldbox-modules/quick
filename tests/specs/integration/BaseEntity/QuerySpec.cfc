component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Query Spec", function() {
            it( "returns all records as entities", function() {
                var users = getInstance( "User" ).all().toArray();
                expect( users ).toHaveLength( 2, "Two users should exist in the database and be returned." );
                expect( users[ 1 ].getId() ).toBe( 1 );
                expect( users[ 1 ].getUsername() ).toBe( "elpete" );
                expect( users[ 2 ].getId() ).toBe( 2 );
                expect( users[ 2 ].getUsername() ).toBe( "johndoe" );
            } );

            it( "can execute an arbitrary get query", function() {
                var users = getInstance( "User" ).where( "username", "elpete" ).get().toArray();
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