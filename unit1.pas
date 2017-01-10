unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb, db, FileUtil, Forms, Controls,
  Graphics, Dialogs, DBGrids, StdCtrls, DbCtrls, LCLType, ExtCtrls, Unit2;

// Notes on Uses
// Added LCLType to expose the std key mappings for keyboard hits

type

  { TForm1 }

  TForm1 = class(TForm)
    btnCommit2: TButton;
    btnInsert: TButton;
    btnCommit: TButton;
    btnQuit: TButton;
    btnHelp: TButton;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    DataSource3: TDataSource;
    dbgAbbrev: TDBGrid;
    dbgTech: TDBGrid;
    dbgXref: TDBGrid;
    DBNaviAbbr: TDBNavigator;
    DBNavTech: TDBNavigator;
    edbAbbr: TEdit;
    edbTech: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    SQLite3Connection1: TSQLite3Connection;
    SQLQuery1: TSQLQuery;
    SQLQuery2: TSQLQuery;
    SQLQuery3: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure btnCommitClick(Sender: TObject);
    procedure btnInsertClick(Sender: TObject);
    procedure btnQuitClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure dbgAbbrevKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure dbgTechKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure dbgXrefKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure openDBConnections;
    procedure runSQLQuery1;
    procedure runSQLQuery2;
    procedure runSQLQuery3;
    procedure saveChanges;
  //  procedure btnInsertClick(Sender: TObject);
  //  procedure btnQueryClick(Sender: TObject);
    procedure dbgAbbrevCellClick(Column: TColumn);
    procedure dbgTechCellClick(Column: TColumn);
    procedure FormCreate(Sender: TObject);



  private
    { private declarations }
  public
    { public declarations }



  end;

var
  Form1: TForm1;
  AbbrUPD: Integer;
  TechUPD: Integer;
  updateAbbrTech: String;


implementation

{$R *.lfm}

{ TForm1 }



procedure TForm1.dbgAbbrevCellClick(Column: TColumn);
begin
  edbAbbr.Caption := SQLQuery1.FieldByName('Acronym').AsString ;
  AbbrUPD := SQLQuery1.FieldByName('AbbrID').AsInteger ;
  runSQLQuery3;

end;

procedure TForm1.dbgTechCellClick(Column: TColumn);
begin
  edbTech.Caption := SQLQuery2.FieldByName('Name').AsString ;
  TechUPD := SQLQuery2.FieldByName('TechID').AsInteger ;

end;



procedure TForm1.FormCreate(Sender: TObject);
begin
//  btnInsert.Caption := 'Insert';
 edbAbbr.Text:= '';
 edbTech.Text:= '';
 openDBConnections;
end;





procedure TForm1.openDBConnections;
begin
  // Run the initial Queries to polpulate our tables
  runSQLQuery1;
  runSQLQuery2;
  runSQLQuery3;

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  saveChanges;
end;

procedure TForm1.dbgAbbrevKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Check for del key being hit and delete the current record in response
  // as long as we're not editing data
  if (key=VK_DELETE) and (not(dbgAbbrev.EditorMode)) then
  begin
    //... delete current record and apply updates to db:
    SQLQuery1.Delete;
    SQLQuery1.ApplyUpdates;

  end;
end;

procedure TForm1.btnInsertClick(Sender: TObject);
begin
  // Insert data using a direct write via the transaction/connection
  // Two approaches used - comment out the one not needed
  try
    updateAbbrTech := 'INSERT INTO TechXAbbr VALUES (NULL,' + IntToStr(AbbrUPD) + ',' + IntToStr(TechUPD) + ');';
    SQLTransaction1.Commit;
    SQLTransaction1.StartTransaction;
    SQLite3Connection1.ExecuteDirect(updateAbbrTech);
    SQLTransaction1.Commit;
    runSQLQuery1;
    runSQLQuery2;
    runSQLQuery3;
  except
    on E: EDatabaseError do
    begin
      MessageDlg('Error','Unable to Insert Acronym Relationship: ' + E.Message,mtError,[mbOK],0);
      runSQLQuery1;
      runSQLQuery2;
      runSQLQuery3;
    end;
  end;
end;

procedure TForm1.btnQuitClick(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.btnHelpClick(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.btnCommitClick(Sender: TObject);
begin
  saveChanges;
  runSQLQuery1;
  runSQLQuery2;
  runSQLQuery3;
end;

procedure TForm1.dbgTechKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  // Check for del key being hit and delete the current record in response
  // as long as we're not editing data
  if (key=VK_DELETE) and (not(dbgTech.EditorMode)) then
  begin
    //... delete current record and apply updates to db:
    SQLQuery2.Delete;
    SQLQuery2.ApplyUpdates;
  end;
end;

procedure TForm1.dbgXrefKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  // Check for del key being hit and delete the current record in response
  // as long as we're not editing data
  if (key=VK_DELETE) and (not(dbgXref.EditorMode)) then
  begin
    //... delete current record and apply updates to db:
    SQLQuery3.Delete;
    SQLQuery3.ApplyUpdates;
  end;
end;

procedure TForm1.runSQLQuery1;
begin
  // Create the SQL Query 1
  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := 'SELECT * FROM Abbr ORDER BY Acronym';
    SQLite3Connection1.Connected:= True;
    SQLTransaction1.Active:= True;
    SQLQuery1.Open;
    {
    Make sure we don't get problems with inserting blank (=NULL) AbbrID values,
    Field AbbrID is required, but not supplied as it is auto created in the DB
    }
    SQLQuery1.FieldByName('AbbrID').Required:=false;
    dbgAbbrev.Columns[0].Visible:= False;
  except
    //We could use EDatabaseError which is a general database error, but we're dealing with Firebird/Interbase, so:
    on E: EDatabaseError do
    begin
      MessageDlg('Error','Unable to Query Abbr table: ' + E.Message,mtError,[mbOK],0);
    end;
  end;
end;


procedure TForm1.runSQLQuery2;
begin
  // Create the SQL Query 1
  try
    SQLQuery2.Close;
    SQLQuery2.SQL.Text := 'SELECT * FROM Tech ORDER BY Name';
    SQLite3Connection1.Connected:= True;
    SQLTransaction1.Active:= True;
    SQLQuery2.Open;
    {
    Make sure we don't get problems with inserting blank (=NULL) TechID values,
    Field ATechID is required, but not supplied as it is auto created in the DB
    }
    SQLQuery2.FieldByName('TechID').Required:=false;
    dbgTech.Columns[0].Visible:= False;
  except
    //We could use EDatabaseError which is a general database error, but we're dealing with Firebird/Interbase, so:
    on E: EDatabaseError do
    begin
      MessageDlg('Error','Unable to Query Tech Table: ' + E.Message,mtError,[mbOK],0);
    end;
  end;
end;

procedure TForm1.runSQLQuery3;
var
  queryString: String;
begin
  // Create the SQL Query 1
  queryString := 'SELECT ta.TechAbbrevID, a.AbbrID, t.TechID, a.Acronym, t.Name ' +
                 'FROM Abbr AS a ' +
                 'INNER JOIN TechXAbbr AS ta ' +
                 'ON ta.AbbrID = a.AbbrID ' +
                 'INNER JOIN Tech AS t ' +
                 'ON ta.TechID = t.TechID ' +
                 'WHERE a.AbbrID = ' + IntToStr(AbbrUPD) +
                 ' ORDER BY a.Acronym';


  try
    SQLQuery3.Close;
    SQLQuery3.SQL.Text := queryString;
    SQLite3Connection1.Connected:= True;
    SQLTransaction1.Active:= True;
    SQLQuery3.Open;
    {
    Make sure we don't get problems with inserting blank (=NULL) TechAbbrevID values,
    Field TechAbbrevID is required, but not supplied as it is auto created in the DB
    }
    SQLQuery3.FieldByName('TechAbbrevID').Required:=false;
    dbgXref.Columns[0].Visible:= False;
    dbgXref.Columns[1].Visible:= False;
    dbgXref.Columns[2].Visible:= False;
  except
    //We could use EDatabaseError which is a general database error, but we're dealing with Firebird/Interbase, so:
    on E: EDatabaseError do
    begin
      MessageDlg('Error','A unable to Query TechXAbbrev table : ' +
                  E.Message,mtError,[mbOK],0);
    end;
  end;
end;

procedure TForm1.saveChanges;

begin
  If SQLTransaction1.Active = True then
    begin
      try
        begin
          // Pass user-generated changes back to database...
          SQLQuery1.ApplyUpdates;
          SQLQuery2.ApplyUpdates;
          SQLQuery3.ApplyUpdates;
          // Commit the changes to the Database
          SQLTransaction1.Commit;
        end;
      except
      on E: EDatabaseError do
        begin
          MessageDlg('Error', 'Unable to save changes to Database: ' +
                      E.Message, mtError, [mbOK], 0);
        end;
      end;
     end;
end;




end.

