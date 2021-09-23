component {

    function up( sb, qb ) {
        sb.create( "internalComments", function( t ) {
            t.unsignedInteger( "FK_comment" )
                .references( "id" )
                .onTable( "comments" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            t.text( "reason" );
            t.primaryKey( "FK_comment" );
        } );

        qb.table( "internalComments" ).insert( [
            { "FK_comment": 4, "reason": "Utra private, ya know?" }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "internalComments" );
    }

}
