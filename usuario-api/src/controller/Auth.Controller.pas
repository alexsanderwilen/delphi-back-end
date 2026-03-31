unit Auth.Controller;

interface

procedure Registry;

implementation

uses
  Horse,
  System.JSON,
  System.SysUtils,
  Auth.DTO,
  Auth.Service;

function GetRequestIP(const Req: THorseRequest): string;
begin
  Result := Req.Headers['X-Forwarded-For'];

  if Result = '' then
    Result := Req.Headers['X-Real-IP'];

  if Result = '' then
    Result := '';
end;

procedure PostLogin(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Body: TJSONObject;
  DTO: TLoginDTO;
  Token: string;
  Resp: TJSONObject;
begin
  Body := Req.Body<TJSONObject>;
  if not Assigned(Body) then
    raise Exception.Create('Body JSON não enviado ou inválido.');

  DTO := TLoginDTO.Create;
  try
    DTO.Login := Body.GetValue<string>('login', '');
    DTO.Senha := Body.GetValue<string>('senha', '');

    Token := TAuthService.Login(DTO, GetRequestIP(Req));

    Resp := TJSONObject.Create;
    try
      Resp.AddPair('success', TJSONBool.Create(True));
      Resp.AddPair('token', Token);
      Resp.AddPair('message', 'Login realizado com sucesso.');

      Res
        .ContentType('application/json')
        .Status(200)
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
  THorse.Post('/auth/login', PostLogin);
end;

end.
