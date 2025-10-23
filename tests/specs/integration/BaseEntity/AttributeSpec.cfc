component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Attributes Spec", function() {
			it( "does not put virtual attributes in the cache", function() {
				var virtualAttributeEntity   = getInstance( "User" ).appendVirtualAttribute( "latestPostId" );
				var attributesAfterSubselect = virtualAttributeEntity.retrieveAttributeNames(
					withVirtualAttributes = true
				);
				var newEntityFromVirtualAttributeEntity = virtualAttributeEntity.newEntity();
				var attributesFromNewEntity             = newEntityFromVirtualAttributeEntity.retrieveAttributeNames(
					withVirtualAttributes = true
				);
				var attributesFromFresh = getInstance( "User" ).retrieveAttributeNames( withVirtualAttributes = true );
				expect( attributesAfterSubselect ).toInclude( "latestPostId" );
				expect( attributesFromNewEntity ).toInclude( "latestPostId" );
				expect( attributesFromFresh ).notToInclude( "latestPostId" );
			} );

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

			it( "can set a value to null using the `setColumnName` magic methods", function() {
				var user = getInstance( "User" ).find( 1 );
				expect( user.getUsername() ).toBe( "elpete" );
				user.setUsername( javacast( "null", "" ) );
				expect( user.getUsername() ).toBeNull();
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
				var memento = getInstance( "User" ).getMemento();
				if ( structCount( memento ) != 14 ) {
					var expected = [
						"id",
						"username",
						"firstName",
						"lastName",
						"password",
						"countryId",
						"teamId",
						"createdDate",
						"modifiedDate",
						"type",
						"email",
						"externalID",
						"address",
						"favoritePost_id"
					];
					var missing = duplicate( expected );
					var extra   = [];
					for ( var key in memento ) {
						var existed = arrayDelete( missing, key );
						if ( !existed ) {
							extra.append( key );
						}
					}
					expect( memento ).toHaveLength( 14 );
				}
				expect( memento ).toHaveKey( "id" );
				expect( memento[ "id" ] ).toBe( "" );
				expect( memento ).toHaveKey( "username" );
				expect( memento[ "username" ] ).toBe( "" );
				expect( memento ).toHaveKey( "firstName" );
				expect( memento[ "firstName" ] ).toBe( "" );
				expect( memento ).toHaveKey( "lastName" );
				expect( memento[ "lastName" ] ).toBe( "" );
				expect( memento ).toHaveKey( "password" );
				expect( memento[ "password" ] ).toBe( "" );
				expect( memento ).toHaveKey( "countryId" );
				expect( memento[ "countryId" ] ).toBe( "" );
				expect( memento ).toHaveKey( "teamId" );
				expect( memento[ "teamId" ] ).toBe( "" );
				expect( memento ).toHaveKey( "createdDate" );
				expect( memento[ "createdDate" ] ).toBe( "" );
				expect( memento ).toHaveKey( "modifiedDate" );
				expect( memento[ "modifiedDate" ] ).toBe( "" );
				expect( memento ).toHaveKey( "type" );
				expect( memento[ "type" ] ).toBe( "" );
				expect( memento ).toHaveKey( "email" );
				expect( memento[ "email" ] ).toBe( "" );
				expect( memento ).toHaveKey( "externalId" );
				expect( memento[ "externalId" ] ).toBe( "" );
				expect( memento ).toHaveKey( "address" );
				var address = memento[ "address" ];
				expect( address ).toBeStruct();
				expect( address ).toHaveKey( "streetOne" );
				expect( address[ "streetOne" ] ).toBe( "" );
				expect( address ).toHaveKey( "streetTwo" );
				expect( address[ "streetTwo" ] ).toBe( "" );
				expect( address ).toHaveKey( "city" );
				expect( address[ "city" ] ).toBe( "" );
				expect( address ).toHaveKey( "state" );
				expect( address[ "state" ] ).toBe( "" );
				expect( address ).toHaveKey( "zip" );
				expect( address[ "zip" ] ).toBe( "" );
				expect( memento ).toHaveKey( "favoritePost_id" );
				expect( memento[ "favoritePost_id" ] ).toBe( "" );
			} );

			it( "shows all the attributes in the component casing", function() {
				var memento         = getInstance( "User" ).findOrFail( 1 ).getMemento();
				memento.createdDate = isBoxLang() ? dateTimeFormat( memento.createdDate, "yyyy-MM-dd hh:mm:ss" ) : dateTimeFormat(
					memento.createdDate,
					"yyyy-mm-dd hh:nn:ss"
				);
				memento.modifiedDate = isBoxLang() ? dateTimeFormat( memento.modifiedDate, "yyyy-MM-dd hh:mm:ss" ) : dateTimeFormat(
					memento.modifiedDate,
					"yyyy-mm-dd hh:nn:ss"
				);
				expect( memento ).toBe( {
					"id"           : 1,
					"username"     : "elpete",
					"firstName"    : "Eric",
					"lastName"     : "Peterson",
					"password"     : "5F4DCC3B5AA765D61D8327DEB882CF99",
					"countryId"    : "02B84D66-0AA0-F7FB-1F71AFC954843861",
					"teamId"       : 1,
					"createdDate"  : "2017-07-28 02:06:36",
					"modifiedDate" : "2017-07-28 02:06:36",
					"type"         : "admin",
					"email"        : "",
					"externalId"   : "1234",
					"address"      : {
						"streetOne" : "123 Elm Street",
						"streetTwo" : isBoxLang() ? javacast( "null", "" ) : "",
						"city"      : "Salt Lake City",
						"state"     : "UT",
						"zip"       : "84123"
					},
					"favoritePost_id" : "1245"
				} );
			} );

			// https://github.com/coldbox-modules/quick/issues/127
			it( "can clear an attribute", () => {
				var elpete = getInstance( "User" ).findOrFail( 1 );
				expect( elpete.isNullValue( "password" ) ).toBeFalse();
				elpete.clearAttribute( "password" );
				expect( elpete.isNullValue( "password" ) ).toBeTrue();
				expect( elpete.getPassword() ).toBe( "" );
			} );
		} );
	}

}
