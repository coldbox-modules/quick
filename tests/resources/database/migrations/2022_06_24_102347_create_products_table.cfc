component {

    function up( schema, qb ) {
        schema.create( "products", function( table ) {
            table.increments( "ID" );
            table.string( "name" ).nullable();
            table.string( "type" ).nullable(); // ( books|music )
            table.string( "isbn" ).nullable(); // books only
            table.string( "artist" ).nullable(); // music only
            table.unsignedInteger( "user_id" ); // relationship to user
        } );

        qb.newQuery().table( "products" ).insert( {
                "ID": 1,
                "name": "The Lord Of The Rings",
                "type": "book",
                "isbn": "9780544003415",
                "user_id": 2
        } );

        qb.newQuery().table( "products" ).insert( {
                "ID": 2,
                "name": "Jeremy",
                "type": "music",
                "artist": "Pearl Jam",
                "user_id": 1
        } );
    }

    function down( schema, query ) {
        schema.drop( "products" );
    }

}
