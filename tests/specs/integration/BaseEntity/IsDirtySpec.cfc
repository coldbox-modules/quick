component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "isDirty Spec", function() {
            it( "can test to see if an updated entity differs from that created", function() {
                var user = getInstance( "User" ).find( 1 );

				user.fill( { "last_name" = "Peterson" } );
				expect( user.isDirty() ).toBeFalse();

				user.fill( { "last_name" = "peterson" } );
				expect( user.isDirty() ).toBeTrue();

				user.fill( { "last_name" = "Smith" } );
				expect( user.isDirty() ).toBeTrue();

				user.fill( { "last_name" = "Peterson" } );
				expect( user.isDirty() ).toBeFalse();
           } );
        } );
    }

}
