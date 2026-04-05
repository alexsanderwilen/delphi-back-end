unit Usuario.Controller;

interface

procedure Registry;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Usuario.Service,
  Usuario.Model,
  Usuario.DTO,
  uJWT.CurrentUser,
  uResponse.Helper,
  uApp.Exception;

procedure EnsureAdmin(const Req: THorseRequest);
begin
  CurrentUserId(Req);

  if not SameText(CurrentUserRole(Req), 'admin') then
    raise EAppException.Create('Acesso negado', 403);
end;

procedure GetUsuarios(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Lista: TObjectList<TUsuario>;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Usuario: TUsuario;
  UserObj: TJSONObject;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  Lista := TUsuarioService.Listar;
  try
    Arr := TJSONArray.Create;
    try
      for Usuario in Lista do
      begin
        Obj := TJSONObject.Create;
        Obj.AddPair('id', TJSONNumber.Create(Usuario.Id));
        Obj.AddPair('login', Usuario.Login);
        Obj.AddPair('nome', Usuario.Nome);
        Obj.AddPair('email', Usuario.Email);
        Obj.AddPair('ativo', Usuario.Ativo);
        Arr.AddElement(Obj);
      end;

      UserObj := TJSONObject.Create;
      UserObj
        .AddPair('id', CurrentUserId(Req))
        .AddPair('login', CurrentLogin(Req))
        .AddPair('nome', CurrentNome(Req))
        .AddPair('role', CurrentUserRole(Req));

      DataObj := TJSONObject.Create;
      DataObj.AddPair('user', UserObj);
      DataObj.AddPair('usuarios', Arr);

      Success(Res, 'Usuários listados com sucesso', DataObj);
    except
      Arr.Free;
      raise;
    end;
  finally
    Lista.Free;
  end;
end;

procedure GetUsuarioPorId(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Usuario: TUsuario;
  Obj: TJSONObject;
  UserObj: TJSONObject;
  DataObj: TJSONObject;
  ResponseObj: TJSONObject;
  LId: Int64;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise Exception.Create('ID inválido.');

  Usuario := TUsuarioService.BuscarPorId(LId);
  try
    if not Assigned(Usuario) then
    begin
      Res.Status(404).Send<TJSONObject>(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair('message', 'Usuário não encontrado.')
      );
      Exit;
    end;

    Obj := TJSONObject.Create;
    Obj.AddPair('id', TJSONNumber.Create(Usuario.Id));
    Obj.AddPair('login', Usuario.Login);
    Obj.AddPair('nome', Usuario.Nome);
    Obj.AddPair('email', Usuario.Email);
    Obj.AddPair('ativo', Usuario.Ativo);

    UserObj := TJSONObject.Create;
    UserObj
      .AddPair('id', CurrentUserId(Req))
      .AddPair('login', CurrentLogin(Req))
      .AddPair('nome', CurrentNome(Req))
      .AddPair('role', CurrentUserRole(Req));

    DataObj := TJSONObject.Create;
    DataObj.AddPair('user', UserObj);
    DataObj.AddPair('usuario', Obj);

    ResponseObj := TJSONObject.Create;
    ResponseObj
      .AddPair('success', TJSONBool.Create(True))
      .AddPair('message', 'Usuário encontrado com sucesso.')
      .AddPair('data', DataObj);

    Res.Status(200).Send<TJSONObject>(ResponseObj);
  finally
    Usuario.Free;
  end;
end;

procedure GetUsuarioPorEmail(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Usuario: TUsuario;
  Obj: TJSONObject;
  UserObj: TJSONObject;
  DataObj: TJSONObject;
  ResponseObj: TJSONObject;
  LEmail: string;
begin
  EnsureAdmin(Req);

  LEmail := Trim(Req.Params['email']);

  if LEmail.IsEmpty then
    raise Exception.Create('E-mail é obrigatório.');

  Usuario := TUsuarioService.BuscarPorEmail(LEmail);
  try
    if not Assigned(Usuario) then
    begin
      Res.Status(404).Send<TJSONObject>(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair('message', 'Usuário não encontrado.')
      );
      Exit;
    end;

    Obj := TJSONObject.Create;
    Obj.AddPair('id', TJSONNumber.Create(Usuario.Id));
    Obj.AddPair('login', Usuario.Login);
    Obj.AddPair('nome', Usuario.Nome);
    Obj.AddPair('email', Usuario.Email);
    Obj.AddPair('ativo', Usuario.Ativo);

    UserObj := TJSONObject.Create;
    UserObj
      .AddPair('id', TJSONNumber.Create(CurrentUserId(Req)))
      .AddPair('login', CurrentLogin(Req))
      .AddPair('nome', CurrentNome(Req))
      .AddPair('role', CurrentUserRole(Req));

    DataObj := TJSONObject.Create;
    DataObj.AddPair('user', UserObj);
    DataObj.AddPair('usuario', Obj);

    ResponseObj := TJSONObject.Create;
    ResponseObj
      .AddPair('success', TJSONBool.Create(True))
      .AddPair('message', 'Usuário encontrado com sucesso.')
      .AddPair('data', DataObj);

    Res.Status(200).Send<TJSONObject>(ResponseObj);
  finally
    Usuario.Free;
  end;
end;

procedure PostUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  DTO: TUsuarioCreateDTO;
  IdGerado: Int64;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  Body := Req.Body<TJSONObject>;
  if not Assigned(Body) then
    raise EAppException.Create('Body JSON não enviado ou inválido.', 400);

  DTO := TUsuarioCreateDTO.Create;
  try
    DTO.Login := Body.GetValue<string>('login', '');
    DTO.Nome := Body.GetValue<string>('nome', '');
    DTO.Email := Body.GetValue<string>('email', '');
    DTO.Senha := Body.GetValue<string>('senha', '');

    IdGerado := TUsuarioService.Criar(DTO);

    DataObj := TJSONObject.Create;
    DataObj.AddPair('id', TJSONNumber.Create(IdGerado));

    Created(Res, 'Usuário criado com sucesso', DataObj);
  finally
    DTO.Free;
  end;
end;

procedure ExcluirUsuarioPorId(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Int64;
  LExcluido: Int64;
  UserObj: TJSONObject;
  DataObj: TJSONObject;
  ResponseObj: TJSONObject;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise Exception.Create('ID inválido.');

  LExcluido := TUsuarioService.ExcluirPorId(LId);

  if LExcluido <= 0 then
  begin
    Res.Status(404).Send<TJSONObject>(
      TJSONObject.Create
        .AddPair('success', TJSONBool.Create(False))
        .AddPair('message', 'Usuário não encontrado.')
    );
    Exit;
  end;

  DataObj := TJSONObject.Create;
  DataObj.AddPair('id', TJSONNumber.Create(LId));

  ResponseObj := TJSONObject.Create;
  ResponseObj
    .AddPair('success', TJSONBool.Create(True))
    .AddPair('message', 'Usuário excluído com sucesso.')
    .AddPair('data', DataObj);

  Res.Status(200).Send<TJSONObject>(ResponseObj);
end;

procedure Registry;
begin
  // LISTAR
  THorse.Get('/api/v1/usuarios', GetUsuarios);

  // BUSCAR POR ID
  THorse.Get('/api/v1/usuarios/:id', GetUsuarioPorId);

  // BUSCAR POR EMAIL (recomendado via query)
  THorse.Get('/api/v1/usuarios/email/:email', GetUsuarioPorEmail);

  // CRIAR
  THorse.Post('/api/v1/usuarios', PostUsuario);

  // ATUALIZAR
  // THorse.Put('/api/v1/usuarios/:id', PutUsuarioPorId);

  // EXCLUIR
  THorse.Delete('/api/v1/usuarios/:id', ExcluirUsuarioPorId);
end;


end.
