component {

	function up( schema, qb ) {
		schema.create( "trip_planner_reservation_component_cruise", function( table ) {
			table.unsignedInteger( "cruiseComponentID" );
			table.unsignedInteger( "componentID" );
			table.string( "confirmationNumber" );
		} );

		qb.newQuery()
			.table( "trip_planner_reservation_component_cruise" )
			.insert( [
				{
					"cruiseComponentID"  : 11,
					"componentID"        : 4,
					"confirmationNumber" : "ABC123"
				}
			] );
	}

	function down( schema, qb ) {
		schema.drop( "trip_planner_reservation_component_cruise" );
	}

}
