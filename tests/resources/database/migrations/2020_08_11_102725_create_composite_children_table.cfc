component {

    function up( schema, qb ) {
        schema.create( "composite_children", function( t ) {
            t.increments( "id" );
            t.unsignedInteger( "composite_a" );
            t.unsignedInteger( "composite_b" );
        } );

        qb.table( "composite_children" ).insert( [
            {
                "id": 1,
                "composite_a": 1,
                "composite_b": 2
            },
            {
                "id": 2,
                "composite_a": 2,
                "composite_b": 2
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "composite_children" );
    }

}
