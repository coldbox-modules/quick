component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Null Values Spec", function() {
			it( "returns null values as a string by default on non-BoxLang Prime engines", function() {
				var user = getInstance( "User" ).findOrFail( 3 );
				expect( user.getCountryId() ).toBe( isBoxLang() ? javacast( "null", "" ) : "" );
				expect( user.getMemento().countryId ).toBe( "" );
			} );

			it( "saves a column containing an empty string as null in the database by default", function() {
				var user = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				user.setCountryId( "" );
				user.save();
				expect(
					getInstance( "User" )
						.whereId( 1 )
						.whereNull( "country_id" )
						.count()
				).toBe( 1 );
				expect(
					getInstance( "User" )
						.whereId( 1 )
						.whereNotNull( "country_id" )
						.count()
				).toBe( 0 );
			} );

			it( "can set a column to not convert empty strings to null", function() {
				expect( getInstance( "PhoneNumber" ).count() ).toBe( 3 );
				getInstance( "PhoneNumber" )
					.setNumber( "" )
					.setActive( false )
					.save();
				expect( getInstance( "PhoneNumber" ).whereNull( "number" ).count() ).toBe( 0 );
				expect( getInstance( "PhoneNumber" ).whereNotNull( "number" ).count() ).toBe( 4 );
			} );

			it( "can choose a custom value to convert to nulls in the database", function() {
				expect( getInstance( "Song" ).whereNull( "title" ).count() ).toBe( 0 );

				getInstance( "Song" )
					.fill( {
						title       : "",
						downloadUrl : "https://example.com/songs/1"
					} )
					.save();
				expect( getInstance( "Song" ).whereNull( "title" ).count() ).toBe( 0 );

				getInstance( "Song" )
					.fill( {
						title       : "Really_Null",
						downloadUrl : "https://example.com/songs/1"
					} )
					.save();
				expect( getInstance( "Song" ).whereNull( "title" ).count() ).toBe( 0 );

				getInstance( "Song" )
					.fill( {
						title       : "REALLY_NULL",
						downloadUrl : "https://example.com/songs/1"
					} )
					.save();
				expect( getInstance( "Song" ).whereNull( "title" ).count() ).toBe( 1 );
			} );

			// https://github.com/coldbox-modules/quick/issues/157
			it( "can check for null values on newly created entities", () => {
				var newUser = getInstance( "User" ).create( {
					"username"  : "newuser",
					"firstName" : "New",
					"lastName"  : "User"
				} );
				expect( newUser.isNullAttribute( "email" ) ).toBeTrue();
				expect( newUser.isNullValue( "email", "" ) ).toBeTrue();
			} );
		} );
	}

}
