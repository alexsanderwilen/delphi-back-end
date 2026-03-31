unit uConnection.Factory;

interface

uses
  FireDAC.Comp.Client;

type
  TConnectionFactory = class
  public
    class procedure Configure;
    class function NewConnection: TFDConnection;
    class function NewQuery(AConnection: TFDConnection): TFDQuery;
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Pool,
  FireDAC.Phys,
  FireDAC.Phys.Intf,
  FireDAC.Phys.Oracle,
  FireDAC.Phys.OracleDef,
  FireDAC.DApt,
  uConnection.Config;

var
  OracleDriverLink: TFDPhysOracleDriverLink;

class procedure TConnectionFactory.Configure;
var
  LDef: IFDStanConnectionDef;
begin
  if not Assigned(OracleDriverLink) then
  begin
    OracleDriverLink := TFDPhysOracleDriverLink.Create(nil);
    OracleDriverLink.DriverID := 'Ora';
    OracleDriverLink.VendorHome := TConnectionConfig.VendorHome;
    OracleDriverLink.VendorLib := TConnectionConfig.VendorLib;
    OracleDriverLink.TNSAdmin := TConnectionConfig.TNSAdmin;
  end;

  if not FDManager.Active then
    FDManager.Active := True;

  if FDManager.ConnectionDefs.FindConnectionDef(TConnectionConfig.ConnectionDefName) <> nil then
    Exit;

  LDef := FDManager.ConnectionDefs.AddConnectionDef;
  LDef.Name := TConnectionConfig.ConnectionDefName;
  LDef.Params.DriverID := TConnectionConfig.DriverID;
  LDef.Params.Values['Database'] := TConnectionConfig.Database;
  LDef.Params.UserName := TConnectionConfig.UserName;
  LDef.Params.Password := TConnectionConfig.Password;
  LDef.Params.Values['Pooled'] := 'True';
  LDef.Params.Values['CharacterSet'] := 'AL32UTF8';
  LDef.Params.Values['LoginTimeout'] := '15';
  LDef.Params.Values['POOL_MaximumItems'] := '50';
  LDef.Params.Values['POOL_ExpireTimeout'] := '90000';
  LDef.Params.Values['POOL_CleanupTimeout'] := '30000';
end;

class function TConnectionFactory.NewConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.ConnectionDefName := TConnectionConfig.ConnectionDefName;
  Result.Connected := True;
end;

class function TConnectionFactory.NewQuery(AConnection: TFDConnection): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := AConnection;
end;

initialization

finalization
  OracleDriverLink.Free;

end.
