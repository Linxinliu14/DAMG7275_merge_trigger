create database Linxin_Liu;
use Linxin_Liu;

CREATE TABLE DateAudit
(LogID INT IDENTITY,
 Action VARCHAR(10),
 AppointmentID INT,
 OldDate DATE, -- appointment date
 NewDate DATE, -- appointment date
 ChangedBy VARCHAR(50) DEFAULT original_login(),
 ChangeTime DATETIME DEFAULT GETDATE());

 create view v1
 as select a.AppointmentID,a.CustomerID,c.LastName,c.FirstName, a.AppointmentDate,a.ModifiedDate from Appointment a
 join Customer c
 on a.CustomerID=c.CustomerID;
 
 

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

	insert into Customer (FirstName, LastName)
	values('Ann', 'Ben');
	insert into Appointment( CustomerID, AppointmentDate,ModifiedDate)
	values (1,'2021-09-23','2021-09-23');
	select * from Appointment
	select * from  Customer
	select * from AppointmentReport;

	delete from Appointment;
	delete from Customer;
	insert into Customer (FirstName, LastName)
	values('Ann', 'Ben');
	insert into Appointment( CustomerID, AppointmentDate,ModifiedDate)
	select CustomerID,'2021-09-23','2021-09-23' from Customer

	select * from Appointment;
	
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

	-- In Source Database

CREATE TABLE Client
(ClientID INT IDENTITY PRIMARY KEY,
 LastName VARCHAR(50),
 FirstName VARCHAR(50),
 ModifiedDate DATETIME DEFAULT getdate());

CREATE TABLE Account
(AccountNumber INT IDENTITY PRIMARY KEY,
 ClientID INT NOT NULL REFERENCES Client(ClientID),
 AccountType varchar(10),
 InterestRate decimal(4,3),
 ModifiedDate DATETIME DEFAULT getdate());

-- In Destination Database

CREATE TABLE ClientReport
(ClientID INT PRIMARY KEY,
 LastName VARCHAR(50),
 FirstName VARCHAR(50),
 ModifiedDate DATETIME);

CREATE TABLE AccountReport
(AccountNumber INT PRIMARY KEY,
 ClientID INT NOT NULL REFERENCES ClientReport(ClientID),
 AccountType varchar(10),
 InterestRate decimal(4,3),
 ModifiedDate DATETIME);

CREATE TABLE AuditClient
 (
  Audit_PK  INT  IDENTITY(1,1) NOT NULL
  ,ClientID  INT  NOT NULL
  ,NewLastName VARCHAR(50)
  ,OldLastName VARCHAR(50)
  ,NewFirstName VARCHAR(50)
  ,OldFirstName VARCHAR(50)
  ,[Action] CHAR(6) NULL
  ,ActionTime DATETIME DEFAULT GETDATE()
 );

CREATE TABLE AuditAccount
 (
  Audit_PK INT IDENTITY(1,1) NOT NULL
  ,AccountNumber INT NOT NULL
  ,ClientID INT NOT NULL
  ,AccountType varchar(10)
  ,NewInterestRate decimal(4,3)
  ,OldInterestRate decimal(4,3)
  ,[Action] CHAR(6) NULL
  ,ActionTime DATETIME DEFAULT GETDATE()
 );
 
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

 Insert into Client(LastName, FirstName)
 values('john', 'j');

 select * from Client;
 select * from ClientReport;
 select * from AuditClient;
 update Client
 set LastName='k'
 where LastName='l'

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

 Insert into Account(ClientID, AccountType, InterestRate)
 select ClientID,'Temorary', 4.33 from Client;

 select * from AccountReport;

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

 update Account
 set InterestRate='0.23'
 where ClientID=1
 select * from Account;
 select * from AccountReport;
 select * from AuditAccount;
