unit Usuario.Controller;

interface

procedure Registry;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Classes,
  System.Generics.Collections,
  Web.HTTPApp,
  Usuario.Service,
  Usuario.Model,
  Usuario.DTO,
  Usuario.Update.DTO,
  Usuario.AlterarSenha.DTO,
  uJWT.CurrentUser,
  uResponse.Helper,
  uApp.Exception;

procedure EnsureAdmin(const Req: THorseRequest);
begin
  CurrentUserId(Req);

  if not SameText(CurrentUserRole(Req), 'admin') then
    raise EAppException.Create('Acesso negado', 403);
end;

function UsuarioToJson(const AUsuario: TUsuario): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AUsuario.Id));
  Result.AddPair('login', AUsuario.Login);
  Result.AddPair('nome', AUsuario.Nome);
  Result.AddPair('email', AUsuario.Email);
  Result.AddPair('ativo', AUsuario.Ativo);
  Result.AddPair('fotoPath', AUsuario.FotoPath);
  Result.AddPair('fotoUrl', AUsuario.FotoUrl);
end;

function CurrentUserToJson(const Req: THorseRequest): TJSONObject;
var
  LUsuario: TUsuario;
  LUserIdStr: string;
  LUserId: Int64;
begin
  LUserIdStr := CurrentUserId(Req);

  if not TryStrToInt64(LUserIdStr, LUserId) then
    raise EAppException.Create('ID do usuário logado inválido.', 400);

  LUsuario := TUsuarioService.BuscarPorId(LUserId);
  try
    Result := TJSONObject.Create;

    Result
      .AddPair('id', TJSONNumber.Create(LUserId))
      .AddPair('login', CurrentLogin(Req))
      .AddPair('nome', CurrentNome(Req))
      .AddPair('role', CurrentUserRole(Req));

    if Assigned(LUsuario) then
    begin
      Result.AddPair('email', LUsuario.Email);
      Result.AddPair('ativo', LUsuario.Ativo);
      Result.AddPair('fotoPath', LUsuario.FotoPath);
      Result.AddPair('fotoUrl', LUsuario.FotoUrl);
    end
    else
    begin
      Result.AddPair('email', '');
      Result.AddPair('ativo', '');
      Result.AddPair('fotoPath', '');
      Result.AddPair('fotoUrl', '');
    end;
  finally
    LUsuario.Free;
  end;
end;

procedure GetUsuarios(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Lista: TObjectList<TUsuario>;
  Arr: TJSONArray;
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
        Arr.AddElement(UsuarioToJson(Usuario));

      UserObj := CurrentUserToJson(Req);

      DataObj := TJSONObject.Create;
      DataObj.AddPair('user', UserObj);
      DataObj.AddPair('usuarios', Arr);

      Success(Res, 'Usuários listados com sucesso.', DataObj);
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
  UserObj: TJSONObject;
  DataObj: TJSONObject;
  LId: Int64;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise EAppException.Create('ID inválido.', 400);

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

    UserObj := CurrentUserToJson(Req);

    DataObj := TJSONObject.Create;
    DataObj.AddPair('user', UserObj);
    DataObj.AddPair('usuario', UsuarioToJson(Usuario));

    Success(Res, 'Usuário encontrado com sucesso.', DataObj);
  finally
    Usuario.Free;
  end;
end;

procedure GetUsuarioPorEmail(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Usuario: TUsuario;
  UserObj: TJSONObject;
  DataObj: TJSONObject;
  LEmail: string;
begin
  EnsureAdmin(Req);

  LEmail := Trim(Req.Params['email']);

  if LEmail.IsEmpty then
    raise EAppException.Create('E-mail é obrigatório.', 400);

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

    UserObj := CurrentUserToJson(Req);

    DataObj := TJSONObject.Create;
    DataObj.AddPair('user', UserObj);
    DataObj.AddPair('usuario', UsuarioToJson(Usuario));

    Success(Res, 'Usuário encontrado com sucesso.', DataObj);
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

    Created(Res, 'Usuário criado com sucesso.', DataObj);
  finally
    DTO.Free;
  end;
end;

procedure PutUsuario(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  DTO: TUsuarioUpdateDTO;
  LId: Int64;
  LAtualizado: Int64;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise EAppException.Create('ID inválido.', 400);

  Body := Req.Body<TJSONObject>;
  if not Assigned(Body) then
    raise EAppException.Create('Body JSON não enviado ou inválido.', 400);

  DTO := TUsuarioUpdateDTO.Create;
  try
    DTO.Login := Body.GetValue<string>('login', '');
    DTO.Nome := Body.GetValue<string>('nome', '');
    DTO.Email := Body.GetValue<string>('email', '');
    DTO.Ativo := Body.GetValue<string>('ativo', '');

    LAtualizado := TUsuarioService.Atualizar(LId, DTO);

    if LAtualizado <= 0 then
    begin
      Res.Status(404).Send<TJSONObject>(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair('message', 'Usuário não encontrado.')
      );
      Exit;
    end;

    DataObj := TJSONObject.Create;
    DataObj.AddPair('id', TJSONNumber.Create(LAtualizado));

    Success(Res, 'Usuário atualizado com sucesso.', DataObj);
  finally
    DTO.Free;
  end;
end;

procedure PutUsuarioSenha(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  DTO: TUsuarioAlterarSenhaDTO;
  LId: Int64;
  LAtualizado: Int64;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise EAppException.Create('ID inválido.', 400);

  Body := Req.Body<TJSONObject>;
  if not Assigned(Body) then
    raise EAppException.Create('Body JSON não enviado ou inválido.', 400);

  DTO := TUsuarioAlterarSenhaDTO.Create;
  try
    DTO.Senha := Body.GetValue<string>('senha', '');
    DTO.ConfirmarSenha := Body.GetValue<string>('confirmarSenha', '');

    LAtualizado := TUsuarioService.AlterarSenha(LId, DTO);

    if LAtualizado <= 0 then
    begin
      Res.Status(404).Send<TJSONObject>(
        TJSONObject.Create
          .AddPair('success', TJSONBool.Create(False))
          .AddPair('message', 'Usuário não encontrado.')
      );
      Exit;
    end;

    DataObj := TJSONObject.Create;
    DataObj.AddPair('id', TJSONNumber.Create(LAtualizado));

    Success(Res, 'Senha do usuário alterada com sucesso.', DataObj);
  finally
    DTO.Free;
  end;
end;

procedure PostUsuarioFoto(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Int64;
  LStream: TMemoryStream;
  LFotoUrl: string;
  LContentType: string;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise EAppException.Create('ID inválido.', 400);

  if Req.RawWebRequest = nil then
    raise EAppException.Create('RawWebRequest não atribuído.', 400);

  if Req.RawWebRequest.Files.Count = 0 then
    raise EAppException.Create('Arquivo não enviado.', 400);

  LContentType := Req.RawWebRequest.Files[0].ContentType;

  if Trim(LContentType) = '' then
    raise EAppException.Create('Content-Type do arquivo não informado.', 400);

  if not LContentType.ToLower.StartsWith('image/') then
    raise EAppException.Create('O arquivo enviado deve ser uma imagem.', 400);

  LStream := TMemoryStream.Create;
  try
    Req.RawWebRequest.Files[0].Stream.Position := 0;
    LStream.CopyFrom(
      Req.RawWebRequest.Files[0].Stream,
      Req.RawWebRequest.Files[0].Stream.Size
    );
    LStream.Position := 0;

    LFotoUrl := TUsuarioService.UploadFoto(
      LId,
      LStream,
      LContentType
    );

    DataObj := TJSONObject.Create;
    DataObj.AddPair('id', TJSONNumber.Create(LId));
    DataObj.AddPair('fotoUrl', LFotoUrl);

    Success(Res, 'Foto do usuário enviada com sucesso.', DataObj);
  finally
    LStream.Free;
  end;
end;

procedure ExcluirUsuarioPorId(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Int64;
  LExcluido: Int64;
  DataObj: TJSONObject;
begin
  EnsureAdmin(Req);

  if not TryStrToInt64(Req.Params['id'], LId) then
    raise EAppException.Create('ID inválido.', 400);

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

  Success(Res, 'Usuário excluído com sucesso.', DataObj);
end;

procedure Registry;
begin
  THorse.Get('/api/v1/usuarios', GetUsuarios);
  THorse.Get('/api/v1/usuarios/:id', GetUsuarioPorId);
  THorse.Get('/api/v1/usuarios/email/:email', GetUsuarioPorEmail);
  THorse.Post('/api/v1/usuarios', PostUsuario);
  THorse.Put('/api/v1/usuarios/:id', PutUsuario);
  THorse.Put('/api/v1/usuarios/:id/senha', PutUsuarioSenha);
  THorse.Post('/api/v1/usuarios/:id/foto', PostUsuarioFoto);
  THorse.Delete('/api/v1/usuarios/:id', ExcluirUsuarioPorId);
end;

end.
