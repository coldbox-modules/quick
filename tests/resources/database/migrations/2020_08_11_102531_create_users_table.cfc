component {

    function up( schema, query ) {
        schema.create( "users", function( table ) {
            table.increments( "id" );
            table.string( "username" );
            table.string( "first_name" );
            table.string( "last_name" );
            table.string( "email" ).nullable();
            table.string( "password" ).nullable();
            table.uuid( "country_id" ).nullable();
            table.unsignedInteger( "team_id" ).nullable();
            table.timestamp( "created_date" ).withCurrent();
            table.timestamp( "modified_date" ).withCurrent();
            table.string( "type" ).default( "limited" );
            table.string( "externalId" ).nullable();
            table.string( "streetOne" ).nullable();
            table.string( "streetTwo" ).nullable();
            table.string( "city" ).nullable();
            table.string( "state", 2 ).nullable().nullable();
            table.string( "zip", 10 ).nullable().nullable();
            table.unsignedInteger( "favoritePost_id" ).nullable();
        } );
    }

    function down( schema, query ) {
        schema.drop( "users" );
    }

}
