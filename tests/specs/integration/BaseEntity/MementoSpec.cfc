component extends="tests.resources.ModuleIntegrationSpec" {

	function run() {
		describe( "mementos", function() {
			it( "returns an empty memento for a newly created entity", function() {
				expect( getInstance( "User" ).getMemento() ).toBe( {
					"id"           : "",
					"firstName"    : "",
					"lastName"     : "",
					"email"        : "",
					"username"     : "",
					"password"     : "",
					"type"         : "",
					"countryId"    : "",
					"teamId"       : "",
					"createdDate"  : "",
					"modifiedDate" : "",
					"externalID"   : "",
					"address"      : {
						"streetOne" : "",
						"streetTwo" : "",
						"city"      : "",
						"state"     : "",
						"zip"       : ""
					},
					"favoritePost_id" : ""
				} );
			} );

			it( "returns set values even before saving them", function() {
				var video = getInstance( "Video" );
				video.setTitle( "My Video" );
				expect( video.getMemento() ).toBe( {
					"id"           : "",
					"url"          : "",
					"title"        : "My Video",
					"description"  : "",
					"createdDate"  : "",
					"modifiedDate" : ""
				} );
			} );

			it( "returns retrieved relationships", function() {
				var post                    = getInstance( "Post" ).with( "author" ).findOrFail( 1245 );
				var memento                 = post.getMemento( includes = "author" );
				memento.createdDate         = dateTimeFormat( memento.createdDate, "yyyy-mm-dd hh:nn:ss" );
				memento.modifiedDate        = dateTimeFormat( memento.modifiedDate, "yyyy-mm-dd hh:nn:ss" );
				memento.publishedDate       = dateTimeFormat( memento.publishedDate, "yyyy-mm-dd hh:nn:ss" );
				memento.author.createdDate  = dateTimeFormat( memento.author.createdDate, "yyyy-mm-dd hh:nn:ss" );
				memento.author.modifiedDate = dateTimeFormat( memento.author.modifiedDate, "yyyy-mm-dd hh:nn:ss" );
				expect( memento ).toBe( {
					"post_pk"       : "1245",
					"body"          : "My awesome post body",
					"createdDate"   : "2017-07-28 02:07:00",
					"modifiedDate"  : "2017-07-28 02:07:00",
					"publishedDate" : "2017-07-28 02:07:00",
					"user_id"       : "1",
					"author"        : {
						"id"           : "1",
						"firstName"    : "Eric",
						"lastName"     : "Peterson",
						"email"        : "",
						"username"     : "elpete",
						"password"     : "5F4DCC3B5AA765D61D8327DEB882CF99",
						"type"         : "admin",
						"countryId"    : "02B84D66-0AA0-F7FB-1F71AFC954843861",
						"teamId"       : 1,
						"createdDate"  : "2017-07-28 02:06:36",
						"modifiedDate" : "2017-07-28 02:06:36",
						"externalID"   : "1234",
						"address"      : {
							"streetOne" : "123 Elm Street",
							"streetTwo" : "",
							"city"      : "Salt Lake City",
							"state"     : "UT",
							"zip"       : "84123"
						},
						"favoritePost_id" : "1245"
					}
				} );
			} );

			it( "can check if two entities are the same", function() {
				var users      = getInstance( "User" ).all();
				var userA      = users[ 1 ];
				var userB      = users[ 2 ];
				var userAAgain = users[ 1 ];
				expect( userA.isSameAs( userB ) ).toBeFalse();
				expect( userA.isSameAs( userAAgain ) ).toBeTrue();

				expect( userA.isNotSameAs( userB ) ).toBeTrue();
				expect( userA.isNotSameAs( userAAgain ) ).toBeFalse();
			} );

			it( "can return a query directly as mementos", function() {
				var users = getInstance( "User" ).asMemento().all();
				expect( users ).toBeArray( 4 );
				expect( users[ 1 ] ).toBeStruct();
				expect( users[ 1 ] ).notToBeComponent();
			} );

			it( "can configure the returned mementos with asMemento", function() {
				var users = getInstance( "User" )
					.asMemento( ignoreDefaults = true, includes = [ "id", "username" ] )
					.get();

				expect( users ).toBeArray( 4 );
				expect( users[ 1 ] ).toBeStruct();
				expect( users[ 1 ] ).notToBeComponent();
				expect( users[ 1 ] ).toHaveLength( 2 );
				expect( users[ 1 ] ).toHaveKey( "id" );
				expect( users[ 1 ] ).toHaveKey( "username" );
			} );
		} );
	}

}
