component {

    function up( schema, query ) {
        schema.create( "children", function( table ) {
            table.increments( "childID" );
            table.unsignedInteger( "familyID" );
            table.string( "firstname" );
            table.string( "lastname" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "children" );
    }

}
