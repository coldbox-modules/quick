component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Belongs To Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can get the owning entity", function() {
				var post = getInstance( "Post" ).find( 1245 );
				var user = post.getAuthor();
				expect( user.getId() ).toBe( 1 );
				expect( user.getUsername() ).toBe( "elpete" );
			} );

			it( "caches the result of fetching the owning entity", function() {
				controller.getInterceptorService().registerInterceptor( interceptorObject = this );
				var post = getInstance( "Post" ).find( 1245 );
				post.getAuthor();
				post.getAuthor();
				post.getAuthor();
				post.getAuthor();
				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "returns null if there is no owning entity", function() {
				var post = getInstance( "Post" ).find( 7777 );
				expect( post.getAuthor() ).toBeNull();
			} );

			it( "can return an empty default entity if there is no owning entity", function() {
				var post = getInstance( "Post" ).find( 7777 );
				expect( post.getAuthorWithEmptyDefault() ).notToBeNull();
				var author = post.getAuthorWithEmptyDefault();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData() ).toBeEmpty();
			} );

			it( "can return a configured default entity if there is no owning entity", function() {
				var post = getInstance( "Post" ).find( 7777 );
				expect( post.getAuthorWithDefaultAttributes() ).notToBeNull();
				var author = post.getAuthorWithDefaultAttributes();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.retrieveAttributesData( aliased = true ) ).toBe( {
					"firstName" : "Guest",
					"lastName"  : "User"
				} );
			} );

			it( "can configure a default entity with a callback", function() {
				var post = getInstance( "Post" ).find( 7777 );
				expect( post.getAuthorWithCalllbackConfiguredDefault() ).notToBeNull();
				var author = post.getAuthorWithCalllbackConfiguredDefault();
				expect( author ).toBeInstanceOf( "User" );
				expect( author.isLoaded() ).toBeFalse( "A default model is not loaded" );
				expect( author.getUsername() ).toBe( post.getBody() );
			} );

			it( "can associate a new entity", function() {
				var newPost = getInstance( "Post" );
				newPost.setBody( "A new post by me!" );
				newPost.save();
				var user = getInstance( "User" ).find( 1 );
				expect( user.posts().count() ).toBe( 2 );
				newPost
					.author()
					.associate( user )
					.save();
				expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
				expect( user.posts().count() ).toBe( 3 );
			} );

			it( "can set the associated relationship by calling a relationship setter", function() {
				var user    = getInstance( "User" ).find( 1 );
				var newPost = getInstance( "Post" ).create( {
					"body"   : "A new post by me!",
					"author" : user
				} );
				expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
				expect( user.posts().count() ).toBe( 3 );
			} );

			it( "sets an entity in the relationship cache when calling a relationship setter", function() {
				var newPost = getInstance( "Post" );
				newPost.setBody( "A new post by me!" );
				var user = getInstance( "User" ).find( 1 );
				newPost.setAuthor( user );
				newPost.getAuthor();
				newPost.getAuthor();
				newPost.getAuthor();
				newPost.getAuthor();
				expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
				expect( variables.queries ).toHaveLength( 1, "Only one query should have been executed." );
			} );

			it( "can set the associated relationship by calling a relationship setter with an id", function() {
				var newPost = getInstance( "Post" );
				newPost.setBody( "A new post by me!" );
				var user = getInstance( "User" ).find( 1 );
				newPost.setAuthor( user.keyValues() ).save();
				expect( newPost.retrieveAttribute( "user_id" ) ).toBe( user.getId() );
				expect( user.posts().count() ).toBe( 3 );
			} );

			it( "can set the associated relationship through fill with an id", function() {
				var newPost = getInstance( "Post" ).create( {
					"body"   : "A new post by me!",
					"author" : 1
				} );
				expect( newPost.retrieveAttribute( "user_id" ) ).toBe( 1 );
				expect(
					newPost
						.getAuthor()
						.posts()
						.count()
				).toBe( 3 );
			} );

			it( "can disassociate the existing entity", function() {
				var post = getInstance( "Post" ).find( 1245 );
				expect( post.retrieveAttribute( "user_id" ) ).notToBe( "" );
				var userId = post.retrieveAttribute( "user_id" );
				expect(
					getInstance( "User" )
						.find( userId )
						.posts()
						.count()
				).toBe( 2 );
				post.author()
					.dissociate()
					.save();
				expect( post.retrieveAttribute( "user_id" ) ).toBe( "" );
				expect(
					getInstance( "User" )
						.find( userId )
						.posts()
						.count()
				).toBe( 1 );
			} );

			it( "can have a relationship with a composite foreign key", function() {
				var compositeChild = getInstance( "CompositeChild" ).findOrFail( 1 );
				expect( compositeChild.getParent() ).toBeInstanceOf( "Composite" );
				expect( compositeChild.getParent().keyValues() ).toBe( [ 1, 2 ] );
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
		arrayAppend( variables.queries, interceptData );
	}

}
