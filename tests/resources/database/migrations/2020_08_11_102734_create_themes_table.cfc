component {

    function up( sb, qb ) {
        sb.create( "themes", function( t ) {
            t.increments( "id" );
            t.string( "slug" );
            t.string( "version" );
            t.text( "config" ).nullable();
        } );

        qb.table( "themes" ).insert( [
            {
                "id": 1,
                "slug": "theme-a",
                "version": "1.0.0"
            }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "themes" );
    }

}
