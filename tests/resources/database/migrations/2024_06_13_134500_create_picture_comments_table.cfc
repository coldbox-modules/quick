component {

    function up( schema, qb ) {
        schema.create( "pictureComments", function( t ) {
            t.unsignedInteger( "FK_comment" )
                .references( "id" )
                .onTable( "comments" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            t.text( "filename" );
            t.primaryKey( "FK_comment" );
        } );

        qb.newQuery().table( "comments" ).insert( [
            {
                "id": 5,
                "body": "This is an picture comment. It is very, very picturesque.",
                "commentable_id": 1246,
                "commentable_type": "Post",
                "designation": "picture",
                "user_id": 1,
                "created_date": "2024-06-13 13:14:22",
                "modified_date": "2024-06-13 13:14:22",
                "sentimentAnalysis" : '{ "analyzed": true, "magnitude": 0.8, "score": 0.6  }'
            }
        ] );

        qb.newQuery().table( "pictureComments" ).insert( [
            {
                "FK_comment": 5,
                "filename": "bliss.jpg"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "pictureComments" );
        qb.table( "comments" ).where( "id", 5 ).delete();
    }

}
