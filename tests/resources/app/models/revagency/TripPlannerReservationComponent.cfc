component
	extends            ="quick.models.BaseEntity"
	table              ="trip_planner_reservation_component"
	discriminatorColumn="type"
	accessors          ="true"
{

	property name="id"              column="componentID";
	property name="reservationId"   column="reservationID";
	property name="tripComponentId" column="tripComponentID";
	property name="type"            column="type";
	property
		name  ="isActive"
		column="isActive"
		type  ="boolean"
		casts ="BooleanCast@quick";
	property
		name  ="createdDate"
		column="createdDate"
		type  ="date";
	property
		name  ="createdByAgentId" 
		column="createdByAgentId" 
		hint  ="if the record was created by an agent, the agent identifier, otherwise null";
	property
		name  ="createdByMemberId"
		column="createdByMemberId"
		hint  ="if the record was created by a member, the member identifier, otherwise null";
	property
		name  ="modifiedDate"
		column="modifiedDate"
		type  ="date";
	property
		name  ="modifiedByAgentId" 
		column="modifiedByAgentId" 
		hint  ="the agent identifier of the last agent to modify this record the record - not necessarily the most recent modification";
	property
		name  ="modifiedByMemberId"
		column="modifiedByMemberId"
		hint  ="the member identifier of the last member to modify this record the record - not necessarily the most recent modification";
	property
		name  ="lastModifiedBy"    
		column="lastModifiedBy"    
		hint  ="was the last person to modify this record";

	variables._discriminators = [ "TripPlannerReservationComponentCruise" ];

}
