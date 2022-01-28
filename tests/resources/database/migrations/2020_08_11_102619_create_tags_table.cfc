component {

    function up( schema, qb ) {
        schema.create( "tags", function( t ) {
            t.increments( "id" );
            t.string( "name" );
        } );

        qb.table( "tags" ).insert( [
        	{
                "id": 1,
                "name": "programming"
            },
            {
                "id": 2,
                "name": "music"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "tags" );
    }

}
