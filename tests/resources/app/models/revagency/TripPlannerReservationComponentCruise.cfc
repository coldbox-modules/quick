component
	extends           ="TripPlannerReservationComponent"
	table             ="trip_planner_reservation_component_cruise"
	joinColumn        ="reservationComponentID"
	discriminatorValue="cruise"
	accessors         ="true"
{

	property name="id"                     column="cruiseComponentID";
	property name="reservationComponentID" column="componentID";
	property name="confirmationNumber"     column="confirmationNumber";

}
