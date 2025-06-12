component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Relationships Aggregates spec", function() {
			describe( "count", function() {
				it( "can add a subselect for the count of a relationship without loading the relationship", function() {
					// delete our internal comments to allow the test to pass:
					getInstance( "InternalComment" )
						.get()
						.each( function( comment ) {
							comment.delete();
						} );

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
					expect( posts[ 2 ].getTagsCount() ).toBe( 3 );

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
					expect( posts[ 4 ].getTagsCount() ).toBe( 1 );
				} );

				it( "can constrain counts at runtime", function() {
					// delete our internal comments to allow the test to pass:
					getInstance( "InternalComment" )
						.get()
						.each( function( comment ) {
							comment.delete();
						} );

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

				// https://github.com/coldbox-modules/quick/issues/115
				it( "can add a count for a belongsToMany relationship", function() {
					var posts = getInstance( "Post" )
						.withCount( "tags" )
						.orderBy( "createdDate" )
						.get();

					expect( posts ).toBeArray();
					expect( posts ).toHaveLength( 4 );

					expect( posts[ 1 ].getPost_Pk() ).toBe( 1245 );
					expect( posts[ 1 ].hasAttribute( "tagsCount" ) ).toBeTrue(
						"Post #posts[ 1 ].getPost_Pk()# should have an attribute named `tagsCount`."
					);
					expect( posts[ 1 ].getTagsCount() ).toBe( 2 );

					expect( posts[ 2 ].getPost_Pk() ).toBe( 523526 );
					expect( posts[ 2 ].hasAttribute( "tagsCount" ) ).toBeTrue(
						"Post #posts[ 2 ].getPost_Pk()# should have an attribute named `tagsCount`."
					);
					expect( posts[ 2 ].getTagsCount() ).toBe( 3 );

					expect( posts[ 3 ].getPost_Pk() ).toBe( 7777 );
					expect( posts[ 3 ].hasAttribute( "tagsCount" ) ).toBeTrue(
						"Post #posts[ 3 ].getPost_Pk()# should have an attribute named `tagsCount`."
					);
					expect( posts[ 3 ].getTagsCount() ).toBe( 0 );

					expect( posts[ 4 ].getPost_Pk() ).toBe( 321 );
					expect( posts[ 4 ].hasAttribute( "tagsCount" ) ).toBeTrue(
						"Post #posts[ 4 ].getPost_Pk()# should have an attribute named `tagsCount`."
					);
					expect( posts[ 4 ].getTagsCount() ).toBe( 1 );
				} );

				it( "can add a count for a hasManyDeep relationship", function() {
					var countries = getInstance( "Country" )
						.withCount( "postsDeep" )
						.orderBy( "createdDate" )
						.get();

					expect( countries ).toBeArray();
					expect( countries ).toHaveLength( 2 );

					expect( countries[ 1 ].getId() ).toBe( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
					expect( countries[ 1 ].getName() ).toBe( "United States" );
					expect( countries[ 1 ].getPostsDeepCount() ).toBe( 2 );

					expect( countries[ 2 ].getId() ).toBe( "02BA2DB0-EB1E-3F85-5F283AB5E45608C6" );
					expect( countries[ 2 ].getName() ).toBe( "Argentina" );
					expect( countries[ 2 ].getPostsDeepCount() ).toBe( 1 );

					var countryMementoKeys = countries[ 2 ].getMemento().keyArray();
					arraySort( countryMementoKeys, "text" );
					expect( countryMementoKeys[ 1 ] ).toBeWithCase( "createdDate" );
					expect( countryMementoKeys[ 2 ] ).toBeWithCase( "id" );
					expect( countryMementoKeys[ 3 ] ).toBeWithCase( "modifiedDate" );
					expect( countryMementoKeys[ 4 ] ).toBeWithCase( "name" );
					expect( countryMementoKeys[ 5 ] ).toBeWithCase( "postsDeepCount" );
				} );

				it( "can return the QuickBuilder instance generated for the count", function() {
					getInstance( "InternalComment" )
						.get()
						.each( function( comment ) {
							comment.delete();
						} );

					var commentsCountBuilder = getInstance( "Post" ).withCount(
						relation  = "comments",
						asBuilder = true
					);
					expect( commentsCountBuilder ).toBeArray();
					expect( commentsCountBuilder ).toHaveLength( 1 );
					expect( commentsCountBuilder[ 1 ] ).toBeInstanceOf( "QuickBuilder" );
				} );
			} );

			describe( "sum", function() {
				it( "can add a subselect for the sum of a relationship without loading the relationship", function() {
					var users = getInstance( "User" )
						.withSum( "purchases.price" )
						.orderBy( "id" )
						.get();

					expect( users ).toBeArray();
					expect( users ).toHaveLength( 5 );

					expect( users[ 1 ].getId() ).toBe( 1 );
					expect( users[ 1 ].getTotalPurchases() ).toBe( 180 );

					expect( users[ 2 ].getId() ).toBe( 2 );
					expect( users[ 2 ].getTotalPurchases() ).toBe( 0 );

					expect( users[ 3 ].getId() ).toBe( 3 );
					expect( users[ 3 ].getTotalPurchases() ).toBe( 0 );

					expect( users[ 4 ].getId() ).toBe( 4 );
					expect( users[ 4 ].getTotalPurchases() ).toBe( 60 );

					expect( users[ 5 ].getId() ).toBe( 5 );
					expect( users[ 5 ].getTotalPurchases() ).toBe( 50 );
				} );

				it( "can order by a loaded sum", function() {
					var users = getInstance( "User" )
						.withSum( "purchases.price" )
						.orderBy( [ "totalPurchases DESC", "createdDate" ] )
						.get();

					expect( users ).toBeArray();
					expect( users ).toHaveLength( 5 );
					expect( users[ 1 ].getId() ).toBe( 1 );
					expect( users[ 2 ].getId() ).toBe( 4 );
					expect( users[ 3 ].getId() ).toBe( 5 );
					expect( users[ 4 ].getId() ).toBe( 2 );
					expect( users[ 5 ].getId() ).toBe( 3 );
				} );

				it( "can add multiple sums at once", function() {
					var users = getInstance( "User" )
						.withSum( [
							"purchases.price AS totalPrice",
							"purchases.quantity AS totalQuantity"
						] )
						.orderBy( "id" )
						.get();

					expect( users ).toBeArray();
					expect( users ).toHaveLength( 5 );

					expect( users[ 1 ].getId() ).toBe( 1 );
					expect( users[ 1 ].getTotalPrice() ).toBe( 180 );
					expect( users[ 1 ].getTotalQuantity() ).toBe( 6 );

					expect( users[ 2 ].getId() ).toBe( 2 );
					expect( users[ 2 ].getTotalPrice() ).toBe( 0 );
					expect( users[ 2 ].getTotalQuantity() ).toBe( 0 );

					expect( users[ 3 ].getId() ).toBe( 3 );
					expect( users[ 3 ].getTotalPrice() ).toBe( 0 );
					expect( users[ 3 ].getTotalQuantity() ).toBe( 0 );

					expect( users[ 4 ].getId() ).toBe( 4 );
					expect( users[ 4 ].getTotalPrice() ).toBe( 60 );
					expect( users[ 4 ].getTotalQuantity() ).toBe( 2 );

					expect( users[ 5 ].getId() ).toBe( 5 );
					expect( users[ 5 ].getTotalPrice() ).toBe( 50 );
					expect( users[ 5 ].getTotalQuantity() ).toBe( 3 );
				} );

				it( "can constrain sums at runtime", function() {
					var users = getInstance( "User" )
						.withSum( {
							"purchases.price" : function( q ) {
								q.where( "quantity", ">", 1 );
							}
						} )
						.orderBy( "id" )
						.get();

					expect( users ).toBeArray();
					expect( users ).toHaveLength( 5 );

					expect( users[ 1 ].getId() ).toBe( 1 );
					expect( users[ 1 ].getTotalPurchases() ).toBe( 150 );

					expect( users[ 2 ].getId() ).toBe( 2 );
					expect( users[ 2 ].getTotalPurchases() ).toBe( 0 );

					expect( users[ 3 ].getId() ).toBe( 3 );
					expect( users[ 3 ].getTotalPurchases() ).toBe( 0 );

					expect( users[ 4 ].getId() ).toBe( 4 );
					expect( users[ 4 ].getTotalPurchases() ).toBe( 0 );

					expect( users[ 5 ].getId() ).toBe( 5 );
					expect( users[ 5 ].getTotalPurchases() ).toBe( 50 );
				} );

				it( "can alias the sums attribute name", function() {
					var users = getInstance( "User" )
						.withSum( "purchases.price AS totalPrice" )
						.orderBy( "id" )
						.get();

					expect( users ).toBeArray();
					expect( users ).toHaveLength( 5 );

					expect( users[ 1 ].getId() ).toBe( 1 );
					expect( users[ 1 ].getTotalPrice() ).toBe( 180 );

					expect( users[ 2 ].getId() ).toBe( 2 );
					expect( users[ 2 ].getTotalPrice() ).toBe( 0 );

					expect( users[ 3 ].getId() ).toBe( 3 );
					expect( users[ 3 ].getTotalPrice() ).toBe( 0 );

					expect( users[ 4 ].getId() ).toBe( 4 );
					expect( users[ 4 ].getTotalPrice() ).toBe( 60 );

					expect( users[ 5 ].getId() ).toBe( 5 );
					expect( users[ 5 ].getTotalPrice() ).toBe( 50 );
				} );

				it( "can add a sum for a hasManyDeep relationship", function() {
					var countries = getInstance( "Country" )
						.withSum( "postsDeep.post_pk AS postIdTotal" )
						.orderBy( "createdDate" )
						.get();

					expect( countries ).toBeArray();
					expect( countries ).toHaveLength( 2 );

					expect( countries[ 1 ].getId() ).toBe( "02B84D66-0AA0-F7FB-1F71AFC954843861" );
					expect( countries[ 1 ].getName() ).toBe( "United States" );
					expect( countries[ 1 ].getPostIdTotal() ).toBe( 524771 );

					expect( countries[ 2 ].getId() ).toBe( "02BA2DB0-EB1E-3F85-5F283AB5E45608C6" );
					expect( countries[ 2 ].getName() ).toBe( "Argentina" );
					expect( countries[ 2 ].getPostIdTotal() ).toBe( 321 );
				} );

				it( "can return the QuickBuilder instance generated for the sum", function() {
					var totalPriceBuilder = getInstance( "User" ).withSum(
						relationMapping = "purchases.price",
						asBuilder       = true
					);
					expect( totalPriceBuilder ).toBeArray();
					expect( totalPriceBuilder ).toHaveLength( 1 );
					expect( totalPriceBuilder[ 1 ] ).toBeInstanceOf( "QuickBuilder" );
					expect( totalPriceBuilder[ 1 ].toSQL() ).toBe( "SELECT COALESCE(SUM(purchases.price), 0) FROM `purchases` WHERE (`users`.`id` = `purchases`.`userId`)" );
				} );
			} );
		} );
	}

}
