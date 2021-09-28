
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

-- In Source Database

CREATE TABLE Customer
(CustomerID INT IDENTITY PRIMARY KEY,
 LastName VARCHAR(50),
 FirstName VARCHAR(50));

CREATE TABLE Appointment
(AppointmentID INT IDENTITY PRIMARY KEY,
 CustomerID INT REFERENCES Customer(CustomerID),
 AppointmentDate DATE,
 ModifiedDate DATETIME DEFAULT getdate());

-- In Destination Database

CREATE TABLE AppointmentReport
(AppointmentID int PRIMARY KEY,
 CustomerID int,
 LastName VARCHAR(50),
 FirstName VARCHAR(50),
 AppointmentDate DATE,
 ModifiedDate DATETIME);

CREATE TABLE DateAudit
(LogID INT IDENTITY,
 Action VARCHAR(10),
 AppointmentID INT,
 OldDate DATE, -- appointment date
 NewDate DATE, -- appointment date
 ChangedBy VARCHAR(50) DEFAULT original_login(),
 ChangeTime DATETIME DEFAULT GETDATE());





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

 


