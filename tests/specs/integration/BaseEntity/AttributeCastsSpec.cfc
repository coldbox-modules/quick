component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Attribute Casts Spec", function() {
			it( "can specify a cast type for an attribute", function() {
				var activeNumber = getInstance( "PhoneNumber" ).find( 1 );
				expect( activeNumber.getActive() ).toBe( true );
				expect( activeNumber.getActive() ).toBeBoolean();

				var inactiveNumber = getInstance( "PhoneNumber" ).find( 2 );
				expect( inactiveNumber.getActive() ).toBe( false );
				expect( inactiveNumber.getActive() ).toBeBoolean();
			} );

			it( "sets the value back for casts attributes", function() {
				var newNumber = getInstance( "PhoneNumber" );
				newNumber.setNumber( "111-111-1111" );
				newNumber.setActive( true );
				newNumber.save();

				var results = queryExecute( "SELECT * FROM `phone_numbers` WHERE `number` = ?", [ "111-111-1111" ] );
				expect( results ).toHaveLength( 1 );
				expect( results.active ).toBe( 1 );
				expect( results.active ).toBeNumeric();
			} );

			it( "casts values in queries", function() {
				var inactiveNumbers = getInstance( "PhoneNumber" ).where( "active", false ).get();
				expect( inactiveNumbers ).notToBeEmpty();
				expect( inactiveNumbers ).toHaveLength( 1 );
				expect( inactiveNumbers[ 1 ].getId() ).toBe( 2 );
			} );

			it( "can use multiple attributes for casting", function() {
				var user = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				expect( user.getAddress() ).notToBeNull();
				var address = user.getAddress();
				expect( address.fullStreet() ).toBe( "123 Elm Street" );
				expect( address.formatted() ).toBe(
					arrayToList(
						[
							"123 Elm Street",
							"Salt Lake City, UT 84123"
						],
						chr( 10 )
					)
				);
			} );

			it( "can assign multiple attributes from a cast when saving to the database", function() {
				var user    = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				var address = user.getAddress();
				address.setState( "TX" );
				user.save();
				user.refresh();
				expect( user.getState() ).toBe( "TX" );
			} );

			it( "can assign a value object that is then casted", () => {
				var user = getInstance( "User" );
				user.setUsername( "testing_casts" );
				user.setFirstName( "Testing" );
				user.setLastName( "Casts" );
				var newAddress = getInstance( "Address" );
				newAddress.setStreetOne( "123 Elm Street" );
				newAddress.setCity( "Salt Lake City" );
				newAddress.setState( "UT" );
				newAddress.setZip( "84123" );
				user.setAddress( newAddress );
				user.save();

				var fetchedUser = getInstance( "User" ).where( "username", "testing_casts" ).firstOrFail();
				expect( fetchedUser.getUsername() ).toBe( "testing_casts" );
				expect( fetchedUser.getFirstName() ).toBe( "Testing" );
				expect( fetchedUser.getLastName() ).toBe( "Casts" );
				expect( fetchedUser.getAddress() ).notToBeNull();
				expect( fetchedUser.getAddress().formatted() ).toBe( newAddress.formatted() );
			} );

			it( "can cast json data", function() {
				var theme = getInstance( "Theme" ).create( {
					"slug"    : "my-theme",
					"version" : "1.0.0",
					"config"  : {
						"fontFamily"   : "Dank Mono",
						"primaryColor" : "orange"
					}
				} );

				theme.refresh();

				expect( theme.getConfig() ).notToBeNull();
				expect( theme.getConfig() ).toBeStruct();
				expect( theme.getConfig() ).toHaveKey( "fontFamily" );
				expect( theme.getConfig().fontFamily ).toBe( "Dank Mono" );
				expect( theme.getConfig() ).toHaveKey( "primaryColor" );
				expect( theme.getConfig().primaryColor ).toBe( "orange" );
			} );

			it( "can still allow nulls when using casts", () => {
				var pn = getInstance( "PhoneNumber" ).find( 3 );
				expect( pn.isNullAttribute( "confirmed" ) ).toBeTrue( "[confirmed] should be considered null" );
				expect( pn.getConfirmed() ).toBe( "" );
				expect( function() {
					pn.update( { "active" : false } );
				} ).notToThrow( message = "PhoneNumber should be able to be saved with a `null` [confirmed] value" );
			} );
		} );
	}

}
