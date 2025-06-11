component {

    function up( schema, qb ) {
        schema.create( "inventory_batches", function( t ) {
            t.unsignedInteger( "id" ).primaryKey();
            t.string( "name" );
        } );

        schema.create( "trades", function( t ) {
            t.increments( "id" );
            t.unsignedInteger( "inventoryBatchId" ).references( "id" ).onTable( "inventory_batches" );
        } );

        qb.newQuery().table( "inventory_batches" ).insert( [
            { "id": 1, "name": "Batch 1" },
            { "id": 2, "name": "Batch 2" },
            { "id": 3, "name": "Batch 3" }
        ] );

        qb.table( "trades" ).insert( [
            { "id": 1, "inventoryBatchId": 1 },
            { "id": 2, "inventoryBatchId": 1 },
            { "id": 3, "inventoryBatchId": 2 },
            { "id": 4, "inventoryBatchId": 3 },
            { "id": 5, "inventoryBatchId": 3 },
            { "id": 6, "inventoryBatchId": 3 }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "trades" );
        schema.drop( "inventory_batches" );
    }

}
