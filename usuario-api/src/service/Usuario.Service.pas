unit Usuario.Service;

interface

uses
  System.Classes,
  System.Generics.Collections,
  Usuario.Model,
  Usuario.DTO;

type
  TUsuarioService = class
  private
    class procedure ValidarEmail(const AEmail: string);
    class procedure PrepararUsuario(AUsuario: TUsuario);
    class procedure PrepararLista(ALista: TObjectList<TUsuario>);
    class function GerarFotoUrl(const AFotoPath: string): string;
    class function ObterExtensaoPorContentType(const AContentType: string): string;
  public
    class function Listar: TObjectList<TUsuario>;
    class function BuscarPorId(const AID: Int64): TUsuario;
    class function BuscarPorEmail(const AEmail: string): TUsuario;
    class function Criar(const ADTO: TUsuarioCreateDTO): Int64;
    class function ExcluirPorId(const AID: Int64): Int64;
    class function UploadFoto(
      const AUsuarioId: Int64;
      AStream: TStream;
      const AContentType: string
    ): string;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Usuario.Repository,
  Storage.MinIO;

class procedure TUsuarioService.ValidarEmail(const AEmail: string);
var
  LEmail: string;
  LPosArroba: Integer;
  LPosPonto: Integer;
begin
  LEmail := Trim(AEmail);

  if LEmail.IsEmpty then
    raise Exception.Create('E-mail é obrigatório.');

  if LEmail.Contains(' ') then
    raise Exception.Create('E-mail inválido.');

  LPosArroba := Pos('@', LEmail);
  if LPosArroba <= 1 then
    raise Exception.Create('E-mail inválido.');

  LPosPonto := LastDelimiter('.', LEmail);
  if (LPosPonto <= LPosArroba + 1) or (LPosPonto = Length(LEmail)) then
    raise Exception.Create('E-mail inválido.');

  if Length(LEmail) < 5 then
    raise Exception.Create('E-mail inválido.');
end;

class function TUsuarioService.ObterExtensaoPorContentType(
  const AContentType: string
): string;
var
  LContentType: string;
begin
  LContentType := Trim(LowerCase(AContentType));

  if (LContentType = 'image/jpeg') or (LContentType = 'image/jpg') then
    Exit('.jpg');

  if LContentType = 'image/png' then
    Exit('.png');

  if LContentType = 'image/webp' then
    Exit('.webp');

  if LContentType = 'image/gif' then
    Exit('.gif');

  raise Exception.Create('Formato de imagem não suportado.');
end;

class function TUsuarioService.GerarFotoUrl(const AFotoPath: string): string;
var
  LFotoPath: string;
begin
  LFotoPath := Trim(AFotoPath);

  if LFotoPath.IsEmpty then
    Exit('');

  Result := TMinIOStorage.GeneratePresignedGetUrl(LFotoPath, 300);
end;

class procedure TUsuarioService.PrepararUsuario(AUsuario: TUsuario);
begin
  if not Assigned(AUsuario) then
    Exit;

  AUsuario.FotoUrl := GerarFotoUrl(AUsuario.FotoPath);
end;

class procedure TUsuarioService.PrepararLista(ALista: TObjectList<TUsuario>);
var
  Usuario: TUsuario;
begin
  if not Assigned(ALista) then
    Exit;

  for Usuario in ALista do
    PrepararUsuario(Usuario);
end;

class function TUsuarioService.Listar: TObjectList<TUsuario>;
begin
  Result := TUsuarioRepository.Listar;
  PrepararLista(Result);
end;

class function TUsuarioService.BuscarPorId(const AID: Int64): TUsuario;
begin
  if AID <= 0 then
    raise Exception.Create('ID inválido.');

  Result := TUsuarioRepository.BuscarPorId(AID);
  PrepararUsuario(Result);
end;

class function TUsuarioService.BuscarPorEmail(const AEmail: string): TUsuario;
begin
  ValidarEmail(AEmail);

  Result := TUsuarioRepository.BuscarPorEmail(Trim(AEmail));
  PrepararUsuario(Result);
end;

class function TUsuarioService.Criar(const ADTO: TUsuarioCreateDTO): Int64;
begin
  if not Assigned(ADTO) then
    raise Exception.Create('Dados do usuário não informados.');

  if Trim(ADTO.Login).IsEmpty then
    raise Exception.Create('Login é obrigatório.');

  if Trim(ADTO.Nome).IsEmpty then
    raise Exception.Create('Nome é obrigatório.');

  ValidarEmail(ADTO.Email);

  if Trim(ADTO.Senha).IsEmpty then
    raise Exception.Create('Senha é obrigatória.');

  ADTO.Login := Trim(ADTO.Login);
  ADTO.Nome := Trim(ADTO.Nome);
  ADTO.Email := LowerCase(Trim(ADTO.Email));
  ADTO.Senha := Trim(ADTO.Senha);

  Result := TUsuarioRepository.Inserir(ADTO);
end;

class function TUsuarioService.ExcluirPorId(const AID: Int64): Int64;
begin
  if AID <= 0 then
    raise Exception.Create('ID inválido.');

  Result := TUsuarioRepository.ExcluirPorId(AID);
end;

class function TUsuarioService.UploadFoto(
  const AUsuarioId: Int64;
  AStream: TStream;
  const AContentType: string
): string;
var
  LObjectName: string;
  LExtensao: string;
  LStorage: TMinIOStorage;
begin
  if AUsuarioId <= 0 then
    raise Exception.Create('Usuário inválido.');

  if not Assigned(AStream) then
    raise Exception.Create('Arquivo não enviado.');

  LExtensao := ObterExtensaoPorContentType(AContentType);

  LObjectName := Format(
    'usuarios/%d/foto_%d%s',
    [AUsuarioId, DateTimeToUnix(Now), LExtensao]
  );

  LStorage := TMinIOStorage.Create;
  try
    if not LStorage.UploadFile(
      LObjectName,
      AStream,
      AContentType
    ) then
      raise Exception.Create('Erro ao enviar imagem para o storage.');
  finally
    LStorage.Free;
  end;

  TUsuarioRepository.AtualizarFoto(AUsuarioId, LObjectName);

  Result := TMinIOStorage.GeneratePresignedGetUrl(LObjectName, 300);
end;

end.
