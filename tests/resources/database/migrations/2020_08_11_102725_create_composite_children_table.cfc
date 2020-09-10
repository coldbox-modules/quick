component {

    function up( schema, query ) {
        schema.create( "composite_children", function( table ) {
            table.increments( "id" );
            table.unsignedInteger( "composite_a" );
            table.unsignedInteger( "composite_b" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "composite_children" );
    }

}
