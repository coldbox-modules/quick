component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "AsQueryEagerLoadingSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "AsQueryEagerLoadingSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Eager Loading Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can eager load a belongs to relationship", function() {
				var posts = getInstance( "Post" )
					.with( "author" )
					.asQuery()
					.get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				expect( posts[ 1 ][ "author" ] ).toBeStruct().notToBeEmpty();
				expect( posts[ 2 ][ "author" ] ).toBeStruct().notToBeEmpty();
				expect( posts[ 3 ][ "author" ] ).toBeStruct().toBeEmpty();
				expect( posts[ 4 ][ "author" ] ).toBeStruct().notToBeEmpty();
				if ( arrayLen( variables.queries ) != 2 ) {
					expect( variables.queries ).toHaveLength(
						2,
						"Only two queries should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "can eager load a belongs to relationship using a composite key", function() {
				var compositeChildren = getInstance( "CompositeChild" )
					.with( "parent" )
					.asQuery()
					.get();
				expect( compositeChildren ).toBeArray();
				expect( compositeChildren ).toHaveLength( 2, "2 entities should have been loaded" );
				expect( compositeChildren[ 1 ][ "parent" ] ).toBeStruct().notToBeEmpty();
				expect( compositeChildren[ 1 ][ "parent" ] ).toHaveKey( "a" );
				expect( compositeChildren[ 1 ][ "parent" ] ).toHaveKey( "b" );
				expect( compositeChildren[ 1 ][ "parent" ][ "a" ] ).toBe( 1 );
				expect( compositeChildren[ 1 ][ "parent" ][ "b" ] ).toBe( 2 );
				expect( compositeChildren[ 2 ][ "parent" ] ).toBeStruct().toBeEmpty();

				if ( arrayLen( variables.queries ) != 2 ) {
					expect( variables.queries ).toHaveLength(
						2,
						"Only two queries should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "does not eager load a belongs to empty record set", function() {
				var posts = getInstance( "Post" )
					.whereNull( "createdDate" )
					.with( "author" )
					.asQuery()
					.get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 0, "0 posts should have been loaded" );
				if ( arrayLen( variables.queries ) != 1 ) {
					expect( variables.queries ).toHaveLength(
						1,
						"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "does not eager load a belongs to relationship if there are no foreign keys available", function() {
				var usersWithoutFavoritePosts = getInstance( "User" )
					.whereNull( "favoritePost_id" )
					.with( "favoritePost" )
					.asQuery()
					.get();
				expect( usersWithoutFavoritePosts ).toBeArray();
				expect( usersWithoutFavoritePosts ).toHaveLength( 4, "4 users should have been loaded" );
				if ( arrayLen( variables.queries ) != 1 ) {
					expect( variables.queries ).toHaveLength(
						1,
						"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "does not eager load a has many empty record set", function() {
				var users = getInstance( "User" )
					.whereNull( "createdDate" )
					.with( "posts" )
					.asQuery()
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 0, "0 users should have been loaded" );
				if ( arrayLen( variables.queries ) != 1 ) {
					expect( variables.queries ).toHaveLength(
						1,
						"Only one query should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "can eager load a has many relationship", function() {
				var users = getInstance( "User" )
					.with( "posts" )
					.latest()
					.asQuery()
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "posts" ] ).toBeArray();
				expect( michaelscott[ "posts" ] ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2[ "username" ] ).toBe( "elpete2" );
				expect( elpete2[ "posts" ] ).toBeArray();
				expect( elpete2[ "posts" ] ).toHaveLength( 1, "One post should belong to elpete2" );

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "posts" ] ).toBeArray();
				expect( janedoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "posts" ] ).toBeArray();
				expect( johndoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );
				expect( elpete[ "posts" ] ).toBeArray();
				expect( elpete[ "posts" ] ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "respects other filters on a relationship when eager loading", function() {
				var users = getInstance( "User" )
					.with( "publishedPosts" )
					.latest()
					.asQuery()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "publishedPosts" ] ).toBeArray();
				expect( michaelscott[ "publishedPosts" ] ).toHaveLength(
					0,
					"No posts should belong to michaelscott. Instead got #arrayLen( michaelscott[ "publishedPosts" ] )#."
				);

				var elpete2 = users[ 2 ];
				expect( elpete2[ "username" ] ).toBe( "elpete2" );
				expect( elpete2[ "publishedPosts" ] ).toBeArray();
				expect( elpete2[ "publishedPosts" ] ).toHaveLength(
					1,
					"One post should belong to elpete2. Instead got #arrayLen( elpete2[ "publishedPosts" ] )#."
				);

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "publishedPosts" ] ).toBeArray();
				expect( janedoe[ "publishedPosts" ] ).toHaveLength(
					0,
					"No posts should belong to janedoe. Instead got #arrayLen( janedoe[ "publishedPosts" ] )#."
				);

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "publishedPosts" ] ).toBeArray();
				expect( johndoe[ "publishedPosts" ] ).toHaveLength(
					0,
					"No posts should belong to johndoe. Instead got #arrayLen( johndoe[ "publishedPosts" ] )#."
				);

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );
				expect( elpete[ "publishedPosts" ] ).toBeArray();
				expect( elpete[ "publishedPosts" ] ).toHaveLength(
					1,
					"One post should belong to elpete. Instead got #arrayLen( elpete[ "publishedPosts" ] )#."
				);

				expect( variables.queries ).toHaveLength(
					2,
					"Only two queries should have been executed. Instead got #variables.queries.len()#."
				);
			} );

			it( "can eager load a hasOne relationship", function() {
				var users = getInstance( "User" )
					.with( "latestPost" )
					.latest()
					.asQuery()
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "latestPost" ] ).toBeStruct().toBeEmpty();

				var elpete2 = users[ 2 ];
				expect( elpete2[ "username" ] ).toBe( "elpete2" );
				expect( elpete2[ "latestPost" ] ).toBeStruct().notToBeEmpty();

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "latestPost" ] ).toBeStruct().toBeEmpty();

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "latestPost" ] ).toBeStruct().toBeEmpty();

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );
				expect( elpete[ "latestPost" ] ).toBeStruct().notToBeEmpty();

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a belongs to many relationship", function() {
				var posts = getInstance( "Post" )
					.with( "tags" )
					.asQuery()
					.get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ][ "tags" ] ).toBeArray();
				expect( posts[ 1 ][ "tags" ] ).toHaveLength( 0 );

				expect( posts[ 2 ][ "tags" ] ).toBeArray();
				expect( posts[ 2 ][ "tags" ] ).toHaveLength( 2 );
				expect( posts[ 2 ][ "tags" ][ 1 ][ "name" ] ).toBe( "programming" );
				expect( posts[ 2 ][ "tags" ][ 2 ][ "name" ] ).toBe( "music" );

				expect( posts[ 3 ][ "tags" ] ).toBeArray();
				expect( posts[ 3 ][ "tags" ] ).toHaveLength( 0 );

				expect( posts[ 4 ][ "tags" ] ).toBeArray();
				expect( posts[ 4 ][ "tags" ] ).toHaveLength( 2 );
				expect( posts[ 4 ][ "tags" ][ 1 ][ "name" ] ).toBe( "programming" );
				expect( posts[ 4 ][ "tags" ][ 2 ][ "name" ] ).toBe( "music" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a has many through relationship", function() {
				var countries = getInstance( "Country" )
					.with( "posts" )
					.asQuery()
					.get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ][ "posts" ] ).toBeArray();
				expect( countries[ 1 ][ "posts" ] ).toHaveLength( 2 );
				expect( countries[ 1 ][ "posts" ][ 1 ][ "body" ] ).toBe( "My awesome post body" );
				expect( countries[ 1 ][ "posts" ][ 2 ][ "body" ] ).toBe( "My second awesome post body" );

				expect( countries[ 2 ][ "posts" ] ).toBeArray();
				expect( countries[ 2 ][ "posts" ] ).toHaveLength( 1 );
				expect( countries[ 2 ][ "posts" ][ 1 ][ "body" ] ).toBe( "My post with a different author" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a long has many through relationship", function() {
				var countries = getInstance( "Country" )
					.with( "comments" )
					.asQuery()
					.get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ][ "comments" ] ).toBeArray();
				expect( countries[ 1 ][ "comments" ] ).toHaveLength( 1 );
				expect( countries[ 1 ][ "comments" ][ 1 ][ "body" ] ).toBe( "I thought this post was great" );

				expect( countries[ 2 ][ "comments" ] ).toBeArray();
				expect( countries[ 2 ][ "comments" ] ).toHaveLength( 1 );
				expect( countries[ 2 ][ "comments" ][ 1 ][ "body" ] ).toBe( "I thought this post was not so good" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a recursive has many through relationship", function() {
				var countries = getInstance( "Country" )
					.with( "commentsUsingHasManyThrough" )
					.asQuery()
					.get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ][ "commentsUsingHasManyThrough" ] ).toBeArray();
				expect( countries[ 1 ][ "commentsUsingHasManyThrough" ] ).toHaveLength( 1 );
				expect( countries[ 1 ][ "commentsUsingHasManyThrough" ][ 1 ][ "body" ] ).toBe(
					"I thought this post was great"
				);

				expect( countries[ 2 ][ "commentsUsingHasManyThrough" ] ).toBeArray();
				expect( countries[ 2 ][ "commentsUsingHasManyThrough" ] ).toHaveLength( 1 );
				expect( countries[ 2 ][ "commentsUsingHasManyThrough" ][ 1 ][ "body" ] ).toBe(
					"I thought this post was not so good"
				);

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load polymorphic belongs to relationships", function() {
				var comments = getInstance( "Comment" )
					.where( "designation", "public" )
					.with( "commentable" )
					.asQuery()
					.get();

				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 3 );

				expect( comments[ 1 ][ "id" ] ).toBe( 1 );
				expect( comments[ 1 ][ "commentable" ] ).toHaveKey( "body", "Post entities should have a body key" );
				expect( comments[ 1 ][ "commentable" ][ "post_pk" ] ).toBe( 1245 );

				expect( comments[ 2 ][ "id" ] ).toBe( 2 );
				expect( comments[ 2 ][ "commentable" ] ).toHaveKey( "body", "Post entities should have a body key" );
				expect( comments[ 2 ][ "commentable" ][ "post_pk" ] ).toBe( 321 );

				expect( comments[ 3 ][ "id" ] ).toBe( 3 );
				expect( comments[ 3 ][ "commentable" ] ).toHaveKey( "url", "Video entities should have a url key" );
				expect( comments[ 3 ][ "commentable" ][ "id" ] ).toBe( 1245 );

				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed." );
			} );

			it( "can eager load polymorphic has many relationships", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];

				var posts = getInstance( "Post" )
					.with( "comments" )
					.asQuery()
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ][ "comments" ] ).toBeArray();
				expect( posts[ 1 ][ "comments" ] ).toHaveLength( 1 );

				expect( posts[ 2 ][ "comments" ] ).toBeArray();
				expect( posts[ 2 ][ "comments" ] ).toHaveLength( 1 );

				expect( posts[ 3 ][ "comments" ] ).toBeArray();
				expect( posts[ 3 ][ "comments" ] ).toBeEmpty();

				expect( posts[ 4 ][ "comments" ] ).toBeArray();
				expect( posts[ 4 ][ "comments" ] ).toBeEmpty();

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a nested relationship", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];
				var users         = getInstance( "User" )
					.with( "posts.comments" )
					.latest()
					.asQuery()
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "posts" ] ).toBeArray();
				expect( michaelscott[ "posts" ] ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2[ "username" ] ).toBe( "elpete2" );
				expect( elpete2[ "posts" ] ).toBeArray();
				expect( elpete2[ "posts" ] ).toHaveLength( 1, "One post should belong to elpete2" );

				expect( elpete2[ "posts" ][ 1 ][ "comments" ] ).toBeArray();
				expect( elpete2[ "posts" ][ 1 ][ "comments" ] ).toHaveLength( 1 );
				expect( elpete2[ "posts" ][ 1 ][ "comments" ][ 1 ][ "id" ] ).toBe( 2 );
				expect( elpete2[ "posts" ][ 1 ][ "comments" ][ 1 ][ "body" ] ).toBe(
					"I thought this post was not so good"
				);

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "posts" ] ).toBeArray();
				expect( janedoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "posts" ] ).toBeArray();
				expect( johndoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );

				expect( elpete[ "posts" ] ).toBeArray();
				expect( elpete[ "posts" ] ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( elpete[ "posts" ][ 1 ][ "post_pk" ] ).toBe( 523526 );
				expect( elpete[ "posts" ][ 1 ][ "comments" ] ).toBeArray();
				expect( elpete[ "posts" ][ 1 ][ "comments" ] ).toBeEmpty();

				expect( elpete[ "posts" ][ 2 ][ "post_pk" ] ).toBe( 1245 );
				expect( elpete[ "posts" ][ 2 ][ "comments" ] ).toBeArray();
				expect( elpete[ "posts" ][ 2 ][ "comments" ] ).toHaveLength( 1 );
				expect( elpete[ "posts" ][ 2 ][ "comments" ][ 1 ][ "id" ] ).toBe( 1 );
				expect( elpete[ "posts" ][ 2 ][ "comments" ][ 1 ][ "body" ] ).toBe( "I thought this post was great" );

				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed." );
			} );

			it( "can constrain eager loading on a belongs to relationship", function() {
				var users = getInstance( "User" )
					.with( {
						"posts" : function( query ) {
							return query.where( "post_pk", "<", 7777 );
						}
					} )
					.latest()
					.asQuery()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "posts" ] ).toBeArray();
				expect( michaelscott[ "posts" ] ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "posts" ] ).toBeArray();
				expect( janedoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "posts" ] ).toBeArray();
				expect( johndoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );
				expect( elpete[ "posts" ] ).toBeArray();
				expect( elpete[ "posts" ] ).toHaveLength( 1, "One post should belong to elpete" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can constrain an eager load on a nested relationship", function() {
				var users = getInstance( "User" )
					.with( {
						"posts" : function( q1 ) {
							return q1.with( {
								"comments" : function( q2 ) {
									return q2.where( "body", "like", "%not%" );
								}
							} );
						}
					} )
					.latest()
					.asQuery()
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott[ "username" ] ).toBe( "michaelscott" );
				expect( michaelscott[ "posts" ] ).toBeArray();
				expect( michaelscott[ "posts" ] ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2[ "username" ] ).toBe( "elpete2" );
				expect( elpete2[ "posts" ] ).toBeArray();
				expect( elpete2[ "posts" ] ).toHaveLength( 1, "One post should belong to elpete2" );

				expect( elpete2[ "posts" ][ 1 ][ "comments" ] ).toBeArray();
				expect( elpete2[ "posts" ][ 1 ][ "comments" ] ).toHaveLength( 1 );
				expect( elpete2[ "posts" ][ 1 ][ "comments" ][ 1 ][ "id" ] ).toBe( 2 );
				expect( elpete2[ "posts" ][ 1 ][ "comments" ][ 1 ][ "body" ] ).toBe(
					"I thought this post was not so good"
				);

				var janedoe = users[ 3 ];
				expect( janedoe[ "username" ] ).toBe( "janedoe" );
				expect( janedoe[ "posts" ] ).toBeArray();
				expect( janedoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe[ "username" ] ).toBe( "johndoe" );
				expect( johndoe[ "posts" ] ).toBeArray();
				expect( johndoe[ "posts" ] ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete[ "username" ] ).toBe( "elpete" );
				expect( elpete[ "posts" ] ).toBeArray();
				expect( elpete[ "posts" ] ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( elpete[ "posts" ][ 1 ][ "post_pk" ] ).toBe( 523526 );
				expect( elpete[ "posts" ][ 1 ][ "comments" ] ).toBeArray();
				expect( elpete[ "posts" ][ 1 ][ "comments" ] ).toBeEmpty();

				expect( elpete[ "posts" ][ 2 ][ "post_pk" ] ).toBe( 1245 );
				expect( elpete[ "posts" ][ 2 ][ "comments" ] ).toBeArray();
				expect( elpete[ "posts" ][ 2 ][ "comments" ] ).toBeEmpty();

				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed." );
			} );

			it( "can eager load a find or first call", function() {
				var post = getInstance( "Post" )
					.with( "comments.author" )
					.asQuery()
					.findOrFail( 1245 );
				expect( post ).toBeStruct().toHaveKey( "comments" );
				var comments = post[ "comments" ];
				expect( comments ).toHaveLength( 2 );
				for ( var comment in comments ) {
					expect( comment ).toHaveKey( "author" );
					expect( comment[ "author" ] ).toBeStruct().notToBeEmpty();
				}
				if ( arrayLen( variables.queries ) != 3 ) {
					expect( variables.queries ).toHaveLength(
						3,
						"Only three queries should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "can eager load in a relationship", function() {
				expect( function() {
					var result = getInstance( "RMME_A" )
						.with( "B" )
						.asQuery()
						.get();
				} ).notToThrow();
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
