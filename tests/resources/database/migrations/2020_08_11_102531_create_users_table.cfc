component {

    function up( schema, qb ) {
        schema.create( "users", function( t ) {
            t.increments( "id" );
            t.string( "username" );
            t.string( "first_name" );
            t.string( "last_name" );
            t.string( "email" ).nullable();
            t.string( "password" ).nullable();
            t.uuid( "country_id" ).nullable();
            t.unsignedInteger( "team_id" ).nullable();
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
            t.string( "type" ).default( "limited" );
            t.string( "externalId" ).nullable();
            t.string( "streetOne" ).nullable();
            t.string( "streetTwo" ).nullable();
            t.string( "city" ).nullable();
            t.string( "state", 2 ).nullable().nullable();
            t.string( "zip", 10 ).nullable().nullable();
            t.unsignedInteger( "favoritePost_id" ).nullable();
        } );

        qb.table( "users" ).insert( [
            {
                "id": 1,
                "username": "elpete",
                "first_name": "Eric",
                "last_name": "Peterson",
                "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                "country_id": "02B84D66-0AA0-F7FB-1F71AFC954843861",
                "team_id": 1,
                "created_date": createDateTime( 2017, 07, 28, 02, 06, 36 ),
                "modified_date": createDateTime( 2017, 07, 28, 02, 06, 36 ),
                "type": "admin",
                "externalId": "1234",
                "streetOne": "123 Elm Street",
                "streetTwo": { "value": "", "null": true },
                "city": "Salt Lake City",
                "state": "UT",
                "zip": "84123",
                "favoritePost_id": 1245
            },
            {
                "id": 2,
                "username": "johndoe",
                "first_name": "John",
                "last_name": "Doe",
                "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                "country_id": "02B84D66-0AA0-F7FB-1F71AFC954843861",
                "team_id": 1,
                "created_date": createDateTime( 2017, 07, 28, 02, 07, 16 ),
                "modified_date": createDateTime( 2017, 07, 28, 02, 07, 16 ),
                "type": "limited",
                "externalId": "6789",
                "streetOne": "123 Elm Street",
                "streetTwo": { "value": "", "null": true },
                "city": "Salt Lake City",
                "state": "UT",
                "zip": "84123",
                "favoritePost_id": { "value": "", "null": true }
            },
            {
                "id": 3,
                "username": "janedoe",
                "first_name": "Jane",
                "last_name": "Doe",
                "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                "country_id": { "value": "", "null": true },
                "team_id": 1,
                "created_date": createDateTime( 2017, 07, 28, 02, 08, 16 ),
                "modified_date": createDateTime( 2017, 07, 28, 02, 08, 16 ),
                "type": "limited",
                "externalId": "5555",
                "streetOne": "123 Elm Street",
                "streetTwo": { "value": "", "null": true },
                "city": "Salt Lake City",
                "state": "UT",
                "zip": "84123",
                "favoritePost_id": { "value": "", "null": true }
            },
            {
                "id": 4,
                "username": "elpete2",
                "first_name": "Another",
                "last_name": "Peterson",
                "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                "country_id": "02BA2DB0-EB1E-3F85-5F283AB5E45608C6",
                "team_id": 2,
                "created_date": createDateTime( 2019, 06, 15, 12, 29, 36 ),
                "modified_date": createDateTime( 2019, 06, 15, 12, 29, 36 ),
                "type": "admin",
                "externalId": "1234",
                "streetOne": "123 Elm Street",
                "streetTwo": { "value": "", "null": true },
                "city": "Salt Lake City",
                "state": "UT",
                "zip": "84123",
                "favoritePost_id": { "value": "", "null": true }
            },
            {
                "id": 5,
                "username": "michaelscott",
                "first_name": "Michael",
                "last_name": "Scott",
                "password": "5F4DCC3B5AA765D61D8327DEB882CF99",
                "country_id": "02BA2DB0-EB1E-3F85-5F283AB5E45608C6",
                "team_id": 3,
                "created_date": createDateTime( 2020, 01, 14, 12, 29, 36 ),
                "modified_date": createDateTime( 2020, 06, 22, 12, 29, 36 ),
                "type": "limited",
                "externalId": { "value": "", "null": true },
                "streetOne": "1725 Slough Avenue",
                "streetTwo": { "value": "", "null": true },
                "city": "Scranton",
                "state": "PA",
                "zip": "18501",
                "favoritePost_id": { "value": "", "null": true }
            }
        ] );
    }

    function down( schema, query ) {
        schema.drop( "users" );
    }

}
