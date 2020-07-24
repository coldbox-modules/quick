component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "good error messages", function() {
			it( "throws about unloaded entities when trying to retrieve the `keyValue`", function() {
				expect( function() {
					getInstance( "User" ).keyValues();
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so the \`keyValues\` cannot be retrieved\."
				);
			} );

			it( "throws about unloaded entities when calling `delete`", function() {
				expect( function() {
					getInstance( "User" ).delete();
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so it cannot be deleted\. Did you maybe mean to use `deleteAll`\?"
				);
			} );

			it( "throws about unloaded entities when calling `update`", function() {
				expect( function() {
					getInstance( "User" ).update( { "username" : "johndoe" } );
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so it cannot be updated\. Did you maybe mean to use `updateAll`, `create`, or `save`\?"
				);
			} );

			it( "throws a helpful error message when the key value is defaulted", function() {
				expect( function() {
					getInstance( "DefaultedKeyEntity" );
				} ).toThrow( type = "QuickEntityDefaultedKey" );
			} );

			it( "throws a helpful error message when trying to access relationships on unloaded entities", function() {
				expect( function() {
					getInstance( "User" ).posts();
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so it cannot access the \[posts\] relationship\.  Either load the entity from the database using a query executor \(like \`first\`\) or base your query off of the \[Post\] entity directly and use the \`has\` or \`whereHas\` methods to constrain it based on data in \[User\]\."
				);

				expect( function() {
					getInstance( "User" ).getPosts();
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so it cannot access the \[posts\] relationship\.  Either load the entity from the database using a query executor \(like \`first\`\) or base your query off of the \[Post\] entity directly and use the \`has\` or \`whereHas\` methods to constrain it based on data in \[User\]\."
				);
			} );

			it( "throws a helpful error message if accessors are not turned on", function() {
				expect( function() {
					getInstance( "EntityWithoutAccessors" );
				} ).toThrow(
					type  = "QuickAccessorsMissing",
					regex = 'This instance is missing \`accessors\=\"true\"\` in the component metadata\.  This is required for Quick to work properly\.  Please add it to your component metadata and reinit your application\.'
				);
			} );

			it( "throws a helpful error message when trying to set a belongsToMany relationship when the relationship is not loaded", function() {
				expect( function() {
					getInstance( "Post" ).create( {
						"user_id"       : 1,
						"body"          : "A new post body",
						"publishedDate" : now(),
						"tags"          : [ 1, 2 ]
					} );
				} ).toThrow(
					type  = "QuickEntityNotLoaded",
					regex = "This instance is not loaded so it cannot set the \[tags\] relationship\.  Save the new entity first before trying to save related entities\."
				);
			} );
		} );
	}

}
