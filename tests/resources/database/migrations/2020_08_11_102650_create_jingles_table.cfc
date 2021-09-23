component {

    function up( sb, qb ) {
        sb.create( "jingles", function( t ) {
            t.unsignedInteger( "FK_song" )
                .references( "id" )
                .onTable( "songs" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            t.integer( "catchiness" );
            t.primaryKey( "FK_song" );
        } );

        qb.table( "jingles" ).insert( [
            { "FK_song": 3, "catchiness": 3 }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "jingles" );
    }

}
