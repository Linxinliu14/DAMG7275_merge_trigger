--database name
use Linxin_Liu;
/* Lab 2 - Data Pipelines */

-- Part 1

 /*
   Given two sets of tables as defined below, build a
   data pipeline using the SQL MERGE function and SQL job
   to synchronize the data stored in these two sets of
   tables daily. Keep an audit trail of what's changed
   in the destination set of tables using the SQL OUTPUT command.
   Create a stored procedure containing the data pipeline code
   and use the stored procedure in the job step.
   The two data sets reside in two separate databases.
   The audit table exists in the destination database.

   Regarding the UPDATE command, in the destination data set,
   only LastName, FirstName, AppointmentDate and ModifiedDate 
   may change.

   Submit the SQL code and the screenshots of the job step and
   the job schedule.
 */
 --view v1 used for merging
 create view v1
 as select a.AppointmentID,a.CustomerID,c.LastName,c.FirstName, a.AppointmentDate,a.ModifiedDate from Appointment a
 join Customer c
 on a.CustomerID=c.CustomerID;

 ---Stored procedure for merging Customer and Appointment into AppointmentReport
 -- Check DAMG Lab2 Linxin Liu . doxc for screenshots
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

	---Stored procedure for merging AppointmentReport into DateAudit
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


-- Part 2

  /*
   Given two sets of tables as defined below, build a
   data pipeline using the SQL triggers
   to synchronize the data stored in these two sets of
   tables. Keep an audit trail of what's changed
   in the destination set of tables.    
   The two data sets reside in two separate databases.
   The audit tables exist in the destination database.

   Regarding the UPDATE command:
   For the Client table, only LastName, FirstName, and 
   ModifiedDate may change. For the Account table, only the 
   interest rate and ModifiedDate may change.

   Submit the SQL code.
 */
 -- Statement for merging Client into ClientReport by using trigger
 Create or Alter Trigger mergeClient
 on Client
 After insert, update
 As
 Begin
 if Exists(Select * from deleted)
 begin
	update ClientReport 
	set ClientReport.LastName= x.LastName, ClientReport.FirstName=x.FirstName, ClientReport.ModifiedDate=x.ModifiedDate
	from (select d.ClientID, i.LastName, i.FirstName, i.ModifiedDate from inserted i
	join deleted d
	on i.ClientID=d.ClientID) as x
	where ClientReport.ClientID=x.ClientID
	end
 else 
 Begin
	Insert into ClientReport( ClientID, LastName, FirstName, ModifiedDate )
	select ClientID, LastName, FirstName, ModifiedDate from Client
 End
 End;

 -- Statement for merging Account into AccountReport by using trigger
 Create or Alter Trigger mergeAccount
 on Account
 After insert, update
 As 
 Begin
 If Exists(Select * from deleted)
 begin
	Update AccountReport
	set AccountNumber=x.AccountNumber, ClientID=x.ClientID, AccountType=x.AccountType, InterestRate=x.InterestRate, ModifiedDate=x.ModifiedDate from 
	(select d.AccountNumber, d.ClientID, d.AccountType, i.InterestRate, i.ModifiedDate from inserted i join deleted d
	on i.AccountNumber=d.AccountNumber
	where i.ClientID=d.ClientID) x
	where AccountReport.AccountNumber=x.AccountNumber and AccountReport.ClientID=x.ClientID and AccountReport.AccountType=x.AccountType
 End
 Else
 Begin
	Insert into AccountReport(AccountNumber, ClientID,AccountType,InterestRate,ModifiedDate)
	select AccountNumber, ClientID, AccountType, InterestRate, ModifiedDate from Account
 End
 End;

 -- Statement for audit changes in Client and merge update in Client into AuditClient
 create or alter trigger updateClient
 on Client
 After update,insert
 As 
 Begin
	if Exists(Select * from deleted)
	Begin
		Insert into AuditClient(ClientID,NewLastName, OldLastName, NewFirstName, OldFirstName,[Action])
		select d.ClientID, i.LastName, d.LastName,i.FirstName,d.FirstName, 'u' from inserted i 
		join deleted d
		on i.ClientID=d.ClientID
	End
 End;

  -- Statement for audit changes in Account and merge update in Account into AuditAccount
 create or alter trigger updateAccount
 on Account
 After update, insert
 As
 Begin
	if Exists(Select * from deleted)
	Begin
		insert into AuditAccount (AccountNumber, ClientID,AccountType, NewInterestRate, OldInterestRate, [Action])
		select i.AccountNumber, i.ClientID, i.AccountType, i.InterestRate, d.InterestRate, 'U' from inserted i join deleted d
		on i.AccountNumber=d.AccountNumber
		where i.ClientID=d.ClientID

	End
 End;