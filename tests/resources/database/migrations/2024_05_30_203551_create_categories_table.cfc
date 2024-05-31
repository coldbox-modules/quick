component {

    function up( schema, qb ) {
        schema.create( "categories", function( table ) {
            table.unsignedInteger( "id" ).primaryKey();
            table.unsignedInteger( "parentId" ).nullable();
        } );

        qb.newQuery().table( "categories" ).insert( [
            { "id": 1, "parentId": { "value": 0, "null": true, "nulls": true } },
            { "id": 2, "parentId": 1 }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "categories" );
    }

}