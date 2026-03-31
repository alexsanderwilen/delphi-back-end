unit uJWT.CurrentUser;

interface

uses
  Horse;

function CurrentUserId(const Req: THorseRequest): string;
function CurrentLogin(const Req: THorseRequest): string;
function CurrentNome(const Req: THorseRequest): string;
function CurrentUserRole(const Req: THorseRequest): string; // NOVO

implementation

uses
  System.SysUtils,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  uJWT.Config,
  uApp.Exception;

function ExtractToken(const Req: THorseRequest): string;
begin
  Result := Trim(Req.Headers['Authorization']);

  if Result = '' then
    raise EAppException.Create('Token não informado', 401);

  if Result.StartsWith('Bearer ', True) then
    Result := Result.Substring(7);

  Result := Trim(Result);

  if Result = '' then
    raise EAppException.Create('Token não informado', 401);
end;

function Decode(const Req: THorseRequest): TJWT;
var
  Token: string;
begin
  Token := ExtractToken(Req);

  try
    Result := TJOSE.Verify(TJWTConfig.SecretKey, Token);
  except
    on E: Exception do
      raise EAppException.Create('Token inválido', 401);
  end;
end;

function CurrentUserId(const Req: THorseRequest): string;
var
  JWT: TJWT;
begin
  JWT := Decode(Req);
  try
    Result := JWT.Claims.Subject;
  finally
    JWT.Free;
  end;
end;

function CurrentLogin(const Req: THorseRequest): string;
var
  JWT: TJWT;
begin
  JWT := Decode(Req);
  try
    Result := JWT.Claims.JSON.GetValue<string>('login', '');
  finally
    JWT.Free;
  end;
end;

function CurrentNome(const Req: THorseRequest): string;
var
  JWT: TJWT;
begin
  JWT := Decode(Req);
  try
    Result := JWT.Claims.JSON.GetValue<string>('nome', '');
  finally
    JWT.Free;
  end;
end;

function CurrentUserRole(const Req: THorseRequest): string;
var
  JWT: TJWT;
begin
  JWT := Decode(Req);
  try
    Result := JWT.Claims.JSON.GetValue<string>('role', '');
  finally
    JWT.Free;
  end;
end;

end.
