component {

    function up( schema, qb ) {
        schema.create( "product_skus", function( table ) {
            table.uuid( "id" ).primaryKey();
            table.timestamp( "createdDate" ).withCurrent();
            table.timestamp( "modifiedDate" ).withCurrent();
            table.timestamp( "deletedDate" ).nullable();
            table.uuid( "productId" ).references( "id" ).onTable( "products_b" );
            table.string( "designation" );
        } );

        qb.newQuery().table( "product_skus" ).insert( [
            {
                "id": "E9B52E1B-66BB-4ACE-B8306808B4E64EA3",
                "productId": "BDC3F099-0FBF-4334-AFEAEFFD06C8AAD8",
                "designation": "apparel"
            },
            {
                "id": "E917DAFA-AD36-4601-9F11A0B54C3B5502",
                "productId": "BDC3F099-0FBF-4334-AFEAEFFD06C8AAD8",
                "designation": "product"
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "product_skus" );
    }

}