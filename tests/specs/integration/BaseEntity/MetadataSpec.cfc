component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Base Entity Metadata Spec", function() {
			it( "extends from the Base Entity", function() {
				var user = getInstance( "Post" );
				var md   = getMetadata( user );
				expect( md ).toHaveKey( "extends" );
				expect( md.extends ).toHaveKey( "name" );
				expect( md.extends.name ).toInclude( "quick.models.BaseEntity" );
			} );

			describe( "full name", function() {
				it( "calculates the full name from the metadata", function() {
					var post = getInstance( "User" );
					expect( post.get_FullName() ).toBe( "app.models.User" );
				} );
			} );

			describe( "entity name", function() {
				it( "calculates the entity name from the file name if no `entityname` attribute is present", function() {
					var post = getInstance( "User" );
					expect( post.entityName() ).toBe( "User" );
				} );
			} );

			describe( "mapping name", function() {
				it( "takes the mapping name from the file name", function() {
					var post = getInstance( "Post" );
					expect( post.mappingName() ).toBe( "Post" );
				} );
			} );

			describe( "table name", function() {
				it( "determines the table name from the metadata if a `table` attribute is present", function() {
					var post = getInstance( "Post" );
					expect( post.tableName() ).toBe( "my_posts" );
				} );

				it( "calculates the table name from the entity name if no `table` attribute is present", function() {
					var post = getInstance( "User" );
					expect( post.tableName() ).toBe( "users" );
				} );

				it( "uses the snake case plural version of the component name", function() {
					var phoneNumber = getInstance( "PhoneNumber" );
					expect( phoneNumber.tableName() ).toBe( "phone_numbers" );
				} );
			} );

			describe( "primary key", function() {
				it( "uses the `variables._key` value if set", function() {
					var post = getInstance( "Post" );
					expect( post.keyNames()[ 1 ] ).toBe( "post_pk" );
				} );

				it( "uses the `id` as the `variables._key` value by default", function() {
					var user = getInstance( "User" );
					expect( user.keyNames()[ 1 ] ).toBe( "id" );
				} );

				it( "can set a composite primary key", function() {
					var composite = getInstance( "Composite" );
					expect( composite.keyNames() ).toBe( [ "a", "b" ] );
				} );
			} );

			describe( "parent meta", function() {
				it( "can detect a discriminated entity", function() {
					var discriminated = getInstance( "InternalComment" );

					expect( discriminated.get_Meta() ).toHaveKey( "parentDefinition" ).toHaveKey( "hasParentEntity" );

					expect( discriminated.get_Meta().hasParentEntity ).toBe( true );
					expect( discriminated.get_Meta().parentDefinition )
						.toBeStruct()
						.toHaveKey( "meta" )
						.toHaveKey( "joincolumn" )
						.toHaveKey( "discriminatorValue" )
						.toHaveKey( "discriminatorColumn" );
				} );

				it( "can detect a non-discriminated child subclass", function() {
					var discriminated = getInstance( "Jingle" );

					expect( discriminated.get_Meta() ).toHaveKey( "parentDefinition" ).toHaveKey( "hasParentEntity" );

					expect( discriminated.get_Meta().hasParentEntity ).toBe( true );
					expect( discriminated.get_Meta().parentDefinition )
						.toBeStruct()
						.toHaveKey( "meta" )
						.toHaveKey( "joincolumn" )
						.notToHaveKey( "discriminatorValue" )
						.notToHaveKey( "discriminatorColumn" );
				} );
			} );
		} );
	}

}
