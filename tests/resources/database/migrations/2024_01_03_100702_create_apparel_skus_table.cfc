component {

    function up( schema, qb ) {
        schema.create( "apparel_skus", function( table ) {
            table.uuid( "id" ).primaryKey();
            table.decimal( "cost", 10, 2 );
            table.string( "color" );
            table.string( "size1" );
            table.string( "size1Description" );
            table.integer( "size1Index" ).default( 0 );
        } );

        qb.newQuery().table( "apparel_skus" ).insert( {
            "id": "E9B52E1B-66BB-4ACE-B8306808B4E64EA3",
            "cost": 10.00,
            "color": "black",
            "size1": "S",
            "size1Description": "Small"
        } );
    }

    function down( schema, qb ) {
        schema.drop( "apparel_skus" );
    }

}