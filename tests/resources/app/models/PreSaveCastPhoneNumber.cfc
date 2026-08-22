component
	extends  ="quick.models.BaseEntity"
	table    ="phone_numbers"
	accessors="true"
{

	property name="id";
	property name="number"    casts="YesNoCast";
	property name="active"    casts="BooleanCast@quick";
	property name="confirmed" casts="BooleanCast@quick";

	function preSave() {
		assignAttribute( "number", getActive() );
	}

}
