component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "AutomaticTimestampsSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "AutomaticTimestampsSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Automatic Timestamps", function() {
			it( "uses the module setting as the per-entity default", function() {
				var user = getInstance( "AutomaticTimestampUser" );

				expect( user.get_automaticTimestampsDefault() ).toBeTrue();
				expect( user.usesAutomaticTimestamps() ).toBeTrue();
				expect( user.timestampFields() ).toBe( [ "createdDate", "modifiedDate" ] );
			} );

			it( "touches the configured timestamp fields", function() {
				var user                = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				var originalCreatedDate = user.getCreatedDate();
				queryExecute( "UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = 1" );
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

				queryExecute(
					"UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = :id",
					{ "id" : user.getId() }
				);
				user                     = getInstance( "AutomaticTimestampUser" ).findOrFail( user.getId() );
				var previousModifiedDate = user.getModifiedDate();
				user.update( { "firstName" : "Updated" } );

				expect( dateCompare( user.getModifiedDate(), previousModifiedDate ) ).toBe( 1 );
			} );

			it( "sets conventional timestamps before insert and update events", function() {
				structDelete( variables, "preInsertTimestamps" );
				structDelete( variables, "preUpdateTimestamps" );

				var user = getInstance( "AutomaticTimestampUser" ).create( {
					"username"  : "automatic-timestamp-events",
					"firstName" : "Automatic",
					"lastName"  : "Events",
					"password"  : "secret"
				} );

				expect( variables ).toHaveKey( "preInsertTimestamps" );
				expect( variables.preInsertTimestamps.createdDate ).toBeDate();
				expect( variables.preInsertTimestamps.modifiedDate ).toBeDate();

				queryExecute(
					"UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = :id",
					{ "id" : user.getId() }
				);
				user                     = getInstance( "AutomaticTimestampUser" ).findOrFail( user.getId() );
				var previousModifiedDate = user.getModifiedDate();
				user.update( { "firstName" : "Updated" } );

				expect( variables ).toHaveKey( "preUpdateTimestamps" );
				expect( variables.preUpdateTimestamps.modifiedDate ).toBeDate();
				expect( dateCompare( variables.preUpdateTimestamps.modifiedDate, previousModifiedDate ) ).toBe( 1 );
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
				queryExecute( "UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = 1" );
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
				queryExecute( "UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = 1" );
				var originalModifiedDate = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 ).getModifiedDate();

				getInstance( "AutomaticTimestampUser" )
					.whereId( 1 )
					.withoutAutomaticTimestamps()
					.updateAll( { "firstName" : "Builder Disabled" } );

				var user = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				expect( dateCompare( user.getModifiedDate(), originalModifiedDate ) ).toBe( 0 );
			} );

			it( "adds the update timestamp to normal bulk updates", function() {
				queryExecute( "UPDATE users SET modified_date = DATE_SUB(CURRENT_TIMESTAMP, INTERVAL 1 DAY) WHERE id = 1" );
				var previousModifiedDate = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 ).getModifiedDate();

				getInstance( "AutomaticTimestampUser" ).whereId( 1 ).updateAll( { "firstName" : "Builder Timestamp" } );

				var user = getInstance( "AutomaticTimestampUser" ).findOrFail( 1 );
				expect( dateCompare( user.getModifiedDate(), previousModifiedDate ) ).toBe( 1 );
			} );
		} );
	}

	function quickPreInsert(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		if (
			arguments.interceptData.attributes.keyExists( "created_date" )
			&& arguments.interceptData.attributes.keyExists( "modified_date" )
		) {
			variables.preInsertTimestamps = {
				"createdDate"  : arguments.interceptData.attributes.created_date,
				"modifiedDate" : arguments.interceptData.attributes.modified_date
			};
		}
	}

	function quickPreUpdate(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		if ( arguments.interceptData.newAttributes.keyExists( "modified_date" ) ) {
			variables.preUpdateTimestamps = { "modifiedDate" : arguments.interceptData.newAttributes.modified_date };
		}
	}

}
