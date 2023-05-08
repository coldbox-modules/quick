component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller.getInterceptorService().registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "Eager Loading Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can eager load a belongs to relationship", function() {
				var posts = getInstance( "Post" ).with( "author" ).get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				expect( posts[ 1 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
				expect( posts[ 2 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
				expect( posts[ 3 ].getAuthor() ).toBeNull();
				expect( posts[ 4 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
				if ( arrayLen( variables.queries ) != 2 ) {
					expect( variables.queries ).toHaveLength(
						2,
						"Only two queries should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "can eager load a belongs to relationship using a composite key", function() {
				var compositeChildren = getInstance( "CompositeChild" ).with( "parent" ).get();
				expect( compositeChildren ).toBeArray();
				expect( compositeChildren ).toHaveLength( 2, "2 entities should have been loaded" );
				expect( compositeChildren[ 1 ].getParent() ).notToBeNull();
				expect( compositeChildren[ 1 ].getParent() ).toBeInstanceOf( "Composite" );
				expect( compositeChildren[ 1 ].getParent().keyValues() ).toBe( [ 1, 2 ] );
				expect( compositeChildren[ 2 ].getParent() ).toBeNull();

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
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getPosts() ).toBeArray();
				expect( michaelscott.getPosts() ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2.getUsername() ).toBe( "elpete2" );
				expect( elpete2.getPosts() ).toBeArray();
				expect( elpete2.getPosts() ).toHaveLength( 1, "One post should belong to elpete2" );

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getPosts() ).toBeArray();
				expect( janedoe.getPosts() ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getPosts() ).toBeArray();
				expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );
				expect( elpete.getPosts() ).toBeArray();
				expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "respects other filters on a relationship when eager loading", function() {
				var users = getInstance( "User" )
					.with( "publishedPosts" )
					.latest()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getPublishedPosts() ).toBeArray();
				expect( michaelscott.getPublishedPosts() ).toHaveLength(
					0,
					"No posts should belong to michaelscott. Instead got #michaelscott.getPublishedPosts().len()#."
				);

				var elpete2 = users[ 2 ];
				expect( elpete2.getUsername() ).toBe( "elpete2" );
				expect( elpete2.getPublishedPosts() ).toBeArray();
				expect( elpete2.getPublishedPosts() ).toHaveLength(
					1,
					"One post should belong to elpete2. Instead got #elpete2.getPublishedPosts().len()#."
				);

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getPublishedPosts() ).toBeArray();
				expect( janedoe.getPublishedPosts() ).toHaveLength(
					0,
					"No posts should belong to janedoe. Instead got #janedoe.getPublishedPosts().len()#."
				);

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getPublishedPosts() ).toBeArray();
				expect( johndoe.getPublishedPosts() ).toHaveLength(
					0,
					"No posts should belong to johndoe. Instead got #johndoe.getPublishedPosts().len()#."
				);

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );
				expect( elpete.getPublishedPosts() ).toBeArray();
				expect( elpete.getPublishedPosts() ).toHaveLength(
					1,
					"One post should belong to elpete. Instead got #elpete.getPublishedPosts().len()#."
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
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getLatestPost() ).toBeNull();

				var elpete2 = users[ 2 ];
				expect( elpete2.getUsername() ).toBe( "elpete2" );
				expect( elpete2.getLatestPost() ).notToBeNull();

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getLatestPost() ).toBeNull();

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getLatestPost() ).toBeNull();

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );
				expect( elpete.getLatestPost() ).notToBeNull();

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a belongs to many relationship", function() {
				var posts = getInstance( "Post" ).with( "tags" ).get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getTags() ).toBeArray();
				expect( posts[ 1 ].getTags() ).toHaveLength( 0 );

				expect( posts[ 2 ].getTags() ).toBeArray();
				expect( posts[ 2 ].getTags() ).toHaveLength( 2 );
				expect( posts[ 2 ].getTags()[ 1 ].getName() ).toBe( "programming" );
				expect( posts[ 2 ].getTags()[ 2 ].getName() ).toBe( "music" );

				expect( posts[ 3 ].getTags() ).toBeArray();
				expect( posts[ 3 ].getTags() ).toHaveLength( 0 );

				expect( posts[ 4 ].getTags() ).toBeArray();
				expect( posts[ 4 ].getTags() ).toHaveLength( 2 );
				expect( posts[ 4 ].getTags()[ 1 ].getName() ).toBe( "programming" );
				expect( posts[ 4 ].getTags()[ 2 ].getName() ).toBe( "music" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a has many through relationship", function() {
				var countries = getInstance( "Country" ).with( "posts" ).get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ].getPosts() ).toBeArray();
				expect( countries[ 1 ].getPosts() ).toHaveLength( 2 );
				expect( countries[ 1 ].getPosts()[ 1 ].getBody() ).toBe( "My awesome post body" );
				expect( countries[ 1 ].getPosts()[ 2 ].getBody() ).toBe( "My second awesome post body" );

				expect( countries[ 2 ].getPosts() ).toBeArray();
				expect( countries[ 2 ].getPosts() ).toHaveLength( 1 );
				expect( countries[ 2 ].getPosts()[ 1 ].getBody() ).toBe( "My post with a different author" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a long has many through relationship", function() {
				var countries = getInstance( "Country" ).with( "comments" ).get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ].getComments() ).toBeArray();
				expect( countries[ 1 ].getComments() ).toHaveLength( 1 );
				expect( countries[ 1 ].getComments()[ 1 ].getBody() ).toBe( "I thought this post was great" );

				expect( countries[ 2 ].getComments() ).toBeArray();
				expect( countries[ 2 ].getComments() ).toHaveLength( 1 );
				expect( countries[ 2 ].getComments()[ 1 ].getBody() ).toBe( "I thought this post was not so good" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load a recursive has many through relationship", function() {
				var countries = getInstance( "Country" ).with( "commentsUsingHasManyThrough" ).get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ].getCommentsUsingHasManyThrough() ).toBeArray();
				expect( countries[ 1 ].getCommentsUsingHasManyThrough() ).toHaveLength( 1 );
				expect( countries[ 1 ].getCommentsUsingHasManyThrough()[ 1 ].getBody() ).toBe(
					"I thought this post was great"
				);

				expect( countries[ 2 ].getCommentsUsingHasManyThrough() ).toBeArray();
				expect( countries[ 2 ].getCommentsUsingHasManyThrough() ).toHaveLength( 1 );
				expect( countries[ 2 ].getCommentsUsingHasManyThrough()[ 1 ].getBody() ).toBe(
					"I thought this post was not so good"
				);

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can eager load polymorphic belongs to relationships", function() {
				var comments = getInstance( "Comment" )
					.where( "designation", "public" )
					.with( "commentable" )
					.get();

				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 3 );

				expect( comments[ 1 ].getId() ).toBe( 1 );
				expect( comments[ 1 ].getCommentable().entityName() ).toBe( "Post" );
				expect( comments[ 1 ].getCommentable().getPost_Pk() ).toBe( 1245 );

				expect( comments[ 2 ].getId() ).toBe( 2 );
				expect( comments[ 2 ].getCommentable().entityName() ).toBe( "Post" );
				expect( comments[ 2 ].getCommentable().getPost_Pk() ).toBe( 321 );

				expect( comments[ 3 ].getId() ).toBe( 3 );
				expect( comments[ 3 ].getCommentable().entityName() ).toBe( "Video" );
				expect( comments[ 3 ].getCommentable().getId() ).toBe( 1245 );

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

				var posts = getInstance( "Post" ).with( "comments" ).get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getComments() ).toBeArray();
				expect( posts[ 1 ].getComments() ).toHaveLength( 1 );

				expect( posts[ 2 ].getComments() ).toBeArray();
				expect( posts[ 2 ].getComments() ).toHaveLength( 1 );

				expect( posts[ 3 ].getComments() ).toBeArray();
				expect( posts[ 3 ].getComments() ).toBeEmpty();

				expect( posts[ 4 ].getComments() ).toBeArray();
				expect( posts[ 4 ].getComments() ).toBeEmpty();

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
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getPosts() ).toBeArray();
				expect( michaelscott.getPosts() ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2.getUsername() ).toBe( "elpete2" );
				expect( elpete2.getPosts() ).toBeArray();
				expect( elpete2.getPosts() ).toHaveLength( 1, "One post should belong to elpete2" );

				expect( elpete2.getPosts()[ 1 ].getComments() ).toBeArray();
				expect( elpete2.getPosts()[ 1 ].getComments() ).toHaveLength( 1 );
				expect( elpete2.getPosts()[ 1 ].getComments()[ 1 ].getId() ).toBe( 2 );
				expect( elpete2.getPosts()[ 1 ].getComments()[ 1 ].getBody() ).toBe(
					"I thought this post was not so good"
				);

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getPosts() ).toBeArray();
				expect( janedoe.getPosts() ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getPosts() ).toBeArray();
				expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );

				expect( elpete.getPosts() ).toBeArray();
				expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( elpete.getPosts()[ 1 ].getPost_Pk() ).toBe( 523526 );
				expect( elpete.getPosts()[ 1 ].getComments() ).toBeArray();
				expect( elpete.getPosts()[ 1 ].getComments() ).toBeEmpty();

				expect( elpete.getPosts()[ 2 ].getPost_Pk() ).toBe( 1245 );
				expect( elpete.getPosts()[ 2 ].getComments() ).toBeArray();
				expect( elpete.getPosts()[ 2 ].getComments() ).toHaveLength( 1 );
				expect( elpete.getPosts()[ 2 ].getComments()[ 1 ].getId() ).toBe( 1 );
				expect( elpete.getPosts()[ 2 ].getComments()[ 1 ].getBody() ).toBe( "I thought this post was great" );

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
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getPosts() ).toBeArray();
				expect( michaelscott.getPosts() ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getPosts() ).toBeArray();
				expect( janedoe.getPosts() ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getPosts() ).toBeArray();
				expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );
				expect( elpete.getPosts() ).toBeArray();
				expect( elpete.getPosts() ).toHaveLength( 1, "One post should belong to elpete" );

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
					.get();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var michaelscott = users[ 1 ];
				expect( michaelscott.getUsername() ).toBe( "michaelscott" );
				expect( michaelscott.getPosts() ).toBeArray();
				expect( michaelscott.getPosts() ).toHaveLength( 0, "No posts should belong to michaelscott" );

				var elpete2 = users[ 2 ];
				expect( elpete2.getUsername() ).toBe( "elpete2" );
				expect( elpete2.getPosts() ).toBeArray();
				expect( elpete2.getPosts() ).toHaveLength( 1, "One post should belong to elpete2" );

				expect( elpete2.getPosts()[ 1 ].getComments() ).toBeArray();
				expect( elpete2.getPosts()[ 1 ].getComments() ).toHaveLength( 1 );
				expect( elpete2.getPosts()[ 1 ].getComments()[ 1 ].getId() ).toBe( 2 );
				expect( elpete2.getPosts()[ 1 ].getComments()[ 1 ].getBody() ).toBe(
					"I thought this post was not so good"
				);

				var janedoe = users[ 3 ];
				expect( janedoe.getUsername() ).toBe( "janedoe" );
				expect( janedoe.getPosts() ).toBeArray();
				expect( janedoe.getPosts() ).toHaveLength( 0, "No posts should belong to janedoe" );

				var johndoe = users[ 4 ];
				expect( johndoe.getUsername() ).toBe( "johndoe" );
				expect( johndoe.getPosts() ).toBeArray();
				expect( johndoe.getPosts() ).toHaveLength( 0, "No posts should belong to johndoe" );

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );
				expect( elpete.getPosts() ).toBeArray();
				expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

				expect( elpete.getPosts()[ 1 ].getPost_Pk() ).toBe( 523526 );
				expect( elpete.getPosts()[ 1 ].getComments() ).toBeArray();
				expect( elpete.getPosts()[ 1 ].getComments() ).toBeEmpty();

				expect( elpete.getPosts()[ 2 ].getPost_Pk() ).toBe( 1245 );
				expect( elpete.getPosts()[ 2 ].getComments() ).toBeArray();
				expect( elpete.getPosts()[ 2 ].getComments() ).toBeEmpty();

				expect( variables.queries ).toHaveLength( 3, "Only three queries should have been executed." );
			} );

			it( "can eager load a find or first call", function() {
				var post     = getInstance( "Post" ).with( "comments.author" ).findOrFail( 1245 );
				var comments = post.getComments();
				expect( comments ).toHaveLength( 2 );
				for ( var comment in comments ) {
					expect( comment.getAuthor() ).notToBeNull();
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
					var result = getInstance( "RMME_A" ).with( "B" ).get();
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
