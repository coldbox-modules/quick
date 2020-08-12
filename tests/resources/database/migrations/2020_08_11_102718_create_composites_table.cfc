component {

    function up( schema, query ) {
        schema.create( "composites", function( table ) {
            table.unsignedInteger( "a" );
            table.unsignedInteger( "b" );
            table.primaryKey( [ "a", "b" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "composites" );
    }

}
