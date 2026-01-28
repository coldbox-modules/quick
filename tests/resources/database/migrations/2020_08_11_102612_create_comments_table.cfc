component {

    function up( schema, qb ) {
        schema.create( "comments", function( t ) {
            t.increments( "id" );
            t.text( "body" );
            t.unsignedInteger( "commentable_id" );
            t.string( "commentable_type" );
            t.string( "designation" ).default( "public" );
            t.unsignedInteger( "user_id" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
        } );

        qb.table( "comments" ).insert( [
            {
                "id": 1,
                "body": "I thought this post was great",
                "commentable_id": 1245,
                "commentable_type": "Post",
                "designation": "public",
                "user_id": 1,
                "created_date": createDateTime( 2017, 07, 02, 04, 14, 22 ),
                "modified_date": createDateTime( 2017, 07, 02, 04, 14, 22 )
            },
            {
                "id": 2,
                "body": "I thought this post was not so good",
                "commentable_id": 321,
                "commentable_type": "Post",
                "designation": "public",
                "user_id": 2,
                "created_date": createDateTime( 2017, 07, 04, 04, 14, 22 ),
                "modified_date": createDateTime( 2017, 07, 04, 04, 14, 22 )
            },
            {
                "id": 3,
                "body": "What a great video! So fun!",
                "commentable_id": 1245,
                "commentable_type": "Video",
                "designation": "public",
                "user_id": 1,
                "created_date": createDateTime( 2017, 07, 02, 04, 14, 22 ),
                "modified_date": createDateTime( 2017, 07, 02, 04, 14, 22 )
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "comments" );
    }

}
