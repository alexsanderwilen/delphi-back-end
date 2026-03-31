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
    class function Criar(const ADTO: TUsuarioCreateDTO): Int64;
  end;

implementation

uses
  System.SysUtils,
  Usuario.Repository;

class function TUsuarioService.Listar: TObjectList<TUsuario>;
begin
  Result := TUsuarioRepository.Listar;
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

end.
