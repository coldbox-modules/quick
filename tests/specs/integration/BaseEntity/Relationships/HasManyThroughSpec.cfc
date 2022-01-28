component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Has Many Through Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can get the related entities through another entity", function() {
				var countryA = getInstance( "Country@something" ).find( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
				expect( arrayLen( countryA.getPosts() ) ).toBe( 2 );
				expect( countryA.getPosts()[ 1 ].getPost_Pk() ).toBe( 1245 );
				expect( countryA.getPosts()[ 1 ].getBody() ).toBe( "My awesome post body" );
				expect( countryA.getPosts()[ 2 ].getPost_Pk() ).toBe( 523526 );
				expect( countryA.getPosts()[ 2 ].getBody() ).toBe( "My second awesome post body" );

				var countryB = getInstance( "Country" ).where( "name", "Argentina" ).firstOrFail();
				expect( countryB.getPosts() ).toHaveLength( 1 );
				expect( countryB.getPosts()[ 1 ].getPost_Pk() ).toBe( 321 );
				expect( countryB.getPosts()[ 1 ].getBody() ).toBe( "My post with a different author" );
			} );

			it( "can get the related entities through any number of intermediate entities including a belongsToMany relationship", function() {
				var country = getInstance( "Country" ).where( "name", "United States" ).firstOrFail();
				var tags = country.getTags();
				expect( tags ).toBeArray();
				expect( tags ).toHaveLength( 2 );
				expect( tags[ 1 ].getId() ).toBe( 1 );
				expect( tags[ 1 ].getName() ).toBe( "programming" );
				expect( tags[ 2 ].getId() ).toBe( 2 );
				expect( tags[ 2 ].getName() ).toBe( "music" );
			} );

			it( "can get the related entities starting with a belongsToMany relationship", function() {
				var user = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				var permissions = user.getPermissions();
				expect( permissions ).toBeArray();
				expect( permissions ).toHaveLength( 2 );
			} );

			it( "can get the related entities starting with a hasManyThrough relationship", function() {
				var country = getInstance( "Country" ).where( "name", "Argentina" ).firstOrFail();
				var permissions = country.getPermissions();
				expect( permissions ).toBeArray();
				expect( permissions ).toHaveLength( 1 );
				expect( permissions[ 1 ].getId() ).toBe( 2 );
			} );

			it( "can get the related entities starting with a polymorphicHasMany relationship", function() {
				var post = getInstance( "Post" ).findOrFail( 1245 );
				var commentingUsers = post.getCommentingUsers();
				expect( commentingUsers ).toBeArray();
				expect( commentingUsers ).toHaveLength( 1 );
				expect( commentingUsers[ 1 ].getId() ).toBe( 1 );
				expect( commentingUsers[ 1 ].getUsername() ).toBe( "elpete" );
			} );

			it( "can get the related entities through a polymorphicBelongsTo relationship", function() {
				var comment = getInstance( "Comment" ).findOrFail( 1 );
				var tags = comment.getTags();
				expect( tags ).toBeArray();
				expect( tags ).toHaveLength( 2 );
			} );

			it( "can get the related entities through any number of intermediate entities including a polymorphicHasMany relationship", function() {
				var country = getInstance( "Country" ).where( "name", "United States" ).firstOrFail();
				var comments = country.getComments();
				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 2 );
				expect( comments[ 1 ].getId() ).toBe( 1 );
				expect( comments[ 1 ].getCommentableType() ).toBe( "Post" );
				expect( comments[ 1 ].getBody() ).toBe( "I thought this post was great" );
				expect( comments[ 2 ].getId() ).toBe( 3 );
				expect( comments[ 2 ].getCommentableType() ).toBe( "Video" );
				expect( comments[ 2 ].getBody() ).toBe( "What a great video! So fun!" );
			} );

			it( "can go up and down belongsTo and hasMany relationships", function() {
				var user = getInstance( "User" ).where( "username", "elpete" ).firstOrFail();
				var teammates = user.getTeammates();
				expect( teammates ).toBeArray();
				expect( teammates ).toHaveLength( 2 );
				expect( teammates[ 1 ].getId() ).toBe( 2 );
				expect( teammates[ 2 ].getId() ).toBe( 3 );
			} );

			it( "can go up and down many belongsTo and hasMany relationships", function() {
				var user = getInstance( "User" ).where( "username", "johndoe" ).firstOrFail();
				var officemates = user.getOfficemates();
				expect( officemates ).toBeArray();
				expect( officemates ).toHaveLength( 3 );
				expect( officemates[ 1 ].getId() ).toBe( 1 );
				expect( officemates[ 2 ].getId() ).toBe( 3 );
				expect( officemates[ 3 ].getId() ).toBe( 4 );
			} );

			it( "can go up and down many belongsTo and hasMany even hasManyThrough relationships", function() {
				var user = getInstance( "User" ).where( "username", "johndoe" ).firstOrFail();
				var officemates = user.getOfficematesAlternate();
				expect( officemates ).toBeArray();
				expect( officemates ).toHaveLength( 3 );
				expect( officemates[ 1 ].getId() ).toBe( 1 );
				expect( officemates[ 2 ].getId() ).toBe( 3 );
				expect( officemates[ 3 ].getId() ).toBe( 4 );
			} );
		} );
	}

}
