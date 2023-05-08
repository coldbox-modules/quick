component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller.getInterceptorService().registerInterceptor( interceptorObject = this );
	}

	function run() {
		describe( "Relationships Count spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can add a subselect for the count of a relationship without loading the relationship", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];

				var posts = getInstance( "Post" )
					.withCount( "comments" )
					.orderBy( "createdDate" )
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( posts[ 1 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 1 ].getCommentsCount() ).toBe( 1 );

				expect( posts[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( posts[ 2 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 2 ].getCommentsCount() ).toBe( 0 );

				expect( posts[ 3 ].getPost_Pk() ).toBe( 7777 );
				expect( posts[ 3 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 3 ].getCommentsCount() ).toBe( 0 );

				expect( posts[ 4 ].getPost_Pk() ).toBe( 321 );
				expect( posts[ 4 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 4 ].getCommentsCount() ).toBe( 1 );
			} );

			it( "can order by a loaded count", function() {
				var posts = getInstance( "Post" )
					.withCount( "comments" )
					.orderBy( [ "commentsCount DESC", "createdDate" ] )
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );
				expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( posts[ 2 ].getPost_Pk() ).toBe( 321 );
				expect( posts[ 3 ].getPost_Pk() ).toBe( 523526 );
				expect( posts[ 4 ].getPost_Pk() ).toBe( 7777 );
			} );

			it( "can add multiple counts at once", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];

				var posts = getInstance( "Post" )
					.withCount( [ "comments", "tags" ] )
					.orderBy( "createdDate" )
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( posts[ 1 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 1 ].getCommentsCount() ).toBe( 1 );
				expect( posts[ 1 ].hasAttribute( "tagsCount" ) ).toBeTrue(
					"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `tagsCount`."
				);
				expect( posts[ 1 ].getTagsCount() ).toBe( 2 );

				expect( posts[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( posts[ 2 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 2 ].getCommentsCount() ).toBe( 0 );
				expect( posts[ 2 ].hasAttribute( "tagsCount" ) ).toBeTrue(
					"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `tagsCount`."
				);
				expect( posts[ 2 ].getTagsCount() ).toBe( 2 );

				expect( posts[ 3 ].getPost_Pk() ).toBe( 7777 );
				expect( posts[ 3 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 3 ].getCommentsCount() ).toBe( 0 );
				expect( posts[ 3 ].hasAttribute( "tagsCount" ) ).toBeTrue(
					"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `tagsCount`."
				);
				expect( posts[ 3 ].getTagsCount() ).toBe( 0 );

				expect( posts[ 4 ].getPost_Pk() ).toBe( 321 );
				expect( posts[ 4 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 4 ].getCommentsCount() ).toBe( 1 );
				expect( posts[ 4 ].hasAttribute( "tagsCount" ) ).toBeTrue(
					"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `tagsCount`."
				);
				expect( posts[ 4 ].getTagsCount() ).toBe( 0 );
			} );

			it( "can constrain counts at runtime", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];

				var posts = getInstance( "Post" )
					.withCount( {
						"comments" : function( q ) {
							q.where( "userId", 1 );
						}
					} )
					.orderBy( "createdDate" )
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( posts[ 1 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 1 ].getCommentsCount() ).toBe( 1 );

				expect( posts[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( posts[ 2 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 2 ].getCommentsCount() ).toBe( 0 );

				expect( posts[ 3 ].getPost_Pk() ).toBe( 7777 );
				expect( posts[ 3 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 3 ].getCommentsCount() ).toBe( 0 );

				expect( posts[ 4 ].getPost_Pk() ).toBe( 321 );
				expect( posts[ 4 ].hasAttribute( "commentsCount" ) ).toBeTrue(
					"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `commentsCount`."
				);
				expect( posts[ 4 ].getCommentsCount() ).toBe( 0 );
			} );

			it( "can alias the counts attribute name", function() {
				// delete our internal comments to allow the test to pass:
				getInstance( "InternalComment" )
					.get()
					.each( function( comment ) {
						comment.delete();
					} );
				variables.queries = [];

				var posts = getInstance( "Post" )
					.withCount( "comments AS comments_count" )
					.orderBy( "createdDate" )
					.get();

				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4 );

				expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( posts[ 1 ].hasAttribute( "comments_count" ) ).toBeTrue(
					"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `comments_count`."
				);
				expect( posts[ 1 ].getcomments_count() ).toBe( 1 );

				expect( posts[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( posts[ 2 ].hasAttribute( "comments_count" ) ).toBeTrue(
					"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `comments_count`."
				);
				expect( posts[ 2 ].getcomments_count() ).toBe( 0 );

				expect( posts[ 3 ].getPost_Pk() ).toBe( 7777 );
				expect( posts[ 3 ].hasAttribute( "comments_count" ) ).toBeTrue(
					"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `comments_count`."
				);
				expect( posts[ 3 ].getcomments_count() ).toBe( 0 );

				expect( posts[ 4 ].getPost_Pk() ).toBe( 321 );
				expect( posts[ 4 ].hasAttribute( "comments_count" ) ).toBeTrue(
					"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `comments_count`."
				);
				expect( posts[ 4 ].getcomments_count() ).toBe( 1 );
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
