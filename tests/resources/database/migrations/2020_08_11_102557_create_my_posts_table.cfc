component {

    function up( schema, qb ) {
        schema.create( "my_posts", function( t ) {
            t.increments( "post_pk" );
            t.unsignedInteger( "user_id" ).nullable();
            t.text( "body" );
            t.timestamp( "created_date" ).withCurrent();
            t.timestamp( "modified_date" ).withCurrent();
            t.timestamp( "published_date" ).nullable();
        } );

        qb.table( "my_posts" ).insert( [
            {
                "post_pk": 1245,
                "user_id": 1,
                "body": "My awesome post body",
                "created_date": "2017-07-28 02:07:00",
                "modified_date": "2017-07-28 02:07:00",
                "published_date": "2017-07-28 02:07:00"
            },
            {
                "post_pk": 523526,
                "user_id": 1,
                "body": "My second awesome post body",
                "created_date": "2017-07-28 02:07:36",
                "modified_date": "2017-07-28 02:07:36",
                "published_date": { "value": "", "null": true }
            },
            {
                "post_pk": 7777,
                "user_id": { "value": "", "null": true },
                "body": "My post with no author",
                "created_date": "2017-07-30 07:00:22",
                "modified_date": "2017-07-30 07:00:22",
                "published_date": { "value": "", "null": true }
            },
            {
                "post_pk": 321,
                "user_id": 4,
                "body": "My post with a different author",
                "created_date": "2017-08-28 14:22:22",
                "modified_date": "2017-08-28 14:22:22",
                "published_date": "2017-08-28 14:22:22"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "my_posts" );
    }

}
