component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Attributes Spec", function() {
            it( "can get any attribute using the `getColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "automatically converts camel case method names and snake case attribute names", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getId() ).toBe( 1 );
                expect( user.getFirstName() ).toBe( "Eric" );
                expect( user.getLastName() ).toBe( "Peterson" );
            } );

            it( "can get foreign keys just like any other column", function() {
                var post = getInstance( "Post" ).find( 1 );
                expect( post.getPostPk() ).toBe( 1 );
                expect( post.getUserId() ).toBe( 1 );
            } );

            it( "can set the value of an attribute using the `setColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                user.setUsername( "new_username" );
                expect( user.getUsername() ).toBe( "new_username" );
            } );
        } );
    }

}