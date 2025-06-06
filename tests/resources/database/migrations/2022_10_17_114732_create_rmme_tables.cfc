component {

    function up( schema, qb ) {
        schema.create( "RMME_A", function( table ) {
            table.unsignedInteger( "ID_A" ).nullable();
            table.primaryKey( "ID_A" );
        } );

        schema.create( "RMME_B", function( table ) {
            table.unsignedInteger( "ID_A" ).nullable();
            table.unsignedInteger( "ID_B" ).nullable();
            table.primaryKey( "ID_B" );
        } );

        schema.create( "RMME_C", function( table ) {
            table.unsignedInteger( "ID_B" ).nullable();
            table.unsignedInteger( "ID_C" ).nullable();
            table.unsignedInteger( "ID_D" ).nullable();
            table.primaryKey( "ID_C" );
        } );

        schema.create( "RMME_D", function( table ) {
            table.unsignedInteger( "ID_D" ).nullable();
            table.unsignedInteger( "dValue" ).nullable();
            table.primaryKey( "ID_D" );
        } );

        qb.newQuery().table( "RMME_A" ).insert( { "ID_A": 1 } );
        qb.newQuery().table( "RMME_B" ).insert( { "ID_A": 1, "ID_B": 1 } );
        qb.newQuery().table( "RMME_C" ).insert( { "ID_B": 1, "ID_C": 1, "ID_D": 1 } );
        qb.newQuery().table( "RMME_D" ).insert( { "ID_D": 1, "dValue": 42 } );
    }

    function down( schema, query ) {
        schema.drop( "products" );
    }

}
