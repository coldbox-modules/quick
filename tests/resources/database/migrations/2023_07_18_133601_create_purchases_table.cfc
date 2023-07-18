component {

    function up( schema, qb ) {
        schema.create( "purchases", function( t ) {
            t.increments( "id" );
            t.unsignedInteger( "userId" );
            t.unsignedInteger( "price" );
            t.unsignedInteger( "quantity" );
            t.datetime( "createdDate" ).withCurrent();
        } );

        qb.newQuery().table( "purchases" ).insert( [
            { "userId": 1, "price": 100, "quantity": 3 },
            { "userId": 1, "price": 50, "quantity": 2 },
            { "userId": 1, "price": 30, "quantity": 1 },
            { "userId": 4, "price": 40, "quantity": 1 },
            { "userId": 4, "price": 20, "quantity": 1 },
            { "userId": 5, "price": 50, "quantity": 3 }
        ] )
    }

    function down( schema, query ) {
        schema.drop( "purchases" );
    }

}
