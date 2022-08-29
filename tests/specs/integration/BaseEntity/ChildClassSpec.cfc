component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

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
		} );

        describe( "Single Table Inheritence Class Spec", function() {
			it( "Will fetch a discriminated entity and merge properties", function() {
				// Grab a productbook (child) entity from the BaseProduct by specifying the type (discriminator column)
                var book = getInstance( "BaseProduct" ).where( "type", "book" ).first();

                expect( book.isLoaded() ).toBeTrue();
                expect( book ).toBeInstanceOf( "ProductBook" );

				var memento = book.getMemento();

				expect( memento )
                    .toHaveKey( "id" )
                    .toHaveKey( "isbn" )
                    .notToHaveKey( "artist" );

                // do the same thing with a musicproduct entity now
                var music = getInstance( "BaseProduct" ).where( "type", "music" ).first();

                expect( music.isLoaded() ).toBeTrue();
                expect( music ).toBeInstanceOf( "ProductMusic" );

				memento = music.getMemento();

				expect( memento )
                    .toHaveKey( "id" )
                    .toHaveKey( "artist" )
                    .notToHaveKey( "isbn" );
			} );

			it( "Can load the relationships of the parent through the discriminated child", function() {
				var book = getInstance( "BaseProduct" ).where( "type", "book" ).first();

				expect( book.getCreator() ).toBeInstanceOf( "User" );
				expect( book.getCreator().isLoaded() ).toBeTrue();
			} );

            it( "Can create a new instance of a child entity by specifying discriminator value", function() {
				var book = getInstance( "BaseProduct" ).newEntity( discriminatorValue="book" );

				expect( book ).toBeInstanceOf( "ProductBook" );
				expect( book.isLoaded() ).toBeFalse();
			} );

			it( "Can query on parent values through the child", function() {
				var newMusic = getInstance( "ProductMusic" )
					.fill( {
						"type": "music",
                        "name" : "Call on Me",
						"artist": "Eric Prydz",
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
						"type" : "music",
                        "name" : "Free Fallin",
						"artist": "Tom Petty",
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
