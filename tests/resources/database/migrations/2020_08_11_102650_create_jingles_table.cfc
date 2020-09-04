component {

    function up( schema, query ) {
        schema.create( "jingles", function( table ) {
            table.unsignedInteger( "FK_song" )
                .references( "id" )
                .onTable( "songs" )
                .onUpdate( "CASCADE" )
                .onDelete( "CASCADE" );
            table.integer( "catchiness" );
            table.primaryKey( "FK_song" );
        } );
    }

    function down( schema, query ) {
        schema.drop( "jingles" );
    }

}
