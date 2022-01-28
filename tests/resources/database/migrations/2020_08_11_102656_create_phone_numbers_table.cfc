component {

    function up( schema, qb ) {
        schema.create( "phone_numbers", function( t ) {
            t.increments( "id" );
            t.string( "number" );
            t.boolean( "active" ).nullable();
        } );

        qb.table( "phone_numbers" ).insert( [
            {
                "id": 1,
                "number": "323-232-3232",
                "active": 1
            },
            {
                "id": 2,
                "number": "545-454-5454",
                "active": 0
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "phone_numbers" );
    }

}
