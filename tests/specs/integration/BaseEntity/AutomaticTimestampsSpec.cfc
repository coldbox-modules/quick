component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Automatic Timestamps", function() {
			it( "uses the module setting as the per-entity default", function() {
				var user = getInstance( "AutomaticTimestampUser" );

				expect( user.get_automaticTimestampsDefault() ).toBeTrue();
				expect( user.usesAutomaticTimestamps() ).toBeTrue();
				expect( user.timestampFields() ).toBe( [ "createdDate", "modifiedDate" ] );
			} );

			it( "touches the configured timestamp fields", function() {
				var user                 = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				var originalCreatedDate  = user.getCreatedDate();
				var previousModifiedDate = dateAdd( "d", -1, now() );
				queryExecute(
					"UPDATE users SET modified_date = :modifiedDate WHERE id = 1",
					{
						"modifiedDate" : {
							"value"   : previousModifiedDate,
							"sqltype" : "cf_sql_timestamp"
						}
					}
				);
				user                     = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				var originalModifiedDate = user.getModifiedDate();

				user.touch();
				var freshUser = user.fresh();

				expect( dateCompare( freshUser.getCreatedDate(), originalCreatedDate ) ).toBe( 1 );
				expect( dateCompare( freshUser.getModifiedDate(), originalModifiedDate ) ).toBe( 1 );
			} );

			it( "sets conventional timestamps during inserts and updates", function() {
				var user = getInstance( "AutomaticTimestampUser" ).create( {
					"username"  : "automatic-timestamps",
					"firstName" : "Automatic",
					"lastName"  : "Timestamps",
					"password"  : "secret"
				} );

				expect( user.getCreatedDate() ).toBeDate();
				expect( user.getModifiedDate() ).toBeDate();

				var previousModifiedDate = dateAdd( "d", -1, now() );
				queryExecute(
					"UPDATE users SET modified_date = :modifiedDate WHERE id = :id",
					{
						"modifiedDate" : {
							"value"   : previousModifiedDate,
							"sqltype" : "cf_sql_timestamp"
						},
						"id" : user.getId()
					}
				);
				user = getInstance( "AutomaticTimestampUser" ).findOrFail( user.getId() );
				user.update( { "firstName" : "Updated" } );

				expect( dateCompare( user.getModifiedDate(), previousModifiedDate ) ).toBe( 1 );
			} );

			it( "preserves explicitly assigned timestamps", function() {
				var createdDate  = dateAdd( "y", -1, now() );
				var modifiedDate = dateAdd( "m", -1, now() );
				var user         = getInstance( "AutomaticTimestampUser" ).create( {
					"username"     : "explicit-timestamps",
					"firstName"    : "Explicit",
					"lastName"     : "Timestamps",
					"password"     : "secret",
					"createdDate"  : createdDate,
					"modifiedDate" : modifiedDate
				} );

				expect( dateCompare( user.getCreatedDate(), createdDate ) ).toBe( 0 );
				expect( dateCompare( user.getModifiedDate(), modifiedDate ) ).toBe( 0 );
			} );

			it( "supports component metadata timestamp attribute names", function() {
				var user = getInstance( "AnnotatedTimestampUser" ).create( {
					"username"  : "annotated-timestamps",
					"firstName" : "Annotated",
					"lastName"  : "Timestamps",
					"password"  : "secret"
				} );

				expect( user.getCreatedDate() ).toBeDate();
				expect( user.getModifiedDate() ).toBeDate();
			} );

			it( "can disable automatic timestamps per entity", function() {
				var previousModifiedDate = dateAdd( "d", -1, now() );
				queryExecute(
					"UPDATE users SET modified_date = :modifiedDate WHERE id = 1",
					{
						"modifiedDate" : {
							"value"   : previousModifiedDate,
							"sqltype" : "cf_sql_timestamp"
						}
					}
				);
				var user                 = getInstance( "DisabledAutomaticTimestampUser" ).findOrFail( 1 );
				var originalModifiedDate = user.getModifiedDate();
				user.update( { "firstName" : "No Timestamp" } );

				expect( user.usesAutomaticTimestamps() ).toBeFalse();
				expect( dateCompare( user.refresh().getModifiedDate(), originalModifiedDate ) ).toBe( 0 );
			} );

			it( "does not add SQL for timestamp attributes missing from the entity", function() {
				var country = getInstance( "Country" ).firstOrFail();
				country.update( { "name" : "No Blind Timestamp SQL" } );

				expect( country.getName() ).toBe( "No Blind Timestamp SQL" );
			} );

			it( "can disable automatic timestamps for a builder chain", function() {
				var previousModifiedDate = dateAdd( "d", -1, now() );
				queryExecute(
					"UPDATE users SET modified_date = :modifiedDate WHERE id = 1",
					{
						"modifiedDate" : {
							"value"   : previousModifiedDate,
							"sqltype" : "cf_sql_timestamp"
						}
					}
				);
				var originalModifiedDate = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 ).getModifiedDate();

				getInstance( "AutomaticTimestampUser" )
					.whereId( 1 )
					.withoutAutomaticTimestamps()
					.updateAll( { "firstName" : "Builder Disabled" } );

				var user = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				expect( dateCompare( user.getModifiedDate(), originalModifiedDate ) ).toBe( 0 );
			} );

			it( "adds the update timestamp to normal bulk updates", function() {
				var previousModifiedDate = dateAdd( "d", -1, now() );
				queryExecute(
					"UPDATE users SET modified_date = :modifiedDate WHERE id = 1",
					{
						"modifiedDate" : {
							"value"   : previousModifiedDate,
							"sqltype" : "cf_sql_timestamp"
						}
					}
				);

				getInstance( "AutomaticTimestampUser" ).whereId( 1 ).updateAll( { "firstName" : "Builder Timestamp" } );

				var user = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				expect( dateCompare( user.getModifiedDate(), previousModifiedDate ) ).toBe( 1 );
			} );
		} );
	}

}
