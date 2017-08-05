component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Attributes Spec", function() {
            it( "can get any attribute using the `getColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "can get foreign keys just like any other column", function() {
                var post = getInstance( "Post" ).find( 1 );
                expect( post.getPost_Pk() ).toBe( 1 );
                expect( post.getUser_Id() ).toBe( 1 );
            } );

            it( "can set the value of an attribute using the `setColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                user.setUsername( "new_username" );
                expect( user.getUsername() ).toBe( "new_username" );
            } );

            it( "can retrieve the original attributes of a loaded entity", function() {
                var user = getInstance( "User" ).find( 1 );
                var originalAttributes = user.getAttributes();
                user.setUsername( "new_username" );
                expect( originalAttributes ).notToBe( user.getAttributes() );
                expect( originalAttributes ).toBe( user.getOriginalAttributes() );
            } );

            it( "can fill some attributes while leaving the others alone", function() {
                var user = getInstance( "User" );
                user.setUsername( "janedoe" );
                user.setFirstName( "Jane" );

                expect( user.getUsername() ).toBe( "janedoe" );
                expect( user.getFirstName() ).toBe( "Jane" );
                expect( user.hasAttribute( "last_name" ) ).toBeFalse();

                user.fill( {
                    "first_name" = "Janice",
                    "last_name" = "Doe"
                } );

                expect( user.getUsername() ).toBe( "janedoe" );
                expect( user.getFirstName() ).toBe( "Janice" );
                expect( user.getLastName() ).toBe( "Doe" );
            } );

            describe( "dirty", function() {
                it( "new entites are not dirty", function() {
                    var user = getInstance( "User" );
                    expect( user.isDirty() ).toBeFalse();
                } );

                it( "newly loaded entites are not dirty", function() {
                    var user = getInstance( "User" ).find( 1 );
                    expect( user.isDirty() ).toBeFalse();
                } );

                it( "changing any attribute sets the entity as `dirty`", function() {
                    var user = getInstance( "User" );
                    user.setUsername( "new_username" );
                    expect( user.isDirty() ).toBeTrue();
                } );

                it( "changing a changed attribute back to the original restores the entity to not dirty", function() {
                    var user = getInstance( "User" ).find( 1 );
                    expect( user.getUsername() ).toBe( "elpete" );
                    expect( user.isDirty() ).toBeFalse();
                    user.setUsername( "new_username" );
                    expect( user.isDirty() ).toBeTrue();
                    user.setUsername( "elpete" );
                    expect( user.isDirty() ).toBeFalse();
                } );
            } );
        } );
    }

}