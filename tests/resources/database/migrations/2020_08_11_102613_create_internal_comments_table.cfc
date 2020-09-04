component {

    function up( schema, query ) {
        schema.create( "internalComments", function( table ) {
            table.unsignedInteger( "FK_comment" )
                .references( "id" )
                .onTable( "comments" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            table.text( "reason" );
            table.primaryKey( "FK_comment" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "internalComments" );
    }

}
