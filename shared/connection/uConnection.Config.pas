unit uConnection.Config;

interface

type
  TConnectionConfig = record
  public
    class function ConnectionDefName: string; static;
    class function DriverID: string; static;
    class function Database: string; static;
    class function UserName: string; static;
    class function Password: string; static;
    class function VendorHome: string; static;
    class function VendorLib: string; static;
    class function TNSAdmin: string; static;
  end;

implementation

class function TConnectionConfig.ConnectionDefName: string;
begin
  Result := 'OraclePool';
end;

class function TConnectionConfig.DriverID: string;
begin
  Result := 'Ora';
end;

class function TConnectionConfig.Database: string;
begin
  Result := 'sancodedb_tp';
end;

class function TConnectionConfig.UserName: string;
begin
  Result := 'ADMIN';
end;

class function TConnectionConfig.Password: string;
begin
  Result := '@SANcode1808@';
end;

class function TConnectionConfig.VendorHome: string;
begin
  Result := 'C:\oracle\instantclient_19_29_x86';
end;

class function TConnectionConfig.VendorLib: string;
begin
  Result := 'C:\oracle\instantclient_19_29_x86\oci.dll';
end;

class function TConnectionConfig.TNSAdmin: string;
begin
  Result := 'C:\oracle\Wallet_sancodeDB';
end;

end.
