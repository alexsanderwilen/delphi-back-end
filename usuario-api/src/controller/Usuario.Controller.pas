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
  uJWT.CurrentUser;

procedure GetUsuarios(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Lista: TObjectList<TUsuario>;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Usuario: TUsuario;
begin
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

      Obj := TJSONObject.Create;
      try
        Obj.AddPair('success', TJSONBool.Create(True));

        Obj.AddPair(
          'user',
          TJSONObject.Create
            .AddPair('id', CurrentUserId(Req))
            .AddPair('login', CurrentLogin(Req))
            .AddPair('nome', CurrentNome(Req))
        );

        Obj.AddPair('data', Arr);

        Res
          .ContentType('application/json')
          .Status(200)
          .Send(Obj.ToJSON);
      finally
        Obj.Free;
      end;
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
  Resp: TJSONObject;
begin
  Body := Req.Body<TJSONObject>;
  if not Assigned(Body) then
    raise Exception.Create('Body JSON não enviado ou inválido.');

  DTO := TUsuarioCreateDTO.Create;
  try
    DTO.Login := Body.GetValue<string>('login', '');
    DTO.Nome := Body.GetValue<string>('nome', '');
    DTO.Email := Body.GetValue<string>('email', '');
    DTO.Senha := Body.GetValue<string>('senha', '');

    IdGerado := TUsuarioService.Criar(DTO);

    Resp := TJSONObject.Create;
    try
      Resp.AddPair('success', TJSONBool.Create(True));
      Resp.AddPair('id', TJSONNumber.Create(IdGerado));
      Resp.AddPair('message', 'Usuário criado com sucesso.');

      Res
        .ContentType('application/json')
        .Status(201)
        .Send(Resp.ToJSON);
    finally
      Resp.Free;
    end;
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
