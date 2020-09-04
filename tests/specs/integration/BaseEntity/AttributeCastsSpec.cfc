component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

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
				var user = variables.fixtures
					.with( "User" )
					.asEntity()
					.find( "elpete" );
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
				var user = variables.fixtures
					.with( "User" )
					.asEntity()
					.find( "elpete" );
				var address = user.getAddress();
				address.setState( "TX" );
				user.save();
				user.refresh();
				expect( user.getState() ).toBe( "TX" );
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
		} );
	}

}
