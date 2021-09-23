component {

    function up( sb, qb ) {
        sb.create( "permissions_roles", function( t ) {
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

    function down( sb, qb ) {
        schema.drop( "permissions_roles" );
    }

}
