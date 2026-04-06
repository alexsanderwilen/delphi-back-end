unit Auth.Repository;

interface

uses
  Auth.Model;

type
  TAuthRepository = class
  public
    class function BuscarPorLogin(const ALogin: string): TAuthUser;
    class procedure AtualizarUltimoLogin(
      const AUserId: Int64;
      const AIp: string
    );
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  uConnection.Factory;

class function TAuthRepository.BuscarPorLogin(const ALogin: string): TAuthUser;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Result := nil;

  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'select id, login, nome, senha_hash, ativo, bloqueado, role, foto_url ' +
        'from usuario ' +
        'where login = :login';

      Qry.ParamByName('login').AsString := ALogin;
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        Result := TAuthUser.Create;
        Result.Id := Qry.FieldByName('id').AsLargeInt;
        Result.Login := Qry.FieldByName('login').AsString;
        Result.Nome := Qry.FieldByName('nome').AsString;
        Result.SenhaHash := Qry.FieldByName('senha_hash').AsString;
        Result.Ativo := Qry.FieldByName('ativo').AsString;
        Result.Bloqueado := Qry.FieldByName('bloqueado').AsString;
        Result.Role := Qry.FieldByName('role').AsString;
        Result.FotoUrl := Qry.FieldByName('foto_url').AsString;
      end;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAuthRepository.AtualizarUltimoLogin(
  const AUserId: Int64;
  const AIp: string
);
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'update usuario ' +
        'set ultimo_login = current_timestamp, ultimo_ip = :ultimo_ip ' +
        'where id = :id';

      Qry.ParamByName('ultimo_ip').AsString := AIp;
      Qry.ParamByName('id').AsLargeInt := AUserId;
      Qry.ExecSQL;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
