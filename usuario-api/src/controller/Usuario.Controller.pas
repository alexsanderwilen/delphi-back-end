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
  // valida token
  CurrentUserId(Req);

  // valida role
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

procedure Registry;
begin
  THorse.Get('/usuarios', GetUsuarios);
  THorse.Post('/usuarios', PostUsuario);
end;

end.
