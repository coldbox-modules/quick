component {

    function up( schema, query ) {
        schema.create( "roles_users", function( table ) {
            table.unsignedInteger( "roleId" );
            table.unsignedInteger( "userId" );
            table.primaryKey( [ "roleId", "userId" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "roles_users" );
    }

}
