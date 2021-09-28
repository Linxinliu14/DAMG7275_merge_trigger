
	merge AppointmentReport as target
	using v1 as source
	on source.AppointmentID=target.AppointmentID
	when matched and target.FirstName<>source.FirstName then --change of the first name
	update set target.FirstName=source.FirstName 
	when matched and target.Lastname<>source.Lastname then --change of the last name
	update set target.Lastname=source.Lastname
	when matched and target.FirstName<>source.FirstName and target.Lastname<>source.Lastname then --change of both first and last name
	update set target.FirstName=source.FirstName, target.Lastname=source.Lastname 
	when matched and target.CustomerID = source.CustomerID --change of Appointment Date and Modified Date
				and target.Lastname=source.Lastname 
				and target.FirstName=source.FirstName 
				and target.AppointmentDate<> source.AppointmentDate 
				and target.ModifiedDate<>source.ModifiedDate then 
	update set target.AppointmentDate=source.AppointmentDate, target.ModifiedDate=source.ModifiedDate
	when not matched by source then -- does not exist in source table
	delete
	when not matched then -- does not exist in target table
	insert (AppointmentID,CustomerID, LastName,FirstName,AppointmentDate,ModifiedDate) 
	values(source.AppointmentID,source.CustomerID, source.LastName,source.FirstName,source.AppointmentDate,source.ModifiedDate);

	merge DateAudit as target
	using AppointmentReport as source
	on source.AppointmentID=target.AppointmentID
	when matched then 
		update 
		set Action='Changed',OldDate=target.NewDate, NewDate=source.AppointmentDate
	when not matched by source then 
		delete
	when not matched then 
		insert (Action, AppointmentID, NewDate) 
		values ('Added',source.AppointmentID,source.AppointmentDate);