component {

    function up( schema, qb ) {
        schema.create( "families", function( t ) {
            t.increments( "familyID" );
            t.unsignedInteger( "parent1ID" ).nullable();
            t.unsignedInteger( "parent2ID" ).nullable();
        } );

        qb.table( "families" ).insert( [
            {
                "familyID": 1,
                "parent1ID": 1,
                "parent2ID": 2
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "families" );
    }

}
