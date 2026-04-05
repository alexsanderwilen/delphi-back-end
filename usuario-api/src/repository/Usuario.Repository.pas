unit Usuario.Repository;

interface

uses
  System.Generics.Collections,
  Data.DB,
  FireDAC.Stan.Param,
  uPassword.Hash,
  Usuario.Model,
  Usuario.DTO;

type
  TUsuarioRepository = class
  public
    class function Listar: TObjectList<TUsuario>;
    class function BuscarPorId(const AID: Int64): TUsuario;
    class function BuscarPorEmail(const AEmail: string): TUsuario;
    class function Inserir(const ADTO: TUsuarioCreateDTO): Int64;
    class function ExcluirPorId(const AID: Int64): Int64;
  end;

implementation

uses
  FireDAC.Comp.Client,
  uConnection.Factory,
  System.SysUtils;

class function TUsuarioRepository.Listar: TObjectList<TUsuario>;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
  Usuario: TUsuario;
begin
  Result := TObjectList<TUsuario>.Create(True);

  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'select id, login, nome, email, ativo ' +
        'from usuario ' +
        'order by id';

      Qry.Open;
      Qry.First;
      while not Qry.Eof do
      begin
        Usuario := TUsuario.Create;
        Usuario.Id := Qry.FieldByName('id').AsLargeInt;
        Usuario.Login := Qry.FieldByName('login').AsString;
        Usuario.Nome := Qry.FieldByName('nome').AsString;
        Usuario.Email := Qry.FieldByName('email').AsString;
        Usuario.Ativo := Qry.FieldByName('ativo').AsString;

        Result.Add(Usuario);
        Qry.Next;
      end;

    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TUsuarioRepository.BuscarPorId(const AID: Int64): TUsuario;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
  Usuario: TUsuario;
begin
  Result := TUsuario.Create;

  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'select id, login, nome, email, ativo ' +
        'from usuario ' +
        'where id = :pID ' +
        'order by id';

      Qry.ParamByName('pID').DataType := ftLargeint;
      Qry.ParamByName('pID').ParamType := ptInput;
      Qry.ParamByName('pID').AsLargeInt := AID;

      Qry.Open;

      if not Qry.IsEmpty then
      begin
        Usuario := TUsuario.Create;
        Usuario.Id := Qry.FieldByName('id').AsLargeInt;
        Usuario.Login := Qry.FieldByName('login').AsString;
        Usuario.Nome := Qry.FieldByName('nome').AsString;
        Usuario.Email := Qry.FieldByName('email').AsString;
        Usuario.Ativo := Qry.FieldByName('ativo').AsString;

        Result := Usuario;
      end;

    finally
      Qry.Close;
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TUsuarioRepository.BuscarPorEmail(
  const AEmail: string): TUsuario;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
  Usuario: TUsuario;
begin
  Result := TUsuario.Create;

  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'select id, login, nome, email, ativo ' +
        'from usuario ' +
        'where email = :pEmail ' +
        'order by id';

      Qry.ParamByName('pEmail').DataType := ftString;
      Qry.ParamByName('pEmail').ParamType := ptInput;
      Qry.ParamByName('pEmail').AsString := AEmail;

      Qry.Open;

      if not Qry.IsEmpty then
      begin
        Usuario := TUsuario.Create;
        Usuario.Id := Qry.FieldByName('id').AsLargeInt;
        Usuario.Login := Qry.FieldByName('login').AsString;
        Usuario.Nome := Qry.FieldByName('nome').AsString;
        Usuario.Email := Qry.FieldByName('email').AsString;
        Usuario.Ativo := Qry.FieldByName('ativo').AsString;

        Result := Usuario;
      end;

    finally
      Qry.Close;
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;


class function TUsuarioRepository.Inserir(const ADTO: TUsuarioCreateDTO): Int64;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'insert into usuario (' +
        '  login, nome, email, senha_hash, ativo, data_cadastro' +
        ') values (' +
        '  :login, :nome, :email, :senha_hash, ''S'', current_timestamp' +
        ') returning id into :id';

      Qry.ParamByName('login').AsString := ADTO.Login;
      Qry.ParamByName('nome').AsString := ADTO.Nome;
      Qry.ParamByName('email').AsString := ADTO.Email;

      Qry.ParamByName('senha_hash').AsString := TPasswordHash.Hash(ADTO.Senha);

      Qry.ParamByName('id').DataType := ftLargeint;
      Qry.ParamByName('id').ParamType := ptOutput;

      Qry.ExecSQL;

      Result := Qry.ParamByName('id').AsLargeInt;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TUsuarioRepository.ExcluirPorId(const AID: Int64): Int64;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Result := -1;
  Conn := TConnectionFactory.NewConnection;
  try
    Qry := TConnectionFactory.NewQuery(Conn);
    try
      Qry.SQL.Text :=
        'delete from usuario ' +
        'where id = :pID';

      Qry.ParamByName('pID').DataType := ftLargeint;
      Qry.ParamByName('pID').ParamType := ptInput;
      Qry.ParamByName('pID').AsLargeInt := AID;

      Qry.ExecSQL;

      if Qry.RowsAffected > 0 then
        Result := AID;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
