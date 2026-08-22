component
	extends  ="quick.models.BaseEntity"
	table    ="phone_numbers"
	accessors="true"
{

	property name="id";
	property name="confirmed" casts="NullValueCast";

}
