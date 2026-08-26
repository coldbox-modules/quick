component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "RelationshipLoadingSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "RelationshipLoadingSpec" );
		super.afterAll();
	}

	function run() {
		describe( "relationship loading", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "returns empty relationship values for new entities", function() {
				var post = getInstance( "Post" );
				var user = getInstance( "User" );

				expect( post.getAuthor() ).toBeNull();
				expect( user.getLatestPost() ).toBeNull();
				expect( user.getPosts() ).toBeArray().toBeEmpty();
				expect( post.getTags() ).toBeArray().toBeEmpty();
				expect( variables.queries ).toBeEmpty();
			} );

			it( "includes empty relationships in mementos for new entities", function() {
				var memento = getInstance( "User" ).getMemento( includes = [ "latestPost", "posts" ] );

				expect( memento.latestPost ).toBe( "" );
				expect( memento.posts ).toBeArray().toBeEmpty();
				expect( variables.queries ).toBeEmpty();
			} );

			it( "retrieves and caches the relationship type default without querying", function() {
				var user = getInstance( "User" );
				var post = getInstance( "Post" );

				expect( user.retrieveRelationship( "posts" ) ).toBeArray().toBeEmpty();
				expect( post.retrieveRelationship( "author" ) ).toBeNull();
				expect( post.retrieveRelationship( "authorWithEmptyDefault" ) ).toBeInstanceOf( "User" );
				expect( user.isRelationshipLoaded( "posts" ) ).toBeTrue();
				expect( post.isRelationshipLoaded( "author" ) ).toBeTrue();
				expect( variables.queries ).toBeEmpty();
			} );

			it( "accepts a default relationship value", function() {
				var user       = getInstance( "User" );
				var seededPost = getInstance( "Post" ).fill( { "body" : "seeded" } );

				var posts = user.retrieveRelationship( "posts", [ seededPost ] );

				expect( posts ).toHaveLength( 1 );
				expect( posts[ 1 ].getBody() ).toBe( "seeded" );
				expect( user.isRelationshipLoaded( "posts" ) ).toBeTrue();
				expect( variables.queries ).toBeEmpty();
			} );

			it( "throws when retrieving an unknown relationship", function() {
				var post = getInstance( "Post" );

				expect( function() {
					post.retrieveRelationship( "missingRelationship" );
				} ).toThrow( "RelationshipNotFound" );
			} );

			describe( "Eager Loading Spec", function() {
				it( "can load a relationship for an entity", function() {
					var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
					elpete.loadRelationship( "posts" );
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
				} );

				it( "does not reload an already loaded relationship", function() {
					var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
					elpete.loadRelationship( "posts" );
					elpete.loadRelationship( "posts" );
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
					expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed" );
				} );

				it( "does reload an already loaded relationship when using the forceLoadRelationship method", function() {
					var elpete = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeFalse();
					elpete.forceLoadRelationship( "posts" );
					elpete.forceLoadRelationship( "posts" );
					expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue();
					expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed" );
				} );
			} );

			describe( "Dynamic relationships", function() {
				it( "can load a relationship based off of a subselect column", function() {
					var users = getInstance( "User" )
						.withLatestPost()
						.orderByAsc( "id" )
						.get();
					expect( users ).toHaveLength( 5 );

					var elpete = users[ 1 ];
					expect( elpete.getDynamicLatestPost() ).notToBeNull();
					expect( elpete.getDynamicLatestPost().getPost_Pk() ).toBe( 523526 );

					var johndoe = users[ 2 ];
					expect( johndoe.getDynamicLatestPost() ).toBeNull();

					var janedoe = users[ 3 ];
					expect( janedoe.getDynamicLatestPost() ).toBeNull();

					var elpete2 = users[ 4 ];
					expect( elpete2.getDynamicLatestPost() ).notToBeNull();
					expect( elpete2.getDynamicLatestPost().getPost_Pk() ).toBe( 321 );

					var michaelscott = users[ 5 ];
					expect( michaelscott.getDynamicLatestPost() ).toBeNull();

					expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed" );

					var postQuery = variables.queries[ 2 ];
					expect( postQuery.result.sqlparameters ).toContain( 321 );
					expect( postQuery.result.sqlparameters ).toContain( 523526 );
				} );
			} );

			it( "does not query a hasMany relationship when any composite local key is null", function() {
				var user = getInstance( "User" ).findOrFail( 2 );

				expect( variables.queries ).toHaveLength( 1 );
				expect( user.getFavoritePostsComposite() ).toBeArray().toBeEmpty();
				expect( variables.queries ).toHaveLength( 1 );
			} );

			it( "queries a hasMany relationship when all composite local keys have values", function() {
				var user = getInstance( "User" ).findOrFail( 1 );

				var favoritePosts = user.getFavoritePostsComposite();

				expect( favoritePosts ).toHaveLength( 1 );
				expect( favoritePosts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( variables.queries ).toHaveLength( 2 );
			} );

			it( "gets a new instance of an entity when calling fill", () => {
				var elpete       = getInstance( "User" ).findOrFail( 1 );
				var relationship = elpete.posts();
				var newPost      = relationship.fill( { "body" : "test body" } );
				var anotherPost  = relationship.fill( { "body" : "another body" } );
				expect( newPost ).notToBeNull();
				expect( newPost ).toBeInstanceOf( "Post" );
				expect( newPost.isLoaded() ).toBeFalse();
				expect( newPost.getBody() ).toBe( "test body" );
				expect( newPost.getUser_Id() ).toBe( 1 );
				expect( anotherPost ).toBeInstanceOf( "Post" );
				expect( anotherPost.isLoaded() ).toBeFalse();
				expect( anotherPost.getBody() ).toBe( "another body" );
				expect( anotherPost.getUser_Id() ).toBe( 1 );
				expect( variables.queries ).toHaveLength(
					1,
					"Filling and associating the new post must not persist it."
				);
			} );

			it( "can call fetch methods on the relationship builder", () => {
				var elpete             = getInstance( "User" ).findOrFail( 1 );
				var elpeteFavoritePost = elpete.favoritePost().first();
				expect( elpeteFavoritePost ).notToBeNull();
				expect( elpeteFavoritePost ).toBeInstanceOf( "Post" );
				expect( elpeteFavoritePost.isLoaded() ).toBeTrue();
				expect( elpeteFavoritePost.getPost_Pk() ).toBe( 1245 );

				var johndoe = getInstance( "User" ).findOrFail( 2 );
				expect( johndoe.favoritePost().first() ).toBeNull();

				var janedoe             = getInstance( "User" ).findOrFail( 3 );
				var janedoeFavoritePost = janedoe.favoritePost().firstOrNew();
				expect( janedoeFavoritePost ).notToBeNull();
				expect( janedoeFavoritePost ).toBeInstanceOf( "Post" );
				expect( janedoeFavoritePost.isLoaded() ).toBeFalse();

				var elpete2             = getInstance( "User" ).findOrFail( 4 );
				var elpete2FavoritePost = elpete2
					.favoritePost()
					.firstOrCreate( { "user_id" : 4, "body" : "test body" } );
				expect( elpete2FavoritePost ).notToBeNull();
				expect( elpete2FavoritePost ).toBeInstanceOf( "Post" );
				expect( elpete2FavoritePost.isLoaded() ).toBeTrue();
				expect( elpete2FavoritePost.getUser_Id() ).toBe( 4 );
				expect( elpete2FavoritePost.getBody() ).toBe( "test body" );
			} );

			it( "can call exists methods on a relationship class", () => {
				var elpete = getInstance( "User" ).findOrFail( 1 );
				expect( elpete.favoritePost().exists() ).toBeTrue();

				var johndoe = getInstance( "User" ).findOrFail( 2 );
				expect( johndoe.favoritePost().exists() ).toBeFalse();

				expect( function() {
					var janedoe = getInstance( "User" ).findOrFail( 3 );
					janedoe.favoritePost().existsOrFail();
				} ).toThrow( type = "EntityNotFound" );
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
