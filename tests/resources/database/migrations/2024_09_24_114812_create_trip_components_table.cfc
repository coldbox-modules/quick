component {

	function up( schema, qb ) {
		schema.create( "trip_planner_reservation_component", function( table ) {
			table.unsignedInteger( "componentID" );
			table.unsignedInteger( "reservationID" );
			table.unsignedInteger( "tripComponentID" );
			table.string( "type" );
			table.bit( "isActive" );
			table.datetime( "createdDate" ).withCurrent();
			table.unsignedInteger( "createdByAgentId" ).nullable();
			table.unsignedInteger( "createdByMemberId" ).nullable();
			table.datetime( "modifiedDate" ).withCurrent();
			table.unsignedInteger( "modifiedByAgentId" ).nullable();
			table.unsignedInteger( "modifiedByMemberId" ).nullable();
			table.unsignedInteger( "lastModifiedBy" ).nullable();
		} );

		qb.newQuery()
			.table( "trip_planner_reservation_component" )
			.insert( [
				{
					"componentID"     : 4,
					"reservationID"   : 5,
					"tripComponentID" : 2,
					"type"            : "cruise",
					"isActive"        : 1,
					"createdDate"     : { "value": now(), "cfsqltype": "TIMESTAMP" },
					"modifiedDate"    : { "value": now(), "cfsqltype": "TIMESTAMP" }
				}
			] );
	}

	function down( schema, qb ) {
		schema.drop( "trip_planner_reservation_component" );
	}

}
