component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Update Spec", function() {
            it( "update a model directly (without calling save)", function() {
                var user = getInstance( "User" ).find( 2 );
                expect( user.getUsername() ).toBe( "johndoe" );
                expect( user.getFirstName() ).toBe( "John" );
                expect( user.getLastName() ).toBe( "Doe" );
                user.update( { "username": "janedoe", "first_name": "Jane" } );
                user.refresh();
                expect( user.getUsername() ).toBe( "janedoe" );
                expect( user.getFirstName() ).toBe( "Jane" );
                expect( user.getLastName() ).toBe( "Doe" );
            } );

            it( "can ignore non-existant properties", function() {
                var user = getInstance( "User" ).find( 2 );
                expect( user.getUsername() ).toBe( "johndoe" );
                expect( user.getFirstName() ).toBe( "John" );
                expect( user.getLastName() ).toBe( "Doe" );
                user.update(
                    {
                        "username": "janedoe",
                        "first_name": "Jane",
                        "non-existant-property": "any-value"
                    },
                    true
                );
                user.refresh();
                expect( user.getUsername() ).toBe( "janedoe" );
                expect( user.getFirstName() ).toBe( "Jane" );
                expect( user.getLastName() ).toBe( "Doe" );
            } );

            describe( "updateOrCreate", function() {
                it( "updates an existing entity", function() {
                    var user = getInstance( "User" ).updateOrCreate(
                        { "username": "elpete" },
                        { "firstName": "changed" }
                    );
                    expect( user.getId() ).toBe( 1 );
                    expect( user.getUsername() ).toBe( "elpete" );
                    expect( user.getFirstName() ).toBe( "changed" );
                } );

                it( "creates a new entity with both attribute structs filled", function() {
                    var user = getInstance( "User" ).updateOrCreate(
                        { "username": "doesntexist" },
                        {
                            "firstName": "doesnt",
                            "lastName": "exist",
                            "password": "secret"
                        }
                    );
                    expect( user.isLoaded() ).toBeTrue();
                    expect( user.getUsername() ).toBe( "doesntexist" );
                    expect( user.getFirstName() ).toBe( "doesnt" );
                    expect( user.getLastName() ).toBe( "exist" );
                    expect( user.getPassword() ).toBe( "secret" );
                } );
            } );
        } );
    }

}
