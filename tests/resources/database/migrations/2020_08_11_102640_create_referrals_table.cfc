component {

    function up( schema, query ) {
        schema.create( "referrals", function( table ) {
            table.increments( "id" );
            table.string( "type" );
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
        } );
    }

    function down( schema, query ) {
        schema.drop( "referrals" );
    }

}
