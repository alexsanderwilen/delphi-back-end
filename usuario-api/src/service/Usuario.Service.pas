unit Usuario.Service;

interface

uses
  System.Generics.Collections,
  Usuario.Model,
  Usuario.DTO;

type
  TUsuarioService = class
  public
    class function Listar: TObjectList<TUsuario>;
    class function BuscarPorId(const AID: Int64): TUsuario;
    class function BuscarPorEmail(const AEmail: string): TUsuario;
    class function Criar(const ADTO: TUsuarioCreateDTO): Int64;
    class function ExcluirPorId(const AID: Int64): Int64;
  end;

implementation

uses
  System.SysUtils,
  Usuario.Repository;

class function TUsuarioService.Listar: TObjectList<TUsuario>;
begin
  Result := TUsuarioRepository.Listar;
end;

class function TUsuarioService.BuscarPorId(const AID: Int64): TUsuario;
begin
  if AID <= 0 then
    raise Exception.Create('ID inválido');

  Result := TUsuarioRepository.BuscarPorId(AID);
end;

class function TUsuarioService.BuscarPorEmail(const AEmail: string): TUsuario;
begin
  // remove espaços
  if Trim(AEmail).IsEmpty then
    raise Exception.Create('E-mail é obrigatório.');

  // não pode ter espaço
  if AEmail.Contains(' ') then
    raise Exception.Create('E-mail inválido.');

  // precisa ter @
  if not AEmail.Contains('@') then
    raise Exception.Create('E-mail inválido.');

  // precisa ter ponto depois do @
  if not AEmail.Contains('.') then
    raise Exception.Create('E-mail inválido.');

  // tamanho mínimo básico
  if Length(AEmail) < 5 then
    raise Exception.Create('E-mail inválido.');

  Result := TUsuarioRepository.BuscarPorEmail(AEmail);
end;

class function TUsuarioService.Criar(const ADTO: TUsuarioCreateDTO): Int64;
begin
  if Trim(ADTO.Login) = '' then
    raise Exception.Create('Login é obrigatório.');

  if Trim(ADTO.Nome) = '' then
    raise Exception.Create('Nome é obrigatório.');

  if Trim(ADTO.Senha) = '' then
    raise Exception.Create('Senha é obrigatória.');

  Result := TUsuarioRepository.Inserir(ADTO);
end;

class function TUsuarioService.ExcluirPorId(const AID: Int64): Int64;
begin
  if AID <= 0 then
    raise Exception.Create('ID inválido');

  Result := TUsuarioRepository.ExcluirPorId(AID);
end;

end.
