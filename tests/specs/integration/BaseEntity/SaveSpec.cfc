component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller.getInterceptorService().registerInterceptor( interceptorObject = this, interceptorName = "SaveSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "SaveSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Save Spec", function() {
			it( "inserts the attributes as a new row if it has not been loaded", function() {
				var newUser = getInstance( "User" );
				newUser.setUsername( "new_user" );
				newUser.setFirstName( "New" );
				newUser.setLastName( "User" );
				newUser.setPassword( hash( "password" ) );
				var userRowsPreSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPreSave ).toHaveLength( 5 );
				newUser.save();
				var userRowsPostSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPostSave ).toHaveLength( 6 );
				var newUserAgain = getInstance( "User" ).whereUsername( "new_user" ).firstOrFail();
				expect( newUserAgain.getFirstName() ).toBe( "New" );
				expect( newUserAgain.getLastName() ).toBe( "User" );
			} );

			it( "allow inserting of column where update=false in property", function() {
				var newUser = getInstance( "User" );
				newUser.setUsername( "new_user2" );
				newUser.setFirstName( "New2" );
				newUser.setLastName( "User2" );
				newUser.setEmail( "test2@test.com" );
				newUser.setPassword( hash( "password" ) );
				var userRowsPreSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPreSave ).toHaveLength( 5 );
				newUser.save();
				var userRowsPostSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPostSave ).toHaveLength( 6 );
				var newUserAgain = getInstance( "User" ).whereUsername( "new_user2" ).firstOrFail();
				expect( newUserAgain.getFirstName() ).toBe( "New2" );
				expect( newUserAgain.getLastName() ).toBe( "User2" );
				expect( newUserAgain.getEmail() ).toBe( "test2@test.com" );
			} );

			it( "retrieves the generated key when saving a new record", function() {
				var newUser = getInstance( "User" );
				newUser.setUsername( "new_user" );
				newUser.setFirstName( "New" );
				newUser.setLastName( "User" );
				newUser.setPassword( hash( "password" ) );
				newUser.save();
				expect( newUser.retrieveAttributesData() ).toHaveKey( "id" );
			} );

			it( "refreshes database-generated attributes after inserts with one fallback read", function() {
				structDelete( request, "saveSpecPreQBExecute" );
				structDelete( request, "databaseGeneratedUserPostLoadCount" );
				structDelete( request, "databaseGeneratedUserPostInsertCreatedDate" );

				var newUser = getInstance( "DatabaseGeneratedUser" )
					.setUsername( "database-timestamp-user" )
					.setFirstName( "Database" )
					.setLastName( "Timestamp" )
					.save( { "timeout" : 30 } );

				expect( newUser.getCreatedDate() ).notToBe( "" );
				expect( newUser.getCreatedDate() ).toBeDate();
				expect( newUser.getType() ).toBe( "LIMITED" );
				expect( newUser.isDirty( "createdDate" ) ).toBeFalse();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 1 ].options.timeout ).toBe( 30 );
				expect( request.saveSpecPreQBExecute[ 2 ].options.timeout ).toBe( 30 );
				expect( request.databaseGeneratedUserPostLoadCount ).toBe( 1 );
				expect( request.databaseGeneratedUserPostInsertCreatedDate ).toBe( newUser.getCreatedDate() );
			} );

			it( "refreshes database-generated attributes after updates with one fallback read", function() {
				var existingUser        = getInstance( "DatabaseGeneratedUser" ).findOrFail( 1 );
				var originalCreatedDate = existingUser.getCreatedDate();

				structDelete( request, "saveSpecPreQBExecute" );
				structDelete( request, "databaseGeneratedUserPostLoadCount" );
				structDelete( request, "databaseGeneratedUserPostUpdateCreatedDate" );

				existingUser
					.setCreatedDate( dateAdd( "d", 1, originalCreatedDate ) )
					.setType( "POISONED" )
					.setFirstName( "Updated" )
					.save();

				expect( dateCompare( existingUser.getCreatedDate(), originalCreatedDate ) ).toBe( 0 );
				expect( existingUser.getType() ).toBe( "ADMIN" );
				expect( existingUser.isDirty( "createdDate" ) ).toBeFalse();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 2 );
				expect( request.databaseGeneratedUserPostLoadCount ).toBe( 1 );
				expect( request.databaseGeneratedUserPostUpdateCreatedDate ).toBe( existingUser.getCreatedDate() );
			} );

			it( "can disable the refresh-on-save fallback read for one save", function() {
				structDelete( request, "saveSpecPreQBExecute" );

				var newUser = getInstance( "DatabaseGeneratedUser" )
					.setUsername( "database-timestamp-without-fallback" )
					.setFirstName( "Database" )
					.setLastName( "No Fallback" )
					.save( refreshOnSaveFallback = false );

				expect( request.saveSpecPreQBExecute ).toHaveLength( 1 );
				expect( newUser.retrieveAttributesData() ).notToHaveKey( "created_date" );
			} );

			it( "uses the injected global refresh-on-save fallback setting", function() {
				structDelete( request, "saveSpecPreQBExecute" );
				var newUser = getInstance( "DatabaseGeneratedUser" );
				expect( newUser.get_refreshOnSaveFallback() ).toBeTrue();

				newUser
					.set_refreshOnSaveFallback( false )
					.setUsername( "database-timestamp-global-without-fallback" )
					.setFirstName( "Database" )
					.setLastName( "Global No Fallback" )
					.save();

				expect( request.saveSpecPreQBExecute ).toHaveLength( 1 );
				expect( newUser.retrieveAttributesData() ).notToHaveKey( "created_date" );
			} );

			it( "uses native returning support without replacing existing returning columns", function() {
				var entity = getInstance( "DatabaseGeneratedUser" );
				makePublic( entity, "retrieveRefreshOnSaveAttributes" );
				makePublic( entity, "configureRefreshOnSaveReturning" );

				expect( getInstance( "PostgresGrammar@qb" ).supportsReturningRowsOnInsert() ).toBeTrue();
				expect( getInstance( "PostgresGrammar@qb" ).supportsReturningRowsOnUpdate() ).toBeTrue();
				expect( getInstance( "SQLiteGrammar@qb" ).supportsReturningRowsOnInsert() ).toBeTrue();
				expect( getInstance( "SQLiteGrammar@qb" ).supportsReturningRowsOnUpdate() ).toBeTrue();
				expect( getInstance( "SqlServerGrammar@qb" ).supportsReturningRowsOnInsert() ).toBeTrue();
				expect( getInstance( "SqlServerGrammar@qb" ).supportsReturningRowsOnUpdate() ).toBeTrue();
				expect( getInstance( "MySQLGrammar@qb" ).supportsReturningRowsOnInsert() ).toBeFalse();
				expect( getInstance( "MySQLGrammar@qb" ).supportsReturningRowsOnUpdate() ).toBeFalse();

				var builder = entity.newQuery();
				builder
					.getQB()
					.setGrammar( getInstance( "PostgresGrammar@qb" ) )
					.returning( "id" );
				entity.configureRefreshOnSaveReturning(
					builder           = builder,
					attributes        = entity.retrieveRefreshOnSaveAttributes(),
					operation         = "insert",
					includeKeyColumns = true
				);

				var returning       = builder.getQB().getReturning();
				var returningValues = [];
				for ( var returningColumn in returning ) {
					returningValues.append( returningColumn.value );
				}
				expect( returningValues ).toHaveLength( 3 );
				expect( arrayFindNoCase( returningValues, "id" ) ).toBeGT( 0 );
				expect( arrayFindNoCase( returningValues, "created_date" ) ).toBeGT( 0 );
				expect( arrayFindNoCase( returningValues, "type" ) ).toBeGT( 0 );

				var returningSql = builder.getQB().insert( values = { "username" : "native-returning" }, toSql = true );
				expect( returningSql ).toInclude( "RETURNING" );
				expect( returningSql ).toInclude( '"id"' );
				expect( returningSql ).toInclude( '"created_date"' );
				expect( returningSql ).toInclude( '"type"' );

				var updateBuilder = entity.newQuery();
				updateBuilder
					.getQB()
					.setGrammar( getInstance( "PostgresGrammar@qb" ) )
					.where( "id", 1 );
				entity.configureRefreshOnSaveReturning(
					builder    = updateBuilder,
					attributes = entity.retrieveRefreshOnSaveAttributes(),
					operation  = "update"
				);
				var updateReturningSql = updateBuilder.update( values = { "first_name" : "Native" }, toSql = true );
				expect( updateReturningSql ).toInclude( "RETURNING" );
				expect( updateReturningSql ).toInclude( '"created_date"' );
				expect( updateReturningSql ).toInclude( '"type"' );
			} );

			it( "checks returning-row support for the current write operation", function() {
				var entity = getInstance( "DatabaseGeneratedUser" );
				makePublic( entity, "retrieveRefreshOnSaveAttributes" );
				makePublic( entity, "configureRefreshOnSaveReturning" );
				var attributes = entity.retrieveRefreshOnSaveAttributes();
				var grammar    = new tests.resources.InsertOnlyReturningGrammar();

				var insertBuilder = entity.newQuery();
				insertBuilder.getQB().setGrammar( grammar );
				expect(
					entity.configureRefreshOnSaveReturning(
						builder    = insertBuilder,
						attributes = attributes,
						operation  = "insert"
					)
				).toBeTrue();
				expect( insertBuilder.getQB().getReturning() ).notToBeEmpty();

				var updateBuilder = entity.newQuery();
				updateBuilder.getQB().setGrammar( grammar );
				expect(
					entity.configureRefreshOnSaveReturning(
						builder    = updateBuilder,
						attributes = attributes,
						operation  = "update"
					)
				).toBeFalse();
				expect( updateBuilder.getQB().getReturning() ).toBeEmpty();
			} );

			it( "uses a returned key row for auto-incrementing entities", function() {
				var returnedKeys = queryNew( "id", "integer" );
				queryAddRow( returnedKeys );
				querySetCell( returnedKeys, "id", 42 );
				var entity = getInstance( "DatabaseGeneratedUser" );

				getInstance( "AutoIncrementingKeyType@quick" ).postInsert(
					entity,
					{
						"query"  : returnedKeys,
						"result" : {}
					}
				);

				expect( entity.getId() ).toBe( 42 );
			} );

			it( "a saved entity is not dirty", function() {
				var newUser = getInstance( "User" );
				newUser.setUsername( "new_user" );
				newUser.setFirstName( "New" );
				newUser.setLastName( "User" );
				newUser.setPassword( hash( "password" ) );
				newUser.save();
				expect( newUser.isDirty() ).toBeFalse();
			} );

			it( "updates the attributes of an existing row if it has been loaded", function() {
				var existingUser = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				existingUser.setUsername( "new_elpete_username" );
				var userRowsPreSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPreSave ).toHaveLength( 5 );
				existingUser.save();
				var userRowsPostSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPostSave ).toHaveLength( 5 );
			} );

			it( "can touch an entity timestamp", function() {
				var user              = getInstance( "User" ).findOrFail( 1 );
				var originalCreated   = user.getCreatedDate();
				var originalModified  = user.getModifiedDate();
				var originalFirstName = user.getFirstName();
				var originalId        = user.getId();
				var dirtyFirstName    = "This must not be persisted";

				user.setFirstName( dirtyFirstName );

				user.touch();

				expect( dateCompare( user.getCreatedDate(), originalCreated ) ).toBe( 0 );
				expect( dateCompare( user.getModifiedDate(), originalModified ) ).toBe( 0 );
				expect( user.getFirstName() ).toBe( dirtyFirstName );
				expect( user.isDirty( "firstName" ) ).toBeTrue();
				expect( user.isDirty( "createdDate" ) ).toBeFalse();
				expect( user.isDirty( "modifiedDate" ) ).toBeFalse();
				var freshUser = getInstance( "User" ).findOrFail( originalId );
				expect( dateCompare( freshUser.getCreatedDate(), originalCreated ) ).toBe( 1 );
				expect( dateCompare( freshUser.getModifiedDate(), originalModified ) ).toBe( 1 );
				expect( freshUser.getFirstName() ).toBe( originalFirstName );
			} );

			it( "can override the timestamp fields used by touch", function() {
				var user             = getInstance( "CustomTimestampUser" ).findOrFail( 1 );
				var originalCreated  = user.getCreatedDate();
				var originalModified = user.getModifiedDate();

				user.touch();

				expect( dateCompare( user.getCreatedDate(), originalCreated ) ).toBe( 0 );
				expect( dateCompare( user.getModifiedDate(), originalModified ) ).toBe( 0 );
				var freshUser = user.fresh();
				expect( dateCompare( freshUser.getCreatedDate(), originalCreated ) ).toBe( 1 );
				expect( dateCompare( freshUser.getModifiedDate(), originalModified ) ).toBe( 0 );
			} );

			it( "throws a helpful error when changing the key of a loaded entity", function() {
				var existingUser = getInstance( "User" ).findOrFail( 1 );

				expect( function() {
					existingUser.setId( 2 ).save();
				} ).toThrow( type = "QuickPrimaryKeyMutationException", regex = "cannot change its primary key" );
			} );

			it( "allows assigning the existing key value to a loaded entity", function() {
				var existingUser = getInstance( "User" ).findOrFail( 1 );

				expect( function() {
					existingUser.setId( 1 ).save();
				} ).notToThrow();
			} );

			it( "guards every part of a loaded composite key", function() {
				var composite = getInstance( "Composite" ).findOrFail( [ 1, 2 ] );

				expect( function() {
					composite.setB( 1 ).save();
				} ).toThrow( type = "QuickPrimaryKeyMutationException", regex = "primary key \[b\]" );
			} );

			it( "does not allow updating of column where update=false in property", function() {
				var existingUser = getInstance( "User" ).find( 1 );
				existingUser.setEmail( "test2@test.com" );
				var userRowsPreSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPreSave ).toHaveLength( 5 );
				existingUser.save();
				var userRowsPostSave = queryExecute( "SELECT * FROM users" );
				expect( userRowsPostSave ).toHaveLength( 5 );
				expect( getInstance( "User" ).findOrFail( 1 ).isNullAttribute( "email" ) ).toBeTrue();
			} );

			it( "uses the sqltype attribute if present for each column", function() {
				structDelete( request, "saveSpecPreQBExecute" );

				var newPhoneNumber = getInstance( "PhoneNumber" );
				newPhoneNumber.setNumber( "+18018644200" );
				newPhoneNumber.setActive( true );
				newPhoneNumber.save();

				expect( request ).toHaveKey( "saveSpecPreQBExecute" );
				expect( request.saveSpecPreQBExecute ).toBeArray();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 1 );
				expect( request.saveSpecPreQBExecute[ 1 ] ).toHaveKey( "bindings" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings ).toBeArray();
				expect( request.saveSpecPreQBExecute[ 1 ].bindings ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 1 ] ).toHaveKey( "value" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 1 ].value ).toBe( 1 );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 1 ] ).toHaveKey( "cfsqltype" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 1 ].cfsqltype ).toBe( "CF_SQL_BIT" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 2 ] ).toHaveKey( "value" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 2 ].value ).toBe( "+18018644200" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 2 ] ).toHaveKey( "cfsqltype" );
				expect( request.saveSpecPreQBExecute[ 1 ].bindings[ 2 ].cfsqltype ).toBe( "CF_SQL_VARCHAR" );
			} );

			it( "uses the sqltype attribute when calling updateOrCreate and updating", function() {
				structDelete( request, "saveSpecPreQBExecute" );

				var newTheme = getInstance( "Theme" ).updateOrCreate( { "slug" : "theme-a" }, { "version" : "1.1.1" } );

				expect( request ).toHaveKey( "saveSpecPreQBExecute" );
				expect( request.saveSpecPreQBExecute ).toBeArray();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 2 ] ).toHaveKey( "bindings" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toBeArray();
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toHaveLength( 4 );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ] ).toHaveKey( "value" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ].value ).toBe( "1.1.1" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ] ).toHaveKey( "cfsqltype" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ].cfsqltype ).toBe( "CF_SQL_VARCHAR" );
			} );

			it( "forwards on updateOrInsert calls to updateOrCreate", function() {
				structDelete( request, "saveSpecPreQBExecute" );

				var newTheme = getInstance( "Theme" )
					.where( "slug", "theme-a" )
					.updateOrInsert( {
						"slug"    : "theme-a",
						"version" : "1.1.1"
					} );

				expect( request ).toHaveKey( "saveSpecPreQBExecute" );
				expect( request.saveSpecPreQBExecute ).toBeArray();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 2 ] ).toHaveKey( "bindings" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toBeArray();
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toHaveLength( 4 );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ] ).toHaveKey( "value" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ].value ).toBe( "1.1.1" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ] ).toHaveKey( "cfsqltype" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 3 ].cfsqltype ).toBe( "CF_SQL_VARCHAR" );
			} );

			it( "uses the sqltype attribute when calling updateOrCreate and creating", function() {
				structDelete( request, "saveSpecPreQBExecute" );

				var newTheme = getInstance( "Theme" ).updateOrCreate( { "slug" : "theme-b" }, { "version" : "1.1.1" } );

				expect( request ).toHaveKey( "saveSpecPreQBExecute" );
				expect( request.saveSpecPreQBExecute ).toBeArray();
				expect( request.saveSpecPreQBExecute ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 2 ] ).toHaveKey( "bindings" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toBeArray();
				expect( request.saveSpecPreQBExecute[ 2 ].bindings ).toHaveLength( 2 );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 2 ] ).toHaveKey( "value" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 2 ].value ).toBe( "1.1.1" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 2 ] ).toHaveKey( "cfsqltype" );
				expect( request.saveSpecPreQBExecute[ 2 ].bindings[ 2 ].cfsqltype ).toBe( "CF_SQL_VARCHAR" );
			} );

			it( "can attach an id to a relationship", function() {
				var tag = getInstance( "Tag" );
				tag.setName( "miscellaneous" );
				tag.save();

				var post = getInstance( "Post" ).findOrFail( 1245 );

				expect( post.getTags() ).toBeArray();
				expect( post.getTags() ).toHaveLength( 2 );

				post.tags().attach( tag.getId() );

				post.refresh();

				expect( post.getTags() ).toBeArray();
				expect( post.getTags() ).toHaveLength( 3 );
			} );

			it( "attaches using the id if the entity is passed", function() {
				var tag = getInstance( "Tag" );
				tag.setName( "miscellaneous" );
				tag.save();

				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );

				post.tags().attach( tag );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 3 );
			} );

			it( "can attach multiple ids or entities at once", function() {
				var tagA = getInstance( "Tag" );
				tagA.setName( "miscellaneous" );
				tagA.save();

				var tagB = getInstance( "Tag" );
				tagB.setName( "other" );
				tagB.save();

				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );

				post.tags().attach( [ tagA.getId(), tagB ] );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 4 );
			} );

			it( "can detach an id from a relationship", function() {
				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );

				var tag = post.getTags().toArray()[ 1 ];

				post.tags().detach( tag.getId() );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 1 );
			} );

			it( "detaches using the id if the entity is passed", function() {
				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );

				var tag = post.getTags().toArray()[ 1 ];

				post.tags().detach( tag );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 1 );
			} );

			it( "can detach multiple ids or entities at once", function() {
				var post = getInstance( "Post" ).find( 1245 );

				var tags = post.getTags().toArray();
				expect( tags ).toBeArray();
				expect( tags ).toHaveLength( 2 );

				post.tags().detach( [ tags[ 1 ].getId(), tags[ 2 ] ] );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toBeEmpty();
			} );

			it( "sets the related ids equal to the list passed in", function() {
				var newTagA = getInstance( "Tag" );
				newTagA.setName( "miscellaneous" );
				newTagA.save();

				var newTagB = getInstance( "Tag" );
				newTagB.setName( "other" );
				newTagB.save();

				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );
				var existingTags = post.getTags().toArray();

				var tagsToSync = [
					existingTags[ 1 ],
					newTagA.getId(),
					newTagB
				];
				var tagIds = [
					existingTags[ 1 ].keyValues(),
					newTagA.keyValues(),
					newTagB.keyValues()
				];

				post.tags()
					.sync( [
						existingTags[ 1 ],
						newTagA.getId(),
						newTagB
					] );

				post.refresh();

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 3 );
				expect(
					post.getTags()
						.map( function( tag ) {
							return tag.keyValues();
						} )
						.toArray()
				).toBe( tagIds );
			} );

			it( "sets the related ids equal to the list passed in using a relationship setter", function() {
				var newTagA = getInstance( "Tag" );
				newTagA.setName( "miscellaneous" );
				newTagA.save();

				var newTagB = getInstance( "Tag" );
				newTagB.setName( "other" );
				newTagB.save();

				var post = getInstance( "Post" ).find( 1245 );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 2 );
				var existingTags = post.getTags().toArray();

				var tagsToSync = [
					existingTags[ 1 ],
					newTagA.getId(),
					newTagB
				];
				var tagIds = [
					existingTags[ 1 ].keyValues(),
					newTagA.keyValues(),
					newTagB.keyValues()
				];

				post.setTags( [
					existingTags[ 1 ],
					newTagA.getId(),
					newTagB
				] );

				expect( post.getTags().toArray() ).toBeArray();
				expect( post.getTags().toArray() ).toHaveLength( 3 );
				expect(
					post.getTags()
						.map( function( tag ) {
							return tag.keyValues();
						} )
						.toArray()
				).toBe( tagIds );
			} );
		} );
	}

	function preQBExecute(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		param request.saveSpecPreQBExecute = [];
		arrayAppend( request.saveSpecPreQBExecute, duplicate( arguments.interceptData ) );
	}

}
