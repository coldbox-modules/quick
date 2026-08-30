component
	extends  ="quick.models.BaseEntity"
	accessors="true"
	table    ="users"
{

	variables.automaticTimestamps = false;

	property name="id";
	property name="username";
	property name="firstName" column="first_name";
	property name="lastName"  column="last_name";
	property
		name         ="createdDate"
		column       ="created_date"
		update       ="false"
		refreshOnSave="true";
	property
		name         ="type"
		insert       ="false"
		update       ="false"
		refreshOnSave="true"
		casts        ="UppercaseCast";

	function postLoad( eventData ) {
		param request.databaseGeneratedUserPostLoadCount = 0;
		request.databaseGeneratedUserPostLoadCount++;
	}

	function postInsert( eventData ) {
		request.databaseGeneratedUserPostInsertCreatedDate = arguments.eventData.entity.getCreatedDate();
	}

	function postUpdate( eventData ) {
		request.databaseGeneratedUserPostUpdateCreatedDate = arguments.eventData.entity.getCreatedDate();
	}

}
