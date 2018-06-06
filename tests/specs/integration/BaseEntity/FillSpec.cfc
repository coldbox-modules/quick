component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Fill Spec", function() {
            it( "can fill many properties at once", function() {
                var user = getInstance( "User" );
                expect( user.getAttribute( "username" ) ).toBe( "" );
                expect( user.getAttribute( "first_name" ) ).toBe( "" );
                expect( user.getAttribute( "last_name" ) ).toBe( "" );
                user.fill( {
                    "username" = "JaneDoe",
                    "first_name" = "Jane",
                    "last_name" = "Doe"
                } );
                expect( user.getAttribute( "username" ) ).toBe( "JaneDoe" );
                expect( user.getAttribute( "first_name" ) ).toBe( "Jane" );
                expect( user.getAttribute( "last_name" ) ).toBe( "Doe" );
            } );

            it( "throws an error when trying to fill non-existant properties", function() {
                var user = getInstance( "User" );
                expect( function() {
                    user.fill( {
                        "non-existant-property" = "any-value"
                    } );
                } ).toThrow( type = "AttributeNotFound" );
            } );
        } );
    }

}
