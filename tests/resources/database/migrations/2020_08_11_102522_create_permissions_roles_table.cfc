component {

    function up( schema, qb ) {
        schema.create( "permissions_roles", function( t ) {
            t.unsignedInteger( "permissionId" );
            t.unsignedInteger( "roleId" );
            t.primaryKey( [ "permissionId", "roleId" ] );
        } );

        qb.table( "permissions_roles" ).insert( [
            {
                "permissionId": 1,
                "roleId": 1
            },
            {
                "permissionId": 2,
                "roleId": 1
            },
            {
                "permissionId": 2,
                "roleId": 2
            }
        ] );
    }

    function down( schema, qb ) {
        schema.drop( "permissions_roles" );
    }

}
