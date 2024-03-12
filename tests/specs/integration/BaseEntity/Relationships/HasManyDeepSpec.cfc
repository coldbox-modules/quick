component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "HasManyDeepSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "HasManyDeepSpec" );
		super.afterAll();
	}

	function run() {
		describe( "Has Many Deep Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can get the related entities through another entity", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var countryA = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( arrayLen( countryA.getPostsDeep() ) ).toBe( 2 );
				expect( countryA.getPostsDeep()[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( countryA.getPostsDeep()[ 1 ].getBody() ).toBe( "My awesome post body" );
				expect( countryA.getPostsDeep()[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( countryA.getPostsDeep()[ 2 ].getBody() ).toBe( "My second awesome post body" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
				variables.queries = [];
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var countryB = getInstance( "Country" ).where( "name", "Argentina" ).firstOrFail();
				expect( countryB.getPostsDeep() ).toHaveLength( 1 );
				expect( countryB.getPostsDeep()[ 1 ].getPost_Pk() ).toBe( 321 );
				expect( countryB.getPostsDeep()[ 1 ].getBody() ).toBe( "My post with a different author" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can restrict the related entity using scopes", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var countryA = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( arrayLen( countryA.getPublishedPostsDeep() ) ).toBe( 1 );
				expect( countryA.getPublishedPostsDeep()[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( countryA.getPublishedPostsDeep()[ 1 ].getBody() ).toBe( "My awesome post body" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can restrict the through entities using scopes", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var countryA = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( arrayLen( countryA.getAdminPostsDeep() ) ).toBe( 0 );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can match aliases when qualifying columns", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var countryA = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( arrayLen( countryA.getAdminPostsDeepAliased() ) ).toBe( 0 );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can get the related entities through any number of intermediate entities including a belongsToMany relationship", function() {
				var user        = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				var permissions = user.getPermissionsDeep();
				expect( permissions ).toBeArray();
				expect( permissions ).toHaveLength( 2 );
				expect( permissions[ 1 ].getId() ).toBe( 1 );
				expect( permissions[ 1 ].getName() ).toBe( "MANAGE_USERS" );
				expect( permissions[ 2 ].getId() ).toBe( 2 );
				expect( permissions[ 2 ].getName() ).toBe( "APPROVE_POSTS" );
			} );

			it( "can get the related entities through any number of intermediate entities including a polymorphicHasMany relationship", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var country  = getInstance( "Country" ).where( "name", "United States" ).firstOrFail();
				var comments = country.getPostCommentsDeep();
				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 2 );
				expect( comments[ 1 ].getId() ).toBe( 1 );
				expect( comments[ 1 ].getCommentableType() ).toBe( "Post" );
				expect( comments[ 1 ].getBody() ).toBe( "I thought this post was great" );

				expect( comments[ 2 ].getId() ).toBe( 4 );
				expect( comments[ 2 ].getCommentableType() ).toBe( "Post" );
				expect( comments[ 2 ].getBody() ).toBe( "This is an internal comment. It is very, very private." );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can restrict intermediate relationships", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var country  = getInstance( "Country" ).where( "name", "United States" ).firstOrFail();
				var comments = country.getPostPublicCommentsDeep();
				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 1 );
				expect( comments[ 1 ].getId() ).toBe( 1 );
				expect( comments[ 1 ].getCommentableType() ).toBe( "Post" );
				expect( comments[ 1 ].getBody() ).toBe( "I thought this post was great" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can apply and target table aliases", function() {
				expect( variables.queries ).toHaveLength( 0, "No queries should have been executed yet." );

				var country  = getInstance( "Country" ).where( "name", "United States" ).firstOrFail();
				var comments = country.getPostPublicCommentsDeepAliased();
				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 1 );
				expect( comments[ 1 ].getId() ).toBe( 1 );
				expect( comments[ 1 ].getCommentableType() ).toBe( "Post" );
				expect( comments[ 1 ].getBody() ).toBe( "I thought this post was great" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "can go up and down belongsTo and hasMany relationships", function() {
				var tag   = getInstance( "Tag" ).where( "name", "music" ).firstOrFail();
				var users = tag.getUsers();
				expect( users ).toBeArray();
				expect( users ).toHaveLength( 2 );
				expect( users[ 1 ].getId() ).toBe( 1 );
				expect( users[ 2 ].getId() ).toBe( 4 );
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
