component extends="tests.resources.ModuleIntegrationSpec" {

	function beforeAll() {
		super.beforeAll();
		controller
			.getInterceptorService()
			.registerInterceptor( interceptorObject = this, interceptorName = "EagerLoadingSpec" );
	}

	function afterAll() {
		controller.getInterceptorService().unregister( "EagerLoadingSpec" );
		super.afterAll();
	}

	function run() {
		registerCoreEagerLoadingTests();
		registerParallelExecutionTests();
		registerParallelRelationshipStateTests();
		registerParallelQueryExecutionTests();
		registerParallelHydrationStateTests();
		registerParallelLifecycleTransactionTests();
		registerEagerLoadingContinuedTests();
		registerRelationTypeTests();
		registerPolymorphicNestedTests();
		registerRetrievalDefaultTests();
		registerLazyLoadingTests();
		registerAutomaticEagerLoadingTests();
		registerMultipleNestedEagerLoadingTests();
	}

	private void function registerCoreEagerLoadingTests() {
		describe( "Eager Loading Spec", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
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

			it( "preserves numeric binding types when eager loading a belongs to relationship", function() {
				getInstance( "Post" ).with( "author" ).get();

				expect( variables.queries ).toHaveLength( 2 );
				var bindingTypes = extractBindingTypes( variables.queries[ 2 ] );

				expect( bindingTypes ).notToBeEmpty();
				for ( var bindingType in bindingTypes ) {
					expect( bindingType ).notToInclude( "varchar" );
					expect( bindingType ).toInclude( "integer" );
				}
			} );

			it( "keeps belongs to eager keys that differ only by case", function() {
				var post         = getInstance( "Post" ).firstOrFail();
				var relationship = post.author();
				var keys         = relationship.getEagerEntityKeys(
					[
						{ "user_id" : "ABC" },
						{ "user_id" : "abc" }
					],
					post
				);

				expect( keys ).toHaveLength( 2 );
			} );
		} );
	}

	private void function registerParallelExecutionTests() {
		describe( "parallel eager loading execution", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );

			it(
				"can eager load top-level relationships in parallel",
				function() {
					var callingThread   = createObject( "java", "java.lang.Thread" ).currentThread().getName();
					var callbackThreads = {};
					var posts           = getInstance( "Post" )
						.with(
							[
								{
									"author" : function( relationship ) {
										callbackThreads.author = createObject( "java", "java.lang.Thread" )
											.currentThread()
											.getName();
									}
								},
								{
									"comments" : function( relationship ) {
										callbackThreads.comments = createObject( "java", "java.lang.Thread" )
											.currentThread()
											.getName();
									}
								}
							],
							true
						)
						.get();

					expect( posts[ 1 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
					expect( posts[ 1 ].getComments() ).toBeArray();
					expect( callbackThreads.author ).toBe( callingThread );
					expect( callbackThreads.comments ).toBe( callingThread );
					expect( variables.workerQueryThreads.size() ).toBe( supportsParallelEagerLoadingForTest() ? 2 : 0 );
					expect( variables.workerRequestContexts.size() ).toBe(
						supportsParallelEagerLoadingForTest() ? 2 : 0
					);
				},
				"no-transaction"
			);

			it( "keeps a single eager load on the calling thread", function() {
				var callingThread = createObject( "java", "java.lang.Thread" ).currentThread().getName();
				var eagerThread   = "";
				getInstance( "Post" )
					.with(
						{
							"author" : function( relationship ) {
								eagerThread = createObject( "java", "java.lang.Thread" ).currentThread().getName();
							}
						},
						true
					)
					.get();

				expect( eagerThread ).toBe( callingThread );
			} );

			it(
				"delivers lifecycle events once on the returned parallel entities",
				function() {
					var users = getInstance( "ParallelLifecycleUser" )
						.where( "id", 1 )
						.with( [ "posts", "comments" ], true )
						.get();

					expect( users ).toHaveLength( 1 );
					expect( request.parallelLifecyclePostLoads ).toHaveLength( 1 );
					expect( request.parallelLifecyclePostLoads[ 1 ].isSameAs( users[ 1 ] ) ).toBeTrue();
					for ( var post in users[ 1 ].getPosts() ) {
						expect( post.retrieveRelationship( "loadedByUser" ).isSameAs( users[ 1 ] ) ).toBeTrue();
					}
				},
				"no-transaction"
			);
		} );
	}

	private void function registerParallelRelationshipStateTests() {
		describe( "parallel eager loading relationship state", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );
			it(
				"preserves nested eager loads in parallel relationship graphs",
				function() {
					var post = getInstance( "Post" )
						.where( "post_pk", 1245 )
						.with( [ "author.country", "comments.author" ], true )
						.firstOrFail();

					expect( post.getAuthor().isRelationshipLoaded( "country" ) ).toBeTrue();
					for ( var comment in post.getComments() ) {
						expect( comment.isRelationshipLoaded( "author" ) ).toBeTrue();
					}
				},
				"no-transaction"
			);

			it(
				"preserves pivot relationships in parallel relationship graphs",
				function() {
					var post = getInstance( "Post" )
						.where( "post_pk", 1245 )
						.with( [ "tagsAsSubscriptions", "comments" ], true )
						.firstOrFail();

					for ( var tag in post.getTagsAsSubscriptions() ) {
						expect( tag.isRelationshipLoaded( "subscription" ) ).toBeTrue();
						var pivot = tag.getSubscription();
						expect( pivot ).toBeInstanceOf( "quick.models.Relationships.Pivot" );
						expect( pivot.getContext() ).notToBeEmpty();
						expect( pivot.getPivotParent() ).toBeInstanceOf( "app.models.Post" );
						expect( pivot.getPivotRelated().isSameAs( tag ) ).toBeTrue();
					}
				},
				"no-transaction"
			);

			it(
				"supports polymorphic belongs-to relationships in parallel",
				function() {
					var comments = getInstance( "Comment" )
						.where( "designation", "public" )
						.with( [ "commentable", "author" ], true )
						.get();

					expect( comments ).toHaveLength( 3 );
					expect( comments[ 1 ].getCommentable() ).toBeInstanceOf( "app.models.Post" );
					expect( comments[ 3 ].getCommentable() ).toBeInstanceOf( "app.models.Video" );
					expect( comments[ 1 ].getAuthor() ).toBeInstanceOf( "app.models.User" );
					expect( variables.workerQueryThreads.size() ).toBe( supportsParallelEagerLoadingForTest() ? 2 : 0 );
				},
				"no-transaction"
			);

			it(
				"applies relationship global scopes on the calling thread",
				function() {
					var callingThread                 = createObject( "java", "java.lang.Thread" ).currentThread().getName();
					request.trackParallelScopeThreads = true;
					request.parallelScopeThreads      = [];

					getInstance( "Post" ).with( [ "scopedAuthor", "comments" ], true ).get();

					expect( request.parallelScopeThreads ).notToBeEmpty();
					for ( var scopeThread in request.parallelScopeThreads ) {
						expect( scopeThread ).toBe( callingThread );
					}
				},
				"no-transaction"
			);
		} );
	}

	private void function registerParallelQueryExecutionTests() {
		describe( "parallel eager loading query execution", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );
			it(
				"supports parallel eager loading for query results",
				function() {
					var posts = getInstance( "Post" )
						.with( [ "author", "comments" ], true )
						.asQuery()
						.get();

					expect( posts[ 1 ] ).toBeStruct();
					expect( posts[ 1 ].author ).toBeStruct();
					expect( posts[ 1 ].comments ).toBeArray();
					expect( posts[ 3 ].author ).toBeStruct().toBeEmpty();
					expect( posts[ 1 ].author ).toHaveKey( "streetTwo" );
				},
				"no-transaction"
			);

			it(
				"limits the number of concurrent eager-loading workers",
				function() {
					if ( supportsParallelEagerLoadingForTest() ) {
						variables.parallelWorkerDelay = 25;
						var builder                   = getInstance( "Post" ).with( [ "author", "comments" ], true );
						builder.set_parallelEagerLoadingMaxThreads( 1 ).get();

						expect( variables.maxActiveWorkers.get() ).toBe( 1 );
					}
				},
				"no-transaction"
			);

			it(
				"propagates parallel eager-loading worker failures",
				function() {
					if ( supportsParallelEagerLoadingForTest() ) {
						variables.failParallelWorker = true;
						expect( function() {
							getInstance( "Post" ).with( [ "author", "comments" ], true ).get();
						} ).toThrow( type = "QuickParallelEagerLoadingException" );
					}
				},
				"no-transaction"
			);

			it(
				"times out and cancels unfinished parallel eager-loading workers",
				function() {
					if ( supportsParallelEagerLoadingForTest() ) {
						var coordinator               = getInstance( "quick.models.ParallelEagerLoadingCoordinator" );
						variables.parallelWorkerDelay = 100;
						var builder                   = getInstance( "Post" ).with( [ "author", "comments" ], true );
						builder.set_parallelEagerLoadingTimeout( 1 );

						expect( function() {
							builder.get();
						} ).toThrow( type = "QuickParallelEagerLoadingTimeout", regex = "1 milliseconds" );

						variables.parallelWorkerDelay = 0;
						var posts                     = getInstance( "Post" ).with( [ "author", "comments" ], true ).get();
						expect( posts ).notToBeEmpty();
						expect( coordinator.getExecutor().getMaximumPoolSize() ).toBeGT( 0 );
					}
				},
				"no-transaction"
			);
		} );
	}

	private void function registerParallelHydrationStateTests() {
		describe( "parallel eager loading hydration state", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );
			it(
				"hydrates virtual attributes on the calling thread",
				function() {
					var post = getInstance( "Post" )
						.where( "post_pk", 1245 )
						.with(
							[
								{
									"comments" : function( relationship ) {
										relationship.addUpperBody();
									}
								},
								"author"
							],
							true
						)
						.firstOrFail();

					for ( var comment in post.getComments() ) {
						expect( comment.hasAttribute( "upperBody" ) ).toBeTrue();
						expect( comment.retrieveAttribute( "upperBody" ) ).toBe( uCase( comment.getBody() ) );
					}
				},
				"no-transaction"
			);

			it(
				"preserves unloaded default relationship entities",
				function() {
					var post = getInstance( "Post" )
						.whereNull( "user_id" )
						.with( [ "authorWithEmptyDefault", "comments" ], true )
						.firstOrFail();

					expect( post.getAuthorWithEmptyDefault() ).toBeInstanceOf( "app.models.User" );
					expect( post.getAuthorWithEmptyDefault().isLoaded() ).toBeFalse();
				},
				"no-transaction"
			);

			it(
				"preserves parallel eager loading when cloning a builder",
				function() {
					getInstance( "Post" )
						.with( [ "author", "comments" ], true )
						.clone()
						.get();

					expect( variables.workerQueryThreads.size() ).toBe( supportsParallelEagerLoadingForTest() ? 2 : 0 );
				},
				"no-transaction"
			);

			it(
				"clears the parallel flag with eager loads",
				function() {
					getInstance( "Post" )
						.with( [ "author", "comments" ], true )
						.clearEagerLoads()
						.with( [ "author", "comments" ] )
						.get();

					expect( variables.workerQueryThreads ).toBeEmpty();
				},
				"no-transaction"
			);

			it(
				"clears the parallel flag when without removes every eager load",
				function() {
					getInstance( "Post" )
						.with( [ "author", "comments" ], true )
						.without( [ "author", "comments" ] )
						.with( [ "author", "comments" ] )
						.get();

					expect( variables.workerQueryThreads ).toBeEmpty();
				},
				"no-transaction"
			);
		} );
	}

	private void function registerParallelLifecycleTransactionTests() {
		describe( "parallel eager loading lifecycle and transactions", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );
			it(
				"does not duplicate instance-ready events during parallel hydration",
				function() {
					variables.trackInstanceReady = true;
					getInstance( "Post" ).with( [ "author", "comments" ] ).get();
					var serialInstanceCount = variables.instanceReadyCount.get();

					variables.instanceReadyCount.set( 0 );
					getInstance( "Post" ).with( [ "author", "comments" ], true ).get();

					expect( variables.instanceReadyCount.get() ).toBe( serialInstanceCount );
				},
				"no-transaction"
			);

			it(
				"does not suppress lifecycle events for queries inside eager callbacks",
				function() {
					getInstance( "Post" )
						.with(
							[
								{
									"author" : function( relationship ) {
										getInstance( "ParallelLifecycleUser" ).where( "id", 1 ).get();
									}
								},
								"comments"
							],
							true
						)
						.get();

					expect( request.parallelLifecyclePostLoads ).toHaveLength( 1 );
				},
				"no-transaction"
			);

			it(
				"uses an application-wide fixed worker pool",
				function() {
					if ( !supportsParallelEagerLoadingForTest() ) {
						return;
					}
					var firstCoordinator  = getInstance( "quick.models.ParallelEagerLoadingCoordinator" );
					var secondCoordinator = getInstance( "quick.models.ParallelEagerLoadingCoordinator" );
					var executor          = firstCoordinator.getExecutor();
					var submissionsBefore = executor.getTaskSubmissionCount();

					expect( firstCoordinator ).toBe( secondCoordinator );
					expect( executor.getMaximumPoolSize() ).toBe( 4 );
					getInstance( "Post" ).with( [ "author", "comments" ], true ).get();
					getInstance( "Post" ).with( [ "author", "comments" ], true ).get();
					expect( executor.getTaskSubmissionCount() ).toBe( submissionsBefore + 4 );
					expect( executor.getLargestPoolSize() ).toBeLTE( executor.getMaximumPoolSize() );
				},
				"no-transaction"
			);

			it( "falls back to serial eager loading inside a database transaction", function() {
				var user = getInstance( "User" ).create( {
					"username"   : "parallel-transaction-user",
					"first_name" : "Parallel",
					"last_name"  : "Transaction",
					"password"   : hash( "password" )
				} );
				getInstance( "Post" ).create( {
					"user_id" : user.getId(),
					"body"    : "uncommitted parallel eager load"
				} );

				var loadedUser = getInstance( "User" )
					.where( "id", user.getId() )
					.with( [ "posts", "roles" ], true )
					.firstOrFail();

				expect( loadedUser.getPosts() ).toHaveLength( 1 );
				expect( loadedUser.getPosts()[ 1 ].getBody() ).toBe( "uncommitted parallel eager load" );
				expect( variables.workerQueryThreads ).toBeEmpty();
			} );
		} );
	}

	private void function registerEagerLoadingContinuedTests() {
		describe( "Eager Loading Spec continued", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
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
		} );
	}

	private void function registerRelationTypeTests() {
		describe( "Eager Loading Spec relation types", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
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
				expect( posts[ 1 ].getTags() ).toHaveLength( 1 );

				expect( posts[ 2 ].getTags() ).toBeArray();
				expect( posts[ 2 ].getTags() ).toHaveLength( 2 );
				expect( posts[ 2 ].getTags()[ 1 ].getName() ).toBe( "programming" );
				expect( posts[ 2 ].getTags()[ 2 ].getName() ).toBe( "music" );

				expect( posts[ 3 ].getTags() ).toBeArray();
				expect( posts[ 3 ].getTags() ).toHaveLength( 0 );

				expect( posts[ 4 ].getTags() ).toBeArray();
				expect( posts[ 4 ].getTags() ).toHaveLength( 3 );
				expect( posts[ 4 ].getTags()[ 1 ].getName() ).toBe( "programming" );
				expect( posts[ 4 ].getTags()[ 2 ].getName() ).toBe( "music" );
				expect( posts[ 4 ].getTags()[ 3 ].getName() ).toBe( "gaming" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "preserves numeric binding types when eager loading a belongs to many relationship", function() {
				getInstance( "Post" ).with( "tags" ).get();

				expect( variables.queries ).toHaveLength( 2 );
				var bindingTypes = extractBindingTypes( variables.queries[ 2 ] );

				expect( bindingTypes ).notToBeEmpty();
				for ( var bindingType in bindingTypes ) {
					expect( bindingType ).notToInclude( "varchar" );
					expect( bindingType ).toInclude( "integer" );
				}
			} );

			it( "keeps relationship eager keys that differ only by case", function() {
				var user         = getInstance( "User" ).findOrFail( 1 );
				var relationship = user.externalThings();
				var keys         = relationship.getKeys(
					[
						{ "externalID" : "ABC" },
						{ "externalID" : "abc" }
					],
					[ "externalID" ],
					user
				);

				expect( keys ).toHaveLength( 2 );
			} );

			it( "can eager load a has many through relationship", function() {
				var countries = getInstance( "Country" ).with( "posts" ).get();
				expect( countries ).toBeArray();
				expect( countries ).toHaveLength( 2 );

				expect( countries[ 1 ].getPosts() ).toBeArray();
				expect( countries[ 1 ].getPosts() ).toHaveLength( 2 );
				expect( countries[ 1 ].getPosts()[ 1 ].getBody() ).toBe( "My second awesome post body" );
				expect( countries[ 1 ].getPosts()[ 2 ].getBody() ).toBe( "My awesome post body" );

				expect( countries[ 2 ].getPosts() ).toBeArray();
				expect( countries[ 2 ].getPosts() ).toHaveLength( 1 );
				expect( countries[ 2 ].getPosts()[ 1 ].getBody() ).toBe( "My post with a different author" );

				expect( variables.queries ).toHaveLength( 2, "Only two queries should have been executed." );
			} );

			it( "preserves constraints from intermediate has many relationships", function() {
				var country = getInstance( "Country" )
					.with( "publishedPostTags" )
					.findOrFail( "02B84D66-0AA0-F7FB-1F71AFC954843861" );

				expect( country.getPublishedPostTags() ).toHaveLength( 2 );
				expect( country.getPublishedPostTags()[ 1 ].getName() ).toBe( "programming" );
				expect( country.getPublishedPostTags()[ 2 ].getName() ).toBe( "music" );
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
		} );
	}

	private void function registerPolymorphicNestedTests() {
		describe( "Eager Loading Spec polymorphic and nested", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
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
		} );
	}

	private void function registerRetrievalDefaultTests() {
		describe( "Eager Loading Spec retrieval and defaults", function() {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
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

			it( "can provide default models if they are defined for the relationship", () => {
				var categories = getInstance( "Category" )
					.with( "parent" )
					.orderByAsc( "id" )
					.get();

				expect( categories ).toBeArray();
				expect( categories ).toHaveLength( 2 );
				expect( categories[ 1 ].getId() ).toBe( 1 );
				expect( categories[ 1 ].getParent() ).notToBeNull();
				expect( categories[ 1 ].getParent().isLoaded() ).toBeFalse( "Category 1 should have a default parent Category NOT loaded from the database" );
				expect( categories[ 2 ].getId() ).toBe( 2 );
				expect( categories[ 2 ].getParent() ).notToBeNull();
				expect( categories[ 2 ].getParent().isLoaded() ).toBeTrue( "Category 2 should have a parent Category loaded from the database" );
				expect( categories[ 2 ].getParent().getId() ).toBe( 1 );
			} );

			it( "caches a default model for an unmatched eager loaded relationship", () => {
				var category = getInstance( "Category" ).with( "parent" ).findOrFail( 1 );

				expect( category.isRelationshipLoaded( "parent" ) ).toBeTrue();
				expect( function() {
					return category.getParent().isLoaded();
				} ).notToThrow();
				expect( category.getParent() ).toBeInstanceOf( "Category" );
				expect( category.getParent().isLoaded() ).toBeFalse();
			} );
		} );
	}

	private void function registerLazyLoadingTests() {
		describe( "handling lazy loading", () => {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );

			it( "can completely disable lazy loading", () => {
				var posts = getInstance( "Post" ).preventLazyLoading().get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				var postA = posts[ 1 ];
				expect( () => {
					postA.getComments();
				} ).toThrow(
					type  = "QuickLazyLoadingException",
					regex = "Attempted to lazy load the \[comments\] relationship on the entity \[Post\] but lazy loading is disabled\. This is usually caused by the N\+1 problem and is a sign that you are missing an eager load\."
				);
			} );

			it( "can enable lazy loading on an entity by entity basis", () => {
				var posts = getInstance( "Post" ).allowLazyLoading().get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				var postA = posts[ 1 ];
				expect( () => {
					postA.getComments();
				} ).notToThrow(
					type  = "QuickLazyLoadingException",
					regex = "Attempted to lazy load the \[comments\] relationship on the entity \[Post\] but lazy loading is disabled\. This is usually caused by the N\+1 problem and is a sign that you are missing an eager load\."
				);
			} );

			it( "can use a callback to control how lazy loading is handled", () => {
				var posts = getInstance( "Post" )
					.preventLazyLoading( ( entity, relationName ) => {
						throw(
							type    = "CustomLazyLoadingException",
							message = "Custom lazy loading message about #relationName#"
						);
					} )
					.get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				var postA = posts[ 1 ];
				expect( () => {
					postA.getComments();
				} ).toThrow( type = "CustomLazyLoadingException", regex = "Custom lazy loading message about comments" );
			} );
		} );
	}

	private void function registerAutomaticEagerLoadingTests() {
		describe( "automatic eager loading", () => {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );

			it( "will automatically eager load specified relationships", () => {
				var posts = getInstance( "EagerLoadedPost" ).preventLazyLoading().get();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 4, "4 posts should have been loaded" );
				for ( var post in posts ) {
					expect( () => {
						post.getComments();
					} ).notToThrow( type = "QuickLazyLoadingException" );
				}
				if ( arrayLen( variables.queries ) != 2 ) {
					expect( variables.queries ).toHaveLength(
						2,
						"Only two queries should have been executed. #arrayLen( variables.queries )# were instead."
					);
				}
			} );

			it( "can disable an automatically eager loaded relationship", () => {
				var posts = getInstance( "EagerLoadedPost" )
					.without( "comments" )
					.preventLazyLoading()
					.get();

				expect( posts ).toHaveLength( 4 );
				expect( posts[ 1 ].isRelationshipLoaded( "comments" ) ).toBeFalse();
				expect( () => posts[ 1 ].getComments() ).toThrow( type = "QuickLazyLoadingException" );
				expect( variables.queries ).toHaveLength( 1, "Only the posts query should execute." );
			} );

			it( "does not clear eager loads when without is called without arguments", () => {
				var posts = getInstance( "EagerLoadedPost" )
					.without()
					.preventLazyLoading()
					.get();

				expect( posts ).toHaveLength( 4 );
				expect( posts[ 1 ].isRelationshipLoaded( "comments" ) ).toBeTrue();
				expect( variables.queries ).toHaveLength( 2 );
			} );

			it( "can explicitly clear all eager loads", () => {
				var posts = getInstance( "EagerLoadedPost" )
					.clearEagerLoads()
					.preventLazyLoading()
					.get();

				expect( posts ).toHaveLength( 4 );
				expect( posts[ 1 ].isRelationshipLoaded( "comments" ) ).toBeFalse();
				expect( () => posts[ 1 ].getComments() ).toThrow( type = "QuickLazyLoadingException" );
				expect( variables.queries ).toHaveLength( 1, "Only the posts query should execute." );
			} );
		} );
	}

	private void function registerMultipleNestedEagerLoadingTests() {
		describe( "multiple nested eager loads", () => {
			beforeEach( function( currentSpec ) {
				setupEagerLoadingTestState( arguments.currentSpec );
			} );

			it( "can eager load multiple nested relationships with the same parent using strings", function() {
				var users = getInstance( "User" )
					.with( [ "posts.tags", "posts.comments" ] )
					.latest()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				// Find elpete who has posts with tags and comments
				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );

				// Verify posts relationship is loaded
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue( "posts should be loaded" );
				expect( elpete.getPosts() ).toBeArray();
				expect( elpete.getPosts() ).toHaveLength( 2, "Two posts should belong to elpete" );

				// Verify both nested relationships are loaded on the posts
				var postWithTagsAndComments = elpete.getPosts()[ 2 ]; // post_pk 1245
				expect( postWithTagsAndComments.getPost_Pk() ).toBe( 1245 );
				expect( postWithTagsAndComments.isRelationshipLoaded( "tags" ) ).toBeTrue( "tags should be loaded on post" );
				expect( postWithTagsAndComments.isRelationshipLoaded( "comments" ) ).toBeTrue( "comments should be loaded on post" );

				// Verify the actual data - post 1245 has 2 tags
				expect( postWithTagsAndComments.getTags() ).toBeArray();
				expect( postWithTagsAndComments.getTags() ).toHaveLength( 2 );
				expect( postWithTagsAndComments.getComments() ).toBeArray();

				// Should be 4 queries: users, posts, tags, comments
				expect( variables.queries ).toHaveLength(
					4,
					"Four queries should have been executed (users, posts, tags, comments). #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can eager load multiple nested relationships with the same parent using structs with callbacks", function() {
				var users = getInstance( "User" )
					.with( [
						{
							"posts.tags" : function( q ) {
								return q.where( "name", "programming" );
							}
						},
						{
							"posts.comments" : function( q ) {
								return q.where( "designation", "public" );
							}
						}
					] )
					.latest()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				// Find elpete who has posts with tags and comments
				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );

				// Verify posts relationship is loaded
				expect( elpete.isRelationshipLoaded( "posts" ) ).toBeTrue( "posts should be loaded" );

				// Verify both nested relationships are loaded on the posts
				var postWithTagsAndComments = elpete.getPosts()[ 2 ]; // post_pk 1245
				expect( postWithTagsAndComments.getPost_Pk() ).toBe( 1245 );
				expect( postWithTagsAndComments.isRelationshipLoaded( "tags" ) ).toBeTrue( "tags should be loaded on post" );
				expect( postWithTagsAndComments.isRelationshipLoaded( "comments" ) ).toBeTrue( "comments should be loaded on post" );

				// Verify the callbacks were applied - only "programming" tags
				var tags = postWithTagsAndComments.getTags();
				expect( tags ).toBeArray();
				for ( var tag in tags ) {
					expect( tag.getName() ).toBe( "programming" );
				}

				// Verify the callbacks were applied - only "public" comments
				var comments = postWithTagsAndComments.getComments();
				expect( comments ).toBeArray();
				for ( var comment in comments ) {
					expect( comment.getDesignation() ).toBe( "public" );
				}

				// Should be 4 queries: users, posts, tags, comments
				expect( variables.queries ).toHaveLength(
					4,
					"Four queries should have been executed (users, posts, tags, comments). #arrayLen( variables.queries )# were instead."
				);
			} );

			it( "can mix string and struct eager loads with the same parent", function() {
				var users = getInstance( "User" )
					.with( [
						"posts.tags",
						{
							"posts.comments" : function( q ) {
								return q.where( "designation", "public" );
							}
						}
					] )
					.latest()
					.get();

				expect( users ).toBeArray();
				expect( users ).toHaveLength( 5, "Five users should be returned" );

				var elpete = users[ 5 ];
				expect( elpete.getUsername() ).toBe( "elpete" );

				var postWithTagsAndComments = elpete.getPosts()[ 2 ];
				expect( postWithTagsAndComments.isRelationshipLoaded( "tags" ) ).toBeTrue( "tags should be loaded on post" );
				expect( postWithTagsAndComments.isRelationshipLoaded( "comments" ) ).toBeTrue( "comments should be loaded on post" );

				// Tags should have all tags (no filter)
				expect( postWithTagsAndComments.getTags() ).toBeArray();

				// Comments should only have public ones (callback applied)
				var comments = postWithTagsAndComments.getComments();
				for ( var comment in comments ) {
					expect( comment.getDesignation() ).toBe( "public" );
				}
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
		lock name="EagerLoadingSpecQueries" type="exclusive" timeout="5" {
			arrayAppend( variables.queries, interceptData );
		}

		var coordinator = getInstance( "quick.models.ParallelEagerLoadingCoordinator" );
		if ( coordinator.isWorker() ) {
			var threadName = coordinator.getWorkerName();
			variables.workerQueryThreads.put( threadName, true );
			variables.workerRequestContexts.put(
				createObject( "java", "java.lang.System" ).identityHashCode( arguments.event ),
				true
			);
			var activeWorkers = variables.activeWorkers.incrementAndGet();
			while (
				activeWorkers > variables.maxActiveWorkers.get()
				&& !variables.maxActiveWorkers.compareAndSet( variables.maxActiveWorkers.get(), activeWorkers )
			) {
			}
			if ( variables.parallelWorkerDelay > 0 ) {
				sleep( variables.parallelWorkerDelay );
			}
			if ( variables.failParallelWorker ) {
				variables.activeWorkers.decrementAndGet();
				throw( type = "ExpectedParallelFailure", message = "worker failed" );
			}
			variables.activeWorkers.decrementAndGet();
		}
	}

	function quickInstanceReady(
		event,
		interceptData,
		buffer,
		rc,
		prc
	) {
		if ( variables.trackInstanceReady ) {
			variables.instanceReadyCount.incrementAndGet();
		}
	}

	private void function setupEagerLoadingTestState( required string currentSpec ) {
		request.quickSkipDatabaseTransactions = specHasLabel( arguments.currentSpec, "no-transaction" );
		variables.queries                     = [];
		variables.workerQueryThreads          = createObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.workerRequestContexts       = createObject( "java", "java.util.concurrent.ConcurrentHashMap" ).init();
		variables.activeWorkers               = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init();
		variables.maxActiveWorkers            = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init();
		variables.parallelWorkerDelay         = 0;
		variables.failParallelWorker          = false;
		variables.trackInstanceReady          = false;
		variables.instanceReadyCount          = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init();
		structDelete( request, "parallelLifecyclePostLoads" );
		structDelete( request, "trackParallelScopeThreads" );
		structDelete( request, "parallelScopeThreads" );
	}

	private array function extractBindingTypes( required struct queryLogEntry ) {
		return arguments.queryLogEntry.bindings
			.filter( function( binding ) {
				return isStruct( binding ) && ( binding.keyExists( "cfsqltype" ) || binding.keyExists( "sqltype" ) );
			} )
			.map( function( binding ) {
				return lCase( binding.keyExists( "cfsqltype" ) ? binding[ "cfsqltype" ] : binding[ "sqltype" ] );
			} );
	}

	private boolean function supportsParallelEagerLoadingForTest() {
		return !server.keyExists( "coldfusion" ) || !findNoCase( "ColdFusion", server.coldfusion.productName );
	}

	private boolean function specHasLabel(
		required string specName,
		required string label,
		array suites = this.$suites
	) {
		for ( var suite in arguments.suites ) {
			for ( var spec in suite.specs ) {
				if ( spec.name == arguments.specName ) {
					return spec.labels.findNoCase( arguments.label ) > 0;
				}
			}
			if (
				specHasLabel(
					arguments.specName,
					arguments.label,
					suite.suites
				)
			) {
				return true;
			}
		}
		return false;
	}

}
