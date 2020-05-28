component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Querying Relationships Spec", function() {
			describe( "has", function() {
				describe( "hasMany", function() {
					it( "can find only entities that have one or more related entities", function() {
						var users = getInstance( "User" ).has( "posts" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "can constrain the count of the has check", function() {
						var users = getInstance( "User" ).has( "posts", ">=", 2 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 1 );
					} );

					it( "can use orHas as well", function() {
						var users = getInstance( "User" )
							.where( function( q ) {
								q.has( "posts", "=", 2 );
								q.orHas( "posts", "=", 1 );
							} )
							.get();

						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "can constrain a has query using whereHas", function() {
						var users = getInstance( "User" )
							.whereHas( "posts", function( q ) {
								q.where( "body", "like", "%different%" );
							} )
							.get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 1 );
					} );

					it( "can constrain a has query using whereHas and orWhereHas", function() {
						var users = getInstance( "User" )
							.where( function( q ) {
								q
									.whereHas( "posts", function( q ) {
										q.where( "body", "like", "%different%" );
									} )
									.orWhereHas( "posts", function( q ) {
										q.where( "body", "like", "%awesome%" );
									} );
							} )
							.get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "can check nested relationships for existence", function() {
						var users = getInstance( "User" ).has( "posts.comments" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "applies count constraints to the final relationship in a nested relationship existence check", function() {
						var users = getInstance( "User" ).has( "posts.comments", "=", 1 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );

						var users = getInstance( "User" ).has( "posts.comments", ">", 1 ).get();
						expect( users ).toBeArray();
						expect( users ).toBeEmpty();
					} );

					it( "applies whereHas constraints to the final relationship in a nested relationship existence check", function() {
						var users = getInstance( "User" )
							.whereHas( "posts.comments", function( q ) {
								q.where( "body", "like", "%great%" );
							} )
							.get();

						expect( users ).toBeArray();
						expect( users ).toHaveLength( 1 );
					} );

					it( "can use orWhereHas with nested relationships", function() {
						var users = getInstance( "User" )
							.where( function( q ) {
								q.doesntHave( "posts" );
								q.orWhereHas( "posts.comments", function( q2 ) {
									q2.where( "body", "like", "%great%" );
								} );
							} )
							.get();

						expect( users ).toBeArray();
						expect( users ).toHaveLength( 3 );
					} );

					it( "can apply counts to a whereHas constraint", function() {
						var users = getInstance( "User" )
							.whereHas(
								"posts",
								function( q ) {
									q.where( "body", "like", "%different%" );
								},
								">",
								3
							)
							.get();
						expect( users ).toBeArray();
						expect( users ).toBeEmpty();
					} );

					it( "can apply counts to nested whereHas constraint", function() {
						var users = getInstance( "User" )
							.whereHas(
								"posts.comments",
								function( q ) {
									q.where( "body", "like", "%great%" );
								},
								">",
								3
							)
							.get();

						expect( users ).toBeArray();
						expect( users ).toBeEmpty();
					} );
				} );

				describe( "belongsTo", function() {
					it( "can find only entities that have a related entity", function() {
						var posts = getInstance( "Post" ).has( "author" ).get();
						expect( posts ).toBeArray();
						expect( posts ).toHaveLength( 3 );
					} );
				} );

				describe( "belongsToMany", function() {
					it( "can find only entities that have a related belongsToMany entity", function() {
						var posts = getInstance( "Post" ).has( "tags" ).get();
						expect( posts ).toBeArray();
						expect( posts ).toHaveLength( 2 );
					} );

					it( "can use whereHas on a belongsToMany relationship", function() {
						var posts = getInstance( "Post" )
							.whereHas( "tags", function( q ) {
								q.where( "name", "doesnt-exist" );
							} )
							.get();

						expect( posts ).toBeEmpty();
					} );

					it( "can use whereHas on a nested belongsToMany relationship", function() {
						var posts = getInstance( "Post" )
							.whereHas( "author.roles", function( q ) {
								expect( q.getEntity().entityName() ).toBe( "Role" );
								q.where( "id", 2 );
							} )
							.get();
						expect( posts ).toBeArray();
						expect( posts ).toHaveLength( 1 );
						expect( posts[ 1 ].getAuthor().getId() ).toBe( 4 );
					} );
				} );

				describe( "hasManyThrough", function() {
					it( "can find only entities that have a related hasManyThrough entity", function() {
						var countries = getInstance( "Country" ).has( "posts" ).get();
						expect( countries ).toBeArray();
						expect( countries ).toHaveLength( 2 );
					} );
				} );

				describe( "hasOne", function() {
					it( "can find only entities that have a related hasOne entity", function() {
						var users = getInstance( "User" ).has( "latestPost" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );
				} );
			} );

			describe( "doesntHave", function() {
				describe( "hasMany", function() {
					it( "can find only entities that do not have one or more related entities", function() {
						var users = getInstance( "User" ).doesntHave( "posts" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "can constrain the count of the doesntHave check", function() {
						var users = getInstance( "User" ).doesntHave( "posts", ">=", 2 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 3 );

						var users = getInstance( "User" ).doesntHave( "posts", "=", 1 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 3 );
					} );

					it( "can constrain a has query using whereDoesntHave", function() {
						var users = getInstance( "User" )
							.whereDoesntHave( "posts", function( q ) {
								q.where( "body", "like", "%different%" );
							} )
							.get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 3 );
					} );

					it( "can constrain a has query using whereDoesntHave and orWhereDoesntHave", function() {
						var users = getInstance( "User" )
							.whereDoesntHave( "posts", function( q ) {
								q.where( "body", "like", "%different%" );
							} )
							.orWhereDoesntHave( "posts", function( q ) {
								q.where( "body", "like", "%awesome%" );
							} )
							.get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 4 );
					} );

					it( "can check nested relationships for absence", function() {
						var users = getInstance( "User" ).doesntHave( "posts.comments" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );

					it( "applies count constraints to the final relationship in a nested relationship absence check", function() {
						var users = getInstance( "User" ).doesntHave( "posts.comments", "=", 1 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );

						var users = getInstance( "User" ).doesntHave( "posts.comments", ">", 1 ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 4 );
					} );

					it( "applies whereDoesntHave constraints to the final relationship in a nested relationship existence check", function() {
						var users = getInstance( "User" )
							.whereDoesntHave( "posts.comments", function( q ) {
								q.where( "body", "like", "%great%" );
							} )
							.get();

						expect( users ).toBeArray();
						expect( users ).toHaveLength( 3 );
					} );

					it( "can apply counts to a whereDoesntHave constraint", function() {
						var users = getInstance( "User" )
							.whereDoesntHave(
								"posts",
								function( q ) {
									q.where( "body", "like", "%different%" );
								},
								">",
								3
							)
							.get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 4 );
					} );

					it( "can apply counts to nested whereDoesntHave constraint", function() {
						var users = getInstance( "User" )
							.whereDoesntHave(
								"posts.comments",
								function( q ) {
									q.where( "body", "like", "%great%" );
								},
								">",
								3
							)
							.get();

						expect( users ).toBeArray();
						expect( users ).toHaveLength( 4 );
					} );
				} );

				describe( "belongsTo", function() {
					it( "can find only entities that do not have a related entity", function() {
						var posts = getInstance( "Post" ).doesntHave( "author" ).get();
						expect( posts ).toBeArray();
						expect( posts ).toHaveLength( 1 );
					} );
				} );

				describe( "belongsToMany", function() {
					it( "can find only entities that do not have a related belongsToMany entity", function() {
						var posts = getInstance( "Post" ).doesntHave( "tags" ).get();
						expect( posts ).toBeArray();
						expect( posts ).toHaveLength( 2 );
					} );
				} );

				describe( "hasManyThrough", function() {
					it( "can find only entities that do not have a related hasManyThrough entity", function() {
						var countries = getInstance( "Country" ).doesntHave( "posts" ).get();
						expect( countries ).toBeArray();
						expect( countries ).toBeEmpty();
					} );
				} );

				describe( "hasOne", function() {
					it( "can find only entities that do not have a related hasOne entity", function() {
						var users = getInstance( "User" ).doesntHave( "latestPost" ).get();
						expect( users ).toBeArray();
						expect( users ).toHaveLength( 2 );
					} );
				} );
			} );
		} );
	}

}
