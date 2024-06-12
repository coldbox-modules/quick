component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "Child Class Spec", function() {
			it( "merges parent table and child table attributes into the entity", function() {
				var jingle = getInstance( "Jingle" ).first();

				expect( jingle.isLoaded() ).toBeTrue();

				var memento = jingle.getMemento();

				expect( memento )
					.toHaveKey( "id" )
					.toHaveKey( "title" )
					.toHaveKey( "catchiness" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "modifiedDate" );

				expect( jingle.getId() ).notToBeNull();
				expect( jingle.isLoaded() ).toBeTrue();
			} );

			it( "can create a child entity and populate the parent and child tables", function() {
				var newJingle = getInstance( "Jingle" )
					.fill( {
						"title"        : "Give me a Break",
						"downloadURL"  : "https://www.youtube.com/watch?v=0nkcVz1mad0",
						"createdDate"  : now(),
						"modifiedDate" : now(),
						"catchiness"   : 2
					} )
					.save();

				var memento = newJingle.getMemento();

				expect( memento )
					.toHaveKey( "id" )
					.toHaveKey( "title" )
					.toHaveKey( "catchiness" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "modifiedDate" );

				expect( newJingle.getId() ).notToBeNull();
				expect( newJingle.isLoaded() ).toBeTrue();

				var jingle = getInstance( "Jingle" ).findOrFail( newJingle.getId() );

				expect( jingle.getMemento() ).toBe( newJingle.getMemento() );
			} );

			it( "can update a child entity", function() {
				var newJingle = getInstance( "Jingle" )
					.fill( {
						"title"        : "Give me a Break",
						"downloadURL"  : "https://www.youtube.com/watch?v=0nkcVz1mad0",
						"createdDate"  : now(),
						"modifiedDate" : now(),
						"catchiness"   : 2
					} )
					.save();

				var jingle = getInstance( "Jingle" ).findOrFail( newJingle.getId() );

				jingle.setTitle( "Give me a Break ( The Kit Kat Bar Song )" );
				jingle.setCatchiness( 1 );

				jingle.save();

				jingle = getInstance( "Jingle" ).findOrFail( jingle.getId() );

				var memento = jingle.getMemento();

				expect( memento )
					.toHaveKey( "id" )
					.toHaveKey( "title" )
					.toHaveKey( "catchiness" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "modifiedDate" );

				expect( jingle.getTitle() ).toBe( "Give me a Break ( The Kit Kat Bar Song )" );
				expect( jingle.getCatchiness() ).toBe( 1 );
			} );

			it( "can delete a child entity", function() {
				var newJingle = getInstance( "Jingle" )
					.fill( {
						"title"        : "Give me a Break",
						"downloadURL"  : "https://www.youtube.com/watch?v=0nkcVz1mad0",
						"createdDate"  : now(),
						"modifiedDate" : now(),
						"catchiness"   : 2
					} )
					.save();

				getInstance( "Jingle" ).findOrFail( newJingle.getId() ).delete();

				expect( isNull( getInstance( "Song" ).set_LoadChildren( false ).find( newJingle.getId() ) ) ).toBeTrue(
					"The parent table row was not deleted"
				);
				expect( isNull( getInstance( "Jingle" ).find( newJingle.getId() ) ) ).toBeTrue(
					"The child table row was not deleted"
				);
			} );
		} );

		describe( "Discriminated Class Spec", function() {
			it( "Will fetch a discriminated entity and merge relationships", function() {
				var comment = getInstance( "InternalComment" ).first();

				expect( comment.isLoaded() ).toBeTrue();

				var memento = comment.getMemento();

				expect( memento ).toHaveKey( "id" ).toHaveKey( "body" );

				expect( comment.getId() ).notToBeNull();
				expect( comment.getDesignation() ).toBe( memento.designation );
				expect( comment.isLoaded() ).toBeTrue();


				expect( comment.getAuthor() ).toBeInstanceOf( "User" );
				expect( comment.getAuthor().isLoaded() ).toBeTrue();

				expect( comment.getCommentable() ).toBeInstanceOf( "Post" );
			} );

			it( "Can load the relationships of the parent through the discriminated child", function() {
				var comment = getInstance( "InternalComment" ).first();

				expect( comment ).toBeInstanceOf( "InternalComment" );

				expect( comment.getAuthor() ).toBeInstanceOf( "User" );
				expect( comment.getAuthor().isLoaded() ).toBeTrue();

				expect( comment.getCommentable() ).toBeInstanceOf( "Post" );
			} );

			it( "Can query on parent values through the child", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var internals = getInstance( "InternalComment" ).where( "body", "Lorem ipsum" ).get();

				expect( internals ).toBeArray().toHaveLength( 1 );
			} );

			it( "Can query on child entity values", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var internals = getInstance( "InternalComment" )
					.where( "reason", "I like to keep things private" )
					.get();

				expect( internals ).toBeArray().toHaveLength( 1 );
			} );

			it( "can create a discriminated entity and populate the parent and child tables", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var memento = newComment.getMemento();

				expect( memento )
					.toHaveKey( "id" )
					.toHaveKey( "body" )
					.toHaveKey( "reason" )
					.toHaveKey( "commentableId" )
					.toHaveKey( "commentableType" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "modifiedDate" );

				expect( newComment.getId() ).notToBeNull();
				expect( newComment.isLoaded() ).toBeTrue();
			} );

			it( "Can associate/dissociate parent relationships from the child", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var newComment = getInstance( "InternalComment" ).find( newComment.getId() );

				expect( newComment.getCommentable() ).notToBeNull();

				var otherPost = getInstance( "Post" ).find( 523526 );
				var otherUser = otherPost.getAuthor();

				newComment.author().associate( otherUser );
				newComment.commentable().associate( otherPost );

				newComment.save();

				var comment = getInstance( "InternalComment" ).find( newComment.getId() );

				expect( comment.getAuthor() ).toBeInstanceOf( "User" );
				expect( comment.getAuthor().getId() ).toBe( otherUser.getId() );

				expect( comment.getCommentable() ).toBeInstanceOf( "Post" );
				expect( comment.getCommentable().getPost_pk() ).toBe( 523526 );
			} );

			it( "can update a child entity", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var comment = getInstance( "InternalComment" ).findOrFail( newComment.getId() );

				comment.setBody( "Lorem ipsum dolor" );
				comment.setReason( "This is nonsense and I don't want anyone to see it." );

				comment.save();

				comment = getInstance( "InternalComment" ).findOrFail( comment.getId() );

				var memento = comment.getMemento();

				expect( memento )
					.toHaveKey( "id" )
					.toHaveKey( "body" )
					.toHaveKey( "reason" )
					.toHaveKey( "commentableId" )
					.toHaveKey( "commentableType" )
					.toHaveKey( "createdDate" )
					.toHaveKey( "modifiedDate" );

				expect( comment.getId() ).notToBeNull();
				expect( comment.isLoaded() ).toBeTrue();

				expect( comment.getBody() ).toBe( "Lorem ipsum dolor" );
				expect( comment.getReason() ).toBe( "This is nonsense and I don't want anyone to see it." );
			} );

			it( "can delete a discriminated entity", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				getInstance( "InternalComment" ).findOrFail( newComment.getId() ).delete();

				expect( isNull( getInstance( "Comment" ).set_LoadChildren( false ).find( newComment.getId() ) ) ).toBeTrue(
					"The parent table row was not deleted"
				);
				expect( isNull( getInstance( "InternalComment" ).find( newComment.getId() ) ) ).toBeTrue(
					"The child table row was not deleted"
				);
			} );

			it( "Will return a child entity when retrieving a single entity from the parent", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1245,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var parentClass = getInstance( "Comment" );
				expect( parentClass.isDiscriminatedParent() ).toBeTrue();

				var parentRetrieval = parentClass.find( newComment.getId() );
				expect( parentRetrieval ).toBeInstanceOf( "InternalComment" );
			} );

			it( "Will return an array of child classes when fetching multiple results from the parent class", function() {
				var parentClass = getInstance( "Comment" );
				expect( parentClass.isDiscriminatedParent() ).toBeTrue();
				var internalComments = parentClass.where( "designation", "internal" ).get();
				internalComments.each( function( comment ) {
					expect( comment ).toBeInstanceOf( "InternalComment" );
					expect( comment.hasAttribute( "reason" ) ).toBeTrue(
						"InternalComments should have a reason field."
					);
					expect( comment.isNullAttribute( "reason" ) ).toBeFalse( "The reason field should not be null." );
				} );
			} );

			it( "returns an array of discriminated entities when loading through a relationship", () => {
				var post     = getInstance( "Post" ).findOrFail( 1245 );
				var comments = post.getComments();

				expect( comments ).toBeArray();
				expect( comments ).toHaveLength( 2 );
				expect( comments[ 1 ] ).toBeInstanceOf( "Comment" );
				expect( comments[ 2 ] ).toBeInstanceOf( "InternalComment" );
			} );

			describe( "products and skus", () => {
				it( "can load products and discriminated skus", () => {
					var product = getInstance( "Product" ).findOrFail( "BDC3F099-0FBF-4334-AFEAEFFD06C8AAD8" );
					expect( product.skus().toSQL() ).toBe( "SELECT `product_skus`.`createdDate`, `product_skus`.`deletedDate`, `product_skus`.`designation`, `product_skus`.`id`, `product_skus`.`modifiedDate`, `product_skus`.`productId`, `apparel_skus`.`color`, `apparel_skus`.`cost`, `apparel_skus`.`size1`, `apparel_skus`.`size1Description`, `apparel_skus`.`size1Index` FROM `product_skus` LEFT OUTER JOIN `apparel_skus` ON `product_skus`.`id` = `apparel_skus`.`id` WHERE (`product_skus`.`productId` = ? AND `product_skus`.`productId` IS NOT NULL)" );
				} );
			} );

			it( "Will maintain virtual attributes in the child class when fetching results from the parent class", function() {
				var comment = getInstance( "Comment" )
					.addUpperBody()
					.where( "designation", "internal" )
					.get()[ 1 ]

				expect( comment.hasAttribute( "upperBody" ) ).toBeTrue(
					"Child class should have a virtual attribute 'upperBody'."
				);
			} );
		} );

		describe( "Single Table Inheritence Class Spec", function() {
			it( "does not fail when it does not find an entity", function() {
				expect( function() {
					var game = getInstance( "BaseProduct" ).where( "type", "game" ).first();
				} ).notToThrow();
			} );

			it( "Will fetch a discriminated entity and merge properties", function() {
				// Grab a productbook (child) entity from the BaseProduct by specifying the type (discriminator column)
				var book = getInstance( "BaseProduct" ).where( "type", "book" ).first();

				expect( book.isLoaded() ).toBeTrue();
				expect( book ).toBeInstanceOf( "ProductBook" );

				var memento = book.getMemento();

				expect( book.getID() ).toBe( 1 );
				expect( book.getName() ).toBe( "The Lord of the Rings" );
				expect( book.getType() ).toBe( "book" );
				expect( book.getISBN() ).toBe( "9780544003415" );
				expect( book.getUser_ID() ).toBe( 2 );
				expect( book.hasAttribute( "artist" ) ).toBeFalse();

				// do the same thing with a musicproduct entity now
				var music = getInstance( "BaseProduct" ).where( "type", "music" ).first();

				expect( music.isLoaded() ).toBeTrue();
				expect( music ).toBeInstanceOf( "ProductMusic" );

				expect( music.getID() ).toBe( 2 );
				expect( music.getName() ).toBe( "Jeremy" );
				expect( music.getType() ).toBe( "music" );
				expect( music.getArtist() ).toBe( "Pearl Jam" );
				expect( music.getUser_ID() ).toBe( 1 );
				expect( music.hasAttribute( "isbn" ) ).toBeFalse();
			} );

			it( "loads the correct entity based on the discriminator value", function() {
				// Grab a productbook (child) entity from the BaseProduct by specifying the type (discriminator column)
				var products = getInstance( "BaseProduct" ).orderByAsc( "ID" ).get();

				var book = products[ 1 ];

				expect( book.isLoaded() ).toBeTrue();
				expect( book ).toBeInstanceOf( "ProductBook" );

				expect( book.getID() ).toBe( 1 );
				expect( book.getName() ).toBe( "The Lord of the Rings" );
				expect( book.getType() ).toBe( "book" );
				expect( book.getISBN() ).toBe( "9780544003415" );
				expect( book.getUser_ID() ).toBe( 2 );
				expect( book.hasAttribute( "artist" ) ).toBeFalse();

				var music = products[ 2 ];

				expect( music.isLoaded() ).toBeTrue();
				expect( music ).toBeInstanceOf( "ProductMusic" );

				expect( music.getID() ).toBe( 2 );
				expect( music.getName() ).toBe( "Jeremy" );
				expect( music.getType() ).toBe( "music" );
				expect( music.getArtist() ).toBe( "Pearl Jam" );
				expect( music.getUser_ID() ).toBe( 1 );
				expect( music.hasAttribute( "isbn" ) ).toBeFalse();
			} );

			it( "applies the discriminator value as a filter when querying by the child entity", function() {
				var book = getInstance( "ProductBook" ).first();

				expect( book.isLoaded() ).toBeTrue();
				expect( book ).toBeInstanceOf( "ProductBook" );

				expect( book.getID() ).toBe( 1 );
				expect( book.getName() ).toBe( "The Lord of the Rings" );
				expect( book.getType() ).toBe( "book" );
				expect( book.getISBN() ).toBe( "9780544003415" );
				expect( book.getUser_ID() ).toBe( 2 );
				expect( book.hasAttribute( "artist" ) ).toBeFalse();
			} );

			it( "Can load the relationships of the parent through the discriminated child", function() {
				var book = getInstance( "BaseProduct" ).where( "type", "book" ).first();

				expect( book.getCreator() ).toBeInstanceOf( "User" );
				expect( book.getCreator().isLoaded() ).toBeTrue();
			} );

			it( "Can create a new instance of a child entity by specifying discriminator value", function() {
				var book = getInstance( "BaseProduct" ).newChildEntity( "book" );

				expect( book ).toBeInstanceOf( "ProductBook" );
				expect( book.isLoaded() ).toBeFalse();
			} );

			it( "Can query on parent values through the child", function() {
				var newMusic = getInstance( "ProductMusic" )
					.fill( {
						"type"   : "music",
						"name"   : "Call on Me",
						"artist" : "Eric Prydz",
						"userId" : getInstance( "User" ).first().getId()
					} )
					.save();

				var entity = getInstance( "BaseProduct" ).where( "name", "Call on Me" ).get();

				expect( entity ).toBeArray().toHaveLength( 1 );
				expect( entity[ 1 ] ).toBeInstanceOf( "ProductMusic" );
			} );

			it( "Can query on child entity values", function() {
				var newMusic = getInstance( "ProductMusic" )
					.fill( {
						"type"   : "music",
						"name"   : "Free Fallin",
						"artist" : "Tom Petty",
						"userId" : getInstance( "User" ).first().getId()
					} )
					.save();

				var entity = getInstance( "BaseProduct" ).where( "artist", "Tom Petty" ).get();

				expect( entity ).toBeArray().toHaveLength( 1 );
				expect( entity[ 1 ] ).toBeInstanceOf( "ProductMusic" );
			} );
		} );
	}

}
