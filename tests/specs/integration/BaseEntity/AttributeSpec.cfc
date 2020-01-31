component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "Attributes Spec", function() {
            it( "can get any attribute using the `getColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getId() ).toBe( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "can set the value of an attribute using the `setColumnName` magic methods", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                user.setUsername( "new_username" );
                expect( user.getUsername() ).toBe( "new_username" );
            } );

            it( "does not set attributes using the `setColumnName` magic methods during object creation", function() {
                var referral = getInstance( "Referral" ).findOrFail( 1 );
                expect( referral.getType() ).toBeWithCase(
                    "external",
                    "type should be `external` in lowercase because the `setType` method on the `Referral` entity should not be called during creation.  Instead got [#referral.getType()#]."
                );
            } );

            it( "returns a default value if the attribute is not yet set", function() {
                var user = getInstance( "User" );
                expect( user.retrieveAttribute( "username" ) ).toBe( "" );
                expect( user.retrieveAttribute( "username", "default-value" ) ).toBe( "default-value" );
            } );

            it( "throws an exception when trying to set an attribute that does not exist", function() {
                var user = getInstance( "User" );
                expect( function() {
                    user.assignAttribute( "does-not-exist", "any-value" );
                } ).toThrow( type = "AttributeNotFound" );
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

            it( "can reset an entity back to its last loaded data", function() {
                var user = getInstance( "User" ).find( 1 );
                expect( user.getUsername() ).toBe( "elpete" );
                user.setUsername( "new_username" );
                expect( user.getUsername() ).toBe( "new_username" );
                user.reset();
                expect( user.getUsername() ).toBe( "elpete" );
            } );

            it( "shows all the attributes in the memento of a newly created object", function() {
                expect( getInstance( "User" ).getMemento() ).toBe( {
                    "id": "",
                    "username": "",
                    "firstName": "",
                    "lastName": "",
                    "password": "",
                    "countryId": "",
                    "createdDate": "",
                    "modifiedDate": "",
                    "type": "",
                    "email": "",
                    "externalId": ""
                } );
            } );

            it( "shows all the attributes in the component casing", function() {
                expect( getInstance( "User" ).findOrFail( 1 ).getMemento() ).toBe( {
                    "id": 1,
                    "username": "elpete",
                    "firstName": "Eric",
                    "lastName": "Peterson",
                    "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                    "countryId": "02B84D66-0AA0-F7FB-1F71AFC954843861",
                    "createdDate": "2017-07-28 02:06:36",
                    "modifiedDate": "2017-07-28 02:06:36",
                    "type": "admin",
                    "email": "",
                    "externalId": "1234"
                } );
            } );
        } );
    }

}
