component {

    function up( schema, qb ) {
        schema.create( "products_b", function( table ) {
            table.uuid( "id" ).primaryKey();
            table.timestamp( "createdDate" ).withCurrent();
            table.timestamp( "modifiedDate" ).withCurrent();
            table.timestamp( "deletedDate" ).nullable();
            table.string( "name" );
            table.string( "itemNumber" );
        } );

        qb.newQuery().table( "products_b" ).insert( {
            "id": "BDC3F099-0FBF-4334-AFEAEFFD06C8AAD8",
            "name": "Test Product A",
            "itemNumber": "A14124GSD423"
        } );
    }

    function down( schema, qb ) {
        schema.drop( "products_b" );
    }

}