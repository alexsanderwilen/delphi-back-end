unit uJWT.Middleware;

interface

uses
  Horse;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);

function GetUserIdFromRequest(const Req: THorseRequest): string;
function GetLoginFromRequest(const Req: THorseRequest): string;
function GetNomeFromRequest(const Req: THorseRequest): string;

implementation

uses
  System.SysUtils,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  uJWT.Config,
  uApp.Exception;

function ExtractBearerToken(const Req: THorseRequest): string;
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

function DecodeToken(const Req: THorseRequest): TJWT;
var
  Token: string;
begin
  Token := ExtractBearerToken(Req);

  try
    Result := TJOSE.Verify(TJWTConfig.SecretKey, Token);
  except
    on E: Exception do
      raise EAppException.Create('Token inválido', 401);
  end;
end;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LJWT: TJWT;
begin
  LJWT := DecodeToken(Req);
  try
    // apenas valida o token
  finally
    LJWT.Free;
  end;

  Next;
end;

function GetUserIdFromRequest(const Req: THorseRequest): string;
var
  LJWT: TJWT;
begin
  LJWT := DecodeToken(Req);
  try
    Result := LJWT.Claims.Subject;
  finally
    LJWT.Free;
  end;
end;

function GetLoginFromRequest(const Req: THorseRequest): string;
var
  LJWT: TJWT;
begin
  LJWT := DecodeToken(Req);
  try
    Result := LJWT.Claims.JSON.GetValue<string>('login', '');
  finally
    LJWT.Free;
  end;
end;

function GetNomeFromRequest(const Req: THorseRequest): string;
var
  LJWT: TJWT;
begin
  LJWT := DecodeToken(Req);
  try
    Result := LJWT.Claims.JSON.GetValue<string>('nome', '');
  finally
    LJWT.Free;
  end;
end;

end.
