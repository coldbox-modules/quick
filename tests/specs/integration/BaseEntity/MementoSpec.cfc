component extends="tests.resources.ModuleIntegrationSpec" appMapping="/app" {

    function run() {
        describe( "mementos", function() {
            it( "returns an empty memento for a newly created entity", function() {
                expect( getInstance( "User" ).getMemento() ).toBe( {
                    "id": "",
                    "firstName": "",
                    "lastName": "",
                    "email": "",
                    "username": "",
                    "password": "",
                    "type": "",
                    "countryId": "",
                    "createdDate": "",
                    "modifiedDate": "",
                    "externalID": ""
                } );
            } );

            it( "returns set values even before saving them", function() {
                var video = getInstance( "Video" );
                video.setTitle( "My Video" );
                expect( video.getMemento() ).toBe( {
                    "id": "",
                    "url": "",
                    "title": "My Video",
                    "description": "",
                    "createdDate": "",
                    "modifiedDate": ""
                } );
            } );

            it( "returns retrieved relationships", function() {
                var post = getInstance( "Post" )
                    .with( "author" )
                    .findOrFail( 1245 );
                expect( post.getMemento( includes = "author" ) ).toBe( {
                    "post_pk": "1245",
                    "body": "My awesome post body",
                    "createdDate": "2017-07-28 02:07:00",
                    "modifiedDate": "2017-07-28 02:07:00",
                    "publishedDate": "2017-07-28 02:07:00",
                    "user_id": "1",
                    "author": {
                        "id": "1",
                        "firstName": "Eric",
                        "lastName": "Peterson",
                        "email": "",
                        "username": "elpete",
                        "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                        "type": "admin",
                        "countryId": "02B84D66-0AA0-F7FB-1F71AFC954843861",
                        "createdDate": "2017-07-28 02:06:36",
                        "modifiedDate": "2017-07-28 02:06:36",
                        "externalID": "1234"
                    }
                } );
            } );

            it( "can check if two entities are the same", function() {
                var users = getInstance( "User" ).all();
                var userA = users[ 1 ];
                var userB = users[ 2 ];
                var userAAgain = users[ 1 ];
                expect( userA.is( userB ) ).toBeFalse();
                expect( userA.is( userAAgain ) ).toBeTrue();

                expect( userA.isNot( userB ) ).toBeTrue();
                expect( userA.isNot( userAAgain ) ).toBeFalse();
            } );
        } );
    }

}
