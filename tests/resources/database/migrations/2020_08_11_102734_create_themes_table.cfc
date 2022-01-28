component {

    function up( schema, qb ) {
        schema.create( "themes", function( t ) {
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

    function down( schema, query ) {
        schema.drop( "themes" );
    }

}
