component {

    function up( sb, qb ) {
        sb.create( "roles_users", function( t ) {
            t.unsignedInteger( "roleId" );
            t.unsignedInteger( "userId" );
            t.primaryKey( [ "roleId", "userId" ] );
        } );

        qb.table( "roles_users" ).insert( [
            { "roleId": 1, "userId": 1 },
            { "roleId": 3, "userId": 1 },
            { "roleId": 3, "userId": 2 },
            { "roleId": 3, "userId": 3 },
            { "roleId": 2, "userId": 4 },
            { "roleId": 3, "userId": 4 }
        ] );
    }

    function down( sb, qb ) {
        sb.drop( "roles_users" );
    }

}
