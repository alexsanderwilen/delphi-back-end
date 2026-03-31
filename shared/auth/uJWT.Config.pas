unit uJWT.Config;

interface

type
  TJWTConfig = record
  public
    class function SecretKey: string; static;
    class function Issuer: string; static;
    class function ExpirationMinutes: Integer; static;
  end;

implementation

class function TJWTConfig.SecretKey: string;
begin
  Result := 'troque_essa_chave_por_uma_bem_forte_e_grande';
end;

class function TJWTConfig.Issuer: string;
begin
  Result := 'sancode.usuario-api';
end;

class function TJWTConfig.ExpirationMinutes: Integer;
begin
  Result := 60;
end;

end.
