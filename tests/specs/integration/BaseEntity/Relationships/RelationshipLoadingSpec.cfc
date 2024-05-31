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
					expect( postQuery.result.sqlparameters ).toHaveLength( 2 );
					expect( postQuery.result.sqlparameters ).toBe( [ 321, 523526 ] );
				} );
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
