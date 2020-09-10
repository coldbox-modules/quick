component {

    function up( schema, query ) {
        schema.create( "countries", function( table ) {
            table.uuid( "id" ).primaryKey();
            table.string( "name" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "countries" );
    }

}
