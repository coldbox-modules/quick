component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Belongs To Many Spec", function() {
			beforeEach( function() {
				variables.queries = [];
			} );

			it( "can get the related entities", function() {
				var post = getInstance( "Post" ).find( 1245 );
				var tags = post.getTags();
				expect( tags ).toBeArray();
				expect( tags ).toHaveLength( 2 );
			} );

			it( "can get the related entities from the inverse relationship", function() {
				var tag   = getInstance( "Tag" ).find( 1 );
				var posts = tag.getPosts();
				expect( posts ).toBeArray();
				expect( posts ).toHaveLength( 2 );
			} );

			it( "hydrates declared pivot columns on a pivot model", function() {
				var post  = getInstance( "Post" ).findOrFail( 1245 );
				var tag   = post.getTagsWithPivot()[ 1 ];
				var pivot = tag.getPivot();

				expect( pivot ).toBeInstanceOf( "quick.models.Relationships.Pivot" );
				expect( pivot.isLoaded() ).toBeTrue();
				expect( pivot.getCustom_post_pk() ).toBe( post.getPost_pk() );
				expect( pivot.getTag_id() ).toBe( tag.getId() );
				expect( pivot.getContext() ).toBe( "primary" );
				expect( pivot.getActive() ).toBeTrue();
				expect( pivot.getPivotParent().getPost_pk() ).toBe( post.getPost_pk() );
				expect( pivot.getPivotRelated().getId() ).toBe( tag.getId() );
				var memento = pivot.getMemento();
				expect( memento.custom_post_pk ).toBe( 1245 );
				expect( memento.tag_id ).toBe( 1 );
				expect( memento.context ).toBe( "primary" );
				expect( function() {
					pivot.setContext( "not persisted" ).save();
				} ).toThrow( "QuickReadOnlyException" );
			} );

			it( "hydrates the correct pivot for every eagerly loaded parent", function() {
				var posts = getInstance( "Post" )
					.with( "tagsWithPivot" )
					.whereIn( "post_pk", [ 1245, 523526 ] )
					.orderBy( "post_pk" )
					.get();

				var firstPostTag  = posts[ 1 ].getTagsWithPivot()[ 1 ];
				var secondPostTag = posts[ 2 ].getTagsWithPivot()[ 1 ];

				expect( firstPostTag.getPivot().getCustom_post_pk() ).toBe( posts[ 1 ].getPost_pk() );
				expect( secondPostTag.getPivot().getCustom_post_pk() ).toBe( posts[ 2 ].getPost_pk() );
				expect( firstPostTag.getPivot().getContext() ).notToBe( secondPostTag.getPivot().getContext() );
			} );

			it( "can customize the pivot accessor", function() {
				var tag = getInstance( "Post" ).findOrFail( 1245 ).getTagsAsSubscriptions()[ 1 ];

				expect( tag.isRelationshipLoaded( "subscription" ) ).toBeTrue();
				expect( tag.getSubscription().getContext() ).toBe( "primary" );
			} );

			it( "can hydrate a custom pivot model with casts and behavior", function() {
				var pivot = getInstance( "Post" ).findOrFail( 1245 ).getTagsWithCustomPivot()[ 1 ].getPivot();

				expect( pivot ).toBeInstanceOf( "app.models.PostTag" );
				expect( pivot.getActive() ).toBeBoolean().toBeTrue();
				expect( pivot.describe() ).toBe( "primary:1" );

				pivot.setContext( "saved through custom pivot" ).save();
				var refreshed = getInstance( "Post" ).findOrFail( 1245 ).getTagsWithCustomPivot()[ 1 ].getPivot();
				expect( refreshed.getContext() ).toBe( "saved through custom pivot" );
			} );

			it( "can constrain and order by pivot columns", function() {
				var tags = getInstance( "Post" ).findOrFail( 523526 ).getActiveTags();

				expect( tags ).toHaveLength( 2 );
				expect( tags[ 1 ].getPivot().getContext() ).toBe( "published" );
				expect( tags[ 2 ].getPivot().getContext() ).toBe( "review" );
			} );

			it( "supports the pivot query helper family", function() {
				var post = getInstance( "Post" ).findOrFail( 1245 );

				expect(
					post.tagsWithPivot()
						.wherePivotIn( "tag_id", [ 1 ] )
						.get()
				).toHaveLength( 1 );
				expect(
					post.tagsWithPivot()
						.wherePivotNotIn( "tag_id", [ 1 ] )
						.get()
				).toHaveLength( 1 );
				expect(
					post.tagsWithPivot()
						.wherePivotBetween( "tag_id", 1, 2 )
						.get()
				).toHaveLength( 2 );
				expect(
					post.tagsWithPivot()
						.wherePivotNotBetween( "tag_id", 2, 2 )
						.get()
				).toHaveLength( 1 );
				expect(
					post.tagsWithPivot()
						.wherePivotNull( "created_date" )
						.get()
				).toHaveLength( 2 );
				expect(
					post.tagsWithPivot()
						.wherePivotNotNull( "context" )
						.get()
				).toHaveLength( 2 );
			} );

			it( "writes and updates additional pivot attributes", function() {
				var post = getInstance( "Post" ).findOrFail( 1245 );

				post.tagsWithPivot().attach( 3, { "context" : "new", "active" : true } );
				var attached = post.tagsWithPivot().findOrFail( 3 );
				expect( attached.getPivot().getContext() ).toBe( "new" );
				expect( attached.getPivot().getActive() ).toBeTrue();

				post.tagsWithPivot()
					.updateExistingPivot(
						3,
						{
							"context" : "updated",
							"active"  : false
						}
					);
				var updated = post.tagsWithPivot().findOrFail( 3 );
				expect( updated.getPivot().getContext() ).toBe( "updated" );
				expect( updated.getPivot().getActive() ).toBeFalse();
			} );

			it( "applies configured pivot values to constraints and writes", function() {
				var post = getInstance( "Post" ).findOrFail( 321 );

				post.defaultActiveTags().attach( 3, { "context" : "defaulted" } );
				var tag = post.defaultActiveTags().findOrFail( 3 );

				expect( tag.getPivot().getActive() ).toBeTrue();
				expect( tag.getPivot().getContext() ).toBe( "defaulted" );
			} );

			it( "maintains configured pivot timestamps", function() {
				var post = getInstance( "Post" ).findOrFail( 321 );

				post.timestampedTags().attach( 1 );
				var pivot = post
					.timestampedTags()
					.findOrFail( 1 )
					.getPivot();

				expect( pivot.getCreated_date() ).notToBeNull();
				expect( pivot.getModified_date() ).notToBeNull();
			} );

			it( "creates and attaches a related entity", function() {
				var post = getInstance( "Post" ).findOrFail( 1245 );
				var tag  = post
					.tagsWithPivot()
					.create(
						{ "name" : "testing" },
						{
							"context" : "created through relationship",
							"active"  : true
						}
					);

				expect( tag ).toBeInstanceOf( "Tag" );
				expect( tag.isLoaded() ).toBeTrue();

				var attached = post.tagsWithPivot().findOrFail( tag.getId() );
				expect( attached.getPivot().getContext() ).toBe( "created through relationship" );
				expect( attached.getPivot().getActive() ).toBeTrue();
			} );
		} );
	}

}
