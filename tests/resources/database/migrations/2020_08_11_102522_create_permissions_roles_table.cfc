component {

    function up( schema, query ) {
        schema.create( "permissions_roles", function( table ) {
            table.unsignedInteger( "permissionId" );
            table.unsignedInteger( "roleId" );
            table.primaryKey( [ "permissionId", "roleId" ] );
        } );
    }

    function down( schema, query ) {
        schema.drop( "permissions_roles" );
    }

}
