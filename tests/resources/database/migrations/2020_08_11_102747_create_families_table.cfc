component {

    function up( schema, query ) {
        schema.create( "families", function( table ) {
            table.increments( "familyID" );
            table.unsignedInteger( "parent1ID" ).nullable();
            table.unsignedInteger( "parent2ID" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "families" );
    }

}
