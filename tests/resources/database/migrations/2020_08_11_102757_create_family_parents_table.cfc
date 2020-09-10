component {

    function up( schema, query ) {
        schema.create( "family_parents", function( table ) {
            table.unsignedInteger( "parentID" );
            table.unsignedInteger( "familyID" );
            table.primaryKey( [ "parentID", "familyID" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "family_parents" );
    }

}
