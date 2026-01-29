component {

    function up( schema, qb ) {
        schema.create( "internalComments", function( t ) {
            t.unsignedInteger( "FK_comment" )
                .references( "id" )
                .onTable( "comments" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            t.text( "reason" );
            t.primaryKey( "FK_comment" );
        } );

        qb.newQuery().table( "comments" ).insert( [
            {
                "id": 4,
                "body": "This is an internal comment. It is very, very private.",
                "commentable_id": 1245,
                "commentable_type": "Post",
                "designation": "internal",
                "user_id": 1,
                "created_date": createDateTime( 2017, 07, 02, 04, 14, 22 ),
                "modified_date": createDateTime( 2017, 07, 02, 04, 14, 22 )
            }
        ] );

        qb.newQuery().table( "internalComments" ).insert( [
            {
                "FK_comment": 4,
                "reason": "Utra private, ya know?"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "internalComments" );
        qb.table( "comments" ).where( "id", 4 ).delete();
    }

}
