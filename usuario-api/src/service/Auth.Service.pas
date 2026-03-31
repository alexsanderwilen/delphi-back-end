unit Auth.Service;

interface

uses
  Auth.DTO;

type
  TAuthService = class
  public
    class function Login(const ADTO: TLoginDTO; const AIp: string): string;
  end;

implementation

uses
  System.SysUtils,
  Auth.Repository,
  Auth.Model,
  uPassword.Hash,
  uJWT.Helper,
  uApp.Exception;

class function TAuthService.Login(const ADTO: TLoginDTO; const AIp: string): string;
var
  User: TAuthUser;
begin
  if Trim(ADTO.Login) = '' then
    raise EAppException.Create('Login é obrigatório.', 400);

  if Trim(ADTO.Senha) = '' then
    raise EAppException.Create('Senha é obrigatória.', 400);

  User := TAuthRepository.BuscarPorLogin(ADTO.Login);
  try
    if not Assigned(User) then
      raise EAppException.Create('Login ou senha inválidos.', 401);

    if User.Ativo <> 'S' then
      raise EAppException.Create('Usuário inativo.', 403);

    if User.Bloqueado = 'S' then
      raise EAppException.Create('Usuário bloqueado.', 403);

    if not TPasswordHash.Verify(ADTO.Senha, User.SenhaHash) then
      raise EAppException.Create('Login ou senha inválidos.', 401);

    TAuthRepository.AtualizarUltimoLogin(User.Id, AIp);

    Result := TJWTToken.GenerateToken(
      User.Id,
      User.Login,
      User.Nome,
      User.Role
    );
  finally
    User.Free;
  end;
end;

end.
