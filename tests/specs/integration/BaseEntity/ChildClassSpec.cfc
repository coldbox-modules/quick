component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

	function run() {
		describe( "Child Class Spec", function() {
			it( "merges parent table and child table attributes int to entity", function() {
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

				transactionSetSavepoint( "jingle-saved" );

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

				transactionSetSavepoint( "jingle-saved" );

				getInstance( "Jingle" ).findOrFail( newJingle.getId() ).delete();

				transactionSetSavepoint( "jingle-deleted" );

				expect( isNull( getInstance( "Jingle" ).find( newJingle.getId() ) ) ).toBeTrue();
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
			} );

			it( "Can query on parent values through the child", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1345,
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
						"commentableId"   : 1345,
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
						"commentableId"   : 1345,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				transactionSetSavepoint( "comment-saved" );

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

			it( "can update a child entity", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1345,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				transactionSetSavepoint( "comment-saved" );

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
						"commentableId"   : 1345,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				transactionSetSavepoint( "comment-saved" );

				getInstance( "InternalComment" ).findOrFail( newComment.getId() ).delete();

				transactionSetSavepoint( "comment-deleted" );

				expect( isNull( getInstance( "InternalComment" ).find( newComment.getId() ) ) ).toBeTrue();
			} );

			it( "Will return a child entity when retrieving a single entity from the parent", function() {
				var newComment = getInstance( "InternalComment" )
					.fill( {
						"reason"          : "I like to keep things private",
						"body"            : "Lorem ipsum",
						"commentableId"   : 1345,
						"commentableType" : "Post",
						"userId"          : getInstance( "User" ).first().getId(),
						"createdDate"     : now(),
						"modifiedDate"    : now()
					} )
					.save();

				var parentRetrieval = getInstance( "Comment" ).find( newComment.getId() );
				expect( isInstanceOf( parentRetrieval, "InternalComment" ) ).toBeTrue();
			} );

			it( "Will return an array of child classes when fetching multiple results from the parent class", function() {
				var internalComments = getInstance( "Comment" ).where( "designation", "internal" ).get();
				internalComments.each( function( comment ) {
					expect( isInstanceOf( comment, "InternalComment" ) ).toBeTrue();
				} );
			} );
		} );
	}

}
